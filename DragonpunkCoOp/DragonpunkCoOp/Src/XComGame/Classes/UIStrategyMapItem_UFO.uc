//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_UFO
//  AUTHOR:  Joe Weinhoffer - 4/28/2015
//  PURPOSE: This file represents a UFO on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_UFO extends UIStrategyMapItem;

function UpdateFlyoverText()
{
	local XComGameState_UFO UFO;

	// debug info about UFO state
	UFO = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	SetLabel(UFO.GetUIPinLabel());
}

defaultproperties
{
}