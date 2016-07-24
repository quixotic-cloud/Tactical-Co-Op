//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_Panic.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    8/29/2015
//  PURPOSE: Condition for activating the panic ability in response to a panic event. 
//           Should not be used when applying panic otherwise (e.g. from Insanity).
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_Panic extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState, OtherUnit;
	local XComGameState_Effect EffectState;
	local X2Effect_Solace SolaceEffect;
	local XComGameStateHistory History;
	local int PanicCount, ActiveCount;

	UnitState = XComGameState_Unit(kTarget);
	if (UnitState == none)
		return 'AA_NotAUnit';
	if (UnitState.IsDead() || UnitState.IsUnconscious() || UnitState.IsBleedingOut())
		return 'AA_UnitIsDead';

	if (UnitState.IsPanicked())
		return 'AA_UnitIsPanicked';

	EffectState = UnitState.GetUnitAffectedByEffectState(class'X2Effect_Solace'.default.EffectName);
	if (EffectState != none)
	{
		SolaceEffect = X2Effect_Solace(EffectState.GetX2Effect());
		if (SolaceEffect != none)
		{
			if (SolaceEffect.IsEffectCurrentlyRelevant(EffectState, UnitState))
				return 'AA_UnitIsImmune';
		}
	}

	//  Check to see if we are at the panic limit
	if (!UnitState.ControllingPlayerIsAI())
	{
		PanicCount = 0;
		ActiveCount = 0;
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', OtherUnit)
		{
			if (OtherUnit != UnitState && OtherUnit.IsAlive() && OtherUnit.GetTeam() == UnitState.GetTeam())
			{
				if (OtherUnit.IsPanicked())
					PanicCount++;
				else if (OtherUnit.IsAbleToAct())
					ActiveCount++;
			}
		}
		if (PanicCount >= class'X2StatusEffects'.default.MAX_PANICKING_UNITS || ActiveCount == 0)
		{
			return 'AA_UnitIsImmune';
		}
	}

	return 'AA_Success';
}