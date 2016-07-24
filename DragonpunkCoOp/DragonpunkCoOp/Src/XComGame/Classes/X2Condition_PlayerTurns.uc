class X2Condition_PlayerTurns extends X2Condition;

var CheckConfig NumTurnsCheck;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;
	local XComGameState_Player PlayerState;
	
	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	PlayerState = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(TargetUnit.ControllingPlayer.ObjectID));
	if (PlayerState == none)
		return 'AA_NotAUnit';

	return PerformValueCheck(PlayerState.PlayerTurnCount, NumTurnsCheck);
}