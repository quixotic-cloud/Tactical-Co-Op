class XComShellPresentationLayer extends XComPresentationLayerBase
	config(UI);


// The amount of time we allow a progress dialog without a "cancel" button to remain on-screen
const UNCANCELLABLE_PROGRESS_DIALOGUE_TIMEOUT = 10;

var XComShell m_kXComShell;
var X2MPShellManager    m_kMPShellManager;

//UI Screens 
var           UISaveExplanationScreen   m_kSaveExplanationScreen;
var protected UIMultiplayerPlayerStats  m_kMultiplayerPlayerStats;
var protected UIMPShell_MainMenu        m_kMPMainMenuScreen;


// MP setup variables -tsmith 
var int                                 m_iMPTurnTimeSeconds;
var int                                 m_iMPMaxSquadCost;
var EMPGameType                         m_eMPGameType;
var EMPNetworkType                      m_eMPNetworkType;
var bool                                m_bMPIsRanked;
var name                                m_nmMPMapName;
var bool                                m_bCreatingOnlineGame;
var XComOnlineGameSearch                m_kOnlineGameSearch;
var bool                                m_bOnlineGameSearchInProgress;
var protected bool                        m_bCanStartOnlineGameSearch;
var protected bool                        m_bOnlineGameSearchAborted;
var protected bool                        m_bOnlineGameSearchCooldown; // true when we're waiting to enable online searches
var OnlineGameSearchResult              m_kAutomatchGameSearchResult;
var protected int                         m_iNumAutomatchSearchAttempts;
var  int                                m_iPlayerSkillRating;
var localized string                    m_strOnlineRankedAutomatchFailed_Title;
var localized string                    m_strOnlineRankedAutomatchFailed_Text;
var localized string                    m_strOnlineRankedAutomatchFailed_ButtonText;
var localized string                    m_strOnlineUnrankedAutomatchFailed_Title;
var localized string                    m_strOnlineUnrankedAutomatchFailed_Text;
var localized string                    m_strOnlineUnrankedAutomatchFailed_ButtonText;
var localized string                    m_strOnlineReadRankedStatsFailed_Title;
var localized string                    m_strOnlineReadRankedStatsFailed_Text;
var localized string                    m_strOnlineReadRankedStatsFailed_ButtonText;
var localized string                    m_strOnlineReadRankedStats_Text;
var localized string                    m_strOnlineSearchForRankedAutomatch_Title;
var localized string                    m_strOnlineSearchForRankedAutomatch_Text;
var localized string                    m_strOnlineSearchForUnrankedAutomatch_Title;
var localized string                    m_strOnlineSearchForUnrankedAutomatch_Text;
var localized string                    m_strOnlineCancelCreateOnlineGame_Title;
var localized string					m_strOnlineCancelCreateLANGame_Title;
var localized string					m_strOnlineCancelCreateSystemLinkGame_Title;
var localized string                    m_strOnlineCancelCreateOnlineGame_Text;
var localized string                    m_strOnlineCancelCreateOnlineGame_ButtonText;
var localized string                    m_strSelectSaveDeviceForEditSquadPrompt;
var string                              m_strMatchOptions;
var name                                m_nMatchingSessionName;

var XComOnlineStatsReadDeathmatchRanked m_kRankedDeathmatchStatsRead;
var protectedwrite bool                   m_bRankedAutomatchStatsReadInProgress;
var protectedwrite bool                   m_bRankedAutomatchStatsReadSuccessful;
var protectedwrite bool                   m_bRankedAutomatchStatsReadCanceled;
var privatewrite bool                   m_bHadNetworkConnectionAtInit;
var privatewrite bool                   m_bHadOnlineConnectionAtInit;

var config float                        m_InitialSteamClientConnectTimer;

var delegate<OnSaveExplanationScreenComplete> m_dOnSaveExplanationScreenComplete;

delegate Callback();
// Callbacks when the user action is performed
delegate delActionAccept_MiniLoadoutEditor( XComGameState GameState, XComGameState_Unit GameStateUnit );
delegate delActionCancel_MiniLoadoutEditor();

// Callback whenever the explanation screen is closed
delegate OnSaveExplanationScreenComplete();

// OnlineSubystem delegates -tsmith 
delegate m_dOnFindOnlineGamesComplete(bool bWasSuccessful);


//----------------------------------------------------------------------------
// Initialization
//

