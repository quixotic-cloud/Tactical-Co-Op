//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDialogueBox.uc
//  AUTHOR:  Tronster - 1/10/2012
//           Brit Steiner - 7/12/11
//  PURPOSE: Generic pop-up, modal, dialog box.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2011-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDialogueBox extends UIScreen
	dependson(UICallbackData);

//----------------------------------------------------------------------------
// MEMBERS

enum EUIDialogBoxDisplay
{
	eDialog_Normal, //cyan
	eDialog_Warning, //red
	eDialog_Alert   //yellow
};

struct TDialogueBoxData
{
	var EUIDialogBoxDisplay eType;
	var bool                isShowing;
	var bool                isModal;
	var bool                bMuteAcceptSound;
	var bool                bMuteCancelSound;
	var string              strTitle;
	var string              strText; 
	var string              strAccept;
	var string              strCancel;
	var string              strImagePath;
	var SoundCue            sndIn;
	var SoundCue            sndOut;
	var delegate<ActionCallback> fnCallback;
	var delegate<ActionCallback> fnPreCloseCallback;
	var delegate<ActionCallbackEx> fnCallbackEx;
	var UICallbackData      xUserData;
	
	structdefaultproperties
	{
		isShowing   = false;
		strTitle    = "<DEFAULT TITLE>";
		strText     = "<DEFAULT BODY>"; 
		strAccept   = ""; 
		strCancel   = ""; 
		strImagePath= "";
		eType       = eDialog_Normal;
		xUserData   = none;
	}
};

enum EUIAction
{
	eUIAction_Accept,   // User initiated
	eUIAction_Cancel,   // User initiated
	eUIAction_Closed    // Automatically closed by system
};

var bool bIsHidingForCinematic; 

var localized string m_strDefaultAcceptLabel;
var localized string m_strDefaultCancelLabel;

var array<TDialogueBoxData> m_arrData;
var string strAccept;
var string strCancel;

// HAX: This is a safe way for screens that are interested in knowing when the dialog box has finished processing its m_arrData.
var delegate<DialogBoxClosed> m_fnClosedCallback;
delegate DialogBoxClosed();

delegate ActionCallback( eUIAction eAction );
delegate ActionCallbackEx( eUIAction eAction, UICallbackData xUserData );

// Flash Callback
simulated function OnInit()
{
	super.OnInit();

	RefreshNavigationHelp();
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( Movie, 'IsMouseActive', self, RefreshNavigationHelp);
	Realize();
	
	// Make sure Flash side push to top
	Movie.InsertHighestDepthScreen(self);
}


// Dialogs are displayed in LIFO order.
simulated function AddDialog( TDialogueBoxData kData )
{
	// If this add is in response to a callback from another dialog being dismissed; 
	// then ensure the new dialog is put BEFORE what is currently showing, because
	// what is showing is about to be popped off in the remove call.
	if ( m_arrData.Length > 0 && m_arrData[ m_arrData.Length - 1].isShowing )
	{
		m_arrData.InsertItem( m_arrData.Length - 1, kData );
	}
	else
	{
		m_arrData.AddItem( kData );
	}

	// Only add the dialog to the state stack once, but insert multiple instances into HighestDepthScreens array
	if(!Movie.Stack.IsInStack(self.Class))
		Movie.Stack.Push(self);

	Movie.InsertHighestDepthScreen(self);

	// Make sure dialogs get pushed to the top of the depth tree
	Realize();
}

// Internally remove the existing dialog
simulated function RemoveDialog()
{
	local TDialogueBoxData kData;

	kData = m_arrData[ m_arrData.Length - 1 ];

	if ( kData.sndOut != none )
		PlaySound( kData.sndOut );

	Movie.RemoveHighestDepthScreen( self );
	m_arrData.Remove( m_arrData.Length - 1, 1 );
	Realize();

	if(m_arrData.Length == 0)
	{
		Movie.Stack.Pop(self, false);

		if(m_fnClosedCallback != none)
			m_fnClosedCallback();
	}
}

