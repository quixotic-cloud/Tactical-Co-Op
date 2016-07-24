///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_IsUnitTrapped.uc
//  AUTHOR:  David Burchanowski  --  9/16/2014
//  PURPOSE: Action to determine if a given unit is "trapped", i.e., it stuck in a pathing island of
//  some kind
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_IsUnitTrapped extends SequenceAction;

var() int MinTileDistance; // minimum tiles this unit must be able to move to not be considered trapped
var XComGameState_Unit Unit;

event Activated()
{
	if(Unit == none)
	{
		`Redscreen("Warning: SeqAct_IsUnitTrapped was called without specifying a unit.");
		OutputLinks[0].bHasImpulse = false;
		OutputLinks[1].bHasImpulse = true;
		return;
	}

	if(class'X2PathSolver'.static.IsUnitTrapped(Unit, MinTileDistance))
	{
		OutputLinks[0].bHasImpulse = true;
		OutputLinks[1].bHasImpulse = false;
	}
	else
	{
		OutputLinks[0].bHasImpulse = false;
		OutputLinks[1].bHasImpulse = true;
	}
}

defaultproperties
{
	ObjName="Is Unit Trapped"
	ObjCategory="Unit"
	bCallHandler=false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	OutputLinks(0)=(LinkDesc="Yes")
	OutputLinks(1)=(LinkDesc="No")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit', LinkDesc="Unit", PropertyName=Unit)

	MinTileDistance=6
}