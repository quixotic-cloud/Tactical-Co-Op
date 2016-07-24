//---------------------------------------------------------------------------------------
//  FILE:    UICallbackData_SystemMessage.uc
//  AUTHOR:  Timothy Talley  --  04/26/2012
//  PURPOSE: Glues together the dialog callback to the OnlineEventMgr callback.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UICallbackData_SystemMessage extends UICallbackData;

var delegate<OnlineEventMgr.DisplaySystemMessageComplete> dOnSystemMessageComplete;

defaultproperties
{
}