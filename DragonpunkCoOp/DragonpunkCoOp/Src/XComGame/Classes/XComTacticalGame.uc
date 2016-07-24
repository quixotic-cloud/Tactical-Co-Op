//---------------------------------------------------------------------------
//
//---------------------------------------------------------------------------
class XComTacticalGame extends XComGameInfo
	dependson(XGLevel);

var bool								bDebugCombatRequested;
var bool                                bNoVictory;
var name                                ForcedSpawnGroupTag;
var int                                 ForcedSpawnGroupIndex;
var string                              strSaveFile;
var bool                                m_bLoadingFromShell;
var bool                                m_bDisableLoadingScreen;

var XComProfileGrid                     m_kProfileGrid;

// ranked games must disconnect if stat read fails otherwise stats would not get recorded correctly -tsmith 
const MAX_FAILED_STAT_READS_UNTIL_RANKED_GAME_DISCONNECT = 4;

var                 int     m_iRequiredPlayers;
//var protectedwrite  int     m_iMaxTurnTimeSeconds;
var protectedwrite  bool    m_bMatchStarting;
var XComOnlineStatsRead     m_kStatsRead;

/** amount of time in seconds the game waits for all players to join before it disconnects */
var config          float   m_fPendingMatchTimeoutSeconds;
var privatewrite    float   m_fPendingMatchTimeoutCounter;
var privatewrite    bool    m_bPendingMatchTimedOut;
var privatewrite    bool    m_bDisconnectedBecauseLogoutsBeforeGameStart;
var privatewrite    bool    m_bPingingMCP;
var privatewrite    bool    m_bHasWorldCleanedUp;
var protectedwrite  int     m_iMaxTurnTimeSeconds;
var privatewrite XComTacticalController m_kPlayerLoggingOut;
var privatewrite XComTacticalController m_kLocalPlayer;
var privatewrite XComTacticalController m_kOpponentPlayer;