simulated function Init()
{
	`log("XComShellPresentationLayer.Init()",,'uixcom');
	
	//Ask for an early read of settings on PC only.
	if( !WorldInfo.IsConsoleBuild() )
	{
		`ONLINEEVENTMGR.ReadProfileSettings();

		if (class'Engine'.static.IsSteamBigPicture())
		{
			`XPROFILESETTINGS.Data.ActivateMouse(false);
		}
	}

	m_kMPShellManager = Spawn(class'X2MPShellManager', self);
	m_kMPShellManager.Init(XComPlayerController(Owner));

	m_bHadNetworkConnectionAtInit = OSSCheckNetworkConnectivity(false);
	m_bHadOnlineConnectionAtInit = OSSCheckOnlineConnectivity(false);

	super.Init();
}

// Called from InterfaceMgr when it's ready to rock..
simulated function InitUIScreens()
{
	`log("??? XComShellPresentationLayer.InitUIScreens()",,'uixcom');

	// Load the common screens.
	super.InitUIScreens();
	
	ScreenStack.Show();
	UIWorldMessages();
	
	m_bPresLayerReady = true;

	if(!IsA('XComMPLobbyPresentationLayer') && !IsA('X2MPLobbyPresentationLayer'))
	{
		if (`ONLINEEVENTMGR.ShouldStartBootInviteProcess())
		{// We have a boot invite or an accepted invite, make sure we're logged in as the correct local user and then shuttle to the MP main menu to process the invite.
			`log(`location @ "Starting boot invite shell login", true, 'XCom_Online');
			if (Class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.HasLinkConnection())
			{
				`ONLINEEVENTMGR.StartGameBootInviteProcess();

				// Login if the player has not already
				if (!`ONLINEEVENTMGR.bHasProfileSettings)
				{
					`ONLINEEVENTMGR.AddBeginShellLoginDelegate(OnShellLoginComplete);
					`ONLINEEVENTMGR.BeginShellLogin(`ONLINEEVENTMGR.InviteUserIndex);
				}
				else
				{
					OnShellLoginComplete(true);
				}
			}
			else
			{
				TravelToNextScreen();
				`ONLINEEVENTMGR.InviteFailed(SystemMessage_BootInviteFailed);
			}
		}		
		else
		{
			if (`ONLINEEVENTMGR.HasAcceptedInvites())
			{
				if (`ONLINEEVENTMGR.InviteUserIndex != `ONLINEEVENTMGR.LocalUserIndex)
				{// The "active" controller has switched, relogin via the shell procedures ...
					`ONLINEEVENTMGR.AddBeginShellLoginDelegate(OnShellLoginComplete);
					`ONLINEEVENTMGR.BeginShellLogin(`ONLINEEVENTMGR.InviteUserIndex);
				}
				else if (!`ONLINEEVENTMGR.bHasProfileSettings)
				{
					`ONLINEEVENTMGR.AddBeginShellLoginDelegate(OnShellLoginComplete);
					`ONLINEEVENTMGR.BeginShellLogin(`ONLINEEVENTMGR.InviteUserIndex);
				}
				else
				{
					OnShellLoginComplete(true);
				}
			}
			else
			{// Continue to the Start Screen
				`ONLINEEVENTMGR.SetBootInviteChecked(true);
				TravelToNextScreen();
			}
		}
	}

	Init3DDisplay();
}

simulated function TravelToNextScreen()
{
	local bool bShuttleToMPMainMenu, bShuttleToMPInviteLoadout;
	bShuttleToMPMainMenu = `ONLINEEVENTMGR.GetShuttleToMPMainMenu();
	bShuttleToMPInviteLoadout = `ONLINEEVENTMGR.GetShuttleToMPInviteLoadout();
	`log(`location @ `ShowVar(IsA('X2MPLobbyPresentationLayer')) @ `ShowVar(bShuttleToMPMainMenu) @ `ShowVar(bShuttleToMPInviteLoadout), true, 'XCom_Online');
	// HACK: @UI, this state can't be pushed when its a Lobby because Lobby calls super.init (this function) and then tries to push its own MP state but this call jacks it up. -tsmith 
	if( !IsA('X2MPLobbyPresentationLayer') )
	{
        if( WorldInfo.Game.IsA('XComMPShell') )
		{
			self.UIMPShell_MainMenu();
		}
		else if( bShuttleToMPInviteLoadout )
		{
			ShuttleToMPInviteLoadoutMenu();
		}
		else if( bShuttleToMPMainMenu )
		{
			ShuttleToMPMainMenu();
		}
		else if( WorldInfo.IsConsoleBuild() )
		{
			UIStartScreenState();
		}
		else
		{
			EnterMainMenu();
		}
	}
	else
	{
		if( bShuttleToMPInviteLoadout )
		{
			ShuttleToMPInviteLoadoutMenu();
		}
	}
}

simulated function OnShellLoginComplete(bool bWasSuccessful)
{
	local bool bTravelNecessary;
	local XComOnlineEventMgr EventMgr;
	`log(`location @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	bTravelNecessary = true;
	EventMgr = `ONLINEEVENTMGR;
	EventMgr.ClearBeginShellLoginDelegate(OnShellLoginComplete);
	if (bWasSuccessful)
	{
		if(EventMgr.ShouldStartBootInviteProcess())
		{
			EventMgr.RefreshLoginStatus();
			OSSCheckNetworkConnectivity(false);
			OSSCheckOnlineConnectivity(false);
			OSSCheckOnlinePlayPermissions(false);
			if(EventMgr.bHasLogin && 
			   m_kMPShellManager.m_bPassedNetworkConnectivityCheck &&
			   m_kMPShellManager.m_bPassedOnlineConnectivityCheck)
			{
				EventMgr.GameBootInviteAccept();
				bTravelNecessary = false;
			}
			else
			{
				EventMgr.InviteFailed(SystemMessage_BootInviteFailed);
			}
		}
		if(bTravelNecessary)
		{
			if(WorldInfo.IsConsoleBuild())
			{//console builds go to the autosave screen on shell login.
				UISaveExplanationScreenState();
			}
			else
			{//PC build goes to the main menu.
				EventMgr.SetBootInviteChecked(true);
				TravelToNextScreen();
			}
		}
	}
	else
	{
		if(EventMgr.IsCurrentlyTriggeringBootInvite())
		{
			EventMgr.InviteFailed(SystemMessage_BootInviteFailed);
		}
		else
		{
			EventMgr.InviteFailed(SystemMessage_InviteSystemError);
		}
		TravelToNextScreen();
	}
}

simulated function GPUAutoDetectTimer()
{
	`XENGINE.RunGPUAutoDetect(false, none);
}

/** Selects and enters the appropriate shell menu state */
simulated function EnterMainMenu()
{
//`if(`isdefined(FINAL_RELEASE))
	SetTimer(0.5, false, 'GPUAutoDetectTimer');
//`endif

	// ------------------

	// THIS MUST ALSO CHECK RELEASE FOR SHIP! -bsteiner
	if( `XENGINE.bReviewFlagged )
		UIFinalShellScreen();
	else
		UIShellScreen();
}

function LinkStatusChange(bool bIsConnected)
{
	`log(`location @ `ShowVar(bIsConnected), true, 'XCom_Online');
	// if the MP shell isnt up then we just display a warning dialog. -tsmith
	if(m_kMPShellManager == none || !m_kMPShellManager.m_bActive)
	{
		if(!bIsConnected)
		{
			UIRaiseDialog(m_kMPShellManager.GetOnlineNoNetworkConnectionDialogBoxData());
		}
	}
	else
	{
		m_kMPShellManager.LinkStatusChange(bIsConnected);
	}
	
}

function ConnectionStatusChange(EOnlineServerConnectionStatus ConnectionStatus)
{
	`log(`location @ `ShowVar(ConnectionStatus),, 'XCom_Online');
	if(m_kMPShellManager == none || !m_kMPShellManager.m_bActive)
	{
		switch(ConnectionStatus)
		{
		case OSCS_ConnectionDropped:
		case OSCS_NoNetworkConnection:
		case OSCS_NotConnected:
			UIRaiseDialog(m_kMPShellManager.GetOnlineNoNetworkConnectionDialogBoxData());
			break;
		}
	}
	else
	{
		m_kMPShellManager.ConnectionStatusChange(ConnectionStatus);
	}
}

simulated private function ShuttleToMPMainMenu()
{
	`log(`location, true, 'XCom_Online');
	ClearUIToHUD();

	UIStartScreen(ScreenStack.GetScreen(class'UIStartScreen')).Hide();	

	UIFinalShellScreen(); 
	UIFinalShell(ScreenStack.GetScreen(class'UIFinalShell')).Hide();

	StartMPShellState();
	`ONLINEEVENTMGR.SetShuttleToMPMainMenu(false);
}

simulated private function ShuttleToMPInviteLoadoutMenu()
{
	`log(`location, true, 'XCom_Online');

	`ONLINEEVENTMGR.SetShuttleToMPMainMenu(false);
	if( m_kMPMainMenuScreen == none )
	{
		UIMPShell_MainMenu();
	}
	// Already in the MP Shell State, load into the correct UI from the Shell
	m_kMPMainMenuScreen.OpenInviteLoadout();
}

simulated function ClearUIToHUD(optional bool bInstant = true)
{
	ScreenStack.PopUntilClass(class'UIShell');
}

simulated event Destroyed()
{
	local OnlineGameInterface GameInterface;
	super.Destroyed();

	Cleanup();

	UnsubscribeFromOnCleanupWorld();

	GameInterface = class'GameEngine'.static.GetOnlineSubsystem().GameInterface;
	if(m_kOnlineGameSearch != none)
	{
		GameInterface.FreeSearchResults(m_kOnlineGameSearch);
	}
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	InitConnectivityHandlers();
	SubscribeToOnCleanupWorld();
	`log(`location @ "Subscribed to OnCleanupWorld!", true, 'XCom_Online');
}

private function InitConnectivityHandlers()
{
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.AddLinkStatusChangeDelegate(LinkStatusChange);
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.AddConnectionStatusChangeDelegate(ConnectionStatusChange);
}

//----------------------------------------------------------------------------


//----------------------------------------------------------------------------
// Destruction
//

/**
* Called when the world is being cleaned up. Allows the actor to free any dynamic content it has created.
*/
simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	Cleanup();
}

private simulated function Cleanup()
{
	local OnlineSubsystem kOnlineSub;
	local OnlineGameInterface kGameInterface;
	local OnlineStatsInterface kStatsInterface;
	local OnlinePlayerInterface kPlayerInterface;
	local XComGameStateNetworkManager NetManager;

	// Cleanup Network Manager Delegates
	NetManager = `XCOMNETMANAGER;
	NetManager.ClearPlayerJoinedDelegate(OnPlayerJoined);

	CleanupConnectivityHandlers();

	// Cleanup Online Subsystem Delegates - it may cause race condition crashes otherwise.
	kOnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	kGameInterface = kOnlineSub.GameInterface;
	if (kGameInterface != none)
	{
		`log(`location @ "Cleaning up GameInterface delegates ...", true, 'XCom_Online');
		kGameInterface.ClearCreateOnlineGameCompleteDelegate(OSSOnCreateUnrankedGameComplete);
		kGameInterface.ClearCreateOnlineGameCompleteDelegate(OSSOnCreateRankedGameComplete);

		kGameInterface.ClearDestroyOnlineGameCompleteDelegate(OSSOnDestroyOnlineGameForJoinAutomatchGame);
		kGameInterface.ClearDestroyOnlineGameCompleteDelegate(OSSOnDestroyOnlineGameForJoinAutomatchGameFailed);

		kGameInterface.ClearJoinOnlineGameCompleteDelegate(OSSOnJoinAutomatchComplete);
		kGameInterface.ClearJoinOnlineGameCompleteDelegate(OSSOnJoinOnlineGameCompleteDelegate);

		kGameInterface.ClearFindOnlineGamesCompleteDelegate(OSSOnFindAutomatchComplete);
		kGameInterface.ClearFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCallback);
		kGameInterface.ClearFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);

		kGameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);
	}
	else
	{
		`warn(`location @ "Unable to find the Online Subystem GameInterface! Delegates will not be cleaned up properly and could lead to crashes!");
	}

	kStatsInterface = kOnlineSub.StatsInterface;
	if (kStatsInterface != none)
	{
		`log(`location @ "Cleaning up StatsInterface delegates ...", true, 'XCom_Online');
		kStatsInterface.ClearReadOnlineStatsCompleteDelegate(OSSOnRequestRankedDeathmatchStatsCompleteLaunchAutomatch);
	}
	else
	{
		`warn(`location @ "Unable to find the Online Subystem StatsInterface! Delegates will not be cleaned up properly and could lead to crashes!");
	}

	kPlayerInterface = kOnlineSub.PlayerInterface;
	if (kPlayerInterface != none)
	{
		`log(`location @ "Cleaning up PlayerInterface delegates ...", true, 'XCom_Online');
		kPlayerInterface.ClearLoginUICompleteDelegate(OnLoginUIComplete);
	}
	else
	{
		`warn(`location @ "Unable to find the Online Subystem PlayerInterface! Delegates will not be cleaned up properly and could lead to crashes!");
	}

	`ONLINEEVENTMGR.ClearBeginShellLoginDelegate(OnShellLoginComplete);

	// Cleanup stored delegates
	Callback = none;
	delActionAccept_MiniLoadoutEditor = none;
	delActionCancel_MiniLoadoutEditor = none;

	m_dOnFindOnlineGamesComplete = none;
}

protected function CleanupConnectivityHandlers()
{
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.ClearLinkStatusChangeDelegate(LinkStatusChange);
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.ClearConnectionStatusChangeDelegate(ConnectionStatusChange);
}

//----------------------------------------------------------------------------

simulated function Init3DUIScreens()
{
	// Disabled this since it's just debug and not yet final, 9/10/2015 bsteiner
	UIShellScreen3D();
}

simulated function UIShellScreen() 
{
	if(m_kNavHelpScreen == none)
	{
		m_kNavHelpScreen = Spawn(class'UIShell_NavHelpScreen', self);
		ScreenStack.Push(m_kNavHelpScreen);
	}
	ScreenStack.Push(Spawn(class'UIShell', self));
}

simulated function UIShellScreen3D()
{
	local UIScreen TestScreen;

	if( ScreenStack.GetScreen(class'UIShell3D') == none )
	{
		TestScreen = Spawn(class'UIShell3D', self);
		TestScreen.InitScreen(XComPlayerController(Owner), Get3DMovie());
		Get3DMovie().LoadScreen(TestScreen);
	}

	Get3DMovie().ShowDisplay('UIShellBlueprint');
}

simulated function UIFinalShellScreen()
{
	if(m_kNavHelpScreen == none)
	{
		m_kNavHelpScreen = Spawn(class'UIShell_NavHelpScreen', self);
		ScreenStack.Push(m_kNavHelpScreen);
	}
	ScreenStack.Push(  Spawn( class'UIFinalShell', self ) );
}

simulated function UIStartScreenState() 
{
	ScreenStack.Push( Spawn( class'UIStartScreen', self ) );
}

simulated function UIDynamicDebugScreen() 
{
	ScreenStack.Push( Spawn(class'UIDynamicDebugScreen', self) );
}

simulated function UIGraphicsOptionsDebugScreen()
{
	local UIGraphicsOptionsDebugScreen kScreen;

	kScreen = Spawn(class'UIGraphicsOptionsDebugScreen', self);
	ScreenStack.Push(kScreen);
}

simulated function UISaveExplanationScreenStateEx(delegate<OnSaveExplanationScreenComplete> dOnSaveExplanationScreenComplete)
{
	m_dOnSaveExplanationScreenComplete = dOnSaveExplanationScreenComplete;
	PushState('State_SaveExplanationScreen');
}
simulated function UISaveExplanationScreenState() 
{
	ScreenStack.Push( spawn( class'UISaveExplanationScreen', self ));
}

simulated function UIStrategyShell()
{
	if(ScreenStack.IsNotInStack(class'UIShellStrategy'))
		ScreenStack.Push(Spawn(class'UIShellStrategy', self));
}

simulated function UIMultiplayerShell() 
{
	local OnlineSubsystem kOnlineSub;


	if(!OSSCheckNetworkConnectivity())
		return;

	if(!OSSCheckOnlineConnectivity(false))
	{
		if(WorldInfo.IsConsoleBuild(CONSOLE_PS3))
		{
			kOnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
			kOnlineSub.PlayerInterface.AddLoginUICompleteDelegate(OnLoginUIComplete);

			// Attempt to login to the online system
			if (!`ONLINEEVENTMGR.ShellLoginShowLoginUI())
			{
				kOnlineSub.PlayerInterface.ClearLoginUICompleteDelegate(OnLoginUIComplete);
				if(!OSSCheckOnlineConnectivity()) // Retest connection and show the problem connection dialog if necessary
					return;
			}
			return;
		}
		else
		{
			StartMPShellState();
		}
	}

	if(!OSSCheckOnlinePlayPermissions())
		return;

	if(!OSSCheckOnlineChatPermissions())
		return;

	StartMPShellState();
}

