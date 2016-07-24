class X2Condition_UnitValue extends X2Condition;

struct CheckValue
{
	var name            UnitValue;
	var CheckConfig     ConfigValue;
	var name            OptionalOverrideFalureCode;
};
var array<CheckValue> m_aCheckValues;

function AddCheckValue(name UnitValue, int Value, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0, optional name OptionalOverrideFalureCode='')
{
	local CheckValue AddValue;
	AddValue.UnitValue = UnitValue;
	AddValue.ConfigValue.CheckType = CheckType;
	AddValue.ConfigValue.Value = Value;
	AddValue.ConfigValue.ValueMin = ValueMin;
	AddValue.ConfigValue.ValueMax = ValueMax;
	AddValue.OptionalOverrideFalureCode = OptionalOverrideFalureCode;
	m_aCheckValues.AddItem(AddValue);
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;
	local name RetCode;
	local int Check, i;
	local UnitValue Value;

	RetCode = 'AA_Success';
	UnitState = XComGameState_Unit(kTarget);
	if (UnitState != none)
	{
		for (i = 0; (i < m_aCheckValues.Length) && (RetCode == 'AA_Success'); ++i)
		{
			if (UnitState.GetUnitValue(m_aCheckValues[i].UnitValue, Value))
				Check = Value.fValue;
			else
				Check = 0;
			RetCode = PerformValueCheck(Check, m_aCheckValues[i].ConfigValue);

			if( RetCode != 'AA_Success' && m_aCheckValues[i].OptionalOverrideFalureCode != '' )
			{
				RetCode = m_aCheckValues[i].OptionalOverrideFalureCode;
			}
		}
	}
	return RetCode;
}