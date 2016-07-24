//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_BonusWeaponDamage.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    17 Jun 2015
//  PURPOSE: Add a flat damage amount if the ability's source weapon matches
//           the source weapon of this effect.
//           Since weapons can define their own damage, this is really for when
//           the damage is temporary, or is coming from a specific soldier ability 
//           and therefore not everyone with the same weapon gets the bonus.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_BonusWeaponDamage extends X2Effect_Persistent;

var int BonusDmg;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{ 
	if (AbilityState.SourceWeapon == EffectState.ApplyEffectParameters.ItemStateObjectRef)
		return BonusDmg;

	return 0; 
}