//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_WorldRegion.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for a region within the strategy
//           game of X-Com 2. For more information on the design spec for regions, refer to
//           https://arcade/sites/2k/Studios/Firaxis/XCOM2/Shared%20Documents/World%20Map%20and%20Strategy%20AI.docx
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_WorldRegion extends XComGameState_ScanningSite
	native(Core) 
	dependson(X2StrategyGameRulesetDataStructures)
	config(GameBoard);

var() protected name                   m_TemplateName;
var() protected X2WorldRegionTemplate  m_Template;

// Region Resistance State
var() EResistanceLevelType				ResistanceLevel;
var int									BaseSupplyDrop;
var int									POISupplyBonusDelta;
var int									RetaliationSupplyDelta;
var bool								bTemporarilyUnlocked;
var TDateTime							TempUnlockedEndTime;
var bool								bCanScanForContact;
var bool								bCanScanForOutpost;
var bool								bOnGPOrAlienFacilityPath;
var bool								bBlockContactEventTrigger;
var bool								bScanForContactEventTriggered;
var bool								bUpdateShortestPathsToMissions;

var int									CurrentMinScanDays;
var int									CurrentMaxScanDays;

// References to other state objects relevant to this region
var() array<StateObjectReference>		Cities;
var() array<StateObjectReference>		LinkedRegions;
var() StateObjectReference				Haven;

// Alien Progress
var StateObjectReference				AlienFacility;
var bool								bBuildingDoomFactory;
var TDateTime							DoomFactoryBuildEndTime;
var bool								bDoomFactoryPopup;
var bool								bControlPopup;
var bool								bResLevelPopup;
var bool								bContinentBonusPopup;
var bool								bUnlockedPopup;
var bool								bTempUnlockedPopup;

// Missing Persons
var int NumMissingPersons;
var int NumMissingPersonsThisMonth;
var int MissingPersonsPerHour;
var TDateTime MissingPersonsStartTime;

//Localized strings
var localized string m_strOutpostScanButtonLabel;
var localized string m_strResHQScanButtonLabel;

// Config vars
var config int							WorldRegion_PopSupportCivilianAlertThreshold; // Value of PopSupport below which Civilians go into red alert against XCom.

var config array<int>					MinSupplyDrop;
var config array<int>					MaxSupplyDrop;
var config int							SupplyDropMultiple;			// The interval between supply drop amounts
var config array<float>					RetaliationSuccessSupplyChangePercent; // Percent supplies added on retaliation success
var config array<float>					RegionDisconnectSupplyChangePercent; // Percent supplies cut by when the region is disconnected
var config array<float>					RegionDisconnectTimeChangePercent; // Percent contact or build outpost time changes when region is disconnected
var config array<int>					ContactIntelCost;
var config array<StrategyCostScalar>	ContactCostScalars;
var config int							LinkCostMax;				// The maximum link distance to take into account when calculating cost of contact
var config array<int>					OutpostSupplyCost;
var config array<int>					OutpostSupplyCostIncrease; // Cost increase per outpost built
var config array<StrategyCostScalar>	OutpostCostScalars;
var config array<float>					OutpostSupplyScalar;		// Building an outpost increases supply drop by X
var config int							TempUnlockedDuration; // hours
var config array<int>					MinMakeContactDays;
var config array<int>					MaxMakeContactDays;
var config array<int>					MinBuildHavenDays;
var config array<int>					MaxBuildHavenDays;

var config int MinStartingMissingPersons;
var config int MaxStartingMissingPersons;
var config int MissingPersonsPerControlPerHour;

var config float					DesiredDistanceBetweenMapItems;
var config float					MinDistanceBetweenMapItems;

