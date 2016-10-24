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
var protected bool bSendingPartialHistory_True;                      //True whenever a send has occurred, but a receive has not yet returned.
var protected bool bRequestedPartialHistory;                      //True whenever a send has occurred, but a receive has not yet returned.
var protected bool bSentPartialHistory;                      //True whenever a send has occurred, but a receive has not yet returned.
var protected bool bRecievedPartialHistory;                      //True whenever a send has occurred, but a receive has not yet returned.
var protected bool bWaitingForEndTacticalGame;
var protected bool b_WaitingForClient;
var protected bool bRulesetRunning;                             //the rulese has fully initialized, downloaded histories, and is now running
var protected XComCoOpReplayMgr ReplayMgr;
`define SETLOC(LocationString)	BeginBlockWaitingLocation = GetStateName() $ ":" @ `LocationString;
var protected bool bLocalPlayerForfeited;
var protected bool bDisconnected;
var protected bool bShouldDisconnect;
var protected bool bReceivedNotifyConnectionClosed;

var int ContextBuildDepthRep;

var bool OtherSideEndedReplay;
var bool bSendingTurnHistory;
var bool FirstTurn;
var bool bReadyForTurnHistory;
var bool bReadyForHistory;
var bool bSyncedWithSource;
var bool SendHistoryThisTurn;
var bool bClientPrepared;
var bool bPauseReplay;
var bool bSendRecieveResponse;
var bool HasEndedLocalTurn;
var bool bServerEndedTurn;
var bool Launched;
var protected bool ConfirmClientHistory;
var protected bool bRecivedHistoryTurnEnd;
var protected bool bStartedGame;
var protected int TurnCounterFixed;
var protected bool UseTurnCounterFixed;
//********************************************************

var TDialogueBoxData DialogData;

var UIScreen DialogScreen;

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


simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	ChangeInviteAcceptedDelegates();
	// Cache a pointer to the online subsystem
	if (class'GameEngine'.static.GetOnlineSubsystem() != None)
	{
		// And grab one for the game interface since it will be used often
		OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).AddLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	}
	SubscribeToOnCleanupWorld();
}


simulated event OnCleanupWorld()
{
	Destroyed();

	super.OnCleanupWorld();
}


simulated event Destroyed()
{
	RevertInviteAcceptedDelegates();
	if( bShouldDisconnect )
	{
		DisconnectGame();
	}
	else
	{
		NetworkMgr.ResetConnectionData();
	}
	super.Destroyed();
}

function ChangeInviteAcceptedDelegates()
{	
                                            
	`XCOMNETMANAGER.AddReceiveHistoryDelegate(ReceiveHistory);
	`XCOMNETMANAGER.AddReceivePartialHistoryDelegate(ReceivePartialHistory);
	`XCOMNETMANAGER.AddReceiveGameStateDelegate(ReceiveGameState);
	`XCOMNETMANAGER.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	`XCOMNETMANAGER.AddReceiveRemoteCommandDelegate(OnRemoteCommand);
	`XCOMNETMANAGER.AddReceiveGameStateContextDelegate(ReceiveGameStateContext);

}

function RevertInviteAcceptedDelegates()
{	

	OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	
	`XCOMNETMANAGER.ClearReceiveHistoryDelegate(ReceiveHistory);
	`XCOMNETMANAGER.ClearReceivePartialHistoryDelegate(ReceivePartialHistory);
	`XCOMNETMANAGER.ClearReceiveGameStateDelegate(ReceiveGameState);
	`XCOMNETMANAGER.ClearReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	`XCOMNETMANAGER.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
	`XCOMNETMANAGER.ClearReceiveGameStateContextDelegate(ReceiveGameStateContext);
}


function XComCoOpReplayMgr GetReplayMgr()
{
	if( ReplayMgr == none )
	{
		ReplayMgr = XComCoOpReplayMgr(XComMPCOOPGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr);
	}
	return ReplayMgr;
}

