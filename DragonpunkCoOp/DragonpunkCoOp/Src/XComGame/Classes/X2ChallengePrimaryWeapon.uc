//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengePrimaryWeapon.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengePrimaryWeapon extends X2ChallengeTemplate;

struct ChallengeClassPrimaryWeapons
{
	var name SoldierClassName;
	var array<WeightedTemplate> PrimaryWeapons;
};

var array<ChallengeClassPrimaryWeapons> PrimaryWeapons;

var delegate<ChallengeWeaponSelector> SelectWeaponFn;

delegate  ChallengeWeaponSelector( X2ChallengePrimaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState );

static function ChallengeClassPrimaryWeapons GetClassWeapons( X2ChallengePrimaryWeapon Selector, name SoliderClassName )
{
	local ChallengeClassPrimaryWeapons ClassWeapons;

	foreach Selector.PrimaryWeapons( ClassWeapons )
	{
		if (ClassWeapons.SoldierClassName == SoliderClassName)
			return ClassWeapons;
	}

	return ClassWeapons;
}

static function WeightedTemplateSelection( X2ChallengePrimaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit Unit;
	local ChallengeClassPrimaryWeapons ClassWeapons;
	local name WeaponName;

	foreach XComUnits(Unit)
	{
		ClassWeapons = GetClassWeapons( Selector, Unit.GetSoldierClassTemplateName() );
		WeaponName = GetRandomTemplate( ClassWeapons.PrimaryWeapons );
		ApplyWeapon( WeaponName, Unit, StartState );
	}
}

static function SelectSoldierPrimaryWeapon( X2ChallengePrimaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	Selector.SelectWeaponFn( Selector, XComUnits, StartState );
}

static function ApplyWeapon( name WeaponTemplateName, XComGameState_Unit Unit, XComGameState StartState )
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager( );

	EquipmentTemplate = X2EquipmentTemplate( ItemTemplateManager.FindItemTemplate( WeaponTemplateName ) );
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate( StartState );
	Unit.AddItemToInventory( NewItem, eInvSlot_PrimaryWeapon, StartState );
	StartState.AddStateObject( NewItem );
}

defaultproperties
{
	SelectWeaponFn = WeightedTemplateSelection;
}