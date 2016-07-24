//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMultiplayerHUD_ChatManager
//  AUTHOR:  Sam Batista
//  PURPOSE: Controls the chat panel for Multiplayer communications
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMultiplayerDisconnectPopup extends UIScreen;

var int       m_iCurrentSelection;
var int       MAX_OPTIONS;

var localized string m_sCancel;
var localized string m_sGameDisconnected;

var localized string m_sExitToMainMenu;
var int m_optExitToMainMenu;

var localized string m_sQuitGame;
var int m_optQuitGame;


var UIList List;
var UIText Title;

//----------------------------------------------------------------------------
// CACHED VARIABLES
var XComGameStateNetworkManager NetworkMgr;

//----------------------------------------------------------------------------
// METHODS
//

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	NetworkMgr = `XCOMNETMANAGER;

	List = Spawn(class'UIList', self);
	List.InitList('ItemList', , , 415, 450);
	List.OnItemClicked = OnChildClicked;
	List.OnSelectionChanged = SetSelected; 
	List.OnItemDoubleClicked = OnChildClicked;
}

// Flash side is initialized.
simulated function OnInit()
{
	local int iCurrent; 

	super.OnInit();	

	iCurrent = 0; 
	List.ClearItems();


	MC.FunctionString("SetTitle", m_sGameDisconnected);

	m_optExitToMainMenu = iCurrent++;
	UIListItemString(List.CreateItem()).InitListItem(m_sExitToMainMenu);

	m_optQuitGame= iCurrent++; 
	UIListItemString(List.CreateItem()).InitListItem(m_sQuitGame);

	MC.FunctionVoid("AnimateIn");

	SetHelp( 0, m_sCancel, 	 class'UIUtilities_Input'.static.GetBackButtonIcon());

	SetSelected(List, 0);
}

public function OnChildClicked(UIList ContainerList, int ItemIndex)
{		
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetSelected(ContainerList, ItemIndex);

	switch( m_iCurrentSelection )
	{
		case m_optExitToMainMenu:
			ExitToMainMenu();
			break; 

		case m_optQuitGame:
			ConsoleCommand("exit");
			break;
	}
}

function ExitToMainMenu()
{
	NetworkMgr.Disconnect();
	CloseScreen();
	Movie.Pres.StartMPShellState();
}

public function OnUCancel()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
}

public function OnUDPadUp()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	--m_iCurrentSelection;
	if (m_iCurrentSelection < 0)
		m_iCurrentSelection = MAX_OPTIONS-1;

	SetSelected(List, m_iCurrentSelection);
}


public function OnUDPadDown()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	++m_iCurrentSelection;
	if (m_iCurrentSelection >= MAX_OPTIONS)
		m_iCurrentSelection = 0;

	SetSelected(List, m_iCurrentSelection);
}

function SetSelected(UIList ContainerList, int ItemIndex)
{
	m_iCurrentSelection = ItemIndex;
}

function int GetSelected()
{
	return  m_iCurrentSelection; 
}

/// ========== FLASH calls ========== 

//Set the info in the standard help bar along the bottom of the screen 
function SetHelp(int index, string text, string buttonIcon)
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

function OnExitButtonClicked(UIButton button)
{
	CloseScreen();
}

// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	//Package="/ package/gfxMultiplayerDisconnectPopup/MultiplayerDisconnectPopup"
	//MCName="theMultiplayerDisconnectPopup"
	Package="/ package/gfxPauseMenu/PauseMenu"
	MCName="thePauseMenu"

	InputState=eInputState_Consume
	bAlwaysTick=true
	bHideOnLoseFocus=false
}