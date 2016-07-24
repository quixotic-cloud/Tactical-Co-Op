//---------------------------------------------------------------------------------------
//  FILE:    UITooltipGroup_Stacking.uc
//  AUTHOR:  Rick Matchett --  2015
//  PURPOSE: Class for a collection of tooltips that stack on top of eachother. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UITooltipGroup_Stacking extends UITooltipGroup;

var array<float> RestingYPositions;

simulated function int Add(UITooltip Tooltip)
{
	//Add a default resting positon for this tooltip
	RestingYPositions.AddItem(9999);
	return super.Add(Tooltip);
}

simulated function int Remove(UITooltip Tooltip)
{
	local int Index;
	Index = Group.Find(Tooltip);
	if (Index != INDEX_NONE)
	{
		RestingYPositions.Remove(Index, 1);
	}

	return super.Remove(Tooltip);
}

simulated function int AddWithRestingYPosition(UITooltip Tooltip, float YPos)
{
	local int Index;
	Index = Add(Tooltip);
	//Overwrite the default with the supplied value.
	RestingYPositions[Index] = YPos;
	return Index;
}

simulated function int UpdateRestingYPosition(UITooltip Tooltip, float YPos)
{
	local int Index;
	Index = Group.Find(Tooltip);
	if(Index != INDEX_NONE)
		RestingYPositions[Index] = YPos;
	return Index;
}

simulated function Notify()
{
	local UITooltip CurrentTooltip, PreviousTooltip;
	local float CurrentOffset;
	local int Index;

	//Default the current offset to a large value since these tooltips stack from the bottom of the screen.
	CurrentOffset = 9999;

	for (Index = 1; Index < Group.Length; ++Index)
	{
		CurrentTooltip = Group[Index];
		PreviousTooltip = Group[Index - 1];
		//Only consider tooltips in the group that are visible.
		if (PreviousTooltip.bIsVisible)
		{
			CurrentOffset = PreviousTooltip.Y;
		}
		//Select the position that is higher up on the screen.
		CurrentTooltip.SetY(Min(RestingYPositions[Index], CurrentOffset - CurrentTooltip.Height));
	}
}