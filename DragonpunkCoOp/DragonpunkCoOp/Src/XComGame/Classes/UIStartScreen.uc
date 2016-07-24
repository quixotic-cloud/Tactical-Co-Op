//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStartScreen.uc
//  AUTHOR:  Brit Steiner - 11/4/10
//  PURPOSE: This file corresponds to the shell "press A to start" screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UIStartScreen extends UIScreen
	dependson(UIDialogueBox);

//----------------------------------------------------------------------------
// MEMBERS

var localized string   m_sPressStartXbox;
var localized string   m_sPressStartPS3;
var localized string   m_sPressStartPC;
var localized string   m_sVersionLabel;

var localized string   m_sController1Required;
var localized string   m_sStandardControllerRequired;

var bool bButtonDownEventCaptured;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}

simulated function OnInit()
{
	local string startMessage; 

	super.OnInit(); 

	if( Movie.IsMouseActive() )
	{
		AS_SetButtonText(m_sPressStartPC);
		AS_SetText("");
	}
	else
	{
		if( WorldInfo.IsConsoleBuild( CONSOLE_PS3 ) )
			startmessage = m_sPressStartPS3; 
		else
			startMessage = Repl(m_sPressStartXbox, "%BUTTON", class'UIUtilities_Input'.static.HTML(class'UIUtilities_Input'.const.ICON_START, 30, -5) , false);

		AS_SetText( startMessage );
		AS_SetButtonText("");
	}

	AS_SetVersion( "" );
	
	Show();

	// Ensure that all user login information has been cleared
	`ONLINEEVENTMGR.ResetLogin();

	`XENGINE.GameViewport.HandleInputKey = HandleInputKey;

	// Will display any pending information for the user since the screen has been transitioned. -ttalley
	`ONLINEEVENTMGR.PerformNewScreenInit();
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	
	SubscribeToOnCleanupWorld(); // When setting a delegate on an object, it must be cleaned up when traveling to a new map (i.e. invite which does not trigger normal UI exit code)
	`ONLINEEVENTMGR.AddGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.AddGameInviteCompleteDelegate(OnGameInviteComplete);
}

event Destroyed()
{
	super.Destroyed();
	UnsubscribeFromOnCleanupWorld();
	Cleanup();
}

simulated event OnCleanupWorld()
{
	super.OnCleanupWorld();
	Cleanup();
}

function Cleanup()
{
	`XENGINE.GameViewport.HandleInputKey = none;
	`ONLINEEVENTMGR.ClearBeginShellLoginDelegate(OnShellLoginComplete);
	`ONLINEEVENTMGR.ClearGameInviteAcceptedDelegate(OnGameInviteAccepted);
	`ONLINEEVENTMGR.ClearGameInviteCompleteDelegate(OnGameInviteComplete);
}

simulated function OnGameInviteAccepted(bool bWasSuccessful)
{
	local XComPresentationLayerBase Presentation;
	local TProgressDialogData kDialogData;

	`log(`location @ `ShowVar(`ONLINEEVENTMGR.bInShellLoginSequence), true, 'XCom_Online');
	if( !`ONLINEEVENTMGR.bInShellLoginSequence && bWasSuccessful)
	{
		// Only show the progress dialog if the shell login sequence is not active. Otherwise conflicts may occur.
		Presentation = Movie.Pres;
		kDialogData.strTitle = `ONLINEEVENTMGR.m_sAcceptingGameInvitation;
		kDialogData.strDescription = `ONLINEEVENTMGR.m_sAcceptingGameInvitationBody;
		Presentation.UIProgressDialog(kDialogData);
	}
	else
	{
		// If an invite is being accepted during the shell login sequence then pretend that
		// the shell login sequence failed. If it actually succeeds the game invite will
		// take us off the start screen. If it fails then we're in the correct state anyway.
		// Not calling OnShellLoginComplete will leave a successful invite unable to join
		// the game properly.
		OnShellLoginComplete(false);
	}
}

simulated function OnGameInviteComplete(ESystemMessageType MessageType, bool bWasSuccessful)
{
	local XComPresentationLayerBase Presentation;
	`log(`location @ `ShowVar(MessageType) @ `ShowVar(bWasSuccessful),,'XCom_Online');

	if (!bWasSuccessful)
	{
		// Only close the progress dialog if there was a failure.
		Presentation = Movie.Pres;
		Presentation.UICloseProgressDialog();
		`ONLINEEVENTMGR.QueueSystemMessage(MessageType);
	}
}

simulated function BeginLogin(int ControllerId, bool bGamepad)
{
	// Don't try to handle input during the shell login process
	`XENGINE.GameViewport.HandleInputKey = none;

	`log("Start Screen Calling Login",,'XCom_Online');
	`ONLINEEVENTMGR.AddBeginShellLoginDelegate(OnShellLoginComplete);
	`ONLINEEVENTMGR.BeginShellLogin(ControllerId);
}

simulated function OnShellLoginComplete(bool bWasSuccessful)
{
	`ONLINEEVENTMGR.ClearBeginShellLoginDelegate(OnShellLoginComplete);
	if( bWasSuccessful )
	{
		// Leave the start screen
		Hide();
	}
	else
	{
		// Shell login failed. Start listening for input again.
		`XENGINE.GameViewport.HandleInputKey = HandleInputKey;
	}
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

