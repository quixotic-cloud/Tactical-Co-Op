//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShell
//  AUTHOR:  Katie Hirsch       --  04/10/09
//           Tronster Hartley   --  04/23/09
//  PURPOSE: This file controls the game side of the shell menu UI screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIShell extends UIScreen
	config(UI);

//------------------------------------------------------
// LOCALIZED STRINGS
var localized string m_strDemo;
var localized string m_sLoad;
var localized string m_sSpecial;
var localized string m_sOptions;
var localized string m_sStrategy;
var localized string m_sTactical;
var localized string m_sTutorial;
var localized string m_sFinalShellDebug;

//------------------------------------------------------
// MEMBER DATA
var bool      m_bDisableActions;

var bool bLoginInitialized;

var const String strTutorialSave;
var const String strDirectedDemoSave;

var UIPanel MainMenuContainer;
var array<UIButton> MainMenu;
var UIPanel MainMenuBG;
var UIPanel DebugMenuContainer;
var UIPanel Logo; 
var UIScrollingText TickerText;
var UIPanel TickerBG;
var float DefaultMainMenuOffset;
var float TickerHeight;

var const config float BufferSpace; // pixel buffer between category buttons. 

delegate OnClickedDelegate(UIButton Button);

//==============================================================================
//		INITIALIZATION & INPUT:
//==============================================================================
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	if(class'GameEngine'.static.GetOnlineSubsystem() != none && class'GameEngine'.static.GetOnlineSubsystem().GameInterface.GetGameSettings('Game') != none)
	{
		class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');
	}
	InitMainMenu();

	Navigator.HorizontalNavigation = true;
	
	Logo = Spawn(class'UIPanel', self).InitPanel('X2Logo', 'X2Logo');
	Logo.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	Logo.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	Logo.SetPosition(20, 20);
	Logo.DisableNavigation();

	`FXSLIVE.AddReceivedMOTDDelegate(OnReceivedMOTD);
	`FXSLIVE.FirstClientInit();
	CreateTicker();
}

simulated function OnInit()
{	
	local XComGameStateNetworkManager NetworkMgr;

	super.OnInit();	

	if( !WorldInfo.IsConsoleBuild() )
	{
		SetTimer(0.1f, false, nameof(DelayedLogin));
	}

	// Will display any pending information for the user since the screen has been transitioned. -ttalley
	`ONLINEEVENTMGR.PerformNewScreenInit();
	m_bDisableActions = false;

	// Force any network connections at this point to close
	NetworkMgr = `XCOMNETMANAGER;
	NetworkMgr.Disconnect();
}
//----------------------------------------------------------

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	SubscribeToOnCleanupWorld();
	`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(OnGameInviteComplete);
}

event Destroyed()
{
	UnsubscribeFromOnCleanupWorld();
	Cleanup();

	super.Destroyed();
}

simulated event OnCleanupWorld()
{
	Cleanup();
	super.OnCleanupWorld();
}

simulated function Cleanup()
{
	`ONLINEEVENTMGR.ClearGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.ClearGameInviteCompleteDelegate(OnGameInviteComplete);
	`FXSLIVE.ClearReceivedMOTDDelegate(OnReceivedMOTD);
}

simulated function OnGameInviteAccepted(bool bWasSuccessful)
{
	local XComPresentationLayerBase Presentation;
	local TProgressDialogData kDialogData;

	`log(`location, true, 'XCom_Online');
	if(bWasSuccessful)
	{
		m_bDisableActions = true; // BUG 14008: TCR # 115 - [ONLINE] - Users will enter a single player game as they accept an invite and attempt to start a new single player game on the Main Menu. -ttalley

		Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
		kDialogData.strTitle = `ONLINEEVENTMGR.m_sAcceptingGameInvitation;
		kDialogData.strDescription = `ONLINEEVENTMGR.m_sAcceptingGameInvitationBody;
		Presentation.UIProgressDialog(kDialogData);
	}
}

simulated function OnGameInviteComplete(ESystemMessageType MessageType, bool bWasSuccessful)
{
	local XComPresentationLayerBase Presentation;

	if (!bWasSuccessful)
	{
		// Only close the progress dialog if there was a failure.
		Presentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
		Presentation.UICloseProgressDialog();
		`ONLINEEVENTMGR.QueueSystemMessage(MessageType);

		m_bDisableActions = false; // BUG 12284: [ONLINE] The user will soft crash on a 'Checking for Downloadable Content' prompt after backing out of a multiplayer lobby, then accepting an expired invite from the title screen, and pressing start at the title screen.
	}
}

