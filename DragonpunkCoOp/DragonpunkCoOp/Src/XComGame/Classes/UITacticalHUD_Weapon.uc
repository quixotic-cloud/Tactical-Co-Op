//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISoldierHUD_WeaponPanel.uc
//  AUTHOR:  Sam Batista
//  PURPOSE: A single weapon and ammo combo for the selected soldier.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_Weapon extends UIPanel;

var XComGameState_Item m_kWeapon;

// Pseudo-Ctor
simulated function UITacticalHUD_Weapon InitWeapon()
{
	InitPanel();
	return self;
}

simulated function OnInit()
{
	super.OnInit();
}

simulated function SetWeaponAndAmmo( XComGameState_Item kWeapon )
{
	//If it's an overheating-type of weapon
	if ( (kWeapon != none) && kWeapon.ShouldDisplayWeaponAndAmmo() )
	{
		// Display the Weapon and Ammo if the weapon exists AND the template allows it to be displayed
		Show();

		m_kWeapon = kWeapon;
		AS_X2SetWeapon(kWeapon.GetWeaponPanelImages());
		if(m_kWeapon.HasInfiniteAmmo())
		{
			AS_X2SetAmmo(1, 1, 0, false);
		}
		else
		{
			AS_X2SetAmmo(kWeapon.Ammo, kWeapon.GetClipSize(), GetPotentialAmmoCost(), true);
		}
	}
	else
	{
		Hide();

		AS_X2SetWeapon();
		AS_X2SetAmmo(0, 0, 0, false);
	}	
}

simulated function float GetPotentialAmmoCost()
{
	local X2AbilityCost AbilityCost;
	local AvailableAction SelectedAction;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate; 


	SelectedAction = UITacticalHUD(screen).m_kAbilityHUD.GetSelectedAction();
	
	// -1 or 0 means an invalid ObjectID
	if(SelectedAction.AbilityObjectRef.ObjectID > 0)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedAction.AbilityObjectRef.ObjectID));
	
		if( m_kWeapon == AbilityState.GetSourceWeapon() )
		{
			AbilityTemplate = AbilityState.GetMyTemplate();
			foreach AbilityTemplate.AbilityCosts(AbilityCost)
			{
				if( AbilityCost.IsA('X2AbilityCost_Ammo') )
				{
					return X2AbilityCost_Ammo(AbilityCost).iAmmo;
				}
			}
		}
	}
	return -1;
}

simulated public function NewActiveWeapon(optional XComGameState_Item activeWeapon)
{
	if(activeWeapon == none || activeWeapon == m_kWeapon)
		Invoke("WeaponPanelSelected");
	else
		Invoke("WeaponPanelNotSelected");
}

simulated function AS_X2SetWeapon( optional array<string> Images )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int i; 

	myValue.Type = AS_String;

	for( i = 0; i < Images.length; i++ )
	{
		myValue.s = Images[i];
		myArray.AddItem( myValue );
	}

	Invoke("X2SetWeapon", myArray);
}

simulated function AS_X2SetAmmo( int ammoCurrent, int ammoMax, int ammoHighlight, bool hasBullets )
{
	Movie.ActionScriptVoid(MCPath$".X2SetAmmo");
}

defaultproperties
{
	MCName = "weaponMC";
	bAnimateOnInit = false;
}