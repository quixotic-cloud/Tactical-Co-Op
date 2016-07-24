/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class SeqCond_CompareUnit extends SequenceCondition;

var XComGameState_Unit A;
var XComGameState_Unit B;

event Activated()
{
	OutputLinks[0].bHasImpulse = false;
	OutputLinks[1].bHasImpulse = false;

	if(A == none && B == none)
	{
		OutputLinks[0].bHasImpulse = true;
	}
	else if((A == none && B != none) || (A != none && B == none))
	{
		OutputLinks[1].bHasImpulse = true;
	}
	else if(A.ObjectID == B.ObjectID)
	{
		OutputLinks[0].bHasImpulse = true;
	}
	else
	{
		OutputLinks[1].bHasImpulse = true;
	}
}

defaultproperties
{
	ObjName="Compare Units"
	ObjCategory="Comparison"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="A == B")
	OutputLinks(1)=(LinkDesc="A != B")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="A",PropertyName=A)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="B",PropertyName=B)
}
