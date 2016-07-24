//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIScreenListener
//  AUTHOR:  Ryan McFall & Sam Batista
//
//  PURPOSE: Provides hooks for mod-based screens to manipulate the shipped UI without
//           requiring edits to the shipped script packages.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIScreenListener extends Object native(UI);

// Set this value in the defaultproperties to filter UI signals based on class
var class<UIScreen> ScreenClass;

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen);

// This event is triggered after a screen receives focus
event OnReceiveFocus(UIScreen Screen);

// This event is triggered after a screen loses focus
event OnLoseFocus(UIScreen Screen);

// This event is triggered when a screen is removed
event OnRemoved(UIScreen Screen);

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = none;
}