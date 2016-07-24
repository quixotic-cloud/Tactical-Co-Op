//---------------------------------------------------------------------------------------
//  FILE:    XComTutorialMgr.uc
//  AUTHOR:  Casey O'Toole  --  3/16/2015 - I has returned
//
//  PURPOSE: Tutorial replay
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComTutorialMgr extends XComReplayMgr 
	implements(X2VisualizationMgrObserverInterfaceNative)
	native(Core)
	config(GameCore);

`define INVALID_SUBMISSION_MAX (2)
`define NUM_WAYPOINT_COMPONENTS (2)

var private const config bool UseTurnBeginCameraPrompt; // at the start of a player's turn, should we autofocus on the ability target/destination?
var private const config bool UseTurnBeginTargetPrompt; // at the start of a player's turn, should we autoshow the ability target visual?

var int NextPlayerInputFrame; // Used/Set inside of state PlayUntilPlayerInputRequired

var protected string DestinationMarkerMeshPath;
var protected string GrenadeTargetMeshPath;
var protected string TargetArrowMeshPath;
var protected string WaypointMarkerMeshPath;
var protected string EvacMarkerMeshPath;

var StaticMeshComponent MeshComp;
var StaticMeshComponent WayPointMeshComp[2];
var StaticMeshComponent GenadeTargetMeshComp;
var StaticMeshComponent TargetArrowMeshComp;
var StaticMeshComponent EvacMarkerMeshComp;

var int InvalidSubmissionCnt;

var vector vCurrentLookAtFocusPoint;  // When the current ability is setup, or when the user has invalidly submitted a couple times, look at this point for a couple seconds
var const vector vInvalidLookAt;

var XComGameStateContext_Ability NextPlayerAbilityContext; // This is the ability context we are waiting for player input for

var bool bDemoMode; // If true, tutorial doesn't not draw move/target markers

