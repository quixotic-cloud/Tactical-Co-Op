//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPLobbyGame.uc
//  AUTHOR:  Todd Smith  --  8/7/2015
//  PURPOSE: Lobby game type so players can connect and finalize game options.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPLobbyGame extends XComShell;

var protected int                           m_iNumPlayers;
var protected ETeam                         m_eNextPlayerTeam;
var privatewrite bool                       m_bGameEnding;
var privatewrite bool                       m_bGameLaunching;

var delegate<OnUpdateOnlineGameComplete>    m_dOnUpdateOnlineGameComplete;

/**
 * Delegate fired when a update request has completed
 *
 * @param SessionName the name of the session this callback is for
 * @param bWasSuccessful true if the async action completed without error, false if there was an error
 */
delegate OnUpdateOnlineGameComplete(name SessionName,bool bWasSuccessful);

/** handles all player initialization that is shared between the travel methods
 * (i.e. called from both PostLogin() and HandleSeamlessTravelPlayer())
 */
function GenericPlayerInitialization(Controller C)
{
	super.GenericPlayerInitialization(C);

}

/* Initialize the game.
 The GameInfo's InitGame() function is called before any other scripts (including
 PreBeginPlay() ), and is used by the GameInfo to initialize parameters and spawn
 its helper classes.
 Warning: this is called before actors' PreBeginPlay.
*/
event InitGame( string Options, out string ErrorMessage )
{
	class'Engine'.static.GetEngine().SetRandomSeeds(class'Engine'.static.GetEngine().GetARandomSeed());
	super.InitGame(Options, ErrorMessage);
}

event PreBeginPlay()
{
	super.PreBeginPlay();
}

simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
}

function InitGameReplicationInfo()
{
	// @TODO tsmith: we can get rid of all the GRI, PRI code
	local XComOnlineGameSettings kGameSettings;
	local XComMPLobbyGRI kGRI;

	super.InitGameReplicationInfo();

	kGameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));
	assert(kGameSettings != none);

	kGRI = XComMPLobbyGRI(WorldInfo.GRI);
	kGRI.m_eMPGameType = kGameSettings.GetGameType();
	kGRI.m_eMPNetworkType = kGameSettings.GetNetworkType();
	kGRI.m_iMPMaxSquadCost = kGameSettings.GetMaxSquadCost();
	kGRI.m_iMPTurnTimeSeconds = kGameSettings.GetTurnTimeSeconds();
	kGRI.m_iMPMapPlotType = kGameSettings.GetMapPlotTypeInt();
	kGRI.m_iMPMapBiomeType = kGameSettings.GetMapBiomeTypeInt();
	kGRI.m_bMPIsRanked = kGameSettings.GetIsRanked();
	kGRI.m_bMPAutomatch = kGameSettings.GetIsAutomatch();
}

//
// Accept or reject a player on the server.
// Fails login if you set the Error to a non-empty string.
// NOTE: UniqueId should not be trusted at this stage, it requires authentication
//
event PreLogin(string Options, string Address, const UniqueNetId UniqueId, bool bSupportsAuth, out string ErrorMessage)
{
	`log(`location @ class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueID) @`ShowVar(Options) @ `ShowVar(Address) @ `ShowVar(bSupportsAuth) @ `ShowVar(m_bGameLaunching), true, 'XCom_Net');

	if(m_bGameLaunching)
	{
		ErrorMessage = "Game is launching, no more logins";
		return;
	}
	else
	{
		super.PreLogin(Options, Address, UniqueId, bSupportsAuth, ErrorMessage);
	}
}