//bsg, lmordarski (5,3,2012) adding this function to be used when certain system callbacks require a dialog to be displayed
//e.g. save device was removed.  In this case, this function will clear any current dialogs to display our own
simulated function ClearDialogs()
{
	//local delegate<ActionCallback> fnCallback;
	local delegate<ActionCallbackEx> fnCallbackEx;
	local int i;
	local TDialogueBoxData kData;

	for(i=m_arrData.Length-1; i>=0; --i)
	{
		kData = m_arrData[ i ];

		if ( kData.sndOut != none )
			PlaySound( kData.sndOut );

		//fnCallback = kData.fnCallback;
		//if ( fnCallback != none )
		//	fnCallBack( eUIAction_Closed );

		fnCallbackEx = kData.fnCallbackEx;
		if ( fnCallbackEx != none )
			fnCallBackEx( eUIAction_Closed, kData.xUserData );

		Movie.RemoveHighestDepthScreen( self );
		m_arrData.Remove( i, 1 );
		Realize();
	}

	Movie.Stack.Pop(self, false);

	if(m_fnClosedCallback != none)
		m_fnClosedCallback();
}
//bsg, lmordarski (5,3,2012) end

simulated function UpdateDialogText(string kText)
{
	if( m_arrData.Length > 0 )
	{
		m_arrData[ m_arrData.Length - 1 ].strText = kText;
		// Since the field is HTML, convert any \n to <br> to prevent weird spacing that will occur.
		Repl( m_arrData[ m_arrData.Length - 1 ].strText, "\n", "<br>", false );
		AS_SetText( m_arrData[ m_arrData.Length - 1 ].strText );
	}
}

// Make the top most piece of data the one displayed to the player
simulated function Realize()
{
	local TDialogueBoxData kData;

	if ( m_arrData.Length == 0 )
	{
		Hide();
		return;
	}
	
	if( bIsHidingForCinematic && !m_arrData[m_arrData.Length - 1].isModal )
	{
		// Hide the screen and wait until cinematics complete before re-showing it.
		XComPresentationLayerBase(Owner).SubscribeToUIUpdate(CheckUIHiddenForCinematics);
		Hide();
		return;
	}
	
	m_arrData[ m_arrData.Length - 1 ].isShowing = true;
	kData = m_arrData[ m_arrData.Length - 1 ];

	if ( kData.sndIn != none )
		PlaySound( kData.sndIn );     //  m_arrUnlocks[0].sndFanfare );

	switch( kData.eType )
	{
		case eDialog_Normal:
	        if(kData.strImagePath == "")
				AS_SetStyleNormal();
			else
				AS_SetStyleNormalWithImage();
			break;
		case eDialog_Warning:
			if(kData.strImagePath == "")
				AS_SetStyleWarning();
			else
				AS_SetStyleWarningWithImage();
			break;
		case eDialog_Alert:
			if(kData.strImagePath == "")
				AS_SetStyleAlert();
			else
				AS_SetStyleAlertWithImage();
			break;
	}

	AS_SetTitle( kData.strTitle );

	// Since the field is HTML, convert any \n to <br> to prevent weird spacing that will occur.
	Repl(kData.strText, "\n", "<br>", false );
	AS_SetText(kData.strText);

	if ( kData.strImagePath != "" )
		AS_SetImage( kData.strImagePath );

	RefreshNavigationHelp();
	Show();
}

simulated function CheckUIHiddenForCinematics()
{
	if( !bIsHidingForCinematic )
	{
		XComPresentationLayerBase(Owner).UnsubscribeToUIUpdate(CheckUIHiddenForCinematics);
		Realize();
	}
}

simulated function HideForCinematics()
{
	super.HideForCinematics();
	bIsHidingForCinematic = true;
}

simulated function ShowForCinematics()
{
	super.ShowForCinematics();
	bIsHidingForCinematic = false; 
}

