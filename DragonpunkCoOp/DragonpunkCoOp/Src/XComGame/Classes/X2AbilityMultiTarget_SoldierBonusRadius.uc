//  NOTE: this functionality is now baked into X2AbilityMultiTarget_Radius.
//  This will continue to work (for now).

class X2AbilityMultiTarget_SoldierBonusRadius extends X2AbilityMultiTarget_Radius native(Core) deprecated;

var name SoldierAbilityName;
var float BonusRadius;          //  flat bonus added to normal fTargetRadius

simulated native function float GetTargetRadius(const XComGameState_Ability Ability);