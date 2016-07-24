//---------------------------------------------------------------------------------------
//  FILE:    X2WorldRegionTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2WorldRegionTemplate extends X2StrategyElementTemplate
	config(GameBoard);

var localized string		DisplayName;

var config array<TRect>		Bounds;
var config array<name>		LinkedRegions; // All regions this region can possibly be linked with
var config array<name>		Countries;
var config Vector			LandingLocation;

var config Vector			RegionMeshLocation;
var config float			RegionMeshScale;
var config string			RegionTexturePath;

function XComGameState_WorldRegion CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_WorldRegion RegionState;

	RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class' XComGameState_WorldRegion'));
	RegionState.OnCreation(self);

	return RegionState;
}

function name GetRandomCountryInRegion()
{
	return Countries[`SYNC_RAND(Countries.Length)];
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
