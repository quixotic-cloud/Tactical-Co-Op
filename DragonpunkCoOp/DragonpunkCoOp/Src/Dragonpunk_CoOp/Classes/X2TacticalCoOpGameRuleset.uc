//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    X2TacticalCoOpGameRuleset
//  AUTHOR:  Elad Dvash
//  PURPOSE: New Ruleset for the Co-Op game
//  Handels all the tactical logic for co-op that including:
//  1. Initializes the game and map for the server
//  2. Loads the map for the client
//  3. Handels transfering the gamestates and recieving them
//  4. Implements the logic for how the control transfers between players
//  5. Everything else that the regular X2TacticalRuleset does like control turns                                                                                                                                                                                                                          
// (turns here are game turns which are an entire cycle: Start->XCom->aliens->Civis->End)                                                                                                                                                                           
//---------------------------------------------------------------------------------------

Class X2TacticalCoOpGameRuleset extends X2TacticalGameRuleset;

//******** General Purpose Variables *********************
`define SETLOC(LocationString)	BeginBlockWaitingLocation = GetStateName() $ ":" @ `LocationString;
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
var protected bool bLocalPlayerForfeited;
var protected bool bDisconnected;
var protected bool bShouldDisconnect;
var protected bool bReceivedNotifyConnectionClosed;

//var array<int> EnemyIDs;
var array<int> ReinforcementIDs;

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
var bool ServerIsReadyToSendAITurn;
var bool bClientPreparedForHistory;
var protected bool ConfirmClientHistory;
var protected bool bRecivedHistoryTurnEnd;
var protected bool bStartedGame;
var protected int TurnCounterFixed;
var protected bool UseTurnCounterFixed;
//********************************************************

var TDialogueBoxData DialogData;

var UIScreen DialogScreen;

var UIButton SyncCoopButton;

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
	`XCOMNETMANAGER.AddReceiveMirrorHistoryDelegate(ReceiveMirrorHistory);

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
	`XCOMNETMANAGER.ClearReceiveMirrorHistoryDelegate(ReceiveMirrorHistory);

}

function OnNotifyConnectionClosed(int ConnectionIdx)
{

	`log("Connection Closed!");
//	`XCOMNETMANAGER.Disconnect();
//	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');	
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
	`log(`location @"Dragonpunk Recieved History Tactical",,'Team Dragonpunk Co Op');
	bRecievedPartialHistory=true;
	SendRemoteCommand("RecievedHistory");
	bSyncedWithSource=true;
	RebuildLocalStateObjectCache();
}

