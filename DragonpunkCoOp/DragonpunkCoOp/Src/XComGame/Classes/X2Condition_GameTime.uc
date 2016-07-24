class X2Condition_GameTime extends X2Condition;

var array<CheckConfig> HourChecks;

function AddHourCheck(int Value, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0)
{
	local CheckConfig Hour;

	Hour.Value = Value;
	Hour.CheckType = CheckType;
	Hour.ValueMax = ValueMax;
	Hour.ValueMin = ValueMin;
	HourChecks.AddItem(Hour);
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_GameTime TimeState;
	local name ReturnCode;
	local bool bSuccess;
	local int i, Hour;

	TimeState = XComGameState_GameTime(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	Hour = class'X2StrategyGameRulesetDataStructures'.static.GetHour(TimeState.CurrentTime);

	bSuccess = false;
	for (i = 0; i < HourChecks.Length; ++i)
	{
		ReturnCode = PerformValueCheck(Hour, HourChecks[i]);
		if (ReturnCode == 'AA_Success')
			bSuccess = true;
	}
	if (bSuccess)
		return 'AA_Success';
	
	return 'AA_WrongTimeOfDay';
}