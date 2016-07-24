//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_City
//  AUTHOR:  Dan Kaplan -- 10/2014
//  PURPOSE: This file represents a city spot on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_City extends UIStrategyMapItem;

function UpdateFlyoverText()
{
	local XComGameStateHistory History;
	local XComGameState_City City;

	History = `XCOMHISTORY;
	City = XComGameState_City(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

	SetLabel(MapPin_Header @ City.GetMyTemplateName());
}

defaultproperties
{
}