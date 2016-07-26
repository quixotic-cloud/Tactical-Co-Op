// This is an Unreal Script

class XComCo_Op_ConnectionSetup extends Actor;

var string m_strMatchOptions;
var name m_nMatchingSessionName;
var X2MPShellManager m_kMPShellManager;
var XComCo_Op_DelegatesHolder DelegatesHolder;

public function XComCo_Op_ConnectionSetup InitConnectionSetup(string MatchOptions,name SessionName)
{
	m_strMatchOptions=	MatchOptions;
	m_nMatchingSessionName= SessionName;
	m_kMPShellManager= XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).m_kMPShellManager;
	DelegatesHolder=Spawn(class'XComCo_Op_DelegatesHolder');
	DelegatesHolder.m_strMatchOptions=MatchOptions;
	DelegatesHolder.m_nMatchingSessionName=SessionName;
	DelegatesHolder.m_kMPShellManager=m_kMPShellManager;
	DelegatesHolder.MPAddLobbyDelegates();	

	return self;
}
function OSSCreateCoOpOnlineGame(optional name SessionName)
{
	local OnlineGameSettings kGameSettings;
	if(string(m_nMatchingSessionName)!=string(SessionName) && string(SessionName)!="")
	{
		m_nMatchingSessionName=SessionName;
		DelegatesHolder.m_nMatchingSessionName=SessionName;	
	}
	m_kMPShellManager.OnlineGame_SetAutomatch(false);
	kGameSettings = CreateGameSettings();
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.AddCreateOnlineGameCompleteDelegate(OSSOnCreateCoOpGameComplete);	
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.CreateOnlineGame( LocalPlayer(PlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).Player).ControllerId, m_nMatchingSessionName, kGameSettings );
	
}
function bool StartNetworkGame(name SessionName, optional string ResolvedURL="")
{
	local URL OnlineURL;
	local string sError, ServerURL, ServerPort;
	local int FindIndex;
	local XComGameStateNetworkManager NetManager;
	local bool bSuccess;

	bSuccess = true;

	//OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).PublishSteamServer();
	//OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).RefreshPublishLobbySettings();
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

function PublishLobbyServer()
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
	`log("Player Joined:" $ Address $ ", URL=" $ RequestURL, true, 'Team Dragonpunk Co Op');
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
	//StartNetworkGame(m_nMatchingSessionName);
	OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).AddCreateLobbyCompleteDelegate(DelegatesHolder.OnCreateLobbyComplete);
	OnlineGameInterfaceXCom(class'GameEngine'.static.GetOnlineSubsystem().GameInterface).CreateLobby(2, XLV_Public);
	//set the input state back to normal
	XComShellInput(XComPlayerController(XComShellPresentationLayer(UISquadSelect(`Screenstack.GetScreen(class'UISquadSelect')).Movie.Pres).Owner).PlayerInput).PopState();
}

