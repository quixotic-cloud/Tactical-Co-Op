//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Continent.uc
//  AUTHOR:  Mark Nauta
// 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Continent extends XComGameState_GeoscapeEntity
	native(Core)
	config(GameBoard);

var() protected name                   m_TemplateName;
var() protected X2ContinentTemplate    m_Template;

var name							   ContinentBonus;
var bool							   bHasHadContinentBonus; // Has ever had the continent bonus active
var bool							   bContinentBonusActive; // Continent bonus is currently active

var array<StateObjectReference>		   Regions;

var config float					   DesiredDistanceBetweenMapItems;
var config float					   MinDistanceBetweenMapItems;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2ContinentTemplate GetMyTemplate()
{
	if(m_Template == none)
	{
		m_Template = X2ContinentTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
function OnCreation(X2ContinentTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

//---------------------------------------------------------------------------------------
// Continents Created and given continent bonus randomnly
static function SetUpContinents(XComGameState StartState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> ContinentDefinitions, ContinentBonuses;
	local XComGameState_Continent ContinentState;
	local X2ContinentTemplate ContinentTemplate;
	local int idx, RandIndex, i;

	StratMgr = GetMyTemplateManager();
	ContinentDefinitions = StratMgr.GetAllTemplatesOfClass(class'X2ContinentTemplate');

	// Grab All Continent Bonuses
	ContinentBonuses = StratMgr.GetAllTemplatesOfClass(class'X2GameplayMutatorTemplate');
	for(idx = 0; idx < ContinentBonuses.Length; idx++)
	{
		if(X2GameplayMutatorTemplate(ContinentBonuses[idx]).Category != "ContinentBonus")
		{
			ContinentBonuses.Remove(idx, 1);
			idx--;
		}
	}

	for(idx = 0; idx < ContinentDefinitions.Length; idx++)
	{
		ContinentTemplate = X2ContinentTemplate(ContinentDefinitions[idx]);
		ContinentState = ContinentTemplate.CreateInstanceFromTemplate(StartState);
		StartState.AddStateObject(ContinentState);
		ContinentState.Location = ContinentTemplate.LandingLocation;
		ContinentState.AssignRegions(StartState);
		
		// Assign Continent Bonus
		if(ContinentBonuses.Length == 0)
		{
			ContinentBonuses = StratMgr.GetAllTemplatesOfClass(class'X2GameplayMutatorTemplate');
			for(i = 0; i < ContinentBonuses.Length; i++)
			{
				if(X2GameplayMutatorTemplate(ContinentBonuses[i]).Category != "ContinentBonus")
				{
					ContinentBonuses.Remove(i, 1);
					i--;
				}
			}
		}

		RandIndex = `SYNC_RAND_STATIC(ContinentBonuses.Length);
		ContinentState.ContinentBonus = ContinentBonuses[RandIndex].DataName;
		ContinentBonuses.Remove(RandIndex, 1);
	}
}

//---------------------------------------------------------------------------------------
// Assign region refs to continent and continent ref to regions
function AssignRegions(XComGameState StartState)
{
	local XComGameState_WorldRegion RegionState;
	
	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(GetMyTemplate().Regions.Find(RegionState.GetMyTemplateName()) != INDEX_NONE)
		{
			Regions.AddItem(RegionState.GetReference());
			RegionState.Continent = self.GetReference();
		}
	}
}

//---------------------------------------------------------------------------------------
function Vector GetLocation()
{
	return GetMyTemplate().LandingLocation;
}

//---------------------------------------------------------------------------------------
function Vector2D Get2DLocation()
{
	local Vector2D v2Loc;

	v2Loc.x = GetMyTemplate().LandingLocation.x;
	v2Loc.y = GetMyTemplate().LandingLocation.y;

	return v2Loc;
}

//---------------------------------------------------------------------------------------
function bool ContainsRegion(StateObjectReference RegionRefToCheck)
{
	local StateObjectReference RegionRef;

	foreach Regions(RegionRef)
	{
		if (RegionRef.ObjectID == RegionRefToCheck.ObjectID)
		{
			return true;
		}
	}

	return false;
}

//#############################################################################################
//----------------   LOCATION HANDLING   ------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
/// Utility method - returns a random point contained by the continent that does not fall in a region
function Vector GetRandomLocationInContinent(optional array<XComGameState_GeoscapeEntity> Entities, optional XComGameState_GeoscapeEntity NewEntity)
{
	local XComGameStateHistory History;
	local Vector RandomLocation;
	local Vector2D RandomLoc2D;
	local XComGameState_GeoscapeEntity EntityState;
	local int Iterations;
	local TRect Bounds;

	RandomLocation.X = -1.0;  RandomLocation.Y = -1.0;  RandomLocation.Z = -1.0;

	Bounds = GetMyTemplate().Bounds[0];
	
	// Grab other entities in the continent (to avoid placing near them)
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', EntityState)
	{
		//First make sure that the entity is associated with this continent
		if (EntityState.Continent.ObjectID == ObjectID)
		{
			// Then ensure the entity is not the new addition, and has not already been saved
			if (EntityState.ObjectID != NewEntity.ObjectID && Entities.Find(EntityState) == INDEX_NONE)
			{
				Entities.AddItem(EntityState);
			}
		}
	}

	RandomLocation.X = Bounds.fLeft + `SYNC_FRAND() * (Bounds.fRight - Bounds.fLeft);
	RandomLocation.Y = Bounds.fTop + `SYNC_FRAND() * (Bounds.fBottom - Bounds.fTop);
	RandomLocation.Z = 0.0f;
	RandomLoc2D = vect2d(RandomLocation.X, RandomLocation.Y);

	while (!class'X2StrategyGameRulesetDataStructures'.static.IsOnLand(RandomLoc2D)
		|| !class'X2StrategyGameRulesetDataStructures'.static.AvoidOverlapWithTooltipBounds(RandomLocation, Entities, NewEntity)
		|| ((Iterations < 100 && !class'X2StrategyGameRulesetDataStructures'.static.MinDistanceFromOtherItems(RandomLocation, Entities, default.DesiredDistanceBetweenMapItems))
		|| (Iterations >= 100 && Iterations < 500 && !class'X2StrategyGameRulesetDataStructures'.static.MinDistanceFromOtherItems(RandomLocation, Entities, default.MinDistanceBetweenMapItems))))
	{
		RandomLocation.X = Bounds.fLeft + `SYNC_FRAND() * (Bounds.fRight - Bounds.fLeft);
		RandomLocation.Y = Bounds.fTop + `SYNC_FRAND() * (Bounds.fBottom - Bounds.fTop);
		RandomLocation.Z = 0.0f;
		RandomLoc2D = vect2d(RandomLocation.X, RandomLocation.Y);

		++Iterations;
	}

	return RandomLocation;
}

//---------------------------------------------------------------------------------------
function Vector2D GetRandom2DLocationInContinent()
{
	local Vector RandomLocation;
	local Vector2D RandomLoc2D;

	RandomLocation = GetRandomLocationInContinent();
	RandomLoc2D.x = RandomLocation.x;
	RandomLoc2D.y = RandomLocation.y;

	return RandomLoc2D;
}

//---------------------------------------------------------------------------------------
function XComGameState_WorldRegion GetRandomRegionInContinent(optional StateObjectReference RegionRef)
{
	local StateObjectReference RandomRegion;

	do
	{
		RandomRegion = Regions[`SYNC_RAND(Regions.Length)];
	} until(RandomRegion.ObjectID != RegionRef.ObjectID);
	
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RandomRegion.ObjectID));
}

