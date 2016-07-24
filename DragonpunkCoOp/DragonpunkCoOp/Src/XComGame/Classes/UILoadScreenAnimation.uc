//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UILoadScreenAnimation.uc
//  AUTHOR:  Brit Steiner
//
//  PURPOSE: Overlay animation to use while loading. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UILoadScreenAnimation extends UIScreen;

simulated function OnInit()
{
	super.OnInit();
	Show();
}

DefaultProperties
{
	Package   = "/ package/gfxLoadScreenAnimation/LoadScreenAnimation";
	MCName = "theLoadScreenAnimation";
	InputState = eInputState_None;
	bIsVisible = false;
}