simulated function OnLoginUIComplete(bool bSuccess)
{
	local OnlineSubsystem kOnlineSub;
	kOnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	kOnlineSub.PlayerInterface.ClearLoginUICompleteDelegate(OnLoginUIComplete);

	`log(`location @ `ShowVar(bSuccess));
	if (bSuccess)
	{
		UIMultiplayerShell(); // Attempt another check of the system
	}
	else
	{
		OSSCheckOnlineConnectivity(); // Retest connection and show the problem connection dialog if necessary
	}
}

simulated function StartMPShellState() 
{
    if( !WorldInfo.Game.IsA('XComMPShell') )
	{
		ConsoleCommand("open XComShell_Multiplayer.umap?Game=XComGame.XComMPShell");
	}
	else
	{
		TravelToNextScreen();
	}
}

simulated function UIMPShell_MainMenu()
{
	m_kMPShellManager.Activate();

	if(m_kNavHelpScreen == none)
	{
		m_kNavHelpScreen = Spawn(class'UIShell_NavHelpScreen', self);
		ScreenStack.Push(m_kNavHelpScreen);
	}

	m_kMPMainMenuScreen = Spawn( class'UIMPShell_MainMenu', self );
	ScreenStack.Push( m_kMPMainMenuScreen );
}


simulated function UIControllerMap() 
{
	if(ScreenStack.GetScreen(class'UIControllerMap') == none)
	{
		TempScreen = spawn( class'UIControllerMap', self );
		UIControllerMap(TempScreen).layout = eLayout_Battlescape; 	
		ScreenStack.Push( TempScreen );
	}
}


// @TODO UI: do we do this for the new UI? if so we need a screen thats the analog of UIMultiplayerPlayerStats
// Show player statistics
simulated function UIPlayerStats( ) 
{ 
	//m_kMPInterface.SetCurrentPlayer( XComPlayerReplicationInfo( XComShellController(Owner).PlayerReplicationInfo ) );
	//TempScreen = spawn( class'UIMultiplayerPlayerStats', self );
	//UIMultiplayerPlayerStats(TempScreen).m_kMPInterface = m_kMPInterface; 	
	//UIMultiplayerPlayerStats(TempScreen).m_bShowBackButton = false; 		
	//ScreenStack.Push( TempScreen );
}


//-------------------------------------------------------------------
reliable client function UICredits( bool isGameOver )
{
	super.UICredits( isGameOver );
}

//--------------------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                             ONLINE SUBSYSTEM 
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

//----------------------------------------------------------------------------
// ONLINE CHECKS
function bool OSSCheckNetworkConnectivity(bool bDisplayDialog=true)
{
	local TDialogueBoxData kDialogBoxData;
	local OnlineSubsystem OnlineSub;

	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if( !OnlineSub.SystemInterface.HasLinkConnection() )
	{
		if(bDisplayDialog)
		{
			kDialogBoxData = m_kMPShellManager.GetOnlineNoNetworkConnectionDialogBoxData();
			kDialogBoxData.fnCallback = UIActionCallback_OnlineNoNetworkConnectionDialogCallback;

			UIRaiseDialog(kDialogBoxData);

			`ONLINEEVENTMGR.bWarnedOfOnlineStatus = true;
		}
		m_kMPShellManager.m_bPassedNetworkConnectivityCheck = false;
	}
	else
	{
		m_kMPShellManager.m_bPassedNetworkConnectivityCheck = true;
	}
	return m_kMPShellManager.m_bPassedNetworkConnectivityCheck;
}

function TDialogueBoxData GetOnlineNoNetworkConnectionDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;

	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_XBOX_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_XBOX_Text;
	}
	else if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
	{
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_PS3_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_PS3_Text;
	}
	else
	{	
		kDialogBoxData.strTitle = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_Default_Title;
		kDialogBoxData.strText = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_Default_Text;
	}
	kDialogBoxData.strAccept = class'X2MPData_Shell'.default.m_strOnlineNoNetworkConnectionDialog_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.eType = eDialog_Warning;

	return kDialogBoxData;
}

function bool OSSCheckOnlineConnectivity(bool bDisplayDialog=true)
{
	local TDialogueBoxData kDialogBoxData;
	local UniqueNetId ZeroID;
	local bool bDoOnlineStatusCheck;
	local XComOnlineEventMgr OnlineEventMgr;
	local XComShellController ShellController;

	bDoOnlineStatusCheck = true;

	// this check is necessary for iterating on one machine. we disable steam therefore 
	// we don't need to do online check because we are just using LAN -tsmith 
`if(`notdefined(FINAL_RELEASE))
	if(!WorldInfo.IsConsoleBuild() && !class'GameEngine'.static.IsSteamworksInitialized())
	{
		bDoOnlineStatusCheck = false;
	}
`endif

	if(bDoOnlineStatusCheck)
	{
		OnlineEventMgr = `ONLINEEVENTMGR;
		ShellController = XComShellController(Owner);
		if (OnlineEventMgr.OnlineSub.PlayerInterface.GetLoginStatus(OnlineEventMgr.LocalUserIndex) != LS_LoggedIn ||
		    ShellController.PlayerReplicationInfo == none ||
		    ShellController.PlayerReplicationInfo.UniqueId == ZeroID ||
		    OnlineEventMgr.OnlineSub.PlayerInterface.IsLocalLogin(OnlineEventMgr.LocalUserIndex))
		{
			if(bDisplayDialog)
			{
				`warn("Trouble logging in to Online service, please try logging in again" $
					", PRI=" $ XComShellController(Owner).PlayerReplicationInfo $
					", IsLocalLogin=" $ OnlineEventMgr.OnlineSub.PlayerInterface.IsLocalLogin(OnlineEventMgr.LocalUserIndex) $
					", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(XComShellController(Owner).PlayerReplicationInfo.UniqueId) );

				kDialogBoxData = m_kMPShellManager.GetOnlineLoginFailedDialogData();
				kDialogBoxData.fnCallback = UIActionCallback_OnlineLoginFailedDialogCallback;

				UIRaiseDialog(kDialogBoxData);
			}

			m_kMPShellManager.m_bPassedOnlineConnectivityCheck = false;
			`ONLINEEVENTMGR.m_bPassedOnlineConnectivityCheck = m_kMPShellManager.m_bPassedOnlineConnectivityCheck;
			return false;
		}
		else if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) && OnlineEventMgr.OnlineSub.PlayerInterface.IsGuestLogin(`ONLINEEVENTMGR.LocalUserIndex) )
		{
			if(bDisplayDialog)
			{
				`warn("Guest logins cannot access multiplayer" $
					", PRI=" $ XComShellController(Owner).PlayerReplicationInfo $
					", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(XComShellController(Owner).PlayerReplicationInfo.UniqueId) );

				kDialogBoxData = m_kMPShellManager.GetOnlineLoginFailedDialogData();
				kDialogBoxData.fnCallback = UIActionCallback_OnlineLoginFailedDialogCallback;

				UIRaiseDialog(kDialogBoxData);
			}
			m_kMPShellManager.m_bPassedOnlineConnectivityCheck = false;
			`ONLINEEVENTMGR.m_bPassedOnlineConnectivityCheck = m_kMPShellManager.m_bPassedOnlineConnectivityCheck;
			return false;
		}
	}
	m_kMPShellManager.m_bPassedOnlineConnectivityCheck = true;
	`ONLINEEVENTMGR.m_bPassedOnlineConnectivityCheck = m_kMPShellManager.m_bPassedOnlineConnectivityCheck;
	return true;
}

function bool OSSCheckOnlinePlayPermissions(bool bDisplayDialog=true)
{
	local TDialogueBoxData kDialogBoxData;
	local OnlineSubsystem OnlineSub;

	// TCR # 086: User is able to access all Multiplayer areas with a gamer profile that has multiplayer privileges set to "blocked". -ttalley
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSub.PlayerInterface.CanPlayOnline(`ONLINEEVENTMGR.LocalUserIndex) == FPL_Disabled)
	{
		if(bDisplayDialog)
		{
			`warn("This account has invalid permissions to access Online Content" $
				", PRI=" $ XComShellController(Owner).PlayerReplicationInfo $
				", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(XComShellController(Owner).PlayerReplicationInfo.UniqueId) $
				", LocalUserNum=" $ `ONLINEEVENTMGR.LocalUserIndex $
				", LoginStatus=" $ OnlineSub.PlayerInterface.GetLoginStatus(`ONLINEEVENTMGR.LocalUserIndex) $
				", CanPlay=" $ OnlineSub.PlayerInterface.CanPlayOnline(`ONLINEEVENTMGR.LocalUserIndex));

			kDialogBoxData = m_kMPShellManager.GetOnlinePlayPermissionDialogBoxData();
			kDialogBoxData.fnCallback = UIActionCallback_OnlinePlayPermissionFailedDialogCallback;

			UIRaiseDialog(kDialogBoxData);
		}
		m_kMPShellManager.m_bPassedOnlinePlayPermissionsCheck = false;
	}
	else
	{
		m_kMPShellManager.m_bPassedOnlinePlayPermissionsCheck = true;
	}
	`ONLINEEVENTMGR.m_bPassedOnlinePlayPermissionsCheck = m_kMPShellManager.m_bPassedOnlinePlayPermissionsCheck;
	return m_kMPShellManager.m_bPassedOnlinePlayPermissionsCheck;
}

function bool OSSCheckOnlineChatPermissions(bool bDisplayDialog=true)
{
	local TDialogueBoxData kDialogBoxData;
	local OnlineSubsystem OnlineSub;

	`log(`location @ `ShowVar(bDisplayDialog));
	OnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if (OnlineSub.PlayerInterface.CanCommunicate(`ONLINEEVENTMGR.LocalUserIndex) == FPL_Disabled)
	{
		if(bDisplayDialog)
		{
			`warn("This account has invalid permissions to communicate" $
				", PRI=" $ XComShellController(Owner).PlayerReplicationInfo $
				", UniqueNetId=" $ class'OnlineSubsystem'.static.UniqueNetIdToString(XComShellController(Owner).PlayerReplicationInfo.UniqueId) $
				", LocalUserNum=" $ `ONLINEEVENTMGR.LocalUserIndex $
				", LoginStatus=" $ OnlineSub.PlayerInterface.GetLoginStatus(`ONLINEEVENTMGR.LocalUserIndex) $
				", CanCommunicate=" $ OnlineSub.PlayerInterface.CanCommunicate(`ONLINEEVENTMGR.LocalUserIndex));

			kDialogBoxData = m_kMPShellManager.GetOnlineChatPermissionDialogBoxData();
			kDialogBoxData.fnCallback = UIActionCallback_OnlineChatPermissionFailedDialogCallback;

			UIRaiseDialog(kDialogBoxData);
		}
		m_kMPShellManager.m_bPassedOnlineChatPermissionsCheck = false;
	}
	else
	{
		m_kMPShellManager.m_bPassedOnlineChatPermissionsCheck = true;
	}
	return m_kMPShellManager.m_bPassedOnlineChatPermissionsCheck;
}

