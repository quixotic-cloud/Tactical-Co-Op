class XComInputBase extends PlayerInput
	native(UI)
	config(Input);

cpptext
{
	virtual UBOOL InputKey(INT ControllerId, FName Key, enum EInputEvent Event, FLOAT AmountDepressed = 1.f, UBOOL bGamepad = FALSE);
	virtual UBOOL InputAxis(INT ControllerId, FName Key, FLOAT Delta, FLOAT DeltaTime, UBOOL bGamepad=FALSE);
	virtual void  UpdateAxisValue( FLOAT* Axis, FLOAT Delta );
}

var bool bAutoTest;
var float fAutoBaseY;
var float fAutoStrafe;

var float m_fSteamControllerGeoscapeScrollX;
var float m_fSteamControllerGeoscapeScrollY;

var float m_fSteamControllerGeoscapeZoomOffset;

var bool m_bSteamControllerInGeoscapeView;

struct native TInputSubscriber
{
	var int iButton;                //button even that we're waiting for 
	var float fTimeThreshold;       // threshold to wait for callback
	//var delegate<SubscriberCallback> fCallbackFunction; //function to call when event is triggered
	var delegate<SubscriberCallback> CallbackFunction; //function to call when event is triggered
	
	structdefaultproperties{} 
}; 

struct native TInputIdleTracker
{
	var int iButton;         //button even that we're waiting for 
	var float fTime;         // threshold to wait for callback
	var bool bValid; 

	structdefaultproperties
	{
		iButton = -1;
		fTime = -1;
		bValid = false;
	} 
}; 

struct native TInputEventTracker
{
	var int iButton;         // FXS_INPUT button even that we're waiting for 
	var float fTime;         // Current delta time 

	structdefaultproperties
	{
		iButton = -1;
		fTime   = 0;
	} 
}; 


var array<TInputSubscriber>     m_arrSubscribers; 
var array<TInputIdleTracker>    m_arrIdleTrackers; 
var array<TInputEventTracker>   m_arrEventTrackers; 

var float                   m_fLTrigger;
var float                   m_fRTrigger;
var float                   m_fRTriggerAngleDegrees;
var bool                    m_bRTriggerActive;

//We're caching these axes as members, because the raw values are set only during 
//the PlayerInput event and not available during our standard input cascade. 
var float                   m_fLSXAxis;
var float                   m_fLSYAxis;
var float                   m_fRSXAxis;
var float                   m_fRSYAxis;

// Double click 
var int   m_iDoubleClickNumClicks;
var float m_fDoubleClickLastClick;

/** If set will get a first crack at the raw input stream. */
var delegate<RawInputHandler> RawInputListener;
var array<delegate<RawInputHandler> > ListenersArray;


// Duration a button must be pressed to trigger a "Hold" input command
const RELEASE_THRESHOLD = 0.3f;

// Frequency at which hold signals will be generated once the release threshold has been crossed.
const SIGNAL_REPEAT_FREQUENCY = 0.1f;

// Bounds of the area in the center of the joystick that will be considered neutral
const RSTICK_THRESHOLD = 0.5; // right stick is now normailzed
const LSTICK_THRESHOLD = 500;
const LSTICK_MAX_THRESHOLD = 3300; 
const RSTICK_MAX_THRESHOLD = 550; 
const LTRIGGER_MAX_THRESHOLD = 1.0; 
const RTRIGGER_MAX_THRESHOLD = 1.0; 

// The length a stick must be active before the repeat commands are sent
const STICK_REPEAT_THRESHOLD = 0.0f;

// Used to prevent TestConsumedByFlash() to execute it's logic more than once a frame.
var bool m_bConsumedByFlashCached;
var bool m_bConsumedBy3DFlashCached;
var bool m_bConsumedByFlash;

var config bool bForceEnableController; 
var bool m_bInputSinceMouseMovement; 
var float aMouseXCached;
var float aMouseYCached; 

// Idle subscription function callback
delegate SubscriberCallback(); 

/** Defines delegate type for RawInputListener. Do not set. Use RawInputListener property instead. */
delegate bool RawInputHandler(Name Key, int ActionMask, bool bCtrl, bool bAlt, bool bShift);


// Using these functions to set raw input delegates allows us to handle the case where screens might clobber existing raw input handlers
// (currently used in UIMultiplayerChatManager and UIKeybindingsPCScreen).
function SetRawInputHandler(delegate<RawInputHandler> handler)
{
	ListenersArray.AddItem(handler);
	RawInputListener = handler;
}
function RemoveRawInputHandler(delegate<RawInputHandler> handler)
{
	if(ListenersArray.Length == 0 || ListenersArray[ListenersArray.Length - 1] != handler)
	{
		XComPlayerController(Outer).Pres.PopupDebugDialog("UI ERROR - RemoveRawInputHandler", "Removing a handler that isn't in the top element in the Listeners array, this is a critical error.");
		RawInputListener = none;
		return;
	}

	ListenersArray.RemoveItem(handler);
	if(ListenersArray.Length > 0)
		RawInputListener = ListenersArray[ListenersArray.Length - 1];
	else
		RawInputListener = none;
}

function PreProcessInput(float DeltaTime)
{
	super.PreProcessInput(DeltaTime);

	if (bAutoTest)
	{
		aBaseY = fAutoBaseY;
		aStrafe = fAutoStrafe;
	}
}

// Determines if the game window is focused 
native function bool IsAppWindowFocused();

// converts the given point in 2d flash UI space into the corresponding point in
// actual screen space
simulated native function Vector2D ConvertUIPointToScreenCoordinate(Vector2D kPoint);

// converts the given point in physical screen space into 2d flash UI space
simulated native function Vector2D ConvertScreenCoordinateToUIPoint(Vector2D kPoint);

//-----------------------------------------------------------
simulated function bool TestMouseConsumedByFlash()
{
	//`log("**UIINPUT: TestMouseConsumedByFlash location 1",, 'uixcom');
	//ScriptTrace();
	//`log("**UIINPUT: TestMouseConsumedByFlash : 1 m_bConsumedByFlash " $m_bConsumedByFlash,, 'uixcom');
	//`log("**UIINPUT: TestMouseConsumedByFlash : 1 m_bConsumedByFlashCached " $m_bConsumedByFlashCached,, 'uixcom');

	if( m_bConsumedByFlashCached == false)
	{
		m_bConsumedByFlash = TestMouseConsumedHelper(Get2DMovie());
		m_bConsumedByFlashCached = true;
		//`log("**UIINPUT: TestMouseConsumedByFlash : caching  and hud is:" @Get2DMovie(),, 'uixcom');
	}

	//`log("**UIINPUT: TestMouseConsumedByFlash : 2 m_bConsumedByFlash " $m_bConsumedByFlash,, 'uixcom');
	//`log("**UIINPUT: TestMouseConsumedByFlash : 2 m_bConsumedByFlashCached " $m_bConsumedByFlashCached,, 'uixcom');
	return m_bConsumedByFlash;
}