function OnMusicLoaded(object LoadedObject)
{
	local MusicTrackStruct MusicTrack;
	local SoundCue MusicCue;

	MusicCue = SoundCue(LoadedObject);
	if (MusicCue != none)
	{
		MusicTrack.TheSoundCue = MusicCue;
		MusicTrack.FadeInTime = 0.0f;
		MusicTrack.FadeOutTime = 0.0f;
		MusicTrack.bAutoPlay = true;

		WorldInfo.UpdateMusicTrack(MusicTrack);
	}
}

function DelayedLogin()
{
	if( !`ONLINEEVENTMGR.bHasProfileSettings )
	{
		`log("Shell Calling Login",,'XCom_Online');
		`ONLINEEVENTMGR.BeginShellLogin(0);
	}

	if(!XComShellPresentationLayer(Movie.Pres).m_bHadNetworkConnectionAtInit && !`ONLINEEVENTMGR.bWarnedOfOfflineStatus)
	{
		`ONLINEEVENTMGR.bWarnedOfOfflineStatus = true;
		Movie.Pres.UIRaiseDialog(XComShellPresentationLayer(Movie.Pres).GetOnlineNoNetworkConnectionDialogBoxData());
	}
}
//===============================================================================
//		SCREEN FUNCTIONALITY & DISPLAY:
//===============================================================================

simulated function InitMainMenu()
{
	MainMenuContainer = Spawn(class'UIPanel', self).InitPanel('ShellMenuContainer');
	MainMenuContainer.Navigator.HorizontalNavigation = true;
	MainMenuContainer.bCascadeFocus = false;
	MainMenuContainer.SetSize(300, 600);
	MainMenuContainer.AnchorBottomCenter();
	MainMenuContainer.SetPosition(0, DefaultMainMenuOffset);

	MainMenuBG = Spawn(class'UIPanel', MainMenuContainer).InitPanel('ShellMenuBG', 'X2MenuBG');
	MainMenuBG.SetY(24);
	MainMenuBG.DisableNavigation();
	
	UpdateMenu();
}

simulated function ClearMenu()
{
	local int i; 
	for( i = MainMenu.Length - 1; i >= 0; i-- )
	{
		MainMenu[i].Remove();
	}
	MainMenu.Length = 0;
}

simulated function UpdateMenu()
{
	InitDebugOptions();

	ClearMenu();

	CreateItem('Tactical', m_sTactical);
	CreateItem('Strategy', m_sStrategy);
	CreateItem('Load', m_sLoad);
	CreateItem('Special', m_sSpecial);
	CreateItem('Options', m_sOptions);
	CreateItem('Tutorial', m_sTutorial);

	MainMenuContainer.Navigator.SelectFirstAvailable();
}

function CreateItem(Name ButtonName, string Label)
{
	local UIX2MenuButton Button; 

	Button = Spawn(class'UIX2MenuButton', MainMenuContainer);

	Button.InitMenuButton(false, ButtonName, Label, OnMenuButtonClicked);
	Button.OnSizeRealized = OnButtonSizeRealized;
	MainMenu.AddItem(Button);
}

simulated function OnButtonSizeRealized()
{
	local int i, CurrentX;

	CurrentX = BufferSpace; //Start spaced over slightly, to give BG edge breathing room. 
	for( i = 0; i < MainMenu.Length; i++ )
	{
		MainMenu[i].SetX(CurrentX);
		CurrentX += MainMenu[i].Width + BufferSpace;
	}

	MainMenuBG.SetWidth(CurrentX);

	// Center to the category list along the bottom of the screen.
	MainMenuContainer.SetX(CurrentX * -0.5);
}

// Button callbacks
simulated function OnMenuButtonClicked(UIButton button)
{
	if( m_bDisableActions )
		return;

	//Re-enable achievements
	`ONLINEEVENTMGR.ResetAchievementState();

	X2ImageCaptureManager(`XENGINE.GetImageCaptureManager()).ClearStore();

	switch( button.MCName )
	{
	case 'Tactical': 
		`XCOMHISTORY.ResetHistory( , false);
		ConsoleCommand("open TacticalQuickLaunch");
		break;
	case 'Strategy':
		`XCOMHISTORY.ResetHistory();
		XComShellPresentationLayer(Owner).UIStrategyShell();
		break;
	case 'Load':
		`XCOMHISTORY.ResetHistory();
		XComShellPresentationLayer(Owner).UILoadScreen();
		break;
	case 'Special':
		`XCOMHISTORY.ResetHistory();
		`ONLINEEVENTMGR.bInitiateReplayAfterLoad = true;
		XComShellPresentationLayer(Owner).UILoadScreen();
		break;
	case 'Options':
		XComPresentationLayerBase(Owner).UIPCOptions();
		break;
	case 'Tutorial':
		//Controlled Start / Demo Direct
		`XCOMHISTORY.ResetHistory();
		`ONLINEEVENTMGR.bTutorial = true;
		`ONLINEEVENTMGR.bInitiateReplayAfterLoad = true;
		`ONLINEEVENTMGR.LoadSaveFromFile(strTutorialSave);
		break;
	}
}

//----------------------------------------------------------

simulated function InitDebugOptions()
{
	local UIButton Button;

	if( DebugMenuContainer != none ) return; 

	DebugMenuContainer = Spawn(class'UIPanel', self).InitPanel('DebugMenuContainer');
	DebugMenuContainer.bCascadeFocus = false;
	DebugMenuContainer.Navigator.HorizontalNavigation = false;

	Spawn(class'UIButton', DebugMenuContainer)
		.InitButton('DynamicDebug', "DEBUG DYNAMIC UI", UIDebugButtonClicked)
		.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT)
		.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT)
		.SetPosition(-10, 10); //Offset when anchored (absolute positioning when not)

	Spawn(class'UIButton', DebugMenuContainer)
		.InitButton('CharacterPool', "CHARACTER POOL", UIDebugButtonClicked)
		.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT)
		.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT)
		.SetPosition(-10, 50); //Offset when anchored (absolute positioning when not)

	Button = Spawn(class'UIButton', DebugMenuContainer);
	Button.InitButton('IntervalChallenge', "CHALLENGE MODE", UIDebugButtonClicked);
	Button.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetPosition(-10, 90); //Offset when anchored (absolute positioning when not)

	`ONLINEEVENTMGR.RefreshLoginStatus();
	if( `XENGINE.MCPManager == none || !(`ONLINEEVENTMGR.bHasLogin) )
	{
		Button.DisableButton("Not logged into online service!");
	}

	Button = Spawn(class'UIButton', DebugMenuContainer);
	Button.InitButton('FiraxisLiveLogin', "FIRAXIS LIVE", UIDebugButtonClicked);
	Button.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetPosition(-10, 130); //Offset when anchored (absolute positioning when not)

	Button = Spawn(class'UIButton', DebugMenuContainer);
	Button.InitButton('DirectedDemo', "DIRECTED DEMO", UIDebugButtonClicked);
	Button.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetPosition(-10, 170); //Offset when anchored (absolute positioning when not)

	Button = Spawn(class'UIButton', DebugMenuContainer);
	Button.InitButton('MultiplayerMenus', "MULTIPLAYER MENUS", UIDebugButtonClicked);
	Button.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetPosition(-10, 210); //Offset when anchored (absolute positioning when not)

	Button = Spawn(class'UIButton', DebugMenuContainer);
	Button.InitButton('FinalShellMenu', m_sFinalShellDebug, UIDebugButtonClicked);
	Button.SetOrigin(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Button.SetPosition(-10, 250); //Offset when anchored (absolute positioning when not)	
}

// Debug keyboard callback (called when 'U' key is pressed)
simulated function UIDebugKeyPressed()
{
	XComShellPresentationLayer(Owner).UIDynamicDebugScreen();
}
// Button callbacks
simulated function UIDebugButtonClicked(UIButton button)
{
	switch( button.MCName )
	{
	case 'DynamicDebug': XComShellPresentationLayer(Owner).UIDynamicDebugScreen(); break;
	case 'MultiplayerMenus': XComShellPresentationLayer(Owner).StartMPShellState(); break;
	case 'CharacterPool':
		XComPresentationLayerBase(Owner).UICharacterPool();
		break;
	case 'IntervalChallenge': `CHALLENGEMODE_MGR.OpenChallengeModeUI(); break;
	case 'FiraxisLiveLogin': XComPresentationLayerBase(Owner).UIFiraxisLiveLogin(); break;

	case 'DirectedDemo':
		`XCOMHISTORY.ResetHistory();
		`ONLINEEVENTMGR.bTutorial = true;
		`ONLINEEVENTMGR.bDemoMode = true;
		`ONLINEEVENTMGR.bInitiateReplayAfterLoad = true;
		`ONLINEEVENTMGR.LoadSaveFromFile(strDirectedDemoSave);
		break;
	case 'FinalShellMenu':
		XComShellPresentationLayer(Owner).UIFinalShellScreen();
		break;

	case 'XComDatabase':
		XComPresentationLayerBase(Owner).UIXComDatabase();
		break;
		
	}
}

//=======================================================================
simulated function OnReceiveFocus()
{
	local XComOnlineProfileSettings kProfileSettings;

	super.OnReceiveFocus();

	// Controller vs. Mouse navigation - check every time 
	kProfileSettings = `XPROFILESETTINGS;
	if ( kProfileSettings.Data.IsMouseActive() )
		Movie.ActivateMouse();
	else
		Movie.DeactivateMouse();

	XComShellPresentationLayer(Movie.Pres).Get3DMovie().ShowDisplay('UIShellBlueprint');
	//Use the panel version 
	super(UIPanel).AnimateIn();
}


