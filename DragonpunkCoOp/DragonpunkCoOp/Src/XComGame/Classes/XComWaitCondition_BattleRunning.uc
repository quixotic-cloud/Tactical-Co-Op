/**
 * Wait for narratives to finish loading.
 */
class XComWaitCondition_BattleRunning extends SeqAct_XComWaitCondition;

/** @return true if the condition has been met */
event bool CheckCondition()
{
	if (`BATTLE != none)
	{
		return `BATTLE.AtBottomOfRunningStateBeginBlock();
	}

	return false;
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if (!bNot)
		return "Battle ready";
	else
		return "Battle not ready";
}

DefaultProperties
{
	ObjCategory="Tutorial"
	ObjName="Wait for Battle ready"
	
	VariableLinks.Empty
}
