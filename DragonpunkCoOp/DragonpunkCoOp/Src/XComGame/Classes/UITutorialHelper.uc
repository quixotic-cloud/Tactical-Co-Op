//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITutorialHelper
//  AUTHOR:  Brittany Steiner
//  PURPOSE: Wrapper functions for gameplay to trigger UI tutorial visuals. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITutorialHelper extends UIScreen;

simulated function OnInit()
{
	super.OnInit();
	Movie.InsertHighestDepthScreen(self);
}


// --------------------------------------------------------------------------------------

defaultproperties
{
	InputState = eInputState_None;
	bAnimateOnInit = false;
	bIsNavigable = false;
	bShowDuringCinematic = false;
}