//  *********   DRAGONPUNK SOURCE CODE   ******************
//  FILE:    XComCo_Op_ConnectionSetup
//  AUTHOR:  Elad Dvash
//  PURPOSE: An actor that deals with connections and movement to tactical.
//---------------------------------------------------------------------------------------

class XComCo_Op_ConnectionSetup extends Actor;


var string m_strMatchOptions;
var name m_nMatchingSessionName;
var X2MPShellManager m_kMPShellManager;
var XComOnlineGameSettings ServerGameSettings;
var bool bWaitingForHistory,bFriendJoined,bCanStartMatch,bHistoryLoaded,AllPlayersLaunched,HostJoinedAlready,CalledForHistory,ForceSuccess;
var bool GoForNetworkTiming,b_ReadyToLaunch,LoadingGame;
var array<StateObjectReference> SavedSquad;
var TDialogueBoxData DialogData;
var XCom_Co_Op_TacticalGameManager TGMCoOp;
var bool Launched;
var XComGameState_BattleData m_BattleData;
var array<StateObjectReference> ServerSquad,ClientSquad,TotalSquad;


event Tick( float DeltaTime )
{
	super.Tick(DeltaTime);
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

	`log("I now have the new Delegates",,'Team Dragonpunk Co Op');
	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.ClearGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,OnGameInviteAccepted);	
	GameInterface.AddJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.AddLobbyInviteDelegate(OnLobbyInvite);
	GameInterface.AddLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.AddCreateLobbyCompleteDelegate(OnCreateLobbyComplete);
	GameInterface.AddLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	GameInterface.AddJoinOnlineGameCompleteDelegate(OnInviteJoinOnlineGameComplete);
	NetworkMgr = `XCOMNETMANAGER;
	//NetworkMgr.AddReceiveHistoryDelegate(ReceiveHistory);
	NetworkMgr.AddReceiveGameStateDelegate(ReceiveGameState);
	NetworkMgr.AddReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	NetworkMgr.AddReceiveRemoteCommandDelegate(OnRemoteCommand);
}

function RevertInviteAcceptedDelegates()
{	
	local OnlineGameInterfaceXCom GameInterface;
	`log("I now have the old Delegates",,'Team Dragonpunk Co Op');	
	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.ClearGameInviteAcceptedDelegate(0,OnGameInviteAccepted);
	GameInterface.AddGameInviteAcceptedDelegate(0,`ONLINEEVENTMGR.OnGameInviteAccepted);
	GameInterface.ClearJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.ClearLobbyInviteDelegate(OnLobbyInvite);
	GameInterface.ClearLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.ClearCreateLobbyCompleteDelegate(OnCreateLobbyComplete);
	GameInterface.ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	GameInterface.ClearJoinOnlineGameCompleteDelegate(OnInviteJoinOnlineGameComplete);

	`XCOMNETMANAGER.ClearReceiveHistoryDelegate(ReceiveHistory);
	`XCOMNETMANAGER.ClearReceiveGameStateDelegate(ReceiveGameState);
	`XCOMNETMANAGER.ClearReceiveMergeGameStateDelegate(ReceiveMergeGameState);
	`XCOMNETMANAGER.ClearReceiveRemoteCommandDelegate(OnRemoteCommand);
}

function CreateOnlineGame()
{
	local OnlineSubsystem OnlineSub;
	
	InitShellManager();
	OnlineSub=class'GameEngine'.static.GetOnlineSubsystem();
	m_kMPShellManager.OnlineGame_SetAutomatch(false);
	OSSCreateGameSettings(false);
	OnCreateOnlineGameComplete(m_nMatchingSessionName,true);
	OnlineSub.GameInterface.AddCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);
// Now kick off the async publish
	if ( !OnlineSub.GameInterface.CreateOnlineGame(LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId,'Game',ServerGameSettings) )
	{
		OnlineSub.GameInterface.ClearCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);
	}
	PopupServerNotification();
}	
function OnCreateLobbyComplete(bool bWasSuccessful, UniqueNetId LobbyId, string Error)
{
	XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).pres.UICloseProgressDialog();
	OpenSteamUI();
}

function RegisterLocalTalker()
{
	local OnlineSubsystem	OnlineSubsystem;

	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSubsystem != none )
	{
		OnlineSubsystem.VoiceInterface.RegisterLocalTalker( LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId );
		OnlineSubsystem.VoiceInterface.StartSpeechRecognition( LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId );

		OnlineSubsystem.VoiceInterface.AddRecognitionCompleteDelegate( LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId, OnRecognitionComplete );
	}
}