//#############################################################################################
//----------------   RESISTANCE LEVEL   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetMaxResistanceLevel()
{
	// 1.5 the number of regions, rounded up
	return FCeil(Regions.Length * 1.5f);
}

//---------------------------------------------------------------------------------------
function int GetResistanceLevel(optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int ResistanceLevel, idx;

	History = `XCOMHISTORY;
	ResistanceLevel = 0;

	for(idx = 0; idx < Regions.Length; idx++)
	{
		RegionState = none;

		if(NewGameState != none)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(Regions[idx].ObjectID));
		}

		if(RegionState == none)
		{
			RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(Regions[idx].ObjectID));
		}

		if(RegionState != none)
		{
			switch(RegionState.ResistanceLevel)
			{
			case eResLevel_Contact:
				ResistanceLevel += 1;
				break;
			case eResLevel_Outpost:
				ResistanceLevel += 2;
				break;
			default:
				break;
			}
		}
	}

	ResistanceLevel = Clamp(ResistanceLevel, 0, GetMaxResistanceLevel());

	return ResistanceLevel;
}

//---------------------------------------------------------------------------------------
function HandleRegionResistanceLevelChange(XComGameState NewGameState)
{
	local int ResistanceLevel;

	ResistanceLevel = GetResistanceLevel(NewGameState);

	if(ResistanceLevel >= GetMaxResistanceLevel() && !bContinentBonusActive)
	{
		`XEVENTMGR.TriggerEvent('ContinentBonusActivated', self, , NewGameState);
		ActivateContinentBonus(NewGameState);
	}
	else if(ResistanceLevel < GetMaxResistanceLevel() && bContinentBonusActive)
	{
		DeactivateContinentBonus(NewGameState);
	}
	RefreshMapItem();
}