// WARNING: This only works in Strategy layer (where there are 3D screens), in Tactical it'll always return false
simulated function bool TestMouseConsumedBy3DFlash()
{
	//`log("**UIINPUT: TestMouseConsumedBy3DFlash location 1",, 'uixcom');
	//`log("**UIINPUT: TestMouseConsumedBy3DFlash : 1 m_bConsumedByFlash " $m_bConsumedByFlash,, 'uixcom');
	//`log("**UIINPUT: TestMouseConsumedBy3DFlash : 1 m_bConsumedBy3DFlashCached " $m_bConsumedBy3DFlashCached,, 'uixcom');
	if( m_bConsumedBy3DFlashCached == false)
	{
		m_bConsumedByFlash = TestMouseConsumedHelper(Get3DMovie());
		m_bConsumedBy3DFlashCached = true;
		//`log("**UIINPUT: TestMouseConsumedBy3DFlash : caching  and Get3DMovie is:" @Get3DMovie(),, 'uixcom');
	}

	//`log("**UIINPUT: TestMouseConsumedBy3DFlash : 2 m_bConsumedByFlash " $m_bConsumedByFlash,, 'uixcom');
	//`log("**UIINPUT: TestMouseConsumedBy3DFlash : 2 m_bConsumedBy3DFlashCached " $m_bConsumedBy3DFlashCached,, 'uixcom');
	return m_bConsumedByFlash;
}

simulated private function bool TestMouseConsumedHelper(UIMovie kMovie)
{
	local Vector2D kMousePosition;

	if( XComPlayerController(Outer).Pres.m_kUIMouseCursor != none )
	{
		kMousePosition = XComPlayerController(Outer).Pres.m_kUIMouseCursor.m_v2MouseLoc;
	}
	
	if(kMovie != none)
		return TestHitPointToFlash(kMousePosition, kMovie);
	else
		return false;
}
simulated native function bool TestHitPointToFlash(Vector2D kPoint, UIMovie kMovie);


simulated function Subscribe( int iButton, float fTimeThreshold, delegate<SubscriberCallback> delCallbackFunction )
{
	local TInputSubscriber subscriber;
	
	//Keep it tidy and remove any previous subscriptions, if there were any.
	Unsubscribe( delCallbackFunction );

	//`log("Subscribe("$iButton$", "$fTimeThreshold$", "$delCallbackFunction$")",,'uixcom');
	subscriber.iButton = iButton;
	subscriber.fTimeThreshold = fTimeThreshold;
	subscriber.CallbackFunction = delCallbackFunction;

	m_arrSubscribers.AddItem( subscriber ); 

	AddIdler( iButton );
}

simulated function Unsubscribe( delegate<SubscriberCallback> delCallbackFunction )
{
	local int foundIndex; 
	local int iButton; 

	//`log("Unsubscribe("$delCallbackFunction$")",,'uixcom');

	foundIndex = m_arrSubscribers.Find( 'CallbackFunction', delCallbackFunction );
	if( foundIndex > -1 )
	{
		//save the target button first
		iButton = m_arrSubscribers[foundIndex].iButton; 
		//remove the subscriber
		m_arrSubscribers.Remove(foundIndex, 1);
	
		//if no other saubscribers are watching for this button
		if( m_arrSubscribers.Find( 'iButton', iButton ) ==  -1)
		{
			//remove any attached idlers
			RemoveIdler( iButton );
		}
	}
	else
	{
		//`log("Trying to Unsubscribe("$delCallbackFunction$"), but it wasn't found as a subscriber.",,'uixcom');
	}
}

//Add a new idle tracker, if not already tracking for iButton. 
simulated function AddIdler( int iButton )
{
	local TInputIdleTracker idler;
	
	//Only add the idler if something is not already tracking it
	if( !GetIdler(iButton).bValid )
	{
		idler.iButton = iButton;
		idler.fTime = 0.0;
		idler.bValid = true;
		m_arrIdleTrackers.AddItem( idler );
	}
}

//Recursively remove all idle trackers for a button.
simulated function RemoveIdler( int iButton )
{	
	local TInputIdleTracker idler;

	idler = GetIdler( iButton );

	if( idler.bValid )
	{
		m_arrIdleTrackers.RemoveItem(idler);
		//Recursive removal, just in case a tracker was added multiple times 
		RemoveIdler( iButton );
	}
}

simulated function TInputIdleTracker GetIdler( int iButton )
{
	local int foundIndex; 
	local TInputIdleTracker idler;

	foundIndex = m_arrIdleTrackers.Find( 'iButton', iButton );

	if( foundIndex > -1 )
	{
		return(m_arrIdleTrackers[foundIndex]);
	}
	else
	{
		//return invalid idler
		return(idler);
	}
}

simulated function PostProcessSubscribers( float deltaTime )
{
	local TInputIdleTracker idler;
	local TInputSubscriber subscriber;
	local delegate<SubscriberCallback> callback;
	local int i;
	
	//first process the idlers
	for( i=0; i< m_arrIdleTrackers.Length; i++)
	{
		m_arrIdleTrackers[i].fTime += deltaTime; 
	}

	//send out any message to subscribers
	foreach m_arrSubscribers(subscriber)
	{
		idler = GetIdler(subscriber.iButton);
		if( idler.bValid && idler.fTime >= subscriber.fTimeThreshold ) 
		{
			callback = subscriber.CallbackFunction;
			callback();
			ResetIdlerTime(subscriber.iButton);
		}
	}
}

simulated function ResetIdlerTime( int iButton )
{
	local int foundIndex; 

	foundIndex = m_arrIdleTrackers.Find( 'iButton', iButton );

	if( foundIndex > -1 )
	{
		m_arrIdleTrackers[foundIndex].fTime = 0.0;
	}
	
	//Also reset idler time for *any. 
	if(iButton != class'UIUtilities_Input'.const.FXS_ANY_INPUT) 
		ResetIdlerTime( class'UIUtilities_Input'.const.FXS_ANY_INPUT ); 
}

simulated function UIScreenStack GetScreenStack()
{
	return XComPlayerController(Outer).Pres.ScreenStack;
}
simulated event UIMovie Get2DMovie()
{
	return XComPlayerController(Outer).Pres.Get2DMovie();
}
simulated event UIMovie Get3DMovie()
{
	return XComPlayerController(Outer).Pres.Get3DMovie();
}

