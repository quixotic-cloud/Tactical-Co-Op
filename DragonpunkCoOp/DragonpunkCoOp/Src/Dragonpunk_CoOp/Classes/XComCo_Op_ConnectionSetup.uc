// This is an Unreal Script

class XComCo_Op_ConnectionSetup extends Actor;

var string m_strMatchOptions;
var name m_nMatchingSessionName;
var X2MPShellManager m_kMPShellManager;
var XComOnlineGameSettings ServerGameSettings;
var bool bWaitingForHistory,bFriendJoined,bCanStartMatch,bHistoryLoaded,AllPlayersLaunched,HostJoinedAlready,CalledForHistory,ForceSuccess;
var bool GoForNetworkTiming;
var float AccumulatedDT;

event Tick( float DeltaTime )
{
	super.Tick(DeltaTime);
	/*`log("TICKING!");
	if(GoForNetworkTiming)
		AccumulatedDT+=DeltaTime;

	if(GoForNetworkTiming&& (AccumulatedDT>1) )
	{
		GoForNetworkTiming=false;
		AccumulatedDT=0;
		`log("FIRING INSIDE TICK!");
		ForceConnectFunction();
	}*/
}
function InitShellManager()
{
	if(m_kMPShellManager==none)
		m_kMPShellManager=Spawn(class'X2MPShellManager', self);
}

function ChangeInviteAcceptedDelegates()
{	
	local OnlineGameInterfaceXCom GameInterface;
	local XComGameStateNetworkManager NetworkMgr;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.ClearGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,OnGameInviteAccepted);	
	GameInterface.AddJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.AddLobbyInviteDelegate(OnLobbyInvite);
	GameInterface.AddLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.AddLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);

	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.AddReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.AddReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.AddReceiveGameStateDelegate(ReceiveGameState);
	NetworkMgr.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	NetworkMgr.AddReceiveRemoteCommandDelegate(OnRemoteCommand);
}

function RevertInviteAcceptedDelegates()
{	
	local OnlineGameInterfaceXCom GameInterface;
	local XComGameStateNetworkManager NetworkMgr;
	
	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.ClearGameInviteAcceptedDelegate(0,OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.ClearJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.ClearLobbyInviteDelegate(OnLobbyInvite);
	GameInterface.ClearLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);

	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.ClearReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.ClearReceiveGameStateDelegate(ReceiveGameState);
	NetworkMgr.ClearReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	NetworkMgr.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
}

function CreateOnlineGame()
{
	local OnlineSubsystem OnlineSub;
	
	InitShellManager();
	OnlineSub=class'GameEngine'.static.GetOnlineSubsystem();
	m_kMPShellManager.OnlineGame_SetAutomatch(false);
	OSSCreateGameSettings(false);
	OnlineSub.GameInterface.AddCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);
	// Now kick off the async publish
	if ( !OnlineSub.GameInterface.CreateOnlineGame(LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId,'Game',ServerGameSettings) )
	{
		OnlineSub.GameInterface.ClearCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);
	}	
}

function OnCreateOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);

	if(bWasSuccessful)
	{
		//block all input, by this point we are committed to the travel
		XComShellInput(XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).PlayerInput).PushState('BlockingInput');
		m_nMatchingSessionName = SessionName;
		//StartNetworkGame(m_nMatchingSessionName);
		// Set timer to allow dialog data to be presented
		SetTimer(1.0, false, 'OnCreateCoOpGameTimerComplete');
		`log("Successfully created online game: Session=" $ SessionName $ ", Server=" @ "TODO: implement, i used to come from the GameReplicationInfo: WorldInfo.GRI.ServerName", true, 'Team Dragonpunk Co Op');

}
	else
	{
		`log("Failed to create online game: Session=" $ SessionName, true, 'Team Dragonpunk Co Op');
	}	
}

function OnCreateCoOpGameTimerComplete()
{
	//clear any repeat timers to prevent the multiplayer match from exiting prematurely during load
	`PRESBASE.ClearInput();
	StartNetworkGame(m_nMatchingSessionName);
	`log("Starting Network Game Ended", true, 'Team Dragonpunk Co Op');
	//set the input state back to normal
	XComShellInput(XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).PlayerInput).PopState();
	OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).CreateLobby(2, XLV_Public);	
	SendRemoteCommand("HostJoined");
}