simulated function  CreateTicker()
{
	TickerBG = Spawn(class'UIPanel', self).InitPanel('BGBoxSimpleBG', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
	TickerBG.AnchorBottomLeft().SetY(-35);
	TickerBG.SetSize(Movie.m_v2ScaledFullscreenDimension.X, TickerHeight);
	TickerBG.SetAlpha(80);
	TickerBG.DisableNavigation();
	TickerBG.Hide();
	TickerBG.bAnimateOnInit = false;

	TickerText = Spawn(class'UIScrollingText', self).InitScrollingText();
	TickerText.AnchorBottomLeft().SetY(-TickerHeight + 10);
	TickerText.SetWidth(Movie.m_v2ScaledFullscreenDimension.X);
	TickerText.Hide();
	TickerText.bAnimateOnInit = false;

	// Call this to update, or blank string to hide the ticker: 
	// UIShell(ShellPres.Screenstack.GetScreen(class'UIShell')).SetTicker("%ATTENTIONICON New ticker text.");	
	// Use %ATTENTIONICON to inject the cool HTML icon.
	if(!`FXSLIVE.GetMOTD("MainMenu", GetLanguage()))
	{
		SetTicker("");
	}
}

function OnReceivedMOTD(string Category, array<MOTDMessageData> Messages)
{
	local int MessageIdx;
	`log(self $ "::" $ GetFuncName() @ `ShowVar(Category) @ `ShowVar(Messages.Length),, 'XCom_Online');
	if( InStr(Category, "MainMenu",,true) > -1 )
	{
		for(MessageIdx = 0; MessageIdx < Messages.Length; ++MessageIdx)
		{
			if( InStr(Messages[MessageIdx].MessageType, GetLanguage(),,true) > -1 )
			{
				`log(self $ "::" $ GetFuncName() @ "   -> Setting Ticker: " @ `ShowVar(Messages[MessageIdx].MessageType, MessageType) @ `ShowVar(Messages[MessageIdx].Message, Message),, 'XCom_Online');
				SetTicker(Messages[MessageIdx].Message);
			}
		}
	}
}


simulated function SetTicker(string DisplayMessage)
{
	local string UpdateDisplayMessage; 
	
	UpdateDisplayMessage = Repl(DisplayMessage, "%ATTENTIONICON", class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 20, 20, -4), false);

	TickerText.SetHtmlText(UpdateDisplayMessage);
	
	if( DisplayMessage == "" )
	{
		TickerText.Hide();
		TickerBG.Hide();
		MainMenuContainer.SetY(DefaultMainMenuOffset);
		MainMenuBG.SetHeight(57); //Large enough to go offscreen 
	}
	else
	{
		TickerText.Show();
		TickerBG.Show();
		MainMenuContainer.SetY(DefaultMainMenuOffset - TickerHeight + 10); //10 px art adjustment
		MainMenuBG.SetHeight(27);
	}
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	InputState = eInputState_Evaluate; 
	bLoginInitialized = false
	m_bDisableActions = false
	bHideOnLoseFocus = true;

	strTutorialSave = "..\\Tutorial\\Tutorial"
	strDirectedDemoSave = "..\\Demo\\Demo"

	DefaultMainMenuOffset = -55;
	TickerHeight = 40;
}