function UIActionCallback_OnlineNoNetworkConnectionDialogCallback( eUIAction eAction ) {
	// Go into MP state anyways, options will be grayed out if player is not connected
	StartMPShellState();
}
function UIActionCallback_OnlineLoginFailedDialogCallback( eUIAction eAction ) {
	// Go into MP state anyways, options will be grayed out if player is not connected
	StartMPShellState();
}
function UIActionCallback_OnlinePlayPermissionFailedDialogCallback( eUIAction eAction ) {
	// Go into MP state anyways, options will be grayed out if player is not connected
	StartMPShellState();
}
function UIActionCallback_OnlineChatPermissionFailedDialogCallback( eUIAction eAction ) {
	// Go into MP state anyways, options will be grayed out if player is not connected
	StartMPShellState();
}

function TDialogueBoxData CreateRankedStatsReadFailedDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;
	kDialogBoxData.eType = eDialog_Warning;
	kDialogBoxData.strTitle = m_strOnlineReadRankedStatsFailed_Title;
	kDialogBoxData.strText = m_strOnlineReadRankedStatsFailed_Text;
	kDialogBoxData.strAccept = m_strOnlineReadRankedStatsFailed_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.fnCallback = UIActionCallback_ProcessSystemErrorMessages;
	return kDialogBoxData;
}

function TDialogueBoxData CreateRankedAutomatchFailedDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;
	kDialogBoxData.eType = eDialog_Warning;
	kDialogBoxData.strTitle = m_strOnlineRankedAutomatchFailed_Title;
	kDialogBoxData.strText = m_strOnlineRankedAutomatchFailed_Text;
	kDialogBoxData.strAccept = m_strOnlineRankedAutomatchFailed_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.fnCallback = UIActionCallback_ProcessSystemErrorMessages;
	return kDialogBoxData;
}

function TDialogueBoxData CreateUnrankedAutomatchFailedDialogBoxData()
{
	local TDialogueBoxData kDialogBoxData;
	kDialogBoxData.eType = eDialog_Warning;
	kDialogBoxData.strTitle = m_strOnlineUnrankedAutomatchFailed_Title;
	kDialogBoxData.strText = m_strOnlineUnrankedAutomatchFailed_Text;
	kDialogBoxData.strAccept = m_strOnlineUnrankedAutomatchFailed_ButtonText;
	kDialogBoxData.strCancel = "";
	kDialogBoxData.fnCallback = UIActionCallback_ProcessSystemErrorMessages;
	return kDialogBoxData;
}

// Process any system error messages that might have gotten added after we throw up one of the error messages above.
function UIActionCallback_ProcessSystemErrorMessages( eUIAction eAction ) 
{
	if(!m_bBlockSystemMessageDisplay)
		ProcessSystemMessages();
}

//----------------------------------------------------------------------------

function bool OSSCreateUnrankedGame(bool bAutomatch)
{
	m_kMPShellManager.OnlineGame_SetIsRanked(false);
	return OSSCreateGame(OSSOnCreateUnrankedGameComplete, bAutomatch);
}

/** Callback for when the game is finish being created. */
function OSSOnCreateUnrankedGameComplete(name SessionName,bool bWasSuccessful)
{
	m_bCreatingOnlineGame = false;
	m_nMatchingSessionName = '';
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearCreateOnlineGameCompleteDelegate(OSSOnCreateUnrankedGameComplete);

	if( m_bOnlineGameSearchAborted )
	{
		if( bWasSuccessful )
		{
			class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame(SessionName);
		}
		m_bOnlineGameSearchAborted = false;
		return;
	}

	if(bWasSuccessful)
	{
		//block all input, by this point we are committed to the travel
		XComShellInput(XComPlayerController(Owner).PlayerInput).PushState('BlockingInput');

		m_nMatchingSessionName = SessionName;
		// Set timer to allow dialog data to be presented
		SetTimer(1.0, false, 'OnCreateUnrankedGameTimerComplete');
		`log("Successfully created online game: Session=" $ SessionName $ ", Server=" @ "TODO: implement, i used to come from the GameReplicationInfo: WorldInfo.GRI.ServerName", true, 'XCom_Online');
	}
	else
	{
		`log("Failed to create online game: Session=" $ SessionName, true, 'XCom_Online');
	}
}

function OnCreateUnrankedGameTimerComplete()
{
	//clear any repeat timers to prevent the multiplayer match from exiting prematurely during load
	ClearInput();
	StartNetworkGame(m_nMatchingSessionName);
	
	//set the input state back to normal
	XComShellInput(XComPlayerController(Owner).PlayerInput).PopState();
}

function bool OSSCreateRankedGame(bool bAutomatch)
{
	return OSSCreateGame(OSSOnCreateRankedGameComplete, bAutomatch);
}

function OSSOnCreateRankedGameComplete(name SessionName,bool bWasSuccessful)
{
	m_bCreatingOnlineGame = false;
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearCreateOnlineGameCompleteDelegate(OSSOnCreateRankedGameComplete);

	if( m_bOnlineGameSearchAborted )
	{
		if( bWasSuccessful )
		{
			class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame(SessionName);
		}
		m_bOnlineGameSearchAborted = false;
		return;
	}

	if(bWasSuccessful)
	{
		StartNetworkGame(SessionName);
	}
	else
	{
		`log("Failed to create online game: Session=" $ SessionName, true, 'XCom_Online');
	}
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

function bool StartNetworkGame(name SessionName, optional string ResolvedURL="")
{
	local URL OnlineURL;
	local string sError, ServerURL, ServerPort;
	local int FindIndex;
	local OnlineGameSettings kGameSettings;
	local XComGameStateNetworkManager NetManager;
	local bool bSuccess;

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
			`log(`location @ "Setting Timer: "$ m_InitialSteamClientConnectTimer $"s for OnSteamClientTimer",,'XCom_Online');
			SetTimer(m_InitialSteamClientConnectTimer, false, nameof(OnSteamClientTimer));
		}
	}
	return bSuccess;
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

function OnNetworkCreateGame()
{
	`log("Loading online game: Session=" $ m_nMatchingSessionName $ ", URL=" $ m_strMatchOptions, true, 'XCom_Online');
	XComPlayerController(Owner).ClientTravel(m_strMatchOptions, TRAVEL_Absolute);
}

function OnPlayerJoined(string RequestURL, string Address, const UniqueNetId UniqueId, bool bSupportsAuth)
{
	local XComGameStateNetworkManager NetManager;
	NetManager = `XCOMNETMANAGER;
	NetManager.ClearPlayerJoinedDelegate(OnPlayerJoined);
	OnNetworkCreateGame();
}

function bool OSSCreateGame(delegate<OnlineGameInterface.OnCreateOnlineGameComplete> dOnCreateOnlineGameComplete, bool bAutomatch)
{
    local OnlineSubsystem kOnlineSub;
    local XComOnlineGameSettings kGameSettings;
    local TProgressDialogData kWaitForTravelDialog;
	local bool bSuccess;

	// don't create a game if we are already creating, it blows things up. -tsmith 
	if(m_bCreatingOnlineGame)
		return false;

	m_kMPShellManager.OnlineGame_SetAutomatch(bAutomatch);
	kOnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	if(kOnlineSub != none)
	{
		kGameSettings = OSSCreateGameSettings(bAutomatch);
		kOnlineSub.GameInterface.AddCreateOnlineGameCompleteDelegate(dOnCreateOnlineGameComplete);
		if(kOnlineSub.GameInterface.CreateOnlineGame( LocalPlayer(PlayerController(Owner).Player).ControllerId, 'Game', kGameSettings ))
		{
			m_bCreatingOnlineGame = true;
			
			UICloseProgressDialog();

			//Set dialog title based on match type and system build
			if (kGameSettings.bIsLanMatch)
			{
				if (WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
				{
					kWaitForTravelDialog.strTitle = m_strOnlineCancelCreateSystemLinkGame_Title;
				}
				else
				{
					kWaitForTravelDialog.strTitle = m_strOnlineCancelCreateLANGame_Title;
				}
			}
			else
			{
				kWaitForTravelDialog.strTitle = m_strOnlineCancelCreateOnlineGame_Title;
			}
			kWaitForTravelDialog.strDescription = m_strOnlineCancelCreateOnlineGame_Text;
			if( WorldInfo.IsConsoleBuild() )
			{
				kWaitForTravelDialog.strAbortButtonText = m_strOnlineCancelCreateOnlineGame_ButtonText;
				kWaitForTravelDialog.fnCallback = OSSCreateOnlineGameAbortCallback;
			}
			else
			{
				kWaitForTravelDialog.strAbortButtonText = "";
			}

			UIProgressDialog(kWaitForTravelDialog);
			bSuccess = true;
			`log(`location @ `ShowVar(dOnCreateOnlineGameComplete) @ kGameSettings.ToString(), true, 'XCom_Online');
		}
		else
		{
			bSuccess = false;
			m_bCreatingOnlineGame = false;
			m_bOnlineGameSearchAborted = false;
			kOnlineSub.GameInterface.ClearCreateOnlineGameCompleteDelegate(dOnCreateOnlineGameComplete);
			`log(`location @ "call to start async CreateOnlineGame failed!", true, 'XCom_Online');
		}
	}
	else
	{
		bSuccess = false;
		`warn(`location @ "No online subsystem found!");
	}

	return bSuccess;
}

function OSSCreateOnlineGameAbortCallback()
{
	m_bOnlineGameSearchAborted = true;
	//ConsoleCommand("disconnect");
}