const NUM_TILES = 3;

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
simulated function X2WorldRegionTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2WorldRegionTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
function OnCreation(X2WorldRegionTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

//---------------------------------------------------------------------------------------
/// Used in the construction of a start state, this method adds region state objects to the start state. The regions
/// are assigned a type based on the game play spec.
static function SetUpRegions(XComGameState StartState, optional bool bRecruitCreate=true, optional bool bRewardCreate=true)
{	
	local XComGameState_WorldRegion RegionState;
	local array<X2StrategyElementTemplate> RegionDefinitions;
	local int idx;

	//Create Regions	
	RegionDefinitions = GetMyTemplateManager().GetAllTemplatesOfClass(class'X2WorldRegionTemplate');

	for(idx = 0; idx < RegionDefinitions.Length; idx++)
	{
		RegionState = X2WorldRegionTemplate(RegionDefinitions[idx]).CreateInstanceFromTemplate(StartState);
		StartState.AddStateObject(RegionState);
		RegionState.Region = RegionState.GetReference();
		RegionState.ResistanceLevel = eResLevel_Locked;
		RegionState.SetStartingSupplyDrop();
		RegionState.AddHaven(StartState);
		// Init Contact Scan Hours
		RegionState.CurrentMinScanDays = default.MinMakeContactDays[`DIFFICULTYSETTING];
		RegionState.CurrentMaxScanDays = default.MaxMakeContactDays[`DIFFICULTYSETTING];
		RegionState.SetScanHoursRemaining(RegionState.CurrentMinScanDays, RegionState.CurrentMaxScanDays);
		// Init Missing Persons
		RegionState.NumMissingPersons = default.MinStartingMissingPersons + `SYNC_RAND_STATIC(default.MaxStartingMissingPersons - default.MinStartingMissingPersons + 1);
		class'X2StrategyGameRulesetDataStructures'.static.SetTime(RegionState.MissingPersonsStartTime, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
			class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);
	}
}

//---------------------------------------------------------------------------------------
function bool CanBeStartingRegion(XComGameState StartState)
{
	local XComGameState_WorldRegion RegionState;
	local int idx, Count;

	Count = 0;

	for(idx = 0; idx < LinkedRegions.Length; idx++)
	{
		RegionState = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(LinkedRegions[idx].ObjectID));

		if(RegionState != none && RegionState.Continent != Continent)
		{
			return false;
		}
		else
		{
			Count++;
		}
	}

	return (Count > 1);
}

//---------------------------------------------------------------------------------------
function bool IsStartingRegion()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return (self.GetReference() == XComHQ.StartingRegion);
}

//---------------------------------------------------------------------------------------
function SetStartingSupplyDrop()
{
	local int Diff;

	Diff = (GetMaxSupplyDrop() - GetMinSupplyDrop()) / default.SupplyDropMultiple;

	BaseSupplyDrop = GetMinSupplyDrop() + (`SYNC_RAND(Diff + 1)*default.SupplyDropMultiple);
}

//---------------------------------------------------------------------------------------
function int GetSupplyDropReward(optional bool bPotentialContact = false, optional bool bPotentialOutpost = false)
{
	local int SupplyDrop;
	
	SupplyDrop = 0;
	if(ResistanceLevel == eResLevel_Outpost)
	{
		SupplyDrop = BaseSupplyDrop + RetaliationSupplyDelta + POISupplyBonusDelta;
	}
	else if(bPotentialOutpost)
	{
		SupplyDrop = (Round(float(BaseSupplyDrop) * GetOutpostSupplyScalar()) + RetaliationSupplyDelta + POISupplyBonusDelta);
	}
	else if(ResistanceLevel == eResLevel_Contact || bPotentialContact)
	{
		SupplyDrop = BaseSupplyDrop + RetaliationSupplyDelta + POISupplyBonusDelta;
	}

	return SupplyDrop;
}

//---------------------------------------------------------------------------------------
// Helper for Hack Rewards to modify base supply value
function ModifyBaseSupplyDrop(int Bonus)
{
	BaseSupplyDrop = BaseSupplyDrop + Bonus;
}

//#############################################################################################
//----------------   LOCATION HANDLING   ------------------------------------------------------
//#############################################################################################

function Vector GetBorderIntersectionPoint(Vector Start, Vector End)
{
	local UIStrategyMapItem_Region MapItem;
	local XComGameState_GeoscapeEntity ThisEntity;
	local StaticMeshComponent MeshComp;
	local Vector Intersection, TranslatedVec;
	local int idx;


	ThisEntity = self;
	MapItem = UIStrategyMapItem_Region(`HQPRES.StrategyMap2D.GetMapItem(ThisEntity));

	if (MapItem != none)
	{
		for (idx = 0; idx < NUM_TILES; ++idx)
		{
			MeshComp = MapItem.RegionComponents[idx];
			TranslatedVec = Start - MeshComp.Bounds.Origin;
			if (TranslatedVec.X > 0 && TranslatedVec.X < MeshComp.Bounds.BoxExtent.X &&
				TranslatedVec.Y > 0 && TranslatedVec.Y < MeshComp.Bounds.BoxExtent.Y)
			{
				Intersection = class'Helpers'.static.GetRegionBorderIntersectionPoint(MeshComp, Start, End);
				break;
			}
		}
	}
	else
	{
		Intersection.x = GetMyTemplate().Bounds[0].fLeft + ((GetMyTemplate().Bounds[0].fRight - GetMyTemplate().Bounds[0].fLeft) / 2.0);
		Intersection.y = GetMyTemplate().Bounds[0].fTop + ((GetMyTemplate().Bounds[0].fBottom - GetMyTemplate().Bounds[0].fTop) / 2.0);
	}

	return Intersection;
}

//---------------------------------------------------------------------------------------
/// Utility method - returns a random point contained by the region
function Vector GetRandomLocationInRegion(optional bool bLandOnly = true, optional array<XComGameState_GeoscapeEntity> Entities, optional XComGameState_GeoscapeEntity NewEntity)
{
	local XComGameStateHistory History;
	local Vector RandomLocation;
	local Vector2D RandomLoc2D;
	local XComGameState_GeoscapeEntity EntityState, ThisEntity;
	local int Iterations;
	local UIStrategyMapItem_Region MapItem;
	local StaticMeshComponent MeshComp;
	local int RandomTri;

	RandomLocation.X = -1.0;  RandomLocation.Y = -1.0;  RandomLocation.Z = -1.0;

	ThisEntity = self;
	if (`HQGAME != none && `HQPRES != none)
		MapItem = UIStrategyMapItem_Region(`HQPRES.StrategyMap2D.GetMapItem(ThisEntity));

	if (MapItem != none)
	{
		MeshComp = MapItem.RegionComponents[0];

		RandomTri = MapItem.GetRandomTriangle();
		RandomLocation = class'Helpers'.static.GetRandomPointInRegionMesh(MeshComp, RandomTri, true);
		RandomLoc2D = `EARTH.ConvertWorldToEarth(RandomLocation);
		RandomLocation.X = RandomLoc2D.X;
		RandomLocation.Y = RandomLoc2D.Y;
		RandomLocation.Z = 0.0f;

		// Grab other entities in the continent (to avoid placing near them)
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_GeoscapeEntity', EntityState)
		{
			//First make sure that the entity is associated with this continent
			if (EntityState.Continent.ObjectID == Continent.ObjectID)
			{
				// Then ensure the entity is not the new addition, and has not already been saved
				if (EntityState.ObjectID != NewEntity.ObjectID && Entities.Find(EntityState) == INDEX_NONE)
				{
					Entities.AddItem(EntityState);
				}
			}
		}

		while ((bLandOnly && !class'X2StrategyGameRulesetDataStructures'.static.IsOnLand(RandomLoc2D))
			|| !class'X2StrategyGameRulesetDataStructures'.static.AvoidOverlapWithTooltipBounds(RandomLocation, Entities, NewEntity)
			|| ((Iterations < 100 && !class'X2StrategyGameRulesetDataStructures'.static.MinDistanceFromOtherItems(RandomLocation, Entities, default.DesiredDistanceBetweenMapItems))
			|| (Iterations >= 100 && Iterations < 500 && !class'X2StrategyGameRulesetDataStructures'.static.MinDistanceFromOtherItems(RandomLocation, Entities, default.MinDistanceBetweenMapItems))))
		{
			RandomTri = MapItem.GetRandomTriangle();
			RandomLocation = class'Helpers'.static.GetRandomPointInRegionMesh(MeshComp, RandomTri, true);
			RandomLoc2D = `EARTH.ConvertWorldToEarth(RandomLocation);
			RandomLocation.X = RandomLoc2D.X;
			RandomLocation.Y = RandomLoc2D.Y;
			RandomLocation.Z = 0.0f;

			++Iterations;
		}
	}

	return RandomLocation;
}

//---------------------------------------------------------------------------------------
function Vector2D GetRandom2DLocationInRegion(optional bool bLandOnly = true)
{
	local Vector RandomLocation;
	local Vector2D RandomLoc2D;

	RandomLocation = GetRandomLocationInRegion(bLandOnly);
	RandomLoc2D.x = RandomLocation.x;
	RandomLoc2D.y = RandomLocation.y;

	return RandomLoc2D;
}

//---------------------------------------------------------------------------------------
function bool InRegion(Vector2D v2Loc)
{
	local UIStrategyMapItem_Region MapItem;
	local XComGameState_GeoscapeEntity ThisEntity;
	local StaticMeshComponent MeshComp;
	local int idx;
	local Vector v3Loc;
	local bool bFoundInRegion;

	bFoundInRegion = false;
	ThisEntity = self;

	if (`HQGAME != none && `HQPRES != none)
		MapItem = UIStrategyMapItem_Region(`HQPRES.StrategyMap2D.GetMapItem(ThisEntity));

	if (MapItem != none)
	{
		v3Loc = `EARTH.ConvertEarthToWorld(v2Loc);
		for (idx = 0; idx < NUM_TILES; ++idx)
		{
			MeshComp = MapItem.RegionComponents[idx];
			if (class'Helpers'.static.IsInRegion(MeshComp, v3Loc, true))
			{
				bFoundInRegion = true;
				break;
			}
		}
	}

	return bFoundInRegion;
}

//---------------------------------------------------------------------------------------
function XComGameState_Haven GetHaven()
{
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	return XComGameState_Haven(History.GetGameStateForObjectID(Haven.ObjectID));
}

