//----------------------------------------------------------------------------
//  *********   WORKSHOP   ******************
//  FILE:    UIGamepadIcons.uc
//  AUTHOR:  Jake Akemann
//  PURPOSE: UIGamepadIcons is used to spawn and display Console Gamepad icons on screen from GamepadIcons.swf
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIGamepadIcons extends UIPanel;

const X_OFFSET = 3.2;

simulated function UIGamepadIcons InitGamepadIcon(optional name InitName, optional String IconId = "", optional float IconSize = 0)
{
	super.InitPanel(InitName);

	if(IconId != "")
		SetIcon(IconId);

	if(IconSize > 0)
		SetSize(IconSize,IconSize);

	return self;
}

//Icon IDs can be found in 'UIUtilities_Input' under "GAMEPAD ICONS" section
simulated function SetIcon(String IconId)
{
	MC.FunctionString("gotoAndPlay", IconId);
}

defaultproperties
{
	LibID = "GamepadIcons";
	bIsNavigable = false;
	Height = 48;
	Width = 48;
}