function XComOnlineGameSettings OSSCreateGameSettings(bool bAutomatch)
{
	local XComOnlineGameSettings kGameSettings;
	local XComOnlineGameSettingsDeathmatchRanked kRankedDeathmatchSettings;
	local XComOnlineGameSettingsDeathmatchUnranked kUnrankedDeathmatchSettings;

	if(m_kMPShellManager.OnlineGame_GetType() == eMPGameType_Deathmatch)
	{
		if(m_kMPShellManager.OnlineGame_GetIsRanked())
		{
			m_iPlayerSkillRating = XComPlayerReplicationInfo(XComPlayerController(Owner).PlayerReplicationInfo).m_iRankedDeathmatchSkillRating;
			kRankedDeathmatchSettings = new class'XComOnlineGameSettingsDeathmatchRanked';
			kRankedDeathmatchSettings.SetHostRankedRating(m_iPlayerSkillRating);

			`if(`notdefined(FINAL_RELEASE))
				if(!m_kMPShellManager.OnlineGame_GetAutomatch() && class'XComOnlineGameSettings'.default.DEBUG_bChangeRankedGameOptions)
				{
					kRankedDeathmatchSettings.SetTurnTimeSeconds(m_kMPShellManager.OnlineGame_GetTurnTimeSeconds()); 
					kRankedDeathmatchSettings.SetMaxSquadCost(m_kMPShellManager.OnlineGame_GetMaxSquadCost()); 
				}
			`endif


			kGameSettings = kRankedDeathmatchSettings;
		}
		else
		{
			// probably don't need skill rating for unranked but we'll clear it anyway -tsmith 
			m_iPlayerSkillRating = 0;
			kUnrankedDeathmatchSettings = new class'XComOnlineGameSettingsDeathmatchUnranked';
			kGameSettings = kUnrankedDeathmatchSettings;
			kGameSettings.SetIsRanked(m_kMPShellManager.OnlineGame_GetIsRanked());
			kGameSettings.SetNetworkType(m_kMPShellManager.OnlineGame_GetNetworkType());
			kGameSettings.SetGameType(m_kMPShellManager.OnlineGame_GetType());
			if(bAutomatch)
			{
				kGameSettings.SetTurnTimeSeconds(class'XComOnlineGameSettings'.default.QuickmatchTurnTimer); 
			}
			else
			{
				kGameSettings.SetTurnTimeSeconds(m_kMPShellManager.OnlineGame_GetTurnTimeSeconds()); 
			}
			kGameSettings.SetMaxSquadCost(m_kMPShellManager.OnlineGame_GetMaxSquadCost()); 
			kGameSettings.SetMapPlotTypeInt(m_kMPShellManager.OnlineGame_GetMapPlotInt());
			kGameSettings.SetMapBiomeTypeInt(m_kMPShellManager.OnlineGame_GetMapBiomeInt());
		

			// only public games can be LAN -tsmith 
			if(kGameSettings.GetNetworkType() == eMPNetworkType_Public)
			{
				kGameSettings.NumPublicConnections = 2;
				kGameSettings.NumPrivateConnections = 0;
			}
			else if(kGameSettings.GetNetworkType() == eMPNetworkType_Private)
			{
				kGameSettings.NumPublicConnections = 0;
				kGameSettings.NumPrivateConnections = 2;
			}
			else
			{
				// LAN match -tsmith 
				kGameSettings.NumPublicConnections = 2;
				kGameSettings.NumPrivateConnections = 0;
				kGameSettings.bIsLanMatch = true;
			}
		}
		kGameSettings.SetMPDataINIVersion(0);
		kGameSettings.SetByteCodeHash(class'Helpers'.static.NetGetVerifyPackageHashes());
		kGameSettings.SetIsAutomatch(bAutomatch);
		kGameSettings.SetInstalledDLCHash(class'Helpers'.static.NetGetInstalledMPFriendlyDLCHash());
		kGameSettings.SetInstalledModsHash(class'Helpers'.static.NetGetInstalledModsHash());
		kGameSettings.SetINIHash(class'Helpers'.static.NetGetMPINIHash());
		kGameSettings.SetIsDevConsoleEnabled(class'Helpers'.static.IsDevConsoleEnabled());
	}
	else
	{
		`warn(`location @ "Unsupported game type:" @ m_kMPShellManager.OnlineGame_GetIsRanked());
	}

	return kGameSettings;
}

function OSSAutomatchRanked()
{
	local TProgressDialogData kWaitForAutomatchDialog;

	`log(`location, true, 'XCom_Online');
	if(class'Helpers'.static.NetAllRankedGameDataValid())
	{
		m_kMPShellManager.OnlineGame_SetAutomatch(true);
		kWaitForAutomatchDialog.strTitle = m_strOnlineSearchForRankedAutomatch_Title;
		kWaitForAutomatchDialog.strDescription = m_strOnlineReadRankedStats_Text;
		kWaitForAutomatchDialog.fnCallback = OSSAutomatchRankedWaitDialogAbortCallback;
		UIProgressDialog(kWaitForAutomatchDialog);
		OSSRequestRankedStatsThenStartAutomatch();
	}
	else
	{
		`log("Modified game data detected. Ranked play not allowed.",, 'XCom_Online');
	}
}

private function bool OSSRequestRankedStatsThenStartAutomatch()
{
	local bool bSuccess;
	local array<UniqueNetId> arrStatReadPlayerIDs;
	local OnlineSubsystem kOnlineSub;

	bSuccess = true;

	if(!m_bRankedAutomatchStatsReadInProgress)
	{
		if(XComPlayerController(Owner) != none)
		{
			kOnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
			if(kOnlineSub != None && kOnlineSub.StatsInterface != None)
			{
				if(m_kRankedDeathmatchStatsRead != none)
				{
					kOnlineSub.StatsInterface.FreeStats(m_kRankedDeathmatchStatsRead);
				}
				m_kRankedDeathmatchStatsRead = new class'XComOnlineStatsReadDeathmatchRanked';
				m_kRankedDeathmatchStatsRead.bReadRawStatsIfNotInLeaderboard = true;
				m_kRankedDeathmatchStatsRead.m_bWritePRIDataToLastMatchInfo = true;
				arrStatReadPlayerIDs.AddItem(XComPlayerController(Owner).PlayerReplicationInfo.UniqueId);
				kOnlineSub.StatsInterface.AddReadOnlineStatsCompleteDelegate(OSSOnRequestRankedDeathmatchStatsCompleteLaunchAutomatch);
				if(!kOnlineSub.StatsInterface.ReadOnlineStats(arrStatReadPlayerIDs, m_kRankedDeathmatchStatsRead))
				{
					`warn(`location @ "Failed to start async task ReadOnlineStats");
					m_bRankedAutomatchStatsReadSuccessful = false;
					kOnlineSub.StatsInterface.ClearReadOnlineStatsCompleteDelegate(OSSOnRequestRankedDeathmatchStatsCompleteLaunchAutomatch);
					kOnlineSub.StatsInterface.FreeStats(m_kRankedDeathmatchStatsRead);
					m_kRankedDeathmatchStatsRead = none;
					bSuccess = false;
				}
				else
				{
					`log(`location @ "Reading stats...", true, 'XCom_Online');
					m_bRankedAutomatchStatsReadInProgress = true;
					m_bRankedAutomatchStatsReadCanceled = false;
				}
			}
			else
			{
				`warn(`location @ "Missing online subsystem components necessary to get stats. OnlineSub=" $ kOnlineSub $ 
					", StatsInterface=" $ ((kOnlineSub != none) ? ("" $ kOnlineSub.StatsInterface) : "None"));

				bSuccess = false;
			}
		}
		else
		{
			`warn(`location @ "No player controller set, cannot proceed");
			bSuccess = false;
		}
	}
	else
	{
		`log(`location @ "Cannot request a stats read while one is already in progress", true, 'XCom_Online');
		bSuccess = false;
	}

	if(!bSuccess)
	{
		// there is already a stats read in progress so it will set the success flag -tsmith
		if(!m_bRankedAutomatchStatsReadInProgress)
		{
			m_bRankedAutomatchStatsReadSuccessful = false;
			UICloseProgressDialog();
			UIRaiseDialog(CreateRankedStatsReadFailedDialogBoxData());
		}
	}

	return bSuccess;
}

private function OSSOnRequestRankedDeathmatchStatsCompleteLaunchAutomatch(bool bWasSuccessful)
{
	local OnlineSubsystem kOnlineSub;

	`log(`location @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	kOnlineSub = class'GameEngine'.static.GetOnlineSubsystem();
	kOnlineSub.StatsInterface.ClearReadOnlineStatsCompleteDelegate(OSSOnRequestRankedDeathmatchStatsCompleteLaunchAutomatch);
	m_bRankedAutomatchStatsReadSuccessful = bWasSuccessful;

	if(bWasSuccessful)
	{
		if(!m_bRankedAutomatchStatsReadCanceled)
		{
			m_kRankedDeathmatchStatsRead.UpdateToPRI(XComPlayerReplicationInfo(XComPlayerController(Owner).PlayerReplicationInfo));
			m_kProgressDialog.UpdateData(m_strOnlineSearchForRankedAutomatch_Title, m_strOnlineSearchForRankedAutomatch_Text);
			OSSFind(OSSCreateAutomatchOnlineGameSearch(), OSSOnFindAutomatchComplete);
		}
		else
		{
			UICloseProgressDialog();
		}
		`log(`location @ `ShowVar(bWasSuccessful) @ `ShowVar(m_bRankedAutomatchStatsReadCanceled) @ m_kRankedDeathmatchStatsRead.ToString_ForPlayer(XComPlayerController(Owner).PlayerReplicationInfo.PlayerName, XComPlayerController(Owner).PlayerReplicationInfo.UniqueId), true, 'XCom_Online');
	}
	else if(m_bRankedAutomatchStatsReadInProgress)
	{
		`warn(`location @ "Error reading stats unable, to create a ranked automatch game");
		UICloseProgressDialog();
		UIRaiseDialog(CreateRankedStatsReadFailedDialogBoxData());
	}
	kOnlineSub.StatsInterface.FreeStats(m_kRankedDeathmatchStatsRead);
	m_bRankedAutomatchStatsReadInProgress = false;
	m_bRankedAutomatchStatsReadCanceled = false;
}

function OSSAutomatchUnranked()
{
	local TProgressDialogData kWaitForAutomatchDialog;

	`log(`location, true, 'XCom_Online');
	m_kMPShellManager.OnlineGame_SetAutomatch(true);
	kWaitForAutomatchDialog.strTitle = m_strOnlineSearchForUnrankedAutomatch_Title;
	kWaitForAutomatchDialog.strDescription = m_strOnlineSearchForUnrankedAutomatch_Text;
	kWaitForAutomatchDialog.fnCallback = OSSAutomatchUnrankedWaitDialogAbortCallback;
	UIProgressDialog(kWaitForAutomatchDialog);
	OSSFind(OSSCreateAutomatchOnlineGameSearch(), OSSOnFindAutomatchComplete);
}

private function OSSAutomatchRankedWaitDialogAbortCallback() 
{
	local TProgressDialogData kProgressDialogData;

	kProgressDialogData.strTitle = class'X2MPData_Shell'.default.m_strMPCancelSearchProgressDialogTitle;
	kProgressDialogData.strDescription = class'X2MPData_Shell'.default.m_strMPCancelSearchProgressDialogText;
	kProgressDialogData.strAbortButtonText = ""; // Do not allow cancelling this operation
	kProgressDialogData.fnCallback = none;
	UIProgressDialog(kProgressDialogData);
	// HAX: Make sure if we don't complete the connection that we close the Progress dialog and cleanup any dangling delegates.
	SetTimer(UNCANCELLABLE_PROGRESS_DIALOGUE_TIMEOUT, false, nameof(CancellingProgressDialogTimeout));

	if(m_bRankedAutomatchStatsReadInProgress)
	{
		m_bRankedAutomatchStatsReadInProgress = false;
		m_bRankedAutomatchStatsReadCanceled = true;
	}
	else
	{
		OSSCancelFind();
	}
}

