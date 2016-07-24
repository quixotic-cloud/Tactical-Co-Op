//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIProgressDialogue.uc
//  AUTHOR:  sbatista - 2/28/12
//  PURPOSE: Generic progress notifier pop-up, modal, dialog box.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIInputDialogue extends UIScreen
	dependson(XComInputBase);

const SMALL_BOX = 0;
const LARGE_BOX = 1;
const REPORT = 2;

enum InputDialogType
{
	eDialogType_SingleLine,
	eDialogType_MultiLine,
	eDialogType_Report,
};

//----------------------------------------------------------------------------
// MEMBERS
struct TInputDialogData
{
	var string              strTitle;
	var string              strInputBoxText;
	var int                 iMaxChars;
	var InputDialogType     DialogType;
	var bool                bIsPassword;

	// NOTE: This screen will pop itself before triggerring this callback.
	var delegate<TextInputClosedCallback> fnCallback;
	var delegate<TextInputCancelledCallback> fnCallbackCancelled;
	var delegate<TextInputAcceptedCallback> fnCallbackAccepted;

	var delegate<TextInputClosedCallback_Report> fnCallback_report;
	var delegate<TextInputCancelledCallback_Report> fnCallbackCancelled_report;
	var delegate<TextInputAcceptedCallback_Report> fnCallbackAccepted_report;

	structdefaultproperties
	{
		bIsPassword         = false;
		strTitle            = "<NO DATA PROVIDED>";
		iMaxChars           = 27; // first name [11] + space [1] + last name [16]  
	}
};

var TInputDialogData m_kData;
var UINavigationHelp NavHelp;

var UIInputSteam SteamInput; 

delegate TextInputClosedCallback(string newText);
delegate TextInputAcceptedCallback(string newText);
delegate TextInputCancelledCallback(string newText);

delegate TextInputClosedCallback_Report(string newTitle, string newText);
delegate TextInputAcceptedCallback_Report(string newTitle, string newText);
delegate TextInputCancelledCallback_Report(string newTitle, string newText);

