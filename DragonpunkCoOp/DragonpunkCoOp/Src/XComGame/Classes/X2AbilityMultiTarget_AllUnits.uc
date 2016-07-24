/***************************************************
 X2AbilityMultiTarget_AllUnits
 
 This multi target script grabs all units relative to the PRIMARY TARGET of the ability.
 So if your ability is friendly, it will be all your friends.
 If your ability is hostile, it will be all your enemies.
 And so on.
 **************************************************/
class X2AbilityMultiTarget_AllUnits extends X2AbilityMultiTarget_Radius native(Core);

var name OnlyAllyOfType;
var bool bAcceptFriendlyUnits;
var bool bAcceptEnemyUnits;
var bool bOnlyAcceptRoboticUnits;
var bool bOnlyAcceptAlienUnits;
var bool bOnlyAcceptAdventUnits;
var bool bRandomlySelectOne;
var bool bDontAcceptNeutralUnits;
var int RandomChance;
var bool bUseAbilitySourceAsPrimaryTarget;

simulated native function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);
simulated native function GetMultiTargetsForLocation(const XComGameState_Ability Ability, const vector Location, out AvailableTarget Target);
simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);


defaultproperties
{
	bDontAcceptNeutralUnits=true
}