function OnJoinLobbyComplete(bool bWasSuccessful, const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, UniqueNetId LobbyUID, string Error)
{
	local string LobbyUIDString;
	LobbyUIDString = class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( LobbyUID );
	`log(`location @ `ShowVar(bWasSuccessful) @ `ShowVar(LobbyIndex) @ `ShowVar(LobbyUIDString) @ `ShowVar(Error),,'XCom_Online');

}
function OnLobbyJoinGame(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, UniqueNetId ServerId, string ServerIP)
{
	local string ServerIdString;
	ServerIdString = class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( ServerId );
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(ServerIdString) @ `ShowVar(ServerIP),,'XCom_Online');
}

function OnLobbyMemberStatusUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, int InstigatorIndex, string Status)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(InstigatorIndex) @ `ShowVar(Status),,'XCom_Online');
	if(Status~="Joined" &&(LobbyList[LobbyIndex].Members.Length >= 1 || `XCOMNETMANAGER.HasServerConnection()  ))
	{
		`log(`location @ `ShowVar(LobbyIndex) @"LobbyList[LobbyIndex].Members"@LobbyList[LobbyIndex].Members.Length,,'Team Dragonpunk Co Op');
	}
}

function OnLobbyInvite(UniqueNetId LobbyId, UniqueNetId FriendId, bool bAccepted)
{
	`log("bAccepted:"@bAccepted ,true,'Team Dragonpunk Co Op');
	if(bAccepted)
	{
		//OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).JoinLobby(LobbyId);
	}	
}

function OSSCreateGameSettings(bool bAutomatch)
{
	local XComOnlineGameSettings kGameSettings;
	local XComOnlineGameSettingsDeathmatchUnranked kUnrankedDeathmatchSettings;

	InitShellManager();
	// probably don't need skill rating for unranked but we'll clear it anyway -tsmith 
	kUnrankedDeathmatchSettings = new class'XComOnlineGameSettingsDeathmatchUnranked';
	kGameSettings = kUnrankedDeathmatchSettings;
	kGameSettings.SetIsRanked(false);
	kGameSettings.SetNetworkType(eMPNetworkType_Public);
	kGameSettings.SetGameType(eMPGameType_Deathmatch);
	kGameSettings.SetTurnTimeSeconds(3600); 
	kGameSettings.SetMaxSquadCost(2147483648); 
	kGameSettings.SetMapPlotTypeInt(m_kMPShellManager.OnlineGame_GetMapPlotInt());
	kGameSettings.SetMapBiomeTypeInt(m_kMPShellManager.OnlineGame_GetMapBiomeInt());
	kGameSettings.NumPublicConnections = 2;
	kGameSettings.NumPrivateConnections = 0;
	kGameSettings.SetMPDataINIVersion(0);
	kGameSettings.SetByteCodeHash(class'Helpers'.static.NetGetVerifyPackageHashes());
	kGameSettings.SetIsAutomatch(false);
	kGameSettings.SetInstalledDLCHash(class'Helpers'.static.NetGetInstalledMPFriendlyDLCHash());
	kGameSettings.SetInstalledModsHash(class'Helpers'.static.NetGetInstalledModsHash());
	kGameSettings.SetINIHash(class'Helpers'.static.NetGetMPINIHash());
	kGameSettings.SetIsDevConsoleEnabled(class'Helpers'.static.IsDevConsoleEnabled());
	kGameSettings.bAllowInvites=true;
	ServerGameSettings=kGameSettings;
	
}

function bool StartNetworkGame(name SessionName, optional string ResolvedURL="")
{
	local URL OnlineURL;
	local string sError, ServerURL, ServerPort;
	local int FindIndex;
	local OnlineGameSettings kGameSettings;
	local XComGameStateNetworkManager NetManager;
	local bool bSuccess;
	local float TimeForTimer;
	local UIPanel_TickActor TickA;
	TimeForTimer=1.0;
	bSuccess = true;
	kGameSettings = class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings(SessionName);

	OnlineURL.Map = "XComShell_Multiplayer";
	OnlineURL.Op.AddItem("Game=XComGame.X2MPLobbyGame");

	m_nMatchingSessionName = SessionName;
	m_strMatchOptions = BuildURL(OnlineURL);

	if (!kGameSettings.bIsLanMatch)
	{
		OnlineURL.Op.AddItem("steamsockets");
	}
	NetManager = `XCOMNETMANAGER;
	ChangeInviteAcceptedDelegates();
	if (ResolvedURL == "")
	{
		`log(`location @ "Creating Network Server to host the Online Game.",,'Team Dragonpunk Co Op');
		NetManager.CreateServer(OnlineURL, sError);
		if (sError == "")
		{
				XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientTravel(m_strMatchOptions, TRAVEL_Absolute);
		}
		else
		{
			`warn(`location @ "Unable to Create the Online Game!" @ `ShowVar(SessionName) @ `ShowVar(ResolvedURL) @ `ShowVar(sError),,'Team Dragonpunk Co Op');
			bSuccess = false;
		}
	}
	else
	{
		FindIndex = InStr(ResolvedURL, ":");
		if (FindIndex != -1)
		{
			ServerURL = Left(ResolvedURL, FindIndex);
			ServerPort = Right(ResolvedURL, Len(ResolvedURL) - (FindIndex+1));
		}
		else
		{
			ServerURL = ResolvedURL;
			ServerPort = "0";
		}
		FindIndex = InStr(ServerURL, "?");
		if(FindIndex != -1)
		{
			ServerURL = Left(ServerURL, FindIndex); // Remove everything after the first '?', which are additional URL parameters.
		}
		OnlineURL.Host = ServerURL;
		OnlineURL.Port = int(ServerPort);

		`log(`location @ "Creating Network Client to join the Online Game at '"$ServerURL$"' on port '"$ServerPort$"'.",,'Team Dragonpunk Co Op');
		NetManager.AddPlayerJoinedDelegate(OnPlayerJoined); // Wait until connected fully to the server before loading the map.
		NetManager.CreateClient(OnlineURL, sError);
		if (sError != "")
		{
			NetManager.ClearPlayerJoinedDelegate(OnPlayerJoined);
			`warn(`location @ "Unable to Create the Online Game!" @ `ShowVar(SessionName) @ `ShowVar(ResolvedURL) @ `ShowVar(sError),,'Team Dragonpunk Co Op');
			`log(`location @ "Unable to Create the Online Game!" @ `ShowVar(SessionName) @ `ShowVar(ResolvedURL) @ `ShowVar(sError),,'Team Dragonpunk Co Op');
			bSuccess = false;
		}
		else
		{
			`log(`location @"Trying to connect to server BEFORE TIMER TimeForTimer:" @TimeForTimer,,'Team Dragonpunk Co Op');
			//GoForNetworkTiming=true;
			TickA=Spawn(class'UIPanel_TickActor',`SCREENSTACK.GetCurrentScreen());
			TickA.SetupTick(5);
			//SetTimer(TimeForTimer,false,'ForceConnectFunction');
		}
	}
	return bSuccess;
}


