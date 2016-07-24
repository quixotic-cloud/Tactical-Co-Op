//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInputSteam.uc
//  AUTHOR:  Brit Steiner - 2/1/2016
//  PURPOSE: Interface to native for Steam input dialogue calls. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIInputSteam extends Object
	dependson(XComInputBase)
	native;

// mirrored from steam_api.h
struct native GamepadTextInputDismissed
{
	var bool m_bSubmitted;										// true if user entered & accepted text (Call ISteamUtils::GetEnteredGamepadTextInput() for text), false if canceled input
	var int m_unSubmittedText;

};

var native bool m_bInitialized;

var UIInputDialogue InputDialogueScreen; 

var native string UserText;


native function Init(string Title, int MaxChars, string InputBoxText, int DialogType, bool bIsPassword);

//==============================================================================
// 		INITIALIZATION / INPUT:
//============================================================================

simulated function InitLink( UIInputDialogue Screen )
{
	InputDialogueScreen = Screen; 

	Init(InputDialogueScreen.m_kData.strTitle, 
		 InputDialogueScreen.m_kData.iMaxChars, 
		 InputDialogueScreen.m_kData.strInputBoxText, 
		 InputDialogueScreen.m_kData.DialogType, 
		 InputDialogueScreen.m_kData.bIsPassword);
}

event OnAccept(string Text)
{
	UserText = Text;
	// Use a delay to allow the Steam overlay to clean itself up. 
	InputDialogueScreen.SetTimer(0.5, false, 'NotifyAccept', self);
}

function NotifyAccept()
{
	InputDialogueScreen.OnAccept(UserText);
	InputDialogueScreen.Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

event OnCancel()
{
	// Use a delay to allow the Steam overlay to clean itself up. 
	InputDialogueScreen.SetTimer(0.5, false, 'NotifyCancel', self);
}

function NotifyCancel()
{
	InputDialogueScreen.OnCancel();
	InputDialogueScreen.Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

cpptext
{
	virtual void OnInputBoxClosed(FGamepadTextInputDismissed CallbackData);

	virtual void BeginDestroy();
}