private function OSSAutomatchUnrankedWaitDialogAbortCallback() 
{
	local TProgressDialogData kProgressDialogData;

	kProgressDialogData.strTitle = class'X2MPData_Shell'.default.m_strMPCancelSearchProgressDialogTitle;
	kProgressDialogData.strDescription = class'X2MPData_Shell'.default.m_strMPCancelSearchProgressDialogText;
	kProgressDialogData.strAbortButtonText = ""; // Do not allow cancelling this operation
	kProgressDialogData.fnCallback = none;
	// HAX: Make sure if we don't complete the connection that we close the Progress dialog and cleanup any dangling delegates.
	SetTimer(UNCANCELLABLE_PROGRESS_DIALOGUE_TIMEOUT, false, nameof(CancellingProgressDialogTimeout));

	UIProgressDialog(kProgressDialogData);
	OSSCancelFind();
}

function OSSOnFindAutomatchComplete(bool bWasSuccessful)
{   
`if (`notdefined(FINAL_RELEASE))
	local int i;
	local XComOnlineGameSettings kGameSettings;
`endif

	`log(`location @ "-" @ `ShowVar(bWasSuccessful) , true, 'XCom_Online');

	if(!m_kOnlineGameSearch.bIsSearchInProgress)
	{
		m_bOnlineGameSearchInProgress = false;
		class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSOnFindAutomatchComplete);

		if( m_bOnlineGameSearchAborted )
		{
			m_iNumAutomatchSearchAttempts = 0;
			m_bOnlineGameSearchAborted = false;
			return;
		}

		if(bWasSuccessful)
		{
			// have we search the entire range and found nothing? -tsmith 
			if(m_kOnlineGameSearch.Results.Length > 0)
			{
`if (`notdefined(FINAL_RELEASE))
				`log("The following automatch games are available:", true, 'XCom_Online');
				for(i = 0; i < m_kOnlineGameSearch.Results.Length; i++)
				{
					kGameSettings = XComOnlineGameSettings(m_kOnlineGameSearch.Results[i].GameSettings); 
					
					`log("     " $ i $ ")" @ kGameSettings.OwningPlayerName @ kGameSettings.ToString(), true, 'XCom_Online');
				}
`endif


				if(m_kMPShellManager.OnlineGame_GetIsRanked())
				{
					m_kAutomatchGameSearchResult = OSSFindGameWithClosestSkillRating(m_kOnlineGameSearch.Results, m_iPlayerSkillRating); 
				}
				else
				{
					// TODO: rand for now, probably want to find closest match based on MP options if the online system backend queries don't handle that -tsmith 
					m_kAutomatchGameSearchResult = m_kOnlineGameSearch.Results[Rand(m_kOnlineGameSearch.Results.Length)];
				}
				
				`log(`location @ XComOnlineGameSettings(m_kAutomatchGameSearchResult.GameSettings).ToString(), true, 'XCom_Online');
				WriteLastMatchInfo(`ONLINEEVENTMGR.m_kMPLastMatchInfo);
				OSSJoin(m_kAutomatchGameSearchResult, OSSOnJoinAutomatchComplete, OSSOnDestroyOnlineGameForJoinAutomatchGame);
			}
			else
			{
				// TODO: timer before we find again
				if(m_iNumAutomatchSearchAttempts < OSSGetMaxAutomatchSearchAttemptsUntilCreateGame())
				{
					if(!OSSFind(OSSCreateAutomatchOnlineGameSearch(), OSSOnFindAutomatchComplete))
					{
						`log(`location @ "OSSFind failed, attempting to create our own...", true, 'XCom_Online');
						if(m_kMPShellManager.OnlineGame_GetIsRanked())
						{
							if(!OSSCreateRankedGame(true /* bAutomatch */))
								CleanupOnFindAutomatchCompleteFailed();
						}
						else
						{
							if(!OSSCreateUnrankedGame(true /* bAutomatch */))
								CleanupOnFindAutomatchCompleteFailed();
						}
					}
				}
				else
				{
					// TODO: should wait X seconds do another search, then after Y seconds if nothing found, create our own. -tsmith 
					`log(`location @ "No matches found, creating our own...", true, 'XCom_Online');
					if(m_kMPShellManager.OnlineGame_GetIsRanked())
					{
						if(!OSSCreateRankedGame(true /* bAutomatch */))
							CleanupOnFindAutomatchCompleteFailed();
					}
					else
					{
						if(!OSSCreateUnrankedGame(true /* bAutomatch */))
							CleanupOnFindAutomatchCompleteFailed();
					}
				}
			}
		}
	}

	if(!bWasSuccessful)
	{
		`log(`location @ "FindOnlineGames failed!:", true, 'XCom_Online');
		CleanupOnFindAutomatchCompleteFailed();
	}
}

private function CleanupOnFindAutomatchCompleteFailed()
{
	`log(`location @ `ShowVar(m_kMPShellManager.OnlineGame_GetIsRanked()), true, 'XCom_Online');

	//Bug 22750 - Destroy the online game, in case we were partially joined when CleanupOnFindAutomatchCompleteFailed() was called.
	//			  A partial join is possible on Steam if the host was quiting from the MP lobby just as the client was quick matching in.
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');

	UICloseProgressDialog();

	if(m_kMPShellManager.OnlineGame_GetIsRanked())
	{
		UIRaiseDialog(CreateRankedAutomatchFailedDialogBoxData());
	}
	else
	{
		UIRaiseDialog(CreateUnrankedAutomatchFailedDialogBoxData());
	}
	m_iNumAutomatchSearchAttempts = 0;
	m_bOnlineGameSearchAborted = false;
}

function XComOnlineGameSearch OSSCreateAutomatchOnlineGameSearch()
{
	local XComOnlineGameSearch kGameSearch;
	local int iMaxAutomatchSearchAttempts;
	local int iSearchRangeDelta;

	switch(m_kMPShellManager.OnlineGame_GetType())
	{
	case eMPGameType_Deathmatch:
		if(m_kMPShellManager.OnlineGame_GetIsRanked())
		{
			m_iNumAutomatchSearchAttempts++;
			iMaxAutomatchSearchAttempts = OSSGetMaxAutomatchSearchAttemptsUntilCreateGame();
			if(m_iNumAutomatchSearchAttempts < iMaxAutomatchSearchAttempts)
			{
				iSearchRangeDelta = class'XComOnlineGameSearchDeathmatchRanked'.default.m_iRankedSearchRatingDelta * m_iNumAutomatchSearchAttempts;
			}
			else
			{
				iSearchRangeDelta = class'XComOnlineGameSearchDeathmatchRanked'.default.m_iFinalRankedSearchRatingDelta;
			}
			m_iPlayerSkillRating = XComPlayerReplicationInfo(XComPlayerController(Owner).PlayerReplicationInfo).m_iRankedDeathmatchSkillRating;
			kGameSearch = new class'XComOnlineGameSearchDeathmatchRanked';
			XComOnlineGameSearchDeathmatchRanked(kGameSearch).SetRatingSearchRange(m_iPlayerSkillRating, iSearchRangeDelta); 
			`log(`location @ `ShowVar(m_iPlayerSkillRating) @ `ShowVar(m_iNumAutomatchSearchAttempts) @ `ShowVar(iMaxAutomatchSearchAttempts) @ `ShowVar(iSearchRangeDelta), true, 'XCom_Online');
		}
		else
		{
			kGameSearch = new class'XComOnlineGameSearchDeathmatchUnranked';
		}
		break;
	default:
		`log(`location @ "Deathmatch is the only game type currently supported", true, 'XCom_Online');
	}

	`log(`location @ `ShowVar(kGameSearch), true, 'XCom_Online');
	return kGameSearch;
}

function int OSSGetMaxAutomatchSearchAttemptsUntilCreateGame()
{
	local int iMaxAutomatchSearchAttempts;

	iMaxAutomatchSearchAttempts = -1;
	switch(m_kMPShellManager.OnlineGame_GetType())
	{
	case eMPGameType_Deathmatch:
		if(m_kMPShellManager.OnlineGame_GetIsRanked())
		{
			iMaxAutomatchSearchAttempts = class'XComOnlineGameSearchDeathmatchRanked'.default.m_iMaxAutomatchSearchesUntilCreateGame;
		}
		break;
	default:
		`log(`location @ "Invalid gametype or option used to determine max search attempts.", true, 'XCom_Online');
	}

	return iMaxAutomatchSearchAttempts;
}

function bool CanStartOnlineGameSearch()
{
	`log(`location @ `ShowVar(m_bCanStartOnlineGameSearch) @ `ShowVar(m_bOnlineGameSearchInProgress),,'XCom_Online');
	return m_bCanStartOnlineGameSearch && !m_bOnlineGameSearchInProgress;
}

