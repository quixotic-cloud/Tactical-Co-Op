///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_GetCurrentDifficulty.uc
//  AUTHOR:  Dan Kaplan  --  11/24/15
//  PURPOSE: Action to determine the current difficulty
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_GetCurrentDifficulty extends SequenceAction;


event Activated()
{
	OutputLinks[`DifficultySetting].bHasImpulse = true;
}

defaultproperties
{
	ObjName="Current Difficulty"
	ObjCategory="Scripting"
	bCallHandler=false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	OutputLinks(0)=(LinkDesc="Rookie")
	OutputLinks(1)=(LinkDesc="Veteran")
	OutputLinks(2)=(LinkDesc="Commander")
	OutputLinks(3)=(LinkDesc="Legend")
}