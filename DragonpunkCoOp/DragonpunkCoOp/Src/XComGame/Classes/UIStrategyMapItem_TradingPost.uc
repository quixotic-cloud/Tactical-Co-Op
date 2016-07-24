//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMap_TradingPost
//  AUTHOR:  Mark Nauta -- 08/2014
//  PURPOSE: This file represents a trading post spot on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_TradingPost extends UIStrategyMapItem;

function UpdateFlyoverText()
{
	//local XComGameStateHistory History;
	//local XComGameState_TradingPost TradingPost;

	//History = `XCOMHISTORY;
	//TradingPost = XComGameState_TradingPost(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));

	SetLabel(MapPin_Header);
}

defaultproperties
{
}