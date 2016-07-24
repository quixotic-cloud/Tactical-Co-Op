//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultEndings.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultEndings extends X2StrategyElement
	dependson(X2StrategyGameRulesetDataStructures);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Endings;

	Endings.Length = 0;

	return Endings;
}

