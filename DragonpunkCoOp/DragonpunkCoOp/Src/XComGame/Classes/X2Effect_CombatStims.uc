class X2Effect_CombatStims extends X2Effect_BonusArmor config(GameCore);

var config int ARMOR_CHANCE, ARMOR_MITIGATION;

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	return DamageType == 'stun' || DamageType == 'psi';
}

function int GetArmorChance(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return default.ARMOR_CHANCE; }
function int GetArmorMitigation(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return default.ARMOR_MITIGATION; }

DefaultProperties
{
	EffectName="CombatStims"
	DuplicateResponse=eDupe_Refresh
}