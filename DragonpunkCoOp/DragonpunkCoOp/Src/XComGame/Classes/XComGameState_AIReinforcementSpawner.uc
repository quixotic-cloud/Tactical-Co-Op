
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComGameState_AIReinforcementSpawner.uc    
//  AUTHOR:  Dan Kaplan  --  2/16/2015
//  PURPOSE: Holds all state data relevant to a pending spawn of a reinforcement group of AIs.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AIReinforcementSpawner extends XComGameState_BaseObject
	implements(X2VisualizedInterface)
	native(AI);

// The list of unit IDs that were spawned from this spawner
var array<int> SpawnedUnitIDs;

// True iff this reinforcements will be using a PsiGate as the spawner
var bool UsingPsiGates;

// The SpawnInfo for the group that will be created by this spawner
var PodSpawnInfo SpawnInfo;

// If using an ATT, this is the ref to the ATT unit that is created
var StateObjectReference TroopTransportRef;

// The number of AI turns remaining until the reinforcements are spawned
var int Countdown;

// If true, these reinforcements were initiated from kismet
var bool bKismetInitiatedReinforcements;

// wrappers for the string literals on the spawn's change container contexts. Allows us to easily ensure that 
// the names don't get out of sync from the various systems that need to use them.
var const string SpawnReinforcementsChangeDesc;
var const string SpawnReinforcementsCompleteChangeDesc;

function OnBeginTacticalPlay()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnBeginTacticalPlay();

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'ReinforcementSpawnerCreated', OnReinforcementSpawnerCreated, ELD_OnStateSubmitted, , ThisObj);
	EventManager.TriggerEvent('ReinforcementSpawnerCreated', ThisObj, ThisObj);
}

function OnEndTacticalPlay()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnEndTacticalPlay();

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.UnRegisterFromEvent(ThisObj, 'ReinforcementSpawnerCreated');
	EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun');
	EventManager.UnRegisterFromEvent(ThisObj, 'SpawnReinforcementsComplete');
}

// This is called after this reinforcement spawner has finished construction
function EventListenerReturn OnReinforcementSpawnerCreated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2EventManager EventManager;
	local Object ThisObj;
	local X2CharacterTemplate SelectedTemplate;
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionSiteState;
	local XComAISpawnManager SpawnManager;
	local int AlertLevel, ForceLevel;
	local XComGameStateHistory History;
	local Name CharTemplateName;
	local X2CharacterTemplateManager CharTemplateManager;

	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	SpawnManager = `SPAWNMGR;
	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	ForceLevel = BattleData.GetForceLevel();
	AlertLevel = BattleData.GetAlertLevel();

	if( BattleData.m_iMissionID > 0 )
	{
		MissionSiteState = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));

		if( MissionSiteState != None && MissionSiteState.SelectedMissionData.SelectedMissionScheduleName != '' )
		{
			AlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
			ForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
		}
	}

	// Select the spawning visualization mechanism and build the persistent in-world visualization for this spawner
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForSpawnerCreation;

	NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.CreateStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));

	// choose reinforcement spawn location

	// build a character selection that will work at this location
	SpawnManager.SelectPodAtLocation(NewSpawnerState.SpawnInfo, ForceLevel, AlertLevel);

	// explicitly disabled all timed loot from reinforcement groups
	NewSpawnerState.SpawnInfo.bGroupDoesNotAwardLoot = true;

	// determine if the spawning mechanism will be via ATT or PsiGate
	//  A) ATT requires open sky above the reinforcement location
	//  B) ATT requires that none of the selected units are oversized (and thus don't make sense to be spawning from ATT)
	NewSpawnerState.UsingPsiGates = NewSpawnerState.SpawnInfo.bForceSpawnViaPsiGate || !DoesLocationSupportATT(NewSpawnerState.SpawnInfo.SpawnLocation);

	if( !NewSpawnerState.UsingPsiGates )
	{
		// determine if we are going to be using psi gates or the ATT based on if the selected templates support it
		foreach NewSpawnerState.SpawnInfo.SelectedCharacterTemplateNames(CharTemplateName)
		{
			SelectedTemplate = CharTemplateManager.FindCharacterTemplate(CharTemplateName);

			if( !SelectedTemplate.bAllowSpawnFromATT )
			{
				NewSpawnerState.UsingPsiGates = true;
				break;
			}
		}
	}

	NewGameState.AddStateObject(NewSpawnerState);

	`TACTICALRULES.SubmitGameState(NewGameState);


	// no countdown specified, spawn reinforcements immediately
	if( Countdown <= 0 )
	{
		NewSpawnerState.SpawnReinforcements();
	}
	// countdown is active, need to listen for AI Turn Begun in order to tick down the countdown
	else
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;

		PlayerState = `BATTLE.GetAIPlayerState();
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnTurnBegun, ELD_OnStateSubmitted, , PlayerState);
	}

	return ELR_NoInterrupt;
}

// TODO: update this function to better consider the space that an ATT requires
private function bool DoesLocationSupportATT(Vector TargetLocation)
{
	local TTile TargetLocationTile;
	local TTile AirCheckTile;
	local VoxelRaytraceCheckResult CheckResult;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

		TargetLocationTile = WorldData.GetTileCoordinatesFromPosition(TargetLocation);
	AirCheckTile = TargetLocationTile;
	AirCheckTile.Z = WorldData.NumZ - 1;

	// the space is free if the raytrace hits nothing
	return (WorldData.VoxelRaytrace_Tiles(TargetLocationTile, AirCheckTile, CheckResult) == false);
}


// This is called at the start of each AI turn
function EventListenerReturn OnTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2GameRuleset Ruleset;

	Ruleset = `XCOMGAME.GameRuleset;

	if( Countdown > 0 )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UpdateReinforcementCountdown");
		NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.CreateStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));
		--NewSpawnerState.Countdown;
		NewGameState.AddStateObject(NewSpawnerState);
		Ruleset.SubmitGameState(NewGameState);

		// we just hit zero? time to spawn reinforcements
		if( NewSpawnerState.Countdown == 0 )
		{
			SpawnReinforcements();
		}
	}

	return ELR_NoInterrupt;
}

