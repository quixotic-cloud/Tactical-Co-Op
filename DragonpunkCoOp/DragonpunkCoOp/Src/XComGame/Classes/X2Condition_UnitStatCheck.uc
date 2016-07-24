//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_UnitStatCheck.uc
//  AUTHOR:  Timothy Talley
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitStatCheck extends X2Condition;

struct CheckStat
{
	var ECharStatType   StatType;
	var CheckConfig     ConfigValue;
	var bool            bCheckAsPercent;
};
var array<CheckStat> m_aCheckStats;

function AddCheckStat(ECharStatType StatType, int Value, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0, optional bool bCheckAsPercent=false)
{
	local CheckStat AddStat;
	AddStat.StatType = StatType;
	AddStat.ConfigValue.CheckType = CheckType;
	AddStat.ConfigValue.Value = Value;
	AddStat.ConfigValue.ValueMin = ValueMin;
	AddStat.ConfigValue.ValueMax = ValueMax;
	AddStat.bCheckAsPercent = bCheckAsPercent;
	m_aCheckStats.AddItem(AddStat);
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;
	local name RetCode;
	local int StatValue, i;

	RetCode = 'AA_Success';
	UnitState = XComGameState_Unit(kTarget);
	if (UnitState != none)
	{
		for (i = 0; (i < m_aCheckStats.Length) && (RetCode == 'AA_Success'); ++i)
		{
			if (m_aCheckStats[i].bCheckAsPercent)
			{
				// Check this value as a percentage of the max
				StatValue = 100 * (UnitState.GetCurrentStat(m_aCheckStats[i].StatType) / UnitState.GetMaxStat(m_aCheckStats[i].StatType));
			}
			else
			{
				StatValue = UnitState.GetCurrentStat(m_aCheckStats[i].StatType);
			}

			RetCode = PerformValueCheck(StatValue, m_aCheckStats[i].ConfigValue);
		}
	}
	return RetCode;
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	return 'AA_Success';
}