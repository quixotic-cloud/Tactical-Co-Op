//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMouseGuard.uc
//  AUTHOR:  Sam Batista 8/7/2013
//  PURPOSE: Displays a movieclip that intercepts all mouse activity
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMouseGuard extends UIScreen;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	// invisible (but still consuming mouse events) on 3D screens because having a frame around the 3D render target looks weird
	if(bIsIn3D) SetAlpha(0);
}

//----------------------------------------------------------------------------

DefaultProperties
{
	MCName = "MouseGuardMC";
	Package = "/ package/gfxMouseGuard/MouseGuard";
	bHideOnLoseFocus = true;
	bProcessesMouseEvents = true;
	bShouldPlayGenericUIAudioEvents = false;
	InputState = eInputState_Consume;
}
