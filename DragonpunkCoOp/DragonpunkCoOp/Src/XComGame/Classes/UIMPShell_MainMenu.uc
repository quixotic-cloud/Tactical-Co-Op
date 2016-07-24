//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_MainMenuuc
//  AUTHOR:  Todd Smith  --  6/18/2015
//  PURPOSE: The new multiplayer menu screen for XCOM 2
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_MainMenu extends UIMPShell_Base;

var localized string m_strQuickmatchButtonText;
var localized string m_strCreateGameButtonText;
var localized string m_strSearchGameButtonText;
var localized string m_strRankedMatchButtonText;
var localized string m_strSquadLoadoutsButtonText;
var localized string m_strLeaderboardsButtonText;
var localized string m_strMPHeaderText;
var localized string m_strCancel;
var localized string m_strDisableModsForRanked;


var int     m_iPartyChatStatusHandle;
var bool    m_bFetchingMPData;
var bool    m_bScreenIsClosing;

var UIList List;
var UIText Title;
var int       m_iCurrentSelection;
var int       MAX_OPTIONS;

var int m_optRanked;
var int m_optCasual;
var int m_optCreateCustom;
var int m_optFindCustom;
var int m_optEditLoadouts;
var int m_optLeaderboards;

var UINavigationHelp NavHelp;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	// need to destroy any pre-existing game session otherwise creation/searching of games will not work. -tsmith
	class'GameEngine'.static.GetOnlineSubsystem().GameInterface.DestroyOnlineGame('Game');

	super.InitScreen(InitController, InitMovie, InitName);
	
	XComCheatManager(GetALocalPlayerController().CheatManager).UnsuppressMP();

	List = Spawn(class'UIList', self);
	List.InitList('ItemList', , , 415, 450);
	List.OnItemClicked = OnChildClicked;
	List.OnSelectionChanged = SetSelected; 
	List.OnItemDoubleClicked = OnChildClicked;

	Movie.UpdateHighestDepthScreens(); 
	InitConnectivityHandlers();
	m_kMPShellManager.UpdateConnectivityData();
}

private function InitConnectivityHandlers()
{
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.AddLinkStatusChangeDelegate(LinkStatusChange);
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.AddConnectionStatusChangeDelegate(ConnectionStatusChange);
}

simulated function OnInit()
{
	local XComOnlineEventMgr OnlineMgr;

	OnlineMgr = `ONLINEEVENTMGR;
	super.OnInit();
	
	NavHelp = m_kMPShellManager.NavHelp;

	BuildMenu();

	UpdateNavHelp();
	UpdateConnectivityDependentButtons();

	// If there is a pending invite, open the screen
	if( !(OnlineMgr.HasAcceptedInvites() && OpenInviteLoadout()) )
	{
		// code added from XEU main menu (UIMultiplayerShell) -tsmith

		// Will display any pending information for the user since the screen has been transitioned. -ttalley
		OnlineMgr.PerformNewScreenInit();

		// Initialize delegates for connection error popus after the Shell is initialized - sbatista 3/22/12
		m_kMPShellManager.OnMPShellScreenInitialized();
	}
	LinkStatusChange(m_kMPShellManager.m_bPassedNetworkConnectivityCheck);
}

simulated function bool OpenInviteLoadout()
{
	if( `SCREENSTACK.GetScreen(class'UIMPShell_SquadLoadoutList_AcceptingInvite') == none )
	{
		`SCREENSTACK.Push(Spawn(class'UIMPShell_SquadLoadoutList_AcceptingInvite', Movie.Pres));
		return true;
	}
	return false;
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(BackButtonCallback);
}

simulated function BuildMenu()
{
	local int iCurrent;

	MC.FunctionString("SetTitle", m_strMPHeaderText);

	List.ClearItems();

	iCurrent = 0; 

	m_optRanked = iCurrent++;
	UIListItemString(List.CreateItem()).InitListItem(m_strRankedMatchButtonText);

	m_optCasual = iCurrent++;
	UIListItemString(List.CreateItem()).InitListItem(m_strQuickmatchButtonText);

	m_optCreateCustom = iCurrent++;
	UIListItemString(List.CreateItem()).InitListItem(m_strCreateGameButtonText);

	m_optFindCustom = iCurrent++;
	UIListItemString(List.CreateItem()).InitListItem(m_strSearchGameButtonText);
	
	m_optLeaderboards = iCurrent++;
	UIListItemString(List.CreateItem()).InitListItem(m_strLeaderboardsButtonText);

	m_optEditLoadouts = iCurrent++;
	UIListItemString(List.CreateItem()).InitListItem(m_strSquadLoadoutsButtonText);

	MAX_OPTIONS = iCurrent;

	MC.FunctionVoid("AnimateIn");
}

simulated function bool OnUnrealCommand(int ucmd, int ActionMask)
{
	// Ignore releases, only pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(ucmd, ActionMask) )
		return true;

	switch(ucmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnChildClicked(List, m_iCurrentSelection);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			OnUDPadUp();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			OnUDPadDown();
			break;

		default:
			// Do not reset handled, consume input since this
			// is the pause menu which stops any other systems.
			break;			
	}

	return super.OnUnrealCommand(ucmd, ActionMask);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			//Update the selection based on what the mouse rolled over
			//SetSelected( int(Split( args[args.Length - 1], "option", true)) );
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			//Update the selection based on what the mouse clicked
			m_iCurrentSelection = int(Split( args[args.Length - 1], "option", true));
			OnChildClicked(List, m_iCurrentSelection);
			break;
	}
}

simulated public function OnChildClicked(UIList ContainerList, int ItemIndex)
{	
	if((UIListItemString(ContainerList.GetItem(ItemIndex)) == none) || UIListItemString(ContainerList.GetItem(ItemIndex)).bDisabled)
		return;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetSelected(ContainerList, ItemIndex);

	switch( m_iCurrentSelection )
	{
	case m_optRanked:
		RankedMatchButtonCallback();
		break;
	case m_optCasual:
		QuickMatchButtonCallback();
		break;
	case m_optCreateCustom:
		CreateGameButtonCallback();
		break;
	case m_optFindCustom:
		SearchGameButtonCallback();
		break;
	case m_optEditLoadouts:
		SquadLoadoutsButtonCallback();
		break;
	case m_optLeaderboards:
		LeaderboardsButtonCallback();
		break;

	default:
		`warn("Multiplayer menu cannot accept an unexpected index of:" @ m_iCurrentSelection);
		break;
	}	
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	SubscribeToOnCleanupWorld();
	`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(OnGameInviteComplete);
}

simulated function OnGameInviteAccepted(bool bWasSuccessful)
{
	local XComPresentationLayerBase Presentation;
	local TProgressDialogData kDialogData;

	`log(`location @ `ShowVar(bWasSuccessful), true, 'XCom_Online');
	if(bWasSuccessful)
	{
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
	}
}

