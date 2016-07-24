//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeArmor.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeArmor extends X2ChallengeTemplate;

var array<WeightedTemplate> WeightedArmor;
var delegate<ChallengeArmorSelector> SelectArmorFn;

delegate  ChallengeArmorSelector( X2ChallengeArmor Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState );

static function WeightedTemplateSelection( X2ChallengeArmor Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit Unit;
	local name ArmorTemplateName;

	foreach XComUnits( Unit )
	{
		ArmorTemplateName = GetRandomTemplate( Selector.WeightedArmor );

		ApplyArmor( ArmorTemplateName, Unit, StartState );
	}
}

static function SelectSoldierArmor( X2ChallengeArmor Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	Selector.SelectArmorFn( Selector, XComUnits, StartState );
}

static function ApplyArmor( name ArmorTemplateName, XComGameState_Unit Unit, XComGameState StartState )
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ArmorTemplate ArmorTemplate;
	local XComGameState_Item NewItem;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager( );

	ArmorTemplate = X2ArmorTemplate( ItemTemplateManager.FindItemTemplate( ArmorTemplateName ) );
	`assert( ArmorTemplate != none );

	NewItem = ArmorTemplate.CreateInstanceFromTemplate( StartState );
	Unit.AddItemToInventory( NewItem, eInvSlot_Armor, StartState );
	StartState.AddStateObject( NewItem );
}

defaultproperties
{
	SelectArmorFn = WeightedTemplateSelection;
}