function OnRecognitionComplete()
{
	local OnlineSubsystem	OnlineSubsystem;
	local array<SpeechRecognizedWord> Words;
	local int i;

	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if( OnlineSubsystem != none )
	{
		OnlineSubsystem.VoiceInterface.GetRecognitionResults( LocalPlayer(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().Player).ControllerId, Words );
		for (i = 0; i < Words.length; i++)
		{
			`Log("Speech recognition got word:" @ Words[i].WordText);
		}
	}
}


function PopupServerNotification()
{
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = "Creating Co-Op Server";
	DialogData.strText = "Please Wait. This message will disappear automatically.";
	DialogData.strAccept=" ";
	DialogData.strCancel=" ";
	`HQPRES.UIRaiseDialog(DialogData);
}

function PopupClientNotification()
{
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = "Waiting For Server To Generate Map";
	DialogData.strText = "Please wait. This message will disappear automatically.";
	DialogData.strAccept=" ";
	DialogData.strCancel=" ";
	`HQPRES.UIRaiseDialog(DialogData);
}

function EndDialogBox()
{
	`log("Ending Dialog box");
	if(UIDialogueBox(`SCREENSTACK.GetCurrentScreen().Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).ShowingDialog())
		UIDialogueBox(`SCREENSTACK.GetCurrentScreen().Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).RemoveDialog();
}

function OpenSteamUI()
{
	local OnlineSubsystem onlineSub;
	local int LocalUserNum;

	onlineSub = `ONLINEEVENTMGR.OnlineSub;
	if(onlineSub==none)
		return;

	LocalUserNum = `ONLINEEVENTMGR.LocalUserIndex;
	onlineSub.PlayerInterfaceEx.ShowInviteUI(LocalUserNum);	
	EndDialogBox();
}

function OnCreateOnlineGameComplete(name SessionName,bool bWasSuccessful)
{
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearCreateOnlineGameCompleteDelegate(OnCreateOnlineGameComplete);

	if(bWasSuccessful)
	{
		m_nMatchingSessionName = SessionName;
		StartNetworkGame(m_nMatchingSessionName);

		`log("Successfully created online game: Session=" $ SessionName $ ", Server=" @ "TODO: implement, i used to come from the GameReplicationInfo: WorldInfo.GRI.ServerName", true, 'Team Dragonpunk Co Op');

}
	else
	{
		`log("Failed to create online game: Session=" $ SessionName, true, 'Team Dragonpunk Co Op');
	}	
}

function OnCreateCoOpGameTimerComplete()
{
	`log("Starting Network Game Ended", true, 'Team Dragonpunk Co Op');
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
	if(InStr(Status,"Joined")>-1)
	{
		`log(`location @ `ShowVar(LobbyIndex) @"LobbyList[LobbyIndex].Members"@LobbyList[LobbyIndex].Members.Length,,'Team Dragonpunk Co Op');
		RegisterLocalTalker();
	}
	else if(InStr(Status, "Exit") > -1)
	{
		DisconnectGame();
	}

	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).LaunchButton.OnClickedDelegate=LoadTacticalMapDelegate;
}
function DisconnectGame()
{
	`XCOMNETMANAGER.Disconnect();
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');
}

function OnLobbyInvite(UniqueNetId LobbyId, UniqueNetId FriendId, bool bAccepted)
{
	`log("bAccepted:"@bAccepted ,true,'Team Dragonpunk Co Op');
}

function OSSCreateGameSettings(bool bAutomatch)
{
	local XComOnlineGameSettings kGameSettings;
	local XComOnlineGameSettingsDeathmatchUnranked kUnrankedDeathmatchSettings;

	InitShellManager();
	kUnrankedDeathmatchSettings = new class'XComOnlineGameSettingsDeathmatchUnranked';
	kGameSettings = kUnrankedDeathmatchSettings;
	kGameSettings.SetIsRanked(false);
	kGameSettings.SetNetworkType(eMPNetworkType_Public);
	kGameSettings.SetGameType(eMPGameType_Deathmatch);
	kGameSettings.SetTurnTimeSeconds(3600); 
	kGameSettings.SetMaxSquadCost(500000); 
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

	OnlineURL.Map = "XComShell_Multiplayer.umap";
	OnlineURL.Op.AddItem("Game=Dragonpunk_CoOp.XComCoOpTacticalGame");

	m_nMatchingSessionName = SessionName;
	m_strMatchOptions = BuildURL(OnlineURL);

	if (!kGameSettings.bIsLanMatch)
	{
		OnlineURL.Op.AddItem("steamsockets");
	}
	NetManager = `XCOMNETMANAGER;
	ChangeInviteAcceptedDelegates();
	if (ResolvedURL == "" && !`XCOMNETMANAGER.HasServerConnection())
	{
		`log(`location @ "Creating Network Server to host the Online Game.",,'Team Dragonpunk Co Op');
		NetManager.CreateServer(OnlineURL, sError);
		`log("Starting Network Game Ended Created Server", true, 'Team Dragonpunk Co Op');
	}
	else if(ResolvedURL != "")
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
			TickA=Spawn(class'UIPanel_TickActor',`SCREENSTACK.GetCurrentScreen());
			TickA.SetupTick(0.25);
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
	`log("OnPlayerJoined",,'Team Dragonpunk Co Op');
	if( `XCOMNETMANAGER.HasClientConnection() )
	{
		`log(`location @ "Sending 'Request History' command",,'Team Dragonpunk Co Op');
		SendRemoteCommand("RequestHistory");
	}
	else if ( `XCOMNETMANAGER.HasServerConnection() )
	{
		bCanStartMatch = true;
		`log(`location @ "Sending 'Host Joined' command",,'Team Dragonpunk Co Op');
		bHistoryLoaded = true;
		SetGameSettingsAsReady();
		SendRemoteCommand("HostJoined");
	}
}

function OnGameInviteAccepted(const out OnlineGameSearchResult InviteResult, bool bWasSuccessful)
{
	local bool bIsMoviePlaying;
	local UISquadSelect SquadSelectScreen;

	`log("Dragonpunk test test test NOT IN XComOnlineEventMgr",true,'Team Dragonpunk Co Op');

	if(XComOnlineGameSettings(InviteResult.GameSettings).GetTurnTimeSeconds()<=1000 || XComOnlineGameSettings(InviteResult.GameSettings).GetMaxSquadCost()<=100000 )
	{
		`log("Entering OnlineEventMgr, TurnTime:"@XComOnlineGameSettings(InviteResult.GameSettings).GetTurnTimeSeconds() @",Max Cost:"@XComOnlineGameSettings(InviteResult.GameSettings).GetMaxSquadCost(),,'Team Dragonpunk Co Op');
		`ONLINEEVENTMGR.OnGameInviteAccepted(InviteResult,bWasSuccessful);
	}
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
			`ONLINEEVENTMGR.InviteFailed(SystemMessage_InviteSystemError, !`ONLINEEVENTMGR.IsCurrentlyTriggeringBootInvite()); // Travel to the MP Menu only if the invite was made while in-game.
			return;
		}

		if (CheckInviteGameVersionMismatch(XComOnlineGameSettings(InviteResult.GameSettings)))
		{
			`ONLINEEVENTMGR.InviteFailed(SystemMessage_VersionMismatch, true);
			`log("InviteFailed(SystemMessage_VersionMismatch)",true,'Team Dragonpunk Co Op');
			return;
		}


		`ONLINEEVENTMGR.bAcceptedInviteDuringGameplay = true;
		class'XComOnlineEventMgr_Co_Op_Override'.static.AddItemToAcceptedInvites(InviteResult);

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
				`XENGINE.StopCurrentMovie();
			}
			if(!`SCREENSTACK.IsCurrentScreen('UISquadSelect'))
			{
				SquadSelectScreen=(`SCREENSTACK.Screens[0].Spawn(Class'UISquadSelect',none));
				`SCREENSTACK.Push(SquadSelectScreen);
				`log("Pushing SquadSelectUI to screen stack",true,'Team Dragonpunk Co Op');
			}
			else
			{
				`log("Already in Squad Select UI",true,'Team Dragonpunk Co Op');
			}
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

	if(`XCOMNETMANAGER.HasServerConnection()) return;

	`log(`location @"OnInviteJoinOnlineGameComplete",,'Team Dragonpunk Co Op');
	OnlineSub=class'GameEngine'.static.GetOnlineSubsystem();
	OnlineSub.GameInterface.ClearJoinOnlineGameCompleteDelegate(OnInviteJoinOnlineGameComplete);
	OnInviteJoinComplete(SessionName, bWasSuccessful);

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
	local string URL;
	local ESystemMessageType eSystemError;
	local OnlineSubsystem OnlineSub;
	
	OnlineSub=class'GameEngine'.static.GetOnlineSubsystem();
	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful), true, 'Team Dragonpunk Co Op');
	
	if (bWasSuccessful)
	{
		`ONLINEEVENTMGR.OnGameInviteComplete(SystemMessage_None, bWasSuccessful);

		`ONLINEEVENTMGR.SetOnlineStatus(OnlineStatus_MainMenu);

		if (OnlineSub != None && OnlineSub.GameInterface != None)
		{
			if (OnlineSub.GameInterface.GetResolvedConnectString(SessionName,URL))
			{
				URL $= "?bIsFromInvite";
				URL = ModifyClientURL(URL); // allow game to override

				`Log("Resulting url is ("$URL$")",true,'Team Dragonpunk Co Op');
				// Open a network connection to it
				StartNetworkGame(SessionName, URL);
				SendRemoteCommand("ChangeLaunchButton");
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
	//Remember to re-enable the checks on the beta and the release. THIS IS NOT HOW IT SHOULD BE OUTSIDE OF ALPHA
	return false; //ByteCodeHash != InviteGameSettings.GetByteCodeHash() ||
			//InstalledDLCHash != InviteGameSettings.GetInstalledDLCHash() ||
			//InstalledModsHash != InviteGameSettings.GetInstalledModsHash();
}

function SendRemoteCommand(string Command) //Copied from UIMPShell_Lobby
{
	local array<byte> Parms;
	Parms.Length = 0; // Removes script warning.
	`XCOMNETMANAGER.SendRemoteCommand(Command, Parms);
	if(Command~="LoadGame")
	{
		LoadingGame=true;
		SendHistory();
	}
	`log(`location @ "Sent Remote Command '"$Command$"'",,'Team Dragonpunk Co Op');
}

function SentRemoteSquadCommand()
{
	local array<byte> Params;
	local StateObjectReference Temp;
	local XComGameStateNetworkManager NetManager;
	local String FinalOut;
	NetManager=`XCOMNETMANAGER;
	Params.Length = 0; // Removes script warning
	foreach TotalSquad(Temp)
	{
		FinalOut$=Temp.ObjectID $"|";
	}
	FinalOut$="-1|";
	foreach ServerSquad(Temp)
	{
		FinalOut$=Temp.ObjectID $"|";
	}
	FinalOut$="-1|";
	foreach ClientSquad(Temp)
	{
		FinalOut$=Temp.ObjectID $"|";
	}
	FinalOut$="-1";
	
	NetManager.AddCommandParam_String(FinalOut,Params);
	NetManager.SendRemoteCommand("UpdateSquad", Params);	
}

function DecipherSquads(array<byte> Params)
{
	local string InString,TString;
	local array<string> SplitSTR;
	local int count,TempInt;
	local XComGameStateNetworkManager NetManager;

	NetManager=`XCOMNETMANAGER;
	InString=NetManager.GetCommandParam_String(Params);
	SplitSTR=SplitString(InString,"|",true);
	`log(InString,,'Dragonpunk Co Op Squads');
	foreach SplitSTR(Tstring)
	{
		TempInt=int(Tstring);

		if(TString~="-1" || TempInt==-1)
		{
			count++;
			continue;
		}
		switch (Count)
		{
			case 0:
				TotalSquad.AddItem(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TempInt)).GetReference());
				break;
			case 1:
				ServerSquad.AddItem(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TempInt)).GetReference());
				break;
			case 2:
				ClientSquad.AddItem(XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TempInt)).GetReference());
				break;
		}
	}
}

simulated function RefreshDisplay()
{
	local int SlotIndex, SquadIndex;
	local UISquadSelect_ListItem ListItem; 
	local UISquadSelect SS; 
	
	SS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));

	for( SlotIndex = 0; SlotIndex < SS.SlotListOrder.Length; ++SlotIndex )
	{
		SquadIndex = SS.SlotListOrder[SlotIndex];

		// The slot list may contain more information/slots than available soldiers, so skip if we're reading outside the current soldier availability. 
		if( SquadIndex >= SS.SoldierSlotCount )
			continue;

		//We want the slots to match the visual order of the pawns in the slot list. 
		ListItem = UISquadSelect_ListItem(SS.m_kSlotList.GetItem(SlotIndex));
		ListItem.UpdateData(SquadIndex);
	}
}

function OnRemoteCommand(string Command, array<byte> RawParams)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local float listWidth,listX;
	local UISquadSelect UISS;
	local XComGameState_Unit UnitState;
	local StateObjectReference UnitRef;
	local XComGameState SearchState;
	local XComGameStateHistory TempH;
//	`log(`location @"Dragonpunk Command" @ Command,,'Team Dragonpunk Co Op');

	if (Command ~= "RequestHistory")
	{
		`XCOMNETMANAGER.SendHistory(`XCOMHISTORY, `XEVENTMGR);
		`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_SquadWatcher);
	}
	else if(Command ~= "RecievedHistory")
	{

		if(LoadingGame==false)
		{
			SendRemoteCommand("HistoryConfirmed");
			UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
			listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
			listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
			UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
			UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(0); //fixes the x position of the list on the screen
			UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation(); //fixes the x position of the list on the screen
			RefreshDisplay();
		}
		else if(!Launched)
		{
			SendRemoteCommand("HistoryConfirmedPopUp");		
			`log(Command);
			Launched=true;
			LoadTacticalMap();
		}	
	}
	else if(Command~="HistoryConfirmedPopUp")
	{
		PopupClientNotification();
	}
	else if(Command~= "HistoryConfirmedLoadGame")
	{
		`log(Command);
		if(`XCOMNETMANAGER.HasClientConnection()) 
		{
			if(UIDialogueBox(UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).ShowingDialog())
				UIDialogueBox(UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).Movie.Stack.GetFirstInstanceOf(class'UIDialogueBox')).RemoveDialog();
			SendRemoteCommand("ImComingBaby");
			LoadTacticalMap();
		}
	}
	else if(Command~= "HistoryConfirmed")
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		foreach XComHQ.Squad(UnitRef)
		{
			`log("Unit in squad HistoryConfirmed:"@XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetFullName(),,'Team Dragonpunk Co Op');
		}
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateMissionInfo();
		SavedSquad=XComHQ.Squad;
		`log("Updating Squad Select HistoryConfirmed",,'Team Dragonpunk Co Op');
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(0); //fixes the x position of the list on the screen
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation(); //fixes the x position of the list on the screen
		RefreshDisplay();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).RefreshDisplay();
		SearchState=`ONLINEEVENTMGR.LatestSaveState(TempH);
		foreach SearchState.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if(UnitState.IsASoldier() && UnitState.IsAlive()) //Only soldiers... that are alive
			{
				`log("Unit Name Test:"@UnitState.GetFullName(),,'Dragonpunk Co Op Unit Load Test');
			}
		}	
	
		`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_SquadWatcher);
	}
	else if (Command~= "HistoryRegisteredConfirmed")
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		foreach XComHQ.Squad(UnitRef)
		{
			`log("Unit in squad RegisteredConfirmed:"@XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetFullName(),,'Team Dragonpunk Co Op');
		}
		SavedSquad=XComHQ.Squad;
		`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_SquadWatcher);
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateMissionInfo();
		UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
		listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
		listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(0); //fixes the x position of the list on the screen
		UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation(); //fixes the x position of the list on the screen
		RefreshDisplay();
		//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).RefreshDisplay();
		`log("Updating Squad Select RegisteredConfirmed",,'Team Dragonpunk Co Op');
	}
	else if (Command~="LoadGame")
	{
		`log("Client:"@`XCOMNETMANAGER.HasClientConnection() @", Server:"@`XCOMNETMANAGER.HasServerConnection() @"Launched:"@Launched ,,'Team Dragonpunk Co Op');		
		`log(Command);
		LoadingGame=true;
	}
	else if (Command~="UpdateSquad")
	{
		TotalSquad.Length=0;
		ServerSquad.Length=0;
		ClientSquad.Length=0;
		DecipherSquads(RawParams);
	}
}