function ForceConnectFunction()
{
	`log(`location @"Trying to connect to server",,'Team Dragonpunk Co Op');
	ForceSuccess=`XCOMNETMANAGER.ForceConnectionAttempt();
	`log(`location @"ForceSuccess"@ForceSuccess,,'Team Dragonpunk Co Op');
}

function string BuildURL(const out URL InURL)
{
	local string strURL, strOp;
	strURL = InURL.Map;
	foreach InUrl.Op(strOp)
	{
		strURL $= "?" $ strOp;
	}
	return strURL;
}

function OnPlayerJoined(string RequestURL, string Address, const UniqueNetId UniqueId, bool bSupportsAuth)
{
	local XComGameStateNetworkManager NetManager;
	NetManager = `XCOMNETMANAGER;
	NetManager.ClearPlayerJoinedDelegate(OnPlayerJoined);
	XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientTravel(m_strMatchOptions, TRAVEL_Absolute);
	`log("OnPlayerJoined",,'Team Dragonpunk Co Op');
	
}
function OnGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	local OnlineSubsystem OnlineSub;
	local bool bIsMoviePlaying;
	
	`log("Dragonpunk test test test NOT IN XComOnlineEventMgr",true,'Team Dragonpunk Co Op');
	OnlineSub=class'GameEngine'.static.GetOnlineSubsystem();

	if(XComOnlineGameSettings(InviteResult.GameSettings).GetMaxSquadCost()<2147483647)
		`ONLINEEVENTMGR.OnGameInviteAccepted(InviteResult,bWasSuccessful);
	else
	{

		if (!bWasSuccessful)
		{
			if (class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.GetLoginStatus(`ONLINEEVENTMGR.LocalUserIndex) != LS_LoggedIn)
			{
				if (class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3))
				{
					class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.AddLoginUICompleteDelegate(`ONLINEEVENTMGR.OnLoginUIComplete);
					class'GameEngine'.static.GetOnlineSubsystem().PlayerInterface.ShowLoginUI(true); // Show Online Only
				}
				else
				{
					`ONLINEEVENTMGR.InviteFailed(SystemMessage_LostConnection);
					`log("InviteFailed(SystemMessage_LostConnection)",true,'Team Dragonpunk Co Op');

				}
			}
			else
			{
				`ONLINEEVENTMGR.InviteFailed(SystemMessage_BootInviteFailed);
				`log("InviteFailed(SystemMessage_BootInviteFailed)",true,'Team Dragonpunk Co Op');
			}
			return;
		}

		if (InviteResult.GameSettings == none)
		{
			// XCOM_EW: BUG 5321: [PCR] [360Only] Client receives the incorrect message 'Game Full' and 'you haven't selected a storage device' when accepting a game invite which has been dismissed.
			// BUG 20260: [ONLINE] - Users will soft crash when accepting an invite to a full lobby.
			`ONLINEEVENTMGR.InviteFailed(SystemMessage_InviteSystemError, !`ONLINEEVENTMGR.IsCurrentlyTriggeringBootInvite()); // Travel to the MP Menu only if the invite was made while in-game.
			return;
		}

		if (CheckInviteGameVersionMismatch(XComOnlineGameSettings(InviteResult.GameSettings)))
		{
			`ONLINEEVENTMGR.InviteFailed(SystemMessage_VersionMismatch, true);
			`log("InviteFailed(SystemMessage_VersionMismatch)",true,'Team Dragonpunk Co Op');
			return;
		}


		// Mark that we accepted an invite. and active game is now marked failed
		`ONLINEEVENTMGR.SetShuttleToMPInviteLoadout(true);
		`ONLINEEVENTMGR.bAcceptedInviteDuringGameplay = true;
		class'XComOnlineEventMgr_Co_Op_Override'.static.AddItemToAcceptedInvites(InviteResult);

		// If on the boot-train, ignore the rest of the checks and reprocess once at the next valid time.
		if (bWasSuccessful && !`ONLINEEVENTMGR.bHasProfileSettings)
		{
			`log(`location @ " -----> Shutting down the playing movie and returning to the MP Main Menu, then accepting the invite again.",,'Team Dragonpunk Co Op');
			return;
		}

		bIsMoviePlaying = `XENGINE.IsAnyMoviePlaying();
		if (bIsMoviePlaying || `ONLINEEVENTMGR.IsPlayerReadyForInviteTrigger() )
		{
			if (bIsMoviePlaying)
			{
				// By-pass movie and continue accepting the invite.
				`XENGINE.StopCurrentMovie();
			}
			if(!`SCREENSTACK.IsCurrentScreen('UISquadSelect'))
			{
				//SquadSelectScreen=(`SCREENSTACK.Screens[0].Spawn(Class'UISquadSelect',none));
				//`SCREENSTACK.Push(SquadSelectScreen);
				`log("Pushing SquadSelectUI to screen stack",true,'Team Dragonpunk Co Op');
			}
			else
			{
				`log("Already in Squad Select UI",true,'Team Dragonpunk Co Op');
			}
			//class'GameEngine'.static.GetOnlineSubsystem().GameInterface.AddJoinOnlineGameCompleteDelegate(OnInviteJoinOnlineGameComplete); 
			OnlineSub.GameInterface.AddJoinOnlineGameCompleteDelegate(OnInviteJoinOnlineGameComplete);
			OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).AcceptGameInvite( LocalPlayer( class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId,'Game');
			OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).JoinOnlineGame( LocalPlayer(  class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId, 'Game',InviteResult );

		}
		else
		{
			`log(`location @ "Waiting for whatever to finish and transition to the UISquadSelect screen.",true,'Team Dragonpunk Co Op');
		}
	}
}
function OnInviteJoinOnlineGameComplete(name SessionName, bool bWasSuccessful)
{
	local OnlineSubsystem OnlineSub;

	OnlineSub=class'GameEngine'.static.GetOnlineSubsystem();
	OnlineSub.GameInterface.ClearJoinOnlineGameCompleteDelegate(OnInviteJoinOnlineGameComplete);
	OnInviteJoinComplete(SessionName, bWasSuccessful);
	/*if( `XCOMNETMANAGER.HasClientConnection() )
	{
		`log(`location @ "Sending 'Request History' command",,'Team Dragonpunk Co Op');
		SendRemoteCommand("RequestHistory");
		SendRemoteCommand("ClientJoined");
	}
	else if ( `XCOMNETMANAGER.HasServerConnection() )
	{
		bCanStartMatch = true;
		//PushState('StartingCoOp');
		`log(`location @ "Sending 'Host Joined' command",,'Team Dragonpunk Co Op');
		bHistoryLoaded = true;
		SendRemoteCommand("HostJoined");
	}*/
}

