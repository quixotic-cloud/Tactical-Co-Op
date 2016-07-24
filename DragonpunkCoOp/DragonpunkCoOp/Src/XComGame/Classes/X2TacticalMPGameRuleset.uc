//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalGameRuleset.uc
//  AUTHOR:  Timothy Talley  --  05/08/2015
//  PURPOSE: Extends the Single-player game ruleset to override the state flow and allow
//           the entire history to be sent between players every turn.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalMPGameRuleset extends X2TacticalGameRuleset
	dependson(XComOnlineStatsUtils)
	dependson(XComMPReplayMgr);


//******** General Purpose Variables *********************
var protected bool bSkipFirstPlayerSync;                        //A one time skip for Startup procedure to get the first player into the correct Ruleset state.
var protected bool bSendingPartialHistory;                      //True whenever a send has occurred, but a receive has not yet returned.
var protected bool bWaitingForEndTacticalGame;
var protected bool bRulesetRunning;                             //the rulese has fully initialized, downloaded histories, and is now running
var protected XComMPReplayMgr ReplayMgr;
`define SETLOC(LocationString)	BeginBlockWaitingLocation = GetStateName() $ ":" @ `LocationString;
var protected bool bLocalPlayerForfeited;
var protected bool bDisconnected;
var protected bool bShouldDisconnect;
var protected bool bReceivedNotifyConnectionClosed;
//********************************************************


//******** TurnPhase_PlayerSync State Variables **********
var protected bool bRequiresPlayerSync;                         //Makes sure that all players are in-sync prior to taking any actions. (MP)
var protected bool bWaitingForUnitActionComplete;               //Opponent waits until the Unit Actions are all complete from the other player.
//********************************************************


//********* Leaderboard Setup ****************************
var int LeaderboardId;                                          //The leaderboard to write the stats to for skill/scoring
var int ArbitratedLeaderboardId;                                //The arbitrated leaderboard to write the stats to for skill/scoring
//********************************************************


//******** Cached Variables ******************************
var OnlineSubsystem OnlineSub;
var OnlineGameInterface GameInterface;
//********************************************************

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

	`ONLINEEVENTMGR.AddSaveProfileSettingsCompleteDelegate( SaveComplete );

	SubscribeToOnCleanupWorld();
}

simulated event OnCleanupWorld()
{
	Cleanup();

	super.OnCleanupWorld();
}

simulated function Cleanup()
{
	StopNetworkedVoiceChecked();

	NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.ClearReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.ClearReceiveMirrorHistoryDelegate(ReceiveMirrorHistory);
	NetworkMgr.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
	NetworkMgr.ClearNotifyConnectionClosedDelegate(OnNotifyConnectionClosed);

	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate( SaveComplete );

	OnlineGameInterfaceXCom(GameInterface).ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);

	if( bShouldDisconnect )
	{
		DisconnectGame();
	}
	else
	{
		NetworkMgr.ResetConnectionData();
	}
	GetReplayMgr().Cleanup();
}

simulated event Destroyed()
{
	Cleanup();

	super.Destroyed();
}

simulated public function SaveComplete(bool bWasSuccessful)
{
	local XComOnlineEventMgr OnlineEventMgr;
	local XComOnlineProfileSettings ProfileSettings;

	OnlineEventMgr = `ONLINEEVENTMGR;
	ProfileSettings = `XPROFILESETTINGS;

	`log(`location @ `ShowVar(bWasSuccessful) @ `ShowVar(ProfileSettings.Data.m_bPushToTalk, m_bPushToTalk),,'XCom_Online');
	if( bWasSuccessful )
	{
		if (OnlineSub != None && OnlineSub.VoiceInterface != None && ProfileSettings.Data.m_bPushToTalk)
		{
			// Option for Push-to-Talk is enabled, only enable the Networked Voice if the talk button is pushed.
			OnlineSub.VoiceInterface.StopNetworkedVoice(OnlineEventMgr.LocalUserIndex);
		}
		else
		{
			// No longer Push-to-Talk, attempt to start the Networked Voice
			OnlineSub.VoiceInterface.StartNetworkedVoice(OnlineEventMgr.LocalUserIndex);
		}
	}
}

/** Tells this client that it should send voice data over the network */
function StartNetworkedVoiceChecked()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local XComOnlineProfileSettings ProfileSettings;

	OnlineEventMgr = `ONLINEEVENTMGR;
	ProfileSettings = `XPROFILESETTINGS;

	`log(`location @ `ShowVar(ProfileSettings.Data.m_bPushToTalk, m_bPushToTalk),,'XCom_Online');
	if (OnlineSub != None && OnlineSub.VoiceInterface != None && !ProfileSettings.Data.m_bPushToTalk)
	{
		OnlineSub.VoiceInterface.StartNetworkedVoice(OnlineEventMgr.LocalUserIndex);
	}
}