simulated function XComGameState_MissionSite GetMission()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom HQ;

	HQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	History = `XCOMHISTORY;
	return XComGameState_MissionSite(History.GetGameStateForObjectID(HQ.MissionRef.ObjectID));
}

function UpdateSS()
{
	local float listWidth,listX;
	local UISquadSelect UISS;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference UnitRef;	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach XComHQ.Squad(UnitRef)
	{
		`log("Unit in squad RegisteredConfirmed:"@XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID)).GetFullName(),,'Team Dragonpunk Co Op');
	}

	SavedSquad=XComHQ.Squad;
	`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_SquadWatcher);
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateData();
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).UpdateMissionInfo();
	UISS=UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect'));
	listWidth = UISS.GetTotalSlots() * (class'UISquadSelect_ListItem'.default.width + UISS.LIST_ITEM_PADDING);
	listX =(UISS.Movie.UI_RES_X / 2) - (listWidth/2);
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.OriginTopCenter();
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.SetX(0); //fixes the x position of the list on the screen
	UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).m_kSlotList.RealizeLocation(); //fixes the x position of the list on the screen
	RefreshDisplay();
	//UISquadSelect(`SCREENSTACK.GetFirstInstanceOf(class'UISquadSelect')).RefreshDisplay();
	`log("Updating Squad Select RegisteredConfirmed",,'Team Dragonpunk Co Op');	
}

static function OnNewGameState_SquadWatcher(XComGameState GameState) //Thank you Amineri and LWS! 
{
	local int StateObjectIndex;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_BaseObject StateObjectCurrent;
	local bool Send;
	if(!`XCOMNETMANAGER.HasConnections())return;
    for( StateObjectIndex = 0; StateObjectIndex < GameState.GetNumGameStateObjects(); ++StateObjectIndex )
	{
		StateObjectCurrent = GameState.GetGameStateForObjectIndex(StateObjectIndex);		
		XComHQ = XComGameState_HeadquartersXCom(StateObjectCurrent);
		if(XComHQ != none) 
		{
			`log("XComHQ:False");
			Send=true;
		}
	}
	if(Send)
	{
		`XCOMNETMANAGER.SendMergeGameState(GameState);
	}	
}

