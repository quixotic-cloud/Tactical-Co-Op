// This is an Unreal Script
                           
Class X2Ability_DefaultAbilitySet_CoOpHackFix extends X2Ability_DefaultAbilitySet;

var array<name> ChangedAbilities;

simulated static function FixHackingAbilities()
{
	local X2AbilityTemplateManager ATM;
	local X2AbilityTemplate TempAbilityTemplate;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_Fix_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('FinalizeHack');
	TempAbilityTemplate.BuildVisualizationFn=FinalizeHackAbility_Fix_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_Chest');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_Fix_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_Workstation');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_Fix_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_ObjectiveChest');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_Fix_BuildVisualization;

	`log('Fixed All Hacking Abilities',,'Dragonpunk Co Op Hack Fix');
}

simulated static function FixLootAbilities()
{
	local X2AbilityTemplateManager ATM;
	local X2AbilityTemplate TempAbilityTemplate;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Loot');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); //Allow looting in coop
	
}

simulated static function UnFixHackingAbilities()
{
	local X2AbilityTemplateManager ATM;
	local X2AbilityTemplate TempAbilityTemplate;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('FinalizeHack');
	TempAbilityTemplate.BuildVisualizationFn=FinalizeHackAbility_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_Chest');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_Workstation');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_BuildVisualization;

	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_ObjectiveChest');
	TempAbilityTemplate.BuildVisualizationFn=HackAbility_BuildVisualization;
}

simulated static function UnFixLootAbilities()
{
	local X2AbilityTemplateManager ATM;
	local X2AbilityTemplate TempAbilityTemplate;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Loot');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Looting" in MP!
	
}

simulated static function FixAllMPAbilities()
{
	local X2AbilityTemplateManager ATM;
	local X2AbilityTemplate TempAbilityTemplate;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Loot');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); //Allow looting in coop

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('AbortMission');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('PlaceEvacZone');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('CarryUnit');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
	
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Evac');
	if(TempAbilityTemplate!=none)
	{
		TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		TempAbilityTemplate.bAllowedByDefault = true;
		TempAbilityTemplate.HideErrors.Length = 0;
		TempAbilityTemplate.AbilityEventListeners.Length = 0;
		TempAbilityTemplate.AbilityShooterConditions.Length = 0;
		TempAbilityTemplate.AbilityShooterConditions.AddItem(new class'X2Condition_UnitInEvacZone');
	}
	
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Interact_ActivateSpark');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_ElevatorControl');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Interact_AtmosphereComputer');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Interact_UseElevator');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
			
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('IntrusionProtocol_Hack_ElevatorControl');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
	

}

simulated static function UnFixAllMPAbilities()
{
	local X2AbilityTemplateManager ATM;
	local X2Condition_UnitValue UnitValue;
	local array<name> SkipExclusions;
	local X2Condition_UnitProperty UnitProperty;
	local X2AbilityTemplate TempAbilityTemplate;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Loot');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Looting" in MP!
	
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('AbortMission');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('PlaceEvacZone');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('CarryUnit');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
	
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Evac');
	if(TempAbilityTemplate!=none)
	{
		TempAbilityTemplate.HideErrors.Length = 0;
		TempAbilityTemplate.AbilityEventListeners.Length = 0;
		TempAbilityTemplate.AbilityShooterConditions.Length = 0;

		TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		TempAbilityTemplate.bAllowedByDefault = false;
		TempAbilityTemplate.HideErrors.AddItem('AA_AbilityUnavailable');

		TempAbilityTemplate.AddAbilityEventListener('EvacActivated', class'XComGameState_Ability'.static.EvacActivated, ELD_OnStateSubmitted);

		UnitValue = new class'X2Condition_UnitValue';
		UnitValue.AddCheckValue(default.EvacThisTurnName, default.MAX_EVAC_PER_TURN, eCheck_LessThan);
		TempAbilityTemplate.AbilityShooterConditions.AddItem(UnitValue);

		TempAbilityTemplate.AbilityShooterConditions.AddItem(new class'X2Condition_UnitInEvacZone');
	
		UnitProperty = new class'X2Condition_UnitProperty';
		UnitProperty.ExcludeDead = true;
		UnitProperty.ExcludeFriendlyToSource = false;
		UnitProperty.ExcludeHostileToSource = true;
		//UnitProperty.IsOutdoors = true;           //  evac zone will take care of this now
		TempAbilityTemplate.AbilityShooterConditions.AddItem(UnitProperty);

		SkipExclusions.AddItem(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
		SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
		SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
		TempAbilityTemplate.AddShooterEffectExclusions(SkipExclusions);

	}
		
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Interact_ActivateSpark');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Hack_ElevatorControl');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Interact_AtmosphereComputer');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
		
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('Interact_UseElevator');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
			
	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	TempAbilityTemplate=ATM.FindAbilityTemplate('IntrusionProtocol_Hack_ElevatorControl');
	if(TempAbilityTemplate!=none) TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 

}



simulated static function FixAllAbilitiesToCOOP()
{
	local X2AbilityTemplateManager ATM;
	local X2AbilityTemplate TempAbilityTemplate;
	local X2DataTemplate TempDataTemplate;
	local array<name> TempArray;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach ATM.IterateTemplates(TempDataTemplate,none)
	{
		TempAbilityTemplate=X2AbilityTemplate(TempDataTemplate);
		if(	!TempAbilityTemplate.IsTemplateAvailableToAnyArea(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer) )
		{
			TempAbilityTemplate.AddTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer);
			TempArray.addItem(TempAbilityTemplate.DataName);
		}
	}
	X2Ability_DefaultAbilitySet_CoOpHackFix(class'XComEngine'.static.GetClassDefaultObject(class'X2Ability_DefaultAbilitySet_CoOpHackFix')).ChangedAbilities = TempArray;
}

simulated static function UnFixAllAbilitiesToCOOP()
{
	local X2AbilityTemplateManager ATM;
	local X2AbilityTemplate TempAbilityTemplate;
	local name TempAbilityTemplateName;

	ATM=Class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach default.ChangedAbilities(TempAbilityTemplateName)
	{
		TempAbilityTemplate=ATM.FindAbilityTemplate(TempAbilityTemplateName);
		if(TempAbilityTemplate!=none) 
			TempAbilityTemplate.RemoveTemplateAvailablility(TempAbilityTemplate.BITFIELD_GAMEAREA_Multiplayer); 
	}
	X2Ability_DefaultAbilitySet_CoOpHackFix(class'XComEngine'.static.GetClassDefaultObject(class'X2Ability_DefaultAbilitySet_CoOpHackFix')).ChangedAbilities.Length=0;
}
simulated function HackAbility_Fix_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;	
	local XComGameState_Unit SourceUnit;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit TargetUnit;
	local XComGameState_InteractiveObject ObjectState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(InteractingUnitRef.ObjectID));

	TargetState = History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID);
	ObjectState = XComGameState_InteractiveObject(TargetState);
	TargetUnit = XComGameState_Unit(TargetState);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	// Add a soldier bark for the hack attempt.
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
	if (ObjectState != none)
	{
		if( ObjectState.IsDoor() )
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackDoor', eColor_Good);
		}
		else
		{
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackWorkstation', eColor_Good);
		}
	}
	else if (TargetUnit != none)
	{
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackUnit', eColor_Good);
	}
	else
	{
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'AttemptingHack', eColor_Good);
	}

	// Only run the X2Action_hack on the player that is performing the hack.  The other player gets a flyover on the FinalizeHack visualization.
	if( (SourceUnit.ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID()) && IsCurrentlyControlledUnit(SourceUnit) )
	{
		class'X2Action_Hack'.static.AddToVisualizationTrack(BuildTrack, Context);
	}
	
	OutVisualizationTracks.AddItem(BuildTrack);
}

function bool IsCurrentlyControlledUnit(XComGameState_Unit SelectedUnit)
{
	local bool IsActive;
	IsActive = !XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).IsCurrentlyWaiting;

	if(!`XCOMNETMANAGER.HasConnections())
		return true;

	if(IsActive && SelectedUnit.GetTeam()==eTeam_XCom && SelectedUnit.GetMaxStat(eStat_FlightFuel)==10 && `XCOMNETMANAGER.HasClientConnection() ) //Check for client unit when you're not the client
	{
		`log("Used for X2 Hack This is a Client trying to access a client unit with the name:"@SelectedUnit.GetFullName());
		return true;
	}
	if(IsActive && SelectedUnit.GetTeam()==eTeam_XCom && SelectedUnit.GetMaxStat(eStat_FlightFuel)!=10 && `XCOMNETMANAGER.HasServerConnection())
	{
		`log("Used for X2 Hack This is a server trying to access a server unit with the name:"@SelectedUnit.GetFullName());
		return True;
	}
	return false;
}

