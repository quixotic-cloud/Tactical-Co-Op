//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UICheckbox.uc
//  AUTHOR:  Brittany Steiner 
//  PURPOSE: UICheckbox to interface with XComSlider
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UICheckbox extends UIPanel;

// Match setting in flash: 
const STYLE_TEXT_TO_THE_LEFT  = 0;	// Text shows up to the left of the checkbox (default)
const STYLE_TEXT_ON_THE_RIGHT = 1;	// Text shows up to the right of the checkbox

var string text;
var bool bChecked;
var bool bReadOnly;
var int iStyle;

var name AlternateLibID;

var delegate<OnChangedCallback> onChangedDelegate;
delegate OnChangedCallback(UICheckbox checkboxControl);

simulated function UICheckbox InitCheckbox(optional name InitName, optional string initText, optional bool bInitChecked, optional delegate<OnChangedCallback> statusChangedDelegate, optional bool bInitReadOnly)
{
	InitPanel(InitName);
	SetText(initText);
	SetChecked(bInitChecked);
	SetReadOnly(bInitReadOnly);
	onChangedDelegate = statusChangedDelegate;
	return self;
}

simulated function UICheckbox SetText(string newText)
{
	if(text != newText)
	{
		text = newText;
		mc.FunctionString("setLabel", text);
		mc.FunctionVoid("realize");
	}
	return self;
}

simulated function UICheckbox SetChecked(bool bIsChecked, optional bool bTriggerChangedDelegate = true)
{
	if(bChecked != bIsChecked)
	{
		bChecked = bIsChecked;
		mc.FunctionBool("setChecked", bIsChecked);

		if( bTriggerChangedDelegate && onChangedDelegate != none )
			onChangedDelegate(self);
	}
	return self;
}

simulated function UICheckbox SetReadOnly(bool bIsReadOnly)
{
	if(bReadOnly != bIsReadOnly)
	{
		bReadOnly = bIsReadOnly;
		mc.FunctionBool("setReadOnly", bReadOnly);
	}
	return self;
}

simulated function UICheckbox SetTextStyle(int iNewStyle)
{
	if(iStyle != iNewStyle)
	{
		iStyle = iNewStyle;
		mc.FunctionNum("setTextStyle", iStyle);
	}
	return self;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			if( !bReadOnly )
				SetChecked(!bChecked);
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	// send a clicked callback
	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		if( !bReadOnly )
			SetChecked(!bChecked);
	}
	super.OnMouseEvent(cmd, args);
}

defaultproperties
{
	LibID = "CheckboxControl";
	AlternateLibID = "X2CheckboxControl";
	bIsNavigable = true;
	bProcessesMouseEvents = true;

	bChecked = false; 
	bReadOnly = false; 
}
