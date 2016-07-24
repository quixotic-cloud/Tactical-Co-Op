//---------------------------------------------------------------------------------------
//  FILE:    X2FacilityUpgradeTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2FacilityUpgradeTemplate extends X2StrategyElementTemplate;

var() string								PreviousMapName;  // Map to turn off when this upgrade is activated
var() config int							PointsToComplete;
var() config int							MaxBuild; // The amount that can be built on a facility
var() config int							UpgradeValue; // Value X for Upgrade (reduce X percent, produce X more power, etc.)
var() config int							iPower; // The amount of power usage this upgrade will add
var() config int							UpkeepCost; // The amount of monthly maintenence this upgrade will add to its parent facility
var() string								strImage; //UI image to display in menus
var() bool									bPriority;
var() bool									bHidden; // Do not display this upgrade to the player

// Requirements and Cost
var StrategyRequirement Requirements;
var StrategyCost		Cost;

// Text
var localized string						DisplayName;
var localized string						FacilityName;
var localized string						Summary;

var() Delegate<OnUpgradeAddedDelegate>      OnUpgradeAddedFn; // Apply the effect of the upgrade

delegate OnUpgradeAddedDelegate(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility);

//---------------------------------------------------------------------------------------
function XComGameState_FacilityUpgrade CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_FacilityUpgrade FacilityUpgradeState;

	FacilityUpgradeState = XComGameState_FacilityUpgrade(NewGameState.CreateStateObject(class'XComGameState_FacilityUpgrade'));
	FacilityUpgradeState.OnCreation(self);

	return FacilityUpgradeState;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bShouldCreateDifficultyVariants = true
}