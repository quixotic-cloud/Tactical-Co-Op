class X2Condition_UnblockedNeighborTile extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnitState;
	local name RetCode;
	local TTile NeighborTile;

	RetCode = 'AA_TileIsBlocked';

	TargetUnitState = XComGameState_Unit(kTarget);
	`assert(TargetUnitState != none);

	if (TargetUnitState.FindAvailableNeighborTile(NeighborTile))
	{
		RetCode = 'AA_Success';
	}
	
	return RetCode;
}