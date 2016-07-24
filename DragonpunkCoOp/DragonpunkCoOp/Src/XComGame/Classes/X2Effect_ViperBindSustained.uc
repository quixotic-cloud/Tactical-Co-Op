//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ViperBindSustained extends X2Effect_Sustained;

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, 
										const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect)
{
	// This effect scales the damage based upon the number of full turns the unit has been bound by the viper
	if( (AbilityState.GetMyTemplateName() == 'BindSustained') && (EffectState.FullTurnsTicked > 1) )
	{
		return (CurrentDamage * (2 ** (EffectState.FullTurnsTicked - 1))) - CurrentDamage;
	}
}