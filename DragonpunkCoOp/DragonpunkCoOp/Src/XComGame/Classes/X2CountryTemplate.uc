//---------------------------------------------------------------------------------------
//  FILE:    X2CountryTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2CountryTemplate extends X2StrategyElementTemplate dependson(X2StrategyGameRulesetDataStructures) config(GameBoard);

var() array<CountryNames>			Names;  // Valid lists of names for units
var() bool							bHideInCustomization; // Should this country be hidden in the nationality list

var() config string					FlagImage; // UI image path
var() config string					FlagArchetype; // image path to pawn texture
var() config CountryRaces			Races;
var() config name					Language; // current valid values are, 'english', 'french', 'german', 'italian', 'polish', 'russian', 'spanish'
var() config int					UnitWeight; // Higher number increases likelihood country will get picked when determining a random country for a unit

var localized string				DisplayName;
var localized string				DisplayNameWithArticle;
var localized string				DisplayNameWithArticleLower;
var localized string				DisplayNamePossessive;
var localized string				DisplayAdjective;

//---------------------------------------------------------------------------------------
DefaultProperties
{
}