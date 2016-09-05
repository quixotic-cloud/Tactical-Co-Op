//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    X2TacticalCoOpGameRuleset
//  AUTHOR:  Elad Dvash
//  PURPOSE: New Ruleset for the Co-Op game
//                                           
// Still very experimental. everything here is pretty much copy paste since i didnt add
// anything of substence here yet,I dont think we'll need anything custom here though
// since we are going to be using events to manage turns 
// (turns here are game turns which are an entire cycle: Start->XCom->aliens->Civis->End)                                                                                                                                                                           
//---------------------------------------------------------------------------------------

Class X2TacticalCoOpGameRuleset extends X2TacticalGameRuleset;

//******** General Purpose Variables *********************
var protected bool bSkipFirstPlayerSync;                        //A one time skip for Startup procedure to get the first player into the correct Ruleset state.
var protected bool bSendingPartialHistory;                      //True whenever a send has occurred, but a receive has not yet returned.
var protected bool bWaitingForEndTacticalGame;
var protected bool bRulesetRunning;                             //the rulese has fully initialized, downloaded histories, and is now running
var protected XComReplayMgr ReplayMgr;
`define SETLOC(LocationString)	BeginBlockWaitingLocation = GetStateName() $ ":" @ `LocationString;
var protected bool bLocalPlayerForfeited;
var protected bool bDisconnected;
var protected bool bShouldDisconnect;
var protected bool bReceivedNotifyConnectionClosed;
//********************************************************

var bool bSkipRemainingTurnActivty_B;

var OnlineSubsystem OnlineSub;
var OnlineGameInterface GameInterface;

struct PlayerSpawnVolume
{
	var XComGameState_Player    Player;
	var XComFalconVolume        Volume;
	var array<SpawnPointCache>  SpawnPoints;
};

struct TrackingTile
{
	var TTile Tile;
	var bool bIsValid;
	var bool bIsAvailable;
};

/*
simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	bRulesetRunning = false;

	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.AddReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.AddReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.AddReceiveMirrorHistoryDelegate(ReceiveMirrorHistory);
	NetworkMgr.AddReceiveRemoteCommandDelegate(OnRemoteCommand);
	NetworkMgr.AddNotifyConnectionClosedDelegate(OnNotifyConnectionClosed);

	// Cache a pointer to the online subsystem
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSub != None)
	{
		// And grab one for the game interface since it will be used often
		GameInterface = OnlineSub.GameInterface;
		OnlineGameInterfaceXCom(GameInterface).AddLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	}

	SubscribeToOnCleanupWorld();
}

simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

simulated function Cleanup()
{

	NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.ClearReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.ClearReceiveMirrorHistoryDelegate(ReceiveMirrorHistory);
	NetworkMgr.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
	NetworkMgr.ClearNotifyConnectionClosedDelegate(OnNotifyConnectionClosed);


	OnlineGameInterfaceXCom(GameInterface).ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);

	if( bShouldDisconnect )
	{
		DisconnectGame();
	}
	else
	{
		NetworkMgr.ResetConnectionData();
	}
}

simulated event Destroyed()
{
	Cleanup();

	super.Destroyed();
}*/

function XComReplayMgr GetReplayMgr()
{
	if( ReplayMgr == none )
	{
		ReplayMgr = XComMPCOOPGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr;
	}
	return ReplayMgr;
}

function SendRemoteCommand(string Command)
{
	local array<byte> EmptyParams;
	EmptyParams.Length = 0; // Removes script warning
	NetworkMgr.SendRemoteCommand(Command, EmptyParams);
}

function DisconnectGame()
{
	bDisconnected = true;
	NetworkMgr.Disconnect();
	OnlineSub.GameInterface.DestroyOnlineGame('Game');
}

function OnLobbyMemberStatusUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, int InstigatorIndex, string Status)
{
	local string Reason;
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(InstigatorIndex) @ `ShowVar(Status),,'XCom_Online');
	if( InStr(Status, "Exit") > -1 )
	{
		// Exit Event Happened
		Reason -= "Exit - ";
		`log(`location @ `ShowVar(Reason),,'XCom_Online');
		// Don't really care about the reason, any exit event should send the other player to the opponent left state.
		GotoState('ConnectionClosed');
	}
}

function StartStatePositionUnits()
{
	local XComGameState StartState;		
	local XComGameState_Unit UnitState;
	
	local vector vSpawnLoc;
	local XComGroupSpawn kSoldierSpawn;
	local array<vector> FloorPoints;
	local int StartStateIndex;

	`log("Getting Inside Creation of UNITS!");
	StartState = CachedHistory.GetStartState();
	`log("Start State Number of gamestates:"@StartState.GetNumGameStateObjects(),,'Team Dragonpunk Co Op');
	if (StartState == none)
	{
		StartStateIndex = CachedHistory.FindStartStateIndex();
		
		StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

		`assert(StartState != none);
	}
	`log("Start State Number of gamestates Cached:"@StartState.GetNumGameStateObjects(),,'Team Dragonpunk Co Op');

	ParcelManager = `PARCELMGR; // make sure this is cached

	//If this is a start state, we need to additional processing. Place the player's
	//units. Create and place the AI player units.
	//======================================================================
	if( StartState != none )
	{
		if(ParcelManager == none || ParcelManager.SoldierSpawn == none)
		{
			// We're probably loaded in PIE, which doesn't go through the parcel manager. Just grab any spawn point for
			// testing
			foreach `XWORLDINFO.AllActors(class'XComGroupSpawn', kSoldierSpawn) { break; }
		}
		else
		{
			kSoldierSpawn = ParcelManager.SoldierSpawn;
		}
			
		`log("No Soldier Spawn found when positioning units!",kSoldierSpawn == none);
		ParcelManager.ParcelGenerationAssert(kSoldierSpawn != none, "No Soldier Spawn found when positioning units!");
			
		kSoldierSpawn.GetValidFloorLocations(FloorPoints);

		ParcelManager.ParcelGenerationAssert(FloorPoints.Length > 0, "No valid floor points for spawn: " $ kSoldierSpawn);
		`log("No valid floor points for spawn",FloorPoints.Length <= 0);
					
		//Updating the positions of the units
		foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{				
			`log("Placing A Unit!",,'Team Dragonpunk Co Op StartStatePositionUnits');
			vSpawnLoc = FloorPoints[`SYNC_RAND_TYPED(FloorPoints.Length)];
			FloorPoints.RemoveItem(vSpawnLoc);						

			UnitState.SetVisibilityLocationFromVector(vSpawnLoc);
			`XWORLD.SetTileBlockedByUnitFlag(UnitState);
		}
	}
}

simulated function StartStateCreateXpManager(XComGameState StartState)
{
	local XComGameState_XpManager XpManager;
	local XComGameState_BaseObject BaseObj;
	local XComGameState_BattleData BattleData;

	XpManager = XComGameState_XpManager(StartState.CreateStateObject(class'XComGameState_XpManager'));
	CachedXpManagerRef = XpManager.GetReference();
	foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
	{
		if(XComGameState_BattleData(BaseObj)!=none)
		{
			BattleData=XComGameState_BattleData(BaseObj);
			`log("Found BattleData XpManager");
			break;
		}	
	}
	XpManager.Init(BattleData);
	StartState.AddStateObject(XpManager);
}

