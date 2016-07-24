//---------------------------------------------------------------------------------------
//  FILE:    X2ChallengeSoldierRank.uc
//  AUTHOR:  Russell Aasland
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ChallengeSoldierRank extends X2ChallengeTemplate;

var delegate<SoldierRankSelector> SelectSoldierRanksFn;

delegate SoldierRankSelector( X2ChallengeSoldierRank Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState );

static function SelectSoldierRanks( X2ChallengeSoldierRank Selector, array<XComGameState_Unit> XComUnits, XComGameState StartState )
{
	Selector.SelectSoldierRanksFn( Selector, XComUnits, StartState );
}