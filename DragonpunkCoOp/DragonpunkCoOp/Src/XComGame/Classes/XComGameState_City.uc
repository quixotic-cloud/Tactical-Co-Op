//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_City.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for a city within the strategy
//           game of X-Com 2. For more information on the design spec for cities, refer to
//           https://arcade/sites/2k/Studios/Firaxis/XCOM2/Shared%20Documents/World%20Map%20and%20Strategy%20AI.docx
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_City extends XComGameState_GeoscapeEntity native(Core)
	dependson(X2StrategyGameRulesetDataStructures);

//var() TCity     CityTemplate;
var() protected name                   m_TemplateName;
var() protected X2CityTemplate         m_Template;


static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

simulated function X2CityTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2CityTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

function OnCreation(X2CityTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

static function SetUpCities(XComGameState StartState)
{
	//Adding cities
	local int Index;	
	local int RandomIndex;
	local XComGameState_WorldRegion RegionStateObject;	
	local XComGameState_City CityStateObject;
	local array<X2StrategyElementTemplate> arrCityTemplates;
	local Vector2D v2Coords;

	//Picking random cities
	local int MaxCityIterations;
	local int CityIterations;	
	local array<X2CityTemplate> PickCitySet;
	local array<X2CityTemplate> PickedCities;
	local int NumDesired;

	arrCityTemplates = GetMyTemplateManager().GetAllTemplatesOfClass(class'X2CityTemplate');
	//Iterate every region and pick out cities for the populated ones
	MaxCityIterations = 100;	
	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', RegionStateObject)
	{			
		//The city templates specify which region they are a part of. Make a list of the cities that belong in the region we are iterating
		PickCitySet.Length = 0;
		for( Index = 0; Index < arrCityTemplates.Length; ++Index )
		{
			v2Coords.x = X2CityTemplate(arrCityTemplates[Index]).Location.x;
			v2Coords.y = X2CityTemplate(arrCityTemplates[Index]).Location.y;

			if(RegionStateObject.InRegion(v2Coords))
			{
				PickCitySet.AddItem(X2CityTemplate(arrCityTemplates[Index]));
			}
		}			

		//Randomly move cites from the PickCitySet array to the PickedCities array. The number of cities is variable.
		NumDesired = `SYNC_RAND_STATIC(2) + 1;			
		CityIterations = 0;
		PickedCities.Length = 0;

		if(PickCitySet.Length > 0)
		{
			do
			{
				RandomIndex = `SYNC_RAND_STATIC(PickCitySet.Length);
				PickedCities.AddItem(PickCitySet[RandomIndex]);
				PickCitySet.Remove(RandomIndex,1);				
				++CityIterations;
			}
			until(PickedCities.Length == NumDesired ||
				  CityIterations < MaxCityIterations );
		}

		//Create state objects for the cities, and associate them with the region that contains them
		for( Index = 0; Index < PickedCities.Length; ++Index )
		{
			//Build the state object and add it to the start state
			CityStateObject = XComGameState_City(StartState.CreateStateObject(class'XComGameState_City'));
			CityStateObject.OnCreation(PickedCities[Index]);
			CityStateObject.Location = CityStateObject.m_Template.Location;
			StartState.AddStateObject(CityStateObject);

			//Add the city to its region's list of cities
			RegionStateObject.Cities.AddItem( CityStateObject.GetReference() );
		}		
	}
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_City';
}

function string GetUIWidgetFlashLibraryName()
{
	return "MI_outpost";
}

function string GetUIPinImagePath()
{
	return "";
}

protected function bool CanInteract()
{
	return false;
}

function bool ShouldBeVisible()
{
	return false;
}


//---------------------------------------------------------------------------------------
DefaultProperties
{    
}
