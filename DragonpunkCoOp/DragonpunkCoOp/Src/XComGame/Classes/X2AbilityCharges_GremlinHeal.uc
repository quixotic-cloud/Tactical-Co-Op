//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCharges_GremlinHeal.uc
//  AUTHOR:  Joshua Bouscher  --  6/22/2015
//  PURPOSE: Setup charges for Gremlin Heal ability
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2AbilityCharges_GremlinHeal extends X2AbilityCharges;

var bool bStabilize;

function int GetInitialCharges(XComGameState_Ability Ability, XComGameState_Unit Unit)
{
	local array<XComGameState_Item> UtilityItems;
	local XComGameState_Item ItemIter;
	local int TotalCharges;

	TotalCharges = InitialCharges;
	UtilityItems = Unit.GetAllItemsInSlot(eInvSlot_Utility);
	foreach UtilityItems(ItemIter)
	{
		if (ItemIter.bMergedOut)
			continue;
		if (ItemIter.GetWeaponCategory() == class'X2Item_DefaultUtilityItems'.default.MedikitCat)
		{
			TotalCharges += ItemIter.Ammo;
		}
	}
	if (bStabilize)
	{
		TotalCharges /= class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_STABILIZE_AMMO;
	}

	return TotalCharges;
}

DefaultProperties
{
	InitialCharges = 1
}