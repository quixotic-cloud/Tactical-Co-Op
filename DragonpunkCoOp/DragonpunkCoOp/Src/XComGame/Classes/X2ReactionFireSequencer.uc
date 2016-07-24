//---------------------------------------------------------------------------------------
//  FILE:    X2ReactionFireSequencer.uc
//  AUTHOR:  Ryan McFall --  07/08/2015
//  PURPOSE: Pulls together logic that formerly lived in X2Actions related to firing with
//			 the goal of compartmentalizing the specialized logic needed to control the 
//			 camera and slo mo rates of actors participating in a reaction fire sequence.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2ReactionFireSequencer extends Actor implements(X2VisualizationMgrObserverInterface) config(Camera);

var private XComGameStateHistory History;
var privatewrite int ReactionFireCount;

var private X2Camera_OverTheShoulder TargetCam; //Used to cut to a shot where the target is in the foreground and the shooter is in the background
var private AkEvent SlomoStartSound;
var private AkEvent SlomoStopSound;
var private bool bFancyOverwatchActivated;

//Track information about what the target is for the current reaction fire sequence
var private Actor TargetVisualizer;
var private X2VisualizerInterface TargetVisualizerInterface;
var private float TargetStartingTimeDilation;

var private const config float ReactionFireWorldSloMoRate;
var private float ReactionFireTargetSloMoRate;

struct ReactionFireInstance
{
	var int ShooterObjectID;
	var int TargetObjectID;
	var X2Action_ExitCover ExitCoverAction; // The reaction fire mgr will make this action wait until the shooting action is ready to be shown
	var X2Camera ShooterCam;
	var bool bStarted; //tracks whether this instance was started or not
	var bool bReadyForNext; //tracks whether this instance is 'done' or not
};
var private array<ReactionFireInstance> ReactionFireInstances;
var private array<X2Camera> AddedCameras; //This is an array that contains all cameras that have been added to the camera stack. Used to make sure they all get removed at the end of the sequence.

/// <summary>
/// Returns true if the ability used in the passed in context is considered reaction fire
/// </summary>
function bool IsReactionFire(XComGameStateContext_Ability FiringAbilityContext)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;	
	local bool bIsReactionFire;

	//Were interrupted and didn't resume ( died or otherwise failed to use the ability )
	if (FiringAbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt &&
		FiringAbilityContext.ResumeHistoryIndex == -1)
	{
		return false;
	}	

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(FiringAbilityContext.InputContext.AbilityTemplateName);
	if(AbilityTemplate != none)
	{
		ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
		if(ToHitCalc != none && ToHitCalc.bReactionFire)
		{			
			bIsReactionFire = true;			
		}

		//Disallow melee to count as reaction fire, per request from Jake & Garth. There is melee handling in this class in case we want to bring it back.
		bIsReactionFire = bIsReactionFire && !AbilityTemplate.IsMelee();
	}

	return bIsReactionFire;
}

/// <summary>
/// Returns the target of this reaction fire sequence
/// </summary>
function Actor GetTargetVisualizer()
{
	return TargetVisualizer;
}