// Debug function for displaying dialogs currently contained in stack.
simulated function TraceDialogsToConsole()
{
	local int i;

	`log("--[ UIDialogueBox Stack ]-----------------------------");

	if ( m_arrData.Length == 0 )
		`log("none");

	for( i = m_arrData.Length; i > 0; i-- )
		`log( i $ ": '" $ m_arrData[i].strTitle $ "', " $ m_arrData[i].strText );
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Pass on input if no dialog is showing.
	if ( m_arrData.Length < 1 )
		return false;

	// Only pay attention to release; ignoring other input types
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return true;

	bHandled = true;

	switch( cmd )
	{	
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
			if( strCancel != "" )
				OnCancel();
			else if( strAccept != "" )
				OnAccept();
			break;
`endif
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if( strAccept != "" )
				OnAccept();
				break;
		
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			if( strCancel != "" )
				OnCancel();
				break;
		default:
			bHandled = false;
	}

	// if this far, a dialog is raised and so all input needs consuming.
	return bHandled || super.OnUnrealCommand(cmd, arg);
}


simulated function bool TopIsModal()
{
	if( m_arrData.Length < 1 )
		return false;

	return m_arrData[ m_arrData.Length - 1 ].isModal;
}

simulated function bool DialogTypeIsShown(int type)
{
	local int i;
	local int length;

	length = m_arrData.Length;

	if( length < 1 )
		return false;

	for( i=0; i<length; i++)
	{
		if( m_arrData[ i ].eType == type )
		{
			return true;
		}
	}
	return false;
}

simulated function bool GetTopDialogBoxData(out TDialogueBoxData kData)
{
	if( m_arrData.Length < 1 )
		return false;

	kData = m_arrData[m_arrData.Length - 1];
	return true;
}

simulated function bool ShowingDialog()
{
	return m_arrData.Length > 0;
}

simulated function OnCommand( string cmd, string arg )
{
	if( cmd == "AnimateOutComplete") 
	{
		if(XComPresentationLayerBase(Owner) != none)
			Movie.Stack.Pop(self, false);
	}
}


simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string targetCallback;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			targetCallback = args[4];
			
			switch( targetCallback )
			{
				case "theStartButton":
					OnAccept();
					break;

				case "theBackButton":
					OnCancel();
					break;

				default:
					//nothing 
			}
			break;
	}
}



//NOTE: The callbacks should be *outside* this screen's pres layer state. 
// The callback is executed after the state is cleared, to keep the stack tidy
// in case the callback funciton pushes additional states. -bsteiner
simulated function bool OnAccept( optional string strOption = "" )
{
	local delegate<ActionCallback> fnCallback;
	local delegate<ActionCallbackEx> fnCallbackEx;
	local TDialogueBoxData kData;

	// in case the callbacks trigger another dialog we copy our data and remove ourselves before calling them
	kData = m_arrData[ m_arrData.Length - 1];

	if(!kData.bMuteAcceptSound)
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	fnCallback = kData.fnPreCloseCallback;
	if ( fnCallback != none )
		fnCallback( eUIAction_Accept );

	RemoveDialog();

	fnCallback = kData.fnCallback;
	if ( fnCallback != none )
		fnCallBack( eUIAction_Accept );

	fnCallbackEx = kData.fnCallbackEx;
	if ( fnCallbackEx != none )
		fnCallBackEx( eUIAction_Accept, kData.xUserData );

	return true;
}

simulated function bool OnCancel( optional string strOption = "" )
{
	local delegate<ActionCallback> fnCallback;
	local delegate<ActionCallbackEx> fnCallbackEx;
	local TDialogueBoxData kData;

	// in case the callbacks trigger another dialog we copy our data and remove ourselves before calling them
	kData = m_arrData[ m_arrData.Length - 1];

	if(!kData.bMuteCancelSound)
		Movie.Pres.PlayUISound(eSUISound_MenuClose);

	fnCallback = kData.fnPreCloseCallback;
	if ( fnCallback != none )
		fnCallback( eUIAction_Cancel );

	RemoveDialog();

	fnCallback = kData.fnCallback;
	if ( fnCallback != none )
		fnCallBack( eUIAction_Cancel );

	fnCallbackEx = kData.fnCallbackEx;
	if ( fnCallbackEx != none )
		fnCallBackEx( eUIAction_Cancel, kData.xUserData );

	return true;
}


