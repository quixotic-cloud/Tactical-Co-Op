//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDropShipBriefing_ListItem.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: List item showing post mission stats.
//
//  NOTE: Used in UIDropShipBriefing_MissionEnd
//
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIDropShipBriefing_ListItem extends UIPanel;

function InitListitem(name InitLibID, string Label, string Value, optional bool bAlignRight)
{
	super.InitPanel(, InitLibID);

	MC.BeginFunctionOp("setData");
	MC.QueueString(Label);
	MC.QueueString(Value);
	MC.QueueBoolean(bAlignRight);
	MC.EndOp();
}

defaultproperties
{
	Width = 500
	Height = 67
}