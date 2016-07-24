//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSoldierClassSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSoldierClassSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem( CreateStandardClassSelector( ) );
	Templates.AddItem( CreateAllPsiSelector( ) );

	return Templates;
}

static function X2ChallengeSoldierClass CreateStandardClassSelector( )
{
	local X2ChallengeSoldierClass	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSoldierClass', Template, 'ChallengeStandardSoldier');

	Template.WeightedSoldierClasses.AddItem( CreateEntry( 'Sharpshooter', 1 ) );
	Template.WeightedSoldierClasses.AddItem( CreateEntry( 'Grenadier', 1 ) );
	Template.WeightedSoldierClasses.AddItem( CreateEntry( 'Specialist', 1 ) );
	Template.WeightedSoldierClasses.AddItem( CreateEntry( 'Ranger', 1 ) );
	Template.WeightedSoldierClasses.AddItem( CreateEntry( 'PsiOperative', 1 ) );

	return Template;
}

static function X2ChallengeSoldierClass CreateAllPsiSelector( )
{
	local X2ChallengeSoldierClass	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSoldierClass', Template, 'ChallengeAllPsi');

	Template.SelectSoldierClassesFn = AllPsiSelector;

	return Template;
}

static function array<name> AllPsiSelector( X2ChallengeSoldierClass Selector, int count )
{
	local array<name> SoldierClasses;

	for( count = count; count > 0; --count )
	{
		SoldierClasses.AddItem( 'PsiOperative' );
	}

	return SoldierClasses;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}