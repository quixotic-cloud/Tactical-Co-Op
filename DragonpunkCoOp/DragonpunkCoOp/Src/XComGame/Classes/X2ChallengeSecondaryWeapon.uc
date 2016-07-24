//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSecondaryWeapon.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSecondaryWeapon extends X2ChallengeTemplate;

struct ChallengeClassSecondaryWeapons
{
	var name SoldierClassName;
	var array<WeightedTemplate> SecondaryWeapons;
};

var array<ChallengeClassSecondaryWeapons> SecondaryWeapons;

var delegate<ChallengeWeaponSelector> SelectWeaponFn;

delegate  ChallengeWeaponSelector( X2ChallengeSecondaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState );

static function ChallengeClassSecondaryWeapons GetClassWeapons( X2ChallengeSecondaryWeapon Selector, name SoliderClassName )
{
	local ChallengeClassSecondaryWeapons ClassWeapons;

	foreach Selector.SecondaryWeapons( ClassWeapons )
	{
		if (ClassWeapons.SoldierClassName == SoliderClassName)
			return ClassWeapons;
	}

	return ClassWeapons;
}

static function WeightedTemplateSelection( X2ChallengeSecondaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit Unit;
	local ChallengeClassSecondaryWeapons ClassWeapons;
	local name WeaponName;

	foreach XComUnits(Unit)
	{
		ClassWeapons = GetClassWeapons( Selector, Unit.GetSoldierClassTemplateName() );
		WeaponName = GetRandomTemplate( ClassWeapons.SecondaryWeapons );
		ApplyWeapon( WeaponName, Unit, StartState );
	}
}

static function SelectSoldierSecondaryWeapon( X2ChallengeSecondaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
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
	Unit.AddItemToInventory( NewItem, eInvSlot_SecondaryWeapon, StartState );
	StartState.AddStateObject( NewItem );
}

defaultproperties
{
	SelectWeaponFn = WeightedTemplateSelection;
}