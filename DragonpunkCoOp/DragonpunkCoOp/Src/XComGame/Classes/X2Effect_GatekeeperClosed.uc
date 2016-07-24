class X2Effect_GatekeeperClosed extends X2Effect_PersistentStatChange
	config(GameCore);
//BMU - This isn't the intended implementation; the damage reduction from closing should be nothing other than bonus armor mitigation + chance.
// The close status effect DOES change the armor correctly, which means that this effect was just doubling up.
// GATEKEEPER_CLOSED_PERCENT_DAMAGE_REDUCTION is now set to be 0, eliminating the effect of this.
var config float GATEKEEPER_CLOSED_PERCENT_DAMAGE_REDUCTION;

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, 
										const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect)
{
	local int ModifiedDamage;

	ModifiedDamage = CurrentDamage * default.GATEKEEPER_CLOSED_PERCENT_DAMAGE_REDUCTION;

	return ModifiedDamage;
}