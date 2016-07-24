//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect_UtilityItem
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: Displays a Utility Item's image, or a locked icon if none is equipped.
//  NOTE:    Can be clicked on.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPSquadSelect_UtilityItem extends UISquadSelect_UtilityItem;


function OnButtonClicked(UIButton ButtonClicked)
{
	UIMPSquadSelect_ListItem(GetParent(class'UIMPSquadSelect_ListItem')).OnUtilItemClicked(SlotType, SlotIndex);
}