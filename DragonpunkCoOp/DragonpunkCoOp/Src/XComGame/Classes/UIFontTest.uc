//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIFontTest
//  AUTHOR:  Tronster Hartley   -- 02/20/2010
//           
//  PURPOSE: Test Fonts
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIFontTest extends UIScreen;

var int       m_iCurrentSelection;

var localized string m_sLettersLower;
var localized string m_sLettersUpper;
var localized string m_sNumbers;
var localized string m_sSymbols;
var localized string m_sExtra;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	//manager.LoadScreen( self );
}

simulated function OnInit()
{
	super.OnInit();	
}



simulated function bool OnUnrealCommand(int ucmd, int ActionMask)
{
	// Ignore releases, just pay attention to presses.
	if ( ( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) == 0 )
		return true;

	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			Invoke("next");
			break;

		case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			Invoke("previous");
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			Movie.Stack.Pop(self);
			//ConsoleCommand("disconnect");
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_Y):
			Invoke("toggleShadow");
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
			Invoke("nextBG");
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_SELECT):
			Invoke("toggleSafeZone");
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER):
			Invoke("decreaseSize");
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER):
			Invoke("increaseSize");
			break;
	}

	return super.OnUnrealCommand(ucmd, ActionMask);
}


DefaultProperties
{
	Package = "/ package/gfxTestFont/TestFont";
	MCName = "theFontHarness";
	InputState= eInputState_Consume;
}
