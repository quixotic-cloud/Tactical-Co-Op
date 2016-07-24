//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultContinents.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultContinents extends X2StrategyElement
	dependson(X2ContinentTemplate)
	config(GameBoard);

var config array<name> Continents;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2ContinentTemplate Template;
	local name ContinentName;

	foreach default.Continents(ContinentName)
	{
		`CREATE_X2TEMPLATE(class'X2ContinentTemplate', Template, ContinentName);
		Templates.AddItem(Template);
	}

	return Templates;
}