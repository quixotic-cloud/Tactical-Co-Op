//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_Skyranger
//  AUTHOR:  Dan Kaplan -- 11/2014
//  PURPOSE: This file represents the Skyranger on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_Skyranger extends UIStrategyMapItem_Airship;

function UpdateFlyoverText()
{
	local XComGameState_Skyranger Skyranger;

	// debug info about Skyranger state
	Skyranger = XComGameState_Skyranger(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	SetLabel(Skyranger.GetUIPinLabel());
}

defaultproperties
{
}