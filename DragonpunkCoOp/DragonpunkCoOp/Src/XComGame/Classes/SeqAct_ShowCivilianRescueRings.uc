//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ShowCivilianRescueRings.uc
//  AUTHOR:  David Burchanowski  --  10/30/2014
//  PURPOSE: Shows rescue rings around all of the civilian units
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqAct_ShowCivilianRescueRings extends SequenceAction;

var() private int RescueRingRadius;

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XGUnit UnitVisualizer;
	local float RescueRingRadiusUnrealUnits;

	History = `XCOMHISTORY;

	RescueRingRadiusUnrealUnits = RescueRingRadius * class'XComWorldData'.const.WORLD_StepSize;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.GetTeam() == eTeam_Neutral && !Unit.IsDead())
		{
			UnitVisualizer = XGUnit(Unit.GetVisualizer());
			UnitVisualizer.GetPawn().AttachRangeIndicator(RescueRingRadiusUnrealUnits, UnitVisualizer.GetPawn().CivilianRescueRing);
		}
	}
}

defaultproperties
{
	ObjName="Show Civilian Rescue Rings"
	RescueRingRadius=3

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty
}