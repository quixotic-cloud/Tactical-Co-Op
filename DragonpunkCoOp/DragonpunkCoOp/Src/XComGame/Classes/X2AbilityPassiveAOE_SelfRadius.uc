class X2AbilityPassiveAOE_SelfRadius extends X2AbilityPassiveAOEStyle native(Core);

var bool OnlyIncludeTargetsInsideWeaponRange;
var bool UseWeaponRadius;

native function DrawAOETiles(const XComGameState_Ability Ability, const vector Location);