simulated function bool IsControllerActive()
{
	if( bForceEnableController )
		return true; 

	if( `XENGINE.m_SteamControllerManager.IsSteamControllerActive() )
		return true; 

	//TODO: 
	//if( profileSetting.usingController) return true;

	return false; 
}

private function bool PreProcessEventMatching( int cmd , int ActionMask) 
{
	local int foundIndex;
	
	//Press actions are always allowed through, as they are the start of the cascade. 
	if(( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0) return true;

	if(IsMouseRangeEvent(cmd))
		return true;

	foundIndex = m_arrEventTrackers.Find( 'iButton', cmd );
	if( foundIndex == -1 )
	{
		// This means we've received an event other than press but without an initial press event to activate a tracker. 
		// Ex. thsi is a crap event from some other system that let later events through when it should have consumed them. 
		return false; 
	}
	
	//We're already tracking this cmd, so it's ok to let it through. 
	return true; 
}

event PlayerInput( float DeltaTime )
{
	super.PlayerInput(DeltaTime);
	m_bConsumedByFlashCached = false;
	m_bConsumedBy3DFlashCached = false;

	if( aMouseX != aMouseXCached || aMouseY != aMouseYCached )
	{
		aMouseXCached = aMouseX;
		aMouseYCached = aMouseY;
		m_bInputSinceMouseMovement = false;
	}
}

//-----------------------------------------------------------
// Called from InputEvent if the External UI is open. (i.e. Steam)
//  cmd             Input command to act on (see UIUtilities_Input for values)
//  ActionMask      behavio of the incoming command (press, hold, repeat, release) 
//
//  Return: True to stop processing input, False to continue processing
function bool HandleExternalUIOpen( int cmd , optional int ActionMask = class'UIUtilities_Input'.const.FXS_ACTION_PRESS )
{
	return true;
}

//-----------------------------------------------------------
// Input raised from controller
//  cmd             Input command to act on (see UIUtilities_Input for values)
//  ActionMask      behavio of the incoming command (press, hold, repeat, release) 
//
final function InputEvent( int cmd , optional int ActionMask = class'UIUtilities_Input'.const.FXS_ACTION_PRESS )
{
	local UIRedScreen RedScreen;
	local int iFilteredUICmd;
	local bool bConsume;
	bConsume = false;

	if( `ONLINEEVENTMGR.CopyProtection!=none && `ONLINEEVENTMGR.CopyProtection.ProtectionFailed() )
		return;  // Consume input if our copy protection failed;

	// event matching and hold/tap/idle timers need to always be processed, or it 
	// is possible to miss the release event after a hold if the press is not consumed
	// but the release is. Safety first!
	//Check that we're getting proper event pairs, and not a partial later event from some other system 
	if( !PreProcessEventMatching( cmd, ActionMask) ) return;

	ResetIdlerTime( cmd );
	CheckForTap(cmd, ActionMask);
	DeactivateTracker(cmd, ActionMask);
	ActivateTracker( cmd, ActionMask );

	//Stop input when an external overlay is up (consoles do this automatically, steam on PC needs to have explicit stoppage)
	if ( bIsExternalUIOpen )
	{
		if (HandleExternalUIOpen(cmd, ActionMask))
		{
			return;
		}
	}
	
	//Never let input through if there's a movie going. 
	if( `XENGINE.IsAnyMoviePlaying() ) 
		return;
	
	//If we are seamless traveling, any input will send us to the next level
	if( !XComPlayerController(Outer).bProcessedTravelDestinationLoaded )
	{
		if( XComPlayerController(Outer).bSeamlessTravelDestinationLoaded &&
		   ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0) )
		{
			XComPlayerController(Outer).CleanupDropshipStart();
			XComPlayerController(Outer).ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.5);
		}
		return;
	}

	// Allow controller inputs but no mouse/keyboard if controller is active; the inverse if mouse/keyboard is active. 
	// Unless internal 'J' which raises chat.
	if( !IsEventWithinInputTypeRange( cmd ) && cmd != class'UIUtilities_Input'.const.FXS_KEY_J )
		return;

	// If we have a RedScreen, bypass all game logic check allowing users to close it regardless of game state.
	RedScreen = UIRedScreen(`SCREENSTACK.GetScreen(class'UIRedScreen'));
	if( RedScreen != none && RedScreen.OnUnrealCommand(cmd, ActionMask) )
		return;

	//Allow the local input to check  if input should be processed first, and stop if failed 
	if( !PreProcessCheckGameLogic(cmd, ActionMask) ) return;
	
	if(!bConsume) {
		cmd = PreProcessMouseInput(cmd, ActionMask);
		if( cmd == class'UIUtilities_Input'.const.FXS_INPUT_NONE )
			return;
	}

	// Smart-toggle the mouse based on input from mouse vs. from the controller 
	// CheckMouseSmartToggle(cmd);

	//Sending input to the UI first
	iFilteredUICmd = FilterCmdForUI(cmd, ActionMask);
	if( iFilteredUICmd != class'UIUtilities_Input'.const.FXS_INPUT_NONE )
	{
		if( !bConsume )
			bConsume = CheckSteamControllerSmartToggle(cmd, ActionMask);
		
		//We want this to happen before the main UI processes it.
		if( !bConsume && ActionMask == class'UIUtilities_Input'.const.FXS_ACTION_RELEASE )
			bConsume = AttemptSteamControllerConfirm(cmd);

		if( !bConsume )
			bConsume = GetScreenStack().OnInput(iFilteredUICmd, ActionMask);
	}


	if( !WorldInfo.IsConsoleBuild()         // On PC only, 
		&& !bConsume                        // And not yet consumed, 
		&& IsMouseRangeEvent(cmd)           // And within the mouse range of behavior,
		&& Get2DMovie().IsMouseActive() )   // And the mouse is active.
	{

		if( TestMouseConsumedByFlash() )
		{
			//We've clicked something with a button handler in flash, so consider the input consumed. 
			bConsume = true;
		}
		else
		{
			//Else we've clicked empy-flash-space or a non-button-event flash element; input NOT consumed by UI. 

			//Sending mouse input to 3D mouse-interactive actors
			bConsume = ProcessMouseInputThroughHUD( cmd, ActionMask );
		}
	}

	// If not consumed by UI or 3D mouse-interactive actor, next hand out input to non-UI systems.
	if( !bConsume )
	{
		if( ButtonIsDisabled( cmd ) ) return;
	
		switch( cmd )
		{
			// Controller ----------------------------------------------------------------------------------------
			// Buttons
			case class'UIUtilities_Input'.const.FXS_BUTTON_A:         bConsume = A_Button(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_B:         bConsume = B_Button(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_X:         bConsume = X_Button(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_Y:         bConsume = Y_Button(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_A_STEAM :  bConsume = A_Button_Steam(ActionMask);   break;

			// Triggers
			case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:   bConsume = Bumper_Left(ActionMask);      break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:   bConsume = Bumper_Right(ActionMask);     break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:  bConsume = Trigger_Left(m_fLTrigger,  ActionMask);     break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:  bConsume = Trigger_Right(m_fRTrigger, ActionMask);    break;
			
			// Joysticks
			case class'UIUtilities_Input'.const.FXS_BUTTON_LSTICK:    bConsume = Stick_Left(m_fLSXAxis, m_fLSYAxis, ActionMask);       break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_RSTICK:    bConsume = Stick_Right(m_fRSXAxis, m_fRSYAxis, ActionMask);      break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_L3:        bConsume = Stick_L3(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_R3:        bConsume = Stick_R3(ActionMask);         break;

			// System buttons
			case class'UIUtilities_Input'.const.FXS_BUTTON_SELECT:    bConsume = Back_Button(ActionMask);      break;
			case class'UIUtilities_Input'.const.FXS_BUTTON_START:     bConsume = Start_Button(ActionMask);     break;

			// D-Pad
			case class'UIUtilities_Input'.const.FXS_DPAD_UP:          bConsume = DPad_Up(ActionMask);          break;
			case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:       bConsume = DPad_Right(ActionMask);       break;
			case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:        bConsume = DPad_Down(ActionMask);        break;
			case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:        bConsume = DPad_Left(ActionMask);        break;

			//Mouse -----------------------------------------------------------------------------------------------

			case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:      bConsume = LMouse(ActionMask);          break;
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:  bConsume = LMouseDelayed(ActionMask); break;
			case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_DOWN: bConsume = LDoubleClick(ActionMask);  break;
			case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:      bConsume = RMouse(ActionMask);          break;
			case class'UIUtilities_Input'.const.FXS_M_MOUSE:           bConsume = MMouse(ActionMask);          break;
			case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:   bConsume = MouseScrollUp(ActionMask);   break;
			case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN: bConsume = MouseScrollDown(ActionMask); break;
			case class'UIUtilities_Input'.const.FXS_MOUSE_4:           bConsume = Mouse4(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_MOUSE_5:           bConsume = Mouse5(ActionMask);         break;

			// Keyboard -------------------------------------------------------------------------------------------

			// Arrow Keys
			case class'UIUtilities_Input'.const.FXS_ARROW_UP:          bConsume = ArrowUp(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:        bConsume = ArrowDown(ActionMask);       break;
			case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:        bConsume = ArrowLeft(ActionMask);       break;
			case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:       bConsume = ArrowRight(ActionMask);      break;
			
			case class'UIUtilities_Input'.const.FXS_KEY_PAUSE:         bConsume = PauseKey(ActionMask);        break;
			case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:        bConsume = EscapeKey(ActionMask);       break;
			case class'UIUtilities_Input'.const.FXS_KEY_ENTER:         bConsume = EnterKey(ActionMask);        break;
			case class'UIUtilities_Input'.const.FXS_KEY_BACKSPACE:     bConsume = Key_Backspace(ActionMask);   break;
			case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:      bConsume = Key_Spacebar(ActionMask);    break;
			case class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT:    bConsume = Key_Left_Shift(ActionMask);  break;
			case class'UIUtilities_Input'.const.FXS_KEY_LEFT_CONTROL:  bConsume = Key_Left_Control(ActionMask);  break;
			case class'UIUtilities_Input'.const.FXS_KEY_DELETE:        bConsume = Key_Delete(ActionMask);  break;
			case class'UIUtilities_Input'.const.FXS_KEY_HOME:          bConsume = Key_Home(ActionMask);        break;
			case class'UIUtilities_Input'.const.FXS_KEY_END:           bConsume = Key_End(ActionMask);   break;
			case class'UIUtilities_Input'.const.FXS_KEY_PAGEUP:        bConsume = Key_PageUp(ActionMask);   break;
			case class'UIUtilities_Input'.const.FXS_KEY_PAGEDN:        bConsume = Key_PageDn(ActionMask);   break;
			
			case class'UIUtilities_Input'.const.FXS_KEY_TAB:           bConsume = Key_Tab(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_A:             bConsume = Key_A(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_B:             bConsume = Key_B(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_C:             bConsume = Key_C(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_D:             bConsume = Key_D(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_E:             bConsume = Key_E(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_F:             bConsume = Key_F(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_G:             bConsume = Key_G(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_H:             bConsume = Key_H(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_I:             bConsume = Key_I(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_J:             bConsume = Key_J(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_K:             bConsume = Key_K(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_L:             bConsume = Key_L(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_M:             bConsume = Key_M(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_N:             bConsume = Key_N(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_O:             bConsume = Key_O(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_P:             bConsume = Key_P(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_Q:             bConsume = Key_Q(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_R:             bConsume = Key_R(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_S:             bConsume = Key_S(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_T:             bConsume = Key_T(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_U:             bConsume = Key_U(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_V:             bConsume = Key_V(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_W:             bConsume = Key_W(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_X:             bConsume = Key_X(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_Y:             bConsume = Key_Y(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_Z:             bConsume = Key_Z(ActionMask);           break;

			// Number keys
			case class'UIUtilities_Input'.const.FXS_KEY_1:             bConsume = Key_1(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_2:             bConsume = Key_2(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_3:             bConsume = Key_3(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_4:             bConsume = Key_4(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_5:             bConsume = Key_5(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_6:             bConsume = Key_6(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_7:             bConsume = Key_7(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_8:             bConsume = Key_8(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_9:             bConsume = Key_9(ActionMask);           break;
			case class'UIUtilities_Input'.const.FXS_KEY_0:             bConsume = Key_0(ActionMask);           break;

			// Function keys
			case class'UIUtilities_Input'.const.FXS_KEY_F1:             bConsume = Key_F1(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F2:             bConsume = Key_F2(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F3:             bConsume = Key_F3(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F4:             bConsume = Key_F4(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F5:             bConsume = Key_F5(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F6:             bConsume = Key_F6(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F7:             bConsume = Key_F7(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F8:             bConsume = Key_F8(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F9:             bConsume = Key_F9(ActionMask);         break;
			case class'UIUtilities_Input'.const.FXS_KEY_F10:            bConsume = Key_F10(ActionMask);        break;
			case class'UIUtilities_Input'.const.FXS_KEY_F11:            bConsume = Key_F11(ActionMask);        break;
			case class'UIUtilities_Input'.const.FXS_KEY_F12:            bConsume = Key_F12(ActionMask);        break;


			default:
				break;
		}
	}
}

// Checks whether double click has been pressed and adjusts inputs accordingly.
simulated function int PreProcessMouseInput( int cmd, int ActionMask )
{
	local int iProcessedCmd;

	// MIRRORED IMPLEMENTATION OF DOUBLE CLICK BEHAVIOR FROM FLASH - ClickablePanel.as - sbatista
	iProcessedCmd = cmd;

	// Don't allow mouse clicks when in alt-tab behavior
	// If this is a press action and we are in a paused state due to Alt-Tab, don't allow it through. -DMW
	if( cmd >= class'UIUtilities_Input'.const.FXS_MOUSE_RANGE_BEGIN && 
		cmd <= class'UIUtilities_Input'.const.FXS_MOUSE_RANGE_END &&
		XComPlayerController(Outer).InAltTab() )
	{
		m_iDoubleClickNumClicks = 0;
		return class'UIUtilities_Input'.const.FXS_INPUT_NONE;
	}

	// We only care about the L_Mouse click, return if it's anything else
	if(iProcessedCmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN)
		return iProcessedCmd;

	// Don't allow any mouse clicks when in alt-tab behavior
	
	if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
	{
		if(IsTimerActive(nameof(ProcessDelayedMouseRelease), self))
		{
			m_iDoubleClickNumClicks = 2;
			iProcessedCmd = class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_DOWN;
		}
		else
			m_iDoubleClickNumClicks  = 1;

		ClearTimer(nameof(ProcessDelayedMouseRelease), self);
		m_fDoubleClickLastClick = WorldInfo.TimeSeconds;
	}
	else if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		ClearTimer(nameof(ProcessDelayedMouseRelease), self);

		if( m_iDoubleClickNumClicks == 0 )
		{
			iProcessedCmd = class'UIUtilities_Input'.const.FXS_INPUT_NONE;
		}
		else
		{
			if(m_iDoubleClickNumClicks == 2)
			{
				// We know that the button was released here, but we only check for Down events, the ActionMask already contains the button state info
				iProcessedCmd = class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_DOWN;
				// Ensure that the next 'press' will not result in a 'double press'.
				m_fDoubleClickLastClick -= class'UIUtilities_Input'.const.MOUSE_DOUBLE_CLICK_SPEED;
			}
			// Set the timer so we wait for the double click, if it doesn't happen, we trigger a single delayed click
			else if(m_fDoubleClickLastClick - WorldInfo.TimeSeconds + (class'UIUtilities_Input'.const.MOUSE_DOUBLE_CLICK_SPEED / 1000.0f) > 0)
			{
				SetTimer( class'UIUtilities_Input'.const.MOUSE_DOUBLE_CLICK_SPEED / 1000.0f - (WorldInfo.TimeSeconds - m_fDoubleClickLastClick), false, nameof(ProcessDelayedMouseRelease), self );
			}
		}

		m_iDoubleClickNumClicks = 0;
	}

	return iProcessedCmd;
}
// Helper function to the PreProcessMouseInput step
simulated function ProcessDelayedMouseRelease()
{	
	InputEvent(class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
}

simulated function PostProcessMouseMovement()
{
	if( aMouseX != 0.0f || aMouseY != 0.0f )
	{
		if( `PRES != none && `PRES.Get2DMovie() != none && !Get2DMovie().IsMouseActive() && Get2DMovie().bIsVisible )
		{
			//HACK: Need to block the auto switch from happening, until we get the save data in the player profile. Then remove this hackola. @bsteiner @tsmith 
			if( WorldInfo.NetMode == NM_Standalone )
			{
				//`log("XCOM INPUT BASE: " @"aMouseX:" @aMouseX @"aMouseY:"@aMouseY);
				//`log("Activating mouse from movement!"); 
				//Get2DMovie().ActivateMouse();
			}
		}
	}
}

