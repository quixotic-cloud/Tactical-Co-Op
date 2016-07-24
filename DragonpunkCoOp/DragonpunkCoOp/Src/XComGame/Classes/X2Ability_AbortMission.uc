//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Ability_AbortMission.uc
//  AUTHOR:  
//  PURPOSE: Defines abilities related to mission abort, evac, etc
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2Ability_AbortMission extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AbortMissionAbility());
	Templates.AddItem(PlaceEvacZone());
	Templates.AddItem(LiftOffAvengerAbility());

	return Templates;
}

static function X2AbilityTemplate AbortMissionAbility()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionCost;
	local X2Condition_BattleState       BattleCondition;
	local X2AbilityTrigger_PlayerInput  PlayerInput;
	local X2Effect_EnableGlobalAbility  GlobalAbility;
	local X2Effect_Persistent           EvacDelay;
	local X2Condition_UnitProperty      ShooterCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AbortMission');

	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Aborting" in MP!

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionCost);

	Template.AbilityToHitCalc = default.DeadEye;

	BattleCondition = new class'X2Condition_BattleState';
	BattleCondition.bMissionNotAborted = true;
	Template.AbilityShooterConditions.AddItem(BattleCondition);

	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	Template.AbilityTargetStyle = default.SelfTarget;

	PlayerInput = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(PlayerInput);

	GlobalAbility = new class'X2Effect_EnableGlobalAbility';
	GlobalAbility.GlobalAbility = 'Evac';
	EvacDelay = new class'X2Effect_Persistent';
	EvacDelay.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	EvacDelay.ApplyOnTick.AddItem(GlobalAbility);
	Template.AddShooterEffect(EvacDelay);
	
	Template.Hostility = eHostility_Neutral;

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_evac";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.EVAC_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_AbilityUnavailable');
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	Template.BuildNewGameStateFn = AbortMission_BuildGameState;
	Template.BuildVisualizationFn = AbortMission_BuildVisualization;

	Template.bCommanderAbility = true; 

	return Template;
}

simulated function XComGameState AbortMission_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;	
	local XComGameState_BattleData BattleData, NewBattleData;
	local XComGameState_Ability AbilityState;

	History = `XCOMHISTORY;	
	NewGameState = TypicalAbility_BuildGameState(Context);
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	NewBattleData = XComGameState_BattleData(NewGameState.CreateStateObject(BattleData.Class, BattleData.ObjectID));
	NewBattleData.bMissionAborted = true;
	NewGameState.AddStateObject(NewBattleData);

	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(XComGameStateContext_Ability(NewGameState.GetContext()).InputContext.AbilityRef.ObjectID));
	`XEVENTMGR.TriggerEvent('MissionAborted', AbilityState, AbilityState, NewGameState);

	return NewGameState;
}

simulated function AbortMission_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;
	local XComGameState_Ability         Ability;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
					
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Good);
	OutVisualizationTracks.AddItem(BuildTrack);
}

static function X2AbilityTemplate PlaceEvacZone()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCooldown_Global          Cooldown;
	local X2AbilityTarget_Cursor            CursorTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PlaceEvacZone');

	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer); // Do not allow "Evac Zone Placement" in MP!

	Template.Hostility = eHostility_Neutral;
	Template.bCommanderAbility = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.PLACE_EVAC_PRIORITY;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_evac";
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	CursorTarget = new class'X2AbilityTarget_Cursor';
	Template.AbilityTargetStyle = CursorTarget;
	Template.TargetingMethod = class'X2TargetingMethod_EvacZone';

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_Global';
	Cooldown.iNumTurns = 3;
	Template.AbilityCooldown = Cooldown;

	Template.BuildNewGameStateFn = PlaceEvacZone_BuildGameState;
	Template.BuildVisualizationFn = PlaceEvacZone_BuildVisualization;

	return Template;
}

simulated function XComGameState PlaceEvacZone_BuildGameState( XComGameStateContext Context )
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;	
	local XComGameState_Ability AbilityState;	
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	//Build the new game state frame
	NewGameState = History.CreateNewGameState(true, Context);	

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());	
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));	
	AbilityTemplate = AbilityState.GetMyTemplate();

	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	//Apply the cost of the ability
	AbilityTemplate.ApplyCost(AbilityContext, AbilityState, UnitState, none, NewGameState);
	NewGameState.AddStateObject(UnitState);

	`assert(AbilityContext.InputContext.TargetLocations.Length == 1);
	class'XComGameState_EvacZone'.static.PlaceEvacZone(NewGameState, AbilityContext.InputContext.TargetLocations[0], UnitState.GetTeam());

	//Return the game state we have created
	return NewGameState;	
}

simulated function PlaceEvacZone_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack Track;
	local XComGameState_EvacZone EvacState;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EvacZone', EvacState)
	{
		break;
	}
	`assert(EvacState != none);

	Track.StateObject_NewState = EvacState;
	Track.StateObject_OldState = EvacState;
	Track.TrackActor = EvacState.GetVisualizer();
	class'X2Action_PlaceEvacZone'.static.AddToVisualizationTrack(Track, VisualizeGameState.GetContext());
	OutVisualizationTracks.AddItem(Track);
}

//Lift Off Avenger Ability
static function X2AbilityTemplate LiftOffAvengerAbility()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionCost;
	local X2Condition_BattleState       BattleCondition;
	local X2AbilityTrigger_PlayerInput  PlayerInput;
	local X2Condition_UnitProperty      ShooterCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LiftOffAvenger');

	ActionCost = new class'X2AbilityCost_ActionPoints';
	ActionCost.iNumPoints = 1;
	ActionCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionCost);

	Template.AbilityToHitCalc = default.DeadEye;

	BattleCondition = new class'X2Condition_BattleState';
	BattleCondition.bMissionNotAborted = true;
	Template.AbilityShooterConditions.AddItem(BattleCondition);

	ShooterCondition = new class'X2Condition_UnitProperty';
	ShooterCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(ShooterCondition);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.TargetingMethod = class'X2TargetingMethod_LiftOffAvenger';

	PlayerInput = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(PlayerInput);
	
	Template.Hostility = eHostility_Neutral;

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_liftoffavenger";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.AbilitySourceName = 'eAbilitySource_Commander';

	Template.BuildNewGameStateFn = LiftOffAvengerAbility_BuildGameState;
	Template.BuildVisualizationFn = LiftOffAvenger_BuildVisualization;

	Template.bCommanderAbility = false; 
	Template.bAllowedByDefault = false;

	return Template;
}

simulated function XComGameState LiftOffAvengerAbility_BuildGameState( XComGameStateContext Context )
{
	local XComWorldData WorldData;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;	
	local XComGameStateHistory History;
	local Volume DropzoneVolume;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	
	//Build the new game state frame
	NewGameState = History.CreateNewGameState(true, Context);	

	DropzoneVolume = class'X2TargetingMethod_LiftOffAvenger'.static.FindDropzoneVolume();
	if(DropzoneVolume != none)
	{
		// evac any units that are within the evac zone. Leave the rest of them to be captured
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if(UnitState.GetTeam() == eTeam_XCom
				&& !UnitState.IsDead()
				&& !UnitState.bRemovedFromPlay
				&& DropzoneVolume.EncompassesPoint(WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation)))
			{
				UnitState.EvacuateUnit(NewGameState);
			}
		}
	}

	//Return the game state we have created
	return NewGameState;	
}

simulated function LiftOffAvenger_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
}