//==============================================================================
// 		INITIALIZATION / INPUT:
//============================================================================

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	if( `XENGINE.m_SteamControllerManager.IsSteamControllerActive() )
	{
		SteamInput = new class'UIInputSteam';
		SteamInput.InitLink(self);
		Hide();
	}
	else
	{
		NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp('helpBarMC');

		NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericCancel, class'UIUtilities_Input'.static.GetBackButtonIcon(), OnMouseCancel);
		NavHelp.AddRightHelp(class'UIUtilities_Text'.default.m_strGenericConfirm, class'UIUtilities_Input'.static.GetAdvanceButtonIcon(), OnMouseAccept);

		XComInputBase(PC.PlayerInput).RawInputListener = RawInputHandler;
	}
}

simulated function OnInit()
{
	super.OnInit();
	if( SteamInput == none )
	{
		SetData(m_kData.strTitle, m_kData.iMaxChars, m_kData.strInputBoxText, m_kData.DialogType, m_kData.bIsPassword);
	}
}

simulated function bool RawInputHandler(Name Key, int ActionMask, bool bCtrl, bool bAlt, bool bShift)
{
	if(!Movie.IsMouseActive())
		return false;

	// NOTE: When editing large text, don't trigger accept when user presses 'Enter', so they can enter line breaks -sbatista
	if(Key == 'Enter' && m_kData.DialogType == eDialogType_SingleLine)
		OnAccept();
	else if(Key == 'Escape' || Key == 'RightMouseButton')
		OnCancel();

	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to release; ignoring other input types
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false; // Consume all input!

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			OnAccept();
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			break;
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			OnCancel();
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			break;
	}

	return super.OnUnrealCommand(cmd, arg);

}


simulated function OnCommand( string cmd, string arg )
{
	if( cmd == "AnimateOutComplete") 
	{
		if(XComPresentationLayerBase(Owner) != none)
			Movie.Stack.Pop(self);
	}
}

//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================
simulated function OnMouseAccept() { OnAccept(); }
simulated function bool OnAccept( optional string strOption = "" )
{
	local string Result;
	local string ResultTitle;
	local delegate<TextInputClosedCallback> OnClosed, OnAccepted;
	local delegate<TextInputClosedCallback_Report> OnClosedReport, OnAcceptedReport;

	Result = ValidateResultText();
	ResultTitle = ValidateResultTitle();

	Movie.Stack.PopIncluding(self);

	if(m_kData.DialogType == eDialogType_Report)
	{
		OnClosedReport = m_kData.fnCallback_report;
		if(OnClosedReport != none)
			OnClosedReport(ResultTitle, Result);
	}
	else
	{
		OnClosed = m_kData.fnCallback;
		if(OnClosed != none)
			OnClosed(Result);
	}
	
	if(m_kData.DialogType == eDialogType_Report)
	{
		OnAcceptedReport = m_kData.fnCallbackAccepted_report;
		if(OnAcceptedReport != none)
			OnAcceptedReport(ResultTitle, Result);
	}
	else
	{
		OnAccepted = m_kData.fnCallbackAccepted;
		if(OnAccepted != none)
			OnAccepted(Result);
	}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	return true;
}
simulated function OnMouseCancel() { OnCancel(); }
simulated function bool OnCancel( optional string strOption = "" )
{
	local delegate<TextInputClosedCallback> OnClosed, OnCancelled;
	local delegate<TextInputClosedCallback_Report> OnClosedReport, OnCancelledReport;

	Movie.Stack.PopIncluding(self);

	if(m_kData.DialogType == eDialogType_Report)
	{
		OnClosedReport = m_kData.fnCallback_report;
		if(OnClosedReport != none)
			OnClosedReport(m_kData.strTitle, m_kData.strInputBoxText);
	}
	else
	{
		OnClosed = m_kData.fnCallback;
		if(OnClosed != none)
			OnClosed(m_kData.strInputBoxText);
	}

	if(m_kData.DialogType == eDialogType_Report)
	{
		OnCancelledReport = m_kData.fnCallbackCancelled_report;
		if(OnCancelledReport != none)
			OnCancelledReport(m_kData.strTitle, m_kData.strInputBoxText);
	}
	else
	{
		OnCancelled = m_kData.fnCallbackCancelled;
		if(OnCancelled != none)
			OnCancelled(m_kData.strInputBoxText);
	}
	
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	return true;
}

simulated function string ValidateResultText()
{
	local string Result;

	Result = AS_GetInputText();
	
	// Don't allow blank strings
	if( IsWhitespace(Result, Len(Result)) )
		Result = "";
	else
		class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(Result);

	return Result;
}

simulated function string ValidateResultTitle()
{
	local string Result;

	Result = AS_GetTitleText();

	// Don't allow blank strings
	if(IsWhitespace(Result, Len(Result)))
		Result = "";
	else
	class'UIUtilities_Text'.static.StripUnsupportedCharactersFromUserInput(Result);

	return Result;
}

simulated function bool IsWhitespace( string strInput, int char_max )
{
	local int i;
	local string temp;
	local bool b_acceptName;

	for( i = 0 ; i < char_max ; i++ )
	{
		temp = temp $ " ";
		if( strInput == temp )
			b_acceptName = true;
	}
	return b_acceptName;
}

//==============================================================================
//		FLASH COMMUNICATION:
//==============================================================================
simulated function SetData( string title, int maxChars, string textBoxText, int textBoxType, bool isPassword)
{
	Movie.ActionScriptVoid( MCPath $ ".SetData" );
}
simulated function string AS_GetInputText() 
{
	if( SteamInput != none )
	{
		return SteamInput.UserText;
	}
	else
	{
		return Movie.ActionScriptString(MCPath $ ".GetInputText");
	}
}
simulated function string AS_GetTitleText()
{
	if( SteamInput != none )
	{
		return ""; //Do we allow entry here? 
	}
	else
	{
		return Movie.ActionScriptString(MCPath $ ".GetTitleText");
	}
}
//==============================================================================
//		DEFAULTS:
//==============================================================================
defaultproperties
{
	Package = "/ package/gfxInputDialogue/InputDialogue";
	MCName = "theInputDialogueScreen";
	InputState = eInputState_Consume;
	bConsumeMouseEvents = true;
	bAlwaysTick = true
	bProcessMouseEventsIfNotFocused = true;
}
