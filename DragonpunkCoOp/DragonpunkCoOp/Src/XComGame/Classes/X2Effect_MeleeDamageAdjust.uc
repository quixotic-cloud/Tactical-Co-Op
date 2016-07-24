class X2Effect_MeleeDamageAdjust extends X2Effect_Persistent;

var int DamageMod;

var name MeleeDamageTypeName;

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, 
										const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect)
{
	local X2AbilityToHitCalc_StandardAim ToHitCalc;

	// The damage effect's DamageTypes must be empty or have melee in order to adjust the damage
	if( (WeaponDamageEffect.EffectDamageValue.DamageType == MeleeDamageTypeName) || (WeaponDamageEffect.DamageTypes.Find(MeleeDamageTypeName) != INDEX_NONE) ||
		((WeaponDamageEffect.EffectDamageValue.DamageType == '') && (WeaponDamageEffect.DamageTypes.Length == 0)) )
	{
		ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityState.GetMyTemplate().AbilityToHitCalc);
		if (ToHitCalc != none && ToHitCalc.bMeleeAttack)
		{
			return DamageMod;
		}
	}
	
	return 0;
}

defaultproperties
{
	MeleeDamageTypeName="melee"
}