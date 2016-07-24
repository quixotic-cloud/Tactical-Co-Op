//---------------------------------------------------------------------------------------
//  FILE:    X2CityTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2CityTemplate extends X2StrategyElementTemplate;

var(CityTemplate) Vector      Location;
var(CityTemplate) name		  Country;

var localized string      DisplayName;
var localized string      PoiText;


//---------------------------------------------------------------------------------------
DefaultProperties
{
}