//---------------------------------------------------------------------------------------
function X2GameplayMutatorTemplate GetContinentBonus()
{
	return X2GameplayMutatorTemplate(GetMyTemplateManager().FindStrategyElementTemplate(ContinentBonus));
}

//---------------------------------------------------------------------------------------
function ActivateContinentBonus(XComGameState NewGameState)
{
	GetContinentBonus().OnActivatedFn(NewGameState, self.GetReference(), bHasHadContinentBonus);
	bHasHadContinentBonus = true;
	bContinentBonusActive = true;
}

//---------------------------------------------------------------------------------------
function DeactivateContinentBonus(XComGameState NewGameState)
{
	GetContinentBonus().OnDeactivatedFn(NewGameState, self.GetReference());
	bContinentBonusActive = false;
}

//#############################################################################################
//----------------   RADIO TOWERS   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetMaxRadioTowers()
{
	return GetMaxResistanceLevel() - Regions.Length;
}

//---------------------------------------------------------------------------------------
function int GetNumRadioTowers(optional XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int NumTowers, idx;

	History = `XCOMHISTORY;
	NumTowers = 0;

	for( idx = 0; idx < Regions.Length; idx++ )
	{
		RegionState = none;

		if( NewGameState != none )
		{
			RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(Regions[idx].ObjectID));
		}

		if( RegionState == none )
		{
			RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(Regions[idx].ObjectID));
		}

		if( RegionState != none )
		{
			switch( RegionState.ResistanceLevel )
			{
			case eResLevel_Outpost:
				NumTowers += 1;
				break;
			default:
				break;
			}
		}
	}

	NumTowers = Clamp(NumTowers, 0, GetMaxRadioTowers());

	return NumTowers;
}

//#############################################################################################
//----------------   GEOSCAPE ENTITY IMPLEMENTATION   -----------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool RequiresAvenger()
{
	return true;
}

//---------------------------------------------------------------------------------------
function bool HasTooltipBounds()
{
	return true;
}

//---------------------------------------------------------------------------------------
function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_Continent';
}

//---------------------------------------------------------------------------------------
function string GetUIWidgetFlashLibraryName()
{
	return "MI_continent";
}

//---------------------------------------------------------------------------------------
function string GetUIPinImagePath()
{
	return "";
}

function bool ShouldBeVisible()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.IsOutpostResearched())
	{
		for(idx = 0; idx < Regions.Length; idx++)
		{
			RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(Regions[idx].ObjectID));

			if(RegionState != none && RegionState.HaveUnlocked())
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
protected function bool CanInteract()
{
	return false;
}

//---------------------------------------------------------------------------------------
function UpdateGameBoard()
{
}

//---------------------------------------------------------------------------------------
simulated function RefreshMapItem()
{
	local UIStrategyMap StrategyMap;
	local XComGameState_GeoscapeEntity Entity;

	Entity = self; // hack to get around "self is not allowed in out parameter" error
	StrategyMap = UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));

	if( StrategyMap != none)
	{
		StrategyMap.GetMapItem(Entity).SetImage(GetUIPinImagePath());
	}
}