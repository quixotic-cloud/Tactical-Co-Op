class X2AbilityMultiTarget_Radius extends X2AbilityMultiTargetStyle
	dependson(XComWorldData)
	native(Core);

struct native AbilityGrantedBonusRadius
{
	var name RequiredAbility;
	var float fBonusRadius;
};

var bool    bUseWeaponRadius;
var bool	bIgnoreBlockingCover;
var float   fTargetRadius;          //  Meters! (for now) If bUseWeaponRadius is true, this value is added on.
var float	fTargetCoveragePercentage;
var bool    bAddPrimaryTargetAsMultiTarget;     //  GetMultiTargetOptions & GetMultiTargetsForLocation will remove the primary target and add it to the multi target array.
var bool    bAllowDeadMultiTargetUnits;
var bool    bExcludeSelfAsTargetIfWithinRadius;
var array<AbilityGrantedBonusRadius> AbilityBonusRadii;

function AddAbilityBonusRadius(name AbilityName, float BonusRadius)
{
	local AbilityGrantedBonusRadius Bonus;

	Bonus.RequiredAbility = AbilityName;
	Bonus.fBonusRadius = BonusRadius;
	AbilityBonusRadii.AddItem(Bonus);
}

// cribbed from the old targeting logic. Should be replaced with something more gameplay centric eventually
native function GetTargetedStateObjects(const XComGameState_Ability Ability, Vector TargetLocation, out array<XComGameState_BaseObject> StateObjects);

/**
 * GetTargetRadius
 * @return Unreal units for radius of targets
 */
simulated native function float GetTargetRadius(const XComGameState_Ability Ability);
simulated native function float GetActiveTargetRadiusScalar(const XComGameState_Ability Ability);
simulated native function float GetTargetCoverage(const XComGameState_Ability Ability);

simulated native function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);
simulated native function GetMultiTargetsForLocation(const XComGameState_Ability Ability, const vector Location, out AvailableTarget Target);
simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);

simulated native protected function bool ActorBlocksRadialDamage(Actor CheckActor, const out vector Location, int EnvironmentDamage);
simulated native protected function GetTilesToCheckForLocation(const XComGameState_Ability Ability, 
															   const out vector Location, 
															   out vector TileExtent, // maximum extent of the returned tiles from Location
															   out array<TilePosPair> CheckTiles);

defaultproperties
{
	bExcludeSelfAsTargetIfWithinRadius=false
}