function SpawnReinforcements()
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComAISpawnManager SpawnManager;
	local XGAIGroup SpawnedGroup;
	local X2GameRuleset Ruleset;

	EventManager = `XEVENTMGR;
	SpawnManager = `SPAWNMGR;
	Ruleset = `XCOMGAME.GameRuleset;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(default.SpawnReinforcementsChangeDesc);
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForUnitSpawning;

	NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.CreateStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));

	// spawn the units
	SpawnedGroup = SpawnManager.SpawnPodAtLocation(
		NewGameState,
		SpawnInfo);

	// clear the ref to this actor to prevent unnecessarily rooting the level
	SpawnInfo.SpawnedPod = None;

	// cache off the spawned unit IDs
	NewSpawnerState.SpawnedUnitIDs = SpawnedGroup.m_arrUnitIDs;
	NewGameState.AddStateObject(NewSpawnerState);

	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'SpawnReinforcementsComplete', OnSpawnReinforcementsComplete, ELD_OnStateSubmitted,, ThisObj);
	EventManager.TriggerEvent('SpawnReinforcementsComplete', ThisObj, ThisObj, NewGameState);

	Ruleset.SubmitGameState(NewGameState);
}

// This is called after the reinforcement spawned
function EventListenerReturn OnSpawnReinforcementsComplete(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComWorldData World;
	local XComGameState_Unit ReinforcementUnit, InstigatingUnit;
	local XComGameState NewGameState;
	local XComGameState_AIUnitData NewAIUnitData;
	local int i;
	local AlertAbilityInfo AlertInfo;
	local XComGameStateHistory History;
	local XComAISpawnManager SpawnManager;
	local Vector PingLocation;
	local array<StateObjectReference> VisibleUnits;
	local XComGameState_AIGroup AIGroupState;
	local bool bDataChanged;
	local XGAIGroup Group;

	World = `XWORLD;
	History = `XCOMHISTORY;
	SpawnManager = `SPAWNMGR;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(default.SpawnReinforcementsCompleteChangeDesc);
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForSpawnerDestruction;

	PingLocation = SpawnManager.GetCurrentXComLocation();
	AlertInfo.AlertTileLocation = World.GetTileCoordinatesFromPosition(PingLocation);
	AlertInfo.AlertRadius = 500;
	AlertInfo.AlertUnitSourceID = 0;
	AlertInfo.AnalyzingHistoryIndex = GameState.HistoryIndex;

	// update the alert pings on all the spawned units
	for( i = 0; i < SpawnedUnitIDs.Length; ++i )
	{
		bDataChanged = false;
		ReinforcementUnit = XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnitIDs[i]));
		class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(ReinforcementUnit.ObjectID, VisibleUnits, class'X2TacticalVisibilityHelpers'.default.LivingLOSVisibleFilter);

		NewAIUnitData = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', ReinforcementUnit.GetAIUnitDataID()));
		if( NewAIUnitData.m_iUnitObjectID != ReinforcementUnit.ObjectID )
		{
			NewAIUnitData.Init(ReinforcementUnit.ObjectID);
			bDataChanged = true;
		}
		if( NewAIUnitData.AddAlertData(SpawnedUnitIDs[i], eAC_MapwideAlert_Hostile, AlertInfo, NewGameState) )
		{
			bDataChanged = true;
		}

		if( bDataChanged )
		{
			NewGameState.AddStateObject(NewAIUnitData);
		}
		else
		{
			NewGameState.PurgeGameStateForObjectID(NewAIUnitData.ObjectID);
		}
	}

	// if there was an ATT, remove it now
	if( TroopTransportRef.ObjectID > 0 )
	{
		NewGameState.RemoveStateObject(TroopTransportRef.ObjectID);
	}

	// remove this state object, now that we are done with it
	NewGameState.RemoveStateObject(ObjectID);

	`TACTICALRULES.SubmitGameState(NewGameState);

	if( VisibleUnits.Length > 0 )
	{
		InstigatingUnit = XComGameState_Unit(History.GetGameStateForObjectID(VisibleUnits[0].ObjectID));
		AIGroupState = ReinforcementUnit.GetGroupMembership();
		AIGroupState.InitiateReflexMoveActivate(InstigatingUnit, eAC_SeesSpottedUnit);
	}
	else
	{
		// If this group isn't starting out scampering, we need to initialize the group turn so it can move properly.
		XGAIPlayer(`BATTLE.GetAIPlayer()).m_kNav.GetGroupInfo(SpawnedUnitIDs[0], Group);
		Group.InitTurn();
	}

	return ELR_NoInterrupt;
}


