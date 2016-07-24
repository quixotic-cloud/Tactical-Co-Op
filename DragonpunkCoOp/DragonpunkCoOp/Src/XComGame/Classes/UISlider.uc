//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISlider.uc
//  AUTHOR:  Brittany Steiner 
//  PURPOSE: UIPanel to interface with XComSlider
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UISlider extends UIPanel;

const INCREASE_VALUE = -1;  // spinner, sliders
const DECREASE_VALUE = -2;  // spinner, sliders

var string text;
var float percent;
var float stepSize; //Percent of 100 that an arrow click will cause the value to step. 

var delegate<OnChangedCallback> onChangedDelegate;
delegate OnChangedCallback(UISlider sliderControl);

simulated function UISlider InitSlider(optional name InitName, optional string initText, optional float initPercent, optional delegate<OnChangedCallback> percentChangedDelegate, optional float initStepSize)
{
	InitPanel(InitName);
	onChangedDelegate = percentChangedDelegate;
	SetText(initText);
	SetPercent(initPercent);
	if (initStepSize > 0.0)
		SetStepSize(initStepSize);
	return self;
}

simulated function UISlider SetText(string newText)
{
	if(text != newText)
	{
		text = newText;
		mc.FunctionString("setLabel", text);
	}
	return self;
}

simulated function UISlider SetPercent(float newValue)
{
	if (newValue < 1) newValue = 1;
	else if (newValue > 100) newValue = 100;

	if(percent != newValue)
	{
		percent = newValue;
		mc.FunctionNum("setValue", newValue);
	}
	return self;
}

simulated function UISlider SetStepSize(float newValue)
{
	if (stepSize != newValue)
	{
		stepSize = newValue;
		mc.FunctionNum("setValue", newValue);
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
			OnDecrease();
			if( onChangedDelegate != none)
				onChangedDelegate(self);
			return true;
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			OnIncrease();
			if( onChangedDelegate != none)
				onChangedDelegate(self);
			return true;
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	// send a clicked callback
	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		if( float(args[args.length-1]) == INCREASE_VALUE )
			OnIncrease();
		else if( float(args[args.length-1]) == DECREASE_VALUE )
			OnDecrease();
		else
			SetPercent( float(args[args.length-1]) ); 

		if( onChangedDelegate != none)
			onChangedDelegate(self);
	}
}

simulated function OnDecrease()
{
	local float per; 
	per = percent; 
	per -= stepSize;
	SetPercent(per);
}

simulated function OnIncrease()
{
	local float per; 
	per = percent; 
	per += stepSize;
	SetPercent(per);
}

defaultproperties
{
	LibID = "SliderControl";
	bIsNavigable = true;

	percent = 0; 
	stepSize = 10.0; 
}
