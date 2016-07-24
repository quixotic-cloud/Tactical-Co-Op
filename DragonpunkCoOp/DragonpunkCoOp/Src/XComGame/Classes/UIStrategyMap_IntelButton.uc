//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMap_IntelButton
//  AUTHOR:  Brit Steiner
//  PURPOSE: Dynamically attached intel button on map pins. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMap_IntelButton extends UIButton;

var string IntelTitle;
var string IntelTimeValue;
var string IntelTimeLabel;
var string IntelInfo;
var bool bAnimate; 

simulated function UIStrategyMap_IntelButton InitIntelButton(optional name InitName, optional string InitLabel, optional delegate<OnClickedDelegate> InitOnClicked)
{
	InitButton(InitName, InitLabel, InitOnClicked);

	AnimateButton(false, true);

	return self;
}

simulated function SetTextAndLabel(string Title, string TimeValue, string TimeLabel, string ExtraInfo)
{
	// Adding an init check here, because this function gets hammered 
	if(!bIsInited) return;

	if( Title != "" )
		Show();
	else
		Hide();

	if( IntelTitle != Title || IntelTimeValue != TimeValue || IntelTimeLabel != TimeLabel || IntelInfo != ExtraInfo)
	{
		IntelTitle = Title;
		IntelTimeValue = TimeValue;
		IntelTimeLabel = TimeLabel;
		IntelInfo = ExtraInfo;

		MC.BeginFunctionOp("setHTMLText");
		MC.QueueString(IntelTitle);
		MC.QueueString(IntelTimeValue);
		MC.QueueString(IntelTimeLabel);
		MC.QueueString(IntelInfo);
		MC.EndOp();
	}
}

simulated function AnimateButton(bool bShouldAnimate, optional bool bForceCall = false)
{
	if( bAnimate != bShouldAnimate || bForceCall )
	{
		bAnimate = bShouldAnimate;

		MC.BeginFunctionOp("animateButton");
		MC.QueueBoolean(bAnimate);
		MC.EndOp();
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
}

//------------------------------------------------------

defaultproperties
{
	LibID = "IntelButton";
}