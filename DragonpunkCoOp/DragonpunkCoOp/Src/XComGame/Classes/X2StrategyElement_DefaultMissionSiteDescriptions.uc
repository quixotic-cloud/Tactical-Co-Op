//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultMissionSiteDescriptions.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultMissionSiteDescriptions extends X2StrategyElement;

var localized array<String> HavenFirstName;
var localized array<String> HavenSecondName;
var localized array<String> SlumsFirstName;
var localized array<String> SlumsSecondName;
var localized array<String> DistrictFirstName;
var localized array<String> DistrictSecondName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
		
	Templates.AddItem(CreateCityCenterTemplate());	
	Templates.AddItem(CreateWildernessTemplate());	
	Templates.AddItem(CreateShantyTemplate());	
	Templates.AddItem(CreateSmallTownTemplate());	
	Templates.AddItem(CreateSlumsTemplate());	
	Templates.AddItem(CreateFacilityTemplate());	

	return Templates;
}

static function X2DataTemplate CreateCityCenterTemplate()
{
	local X2MissionSiteDescriptionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSiteDescriptionTemplate', Template, 'CityCenter');

	Template.GetMissionSiteDescriptionFn = GetCityCenterMissionSiteDescription;

	return Template;
}

static function X2DataTemplate CreateWildernessTemplate()
{
	local X2MissionSiteDescriptionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSiteDescriptionTemplate', Template, 'Wilderness');

	Template.GetMissionSiteDescriptionFn = GetWildernessMissionSiteDescription;

	return Template;
}

static function X2DataTemplate CreateShantyTemplate()
{
	local X2MissionSiteDescriptionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSiteDescriptionTemplate', Template, 'Shanty');

	Template.GetMissionSiteDescriptionFn = GetShantyMissionSiteDescription;

	return Template;
}

static function X2DataTemplate CreateSmallTownTemplate()
{
	local X2MissionSiteDescriptionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSiteDescriptionTemplate', Template, 'SmallTown');

	Template.GetMissionSiteDescriptionFn = GetSmallTownMissionSiteDescription;

	return Template;
}

static function X2DataTemplate CreateSlumsTemplate()
{
	local X2MissionSiteDescriptionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSiteDescriptionTemplate', Template, 'Slums');

	Template.GetMissionSiteDescriptionFn = GetSlumsMissionSiteDescription;

	return Template;
}

static function X2DataTemplate CreateFacilityTemplate()
{
	local X2MissionSiteDescriptionTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSiteDescriptionTemplate', Template, 'Facility');

	Template.GetMissionSiteDescriptionFn = GetFacilityMissionSiteDescription;

	return Template;
}

static function string GetCityCenterMissionSiteDescription(string BaseString, XComGameState_MissionSite MissionSite)
{
	local string OutputString;
	local X2CityTemplate NearestCityTemplate;

	NearestCityTemplate = GetNearestCity(MissionSite.Location, MissionSite.GetWorldRegion()); //Specify a region so that it only chooses amongst advent cities
	if( NearestCityTemplate != none )
	{
		OutputString = GenerateDistrictName(BaseString);
		OutputString = Repl(OutputString, "<AdventCity>", NearestCityTemplate.DisplayName);
	}

	return OutputString;
}
static function string GetWildernessMissionSiteDescription(string BaseString, XComGameState_MissionSite MissionSite)
{
	local string OutputString;

	OutputString = BaseString;
	OutputString = Repl(OutputString, "<Region>", MissionSite.GetWorldRegion().GetMyTemplate().DisplayName);

	return OutputString;
}
static function string GetShantyMissionSiteDescription(string BaseString, XComGameState_MissionSite MissionSite)
{
	local string OutputString;
	
	OutputString = GenerateHavenName(BaseString);
	OutputString = Repl(OutputString, "<Region>", MissionSite.GetWorldRegion().GetMyTemplate().DisplayName);

	return OutputString;
}
static function string GetSmallTownMissionSiteDescription(string BaseString, XComGameState_MissionSite MissionSite)
{
	local string OutputString;
	local X2CityTemplate NearestCityTemplate;

	OutputString = BaseString;
	NearestCityTemplate = GetNearestCity(MissionSite.Location);

	if( NearestCityTemplate != none )
	{
		OutputString = Repl(OutputString, "<PatrolNum>", `SYNC_RAND_STATIC(19) + 1);
		OutputString = Repl(OutputString, "<NearestCity>", NearestCityTemplate.DisplayName);
	}

	return OutputString;
}
static function string GetSlumsMissionSiteDescription(string BaseString, XComGameState_MissionSite MissionSite)
{
	local string OutputString;
	local X2CityTemplate NearestCityTemplate;

	NearestCityTemplate = GetNearestCity(MissionSite.Location, MissionSite.GetWorldRegion()); //Specify a region so that it only chooses amongst advent cities

	OutputString = GenerateSlumsName(BaseString);
	OutputString = Repl(OutputString, "<AdventCity>", NearestCityTemplate.DisplayName);

	return OutputString;
}
static function string GetFacilityMissionSiteDescription(string BaseString, XComGameState_MissionSite MissionSite)
{
	local string OutputString;

	OutputString = BaseString;

	return OutputString;
}

static function String GenerateHavenName(string BaseString)
{
	local XGParamTag kTag;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	kTag.StrValue0 = default.HavenFirstName[Rand(default.HavenFirstName.Length)];
	kTag.StrValue1 = default.HavenSecondName[Rand(default.HavenSecondName.Length)];

	return `XEXPAND.ExpandString(BaseString);
}

static function String GenerateSlumsName(string BaseString)
{
	local XGParamTag kTag;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	kTag.StrValue0 = default.SlumsFirstName[Rand(default.SlumsFirstName.Length)];
	kTag.StrValue1 = default.SlumsSecondName[Rand(default.SlumsSecondName.Length)];

	return `XEXPAND.ExpandString(BaseString);
}

static function String GenerateDistrictName(string BaseString)
{
	local XGParamTag kTag;
	
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	kTag.StrValue0 = default.DistrictFirstName[Rand(default.DistrictFirstName.Length)];
	kTag.StrValue1 = default.DistrictSecondName[Rand(default.DistrictSecondName.Length)];
		
	return `XEXPAND.ExpandString(BaseString);
}

static function X2CityTemplate GetNearestCity(Vector Location, XComGameState_WorldRegion LimitToRegion = none)
{
	local array<X2StrategyElementTemplate> arrCityTemplates;
	local X2StrategyElementTemplate IterateTemplate;
	local X2CityTemplate CityTemplate;
	//local StateObjectReference CityRef;
	local float BestDistance;
	local float Distance;
	//local XComGameStateHistory History;
	//local XComGameState_City CityState;

	//History = `XCOMHISTORY;

	//if(LimitToRegion == none)
	//{
		arrCityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2CityTemplate');
	//}
	//else
	//{
	//	foreach LimitToRegion.Cities(CityRef)
	//	{
	//		CityState = XComGameState_City(History.GetGameStateForObjectID(CityRef.ObjectID));
	//		arrCityTemplates.AddItem( CityState.GetMyTemplate() );
	//	}
	//}
	

	BestDistance = 10000000.0f;
	foreach arrCityTemplates(IterateTemplate)
	{
		Distance = VSize(X2CityTemplate(IterateTemplate).Location - Location);
		if( Distance < BestDistance )
		{
			BestDistance = Distance;
			CityTemplate = X2CityTemplate(IterateTemplate);
		}		
	}

	return CityTemplate;
}