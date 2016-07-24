//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIProgressDialogue.uc
//  AUTHOR:  sbatista - 2/28/12
//  PURPOSE: Generic progress notifier pop-up, modal, dialog box.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIProgressDialogue extends UIScreen;

//----------------------------------------------------------------------------
// MEMBERS
struct TProgressDialogData
{
	var string              strTitle;
	var string              strDescription;

	// No need to modify unless it needs to say something other then "Cancel"
	var string              strAbortButtonText;
	
	// IMPORTANT: Leaving this as none is the same as saying CANNOT ABORT THIS OPERATION.
	// User will not be able to close the dialog, and no button / gamepad help will be displayed. - sbatista 2/28/12

	// NOTE: This screen will pop itself before trigerring this callback.
	var delegate<ButtonPressCallback> fnCallback;

	var delegate<ProgressDialogOpenCallback> fnProgressDialogOpenCallback;

	structdefaultproperties
	{
		strTitle            = "<NO DATA PROVIDED>";
		strAbortButtonText  = "<DEFAULT ABORT>";
	}
};
var  TProgressDialogData m_kData; 

var delegate<ButtonPressCallback> m_fnCallback;
delegate ButtonPressCallback();

delegate ProgressDialogOpenCallback();

//==============================================================================
// 		INITIALIZATION / INPUT:
//============================================================================

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_fnCallback = m_kData.fnCallback;
	ProgressDialogOpenCallback = m_kData.fnProgressDialogOpenCallback;

	if(m_fnCallback == none)
		m_kData.strAbortButtonText = "";
	else if(m_kData.strAbortButtonText == "<DEFAULT ABORT>" )
		m_kData.strAbortButtonText = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
}

simulated function OnInit()
{
	if ( bIsPendingRemoval )
	{
		// Message should be removed, but only after:
		// 1) We filled in the data, above, so the box isn't blank (set delayed remove to false so it won't get removed immediately).
		// 2) A small time delay, so that the flash of the box at least makes sense. Casey suggested a half-second minimum.
		bIsPendingRemoval = false;
		SetTimer( 0.5, false, 'DelayedRemoval');
	}

	super.OnInit();

	`log("ProgressDialogue::OnInit()"@`ShowVar(bIsPendingRemoval),,'uixcom');

	AS_SetTitle(Caps(m_kData.strTitle));
	AS_SetDescription(m_kData.strDescription);
	
	AS_SetButtonHelp( m_kData.strAbortButtonText, class'UIUtilities_Input'.static.GetBackButtonIcon() );

	Movie.InsertHighestDepthScreen(self);
	Show();
}

simulated function DelayedRemoval()
{
	Movie.RemoveScreen(self); 

	// Remove this screen.
	if(XComPresentationLayerBase(Owner) != none)
		XComPresentationLayerBase(Owner).UICloseProgressDialog(); 
}

event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	// Call ProgressDialogOpenCallback after the first update.
	// Doing this here to avoid a flash callback.
	if( bIsInited && ProgressDialogOpenCallback != none )
	{
		ProgressDialogOpenCallback();
		ProgressDialogOpenCallback = none;
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to release; ignoring other input types
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			OnCancel();
			Movie.Pres.PlayUISound(eSUISound_MenuClose);
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string targetCallback;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			targetCallback = args[args.Length - 1];
			if(targetCallback == "theButton")
				OnCancel();

			break;
	}
}

//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================
simulated function bool OnCancel( optional string strOption = "" )
{
	if(m_fnCallback != none)
	{
		// Remove this screen.
		if(XComPresentationLayerBase(Owner) != none)
			XComPresentationLayerBase(Owner).UICloseProgressDialog(); 

		m_fnCallback();
	}

	return true;
}

simulated function Show()
{
	super.Show();
	// TODO: Don't yet know how to solve the lack of animation problem - sbatista 2/28/12
	//Invoke("AnimateIn");
}

simulated function UpdateData( string title, string description )
{
	m_kData.strTitle = title;
	m_kData.strDescription = description;

	if( !bIsInited ) return; 

	AS_SetTitle(Caps(m_kData.strTitle));
	AS_SetDescription(m_kData.strDescription);
}

simulated function OnRemoved()
{
	// Remove this screen.
	if(XComPresentationLayerBase(Owner) != none)
		XComPresentationLayerBase(Owner).UICloseProgressDialog(); 
}


//==============================================================================
//		FLASH COMMUNICATION:
//==============================================================================
simulated function AS_SetTitle( string text ) {
	Movie.ActionScriptVoid( MCPath $ ".SetTitle" );
}
simulated function AS_SetDescription( string text ) {
	Movie.ActionScriptVoid( MCPath $ ".SetDescription" );
}
simulated function AS_SetButtonHelp( string buttonText, string icon ) {
	Movie.ActionScriptVoid( MCPath $ ".SetButtonHelp" );
}


//==============================================================================
//		DEFAULTS:
//==============================================================================
defaultproperties
{
	Package   = "/ package/gfxProgressDialogue/ProgressDialogue";
	MCName      = "theProgressDialogue";
	
	InputState = eInputState_Consume;

	// We need to tick in order to fire off ProgressDialogOpenCallback on the first update
	bAlwaysTick = true;
}