function string ModifyClientURL(string URL)
{
	return URL;
}

function SetLobbyServer(UniqueNetId LobbyIdHexString, UniqueNetId ServerIdHexString, optional string ServerIP)
{
	local OnlineGameInterfaceXCom GameInterface;
	`log("DRAGON PUNK DRAGON PUNK SET LOBBY SERVER",,'Team Dragonpunk Co Op');

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.SetLobbyServer(LobbyIdHexString, ServerIdHexString, "0.0.0.0");
	
}

function OnInviteJoinComplete(name SessionName,bool bWasSuccessful)
{
	local string URL;//, ConnectPassword;
	local ESystemMessageType eSystemError;
	local OnlineSubsystem OnlineSub;
	
	OnlineSub=class'GameEngine'.static.GetOnlineSubsystem();
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful), true, 'Team Dragonpunk Co Op');

	if (bWasSuccessful)
	{
		`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_None, bWasSuccessful);

		// Set the online status for the MP menus
		`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_MainMenu);

		if (OnlineSub != None && OnlineSub.GameInterface != None)
		{
			// Get the platform specific information
			if (OnlineSub.GameInterface.GetResolvedConnectString(SessionName,URL))
			{
				URL $= "?bIsFromInvite";
				URL = ModifyClientURL(URL); // allow game to override

				`Log("Resulting url is ("$URL$")",true,'Team Dragonpunk Co Op');
				// Open a network connection to it
				StartNetworkGame(SessionName, URL);
			}
		}
	}
	else
	{
		eSystemError = SystemMessage_InviteSystemError;
		if (SessionName == 'RoomFull' || SessionName == 'LobbyFull' || SessionName == 'GroupFull')
		{
			eSystemError = SystemMessage_GameFull;
		}

		`ONLINEEVENTMGR.OnGameInviteComplete(eSystemError, bWasSuccessful);

		// Clean-up session
		if (OnlineSub != None && OnlineSub.GameInterface != None)
		{
			OnlineSub.GameInterface.DestroyOnlineGame(SessionName);
		}
	}
}

function bool CheckInviteGameVersionMismatch(XComOnlineGameSettings InviteGameSettings)
{
	local string ByteCodeHash;
	local int InstalledDLCHash;
	local int InstalledModsHash;
	local string INIHash;
	local string TempToLog;
	local array<string> TempLog;
	
	ByteCodeHash = class'Helpers'.static.NetGetVerifyPackageHashes();
	InstalledDLCHash = class'Helpers'.static.NetGetInstalledMPFriendlyDLCHash();
	InstalledModsHash = class'Helpers'.static.NetGetInstalledModsHash();
	INIHash = class'Helpers'.static.NetGetMPINIHash();

	TempLog=class'Helpers'.static.GetInstalledModNames();
	foreach TempLog(TempToLog)
	{
		`log("Installed Mods:"@TempToLog,true,'Team Dragonpunk Co Op');
	}
	`log("Installed Mods Hash:"@InstalledModsHash @InstalledModsHash== InviteGameSettings.GetInstalledModsHash(),true,'Team Dragonpunk Co Op');

	TempLog=class'Helpers'.static.GetInstalledDLCNames();
	foreach TempLog(TempToLog)
	{
		`log("Installed DLCs:"@TempToLog,true,'Team Dragonpunk Co Op');
	}
	`log("Installed DLCs Hash:"@InstalledDLCHash @InstalledDLCHash== InviteGameSettings.GetInstalledDLCHash(),true,'Team Dragonpunk Co Op');
	`log("INI HASH:"@INIHash @INIHash== InviteGameSettings.GetINIHash() ,true,'Team Dragonpunk Co Op');
	`log("ByteCode HASH:"@ByteCodeHash @ByteCodeHash==InviteGameSettings.GetByteCodeHash(),true,'Team Dragonpunk Co Op');


	`log(`location @ "InviteGameSettings=" $ InviteGameSettings.ToString(),, 'Team Dragonpunk Co Op');
	`log(`location @ `ShowVar(ByteCodeHash) @ `ShowVar(InstalledDLCHash) @ `ShowVar(InstalledModsHash) @ `ShowVar(INIHash),, 'Team Dragonpunk Co Op');
	return false; //ByteCodeHash != InviteGameSettings.GetByteCodeHash() ||
			//InstalledDLCHash != InviteGameSettings.GetInstalledDLCHash() ||
			//InstalledModsHash != InviteGameSettings.GetInstalledModsHash();
}

function SendRemoteCommand(string Command) //Copied from UIMPShell_Lobby
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`XCOMNETMANAGER.SendRemoteCommand(Command, Parms);
	`log(`location @ "Sent Remote Command '"$Command$"'",,'Team Dragonpunk Co Op');
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	`log(`location @"Dragonpunk Command" @ Command,,'Team Dragonpunk Co Op');
	if(Command ~= "HostJoined")
	{
		SetGameSettingsAsReady();
	}
	if (Command ~= "RequestHistory")
	{
		`XCOMNETMANAGER.SendHistory(`XCOMHISTORY, `XEVENTMGR);
	}
	else
		global.OnRemoteCommand(Command, RawParams);
}
function SendHistory()
{
	`log(`location,,'XCom_Online');
	`XCOMNETMANAGER.SendHistory(`XCOMHISTORY, `XEVENTMGR);
}

function bool SendOrMergeGamestate(XComGameState GameState)
{
	local bool bGameStateSubmitted;
	bGameStateSubmitted = false;
	if (`XCOMNETMANAGER.HasConnections())
	{
		if (`XCOMHISTORY.GetStartState() != none)
		{
			`XCOMNETMANAGER.SendMergeGameState(GameState);
		}
		else
		{
			// HACK: Setting the CachedHistory since the Tacticalrules have not been setup yet ...
			`TACTICALRULES.BuildLocalStateObjectCache();
			`TACTICALRULES.SubmitGameState(GameState);
			bGameStateSubmitted = true;
		}
	}
	return bGameStateSubmitted;
}

function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	`log(`location,,'XCom_Online');
	bHistoryLoaded = true;
}

function ReceivePartialHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	`log(`location,,'XCom_Online');
	bHistoryLoaded = true;
}

function ReceiveGameState(XComGameState InGameState)
{
	`log(`location,,'XCom_Online');
	//CalcAllPlayersReady();
	//UpdateButtons();
}

function ReceiveMergeGameState(XComGameState InGameState)
{
	`log(`location,,'XCom_Online');
	//CalcAllPlayersReady();
	//UpdateButtons();
}

function GetAllPlayersLaunched()
{
	local XComGameState_Player PlayerState;

	AllPlayersLaunched=true;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(!PlayerState.bPlayerReady)
		{
			AllPlayersLaunched = false;
			break;
		}
	}
		
} 

function SetGameSettingsAsReady()
{
	local XComOnlineGameSettings GameSettings;
	local OnlineGameInterface GameInterface;;
	GameInterface = class'GameEngine'.static.GetOnlineSubsystem().GameInterface;
	GameSettings = XComOnlineGameSettings(GameInterface.GetGameSettings('Game'));
	GameSettings.SetServerReady(true);
	GameInterface.UpdateOnlineGame('Game', GameSettings, true);
}