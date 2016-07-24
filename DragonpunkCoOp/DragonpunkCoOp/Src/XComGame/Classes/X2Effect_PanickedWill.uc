//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Effect_PanickedWill.uc    
//  AUTHOR:  Joshua Bouscher  --  10/13/2015
//  PURPOSE: Handles the Will adjustments that occur as a result of responding to a
//           a panic event. (Therefore is only part of the "panic" ability itself
//           and not other things which may cause panic, such as Insanity.)
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_PanickedWill extends X2Effect_ModifyStats;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local int WillMod;
	local StatChange WillChange;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	AbilityState = XComGameState_Ability(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if (AbilityState == none)
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if (AbilityState != none)
	{
		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(ApplyEffectParameters.AbilityResultContext.HitResult))
		{
			//  Recover some amount of Will if you actually panicked
			WillMod = class'X2StatusEffects'.default.PANIC_SUCCESS_WILL_MOD;
		}
		//  Will is impacted directly equivalent to the panic event value
		WillMod -= AbilityState.PanicEventValue;
		if (WillMod > 0)
		{
			if (UnitState.GetCurrentStat(eStat_Will) + WillMod > UnitState.GetBaseStat(eStat_Will))
			{
				WillMod = UnitState.GetBaseStat(eStat_Will) - UnitState.GetCurrentStat(eStat_Will);
			}
		}
		WillChange.StatType = eStat_Will;
		WillChange.StatAmount = WillMod;	
		NewEffectState.StatChanges.AddItem(WillChange);
		super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
	}
}

DefaultProperties
{
	EffectName="PanickedWill"
	DuplicateResponse=eDupe_Allow
	DamageTypes.Add("Mental");
	bApplyOnHit=true
	bApplyOnMiss=true
}