/// <summary>
/// Returns the number of reaction fire events remaining in the interrupt chain
/// </summary>
private function int GetNumRemainingReactionFires(XComGameStateContext_Ability FiringAbilityContext, optional out XComGameStateContext_Ability OutNextReactionFire, optional out int NumTilesVisibleToShooters)
{
	local int Index;
	local XComGameStateHistory LocalHistory;
	local XComGameState TestState;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;
	local XComGameStateContext CheckContext;
	local XComGameStateContext_Ability CheckAbilityContext;
	local XComGameState InterruptedState;
	local XComGameStateContext_Ability InterruptedAbility;
	local XComGameStateContext_Ability ResumeAbility;	
	local array<int> ShooterObjectIDs;
	local int NumReactionFireShots;
	local int ShooterIndex;
	local int TargetObjectID;
	local int TargetPathIndex;
	local int PathTileIndex;
	local PathingResultData PathingData;
	local bool bShootersCanSee;
	local int FirstInterruptStep;	

	LocalHistory = `XCOMHISTORY;

	InterruptedState = FiringAbilityContext.GetInterruptedState();
	InterruptedAbility = XComGameStateContext_Ability(InterruptedState.GetContext());
	FirstInterruptStep = InterruptedAbility.ResultContext.InterruptionStep;	
	TargetObjectID = InterruptedAbility.InputContext.SourceObject.ObjectID;
	ShooterObjectIDs.Length = 0;

	NumTilesVisibleToShooters = 0; //Default to no tiles visible. Either the unit died or immediately broke LOS with the shooters.
	for(Index = FiringAbilityContext.AssociatedState.HistoryIndex + 1; Index < LocalHistory.GetNumGameStates(); ++Index)
	{
		TestState = LocalHistory.GetGameStateFromHistory(Index);

		//Exit if we have left our event chain. Will happen in cases where there is no resume
		CheckContext = TestState.GetContext();
		if(CheckContext.EventChainStartIndex != FiringAbilityContext.EventChainStartIndex)
		{
			break;
		}

		//Exit if we found the resume state
		if (InterruptedAbility.ResumeHistoryIndex != -1 &&
			InterruptedAbility.ResumeHistoryIndex == TestState.HistoryIndex)
		{
			//Here, were traverse the interrupt chain checking for more interrupts along this unit's path. We treat an additional interrupt 
			//in the same way we would treat the unit moving behind a wall - the reaction fire sequence shouldn't last past it.
			if( InterruptedState.GetContext() != None && InterruptedState.GetContext().GetResumeState() != None )
			{
				ResumeAbility = XComGameStateContext_Ability(InterruptedState.GetContext().GetResumeState().GetContext());
			}
			while(ResumeAbility != none && ResumeAbility.InterruptionStatus == eInterruptionStatus_Interrupt)
			{
				InterruptedState = LocalHistory.GetGameStateFromHistory(ResumeAbility.AssociatedState.HistoryIndex + 1);					
				if(XComGameStateContext_Ability(InterruptedState.GetContext()) != none)
				{
					//Interrupted by an ability - abort.
					break;
				}

				//Get the resume context and repeat
				ResumeAbility = XComGameStateContext_Ability(InterruptedState.GetContext().GetResumeState().GetContext());
			}

			//We know at this point that there will be no further interruptions along this path. Now see how many tiles we can see along the path
			if( ResumeAbility == None || ResumeAbility.InterruptionStatus != eInterruptionStatus_Interrupt)
			{
				//Find the path results representing the unit that is moving and being fired at. Will not do anything if there was no move / path results.
				for(TargetPathIndex = 0; TargetPathIndex < InterruptedAbility.ResultContext.PathResults.Length; ++TargetPathIndex)
				{
					//Handle group moves such as alien patrols, specialist + gremlin. Find the right target unit.
					if(InterruptedAbility.ResultContext.PathResults[TargetPathIndex].PathTileData.Length > 0 &&
					   InterruptedAbility.ResultContext.PathResults[TargetPathIndex].PathTileData[0].SourceObjectID == TargetObjectID)
					{
						//Iterate the path, finding out how many tiles of the resume path that the overwatching units can see
						PathingData = InterruptedAbility.ResultContext.PathResults[TargetPathIndex];

						//For each tile the unit moves through during this reaction fire sequence, check to see whether the shooters can see them at that tile as recorded by
						//the path results array ( filled out when the most is submitted to the ruleset ).
						for(PathTileIndex = FirstInterruptStep; PathTileIndex < PathingData.PathTileData.Length; ++PathTileIndex)
						{
							bShootersCanSee = true;
							for(ShooterIndex = 0; ShooterIndex < ShooterObjectIDs.Length; ++ShooterIndex)
							{
								if(PathingData.PathTileData[PathTileIndex].VisibleEnemies.Find('SourceID', ShooterObjectIDs[ShooterIndex]) == -1)
								{
									bShootersCanSee = false;
									break;
								}
							}

							//All the shooters could see this tile, increment the number of tiles visible to the shooters
							if(bShootersCanSee)
							{
								++NumTilesVisibleToShooters;
							}
						}
					}
				}
			}			

			break;
		}

		CheckAbilityContext = XComGameStateContext_Ability(TestState.GetContext());
		if(CheckAbilityContext != none)
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(CheckAbilityContext.InputContext.AbilityTemplateName);
			if(AbilityTemplate != none)
			{
				ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
				if(ToHitCalc != none && ToHitCalc.bReactionFire)
				{
					++NumReactionFireShots;
					if (NumReactionFireShots == 1)
					{
						OutNextReactionFire = CheckAbilityContext;
					}

					ShooterObjectIDs.AddItem(CheckAbilityContext.InputContext.SourceObject.ObjectID);
				}
			}
		}
	}

	return NumReactionFireShots;
}

function bool InReactionFireSequence()
{
	return ReactionFireCount > 0;
}

function bool FiringAtMovingTarget()
{
	return bFancyOverwatchActivated;
}

private function StartReactionFireSequence(XComGameStateContext_Ability FiringAbilityContext)
{
	local float NumReactions;
	local float WorldSloMoRate;
	local int NumTilesVisibleToShooters;

	History = `XCOMHISTORY;

	TargetVisualizer = History.GetVisualizer(FiringAbilityContext.InputContext.PrimaryTarget.ObjectID);
	TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

	//Force the slomo rate to be a reasonable value
	WorldSloMoRate = FMax(FMin(ReactionFireWorldSloMoRate, 1.0f), 0.33f);

	//See how many reaction fires there will be
	NumReactions = FMax(float(GetNumRemainingReactionFires(FiringAbilityContext, , NumTilesVisibleToShooters)), 1.0f);

	//Decide between a standard overwatch sequence and a more dynamic one. For the more dynamic one we let the character run faster while the
	//shooter tracks and shoots at them. This has several requirements relating to how many shooters and the number of tiles left in the path
	//that are visible. If the unit was killed or didn't resume from the shot NumTilesVisibleToShooters will be 0
	if(NumReactions == 1.0f && NumTilesVisibleToShooters > 6)
	{		
		WorldInfo.Game.SetGameSpeed(WorldSloMoRate);
		TargetStartingTimeDilation = TargetVisualizer.CustomTimeDilation;
		TargetVisualizerInterface.SetTimeDilation(ReactionFireTargetSloMoRate*2.0f);		
		bFancyOverwatchActivated = true;
	}
	else
	{
		WorldInfo.Game.SetGameSpeed(WorldSloMoRate);
		TargetStartingTimeDilation = TargetVisualizer.CustomTimeDilation;
		TargetVisualizerInterface.SetTimeDilation(ReactionFireTargetSloMoRate);
	}
	
	PlayAkEvent(SlomoStartSound);
}

