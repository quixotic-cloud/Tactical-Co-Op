// This is an Unreal Script
                           
class X2_Actor_InviteButtonManager extends Actor;

var array<UIButton> AllInviteButtons;
var array<UITextContainer>	AllInviteText;
var float			TimeCounter;
var string m_strMatchOptions;
var name m_nMatchingSessionName;
var X2MPShellManager m_kMPShellManager;

function SetAllElements(array<UIButton> Buttons,array<UITextContainer> AllText)
{
	AllInviteButtons=Buttons;
	AllInviteText=AllText;
}
simulated event Destroyed ()
{
	AllInviteButtons.Length=0;	
	AllInviteText.Length=0;	
}
event Tick(float deltaTime)
{
	local UISquadSelect MySSS;
	local int i,Count;
	local UIButton MyInvite,MySelect;
	MySSS=UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect'));
	if(MySSS!=none)
	{
		Count=MySSS.m_kSlotList.ItemCount;
		TimeCounter+=1;
		//`log("Tried Changing Size");
		if(TimeCounter%5==4)
		{
			for(i=0;i<Count;i++)
			{
				MyInvite=none;
				MySelect=none;
				if(UISquadSelect_ListItem(MySSS.m_kSlotList.GetItem(i)).GetUnitRef().ObjectId>0 || UISquadSelect_ListItem(MySSS.m_kSlotList.GetItem(i)).bDisabled)
				{	
					//MySSS.m_kSlotList.GetItem(i).SetAlpha(0.75);
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer')).Hide();
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer')).Hide();
					MySelect=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer'));
					MyInvite=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer'));
					UITextContainer(MySelect.GetChildAt(0)).Hide();
					UITextContainer(MyInvite.GetChildAt(0)).Hide();
				}
				else
				{
					//MySSS.m_kSlotList.GetItem(i).SetAlpha(0);
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer')).Show();
					UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer')).Show();
					MySelect=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('SelectPlayer'));
					MyInvite=UIButton(MySSS.m_kSlotList.GetItem(i).GetChild('InvitePlayer'));
					UITextContainer(MySelect.GetChildAt(0)).Show();
					UITextContainer(MyInvite.GetChildAt(0)).Show();
				}
			}
			TimeCounter=0;
		}
	}
}
function MPAddLobbyDelegates()
{
	local OnlineGameInterfaceXCom GameInterface;

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

}

function MPClearLobbyDelegates()
{
	local OnlineGameInterfaceXCom GameInterface;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.ClearJoinLobbyCompleteDelegate(OnJoinLobbyComplete);
	GameInterface.ClearLobbySettingsUpdateDelegate(OnLobbySettingsUpdate);
	GameInterface.ClearLobbyMemberSettingsUpdateDelegate(OnLobbyMemberSettingsUpdate);
	GameInterface.ClearLobbyMemberStatusUpdateDelegate(OnLobbyMemberStatusUpdate);
	GameInterface.ClearLobbyReceiveMessageDelegate(OnLobbyReceiveMessage);
	GameInterface.ClearLobbyReceiveBinaryDataDelegate(OnLobbyReceiveBinaryData);
	GameInterface.ClearLobbyJoinGameDelegate(OnLobbyJoinGame);
	GameInterface.ClearGameInviteAcceptedDelegate(0,OnGameInviteAccepted);

}

function OnJoinLobbyComplete(bool bWasSuccessful, const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, UniqueNetId LobbyUID, string Error)
{
	local string LobbyUIDString;
	LobbyUIDString = class'GameEngine'.static.GetOnlineSubsystem().UniqueNetIdToHexString( LobbyUID );
	`log(`location @ `ShowVar(bWasSuccessful) @ `ShowVar(LobbyIndex) @ `ShowVar(LobbyUIDString) @ `ShowVar(Error),,'XCom_Online');
}

function OnLobbySettingsUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex)
{
	`log(`location @ `ShowVar(LobbyIndex),,'XCom_Online');
}

function OnLobbyMemberSettingsUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex),,'XCom_Online');
}

function OnLobbyMemberStatusUpdate(const out array<OnlineGameInterfaceXCom_ActiveLobbyInfo> LobbyList, int LobbyIndex, int MemberIndex, int InstigatorIndex, string Status)
{
	`log(`location @ `ShowVar(LobbyIndex) @ `ShowVar(MemberIndex) @ `ShowVar(InstigatorIndex) @ `ShowVar(Status),,'XCom_Online');
	if( LobbyList.Length >= 2 )
	{
		MPCreateLobbyServer();
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


function OSSCreateCoOpOnlineGame(name SessionName)
{
	local OnlineGameSettings kGameSettings;

	m_kMPShellManager= XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).m_kMPShellManager;
	m_kMPShellManager.OnlineGame_SetAutomatch(false);
	kGameSettings = CreateGameSettings();
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.AddCreateOnlineGameCompleteDelegate(OSSOnCreateCoOpGameComplete);	
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.CreateOnlineGame( LocalPlayer(PlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).Player).ControllerId, SessionName, kGameSettings );
}
function bool StartNetworkGame(name SessionName, optional string ResolvedURL="")
{
	local URL OnlineURL;
	local string sError, ServerURL, ServerPort;
	local int FindIndex;
	local XComGameStateNetworkManager NetManager;
	local bool bSuccess;

	bSuccess = true;
	MPAddLobbyDelegates();	
	//OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).AddCreateLobbyCompleteDelegate(OnCreateLobbyComplete);
	OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).CreateLobby(2, XLV_Public);
	OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).PublishSteamServer();
	OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).RefreshPublishLobbySettings();
	OnlineURL.Map = `Maps.SelectShellMap();
	OnlineURL.Op.AddItem("Game=XComGame.XComShell");

	m_nMatchingSessionName = SessionName;
	m_strMatchOptions = BuildURL(OnlineURL);
	
	OnlineURL.Op.AddItem("steamsockets");
	NetManager = `XCOMNETMANAGER;
	if (ResolvedURL == "")
	{
		`log(`location @ "Creating Network Server to host the Online Game.",,'XCom_Online');
		NetManager.CreateServer(OnlineURL, sError);
		if (sError == "")
		{
			OnNetworkCreateGame();
		}
		else
		{
			`warn(`location @ "Unable to Create the Online Game!" @ `ShowVar(SessionName) @ `ShowVar(ResolvedURL) @ `ShowVar(sError),,'XCom_Online');
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

		`log(`location @ "Creating Network Client to join the Online Game at '"$ServerURL$"' on port '"$ServerPort$"'.",,'XCom_Online');
		NetManager.AddPlayerJoinedDelegate(OnPlayerJoined); // Wait until connected fully to the server before loading the map.
		NetManager.CreateClient(OnlineURL, sError);
		if (sError != "")
		{
			NetManager.ClearPlayerJoinedDelegate(OnPlayerJoined);
			`warn(`location @ "Unable to Create the Online Game!" @ `ShowVar(SessionName) @ `ShowVar(ResolvedURL) @ `ShowVar(sError),,'XCom_Online');
			bSuccess = false;
		}
		else
		{
			`log(`location @ "Setting Timer: "$ 30 $"s for OnSteamClientTimer",,'XCom_Online');
			SetTimer(30, false, nameof(OnSteamClientTimer));
		}
	}
	return bSuccess;
}

function MPCreateLobbyServer()
{
	local OnlineGameInterfaceXCom GameInterface;

	GameInterface = OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface);
	GameInterface.PublishSteamServer();
}
function OnNetworkCreateGame()
{
	`log("Loading online game: Session=" $ m_nMatchingSessionName $ ", URL=" $ m_strMatchOptions, true, 'XCom_Online');
	XComPlayerController(Owner).ClientTravel(m_strMatchOptions, TRAVEL_Absolute);
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
	OnNetworkCreateGame();
}

function OnSteamClientTimer()
{
	local XComGameStateNetworkManager NetManager;
	local bool bAttemptSuccessful;
	// Attempt to establish a connection to the Steam Server ...
	NetManager = `XCOMNETMANAGER;
	bAttemptSuccessful = NetManager.ForceConnectionAttempt();
	`log(`location @ "Timer Called: OnSteamClientTimer -" @ `ShowVar(bAttemptSuccessful),,'XCom_Online');
	if( !bAttemptSuccessful )
	{
		// Unable to send additional attempts, clear the timer.
		//ClearTimer(nameof(OnSteamClientTimer));
	}
}

function XComOnlineGameSettings CreateGameSettings()
{
	local XComOnlineGameSettings kGameSettings;
	//local XComOnlineGameSettingsDeathmatchRanked kRankedDeathmatchSettings;
	local XComOnlineGameSettingsDeathmatchUnranked kUnrankedDeathmatchSettings;


	// probably don't need skill rating for unranked but we'll clear it anyway -tsmith 
	kUnrankedDeathmatchSettings = new class'XComOnlineGameSettingsDeathmatchUnranked';
	kGameSettings = kUnrankedDeathmatchSettings;
	kGameSettings.SetIsRanked(false);
	kGameSettings.SetNetworkType(eMPNetworkType_Public);
	kGameSettings.SetGameType(eMPGameType_Deathmatch);
	kGameSettings.SetTurnTimeSeconds(3600);
	kGameSettings.SetMaxSquadCost(152423072016); 
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

	return kGameSettings;
}

function OSSOnCreateCoOpGameComplete(name SessionName,bool bWasSuccessful)
{
	m_nMatchingSessionName = '';
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearCreateOnlineGameCompleteDelegate(OSSOnCreateCoOpGameComplete);

	if(bWasSuccessful)
	{
		//block all input, by this point we are committed to the travel
		XComShellInput(XComPlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).PlayerInput).PushState('BlockingInput');

		m_nMatchingSessionName = SessionName;
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
	XComShellInput(XComPlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).PlayerInput).ClearAllRepeatTimers();
	StartNetworkGame(m_nMatchingSessionName);
	
	//set the input state back to normal
	XComShellInput(XComPlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).PlayerInput).PopState();
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
				SquadSelectScreen=(`SCREENSTACK.Screens[0].Spawn(Class'UISquadSelect',none));
				`SCREENSTACK.Push(SquadSelectScreen);
				`log("Pushing SquadSelectUI to screen stack",true,'Team Dragonpunk Co Op');
			}
			else
			{
				`log("Already in Squad Select UI",true,'Team Dragonpunk Co Op');
			}
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