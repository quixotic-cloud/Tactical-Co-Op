//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSquadAlienSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSquadAlienSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateStandardRandomSelector( ) );
	Templates.AddItem( CreateAdventSelector( ) );
	Templates.AddItem( CreateAllPsiSelector( ) );

	return Templates;
}

static function X2ChallengeSquadAlien CreateStandardRandomSelector( )
{
	local X2ChallengeSquadAlien	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSquadAlien', Template, 'ChallengeStandardRandomAliens');

	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvTrooperMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvCaptainMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvStunLancerMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvShieldBearerMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvMEC_MP', 1 ) );

	Template.WeightedAlienTypes.AddItem( CreateEntry( 'SectoidMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'FacelessMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'ViperMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'MutonMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'CyberusMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'BerserkerMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'ArchonMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'ChryssalidMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AndromedonMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'SectopodMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'GatekeeperMP', 1 ) );

	return Template;
}

static function X2ChallengeSquadAlien CreateAdventSelector( )
{
	local X2ChallengeSquadAlien	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSquadAlien', Template, 'ChallengeAdventOnly');

	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvTrooperMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvCaptainMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvStunLancerMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvShieldBearerMP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'AdvMEC_MP', 1 ) );
	Template.WeightedAlienTypes.AddItem( CreateEntry( 'SectopodMP', 1 ) );

	return Template;
}

static function X2ChallengeSquadAlien CreateAllPsiSelector( )
{
	local X2ChallengeSquadAlien	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSquadAlien', Template, 'ChallengeAllPsiAliens');

	Template.SelectSquadAliensFn = AllPsiSelector;

	return Template;
}

static function array<name> AllPsiSelector( X2ChallengeSquadAlien Selector, int count )
{
	local array<name> AlienTypes;

	for (count = count; count > 0; --count)
	{
		AlienTypes.AddItem( 'SectoidMP' );
	}

	return AlienTypes;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}