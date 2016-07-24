//---------------------------------------------------------------------------------------
//  FILE:    X2RegionLinkTemplate.uc
//  AUTHOR:  Jake Solomon
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2RegionLinkTemplate extends X2StrategyElementTemplate
	config(GameBoard);

var config array<name>				Regions;

function XComGameState_RegionLink CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_RegionLink LinkState;

	LinkState = XComGameState_RegionLink(NewGameState.CreateStateObject(class'XComGameState_RegionLink'));
	LinkState.OnCreation(self);

	return LinkState;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}