static function bool PerSoldierSquadCheck(XComGameState InGS)
{
	local int i;
	local XComGameState_Unit Unit,UnitPrev;

	for(i=0;i<InGS.GetNumGameStateObjects();i++)
	{
		Unit=XComGameState_Unit(InGS.GetGameStateForObjectIndex(i));
		if(Unit!=none)
		{
			UnitPrev=XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Unit.ObjectID,,InGS.HistoryIndex - 1));
			if(UnitPrev !=none)
			{
				if(UnitPrev!=Unit)
					return false;
			}
		}
	}
	return true;
}

function ReceiveMergeGameState(XComGameState InGameState)
{
	`log(`location @"Recieved Merge GameState Connection Setup",,'Team Dragonpunk Co Op');
}

static function bool SquadCheck(array<StateObjectReference> arrOne, array<StateObjectReference> arrTwo)
{
	local int i,j;
	local array<bool> CheckArray;

	if(arrOne.Length!=arrTwo.Length) 
		return False;

	for(i=0;i<arrOne.Length;i++)
	{
		for(j=0;j<arrTwo.Length;j++)
		{
			if(arrOne[i]==arrTwo[j])
				CheckArray.AddItem(true);
		}
	}
	if(CheckArray.Length==arrOne.Length)
		return true;

	return false;
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
			`TACTICALRULES.BuildLocalStateObjectCache();
			`TACTICALRULES.SubmitGameState(GameState);
			bGameStateSubmitted = true;
		}
	}
	return bGameStateSubmitted;
}

