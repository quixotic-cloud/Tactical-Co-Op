//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc_SeeMovement.uc
//  AUTHOR:  Ryan McFall  --  1/11/2014
//  PURPOSE: Defines the abilities that form the concealment / alertness mechanics in 
//  X-Com 2. Presently these abilities are only available to the AI.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityToHitCalc_SeeMovement extends X2AbilityToHitCalc;

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int RandRoll;
	
	RandRoll = `SYNC_RAND_TYPED(100, ESyncRandType_Generic);
	
	if (RandRoll <= GetHitChance(kAbility, kTarget))
		ResultContext.HitResult = eHit_Success;
	else
		ResultContext.HitResult = eHit_Miss;
}

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	local XComGameState_Unit LookoutUnitState;

	LookoutUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));

	//  @TODO gameplay - implement actual gameplay rules
	return 10 + LookoutUnitState.GetCurrentStat(eStat_SeeMovement);
}

function int GetShotBreakdown(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown kBreakdown)
{
	kBreakdown.HideShotBreakdown = true;
	return kBreakdown.FinalHitChance;
}

function bool NoGameStateOnMiss()
{
	return true;
}