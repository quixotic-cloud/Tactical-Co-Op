//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultRegionBonuses.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultRegionBonuses extends X2StrategyElement;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Bonuses;

	// @mnauta Region bonuses are deprecated
	Bonuses.Length = 0;

	return Bonuses;
}
