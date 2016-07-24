//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    SeqAct_AreEnemiesInEvacZone.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Indicates if, and how many, enemies are in the evac zone
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class SeqAct_AreEnemiesInEvacZone extends SequenceAction;

var private int Count;

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_EvacZone EvacZoneState;

	History = `XCOMHISTORY;
	Count = 0;

	// find the evac zone, if one has been placed
	EvacZoneState = class'XComGameState_EvacZone'.static.GetEvacZone(eTeam_XCom);

	if(EvacZoneState == none)
	{
		OutputLinks[0].bHasImpulse = false;
		OutputLinks[1].bHasImpulse = true;
		return;
	}

	// count the enemy units in it
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if(UnitState.GetTeam() == eTeam_Alien 
			&& !UnitState.IsDead() 
			&& !UnitState.IsUnconscious()
			&& EvacZoneState.IsUnitInEvacZone(UnitState))
		{
			Count++;
		}
	}

	// and activate the appropriate outputs
	OutputLinks[0].bHasImpulse = Count > 0;
	OutputLinks[1].bHasImpulse = !OutputLinks[0].bHasImpulse;
}

defaultproperties
{
	ObjName="Are Enemies In Evac Zone"
	ObjCategory="Gameplay"

	OutputLinks(0)=(LinkDesc="Yes")
	OutputLinks(1)=(LinkDesc="No")

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	bAutoActivateOutputLinks=false

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Int',LinkDesc="Count",PropertyName=Count, bWriteable=true)
}
