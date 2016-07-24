//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_Inventory.uc
//  AUTHOR:  Sam Batista
//  PURPOSE: Weapons and items currently equipped on the selected soldier.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_Inventory extends UIPanel
	dependson(XComKeybindingData);

var public UITacticalHUD_Weapon m_kWeapon;
var public UITacticalHUD_Backpack m_kBackpack;

var bool                bSelectionbracketsActive; 

var XGUnit            m_kCurrentUnit;

var localized string m_strHelpReloadWeapon;
var localized string m_strHelpSwapWeapon;

// Pseudo-Ctor
simulated function UITacticalHUD_Inventory InitInventory()
{
	InitPanel();
	m_kWeapon = Spawn( class'UITacticalHUD_Weapon', self).InitWeapon();
	m_kBackpack = Spawn( class'UITacticalHUD_Backpack', self).InitBackpack();
	m_kBackpack.Hide();
	return self;
}


simulated function OnInit()
{
	super.OnInit();
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen).m_kAbilityHUD, 'm_iCurrentIndex', self, ForceUpdate);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen), 'm_isMenuRaised', self, ForceUpdate);
	Update();
}

public function ForceUpdate()
{
	Update( true );
}

public function Update( optional bool bForceUpdate = false )
{
	local XGUnit		kActiveUnit;
	local XComGameState_Unit kGameStateUnit;
	local XComGameState_Item kPrimaryWeapon;

	// If not shown or ready, leave.
	if( !bIsInited )
		return;
	
	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if( kActiveUnit == none )
	{
		Hide();
	} 
	else if( bForceUpdate || (kActiveUnit != none && kActiveUnit != m_kCurrentUnit) )
	{
		m_kCurrentUnit = kActiveUnit;
		
		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
		kPrimaryWeapon = kGameStateUnit.GetPrimaryWeapon();

		if( kPrimaryWeapon != none && kPrimaryWeapon.ShouldDisplayWeaponAndAmmo() )
		{
			m_kWeapon.SetWeaponAndAmmo(kPrimaryWeapon);
			AS_SetWeaponName(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(kPrimaryWeapon.GetMyTemplate().GetItemFriendlyName(kPrimaryWeapon.ObjectID)));
			Show();
		}
		else
		{
			AS_SetWeaponName("");
			Hide();
		}
	}
	
	Movie.Pres.m_kTooltipMgr.ForceUpdateByPartialPath( string(MCPath) );
}

simulated function HideSelectionBrackets()
{
	if( bSelectionbracketsActive )
	{
		Invoke("DeactivateSelectionBrackets");
		bSelectionbracketsActive = false; 
	}
}

simulated function UpdateSelectionBracket(XComGameState_Item activeWeapon)
{
	if( !bSelectionbracketsActive )
	{
		Invoke("ActivateSelectionBrackets");
		bSelectionbracketsActive = TRUE; 
	}
	// Panels will check whether the weapon they represent matches up with the new ActiveWeapon.
	m_kWeapon.NewActiveWeapon(activeWeapon);
}

simulated function AS_SetWeaponName( string displayString )
{
	Movie.ActionScriptVoid(MCPath$".SetWeaponName");
}
simulated function AS_SetHelp(int Index, string Icon, string DisplayText )
{
	Movie.ActionScriptVoid(MCPath$".SetHelp");
}

defaultproperties
{
	MCName = "inventoryMC";
	bAnimateOnInit = false;
	bSelectionbracketsActive = false;
}

