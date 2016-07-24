//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc_PercentChange.uc
//  AUTHOR:  Scott Boeckmann
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityToHitCalc_PercentChance extends X2AbilityToHitCalc;

var int PercentToHit;
var bool bNoGameStateOnMiss;

function bool NoGameStateOnMiss() { return bNoGameStateOnMiss; }

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int MultiIndex, RandRoll;
	local ArmorMitigationResults NoArmor;

	RandRoll = `SYNC_RAND_TYPED(100, ESyncRandType_Generic);
	ResultContext.HitResult = RandRoll < PercentToHit ? eHit_Success : eHit_Miss;
	ResultContext.ArmorMitigation = NoArmor;
	ResultContext.CalculatedHitChance = PercentToHit;

	for (MultiIndex = 0; MultiIndex < kTarget.AdditionalTargets.Length; ++MultiIndex)
	{
		RandRoll = `SYNC_RAND_TYPED(100, ESyncRandType_Generic);
		ResultContext.MultiTargetHitResults.AddItem(RandRoll < PercentToHit ? eHit_Success : eHit_Miss);
		ResultContext.MultiTargetArmorMitigation.AddItem(NoArmor);
		ResultContext.MultiTargetStatContestResult.AddItem(0);
	}
}

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	return PercentToHit;
}

function int GetShotBreakdown(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown kBreakdown)
{
	kBreakdown.HideShotBreakdown = true;
	return PercentToHit;
}

defaultproperties
{
	PercentToHit=100;
}