// Update the buttons for console or mouse clicking
public function RefreshNavigationHelp()
{
	local TDialogueBoxData kData;

	if ( m_arrData.Length < 1 )
		return;

	strAccept = "";
	strCancel = "";

	kData = m_arrData[ m_arrData.Length - 1 ];
	if ( kData.strAccept != "" )    strAccept = kData.strAccept;
	if ( kData.strCancel != "" )    strCancel = kData.strCancel;

	// If nothing has been set then "Accept" is set to the default.
	if ( strAccept == "" && strCancel == "" )
	{
		strAccept = m_strDefaultAcceptLabel;
		strCancel = m_strDefaultCancelLabel;
	}

	AS_SetHelp( 0, strAccept, class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	AS_SetHelp( 1, strCancel, class'UIUtilities_Input'.static.GetBackButtonIcon());	
}


simulated function Show()
{
	// Ignore show if no data set to display.
	// Necessary for when the interface Movie slams on all screens (like it does
	// in tactical when starting a battle) -TMH
	if ( m_arrData.Length < 1 )
		return;

	super.Show();	
	Invoke("AnimateIn");
	InputState = eInputState_Consume;
}

simulated function Hide()
{
	super.Hide();
	InputState = eInputState_Evaluate;
}

event Destroyed()
{
	// Just to be safe, ensure there are no delegates floating around when this object is destroyed - sbatista 7/17/2013
	XComPresentationLayerBase(Owner).UnsubscribeToUIUpdate(CheckUIHiddenForCinematics);
}

//==============================================================================
//		FLASH COMMUNICATION:
//==============================================================================
simulated function AS_SetStyleNormal()
{ Movie.ActionScriptVoid( MCPath $ ".SetStyleNormal" ); }

simulated function AS_SetStyleNormalWithImage()
{ Movie.ActionScriptVoid( MCPath $ ".SetStyleNormalWithImage" ); }

simulated function AS_SetStyleWarning()
{ Movie.ActionScriptVoid( MCPath $ ".SetStyleWarning" ); }

simulated function AS_SetStyleWarningWithImage()
{ Movie.ActionScriptVoid( MCPath $ ".SetStyleWarningWithImage" ); }

simulated function AS_SetStyleAlert()
{ Movie.ActionScriptVoid( MCPath $ ".SetStyleAlert" ); }

simulated function AS_SetStyleAlertWithImage()
{ Movie.ActionScriptVoid( MCPath $ ".SetStyleAlertWithImage" ); }

simulated function AS_SetTitle( string text )
{ Movie.ActionScriptVoid( MCPath $ ".SetTitle" ); }

simulated function AS_SetText( string text )
{ Movie.ActionScriptVoid( MCPath $ ".SetText" ); }

simulated function AS_SetImage( string imagePath )
{ Movie.ActionScriptVoid( MCPath $ ".SetImage" ); }

simulated function AS_SetHelp(int index, string text, string buttonIcon)
{ Movie.ActionScriptVoid(MCPath$".SetHelp"); }

simulated function AS_SetMouseNavigationText( string text, string buttonIcon)
{ Movie.ActionScriptVoid(MCPath$".SetMouseNavigationText"); }

simulated function AS_UseMouseNavigation()
{ Movie.ActionScriptVoid( MCPath $ ".UseMouseNavigation" ); }

simulated function AS_UseControllerNavigation()
{ Movie.ActionScriptVoid( MCPath $ ".UseControllerNavigation" ); }



//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	bIsPermanent = true;
	bConsumeMouseEvents = true;

	Package   = "/ package/gfxDialogueBox/DialogueBox";
	MCName      = "theDialogueBox";

	bIsHidingForCinematic = false; 
}
