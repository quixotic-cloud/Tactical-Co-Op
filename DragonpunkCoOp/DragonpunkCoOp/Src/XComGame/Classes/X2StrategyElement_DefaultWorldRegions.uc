//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultWorldRegions.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultWorldRegions extends X2StrategyElement
	config(GameBoard);

var config array<name> Regions;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2WorldRegionTemplate Template;
	local name RegionName;

	foreach default.Regions(RegionName)
	{
		`CREATE_X2TEMPLATE(class'X2WorldRegionTemplate', Template, RegionName);
		Templates.AddItem(Template);
	}

	return Templates;
}
