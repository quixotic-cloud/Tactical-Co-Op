//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeArmorSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeArmorSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateRandomPlatedArmor( ) );
	Templates.AddItem( CreateRandomPowerArmor( ) );
	Templates.AddItem( CreateClassPowerArmor( ) );

	return Templates;
}

static function X2ChallengeArmor CreateRandomPlatedArmor( )
{
	local X2ChallengeArmor	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeArmor', Template, 'ChallengeRandomPlatedArmor');

	Template.WeightedArmor.AddItem( CreateEntry( 'LightPlatedArmor', 1 ) );
	Template.WeightedArmor.AddItem( CreateEntry( 'MediumPlatedArmor', 1 ) );
	Template.WeightedArmor.AddItem( CreateEntry( 'HeavyPlatedArmor', 1 ) );

	return Template;
}

static function X2ChallengeArmor CreateRandomPowerArmor( )
{
	local X2ChallengeArmor	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeArmor', Template, 'ChallengeRandomPowerArmor');

	Template.WeightedArmor.AddItem( CreateEntry( 'LightPoweredArmor', 1 ) );
	Template.WeightedArmor.AddItem( CreateEntry( 'MediumPoweredArmor', 1 ) );
	Template.WeightedArmor.AddItem( CreateEntry( 'HeavyPoweredArmor', 1 ) );

	return Template;
}

static function X2ChallengeArmor CreateClassPowerArmor( )
{
	local X2ChallengeArmor	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeArmor', Template, 'ChallengeClassPowerArmor');

	Template.SelectArmorFn = ClassPowerArmorSelector;

	return Template;
}

static function ClassPowerArmorSelector( X2ChallengeArmor Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit Unit;
	local name ArmorTemplateName;

	foreach XComUnits( Unit )
	{
		switch (Unit.GetSoldierClassTemplateName())
		{
			case 'Grenadier': ArmorTemplateName = 'HeavyPoweredArmor';
				break;

			case 'Ranger':
			case 'Sharpshooter': ArmorTemplateName = 'LightPoweredArmor';

			default:
				ArmorTemplateName = 'MediumPoweredArmor';
		}

		class'X2ChallengeArmor'.static.ApplyArmor( ArmorTemplateName, Unit, StartState );
	}
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}