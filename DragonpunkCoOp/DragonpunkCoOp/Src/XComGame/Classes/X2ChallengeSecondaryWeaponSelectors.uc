//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSecondaryWeaponSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSecondaryWeaponSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateMagneticWeapons( ) );
	Templates.AddItem( CreateBeamWeapons( ) );
	Templates.AddItem( CreateRandomMix( ) );

	return Templates;
}

static function X2ChallengeSecondaryWeapon CreateMagneticWeapons( )
{
	local X2ChallengeSecondaryWeapon	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSecondaryWeapon', Template, 'ChallengeSecondaryMagneticWeapons');

	Template.SecondaryWeapons.Length = 5;

	Template.SecondaryWeapons[ 0 ].SoldierClassName = 'Sharpshooter';
	Template.SecondaryWeapons[ 0 ].SecondaryWeapons.AddItem( CreateEntry( 'Pistol_MG', 1 ) );

	Template.SecondaryWeapons[ 1 ].SoldierClassName = 'Grenadier';
	Template.SecondaryWeapons[ 1 ].SecondaryWeapons.AddItem( CreateEntry( 'GrenadeLauncher_CV', 1 ) );

	Template.SecondaryWeapons[ 2 ].SoldierClassName = 'Specialist';
	Template.SecondaryWeapons[ 2 ].SecondaryWeapons.AddItem( CreateEntry( 'Gremlin_MG', 1 ) );

	Template.SecondaryWeapons[ 3 ].SoldierClassName = 'Ranger';
	Template.SecondaryWeapons[ 3 ].SecondaryWeapons.AddItem( CreateEntry( 'Sword_MG', 1 ) );

	Template.SecondaryWeapons[ 4 ].SoldierClassName = 'PsiOperative';
	Template.SecondaryWeapons[ 4 ].SecondaryWeapons.AddItem( CreateEntry( 'PsiAmp_MG', 1 ) );
	
	return Template;
}

static function X2ChallengeSecondaryWeapon CreateBeamWeapons( )
{
	local X2ChallengeSecondaryWeapon	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSecondaryWeapon', Template, 'ChallengeSecondaryBeamWeapons');

	Template.SelectWeaponFn = BeamWeaponSelector;

	return Template;
}

// Functionally the outcom is the same as the Magnetics (everyone with the same level weapon tech), but with a different implementation
static function BeamWeaponSelector( X2ChallengeSecondaryWeapon Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	local XComGameState_Unit Unit;
	local name WeaponName;

	foreach XComUnits( Unit )
	{
		switch (Unit.GetSoldierClassTemplateName())
		{
			case 'Sharpshooter': WeaponName = 'Pistol_BM';
				break;

			case 'Grenadier': WeaponName = 'GrenadeLauncher_MG';
				break;

			case 'Ranger': WeaponName = 'Sword_BM';
				break;

			case 'Specialist': WeaponName = 'Gremlin_BM';
				break;

			case 'PsiOperative': WeaponName = 'PsiAmp_BM';
				break;

			default:
				WeaponName = '';
		}

		if (WeaponName == '')
			continue;

		class'X2ChallengeSecondaryWeapon'.static.ApplyWeapon( WeaponName, Unit, StartState );
	}
}

static function X2ChallengeSecondaryWeapon CreateRandomMix( )
{
	local X2ChallengeSecondaryWeapon	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSecondaryWeapon', Template, 'ChallengeSecondaryRandom');

	Template.SecondaryWeapons.Length = 5;

	Template.SecondaryWeapons[ 0 ].SoldierClassName = 'Sharpshooter';
	Template.SecondaryWeapons[ 0 ].SecondaryWeapons.AddItem( CreateEntry( 'Pistol_CV', 1 ) );
	Template.SecondaryWeapons[ 0 ].SecondaryWeapons.AddItem( CreateEntry( 'Pistol_MG', 1 ) );
	Template.SecondaryWeapons[ 0 ].SecondaryWeapons.AddItem( CreateEntry( 'Pistol_BM', 1 ) );

	Template.SecondaryWeapons[ 1 ].SoldierClassName = 'Grenadier';
	Template.SecondaryWeapons[ 1 ].SecondaryWeapons.AddItem( CreateEntry( 'GrenadeLauncher_CV', 1 ) );
	Template.SecondaryWeapons[ 1 ].SecondaryWeapons.AddItem( CreateEntry( 'GrenadeLauncher_MG', 1 ) );

	Template.SecondaryWeapons[ 2 ].SoldierClassName = 'Specialist';
	Template.SecondaryWeapons[ 2 ].SecondaryWeapons.AddItem( CreateEntry( 'Gremlin_CV', 1 ) );
	Template.SecondaryWeapons[ 2 ].SecondaryWeapons.AddItem( CreateEntry( 'Gremlin_MG', 1 ) );
	Template.SecondaryWeapons[ 2 ].SecondaryWeapons.AddItem( CreateEntry( 'Gremlin_BM', 1 ) );

	Template.SecondaryWeapons[ 3 ].SoldierClassName = 'Ranger';
	Template.SecondaryWeapons[ 3 ].SecondaryWeapons.AddItem( CreateEntry( 'Sword_CV', 1 ) );
	Template.SecondaryWeapons[ 3 ].SecondaryWeapons.AddItem( CreateEntry( 'Sword_MG', 1 ) );
	Template.SecondaryWeapons[ 3 ].SecondaryWeapons.AddItem( CreateEntry( 'Sword_BM', 1 ) );

	Template.SecondaryWeapons[ 4 ].SoldierClassName = 'PsiOperative';
	Template.SecondaryWeapons[ 4 ].SecondaryWeapons.AddItem( CreateEntry( 'PsiAmp_CV', 1 ) );
	Template.SecondaryWeapons[ 4 ].SecondaryWeapons.AddItem( CreateEntry( 'PsiAmp_MG', 1 ) );
	Template.SecondaryWeapons[ 4 ].SecondaryWeapons.AddItem( CreateEntry( 'PsiAmp_BM', 1 ) );

	return Template;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}