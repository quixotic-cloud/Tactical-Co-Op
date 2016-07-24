//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCost_ReserveActionPoints.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCost_ReserveActionPoints extends X2AbilityCost;

var int     iNumPoints;
var array<name> AllowedTypes;

simulated function name CanAfford(XComGameState_Ability kAbility, XComGameState_Unit ActivatingUnit)
{
	local XComGameState_Unit kUnit;
	local name Availability;
	local int i, PointSum;
	
	kUnit = ActivatingUnit;
	`assert(kUnit != none);

	Availability = 'AA_CannotAfford_ReserveActionPoints';
	PointSum = 0;
	for (i = 0; i < AllowedTypes.Length; ++i)
	{
		PointSum += kUnit.NumReserveActionPoints(AllowedTypes[i]);
	}

	if( PointSum >= iNumPoints )
	{
		Availability = 'AA_Success';
	}

	return Availability;
}

simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Unit ModifiedUnitState;
	local int i, j, iPointsConsumed;

	if (bFreeCost)
		return;

	ModifiedUnitState = XComGameState_Unit(AffectState);

	//  Assume that AllowedTypes is built with the most specific point types at the end, which we should
	//  consume before more general types. e.g. Consume "reflex" if that is allowed before "standard" if that is also allowed.
	//  If this isn't good enough we may want to provide a specific way of ordering the priority for action point consumption.
	for (i = AllowedTypes.Length - 1; i >= 0 && iPointsConsumed < iNumPoints; --i)
	{
		for (j = ModifiedUnitState.ReserveActionPoints.Length - 1; j >= 0; --j)
		{
			if (ModifiedUnitState.ReserveActionPoints[j] == AllowedTypes[i])
			{
				ModifiedUnitState.ReserveActionPoints.Remove(j, 1);
				iPointsConsumed++;
				break;
			}
		}
	}
}