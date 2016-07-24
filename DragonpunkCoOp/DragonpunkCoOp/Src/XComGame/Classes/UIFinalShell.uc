//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIFinalShell.uc
//  AUTHOR:  Sam Batista - 11/4/10
//  PURPOSE: Carbon copy of 'Shell.uc' with different menu options.
//           OVERRIDES ONLY NECESSARY FUNCTIONS.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009 - 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIFinalShell extends UIShell;

//------------------------------------------------------
// LOCALIZED STRINGS
var localized string            m_sNewGame;
var localized string            m_sMultiplayer;
var localized string            m_sExitToDesktop;
var localized string            m_sCharacterPool;

var localized string            m_strExitToPSNStoreTitle;
var localized string            m_strExitToPSNStoreBody;

var UIButton                    m_my2KButton;


var int m_iSP;
var int m_iMP;
var int m_iLoad;
var int m_iOptions;
var int m_iExit;


//--------------------------------------------------------------------------------------- 
// Cached References
//
var X2FiraxisLiveClient FiraxisLiveClient;


// Flash is ready
simulated function OnInit()
{
	super.OnInit();
	
	m_my2KButton = Spawn(class'UIButton', self);
	m_my2KButton.LibID = 'My2KButton';
	m_my2KButton.InitButton('My2KButton', ,  ProcessMy2KButtonClick);
	m_my2KButton.AnchorBottomRight();
	m_my2KButton.SetPosition(-200,-120);
	
	SubscribeToOnCleanupWorld();
	FiraxisLiveClient = `FXSLIVE;
	FiraxisLiveClient.AddLoginStatusDelegate(LoginStatusChange);

	FiraxisLiveClient.FirstClientInit();

	UpdateMy2KButtonStatus();

	SetTimer(1.0f, true, nameof(UpdateMy2KButtonStatus));
}

simulated function UpdateMenu()
{
	ClearMenu();

	CreateItem('SP', m_sNewGame);
	CreateItem('Load', m_sLoad);
	CreateItem('MP', m_sMultiplayer);
	CreateItem('Options', m_sOptions);
	CreateItem('CharacterPool', m_sCharacterPool);
	CreateItem('Exit', m_sExitToDesktop);

	MainMenuContainer.Navigator.SelectFirstAvailable();
}

// Button callbacks
simulated function OnMenuButtonClicked(UIButton button)
{
	if( m_bDisableActions )
		return;

	//Re-enable achievements
	`ONLINEEVENTMGR.ResetAchievementState();

	switch( button.MCName )
	{
	case 'SP':
		XComShellPresentationLayer(Owner).UIDifficulty();
		break;
	case 'MP':
		XComShellPresentationLayer(Owner).StartMPShellState();
		break;
	case 'Load':
		`XCOMHISTORY.ResetHistory();
		XComShellPresentationLayer(Owner).UILoadScreen();
		break;
	case 'Options':
		XComPresentationLayerBase(Owner).UIPCOptions();
		break;
	case 'CharacterPool':
		XComPresentationLayerBase(Owner).UICharacterPool();
		`XCOMGRI.DoRemoteEvent('StartCharacterPool');
		break;
		break;
	case 'Exit':
		if( !WorldInfo.IsConsoleBuild(CONSOLE_Any) )
		{
			ConsoleCommand("exit");
		}
		break;
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	XComShellPresentationLayer(Movie.Pres).UIShellScreen3D();
}

function ProcessMy2KButtonClick(UIButton Button)
{
	local EStatusType StatusType;

	StatusType = FiraxisLiveClient.GetStatus();
	`log( `location @ `ShowEnum(EStatusType, StatusType, StatusType),,'FiraxisLive');

	switch(StatusType)
	{
	case E2kST_OfflineLoggedInCached:
	case E2kST_OnlineLoggedIn:
		if( FiraxisLiveClient.IsAccountAnonymous() )
		{
			FiraxisLiveClient.UpgradeAccount();
			break;
		}
		if( FiraxisLiveClient.IsAccountPlatform() )
		{
			FiraxisLiveClient.StartLinkAccount();
			break;
		}
		if( FiraxisLiveClient.IsAccountFull() )
		{
			PromptForUnlink();
			break;
		}

	case E2kST_Unknown:
	case E2kST_Online:
	case E2kST_Offline:
	case E2kST_OfflineBanned:
	case E2kST_OfflineBlocked:
	case E2kST_OfflineRejectedWhitelist:
	case E2kST_OfflineRejectedCapacity:
	case E2kST_OfflineLegalAccepted:
	case E2kST_LoggedInDoormanOffline:
	default:
		FiraxisLiveClient.StartLoginRequest();
		break;
	}
}

function UIFiraxisLiveLogin GetFiraxisLiveLoginUI()
{
	local XComPresentationLayerBase Presentation;
	local UIFiraxisLiveLogin FiraxisLiveUI;
	Presentation = XComPresentationLayerBase(Owner);
	if( !Presentation.ScreenStack.HasInstanceOf(class'UIFiraxisLiveLogin') )
	{
		// Only open and handle the notification if the Live UI is not up already.
		FiraxisLiveUI = UIFiraxisLiveLogin(Presentation.UIFiraxisLiveLogin(false));
	}
	return FiraxisLiveUI;
}

function PromptForUnlink()
{
	local UIFiraxisLiveLogin FiraxisLiveUI;
	FiraxisLiveUI = GetFiraxisLiveLoginUI();
	if( FiraxisLiveUI != None )
	{
		FiraxisLiveUI.GotoRequestUnlink();
	}
}

function UpdateMy2KButtonStatus()
{
	local ELoginStatus NewButtonStatus;
	local EStatusType StatusType;
	local string StatusText;

	// TODO: once my2k provides the status message, use that message instead of the local messages below

	NewButtonStatus = LS_NotLoggedIn;
	StatusType = FiraxisLiveClient.GetStatus();
	StatusText = class'XComOnlineEventMgr'.default.My2k_Offline;
	switch(StatusType)
	{
	case E2kST_Online:
	case E2kST_OnlineLoggedIn:
		if( FiraxisLiveClient.IsAccountAnonymous() || FiraxisLiveClient.IsAccountPlatform() )
		{
			NewButtonStatus = LS_UsingLocalProfile;
			StatusText = class'XComOnlineEventMgr'.default.My2k_Link;
		}
		else if( FiraxisLiveClient.IsAccountFull() )
		{
			NewButtonStatus = LS_LoggedIn;
			StatusText = class'XComOnlineEventMgr'.default.My2k_Unlink;
		}
		break;

	case E2kST_Unknown:
	case E2kST_Offline:
	case E2kST_OfflineBanned:
	case E2kST_OfflineBlocked:
	case E2kST_OfflineRejectedWhitelist:
	case E2kST_OfflineRejectedCapacity:
	case E2kST_OfflineLegalAccepted:
	case E2kST_OfflineLoggedInCached:
	case E2kST_LoggedInDoormanOffline:
	default:
		break;
	}

	//`log( `location @ `ShowEnum(ELoginStatus, NewButtonStatus, NewButtonStatus) @ `ShowEnum(EStatusType, StatusType, StatusType),,'FiraxisLive');
	m_my2KButton.MC.FunctionString("setStatusText", StatusText);
	m_my2KButton.MC.FunctionNum("setStatus", NewButtonStatus);
}

function LoginStatusChange(ELoginStatusType Type, EFiraxisLiveAccountType Account, string Message, bool bSuccess)
{
	`log( `location @ `ShowEnum(ELoginStatusType, Type, Type) @ `ShowEnum(EFiraxisLiveAccountType, Account, Account) @ `ShowVar(Message) @ `ShowVar(bSuccess),,'FiraxisLive');

	// Ignore status coming back that are errors
	if( !bSuccess ) return;

	// Refresh the menu options to handle the DLC option either
	// appearing or disappearing with a login status change.
	UpdateMenu();

	UpdateMy2KButtonStatus();
}


//==============================================================================
//		CLEANUP (can never be too careful):
//==============================================================================

event Destroyed() 
{
	Cleanup();
	UnsubscribeFromOnCleanupWorld();
	super.Destroyed();
}
simulated event OnCleanupWorld()
{
	Cleanup();
	super.OnCleanupWorld();
}
simulated function Cleanup()
{
	super.Cleanup();
	FiraxisLiveClient.ClearLoginStatusDelegate(LoginStatusChange);

	ClearTimer(nameof(UpdateMy2KButtonStatus));

	//CleanupMOTDReference();
}

DefaultProperties
{
	InputState = eInputState_Evaluate; 
}