//-----------------------------------------------------------
auto state PendingMatch
{
	function bool IsLoading()
	{
		local bool bLoading;
		local string MyURL;
		MyURL = WorldInfo.GetLocalURL();
		bLoading = InStr(MyURL, "LoadingSave") != -1;
		return bLoading;
	}

	event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		m_bMatchStarting = false;
	}

	function Tick( float fDTime )
	{
		if( WorldInfo.NetMode != NM_Standalone )
		{
			if(m_bPendingMatchTimedOut)
			{
				return;
			}

			if(!m_bMatchStarting)
			{
				m_fPendingMatchTimeoutCounter += fDTime;
				if(m_fPendingMatchTimeoutCounter >= m_fPendingMatchTimeoutSeconds)
				{
					m_bPendingMatchTimedOut = true;
					ConsoleCommand("disconnect");
					return;
				}
				// TODO: SP has 0 required players
				if( CountHumanPlayers() >= m_iRequiredPlayers )
				{
					`Log( "Player quota met, calling StartMatch()" @ "State=" $ GetStateName(), true, 'XCom_Net' );
					m_bMatchStarting = true;
					StartMatch();
				}
			}
		}
	}


Begin:
	// for now, MP uses the same code path -tsmith
	//if( WorldInfo.NetMode == NM_Standalone )
	//{
		if( IsLoading() )
		{
			`MAPS.AddStreamingMapsFromURL(WorldInfo.GetLocalURL(), false);
			GetALocalPlayerController().ClientFlushLevelStreaming();
		}

		while( WorldInfo.bRequestedBlockOnAsyncLoading )
		{
			Sleep( 0.1f );
		}

		if (class'WorldInfo'.static.IsPlayInEditor())
		{
			while (!`MAPS.IsStreamingComplete( ))
			{
				sleep( 0.0f );
			}
		}

		StartMatch();
		while( WorldInfo.GRI.IsInState( 'LoadingFromStrategy' ) )
		{
			Sleep( 0.1f );
		}
	//}
	//else
	//{
	//	`Log( "XComTacticalGame: Started in non-standalone mode... confused" );
	//}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
state Playing
{
	//
	// Player exits.
	//
	function Logout( Controller Exiting )
	{
		super.Logout(Exiting);
		return; // TODO: Add in reconnection logic -ttalley
	}

Begin:
}

function Logout( Controller Exiting )
{
	super.Logout(Exiting);

	return; // TODO: Add in reconnection logic -ttalley
}

/**
 * Updates the online subsystem's information for player counts 
 */
function UpdateGameSettingsCounts()
{
	// do nothing, we are in game, don't allow joins, so we dont want our game to show up in searches. -tsmith 
}

function bool IsGameControllerLoggingOut(Controller Exiting)
{
	local bool bIsValid;

	bIsValid = true;
	if(Exiting.Class != PlayerControllerClass)
	{
		ScriptTrace();
		`log(self $ "::" $ GetFuncName() @ "Non game controller logging out" @ `ShowVar(Exiting.Class) @ `ShowVar(PlayerControllerClass), true, 'XCom_Net');
		bIsValid = false;;
	}

	return bIsValid;
}

function StartMatch()
{
	super.StartMatch();

	InitResources();
	PostStartMatch();
}

function InitResources()
{
	local string Resource;

	foreach PawnAnimSetNames(Resource)
	{
		if (Len(Resource) > 0)
			PawnAnimSets.AddItem(AnimSet(DynamicLoadObject(Resource, class'AnimSet')));
	}
}

function PostStartMatch()
{
	GotoState('Playing');
}

/** Does end of game handling for the online layer */
function PerformEndGameHandling()
{
	super.PerformEndGameHandling();
}

event InitGame( string Options, out string ErrorMessage )
{
	local string InOpt;
	local string InOpt2;
	local string InOpt3;
	local string InOpt4;
	local string strMaxTurnTimeSeconds;

	`log(`location @ `ShowVar(WorldInfo.IsInSeamlessTravel()) @ `ShowVar(Options), true, 'XCom_Net');
	`log("OPTIONS = "@Options,,'GameCore');

	super.InitGame(Options, ErrorMessage);

	InOpt = ParseOption( Options, "DebugCombat");
	if( InOpt != "" )
	{
		bDebugCombatRequested = true;
		`log("Requesting Debug Combat");
	}

	InOpt = ParseOption(Options, "NoVictory");
	if (InOpt != "")
	{
		bNoVictory = true;
		`log("Requesting No Victory");
	}

	InOpt = ParseOption(Options, "SpawnGroup");
	if (InOpt != "")
	{
		ForcedSpawnGroupTag = name(InOpt);
		ForcedSpawnGroupIndex = int(Split( ForcedSpawnGroupTag, "Group", true));
		`LOG("Forcing spawn group" @ ForcedSpawnGroupTag);
	}
	else
	{
		ForcedSpawnGroupIndex = -1;
	}

	strMaxTurnTimeSeconds = ParseOption(Options, "MaxTurnTimeSeconds");
	if(strMaxTurnTimeSeconds != "")
	{
		m_iMaxTurnTimeSeconds = FMax(0, float(strMaxTurnTimeSeconds));
	}
	else
	{
		m_iMaxTurnTimeSeconds = 0.0;
	}

	OnlineGameSettingsClass = GetOnlineGameSettingsClass();
	OnlineStatsWriteClass = GetOnlineStatsWriteClass("");
	`log(self $ "::" $ GetFuncName() @ `ShowVar(OnlineGameSettingsClass) @ `ShowVar(OnlineStatsWriteClass), true, 'XCom_Online');

	// Is this an attempt to load a saved Battle?
	strSaveFile = ParseOption( Options, "SaveFile");

	`if(`notdefined(FINAL_RELEASE))
	if (ParseOption(Options, "ProfileGrid") != "")
	{
		m_kProfileGrid = Spawn(class'XComProfileGrid');
	}
	`endif

	// Was this battle triggered from the Shell?  (Not from the strategy game) if so load in our 
	// fake savegame to setup the soldier equipment loadouts.
	InOpt = ParseOption(Options, "LoadingFromShell");
	InOpt2 = ParseOption(Options, "NoLoadingScreen");
	InOpt3 = ParseOption(Options, "LoadingFromStrategy");
	InOpt4 = ParseOption(Options, "ActionReplay");

	`Log("InOpt:"@InOpt,,'GameCore');
	`Log("InOpt2:"@InOpt2,,'GameCore');
	if (InOpt2 !="")
	{
		m_bDisableLoadingScreen = true;
	}

	if (InOpt4 != "")
	{
		//m_bLoadingActionReplay = true;
	}

	if (InOpt != "" || InOpt2 != "" || WorldInfo.IsPlayInEditor())
	{
		m_bLoadingFromShell = true;
		`log("Requesting Loading from Shell",,'GameCore');
	}

	if (InOpt3 != "")
	{
		m_bLoadingFromShell = false;
		`log("Requesting Loading from Strategy",,'GameCore');
	}
}

function InitGameReplicationInfo()
{
	local XComOnlineGameSettings kGameSettings;
	local XComMPTacticalGRI kGRI;

	super.InitGameReplicationInfo();

	kGameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	// in certain debug runs of the game we will not get a game settings class so just emit a warning instead of a crash -tsmith 
	if(kGameSettings != none)
	{
		kGRI = XComMPTacticalGRI(WorldInfo.GRI);
		kGRI.m_eGameType = kGameSettings.GetGameType();
		kGRI.m_eNetworkType = kGameSettings.GetNetworkType();
		kGRI.m_iMaxSquadCost = kGameSettings.GetMaxSquadCost();
		kGRI.m_iTurnTimeSeconds = kGameSettings.GetTurnTimeSeconds();
		kGRI.m_bIsRanked = kGameSettings.GetIsRanked();
		kGRI.m_iMapPlotType = kGameSettings.GetMapPlotTypeInt();
		kGRI.m_iMapBiomeType = kGameSettings.GetMapBiomeTypeInt();
	}
}

event GameEnding()
{
	super.GameEnding();
}

// NOTE: copied from GameInfo::FindPlayerStart, slightly modified so we always find a player start (as long as NavigationPoints exist in the map) -tsmith 
function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string IncomingName )
{
	local NavigationPoint N, BestStart;

	// allow GameRulesModifiers to override playerstart selection
	if (BaseMutator != None)
	{
		N = BaseMutator.FindPlayerStart(Player, InTeam, IncomingName);
		if (N != None)
		{
			return N;
		}
	}

	// always pick StartSpot at start of match
	if ( ShouldSpawnAtStartSpot(Player) &&
		(PlayerStart(Player.StartSpot) == None || RatePlayerStart(PlayerStart(Player.StartSpot), InTeam, Player) >= 0.0) )
	{
		return Player.StartSpot;
	}

	BestStart = ChoosePlayerStart(Player, InTeam);

	// NOTE: commented out this check for none player. dont know why UE3 has it but we need to disable in situations such as seamless travel maps -tsmith 
	if ( (BestStart == None)/* && (Player == None)*/ )
	{
		// no playerstart found, so pick any NavigationPoint to keep player from failing to enter game
		//`log("Warning - PATHS NOT DEFINED or NO PLAYERSTART with positive rating"); RAM - this is not an error for X-Com
		ForEach AllActors( class 'NavigationPoint', N )
		{
			BestStart = N;
			break;
		}
	}
	return BestStart;
}


//
// Accept or reject a player on the server.
// Fails login if you set the Error to a non-empty string.
// NOTE: UniqueId should not be trusted at this stage, it requires authentication
//
event PreLogin(string Options, string Address, const UniqueNetId UniqueId, bool bSupportsAuth, out string ErrorMessage)
{
	`log(`location @ `ShowVar(m_bSeamlessTraveled) @ class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueID) @`ShowVar(Options) @ `ShowVar(Address) @ `ShowVar(bSupportsAuth), true, 'XCom_Net');
	super.PreLogin(Options, Address, UniqueId, bSupportsAuth, ErrorMessage);	
}

//-----------------------------------------------------------
// Log a player in.
// Fails login if you set the Error string.
// PreLogin is called before Login, but significant game time may pass before
// Login is called, especially if content is downloaded.
//-----------------------------------------------------------
event PlayerController Login
(
	string Portal,
	string Options,
	const UniqueNetID UniqueID, 
	out string ErrorMessage
)
{
	local NavigationPoint StartSpot;
	local string          InName, InCharacter/*, InAdminName*/, InPassword;
	local byte            InTeam;
	local bool bSpectator, bAdmin, bPerfTesting;
	local rotator SpawnRotation;
	local vector SpawnLocation;
	local PlayerController PlayerController;
	bAdmin = false;

	`log(`location @ `ShowVar(m_bSeamlessTraveled) @ class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueID) @ `ShowVar(Portal) @ `ShowVar(Options), true, 'XCom_Net');
	
	// Kick the player if they joined during the handshake process
	if (bUsingArbitration && bHasArbitratedHandshakeBegun)
	{
		ErrorMessage = GameMessageClass.Default.MaxedOutMessage;
		return None;
	}

	if ( BaseMutator != None )
		BaseMutator.ModifyLogin(Portal, Options);

	bPerfTesting = ( ParseOption( Options, "AutomatedPerfTesting" ) ~= "1" );
	bSpectator = bPerfTesting || ( ParseOption( Options, "SpectatorOnly" ) ~= "1" );

	// Get URL options.
	InName     = Left(ParseOption ( Options, "Name"), 255);
	InTeam     = GetIntOption( Options, "Team", 255 ); // default to "no team"
	//InAdminName= ParseOption ( Options, "AdminName");
	InPassword = ParseOption ( Options, "Password" );
	//InChecksum = ParseOption ( Options, "Checksum" );

	if ( AccessControl != None )
	{
		bAdmin = AccessControl.ParseAdminOptions(Options);
	}

	// Make sure there is capacity except for admins. (This might have changed since the PreLogin call).
	if ( !bAdmin && AtCapacity(bSpectator) )
	{
		ErrorMessage = GameMessageClass.Default.MaxedOutMessage;
		return None;
	}

	// If admin, force spectate mode if the server already full of reg. players
	if ( bAdmin && AtCapacity(false) )
	{
		bSpectator = true;
	}

	// Pick a team (if need teams)
	InTeam = PickTeam(InTeam,None);

	// Find a start spot.
	StartSpot = FindPlayerStart( None, InTeam, Portal );

	if( StartSpot == None )
	{		
		PlayerController = SpawnPlayerController(SpawnLocation, SpawnRotation);
	}
	else
	{
		SpawnRotation.Yaw = StartSpot.Rotation.Yaw;
		PlayerController = SpawnPlayerController(StartSpot.Location, SpawnRotation);
	}

	// Handle spawn failure.
	if( PlayerController == none )
	{
		`log("Couldn't spawn player controller of class "$PlayerControllerClass);
		ErrorMessage = GameMessageClass.Default.FailedSpawnMessage;
		return None;
	}

	// tmp network fix
	/*  This SHOULD no longer be necessary
	if ( XComTacticalGRI(WorldInfo.GRI).xPlayerController == none )
	{
		XComTacticalGRI(WorldInfo.GRI).xPlayerController = XComTacticalController(PlayerController);

		// Assign the CursorController
		CursorController = XComTacticalGRI(WorldInfo.GRI).xPlayerController;
	}
	*/

	PlayerController.StartSpot = StartSpot;

	// Set the player's ID.
	PlayerController.PlayerReplicationInfo.PlayerID = CurrentID++;

	// Init player's name
	if( InName=="" )
	{
		InName=DefaultPlayerName$PlayerController.PlayerReplicationInfo.PlayerID;
	}

	ChangeName( PlayerController, InName, false );

	InCharacter = ParseOption(Options, "Character");
	PlayerController.SetCharacter(InCharacter);

	if ( bSpectator || PlayerController.PlayerReplicationInfo.bOnlySpectator || !ChangeTeam(PlayerController, InTeam, false) )
	{
		PlayerController.GotoState('Spectating');
		PlayerController.PlayerReplicationInfo.bOnlySpectator = true;
		PlayerController.PlayerReplicationInfo.bIsSpectator = true;
		PlayerController.PlayerReplicationInfo.bOutOfLives = true;
		return PlayerController;
	}

	// perform auto-login if admin password/name was passed on the url
	if ( AccessControl != None && AccessControl.AdminLogin(PlayerController, InPassword) )
	{
		AccessControl.AdminEntered(PlayerController);
	}

	// if delayed start, don't give a pawn to the player yet
	// Normal for multiplayer games
	if ( bDelayedStart )
	{
		PlayerController.GotoState('PlayerWaiting');
		return PlayerController;
	}

	return PlayerController;
	
}

//
// Called after a successful login. This is the first place
// it is safe to call replicated functions on the PlayerController.
//
// this is also the first place where its safe to test for being a local player controller on the server
event PostLogin( PlayerController NewPlayer )
{
	super.PostLogin(NewPlayer);

	if (WorldInfo.IsPlayInEditor())
	{
		SetupPIE();
	}
}

exec function SetupPIE()
{
	local XComLevelVolume TempLevelVolume;
	local int NumLevelVolumes;

	`Log( "XComTacticalGame:SetupPIE - map:" @ WorldInfo.GetMapName() );

	foreach `XWORLDINFO.AllActors(class'XComLevelVolume', TempLevelVolume)
	{
		++NumLevelVolumes;
	}

	if( NumLevelVolumes == 0 )
	{
		`Log( "NO WORLD DATA FOUND!!!!" );
	}
}

function string GetSavedGameDescription()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local X2MissionTemplate MissionTemplate;
	local string Desc, GeoTimeDesc;
	local int GeoHour, GeoMinute;
	local TDateTime GeoTime;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));	
	
	GeoTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	GeoHour = class'X2StrategyGameRulesetDataStructures'.static.GetHour(GeoTime);
	GeoMinute = class'X2StrategyGameRulesetDataStructures'.static.GetMinute(GeoTime);
	`ONLINEEVENTMGR.FormatTimeStamp(GeoTimeDesc, GeoTime.m_iYear, GeoTime.m_iMonth, GeoTime.m_iDay, GeoHour, GeoMinute);

	if( GetLanguage() == "INT" )
	{
		GeoTimeDesc = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(GeoTimeDesc);
	}

	if(BattleData.m_strDesc != "")
	{
		Desc = BattleData.m_strDesc;
		Desc $= "\n" $ BattleData.m_strOpName;
		Desc $= "\n" $ GeoTimeDesc @ BattleData.m_strLocation @ BattleData.m_strTime;
	}		
	else
	{
		if(BattleData.bIsTacticalQuickLaunch)
		{
			MissionTemplate = class'X2MissionTemplateManager'.static.GetMissionTemplateManager().FindMissionTemplate(BattleData.MapData.ActiveMission.MissionName);
			Desc = "Tactical Quick Launch" @ "(" $ MissionTemplate.DisplayName $ ")";
			Desc $= "\n" $ GeoTimeDesc  @ BattleData.MapData.PlotMapName;
		}
		else
		{
			Desc = BattleData.m_strOpName;
			Desc $= "\n" $ GeoTimeDesc @ BattleData.m_strLocation @ BattleData.m_strTime;
		}
	}		
	

	return Desc;
}

function string GetSavedGameCommand()
{
	local string Output;	
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if( BattleData != none )
	{
		if(BattleData.MapData.PlotMapName != "")
		{
			Output = "open"@BattleData.MapData.PlotMapName$"?game=XComGame.XComTacticalGame";
		}
		else
		{
			Output = "open"@WorldInfo.GetMapName()$"?game=XComGame.XComTacticalGame";
		}
	}
	else
	{
		`log("ERROR! Attempting to save a tactical game that does not contain the necessary state objects!");
	}	

	return Output $ "?LoadingSave";
}

function string GetSavedGameMapName()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if( BattleData != none )
	{
		if(BattleData.MapData.ParcelData[0].MapName != "")
		{
			return BattleData.MapData.ParcelData[0].MapName;
		}
		else
		{
			return WorldInfo.GetMapName();
		}
	}	

	return "";
}

// This will be called when going from Tactical -> Strategy, once when heading to the
// transition map, and once again when heading to the destination map
event GetSeamlessTravelActorList(bool bToTransitionMap, out array<Actor> ActorList)
{
	local XComPlayerController PC;
	//local XGSquad Squad;
	//local XGUnit Unit;
	//local int UnitIdx;
	//local XComUnitPawn UnitPawn;
	super.GetSeamlessTravelActorList(bToTransitionMap, ActorList);

	// Find remaining living soldiers, and make them persist so we can show them
	// in the dropship
	if (bToTransitionMap)
	{
		// Get squad, find living members, save their pawns only for the dropship
		//Squad = XGBattle_SP(`BATTLE).GetHumanPlayer().m_kSquad;
		//for (UnitIdx = 0; UnitIdx < Squad.GetNumMembers(); ++UnitIdx)
		//{
		//	Unit = Squad.GetMemberAt(UnitIdx);
		//	if (Unit.IsAliveAndWell())
		//	{
		//		UnitPawn = Unit.GetPawn();
		//		UnitPawn.GotoState('NoTicking');
		//		XComHumanPawn(UnitPawn).GetSeamlessTravelActorList(bToTransitionMap, ActorList);
		//	}
		//}

		PC = XComPlayerController(GetALocalPlayerController());
		ActorList[ActorList.Length] = PC;
		ActorList[ActorList.Length] = PC.Pres;
	}
}

// This will be called when going from Strategy -> Tactical, after the tactical
// map is loaded and ready to go
event PostSeamlessTravel()
{
	`log("XComTacticalGame.PostSeamlessTravel",,'DevStreaming');
	super.PostSeamlessTravel();

	// TODO@jboswell: Kill old pawns?
}

/** handles reinitializing players that remained through a seamless level transition
 * called from C++ for players that finished loading after the server
 * @param C the Controller to handle
 */
// Called on player controllers that are transitioned from Strategy -> Tactical,
// this is called instead of Login()
event HandleSeamlessTravelPlayer(out Controller C)
{
	local NavigationPoint StartSpot;
	local ETeam eOldTeam;
	local bool bOldIsMouseActive;


	// Handle all the transitional logic
	bOldIsMouseActive = XComPlayerController(C).m_bIsMouseActive;
	eOldTeam = C.m_eTeam;
	super.HandleSeamlessTravelPlayer(C);
	XComPlayerController(C).SetIsMouseActive(bOldIsMouseActive);
	C.SetTeamType(eOldTeam);

	// now move the controller/view underground to get a black screen for a moment
	StartSpot = FindPlayerStart(C, C.GetTeamNum());
	if (StartSpot != none)
	{
		if (!C.SetLocation(StartSpot.Location - vect(0,0,1024)))
			`log("XComGameInfo.HandleSeamlessTravelPlayer: Could not move PlayerController to start location");
	}
}

// override in each gameInfo for Project
// specific implementation of each GetItemCard
simulated function TItemCard GetItemCard()
{
	local TItemCard kItemCard;

	kItemCard.m_strName = "TACTICAL PLACEHOLDER";
	`log("GetItemCard in tactical");

	return kItemCard;
}

simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'X2TacticalGameRuleset';
}

simulated event PreBeginPlay()
{
	super.PreBeginPlay();
	SubscribeToOnCleanupWorld();
}

simulated event Destroyed()
{
	super.Destroyed();
	UnsubscribeFromOnCleanupWorld();
}

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	`log(self $ "::" $ GetFuncName() @ `ShowVar(m_bPingingMCP), true, 'XCom_Net');
	if(m_bPingingMCP)
	{
		`XENGINE.MCPManager.OnEventCompleted = none;
	}
	m_bHasWorldCleanedUp = true;
}

private function CheckForDisconnectOnLogout(Controller Exiting)
{
	local XComTacticalController kPC;

	foreach DynamicActors(class'XComTacticalController', kPC)
	{
		if(kPC.IsLocalPlayerController())
		{
			m_kLocalPlayer = kPC;
		}
		else
		{
			m_kOpponentPlayer = kPC;
		}
	}

	`log(self $ "::" $ GetFuncName(), true, 'XCom_Net');
	if(!m_bHasWorldCleanedUp)
	{
		// if local player can't ping MCP then record a disconnect -tsmith 
		if( `XENGINE.MCPManager != none )
		{
			if(`XENGINE.MCPManager.PingMCP(OnPingMCPCompleteFinishCheckForDisconnectOnLogout))
			{
				`log("      started async task PingMCP", true, 'XCom_Net');
				m_bPingingMCP = true;
				m_kPlayerLoggingOut = XComTacticalController(Exiting);
			}
			else
			{
				`warn("      failed to start async task PingMCP");
				FinishCheckForDisconnectOnLogout(false);
			}
		}
		else
		{
			`warn("      MCP manager does not exist");
			FinishCheckForDisconnectOnLogout(false);
		}
	}
	else
	{
		`log(self $ "::" $ GetStateName() $ "::" $ GetFuncName() @ "Can't ping MCP after world has already cleaned up", true, 'XCom_Net');
	}
}


private function OnPingMCPCompleteFinishCheckForDisconnectOnLogout(bool bWasSuccessful, EOnlineEventType EventType)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bWasSuccessful) @ `ShowVar(m_kPlayerLoggingOut) @ `ShowVar(m_kLocalPlayer) @ `ShowVar(m_kOpponentPlayer), true, 'XCom_Net');
	FinishCheckForDisconnectOnLogout(bWasSuccessful);
}

private function FinishCheckForDisconnectOnLogout(bool bOtherPlayerDisconnected)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bOtherPlayerDisconnected) @ `ShowVar(m_kPlayerLoggingOut) @ `ShowVar(m_kLocalPlayer) @ `ShowVar(m_kOpponentPlayer), true, 'XCom_Net');

	m_bPingingMCP = false;
	`XENGINE.MCPManager.OnEventCompleted = none;

	m_kLocalPlayer.UpdateEndOfGamePRIDueToDisconnect(bOtherPlayerDisconnected);
	m_kLocalPlayer.DisplayEndOfGameDialog();
	
	if(bOtherPlayerDisconnected)
	{
		m_kLocalPlayer.StatsWriteWinDueToDisconnect();
	}
	
	super.Logout(m_kPlayerLoggingOut);
	
	EndOnlineGame();
}

