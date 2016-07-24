//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeAlertForce.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeAlertForce extends X2ChallengeTemplate;

var delegate<ChallengeAlertForceSelector> SelectAlertForceFn;

delegate  ChallengeAlertForceSelector( X2ChallengeAlertForce Selector, XComGameState_HeadquartersXCom HeadquartersStateObject, out int AlertLevel, out int ForceLevel );

static function SelectAlertAndForceLevels( X2ChallengeAlertForce Selector, XComGameState_HeadquartersXCom HeadquartersStateObject, out int AlertLevel, out int ForceLevel )
{
	Selector.SelectAlertForceFn( Selector, HeadquartersStateObject, AlertLevel, ForceLevel );

	`assert( AlertLevel >= class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty );
	`assert( AlertLevel <= class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty );
	`assert( ForceLevel >= 1 );
	`assert( ForceLevel <= `GAMECORE.MAX_FORCE_LEVEL_UI_VAL );
}