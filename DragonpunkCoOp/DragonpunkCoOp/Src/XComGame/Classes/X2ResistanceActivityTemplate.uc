//---------------------------------------------------------------------------------------
//  FILE:    X2ResistanceActivityTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2ResistanceActivityTemplate extends X2StrategyElementTemplate config(GameData);

// Text displayed in Resistance Report
var localized string		DisplayName;

// Governs UI state of text, if not always good or bad use the int values to determine the state
var config bool				bAlwaysGood;
var config bool				bAlwaysBad;
var config int				MinGoodValue;
var config int				MaxGoodValue;

var config bool				bMission; // If the activity corresponds to a mission

//---------------------------------------------------------------------------------------
DefaultProperties
{
}