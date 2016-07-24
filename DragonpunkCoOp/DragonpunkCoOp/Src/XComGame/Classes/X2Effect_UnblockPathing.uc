// Effect set up primarily for civilians to avoid being blocked from pathing for rescue, and also to prevent
// civilians from blocking XCom units from rescuing them (atop ladders, etc)
class X2Effect_UnblockPathing extends X2Effect_Persistent;

function EGameplayBlocking ModifyGameplayPathBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit)
{
	return eGameplayBlocking_DoesNotBlock;
}
