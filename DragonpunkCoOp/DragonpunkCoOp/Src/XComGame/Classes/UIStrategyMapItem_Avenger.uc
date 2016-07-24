//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_Avenger
//  AUTHOR:  Dan Kaplan -- 11/2014
//  PURPOSE: This file represents the Avenger on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_Avenger extends UIStrategyMapItem_Airship;

function UpdateFlyoverText()
{
	SetLabel(MapPin_Header);
}

defaultproperties
{	
	bAnimateOnInit = false;
}