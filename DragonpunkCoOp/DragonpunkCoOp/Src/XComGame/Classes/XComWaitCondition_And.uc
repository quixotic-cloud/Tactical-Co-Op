/**
 * Used when a wait Condition requires a compound condition.
 */
class XComWaitCondition_And extends SeqAct_XComWaitCondition;

var() editinline SeqAct_XComWaitCondition Condition1;
var() editinline SeqAct_XComWaitCondition Condition2;

/**
 * @return True if both start conditions are true. None treated as no condition.
 */
event bool CheckCondition()
{
	return
		(Condition1 == none || Condition1.CheckCondition()) &&
		(Condition2 == none || Condition2.CheckCondition());
}

event string GetConditionDesc()
{
	local string Condition;

	if (Condition1 != none)
	{
		if (Condition2 != none)
			Condition = "(" $ Condition1.GetConditionDesc() $ " AND " $ Condition2.GetConditionDesc() $ ")";
		else
			Condition =  Condition1.GetConditionDesc();
	}
	else if (Condition2 != none)
	{
		Condition =  Condition2.GetConditionDesc();
	}
	else
	{
		Condition = "<Empty Condition>";
	}

	if (bNot)
		return "NOT " $ Condition;
	else
		return Condition;
}

DefaultProperties
{
	ObjName="Wait for <Condition1> AND <Condition2>"
}
