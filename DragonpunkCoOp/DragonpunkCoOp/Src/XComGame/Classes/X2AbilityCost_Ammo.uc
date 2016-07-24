//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityCost_Ammo.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityCost_Ammo extends X2AbilityCost;

var int     iAmmo;
var bool    UseLoadedAmmo;            //  for grenade abilities on the grenade launcher
var bool    bReturnChargesError;      //  use the error code for lack of charges rather than ammo

simulated function int CalcAmmoCost(XComGameState_Ability Ability, XComGameState_Item ItemState, XComGameState_BaseObject TargetState)
{
	return iAmmo;
}

simulated function name CanAfford(XComGameState_Ability kAbility, XComGameState_Unit ActivatingUnit)
{
	local XComGameState_Item Weapon, SourceAmmo;

	if (UseLoadedAmmo)
	{
		SourceAmmo = kAbility.GetSourceAmmo();
		if (SourceAmmo != None)
		{
			if (SourceAmmo.HasInfiniteAmmo() || SourceAmmo.Ammo >= iAmmo)
				return 'AA_Success';
		}
	}
	else
	{
		Weapon = kAbility.GetSourceWeapon();
		if (Weapon != none)
		{
			// If the weapon has infinite ammo, the weapon must still have an ammo value
			// of at least one. This could happen if the weapon becomes disabled.
			if ((Weapon.HasInfiniteAmmo() && (Weapon.Ammo > 0)) || Weapon.Ammo >= iAmmo)
				return 'AA_Success';
		}	
	}

	if (bReturnChargesError)
		return 'AA_CannotAfford_Charges';

	return 'AA_CannotAfford_AmmoCost';
}

simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local XComGameState_Item LoadedAmmoState;
	local XComGameStateHistory History;
	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit Unit;
	local int Cost;

	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	
	if (bFreeCost || AffectWeapon.HasInfiniteAmmo() || (`CHEATMGR != none && `CHEATMGR.bUnlimitedAmmo && Unit.GetTeam() == eTeam_XCom))	
		return;

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	Cost = CalcAmmoCost(kAbility, AffectWeapon, TargetState);

	kAbility.iAmmoConsumed = Cost;

	//  loaded ammo (aka grenades in a grenade launcher) track their own ammo, and we ignore the launcher's
	if (UseLoadedAmmo)
	{
		LoadedAmmoState = XComGameState_Item(History.GetGameStateForObjectID(kAbility.SourceAmmo.ObjectID));
		if (LoadedAmmoState != None)
		{
			LoadedAmmoState = XComGameState_Item(NewGameState.CreateStateObject(LoadedAmmoState.Class, LoadedAmmoState.ObjectID));
			LoadedAmmoState.Ammo -= Cost;
			NewGameState.AddStateObject(LoadedAmmoState);
		}
	}
	else
	{
		AffectWeapon.Ammo -= Cost;
	}
}