function EndReactionFireSequence(XComGameStateContext_Ability FiringAbilityContext)
{
	local int Index;

	//Failsafe handling to make sure that no reaction fire cameras get stuck on the camera stack
	for(Index = 0; Index < AddedCameras.Length; ++Index)
	{
		`CAMERASTACK.RemoveCamera(AddedCameras[Index]);
	}

	if(FiringAbilityContext != none)
	{
		if(FiringAbilityContext.GetInterruptedState().GetContext().ResumeHistoryIndex > -1)
		{
			//Let the interruptee continue on, the shooting part is done
			`XCOMVISUALIZATIONMGR.ManualPermitNextVisualizationBlockToRun(FiringAbilityContext.AssociatedState.HistoryIndex);
		}
		else
		{
			TargetVisualizerInterface.SetTimeDilation(TargetStartingTimeDilation);
		}
	}
	else
	{
		TargetVisualizerInterface.SetTimeDilation(TargetStartingTimeDilation);
	}
	
	WorldInfo.Game.SetGameSpeed(1.0f);
	PlayAkEvent(SlomoStopSound);
	bFancyOverwatchActivated = false;
}

function PushReactionFire(X2Action_ExitCover ExitCoverAction)
{
	local XComGameStateContext_Ability FiringAbilityContext;
	local ReactionFireInstance NewReactionFire;
	local XComGameState_Unit ShooterState;
	local XComGameState_Unit TargetState;
	local X2Camera_OTSReactionFireShooter ShooterCam;
	local X2Camera_Midpoint MeleeCam;
	local X2AbilityTemplate FiringAbilityTemplate;

	++ReactionFireCount;

	if(History == none)
	{
		History = `XCOMHISTORY;
	}
	
	FiringAbilityContext = ExitCoverAction.AbilityContext;

	NewReactionFire.ShooterObjectID = FiringAbilityContext.InputContext.SourceObject.ObjectID;
	NewReactionFire.TargetObjectID = FiringAbilityContext.InputContext.PrimaryTarget.ObjectID;	
	NewReactionFire.ExitCoverAction = ExitCoverAction;
	ShooterState = XComGameState_Unit(History.GetGameStateForObjectID(NewReactionFire.ShooterObjectID, eReturnType_Reference, FiringAbilityContext.AssociatedState.HistoryIndex));

	FiringAbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(FiringAbilityContext.InputContext.AbilityTemplateName);
	if (FiringAbilityTemplate.IsMelee())
	{
		//Don't use an over-the-shoulder camera for melee reactions
		MeleeCam = new class'X2Camera_Midpoint';
		MeleeCam.AddFocusActor(ShooterState.GetVisualizer());
		MeleeCam.AddFocusActor(History.GetVisualizer(NewReactionFire.TargetObjectID));

		NewReactionFire.ShooterCam = MeleeCam;
	}
	else
	{
		ShooterCam = new class'X2Camera_OTSReactionFireShooter';
		ShooterCam.FiringUnit = XGUnit(ShooterState.GetVisualizer());
		ShooterCam.CandidateMatineeCommentPrefix = ShooterState.GetMyTemplate().strTargetingMatineePrefix;
		ShooterCam.ShouldBlend = true;
		ShooterCam.ShouldHideUI = true;
		ShooterCam.SetTarget(XGUnit(History.GetVisualizer(NewReactionFire.TargetObjectID)));

		NewReactionFire.ShooterCam = ShooterCam;
	}


	ReactionFireInstances.AddItem(NewReactionFire);

	if(ReactionFireCount == 1)
	{		
		TargetState = XComGameState_Unit(History.GetGameStateForObjectID(NewReactionFire.TargetObjectID));

		TargetCam = new class'X2Camera_OTSReactionFireTarget';
		TargetCam.FiringUnit = XGUnit(History.GetVisualizer(NewReactionFire.TargetObjectID));
		TargetCam.CandidateMatineeCommentPrefix = TargetState.GetMyTemplate().strTargetingMatineePrefix;
		TargetCam.ShouldBlend = true;
		TargetCam.ShouldHideUI = true;
		TargetCam.SetTarget(XGUnit(ShooterState.GetVisualizer()));

		StartReactionFireSequence(FiringAbilityContext);
		ShowReactionFireInstance(FiringAbilityContext); //If this is the first instance, kick it off right away
	}
}

function PopReactionFire(XComGameStateContext_Ability FiringAbilityContext)
{
	local int Index;	

	if( ReactionFireCount > 0 )
	{
		--ReactionFireCount;

		for( Index = 0; Index < ReactionFireInstances.Length; ++Index )
		{
			if( ReactionFireInstances[Index].ShooterObjectID == FiringAbilityContext.InputContext.SourceObject.ObjectID &&
			   ReactionFireInstances[Index].TargetObjectID == FiringAbilityContext.InputContext.PrimaryTarget.ObjectID )
			{
				ReactionFireInstances[Index].bStarted = true; //Mark as shown even though we were skipped. Maybe warn on this?
				ReactionFireInstances[Index].bReadyForNext = true; //Mark as shown even though we were skipped. Maybe warn on this?

				//If we're the last reaction fire, then we can pop the camera. Otherwise wait for the next push
				if( Index == (ReactionFireInstances.Length - 1) )
				{
					`CAMERASTACK.RemoveCamera(ReactionFireInstances[Index].ShooterCam);
				}
			}
		}

		if( ReactionFireCount <= 0 )
		{
			ReactionFireInstances.Length = 0;
			EndReactionFireSequence(FiringAbilityContext);
		}
	}
}

