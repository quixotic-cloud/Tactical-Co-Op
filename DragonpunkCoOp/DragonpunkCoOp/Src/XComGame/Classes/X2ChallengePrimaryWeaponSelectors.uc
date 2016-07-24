//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengePrimaryWeaponSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengePrimaryWeaponSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateMagneticWeapons( ) );
	Templates.AddItem( CreateBeamWeapons( ) );
	Templates.AddItem( CreateRandomMix( ) );

	return Templates;
}

static function X2ChallengePrimaryWeapon CreateMagneticWeapons( )
{
	local X2ChallengePrimaryWeapon	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengePrimaryWeapon', Template, 'ChallengePrimaryMagneticWeapons');

	Template.PrimaryWeapons.Length = 5;

	Template.PrimaryWeapons[ 0 ].SoldierClassName = 'Sharpshooter';
	Template.PrimaryWeapons[ 0 ].PrimaryWeapons.AddItem( CreateEntry( 'SniperRifle_MG', 1 ) );

	Template.PrimaryWeapons[ 1 ].SoldierClassName = 'Grenadier';
	Template.PrimaryWeapons[ 1 ].PrimaryWeapons.AddItem( CreateEntry( 'Cannon_MG', 1 ) );

	Template.PrimaryWeapons[ 2 ].SoldierClassName = 'Specialist';
	Template.PrimaryWeapons[ 2 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_MG', 1 ) );

	Template.PrimaryWeapons[ 3 ].SoldierClassName = 'Ranger';
	Template.PrimaryWeapons[ 3 ].PrimaryWeapons.AddItem( CreateEntry( 'Shotgun_MG', 1 ) );

	Template.PrimaryWeapons[ 4 ].SoldierClassName = 'PsiOperative';
	Template.PrimaryWeapons[ 4 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_MG', 1 ) );
	
	return Template;
}

static function X2ChallengePrimaryWeapon CreateBeamWeapons( )
{
	local X2ChallengePrimaryWeapon	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengePrimaryWeapon', Template, 'ChallengePrimaryBeamWeapons');

	Template.SelectWeaponFn = BeamWeaponSelector;

	return Template;
}

// Functionally the outcom is the same as the Magnetics (everyone with the same level weapon tech), but with a different implementation
static function BeamWeaponSelector( X2ChallengePrimaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit Unit;
	local name WeaponName;

	foreach XComUnits( Unit )
	{
		switch (Unit.GetSoldierClassTemplateName())
		{
			case 'Sharpshooter': WeaponName = 'SniperRifle_BM';
				break;

			case 'Grenadier': WeaponName = 'Cannon_BM';
				break;

			case 'Ranger': WeaponName = 'Shotgun_BM';
				break;

			default:
				WeaponName = 'AssaultRifle_BM';
		}

		class'X2ChallengePrimaryWeapon'.static.ApplyWeapon( WeaponName, Unit, StartState );
	}
}

static function X2ChallengePrimaryWeapon CreateRandomMix( )
{
	local X2ChallengePrimaryWeapon	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengePrimaryWeapon', Template, 'ChallengePrimaryRandom');

	Template.PrimaryWeapons.Length = 5;

	Template.PrimaryWeapons[ 0 ].SoldierClassName = 'Sharpshooter';
	Template.PrimaryWeapons[ 0 ].PrimaryWeapons.AddItem( CreateEntry( 'SniperRifle_CV', 1 ) );
	Template.PrimaryWeapons[ 0 ].PrimaryWeapons.AddItem( CreateEntry( 'SniperRifle_MG', 1 ) );
	Template.PrimaryWeapons[ 0 ].PrimaryWeapons.AddItem( CreateEntry( 'SniperRifle_BM', 1 ) );

	Template.PrimaryWeapons[ 1 ].SoldierClassName = 'Grenadier';
	Template.PrimaryWeapons[ 1 ].PrimaryWeapons.AddItem( CreateEntry( 'Cannon_CV', 1 ) );
	Template.PrimaryWeapons[ 1 ].PrimaryWeapons.AddItem( CreateEntry( 'Cannon_MG', 1 ) );
	Template.PrimaryWeapons[ 1 ].PrimaryWeapons.AddItem( CreateEntry( 'Cannon_BM', 1 ) );

	Template.PrimaryWeapons[ 2 ].SoldierClassName = 'Specialist';
	Template.PrimaryWeapons[ 2 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_CV', 1 ) );
	Template.PrimaryWeapons[ 2 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_MG', 1 ) );
	Template.PrimaryWeapons[ 2 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_BM', 1 ) );

	Template.PrimaryWeapons[ 3 ].SoldierClassName = 'Ranger';
	Template.PrimaryWeapons[ 3 ].PrimaryWeapons.AddItem( CreateEntry( 'Shotgun_CV', 1 ) );
	Template.PrimaryWeapons[ 3 ].PrimaryWeapons.AddItem( CreateEntry( 'Shotgun_MG', 1 ) );
	Template.PrimaryWeapons[ 3 ].PrimaryWeapons.AddItem( CreateEntry( 'Shotgun_BM', 1 ) );
	Template.PrimaryWeapons[ 3 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_CV', 1 ) );
	Template.PrimaryWeapons[ 3 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_MG', 1 ) );
	Template.PrimaryWeapons[ 3 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_BM', 1 ) );

	Template.PrimaryWeapons[ 4 ].SoldierClassName = 'PsiOperative';
	Template.PrimaryWeapons[ 4 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_CV', 1 ) );
	Template.PrimaryWeapons[ 4 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_MG', 1 ) );
	Template.PrimaryWeapons[ 4 ].PrimaryWeapons.AddItem( CreateEntry( 'AssaultRifle_BM', 1 ) );

	return Template;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}