//---------------------------------------------------------------------------------------
function MakeContactETA(out int MinDays, out int MaxDays)
{
	MinDays = CurrentMinScanDays;
	MaxDays = CurrentMaxScanDays;
}

//---------------------------------------------------------------------------------------
function BuildHavenETA(out int MinDays, out int MaxDays)
{
	MinDays = CurrentMinScanDays;
	MaxDays = CurrentMaxScanDays;
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################


// THIS FUNCTION SHOULD RETURN TRUE IN ALL THE SAME CASES AS Update
function bool ShouldUpdate( )
{
	local UIStrategyMap StrategyMap;
	StrategyMap = `HQPRES.StrategyMap2D;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass( class'UIAlert' ))
	{
		if (bUpdateShortestPathsToMissions)
		{
			return true;
		}

		// check for end of temporary unlocked state
		if (ResistanceLevel == eResLevel_Unlocked && bTemporarilyUnlocked && class'X2StrategyGameRulesetDataStructures'.static.LessThan( TempUnlockedEndTime, `STRATEGYRULES.GameTime ))
		{
			return true;
		}

		// Check if making contact is complete
		if (bCanScanForContact && IsScanComplete( ))
		{
			return true;
		}

		// Check if building outpost is complete
		if (bCanScanForOutpost && IsScanComplete( ))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// IF ADDING NEW CASES WHERE bModified = true, UPDATE FUNCTION ShouldUpdate ABOVE
function bool Update(XComGameState NewGameState)
{
	local UIStrategyMap StrategyMap;
	local bool bModified;

	StrategyMap = `HQPRES.StrategyMap2D;
	bModified = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (bUpdateShortestPathsToMissions)
		{
			UpdateShortestPathToMissions(NewGameState);
			bUpdateShortestPathsToMissions = false;
			bModified = true;
		}

		// check for end of temporary unlocked state
		if (ResistanceLevel == eResLevel_Unlocked && bTemporarilyUnlocked && class'X2StrategyGameRulesetDataStructures'.static.LessThan(TempUnlockedEndTime, `STRATEGYRULES.GameTime))
		{
			bTemporarilyUnlocked = false;
			SetResistanceLevel(NewGameState, eResLevel_Locked);
			bModified = true;
		}

		// Check if making contact is complete
		if (bCanScanForContact && IsScanComplete()) 
		{
			bCanScanForContact = false;
			SetResistanceLevel(NewGameState, eResLevel_Contact);
			bModified = true;
			bResLevelPopup = true;

			// Reset the scan timer to work for outposts
			CurrentMinScanDays = default.MinBuildHavenDays[`DIFFICULTYSETTING];
			CurrentMaxScanDays = default.MaxBuildHavenDays[`DIFFICULTYSETTING];
			ResetScan(CurrentMinScanDays, CurrentMaxScanDays);
			m_strScanButtonLabel = m_strOutpostScanButtonLabel;
		}

		// Check if building outpost is complete
		if (bCanScanForOutpost && IsScanComplete())
		{
			bCanScanForOutpost = false;
			SetResistanceLevel(NewGameState, eResLevel_Outpost);
			bModified = true;
			bResLevelPopup = true;
		}
	}

	return bModified;
}

//#############################################################################################
//----------------   RESISTANCE LEVEL   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function SetResistanceLevel(XComGameState NewGameState, EResistanceLevelType NewResLevel)
{
	local XComGameState_Continent ContinentState;
	local EResistanceLevelType OldResLevel;
	local bool bHadBonus;

	OldResLevel = ResistanceLevel;
	
	if(OldResLevel != NewResLevel)
	{
		ResistanceLevel = NewResLevel;
		HandleResistanceLevelChange(NewGameState, NewResLevel, OldResLevel);

		ContinentState = XComGameState_Continent(NewGameState.GetGameStateForObjectID(Continent.ObjectID));

		if(ContinentState == none)
		{
			ContinentState = XComGameState_Continent(NewGameState.CreateStateObject(class'XComGameState_Continent', Continent.ObjectID));
			NewGameState.AddStateObject(ContinentState);
		}

		bHadBonus = ContinentState.bContinentBonusActive;
		ContinentState.HandleRegionResistanceLevelChange(NewGameState);
		if( !bHadBonus && ContinentState.bContinentBonusActive )
		{
			bContinentBonusPopup = true;
		}
	}
}

//---------------------------------------------------------------------------------------
function ModifyResistanceLevel(XComGameState NewGameState, int Delta)
{
	local EResistanceLevelType NewResLevel;
	local int iResLevel;

	if(!IsStartingRegion())
	{
		iResLevel = ResistanceLevel + Delta;
		NewResLevel = EResistanceLevelType(Clamp(iResLevel, eResLevel_Unlocked, eResLevel_Outpost));
		SetResistanceLevel(NewGameState, NewResLevel);
	}
}