//
// Log a player in.
// Fails login if you set the Error string.
// PreLogin is called before Login, but significant game time may pass before
// Login is called, especially if content is downloaded.
//
event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local PlayerController kPC;

	`log(`location @ class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueID) @ `ShowVar(Portal) @ `ShowVar(Options) @ `ShowVar(m_bGameLaunching), true, 'XCom_Net');

	if(m_bGameLaunching)
	{
		ErrorMessage = "Game is launching, no more logins";
		return none;
	}

	if(m_iNumPlayers == 0)
	{
		// randomly set the team as this dictates which spawn points to use, otherwise host would always be eTeam_One and use those spawn points. -tsmith 
		m_iNumPlayers++;
		m_eNextPlayerTeam = (Rand(2) == 1) ? eTeam_One : eTeam_Two;
		m_dOnUpdateOnlineGameComplete = OnUpdateOnlineGameSettingsComplete_ConnectionCountsForHostPlayerLogin;
	}
	else if(m_iNumPlayers == 1)
	{
		m_iNumPlayers++;
		m_eNextPlayerTeam = (m_eNextPlayerTeam == eTeam_One) ? eTeam_Two : eTeam_One;
		m_dOnUpdateOnlineGameComplete = OnUpdateOnlineGameSettingsComplete_ConnectionCountsForClientPlayerLogin;
	}
	else
	{
		`warn("Max number of players are in the game already. Denying login");
		m_eNextPlayerTeam = eTeam_None;
		ErrorMessage = "OnlineEventMgr.ESystemMessageType.SystemMessage_GameFull";
		`log(self $ "::" $ GetFuncName() @ "Player=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueID) @ `ShowVar(m_iNumPlayers) @ `ShowVar(NumPlayers), true, 'XCom_Net');
		return none;
	}

	`log(self $ "::" $ GetFuncName() @ "BEFORE super.Login: Player=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueID) @ `ShowVar(m_iNumPlayers) @ `ShowVar(NumPlayers), true, 'XCom_Net');
	kPC = super.Login(Portal, Options, UniqueID, ErrorMessage);
	`log(self $ "::" $ GetFuncName() @ "AFTER super.Login:" @ `ShowVar(kPC) @ "Player=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueID) @ `ShowVar(m_iNumPlayers) @ `ShowVar(NumPlayers), true, 'XCom_Net');

	if(kPC == none)
	{
		if(m_iNumPlayers > 0)
		{
			m_iNumPlayers--;
		}
	}

	return kPC;
}