function SendRemoteCommand(string Command)
{
	local array<byte> EmptyParams;
	EmptyParams.Length = 0; // Removes script warning
	NetworkMgr.SendRemoteCommand(Command, EmptyParams);
	`log("Command Sent:"@Command,,'Dragonpunk Tactical');
}


function SendStopTime()
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`log("Send Stop Time", , 'XCom_Online');
	`XCOMNETMANAGER.SendRemoteCommand("StopTime", Parms);
}

function SendUpdateTime()
{
	local array<byte> Parms;
	Parms.AddItem(byte(0)); // Removes script warning.
	`log("Send Stop Time", , 'XCom_Online');
	`XCOMNETMANAGER.SendRemoteCommand("UpdateTime", Parms);
}

function ReceiveGameState(XComGameState InGameState)
{
	`log(`location,,'Team Dragonpunk Co Op');
}

function ReceiveMergeGameState(XComGameState InGameState)
{
	`log(`location @"Recieved Merge GameState Connection Setup",,'Team Dragonpunk Co Op');
}

simulated function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	bRecievedPartialHistory=true;
	SendRemoteCommand("HistoryReceived");
	RebuildLocalStateObjectCache();
}


function ReceiveGameStateContext(XComGameStateContext Context)
{
	`log(`location,,'Dragonpunk Tactical Co Op');
	//SubmitGameStateInternal(Context.ContextBuildGameState(), false, false);	
	if(`XCOMNETMANAGER.HasServerConnection())SendPartialHistory();
}

simulated function RebuildLocalStateObjectCache()
{
	local XComGameStateContext_TacticalGameRule Context;
	local XComGameState_XpManager XpManager;	
	local XComGameState_Unit UnitState;
	local GameRulesCache_Unit UnitCache;
	local AvailableAction Action;
	local XComGameState_BattleData BattleData;
	local StateObjectReference EmptyRef;
	local int i;

	CachedHistory=`XCOMHISTORY;
	// Get a reference to the BattleData for this tactical game
	BattleData = XComGameState_BattleData(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	CachedBattleDataRef = BattleData.GetReference();

	// Find the Unit Action Player
	CachedUnitActionPlayerRef = EmptyRef;
	foreach CachedHistory.IterateContextsByClassType(class'XComGameStateContext_TacticalGameRule', Context)
	{
		if(Context.GameRuleType == eGameRule_PlayerTurnBegin) 
		{
			CachedUnitActionPlayerRef = Context.PlayerRef;
			break;
		}
	}

	// Get the Index for the player
	UnitActionPlayerIndex = -1;
	for( i = 0; i < BattleData.PlayerTurnOrder.Length; ++i )
	{
		if( BattleData.PlayerTurnOrder[i] == CachedUnitActionPlayerRef )
		{
			UnitActionPlayerIndex = i;
			break;
		}
	}

	foreach CachedHistory.IterateByClassType(class'XComGameState_XpManager', XpManager, eReturnType_Reference)
	{
		CachedXpManagerRef = XpManager.GetReference();
		break;
	}

	foreach CachedHistory.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		//Check whether this unit is controlled by the UnitActionPlayer
		if( UnitState.ControllingPlayer.ObjectID == CachedUnitActionPlayerRef.ObjectID ||
			UnitState.ObjectID == PriorityUnitRef.ObjectID) 
		{				
			if( UnitState.NumAllActionPoints() > 0 && !UnitState.GetMyTemplate().bIsCosmetic )
			{
				GetGameRulesCache_Unit(UnitState.GetReference(), UnitCache);
				foreach UnitCache.AvailableActions(Action)
				{
					if (Action.bInputTriggered && Action.AvailableCode == 'AA_Success')
					{
						break;
					}
				}
			}
		}
	}
}


simulated function ReceivePartialHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	`log(`location @"Received Partial History");
	ReceiveHistory(InHistory, EventManager);
	CachedHistory=`XCOMHISTORY;
}

simulated function LoadMap()
{
	local XComGameState_BattleData CachedBattleData;
	
	//Check whether the map has been generated already
	if( ParcelManager.arrParcels.Length == 0 )
	{	
		`MAPS.RemoveAllStreamingMaps(); //Generate map requires there to be NO streaming maps when it starts

		CachedBattleData = XComGameState_BattleData(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
		ParcelManager.LoadMap(CachedBattleData);
	}
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	if( Command ~= "RecievedHistory" || Command ~= "HistoryReceived" )
	{
		bSendingPartialHistory = false;
		bSendingPartialHistory_True = false;
		CachedHistory=`XCOMHISTORY;
	}
	else if(Command~= "EndOfReplay")
	{
		OtherSideEndedReplay=true;
	}
	else if( Command ~= "ReadyForTurnHistory")
	{
		bReadyForTurnHistory=true;
	}
	else if( Command ~= "RequestTurnHistory")
	{
		SendHistory();
	}
	else if (Command ~="HistoryRequested")
	{
		bSentPartialHistory=true;
		SendRemoteCommand("SendingHistory");
	}
	else if( Command~= "SendingHistory")
	{
		bRequestedPartialHistory=true;
	}
	else if( Command ~= "SwitchTurn" )
	{
		// Stop replaying, and give player control
		PopState();
		GetReplayMgr().RequestPauseReplay();
		bPauseReplay=true;
		HasEndedLocalTurn=false;
		if(`XCOMNETMANAGER.HasClientConnection())
			bServerEndedTurn=true;
	}
	else if(Command ~="ReadyForFinalHistory")
	{
		bSendingPartialHistory=bRecievedPartialHistory;
		bRecievedPartialHistory=false;
		SendRemoteCommand("SendFinalHistory");
	}
	else if( Command ~= "SendFinalHistory" )
	{
		bReadyForHistory=true;	
	}
	else if( Command ~= "ClientReadyForAITurn" )
	{
		bClientPrepared=true;
	}
	else if( Command ~= "SwitchTurnNonXCom" )
	{
		// Stop replaying, and give player control
		bPauseReplay=true;
		HasEndedLocalTurn=false;
		bClientPrepared=false;
		if(`XCOMNETMANAGER.HasClientConnection())
			bServerEndedTurn=true;
		PopState();
		GetReplayMgr().RequestPauseReplay();
		`log("Requested Pause Play");
	}
	else if( Command ~= "EndTacticalGame" )
	{
		// Stop replaying, and give player control
		PopState();
		GetReplayMgr().RequestPauseReplay();
	}
	else if( Command ~= "ForfeitMatch" )
	{
	//	HandleForfeitMatch(RawParams);
	}
	else if( Command ~= "ServerRequestEndTurn")
	{
		SendRemoteCommand("ServerEndTurn");
		bServerEndedTurn=true;
	}
	else if( Command ~= "ServerEndTurn")
	{
		bServerEndedTurn=true;
	}
	else if( Command ~= "Heartbeat")
	{
		`log("Got Heartbeat");
	}
	else if( Command ~= "ReadyForPartial")
	{
		if(!(string(GetStateName())~="PerformingReplay"))
			PushState('PerformingReplay');

		GetReplayMgr().ResumeReplay();
		`log("Got Partial Ready!");
		SendRemoteCommand("ReadyToReceive");
	}
	else if( Command ~= "ReadyToReceive")
	{
		SendPartialHistoryTrue();
	}
	else if( Command ~= "XComTurnEnded")
	{
		bSkipRemainingTurnActivty_B=true;
	}
	`log("Command Recieved:"@Command,,'Dragonpunk Tactical');
}

function ResumeReplay()
{
	return;
}

function bool SendPartialHistory()
{
	`log(`location @"Send Partial History Function");
	if( (!bSendingPartialHistory && !GetReplayMgr().bInReplay && !HasEndedLocalTurn) )
	{
		bSendingPartialHistory = true;
		SendRemoteCommand("ReadyForPartial");	
		return true;
	}
	return false;
}

function bool SendPartialHistoryTrue(optional bool bForce=false)
{
	// Send the history if we are forced or in the network mode where we want to send the history and we are currently not sending the history
	`log(`location @"Send Partial History TRUE!! Function");
	if( (!bSendingPartialHistory_True&&!GetReplayMgr().bInReplay && !HasEndedLocalTurn) || bForce )
	{
		bSendingPartialHistory_True=true;
		SendHistoryThisTurn=true;
		`log(`location @"Sending the Partial History Now");
		`XCOMNETMANAGER.SendPartialHistory(`XCOMHISTORY, `XEVENTMGR);
	}

	// Will default to false unless a history has been sent, in which case it will remain true until the other side responds that it got the history
	return bSendingPartialHistory;
}

function DisconnectGame()
{
	bDisconnected = true;
	NetworkMgr.Disconnect();
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');
}
simulated function LoadGame()
{
	//Build a local cache of useful state object references
	BuildLocalStateObjectCache();

	GotoState('LoadCoOpTacticalGame');
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
		//GotoState('ConnectionClosed');
		DisconnectGame();
	}
}

simulated function name GetNextTurnPhase(name CurrentState, optional name DefaultPhaseName='TurnPhase_End')
{
	local name LastState;
	switch (CurrentState)
	{
	case 'CreateTacticalGame':
		return 'PostCreateTacticalGame';
	case 'LoadCoopTacticalGame':
		
		if (LoadedGameNeedsPostCreate())
		{
			return 'PostCreateTacticalGame';
		}
		if( XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay )
		{
			return 'PerformingReplay';
		}
		LastState = GetLastStateNameFromHistory();
		return (LastState == '' || LastState == 'LoadTacticalGame') ? 'TurnPhase_UnitActions' : GetNextTurnPhase(LastState, 'TurnPhase_UnitActions');
	case 'PostCreateTacticalGame':
		if (CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) != none)
			return 'TurnPhase_StartTimer';

		return 'TurnPhase_Begin';
	case 'TurnPhase_Begin':		
		return 'TurnPhase_UnitActions';
	case 'TurnPhase_UnitActions':
		return 'TurnPhase_End';
	case 'TurnPhase_End':
		return 'TurnPhase_Begin';
	case 'PerformingReplay':
		if (!XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay || XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInTutorial)
		{
			//Used when resuming from a replay, or in the tutorial and control has "returned" to the player
			return 'TurnPhase_Begin';
		}
	case 'CreateChallengeGame':
		return 'TurnPhase_StartTimer';
	case 'TurnPhase_StartTimer':
		return 'TurnPhase_Begin';
	}
	`assert(false);
	return DefaultPhaseName;
}

exec function SendToConsole(string Command)
{
	if (LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player) != None)
	{
		LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ViewportClient.ViewportConsole.ConsoleCommand(Command);
	}
}

function SendHistory()
{
	`log(`location,,'XCom_Online');
	bSendingPartialHistory=true;
	SendRemoteCommand("SendingHistory");
	`XCOMNETMANAGER.SendHistory(`XCOMHISTORY, `XEVENTMGR);
}

function SendTurnHistoryTrue()
{
	`log(`location,,'XCom_Online');
	bSendingTurnHistory=true;
	`XCOMNETMANAGER.SendHistory(`XCOMHISTORY, `XEVENTMGR);		
}	

function SendTurnHistory()
{
	`log(`location @"Send Turn History",,'XCom_Online');
	SendRemoteCommand("ReadyForTurnHistory");
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

simulated function bool PlayerIsRemote(int PlayerTurnNum)
{
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(GetBD().PlayerTurnOrder[PlayerTurnNum].ObjectID));

	return (PlayerState.GetTeam()!=eTeam_XCom);
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

	return HasTimeExpired()||(TurnCounterFixed<=0 && UseTurnCounterFixed);
}

