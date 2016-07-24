//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_UITimer.uc
//  AUTHOR:  Kirk Martinez --  08/19/2015
//  PURPOSE: Game State Object that represents the objective timer
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameState_UITimer extends XComGameState_BaseObject;

var int TimerValue;
var int UiState;
var bool ShouldShow;
var string  DisplayMsgTitle;
var string  DisplayMsgSubtitle;

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
}