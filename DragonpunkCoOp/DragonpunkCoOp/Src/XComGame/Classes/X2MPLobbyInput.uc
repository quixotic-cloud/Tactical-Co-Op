//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPLobbyInput.uc
//  AUTHOR:  Todd Smith  --  8/13/2015
//  PURPOSE: Input for the lobby
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPLobbyInput extends XComShellInput;

//-----------------------------------------------------------
// Called from InputEvent if the External UI is open. (i.e. Steam)
//  cmd             Input command to act on (see UIUtilities_Input for values)
//  ActionMask      behavio of the incoming command (press, hold, repeat, release) 
//
//  Return: True to stop processing input, False to continue processing
function bool HandleExternalUIOpen( int cmd , optional int ActionMask = class'UIUtilities_Input'.const.FXS_ACTION_PRESS )
{
	local bool bStopProcessing;
	`log(`location @ `ShowVar(cmd) @ `ShowVar(ActionMask),,'BUG1590_InputHang');
    // HACK: Adding this for Invite Dialog Closing XCOM_EW: BUG 1590: [MP] - Game lost functionality when attempting to pull up invite menu with a 360 controller.
	// Returning false to allow all buttons to be pressed. Somehow the externalUI flag has been enabled, but the Overlay is not consuming input.
	bStopProcessing = WorldInfo.IsConsoleBuild(CONSOLE_Any); // Only continue (False) for Steam since the Overlay is supposed to consume input, but may not have opened properly. -ttalley
    return bStopProcessing;
}

defaultproperties
{

}