simulated function CheckMouseSmartToggle( int cmd )
{
	if( IsMouseRangeEvent(cmd) || IsKeyboardRangeEvent( cmd ) )
	{
		if( !Get2DMovie().IsMouseActive() )
		{
			Get2DMovie().ActivateMouse();
		}
		m_bInputSinceMouseMovement = true;
	}
	else if( IsControllerRangeEvent(cmd) )
	{	
		if( Get2DMovie().IsMouseActive() )
		{
			Get2DMovie().DeactivateMouse();
		}
	}
}
simulated function bool IsMouseRangeEvent( int cmd )
{
	if( cmd > class'UIUtilities_Input'.const.FXS_MOUSE_RANGE_END 
		|| cmd < class'UIUtilities_Input'.const.FXS_MOUSE_RANGE_BEGIN )
	{
		return false;
	}
	else
	{
		return true;
	}
}
simulated function bool IsControllerRangeEvent( int cmd )
{
	if( cmd > class'UIUtilities_Input'.const.FXS_CONTROLLER_RANGE_END 
		|| cmd < class'UIUtilities_Input'.const.FXS_CONTROLLER_RANGE_BEGIN)
	{
		return false;
	}
	else
	{
		return true;
	}
}
simulated function bool IsKeyboardRangeEvent( int cmd )
{
	if( cmd > class'UIUtilities_Input'.const.FXS_KEYBOARD_RANGE_END 
		|| cmd < class'UIUtilities_Input'.const.FXS_KEYBOARD_RANGE_BEGIN )
	{
		return false;
	}
	else
	{
		return true;
	}
}

