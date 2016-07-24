//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIListItemSpinner.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Basic list item control.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIListItemSpinner extends UIPanel;

var int selectedIndex;
var string value;
var string label;
var bool bCenter; 
var bool bIsDisabled; 

var delegate<OnSpinnerChangedCallback> onSpinnerChanged;

// direction will either be -1 (left arrow), or 1 (right arrow)
delegate OnSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction);

simulated function UIListItemSpinner InitSpinner(optional string initText, 
												 optional string initValue, 
												 optional delegate<OnSpinnerChangedCallback> spinnerChangedCallback)
{
	super.InitPanel();
	SetText(initText);
	SetValue(initValue);
	onSpinnerChanged = spinnerChangedCallback;
	return self;
}

simulated function UIListItemSpinner SetText(string txt)
{
	if(label != txt)
	{
		label = txt;
		mc.FunctionString("setLabel", label);
	}
	return self;
}

simulated function UIListItemSpinner SetValue(string val)
{
	if(value != val)
	{
		value = val;
		mc.FunctionString("setValue", value);
	}
	return self;
}

public function SetValueWidth(int newWidth, bool center) 
{
	if( Width != newWidth || bCenter != center )
	{
		Width = newWidth;
		bCenter = center;

		MC.BeginFunctionOp("forceValueWidth");
		MC.QueueNumber(Width);
		MC.QueueBoolean(bCenter);
		MC.EndOp();
	}
}

simulated function UIListItemSpinner SetDisabled(bool bDisabled)
{
	if(bIsDisabled != bDisabled)
	{
		bIsDisabled = bDisabled;
		mc.FunctionBool("setDisabled", bIsDisabled);
	}
	return self;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			onSpinnerChanged(self, -1);
			return true;
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			onSpinnerChanged(self, 1);
			return true;
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string callbackTarget;

	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP && onSpinnerChanged != none)
	{
		callbackTarget = args[args.Length - 1];
		switch(callbackTarget)
		{
		case "leftArrow":
			onSpinnerChanged(self, -1);
			break;
		case "rightArrow":
			onSpinnerChanged(self, 1);
			break;
		}
	}
}


defaultproperties
{
	LibID = "XComSpinner";
	width = 207; 
	height = 37; 
	bCenter = true;
}