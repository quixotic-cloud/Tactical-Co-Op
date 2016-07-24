//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeAlertForceSelectors.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeAlertForceSelectors extends X2ChallengeElement;

static function array<X2DataTemplate> CreateTemplates( )
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem( CreateRandomLevels( ) );
	Templates.AddItem( CreateHardestLevels( ) );

	return Templates;
}

static function X2ChallengeAlertForce CreateRandomLevels( )
{
	local X2ChallengeAlertForce	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeAlertForce', Template, 'ChallengeRandomForceLevels');

	Template.SelectAlertForceFn = RandomForceLevelSelection;

	return Template;
}

static function RandomForceLevelSelection( X2ChallengeAlertForce Selector, XComGameState_HeadquartersXCom HeadquartersStateObject, out int AlertLevel, out int ForceLevel )
{
	// Set the Alert Level to the Squadsize +/- 1
	AlertLevel = `SYNC_RAND_STATIC(3) - 1 + HeadquartersStateObject.Squad.Length;
	AlertLevel = Clamp( AlertLevel, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty, class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty );

	ForceLevel = `SYNC_RAND_STATIC( 20 - 15 + 1 ) + 15;
}

static function X2ChallengeAlertForce CreateHardestLevels( )
{
	local X2ChallengeAlertForce	Template;

	`CREATE_X2TEMPLATE(class'X2ChallengeAlertForce', Template, 'ChallengeHardestForceLevels');

	Template.SelectAlertForceFn = MaximizedForceLevelSelection;

	return Template;
}

static function MaximizedForceLevelSelection( X2ChallengeAlertForce Selector, XComGameState_HeadquartersXCom HeadquartersStateObject, out int AlertLevel, out int ForceLevel )
{
	AlertLevel = 4;
	ForceLevel = 20;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = false
}