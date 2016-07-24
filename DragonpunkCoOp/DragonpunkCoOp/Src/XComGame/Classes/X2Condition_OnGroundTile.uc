class X2Condition_OnGroundTile extends X2Condition native(Core);

var name NotAFloorTileTag;

native function name MeetsCondition(XComGameState_BaseObject kTarget);

defaultproperties
{
	NotAFloorTileTag="";
}