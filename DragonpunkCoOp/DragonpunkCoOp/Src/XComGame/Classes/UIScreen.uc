//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPanel.uc
//  AUTHOR:  Samuel Batista, Brit Steiner
//  PURPOSE: Base class for managing a SWF/GFx file that is loaded into the game.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIScreen extends UIPanel 
	native(UI)
	config(UI);

var name Package; // Complete Unreal package (UPK) path to the SWF 

var bool bIsIn3D;
var bool bIsPermanent; //Prevents automatic removal in the UI stack system. 
var bool bIsPendingRemoval; // Fix for when screens get removed before they get initialized.
var bool bIsVisiblePreCinematic;

var bool bShowDuringCinematic;
var bool bHideOnLoseFocus;

var bool bAnimateOut;

var config bool bPlayAnimateInDistortion;
var config bool bPlayIdleDistortion;

var config float IdleDistortionAnimationLength;
var config float IdleDistortionGapMin;
var config float IdleDistortionGapMax;
var config float MaxIdleStrength;
var config float AnimateInDistortionTime; // 0 to 1

var bool bAutoSelectFirstNavigable;

// Raises a Mouse Guard class underneath of this Screen if set to true
var bool bConsumeMouseEvents;
// Prevents components in this screen from processing mouse events if this is not the top of the Screen stack
var bool bProcessMouseEventsIfNotFocused;
var class<UIScreen> MouseGuardClass;

var int  CinematicWatch;

enum EUIInputState
{	
	eInputState_None,
	eInputState_Evaluate,
	eInputState_Consume
};

// Determines whether this panel responds to keyboard / gamepad input
var EUIInputState InputState;

//==============================================================================
//  INITIALIZATION
//==============================================================================

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	Screen = self;
	Movie = InitMovie;
	PC = InitController;

	InitPanel(InitName);

	// Are we displaying in a 3D surface?
	bIsIn3D = Movie.Class == class'UIMovie_3D';
	
	// Setup watch for force hide via cinematics.
	if (PC != none)
	{
		if( Movie.Stack.bCinematicMode )
			HideForCinematics();
	}
	else
		`warn("UIMovie::BaseInit - PlayerController (PC) == none!");

	Movie.Pres.PlayUISound(eSUISound_MenuOpen);
}

simulated function OnInit()
{
	super.OnInit();

	// If this screen was removed before it had the chance to complete initialization, make sure to clean it up.
	if ( bIsPendingRemoval )
	{
		Movie.RemoveScreen(self);
		return;
	}

	if( AcceptsInput() && bAutoSelectFirstNavigable )
		Navigator.SelectFirstAvailableIfNoCurrentSelection();
}

// ---------------------------------------------------------------------------
//  Default input handling
//

simulated function OnCommand(string cmd, string arg)
{
	`warn("Unhandled fscommand '" $ cmd $ "," $ arg $ "' sent to '" $ MCPath $ "'.",,'uicore' );
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	// Ensure we're at the top of the input stack - navigation commands should only be processed on top screen
	if ( Movie.Stack.GetCurrentScreen() != self )
		return false;

	// Pipe input commands through the Navigator system
	return Navigator.OnUnrealCommand(cmd, arg);
}

//Controls if a screen should automatically turn off during cinemtatic mode. 
simulated function AllowShowDuringCinematic( bool bShow )
{
	bShowDuringCinematic = bShow; 
}

