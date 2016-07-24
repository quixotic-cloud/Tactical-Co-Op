//---------------------------------------------------------------------------------------
//  FILE:    X2MissionSiteDescriptionTemplate.uc
//  AUTHOR:  Ryan McFall
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2MissionSiteDescriptionTemplate extends X2StrategyElementTemplate;

var localized string DescriptionString;

var() Delegate<GetMissionSiteDescription> GetMissionSiteDescriptionFn;

delegate string GetMissionSiteDescription(string BaseString, XComGameState_MissionSite MissionSite);

//---------------------------------------------------------------------------------------
DefaultProperties
{
}