/** Tells this client that it should not send voice data over the network */
function StopNetworkedVoiceChecked()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local XComOnlineProfileSettings ProfileSettings;

	OnlineEventMgr = `ONLINEEVENTMGR;
	ProfileSettings = `XPROFILESETTINGS;

	`log(`location @ `ShowVar(ProfileSettings.Data.m_bPushToTalk, m_bPushToTalk),,'XCom_Online');
	if (OnlineSub != None && OnlineSub.VoiceInterface != None && !ProfileSettings.Data.m_bPushToTalk)
	{
		OnlineSub.VoiceInterface.StopNetworkedVoice(OnlineEventMgr.LocalUserIndex);
	}
}

function bool RulesetShouldAutosave()
{
	return false;
}

function ApplyStartOfMatchConditions()
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if( UnitState.FindAbility('Phantom').ObjectID > 0 )
		{
			UnitState.EnterConcealment();
		}
	}
}

function XComMPReplayMgr GetReplayMgr()
{
	if( ReplayMgr == none )
	{
		ReplayMgr = XComMPReplayMgr(XComMPTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr);
	}
	return ReplayMgr;
}

/// <summary>
/// Rebuilds all of the cached references without registering for static objects
/// </summary>
simulated function RebuildLocalStateObjectCache()
{
	local XComGameStateContext_TacticalGameRule Context;
	local XComGameState_XpManager XpManager;	
	local XComGameState_Unit UnitState;
	local GameRulesCache_Unit UnitCache;
	local AvailableAction Action;
	local XComGameState_BattleDataMP BattleData;
	local StateObjectReference EmptyRef;
	local int i;

	// Get a reference to the BattleData for this tactical game
	BattleData = XComGameState_BattleDataMP(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleDataMP'));
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

simulated function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	SendRemoteCommand("HistoryReceived");
	RebuildLocalStateObjectCache();
}

simulated function ReceivePartialHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	ReceiveHistory(InHistory, EventManager);
}

simulated function ReceiveMirrorHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	if( Command ~= "HistoryReceived" )
	{
		bSendingPartialHistory = false;
	}
	else if( Command ~= "SwitchTurn" )
	{
		// Stop replaying, and give player control
		GetReplayMgr().RequestPauseReplay();
	}
	else if( Command ~= "EndTacticalGame" )
	{
		// Stop replaying, and give player control
		GetReplayMgr().RequestPauseReplay();
	}
	else if( Command ~= "ForfeitMatch" )
	{
		HandleForfeitMatch(RawParams);
	}
}

function SendRemoteCommand(string Command)
{
	local array<byte> EmptyParams;
	EmptyParams.Length = 0; // Removes script warning
	NetworkMgr.SendRemoteCommand(Command, EmptyParams);
}

function bool SendPartialHistory(optional bool bForce=false)
{
	// Send the history if we are forced or in the network mode where we want to send the history and we are currently not sending the history
	if( (!bSendingPartialHistory && NetworkMgr.bPauseGameStateSending) || bForce )
	{
		bSendingPartialHistory = true;
		NetworkMgr.SendPartialHistory(`XCOMHISTORY, `XEVENTMGR);
	}

	// Will default to false unless a history has been sent, in which case it will remain true until the other side responds that it got the history
	return bSendingPartialHistory;
}

function OnNotifyConnectionClosed(int ConnectionIdx)
{
	`log(`location,,'XCom_Net');
	if(bRulesetRunning)
	{
		PushState('ConnectionClosed');
	}
	else
	{
		bReceivedNotifyConnectionClosed = true;
	}
}

function EndReplay()
{
	GotoState( GetNextTurnPhase( GetStateName() ) );
}

simulated function bool PlayerIsRemote(int PlayerTurnNum)
{
	local XComGameState_Player PlayerState;
	local XComGameState_BattleDataMP BattleData;
	local UniqueNetId LocalUid, GameStateUid;

	if( CachedBattleDataRef.ObjectID > 0 )
	{
		BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
	}
	else
	{
		BattleData = XComGameState_BattleDataMP(CachedHistory.GetSingleGameStateObjectForClass(class'XComGameState_BattleDataMP'));
		CachedBattleDataRef = BattleData.GetReference();
	}
	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(BattleData.PlayerTurnOrder[PlayerTurnNum].ObjectID));

	LocalUid = GetALocalPlayerController().PlayerReplicationInfo.UniqueId;
	GameStateUid = PlayerState.GetGameStatePlayerNetId();

	return (LocalUid != GameStateUid);
}


function FinishWriteOnlineStats()
{
	if(`ONLINEEVENTMGR.bOnlineSubIsSteamworks)
	{
		// steam needs to flush the stats so they get cached in the steam client and will eventually get written -tsmith 
		`log(`location @ "OnlineSubsystem is Steam, attempting to flush stats...", true, 'XCom_Net');
		if(!OnlineSub.StatsInterface.FlushOnlineStats('Game'))
		{
			`warn("     FlushOnlineStats failed, can't write leaderboard stats", true, 'XCom_Net');
		}
		else
		{
			`log("      FlushOnlineStats successful", true, 'XCom_Net');
		}
	}
}

/**
	* Tells all clients to write stats and then handles writing local stats
	*/