function ReceiveMirrorHistory(XComGameStateHistory History, X2EventManager EventManager)
{
	`log("Mirror History Recieved");
	`XCOMNETMANAGER.GenerateValidationReport(History, EventManager);
	`log("Mirror History Ended");
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


function MarkObjectiveAsCompleted(name ObjectiveName)
{
	local XComGameState_BattleData BattleData;
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData.CompleteObjective(ObjectiveName);
}

function bool AllEnemiesEliminated()
{
	local XComGameState_Unit UnitState;
	local XComGameState_AIReinforcementSpawner ReinfState;
	local bool ToRet;

	ToRet=true;
	
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIReinforcementSpawner', ReinfState)
	{
		if(ReinforcementIDs.Find(ReinfState.ObjectID)==-1)
		{
			ReinforcementIDs.AddItem(ReinfState.ObjectID);
			ToRet=false;
		}
		if(ReinfState.Countdown>0)
		{
			`log("Countdown:"@ ReinfState.Countdown @"From:"@ReinfState.ObjectID);
			ToRet=false;
		}
	}
	if(!UITacticalHUD(`ScreenStack.GetScreen(class'UITacticalHUD')).m_kCountdown.bIsVisible)
		ToRet=true;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		
		if(UnitState.GetTeam()==eTeam_Alien && UnitState.IsAlive() && UnitState.IsInCombat())
			ToRet=false;
	}

	return ToRet;
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
	if( Command ~= "RecievedHistory")
	{
		bSendingPartialHistory = false;
		bSendingPartialHistory_True = false;
		bSendingTurnHistory= false;
		ConfirmClientHistory=true;
		CachedHistory=`XCOMHISTORY;
	}
	else if( Command ~= "SetCurrentTime")
	{
		`log("SetCurrentTime Command Recieved, setting current time!");
		SetCurrentTime(`XCOMNETMANAGER.GetCommandParam_Int(RawParams));
	}
	else if(Command~="ReadyToSendAITurn")
	{
		ServerIsReadyToSendAITurn=true;
	}
	else if(Command~="ServerEnteredTurn")
	{
		XComCoOpTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).SetInputState('BlockingInput');
	}
	else if( Command~= "UnlockInput")
		b_WaitingForClient=true;
	else if( Command~= "ClientReadyForHistory")
		bClientPreparedForHistory=true;
	else if(Command~= "EndOfReplay")
	{
		bSendingPartialHistory = false;
		bSendingPartialHistory_True = false;
		bSendingTurnHistory= false;
		ConfirmClientHistory=true;
		OtherSideEndedReplay=true;
	}
	else if( Command ~= "ReadyForTurnHistory")
	{
		bReadyForTurnHistory=true;
	}
	else if( Command ~= "RequestTurnHistory")
	{
		SendTurnHistoryTrue();
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
		SendRemoteCommand("DisableControls");
		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('ActiveUnit_Moving');	
		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).IsCurrentlyWaiting=false;
		if(`XCOMNETMANAGER.HasClientConnection())
			bServerEndedTurn=true;
	}
	else if(Command ~="DisableControls")
	{
	}
	else if(Command ~="ReadyForFinalHistory")
	{
		bRecievedPartialHistory=false;
		bReadyForHistory=true;
	}
	else if( Command ~= "SendFinalHistory" )
	{
		bReadyForHistory=true;	
	}
	else if( Command ~= "ClientReadyForAITurn" )
	{
		bClientPrepared=true;
	}
	else if( Command ~= "Switch_Turn_NonXCom" )
	{
		// Stop replaying, and give player control
		bPauseReplay=true;
		HasEndedLocalTurn=false;
		bClientPrepared=false;
		SyncPlayerVis();
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
		//DisconnectGame();
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
		GetReplayMgr().LastKnownHistoryIndex=GetReplayMgr().CurrentHistoryFrame;
		GetReplayMgr().CachedHistory=`XCOMHISTORY;
//		if(!(string(GetStateName())~="PerformingReplay"))
//			PushState('PerformingReplay');

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
		`PRES.m_kTurnOverlay.HideOtherTurn();
		SyncPlayerVis();
	}
	else if( Command ~= "ForceSync")
	{
		HasEndedLocalTurn=true;
		GotoState('TurnPhase_ForceSync');
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
//			return 'PerformingReplay';
		}
		LastState = GetLastStateNameFromHistory();
		return (LastState == '' || LastState == 'LoadTacticalGame') ? 'TurnPhase_Begin_Coop' : GetNextTurnPhase(LastState, 'TurnPhase_Begin_Coop');
	case 'PostCreateTacticalGame':
		if (CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_ChallengeData', true) != none)
			return 'TurnPhase_StartTimer';

		return 'TurnPhase_Begin_Coop';
	case 'TurnPhase_Begin':		
		return 'TurnPhase_UnitActions';
	case 'TurnPhase_Begin_Coop':		
		return 'TurnPhase_UnitActions';
	case 'TurnPhase_UnitActions':
		return 'TurnPhase_End';
	case 'TurnPhase_End':
		return 'TurnPhase_Begin_Coop';
	case 'PerformingReplay':
		if (!XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay || XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInTutorial)
		{
			//Used when resuming from a replay, or in the tutorial and control has "returned" to the player
			return 'TurnPhase_UnitActions';
		}
	case 'CreateChallengeGame':
		return 'TurnPhase_StartTimer';
	case 'TurnPhase_StartTimer':
		return 'TurnPhase_Begin_Coop';
	case 'TurnPhase_ForceSync':
		return 'TurnPhase_UnitActions';
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
	bSendingTurnHistory=true;
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

function SyncPlayerVis()
{
	local XComGameState_Unit UnitState;
	local XComGameState_Player PlayerState;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		If(UnitState.IsInCombat())
			UnitState.SyncVisualizer(`XCOMHISTORY.GetGameStateFromHistory(`XCOMHISTORY.GetNumGameStates()-1));
	}
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		PlayerState.SyncVisualizer(`XCOMHISTORY.GetGameStateFromHistory(`XCOMHISTORY.GetNumGameStates()-1));
	}
}

simulated function UIShowAlienTurnOverlay()
{
		
	if(`PRES.m_kTurnOverlay != none && `PRES.m_kTurnOverlay.bIsInited)
	{
		if( !`PRES.m_kTurnOverlay.IsShowingAlienTurn() )
		{
			`PRES.m_kTurnOverlay.HideOtherTurn();
			`PRES.m_kTurnOverlay.ShowAlienTurn();
		}
	}
	SyncCoopButton.Hide();
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
	local XComGameState NewGameState;
	local XComGameState_UITimer OUITimer,UITimer;
	local UISpecialMissionHUD_TurnCounter TurnCounter;
	local array<byte> Params;


	if(`XCOMNETMANAGER.HasServerConnection())
	{
		Params.Length = 0; // Removes script warning
		`XCOMNETMANAGER.AddCommandParam_Int(DesiredTime,Params);
		`XCOMNETMANAGER.SendRemoteCommand("SetCurrentTime", Params);
	}
	else
		TurnCounterFixed=DesiredTime;


	//SetTimers(DesiredTime);

	TurnCounter=UISpecialMissionHUD(`SCREENSTACK.GetFirstInstanceOf(class'UISpecialMissionHUD')).m_kGenericTurnCounter;
	TurnCounter.SetCounter(string(DesiredTime),true);

	OUITimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
	`log("OUITimer.TimerValue"@OUITimer.TimerValue @"Desired Value:"@DesiredTime);

	if(DesiredTime!=OUITimer.TimerValue)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UpdateTimerAgain");
		if (OUITimer != none)
			UITimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer', OUITimer.ObjectID));
		else
			UITimer = XComGameState_UITimer(NewGameState.CreateStateObject(class 'XComGameState_UITimer'));
		UITimer.TimerValue=DesiredTime;
		UITimer.UiState= (DesiredTime<=3 ? eUIState_Bad : eUIState_Normal);
		
		NewGameState.AddStateObject(UITimer);

		if(NewGameState.GetNumGameStateObjects()>0)
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		else
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);

		OUITimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));

		`log("OUITimer.TimerValue"@OUITimer.TimerValue @"Desired Value:"@DesiredTime);
		
		`PRES.UITimerMessage(UITimer.DisplayMsgTitle, UITimer.DisplayMsgSubtitle, string(UITimer.TimerValue),DesiredTime>3 ? eUIState_Normal : eUIState_Bad , UITimer.ShouldShow && DesiredTime>=0);

	}
	 
}

function bool SetTimers(int TurnsLeft)
{
	local SeqVar_Int TimerVariable;
	local WorldInfo wInfo;
	local Sequence mainSequence;
	local array<SequenceObject> SeqObjs;
	local int i,k;
	wInfo = `XWORLDINFO;
	mainSequence = wInfo.GetGameSequence();
	if (mainSequence != None)
	{
		`Log("Game sequence found: " $ mainSequence);
		mainSequence.FindSeqObjectsByClass( class'SeqAct_DisplayUISpecialMissionTimer', true, SeqObjs);
		if(SeqObjs.Length != 0)
		{
			`Log("Kismet variables found" @SeqObjs.Length);
			for(i = 0; i < SeqObjs.Length; i++)
			{
				`Log("SeqObjs variables found" @SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables.length);
				`Log("Variable found: " $  SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k].VarName);
				`Log("Variable found: " $  SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k].VarName);

				for(k=0;k<SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables.length ; k++)
				{
			
					`Log("Variable found: " $  SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k].VarName);
					`Log("IntValue = " $  SeqVar_Int(SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k]).IntValue);
					//if(InStr(string(SequenceVariable(SeqObjs[i]).VarName), "NumTurns") != -1)
					//{
						TimerVariable = SeqVar_Int(SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k]);

						TimerVariable.IntValue=TurnsLeft;
						SeqVar_Int(SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k]).IntValue = TurnsLeft;
						`Log("Timer set to: " $ TimerVariable.IntValue);
					//}
				}
			}
			mainSequence.FindSeqObjectsByClass( class'SeqAct_DisplayUISpecialMissionTimer', true, SeqObjs);
			for(i = 0; i < SeqObjs.Length; i++)
			{
				for(k=0;k<SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables.length ; k++)
				{
					if(SeqVar_Int(SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k]).IntValue==TurnsLeft)
						`Log("Timer set to: " $ SeqVar_Int(SeqAct_DisplayUISpecialMissionTimer(SeqObjs[i]).VariableLinks[0].LinkedVariables[k]).IntValue);
					else
						`log("Not Our Turn Count");
				}
			}
		}
	}
}