simulated function bool IsEventWithinInputTypeRange( int cmd )
{

	if( IsControllerRangeEvent(cmd) )
	{
		if( bForceEnableController )
			return true; 

		if( `XENGINE.m_SteamControllerManager.IsSteamControllerActive() )
			return true; 

		if( XComPlayerController(Outer).Pres != none && Get2DMovie().IsMouseActive()  )
			return false; 
		else
			return true;
	}
	else //Mouse or Keyboard Event 
	{
		if( XComPlayerController(Outer).Pres != none && Get2DMovie().IsMouseActive() )
			return true; 
		else
		{ 
			if( AllowEscKeyIfChangingInputDevice( cmd ) ) 
				return true; 
			else
				return false;
		}
	}
}
/*public function CheckDeactivateMouseFromController( int cmd )
{
	if( IsControllerRangeEvent(cmd) && Get2DMovie().IsMouseActive() )
	{
		//`log("Deactivating mouse from controller!"); 
		Get2DMovie().DeactivateMouse();
	}
}*/

//Sends the mouse input through the world to any IMouseInterface-equipped hit actors. Returns bHandled. 
simulated function bool ProcessMouseInputThroughHUD( int cmd, int ActionMask )
{
	local bool bConsume;
	local XComHUD HUD; 
	local IMouseInteractionInterface LastInterface; 
	local Vector CachedMouseWorldOrigin, CachedMouseWorldDirection, CachedHitLocation;

	bConsume = false; 

	HUD = GetXComHUD();
	if( HUD == none ) return false; 

	LastInterface = GetMouseInterfaceTarget();
	if( LastInterface == none ) return false; 

	//Grab all of the infos about the mouse click 
	CachedMouseWorldOrigin = HUD.CachedMouseWorldOrigin;
	CachedMouseWorldDirection = HUD.CachedMouseWorldDirection; 
	CachedHitLocation = HUD.CachedHitLocation; 

	//Send to the mouse interfaced object, see if it handles the input.
	bConsume = LastInterface.OnMouseEvent(  cmd, Actionmask, CachedMouseWorldOrigin, CachedMouseWorldDirection, CachedHitLocation); 

	return bConsume;
}

//Will we need this anywhere besides the Tactical HUD? If so, will  need to rewrite this to live in a shared base HUD class. -bsteiner 
function XComHUD GetXComHUD()
{
	if( XComPlayerController(Outer) == none ) 
		return none;
	
	return XComHUD(XComPlayerController(Outer).myHUD);
}

//Returns the cached mouse interface target from the HUD. 
protected function IMouseInteractionInterface GetMouseInterfaceTarget()
{
	local XComTacticalHUD HUD; 
	local IMouseInteractionInterface LastInterface; 

	HUD = XComTacticalHUD(XComPlayerController(Outer).myHUD);
	if( HUD == none ) return none; 

	LastInterface = HUD.CachedMouseInteractionInterface; 
	return( LastInterface );
}

//Translates input into virtual buttons for UI consumption
simulated function int FilterCmdForUI( int cmd, int ActionMask )
{
	local int iFilteredCmd; 

	iFilteredCmd = cmd;

	switch( cmd )
	{
	//Left stick ----------------------------------------------------------------------------------
	case class'UIUtilities_Input'.const.FXS_BUTTON_LSTICK:

		//Very simple conversion. Refactor later? -bsteiner 
		if( m_fLSYAxis > LSTICK_THRESHOLD )        //joy up
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP;
		}
		else if (m_fLSYAxis < -LSTICK_THRESHOLD )    //joy down
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN;
		}
		else if ( m_fLSXAxis > LSTICK_THRESHOLD )    //joy right
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT;
		}
		else if ( m_fLSXAxis < -LSTICK_THRESHOLD )  //joy left
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT;
		}
		else
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_BUTTON_LSTICK;
		}

		break;
	//Right stick ----------------------------------------------------------------------------------
	case class'UIUtilities_Input'.const.FXS_BUTTON_RSTICK:
	
		//Very simple conversion. Refactor later? -bsteiner 
		if( m_fRSYAxis > RSTICK_THRESHOLD )        //joy up
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_UP;
		}
		else if (m_fRSYAxis < -RSTICK_THRESHOLD )    //joy down
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_DOWN;
		}
		else if ( m_fRSXAxis > RSTICK_THRESHOLD )    //joy right
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_RIGHT;
		}
		else if ( m_fRSXAxis < -RSTICK_THRESHOLD )  //joy left
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_LEFT;
		}
		else
		{
			iFilteredCmd = class'UIUtilities_Input'.const.FXS_BUTTON_RSTICK;
		}

		break;

	// Filter out all Mouse Inputs -------------------------------------------------------------
	// TODO: Edit to add Right Click functionality
	//case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:
	//case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN: // DO allow right click event through. 
	case class'UIUtilities_Input'.const.FXS_M_MOUSE:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_DOWN:
	//case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:// DO allow scroll event through. 
	//case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:	// DO allow scroll event through. 

		iFilteredCmd = class'UIUtilities_Input'.const.FXS_INPUT_NONE;

		break;
	}	

	// If it didn't need to translate, return cmd
	return iFilteredCmd;
}