//---------------------------------------------------------------------------------------
function HandleResistanceLevelChange(XComGameState NewGameState, EResistanceLevelType NewResLevel, EResistanceLevelType OldResLevel)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local ETimeOfDay TimeOfDayValue;
	local string Biome, TimeOfDay;
	local name ContactEvent;
	
	History = `XCOMHISTORY;

	// Mark appropriate missions as available if you've made contact
	if(HaveMadeContact())
	{
		if(!IsStartingRegion())
		{
			if(NewResLevel == eResLevel_Contact)
			{
				Biome = class'X2StrategyGameRulesetDataStructures'.static.GetBiome(Get2DLocation());
				
				TimeOfDayValue = class'X2StrategyGameRulesetDataStructures'.static.GetTimeOfDay(`STRATEGYRULES.GameTime);
				switch (TimeOfDayValue)
				{
				case eTimeOfDay_Noon:
					TimeOfDay = "Day";
					break;
				case eTimeOfDay_Dawn:
				case eTimeOfDay_Dusk:
				case eTimeofDay_Sunset:
					TimeOfDay = "Sunset";
					break;
				case eTimeOfDay_Night:
					TimeOfDay = "Night";
					break;
				}

				ContactEvent = name("RegionContacted_" $ Biome $ "_" $ TimeOfDay);

				`XEVENTMGR.TriggerEvent(ContactEvent, , , NewGameState);
				`XEVENTMGR.TriggerEvent('RegionContacted', , , NewGameState); // Need this event to fire for the achievement
			}
			else if(NewResLevel == eResLevel_Outpost)
			{
				`XEVENTMGR.TriggerEvent('RegionBuiltOutpost', , , NewGameState);
			}
		}

		foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.Region == self.GetReference() && MissionState.bNotAtThreshold)
			{
				MissionState.bNotAtThreshold = false;
			}
		}
			
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(XComGameState_MissionSite(NewGameState.GetGameStateForObjectID(MissionState.ObjectID)) == none &&
			   MissionState.Region == self.GetReference() && MissionState.bNotAtThreshold)
			{
				MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
				NewGameState.AddStateObject(MissionState);
				MissionState.bNotAtThreshold = false;

				if(MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite')
				{
					bBlockContactEventTrigger = true;
					`XEVENTMGR.TriggerEvent('OnBlacksiteContacted', , , NewGameState);
				}
				else if (MissionState.GetMissionSource().DataName == 'MissionSource_Forge' && MissionState.Available)
				{
					bBlockContactEventTrigger = true;
					`XEVENTMGR.TriggerEvent('OnForgeContacted', , , NewGameState);
				}
				else if (MissionState.GetMissionSource().DataName == 'MissionSource_PsiGate' && MissionState.Available)
				{
					bBlockContactEventTrigger = true;
					`XEVENTMGR.TriggerEvent('OnPsiGateContacted', , , NewGameState);
				}
			}
		}

		bTemporarilyUnlocked = false;
		bCanScanForContact = false;
	}

	// Adjust outpost scanning flag
	if(NewResLevel < eResLevel_Contact)
	{
		bCanScanForOutpost = false;
	}

	// Unlock adjacent regions when we make contact
	if( OldResLevel < eResLevel_Contact && NewResLevel >= eResLevel_Contact )
	{
		// If this is start start, unlock the regions next to ResHQ. Otherwise skip, they will be unlocked on popup callback
		if (NewGameState.GetContext().IsStartState())
			UnlockLinkedRegions(NewGameState);
		else // Only record the resistance activity if this is not the start state
			class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_RegionsContacted');
	}

	if( OldResLevel < eResLevel_Unlocked && NewResLevel == eResLevel_Unlocked )
	{
		if( !IsFirstUnlock(NewGameState) ) // Don't display unlocked popup for the first regions unlocked
		{
			bUnlockedPopup = true;
		}
	}

	// Lock adjacent regions if we lose contact
	if(OldResLevel >= eResLevel_Contact && NewResLevel < eResLevel_Contact)
	{
		LockLinkedRegions(NewGameState);

		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(XComGameState_MissionSite(NewGameState.GetGameStateForObjectID(MissionState.ObjectID)) == none &&
			   MissionState.Region == self.GetReference() && !MissionState.bNotAtThreshold && MissionState.Source != 'MissionSource_Broadcast')
			{
				MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
				NewGameState.AddStateObject(MissionState);
				MissionState.bNotAtThreshold = true;
			}
		}
	}

	// Supply amounts change based on resistance level, add/remove outpost or contact
	if( OldResLevel <= eResLevel_Contact && NewResLevel == eResLevel_Outpost )
	{
		BaseSupplyDrop *= GetOutpostSupplyScalar();
		bCanScanForOutpost = false;
		
		// Only record the resistance activity if this is not the start state
		if (!NewGameState.GetContext().IsStartState())
			class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_OutpostsBuilt');
	}
	else if( OldResLevel == eResLevel_Outpost && NewResLevel <= eResLevel_Contact )
	{
		//RemoveHaven(NewGameState);
		BaseSupplyDrop /= GetOutpostSupplyScalar();

		// Reset the scan timer to rebuild the outpost
		CurrentMinScanDays = default.MinBuildHavenDays[`DIFFICULTYSETTING] * GetRegionDisconnectTimeChangePercent();
		CurrentMaxScanDays = default.MaxBuildHavenDays[`DIFFICULTYSETTING] * GetRegionDisconnectTimeChangePercent();
		ResetScan(CurrentMinScanDays, CurrentMaxScanDays);
		m_strScanButtonLabel = default.m_strOutpostScanButtonLabel;
	}
	else if (OldResLevel == eResLevel_Contact && NewResLevel < eResLevel_Contact)
	{
		// Reset the scan timer to make contact again
		CurrentMinScanDays = default.MinMakeContactDays[`DIFFICULTYSETTING] * GetRegionDisconnectTimeChangePercent();
		CurrentMaxScanDays = default.MaxMakeContactDays[`DIFFICULTYSETTING] * GetRegionDisconnectTimeChangePercent();
		ResetScan(CurrentMinScanDays, CurrentMaxScanDays);
		m_strScanButtonLabel = default.m_strScanButtonLabel;
		bScanForContactEventTriggered = false;
	}

	GetHaven().HandleResistanceLevelChange(NewGameState, NewResLevel, OldResLevel);

	// Update shortest paths to GP missions if the region lost or gained contact
	if (OldResLevel >= eResLevel_Contact || NewResLevel >= eResLevel_Contact)
	{
		bUpdateShortestPathsToMissions = true;
	}
}

//---------------------------------------------------------------------------------------
function UpdateShortestPathToMissions(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_WorldRegion> MissionRegions;

	History = `XCOMHISTORY;

	// First reset all of the regions which are currently on GP or Facility paths to be false
	foreach NewGameState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if (RegionState.bOnGPOrAlienFacilityPath)
		{
			RegionState.bOnGPOrAlienFacilityPath = false;
		}

		if (RegionState.HasAlienFacilityOrGoldenPathMission())
		{
			MissionRegions.AddItem(RegionState);
		}
	}

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if (XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(RegionState.ObjectID)) == none)
		{
			if (RegionState.bOnGPOrAlienFacilityPath)
			{
				RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
				NewGameState.AddStateObject(RegionState);
				RegionState.bOnGPOrAlienFacilityPath = false;
			}

			if (RegionState.HasAlienFacilityOrGoldenPathMission())
			{
				MissionRegions.AddItem(RegionState);
			}
		}
	}

	// Then take all of the regions which have GP or facility missions and recalculate their shortest paths
	foreach MissionRegions(RegionState)
	{
		RegionState.SetShortestPathToContactRegion(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function bool IsFirstUnlock(XComGameState NewGameState)
{
	local StateObjectReference NeighborRegionRef;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ(true /* AllowNull */);

	foreach LinkedRegions(NeighborRegionRef)
	{
		// If this region is neighbors with the starting region, then this region is one of the first unlocks
		if( NeighborRegionRef == XComHQ.StartingRegion )
			return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UnlockLinkedRegions(XComGameState NewGameState)
{
	local XComGameState_WorldRegion LinkedRegion;
	local StateObjectReference RegionRef;
	local bool bPlayedNarrative;

	foreach LinkedRegions(RegionRef)
	{
		LinkedRegion = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(RegionRef.ObjectID));

		if(LinkedRegion == none)
		{
			LinkedRegion = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionRef.ObjectID));
			NewGameState.AddStateObject(LinkedRegion);
		}

		if (LinkedRegion.ResistanceLevel == eResLevel_Locked && !bPlayedNarrative && `HQGAME != none)
		{
			`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.AvengerAI_Support_Regions_Available');
			bPlayedNarrative = true;
		}

		LinkedRegion.Unlock(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function LockLinkedRegions(XComGameState NewGameState)
{
	local XComGameState_WorldRegion LinkedRegion;
	local StateObjectReference RegionRef;
	
	foreach LinkedRegions(RegionRef)
	{
		LinkedRegion = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(RegionRef.ObjectID));

		if(LinkedRegion == none)
		{
			LinkedRegion = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionRef.ObjectID));
			NewGameState.AddStateObject(LinkedRegion);
		}

		LinkedRegion.Lock(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function Unlock(XComGameState NewGameState, optional int iHoursUnlocked = -1)
{
	if(ResistanceLevel == eResLevel_Locked )
	{
		SetResistanceLevel(NewGameState, eResLevel_Unlocked);

		if(iHoursUnlocked > 0)
		{
			bTemporarilyUnlocked = true;
			bTempUnlockedPopup = true;
			TempUnlockedEndTime = GetCurrentTime();
			class'X2StrategyGameRulesetDataStructures'.static.AddHours(TempUnlockedEndTime, iHoursUnlocked);
		}
	}
}

//---------------------------------------------------------------------------------------
function Lock(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion LinkedRegion;
	local StateObjectReference RegionRef;

	History = `XCOMHISTORY;

	if(ResistanceLevel == eResLevel_Unlocked && !bCanScanForContact)
	{
		foreach LinkedRegions(RegionRef)
		{
			LinkedRegion = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(RegionRef.ObjectID));

			if(LinkedRegion == none)
			{
				LinkedRegion = XComGameState_WorldRegion(History.GetGameStateForObjectID(RegionRef.ObjectID));
			}

			if(LinkedRegion.HaveMadeContact())
			{
				return;
			}
		}

		SetResistanceLevel(NewGameState, eResLevel_Locked);
	}
}

