//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_StasisTarget.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    18 Aug 2015
//  PURPOSE: Use this in place of a regular UnitProperty condition for Stasis ability.
//           Allows friendlies to be targeted if the source unit has Stasis Shield.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_StasisTarget extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (TargetUnit.IsDead())
		return 'AA_UnitIsDead';

	if (TargetUnit.IsInStasis())
		return 'AA_UnitIsInStasis';

	//Due to an issue with targeting in general, cosmetic units may end up considered as targets. Explicitly disallow this.
	if (TargetUnit.GetMyTemplate().bIsCosmetic)
		return 'AA_UnitIsCosmetic';

	return 'AA_Success'; 
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit TargetUnit, SourceUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	SourceUnit = XComGameState_Unit(kSource);

	if (TargetUnit == none || SourceUnit == none)
		return 'AA_NotAUnit';

	if (!SourceUnit.HasSoldierAbility('StasisShield'))
	{
		if (SourceUnit.IsFriendlyUnit(TargetUnit))
			return 'AA_UnitIsFriendly';
	}

	return 'AA_Success';
}