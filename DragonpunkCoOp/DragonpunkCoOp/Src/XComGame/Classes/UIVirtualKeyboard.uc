//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIVirtualKeyboard.uc
//  AUTHOR:  Brit Steiner  --  06/29/09
//  PURPOSE: This file corresponds to the flash Virtual Keyboard screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIVirtualKeyboard extends UIScreen;

// Contain the layouts for the keyboard keys
// THESE LAYOUTS WILL NEED TO BE LOCALIZED!!! -bsteiner
var string m_kLayoutRegular;
var string m_kLayoutShift;
var string m_kLayoutShiftDisplay;
var string m_kLayoutAltGr;

var string m_sTitle;
var string m_sDefault;

// Callbacks when the user action is performed
delegate delActionAccept( string userInput );
delegate delActionCancel();

//----------------------------------------------------------------------------
// METHODS
//

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();	
	`log("++++++ VirtualKeyboard.OnInit()");
	
	InitializeLayouts();
	
	//TODO: bsteiner: What are these final icons? 
	SetFunctionButton( 0, class'UIUtilities_Input'.const.ICON_LB_L1, "Symbols"); //AltGr, international
	SetFunctionButton( 1, class'UIUtilities_Input'.const.ICON_RB_R1, "Shift");
	SetFunctionButton( 2, class'UIUtilities_Input'.const.ICON_LSCLICK_L3, "Capslock");
	SetFunctionButton( 3, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, "Space");
	SetFunctionButton( 4, class'UIUtilities_Input'.const.ICON_X_SQUARE, "Backspace");
	SetFunctionButton( 5, class'UIUtilities_Input'.static.GetBackButtonIcon(), "Cancel");
	SetFunctionButton( 6, class'UIUtilities_Input'.const.ICON_START, "Confirm");
	
	SetTitle(m_sTitle);
	SetDefaultText( m_sDefault );
	
	Invoke("buildDisplay");
	Show();

}


//----------------------------------------------------------------------------
//  Link input to correct special functions. Also absorbs all input, sending 
//  by default along a keyboard entries. 
//
simulated function bool OnUnrealCommand(int ucmd, int arg)
{

	//`log(MCName$".OnUnrealCommand" @ ucmd @ arg, true, 'uixcom'); 
	//`log(MCName$".OnUnrealCommand" @ ucmd @ arg); 
	
	// Only pay attention to presses or repeats; ignoring other input types
	if( !CheckInputIsReleaseOrDirectionRepeat(ucmd, arg) )
		return false;

	//TODO: bsteiner: What are these buttons ultimately goign to be? 
	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
			Invoke( "PressEnter" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
			Invoke( "PressCancel" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_X):
			Invoke( "PressBackspace" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_Y):
			Invoke( "PressSpace" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER):
			Invoke( "PressAltGr" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER):
			Invoke( "PressShift" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_L3):
			Invoke( "PressCapsLock" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_START):
			Invoke( "PressFinish" );
		//----------------------------------------------------
		case (class'UIUtilities_Input'.const.FXS_DPAD_UP):
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
			Invoke( "goUp" );
		break;
		case (class'UIUtilities_Input'.const.FXS_DPAD_DOWN):
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
			Invoke( "goDown" );
		break;
		case (class'UIUtilities_Input'.const.FXS_DPAD_RIGHT):
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
			Invoke( "goRight" );
		break;
		case (class'UIUtilities_Input'.const.FXS_DPAD_LEFT):
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
			Invoke( "goLeft" );
		break;
		//----------------------------------------------------
		case (class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER):
			Invoke( "CursorRight" );
		break;
		case (class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER):
			Invoke( "CursorLeft" );
		break;
		//----------------------------------------------------
		default: 
			`log("VirtualKeyboard has received a default input option!!!",,'uixcom');
			//PressKeyboardKey( "W" ); //DEBUGGING: bsteiner
			// Ultimately, this needs to send all incoming string presses along to PressKeyboardKey().
	}

	return super.OnUnrealCommand(ucmd, arg);
}

//----------------------------------------------------------------------------
// Receives information back from flash. 
//
simulated function OnCommand( string cmd, string arg )
{
	switch( cmd )
	{
		case("OnAccept"):
			//`log("VirtualKeyboard received OnAccept(" $arg $")",,'uixcom' );
			delActionAccept( arg );
			Movie.Stack.Pop(self);
			break;
		case("OnCancel"):
			//`log("VirtualKeyboard received OnCancel()",,'uixcom' );
			delActionCancel();
			Movie.Stack.Pop(self);
			break;
			
		case("OnOption"):
			// Do nothing
			break;

		default:
			`log("VirtualKeyboard received unhandled callback (" $cmd $", " $arg $")",,'uixcom');
	}
}

//----------------------------------------------------------------------------
// Overriding: Must clear out delegates, else ye may be faced with memory leaks and 
// potential crashes if calls are made post-removal! -bsteiner
//
simulated function Remove()
{
	
	delActionAccept = none;
	delActionCancel = none;

	super.Remove();
}


//----------------------------------------------------------------------------
//  Set up the key layout strings and send to flash 
//
simulated function InitializeLayouts()
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	// These used tilde delimiters to separate the individual keys.
	// THESE LAYOUTS WILL NEED TO BE LOCALIZED!!! -bsteiner
	m_kLayoutRegular = "1~2~3~4~5~6~7~8~9~0"$ 
						"~q~w~e~r~t~y~u~i~o~p" $
						"~a~s~d~f~g~h~j~k~l~" $ 
						"~z~x~c~v~b~n~m~,~.~/";
	
	m_kLayoutShift = "!~@~#~$~%~^~&~*~(~)"$ 
					  "~Q~W~E~R~T~Y~U~I~O~P" $
					  "~A~S~D~F~G~H~J~K~L~ " $ 
					  "~Z~X~C~V~B~N~M~,~.~/";
	
	m_kLayoutShiftDisplay = "!~@~#~$~%~^~&~*~(~)"$ 
							"~~~~~~~~~~"$
							"~~~~~~~~~~"$ 
							"~~~~~~~~~~";
	
	m_kLayoutAltGr = "~~~~~~~~~"$   
					 "~~~€~£~§~~~~—"$
					 "~~/~*~+~-~=~[~]~{~}"$  
					 "~~:~;~\"~'~\\~|~<~>~?"; 

	myValue.Type = AS_String;

	myValue.s = m_kLayoutRegular;
	myArray.AddItem( myValue );

	myValue.s = m_kLayoutShift;
	myArray.AddItem( myValue );

	myValue.s = m_kLayoutShiftDisplay;
	myArray.AddItem( myValue );

	myValue.s = m_kLayoutAltGr;
	myArray.AddItem( myValue );

	Invoke("SerializeLayouts", myArray);
}

//----------------------------------------------------------------------------
//Allows the string sKey to be appended directly to the current user input.
//
simulated function PressKeyboardKey( string sKey )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;
	myValue.s = sKey;
	myArray.AddItem( myValue );

	Invoke( "PressKeyboardKey", myArray );
}

//----------------------------------------------------------------------------
// Sets the title or "prompt" on the display.
//
simulated function SetTitle( string DisplayText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	m_sTitle = DisplayText; 
	if( !bIsInited ) return; 

	myValue.Type = AS_String;
	myValue.s = DisplayText;
	myArray.AddItem( myValue );

	Invoke( "SetTitle", myArray );
}

//----------------------------------------------------------------------------
//Set the icon and display for the specified "special function" buttons around 
//the perimiter of the screen. 
//
simulated function SetFunctionButton( int Index, string ButtonIcon, string DisplayText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = Index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = ButtonIcon;
	myArray.AddItem( myValue );
	myValue.s = DisplayText;
	myArray.AddItem( myValue );

	Invoke( "SetFunctionButton", myArray );
}
//----------------------------------------------------------------------------
//Set the icon and display for the specified "special function" buttons around 
//the perimiter of the screen. 
//
simulated function SetDefaultText( string DisplayText)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	m_sDefault = DisplayText;
	if( !bIsInited ) return; 

	myValue.Type = AS_String;
	myValue.s = m_sDefault;
	myArray.AddItem( myValue );

	Invoke( "SetDefaultText", myArray );
}

defaultproperties
{
	MCName      = "theVirtualKeyboard";
	Package   = "/ package/gfxVirtualKeyboard/VirtualKeyboard";
	InputState = eInputState_Evaluate;
}