function AddCharacterStreamingCinematicMaps(bool bBlockOnLoad = false)
{
	local X2CharacterTemplateManager TemplateManager;
	local XComGameStateHistory History;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit UnitState;
	local array<string> MapNames;
	local string MapName;

	History = `XCOMHISTORY;
	TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	// Force load any specified maps
	MapNames = ForceLoadCinematicMaps;

	// iterate each unit on the map and add it's cinematic maps to the list of maps
	// we need to load
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		CharacterTemplate = TemplateManager.FindCharacterTemplate(UnitState.GetMyTemplateName());
		if (CharacterTemplate != None)
		{
			foreach CharacterTemplate.strMatineePackages(MapName)
			{
				if(MapName != "" && MapNames.Find(MapName) == INDEX_NONE)
				{
					MapNames.AddItem(MapName);
				}
			}
		}
	}

	// and then queue the maps for streaming
	foreach MapNames(MapName)
	{
		`log( "Adding matinee map" $ MapName );
		`MAPS.AddStreamingMap(MapName, , , bBlockOnLoad).bForceNoDupe = true;
	}
}

function XComGameState_BattleData GetBD()
{
	local XComGameState_BattleData BattleDataState;
	local XComGameState_BaseObject BaseObj;
	local XComGameState StartState;
	local int StartStateIndex;
	StartState = CachedHistory.GetStartState();
	if (StartState == none)
	{
		StartStateIndex = CachedHistory.FindStartStateIndex();

		StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

		`assert(StartState != none);

	}
	foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
	{
		if(XComGameState_BattleData(BaseObj)==none) Continue;
		BattleDataState=XComGameState_BattleData(BaseObj);
	}
	return BattleDataState;
}