function BuildVisualizationForUnitSpawning(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local XComGameState_Unit SpawnedUnit;
	local TTile SpawnedUnitTile;
	local int i;
	local VisualizationTrack BuildTrack, EmptyBuildTrack;
	local X2Action_PlayAnimation PsiWarpInEffectAnimation;
	local X2Action_PlayEffect PsiWarpInEffectAction;
	local XComWorldData World;
	local XComContentManager ContentManager;
	local XComGameStateHistory History;
	local bool bUsingATTTransport;
	local X2Action_ShowSpawnedUnit ShowSpawnedUnitAction;
	local X2Action_ATT ATTAction;
	local float ShowSpawnedUnitActionTimeout;

	History = `XCOMHISTORY;
	ContentManager = `CONTENT;
	World = `XWORLD;
	AISpawnerState = XComGameState_AIReinforcementSpawner(VisualizeGameState.GetGameStateForObjectID(ObjectID));

	bUsingATTTransport = false;
	ShowSpawnedUnitActionTimeout = 10.0f;
	if( !AISpawnerState.UsingPsiGates )
	{
		BuildTrack.StateObject_OldState = AISpawnerState;
		BuildTrack.StateObject_NewState = AISpawnerState;
		ATTAction = X2Action_ATT(class'X2Action_ATT'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		ShowSpawnedUnitActionTimeout = ATTAction.TimeoutSeconds;

		OutVisualizationTracks.AddItem(BuildTrack);

		bUsingATTTransport = true;
	}


	for( i = 0; i < AISpawnerState.SpawnedUnitIDs.Length; ++i )
	{
		SpawnedUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AISpawnerState.SpawnedUnitIDs[i]));

		if( SpawnedUnit.GetVisualizer() == none )
		{
			SpawnedUnit.FindOrCreateVisualizer();
			SpawnedUnit.SyncVisualizer();

			//Make sure they're hidden until ShowSpawnedUnit makes them visible (SyncVisualizer unhides them)
			XGUnit(SpawnedUnit.GetVisualizer()).m_bForceHidden = true;
		}

		BuildTrack = EmptyBuildTrack;
		BuildTrack.StateObject_OldState = SpawnedUnit;
		BuildTrack.StateObject_NewState = SpawnedUnit;
		BuildTrack.TrackActor = History.GetVisualizer(SpawnedUnit.ObjectID);

		ShowSpawnedUnitAction = X2Action_ShowSpawnedUnit(class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		ShowSpawnedUnitAction.bWaitToShow = bUsingATTTransport;
		ShowSpawnedUnitAction.ChangeTimeoutLength(ShowSpawnedUnitActionTimeout + ShowSpawnedUnitAction.TimeoutSeconds);

		// if spawning from PsiGates, need a warp in effect to play at each of the unit spawn locations
		if( AISpawnerState.UsingPsiGates )
		{
			SpawnedUnit.GetKeystoneVisibilityLocation(SpawnedUnitTile);

			PsiWarpInEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
			PsiWarpInEffectAction.EffectName = ContentManager.PsiWarpInEffectPathName;
			PsiWarpInEffectAction.EffectLocation = World.GetPositionFromTileCoordinates(SpawnedUnitTile);
			PsiWarpInEffectAction.bStopEffect = false;

			PsiWarpInEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
			PsiWarpInEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
			PsiWarpInEffectAction.EffectLocation = World.GetPositionFromTileCoordinates(SpawnedUnitTile);
			PsiWarpInEffectAction.bStopEffect = true;

			if( AISpawnerState.SpawnInfo.EncounterID == 'LoneCodex' || AISpawnerState.SpawnInfo.EncounterID == 'LoneAvatar' )
			{
				PsiWarpInEffectAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
				PsiWarpInEffectAnimation.Params.AnimName = 'HL_TeleportStop';
			}
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}
}

function BuildVisualizationForSpawnerCreation(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local X2Action_PlayEffect ReinforcementSpawnerEffectAction;
	local X2Action_RevealArea RevealAreaAction;
	local XComContentManager ContentManager;
	local XComGameState_Unit UnitIterator;
	local XGUnit TempXGUnit;
	local bool bUnitHasSpokenVeryRecently;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	ContentManager = `CONTENT;
	History = `XCOMHISTORY;
	AISpawnerState = XComGameState_AIReinforcementSpawner(History.GetGameStateForObjectID(ObjectID));

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	RevealAreaAction.TargetLocation = AISpawnerState.SpawnInfo.SpawnLocation;
	RevealAreaAction.AssociatedObjectID = ObjectID;
	RevealAreaAction.bDestroyViewer = false;

	ReinforcementSpawnerEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));

	if( AISpawnerState.UsingPsiGates )
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
	}
	else
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.ATTFlareEffectPathName;
	}

	ReinforcementSpawnerEffectAction.EffectLocation = AISpawnerState.SpawnInfo.SpawnLocation;
	ReinforcementSpawnerEffectAction.CenterCameraOnEffectDuration = ContentManager.LookAtCamDuration;
	ReinforcementSpawnerEffectAction.bStopEffect = false;

	BuildTrack.StateObject_OldState = AISpawnerState;
	BuildTrack.StateObject_NewState = AISpawnerState;
	OutVisualizationTracks.AddItem(BuildTrack);


	// Add a track to one of the x-com soldiers, to say a line of VO (e.g. "Alien reinforcements inbound!").
	foreach History.IterateByClassType( class'XComGameState_Unit', UnitIterator )
	{
		TempXGUnit = XGUnit(UnitIterator.GetVisualizer());
		bUnitHasSpokenVeryRecently = ( TempXGUnit != none && TempXGUnit.m_fTimeSinceLastUnitSpeak < 3.0f );

		if (UnitIterator.GetTeam() == eTeam_XCom && !bUnitHasSpokenVeryRecently && !AISpawnerState.SpawnInfo.SkipSoldierVO)
		{
			BuildTrack = EmptyTrack;
			BuildTrack.StateObject_OldState = UnitIterator;
			BuildTrack.StateObject_NewState = UnitIterator;
			BuildTrack.TrackActor = UnitIterator.GetVisualizer();

			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(none, "", 'AlienReinforcements', eColor_Bad);

			OutVisualizationTracks.AddItem(BuildTrack);
			break;
		}
	}

}

function BuildVisualizationForSpawnerDestruction(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local X2Action_PlayEffect ReinforcementSpawnerEffectAction;
	local X2Action_RevealArea RevealAreaAction;
	local XComContentManager ContentManager;

	ContentManager = `CONTENT;
	History = `XCOMHISTORY;
	AISpawnerState = XComGameState_AIReinforcementSpawner(History.GetGameStateForObjectID(ObjectID));

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	RevealAreaAction.AssociatedObjectID = ObjectID;
	RevealAreaAction.bDestroyViewer = true;

	ReinforcementSpawnerEffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));

	if( AISpawnerState.UsingPsiGates )
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
	}
	else
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.ATTFlareEffectPathName;
	}

	ReinforcementSpawnerEffectAction.EffectLocation = AISpawnerState.SpawnInfo.SpawnLocation;
	ReinforcementSpawnerEffectAction.bStopEffect = true;

	BuildTrack.StateObject_OldState = AISpawnerState;
	BuildTrack.StateObject_NewState = AISpawnerState;
	OutVisualizationTracks.AddItem(BuildTrack);
}


static function InitiateReinforcements(
	Name EncounterID, 
	optional int OverrideCountdown, 
	optional bool OverrideTargetLocation,
	optional const out Vector TargetLocationOverride,
	optional int IdealSpawnTilesOffset,
	optional XComGameState IncomingGameState,
	optional bool InKismetInitiatedReinforcements)
{
	local XComGameState_AIReinforcementSpawner NewAIReinforcementSpawnerState;
	local XComGameState NewGameState;
	local XComTacticalMissionManager MissionManager;
	local ConfigurableEncounter Encounter;
	local XComAISpawnManager SpawnManager;
	local Vector DesiredSpawnLocation;

	SpawnManager = `SPAWNMGR;

	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.GetConfigurableEncounter(EncounterID, Encounter);

	if (IncomingGameState == none)
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Creating Reinforcement Spawner");
	else
		NewGameState = IncomingGameState;

	// Update AIPlayerData with CallReinforcements data.
	NewAIReinforcementSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.CreateStateObject(class'XComGameState_AIReinforcementSpawner'));
	NewAIReinforcementSpawnerState.SpawnInfo.EncounterID = EncounterID;

	if( OverrideCountdown > 0 )
	{
		NewAIReinforcementSpawnerState.Countdown = OverrideCountdown;
	}
	else
	{
		NewAIReinforcementSpawnerState.Countdown = Encounter.ReinforcementCountdown;
	}

	if( OverrideTargetLocation )
	{
		DesiredSpawnLocation = TargetLocationOverride;
	}
	else
	{
		DesiredSpawnLocation = SpawnManager.GetCurrentXComLocation();
	}

	NewAIReinforcementSpawnerState.SpawnInfo.SpawnLocation = SpawnManager.SelectReinforcementsLocation(NewAIReinforcementSpawnerState, DesiredSpawnLocation, IdealSpawnTilesOffset, Encounter.bSpawnViaPsiGate);

	NewAIReinforcementSpawnerState.bKismetInitiatedReinforcements = InKismetInitiatedReinforcements;

	NewGameState.AddStateObject(NewAIReinforcementSpawnerState);

	if (IncomingGameState == none)
		`TACTICALRULES.SubmitGameState(NewGameState);
}

// When called, the visualized object must create it's visualizer if needed, 
function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	return none;
}

// Ensure that the visualizer visual state is an accurate reflection of the state of this object.
function SyncVisualizer( optional XComGameState GameState = none )
{
}

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack )
{
	local XComContentManager ContentManager;
	local X2Action_PlayEffect ReinforcementSpawnerEffectAction;

	if (Countdown <= 0)
	{
		return; // we've completed the reinforcement and the effect was stopped
	}

	ContentManager = `CONTENT;

	ReinforcementSpawnerEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTrack( BuildTrack, GetParentGameState().GetContext() ) );

	if (UsingPsiGates)
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.PsiGateEffectPathName;
	}
	else
	{
		ReinforcementSpawnerEffectAction.EffectName = ContentManager.ATTFlareEffectPathName;
	}

	ReinforcementSpawnerEffectAction.EffectLocation = SpawnInfo.SpawnLocation;
	ReinforcementSpawnerEffectAction.CenterCameraOnEffectDuration = 0;
	ReinforcementSpawnerEffectAction.bStopEffect = false;
}

cpptext
{
	// UObject interface
	virtual void Serialize(FArchive& Ar);
}

defaultproperties
{
	SpawnReinforcementsChangeDesc="SpawnReinforcements"
	SpawnReinforcementsCompleteChangeDesc="OnSpawnReinforcementsComplete"
	Countdown = -1
}