function bool CheckForLogoutBeforeGameStartAndDisconnect()
{
	if(`BATTLE == none)
	{
		// something has gone horribly wrong, user probably disconnected while loading. force a disconnect back to main menu.
		`log(self $ "::" $ GetFuncName() $ "::" $ GetStateName() @ "logout occured before the first turn, something has gone wrong with the connection, returning to menus", true, 'XCom_Net');
		if(!m_bDisconnectedBecauseLogoutsBeforeGameStart)
		{
			m_bDisconnectedBecauseLogoutsBeforeGameStart = true;
			`ONLINEEVENTMGR.ReturnToMPMainMenu(QuitReason_OpponentDisconnected);
		}
		return true;
	}
	else
	{
		return false;
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
function int CountHumanPlayers()
{
	local XComTacticalController P;
	local int playerCount;
	playerCount = 0;

	foreach WorldInfo.AllControllers( class'XComTacticalController', P )
	{
		playerCount++;
	}
	return playerCount;
}

/**
 * Tells the online system to end the game and tells all clients to do the same
 */
function EndOnlineGame()
{
	super.EndOnlineGame();
}
function class<XComOnlineGameSettings> GetOnlineGameSettingsClass()
{
	local XComOnlineGameSettings kGameSettings;

	kGameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	// in certain debug runs of the game we will not get a game settings class so just emit a warning instead of a crash -tsmith 
	if(kGameSettings != none)
	{
		if(kGameSettings.bUsesArbitration)
		{
			return class'XComOnlineGameSettingsDeathmatchRanked';
		}
		else
		{
			return class'XComOnlineGameSettingsDeathmatchUnranked';
		}
	}
	else
	{		
		return none;
	}
}

function class<OnlineStatsWrite> GetOnlineStatsWriteClass(string WrtiteType)
{
	local XComOnlineGameSettings kGameSettings;
	kGameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	// in certain debug runs of the game we will not get a game settings class so just emit a warning instead of a crash -tsmith 
	if(kGameSettings != none)
	{
		return kGameSettings.GetOnlineStatsWriteClass(WrtiteType);
	}
	else
	{
		return none;
	}
}

function class<OnlineStatsRead> GetOnlineStatsReadClass(string ReadType)
{
	local XComOnlineGameSettings kGameSettings;
	kGameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	// in certain debug runs of the game we will not get a game settings class so just emit a warning instead of a crash -tsmith 
	if(kGameSettings != none)
	{
		return kGameSettings.GetOnlineStatsReadClass(ReadType);
	}
	else
	{
		return none;
	}
}

//-----------------------------------------------------------
//-----------------------------------------------------------
defaultproperties
{
	HUDType=class'XComGame.XComTacticalHUD'
	GameReplicationInfoClass = class 'XComTacticalGRI'
	bDebugCombatRequested = false
	m_bLoadingFromShell=true
	m_bDisableLoadingScreen=false
	strSaveFile=""
	bUseSeamlessTravel=true
	AutoTestManagerClass = class'X2LevelGenerationAutoTestManager'
}
