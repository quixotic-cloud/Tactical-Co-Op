//---------------------------------------------------------------------------------------
//  FILE:    X2ContinentTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ContinentTemplate extends X2StrategyElementTemplate
	config(GameBoard);

var localized string				DisplayName;
var config array<TRect>			    Bounds;
var config Vector					LandingLocation;
var config array<name>				Regions;

function XComGameState_Continent CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Continent ContinentState;

	ContinentState = XComGameState_Continent(NewGameState.CreateStateObject(class' XComGameState_Continent'));
	ContinentState.OnCreation(self);

	return ContinentState;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}