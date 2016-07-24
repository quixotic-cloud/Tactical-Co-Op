//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_ReserveOverwatchPoints.uc
//  AUTHOR:  Joshua Bouscher  --  2/11/2015
//  PURPOSE: Specifically for Overwatch; allows Pistols to use their own action points,
//           making it easier to distinguish from the Sniper Rifle.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_ReserveOverwatchPoints extends X2Effect_ReserveActionPoints;

simulated function name GetReserveType(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameState_Item ItemState;
	local X2WeaponTemplate WeaponTemplate;

	if (ApplyEffectParameters.ItemStateObjectRef.ObjectID > 0)
	{
		ItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));
		if (ItemState == none)
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.ItemStateObjectRef.ObjectID));

		if (ItemState != none)
		{
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
			if (WeaponTemplate != None && WeaponTemplate.OverwatchActionPoint != '')
				return WeaponTemplate.OverwatchActionPoint;
		}
	}
	return default.ReserveType;
}

DefaultProperties
{
	ReserveType = "overwatch"
	NumPoints = 1
}