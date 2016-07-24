//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISaveExplanationScreen.uc
//  AUTHOR:  Brit Steiner - 5/9/12
//  PURPOSE: This file corresponds to the shell "this is your save icon, derp." screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UISaveExplanationScreen extends UIScreen;

//----------------------------------------------------------------------------
// MEMBERS

var localized string   m_sDesc;
var localized string   m_sDescPS3;
var localized string   m_sDescPC;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}

simulated function OnInit()
{
	super.OnInit();

	AS_SetButtonText(class'UIUtilities_Text'.default.m_strGenericConfirm);
	if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_PS3) )
	{
		AS_SetDescription( m_sDescPS3 );
	}
	else if( class'WorldInfo'.static.IsConsoleBuild(CONSOLE_Xbox360) )
	{
		AS_SetDescription( m_sDesc );
	}
	else
	{
		AS_SetDescription( m_sDescPC );
	}
	
	Show();
}

simulated function Show()
{
	super.Show();

	Invoke("AnimateIn");
}

simulated function Hide()
{
	super.Hide();

	Invoke("AnimateOut");
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	bHandled = true;

	// Only pay attention to presses or repeats; ignoring other input types
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch( cmd )
	{
		// OnAccept
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
			Hide();
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			`ONLINEEVENTMGR.bSaveExplanationScreenHasShown = true;
			break;

		default:
			bHandled = false;
			break;
	}

	if (bHandled)
		return true;

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			if( args[args.Length-1] == "startButton" )
			{
				Movie.Pres.PlayUISound(eSUISound_MenuSelect);
				`ONLINEEVENTMGR.bSaveExplanationScreenHasShown = true;
				Hide();
			}
			break;
	}
}

simulated function OnCommand( string cmd, string arg )
{
	if( cmd == "AnimateOutComplete")
	{
		GoToNextScreen();
	}
}

simulated function GoToNextScreen()
{
	local XComShellPresentationLayer Presentation;

	Presentation = XComShellPresentationLayer(Owner);
	if( Presentation.Get2DMovie().DialogBox.ShowingDialog() )
	{   // Wait for all dialogs to close
		SetTimer(1, false, 'GoToNextScreen');
	}
	else if( Presentation.IsInState('State_MPLoadoutList', true) && Presentation.IsInState('State_SaveExplanationScreen'))
	{   
		//Let this close silently 
		Presentation.PopState();
	}
	else
	{   // Otherwise go straight to the main menu
		Presentation.EnterMainMenu();
	}
}

simulated function OnReceiveFocus()
{
	Show();
}

simulated function OnLoseFocus()
{
	Hide();
}

simulated function OnRemoved()
{
	if (XComShellPresentationLayer(Movie.Pres).m_dOnSaveExplanationScreenComplete != none)
	{
		XComShellPresentationLayer(Movie.Pres).m_dOnSaveExplanationScreenComplete();
		XComShellPresentationLayer(Movie.Pres).m_dOnSaveExplanationScreenComplete = none;
	}
}

//==============================================================================
// 		FLASH COMMUNICATION:
//==============================================================================
simulated function AS_SetButtonText( string text ) {
	Movie.ActionScriptVoid(MCPath$".SetButtonText");
}
simulated function AS_SetDescription( string text ) {
	Movie.ActionScriptVoid(MCPath$".SetDescription");
}
//==============================================================================
//		DEFAULTS:
//==============================================================================
defaultproperties
{
	Package   = "/ package/gfxSaveExplanationScreen/SaveExplanationScreen";
	MCName      = "theScreen";
	
	InputState = eInputState_Evaluate;

	bAlwaysTick  = true; // Allows us to set timers and have them work even when paused
}
