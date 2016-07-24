class X2AbilityPassiveAOE_WeaponRadius extends X2AbilityPassiveAOEStyle native(Core);

var bool bUseSourceWeaponLocation;
var float fTargetRadius;

native function DrawAOETiles(const XComGameState_Ability Ability, const vector Location);
native function float GetTargetRadius(const XComGameState_Ability Ability);