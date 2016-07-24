//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultRegionLinks.uc
//  AUTHOR:  Jake Solomon
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultRegionLinks extends X2StrategyElement
	dependson(X2RegionLinkTemplate)
	config(GameBoard);

var config array<name> RegionLinks;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2RegionLinkTemplate Template;
	local name RegionLinkName;

	foreach default.RegionLinks(RegionLinkName)
	{
		`CREATE_X2TEMPLATE(class'X2RegionLinkTemplate', Template, RegionLinkName);
		Templates.AddItem(Template);
	}

	return Templates;
}