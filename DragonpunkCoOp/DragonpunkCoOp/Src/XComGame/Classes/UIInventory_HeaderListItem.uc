//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventory_HeaderListItem.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIPanel representing a list entry that separates categories on UIInventory screens.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIInventory_HeaderListItem extends UIPanel;

simulated function InitHeaderItem(optional string IconPath, optional string HeaderText, optional string SubHeaderText)
{
	InitPanel();
	PopulateData(IconPath, HeaderText, SubHeaderText);
}

simulated function PopulateData(string IconPath, string HeaderText, string SubHeaderText)
{
	MC.BeginFunctionOp("populateData");
	MC.QueueString(IconPath);
	MC.QueueString(HeaderText);
	MC.QueueString(SubHeaderText);
	MC.EndOp();
}

defaultproperties
{
	width = 565;
	height = 62;
	bProcessesMouseEvents = false;
	LibID = "InventoryHeaderRowItem";
}
