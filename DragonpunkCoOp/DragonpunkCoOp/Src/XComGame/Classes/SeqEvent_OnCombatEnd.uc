//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_OnCombatEnd.uc
//  AUTHOR:  Ryan McFall  --  3/10/2014
//  PURPOSE: Fires when the number of red alert units transitions from more than zero to zero
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_OnCombatEnd extends SeqEvent_X2GameState;

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

	OutputLinks(0)=(LinkDesc="Combat End")

	bGameSequenceEvent=true
	bConvertedForReplaySystem=true

	ObjCategory="Gameplay"
	ObjName="On Combat End"
}