function bool OSSFind(XComOnlineGameSearch kGameSearch, delegate<OnlineGameInterface.OnFindOnlineGamesComplete> dOnFindOnlineGamesComplete)
{
    local OnlineSubsystem kOSS;
	local bool bSuccess;

	if(kGameSearch == none)
	{
		`log(`location @ "Game search object is none! Aborting game search.", true, 'XCom_Online');
		return false;
	}

	`log(`location @ "GameSearch=" $ kGameSearch.ToString(),, 'XCom_Online');

	if(m_bOnlineGameSearchInProgress)
	{
		`log(`location @ "Game search already in progress" @ `ShowVar(m_kOnlineGameSearch) @ `ShowVar(kGameSearch) @ `ShowVar(dOnFindOnlineGamesComplete), true, 'XCom_Online');
		return false;
	}

	m_dOnFindOnlineGamesComplete = dOnFindOnlineGamesComplete;
	m_kOnlineGameSearch = kGameSearch;
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.FreeSearchResults(m_kOnlineGameSearch);
	m_kOnlineGameSearch.SetMPDataINIVersion(0);
	m_kOnlineGameSearch.SetByteCodeHash(class'Helpers'.static.NetGetVerifyPackageHashes());
	m_kOnlineGameSearch.SetInstalledModsHash(class'Helpers'.static.NetGetInstalledModsHash());
	m_kOnlineGameSearch.SetInstalledDLCHash(class'Helpers'.static.NetGetInstalledMPFriendlyDLCHash());
	m_kOnlineGameSearch.SetINIHash(class'Helpers'.static.NetGetMPINIHash());
	m_kOnlineGameSearch.SetNetworkType(m_kMPShellManager.OnlineGame_GetNetworkType());
	m_kOnlineGameSearch.SetIsDevConsoleEnabled(class'Helpers'.static.IsDevConsoleEnabled());

	`log(`location @ `ShowVar(m_kOnlineGameSearch) @ `ShowVar(dOnFindOnlineGamesComplete) , true, 'XCom_Online');

	// proper way to determine LAN query: from the network type in the setup screen -tsmith 
	if(m_kMPShellManager.OnlineGame_GetNetworkType() == eMPNetworkType_LAN && !m_kMPShellManager.OnlineGame_GetIsRanked())
	{
		m_kOnlineGameSearch.bIsLanQuery = true;
	}
	else
	{
		m_kOnlineGameSearch.bIsLanQuery = false;
	}

    kOSS = class'GameEngine'.static.GetOnlineSubsystem();
    kOSS.GameInterface.AddFindOnlineGamesCompleteDelegate(m_dOnFindOnlineGamesComplete);
    kOSS.GameInterface.AddFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCallback);

    if( kOSS.GameInterface.FindOnlineGames( LocalPlayer(PlayerController(Owner).Player).ControllerId, m_kOnlineGameSearch ) )
    {
		m_bOnlineGameSearchInProgress = true;
		m_bCanStartOnlineGameSearch = false;
		bSuccess = true;
        `log(`location @ "Searching for online games...", true, 'XCom_Online');
    }
    else
    {
		m_bOnlineGameSearchInProgress = false;
		`log(`location @ "Failed to begin search", true, 'XCom_Online');
		kOSS.GameInterface.ClearFindOnlineGamesCompleteDelegate(m_dOnFindOnlineGamesComplete);
		bSuccess = false;
    }

	return bSuccess;
}

function OnlineGameSearchResult OSSFindGameWithClosestSkillRating(const out array<OnlineGameSearchResult> arrGameSearchResults, int iSkillRating)
{
	local int i;
	local int iSkillDelta, iSmallestDelta;
	local OnlineGameSearchResult  kBestGame;

	iSmallestDelta = 999999999;
	for(i = 0; i < arrGameSearchResults.Length; i++)
	{
		iSkillDelta = Abs(XComOnlineGameSettings(arrGameSearchResults[i].GameSettings).GetHostRankedRating() - iSkillRating);
		`log(`location 
			@ `ShowVar(iSkillRating) 
			@ `ShowVar(iSkillDelta) 
			@ `ShowVar(iSmallestDelta) 
			@ XComOnlineGameSettings(arrGameSearchResults[i].GameSettings).ToString(), true, 'XCom_Online');
		if(iSkillDelta <= iSmallestDelta)
		{
			iSmallestDelta = iSkillDelta;
			kBestGame = arrGameSearchResults[i];
		}
	}

	return kBestGame;
}
	
function OSSOnJoinAutomatchComplete(name SessionName,bool bWasSuccessful)
{

	local OnlineGameInterface kGameInterface;
	local string sURL;

	`log(`location @ "-" @ `ShowVar(SessionName) $ ", " $ `ShowVar(bWasSuccessful) , true, 'XCom_Online');

	kGameInterface = class'GameEngine'.static.GetOnlineSubsystem().GameInterface;

	// HAX: Reset the uncancellable progress dialog timeout -ttalley
	ClearTimer(nameof(CleanupOnFindAutomatchCompleteFailed)); // Must clear, otherwise a slightly long join will pop-up an error message and fail cert! -ttalley
	SetTimer(UNCANCELLABLE_PROGRESS_DIALOGUE_TIMEOUT, false, nameof(CleanupOnFindAutomatchCompleteFailed));

	// Figure out if we have an online subsystem registered
	if (kGameInterface != None)
	{
		// Remove the delegate from the list
		kGameInterface.ClearJoinOnlineGameCompleteDelegate(OSSOnJoinAutomatchComplete);

		if (bWasSuccessful)
		{
			// Get the platform specific information
			if (kGameInterface.GetResolvedConnectString('Game',sURL))
			{
				// Call the game specific function to appending/changing the URL
				//sURL = "open" @ sURL;

				`log(`location @ "Join Game Successful, Traveling: "$sURL$"", true, 'XCom_Online');

				//ConsoleCommand(sURL);
				StartNetworkGame(SessionName, sURL);
			}
			else
			{
				`log(`location @ "failed to get resolved connection string, bailing out...", true, 'XCom_Online');
				CleanupOnFindAutomatchCompleteFailed();
			}
		}
		else
		{
			if(kGameInterface.GetGameSettings('Game') != none)
			{
				`log(`location @ "Join Game FAILED!!!! Destroying online game session 'Game' if it exists and then creating our own", true, 'XCom_Online');
				kGameInterface.AddDestroyOnlineGameCompleteDelegate(OSSOnDestroyOnlineGameForJoinAutomatchGameFailed);
				if(!kGameInterface.DestroyOnlineGame('Game'))
				{
					`log(`location @ "failed to create async task DestroyOnlineGame, bailing out...", true, 'XCom_Online');
					CleanupOnFindAutomatchCompleteFailed();
				}	
			}
			else
			{
				`log(`location @ "OSSJoinAutomatch failed, attempting to create our own...", true, 'XCom_Online');
				if(m_kMPShellManager.OnlineGame_GetIsRanked())
				{
					if(!OSSCreateRankedGame(false /* bAutomatch */))
					{
						`log(`location @ "OSSCreateRankedGame failed, bailing out...", true, 'XCom_Online');
						CleanupOnFindAutomatchCompleteFailed();
					}
				}
				else
				{
					if(!OSSCreateUnrankedGame(false /* bAutomatch */))
					{
						`log(`location @ "OSSCreateUnrankedGame failed, bailing out...", true, 'XCom_Online');
						CleanupOnFindAutomatchCompleteFailed();
					}
				}
			}
		}
	}
	else
	{
		`warn(`location @ "GameInterace none, major problems, bailing...");
		CleanupOnFindAutomatchCompleteFailed();
	}

	m_iNumAutomatchSearchAttempts = 0;
}

function OSSOnDestroyOnlineGameForJoinAutomatchGameFailed(name SessionName,bool bWasSuccessful)
{
	if(bWasSuccessful)
	{
		`log(`location @ "DestroyOnlineGame after automatch failed succeeded, attempting to create our own...", true, 'XCom_Online');
		if(m_kMPShellManager.OnlineGame_GetIsRanked())
		{
			if(!OSSCreateRankedGame(false /* bAutomatch */))
			{
				`log(`location @ "OSSCreateRankedGame failed, bailing out...", true, 'XCom_Online');
				CleanupOnFindAutomatchCompleteFailed();
			}
		}
		else
		{
			if(!OSSCreateUnrankedGame(false /* bAutomatch */))
			{
				`log(`location @ "OSSCreateUnrankedGame failed, bailing out...", true, 'XCom_Online');
				CleanupOnFindAutomatchCompleteFailed();
			}
		}
	}
	else
	{
		`log(`location @ "DestroyOnlineGame failed, bailing out...", true, 'XCom_Online');
		CleanupOnFindAutomatchCompleteFailed();
	}
	m_iNumAutomatchSearchAttempts = 0;
}

function OSSOnDestroyOnlineGameForJoinAutomatchGame(name SessionName,bool bWasSuccessful)
{
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearDestroyOnlineGameCompleteDelegate(OSSOnDestroyOnlineGameForJoinAutomatchGame);
	OSSJoin(m_kAutomatchGameSearchResult, OSSOnJoinAutomatchComplete, OSSOnDestroyOnlineGameForJoinAutomatchGame);
}

function OSSJoin(OnlineGameSearchResult kSearchResult, 
	delegate<OnlineGameInterface.OnJoinOnlineGameComplete> dOnJoinOnlineGameCompleteDelegate, 
	delegate<OnlineGameInterface.OnDestroyOnlineGameComplete> dOnDestroyOnlineGameForJoinCompleteDelegate)
{
	local XGParamTag kTag;
	local TProgressDialogData kProgressDialogData;
	local OnlineGameInterface GameInterface;

	GameInterface = class'GameEngine'.static.GetOnlineSubsystem().GameInterface;
	if(GameInterface.GetGameSettings('Game') == none)
	{
		GameInterface.AddJoinOnlineGameCompleteDelegate(dOnJoinOnlineGameCompleteDelegate);
		GameInterface.AddJoinOnlineGameCompleteDelegate(OSSOnJoinOnlineGameCompleteDelegate);
		if(GameInterface.JoinOnlineGame(LocalPlayer(PlayerController(Owner).Player).ControllerId, 'Game', kSearchResult))
		{
			`log(`location @ "Attempting to join " @ kSearchResult.GameSettings.OwningPlayerName, true, 'XCom_Online');

			kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

			`log(`location @ "- Connection successful, opening progress dialog." , true, 'XCom_Online');
			kProgressDialogData.strTitle = class'X2MPData_Shell'.default.m_strMPJoiningGameProgressDialogTitle;
			kTag.StrValue0 = kSearchResult.GameSettings.OwningPlayerName;
			kProgressDialogData.strDescription = `XEXPAND.ExpandString(class'X2MPData_Shell'.default.m_strMPJoiningGameProgressDialogText);
			UIProgressDialog(kProgressDialogData);

			// HAX: Make sure if we don't complete the connection that we close the Progress dialog and cleanup any dangling delegates.
			SetTimer(UNCANCELLABLE_PROGRESS_DIALOGUE_TIMEOUT, false, nameof(CleanupOnFindAutomatchCompleteFailed));
		}
		else
		{
			`log(`location @ "FAILED to start async JoinOnlineGame task: Tried to join" @ kSearchResult.GameSettings.OwningPlayerName $ "'s game", true, 'XCom_Online');
			GameInterface.ClearJoinOnlineGameCompleteDelegate(dOnJoinOnlineGameCompleteDelegate);
			//dOnJoinOnlineGameCompleteDelegate(SessionName, false); // Make sure that the join delegate is still called.
		}
	}
	else
	{
		`log(`location $ ": Session 'Game' already exists, tearing down and then joining...", true, 'XCom_Online');
		// need to clear our own game if we are going to join another game -tsmith 
		GameInterface.AddDestroyOnlineGameCompleteDelegate(dOnDestroyOnlineGameForJoinCompleteDelegate);
		if(!GameInterface.DestroyOnlineGame('Game'))
		{
			`log(`location $ ": Failed to start async task DestroyOnlineGame", true, 'XCom_Online');
			GameInterface.ClearDestroyOnlineGameCompleteDelegate(dOnDestroyOnlineGameForJoinCompleteDelegate);
			//dOnDestroyOnlineGameForJoinCompleteDelegate(SessionName, false); // Make sure that the destroy delegate is still called.
		}
	}
}

function OSSOnJoinOnlineGameCompleteDelegate(name SessionName,bool bWasSuccessful)
{
	local OnlineGameInterface GameInterface;

	GameInterface = class'GameEngine'.static.GetOnlineSubsystem().GameInterface;
	GameInterface.ClearJoinOnlineGameCompleteDelegate(OSSOnJoinOnlineGameCompleteDelegate);
	ClearTimer(nameof(CleanupOnFindAutomatchCompleteFailed));

	//The JoinOnlineGameComplete delegate indicates that the player has joined the game's lobby, not the actual game.
	//Console builds close the joining game dialog at this point because the actual game network connection opens effectively instantly.
	//However, on the PC, the Steamworks p2p network connection takes MUCH longer (several seconds) to open.  
	//So, for PC builds, we keep the progress dialog up.
	if(WorldInfo.IsConsoleBuild())
	{
		UICloseProgressDialog();
	}
}

function bool OSSCancelFind(optional delegate<OnlineGameInterface.OnCancelFindOnlineGamesComplete> OnCancelFindOnlineGamesCompleteDelegate)
{
	local OnlineSubsystem kOSS;

	kOSS = class'GameEngine'.static.GetOnlineSubsystem();

	m_kOnlineGameSearch = none;
	m_bOnlineGameSearchInProgress = false;

	`log(`location @ " - " $ `ShowVar(OnCancelFindOnlineGamesCompleteDelegate), true, 'XCom_Online');

	kOSS.GameInterface.ClearFindOnlineGamesCompleteDelegate(m_dOnFindOnlineGamesComplete);

	//Adding OnCancelFindOnlineGamesComplete delegates now because CancelFindOnlineGames()
	//can complete instantly.
	if(OnCancelFindOnlineGamesCompleteDelegate != none)
		kOSS.GameInterface.AddCancelFindOnlineGamesCompleteDelegate(OnCancelFindOnlineGamesCompleteDelegate);
	kOSS.GameInterface.AddCancelFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);	

	if(!kOSS.GameInterface.CancelFindOnlineGames())
	{
		`log(`location @ "Failed to start async task CancelFindOnlineGames", true, 'XCom_Online');	
		m_bOnlineGameSearchInProgress = true;

		//Remove our CancelFindOnlineGamesComplete Delegates from CancelFindOnlineGamesComplete event
		//and have them fire on FindOnlineGamesComplete instead.  
		//This is to proactively prevent the cancelling popup from getting stuck on.
		if(OnCancelFindOnlineGamesCompleteDelegate != none)
			kOSS.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OnCancelFindOnlineGamesCompleteDelegate);
		kOSS.GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);	

		if(OnCancelFindOnlineGamesCompleteDelegate != none)
			kOSS.GameInterface.AddFindOnlineGamesCompleteDelegate(OnCancelFindOnlineGamesCompleteDelegate);
		kOSS.GameInterface.AddFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);

		return false;
	}
	return true;
}

