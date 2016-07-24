//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_UnitType.uc
//  AUTHOR:  sboeckmann  --  2/2/2016
//  PURPOSE: Conditional on unit type (Sectoid, AdventComander, etc.)
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitType extends X2Condition;

var array<name> IncludeTypes; //Include Types override Exclude. I.E. If sectoid is in both arrays, Sectoid is considered a pass for the test.
var array<name> ExcludeTypes;

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{ 
	local XComGameState_Unit UnitState;
	local name UnitTypeName;

	UnitState = XComGameState_Unit(kTarget);
	if (UnitState != none)
		UnitTypeName = UnitState.GetMyTemplate().CharacterGroupName;

	if (IncludeTypes.Length > 0)
	{
		if (IncludeTypes.Find(UnitTypeName) == INDEX_NONE)
			return 'AA_UnitIsWrongType';
		else
			return 'AA_Success';
	}
	else if (ExcludeTypes.Length > 0)
	{
		if (ExcludeTypes.Find(UnitTypeName) == INDEX_NONE)
			return 'AA_Success';
		else
			return 'AA_UnitIsWrongType';
	}

	return 'AA_Success';
}