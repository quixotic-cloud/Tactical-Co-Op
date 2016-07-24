class SeqAct_WaitForBattleRunning extends SeqAct_XComWaitCondition;

event bool CheckCondition()
{
	local XComPlayerController PC;

	PC = XComPlayerController(GetWorldInfo().GetALocalPlayerController());

	if( !GetXGBattle().IsInState('Running') || PC == none || PC.Pres == none || PC.Pres.m_kNarrativeUIMgr == none)
	{
		return false;
	}

	return true;
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if (!bNot)
		return "Wait For Battle Running .";
	else
		return "..No. Don't do this.";
}

function XGBattle_SP GetXGBattle()
{
	local XComTacticalGRI TacticalGRI;
	local XGBattle_SP Battle;
	
	TacticalGRI = `TACTICALGRI;
	Battle = (TacticalGRI != none)? XGBattle_SP(TacticalGRI.m_kBattle) : none;

	return Battle;
}

defaultproperties
{
	ObjName="Wait for Battle Running"
	ObjCategory="Wait Conditions"
}