function TimerCheckAndClearFetchingMPProgressDialog()
{
	local XComPresentationLayerBase kPresentation;

	kPresentation = XComPlayerController(class'UIInteraction'.static.GetLocalPlayer(0).Actor).Pres;
	if(kPresentation.IsInState('State_ProgressDialog'))
	{
		kPresentation.PopState();
		m_bFetchingMPData = false;
		ClearTimer(nameof(TimerCheckAndClearFetchingMPProgressDialog));
	}
}

function QuickMatchButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(`SCREENSTACK.GetScreen(class'UIMPShell_SquadLoadoutList_QuickMatch') == none)
		`SCREENSTACK.Push(Spawn(class'UIMPShell_SquadLoadoutList_QuickMatch', Movie.Pres));
}

function CreateGameButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(`SCREENSTACK.GetScreen(class'UIMPShell_CustomGameCreateMenu') == none)
		`SCREENSTACK.Push(Spawn(class'UIMPShell_CustomGameCreateMenu', Movie.Pres), Movie.Pres.Get3DMovie());
}

function SearchGameButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(`SCREENSTACK.GetScreen(class'UIMPShell_CustomGameMenu_Search') == none)
		`SCREENSTACK.Push(Spawn(class'UIMPShell_CustomGameMenu_Search', Movie.Pres), Movie.Pres.Get3DMovie());
}

function RankedMatchButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(`SCREENSTACK.GetScreen(class'UIMPShell_SquadLoadoutList_RankedGame') == none)
		`SCREENSTACK.Push(Spawn(class'UIMPShell_SquadLoadoutList_RankedGame', Movie.Pres));
}

function LeaderboardsButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	if(`SCREENSTACK.GetScreen(class'UIMPShell_Leaderboards') == none)
		`SCREENSTACK.Push(Spawn(class'UIMPShell_Leaderboards', Movie.Pres));
}

function SquadLoadoutsButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	
	if(`SCREENSTACK.GetScreen(class'UIMPShell_SquadLoadoutList_Preset') == none)
		`SCREENSTACK.Push(Spawn(class'UIMPShell_SquadLoadoutList_Preset', Movie.Pres));
}

function BackButtonCallback()
{
	CloseScreen();
}

simulated function CloseScreen()
{
	m_kMPShellManager.CloseShell();
	super.CloseScreen();
}

simulated public function OnUCancel()
{
	if( !bIsInited )
		return;

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	CloseScreen();
}

