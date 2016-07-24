///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_IsUnitTrapped.uc
//  AUTHOR:  David Burchanowski  --  9/16/2014
//  PURPOSE: Action to determine if a given unit is "trapped", i.e., it stuck in a pathing island of
//  some kind
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_GetUnitStatus extends SequenceAction;

var XComGameState_Unit Unit;

event Activated()
{
	local int LinkIndex;

	if(Unit == none)
	{
		`Redscreen("Warning: SeqAct_GetUnitStatus was called without specifying a unit.");

		for(LinkIndex = 0; LinkIndex < OutputLinks.Length; LinkIndex++)
		{
			OutputLinks[LinkIndex].bHasImpulse = false;
		}

		return;
	}

	OutputLinks[0].bHasImpulse = Unit.IsAlive();
	OutputLinks[1].bHasImpulse = !OutputLinks[0].bHasImpulse;

	OutputLinks[2].bHasImpulse = Unit.IsUnconscious();
	OutputLinks[3].bHasImpulse = Unit.IsBleedingOut();
	OutputLinks[4].bHasImpulse = Unit.IsImpaired();
	OutputLinks[5].bHasImpulse = Unit.IsMindControlled();

	// Healthy if none of the status conditions return true and is alive
	OutputLinks[6].bHasImpulse = OutputLinks[0].bHasImpulse && !OutputLinks[2].bHasImpulse && !OutputLinks[3].bHasImpulse && !OutputLinks[4].bHasImpulse && !OutputLinks[5].bHasImpulse;
}

defaultproperties
{
	ObjName="Get Unit Status"
	ObjCategory="Unit"
	bCallHandler=false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	OutputLinks(0)=(LinkDesc="Alive")
	OutputLinks(1)=(LinkDesc="Dead")
	OutputLinks(2)=(LinkDesc="Unconscious")
	OutputLinks(3)=(LinkDesc="Bleeding Out")
	OutputLinks(4)=(LinkDesc="Impaired")
	OutputLinks(5)=(LinkDesc="Mind Controlled")
	OutputLinks(6)=(LinkDesc="Healthy")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit', LinkDesc="Unit", PropertyName=Unit)
}