//
// Player exits.
//
function Logout( Controller Exiting )
{
	super.Logout(Exiting);

	`log(`location @ `ShowVar(m_bGameLaunching) @ `ShowVar(Exiting) @ `ShowVar(Exiting.PlayerReplicationInfo.PlayerName), true, 'XCom_Net');

	if(m_bGameLaunching)
		return;

	m_iNumPlayers--;
	if(Exiting.m_eTeam == eTeam_One)
	{
		m_eNextPlayerTeam = eTeam_Two;
	}
	else
	{
		m_eNextPlayerTeam = eTeam_One;
	}
	if(!Exiting.IsLocalPlayerController())
	{
		m_dOnUpdateOnlineGameComplete = OnUpdateOnlineGameSettingsComplete_ConnectionCountsForClientPlayerLogout;
		UpdateGameSettingsCounts();
	}

	`log(self $ "::" $ GetFuncName() @ "Player=" $ PlayerController(Exiting).PlayerReplicationInfo.PlayerName @ `ShowVar(Exiting.m_eTeam) @ `ShowVar(m_iNumPlayers) @ `ShowVar(NumPlayers), true, 'XCom_Net');
}

/* ProcessServerTravel()
 Optional handling of ServerTravel for network games.
*/
function ProcessServerTravel(string URL, optional bool bAbsolute)
{
	super.ProcessServerTravel(URL, bAbsolute);
}

/**
 * Updates the online subsystem's information for player counts 
 */
function UpdateGameSettingsCounts()
{
	local OnlineGameSettings GameSettings;

	if(m_bGameEnding || m_bGameLaunching)
		return;

	if (GameInterface != None)
	{
		GameSettings = GameInterface.GetGameSettings(PlayerReplicationInfoClass.default.SessionName);
		if (GameSettings != None)
		{
			// Update the number of open slots available
			GameSettings.NumOpenPublicConnections = GameSettings.NumPublicConnections - GetNumPlayers();
			if (GameSettings.NumOpenPublicConnections < 0)
			{
				GameSettings.NumOpenPublicConnections = 0;
			}
			GameSettings.NumOpenPrivateConnections = GameSettings.NumPrivateConnections - GetNumPlayers();
			if (GameSettings.NumOpenPrivateConnections < 0)
			{
				GameSettings.NumOpenPrivateConnections = 0;
			}

			if(GameSettings.NumOpenPublicConnections == 0 && GameSettings.NumOpenPrivateConnections == 0)
			{
				`log(`location @ "No more slots available, stopping game advertising", true, 'XCom_Online');
				GameSettings.bShouldAdvertise = false;
			}
			else
			{
				`log(`location @ "slots opened up, advertising game", true, 'XCom_Online');
				GameSettings.bShouldAdvertise = true;
			}

			if(m_dOnUpdateOnlineGameComplete != none)
			{
				GameInterface.AddUpdateOnlineGameCompleteDelegate(m_dOnUpdateOnlineGameComplete);
				GameInterface.UpdateOnlineGame('Game', GameSettings, true);
			}
		}
	}
}

function OnUpdateOnlineGameSettingsComplete_ConnectionCountsForHostPlayerLogin(name SessionName, bool bWasSuccessful)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful) @ XComOnlineGameSettings(GameInterface.GetGameSettings('Game')).ToString(), true, 'XCom_Online');
	GameInterface.ClearUpdateOnlineGameCompleteDelegate(m_dOnUpdateOnlineGameComplete);	
	m_dOnUpdateOnlineGameComplete = none;
	if(!bWasSuccessful)
	{
		`log(self $ "::" $ GetFuncName() @ "failed to update connection counts during host player login", true, 'XCom_Online');
	}
}

function OnUpdateOnlineGameSettingsComplete_ConnectionCountsForClientPlayerLogin(name SessionName, bool bWasSuccessful)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful) @ XComOnlineGameSettings(GameInterface.GetGameSettings('Game')).ToString(), true, 'XCom_Online');
	GameInterface.ClearUpdateOnlineGameCompleteDelegate(m_dOnUpdateOnlineGameComplete);	
	m_dOnUpdateOnlineGameComplete = none;
	if(!bWasSuccessful)
	{
		`log(self $ "::" $ GetFuncName() @ "failed to update connection counts during client player login", true, 'XCom_Online');
	}
}

function OnUpdateOnlineGameSettingsComplete_ConnectionCountsForClientPlayerLogout(name SessionName, bool bWasSuccessful)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful) @ XComOnlineGameSettings(GameInterface.GetGameSettings('Game')).ToString(), true, 'XCom_Online');
	GameInterface.ClearUpdateOnlineGameCompleteDelegate(m_dOnUpdateOnlineGameComplete);	
	m_dOnUpdateOnlineGameComplete = none;
	if(!bWasSuccessful)
	{
		`log(self $ "::" $ GetFuncName() @ "failed to update connection counts during client player logout", true, 'XCom_Online');
	}
}

/** spawns a PlayerController at the specified location; split out from Login()/HandleSeamlessTravelPlayer() for easier overriding */
function PlayerController SpawnPlayerController(vector SpawnLocation, rotator SpawnRotation)
{
	local X2MPLobbyController kLobbyPC;

	`log(self $ "::" $ GetFuncName() @ `ShowVar(m_eNextPlayerTeam), true, 'XCom_Net');
	kLobbyPC = X2MPLobbyController(Spawn(PlayerControllerClass,,, SpawnLocation, SpawnRotation,,, m_eNextPlayerTeam));

	return kLobbyPC;
}


// Called when game shutsdown.  
event GameEnding()
{
	m_bGameEnding = true;
	GameInterface.ClearUpdateOnlineGameCompleteDelegate(m_dOnUpdateOnlineGameComplete);
	m_dOnUpdateOnlineGameComplete = none;

	super.GameEnding();
}

function LaunchGame()
{
	`assert(false);
}

function int GetNumPlayers()
{
	return m_iNumPlayers;
}

function SetNumPlayers(int iNumPlayers)
{
	ScriptTrace();
	m_iNumPlayers = iNumPlayers;
}

simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'X2StrategyGameRuleset';
}

simulated event Destroyed()
{
	super.Destroyed();
}

defaultproperties
{
	bUseSeamlessTravel=true
	m_iNumPlayers=0
	m_eNextPlayerTeam=eTeam_None
	PlayerControllerClass=class'XComGame.X2MPLobbyController'
	// we dont use the PRI/GRI classes anymore -tsmith
	PlayerReplicationInfoClass=class'XComGame.XComMPLobbyPRI'
	GameReplicationInfoClass=class'XComGame.XComMPLobbyGRI'
}
