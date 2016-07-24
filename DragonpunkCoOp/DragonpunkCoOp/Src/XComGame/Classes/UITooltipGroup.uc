//---------------------------------------------------------------------------------------
//  FILE:    UITooltipGroup.uc
//  AUTHOR:  Rick Matchett --  2015
//  PURPOSE: Base class for a collection of tooltips that depend on each other in some way. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UITooltipGroup extends Object;

var array<UITooltip> Group;
var bool bShouldNotify;

simulated function int Add(UITooltip Tooltip)
{
	Tooltip.SetTooltipGroup(self);
	return Group.AddItem(Tooltip);
}

simulated function int Remove(UITooltip Tooltip)
{
	Tooltip.SetTooltipGroup(none);
	return Group.RemoveItem(Tooltip);
}

simulated final function SignalNotify()
{
	bShouldNotify = true;
}

simulated final function CheckNotify()
{
	if (bShouldNotify)
	{
		bShouldNotify = false;
		Notify();
	}
}

//Intended to be overwritten in child classes. 
simulated function Notify()
{

}