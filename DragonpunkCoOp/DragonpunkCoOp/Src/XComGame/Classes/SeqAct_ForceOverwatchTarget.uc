//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ForceOverwatchTarget.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Forces a unit to be targeted by an overwatch (move-interrupting) ability if that
//           unit is an available target
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_ForceOverwatchTarget extends SequenceAction;

var XComGameState_Unit Unit;

event Activated()
{
	local XComTacticalCheatManager CheatManager;
	
	if(Unit == none)
	{
		`Redscreen("SeqAct_ForceOverwatchTarget: no unit provided, bailing");
		return;
	}

	CheatManager = `CHEATMGR;
	CheatManager.ForcedOverwatchTarget = Unit.GetReference();
}

defaultproperties
{
	ObjCategory="Automation"
	ObjName="Force Overwatch Target"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}