class X2Condition_Lootable extends X2Condition;

var bool bRestrictRange;
var int LootableRange;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local Lootable LootObject;

	LootObject = Lootable(kTarget);
	if (LootObject != none && LootObject.HasAvailableLoot())
		return 'AA_Success';

	return 'AA_TargetHasNoLoot';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{	
	local XComWorldData WorldData;
	local XComGameState_Unit SourceUnitState;
	local Lootable TargetLootableState;
	local vector SourcePos, TargetPos;
	local float Distance;
	local TTile TargetTileLocation;

	SourceUnitState = XComGameState_Unit(kSource);
	if( SourceUnitState == none )
		return 'AA_NotAUnit';

	if (bRestrictRange)
	{
		TargetLootableState = Lootable(kTarget);
		if( TargetLootableState != none )
		{
			WorldData = `XWORLD;
			SourcePos = WorldData.GetPositionFromTileCoordinates(SourceUnitState.TileLocation);
			TargetTileLocation = TargetLootableState.GetLootLocation();
			TargetPos = WorldData.GetPositionFromTileCoordinates(TargetTileLocation);
			Distance = VSize(TargetPos - SourcePos);
			if (Distance >= LootableRange)
			{
				return 'AA_NotInRange';
			}
		}
	}

	return 'AA_Success';
}
