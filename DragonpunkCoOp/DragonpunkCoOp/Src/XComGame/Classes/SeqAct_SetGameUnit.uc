///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SetGameUnit.uc
//  AUTHOR:  David Burchanowski  --  9/16/2014
//  PURPOSE: Copies a game unit variable to another game unit variable
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_SetGameUnit extends SeqAct_SetSequenceVariable;

var XComGameState_Unit Source;
var XComGameState_Unit Target;

function Activated()
{
	Target = Source;
}

defaultproperties
{
	ObjName="Game Unit"
	bCallHandler=false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Source",PropertyName=Source)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Target",bWriteable=true,PropertyName=Target)
}