simulated event PostBeginPlay()
{
	local int i;
	local StaticMesh TargetMesh;

	super.PostBeginPlay();

	// Init Destination mesh comp
	TargetMesh = StaticMesh(`CONTENT.RequestGameArchetype(default.DestinationMarkerMeshPath));
	`assert(TargetMesh != none);
	MeshComp.SetStaticMesh(TargetMesh);
	MeshComp.SetHidden(true);
	MeshComp.SetActorCollision(false, false, false);

	// Init waypoint mesh comps
	TargetMesh = StaticMesh(`CONTENT.RequestGameArchetype(default.WaypointMarkerMeshPath));
	for (i = 0; i < `NUM_WAYPOINT_COMPONENTS; i++)
	{
		WayPointMeshComp[i].SetStaticMesh(TargetMesh);
		WayPointMeshComp[i].SetHidden(true);
	}

	// Init Grenade Mesh comp
	TargetMesh = StaticMesh(`CONTENT.RequestGameArchetype(default.GrenadeTargetMeshPath));
	GenadeTargetMeshComp.SetStaticMesh(TargetMesh);
	GenadeTargetMeshComp.SetHidden(true);
	
	// Init target arrow mesh comp
	TargetMesh = StaticMesh(`CONTENT.RequestGameArchetype(default.TargetArrowMeshPath));
	TargetArrowMeshComp.SetStaticMesh(TargetMesh);
	TargetArrowMeshComp.SetHidden(true);

	// Init target arrow mesh comp
	TargetMesh = StaticMesh(`CONTENT.RequestGameArchetype(default.EvacMarkerMeshPath));
	EvacMarkerMeshComp.SetStaticMesh(TargetMesh);
	EvacMarkerMeshComp.SetHidden(true);
	
}

simulated event StartReplay(int SessionStartStateIndex)
{
	local int TutorialStartFrame;

	super.StartReplay(SessionStartStateIndex);

	// Start at the frame indicated by a DemoStart game rule, otherwise returns -1
	TutorialStartFrame = FindDemoStartFrame();

	if (TutorialStartFrame < 0)
	{
		// If we did not find a demo start frame, start off at the first frame requiring player input
		TutorialStartFrame = FindNextFrameRequiringPlayerInput() - 1;
	}

	//TutorialStartFrame = 344;// 1745;// 55;//300;//150;  // My way of quickly starting at an advanced frame when I need to

	JumpReplayToFrame(TutorialStartFrame);

	ToggleUI();

	`PRES.m_kUnitFlagManager.Show();

	// add our listener on the visualization manager so we can check for end of battle after each visualization
	// idle
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

//This function is called continuously on a timer and passes through once the game is no longer playing a movie
function StartDemoSequenceDeferred()
{
	if(class'XComEngine'.static.IsAnyMoviePlaying())
	{
		SetTimer(0.1f, false, nameof(StartDemoSequenceDeferred));
	}
	else
	{
		GotoState('PlayUntilPlayerInputRequired');
	}
}

simulated function bool IsNextAbility(name TemplateName)
{
	if (bDemoMode || NextPlayerAbilityContext == none)
		return false;

	return TemplateName == NextPlayerAbilityContext.InputContext.AbilityTemplateName;
}

simulated function bool IsTarget(int ObjectID)
{
	if (bDemoMode || NextPlayerAbilityContext == none)
		return false;

	return NextPlayerAbilityContext.InputContext.PrimaryTarget.ObjectID == ObjectID;
}

simulated function ToggleDemoMode()
{
	bDemoMode = !bDemoMode;

	if (bDemoMode)
	{
		ClearMoveMarkers();
		ClearTargetLocationMarkers();
	}
	else
	{
		SetMoveMarkers();
		SetTargetLocationMarkers();
	}
}

simulated function bool HandleSubmittedGameStateContext(XComGameStateContext SubmittedContext)
{
	//Check for cheat victory
	if(`CHEATMGR != none && `CHEATMGR.bSimulatingCombat) //The player won by using the simcombat cheat ( performs its own end battle call )
	{
		bInReplay = false; //We're not replaying anymore, end the battle		
		`TACTICALRULES.SubmitGameStateContext(SubmittedContext);
		`TACTICALRULES.GotoState('EndTacticalGame');
		return true;
	}

	// We're not waiting for playing input yet, so just return false, possible fix for tutorial hang when rapidly clicking move target
	return false;
}

function bool ValidateTargets(XComGameStateContext_Ability AbilityContext1, XComGameStateContext_Ability AbilityContext2)
{
	local int i;
	local Vector vDiff;
	local float fLength;

	// It doesnt matter which abilitycontext we use at this point as we have already validated they are the same template
	if (AbilityContext1.InputContext.PrimaryTarget.ObjectID > 0)
	{
		if(AbilityContext1.InputContext.PrimaryTarget != AbilityContext2.InputContext.PrimaryTarget)
		{
			return false;
		}
	}
	else
	{
		if (AbilityContext1.InputContext.TargetLocations.Length != AbilityContext2.InputContext.TargetLocations.Length)
		{
			return false;
		}
		else
		{
			for (i = 0; i < AbilityContext1.InputContext.TargetLocations.Length; i++)
			{
				vDiff = AbilityContext1.InputContext.TargetLocations[i] - AbilityContext2.InputContext.TargetLocations[i];
				fLength = VSize(vDiff);

				if (fLength > class'XComWorldData'.const.WORLD_StepSize)
				{
					return false;
				}
			}
		}
	}

	return true;
}

function HandleTooManyInvalidSubmissions(XComGameStateContext_Ability AbilityContext)
{
	// If the user clicked an invalid location too many times, focus the camera on the destination again
	if (vCurrentLookAtFocusPoint != vInvalidLookAt)
	{
		if (!`CAMERASTACK.ContainsCameraOfClass('X2Camera_LookAtLocationTimed'))
		{
			DoTimedFocusOnTargetPoint();
		}
	}
}

function bool ValidateMovement(XComGameStateContext_Ability AbilityContext1, XComGameStateContext_Ability AbilityContext2)
{
	local int i;
	local TTile DestTile1;
	local TTile DestTile2;
	
	// MovingSwordSlice movementtiles off by 1 in length, so just check the waypoint tiles in this case
	if (AbilityContext2.InputContext.AbilityTemplateName == class'X2Ability_RangerAbilitySet'.default.SwordSliceName)
	{
		if(AbilityContext1.InputContext.MovementPaths[0].WaypointTiles.Length == AbilityContext2.InputContext.MovementPaths[0].WaypointTiles.Length)
		{
			return true;
		}
	}

	if(AbilityContext1.InputContext.MovementPaths[0].MovementTiles.Length == 0 && AbilityContext2.InputContext.MovementPaths[0].MovementTiles.Length == 0)
		return true;


	// Check destination
	if(AbilityContext1.InputContext.MovementPaths[0].MovementTiles.Length > 0 && AbilityContext2.InputContext.MovementPaths[0].MovementTiles.Length > 0)
	{
		DestTile1 = AbilityContext1.InputContext.MovementPaths[0].MovementTiles[AbilityContext1.InputContext.MovementPaths[0].MovementTiles.Length - 1];
		DestTile2 = AbilityContext2.InputContext.MovementPaths[0].MovementTiles[AbilityContext2.InputContext.MovementPaths[0].MovementTiles.Length - 1];

		if (DestTile1 == DestTile2)
		{
			// Check waypoints
			if(AbilityContext1.InputContext.MovementPaths[0].WaypointTiles.Length == AbilityContext2.InputContext.MovementPaths[0].WaypointTiles.Length)
			{
				for(i = 0; i < AbilityContext1.InputContext.MovementPaths[0].WaypointTiles.Length; i++)
				{
					if(AbilityContext1.InputContext.MovementPaths[0].WaypointTiles[i] != AbilityContext2.InputContext.MovementPaths[0].WaypointTiles[i])
					{
						return false;
					}
				}
				return true;
			}
		}
	}
	else
	{
		return false;
	}

	return false;
}

function bool MovementTilesAreEqual(array<TTile> Tile1, array<TTile> Tile2)
{
	local int i;

	if (Tile1.Length != Tile2.Length)
		return false;

	for (i = 0; i < Tile1.Length; i++)
	{
		if (Tile1[i] != Tile2[i])
			return false;
	}

	return true;
}

function SetupForPlayerInputUsingFrame(int FrameToUse)
{
	local XComGameStateHistory History;
	local XComTacticalController TacticalController;

	History = `XCOMHISTORY;
	TacticalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());	

	if (NextPlayerAbilityContext != none)
	{
		`TACTICALRULES.EndReplay();	
		TacticalController.Visualizer_SelectUnit(XComGameState_Unit(History.GetGameStateForObjectID(NextPlayerAbilityContext.InputContext.SourceObject.ObjectID)));
		TacticalController.SetInputState('ActiveUnit_Moving');
	
		if(UseTurnBeginTargetPrompt)
		{
			SetMoveMarkers();
			SetTargetLocationMarkers();
		}

		if (vCurrentLookAtFocusPoint != vInvalidLookAt && UseTurnBeginCameraPrompt)
		{
			SetTimer(0.5f, false, 'DoTimedFocusOnTargetPoint');
		}

		// Put the next frame into the UI box so we can see what we are supposed to be doing
		UpdateUIWithFrame(NextPlayerAbilityContext.AssociatedState.HistoryIndex);
	}

}


// Grenade target locations
function SetTargetLocationMarkers()
{
	local X2AbilityTemplate AbilityTemplate;
	local Vector vPos;
	local XComGameState_Unit GSUnit;
	local TTile Tile;

	// Early out if we are in demo mode
	if (bDemoMode)
		return;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(NextPlayerAbilityContext.InputContext.AbilityTemplateName);

	switch (AbilityTemplate.TargetingMethod)
	{
		case class'X2TargetingMethod_Grenade':
			if (NextPlayerAbilityContext.InputContext.TargetLocations.Length > 0) // Just going to draw 1 Target Location, will implement more if necessary
			{
				GenadeTargetMeshComp.SetHidden(false);
				GenadeTargetMeshComp.SetTranslation(NextPlayerAbilityContext.InputContext.TargetLocations[0] + vect(0, 0, 4));
				vCurrentLookAtFocusPoint = GenadeTargetMeshComp.Translation;		
			}
			break;
		case class'X2TargetingMethod_OverTheShoulder':
			if (NextPlayerAbilityContext.InputContext.PrimaryTarget.ObjectID != 0)
			{
				GSUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(NextPlayerAbilityContext.InputContext.PrimaryTarget.ObjectID));
				if (GSUnit != none)
				{
					vPos = `XWORLD.GetPositionFromTileCoordinates(GSUnit.TileLocation);
					vCurrentLookAtFocusPoint = vPos;
					TargetArrowMeshComp.SetTranslation(vCurrentLookAtFocusPoint + vect(0, 0, 200));
					TargetArrowMeshComp.SetRotation(rot(0, 16384, -16384));
					TargetArrowMeshComp.SetHidden(false);
				}
			}
			break;
		case class'X2TargetingMethod_EvacZone':
			if (NextPlayerAbilityContext.InputContext.TargetLocations.Length > 0)
			{
				// Convert position to Tile, then back to Vector
				vPos = NextPlayerAbilityContext.InputContext.TargetLocations[0];
				Tile = `XWORLD.GetTileCoordinatesFromPosition(vPos);
				vPos = `XWORLD.GetPositionFromTileCoordinates(Tile);

				EvacMarkerMeshComp.SetHidden(false);
				EvacMarkerMeshComp.SetTranslation(vPos + vect(0, 0, -44));
				//EvacMarkerMeshComp.SetScale3D(vect(1.0f, 1.0f, 0.33f));
				vCurrentLookAtFocusPoint = EvacMarkerMeshComp.Translation;
			}
			break;
	};
}

function ClearTargetLocationMarkers()
{
	GenadeTargetMeshComp.SetHidden(true);
	TargetArrowMeshComp.SetHidden(true);
	EvacMarkerMeshComp.SetHidden(true);
}

function SetMoveMarkers()
{
	local XComWorldData WorldData;
	Local int i;
	local int Index;
	local Vector vPos;
	local TTile Tile;

	// Early out if we are in demo mode
	if (bDemoMode)
		return;

	WorldData = `XWORLD;

	if (NextPlayerAbilityContext.InputContext.MovementPaths[0].MovementTiles.Length > 0)
	{
		Index = NextPlayerAbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1;
		MeshComp.SetHidden(false);

		vPos = NextPlayerAbilityContext.InputContext.MovementPaths[0].MovementData[Index].Position;
		vPos.Z = WorldData.GetFloorZForPosition(vPos) + class'XComPathingPawn'.default.PathHeightOffset;
		MeshComp.SetTranslation(vPos);
		vCurrentLookAtFocusPoint = MeshComp.Translation;

		for (i = 0; i < NextPlayerAbilityContext.InputContext.MovementPaths[0].WaypointTiles.Length && i < `NUM_WAYPOINT_COMPONENTS; i++)
		{
			Tile = NextPlayerAbilityContext.InputContext.MovementPaths[0].WaypointTiles[i];
			if(!WorldData.GetFloorPositionForTile(Tile, vPos))
			{
				// as a fallback, just stick it at the center of the tile
				vPos = WorldData.GetPositionFromTileCoordinates(Tile);
			}
			else
			{
				vPos.Z += class'XComPathingPawn'.default.PathHeightOffset;
			}

			WayPointMeshComp[i].SetHidden(false);
			WayPointMeshComp[i].SetTranslation(vPos);
			//WayPointMeshComp[i].SetScale3D(vect(0.33f, 0.33f, 0.33f));
		}
	}
}

