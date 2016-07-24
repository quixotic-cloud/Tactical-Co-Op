//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeEnemyForces.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeEnemyForces extends X2ChallengeTemplate;

var delegate<EnemyForcesSelector> SelectEnemyForcesFn;

delegate EnemyForcesSelector( X2ChallengeEnemyForces Selector, XComGameState_MissionSite MissionSite, XComGameState_BattleData BattleData, XComGameState StartState );

static function SelectEnemyForces( X2ChallengeEnemyForces Selector, XComGameState_MissionSite MissionSite, XComGameState_BattleData BattleData, XComGameState StartState )
{
	Selector.SelectEnemyForcesFn( Selector, MissionSite, BattleData, StartState );
}