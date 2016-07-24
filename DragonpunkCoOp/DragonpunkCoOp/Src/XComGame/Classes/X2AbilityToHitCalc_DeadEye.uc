//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc_DeadEye.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityToHitCalc_DeadEye extends X2AbilityToHitCalc;

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int MultiIndex;
	local ArmorMitigationResults NoArmor;

	//  DeadEye always hits
	ResultContext.HitResult = eHit_Success;

	for (MultiIndex = 0; MultiIndex < kTarget.AdditionalTargets.Length; ++MultiIndex)
	{
		ResultContext.MultiTargetHitResults.AddItem(ResultContext.HitResult);		
		ResultContext.MultiTargetArmorMitigation.AddItem(NoArmor);
		ResultContext.MultiTargetStatContestResult.AddItem(0);
	}
}

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	return 100;
}

function int GetShotBreakdown(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown kBreakdown)
{
	kBreakdown.HideShotBreakdown = true;
	return 100;
}