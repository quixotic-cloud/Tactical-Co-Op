//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShellDifficulty.uc
//  AUTHOR:  Brit Steiner       -- 01/25/12
//           Tronster           -- 04/13/12
//  PURPOSE: Controls the difficulty menu in the shell SP game. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChooseIronMan extends UIScreen;

var localized string m_strStartNoIronMan;
var localized string m_strIronmanTitle;
var localized string m_strIronmanBody;
var localized string m_strIronmanOK;
var localized string m_strIronmanCancel;

var localized string m_strWaitingForSaveTitle;
var localized string m_strWaitingForSaveBody;

var UILargeButton    m_StartWithoutIronmanButton;
var UIButton         m_CancelButton;
var UILargeButton    m_StartButton;

var bool m_bControlledStart;
var bool m_bIronmanFromShell;
var bool m_bFirstTimeNarrative;
		 
var bool m_bSaveInProgress;

var bool m_bIsPlayingGame;

var UIShellStrategy DevStrategyShell;

//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	
	m_StartButton = Spawn(class'UILargeButton', self);
	m_StartButton.InitLargeButton('ironmanToggle', m_strIronmanOK, "", ConfirmIronman);

	m_StartWithoutIronmanButton = Spawn(class'UILargeButton', self);
	m_StartWithoutIronmanButton.InitLargeButton('ironmanLaunchButton', m_strStartNoIronMan, "", ConfirmWithoutIronman);
	Navigator.SetSelected(m_StartWithoutIronmanButton);

	m_CancelButton = Spawn(class'UIButton', self);
	m_CancelButton.bIsNavigable = false;
	m_CancelButton.InitButton('ironmanCancelButton', m_strIronmanCancel, OnButtonCancel);

	`XPROFILESETTINGS.Data.ClearGameplayOptions();
}


//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	super.OnInit();	

	SetX(500);

	BuildMenu();
}

//----------------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return true;

	if( m_bSaveInProgress ) 
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return true;
	}
	
	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			//bsg lmordarski only enable the advanced options in the shell
			if(Movie.Pres.m_eUIMode == eUIMode_Shell)
			{
				Movie.Pres.PlayUISound(eSUISound_MenuSelect);			
			}
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			ConfirmIronman(m_StartButton);
			return true;
			
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN: 
			OnUCancel();
			return true;
	}
	

	return super.OnUnrealCommand(cmd, arg);
}


//----------------------------------------------------------------------------

simulated function BuildMenu()
{
	AS_SetIronManMenu( m_strIronmanTitle, m_strIronmanBody, m_strIronmanOK, m_strStartNoIronMan, m_strIronmanCancel );
}

// Lower pause screen
simulated public function OnUCancel()
{
	if( bIsInited )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		Movie.Stack.Pop(self); 
	}
}

simulated public function OnButtonCancel(UIButton ButtonControl)
{
	if( bIsInited )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		Movie.Stack.Pop(self); 
	}
}


simulated public function ConfirmIronman(UIButton ButtonControl)
{
	local UIShellDifficulty difficultyMenu;
	difficultyMenu = UIShellDifficulty(Movie.Stack.GetFirstInstanceOf(class'UIShellDifficulty'));
	difficultyMenu.UpdateIronman(true);
	Movie.Stack.Pop(self);
	Movie.Pres.UIShellNarrativeContent();
}

simulated public function ConfirmWithoutIronman(UIButton ButtonControl)
{
	local UIShellDifficulty difficultyMenu;
	difficultyMenu = UIShellDifficulty(Movie.Stack.GetFirstInstanceOf(class'UIShellDifficulty'));
	difficultyMenu.UpdateIronman(false);
	Movie.Stack.Pop(self); 
	Movie.Pres.UIShellNarrativeContent();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Show();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Hide();
}

simulated function AS_SetIronManMenu(string title, string message, string IronMan, string launchLabel, string CancelLabel)
{
   Movie.ActionScriptVoid(MCPath$".UpdateIronmanMenu"); 
}

DefaultProperties
{
	Package   = "/ package/gfxDifficultyMenu/DifficultyMenu";
	LibID     = "DifficultyMenu_Ironman" 

	InputState= eInputState_Consume;
	m_bSaveInProgress = false;
}