private function ShowReactionFireInstance(XComGameStateContext_Ability FiringAbilityContext)
{
	local X2Camera_OTSReactionFireShooter ShooterCam;
	local int Index;

	for(Index = 0; Index < ReactionFireInstances.Length; ++Index)
	{
		if(ReactionFireInstances[Index].ShooterObjectID == FiringAbilityContext.InputContext.SourceObject.ObjectID &&
		   ReactionFireInstances[Index].TargetObjectID == FiringAbilityContext.InputContext.PrimaryTarget.ObjectID &&
		   !ReactionFireInstances[Index].bReadyForNext ) //Don't admit shooters that have already gone ( some abilities let a shooter take multiple shots ).
		{	
			ReactionFireInstances[Index].bStarted = true;
			
			AddedCameras.AddItem(ReactionFireInstances[Index].ShooterCam);
			`CAMERASTACK.AddCamera(ReactionFireInstances[Index].ShooterCam);

			//If the interrupting shooter was involved in an interrupted action, they may have been time-dilated.
			//Un-dilate them so they can shoot.
			ShooterCam = X2Camera_OTSReactionFireShooter(ReactionFireInstances[Index].ShooterCam);
			if (ShooterCam != None)
			{
				if (ShooterCam.FiringUnit.CustomTimeDilation < 1.0)
				{
					ShooterCam.FiringUnit.SetTimeDilation(1.0);
				}
			}

			if(Index > 0)
			{
				`CAMERASTACK.RemoveCamera(ReactionFireInstances[Index - 1].ShooterCam);
			}
		}
	}
}

