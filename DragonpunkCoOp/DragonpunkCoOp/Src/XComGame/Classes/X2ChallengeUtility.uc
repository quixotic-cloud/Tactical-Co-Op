//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeUtility.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeUtility extends X2ChallengeTemplate;

var array<WeightedTemplate> UtilitySlot;	// Everyone pulls from this list to fill primary utility slot
var array<WeightedTemplate> UtilitySlot2;	// If unit has a second slot, they pull from this list
var array<WeightedTemplate> GrenadierSlot;	// Grenediers pull from this list for their second grenade
var array<WeightedTemplate> HeavyWeapon;	// If unit has an EXO/WAR suit, heavy weapon is pulled from here

var delegate<ChallengeUtilityItemSelector> SelectUtilityItemFn;

delegate  ChallengeUtilityItemSelector( X2ChallengeUtility Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState );

static function WeightedTemplateSelection( X2ChallengeUtility Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit Unit;
	local name ItemTemplateName;
	local int Index;
	local XComGameState_Item NewItem;
	local X2ArmorTemplate ArmorTemplate;

	foreach XComUnits( Unit )
	{
		// Give them something to fill their utility slot
		ItemTemplateName = GetRandomTemplate( Selector.UtilitySlot );
		ApplyUtilityItem( ItemTemplateName, eInvSlot_Utility, Unit, StartState );

		// Give them stuff to fill the rest of their utility slots
		for (Index = 1; Index < Unit.GetCurrentStat( eStat_UtilityItems ); ++Index)
		{
			ItemTemplateName = GetRandomTemplate( Selector.UtilitySlot2 );
			ApplyUtilityItem( ItemTemplateName, eInvSlot_Utility, Unit, StartState );
		}

		if (Unit.GetSoldierClassTemplateName( ) == 'Grenadier')
		{
			ItemTemplateName = GetRandomTemplate( Selector.GrenadierSlot );
			ApplyUtilityItem( ItemTemplateName, eInvSlot_GrenadePocket, Unit, StartState );
		}

		// if they can carry a heavy weapon, fill that slot
		NewItem = Unit.GetItemInSlot( eInvSlot_Armor );
		ArmorTemplate = X2ArmorTemplate( NewItem.GetMyTemplate( ) );
		if (ArmorTemplate.bHeavyWeapon)
		{
			ItemTemplateName = GetRandomTemplate( Selector.HeavyWeapon );
			ApplyUtilityItem( ItemTemplateName, eInvSlot_HeavyWeapon, Unit, StartState );
		}
	}
}

static function SelectSoldierUtilityItems( X2ChallengeUtility Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	Selector.SelectUtilityItemFn( Selector, XComUnits, StartState );
}

static function ApplyUtilityItem( name ItemTemplateName, EInventorySlot Slot, XComGameState_Unit Unit, XComGameState StartState )
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;

	// Should only be using this to add to these three inventory slots
	`assert( (Slot == eInvSlot_HeavyWeapon) || (Slot == eInvSlot_Utility) || (Slot == eInvSlot_GrenadePocket) );

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager( );

	EquipmentTemplate = X2EquipmentTemplate( ItemTemplateManager.FindItemTemplate( ItemTemplateName ) );
	`assert( EquipmentTemplate != none );

	NewItem = EquipmentTemplate.CreateInstanceFromTemplate( StartState );
	Unit.AddItemToInventory( NewItem, Slot, StartState );
	StartState.AddStateObject( NewItem );
}

defaultproperties
{
	SelectUtilityItemFn = WeightedTemplateSelection;
}