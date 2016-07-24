//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_AlertStatus.uc
//  AUTHOR:  Ryan McFall  --  1/11/2014
//  PURPOSE: Defines the abilities that form the concealment / alertness mechanics in 
//  X-Com 2. Presently these abilities are only available to the AI.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitAlertStatus extends X2Condition;

// APC- Updated to allow for a range of values (i.e. Red alert can be kicked off from green or yellow).
// One of these must be set or MeetsCondition will return invalid.
var int RequiredAlertStatusMaximum; // default -1, means ignored.
var int RequiredAlertStatusMinimum; // default -1, means ignored.

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;
	local int iAlertVal; 

	UnitState = XComGameState_Unit(kTarget);
	if( UnitState == none )
		return 'AA_NotAUnit';

	iAlertVal = UnitState.GetCurrentStat(eStat_AlertLevel);

	if (RequiredAlertStatusMaximum != -1 && RequiredAlertStatusMinimum != -1)
	{
		if (iAlertVal <= RequiredAlertStatusMaximum && iAlertVal >= RequiredAlertStatusMinimum)
		{
			return 'AA_Success';
		}
		return 'AA_AlertStatusInvalid';
	}

	if (RequiredAlertStatusMinimum != -1)
	{
		if (iAlertVal >= RequiredAlertStatusMinimum) 
		{
			return 'AA_Success';
		}
		return 'AA_AlertStatusInvalid';
	}

	if (RequiredAlertStatusMaximum != -1)
	{
		if (iAlertVal <= RequiredAlertStatusMaximum) 
		{
			return 'AA_Success';
		}
		return 'AA_AlertStatusInvalid';
	}

	return 'AA_AlertStatusInvalid';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kSource);
	if( UnitState == none )
		return 'AA_NotAUnit';

	if (UnitState.GetCurrentStat(eStat_AlertLevel) <= RequiredAlertStatusMaximum) 
	{
		return 'AA_Success';
	}

	return 'AA_AlertStatusInvalid';
}

defaultproperties
{
	RequiredAlertStatusMaximum=-1;
	RequiredAlertStatusMinimum=-1;

}