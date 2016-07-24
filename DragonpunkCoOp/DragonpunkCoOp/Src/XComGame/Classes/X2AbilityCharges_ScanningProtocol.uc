//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCharges_ScanningProtocol.uc
//  AUTHOR:  Joshua Bouscher  --  6/24/2015
//  PURPOSE: Setup charges for Scanning Protocol ability
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCharges_ScanningProtocol extends X2AbilityCharges;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	local XComGameState_Item ItemState;
	local X2GremlinTemplate GremlinTemplate;
	local int Charges;

	Charges = InitialCharges;
	ItemState = Ability.GetSourceWeapon();
	if (ItemState != None)
	{
		GremlinTemplate = X2GremlinTemplate(ItemState.GetMyTemplate());
		if (GremlinTemplate != None)
			Charges += GremlinTemplate.ScanningChargesBonus;
	}
	return Charges;
}

DefaultProperties
{
	InitialCharges = 1
}