/**
 * Called when a FindOnlineGames async operation has completed
 */
private function OSSFindOnlineGamesCallback(bool bWasSuccessful)
{
	`log(`location @ "-" @ `ShowVar(bWasSuccessful) , true, 'XCom_Online');
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCallback);
	EnableOnlineGameSearches();
}

/**
 * Called when a FindOnlineGames async operation is canceled
 */
private function OSSFindOnlineGamesCanceledCallback(bool bCancelWasSuccessful)
{
	`log(`location @ "-" @ `ShowVar(bCancelWasSuccessful) , true, 'XCom_Online');
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);
	if( bCancelWasSuccessful )
	{
		UICloseProgressDialog();
		EnableOnlineGameSearches();
	}
}

private function CancellingProgressDialogTimeout()
{
	// Close the Cancelling dialog
	UICloseProgressDialog();

	// Clean up any "cancel" or complete delegates.
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCallback);
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.ClearCancelFindOnlineGamesCompleteDelegate(OSSFindOnlineGamesCanceledCallback);
	
	m_iNumAutomatchSearchAttempts = 0;

	// SUPER MEGA HAX OF DEATH: Force the code bellow to set up the 'EnableOnlineGameSearchesCooldownComplete' timer.
	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		m_bOnlineGameSearchCooldown = false;
		m_bCanStartOnlineGameSearch = false;
	}
	EnableOnlineGameSearches();
}

/**
 * Enable online game searches again. On Xbox 360 this waits for a cooldown.
 */
private function EnableOnlineGameSearches()
{
	`log(`location, true, 'XCom_Online');
	if( WorldInfo.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		// Don't allow the user to spam online game searches on Xbox 360.
		if( !m_bCanStartOnlineGameSearch && !m_bOnlineGameSearchCooldown )
		{
			m_bOnlineGameSearchCooldown = true;
			SetTimer(1, false, 'EnableOnlineGameSearchesCooldownComplete');
		}
	}
	else
	{
		m_bCanStartOnlineGameSearch = true;
		m_bOnlineGameSearchInProgress = false;
		m_bOnlineGameSearchCooldown = false;
	}
}

/**
 * Called via a timer when the cooldown for enabling online game searches is complete.
 */
private function EnableOnlineGameSearchesCooldownComplete()
{
	`log(`location, true, 'XCom_Online');
	m_bCanStartOnlineGameSearch = true;
	m_bOnlineGameSearchInProgress = false;
	m_bOnlineGameSearchCooldown = false;
	m_bOnlineGameSearchAborted = false;
}

function bool OnSystemMessage_AutomatchGameFull()
{
	local bool bSuccess;

	bSuccess = false;

	ReadLastMatchInfo(`ONLINEEVENTMGR.m_kMPLastMatchInfo);
	FillLocalPRIFromLastMatchPlayerInfo(XComPlayerReplicationInfo(XComPlayerController(Owner).PlayerReplicationInfo), `ONLINEEVENTMGR.m_kMPLastMatchInfo.m_kLocalPlayerInfo);
	`log(`location @ "Game full, creating our own game" @ 
		`ShowVar(`GAMECORE) @
		`ShowVar(m_kMPShellManager.OnlineGame_GetIsRanked()) @
		"LocalPRI=" $ XComPlayerReplicationInfo(XComPlayerController(Owner).PlayerReplicationInfo).ToString() @
		"LastMatchInfo=" $ class'XComOnlineEventMgr'.static.TMPLastMatchInfo_ToString(`ONLINEEVENTMGR.m_kMPLastMatchInfo), true, 'XCom_Online');

	if(m_kMPShellManager.OnlineGame_GetIsRanked())
	{
		if(OSSCreateRankedGame(false /* bAutomatch */))
		{
			bSuccess = true;
		}
		else
		{
			`log(`location @ "OSSCreateRankedGame failed!", true, 'XCom_Online');
			bSuccess = false;
		}
	}
	else
	{
		if(OSSCreateUnrankedGame(false /* bAutomatch */))
		{
			bSuccess = true;
		}
		else
		{
			`log(`location @ "OSSCreateUnrankedGame failed!", true, 'XCom_Online');
			bSuccess = false;
		}
	}
	// set the flag to false because we just failed an automatch and are going to create the game directly. -tsmith 
	`ONLINEEVENTMGR.m_kMPLastMatchInfo.m_bAutomatch = false;

	return bSuccess;
}

function WriteLastMatchInfo(out TMPLastMatchInfo kLastMatchInfo)
{
	kLastMatchInfo.m_bIsRanked = m_kMPShellManager.OnlineGame_GetIsRanked();
	kLastMatchInfo.m_bAutomatch = m_kMPShellManager.OnlineGame_GetAutomatch();
	kLastMatchInfo.m_iMapPlotType = m_kMPShellManager.OnlineGame_GetMapPlotInt();
	kLastMatchInfo.m_iMapBiomeType = m_kMPShellManager.OnlineGame_GetMapBiomeInt();
	kLastMatchInfo.m_eGameType = m_kMPShellManager.OnlineGame_GetType();
	kLastMatchInfo.m_eNetworkType = m_kMPShellManager.OnlineGame_GetNetworkType();
	kLastMatchInfo.m_iTurnTimeSeconds = m_kMPShellManager.OnlineGame_GetTurnTimeSeconds();
	kLastMatchInfo.m_iMaxSquadCost = m_kMPShellManager.OnlineGame_GetMaxSquadCost();
}

function ReadLastMatchInfo( const out TMPLastMatchInfo kLastMatchInfo)
{
	m_kMPShellManager.OnlineGame_SetIsRanked(kLastMatchInfo.m_bIsRanked);
	m_kMPShellManager.OnlineGame_SetAutomatch(kLastMatchInfo.m_bAutomatch);
	m_kMPShellManager.OnlineGame_SetMapPlotInt(kLastMatchInfo.m_iMapPlotType);
	m_kMPShellManager.OnlineGame_SetMapBiomeInt(kLastMatchInfo.m_iMapBiomeType);
	m_kMPShellManager.OnlineGame_SetType(kLastMatchInfo.m_eGameType);
	m_kMPShellManager.OnlineGame_SetNetworkType(kLastMatchInfo.m_eNetworkType);
	m_kMPShellManager.OnlineGame_SetTurnTimeSeconds(kLastMatchInfo.m_iTurnTimeSeconds);
	m_kMPShellManager.OnlineGame_SetMaxSquadCost(kLastMatchInfo.m_iMaxSquadCost);
}

// @TODO tsmith: we dont have an analog of this function in the new UI/shell code
simulated function FillLocalPRIFromLastMatchPlayerInfo(XComPlayerReplicationInfo kLocalPRI, const out TMPLastMatchInfo_Player kLastMatchLocalPlayerInfo)
{
	kLocalPRI.m_iRankedDeathmatchMatchesWon = kLastMatchLocalPlayerInfo.m_iWins;
	kLocalPRI.m_iRankedDeathmatchMatchesLost = kLastMatchLocalPlayerInfo.m_iLosses;
	kLocalPRI.m_iRankedDeathmatchDisconnects = kLastMatchLocalPlayerInfo.m_iDisconnects;
	kLocalPRI.m_iRankedDeathmatchSkillRating = kLastMatchLocalPlayerInfo.m_iSkillRating;
	kLocalPRI.m_iRankedDeathmatchRank = kLastMatchLocalPlayerInfo.m_iRank;
	kLocalPRI.m_bRankedDeathmatchLastMatchStarted = kLastMatchLocalPlayerInfo.m_bMatchStarted;
}

reliable client function CAMLookAtNamedLocation( string strLocation, optional float fInterpTime = 2, optional bool bSkipBaseViewTransition )
{
	XComCamState_Shell(GetCamera().SetCameraState(class'XComCamState_Shell', fInterpTime)).InitView(PlayerController(Owner), name(strLocation));
	GetCamera().GotoState( 'BaseRoomView' );
}

simulated function XComBaseCamera GetCamera()
{
	return XComBaseCamera(PlayerController(Owner).PlayerCamera);
}

defaultproperties
{
	//m_fSaveCompleteCallback=none ??? 
	m_eUIMode=eUIMode_Shell
	m_bCanStartOnlineGameSearch=true
	bAlwaysTick=true
}