//---------------------------------------------------------------------------------------
function bool HaveUnlocked()
{
	return (ResistanceLevel >= eResLevel_Unlocked);
}

//---------------------------------------------------------------------------------------
function bool HaveMadeContact()
{
	return (ResistanceLevel == eResLevel_Contact || ResistanceLevel == eResLevel_Outpost);
}

//---------------------------------------------------------------------------------------
function AddHaven(XComGameState NewGameState)
{
	local XComGameState_Haven HavenState;
	local StateObjectReference EmptyRef;

	if(Haven == EmptyRef)
	{
		HavenState = XComGameState_Haven(NewGameState.CreateStateObject(class'XComGameState_Haven'));
		NewGameState.AddStateObject(HavenState);
		HavenState.Region = self.GetReference();
		Haven = HavenState.GetReference();
	}
}

//---------------------------------------------------------------------------------------
function RemoveHaven(XComGameState NewGameState)
{
	local StateObjectReference EmptyRef;

	NewGameState.RemoveStateObject(Haven.ObjectID);
	Haven = EmptyRef;
}

//#############################################################################################
//----------------   MISSING PERSONS   --------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function UpdateMissingPersons()
{
	local int HourDiff;

	HourDiff = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(GetCurrentTime(), MissingPersonsStartTime);
	NumMissingPersons += (HourDiff*MissingPersonsPerHour);
	NumMissingPersonsThisMonth += (HourDiff*MissingPersonsPerHour);
	MissingPersonsStartTime = GetCurrentTime();

	UpdateMissingPersonsPerHour();
}

//---------------------------------------------------------------------------------------
function UpdateMissingPersonsPerHour()
{
	MissingPersonsPerHour = (default.MissingPersonsPerControlPerHour);
}

//---------------------------------------------------------------------------------------
function int GetNumMissingPersons()
{
	local int HourDiff;

	HourDiff = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(GetCurrentTime(), MissingPersonsStartTime);
	return (NumMissingPersons + (HourDiff*MissingPersonsPerHour));
}

//---------------------------------------------------------------------------------------
function int GetNumMissingPersonsThisMonth()
{
	local int HourDiff;

	HourDiff = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(GetCurrentTime(), MissingPersonsStartTime);
	return (NumMissingPersonsThisMonth + (HourDiff*MissingPersonsPerHour));
}

//#############################################################################################
//----------------   GEOSCAPE ENTITY IMPLEMENTATION   -----------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function string GetDisplayName()
{
	return GetMyTemplate().DisplayName;
}

simulated function string GetUIButtonTooltipTitle()
{
	return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetDisplayName());
}

simulated function string GetUIButtonTooltipBody()
{
	local UIStrategyMapItem_Region MapItem;
	local string TooltipStr, StatusStr, ScanTimeValue, ScanTimeLabel;
	local int DaysRemaining;

	MapItem = UIStrategyMapItem_Region(`HQPRES.StrategyMap2D.GetMapItem(self));
	if (bCanScanForContact)
		StatusStr = MapItem.m_strScanForIntelLabel;
	else if (bCanScanForOutpost)
		StatusStr = MapItem.m_strScanForOutpostLabel;

	DaysRemaining = GetNumScanDaysRemaining();
	ScanTimeValue = string(DaysRemaining);
	ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
	TooltipStr = StatusStr $ ":" @ ScanTimeValue @ ScanTimeLabel @ m_strRemainingLabel;

	return TooltipStr;
}

function bool HasTooltipBounds()
{
	return true;
}

//---------------------------------------------------------------------------------------
function bool CanBeScanned()
{
	return ((!HaveMadeContact() && bCanScanForContact) ||
			(ResistanceLevel == eResLevel_Contact && bCanScanForOutpost));
}

//---------------------------------------------------------------------------------------
function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_Region';
}

//---------------------------------------------------------------------------------------
function string GetUIWidgetFlashLibraryName()
{
	return "MI_region";
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
	local UIStrategyMap kMap;

	if(!ResistanceActive())
	{
		return false;
	}

	kMap = UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));

	if(kMap != none && kMap.m_eUIState == eSMS_Resistance)
	{
		return true;
	}

	if (HasAlienFacilityOrGoldenPathMission() || bOnGPOrAlienFacilityPath)
	{
		return true;
	}

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.IsContactResearched())
	{
		return (ResistanceLevel >= eResLevel_Unlocked);
	}
	else
	{
		return (HaveMadeContact());
	}
}

//---------------------------------------------------------------------------------------
function bool HasMissionInRegion()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	if (AlienFacility.ObjectID != 0)
	{
		return true;
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.Region == GetReference() && MissionState.Available)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasAlienFacilityOrGoldenPathMission()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	if(AlienFacility.ObjectID != 0)
	{
		return true;
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Region == GetReference() && MissionState.Available && MissionState.GetMissionSource().bGoldenPath)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;
	//local XComGameState_HeadquartersXCom XComHQ;
	local XComHeadquartersCheatManager CheatMgr;
	local bool bSuccess;

	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Update Regions" );

		RegionState = XComGameState_WorldRegion( NewGameState.CreateStateObject( class'XComGameState_WorldRegion', ObjectID ) );
		NewGameState.AddStateObject( RegionState );

		bSuccess = RegionState.Update(NewGameState);
		`assert( bSuccess ); // why did Update & ShouldUpdate return different bools?

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}

	if( bControlPopup )
	{
		AdventControlPopup();
	}
	else if( bResLevelPopup )
	{
		CheatMgr = XComHeadquartersCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);

		if(CheatMgr != none && CheatMgr.bGamesComDemo)
		{
			CheatMgr.SpawnPOI(false, 2, 'POI_Gamescom', 0.478f, 0.222f);
		}

		ResistanceLevelPopup();
	}
	else if( bTempUnlockedPopup )
	{
		UnlockPopup();
	}
	else if( bUnlockedPopup)
	{
		//if(XComHQ.bNeedsNewRegionsHelp)
		//{
			//`HQPRES.UIHelp_NewRegions();
		//}
		//else
		//{
		if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M11_IntroToResComms') != eObjectiveState_InProgress)
		{
			UnlockPopup();
		}
		//}
	}

	if(bDoomFactoryPopup)
	{
		AlienFacilityPopup();
	}
}

