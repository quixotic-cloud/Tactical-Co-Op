// This is an Unreal Script
                           
Class XComCo_Op_DelegatesHolder extends actor;

var string m_strMatchOptions;
var name m_nMatchingSessionName;
var X2MPShellManager m_kMPShellManager;
var bool bWaitingForHistory,bFriendJoined,bCanStartMatch,bHistoryLoaded,AllPlayersLaunched,HostJoinedAlready,CalledForHistory;

function MPAddLobbyDelegates()
{
	local OnlineGameInterfaceXCom GameInterface;
	local XComGameStateNetworkManager NetworkMgr;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.AddJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.AddLobbySettingsUpdateDelegate(OnLobbySettingsUpdate);
	GameInterface.AddLobbyMemberSettingsUpdateDelegate(OnLobbyMemberSettingsUpdate);
	GameInterface.AddLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	GameInterface.AddLobbyReceiveMessageDelegate(OnLobbyReceiveMessage);
	GameInterface.AddLobbyReceiveBinaryDataDelegate(OnLobbyReceiveBinaryData);
	GameInterface.AddLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.ClearGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,OnGameInviteAccepted);
	GameInterface.AddLobbyInviteDelegate(OnLobbyInvite);

	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.AddPlayerJoinedDelegate(PlayerJoined);
	NetworkMgr.AddPlayerLeftDelegate(PlayerLeft);
	NetworkMgr.AddReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.AddReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.AddReceiveGameStateDelegate(ReceiveGameState);
	NetworkMgr.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	NetworkMgr.AddReceiveRemoteCommandDelegate(OnRemoteCommand);
	//NetworkMgr.AddNotifyConnectionClosedDelegate(OnConnectionClosed);

}

function MPClearLobbyDelegates()
{
	local OnlineGameInterfaceXCom GameInterface;
	local XComGameStateNetworkManager NetworkMgr;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.ClearJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.ClearLobbySettingsUpdateDelegate(OnLobbySettingsUpdate);
	GameInterface.ClearLobbyMemberSettingsUpdateDelegate(OnLobbyMemberSettingsUpdate);
	GameInterface.ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	GameInterface.ClearLobbyReceiveMessageDelegate(OnLobbyReceiveMessage);
	GameInterface.ClearLobbyReceiveBinaryDataDelegate(OnLobbyReceiveBinaryData);
	GameInterface.ClearLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.ClearGameInviteAcceptedDelegate(0,OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.ClearLobbyInviteDelegate(OnLobbyInvite);

	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.ClearPlayerJoinedDelegate(PlayerJoined);
	NetworkMgr.ClearPlayerLeftDelegate(PlayerLeft);
	NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.ClearReceivePartialHistoryDelegate(ReceivePartialHistory);
	NetworkMgr.ClearReceiveGameStateDelegate(ReceiveGameState);
	NetworkMgr.ClearReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	NetworkMgr.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
	//NetworkMgr.ClearNotifyConnectionClosedDelegate(OnConnectionClosed);
}

function OnLobbyInvite(UniqueNetId LobbyId, UniqueNetId FriendId, bool bAccepted)
{
	`log("bAccepted:"@bAccepted ,true,'Team Dragonpunk Co Op');
	if(bAccepted)
	{
		OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).JoinLobby(LobbyID);
	}	
}

function OnJoinLobbyComplete(bool bWasSuccessful, const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, UniqueNetId LobbyUID, string Error)
{
	local string LobbyUIDString;
	LobbyUIDString = class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( LobbyUID );
	`log(`location @ `ShowVar(bWasSuccessful) @ `ShowVar(LobbyIndex) @ `ShowVar(LobbyUIDString) @ `ShowVar(Error),,'XCom_Online');
	if(!`XCOMNETMANAGER.HasServerConnection())
		OnInviteJoinOnlineGameComplete(m_nMatchingSessionName,bWasSuccessful);
	`log("Player OnJoinLobbyComplete" @"Client Connections"@ `XCOMNETMANAGER.HasClientConnection() @"Server Connections"@ `XCOMNETMANAGER.HasServerConnection() ,,'Team Dragonpunk');

	if( `XCOMNETMANAGER.HasClientConnection() )
	{
		bCanStartMatch = false;
		//PushState('FriendJoining');
		bWaitingForHistory = true;
		SendRemoteCommand("RequestHistory");
		SetTimer(0.05f,true,'HasHistory');
	}
	else if ( `XCOMNETMANAGER.HasServerConnection() )
	{
		bCanStartMatch = true;
		//PushState('StartingCoOp');
		`log(`location @ "Starting 'StartingCoOp' state!",,'Team Dragonpunk');
		bHistoryLoaded = true;
		if(!HostJoinedAlready)
		{
			SendRemoteCommand("HostJoined");
			HostJoinedAlready=true;
		}
		SetGameSettingsAsReady();
	}
}

function OnLobbySettingsUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex)
{
	`log(`location @ `ShowVar(LobbyIndex),,'XCom_Online');
	if( LobbyList.Length >= 1 )
	{
		`log("Player OnLobbySettingsUpdate" @"Client Connections"@ `XCOMNETMANAGER.HasClientConnection() @"Server Connections"@ `XCOMNETMANAGER.HasServerConnection() ,,'Team Dragonpunk');
		//`XCOMNETMANAGER.PrintDebugInformation();
		//`log("Player TEST HERE",,'Team Dragonpunk');
		if( `XCOMNETMANAGER.HasClientConnection() )
		{
			bCanStartMatch = false;
			//PushState('FriendJoining');
			bWaitingForHistory = true;
			SendRemoteCommand("RequestHistory");
			SetTimer(0.05f,true,'HasHistory');
		}
		else if ( `XCOMNETMANAGER.HasServerConnection() )
		{
			bCanStartMatch = true;
			//PushState('StartingCoOp');
			`log(`location @ "Starting 'StartingCoOp' state!",,'Team Dragonpunk');
			bHistoryLoaded = true;
			if(!HostJoinedAlready)
			{
				SendRemoteCommand("HostJoined");
				HostJoinedAlready=true;
			}
			SetGameSettingsAsReady();
		}
	}
}

function OnLobbyMemberSettingsUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex),,'XCom_Online');
}

function OnLobbyMemberStatusUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, int InstigatorIndex, string Status)
{
	`log(`location @`ShowVar(LobbyList.Length) @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(InstigatorIndex) @ `ShowVar(Status),,'XCom_Online');
	if(Status=="Joined")
	{
		`log("DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK DRAGON PUNK",,'Team Dragonpunk Co Op');
		`XCOMNETMANAGER.ForceConnectionAttempt();
		if( LobbyList.Length >= 1 )
		{
			SetLobbyServer(LobbyList[LobbyIndex].LobbyUID,OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).CurrentGameServerId);
			OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).PublishSteamServer();
			`log("Player OnLobbyMemberStatusUpdate" @"Client Connections"@ `XCOMNETMANAGER.HasClientConnection() @"Server Connections"@ `XCOMNETMANAGER.HasServerConnection() ,,'Team Dragonpunk');
			//`XCOMNETMANAGER.PrintDebugInformation();
			//`log("Player TEST HERE",,'Team Dragonpunk');
			if( `XCOMNETMANAGER.HasClientConnection() )
			{
				bCanStartMatch = false;
				//PushState('FriendJoining');
				bWaitingForHistory = true;
				SendRemoteCommand("RequestHistory");
				SetTimer(0.05f,true,'HasHistory');
			}
			else if ( `XCOMNETMANAGER.HasServerConnection() )
			{
				bCanStartMatch = true;
				//PushState('StartingCoOp');
				`log(`location @ "Starting 'StartingCoOp' state!",,'Team Dragonpunk');
				bHistoryLoaded = true;
				if(!HostJoinedAlready)
				{
					SendRemoteCommand("HostJoined");
					HostJoinedAlready=true;
				}
				SetGameSettingsAsReady();
			}

			//XComCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager).MPSendHistory();
			//XComCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager).MPCheckConnections();
		}
		
	}
	
}
function HasHistory()
{
	if(!bWaitingForHistory)
	{
		`log("Cleared Timer Dragonpunk",,'Team Dragonpunk');
		SendRemoteCommand("ClientJoined");
		ClearTimer('HasHistory');
		//CalledForHistory=false;
	}	
}
function OnLobbyReceiveMessage(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, string Type, string Message)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(Type) @ `ShowVar(Message),,'XCom_Online');
}

function OnLobbyReceiveBinaryData(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, const out array<byte> Data)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(Data.Length),,'XCom_Online');
}

function OnLobbyJoinGame(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, UniqueNetId ServerId, string ServerIP)
{
	local string ServerIdString;
	ServerIdString = class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( ServerId );
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(ServerIdString) @ `ShowVar(ServerIP),,'XCom_Online');
}

function OnLobbyKicked(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int AdminIndex)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(AdminIndex),,'XCom_Online');
}

function SetLobbyServer(UniqueNetId LobbyIdHexString, UniqueNetId ServerIdHexString, optional string ServerIP)
{
	local OnlineGameInterfaceXCom GameInterface;
	`log("DRAGON PUNK DRAGON PUNK SET LOBBY SERVER",,'Team Dragonpunk Co Op');

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.SetLobbyServer(LobbyIdHexString, ServerIdHexString, ServerIP);
	
}

