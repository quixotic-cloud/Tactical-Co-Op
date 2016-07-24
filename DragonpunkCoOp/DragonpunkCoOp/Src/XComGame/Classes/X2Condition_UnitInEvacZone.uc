//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Condition_UnitInEvacZone.uc
//  AUTHOR:  Josh Bouscher, David Burchanowski
//  PURPOSE: Condition for determining if a unit is currently in the evac zone.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2Condition_UnitInEvacZone extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;
	local XComGameState_EvacZone EvacZone;

	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)
		return 'AA_NotAUnit';

	EvacZone = class'XComGameState_EvacZone'.static.GetEvacZone(UnitState.GetTeam());

	if (EvacZone != none && EvacZone.IsUnitInEvacZone(UnitState))
		return 'AA_Success';

	return 'AA_NotInsideEvacZone';
}