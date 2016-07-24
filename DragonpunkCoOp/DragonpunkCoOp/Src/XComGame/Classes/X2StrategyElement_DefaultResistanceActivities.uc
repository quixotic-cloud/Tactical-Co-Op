//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultResistanceActivities.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultResistanceActivities extends X2StrategyElement
	dependson(X2ResistanceActivityTemplate)
	config(GameData);

var config array<name> Activities;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2ResistanceActivityTemplate Template;
	local name ActivityName;

	foreach default.Activities(ActivityName)
	{
		`CREATE_X2TEMPLATE(class'X2ResistanceActivityTemplate', Template, ActivityName);
		Templates.AddItem(Template);
	}

	return Templates;
}