function ReceiveHistory(XComGameStateHistory InHistory, X2EventManager EventManager)
{
	local XComGameStateNetworkManager NetworkMgr;
	if(!bHistoryLoaded)
	{
		NetworkMgr = `XCOMNETMANAGER;
		NetworkMgr.ClearReceiveHistoryDelegate(ReceiveHistory);
		`log(`location,,'XCom_Online');
		`log(`location @"Dragonpunk Recieved History",,'Team Dragonpunk Co Op');
		bHistoryLoaded = true;
		Global.ReceiveHistory(InHistory, EventManager);
		SendRemoteCommand("RecievedHistory");
		SendRemoteCommand("ClientJoined");
	}
	
}

function ReceiveGameState(XComGameState InGameState)
{
	`log(`location,,'XCom_Online');
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

function LoadTacticalMapDelegate(UIButton Button)
{
	Button.SetDisabled(true);
	SetupStartState();
	SetupMission();
	LoadTacticalMap();	
	if(`XCOMNETMANAGER.HasServerConnection() && !LoadingGame) SendRemoteCommand("LoadGame");
}

function LoadTacticalMap()
{
	local XComGameState_BattleData BattleDataState;
	`log(`location,,'XCom_Online');
//	ConsoleCommand("unsuppress XCom_GameStates");
	`XCOMHISTORY.UnRegisterOnNewGameStateDelegate(OnNewGameState_SquadWatcher);
	
	BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(BattleDataState==none)
	{
		BattleDataState =m_BattleData;
	}
	
	`log(`location @ "'" $ BattleDataState.m_strMapCommand $ "'",,'Dragonpunk Co Op');
	if(LoadingGame)
	{
		Launched=true;
		RevertInviteAcceptedDelegates();
		ConsoleCommand(BattleDataState.m_strMapCommand);
	}
}



function SetupMission()
{
	local XComGameState                     TacticalStartState;
	local XComTacticalMissionManager		MissionManager;
	local XComGameState_MissionSite			MPMission;

	TacticalStartState = `XCOMHISTORY.GetStartState();

	// There should only be one Mission Site for MP in the Tactical Start State
	foreach TacticalStartState.IterateByClassType(class'XComGameState_MissionSite', MPMission)
	{
		`log(`location @ MPMission.ToString(),,'XCom_Online');
		break;
	}

	// Setup the Mission Data
	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.ForceMission = MPMission.GeneratedMission.Mission;
	MissionManager.MissionQuestItemTemplate = MPMission.GeneratedMission.MissionQuestItemTemplate;
}

function InitListeners()
{
	local object myself;
	myself=self;
	`XEVENTMGR.RegisterForEvent( myself, 'OnTacticalBeginPlay', OnTacticalBeginPlay);
	`log(`location @"InitListeners",,'Dragonpunk Co Op');
}
function EventListenerReturn OnTacticalBeginPlay(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	TGMCoOp=Spawn(class'XCom_Co_Op_TacticalGameManager',self);
	TGMCoOp.InitManager();
	return ELR_NoInterrupt;
}

function SetupStartState()
{
	local XComGameState StrategyStartState, TacticalStartState;
	local XGTacticalGameCore GameCore;
	local XComGameStateHistory	History;

	`log(`location,,'XCom_Online');

	`ONLINEEVENTMGR.ReadProfileSettings();
	History=`XCOMHISTORY;

	///
	/// Setup the Strategy side ...
	///

	// Create the basic strategy objects
	if((XComGameStateContext_StrategyGameRule(History.GetGameStateFromHistory(History.FindStartStateIndex()).GetContext()) == None))
	{
		StrategyStartState = class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(, , , , , , false, , class'X2DataTemplate'.const.BITFIELD_GAMEAREA_Multiplayer, false /*SetupDLCContent*/);
		`log("Creating New Stategy State",,'Dragonpunk Co Op');
	}
	else
	{
		StrategyStartState=History.GetGameStateFromHistory(History.FindStartStateIndex());
	}
	///
	/// Setup the Tactical side ...
	///

	// Setup the GameCore
	GameCore = `GAMECORE;
	if(GameCore == none)
	{
		GameCore = Spawn(class'XGTacticalGameCore', self);
		GameCore.Init();
		`GAMECORE = GameCore;
	}

	// Create the basic objects
	TacticalStartState = CreateDefaultTacticalStartState_Coop(m_BattleData);

	///
	/// Setup the Map
	///

	// Configure the map from the current strategy start state
	SetupMapData(StrategyStartState, TacticalStartState);

	//Add the start state to the history
	`XCOMHISTORY.AddGameStateToHistory(TacticalStartState);	
}

simulated function CreateBD(XComGameState NewGameState,optional out XComGameState_BattleData BD )
{
	local XComGameStateHistory				History;
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameState_HeadquartersAlien	AlienHQ;
	local XComGameState_MissionSite			MissionState;
	local GeneratedMissionData				MissionData;
	local XComGameState_BattleData			BattleData;
	local XComTacticalMissionManager		TacticalMissionManager;
	local X2SelectedMissionData				EmptyMissionData;
	local XComGameState_GameTime			TimeState;
	local X2MissionTemplate					MissionTemplate;
	local X2MissionTemplateManager			MissionTemplateManager;
	local String							MissionBriefing;
	local XComGameState_Unit				NewUnitState;
	local XComGameState_Item				ItemReference;
	local StateObjectReference				StateRef;

	History = `XCOMHISTORY;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	MissionTemplateManager = class'X2MissionTemplateManager'.static.GetMissionTemplateManager();

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', GetMission().ObjectID));
	MissionData = XComHQ.GetGeneratedMissionData(XComHQ.MissionRef.ObjectID);


	//NewGameState.AddStateObject(MissionState);
	//NewGameState.AddStateObject(XComHQ);

	MissionState.m_strEnemyUnknown$=" ";
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	if(MissionState.SelectedMissionData == EmptyMissionData)
	{
		MissionState.CacheSelectedMissionData(AlienHQ.GetForceLevel(), MissionState.GetMissionDifficulty());
	}

	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	if(BD==none) BattleData = XComGameState_BattleData(NewGameState.CreateStateObject(class'XComGameState_BattleData'));
	else	BattleData=BD;
	//NewGameState.AddStateObject(BattleData);
	BattleData.m_iMissionID = MissionState.ObjectID;
	BattleData.m_strOpName = MissionData.BattleOpName;
	BattleData.LocalTime = TimeState.CurrentTime;	
	foreach XComHQ.Squad(StateRef)
	{
		NewUnitState=XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit',StateRef.ObjectID));
		NewGameState.AddStateObject(NewUnitState);		
		NewUnitState.SetControllingPlayer(BattleData.PlayerTurnOrder[0]);
		if(GetSoldierController(StateRef))
			NewUnitState.SetBaseMaxStat(eStat_FlightFuel,10);
		`log("UNIT AT TOTAL SQUAD"@NewUnitState.ObjectID @NewUnitState.GetFullName());

		foreach NewUnitState.InventoryItems(StateRef)
		{
			ItemReference = XComGameState_Item(NewGameState.CreateStateObject(Class'XComGameState_Item',StateRef.ObjectID));
			NewGameState.AddStateObject(ItemReference);	
		}
		`log("Adding unit to StartState");
	}
	MissionTemplate = MissionTemplateManager.FindMissionTemplate(MissionData.Mission.MissionName);
	if (MissionTemplate != none)
	{
		MissionBriefing = MissionTemplate.Briefing;
	}
	else
	{
		MissionBriefing  = "NO LOCALIZED BRIEFING TEXT!";
	}
	BattleData.m_iMissionType = TacticalMissionManager.arrMissions.Find('sType', MissionData.Mission.sType);
	BattleData.m_bIsFirstMission = false;
	BattleData.iLevelSeed = MissionData.LevelSeed;
	BattleData.m_strDesc    = MissionBriefing;
	BattleData.m_strOpName  = MissionData.BattleOpName;
	BattleData.MapData.PlotMapName = MissionData.Plot.MapName;
	BattleData.MapData.Biome = MissionData.Biome.strType;	
	BattleData.m_iMissionID = XComHQ.MissionRef.ObjectID;
	BattleData.bUseFirstStartTurnSeed = false;
//	BattleData.GameSettings = XComOnlineGameSettings(class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game'));

	// Force Level
	BattleData.SetForceLevel( AlienHQ.GetForceLevel() );

	// Alert Level
	BattleData.SetAlertLevel(MissionState.GetMissionDifficulty());
	BattleData.m_strLocation = MissionState.GetLocationDescription();
	TacticalMissionManager.ForceMission = MissionData.Mission;
	TacticalMissionManager.MissionQuestItemTemplate = MissionData.MissionQuestItemTemplate;
	BattleData.m_strMapCommand = "open"@BattleData.MapData.PlotMapName$"?game=Dragonpunk_CoOp.XComCoOpTacticalGame";	
}

function bool GetSoldierController(StateObjectReference UnitRef)
{
	local bool FoundAtServer,FoundAtClient,Found;
	local StateObjectReference Temp;
	foreach TotalSquad(Temp)
	{
		if(Temp.ObjectID==UnitRef.ObjectID)
		{
			Found=true;
			break;
		}
	}
	foreach ServerSquad(Temp)
	{
		if(Temp.ObjectID==UnitRef.ObjectID)
		{
			FoundAtServer=true;
			break;
		}
	}
	foreach ClientSquad(Temp)
	{
		if(Temp.ObjectID==UnitRef.ObjectID)
		{
			FoundAtClient=true;
			break;
		}
	}
	
	if(!Found)
		`log("DIDNT FIND UNIT AT TOTAL SQUAD"@UnitRef.ObjectID);
	if(!(Found||FoundAtClient||FoundAtServer))
		`log("DIDNT FIND UNIT AT ANY SQUAD"@UnitRef.ObjectID);
	if(FoundAtClient&&FoundAtServer)
		`log("FOUND UNIT AT 2 SQUADS"@UnitRef.ObjectID);

	`log("FOUND UNIT Returning"@FoundAtClient @UnitRef.ObjectID);

	if(FoundAtServer&&!FoundAtClient)
	{
		`log("FOUND UNIT AT 1 SQUAD Returning"@FoundAtClient @UnitRef.ObjectID);
		return false;
	}
	else if(!FoundAtServer&&FoundAtClient)
	{
		`log("FOUND UNIT AT 1 SQUAD Returning"@FoundAtClient @UnitRef.ObjectID);
		return true;
	}
	return true;
	
}

function SetupMapData(XComGameState StrategyStartState, XComGameState TacticalStartState)
{
	local XComGameState_MissionSite			MPMission;
	local X2MissionSourceTemplate			MissionSource;
	local XComGameState_Reward				RewardState;
	local X2RewardTemplate					RewardTemplate;
	local X2StrategyElementTemplateManager	StratMgr;
	local array<XComGameState_WorldRegion>  arrRegions;
	local XComGameState_WorldRegion         RegionState;
	local string                            PlotType;
	local XComGameState_HeadquartersXCom	XComHQ;
	local string                            Biome;
	local XComParcelManager                 ParcelMgr;
	local array<PlotDefinition>             arrValidPlots;
	local array<PlotDefinition>             arrSelectedTypePlots;
	local PlotDefinition                    CheckPlot;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ParcelMgr = `PARCELMGR;

	PlotType = m_kMPShellManager.OnlineGame_GetMapPlotName();
	Biome = m_kMPShellManager.OnlineGame_GetMapBiomeName();
	`log(self $ "::" $ GetFuncName() @ `ShowVar(PlotType) @ `ShowVar(Biome),, 'uixcom_mp');

	// Setup the MissionRewards
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(StrategyStartState);
	RewardState.SetReward(,0);
	StrategyStartState.AddStateObject(RewardState);
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Setup the GeneratedMission
	MPMission = XComGameState_MissionSite(StrategyStartState.CreateStateObject(class'XComGameState_MissionSite'));
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_Multiplayer'));

	// Choose a random region
	foreach StrategyStartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		arrRegions.AddItem(RegionState);
	}
	RegionState = arrRegions[`SYNC_RAND_STATIC(arrRegions.Length)];

	// Build the mission
	MPMission = XComGameState_MissionSite(TacticalStartState.CreateStateObject(class'XComGameState_MissionSite',XComHQ.MissionRef.ObjectID));
	ParcelMgr.GetValidPlotsForMission(arrValidPlots, MPMission.GeneratedMission.Mission, Biome);
	if(PlotType == "")
	{
		MPMission.GeneratedMission.Plot = arrValidPlots[`SYNC_RAND_STATIC(arrValidPlots.Length)];
	}
	else
	{
		foreach arrValidPlots(CheckPlot)
		{
			if(CheckPlot.strType == PlotType)
				arrSelectedTypePlots.AddItem(CheckPlot);
		}

		MPMission.GeneratedMission.Plot = arrSelectedTypePlots[`SYNC_RAND_STATIC(arrSelectedTypePlots.Length)];
	}

	if(MPMission.GeneratedMission.Mission.sType == "")
	{
		`Redscreen("GetMissionDataForSourceReward() failed to generate a mission with: \n"
						$ " Source: " $ MissionSource.DataName $ "\n RewardType: " $ RewardState.GetMyTemplate().DisplayName);
	}

	if(Biome == "" && MPMission.GeneratedMission.Plot.ValidBiomes.Length > 0)
	{
		// This plot uses biomes but the user didn't select one, so pick one here
		Biome = MPMission.GeneratedMission.Plot.ValidBiomes[`SYNC_RAND(MPMission.GeneratedMission.Plot.ValidBiomes.Length)];
	}
	if(Biome != "")
	{
		MPMission.GeneratedMission.Biome = ParcelMgr.GetBiomeDefinition(Biome);
	}

	`assert(Biome == "" || MPMission.GeneratedMission.Plot.ValidBiomes.Find(Biome) != INDEX_NONE);

	// Add the mission to the start states
	StrategyStartState.AddStateObject(MPMission);
	MPMission = XComGameState_MissionSite(TacticalStartState.CreateStateObject(class'XComGameState_MissionSite', MPMission.ObjectID));
	TacticalStartState.AddStateObject(MPMission);

	CreateBD(TacticalStartState,m_BattleData);
	// Setup the Battle Data
	`log(`location @ `ShowVar(m_BattleData.MapData.PlotMapName, PlotMapName) @ `ShowVar(m_BattleData.MapData.Biome, Biome) @ `ShowVar(m_BattleData.m_strMapCommand, MapCommand),,'XCom_Online');
}

static function XComGameState CreateDefaultTacticalStartState_Coop(optional out XComGameState_BattleData CreatedBattleDataObject)
{
	local XComGameStateHistory History;
	local XComGameState StartState;
	local XComGameStateContext_TacticalGameRule TacticalStartContext;
	local XComGameState_BattleData BattleDataState;
	local XComGameState_Player XComPlayerState;
	local XComGameState_Player EnemyPlayerState;
	local XComGameState_Player CivilianPlayerState;
	local XComGameState_Cheats CheatState;

	History = `XCOMHISTORY;

	TacticalStartContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
	TacticalStartContext.GameRuleType = eGameRule_TacticalGameStart;
	StartState = History.CreateNewGameState(false, TacticalStartContext);

	BattleDataState = XComGameState_BattleData(StartState.CreateStateObject(class'XComGameState_BattleData'));
	BattleDataState.BizAnalyticsMissionID = `FXSLIVE.GetGUID( );
	BattleDataState = XComGameState_BattleData(StartState.AddStateObject(BattleDataState));
	BattleDataState.PlayerTurnOrder.Length=0;

	XComPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_XCom);
	XComPlayerState.bPlayerReady = true; 
	BattleDataState.PlayerTurnOrder.AddItem(XComPlayerState.GetReference());
//	class'XGPlayer'.static.CreateVisualizer(XComPlayerState);
	StartState.AddStateObject(XComPlayerState);

	EnemyPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Alien);
	EnemyPlayerState.bPlayerReady = true; 
	BattleDataState.PlayerTurnOrder.AddItem(EnemyPlayerState.GetReference());
//	class'XGPlayer'.static.CreateVisualizer(EnemyPlayerState);
	StartState.AddStateObject(EnemyPlayerState);

	CivilianPlayerState = class'XComGameState_Player'.static.CreatePlayer(StartState, eTeam_Neutral);
	CivilianPlayerState.bPlayerReady = true; 
	BattleDataState.CivilianPlayerRef = CivilianPlayerState.GetReference();
//	class'XGPlayer'.static.CreateVisualizer(CivilianPlayerState);
	StartState.AddStateObject(CivilianPlayerState);

	CheatState = XComGameState_Cheats(StartState.CreateStateObject(class'XComGameState_Cheats'));
	StartState.AddStateObject(CheatState);

	CreatedBattleDataObject = BattleDataState;
	return StartState;
}