simulated public function OnUDPadUp()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	--m_iCurrentSelection;
	if (m_iCurrentSelection < 0)
		m_iCurrentSelection = MAX_OPTIONS-1;

	SetSelected(List, m_iCurrentSelection);
}


simulated public function OnUDPadDown()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	++m_iCurrentSelection;
	if (m_iCurrentSelection >= MAX_OPTIONS)
		m_iCurrentSelection = 0;

	SetSelected( List, m_iCurrentSelection );
}

simulated function SetSelected(UIList ContainerList, int ItemIndex)
{
	m_iCurrentSelection = ItemIndex;
}

simulated function int GetSelected()
{
	return  m_iCurrentSelection; 
}

function LinkStatusChange(bool bIsConnected)
{
	`log(`location @ `ShowVar(bIsConnected), true, 'XCom_Online');
	m_kMPShellManager.UpdateConnectivityData();
	UpdateConnectivityDependentButtons();
}

function ConnectionStatusChange(EOnlineServerConnectionStatus ConnectionStatus)
{
	`log(`location @ `ShowVar(ConnectionStatus), true, 'XCom_Online');
	m_kMPShellManager.UpdateConnectivityData();
	UpdateConnectivityDependentButtons();
}

//==============================================================================
//		CLEANUP:
//==============================================================================
simulated function OnReceiveFocus() 
{
	super.OnReceiveFocus();

	UpdateNavHelp();
	UpdateConnectivityDependentButtons();
}

function UpdateConnectivityDependentButtons()
{
	UIListItemString(List.GetItem(m_optRanked)).EnableListItem();
	UIListItemString(List.GetItem(m_optCasual)).EnableListItem();
	UIListItemString(List.GetItem(m_optCreateCustom)).EnableListItem();
	UIListItemString(List.GetItem(m_optFindCustom)).EnableListItem();
	UIListItemString(List.GetItem(m_optLeaderboards)).EnableListItem();

	// custom matches can still be played (LAN only) without an online connection -tsmith
	if(m_kMPShellManager.m_bPassedNetworkConnectivityCheck)
	{
		if(!m_kMPShellManager.m_bPassedOnlineConnectivityCheck)
		{
			UIListItemString(List.GetItem(m_optRanked)).DisableListItem();
			UIListItemString(List.GetItem(m_optCasual)).DisableListItem();
			UIListItemString(List.GetItem(m_optLeaderboards)).DisableListItem();
		}
		else if(!class'Helpers'.static.NetAllRankedGameDataValid())
		{
			`log("Modified game data detected, disabling ranked play",, 'uixcom_mp');
			UIListItemString(List.GetItem(m_optRanked)).DisableListItem(m_strDisableModsForRanked);
		}
	}
	else
	{
		// no network connection at all, disable everything -tsmith
		UIListItemString(List.GetItem(m_optRanked)).DisableListItem();
		UIListItemString(List.GetItem(m_optCasual)).DisableListItem();
		UIListItemString(List.GetItem(m_optCreateCustom)).DisableListItem();
		UIListItemString(List.GetItem(m_optFindCustom)).DisableListItem();
		UIListItemString(List.GetItem(m_optLeaderboards)).DisableListItem();
	}
}

simulated function OnRemoved()
{
	CleanUpPartyChatWatch();
}
event Destroyed()
{
	UnsubscribeFromOnCleanupWorld();
	Cleanup();
	CleanUpPartyChatWatch();
	super.Destroyed();
}

simulated event OnCleanupWorld()
{
	Cleanup();
	super.OnCleanupWorld();
}

function Cleanup()
{
	`ONLINEEVENTMGR.ClearGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.ClearGameInviteCompleteDelegate(OnGameInviteComplete);
	CleanupConnectivityHandlers();
}

function CleanUpPartyChatWatch()
{
	if(WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))
		WorldInfo.MyWatchVariableMgr.UnRegisterWatchVariable(m_iPartyChatStatusHandle);
}

function CleanupConnectivityHandlers()
{
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.ClearLinkStatusChangeDelegate(LinkStatusChange);
	class'GameEngine'.static.GetOnlineSubsystem().SystemInterface.ClearConnectionStatusChangeDelegate(ConnectionStatusChange);
}

simulated function SetHelp(int index, string text, string buttonIcon)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = text;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = buttonIcon;
	myArray.AddItem( myValue );

	Invoke("SetHelp", myArray);
}


//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
	m_iCurrentSelection = 0;
	MAX_OPTIONS = -1;

	Package   = "/ package/gfxPauseMenu/PauseMenu";
	MCName      = "thePauseMenu";

	InputState= eInputState_Evaluate;

	bAlwaysTick = true
}