function MarkReactionFireInstanceDone(XComGameStateContext_Ability FiringAbilityContext)
{
	local int Index;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameStateContext_Ability OutNextReactionFire;
	local int NextReactionFireRunIndex;

	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	for(Index = 0; Index < ReactionFireInstances.Length; ++Index)
	{
		if(ReactionFireInstances[Index].ShooterObjectID == FiringAbilityContext.InputContext.SourceObject.ObjectID &&
		   ReactionFireInstances[Index].TargetObjectID == FiringAbilityContext.InputContext.PrimaryTarget.ObjectID)
		{
			ReactionFireInstances[Index].bReadyForNext = true;

			//Only do this if there is more reaction fire waiting
			if(GetNumRemainingReactionFires(FiringAbilityContext, OutNextReactionFire) > 0)
			{
				NextReactionFireRunIndex = OutNextReactionFire.VisualizationStartIndex == -1 ? (OutNextReactionFire.AssociatedState.HistoryIndex - 1) : OutNextReactionFire.VisualizationStartIndex;
				VisualizationMgr.ManualPermitNextVisualizationBlockToRun(NextReactionFireRunIndex);
			}
		}
	}
}

function bool AttemptStartReactionFire(X2Action_ExitCover ExitCoverAction)
{
	local int Index;

	if(ReactionFireInstances.Length == 0)
	{
		return true; //Something has gone wrong, abort
	}

	if(ReactionFireInstances[0].ExitCoverAction == ExitCoverAction &&
	   ReactionFireInstances[0].bStarted)
	{
		return true; //The party has already begun
	}

	for(Index = 1; Index < ReactionFireInstances.Length; ++Index)
	{
		if(Index > 0 && !ReactionFireInstances[Index - 1].bReadyForNext)
		{
			break;
		}		

		if(ReactionFireInstances[Index].ExitCoverAction == ExitCoverAction &&
		   !ReactionFireInstances[Index].bStarted)
		{
			ShowReactionFireInstance(ExitCoverAction.AbilityContext);
			return true;
		}
	}

	return false;
}

/// <summary>
/// Called when an active visualization block is marked complete 
/// </summary>
event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{

}

/// <summary>
/// Called when the visualizer runs out of active and pending blocks, and becomes idle
/// </summary>
event OnVisualizationIdle()
{
	//Failsafe check. If ReactionFireCount is non-zero here, it means that something weird happened - and as a result 
	//the reaction fire sequencer got stuck on. This should have been caught by IsReactionFire, but this failsafe will handled it either way.
	if (ReactionFireCount > 0)
	{	
		EndReactionFireSequence(none);
		ReactionFireCount = 0;
		ReactionFireInstances.Length = 0;
	}
}

/// <summary>
/// Called when the active unit selection changes
/// </summary>
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{

}

defaultproperties
{
	SlomoStartSound = AkEvent'SoundTacticalUI.TacticalUI_SlowMo_Start'
	SlomoStopSound = AkEvent'SoundTacticalUI.TacticalUI_SlowMo_Stop'
	ReactionFireTargetSloMoRate = 0.2
}