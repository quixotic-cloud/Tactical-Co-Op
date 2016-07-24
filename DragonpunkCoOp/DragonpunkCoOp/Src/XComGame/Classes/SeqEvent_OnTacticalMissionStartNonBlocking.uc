//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_OnTacticalMissionStartNonBlocking.uc
//  AUTHOR:  Dan Kaplan  --  4/22/2015
//  PURPOSE: Fires when at the start of the mission just before the player gains control
//			 of their units.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqEvent_OnTacticalMissionStartNonBlocking extends SeqEvent_X2GameState;

event Activated()
{
	OutputLinks[0].bHasImpulse = true;
}

static function Fire()
{

}

defaultproperties
{
	VariableLinks.Empty

	OutputLinks(0) = (LinkDesc = "Mission Start")

	bGameSequenceEvent = true
	bConvertedForReplaySystem = true

	ObjCategory = "Gameplay"
	ObjName = "On Mission Start (Non-Blocking)"
}