//---------------------------------------------------------------------------------------
protected function bool CanInteract()
{
	return (CanBeScanned() || HasMissionInRegion());
}

//---------------------------------------------------------------------------------------
protected function bool DisplaySelectionPrompt()
{
	//`HQPRES.UIResistance(self);


	/*if( bMakingContact || bBuildingOutpost )
	{
		// Can't interact with the Resistance when it is changing states
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
	}
	else
	{
		
	}*/

	
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// if click on a not current continent, display the lift off pop
	if(XComHQ.Region != GetReference() && (CanBeScanned() || XComHQ.CrossContinentMission.ObjectID != 0))
	{
		return false;
	}
	
	return true;
}

//---------------------------------------------------------------------------------------
function DestinationReached()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_MissionSite MissionState;
	local StateObjectReference EmptyRef;
	local XComGameState NewGameState;

	super.DestinationReached();

	// Do we need to fly to a mission right away
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.CrossContinentMission.ObjectID));

	if(MissionState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear cross continent mission reference");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.CrossContinentMission = EmptyRef;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		
		MissionState.ConfirmSelection();
	}
}

//---------------------------------------------------------------------------------------
simulated function UnlockedCallback(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Region Unlocked");
	`XEVENTMGR.TriggerEvent('RegionUnlocked', , , NewGameState);

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.Region == self.GetReference())
		{
			if (MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite')
			{
				`XEVENTMGR.TriggerEvent('BlacksiteRegionUnlocked', , , NewGameState);
			}
		}
	}

	`GAMERULES.SubmitGameState(NewGameState);

	`GAME.GetGeoscape().Resume();
}

//---------------------------------------------------------------------------------------
simulated function MakeContactCallback(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local StrategyCost ContactCost;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (eAction == eUIAction_Accept)
	{
		ContactCost = CalcContactCost();

		if (XComHQ.CanAffordAllStrategyCosts(ContactCost, ContactCostScalars))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Initiate Making Contact");
			RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', self.ObjectID));
			NewGameState.AddStateObject(RegionState);
			RegionState.bCanScanForContact = true;
			
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			NewGameState.AddStateObject(XComHQ);

			// Handle Signal Flare
			if (XComHQ.bFreeContact)
			{
				XComHQ.bFreeContact = false;
				XComHQ.bUsedFreeContact = true;
			}
			else
			{
				// Handle Reduced Contact Reward
				if (XComHQ.bReducedContact)
				{
					XComHQ.bReducedContact = false;
					XComHQ.ReducedContactModifier = 0.0;
				}

				XComHQ.PayStrategyCost(NewGameState, ContactCost, ContactCostScalars);
			}

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			
			`HQPRES.m_kAvengerHUD.UpdateResources();
			
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_PopularSupportThreshold");
			class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
			
			if (XComHQ.GetRemainingContactCapacity() == 0 && XComHQ.HasRegionsAvailableForContact())
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Warning No Comms");
				`XEVENTMGR.TriggerEvent('WarningNoComms', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}

			// Avenger should fly to the region to make contact if it isn't already there
			if (XComHQ.CurrentLocation.ObjectID != ObjectID)
			{
				XComHQ.SetPendingPointOfTravel(RegionState);
			}
		}
		else
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		}
	}
}

//---------------------------------------------------------------------------------------
simulated function BuildOutpostCallback(eUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local StrategyCost OutpostCost;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (eAction == eUIAction_Accept)
	{
		OutpostCost = CalcOutpostCost();

		if (XComHQ.CanAffordAllStrategyCosts(OutpostCost, OutpostCostScalars))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Initiate Building Outpost");
			RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', self.ObjectID));
			NewGameState.AddStateObject(RegionState);
			RegionState.bCanScanForOutpost = true;

			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			NewGameState.AddStateObject(XComHQ);
			XComHQ.PayStrategyCost(NewGameState, OutpostCost, OutpostCostScalars);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			`HQPRES.m_kAvengerHUD.UpdateResources();

			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_PopularSupportThreshold");

			// Avenger should fly to the region to build the outpost if it isn't already there
			if (XComHQ.CurrentLocation.ObjectID != ObjectID)
			{
				XComHQ.SetPendingPointOfTravel(RegionState);
			}
		}
		else
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_MenuClickNegative");
		}
	}
}

//---------------------------------------------------------------------------------------
function StrategyCost CalcContactCost()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local StrategyCost ContactCost;
	local ArtifactCost IntelCost;
	local int iNumLinks;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	IntelCost.ItemTemplateName = 'Intel';

	if(XComHQ.bFreeContact)
	{
		IntelCost.Quantity = 0;
	}
	else
	{
		iNumLinks = GetLinkCountToOutpost();

		// If no outpost exists
		if( iNumLinks == -1 )
		{
			iNumLinks = default.LinkCostMax;
		}

		IntelCost.Quantity = ContactIntelCost[`DIFFICULTYSETTING] * iNumLinks;

		if (XComHQ.bReducedContact)
		{
			IntelCost.Quantity -= (IntelCost.Quantity * XComHQ.ReducedContactModifier);
		}
	}

	ContactCost.ResourceCosts.AddItem(IntelCost);

	return ContactCost;
}

//---------------------------------------------------------------------------------------
function int GetContactCostAmount()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int iNumLinks, ContactCost;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();	
	if (XComHQ.bFreeContact)
	{
		ContactCost = 0;
	}
	else
	{
		iNumLinks = GetLinkCountToOutpost();

		// If no outpost exists
		if (iNumLinks == -1)
		{
			iNumLinks = default.LinkCostMax;
		}

		ContactCost = ContactIntelCost[`DIFFICULTYSETTING] * iNumLinks;

		if (XComHQ.bReducedContact)
		{
			ContactCost -= (ContactCost * XComHQ.ReducedContactModifier);
		}
	}

	return ContactCost;
}

//---------------------------------------------------------------------------------------
// Helper for Hack Rewards to modify contact cost
function ModifyContactCost(float Modifier)
{
	ContactIntelCost[`DIFFICULTYSETTING] = float(ContactIntelCost[`DIFFICULTYSETTING]) * Modifier;
}

//---------------------------------------------------------------------------------------
function StrategyCost CalcOutpostCost()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local StrategyCost OutpostCost;
	local ArtifactCost SuppliesCost;
	local int SupplyCostTotal;
	
	History = `XCOMHISTORY;
	SuppliesCost.ItemTemplateName = 'Supplies';
	SupplyCostTotal = default.OutpostSupplyCost[`DIFFICULTYSETTING];

	// Add X Supplies for every outpost and outpost being built
	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(!RegionState.IsStartingRegion() && 
		   (RegionState.ResistanceLevel >= eResLevel_Outpost || RegionState.bCanScanForOutpost))
		{
			SupplyCostTotal += default.OutpostSupplyCostIncrease[`DIFFICULTYSETTING];
		}
	}

	SuppliesCost.Quantity = SupplyCostTotal;
	OutpostCost.ResourceCosts.AddItem(SuppliesCost);

	return OutpostCost;
}