simulated function CloseScreen()
{
	Movie.Stack.Pop(self);
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function MarkForDelayedRemove() 
{
	// Set a bool that will make the screen be removed when OnInit gets called.
	bIsPendingRemoval = true; 
	// Set the screen to ignore all input.
	InputState = eInputState_None;
}

// Called from CPP code when screen is removed
simulated event Removed()
{
	super.Removed();
	OnRemoved();
	`TOOLTIPMGR.RemoveTooltips(self);
}

// Override for custom cleanup logic
simulated function OnRemoved();

simulated function OnLoseFocus()
{
	// Don't call super.OnLoseFocus here: screens don't propagate their focus status to child controls
	bIsFocused = false;

	if(bHideOnLoseFocus)
		Hide();
}

simulated function OnReceiveFocus()
{
	// Don't call super.OnReceiveFocus here: screens don't propagate their focus status to child controls
	bIsFocused = true;

	if(bHideOnLoseFocus)
		Show();
}

simulated function Show()
{
	if( Movie.Stack.bCinematicMode && !bShowDuringCinematic )
	{
		bIsVisiblePreCinematic = true;
	}
	else
	{
		super.Show();
	}
}

simulated function Hide()
{
	if( Movie != none && Movie.Stack.bCinematicMode && !bShowDuringCinematic)
	{
		bIsVisiblePreCinematic = false;
	}
	else
	{
		// Hide tooltips on a screen that was previously hidden
		if(bIsVisible && `TOOLTIPMGR != none)
		{
			`TOOLTIPMGR.HideTooltipsByPartialPath(string(MCPath));
		}

		super.Hide();
	}
}

simulated function HideForCinematics()
{
	local bool bPreviouslyViz; 

	if( !bShowDuringCinematic )
	{
		bPreviouslyViz = bIsVisible;
		super.Hide(); //Call directly up to the UIPanel version.
		bIsVisiblePreCinematic = bPreviouslyViz;
	}
}

simulated function ShowForCinematics()
{
	if( bIsVisiblePreCinematic )
		super.Show(); //Call directly up to the UIPanel version.
}

// ---------------------------------------------------------------------------
//  Signals for Screen Listeners
// ---------------------------------------------------------------------------

simulated native function SignalOnInit();
simulated native function SignalOnReceiveFocus();
simulated native function SignalOnLoseFocus();
simulated native function SignalOnRemoved();

simulated native function PopulateListenerCache();
simulated native function UIScreenListener GetListener(int Index);

// ---------------------------------------------------------------------------
//  Input state accessors
//

simulated function SetInputState( EUIInputState eInputState )
{
	InputState = eInputState;
}

simulated native function bool AcceptsInput();
simulated native function bool ConsumesInput();
simulated native function bool EvaluatesInput();
simulated native function bool ConsumesMouseEvents();

simulated function OnMouseEvent(int cmd, array<string> args)
{
	// NOTE: Focus events have a different meaning for screens than they do for normal Panels.
	//       By intercepting mouse events we prevent the UIPanel from trigerring focus changes, 
	//       which are handled exclusively by the UIScreenStack for UIScreens.
	if( OnMouseEventDelegate != none )
		OnMouseEventDelegate(self, cmd);
}

//----------------------------------------------------------------------------

simulated function AnimateIn(optional float Delay = 0.0)
{
	super.AnimateIn(Delay);

	if( bPlayAnimateInDistortion && !PC.IsPaused() )
	{
		if( Delay > 0.0 )
			SetTimer(Delay, false, 'BeginAnimateInDistortion');
		else
			BeginAnimateInDistortion();
	}
}

simulated function BeginAnimateInDistortion()
{
	if( bIsIn3D )
		bPlayAnimateInDistortion = true;
	else
		Movie.Pres.StartDistortUI(AnimateInDistortionTime);
}

//----------------------------------------------------------------------------


DefaultProperties
{
	Package = "NONE";
	MCName = "theScreen"; // this matches the instance name of the EmptyScreen MC in components.swf
	LibID = "EmptyScreen"; // this is used to determine whether a LibID was overridden when UIMovie loads a screen
	
	bIsFocused = true;
	bCascadeFocus = false;
	bHideOnLoseFocus = true;

	bAnimateOnInit = true;
	bAnimateOut = true;

	CinematicWatch = -1;	
	bShowDuringCinematic = false;

	bConsumeMouseEvents	= false;
	bProcessMouseEventsIfNotFocused = false;
	bAutoSelectFirstNavigable = true;
	InputState = eInputState_Evaluate;

	MouseGuardClass = class'UIMouseGuard';
}