function bool A_Button(int ActionMask);
function bool B_Button(int ActionMask);
function bool X_Button(int ActionMask);
function bool Y_Button(int ActionMask);
function bool A_Button_Steam(int ActionMask);
function bool Bumper_Left(int ActionMask);
function bool Bumper_Right(int ActionMask);
function bool Trigger_Left(float fTrigger, int ActionMask);
function bool Trigger_Right(float fTrigger, int ActionMask);
function bool Stick_Left(float _x, float _y, int ActionMask);
function bool Stick_Right(float _x, float _y, int ActionMask);
function bool Stick_L3(int ActionMask);
function bool Stick_R3(int ActionMask);
function bool Back_Button(int ActionMask);
function bool Start_Button(int ActionMask);
function bool DPad_Right(int ActionMask);
function bool DPad_Left(int ActionMask);
function bool DPad_Up(int ActionMask);
function bool DPad_Down(int ActionMask);

function bool LMouse(int ActionMask);
function bool LMouseDelayed(int ActionMask);
function bool LDoubleClick(int ActionMask);
function bool RMouse(int ActionMask);
function bool MMouse(int ActionMask);
function bool MouseScrollUp(int ActionMask);
function bool MouseScrollDown(int ActionMask);
function bool Mouse4(int ActionMask);
function bool Mouse5(int ActionMask);

