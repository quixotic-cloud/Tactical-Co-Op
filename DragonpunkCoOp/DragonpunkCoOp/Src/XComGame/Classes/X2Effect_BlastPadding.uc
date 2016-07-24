class X2Effect_BlastPadding extends X2Effect_BonusArmor config(GameCore);

var float ExplosiveDamageReduction;
var config int ARMOR_CHANCE, ARMOR_MITIGATION;

function int GetArmorChance(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return default.ARMOR_CHANCE; }
function int GetArmorMitigation(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return default.ARMOR_MITIGATION; }

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect)
{
	local int DamageMod;

	if (WeaponDamageEffect.bExplosiveDamage)
	{
		DamageMod = -int(float(CurrentDamage) * ExplosiveDamageReduction);
	}

	return DamageMod;
}