//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_UnitActionPoints.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    20-Aug-2014
//           
//  NOTE: Unlike the UnitValue and UnitStatCheck conditions, which fail on any value failing,
//        ActionPonits will succeed if any value succeeds. Frequently you'd want to group multiple action point types,
//        so that the check will pass if the unit has any one of: standard, move, reflex.
//        Abilities generally don't care which type you have, just that you have one of them.
//        If you really need to validate multiple different types, just use multiple conditions.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitActionPoints extends X2Condition;

struct ActionPointCheck
{
	var name            ActionPointType;
	var bool            bCheckReserved;
	var CheckConfig     ConfigValue;
};
var array<ActionPointCheck> m_aCheckValues;

function AddActionPointCheck(int Value, optional name Type=class'X2CharacterTemplateManager'.default.StandardActionPoint, optional bool bReserve=false, optional EValueCheck CheckType=eCheck_Exact, optional int ValueMax=0, optional int ValueMin=0)
{
	local ActionPointCheck AddValue;
	AddValue.ActionPointType = Type;
	AddValue.bCheckReserved = bReserve;
	AddValue.ConfigValue.CheckType = CheckType;
	AddValue.ConfigValue.Value = Value;
	AddValue.ConfigValue.ValueMin = ValueMin;
	AddValue.ConfigValue.ValueMax = ValueMax;
	m_aCheckValues.AddItem(AddValue);
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;
	local name RetCode;
	local int i, NumPoints;

	RetCode = 'AA_CannotAfford_ActionPoints';
	UnitState = XComGameState_Unit(kTarget);
	if (UnitState != none )
	{
		if( UnitState.GetMyTemplate().bIsCosmetic ) //Cosmetic units are not limited by AP
		{
			RetCode = 'AA_Success';
		}
		else
		{
			for (i = 0; (i < m_aCheckValues.Length) && (RetCode != 'AA_Success'); ++i)
			{
				if (m_aCheckValues[i].bCheckReserved)
					NumPoints = UnitState.NumReserveActionPoints(m_aCheckValues[i].ActionPointType);
				else
					NumPoints = UnitState.NumActionPoints(m_aCheckValues[i].ActionPointType);

				RetCode = PerformValueCheck(NumPoints, m_aCheckValues[i].ConfigValue);
			}
		}
	}
	if (RetCode == 'AA_Success')
		return RetCode;

	return 'AA_CannotAfford_ActionPoints';   //  Change from value check error
}