function bool ArrowUp(int ActionMask);
function bool ArrowDown(int ActionMask);
function bool ArrowLeft(int ActionMask);
function bool ArrowRight(int ActionMask);
function bool PauseKey(int ActionMask);
function bool EscapeKey(int ActionMask);
function bool EnterKey(int ActionMask);
function bool Key_Backspace(int ActionMask);
function bool Key_Spacebar(int ActionMask);
function bool Key_Tab(int ActionMask);
function bool Key_Left_Shift(int ActionMask);
function bool Key_Left_Control(int ActionMask);
function bool Key_Delete(int ActionMask);
function bool Key_Home(int ActionMask);
function bool Key_End(int ActionMask);
function bool Key_PageUp(int ActionMask);
function bool Key_PageDn(int ActionMask);
function bool Key_A(int ActionMask);
function bool Key_B(int ActionMask)
{
	local XComOnlineEventMgr OnlineEventMgr;
	local XComOnlineProfileSettings ProfileSettings;
	ProfileSettings = `XPROFILESETTINGS;
	// Only activate / deactivate if the push to talk setting is true
	if( ProfileSettings != none && ProfileSettings.Data.m_bPushToTalk )
	{
		OnlineEventMgr = `ONLINEEVENTMGR;
		if (OnlineSub.VoiceInterface != none)
		{
			if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
			{
				`log(`location @ `ShowVar(ActionMask) @ "-- Starting Networked Voice --");
				OnlineSub.VoiceInterface.StartNetworkedVoice(OnlineEventMgr.LocalUserIndex);
			}
			else if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			{
				`log(`location @ `ShowVar(ActionMask) @ "-- Stopping Networked Voice --");
				OnlineSub.VoiceInterface.StopNetworkedVoice(OnlineEventMgr.LocalUserIndex);
			}
			return true;
		} 
	}
	return false;
}
function bool Key_C(int ActionMask);
function bool Key_D(int ActionMask);
function bool Key_E(int ActionMask);
function bool Key_F(int ActionMask);
function bool Key_G(int ActionMask);
function bool Key_H(int ActionMask);
function bool Key_I(int ActionMask);
function bool Key_J(int ActionMask);
function bool Key_K(int ActionMask);
function bool Key_L(int ActionMask);
function bool Key_M(int ActionMask);
function bool Key_N(int ActionMask);
function bool Key_O(int ActionMask);
function bool Key_P(int ActionMask);
function bool Key_Q(int ActionMask);
function bool Key_R(int ActionMask);
function bool Key_S(int ActionMask);
function bool Key_T(int ActionMask);
function bool Key_U(int ActionMask);
function bool Key_V(int ActionMask);
function bool Key_W(int ActionMask);
function bool Key_X(int ActionMask);
function bool Key_Y(int ActionMask);
function bool Key_Z(int ActionMask);

function bool Key_1(int ActionMask);
function bool Key_2(int ActionMask);
function bool Key_3(int ActionMask);
function bool Key_4(int ActionMask);
function bool Key_5(int ActionMask);
function bool Key_6(int ActionMask);
function bool Key_7(int ActionMask);
function bool Key_8(int ActionMask);
function bool Key_9(int ActionMask);
function bool Key_0(int ActionMask);

function bool Key_F1(int ActionMask);
function bool Key_F2(int ActionMask);
function bool Key_F3(int ActionMask);
function bool Key_F4(int ActionMask);

function bool Key_F5(int ActionMask)
{
	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 && `HQPRES != none)
	{
		`AUTOSAVEMGR.DoQuickSave();
		return true;
	} 
	return false;	
}

function bool Key_F6(int ActionMask);
function bool Key_F7(int ActionMask);
function bool Key_F8(int ActionMask);
function bool Key_F9(int ActionMask)
{
		if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			`AUTOSAVEMGR.DoQuickLoad();
			return true;
		} 
		return false;
}

function bool Key_F10(int ActionMask);
function bool Key_F11(int ActionMask);
function bool Key_F12(int ActionMask);

event Trigger_Left_Analog(float fAnalog)
{
	m_fLTrigger = fAnalog;
}
event Trigger_Right_Analog(float fAnalog)
{
	m_fRTrigger = fAnalog;
}

//Returns true if the button has been disabled.
simulated function bool ButtonIsDisabled( int cmd ) 
{
	return false;
}

//Returns false if processing stopped (ex. if screen or camera isn't ready.) 
simulated function bool PreProcessCheckGameLogic( int cmd, int ActionMask ) 
{
	`log("Should not be calling XComInputBase.PreProcessCheckGameLogic(). Child classes of InputBase should override this function.", true, 'uixcom');
	return false;
}


simulated function bool AllowEscKeyIfChangingInputDevice( int cmd )
{
	if( cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE && XComPlayerController(Outer).Pres.IsInState( 'State_PCOptions', true ) )
		return true; 
	else
		return false; 
}
//Called from PlayerInput.uc
function PostProcessInput( float DeltaTime )
{
	if( PostProcessCheckGameLogic( DeltaTime ) )
	{
		super.PostProcessInput( DeltaTime );

		// Temporarily allow gamepad input to facilitate demo showing to the press, maybe reenable if we bring back gamepad mode - sbatista
		//if( !XComPlayerController(Outer).Pres.Get2DMovie().IsMouseActive() )
		//{
			PostProcessJoysticks();
		//}
		PostProcessTrackers( DeltaTime);
		PostProcessSubscribers( DeltaTime );
		PostProcessMouseMovement();		
	}

	//Camera lives out here so that the debug camera can still scoot around while input is generally disabled
	if(XComCameraBase(PlayerCamera) != none)
		XComCameraBase(PlayerCamera).PostProcessInput();
}