static function OnNewGameState_GameWatcher(XComGameState GameState) //Thank you Amineri and LWS! 
{
	`XCOMNETMANAGER.SendGameState(GameState,GameState.HistoryIndex);
}

simulated State LoadCoOpTacticalGame extends LoadTacticalGame
{
	simulated function SendHeartbeat()
	{
		SendRemoteCommand("Heartbeat");	
		`log("Sent Heartbeat");
	}
	Begin:
	`SETLOC("Start of Begin Block");

	LoadMap();
	SendHeartbeat();
	AddCharacterStreamingCinematicMaps(true);

	while( ParcelManager.IsGeneratingMap() )
	{
		Sleep(0.0f);
	}
	if(XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).WeatherControl() != none)
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();

		class'XComWeatherControl'.static.SetAllAsWet(CanToggleWetness());
	}
	else
	{
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight != none &&
		class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}

	InitVolumes();
	class'WorldInfo'.static.GetWorldInfo().MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	class'WorldInfo'.static.GetWorldInfo().MyLocalEnvMapManager.SetEnableCaptures(true);
	
	class'XComEngine'.static.UpdateGI();

	RefreshEventManagerUnitRegistration();

	//Have the event manager check for errors
	`XEVENTMGR.ValidateEventManager("while loading a saved game! This WILL result in buggy behavior during game play continued with this save.");

	// Update visibility before updating the visualizers as this affects Tactical HUD ability caching
	VisibilityMgr.InitialUpdate();

	//If the load occurred from UnitActions, mark the ruleset as loading which will instigate the loading procedure for 
	//mid-UnitAction save (suppresses player turn events). This will be false for MP loads, and true for singleplayer saves.
	// raasland - except it wasn't being set to true for SP and breaking turn start tick effects
	//bLoadingSavedGame = true;

	//Wait for the presentation layer to be ready
	while(Pres.UIIsBusy())
	{
		Sleep(0.0f);
	}
	
	// Add the default camera
	AddDefaultPathingCamera( );

	Sleep(0.1f);
	SendHeartbeat();
	BuildVisualizationForStartState();

	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Sync visualizers to the proper state ( variable depending on whether we are performing a replay or loading a save game to play )
	SyncVisualizationMgr();

	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Wait for any units that are ragdolling to stop
	while(AnyUnitsRagdolling())
	{
		sleep(0.0f);
	}
		
	// remove all the replacement actors that have been replaced
	`SPAWNMGR.CleanupReplacementActorsOnLevelLoad();

	//Create game states for actors in the map - Moved to be after the WaitingForVisualizers Block, otherwise the advent tower blueprints were not loaded yet
	//	added here to account for actors which may have changed between when the save game was created and when it was loaded
	//*************************************************************************
	CreateMapActorGameStates();
	//*************************************************************************

	//This needs to be called after CreateMapActorGameStates, to make sure Destructibles have their state objects ready.
	Pres.m_kUnitFlagManager.AddFlags();

	//Flush cached visibility data now that the visualizers are correct for all the viewers and the cached visibility system uses visualizers as its inputs
	`XWORLD.FlushCachedVisibility();

	//Flush cached unit rules, because they can be affected by not having visualizers ready (pre-SyncVisualizationMgr)
	UnitsCache.Length = 0; 

	VisibilityMgr.ActorVisibilityMgr.OnVisualizationIdle(); //Force all visualizers to update their visualization state

	if (UnitRadiusManager != none)
	{
		UnitRadiusManager.SetEnabled( true );
	}

	CachedHistory.CheckNoPendingGameStates();

	SetupDeadUnitCache();
	SendHeartbeat();	
	//Signal that we are done
	bProcessingLoad = false; 

	//Destructible objects - those with states created in CreateMapActorGameStates - were not caught by the previous full visibility update.
	//Force another visibility update, just before we prod the HUD, to make sure that those are targetable immediately on load.
	//(By the looks of the existing comments, I don't think it's possible to order the code such that one update is sufficient.)
	//TTP 8268 / btopp 2015.10.15
	VisibilityMgr.InitialUpdate();

	Pres.m_kTacticalHUD.ForceUpdate(-1);

	if (`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		SetupFirstStartTurnSeed();
	}

	//Achievement event listeners do not survive the serialization process. Adding them here.
	`XACHIEVEMENT_TRACKER.Init();

	if(`REPLAY.bInTutorial)
	{
		// Force an update of the save game list, otherwise our tutorial replay save is shown in the load/save screen
		`ONLINEEVENTMGR.UpdateSaveGameList();

		//Allow the user to skip the movie now that the major work / setup is done
		`XENGINE.SetAllowMovieInput(true);

		while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
		{
			Sleep(0.0f);
		}
		
		TutorialIntro = XComNarrativeMoment(`CONTENT.RequestGameArchetype("X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_PostIntro"));
		Pres.UINarrative(TutorialIntro);		
	}

	//Movie handline - for both the tutorial and normal loading
	while(class'XComEngine'.static.IsAnyMoviePlaying() && !class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		Sleep(0.0f);
	}

	if(class'XComEngine'.static.IsLoadingMoviePlaying())
	{
		//Set the screen to black - when the loading move is stopped the renderer and game will be initializing lots of structures so is not quite ready
		WorldInfo.GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
		Pres.HideLoadingScreen();		

		//Allow the game time to finish setting up following the loading screen being popped. Among other things, this lets ragdoll rigid bodies finish moving.
		Sleep(4.0f);
	}
	SendHeartbeat();
	// once all loading and intro screens clear, we can start the actual tutorial
	if(`REPLAY.bInTutorial)
	{
		`TUTORIAL.StartDemoSequenceDeferred();
	}
	
	//Clear the camera fade if it is still set
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false, , , 1.0f);	
	`XTACTICALSOUNDMGR.StartAllAmbience();

	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
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
				
		return true; // bValidMapLaunchType && bSkyrangerTravel && !BattleData.DirectTransferInfo.IsDirectMissionTransfer;
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
		`TACTICALMISSIONMGR.SpawnMissionObjectives();
		`log("SpawnMissionObjectives");
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
	`log("Started Creating Game",,'Team Dragonpunk Co Op');
	
	// Added for testing with command argument for map name (i.e. X2_ObstacleCourse) otherwise mouse does not get initialized.
	//`ONLINEEVENTMGR.ReadProfileSettings();
	ChangeInviteAcceptedDelegates();
	if(`XCOMNETMANAGER.HasClientConnection())
		GotoState('LoadTacticalGame');

	while( Pres.UIIsBusy() )
	{
		Sleep(0.0f);
	}
	
	//Show the soldiers riding to the mission while the map generates
	`log("Show DropShip Ahead",,'Team Dragonpunk Co Op');

	bShowDropshipInteriorWhileGeneratingMap = ShowDropshipInterior();
	`log("Showign DropShip",,'Team Dragonpunk Co Op');
	if(bShowDropshipInteriorWhileGeneratingMap)
	{		
		`MAPS.AddStreamingMap(`MAPS.GetTransitionMap(), DropshipLocation, DropshipRotation, false);
		while(!`MAPS.IsStreamingComplete())
		{
			sleep(0.0f);
		}

		MarkPlotUsed();
				
		XComPlayerController(Pres.Owner).NotifyStartTacticalSeamlessLoad();

		class'WorldInfo'.static.GetWorldInfo().MyLocalEnvMapManager.SetEnableCaptures(TRUE);

		//Let the dropship settle in
		Sleep(1.0f);

		//Stop any movies playing. HideLoadingScreen also re-enables rendering
		Pres.UIStopMovie();
		Pres.HideLoadingScreen();
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(false);

		class'WorldInfo'.static.GetWorldInfo().MyLocalEnvMapManager.SetEnableCaptures(FALSE);
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

	if( XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).WeatherControl() != none )
	{
		// Need to rerender static depth texture for the current weather actor in case a different parcel was selected in TQL
		XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).WeatherControl().UpdateStaticRainDepth();
		
		class'XComWeatherControl'.static.SetAllAsWet(CanToggleWetness());
	}
	else
	{
		class'XComWeatherControl'.static.SetAllAsWet(false);
	}
	EnvironmentLightingRemoteEvents();

	if (class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight != none &&
		class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight.LightComponent != none &&
		DominantDirectionalLightComponent(class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight.LightComponent) != none)
	{
		DominantDirectionalLightComponent(class'WorldInfo'.static.GetWorldInfo().m_kDominantDirectionalLight.LightComponent).SetToDEmissionOnAll();
	}
	else
	{
		class'DominantDirectionalLightComponent'.static.SetToDEmissionOnAll();
	}
	
	InitVolumes();

	class'WorldInfo'.static.GetWorldInfo().MyLightClippingManager.BuildFromScript();

	class'XComEngine'.static.BlendVertexPaintForTerrain();

	class'XComEngine'.static.ConsolidateVisGroupData();

	class'XComEngine'.static.TriggerTileDestruction();

	class'XComEngine'.static.AddEffectsToStartState();

	class'XComEngine'.static.UpdateGI();

	class'XComEngine'.static.ClearLPV();

	class'WorldInfo'.static.GetWorldInfo().MyLocalEnvMapManager.SetEnableCaptures(TRUE);
	
	class'XComEngine'.static.UpdateGI();

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
		if(!bStartedGame)
		{
			if(`XCOMNETMANAGER.HasServerConnection())
			{
				SendRemoteCommand("ServerEnteredTurn");
			}
			bStartedGame=true;
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

		UnitActionPlayerIndex=UnitActionPlayerIndex+1;
		return BeginPlayerTurn();
	}
	function OnRemoteCommand(string Command, array<byte> RawParams)
	{
		if(Command~="ServerEnteredTurn")
		{
			XComCoOpTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).SetInputState('BlockingInput');
		}
		else if( Command~= "UnlockInput")
			b_WaitingForClient=true;
		else if(Command~="RecievedHistory")
		{
			ConfirmClientHistory=true;
		}
		global.OnRemoteCommand(Command,RawParams);
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
				//XGAIPlayer(`BATTLE.GetAIPlayer()).AddNewSpawnAIData(NewGameState);
			
				SubmitGameState(NewGameState);

				PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));				
				
				//Notify the player state's visualizer that they are now the unit action player
				`assert(PlayerState != none);
				PlayerStateVisualizer = XGPlayer(PlayerState.GetVisualizer());
				PlayerStateVisualizer.OnUnitActionPhaseBegun_NextPlayer();  // This initializes the AI turn 

				// Trigger the PlayerTurnBegun event
				EventManager.TriggerEvent( 'PlayerTurnBegun', PlayerState, PlayerState );

				// build a gamestate to mark this beginning of this players turn
				Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnBegin);
				Context.PlayerRef = CachedUnitActionPlayerRef;				
				`log("PlayerState:"@PlayerState!=none @"Team:"@PlayerState.GetTeam(),,'Team Dragonpunk Co Op');
				SubmitGameStateContext(Context);
			}

			ChallengeData = XComGameState_ChallengeData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) );
			if ((ChallengeData != none) && !UnitActionPlayerIsAI( ))
			{
				TimerState = XComGameState_TimerData( CachedHistory.GetSingleGameStateObjectForClass( class'XComGameState_TimerData' ) );
				TimerState.bStopTime = false||`XCOMNETMANAGER.HasClientConnection();
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
	
	simulated function bool ServerHasActionsLeft()
	{
		local bool bActionsAvailableServer;
		local XComGameState_Unit UnitState;
		
		if(bSkipRemainingTurnActivty_B || (HasEndedLocalTurn&& IsServer()))
			return false;

		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			bActionsAvailableServer = UnitHasActionsAvailable(UnitState) && UnitState.GetMaxStat(eStat_FlightFuel)!=10 && !bServerEndedTurn;
			`log("Server Turn Ended, manual call",UnitHasActionsAvailable(UnitState) && UnitState.GetMaxStat(eStat_FlightFuel)!=10 && bServerEndedTurn && !GetReplayMgr().bInReplay);
			if (bActionsAvailableServer)
			{
				break; // once we find an action, no need to keep iterating
			}
		}
		return bActionsAvailableServer;
	}

	simulated function bool IsServer()
	{
		return `XCOMNETMANAGER.HasServerConnection();
	}

	simulated function bool HasActionsLeft()
	{
		local bool HAL,TEMP;
		local XComGameState_Unit UnitState;
		
		if(bSkipRemainingTurnActivty_B)
			return false;
		HAL=ServerHasActionsLeft();

		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			TEMP = UnitHasActionsAvailable(UnitState) && UnitState.GetMaxStat(eStat_FlightFuel)==10;
			if (TEMP)
			{
				break; // once we find an action, no need to keep iterating
			}
		}
		`log("HasActionsLeft- HAL:"@HAL @",TEMP:"@TEMP);
		if(bServerEndedTurn)
			return TEMP;

		if(HAL || TEMP)
			return true;

		return false;
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
			if (WaitingForNewStatesTime > fTimeOut && !GetReplayMgr().bInReplay)
			{
				`LogAIActions("Exceeded WaitingForNewStates TimeLimit"@WaitingForNewStatesTime$"s!  Calling AIPlayer.EndTurn()");
				AIPlayer.OnTimedOut();
				class'XGAIPlayer'.static.DumpAILog();
				AIPlayer.EndTurn(ePlayerEndTurnType_AI);
			}
		}
		if((ServerHasActionsLeft()&&!IsServer()) ||(!ServerHasActionsLeft()&&IsServer()) )
			XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');	

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
	simulated function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
	{
		`log(`location @"Dragonpunk Recieved History Tactical",,'Team Dragonpunk Co Op');
		bRecievedPartialHistory=true;
		SendRemoteCommand("RecievedHistory");
		bSyncedWithSource=true;
	}
	
	function PopupServerWaitNotification()
	{
		DialogData.eType = eDialog_Normal;
		DialogData.strTitle = "Waiting For Client To Show Up";
		DialogData.strText = "Please wait for the Client to enter the tactical game";
		DialogScreen=`SCREENSTACK.GetCurrentScreen();
		DialogScreen.Movie.Pres.UIRaiseDialog(DialogData);
	}
	function EndServerWaitNotification()
	{
		`log("Ending Dialog box");
		if(UIDialogueBox(DialogScreen.Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).ShowingDialog())
			UIDialogueBox(DialogScreen.Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).RemoveDialog();
	}
	function bool IsCurrentPlayerOfTeam(ETeam Team)
	{
		return XComGameState_Player(CachedHistory.GetGameStateForObjectID(GetBD().PlayerTurnOrder[UnitActionPlayerIndex].ObjectID)).GetTeam()==Team;
	}
	simulated function int GetCurrentTime()
	{
		local XComGameState_TimerData Timer;
		local XComGameState_UITimer UITimer;

		UITimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
		Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));

		if(UITimer.TimerValue>0)
		{
			return UITimer.TimerValue;
		}
		return Timer.GetCurrentTime();
	}

	simulated function SetCurrentTime(int DesiredTime)
	{
		local XComGameState_TimerData OTimer,Timer;
		local XComGameState NewGameState;
		local XComGameState_UITimer OUITimer,UITimer;
		local UISpecialMissionHUD_TurnCounter TurnCounter;

		TurnCounter=UISpecialMissionHUD(`SCREENSTACK.GetFirstInstanceOf(class'UISpecialMissionHUD')).m_kGenericTurnCounter;
		TurnCounter.SetCounter(string(DesiredTime),true);

		if(DesiredTime-Timer.GetCurrentTime()>0)
		{
			OUITimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
			OTimer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UpdateTimerAgain");
			if (OUITimer != none)
				UITimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer', OUITimer.ObjectID));
			else
				UITimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer'));

			if (OTimer != none)
			{
				OTimer = XComGameState_TimerData(NewGameState.CreateStateObject(class 'XComGameState_TimerData', OTimer.ObjectID));
				OTimer.AddPauseTime(DesiredTime-Timer.GetCurrentTime());
				NewGameState.AddStateObject(Timer);
			}
			else
			{
				UITimer.TimerValue=DesiredTime;
				NewGameState.AddStateObject(UITimer);
			}
			if(NewGameState.GetNumGameStateObjects()>0)
				`XCOMHISTORY.AddGameStateToHistory(NewGameState);
			else
				`XCOMHISTORY.CleanupPendingGameState(NewGameState);

		}
	}
Begin:
	`SETLOC("Start of Begin Block");
	if(!Launched)	
	{
		//SendToConsole("show gi");
		if(`XCOMNETMANAGER.HasClientConnection())
		{
			SendRemoteCommand("UnlockInput");
		}
		else if(`XCOMNETMANAGER.HasServerConnection())
		{
			`log("Sending History While Locked",,'Dragonpunk Tactical TurnState');
			SendHistory();
			while(!ConfirmClientHistory)
			{
				sleep(0.0);
			}
			SendRemoteCommand("HistoryConfirmedLoadGame");
			XComCoOpInput(XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).PlayerInput).PushState('BlockingInput');
			PopupServerWaitNotification();
			`log("Input Locked",,'Dragonpunk Tactical TurnState');
		}
		While(!b_WaitingForClient&&`XCOMNETMANAGER.HasServerConnection())
		{
			sleep(0.0);
		}
		if(`XCOMNETMANAGER.HasServerConnection())
		{
			`log("Ending Input Lock",,'Dragonpunk Tactical TurnState');
			EndServerWaitNotification();
			sleep(1.0);
			XComCoOpInput(XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).PlayerInput).PopState();
		}
		launched=true;
		FirstTurn=false;
	}
	if(FirstTurn)
	{	
		bSyncedWithSource=false;
		`SETLOC("Waiting for History Sync.");
		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');
		if(`XCOMNETMANAGER.HasServerConnection())
		{
			while(bSendingPartialHistory||bSendingTurnHistory)
			{
				Sleep(0.0);
			}
			SendTurnHistory();
			while(bSendingTurnHistory)
			{
				Sleep(0.0);
			}
		}
		else 
		{
			while (!bReadyForTurnHistory)
			{
				sleep(0.0);
			}
			SendRemoteCommand("RequestTurnHistory");
			while(!bSyncedWithSource)
			{
				Sleep(0.0);
			}
		}	
			
		LatentWaitingForPlayerSync();
		bSendingPartialHistory=false;
		SendHistoryThisTurn=false;
		bSendingTurnHistory=false;
		TurnCounterFixed--;
		if(UseTurnCounterFixed) SetCurrentTime(TurnCounterFixed);
	}
	else
	{
		TurnCounterFixed=GetCurrentTime();
		`log("Current Time on Timer:"@TurnCounterFixed @(`XCOMNETMANAGER.HasServerConnection()?"I am Server":"I am Client"),,'Team Dragonpunk Co Op');
		if(TurnCounterFixed>1)
		{
				UseTurnCounterFixed=true;
	
			if(`XCOMNETMANAGER.HasServerConnection()&&UseTurnCounterFixed)
			{
				TurnCounterFixed+=2;
			}
			else if(UseTurnCounterFixed && `XCOMNETMANAGER.HasClientConnection())
			{
				TurnCounterFixed+=4;
			}
			if(UseTurnCounterFixed)SetCurrentTime(TurnCounterFixed);

		}
		`log("Current Time on Timer:"@TurnCounterFixed @(`XCOMNETMANAGER.HasServerConnection()?"I am Server":"I am Client"),,'Team Dragonpunk Co Op');
	}
	CachedHistory=`XCOMHISTORY;
	CachedHistory.CheckNoPendingGameStates();
	
	bSkipRemainingTurnActivty_B = false;
	bServerEndedTurn=false;
	HasEndedLocalTurn=false;
	bPauseReplay=false;
	bClientPrepared=false;
	XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('Multiplayer_Inactive');	
	XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('ActiveUnit_Moving');
	
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
		HasEndedLocalTurn=false;
		`SETLOC("Check for Available Actions");
		while( ActionsAvailable() && !HasTacticalGameEnded() )
		{
			`log("Actions Available Start",,'Dragonpunk Tactical TurnState');
			SendHistoryThisTurn=false;
			WaitingForNewStatesTime = 0.0f;
			if(IsCurrentPlayerOfTeam(eTeam_XCom))
			{
				`log("WE ARE XCOM. WE ARE MANY");
				if(`XCOMNETMANAGER.HasServerConnection())
				{
					if(ServerHasActionsLeft())
					{
						XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('Multiplayer_Inactive');	
						XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('ActiveUnit_Moving');
					}
					if(!ServerHasActionsLeft()&& !HasEndedLocalTurn)
					{
						`log("!ServerHasActionsLeft()",,'Dragonpunk Tactical TurnState');
						while (bSendingPartialHistory)
						{
							sleep(0.0);
						}
						OtherSideEndedReplay=false;
						SendPartialHistory();
						while (bSendingPartialHistory)
						{
							sleep(0.0);
						}
						HasEndedLocalTurn=true;
						bServerEndedTurn=true;
						while(!OtherSideEndedReplay)
						{
							sleep(0.0);
						}
						OtherSideEndedReplay=false;
						SendRemoteCommand("SwitchTurn");
						`log("Switching To Client, Server has no actions");
						//`XCOMHISTORY.UnRegisterOnNewGameStateDelegate(OnNewGameState_GameWatcher);
						//XComCoOpInput(XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).PlayerInput).PushState('BlockingInput');
						
					}
					else if (!ServerHasActionsLeft()&&string(GetReplayMgr().GetStateName())!="PausedReplay"&& bPauseReplay)
					{
						
						while(string(GetReplayMgr().GetStateName())!="PausedReplay"&& bPauseReplay)
						{
							sleep(0.0);
						}
						`log("Exited Wait for Pausing state");
						bPauseReplay=false;
						if(bSkipRemainingTurnActivty_B)
						{
							`log("Server did go into the Wait If, Means that no longer in replay AND dosnt have any moves left.");
						}
					}
					else if(!ServerHasActionsLeft()&&bSkipRemainingTurnActivty_B)
					{
						`log("Server Didnt go into any If, Means that no longer in replay AND dosnt have any moves left.");
					}
				}
				else if(`XCOMNETMANAGER.HasClientConnection())
				{
					`log("HasActionsLeft():"@HasActionsLeft());
					if(ServerHasActionsLeft())
						SendHistoryThisTurn=true;
					
					if(HasActionsLeft()&&!ServerHasActionsLeft())
					{						
						while(string(GetReplayMgr().GetStateName())!="PausedReplay"&& bPauseReplay)
						{
							sleep(0.0);
						}
						`log("Exited Wait for Pausing state");
						bPauseReplay=false;
						//XComCoOpInput(XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).PlayerInput).PopState();
						XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('Multiplayer_Inactive');	
						XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('ActiveUnit_Moving');
					}
					else if(ServerHasActionsLeft())
					{
						XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');	
					}
					else if(!HasActionsLeft())
					{
						`log("!HasActionsLeft(),Next Turn",,'Dragonpunk Tactical TurnState');
						while (bSendingPartialHistory)
						{
							sleep(0.0);
						}
						OtherSideEndedReplay=false;
						SendPartialHistory();
						while (bSendingPartialHistory)
						{
							sleep(0.0);
						}
						HasEndedLocalTurn=true;
						while(!OtherSideEndedReplay)
						{
							sleep(0.0);
						}
						OtherSideEndedReplay=false;
						SendRemoteCommand("SwitchTurn");
						`log("Switching To Server, no actions left");
						SendRemoteCommand("XComTurnEnded");
						bSkipRemainingTurnActivty_B=true;
						//`XCOMHISTORY.UnRegisterOnNewGameStateDelegate(OnNewGameState_GameWatcher);
						//XComCoOpInput(XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).PlayerInput).PushState('BlockingInput');
					}
				}
				if(SendHistoryThisTurn||bSkipRemainingTurnActivty_B || HasEndedLocalTurn || GetReplayMgr().bInReplay || (string(GetReplayMgr().GetStateName())!="PausedReplay"&& bPauseReplay))
				{
					`log("Skipped Sending history"@ `XCOMNETMANAGER.HasServerConnection()? "Server":"Client" @"Replay:"@GetReplayMgr().bInReplay );
				}	
				else
				{
					while (bSendingPartialHistory)
					{
						sleep(0.0);
					}
					SendPartialHistory();
					while (bSendingPartialHistory)
					{
						sleep(0.0);
					}
				}
			}

			else if(!IsCurrentPlayerOfTeam(eTeam_XCom))
			{
				if(IsServer())
				{
					while (bSendingPartialHistory || !bClientPrepared || WaitingForVisualizer())
					{
						sleep(0.0);
					}
					sleep(0.5);
					SendPartialHistory();
					`log("Sent AI Partial History");
					while (bSendingPartialHistory)
					{
						sleep(0.0);
					}
				
				}
				else
				{
					`log("Wait for Pausing state AI turn");
					bPauseReplay=true;		
					SendRemoteCommand("ClientReadyForAITurn");
					PushState('PerformingReplay');			
					while(string(GetReplayMgr().GetStateName())!="PausedReplay"&& bPauseReplay)
					{
						sleep(0.0);
					}		
					`log("Exited Wait for Pausing state AI turn");
					bPauseReplay=false;
					bSkipRemainingTurnActivty_B=true;
					HasEndedLocalTurn=true;			
				}
			}

			//Wait for new states created by the player / AI / remote player. Manipulated by the SubmitGameStateXXX methods
			while( bWaitingForNewStates &&!bSkipRemainingTurnActivty_B)
			{
				`SETLOC("Available Actions");
				sleep(0.0);
			}
			`log("Not Waiting for New States");
			while( WaitingForVisualizer() )
			{
				`SETLOC("Waiting for Visualizer: 1.5");
				sleep(0.0);
			}
			`log("Not Waiting for Visualizer");
			`SETLOC("Available Actions: Done waiting for New States");

			CachedHistory.CheckNoPendingGameStates();

			if( `CHEATMGR.bShouldAutosaveBeforeEveryAction )
			{
				`AUTOSAVEMGR.DoAutosave();
			}
			sleep(0.0);
			if(!GetReplayMgr().bInReplay && !SendHistoryThisTurn && IsCurrentPlayerOfTeam(eTeam_XCom))
			{
				`log("Sending History Just in case");
				while (bSendingPartialHistory)
				{
					sleep(0.0);
				}
				SendPartialHistory();
				while (bSendingPartialHistory)
				{
					sleep(0.0);
				}
			}
			`log("Once more time around the loop we go!");
		}
		if(!HasEndedLocalTurn && !bSkipRemainingTurnActivty_B && IsCurrentPlayerOfTeam(eTeam_XCom) && !IsServer() && !HasActionsLeft())	
		{
			while (bSendingPartialHistory&&!HasEndedLocalTurn)
			{
				sleep(0.0);
			}
			OtherSideEndedReplay=false;
			SendPartialHistory();
			while (bSendingPartialHistory)
			{
				sleep(0.0);
			}
			HasEndedLocalTurn=true;
			while(!OtherSideEndedReplay)
			{
				sleep(0.0);
			}
			OtherSideEndedReplay=false;
			SendRemoteCommand("SwitchTurn");
			`log("Switching To Server, no actions left Out of moves");
			SendRemoteCommand("XComTurnEnded");
			bSkipRemainingTurnActivty_B=true;
		}
		if(!IsCurrentPlayerOfTeam(eTeam_XCom))
		{
			if(IsServer())
			{
				SendRemoteCommand("SwitchTurnNonXCom");
				bSkipRemainingTurnActivty_B=true;
				HasEndedLocalTurn=true;
			}
		}
		`SETLOC("Checking for Tactical Game Ended");
		//Perform fail safe checking for whether the tactical battle is over
		FailsafeCheckForTacticalGameEnded();
		// Moved to clear the SkipRemainingTurnActivty flag until after the visualizer finishes.  Prevents an exploit where
		// the end/back button is spammed during the player's final action. Previously the Skip flag was set to true 
		// while visualizing the action, after the flag was already cleared, causing the subsequent AI turn to get skipped.
		bRecievedPartialHistory=false;
		bSkipRemainingTurnActivty_B = false;
		bServerEndedTurn=false;
		HasEndedLocalTurn=false;
		bPauseReplay=false;
		bClientPrepared=false;
		`log("Going to the Next Player");
		`SETLOC("Going to the Next Player");

		if(IsServer())
		{
			SendRemoteCommand("ReadyForFinalHistory");
			while(!bReadyForHistory)
			{
				sleep(0.0);
			}
			SendHistory();
			while (bSendingPartialHistory)
			{
				sleep(0.0);
			}
		}
		else
		{
			while(!bRecievedPartialHistory)
			{
				Sleep(0.0);
			}
			bRecievedPartialHistory=bSendingPartialHistory;		
			bSendingPartialHistory=false;
			`log("We are past end turn history sync");
		}
		LatentWaitingForPlayerSync();
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
	FirstTurn=true;
	EndPhase();
	`SETLOC("End of Begin Block");
}
