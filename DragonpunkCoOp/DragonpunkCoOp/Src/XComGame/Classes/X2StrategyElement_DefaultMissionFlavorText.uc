//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultMissionFlavorText.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultMissionFlavorText extends X2StrategyElement
	dependson(X2MissionFlavorTextTemplate)
	config(GameBoard);

var config array<name> Missions;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2MissionFlavorTextTemplate Template;
	local name MissionTextName;

	foreach default.Missions(MissionTextName)
	{
		`CREATE_X2TEMPLATE(class'X2MissionFlavorTextTemplate', Template, MissionTextName);
		Templates.AddItem(Template);
	}

	return Templates;
}