//---------------------------------------------------------------------------------------
function int GetLinkCountToOutpost()
{
	return GetLinkCountToMinResistanceLevel(eResLevel_Outpost);
}

//---------------------------------------------------------------------------------------
function int GetLinkCountToMinResistanceLevel( EResistanceLevelType InResistanceLevel )
{
	local array<XComGameState_WorldRegion> arrOutpostRegions;
	local XComGameState_WorldRegion ClosestOutpostRegion;
	local XComGameState_WorldRegion TestRegion;

	if( ResistanceLevel >= InResistanceLevel )
	{
		return 0;
	}

	// Find all the outposts
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_WorldRegion', TestRegion)
	{
		if( TestRegion.ResistanceLevel >= InResistanceLevel )
		{
			arrOutpostRegions.AddItem(TestRegion);
		}
	}

	if( arrOutpostRegions.Length == 0 )
	{
		return -1;
	}

	ClosestOutpostRegion = none;
	return FindClosestRegion(arrOutpostRegions, ClosestOutpostRegion);
}

// Breadth first search to an array of regions along links
function int FindClosestRegion(array<XComGameState_WorldRegion> arrPossibleRegions, out XComGameState_WorldRegion ClosestRegion)
{
	local array<XComGameState_WorldRegion> arrSearchRegions;
	local array<int> arrSearchDist;
	local array<XComGameState_WorldRegion> arrVisited;
	//local array<int> arrVisitedDist;
	local XComGameState_WorldRegion TestRegion, ChildRegion;
	local StateObjectReference StateRef;
	local int iTestDist;


	arrSearchRegions.AddItem(self);
	arrSearchDist.AddItem(0);

	while( arrSearchRegions.Length > 0 )
	{
		// Pop nearest region off queue
		TestRegion = arrSearchRegions[0];
		iTestDist = arrSearchDist[0];
		arrSearchRegions.Remove(0, 1);
		arrSearchDist.Remove(0, 1);

		// Did we find a match? 
		if( arrPossibleRegions.Find(TestRegion) != -1 )
		{
			ClosestRegion = TestRegion;
			return iTestDist;
		}

		arrVisited.AddItem(TestRegion);
		//arrVisitedDist.AddItem(iTestDist);

		foreach TestRegion.LinkedRegions(StateRef)
		{
			ChildRegion = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(StateRef.ObjectID));
			if( arrVisited.Find(ChildRegion) == -1 )
			{
				arrSearchRegions.AddItem(ChildRegion);
				arrSearchDist.AddItem(iTestDist+1);
			}
		}
	}

	ClosestRegion = none;
	return -1;
}

//---------------------------------------------------------------------------------------
function SetShortestPathToContactRegion(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local array<XComGameState_WorldRegion> arrEndRegions, arrShortestPath;
	local XComGameState_WorldRegion TestRegion, NewRegion;

	History = `XCOMHISTORY;

	if (ResistanceLevel < eResLevel_Contact)
	{
		// Find all the contacted regions
		foreach History.IterateByClassType(class'XComGameState_WorldRegion', TestRegion)
		{
			if (TestRegion.ResistanceLevel >= eResLevel_Contact)
			{
				arrEndRegions.AddItem(TestRegion);
			}
		}

		if (arrEndRegions.Length > 0)
		{
			arrShortestPath = FindShortestPathToRegions(arrEndRegions);
		}
	}

	foreach arrShortestPath(TestRegion)
	{
		if (TestRegion.ObjectID != ObjectID) // ignore self for now
		{
			NewRegion = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', TestRegion.ObjectID));
			NewGameState.AddStateObject(NewRegion);
			NewRegion.bOnGPOrAlienFacilityPath = true;
		}
	}

	bOnGPOrAlienFacilityPath = true; // Make sure the region containing the mission gets flagged
}

// Breadth first search to an array of regions along links
function array<XComGameState_WorldRegion> FindShortestPathToRegions(array<XComGameState_WorldRegion> arrPossibleRegions)
{
	local XComGameStateHistory History;
	local array<RegionPath> arrSearchPaths, arrSolutionPaths;
	local XComGameState_WorldRegion TestRegion, ChildRegion;
	local RegionPath StartPath, TestPath, NewPath;
	local StateObjectReference StateRef;

	History = `XCOMHISTORY;

	StartPath.Regions.AddItem(self);
	StartPath.Cost = 0;

	arrSearchPaths.AddItem(StartPath);
	
	while (arrSearchPaths.Length > 0)
	{
		// Pop nearest region off queue
		TestPath = arrSearchPaths[0];
		TestRegion = TestPath.Regions[TestPath.Regions.Length - 1];
		arrSearchPaths.Remove(0, 1);

		// If the search has started testing region paths which are longer than a potential solution, break
		// We want the smallest cost between all paths with the fewest links. If we have a short solution, don't test longer ones.
		if (arrSolutionPaths.Length > 0 && TestPath.Regions.Length > arrSolutionPaths[0].Regions.Length)
		{
			break;
		}

		// Did we find a match?
		if (arrPossibleRegions.Find(TestRegion) != -1)
		{
			arrSolutionPaths.AddItem(TestPath);
			continue;
		}

		foreach TestRegion.LinkedRegions(StateRef)
		{
			ChildRegion = XComGameState_WorldRegion(History.GetGameStateForObjectID(StateRef.ObjectID));
			if (TestPath.Regions.Find(ChildRegion) == INDEX_NONE)
			{
				NewPath = TestPath;
				NewPath.Regions.AddItem(ChildRegion);

				if (!ChildRegion.HaveMadeContact())
					NewPath.Cost += ChildRegion.GetContactCostAmount();

				arrSearchPaths.AddItem(NewPath);
			}
		}
	}

	NewPath = StartPath; // Reset NewPath to match StartPath
	NewPath.Cost = -1; // Then use it to try and the lowest cost Best Path
	foreach arrSolutionPaths(TestPath)
	{
		if (NewPath.Cost == -1)
		{
			NewPath = TestPath;
		}
		else if (TestPath.Cost < NewPath.Cost)
		{
			NewPath = TestPath;
		}
	}

	return NewPath.Regions;
}

