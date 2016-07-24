//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_BerserkerDevastatingPunch extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);

	if( TargetUnit == none )
	{
		return 'AA_NotAUnit';
	}

	if( TargetUnit.IsBleedingOut() )
	{
		return 'AA_UnitIsBleedingOut';
	}

	if( TargetUnit.IsUnconscious() )
	{
		return 'AA_UnitIsUnconscious';
	}

	if( TargetUnit.IsDead() || TargetUnit.IsStasisLanced() )
	{
		return 'AA_UnitIsDead';
	}

	if( TargetUnit.IsInStasis())
	{
		return 'AA_UnitIsInStasis';
	}

	if( TargetUnit.GetMyTemplate().bIsCosmetic)
	{
		return 'AA_UnitIsCosmetic';
	}

	return 'AA_Success';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;
	
	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);
	
	if( (SourceUnit == none) || (TargetUnit == none) )
	{
		return 'AA_NotAUnit';
	}

	if( SourceUnit.IsPlayerControlled() && TargetUnit.IsPlayerControlled() )
	{
		return 'AA_UnitIsFriendly';
	}
	
	return 'AA_Success';
}