//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSquadSizeSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSquadSizeSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateRandomSquadSize( ) );
	Templates.AddItem( CreateMaximizedSquadSize( ) );
	Templates.AddItem( CreatePuritySquadSize( ) );

	return Templates;
}

static function X2ChallengeSquadSize CreateRandomSquadSize( )
{
	local X2ChallengeSquadSize	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSquadSize', Template, 'ChallengeRandomSquadSize');

	Template.MinXCom = 2;
	Template.MaxXCom = 4;

	Template.MinAliens = 1;
	Template.MaxAliens = 3;

	return Template;
}

static function X2ChallengeSquadSize CreateMaximizedSquadSize( )
{
	local X2ChallengeSquadSize	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSquadSize', Template, 'ChallengeMaximizedSquadSize');

	Template.SelectSquadSizeFn = MaximizedSquadSizeSelection;

	return Template;
}

static function MaximizedSquadSizeSelection( X2ChallengeSquadSize Selector, out int NumXcom, out int NumAlien )
{
	NumXCom = 4;
	NumAlien = 3;
}

static function X2ChallengeSquadSize CreatePuritySquadSize( )
{
	local X2ChallengeSquadSize	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeSquadSize', Template, 'ChallengePuritySquadSize');

	Template.MinXCom = 4;
	Template.MaxXCom = 7;

	Template.Weight = 8;

	return Template;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}