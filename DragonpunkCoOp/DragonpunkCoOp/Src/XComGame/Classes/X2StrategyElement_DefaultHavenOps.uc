//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultHavenOps.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultHavenOps extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Ops;

	// @mnauta Haven ops deprecated
	Ops.Length = 0;

	return Ops;
}