function SetTurnDisplay()
{
	local UITurnOverlay TurnOverlay;
	TurnOverlay=UITurnOverlay(`ScreenStack.GetFirstInstanceOf(class'UITurnOverlay'));
	TurnOverlay.SetDisplayText(TurnOverlay.m_sAlienTurn,TurnOverlay.m_sXComTurn,"Other Player's Turn", TurnOverlay.m_sReflexAction, TurnOverlay.m_sSpecialTurn );
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
	if(UseTurnCounterFixed)
		return TurnCounterFixed<=0;

	return HasTimeExpired();
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
	`log("GOING TO BEGIN COOP!");
	GotoState('TurnPhase_Begin_Coop');
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
		local XComGameState_InteractiveObject BaseObj,newObj;

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
	/*	foreach CachedHistory.IterateByClassType(class'XComGameState_InteractiveObject', BaseObj)
		{
			if(BaseObj.Health>0)
			{
				newObj=XComGameState_InteractiveObject(StartState.CreateStateObject(class'XComGameState_InteractiveObject', BaseObj.ObjectID));
				newObj.Health=0;
				StartState.AddStateObject(newObj);
			}	
		}*/
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
	function UpdateTurnUI()
	{
		local XComGameState_UITimer UITimer;

		UITimer = XComGameState_UITimer(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_UITimer', true));
		`PRES.UITimerMessage(UITimer.DisplayMsgTitle, UITimer.DisplayMsgSubtitle, string(TurnCounterFixed), UITimer.UiState, UITimer.ShouldShow && TurnCounterFixed>=0);

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
				if(!IsServer()/* && PlayerState.IsAIPlayer()*/)
				{
					`PRES.m_kTurnOverlay.ShowOtherTurn();
				// Trigger the PlayerTurnBegun event
					if(PlayerState.IsAIPlayer())
					{
						`log("Encountered Alien Turn at client. Does not trigger the turn start");
						XGAIPlayer(PlayerState.GetVisualizer()).m_bSkipAI=true;
					}
				}	
				else
				{
					PlayerStateVisualizer = XGPlayer(PlayerState.GetVisualizer());
					PlayerStateVisualizer.OnUnitActionPhaseBegun_NextPlayer();  // This initializes the AI turn 

					EventManager.TriggerEvent( 'PlayerTurnBegun', PlayerState, PlayerState );

					// build a gamestate to mark this beginning of this players turn
					Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnBegin);
					Context.PlayerRef = CachedUnitActionPlayerRef;				
					`log("PlayerState:"@PlayerState!=none @"Team:"@PlayerState.GetTeam(),,'Team Dragonpunk Co Op');
					SubmitGameStateContext(Context);
				}
				UpdateTurnUI();
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

			//Don't process turn begin/end events if we are loading from a save
			if( !bLoadingSavedGame )
			{
				if(!IsServer() /*&& PlayerState.IsAIPlayer()*/)
				{
					if(PlayerState.IsAIPlayer())
					{
						`log("Encountered Alien Turn at client. Does not trigger the turn end");
						XGAIPlayer(PlayerState.GetVisualizer()).m_bSkipAI=false;
					}	
				}
				else
				{
					XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhaseFinished_NextPlayer();
					EventManager.TriggerEvent( 'PlayerTurnEnded', PlayerState, PlayerState );

					// build a gamestate to mark this end of this players turn
					Context = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_PlayerTurnEnd);
					Context.PlayerRef = CachedUnitActionPlayerRef;				
					SubmitGameStateContext(Context);
				}
			}
			else
				XGPlayer(PlayerState.GetVisualizer()).OnUnitActionPhaseFinished_NextPlayer();


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

		if (UnitState == none )
			return false;

		//Check whether this unit is controlled by the UnitActionPlayer
		if (UnitState.ControllingPlayer.ObjectID == CachedUnitActionPlayerRef.ObjectID ||
			UnitState.ObjectID == PriorityUnitRef.ObjectID)
		{
			if (!UnitState.GetMyTemplate().bIsCosmetic &&
				!UnitState.IsPanicked() &&
				UnitState.IsAlive() &&
				!UnitState.IsBleedingOut() &&
				!UnitState.IsUnconscious() &&
				!UnitState.IsStunned() &&
				!(UnitState.IsMindControlled()&& UnitState.GetPreviousTeam()!=UnitState.GetTeam()) &&
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
			return TEMP&&!HasEndedLocalTurn;

		if(HAL || TEMP)
			return true;

		return false;
	}
	simulated function EndPhase()
	{
		if (HasTacticalGameEnded())
		{
			//DisconnectGame();
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
		UpdateTurnUI();
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
	
	
	function PopupServerWaitNotification()
	{
		DialogData.eType = eDialog_Normal;
		DialogData.strTitle = "Waiting for other player to enter the tactical game";
		DialogData.strText = "Please wait. This message will disappear automatically.";
		DialogData.strAccept=" ";
		DialogData.strCancel=" ";
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
	
	

Begin:
	`SETLOC("Start of Begin Block");
	
	UpdateTurnUI();
	CachedHistory=`XCOMHISTORY;
	CachedHistory.CheckNoPendingGameStates();
	XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('Multiplayer_Inactive');	
	XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('ActiveUnit_Moving');
	bSkipRemainingTurnActivty_B = false;
	bServerEndedTurn=false;
	HasEndedLocalTurn=false;
	bPauseReplay=false;
	bClientPrepared=false;
	sleep(1.0);
	if(!IsServer())
	{
		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).IsCurrentlyWaiting=true;
	}
	//Loop through the players, allowing each to perform actions with their units
	SetTurnDisplay();
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
			SyncCoopButton.Hide();
			if(IsCurrentPlayerOfTeam(eTeam_XCom))
			{
				StartTimerSync();
				//SyncCoopButton.Show();
				`log("WE ARE XCOM. WE ARE MANY");
				SetCurrentTime(TurnCounterFixed);
				if(`XCOMNETMANAGER.HasServerConnection())
				{
					if(ServerHasActionsLeft() && IsCurrentPlayerOfTeam(eTeam_XCom) )
					{
						SendRemoteCommand("DisableControls");
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
						`PRES.m_kTurnOverlay.ShowOtherTurn();	
						SetCurrentTime(TurnCounterFixed);					
						SendRemoteCommand("SwitchTurn");
						`log("Switching To Client, Server has no actions");
						
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
					{
						`PRES.m_kTurnOverlay.ShowOtherTurn();
						SetCurrentTime(TurnCounterFixed);
						SendHistoryThisTurn=true;
						XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).IsCurrentlyWaiting=true;
						
					}
					if(HasActionsLeft()&&!ServerHasActionsLeft())
					{
						`PRES.UIHideAllHUD();
						`PRES.m_kTurnOverlay.HideOtherTurn();
						`PRES.UIShowMyTurnOverlay();
						if(XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).IsCurrentlyWaiting)		
							XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).IsCurrentlyWaiting=false;			
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
					else if(!HasActionsLeft())
					{
						`log("!HasActionsLeft(),Next Turn",,'Dragonpunk Tactical TurnState');
						while (bSendingPartialHistory)
						{
							sleep(0.0);
						}
						OtherSideEndedReplay=false;
						HasEndedLocalTurn=false;
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
				SendRemoteCommand("ReadyToSendAITurn");
				while (bSendingPartialHistory || !bClientPrepared || WaitingForVisualizer())
				{
					sleep(0.0);
				}
				OtherSideEndedReplay=false;
				SendPartialHistory();
				`log("Sent AI Partial History");
				while (bSendingPartialHistory)
				{
					sleep(0.0);
				}
				while(!OtherSideEndedReplay)
				{
					sleep(0.0);
				}
				SendRemoteCommand("Switch_Turn_NonXCom");
			}
			else
			{
				UIShowAlienTurnOverlay();
				`log("Wait for server to be ready to send AI turn");
				while(!ServerIsReadyToSendAITurn)
				{
					sleep(0.0);
				}
				`log("Wait for Pausing state AI turn");
				bPauseReplay=true;		
				SendRemoteCommand("ClientReadyForAITurn");
//				PushState('PerformingReplay');			
				while(string(GetReplayMgr().GetStateName())!="PausedReplay"&& bPauseReplay)
				{
					sleep(0.0);
				}		
				`log("Exited Wait for Pausing state AI turn");
				bPauseReplay=false;
				bSkipRemainingTurnActivty_B=true;
				HasEndedLocalTurn=true;			
				ServerIsReadyToSendAITurn=false;			
				
			}
		}
		`SETLOC("Checking for Tactical Game Ended");
		//Perform fail safe checking for whether the tactical battle is over
		FailsafeCheckForTacticalGameEnded();
		// Moved to clear the SkipRemainingTurnActivty flag until after the visualizer finishes.  Prevents an exploit where
		// the end/back button is spammed during the player's final action. Previously the Skip flag was set to true 
		// while visualizing the action, after the flag was already cleared, causing the subsequent AI turn to get skipped.
		bReadyForHistory=false;
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
			if(AllEnemiesEliminated())
			{
				MarkObjectiveAsCompleted('Sweep');
			}
			while(!bClientPreparedForHistory)
			{
				sleep(0.0);
			}
			bClientPreparedForHistory=false;
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
			bReadyForHistory=false;
		}
		else
		{
			bRecievedPartialHistory=false;
			SendRemoteCommand("ClientReadyForHistory");
			while(!bReadyForHistory)
			{
				Sleep(0.0);
			}
			SendRemoteCommand("SendFinalHistory");
			while(!bRecievedPartialHistory)
			{
				Sleep(0.0);
			}
			bSendingPartialHistory=false;
			bReadyForHistory=false;
			`log("We are past end turn history sync");
		}
		if(!IsCurrentPlayerOfTeam(eTeam_XCom) && !IsServer() )
		{
			`PRES.m_kTurnOverlay.HideAlienTurn();
		}
		//LatentWaitingForPlayerSync();
		SyncPlayerVis();
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

function StartTimerSync()
{
	SetTimer(60,false,'SyncButtonShow');
}

simulated state TurnPhase_Begin_Coop extends TurnPhase_Begin
{
	simulated event BeginState(name PreviousStateName)
	{
		BeginState_RulesAuthority(UpdateAbilityCooldowns);
	}
	
	function PopupServerWaitNotification()
	{
		DialogData.eType = eDialog_Normal;
		DialogData.strTitle = "Waiting for other player to enter the tactical game";
		DialogData.strText = "Please wait. This message will disappear automatically.";
		DialogData.strAccept=" ";
		DialogData.strCancel=" ";
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

Begin:
	`SETLOC("Start of Begin Block");
	`log("WE ARE IN BEGIN COOP!");
	if(!Launched)	
	{
		SyncCoopButton=UITacticalHUD(`ScreenStack.GetScreen(class'UITacticalHUD')).Spawn(class'UIButton',UITacticalHUD(`ScreenStack.GetScreen(class'UITacticalHUD'))).InitButton('MySyncButton',"Sync Co-Op",OnClickedSync ,eUIButtonStyle_SELECTED_SHOWS_HOTLINK);
		SyncCoopButton.SetPosition(SyncCoopButton.Movie.GetUIResolution().x-192,16-SyncCoopButton.Height);
		SyncCoopButton.Hide();	
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
		FirstTurn=true;
	}
	if(FirstTurn)
	{	
		bSyncedWithSource=false;
		bReadyForTurnHistory=false;
		`SETLOC("Waiting for History Sync.");
		XComCoOpTacticalController( class'WorldInfo'.static.GetWorldInfo( ).GetALocalPlayerController( ) ).SetInputState('BlockingInput');
		
		if(`XCOMNETMANAGER.HasServerConnection())
		{

			while(!bClientPreparedForHistory)
			{
				sleep(0.0);
			}
			bClientPreparedForHistory=false;
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
			bReadyForHistory=false;
		}
		else
		{
			bRecievedPartialHistory=false;
			bReadyForHistory=false;
			SendRemoteCommand("ClientReadyForHistory");
			while(!bReadyForHistory)
			{
				Sleep(0.0);
			}
			SendRemoteCommand("SendFinalHistory");
			while(!bRecievedPartialHistory)
			{
				Sleep(0.0);
			}
			bSendingPartialHistory=false;
			bReadyForHistory=false;
			`log("We are past end turn history sync");
		}
/*
		if(`XCOMNETMANAGER.HasServerConnection())
		{
			while(bSendingPartialHistory||bSendingTurnHistory)
			{
				Sleep(0.0);
			}
			`log("Before Sending Turn History");
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
			*/
		LatentWaitingForPlayerSync();

		TurnCounterFixed--;

		if(UseTurnCounterFixed) 
			SetCurrentTime(TurnCounterFixed);
	

		bSendingPartialHistory=false;
		SendHistoryThisTurn=false;
		bSendingTurnHistory=false;

	}
	else
	{
		TurnCounterFixed=GetCurrentTime();
		`log("Current Time on Timer:"@TurnCounterFixed @(`XCOMNETMANAGER.HasServerConnection()?"I am Server":"I am Client"),,'Team Dragonpunk Co Op');
		if(TurnCounterFixed<=0)
			GetTimersStart();

		`log("Current Time on Timer:"@TurnCounterFixed @(`XCOMNETMANAGER.HasServerConnection()?"I am Server":"I am Client"),,'Team Dragonpunk Co Op');

		if(TurnCounterFixed>1)
		{
			UseTurnCounterFixed=true;
			if(`XCOMNETMANAGER.HasServerConnection())
				SetCurrentTime(TurnCounterFixed);

			//UISpecialMissionHUD(`SCREENSTACK.GetFirstInstanceOf(class'UISpecialMissionHUD')).m_kGenericTurnCounter.LockCounter();
		}
	}

	CachedHistory.CheckNoPendingGameStates();
	
	`SETLOC("End of Begin Block");
	GotoState(GetNextTurnPhase(GetStateName()));
}

function OnClickedSync(UIButton Button)
{
	SyncCoopButton.Hide();		
	SendRemoteCommand("ForceSync");
	GotoState('TurnPhase_ForceSync');
}

function SyncButtonShow()
{
	SyncCoopButton.Show();	
}

simulated state TurnPhase_ForceSync
{
Begin:
	bReadyForHistory=false;
	bRecievedPartialHistory=false;
	bServerEndedTurn=false;
	bSendingPartialHistory=false;
	if(`XCOMNETMANAGER.HasServerConnection())
		{

			while(!bClientPreparedForHistory)
			{
				sleep(0.0);
			}
			bClientPreparedForHistory=false;
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
			bReadyForHistory=false;
		}
		else
		{
			bRecievedPartialHistory=false;
			SendRemoteCommand("ClientReadyForHistory");
			while(!bReadyForHistory)
			{
				Sleep(0.0);
			}
			SendRemoteCommand("SendFinalHistory");
			while(!bRecievedPartialHistory)
			{
				Sleep(0.0);
			}
			bSendingPartialHistory=false;
			`log("We are past end turn history sync");
			bReadyForHistory=false;
		}
	GotoState(GetNextTurnPhase(GetStateName()));
}

function GetTimersStart()
{
	local SeqVar_Int TimerVariable;
	local WorldInfo wInfo;
	local Sequence mainSequence;
	local array<SequenceObject> SeqObjs;
	local int i,k;
	wInfo = `XWORLDINFO;
	mainSequence = wInfo.GetGameSequence();
	if (mainSequence != None)
	{
		`Log("Game sequence found: " $ mainSequence);
		mainSequence.FindSeqObjectsByClass( class'SequenceVariable', true, SeqObjs);
		if(SeqObjs.Length != 0)
		{
			`Log("Kismet variables found");
			for(i = 0; i < SeqObjs.Length; i++)
			{
				if(InStr(string(SequenceVariable(SeqObjs[i]).VarName), "DefaultTurns") != -1)
				{
					`Log("Variable found: " $ SequenceVariable(SeqObjs[i]).VarName);
					`Log("IntValue = " $ SeqVar_Int(SeqObjs[i]).IntValue);
					TimerVariable = SeqVar_Int(SeqObjs[i]);
					TurnCounterFixed = (TimerVariable.IntValue/3)-1;
					`Log("Timer Is to: " $ TurnCounterFixed);
				}	
			}
		}
	}
}