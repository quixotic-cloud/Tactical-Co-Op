//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_AlienNetworkComponent
//  AUTHOR:  Mark Nauta -- 01/12/2015
//  PURPOSE: This file represents an alien network spot on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_AlienNetworkComponent extends UIStrategyMapItem;

function UpdateFlyoverText()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	SetLevel(MissionState.Doom);
}

simulated function bool IsSelectable()
{
	return true;
}

defaultproperties
{
}