simulated function bool HandleInputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed, bool bGamepad)
{
	local XComOnlineEventMgr OnlineEventMgr;
	local XComPresentationLayerBase Presentation;
	local bool bHandled;
	bHandled = false;

	OnlineEventMgr = `ONLINEEVENTMGR;
	Presentation = XComPresentationLayerBase(Owner);

	if( !Presentation.Get2DMovie().DialogBox.ShowingDialog() &&
	    !OnlineEventMgr.bInShellLoginSequence &&
	    OnlineEventMgr.NumSystemMessages() == 0 )
	{
		if( EventType == IE_Pressed )
		{
			switch( Key )
			{
				// OnAccept
				case 'XboxTypeS_A':
				case 'XboxTypeS_Start':
				case 'Enter':
					bButtonDownEventCaptured = true;
					bHandled = true;
					break;

				default:
					bHandled = false;
					break;
			}
		}
		else if( EventType == IE_Released && bButtonDownEventCaptured )
		{
			if( WorldInfo.IsConsoleBuild(CONSOLE_PS3) )
			{
				if( ControllerId != 0 )
				{
					// Ignore input from anything other than the first controller on PS3
					ShowController1RequiredDialog();
					return false;
				}
				else if( !OnlineEventMgr.StandardControllerInUsePS3(ControllerId) )
				{
					// Require a standard controller on PS3
					ShowStandardControllerRequiredDialog();
					return false;
				}
			}

			switch( Key )
			{
				// OnAccept
				case 'XboxTypeS_A':
				case 'XboxTypeS_Start':
				case 'Enter':
					Movie.Pres.PlayUISound(eSUISound_MenuSelect);
					BeginLogin(ControllerId, bGamepad);
					bHandled = true;
					break;

				default:
					bHandled = false;
					break;
			}
		}
	}

	return bHandled;
} 
simulated function OnMouseEvent(int cmd, array<string> args)
{
	local XComOnlineEventMgr OnlineEventMgr;
	local XComPresentationLayerBase Presentation;

	OnlineEventMgr = `ONLINEEVENTMGR;
	Presentation = XComPresentationLayerBase(Owner);

	if( !Presentation.Get2DMovie().DialogBox.ShowingDialog() &&
	    !OnlineEventMgr.bInShellLoginSequence &&
	    OnlineEventMgr.NumSystemMessages() == 0 )
	{
		switch( cmd )
		{
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
				if( args[args.Length-1] == "startButton" )
				{
					Movie.Pres.PlayUISound(eSUISound_MenuSelect);
					BeginLogin(0, false);
				}
				break;
		}
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
	else if( !`ONLINEEVENTMGR.bSaveExplanationScreenHasShown )
	{   // Show the save explanation screen if it hasn't shown this session
		Presentation.UISaveExplanationScreenState();
	}
	else
	{   // Otherwise go straight to the main menu
		Presentation.EnterMainMenu();
	}
}

simulated function ShowController1RequiredDialog()
{
	local TDialogueBoxData DialogData;

	// Only show this dialog if we aren't already asking the player to replace controller 1.  -dwuenschell
	if( !XComPresentationLayerBase(Owner).IsShowingReconnectControllerDialog() )
	{
		DialogData.eType = eDialog_Normal;
		DialogData.strText = m_sController1Required;
		DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

		XComPresentationLayerBase(Owner).UIRaiseDialog(DialogData);
	}
}

simulated function ShowStandardControllerRequiredDialog()
{
	local TDialogueBoxData DialogData;

	// Only show this dialog if we aren't already asking the player to replace controller 1.  -dwuenschell
	if( !XComPresentationLayerBase(Owner).IsShowingReconnectControllerDialog() )
	{
		DialogData.eType = eDialog_Normal;
		DialogData.strText = m_sStandardControllerRequired;
		DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

		XComPresentationLayerBase(Owner).UIRaiseDialog(DialogData);
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

//==============================================================================
// 		FLASH COMMUNICATION:
//==============================================================================
simulated function AS_SetText( string text ) {
	Movie.ActionScriptVoid(MCPath$".SetText");
}
simulated function AS_SetVersion( string text ) {
	Movie.ActionScriptVoid(MCPath$".SetVersion");
}
simulated function AS_SetButtonText( string text ) {
	Movie.ActionScriptVoid(MCPath$".SetButtonText");
}
simulated function AS_TraceThings( int numTraces) {
	Movie.ActionScriptVoid(MCPath$".TraceThings");
}
simulated function AS_NoTrace() {
	Movie.ActionScriptVoid(MCPath$".NoTrace");
}
//==============================================================================
//		DEFAULTS:
//==============================================================================
defaultproperties
{
	Package   = "/ package/gfxStartScreen/StartScreen";
	MCName      = "theStartScreen";
	
	InputState = eInputState_Evaluate;
	bAlwaysTick  = true; // Allows us to set timers and have them work even when paused

	bButtonDownEventCaptured = false
}