function DoTimedFocusOnTargetPoint()
{
	local X2Camera_LookAtLocationTimed CameraTimed;

	// Early out if we are in demo mode
	if (bDemoMode)
		return;

	CameraTimed = new class'X2Camera_LookAtLocationTimed';
	CameraTimed.LookAtLocation = vCurrentLookAtFocusPoint;
	CameraTimed.LookAtLocation.Z = `CURSOR.m_fLogicalCameraFloorHeight;
	CameraTimed.LookAtDuration = 1.0f;
	CameraTimed.TetherScreenPercentage = 0.5f;
	`CAMERASTACK.AddCamera(CameraTimed);
}

function ClearMoveMarkers()
{
	local int i;

	MeshComp.SetHidden(true);

	for (i = 0; i < `NUM_WAYPOINT_COMPONENTS; i++)
	{
		WayPointMeshComp[i].SetHidden(true);
	}
}

function int FindDemoStartFrame()
{
	local XComGameStateHistory History;
	local XComGameState NextGameState;
	local XComGameStateContext_TacticalGameRule GameRuleContext;
	local int FrameResult;

	History = `XCOMHISTORY;

	FrameResult = CurrentHistoryFrame;

	do
	{
		FrameResult++;

		NextGameState = History.GetGameStateFromHistory(FrameResult);

		GameRuleContext = XComGameStateContext_TacticalGameRule(NextGameState.GetContext());

		if (GameRuleContext != none)
		{
			if (GameRuleContext.GameRuleType == eGameRule_DemoStart)
			{
				return FrameResult;
			}
		}

	} until(FrameResult >= (History.GetNumGameStates() - 1));


	return -1;
}

function int FindNextFrameRequiringPlayerInput()
{
	local XComGameStateHistory History;
	local XComGameState NextGameState;	
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit GameStateUnit;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local int FrameResult;
	local bool bAbilityFromPlayerInput;
	local bool bGameStateUnitIsNotAI;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	History = `XCOMHISTORY;

	FrameResult = CurrentHistoryFrame;

	do
	{
		bAbilityFromPlayerInput = false;
		bGameStateUnitIsNotAI = false;

		FrameResult++;

		NextGameState = History.GetGameStateFromHistory(FrameResult);

		AbilityContext = XComGameStateContext_Ability(NextGameState.GetContext());

		if (AbilityContext != none)
		{
			// grab the unit as it existed at this point in the history. It's possible it has switched teams throughout the game.
			GameStateUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID,, NextGameState.HistoryIndex));
	
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

			if (GameStateUnit != none)
			{
				bGameStateUnitIsNotAI = !GameStateUnit.ControllingPlayerIsAI() && GameStateUnit.GetTeam() == eTeam_XCom;
			}

			if (AbilityTemplate != none)
			{
				bAbilityFromPlayerInput = AbilityTemplateHasPlayerInputTrigger(AbilityTemplate);
			}
			
		}

	} until(bGameStateUnitIsNotAI && bAbilityFromPlayerInput || FrameResult >= (History.GetNumGameStates() - 1));

	NextPlayerAbilityContext = NextGameState != none ? XComGameStateContext_Ability(NextGameState.GetContext()) : none;

	return FrameResult;
}

function bool AbilityTemplateHasPlayerInputTrigger(X2AbilityTemplate AbilityTemplate)
{
	local int i;

	// Hack in support for ignoring knockout self
	if (AbilityTemplate.DataName == 'KnockoutSelf')
		return false;

	for (i = 0; i < AbilityTemplate.AbilityTriggers.Length; i++)
	{
		if (AbilityTemplate.AbilityTriggers[i].IsA('X2AbilityTrigger_PlayerInput'))
		{
			return true;
		}
	}
	
	return false;
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle()
{
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameStateContext_TacticalGameRule Context;
	local XComGameStateHistory History;

	// check if we have visualized the end of battle context. If so, the replay is now complete
	Context = XComGameStateContext_TacticalGameRule(AssociatedGameState.GetContext());
	if(Context != none && Context.GameRuleType == eGameRule_TacticalGameEnd) 
	{
		// jump to the end of the replay. There could be states after the end of game state, and
		// the systems that setup the strategy start state will explode if we aren't at the end, since they assume
		// tactical missions always stop at the end
		History = `XCOMHISTORY;
		History.SetCurrentHistoryIndex(-1); // exit replay mode history tracking, -1 indicates we should always stay at the end of the history

		`XCOMVISUALIZATIONMGR.RemoveObserver(self);
		`TACTICALRULES.GotoState('EndTacticalGame');
		bInReplay = false; // need to set after having the ruleset end the game, so it can do replay specific shutdown stuff
	}
}