simulated function bool PostProcessCheckGameLogic( float DeltaTime )
{
	`log("Should not be calling XComInputBase.PostProcessCheckGameLogic(). Child classes of InputBase should override this function.", true, 'uixcom');
	return false;
}

simulated function PostProcessJoysticks()
{
	local int foundIndex; 

	// aBaseY and aStrafe are defined in the parent class PlayerInput.uc. 
	// They are set on via binding commands in PlayerInput's Input() event. 
	// Here we're caching them as member variables so that the values will be
	// available when not in the input event update (ex. when in the repeat timers).

	m_fLSXAxis = aStrafe;
	m_fLSYAxis = aBaseY;
	m_fRSXAxis = aTurn;
	m_fRSYAxis = aLookUp;

	//Left stick ----------------------------------------------------------------------------------

	foundIndex = m_arrEventTrackers.Find( 'iButton', class'UIUtilities_Input'.const.FXS_BUTTON_LSTICK );

	//Very simple conversion. Refactor later? -bsteiner 
	if(    m_fLSXAxis > LSTICK_THRESHOLD    //joy up
		|| m_fLSXAxis < -LSTICK_THRESHOLD   //joy down
		|| m_fLSYAxis > LSTICK_THRESHOLD    //joy right
		|| m_fLSYAxis < -LSTICK_THRESHOLD ) //joy left
	{
		//if joy is not being held down currently, send a press
		
		if(foundIndex == -1)
		{
			InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_LSTICK, class'UIUtilities_Input'.const.FXS_ACTION_PRESS );
		}
	}
	else
	{
		//if we were holding, now send a release
		if(foundIndex > -1)
		{
			InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_LSTICK, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );	
		}
	}	

	//Right stick ----------------------------------------------------------------------------------
	
	foundIndex = m_arrEventTrackers.Find( 'iButton', class'UIUtilities_Input'.const.FXS_BUTTON_RSTICK );

	//Very simple conversion. Refactor later? -bsteiner 
	if(    m_fRSXAxis > RSTICK_THRESHOLD	//joy up
		|| m_fRSXAxis < -RSTICK_THRESHOLD   //joy down
		|| m_fRSYAxis > RSTICK_THRESHOLD    //joy right
		|| m_fRSYAxis < -RSTICK_THRESHOLD ) //joy left
	{
		//if joy is not being held down currently, send a press
		if(foundIndex == -1)
		{
			InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_RSTICK, class'UIUtilities_Input'.const.FXS_ACTION_PRESS );
		}
	}
	else
	{
		//if we were holding, now send a release
		if(foundIndex > -1)
		{
			InputEvent( class'UIUtilities_Input'.const.FXS_BUTTON_RSTICK, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE );	
		}
	}	
}

//If a Release event comes in, turn off any Trackers that were active for that particular cmd
simulated final function DeactivateTracker( int cmd, int ActionMask )
{
	local int foundIndex; 
	local TInputEventTracker tTracker;

	//If the button was RELEASED before the hold-threshold, 
	//then we deactivate the tracker. The RELEASE event
	//will be sent via the event chain naturally, so do 
	//not simulate any events here. 

	if(( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0) return;
	
  	foundIndex = m_arrEventTrackers.Find( 'iButton', cmd );
	if( foundIndex > -1 )
	{
		tTracker = m_arrEventTrackers[foundIndex];
		m_arrEventTrackers.RemoveItem(tTracker);
	}

	//Turn off the repeat timer if there's nothing left to watch 
	if( m_arrEventTrackers.Length == 0 && IsTimerActive( 'InputRepeatTimer', self ))
		ClearTimer( 'InputRepeatTimer', self);	
}


simulated final function CheckForTap( int cmd, int ActionMask )
{
	local int foundIndex; 
	local TInputEventTracker tTracker;

	//If the button was RELEASED before the hold-threshold, 
	//then we send a TAP action to the system. The RELEASE 
	//will be sent naturally directly after.

	if(( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0) return;
	
	foundIndex = m_arrEventTrackers.Find( 'iButton', cmd );
	if( foundIndex > -1 )
	{
		tTracker = m_arrEventTrackers[foundIndex];
		if( tTracker.fTime < RELEASE_THRESHOLD)
		{
			tTracker.fTime = 0;
			m_arrEventTrackers[foundIndex] = tTracker;
			InputEvent( cmd, class'UIUtilities_Input'.const.FXS_ACTION_TAP );
		}
	}
}

simulated final function ActivateTracker( int cmd, int ActionMask )
{
	local int foundIndex; 
	local TInputEventTracker tTracker;
	
	if(( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) == 0) return;
	
	if(IsMouseRangeEvent(cmd))
		return;

	foundIndex = m_arrEventTrackers.Find( 'iButton', cmd );
	if( foundIndex == -1 )
	{
		tTracker.iButton = cmd;
		tTracker.fTime = 0;

		m_arrEventTrackers.AddItem( tTracker);
	}
	else
	{
		//We're already tracking this cmd, so do nothing. 
	}
}

simulated function PostProcessTrackers( float DeltaTime )
{
	local int iTrackerIndex; 
	local TInputEventTracker tTracker;

	for( iTrackerIndex = 0; iTrackerIndex < m_arrEventTrackers.length; iTrackerIndex++ )
	{
		tTracker = m_arrEventTrackers[iTrackerIndex];
		
		// IF( The button has been held long enough and is just now crossing the threshold)
		if( (tTracker.fTime + DeltaTime >= RELEASE_THRESHOLD) && tTracker.fTime < RELEASE_THRESHOLD  )
		{
			// Simulate a hold event
			InputEvent( tTracker.iButton, class'UIUtilities_Input'.const.FXS_ACTION_HOLD );
		}

		tTracker.fTime += DeltaTime;

		// Start the repeat event trigger 
		if( !IsTimerActive( 'InputRepeatTimer', self ) )
			SetTimer(SIGNAL_REPEAT_FREQUENCY, true, 'InputRepeatTimer', self);
		
		m_arrEventTrackers[iTrackerIndex] = tTracker;
	}
}

//-------------------------------------------------------------------------------------------------------
//Timer functions - callback to create REPEAT event signals

simulated function InputRepeatTimer()
{
	local int iTrackerIndex; 
	local TInputEventTracker tTracker;

	for( iTrackerIndex = 0; iTrackerIndex < m_arrEventTrackers.length; iTrackerIndex++ )
	{
		tTracker = m_arrEventTrackers[iTrackerIndex];

		if( tTracker.fTime < RELEASE_THRESHOLD )
			InputEvent( tTracker.iButton, class'UIUtilities_Input'.const.FXS_ACTION_PREHOLD_REPEAT );
		else
			InputEvent( tTracker.iButton, class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT );
	}
}

// When cinematics start, we need to clear out the repeat trackers, else the cinematic will consume the 
// button's release, and the button release will never waterfall in to this system and release the 
// trackers. On UI Cinematic hide in the pres layer, we're manually clearing the trackers to prevent this issue. 
// -bsteiner 10.21.11
simulated function ClearAllRepeatTimers()
{
	m_arrEventTrackers.Length = 0; 
}

function bool AttemptSteamControllerConfirm(int cmd)
{
	local bool bHandled;

	if( cmd != class'UIUtilities_Input'.const.FXS_BUTTON_A_STEAM || !IsControllerActive() ) return false;

	// Steam controller code below; this button was unused, try to make it an all-in-one targeting/pathing tool

	if( TestMouseConsumedByFlash() )
	{
		//Push a click over in to Flash 
		XComPlayerController(Outer).Pres.ClickPathUnderMouse();
		bHandled = true;
	}

	if( TestMouseConsumedBy3DFlash() )
	{
		//Push a click over in to the 3D Flash movie 
		XComPlayerController(Outer).Pres.ClickPathUnderMouse3D();
		bHandled = true;
	}
	return bHandled; 
}

function bool CheckSteamControllerSmartToggle(int cmd, int ActionMask)
{
	if( cmd != class'UIUtilities_Input'.const.FXS_BUTTON_A_STEAM )
	{
		m_bInputSinceMouseMovement = true;
	}

	if( cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A_STEAM 
	   && IsControllerActive()
	   && m_bInputSinceMouseMovement )
	{

		//We're going to absorb the Key I press and turn it in to an Enter press. 
		InputEvent(class'UIUtilities_Input'.const.FXS_KEY_ENTER, ActionMask);

		//Returning true will absorb the original KEY_I event. 
		return true; 
	}
	return false;
}

defaultproperties
{
	m_fLTrigger = -1;
	m_fRTrigger = -1;
	aMouseXCached = 0.0f;
	aMouseYCached = 0.0f;

	m_bConsumedByFlashCached=false
	m_bConsumedBy3DFlashCached=false
	m_bConsumedByFlash=false
	m_bInputSinceMouseMovement=false
}
