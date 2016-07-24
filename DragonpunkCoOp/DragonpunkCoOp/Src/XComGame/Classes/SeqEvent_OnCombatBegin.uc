//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_OnCombatBegin.uc
//  AUTHOR:  Ryan McFall  --  3/10/2014
//  PURPOSE: Fires when the number of red alert units transitions from 0 to 1
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_OnCombatBegin extends SeqEvent_X2GameState;

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

	OutputLinks(0)=(LinkDesc="Combat Begin")

	bGameSequenceEvent=true
	bConvertedForReplaySystem=true

	ObjCategory="Gameplay"
	ObjName="On Combat Begin"
}