// This state should always be pushed, never use gotostate to go here
state WaitForVisualizers
{
	event Tick(float DeltaTime)
	{
		if (!class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
		{
			PopState();
		}
	}
Begin:
}

state PlayUntilPlayerInputRequired
{
	event BeginState(Name PreviousStateName)
	{
		NextPlayerInputFrame = FindNextFrameRequiringPlayerInput();

		// Must set this otherwise SteppingForward might step just a tad too far because it steps past things that don't
		// have visualization, etc.
		StepForwardStopFrame = NextPlayerInputFrame - 1;
	}

	event Tick(float DeltaTime)
	{
		if (CurrentHistoryFrame < NextPlayerInputFrame - 1)
		{
			//if (!class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
			//{
				StepReplayForward();
				UpdateUIWithFrame(CurrentHistoryFrame);
			//}
		}
		else if (!class'XComGameStateVisualizationMgr'.static.VisualizerBusy())
		{
			GotoState('WaitForPlayerInput');
		}
	}

Begin:
}

state WaitForPlayerInput
{
	simulated function bool HandleSubmittedGameStateContext(XComGameStateContext SubmittedContext)
	{
		local XComGameStateHistory History;
		local XComGameStateContext Context;
		local XComGameStateContext_Ability AbilityContext;
		local XComGameStateContext_Ability SubmittedAbilityContext;
		local XComGameState GameState;
		local XComGameStateContext_TacticalGameRule EndTurnContext;

		local bool bTargetsValidationPassed;
		local bool bMovementValidationPassed;

		History = `XCOMHISTORY;

			//Check for cheat victory
		if (`CHEATMGR != none && `CHEATMGR.bSimulatingCombat) //The player won by using the simcombat cheat ( performs its own end battle call )
		{
			bInReplay = false; //We're not replaying anymore, end the battle		
			`TACTICALRULES.SubmitGameStateContext(SubmittedContext);
			`TACTICALRULES.GotoState('EndTacticalGame');
			return true;
		}

		GameState = History.GetGameStateFromHistory(CurrentHistoryFrame + 1);
		Context = GameState.GetContext();
		AbilityContext = XComGameStateContext_Ability(Context);
		SubmittedAbilityContext = XComGameStateContext_Ability(SubmittedContext);

		if (SubmittedAbilityContext != none)
		{
			if (AbilityContext.InputContext.AbilityTemplateName == SubmittedAbilityContext.InputContext.AbilityTemplateName)
			{
				bTargetsValidationPassed = ValidateTargets(AbilityContext, SubmittedAbilityContext);
				bMovementValidationPassed = ValidateMovement(AbilityContext, SubmittedAbilityContext);

				if (bTargetsValidationPassed && bMovementValidationPassed)
				{
					ClearMoveMarkers();
					ClearTargetLocationMarkers();

					`TACTICALRULES.ResumeReplay();
					StepReplayForward();
					UpdateUIWithFrame(CurrentHistoryFrame);

					GotoState('PlayUntilPlayerInputRequired');
					InvalidSubmissionCnt = 0;
					vCurrentLookAtFocusPoint = vInvalidLookAt;

					`PRES.GetWorldMessenger().RemoveAllBladeMessages(); // clear all tutorial blades

					return true;
				}
			}
		}

		InvalidSubmissionCnt++;

		if (InvalidSubmissionCnt > `INVALID_SUBMISSION_MAX)
		{
			HandleTooManyInvalidSubmissions(AbilityContext);
			InvalidSubmissionCnt = 0;
		}


		// If we get here, it's likely due to bad input.  Check and play audio only when appropriate.
		EndTurnContext = XComGameStateContext_TacticalGameRule(SubmittedContext);
		if (EndTurnContext == None || EndTurnContext.GameRuleType != eGameRule_PlayerTurnBegin )
		{
			`PRES.PlayUISound(eSUISound_MenuClickNegative);
		}

		return false;
	}

Begin:
	PushState('WaitForVisualizers');
	
	// Set the stop frame back to the end of the replay
	StepForwardStopFrame = (`XCOMHISTORY.GetNumGameStates() - 1);

	SetupForPlayerInputUsingFrame(CurrentHistoryFrame + 1);
}

defaultproperties
{
	bInTutorial = true

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		bOwnerNoSee = FALSE
		CastShadow = FALSE
		CollideActors = FALSE
		BlockActors = FALSE
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
		BlockRigidBody = FALSE
		HiddenGame = FALSE
	End Object
	MeshComp = StaticMeshComponent0
	Components.Add(StaticMeshComponent0)

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent1
		bOwnerNoSee = FALSE
		CastShadow = FALSE
		CollideActors = FALSE
		BlockActors = FALSE
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
		BlockRigidBody = FALSE
		HiddenGame = FALSE
	End Object
	WayPointMeshComp[0] = StaticMeshComponent1
	Components.Add(StaticMeshComponent1)

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent2
		bOwnerNoSee = FALSE
		CastShadow = FALSE
		CollideActors = FALSE
		BlockActors = FALSE
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
		BlockRigidBody = FALSE
		HiddenGame = FALSE
	End Object
	WayPointMeshComp[1] = StaticMeshComponent2
	Components.Add(StaticMeshComponent2)

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent3
		bOwnerNoSee = FALSE
		CastShadow = FALSE
		CollideActors = FALSE
		BlockActors = FALSE
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
		BlockRigidBody = FALSE
		HiddenGame = FALSE
	End Object
	GenadeTargetMeshComp = StaticMeshComponent3
	Components.Add(StaticMeshComponent3)

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent4
		bOwnerNoSee = FALSE
		CastShadow = FALSE
		CollideActors = FALSE
		BlockActors = FALSE
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
		BlockRigidBody = FALSE
		HiddenGame = FALSE
	End Object
	TargetArrowMeshComp = StaticMeshComponent4
	Components.Add(StaticMeshComponent4)

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent5
		bOwnerNoSee = FALSE
		CastShadow = FALSE
		CollideActors = FALSE
		BlockActors = FALSE
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
		BlockRigidBody = FALSE
		HiddenGame = FALSE
	End Object
	EvacMarkerMeshComp = StaticMeshComponent5
	Components.Add(StaticMeshComponent5)

	bStatic = FALSE
	bWorldGeometry = FALSE
	bMovable = TRUE

	DestinationMarkerMeshPath = "UI_3D.Waypoint.GoHere_Destination"//"UI_3D.Unit.SlelectionBox"
	WaypointMarkerMeshPath = "UI_3D.Waypoint.GoHere_Waypoint"
	GrenadeTargetMeshPath = "UI_3D.Range.TutGrenadeTarget"
	TargetArrowMeshPath = "UI_3D.Range.TutShootTarget"
	EvacMarkerMeshPath = "UI_3D.Evacuation.EvacLocation"

	vInvalidLookAt = (X=-9999,Y=-9999, Z=-9999)
};