function WriteOnlineStatsForPlayer(XComGameState_BattleDataMP BattleData, XComGameState_Player Player, string StatWriteType)
{
	local class<OnlineStatsWrite> StatsWriteClass;
	local UniqueNetId NetId;
	local string UniqueNetString;
	local XComOnlineStatsWrite Stats;
	local OnlineGameSettings GameSettings;
	GameSettings = BattleData.GameSettings;

	NetId = Player.GetGameStatePlayerNetId();
	UniqueNetString = class'OnlineSubsystem'.static.UniqueNetIdToString(NetId);
	// Only calc this if the subsystem can write stats
	`log(`location @ `ShowVar(OnlineSub) @ `ShowVar(OnlineSub.StatsInterface) @ `ShowVar(GameSettings) @ `ShowVar(Player.GetGameStatePlayerName()) @ `ShowVar(UniqueNetString), true,'XCom_Net');
	if (OnlineSub != None && OnlineSub.StatsInterface != None && GameSettings != None)
	{
		StatsWriteClass = GameSettings.GetOnlineStatsWriteClass(StatWriteType);
		if (StatsWriteClass != None && GameSettings.bUsesStats)
		{
			// Arbitration requires us to report for everyone, whereas non-arbitrated is just for ourselves
			if (GameSettings.bUsesArbitration || Player.IsLocalPlayer())
			{
				// create the stats object that will write to the leaderboard -tsmith 
				Stats = XComOnlineStatsWrite(new StatsWriteClass);

				// Copy the stats from the PRI to the object
				`log(`location @ "Writing stats for '" $ Player.GetGameStatePlayerName() $ "'" @ `ShowVar(StatsWriteClass) @ `ShowVar(Stats), true, 'XCom_Net');
				Stats.UpdateFromGameState(Player);

				// This will copy them into the online subsystem where they will be
				// sent via the network in EndOnlineGame()
				OnlineSub.StatsInterface.WriteOnlineStats('Game', Player.GetGameStatePlayerNetId(), Stats);
			}
			else
			{
				`log(`location @ "Skipping Write for Player:" @ Player.GetGameStatePlayerName() @ "bUsesArbitration(" $ GameSettings.bUsesArbitration $ ")", true, 'XCom_Net');
			}
		}
		else
		{
			`log(`location @ "Skipping Write for Player:" @ Player.GetGameStatePlayerName() @ "bUsesStats(" $ GameSettings.bUsesStats $ ")", true, 'XCom_Net');
		}
	}
	else
	{
		`log(`location @ "Skipping Write for Player:" @ Player.GetGameStatePlayerName(), true, 'XCom_Net');
	}
}


simulated function string GetStateDebugString()
{
	local string DebugString;
	local XComGameState_Player PlayerState;

	PlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(CachedUnitActionPlayerRef.ObjectID));

	DebugString = "Unit Action Player  :";
	if( PlayerState != none )
	{
		DebugString @= string(PlayerState.GetVisualizer()) @ " (" @ CachedUnitActionPlayerRef.ObjectID @ ") (" @ (UnitActionPlayerIsRemote() ? "REMOTE" : "") @ ")\n";
	}
	else
	{
		DebugString @= "PlayerState_None";
	}
	DebugString $= "Begin Block Location: " @ GetStateName() @ BeginBlockWaitingLocation @ "\n\n";
	DebugString $= "Player Sync: " @ (bRequiresPlayerSync ? "True" : "False") @ "    ";
	DebugString $= "Sending Partial History: " @ (bSendingPartialHistory ? "True" : "False") @ "\n\n";

	return DebugString;
}

function LocalPlayerForfeitMatch()
{
	local array<byte> Params;
	
	bLocalPlayerForfeited = true;
	NetworkMgr.AddCommandParam_Int(XComTacticalController(GetALocalPlayerController()).ControllingPlayerVisualizer.ObjectID, Params);
	NetworkMgr.SendRemoteCommand("ForfeitMatch", Params);
	HandleForfeitMatch(Params);
}

function HandleForfeitMatch(array<byte> Params)
{
	local int ForfeitPlayerID;
	local XComGameState_Player ForfeitPlayerState, WinnerPlayerState; 

	bShouldDisconnect = true;
	ForfeitPlayerID = NetworkMgr.GetCommandParam_Int(Params);

	`log(`location @ `ShowVar(ForfeitPlayerID) @ `ShowVar(GetReplayMgr().bInReplay, bInReplay),,'XCom_Online');

	// Is the local player active?
	if( !GetReplayMgr().bInReplay )
	{
		ForfeitPlayerState = XComGameState_Player(CachedHistory.GetGameStateForObjectID(ForfeitPlayerID));
		foreach CachedHistory.IterateByClassType(class'XComGameState_Player', WinnerPlayerState)
		{
			if( WinnerPlayerState.IsEnemyPlayer(ForfeitPlayerState) )
			{
				// Find the first enemy of the forfeiting player
				break;
			}
		}

		EndBattle( XGPlayer(WinnerPlayerState.GetVisualizer()) );
	}
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
	local XComGameState             StartState;		
	local XComGameState_Player      PlayerState;
	local XComGameState_Unit        UnitState;

	local array<PlayerSpawnVolume>  arrPlayerVolumes;
	local array<XComFalconVolume>   arrFalconVolumes;

	local XComFalconVolume          kFalconVolume;
	local XComGroupSpawn            kSpawn;
	local int                       VolumeIdx, PlayerIdx;

	local array<TTile>              arrFloorTiles;
	local array<TrackingTile>       arrTrackingTiles;
	local TTile                     SpawnersKeystoneTile;
	local int                       i, k, iX, iY, iDirX, iDirY;
	local int                       iSpawnAreaWidth, iSpawnAreaHeight;
	local int                       iNumPlacementAttempts;
	local bool                      bUnitPlacementFound;

	StartState = CachedHistory.GetStartState();

	//Place each player's units.
	//======================================================================
	if( StartState != none )
	{
		// Find all the players and prepare their data for the Volume array.
		foreach StartState.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
		{
			if (PlayerState == none || PlayerState.TeamFlag == eTeam_XCom || PlayerState.TeamFlag == eTeam_Alien || PlayerState.TeamFlag == eTeam_Neutral)
			{
				`RedScreen("Found an unhandled non-MP PlayerState" @ `ShowEnum(ETeam, PlayerState.TeamFlag, TeamFlag) @ "in the Start State waiting for an associated Spawn Point. @ttalley");
				continue;
			}

			arrPlayerVolumes.Add(1);
			arrPlayerVolumes[arrPlayerVolumes.Length-1].Player = PlayerState;
		}
		
		// Cache all falcon volumes within the world
		foreach `XWORLDINFO.AllActors(class'XComFalconVolume', kFalconVolume)
		{
			arrFalconVolumes.AddItem(kFalconVolume);
		}

		if( arrFalconVolumes.Length < arrPlayerVolumes.Length )
		{
			`RedScreen("Not enough FalconVolumes for Players on this map! @ttalley");
			return;
		}

		//
		// Assign Spawn Points to Players
		//

		// Make sure that the order assigned to the players is randomized
		arrFalconVolumes.RandomizeOrder();

		// Assign a Volume per player
		for( PlayerIdx = 0; PlayerIdx < arrPlayerVolumes.Length; ++PlayerIdx )
		{
			arrPlayerVolumes[PlayerIdx].Volume = arrFalconVolumes[PlayerIdx];
		}

		// For each Spawn point find those within each Player's assigned Volume
		foreach `XWORLDINFO.AllActors(class'XComGroupSpawn', kSpawn)
		{
			for( VolumeIdx = 0; VolumeIdx < arrPlayerVolumes.Length; ++VolumeIdx )
			{
				kFalconVolume = arrPlayerVolumes[VolumeIdx].Volume;
				if(kFalconVolume.ContainsPoint(kSpawn.Location))
				{
					arrPlayerVolumes[VolumeIdx].SpawnPoints.Add(1);
					arrPlayerVolumes[VolumeIdx].SpawnPoints[arrPlayerVolumes[VolumeIdx].SpawnPoints.Length-1].GroupSpawnPoint = kSpawn;
					break;
				}
			}

			kSpawn.SetVisible(false);
		}

		// Randomize all of the SpawnPoints within each Volume
		for( VolumeIdx = 0; VolumeIdx < arrPlayerVolumes.Length; ++VolumeIdx )
		{
			arrPlayerVolumes[VolumeIdx].SpawnPoints.RandomizeOrder();
		}


		//
		// Assign Units to Spawn Point's Floor Locations
		//

		foreach StartState.IterateByClassType(class'XComGameState_Player', PlayerState, eReturnType_Reference)
		{
			// Get the spawn point for this player.
			for( PlayerIdx = 0; PlayerIdx < arrPlayerVolumes.Length; ++PlayerIdx )
			{
				if( arrPlayerVolumes[PlayerIdx].Player.ObjectID == PlayerState.ObjectID )
				{
					kSpawn = arrPlayerVolumes[PlayerIdx].SpawnPoints[0].GroupSpawnPoint;
					break;
				}
			}

			// Gather all the valid Floor Tiles around the spawn point.
			iSpawnAreaWidth = 6;
			iSpawnAreaHeight = 6;
			arrFloorTiles.Length = 0;
			kSpawn.GetValidFloorTilesForMP( arrFloorTiles, iSpawnAreaWidth, iSpawnAreaHeight );


			// Construct a mapping between the selected Floor Tiles and a 2d grid of Tracking Tiles.
			// The grid lets us index tiles in the typical way: Row-by-Column, and 0 indexed.
			// Note that the mapping is not necessarily 1:1.  Some Tracking Tiles in the grid may not
			// map to any valid Floor Tiles.
			SpawnersKeystoneTile = kSpawn.GetTile();
			arrTrackingTiles.Length = 0;
			arrTrackingTiles.Add( iSpawnAreaWidth * iSpawnAreaHeight );
			for ( i = 0; i < arrFloorTiles.Length; ++i )
			{
				iX = ( arrFloorTiles[ i ].X - SpawnersKeystoneTile.X );
				iY = ( arrFloorTiles[ i ].Y - SpawnersKeystoneTile.Y );

				k = ( ( iY * iSpawnAreaWidth ) + iX );
				arrTrackingTiles[ k ].Tile = arrFloorTiles[ i ];
				arrTrackingTiles[ k ].bIsValid = !`XWORLD.IsTileOutOfRange( arrFloorTiles[ i ] );
				arrTrackingTiles[ k ].bIsAvailable = true;
			}
			
			// This is the core logic.  For each unit:
			//   1. Attempt to place the unit in the center of the spawn area.
			//   2. If the center is not available (tile is not valid, or it is already taken),
			//      move 1 tile outward from the center in a random direction, and try again. 
			//   3. Continue moving outward, 1 tile at a time, in the chosen direction,
			//      until a valid placement is found or we are out of range.
			//   4. If we didn't find a valid placement, start over, but pick a new direction
			//      to iterate over.
			//   5. Repeat steps 1-4 until we find a placement or we hit an attempt-count limit.
			//   6. If we STILL can't find a placement, fall back to a basic placement.  This 
			//      will probably be a bad placement, but this should be rare.
			foreach StartState.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
			{				
				`assert(UnitState.bReadOnly == false);

				if ( UnitState.ControllingPlayer.ObjectID == PlayerState.ObjectID )
				{
					bUnitPlacementFound = false;
					iNumPlacementAttempts = 0;

					while ( !bUnitPlacementFound && iNumPlacementAttempts < 100 )
					{
						// Start with the center index.  The -1 accounts for the 0 indexing.  ie if Width=6, we want X=2.
						iX = ( iSpawnAreaWidth - 1 ) / 2;
						iY = ( iSpawnAreaHeight - 1 ) / 2;

						// Pick random cardinal directions
						iDirX = OneOrNegativeOne();
						iDirY = OneOrNegativeOne();

						// Try to place the unit somewhere on the line from the center going outwards
						while ( iX >= 0 && iX < iSpawnAreaWidth && iY >= 0 && iY < iSpawnAreaHeight && !bUnitPlacementFound )
						{
							bUnitPlacementFound = CanUnitBePlacedAtXy( UnitState, arrTrackingTiles, iX, iY, iSpawnAreaWidth, iSpawnAreaHeight );

							if ( bUnitPlacementFound )
							{
								PlaceUnitAtXy( UnitState, arrTrackingTiles, iX, iY, iSpawnAreaWidth );
							}

							// Randomly pick one cardinal direction to move along.  With iteration this results in a
							// line going in an arbitrarily random direction.
							AdjustXorY( iX, iY, iDirX, iDirY );
						}

						iNumPlacementAttempts ++;
					}


					// Fallback - if no placement was found above...
					if ( !bUnitPlacementFound )
					{
						LastResortUnitPlacement( UnitState, arrTrackingTiles, iSpawnAreaWidth, iSpawnAreaHeight );
					}
				}
			}
		}
	}
}

function int OneOrNegativeOne()
{
	if ( `SYNC_RAND(100) > 50 )
		return 1;

	return -1;
}

function AdjustXorY( out int iX, out int iY, int iDirX, int iDirY )
{
	if (`SYNC_RAND(100) > 50) 
		iX += iDirX;
	else
		iY += iDirY;
}

function bool CanUnitBePlacedAtXy( XComGameState_Unit UnitState, array<TrackingTile> arrTrackingTiles, int iX, int iY, int iWidth, int iHeight )
{
	local int iCurrX, iCurrY;
	local int iIndex;

	for ( iCurrX = 0; iCurrX < UnitState.UnitSize; iCurrX ++ )
	{
		for ( iCurrY = 0; iCurrY < UnitState.UnitSize; iCurrY ++ )
		{
			// if we are out of range, the placement doesn't work.
			if ( iX + iCurrX >= iWidth || iY + iCurrY >= iHeight )
				return false;

			// if the tile is not valid and available, the placement doesn't work.
			iIndex = ( (iY + iCurrY) * iWidth ) + (iX + iCurrX);
			if ( !arrTrackingTiles[ iIndex ].bIsValid || !arrTrackingTiles[ iIndex ].bIsAvailable )
				return false;
		}
	}

	return true;
}

function PlaceUnitAtXy( XComGameState_Unit UnitState, out array<TrackingTile> arrTrackingTiles, int iX, int iY, int iWidth )
{
	local int iCurrX, iCurrY;
	local int iIndex;
	local TTile Tile;
	local vector vTileLocation;

	// Place the unit
	iIndex = ( iY * iWidth ) + iX;
	Tile = arrTrackingTiles[ iIndex ].Tile;
	vTileLocation = `XWORLD.GetPositionFromTileCoordinates( Tile );
	UnitState.SetVisibilityLocationFromVector( vTileLocation );

	// Mark each tracking tile this unit occupies as "not available"
	for ( iCurrX = 0; iCurrX < UnitState.UnitSize; iCurrX ++ )
	{
		for ( iCurrY = 0; iCurrY < UnitState.UnitSize; iCurrY ++ )
		{
			iIndex = ( (iY + iCurrY) * iWidth ) + (iX + iCurrX);

			if ( iIndex < arrTrackingTiles.Length )
			{
				arrTrackingTiles[ iIndex ].bIsAvailable = false;
			}
		}
	}
}

function LastResortUnitPlacement( XComGameState_Unit UnitState, out array<TrackingTile> arrTrackingTiles, int iWidth, int iHeight )
{
	local int iX, iY, iIndex;
	local bool bUnitPlacementFound;

	`RedScreen("Failed to find an ideal spawn location.  Using last resort placement instead.  Send to mdomowicz");

	// Attempt to place the unit on the first valid and available tile, even
	// if it means overlapping with other units or the environment (which can happen
	// when a unit is 2x2 or larger in size).
	bUnitPlacementFound = false;
	for ( iX = 0; iX < iWidth; iX ++ )
	{
		for ( iY = 0; iY < iHeight; iY ++ )
		{
			iIndex = (iY * iWidth) + iX;
			if ( arrTrackingTiles[ iIndex ].bIsAvailable )
			{
				PlaceUnitAtXy( UnitState, arrTrackingTiles, iX, iY, iWidth );
				bUnitPlacementFound = true;
			}
		}
	}

	// If a unit is **STILL** not placable, just place at the first valid tile, even if it
	// is not available.
	if ( !bUnitPlacementFound )
	{
		for ( iX = 0; iX < iWidth; iX ++ )
		{
			for ( iY = 0; iY < iHeight; iY ++ )
			{
				iIndex = (iY * iWidth) + iX;
				if ( arrTrackingTiles[ iIndex ].bIsValid )
				{
					PlaceUnitAtXy( UnitState, arrTrackingTiles, iX, iY, iWidth );
					bUnitPlacementFound = true;
				}
			}
		}
	}


	// If this assert fires, there were no valid tiles to begin with, which is very wrong.  
	// Speak with mdomowicz.
	`assert( bUnitPlacementFound );
}



simulated function bool HasTimeExpired()
{
	local XComGameState_TimerData Timer;

	Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));

	return Timer != none && Timer.HasTimeExpired();
}

/// <summary>
/// Determines the starting player and gives them priority to continue generating states while the other player waits in a replay state.
/// </summary>
simulated state TurnPhase_MPGameStart
{
	simulated event BeginState(name PreviousStateName)
	{
		local XComGameState_Player Player;
		local XComGameState_BattleDataMP BattleData;

		`log(`location @ `ShowVar(bReceivedNotifyConnectionClosed),, 'WTF');
		if(bReceivedNotifyConnectionClosed)
		{
			GotoState('ConnectionClosed');
		}

		BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		foreach CachedHistory.IterateByClassType(class'XComGameState_Player', Player)
		{
			WriteOnlineStatsForPlayer(BattleData, Player, "TacticalGameStart");
		}
		FinishWriteOnlineStats();

		bRulesetRunning = true;

		class'AnalyticsManager'.static.SendMPStartTelemetry( CachedHistory );

		// Do not keep a record of this state in the History.
	}

	simulated function EndPhase()
	{
		local XComGameStateContext_TacticalGameRule SyncVisualizersContext;

		StartNetworkedVoiceChecked();

		// Is the first player a remote player?
		if( !(NetworkMgr.bPauseGameStateSending && PlayerIsRemote(0)) )
		{
			if( NetworkMgr.bPauseGameStateSending )
			{
				bSkipFirstPlayerSync = true;
			}

			// If we don't do this, then the first acting player will have all their units
			// facing the wrong direction on game start.  mdomowicz 2015_12_08
			SyncVisualizersContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
			SyncVisualizersContext.GameRuleType = eGameRule_ForceSyncVisualizers;
			`XCOMGAME.GameRuleset.SubmitGameStateContext(SyncVisualizersContext);

			GotoState( GetNextTurnPhase( GetStateName() ) );
		}
		else
		{
			// Inactive player and should goto Replay
			GetReplayMgr().ResumeReplay();
		}
	}

	simulated function bool AllowVisualizerSelection()
	{
		return false;
	}

Begin:
	`SETLOC("Waiting for Player Sync");
	LatentWaitingForPlayerSync();

	`SETLOC("Waiting for Visualizer: 1");
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	`SETLOC("Ending the Phase");
	EndPhase();
	`SETLOC("End of Begin Block");
}

/// <summary>
/// State generation for the end of the last player's turn and the beginning of the new player's turn. This should only happen for the player with priority.
/// </summary>
simulated state TurnPhase_BeginPlayerTurn extends TurnPhase_UnitActions
{
	simulated function BeginUnitActions()
	{
		BeginPlayerTurn();
	}

	simulated function InitializePlayerTurnOrder()
	{
		local XComGameState_BattleDataMP BattleData;
		BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		if( UnitActionPlayerIndex >= BattleData.PlayerTurnOrder.Length )
		{
			UnitActionPlayerIndex = 0;
		}
	}

	simulated function string GetStateDebugString()
	{
		local string DebugString;

		DebugString = Super.GetStateDebugString();
		DebugString $= "Player Sync: " @ (bRequiresPlayerSync ? "True" : "False") @ "    ";
		DebugString $= "Sending Partial History: " @ (bSendingPartialHistory ? "True" : "False") @ "\n\n";

		return DebugString @ "\n\n";
	}

Begin:
	`SETLOC("Start of Begin Block");
	// Waiting a tick before processing TurnPhase_BeginPlayerTurn allows listeners to respond to event triggers and keep the History in sync
	sleep(0.0);
	CachedHistory.CheckNoPendingGameStates();

	//Wait for the visualizer to perform the visualization steps for all states before we permit the rules engine to proceed to the next phase
	while( WaitingForVisualizer() )
	{
		`SETLOC("Waiting for Visualizer: 1");
		sleep(0.0);
	}

	`SETLOC("Ending the Phase");
	EndPhase();
	`SETLOC("End of Begin Block");
}

/// <summary>
/// This turn phase waits for all players to get to identical locations in the ruleset before continuing. It also serves 
/// as a point where a 'reconnect' could occur if the two machines get too divergent.
/// </summary>
simulated state TurnPhase_PlayerSync
{
	simulated event BeginState(name PreviousStateName)
	{
		`log(`location @ "Adding TurnPhase_PlayerSync to the History.",,'XCom_GameStates');
		BeginState_RulesAuthority(none);

		SendPartialHistory(bRequiresPlayerSync);
	}

	function OnRemoteCommand(string Command, array<byte> RawParams)
	{
		if( Command ~= "HistoryReceived" )
		{
			SendRemoteCommand("SwitchTurn");
		}
		global.OnRemoteCommand(Command, RawParams);
	}

	function EndPhase()
	{
		if( NetworkMgr.bPauseGameStateSending )
		{
			// This is now the inactive player and should go into Replay mode
			GetReplayMgr().ResumeReplay();
		}
		else
		{
			GotoState(GetNextTurnPhase(GetStateName()));
		}
	}

Begin:
	`SETLOC("Waiting for player sync ...");
	while( bSendingPartialHistory )
	{
		sleep(0.0);
	}

	`SETLOC("Waiting for Visualizer: 1");
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	// Skip this functionality if the history is being sent across the wire.
	if( !NetworkMgr.bPauseGameStateSending )
	{
		`SETLOC("Starting Player Sync ...");
		//Wait for all players to reach this point in their rules engine
		LatentWaitingForPlayerSync();
	}

	`SETLOC("End of Begin Block");
	EndPhase();
}

/// <summary>
/// Overriding the base class version of this state to allow it to re-enter per player turn.
/// </summary>
simulated state TurnPhase_MPUnitActions extends TurnPhase_UnitActions
{
	simulated event BeginState(name PreviousStateName)
	{
		local XComGameState_TimerData Timer;

		Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
		Timer.ResetTimer();

		// Skipping the NextPlayer() logic in the base, instead this happens in the TurnPhase_BeginPlayerTurn & TurnPhase_EndPlayerTurn.
		BeginState_RulesAuthority(SetupUnitActionsState);
	}

	event Tick(float DeltaTime)
	{
		// Skipping all AI logic ...
	}

	simulated function string GetStateDebugString()
	{
		local string DebugString;

		DebugString = Super.GetStateDebugString();
		DebugString $= "Player Sync: " @ (bRequiresPlayerSync ? "True" : "False") @ "    ";
		DebugString $= "Sending Partial History: " @ (bSendingPartialHistory ? "True" : "False") @ "\n\n";

		return DebugString @ "\n\n";
	}

	simulated function SendResetTime()
	{
		local XComGameState_TimerData Timer;
		local array<byte> Parms;

		//Ensure that the timer is not stopped.
		Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
		Timer.bStopTime = false;

		Parms.Length = 0; // Removes script warning.
		`log("Send Reset Time", , 'XCom_Online');
		NetworkMgr.SendRemoteCommand("ResetTime", Parms);
	}

Begin:
	`SETLOC("Start of Begin Block");
	CachedHistory.CheckNoPendingGameStates();

	sleep(0.0); // Wait a tick for the game states to be updated before switching the sending

	//Before switching players, wait for the current player's last action to be fully visualized
	`SETLOC("Waiting for Visualizer: 1");
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	//Let the other player know the timer has been reset after the visualizer is complete to avoid having the timer stopped due to a busy visualizer.
	SendResetTime();

	`SETLOC("Checking for Tactical Game Ended - PreActions");
	//Perform fail safe checking for whether the tactical battle is over
	FailsafeCheckForTacticalGameEnded();

	`SETLOC("Check for Available Actions");
	while( ActionsAvailable() && (!HasTacticalGameEnded()) && (!HasTimeExpired()) )
	{
		SendPartialHistory();

		WaitingForNewStatesTime = 0.0f;

		//Wait for new states created by the player / AI / remote player. Manipulated by the SubmitGameStateXXX methods
		`SETLOC("Available Actions");
		while( bWaitingForNewStates && (!HasTacticalGameEnded()) && (!HasTimeExpired()) )
		{
			sleep(0.0);
		}
		`SETLOC("Available Actions: Done waiting for New States");

		CachedHistory.CheckNoPendingGameStates();

		sleep(0.0);

		`SETLOC("Checking for Tactical Game Ended");
		//Perform fail safe checking for whether the tactical battle is over
		FailsafeCheckForTacticalGameEnded();
	}
	`SETLOC("Disabling input for the local player");
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).SetInputState('Multiplayer_Inactive');

	// need to check again as its possible to break from the loop without hitting the failsafe check and thus the game never ends.
	// this can happen if all units die on the same turn, say from a massive explosion. TTP #21451 -tsmith
	FailsafeCheckForTacticalGameEnded();

	`SETLOC("Waiting for previous History to be sent ...");
	while( bSendingPartialHistory )
	{
		sleep(0.0);
	}

	SendPartialHistory();

	`SETLOC("Waiting for History to be sent ...");
	while( bSendingPartialHistory )
	{
		sleep(0.0);
	}

	`SETLOC("Waiting for Visualizer: 2");
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	`SETLOC("Ending the Phase");
	GotoState( GetNextTurnPhase( GetStateName() ) );
	`SETLOC("End of Begin Block");
}

/// <summary>
/// State generation for the end of the last player's turn and the beginning of the new player's turn. This should only happen for the player with priority.
/// </summary>
simulated state TurnPhase_EndPlayerTurn extends TurnPhase_UnitActions
{
	simulated function BeginUnitActions()
	{
		EndPlayerTurn();
		++UnitActionPlayerIndex;
	}

	simulated function InitializePlayerTurnOrder()
	{
		// Intentionally doing nothing here
	}

	simulated function string GetStateDebugString()
	{
		local string DebugString;

		DebugString = Super.GetStateDebugString();
		DebugString $= "Player Sync: " @ (bRequiresPlayerSync ? "True" : "False") @ "    ";
		DebugString $= "Sending Partial History: " @ (bSendingPartialHistory ? "True" : "False") @ "\n\n";

		return DebugString @ "\n\n";
	}

Begin:
	`SETLOC("Start of Begin Block");
	CachedHistory.CheckNoPendingGameStates();

	//Wait for the visualizer to perform the visualization steps for all states before we permit the rules engine to proceed to the next phase
	while( WaitingForVisualizer() )
	{
		`SETLOC("Waiting for Visualizer: 1");
		sleep(0.0);
	}

	`SETLOC("Ending the Phase");
	EndPhase();
	`SETLOC("End of Begin Block");
}

/// <summary>
/// This state is entered when a tactical game ended state is pushed onto the history
/// </summary>
simulated state EndTacticalGame
{
	simulated event BeginState(name PreviousStateName)
	{
		`log(self $ "::" $ GetStateName() $ "::" $ GetFuncName(),,'WTF');

		if( NetworkMgr.bPauseGameStateSending && PreviousStateName != 'PerformingReplay' )
		{
			bRequiresPlayerSync = true;
			bWaitingForEndTacticalGame = false;
			BeginState_RulesAuthority(OnEndTacticalGame_SetupStateChange);

			CleanupTacticalMission();
			EndTacticalPlay();
		}
		else
		{
			SendRemoteCommand("EnteredEndTacticalGame");
		}
	}

	function OnEndTacticalGame_SetupStateChange(XComGameState SetupState)
	{
		local array<XComGameState_Player> PlayerCache, UpdatedPlayerCache;
		local XComGameState_Player Player, NewPlayer;
		local XComGameState_Player Enemy;
		local int PlayerIdx, EnemyIdx;
		local XComGameState_BattleDataMP BattleData;

		BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		for( PlayerIdx = 0; PlayerIdx < BattleData.PlayerTurnOrder.Length; ++PlayerIdx)
		{
			Player = XComGameState_Player(CachedHistory.GetGameStateForObjectID(BattleData.PlayerTurnOrder[PlayerIdx].ObjectID));
			PlayerCache.AddItem(Player);
			NewPlayer = XComGameState_Player(SetupState.CreateStateObject(Player.Class, Player.ObjectID));
			UpdatedPlayerCache.AddItem(NewPlayer);
			SetupState.AddStateObject(NewPlayer);
		}

		for( PlayerIdx = 0; PlayerIdx < UpdatedPlayerCache.Length; ++PlayerIdx)
		{
			Player = UpdatedPlayerCache[PlayerIdx];
			for( EnemyIdx = 0; EnemyIdx < UpdatedPlayerCache.Length; ++EnemyIdx )
			{
				// Want the enemy from the old player cache, since we do not want the updated skill value.
				Enemy = PlayerCache[EnemyIdx];
				if( PlayerIdx != EnemyIdx && Player.IsEnemyPlayer(Enemy) )
				{
					Player.FinishMatch('Ranked', Enemy, (BattleData.VictoriousPlayer.ObjectID == Player.ObjectID) ? EOMRT_Win : EOMRT_Loss);
					break;
				}
			}
		}
	}

	function Local_WritePlayerStats()
	{
		local XComOnlineEventMgr OnlineEventManager;
		local XComTacticalController LocalController;
		local XComGameState_BattleDataMP BattleData;
		local XComGameState_Player LocalPlayer;
		local StateObjectReference LocalPlayerRef;

		OnlineEventManager = `ONLINEEVENTMGR;
		LocalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
		LocalPlayerRef = LocalController.ControllingPlayer;
		LocalPlayer = XComGameState_Player(CachedHistory.GetGameStateForObjectID(LocalPlayerRef.ObjectID));
		BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		// update the last match info so that it doesn't consider this match as incomplete
		XComMPTacticalPRI(LocalController.PlayerReplicationInfo).m_bRankedDeathmatchLastMatchStarted = false; // match is done!
		OnlineEventManager.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_bMatchStarted = false;
		OnlineEventManager.FillLastMatchPlayerInfoFromPRI(OnlineEventManager.m_kMPLastMatchInfo.m_kLocalPlayerInfo, XComMPTacticalPRI(LocalController.PlayerReplicationInfo));

		WriteOnlineStatsForPlayer(BattleData, LocalPlayer, "TacticalGameEnd");
		FinishWriteOnlineStats();
	}

	function Local_UpdateBattleData()
	{
		local XComGameState_BattleDataMP NewBattleData;
		local XComGameState NewGameState;
		local StateObjectReference LocalPlayerRef;

		LocalPlayerRef = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ControllingPlayer;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Local Update - EndTacticalGame");
		NewBattleData = XComGameState_BattleDataMP(NewGameState.CreateStateObject(class'XComGameState_BattleDataMP', CachedBattleDataRef.ObjectID));
		NewBattleData.bLocalPlayerWon = (LocalPlayerRef == NewBattleData.VictoriousPlayer);
		NewGameState.AddStateObject(NewBattleData);
		SubmitGameState(NewGameState);
	}

	function OnRemoteCommand(string Command, array<byte> RawParams)
	{
		if( Command ~= "HistoryReceived" )
		{
			SendRemoteCommand("EndTacticalGame");
		}
		else if( Command ~= "EnteredEndTacticalGame" )
		{
			bWaitingForEndTacticalGame = false;
		}
		global.OnRemoteCommand(Command, RawParams);
	}

	simulated function NextSessionCommand()
	{
		ConsoleCommand("open XComShell_Multiplayer?Game=XComGame.XComMPShell");
	}

	function OnNotifyConnectionClosed(int ConnectionIdx)
	{
		// Already at the end of the game, no reason to do anything here.
		bSendingPartialHistory = false;
		bDisconnected = true;
	}

	// Overridding the global functionality to make sure we don't change to the ConnectionClosed state
	function OnLobbyMemberStatusUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, int InstigatorIndex, string Status)
	{
		local string Reason;
		`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(InstigatorIndex) @ `ShowVar(Status),,'XCom_Online');
		if( InStr(Status, "Exit") > -1 )
		{
			// Exit Event Happened
			Reason -= "Exit - ";
			`log(`location @ `ShowVar(Reason),,'XCom_Online');
			// Player left, we don't care about this since it's the end of the game.
		}
	}



Begin:
	`SETLOC("Start of Begin Block");
	CachedHistory.CheckNoPendingGameStates();

	sleep(0.0); // Wait a tick for the game states to be updated before switching the sending

	//Before switching players, wait for the current player's last action to be fully visualized
	`SETLOC("Waiting for Visualizer: 1");
	while( WaitingForVisualizer() )
	{
		sleep(0.0);
	}

	if( bRequiresPlayerSync )
	{
		`SETLOC("Waiting for previous History to be sent...");
		while( bSendingPartialHistory )
		{
			sleep(0.0);
		}

		`SETLOC("Sending Partial History");
		bWaitingForEndTacticalGame = true;
		SendPartialHistory();

		`SETLOC("Waiting for Player Sync ...");
		while( bWaitingForEndTacticalGame )
		{
			sleep(0.0);
		}
	}

	Local_UpdateBattleData();
	Local_WritePlayerStats();

	class'AnalyticsManager'.static.SendMPEndTelemetry( CachedHistory, true );

	bShouldDisconnect = true; // Always disconnecting!
	if( bShouldDisconnect )
	{
		DisconnectGame();
	}

	if( !bLocalPlayerForfeited )
	{
		//Show the mission summary screen and wait for input
		`SETLOC("Opening UI Mission Summary Screen");
		`PRES.UIMPShowPostMatchSummary();

		//This variable is cleared by the mission summary screen accept button
		bWaitingForMissionSummary = true;
		`SETLOC("Waiting For Mission Summary to Close ...");
		while(bWaitingForMissionSummary)
		{
			sleep(0.0f);
		}
	}

	Cleanup();

	NextSessionCommand();
	`SETLOC("End of Begin Block");
}

simulated state ConnectionClosed
{
	function OnNotifyConnectionClosed(int ConnectionIdx)
	{
		// do nothing, since we are already in this state -tsmith
	}

	function StatsWriteWinDueToDisconnect()
	{
		local XComOnlineStatsWriteDeathmatchClearGameStartedFlagDueToDisconnect kClearDeathmatchStartedFlag;
		local UniqueNetId NetId;
		local string UniqueNetString;
		local XComOnlineGameSettings GameSettings;
		local XComOnlineEventMgr OnlineEventManager;
		local XComGameState_Player LocalPlayer;
		local StateObjectReference LocalPlayerRef;
		local XComTacticalController LocalController;
		local XComGameState_BattleDataMP BattleData;

		`log(`location @ `ShowVar(OnlineSub) @ `ShowVar(OnlineSub.StatsInterface), true,'XCom_Online');
		if (OnlineSub != None && OnlineSub.StatsInterface != None)
		{
			OnlineEventManager = `ONLINEEVENTMGR;
			LocalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
			LocalPlayerRef = LocalController.ControllingPlayer;
			LocalPlayer = XComGameState_Player(CachedHistory.GetGameStateForObjectID(LocalPlayerRef.ObjectID));
			BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
			GameSettings = XComOnlineGameSettings(BattleData.GameSettings);

			NetId = LocalPlayer.GetGameStatePlayerNetId();
			UniqueNetString = OnlineSub.UniqueNetIdToString(NetId);
			`log(`location @ `ShowVar(GameSettings) @ `ShowVar(LocalPlayer.GetGameStatePlayerName()) @ `ShowVar(UniqueNetString), true,'XCom_Online');

			// clear ranked match flag if we are ranked, also write win because we have been disconnected by other player -tsmith 
			if(GameSettings.GetIsRanked())
			{
				`log(`location @ "Attempting to clear game started flag", true, 'XCom_Online');
				kClearDeathmatchStartedFlag = new class'XComOnlineStatsWriteDeathmatchClearGameStartedFlagDueToDisconnect';
				kClearDeathmatchStartedFlag.UpdateFromGameState(LocalPlayer);
				if(!OnlineSub.StatsInterface.WriteOnlineStats('Game', NetId, kClearDeathmatchStartedFlag))
				{
					`warn(`location @ "WriteOnlineStats failed, can't clear match started flag", true, 'XCom_Online');
				}
				else if(OnlineEventManager.bOnlineSubIsSteamworks)
				{
					// steam needs to flush the stats so they get cached in the steam client and will eventually get written -tsmith 
					`log(`location @ "OnlineSubsystem is Steam, attempting to flush stats...", true, 'XCom_Online');
					if(!OnlineSub.StatsInterface.FlushOnlineStats('Game'))
					{
						`warn(`location @ "     FlushOnlineStats failed, can't write leaderboard stats", true, 'XCom_Online');
					}
					else
					{
						`log(`location @ "      FlushOnlineStats successful", true, 'XCom_Online');
					}
				}
			}
		}
	}

	function EndDisconnectedGame()
	{
		local array<XComGameState_Player> PlayerCache;
		local XComOnlineEventMgr OnlineEventManager;
		local XComGameState_BattleDataMP BattleData;
		local XComTacticalController LocalController;
		local XComGameState_Player LocalPlayer, Player, Enemy;
		local StateObjectReference LocalPlayerRef;
		local int PlayerIdx, EnemyIdx;
		local MatchResultType MatchResult;

		OnlineEventManager = `ONLINEEVENTMGR;
		LocalController = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController());
		LocalPlayerRef = LocalController.ControllingPlayer;
		LocalPlayer = XComGameState_Player(CachedHistory.GetGameStateForObjectID(LocalPlayerRef.ObjectID));
		BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));

		MatchResult = EOMRT_AbandonedWin; // Assuming that the disconnection should result in a win
		// Check to see if the disconnected player has a net connection
		if( !OnlineSub.SystemInterface.HasLinkConnection() )
		{
			// Player lost link intentionally or unintentionally, either way going to force an abandoned loss here.
			MatchResult = EOMRT_AbandonedLoss;
		}

		for( PlayerIdx = 0; PlayerIdx < BattleData.PlayerTurnOrder.Length; ++PlayerIdx)
		{
			Player = XComGameState_Player(CachedHistory.GetGameStateForObjectID(BattleData.PlayerTurnOrder[PlayerIdx].ObjectID));
			PlayerCache.AddItem(Player);
		}

		for( PlayerIdx = 0; PlayerIdx < PlayerCache.Length; ++PlayerIdx)
		{
			Player = PlayerCache[PlayerIdx];
			for( EnemyIdx = 0; EnemyIdx < PlayerCache.Length; ++EnemyIdx )
			{
				// Want the enemy from the old player cache, since we do not want the updated skill value.
				Enemy = PlayerCache[EnemyIdx];
				if( PlayerIdx != EnemyIdx && Player.IsEnemyPlayer(Enemy) && Player.IsLocalPlayer() )
				{
					`log(`location @ Player.ToString() @ Enemy.ToString(), true,'XCom_Online');
					// For the remote player that disconnected, they will have their disconnects increased in UIMPShell_SquadCostPanel_LocalPlayer
					Player.FinishMatch('Ranked', Enemy, MatchResult);
					break;
				}
			}
		}

		// update the last match info so that it doesn't consider this match as incomplete
		XComMPTacticalPRI(LocalController.PlayerReplicationInfo).m_bRankedDeathmatchLastMatchStarted = false; // match is done!
		OnlineEventManager.m_kMPLastMatchInfo.m_kLocalPlayerInfo.m_bMatchStarted = false;
		OnlineEventManager.FillLastMatchPlayerInfoFromPRI(OnlineEventManager.m_kMPLastMatchInfo.m_kLocalPlayerInfo, XComMPTacticalPRI(LocalController.PlayerReplicationInfo));
		WriteOnlineStatsForPlayer(BattleData, LocalPlayer, "Disconnected");
		FinishWriteOnlineStats();

		class'AnalyticsManager'.static.SendMPEndTelemetry( CachedHistory, false );
	}

Begin:
	`SETLOC("Start of Begin Block");

	`SETLOC("Ending the game");
	EndDisconnectedGame();

	`SETLOC("Shutting down the network");
	DisconnectGame();

	`SETLOC("Showing disconnected screen");
	`PRES.UIMPShowDisconnectedOverlay();

	`SETLOC("End of Begin Block");
}

simulated function bool PlayersAreWaitingForATurn()
{
	local XComGameState_BattleDataMP BattleData;
	BattleData = XComGameState_BattleDataMP(CachedHistory.GetGameStateForObjectID(CachedBattleDataRef.ObjectID));
	return (UnitActionPlayerIndex < BattleData.PlayerTurnOrder.Length);
}

simulated function name GetNextTurnPhase(name CurrentState, optional name DefaultPhaseName='TurnPhase_End')
{
	if (HasTacticalGameEnded())
	{
		return 'EndTacticalGame';
	}

	if(bReceivedNotifyConnectionClosed)
	{
		return 'ConnectionClosed';
	}

	switch (CurrentState)
	{
	case 'CreateTacticalGame':
		return 'PostCreateTacticalGame';
	case 'PostCreateTacticalGame':
		return 'TurnPhase_MPGameStart';
	case 'LoadTacticalGame':
		if (LoadedGameNeedsPostCreate())
		{
			return 'PostCreateTacticalGame';
		}
		return 'PerformingReplay';

	//
	// Start MP Game: (Passive) Enter Replay Mode; (Active) Turn Phase Begin
	//
	case 'TurnPhase_MPGameStart':
		return 'TurnPhase_Begin';

	//
	// Phase Loop: Phase Begin -> Player Turn Loop -> Phase End
	//
	case 'TurnPhase_Begin':
		return 'TurnPhase_BeginPlayerTurn';
	// Enter Player Turn Loop
	case 'TurnPhase_End':
		return 'TurnPhase_Begin';

	//
    // Player Turn Loop: Player Begin -> Player Sync -> (Passive) Enter Replay Mode; (Active) MPUnit Actions -> Player End -> (More Player Turns) Player Begin; (All Complete) Phase End
	//
	case 'TurnPhase_BeginPlayerTurn':
		if( bSkipFirstPlayerSync )
		{
			bSkipFirstPlayerSync = false;
			return 'TurnPhase_MPUnitActions';
		}
		return 'TurnPhase_PlayerSync';

	case 'TurnPhase_PlayerSync':
		return 'TurnPhase_MPUnitActions';
	case 'PerformingReplay':
		return 'TurnPhase_MPUnitActions';

	case 'TurnPhase_MPUnitActions':
		return 'TurnPhase_EndPlayerTurn';
	case 'TurnPhase_EndPlayerTurn':
		if( PlayersAreWaitingForATurn() )
		{
			return 'TurnPhase_BeginPlayerTurn';
		}
		return 'TurnPhase_End';
	}
	`assert(false);
	return DefaultPhaseName;
}

defaultproperties
{
	UnitActionPlayerIndex=0
	bRequiresPlayerSync=false

	// Defaults for if your game has only one skill leaderboard
	LeaderboardId=0xFFFE0000
	ArbitratedLeaderboardId=0xFFFF0000
}
