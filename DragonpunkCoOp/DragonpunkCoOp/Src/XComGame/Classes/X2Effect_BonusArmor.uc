class X2Effect_BonusArmor extends X2Effect_Persistent;

var int ArmorMitigationAmount;

function int GetArmorChance(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return 0; }       //  DEPRECATED
function int GetArmorMitigation(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return ArmorMitigationAmount; }
function string GetArmorName(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return FriendlyName; }