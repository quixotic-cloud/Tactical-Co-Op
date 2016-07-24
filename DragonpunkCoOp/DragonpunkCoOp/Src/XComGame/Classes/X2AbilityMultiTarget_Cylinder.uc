class X2AbilityMultiTarget_Cylinder extends X2AbilityMultiTarget_Radius
	native(Core);

var float fTargetHeight;          //  Meters! (for now)
var bool bUseOnlyGroundTiles;

simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);
simulated native protected function GetTilesToCheckForLocation(const XComGameState_Ability Ability, 
															   const out vector Location, 
															   out vector TileExtent, // maximum extent of the returned tiles from Location
															   out array<TilePosPair> CheckTiles);

defaultproperties
{
	bUseOnlyGroundTiles=false
}