// Hacking is split into two abilities, "Hack" and "FinalizeHack".
// This function is used for visualizing the second half of the hacking
// process, and is for letting the player know the results of the hack
// attempt.  mdomowicz 2015_06_30
simulated function FinalizeHackAbility_Fix_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference          InteractingUnitRef;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Item ItemState;
	local XComGameState_InteractiveObject ObjectState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	local XComGameState_Unit SourceUnit;
	local String HackText;
	local bool bLocalUnit;
	local array<Name> HackRewards;
	local Hackable HackTarget;
	local X2HackRewardTemplateManager HackMgr;
	local int ChosenHackIndex;
	local X2HackRewardTemplate HackRewardTemplate;
	local EWidgetColor TextColor;
	local XGParamTag kTag;

	History = `XCOMHISTORY;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(InteractingUnitRef.ObjectID));

	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	ObjectState = XComGameState_InteractiveObject(TargetState);
	TargetUnit = XComGameState_Unit(TargetState);
	ItemState = XComGameState_Item( VisualizeGameState.GetGameStateForObjectID( AbilityContext.InputContext.ItemObject.ObjectID ) );

	bLocalUnit = (SourceUnit.ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID()) && IsCurrentlyControlledUnit(SourceUnit);

	if( bLocalUnit )
	{
		if( ObjectState != none )
		{
			if( ObjectState.HasBeenHacked() )
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
				SoundAndFlyOver.BlockUntilFinished = true;
				SoundAndFlyOver.DelayDuration = 1.5f;

				if( ObjectState.IsDoor() )
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackDoorSuccess', eColor_Good);
				}
				else
				{
					// Can't use 'HackWorkstationSuccess', because it doesn't work for Advent Towers
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good);
				}

				if( ItemState.CosmeticUnitRef.ObjectID == 0 )
				{
					// if the hack was successful, we will also interact with it
					class'X2Action_Interact'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);

					// and show any looting we did
					class'X2Action_Loot'.static.AddToVisualizationTrackIfLooted(ObjectState, AbilityContext, BuildTrack);
				}
			}
			else
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackFailed', eColor_Bad);
				SoundAndFlyOver.BlockUntilFinished = true;
				SoundAndFlyOver.DelayDuration = 1.5f;
			}
		}
		else if( TargetUnit != none )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));

			if ( AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLJACK' || AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLMINE' )
			{
				// 'StunnedAlien' and 'AlienNotStunned' VO lines are appropriate for skull jack activation (or failed activation),
				// but there are no good cues for the result.  So we just use the generic cues.
				if( TargetUnit.bHasBeenHacked )
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackFailed', eColor_Bad);
				}
			}
			else if( TargetUnit.IsTurret() )
			{
				if( TargetUnit.bHasBeenHacked )
				{
					// Can't use 'HackTurretSuccess' here because all the VO lines are about taking control of the
					// turret, but sometimes the success result is shutting down the turret instead.
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackTurretFailed', eColor_Bad);
				}
			}
			else
			{
				// If we got here, then the target unit must be a robot...
				if( TargetUnit.bHasBeenHacked )
				{
					// Can't use 'HackUnitSuccess' for the exact same reason we can't use 'HackTurretSuccess' above.
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'GenericHackSuccess', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackUnitFailed', eColor_Bad);
				}
			}

			// This prevents a VO overlap that occurs when using skullmine or skulljack.  mdomowicz 2015_11_18
			if( AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLMINE' || AbilityContext.InputContext.AbilityTemplateName == 'FinalizeSKULLJACK' )
			{
				SoundAndFlyOver.DelayDuration = 1.5f;  // found empirically.
				SoundAndFlyOver.BlockUntilFinished = true;
			}
		}
		else
		{
			`assert(false);
		}
	}
	else
	{
		HackTarget = Hackable(TargetState);
		if( HackTarget != None )
		{
			HackRewards = HackTarget.GetHackRewards(AbilityContext.InputContext.AbilityTemplateName);
			HackMgr = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

			if( !HackTarget.HasBeenHacked() )
			{
				ChosenHackIndex = 0;
				HackText = EnemyHackAttemptFailureString;
				TextColor = eColor_Bad;
			}
			else
			{
				HackText = EnemyHackAttemptSuccessString;
				ChosenHackIndex = HackTarget.GetUserSelectedHackOption();
				TextColor = eColor_Good;
			}
			
			if( ChosenHackIndex >= HackRewards.Length )
			{
				`RedScreen("FinalizeHack Visualization Error- Selected Hack Option >= num hack reward options!  @acheng");
			}
			HackRewardTemplate = HackMgr.FindHackRewardTemplate(HackRewards[ChosenHackIndex]);

			kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			kTag.StrValue0 = HackRewardTemplate.GetFriendlyName();
			
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, `XEXPAND.ExpandString(HackText), '', TextColor);
		}
	}


	OutVisualizationTracks.AddItem(BuildTrack);
}