//---------------------------------------------------------------------------------------
simulated public function AlienFacilityPopup()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_MissionSite MissionState;
	local UIAlert kAlert;
	local float bDoomPercent;
	local bool bFirstFacility;
	local PendingDoom DoomPending;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Doom Factory Popup flag");
	RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', self.ObjectID));
	NewGameState.AddStateObject(RegionState);
	RegionState.bDoomFactoryPopup = false;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	bDoomPercent = (1.0 * AlienHQ.GetCurrentDoom()) / AlienHQ.GetMaxDoom();
	if (!AlienHQ.bHasHeardFacilityWarningAlmostDone && bDoomPercent >= 0.75)
	{
		AlienHQ.bHasHeardFacilityWarningAlmostDone = true;
		`XEVENTMGR.TriggerEvent('OnAlienFacilityPopupReallyBad', , , NewGameState);
	}
	else if (!AlienHQ.bHasHeardFacilityWarningHalfway && bDoomPercent >= 0.5)
	{
		AlienHQ.bHasHeardFacilityWarningHalfway = true;
		`XEVENTMGR.TriggerEvent('OnAlienFacilityPopupBad', , , NewGameState);
	}
	else if (!AlienHQ.bHasSeenFacility)
	{
		AlienHQ.bHasSeenFacility = true;
		bFirstFacility = true;
	}
	else
	{
		`XEVENTMGR.TriggerEvent('OnAlienFacilityPopup', , , NewGameState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(AlienFacility.ObjectID));

	// Don't show the popup for the first facility, we'll do a special camera pan instead
	if (!bFirstFacility)
	{
		`GAME.GetGeoscape().Pause();
		kAlert = `HQPRES.Spawn(class'UIAlert', `HQPRES);
		kAlert.eAlert = eAlert_AlienFacility;
		kAlert.Mission = MissionState;
		kAlert.fnCallback = `HQPRES.DoomAlertCB;
		kAlert.SoundToPlay = "GeoscapeFanfares_AlienFacility";
		`HQPRES.ScreenStack.Push(kAlert);
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add First Facility Pending doom");
		AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
		DoomPending.Doom = MissionState.Doom;
		AlienHQ.PendingDoomData.AddItem(DoomPending);
		AlienHQ.PendingDoomEvent = 'CameraAtAlienFacility';
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`HQPRES.DoomCameraPan(MissionState, false, true);
	}
}

function AdventControlPopup()
{
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;
	local UIAlert kAlert;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Advent Control Popup flag");
	RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', self.ObjectID));
	NewGameState.AddStateObject(RegionState);
	RegionState.bControlPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`GAME.GetGeoscape().Pause();

	kAlert = `HQPRES.Spawn(class'UIAlert', `HQPRES);
	kAlert.eAlert = eAlert_Control;
	kAlert.RegionRef = self.GetReference();
	kAlert.fnCallback = `HQPRES.GeoscapeAlertCB;
	kAlert.SoundToPlay = "GeoscapeAlerts_ADVENTControl";
	`HQPRES.ScreenStack.Push(kAlert);
}

function ResistanceLevelPopup()
{
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Haven HavenState;
	local UIAlert kAlert;
	local bool bContBonus;

	bContBonus = bContinentBonusPopup;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Advent Control Popup flag");
	RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', self.ObjectID));
	NewGameState.AddStateObject(RegionState);
	RegionState.bResLevelPopup = false;
	RegionState.bContinentBonusPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if( bContBonus )
	{
		`HQPRES.UIContinentBonus(Continent);
	}

	if( HaveMadeContact() )
	{
		`GAME.GetGeoscape().Pause();
		kAlert = `HQPRES.Spawn(class'UIAlert', `HQPRES);

		if( ResistanceLevel == eResLevel_Contact )
		{
			kAlert.eAlert = eAlert_ContactMade;
			kAlert.fnCallback = ContactMadeCB;
			kAlert.SoundToPlay = "GeoscapeAlerts_MakeContact";
		}
		else if( ResistanceLevel == eResLevel_Outpost )
		{
			HavenState = GetHaven();
			kAlert.eAlert = eAlert_OutpostBuilt;
			kAlert.fnCallback = HavenState.OutpostBuiltCB;
			kAlert.SoundToPlay = "GeoscapeAlerts_BuildOutpost";
		}

		kAlert.RegionRef = self.GetReference();
		`HQPRES.ScreenStack.Push(kAlert);
		
		if (!bBlockContactEventTrigger)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On Contact Or Outpost");
			`XEVENTMGR.TriggerEvent('OnContactOrOutpost', , , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
simulated function ContactMadeCB(EUIAction eAction, UIAlert AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (!XComHQ.bHasSeenSupplyDropReminder && XComHQ.IsSupplyDropAvailable())
	{
		`HQPRES.UISupplyDropReminder();
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Make contact CB - unlock linked regions");	
	UnlockLinkedRegions(NewGameState);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`GAME.GetGeoscape().Resume();
}

simulated function UnlockPopup()
{
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;
	local UIAlert kAlert;
	local bool bTempUnlock;

	bTempUnlock = bTempUnlockedPopup;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Unlock Popup flag");
	RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', self.ObjectID));
	NewGameState.AddStateObject(RegionState);
	RegionState.bTempUnlockedPopup = false;
	RegionState.bUnlockedPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`GAME.GetGeoscape().Pause();

	kAlert = `HQPRES.Spawn(class'UIAlert', `HQPRES);
	if( bTempUnlock )
	{
		kAlert.eAlert = eAlert_RegionUnlockedMission;
	}
	else
	{
		kAlert.eAlert = eAlert_RegionUnlocked;
	}
	kAlert.RegionRef = self.GetReference();
	kAlert.fnCallback = UnlockedCallback;
	kAlert.SoundToPlay = "Geoscape_POIReveal";
	`HQPRES.ScreenStack.Push(kAlert);
}

//---------------------------------------------------------------------------------------
simulated private function DefaultAcceptCallback(eUIAction eAction)
{
	InteractionComplete(false);
}

simulated function string GetUIButtonIcon()
{
	if(IsStartingRegion())
		return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_ResHQ";

	if(bCanScanForOutpost)
		return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Outpost";

	return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Region";
}

// If the player tries to go somewhere else while making contact, trigger this event
protected function OnInterruptionPopup()
{
	local XComGameState NewGameState;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Leaving Contact Site Without Scanning Event");
	`XEVENTMGR.TriggerEvent('LeaveContactWithoutScan', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

protected function bool CurrentlyInteracting()
{
	// If we can scan for contact and the avenger is landed here, then yes, we're interacting.
	return (bCanScanForContact && GetReference() == class'UIUtilities_Strategy'.static.GetXComHQ().CurrentLocation);
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetMinSupplyDrop()
{
	return default.MinSupplyDrop[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMaxSupplyDrop()
{
	return default.MaxSupplyDrop[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetOutpostSupplyScalar()
{
	return default.OutpostSupplyScalar[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function float GetRetaliationSuccessSupplyChangePercent()
{
	return default.RetaliationSuccessSupplyChangePercent[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function float GetRegionDisconnectSupplyChangePercent()
{
	return default.RegionDisconnectSupplyChangePercent[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function float GetRegionDisconnectTimeChangePercent()
{
	return default.RegionDisconnectTimeChangePercent[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
DefaultProperties
{   
}


