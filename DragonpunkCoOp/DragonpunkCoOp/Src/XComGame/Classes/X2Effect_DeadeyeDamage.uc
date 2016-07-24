class X2Effect_DeadeyeDamage extends X2Effect_Persistent config(GameData_SoldierSkills);

var config float DamageMultiplier;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local float ExtraDamage;

	if (AbilityState.GetMyTemplateName() == 'Deadeye')
	{
		ExtraDamage = CurrentDamage * DamageMultiplier;
	}
	return int(ExtraDamage);
}