function AddDropshipStreamingCinematicMaps()
{
	local XComTacticalMissionManager MissionManager;
	local MissionIntroDefinition MissionIntro;
	local AdditionalMissionIntroPackageMapping AdditionalIntroPackage;
	local XComGroupSpawn kSoldierSpawn;
	local XComGameState StartState;
	local Vector ObjectiveLocation;
	local Vector DirectionTowardsObjective;
	local Rotator ObjectiveFacing;
	local int StartStateIndex;

	StartState = CachedHistory.GetStartState();
	if (StartState == none)
	{
		StartStateIndex = CachedHistory.FindStartStateIndex();
		
		StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

		`assert(StartState != none);

	}
	ParcelManager = `PARCELMGR; // make sure this is cached

	//Don't do the cinematic intro if the below isn't correct, as this means we are loading PIE, or directly into a map
	if( StartState != none && ParcelManager != none && ParcelManager.SoldierSpawn != none)
	{
		kSoldierSpawn = ParcelManager.SoldierSpawn;		
		ObjectiveLocation = ParcelManager.ObjectiveParcel.Location;
		DirectionTowardsObjective = ObjectiveLocation - kSoldierSpawn.Location;
		DirectionTowardsObjective.Z = 0;
		ObjectiveFacing = Rotator(DirectionTowardsObjective);
	}

	// load the base intro matinee package
	MissionManager = `TACTICALMISSIONMGR;
	MissionIntro = MissionManager.GetActiveMissionIntroDefinition();
	if( kSoldierSpawn != none && MissionIntro.MatineePackage != "" && MissionIntro.MatineeSequences.Length > 0)
	{	
		`MAPS.AddStreamingMap(MissionIntro.MatineePackage, kSoldierSpawn.Location, ObjectiveFacing, false).bForceNoDupe = true;
	}

	// load any additional packages that mods may require
	foreach MissionManager.AdditionalMissionIntroPackages(AdditionalIntroPackage)
	{
		if(AdditionalIntroPackage.OriginalIntroMatineePackage == MissionIntro.MatineePackage)
		{
			`MAPS.AddStreamingMap(AdditionalIntroPackage.AdditionalIntroMatineePackage, kSoldierSpawn.Location, ObjectiveFacing, false).bForceNoDupe = true;
		}
	}
}

simulated function bool HasTacticalGameEnded()
{
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule Context;

	History = `XCOMHISTORY;
	foreach History.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
	{
		if(Context.GameRuleType == eGameRule_TacticalGameEnd)
		{
			return true;
		}
		else if(Context.GameRuleType == eGameRule_TacticalGameStart)
		{
			return false;
		}
	}

	return HasTimeExpired();
}

simulated state CreateTacticalGame
{
	simulated event BeginState(name PreviousStateName)
	{
		local X2EventManager EventManager;
		local Object ThisObject;
		local int StartStateIndex;
		local XComGameState StartState;		
		local XComGameState_BaseObject BaseObj;
		// the start state has been added by this point
		//	nothing in this state should be adding anything that is not added to the start state itself
		CachedHistory=`XCOMHISTORY;
		BuildLocalStateObjectCache();
		CachedHistory.AddHistoryLock();
		
		EventManager = `XEVENTMGR;
		ThisObject = self;

		EventManager.RegisterForEvent(ThisObject, 'UnitMoveFinished', HandleNeutralReactionsOnMovement, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'AbilityActivated', HandleNeutralReactionsOnAbilityActivated, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'UnitDied', HandleUnitDiedCache, ELD_OnStateSubmitted);
		EventManager.RegisterForEvent(ThisObject, 'TileDataChanged', HandleAdditionalFalling, ELD_OnStateSubmitted);
			
		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_BattleData(BaseObj)!=none)
			{
				CachedBattleDataRef=XComGameState_BattleData(BaseObj).GetReference();
				break;
			}	
		}
	}
	
	simulated function StartStateSpawnAliens(XComGameState StartState)
	{
		local XComGameState_Player IteratePlayerState;
		local XComGameState_BattleData BattleData;
		local XComGameState_MissionSite MissionSiteState;
		local XComGameState_BaseObject BaseObj;
		local XComAISpawnManager SpawnManager;
		local int AlertLevel, ForceLevel;

		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_BattleData(BaseObj)!=none)break;
			BattleData=XComGameState_BattleData(BaseObj);
		}

		ForceLevel = BattleData.GetForceLevel();
		AlertLevel = BattleData.GetAlertLevel();

		//MissionSiteState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(BattleData.m_iMissionID));
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_MissionSite(BaseObj)==none)continue;
			MissionSiteState=XComGameState_MissionSite(BaseObj);
			if(MissionSiteState!=none) `log("Found MissionSiteState");

		}

		if( MissionSiteState != None && MissionSiteState.SelectedMissionData.SelectedMissionScheduleName != '' )
		{
			`log("Found MissionSiteState 2");

			AlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
			ForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
		}

		SpawnManager = class'XComAISpawnManager'.static.GetSpawnManager();
		`log("Spawn Manager is:"@SpawnManager!=none @"Mission state is:"@MissionSiteState!=none,,'Team Dragonpunk Co Op');
		SpawnManager.SpawnAllAliens(ForceLevel, AlertLevel, StartState, MissionSiteState);

		// After spawning, the AI player still needs to sync the data
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_Player(BaseObj)==none) continue;

			IteratePlayerState=XComGameState_Player(BaseObj);

			`log("Player State AI Search Object ID is:"@IteratePlayerState.ObjectID,,'Team Dragonpunk Co Op');
			if( IteratePlayerState.GetTeam() == eTeam_Alien )
			{
				`log("Alien Player State AI Search Object ID is:"@IteratePlayerState.ObjectID,,'Team Dragonpunk Co Op');
				XGAIPlayer( CachedHistory.GetVisualizer(IteratePlayerState.ObjectID) ).UpdateDataToAIGameState(true);
			}
		}
		`log("Ended Spawning aliens");

	}

	simulated function StartStateSpawnCosmeticUnits(XComGameState StartState)
	{
		local XComGameState_BaseObject BaseObj;
		local XComGameState_Item IterateItemState;
				
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_Item(BaseObj)==none) continue;
			
			IterateItemState=XComGameState_Item(BaseObj);
			IterateItemState.CreateCosmeticItemUnit(StartState);
		}
	}

	function SetupPIEGame()
	{
		local XComParcel FakeObjectiveParcel;
		local MissionDefinition MissionDef;

		local Sequence GameSequence;
		local Sequence LoadedSequence;
		local array<string> KismetMaps;

		local X2DataTemplate ItemTemplate;
		local X2QuestItemTemplate QuestItemTemplate;

		// Since loading a map in PIE just gives you a single parcel and possibly a mission map, we need to
		// infer the mission type and create a fake objective parcel so that the LDs can test the game in PIE

		// This would normally be set when generating a map
		ParcelManager.TacticalMissionManager = `TACTICALMISSIONMGR;

		// Get the map name for all loaded kismet sequences
		GameSequence = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
		foreach GameSequence.NestedSequences(LoadedSequence)
		{
			// when playing in PIE, maps names begin with "UEDPIE". Strip that off.
			KismetMaps.AddItem(split(LoadedSequence.GetLevelName(), "UEDPIE", true));
		}

		// determine the mission 
		foreach ParcelManager.TacticalMissionManager.arrMissions(MissionDef)
		{
			if(KismetMaps.Find(MissionDef.MapNames[0]) != INDEX_NONE)
			{
				ParcelManager.TacticalMissionManager.ActiveMission = MissionDef;
				break;
			}
		}

		// Add a quest item in case the mission needs one. we don't care which one, just grab the first
		foreach class'X2ItemTemplateManager'.static.GetItemTemplateManager().IterateTemplates(ItemTemplate, none)
		{
			QuestItemTemplate = X2QuestItemTemplate(ItemTemplate);

			if(QuestItemTemplate != none)
			{
				ParcelManager.TacticalMissionManager.MissionQuestItemTemplate = QuestItemTemplate.DataName;
				break;
			}
		}
		
		// create a fake objective parcel at the origin
		FakeObjectiveParcel = Spawn(class'XComParcel');
		ParcelManager.ObjectiveParcel = FakeObjectiveParcel;
	}

	simulated function GenerateMap()
	{
		local int ProcLevelSeed;
	
		local XComGameState_BattleData BattleData;
		local bool bSeamlessTraveled;		
		local XComGameState_BaseObject BaseObj;
		local int StartStateIndex;
		local XComGameState StartState;
		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_BattleData(BaseObj)==none) Continue;
			BattleData=XComGameState_BattleData(BaseObj);
		}
		bSeamlessTraveled = `XCOMGAME.m_bSeamlessTraveled;

		//Check whether the map has been generated already
		if(BattleData.MapData.ParcelData.Length > 0 && !bSeamlessTraveled)
		{
			// this data has a prebuilt map, load it
			LoadMap();
		}
		else if(BattleData.MapData.PlotMapName != "")
		{			
			// create a new procedural map 
			ProcLevelSeed = BattleData.iLevelSeed;

			//Unless we are using seamless travel, generate map requires there to be NO streaming maps when it starts
			if(!bSeamlessTraveled)
			{
				if(bShowDropshipInteriorWhileGeneratingMap)
				{	 
					ParcelManager.bBlockingLoadParcels = false;
				}
				else
				{
					`MAPS.RemoveAllStreamingMaps();
				}
				
				ParcelManager.GenerateMap(ProcLevelSeed);
			}
			else
			{
				//Make sure that we don't flush async loading, or else the transition map will hitch.
				ParcelManager.bBlockingLoadParcels = false; 

				//The first part of map generation has already happened inside the dropship. Now do the second part
				ParcelManager.GenerateMapUpdatePhase2();
			}
		}
		else // static, non-procedural map (such as the obstacle course)
		{
			`log("X2TacticalGameRuleset: RebuildWorldData");
			ParcelManager.InitPlacedEvacZone(); // in case we are testing placed evac zones in this map

			if(class'WorldInfo'.static.IsPlayInEditor())
			{
				SetupPIEGame();
			}
		}
	}

	function bool ShowDropshipInterior()
	{
		local XComGameState_BattleData BattleData;
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameState_MissionSite MissionState;
		local bool bValidMapLaunchType;
		local bool bSkyrangerTravel;
		local XComGameState_BaseObject BaseObj;
		local int StartStateIndex;
		local XComGameState StartState;
		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_BattleData(BaseObj)==none) Continue;
			BattleData=XComGameState_BattleData(BaseObj);
		}

		XComHQ = XComGameState_HeadquartersXCom(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if(XComHQ != none)
		{
			MissionState = XComGameState_MissionSite(CachedHistory.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
		}

		//Not TQL, test map, PIE, etc.
		bValidMapLaunchType = `XENGINE.IsSinglePlayerGame() && BattleData.MapData.PlotMapName != "" && BattleData.MapData.ParcelData.Length == 0;

		//True if we didn't seamless travel here, and the mission type wanted a skyranger travel ( ie. no avenger defense or other special mission type )
		bSkyrangerTravel = !`XCOMGAME.m_bSeamlessTraveled && (MissionState == None || MissionState.GetMissionSource().bRequiresSkyrangerTravel);
				
		return true||bValidMapLaunchType && bSkyrangerTravel && !BattleData.DirectTransferInfo.IsDirectMissionTransfer;
	}

	simulated function CreateMapActorGameStates()
	{
		local XComDestructibleActor DestructibleActor;
		local X2WorldNarrativeActor NarrativeActor;
		local X2SquadVisiblePoint SquadVisiblePoint;

		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		foreach `BATTLE.AllActors(class'XComDestructibleActor', DestructibleActor)
		{
			DestructibleActor.GetState(StartState);
		}

		foreach `BATTLE.AllActors(class'X2WorldNarrativeActor', NarrativeActor)
		{
			NarrativeActor.CreateState(StartState);
		}

		foreach `BATTLE.AllActors(class'X2SquadVisiblePoint', SquadVisiblePoint)
		{
			SquadVisiblePoint.CreateState(StartState);
		}
	}

	simulated function BuildVisualizationForStartState()
	{
		local int StartStateIndex;		
		
		StartStateIndex = CachedHistory.FindStartStateIndex();
		//Make sure this is a tactical game start state
		`assert( StartStateIndex > -1 );
		`assert( XComGameStateContext_TacticalGameRule(CachedHistory.GetGameStateFromHistory(StartStateIndex).GetContext()) != none );
		
		//Bootstrap the visualization mgr. Enabling processing of new game states, and making sure it knows which state index we are at.
		VisualizationMgr.EnableBuildVisualization();
		VisualizationMgr.SetCurrentHistoryFrame(StartStateIndex);

		//This will set up the visualizers that init the camera, XGBattle, etc.
		VisualizationMgr.BuildVisualization(StartStateIndex); 
	}

	simulated function SetupFirstStartTurnSeed()
	{
		local XComGameState_BattleData BattleData;
		local int StartStateIndex;
		local XComGameState StartState;
		local XComGameState_BaseObject BaseObj;
		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_BattleData(BaseObj)==none) Continue;
			BattleData=XComGameState_BattleData(BaseObj);
		}

		if (BattleData.bUseFirstStartTurnSeed)
		{
			class'Engine'.static.GetEngine().SetRandomSeeds(BattleData.iFirstStartTurnSeed);
		}
	}

	simulated function SetupUnits()
	{
		local XComGameState StartState;
		local int StartStateIndex;

		StartState = CachedHistory.GetStartState();
		
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();
		
			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}
		GetAllGroupsID();
		// only spawn AIs in SinglePlayer...
		StartStateSpawnAliens(StartState);
		GetAllGroupsID();

		// Spawn additional units ( such as cosmetic units like the Gremlin )
		StartStateSpawnCosmeticUnits(StartState);
		`log("Spawned Cosmetics");
		//Add new game object states to the start state.
		//*************************************************************************	
		StartStateCreateXpManager(StartState);
		`log("StartStateCreateXpManager");
		StartStateInitializeUnitAbilities(StartState);      //Examine each unit's start state, and add ability state objects as needed
		`log("StartStateInitializeUnitAbilities");
		StartStateInitializeSquads(StartState);
		`log("StartStateInitializeSquads");
		//*************************************************************************

	}

	//Used by the system if we are coming from strategy and did not use seamless travel ( which handles this internally )
	function MarkPlotUsed()
	{
		local XComGameState_BattleData BattleDataState;
		local int StartStateIndex;
		local XComGameState StartState;
		local XComGameState_BaseObject BaseObj;
		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}
		foreach StartState.IterateByClassType(class'XComGameState_BaseObject', BaseObj)
		{
			if(XComGameState_BattleData(BaseObj)==none) Continue;
			BattleDataState=XComGameState_BattleData(BaseObj);
		}

		// notify the deck manager that we have used this plot
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('Plots', BattleDataState.MapData.PlotMapName);
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('PlotTypes', ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName).strType);
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}
	
	function StartPlayerVisualizers()
	{
		local XComGameState StartState;
		local XComGameState_Player PlayerState;
		local XComGameState_Unit UnitState;
		local int StartStateIndex;
		StartState = CachedHistory.GetStartState();
		if (StartState == none)
		{
			StartStateIndex = CachedHistory.FindStartStateIndex();

			StartState = CachedHistory.GetGameStateFromHistory(StartStateIndex);

			`assert(StartState != none);

		}

		foreach StartState.IterateByClassType(class'XComGameState_Player', PlayerState)
		{	 
			class'XGPlayer'.static.CreateVisualizer(PlayerState);
		} 
		foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{	 
			PlayerState=XComGameState_Player(StartState.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
			class'XGUnit'.static.CreateVisualizer(StartState, UnitState, PlayerState);
		} 
	}

	simulated function GetAllGroupsID()
	{
		local XGAIGroup CurrentGroup;
		foreach `XWORLDINFO.AllActors(class'XGAIGroup', CurrentGroup)
		{
			if( CurrentGroup.m_kPlayer!=none )
			{
				`log("Current Group has a player ID:"@CurrentGroup.m_kPlayer.ObjectID);
			}
			else
				CurrentGroup.m_kPlayer= XGAIPlayer(`BATTLE.GetAIPlayer());

		}
	}
Begin:
	`SETLOC("Start of Begin Block");
	//Wait for the UI to initialize
	`assert(Pres != none); //Reaching this point without a valid presentation layer is an error
	
	// Added for testing with command argument for map name (i.e. X2_ObstacleCourse) otherwise mouse does not get initialized.
	//`ONLINEEVENTMGR.ReadProfileSettings();

	while( Pres.UIIsBusy() )
	{
		Sleep(0.0f);
	}
	
	//Show the soldiers riding to the mission while the map generates
	bShowDropshipInteriorWhileGeneratingMap = ShowDropshipInterior();
	if(bShowDropshipInteriorWhileGeneratingMap)
	{		
		`MAPS.AddStreamingMap(`MAPS.GetTransitionMap(), DropshipLocation, DropshipRotation, false);
		while(!`MAPS.IsStreamingComplete())
		{
			sleep(0.0f);
		}

		MarkPlotUsed();
				
		XComPlayerController(Pres.Owner).NotifyStartTacticalSeamlessLoad();

		WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

		//Let the dropship settle in
		Sleep(1.0f);

		//Stop any movies playing. HideLoadingScreen also re-enables rendering
		Pres.UIStopMovie();
		Pres.HideLoadingScreen();
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false);

		WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(FALSE);
	}
	else
	{
		//Will stop the HQ launch music if it is still playing ( which it should be, if we seamless traveled )
		`XTACTICALSOUNDMGR.StopHQMusicEvent();
	}

	//Generate the map and wait for it to complete
	GenerateMap();
	`log("Generated My Map",,'Team Dragonpunk Co Op');
	// Still rebuild the world data even if it is a static map except we need to wait for all the blueprints to resolve before
	// we build the world data.  In the case of a valid plot map, the parcel manager will build the world data at a step before returning
	// true from IsGeneratingMap
	if (GetBD().MapData.PlotMapName == "")
	{
		while (!`MAPS.IsStreamingComplete( ))
		{
			sleep( 0.0f );
		}

		ParcelManager.RebuildWorldData( );
	}

	while( ParcelManager.IsGeneratingMap() )
	{
		Sleep(0.0f);
	}

	AddDropshipStreamingCinematicMaps();

	//Wait for the drop ship and all other maps to stream in
	while (!`MAPS.IsStreamingComplete())
	{
		sleep(0.0f);
	}

	if(bShowDropshipInteriorWhileGeneratingMap)
	{
		WorldInfo.bContinueToSeamlessTravelDestination = false;
		XComPlayerController(Pres.Owner).NotifyLoadedDestinationMap('');
		while(!WorldInfo.bContinueToSeamlessTravelDestination)
		{
			Sleep(0.0f);
		}

		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
		`XTACTICALSOUNDMGR.StopHQMusicEvent();

		`MAPS.ClearPreloadedLevels();
		`MAPS.RemoveStreamingMapByName(`MAPS.GetTransitionMap(), false);
	}

	if( XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl() != none )
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(WorldInfo.GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();
		
		class'XComWeatherControl'.static.SetAllAsWet(CanToggleWetness());
	}
	else
	{
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (WorldInfo.m_kDominantDirectionalLight != none &&
		WorldInfo.m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(WorldInfo.m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}
	
	InitVolumes();

	WorldInfo.MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.TriggerTileDestruction();

	class'XComEngine'.static.AddEffectsToStartState();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	WorldInfo.MyLocalEnvMapManager.SetEnableCaptures(TRUE);

	`log("X2TacticalGameRuleset: Finished Generating Map", , 'XCom_GameStates');
	`log("Start State Positioning Units",,'Team Dragonpunk Co Op');
	
	//Position units already in the start state
	//*************************************************************************
	CachedHistory.RemoveHistoryLock();
	StartStatePositionUnits();
	//*************************************************************************

	// "spawn"/prespawn player and ai units
	SetupUnits();
	`log("Finished Setup Units",,'Team Dragonpunk Co Op');
	StartPlayerVisualizers();
	
	// load cinematic maps for units
	AddCharacterStreamingCinematicMaps();

	//Wait for any loading movie to finish playing
	while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		Sleep(0.0f);
	}

	// Add the default camera
	AddDefaultPathingCamera();

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled( true );
	}

	//Visualize the start state - in the most basic case this will create pawns, etc. and position the camera.
	BuildVisualizationForStartState();
	
	//Let the visualization blocks accumulated so far run their course ( which may include intro movies, etc. ) before continuing. 
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Create game states for actors in the map - Moved to be after the WaitingForVisualizers Block, otherwise the advent tower blueprints were not loaded yet
	//*************************************************************************
	CreateMapActorGameStates();
	//*************************************************************************

	//This needs to be called after CreateMapActorGameStates, to make sure Destructibles have their state objects ready.
	`PRES.m_kUnitFlagManager.AddFlags();

	//Bootstrap the visibility mgr with the start state
	VisibilityMgr.InitialUpdate();

	// For things like Challenge Mode that require a level seed for all the level generation and a differing seed for each player that enters, set the 
	// specific seed for all random actions hereafter. Additionally, do this before the BeginState_rulesAuthority submits its state context so that the
	// seed is baked into the first context.
	SetupFirstStartTurnSeed();

	// remove the lock that was added in CreateTacticalGame.BeginState
	//	the history is fair game again...

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while entering a tactical battle! This WILL result in buggy behavior during game play continued with this save.");

	//After this point, the start state is committed
	BeginState_RulesAuthority(none);

	// if we've still got a movie playing, kill it and fade the screen. this should only really happen from the 'open' console command.
	if (class'XComEngine'.static.IsLoadingMoviePlaying( ))
	{
		Pres.HideLoadingScreen( );
		XComTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).ClientSetCameraFade( false, , , 1.0f );		
	}

	//This is guarded internally from redundantly starting. Various different ways of entering the mission may have called this earlier.
	`XTACTICALSOUNDMGR.StartAllAmbience();

	//Initialization continues in the PostCreateTacticalGame state.
	//Further changes are not part of the Tactical Game start state.
	`log("Finished Creating Game",,'Team Dragonpunk Co Op');

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

simulated state TurnPhase_UnitActions
{
	simulated event BeginState(name PreviousStateName)
	{
		local XComGameState_BattleData BattleData;	

		if( !bLoadingSavedGame )
		{
			BeginState_RulesAuthority(SetupUnitActionsState);
		}

		BattleData = GetBD();
		`assert(BattleData.PlayerTurnOrder.Length > 0);

		InitializePlayerTurnOrder();
		BeginUnitActions();
		
		//Clear the loading flag - it is only relevant during the 'next player' determination
		//bLoadingSavedGame = false;
		bSkipRemainingTurnActivty_B = false;
	}

	simulated function InitializePlayerTurnOrder()
	{
		UnitActionPlayerIndex = -1;
	}

	simulated function SetupUnitActionsState(XComGameState NewPhaseState)
	{
		//  This code has been moved to the player turn observer, as units need to reset their actions
		//  only when their player turn changes, not when the over all game turn changes over.
		//  Leaving this function hook for future implementation needs. -jbouscher
	}

	simulated function SetupUnitActionsForPlayerTurnBegin(XComGameState NewGameState)
	{
		local XComGameState_Unit UnitState;
		local XComGameState_Unit NewUnitState;
		local XComGameState_Player NewPlayerState;

		// clear the streak counters on this player
		NewPlayerState = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', CachedUnitActionPlayerRef.ObjectID));
		NewPlayerState.MissStreak = 0;
		NewPlayerState.HitStreak = 0;
		NewGameState.AddStateObject(NewPlayerState);

		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			// Only process units that belong to the player whose turn it now is
			if (UnitState.ControllingPlayer.ObjectID != CachedUnitActionPlayerRef.ObjectID)
			{
				continue;
			}

			// Create a new state object on NewPhaseState for UnitState
			NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewUnitState.SetupActionsForBeginTurn();
			// Add the updated unit state object to the new game state
			NewGameState.AddStateObject(NewUnitState);
		}	
	}

	simulated function BeginUnitActions()
	{
		NextPlayer();
	}

	simulated function bool NextPlayer()
	{
		EndPlayerTurn();
		`log("Player turn ended");
		if(HasTacticalGameEnded())
		{
			// if the tactical game has already completed, then we need to bail before
			// initializing the next player, as we do not want any more actions to be taken.
			return false;
		}

		++UnitActionPlayerIndex;
		return BeginPlayerTurn();
	}

	simulated function bool BeginPlayerTurn()
	{
		local XComGameStateContext_TacticalGameRule Context;
		local XComGameState_BattleData BattleData;
		local XComGameState_Player PlayerState;
		local X2EventManager EventManager;
		local XComGameState NewGameState;
		local XGPlayer PlayerStateVisualizer;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;
		local XComGameState_AIPlayerData IterateAIData,AIDataState;
	
		`log("Player turn begun");

		EventManager = `XEVENTMGR;
		BattleData = GetBD();
		`assert(BattleData.PlayerTurnOrder.Length > 0);

		if( UnitActionPlayerIndex < BattleData.PlayerTurnOrder.Length )
		{
			CachedUnitActionPlayerRef = BattleData.PlayerTurnOrder[UnitActionPlayerIndex];

			//Don't process turn begin/end events if we are loading from a save
			if( !bLoadingSavedGame )
			{
				// before the start of each player's turn, submit a game state resetting that player's units' per-turn values (like action points remaining)
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SetupUnitActionsForPlayerTurnBegin");
				SetupUnitActionsForPlayerTurnBegin(NewGameState);
				// Moved this down here since SetupUnitActionsForPlayerTurnBegin needs to reset action points before 
				// OnUnitActionPhaseBegun_NextPlayer calls GatherUnitsToMove.
				PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
				foreach CachedHistory.IterateByClassType(Class'XComGameState_AIPlayerData',IterateAIData)
				{
					if(IterateAIData.m_iPlayerObjectID==PlayerState.ObjectID)
					{
						`log("Found AI data with same ID as"@PlayerState.GetTeam() @"Player, ID:"@IterateAIData.m_iPlayerObjectID);
						AIDataState=IterateAIData;
					}
				}
				`log("GetAIPlayer is:"@XGAIPlayer(`BATTLE.GetAIPlayer())!=none);
				if(AIDataState==none && PlayerState.IsAIPlayer())
				{
						XGAIPlayer(`BATTLE.GetAIPlayer()).AddNewSpawnAIData(NewGameState);
				}
				SubmitGameState(NewGameState);

				
				
				//Notify the player state's visualizer that they are now the unit action player
				`assert(PlayerState != none);
				PlayerStateVisualizer = XGPlayer(PlayerState.GetVisualizer());
				PlayerStateVisualizer.OnUnitActionPhaseBegun_NextPlayer();  // This initializes the AI turn 

				// Trigger the PlayerTurnBegun event
				EventManager.TriggerEvent( 'PlayerTurnBegun', PlayerState, PlayerState );

				// build a gamestate to mark this beginning of this players turn
				Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnBegin);
				Context.PlayerRef = CachedUnitActionPlayerRef;				
				`log("PlayerState:"@PlayerState!=none,,'Team Dragonpunk Co Op');
				SubmitGameStateContext(Context);
			}

			ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );
			if ((ChallengeData != none) && !UnitActionPlayerIsAI( ))
			{
				TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_TimerData' ) );
				TimerState.bStopTime = false;
			}

			//Uncomment if there are persistent lines you want to refresh each turn
			//WorldInfo.FlushPersistentDebugLines();

			`XTACTICALSOUNDMGR.EvaluateTacticalMusicState();
			return true;
		}
		return false;
	}

	simulated function EndPlayerTurn()
	{
		local XComGameStateContext_TacticalGameRule Context;
		local XComGameState_Player PlayerState;
		local X2EventManager EventManager;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;

		EventManager = `XEVENTMGR;
		if( UnitActionPlayerIndex > -1 )
		{
			//Notify the player state's visualizer that they are no longer the unit action player
			PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
			`assert(PlayerState != none);
			XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhaseFinished_NextPlayer();

			//Don't process turn begin/end events if we are loading from a save
			if( !bLoadingSavedGame )
			{
				EventManager.TriggerEvent( 'PlayerTurnEnded', PlayerState, PlayerState );

				// build a gamestate to mark this end of this players turn
				Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnEnd);
				Context.PlayerRef = CachedUnitActionPlayerRef;				
				SubmitGameStateContext(Context);
			}


			ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );
			if ((ChallengeData != none) && !UnitActionPlayerIsAI( ))
			{
				TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_TimerData' ) );
				TimerState.bStopTime = true;
			}
		}
	}

	simulated function bool UnitHasActionsAvailable(XComGameState_Unit UnitState)
	{
		local GameRulesCache_Unit UnitCache;
		local AvailableAction Action;

		if (UnitState == none)
			return false;

		//Check whether this unit is controlled by the UnitActionPlayer
		if (UnitState.ControllingPlayer.ObjectID == CachedUnitActionPlayerRef.ObjectID ||
			UnitState.ObjectID == PriorityUnitRef.ObjectID)
		{
			if (!UnitState.GetMyTemplate().bIsCosmetic &&
				!UnitState.IsPanicked() &&
				(UnitState.AffectedByEffectNames.Find(class'X2Ability_Viper'.default.BindSustainedEffectName) == INDEX_NONE))
			{
				GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache);
				foreach UnitCache.AvailableActions(Action)
				{
					if (Action.bInputTriggered && Action.AvailableCode == 'AA_Success')
					{
						return true;
					}
				}
			}
		}

		return false;
	}

	simulated function bool ActionsAvailable()
	{
		local XGPlayer ActivePlayer;
		local XComGameState_Unit UnitState;
		local XComGameState_Player PlayerState;
		local bool bActionsAvailable;

		// Turn was skipped, no more actions
		if (bSkipRemainingTurnActivty_B)
		{
			return false;
		}

		bActionsAvailable = false;

		ActivePlayer = XGPlayer(CachedHistory.GetVisualizer(CachedUnitActionPlayerRef.ObjectID));

		if (ActivePlayer.m_kPlayerController != none)
		{
			// Check current unit first, to ensure we aren't switching away from a unit that has actions (XComTacticalController::OnVisualizationIdle also switches units)
			UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(ActivePlayer.m_kPlayerController.ControllingUnit.ObjectID));
			bActionsAvailable = UnitHasActionsAvailable(UnitState);
		}

		if (!bActionsAvailable)
		{
			foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				bActionsAvailable = UnitHasActionsAvailable(UnitState);

				if (bActionsAvailable)
				{
					break; // once we find an action, no need to keep iterating
				}
			}
		}

		if( bActionsAvailable )
		{
			bWaitingForNewStates = true;	//If there are actions available, indicate that we are waiting for a decision on which one to take

			if( !UnitActionPlayerIsRemote() )
			{				
				PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
				`assert(PlayerState != none);
				XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhase_ActionsAvailable(UnitState);
			}
		}

		return bActionsAvailable;
	}

	simulated function EndPhase()
	{
		if (HasTacticalGameEnded())
		{
			GotoState( 'EndTacticalGame' );
		}
		else
		{
			GotoState( GetNextTurnPhase( GetStateName() ) );
		}
	}

	function FailsafeCheckForTacticalGameEnded()
	{
		local int Index;
		local KismetGameRulesetEventObserver KismetObserver;

		if (!HasTacticalGameEnded())
		{
			//Do a last check at the end of the unit action phase to see if any players have lost all their playable units
			for (Index = 0; Index < EventObservers.Length; ++Index)
			{
				KismetObserver = KismetGameRulesetEventObserver(EventObservers[Index]);
				if (KismetObserver != none)
				{
					KismetObserver.CheckForTeamHavingNoPlayableUnitsExternal();
					break;
				}
			}
		}		
	}

	simulated function string GetStateDebugString()
	{
		local string DebugString;
		local XComGameState_Player PlayerState;
		local int UnitCacheIndex;
		local int ActionIndex;
		local XComGameState_Unit UnitState;				
		local XComGameState_Ability AbilityState;
		local AvailableAction AvailableActionData;
		local string EnumString;

		PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));

		DebugString = "Unit Action Player  :"@((PlayerState != none) ? string(PlayerState.GetVisualizer()) : "PlayerState_None")@" ("@CachedUnitActionPlayerRef.ObjectID@") ("@ (UnitActionPlayerIsRemote() ? "REMOTE" : "") @")\n";
		DebugString = DebugString$"Begin Block Location: " @ BeginBlockWaitingLocation @ "\n\n";
		DebugString = DebugString$"Internal State:"@ (bWaitingForNewStates ? "Waiting For Player Decision" : "Waiting for Visualizer") @ "\n\n";
		DebugString = DebugString$"Unit Cache Info For Unit Action Player:\n";

		for( UnitCacheIndex = 0; UnitCacheIndex < UnitsCache.Length; ++UnitCacheIndex )
		{
			UnitState = XComGameState_Unit(CachedHistory.GetGameStateForObjectID(UnitsCache[UnitCacheIndex].UnitObjectRef.ObjectID));

			//Check whether this unit is controlled by the UnitActionPlayer
			if( UnitState.ControllingPlayer.ObjectID == CachedUnitActionPlayerRef.ObjectID ) 
			{			
				DebugString = DebugString$"Unit: "@((UnitState != none) ? string(UnitState.GetVisualizer()) : "UnitState_None")@"("@UnitState.ObjectID@") [HI:"@UnitsCache[UnitCacheIndex].LastUpdateHistoryIndex$"] ActionPoints:"@UnitState.NumAllActionPoints()@" (Reserve:" @ UnitState.NumAllReserveActionPoints() $") - ";
				for( ActionIndex = 0; ActionIndex < UnitsCache[UnitCacheIndex].AvailableActions.Length; ++ActionIndex )
				{
					AvailableActionData = UnitsCache[UnitCacheIndex].AvailableActions[ActionIndex];

					AbilityState = XComGameState_Ability(CachedHistory.GetGameStateForObjectID(AvailableActionData.AbilityObjectRef.ObjectID));
					EnumString = string(AvailableActionData.AvailableCode);
					
					DebugString = DebugString$"("@AbilityState.GetMyTemplateName()@"-"@EnumString@") ";
				}
				DebugString = DebugString$"\n";
			}
		}

		return DebugString;
	}

	event Tick(float DeltaTime)
	{		
		local XComGameState_Player PlayerState;
		local XGAIPlayer AIPlayer;
		local int fTimeOut;
		local XComGameState_ChallengeData ChallengeData;
		local XComGameState_TimerData TimerState;
		local XGPlayer Player;

		//rmcfall - if the AI player takes longer than 25 seconds to make a decision a blocking error has occurred in its logic. Skip its turn to avoid a hang.
		//This logic is redundant to turn skipping logic in the behaviors, and is intended as a last resort
		if( UnitActionPlayerIsAI() && bWaitingForNewStates && !(`CHEATMGR != None && `CHEATMGR.bAllowSelectAll) )
		{
			PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));
			AIPlayer = XGAIPlayer(PlayerState.GetVisualizer());

			if (AIPlayer.m_eTeam == eTeam_Neutral)
			{
				fTimeOut = 5.0f;
			}
			else
			{
				fTimeOut = 25.0f;
			}
			WaitingForNewStatesTime += DeltaTime;
			if (WaitingForNewStatesTime > fTimeOut && !`REPLAY.bInReplay)
			{
				`LogAIActions("Exceeded WaitingForNewStates TimeLimit"@WaitingForNewStatesTime$"s!  Calling AIPlayer.EndTurn()");
				AIPlayer.OnTimedOut();
				class'XGAIPlayer'.static.DumpAILog();
				AIPlayer.EndTurn(ePlayerEndTurnType_AI);
			}
		}

		ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) );
		if ((ChallengeData != none) && !UnitActionPlayerIsAI() && !WaitingForVisualizer())
		{
			TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_TimerData') );
			if (TimerState.GetCurrentTime() <= 0)
			{
				PlayerState = XComGameState_Player( CachedHistory.GetGameStateForObjectID( CachedUnitActionPlayerRef.ObjectID ) );
				Player = XGPlayer(PlayerState.GetVisualizer());

				EndBattle( Player );
			}
		}
	}

	function StateObjectReference GetCachedUnitActionPlayerRef()
	{
		return CachedUnitActionPlayerRef;
	}

	function CheckForAutosave()
	{

		if (RulesetShouldAutosave())
		{
			`AUTOSAVEMGR.DoAutosave(); 
		}
	}

Begin:
	`SETLOC("Start of Begin Block");
	CachedHistory.CheckNoPendingGameStates();

	//Loop through the players, allowing each to perform actions with their units
	do
	{	
		sleep(0.0); // Wait a tick for the game states to be updated before switching the sending
		
		//Before switching players, wait for the current player's last action to be fully visualized
		while( WaitingForVisualizer() )
		{
			`SETLOC("Waiting for Visualizer: 1");
			sleep(0.0);
		}

		// autosave after the visualizer finishes doing it's thing and control is being handed over to the player. 
		// This guarantees that any pre-turn behavior tree or other ticked decisions have completed modifying the history.
		CheckForAutosave();

		`SETLOC("Check for Available Actions");
		while( ActionsAvailable() && !HasTacticalGameEnded() )
		{
			WaitingForNewStatesTime = 0.0f;

			//Wait for new states created by the player / AI / remote player. Manipulated by the SubmitGameStateXXX methods
			while( bWaitingForNewStates && !HasTimeExpired())
			{
				`SETLOC("Available Actions");
				sleep(0.0);
			}
			`SETLOC("Available Actions: Done waiting for New States");

			CachedHistory.CheckNoPendingGameStates();

			if( `CHEATMGR.bShouldAutosaveBeforeEveryAction )
			{
				`AUTOSAVEMGR.DoAutosave();
			}
			sleep(0.0);
		}

		`SETLOC("Checking for Tactical Game Ended");
		//Perform fail safe checking for whether the tactical battle is over
		FailsafeCheckForTacticalGameEnded();

		while( WaitingForVisualizer() )
		{
			`SETLOC("Waiting for Visualizer: 2");
			sleep(0.0);
		}

		// Moved to clear the SkipRemainingTurnActivty flag until after the visualizer finishes.  Prevents an exploit where
		// the end/back button is spammed during the player's final action. Previously the Skip flag was set to true 
		// while visualizing the action, after the flag was already cleared, causing the subsequent AI turn to get skipped.
		bSkipRemainingTurnActivty_B = false;
		`SETLOC("Going to the Next Player");
	}until( !NextPlayer() ); //NextPlayer returns false when the UnitActionPlayerIndex has reached the end of PlayerTurnOrder in the BattleData state.
	
	//Wait for the visualizer to perform the visualization steps for all states before we permit the rules engine to proceed to the next phase
	while( WaitingForVisualizer() )
	{
		`SETLOC("Waiting for Visualizer: 3");
		sleep(0.0);
	}

	// Failsafe. Make sure there are no active camera anims "stuck" on
	GetALocalPlayerController().PlayerCamera.StopAllCameraAnims(TRUE);

	`SETLOC("Updating AI Activity");
	UpdateAIActivity(false);

	CachedHistory.CheckNoPendingGameStates();

	`SETLOC("Ending the Phase");
	EndPhase();
	`SETLOC("End of Begin Block");
}