function OnCreateLobbyComplete(bool bWasSuccessful, UniqueNetId LobbyId, string Error)
{
	`log(`location @ `ShowVar(class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( LobbyId )) @ `ShowVar(bWasSuccessful) @ `ShowVar(Error),,'XCom_Online');
	//OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).JoinLobby(LobbyId);
	`log("Player OnCreateLobbyComplete" @"Client Connections"@ `XCOMNETMANAGER.HasClientConnection() @"Server Connections"@ `XCOMNETMANAGER.HasServerConnection() ,,'Team Dragonpunk');
	if( `XCOMNETMANAGER.HasClientConnection() )
	{
		bCanStartMatch = false;
		//PushState('FriendJoining');
		bWaitingForHistory = true;
		SendRemoteCommand("RequestHistory");
		SetTimer(0.05f,true,'HasHistory');
	}
	else if ( `XCOMNETMANAGER.HasServerConnection() )
	{
		bCanStartMatch = true;
		//PushState('StartingCoOp');
		`log(`location @ "Starting 'StartingCoOp' state!",,'Team Dragonpunk');
		bHistoryLoaded = true;
		if(!HostJoinedAlready)
		{
			SendRemoteCommand("HostJoined");
			HostJoinedAlready=true;
		}
		SetGameSettingsAsReady();
	}
}

function OnGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	local UISquadSelect SquadSelectScreen;
	local bool bIsMoviePlaying;
	
	`log("Dragonpunk test test test NOT IN XComOnlineEventMgr",true,'Team Dragonpunk Co Op');

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
			`log(`location @ " -----> Shutting down the playing movie and returning to the MP Main Menu, then accepting the invite again.",,'XCom_Online');
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
			OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).AcceptGameInvite(LocalPlayer(PlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).Player).ControllerId,'XComOnlineCoOpGame_TeamDragonpunk');
		}
		else
		{
			`log(`location @ "Waiting for whatever to finish and transition to the UISquadSelect screen.",true,'Team Dragonpunk Co Op');
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

function OnInviteJoinOnlineGameComplete(name SessionName, bool bWasSuccessful)
{
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	//class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearJoinOnlineGameCompleteDelegate(OnInviteJoinOnlineGameComplete);
	OnInviteJoinComplete(SessionName, bWasSuccessful);
}
function OnInviteJoinComplete(name SessionName,bool bWasSuccessful)
{
	local string URL;

	if (bWasSuccessful)
	{
		`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_None, bWasSuccessful);

		// Set the online status for the MP menus
		`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_MainMenu);
		if (class'GameEngine'.static.GetOnlineSubsystem() != None && class'GameEngine'.static.GetOnlineSubsystem().GameInterface != None)
		{
			// Get the platform specific information
			if (class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetResolvedConnectString(SessionName,URL))
			{
				URL $= "?bIsFromInvite";

				// allow game to override
				URL = ModifyClientURL(URL);

				`Log("Resulting url is ("$URL$")",,'Team Dragonpunk');
				// Open a network connection to it
				StartClient(SessionName, URL);
			}
		}
	}
}
function string ModifyClientURL(string URL)
{
	return URL;
}
function StartClient(name SessionName, optional string ResolvedURL="")
{
	local URL OnlineURL;
	local string sError;
	OnlineURL.Host = ResolvedURL;
	OnlineURL.Port = 7777;
	`log(`location @ "Creating Network Client to join the Online Game at '"$ResolvedURL$"' on port '"$"7777"$"'.",,'XCom_Online');
	`XCOMNETMANAGER.CreateClient(OnlineURL, sError);	
}

function SendRemoteCommand(string Command) //Copied from UIMPShell_Lobby
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	if(Command~="RequestHistory" && !CalledForHistory)
	{
		`XCOMNETMANAGER.SendRemoteCommand(Command, Parms);
		CalledForHistory=true;
	}
	`log(`location @ "Sent Remote Command '"$Command$"'",,'Team Dragonpunk');
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	`log(`location @ `ShowVar(Command),,'Team Dragonpunk');
	if (Command ~= "ClientJoined")
	{
		`log("Client JOINED",,'Team Dragonpunk');
	}	
	else if (Command ~= "RequestHistory")
	{
		`XCOMNETMANAGER.SendHistory(`XCOMHISTORY, `XEVENTMGR);
	}
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
function PlayerJoined(string RequestURL, string Address, const UniqueNetId UniqueId, bool bSupportsAuth)
{
	local string strUniqueId;
	bFriendJoined = true;
	
	strUniqueId = class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueId);
	`log("Player Joined" @ `ShowVar(strUniqueId),,'Team Dragonpunk');

	//RemotePlayerJoined(UniqueId);  // Player joined, update!
}

function PlayerLeft(const UniqueNetId UniqueId)
{
	local string strUniqueId;
	bFriendJoined = false;
	
	strUniqueId = class'OnlineSubsystem'.static.UniqueNetIdToString(UniqueId);
	`log("Player Left" @ `ShowVar(strUniqueId),,'Team Dragonpunk');
	//RemotePlayerLeft(UniqueId); // Player left, update!
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
	GameSettings = XComOnlineGameSettings(GameInterface.GetGameSettings('XComOnlineCoOpGame_TeamDragonpunk'));
	GameSettings.SetServerReady(true);
	GameInterface.UpdateOnlineGame('XComOnlineCoOpGame_TeamDragonpunk', GameSettings, true);
}

