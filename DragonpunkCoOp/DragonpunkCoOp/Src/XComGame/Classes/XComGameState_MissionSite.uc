//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_MissionSite.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for a mission site on the world map
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_MissionSite extends XComGameState_GeoscapeEntity
	native(Core);

var() name Source;
var() bool Available;
var() bool Expiring;
var() TDateTime TimerStartDateTime;
var() TDateTime ExpirationDateTime;
var() float TimeUntilDespawn; // seconds
var() GeneratedMissionData GeneratedMission;
var() array<StateObjectReference> Rewards;
var() StateObjectReference POIToSpawn; // The POI which will be spawned if the mission is successful
var() bool bSpawnUFO; // If a UFO will be spawned when this mission is completed

var() int ManualPopSupportModifier;
var() int ManualAlertModifier;
var() int PostMissionPopSupport;
var() int PostMissionAlert;

var() bool bNotAtThreshold;
var() string FlavorText;
var() string SuccessText;
var() string PartialSuccessText;
var() string FailureText;
var() bool bBuilding;
var() bool bNeedsBuildCompletePopup;
var() bool bNeedsBuildStartPopup;
var() TDateTime BuildStartTime;
var() TDateTime BuildEndTime;
var String m_strShadowCount;
var String m_strShadowCrew;
var int ManualDifficultySetting;
var bool bUsePartialSuccessText;
var bool bHasSeenSkipPopup;
var bool bHasSeenLaunchMissionWarning;

// Doom Related variables
var() int Doom;
var() bool bMakesDoom;
var() bool bNeedsDoomPopup;
var float DoomToRemovePercent; // Some missions remove a percentage of their doom
var int FixedDoomToRemove; // Some missions remove a fixed amount of doom

// Dark Events (for GOps)
var StateObjectReference DarkEvent;

var private name TerrorSourceName;

// Intel Rewards
var() array<MissionIntelOption> IntelOptions;
var() array<MissionIntelOption> PurchasedIntelOptions;

var public localized String m_strEnemyUnknown;

//---------------------------------------------------------------------------------------
// Mission Pre-Selection information

struct native X2SelectedEncounterData
{
	// The Encounter Id to be used
	var() Name SelectedEncounterName;

	// The spawning info generated for this encounter
	var() PodSpawnInfo EncounterSpawnInfo;
};

struct native X2SelectedMissionData
{
	// The Alert Level for which this mission data is valid
	var() int AlertLevel;

	// The Force Level for which this mission data is valid
	var() int ForceLevel;

	// The name of the mission schedule which has been selected for this mission
	var() Name SelectedMissionScheduleName;

	// The list of encounters which have been selected for this mission
	var() array<X2SelectedEncounterData> SelectedEncounters;
};

// Mission data that has been selected for this Mission Site.
var() X2SelectedMissionData SelectedMissionData;


function bool CacheSelectedMissionData(int ForceLevel, int AlertLevel)
{
	local XComTacticalMissionManager TacticalMissionManager;
	local MissionSchedule SelectedMissionSchedule;
	local PrePlacedEncounterPair EncounterInfo;
	local ConfigurableEncounter Encounter;
	local X2SelectedEncounterData NewEncounter, EmptyEncounter;
	local XComAISpawnManager SpawnManager;
	local array<X2CharacterTemplate> SelectedCharacterTemplates;
	local float AlienLeaderWeight, AlienFollowerWeight;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local int LeaderForceLevelMod;

	if(SelectedMissionData.ForceLevel == ForceLevel && SelectedMissionData.AlertLevel == AlertLevel &&
	   SelectedMissionData.SelectedMissionScheduleName != '')
	{
		return false;
	}

	if( GeneratedMission.MissionID == ObjectID )
	{
		SelectedMissionData.ForceLevel = ForceLevel;
		SelectedMissionData.AlertLevel = AlertLevel;

		TacticalMissionManager = `TACTICALMISSIONMGR;
		SelectedMissionData.SelectedMissionScheduleName = TacticalMissionManager.ChooseMissionSchedule(self);

		TacticalMissionManager.GetMissionSchedule(SelectedMissionData.SelectedMissionScheduleName, SelectedMissionSchedule);

		// have to actually clear the previously selected encounters
		SelectedMissionData.SelectedEncounters.Remove(0, SelectedMissionData.SelectedEncounters.Length);

		SpawnManager = `SPAWNMGR;
		AlienLeaderWeight = 0.0;
		AlienFollowerWeight = 0.0;

		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		LeaderForceLevelMod = SpawnManager.GetLeaderForceLevelMod();

		foreach SelectedMissionSchedule.PrePlacedEncounters(EncounterInfo)
		{
			// if this pre-placed encounter depends on a tactical gameplay tag, and that tag is not present, the encounter group will not spawn
			if( EncounterInfo.IncludeTacticalTag != '' && XComHQ.TacticalGameplayTags.Find(EncounterInfo.IncludeTacticalTag) == INDEX_NONE )
			{
				continue;
			}

			// if this pre-placed encounter depends on not having a tactical gameplay tag, and that tag is present, the encounter group will not spawn
			if( EncounterInfo.ExcludeTacticalTag != '' && XComHQ.TacticalGameplayTags.Find(EncounterInfo.ExcludeTacticalTag) != INDEX_NONE )
			{
				continue;
			}

			TacticalMissionManager.GetConfigurableEncounter(EncounterInfo.EncounterID, Encounter, ForceLevel, AlertLevel, XComHQ);

			if( Encounter.EncounterID != '' )
			{
				NewEncounter = EmptyEncounter;

				NewEncounter.SelectedEncounterName = Encounter.EncounterID;

				// select the group members who will fill out this encounter group
				AlienLeaderWeight += SelectedMissionSchedule.AlienToAdventLeaderRatio;
				AlienFollowerWeight += SelectedMissionSchedule.AlienToAdventFollowerRatio;
				SpawnManager.SelectSpawnGroup(NewEncounter.EncounterSpawnInfo, GeneratedMission.Mission, Encounter, ForceLevel, AlertLevel, SelectedCharacterTemplates, AlienLeaderWeight, AlienFollowerWeight, LeaderForceLevelMod);

				NewEncounter.EncounterSpawnInfo.EncounterZoneWidth = EncounterInfo.EncounterZoneWidth;
				NewEncounter.EncounterSpawnInfo.EncounterZoneDepth = ((EncounterInfo.EncounterZoneDepthOverride >= 0.0) ? EncounterInfo.EncounterZoneDepthOverride : SelectedMissionSchedule.EncounterZonePatrolDepth);
				NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetFromLOP = EncounterInfo.EncounterZoneOffsetFromLOP;
				NewEncounter.EncounterSpawnInfo.EncounterZoneOffsetAlongLOP = EncounterInfo.EncounterZoneOffsetAlongLOP;

				NewEncounter.EncounterSpawnInfo.SpawnLocationActorTag = EncounterInfo.SpawnLocationActorTag;

				SelectedMissionData.SelectedEncounters.AddItem(NewEncounter);
			}
		}

		return true;
	}

	return false;
}

function GetShadowChamberMissionInfo(out int NumPreSpawnUnits, out array<X2CharacterTemplate> UnitTemplatesThatWillSpawn)
{
	local int EncounterIndex, CharacterIndex, UniqueTemplateIndex;
	local X2CharacterTemplate SelectedTemplate;
	local bool GroupAlreadyRepresented;
	local Name CharTemplateName;
	local X2CharacterTemplateManager CharTemplateManager;

	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	NumPreSpawnUnits = 0;
	UnitTemplatesThatWillSpawn.Length = 0;

	for( EncounterIndex = 0; EncounterIndex < SelectedMissionData.SelectedEncounters.Length; ++EncounterIndex )
	{
		for( CharacterIndex = 0; CharacterIndex < SelectedMissionData.SelectedEncounters[EncounterIndex].EncounterSpawnInfo.SelectedCharacterTemplateNames.Length; ++CharacterIndex )
		{
			CharTemplateName = SelectedMissionData.SelectedEncounters[EncounterIndex].EncounterSpawnInfo.SelectedCharacterTemplateNames[CharacterIndex];
			SelectedTemplate = CharTemplateManager.FindCharacterTemplate(CharTemplateName);

			if( !SelectedTemplate.bIsCivilian )
			{
				++NumPreSpawnUnits;
			}

			if( SelectedTemplate.CharacterGroupName != '' )
			{
				// add only 1 template per template group
				GroupAlreadyRepresented = false;
				for( UniqueTemplateIndex = 0; UniqueTemplateIndex < UnitTemplatesThatWillSpawn.Length; ++UniqueTemplateIndex )
				{
					if( UnitTemplatesThatWillSpawn[UniqueTemplateIndex].CharacterGroupName == SelectedTemplate.CharacterGroupName )
					{
						GroupAlreadyRepresented = true;
						break;
					}
				}

				if( !GroupAlreadyRepresented )
				{
					UnitTemplatesThatWillSpawn.AddItem(SelectedTemplate);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
// Set all relevant values for the mission and start expiration timer (if applicable)
function BuildMission(X2MissionSourceTemplate MissionSource, Vector2D v2Loc, StateObjectReference RegionRef, array<XComGameState_Reward> MissionRewards, optional bool bAvailable=true, optional bool bExpiring=false, optional int iHours=-1, optional int iSeconds=-1, optional bool bUseSpecifiedLevelSeed=false, optional int LevelSeedOverride=0, optional bool bSetMissionData=true)
{
	local int idx, DoomDiff;
	local XComGameState_WorldRegion localRegion;
	local XGParamTag ParamTag;
	local XComGameState_HeadquartersAlien AlienHQ;

	Source = MissionSource.DataName;
	Location.x = v2Loc.x;
	Location.y = v2Loc.y;
	Region = RegionRef;
	localRegion = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));
	if(localRegion != none)
		Continent = localRegion.GetContinent().GetReference();
	Available = bAvailable;
	Expiring = bExpiring;
	TimeUntilDespawn = (iSeconds > 0) ? float(iSeconds) : float(3600 * iHours);
	bSpawnUFO = class'X2StrategyGameRulesetDataStructures'.static.Roll(MissionSource.SpawnUFOChance);

	if(Available && Expiring)
	{
		TimerStartDateTime = `STRATEGYRULES.GameTime;
		SetProjectedExpirationDateTime(TimerStartDateTime);
	}
	else
	{
		ExpirationDateTime.m_iYear = 9999;
	}

	for(idx = 0; idx < MissionRewards.Length; idx++)
	{
		Rewards.AddItem(MissionRewards[idx].GetReference());
	}

	if (MissionRewards.Length != 0 && bSetMissionData)
	{
		SetMissionData(MissionRewards[0].GetMyTemplate(), bUseSpecifiedLevelSeed, LevelSeedOverride);
	}

	bMakesDoom = MissionSource.bMakesDoom;

	if(MissionSource.CalculateStartingDoomFn != none)
	{
		Doom = MissionSource.CalculateStartingDoomFn();
		AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		DoomDiff = AlienHQ.GetMaxDoom() - AlienHQ.GetCurrentDoom();
		Doom = Clamp(Doom, 0, DoomDiff);
	}

	if(Doom > 0)
	{
		if(`HQGAME != none && `HQPRES != none)
		{
			ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			ParamTag.StrValue0 = localRegion.GetDisplayName();
			`HQPRES.StrategyMap2D.StrategyMapHUD.SetDoomMessage(`XEXPAND.ExpandString(class'XComGameState_HeadquartersAlien'.default.FacilityDoomLabel), false, true);
		}
		
	}

	if (MissionSource.bIntelHackRewards)
	{
		PickIntelOptions();
	}

	// Precalculate doom removal data
	if(MissionSource.CalculateDoomRemovalFn != none)
	{
		MissionSource.CalculateDoomRemovalFn(self);
	}
}

function BuildRandomMission(X2MissionSourceTemplate MissionSource, array<XComGameState_Reward> MissionRewards, optional bool bAvailable=true, optional bool bExpiring=false, optional int iHours=-1, optional int iSeconds=-1, optional bool bUseSpecifiedLevelSeed=false, optional int LevelSeedOverride=0)
{
	local StateObjectReference RegionRef;
	local Vector2D RandomLocation;

	RandomLocation = SelectRandomMissionLocation(RegionRef);
	BuildMission(MissionSource, RandomLocation, RegionRef, MissionRewards, bAvailable, bExpiring, iHours, iSeconds, bUseSpecifiedLevelSeed, LevelSeedOverride);
}

simulated function string GetUIButtonTooltipTitle()
{
	return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetMissionSource().MissionPinLabel);
}

simulated function string GetUIButtonTooltipBody()
{
	local string toolTip;
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local int i;

	i = 0;

	if( GetMissionSource().DataName == 'MissionSource_GuerillaOp' )
	{
		toolTip = Caps(GetMissionSource().MissionPinLabel) $ ":";
		History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if( MissionState.Source == 'MissionSource_GuerillaOp' && MissionState.Available )
			{
				if(i > 0)
				{
					toolTip $= ",";
				}
				toolTip @= MissionState.GetWorldRegion().GetDisplayName();
			}
			i++;
		}
	}
	else
		toolTip = GetWorldRegion().GetDisplayName();

	return toolTip;
}


//---------------------------------------------------------------------------------------
// Determine a random region and random location
public static function Vector2D SelectRandomMissionLocation(out StateObjectReference RegionRef, optional XComGameState GameStateSearch)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_WorldRegion> arrRegions;

	History = `XCOMHISTORY;

	if (GameStateSearch == none)
	{
		// Choose random wilderness regions, then random location in that region
		foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
		{
			arrRegions.AddItem(RegionState);
		}
	}
	else
	{
		// Choose random wilderness regions, then random location in that region
		foreach GameStateSearch.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
		{
			arrRegions.AddItem(RegionState);
		}
	}

	RegionState = arrRegions[`SYNC_RAND_STATIC(arrRegions.Length)];
	RegionRef = RegionState.GetReference();
	return RegionState.GetRandom2DLocationInRegion();
}

//---------------------------------------------------------------------------------------
private function PlotDefinition SelectPlotDefinition(MissionDefinition MissionDef, string Biome)
{
	local XComParcelManager ParcelMgr;
	local array<PlotDefinition> ValidPlots;
	local PlotDefinition SelectedDef;

	ParcelMgr = `PARCELMGR;
	ParcelMgr.GetValidPlotsForMission(ValidPlots, MissionDef, Biome);

	// pull the first one that isn't excluded from strategy, they are already in order by weight
	foreach ValidPlots(SelectedDef)
	{
		if(!SelectedDef.ExcludeFromStrategy)
		{
			return SelectedDef;
		}
	}

	`Redscreen("Could not find valid plot for mission!\n"
				$ " MissionType: " $ GeneratedMission.Mission.MissionName);

	return ParcelMgr.arrPlots[0];
}

//---------------------------------------------------------------------------------------
function SetMissionData(X2RewardTemplate MissionReward, bool bUseSpecifiedLevelSeed, int LevelSeedOverride, optional array<string> ExcludeFamilies)
{
	local GeneratedMissionData EmptyData;
	local XComTacticalMissionManager MissionMgr;
	local XComParcelManager ParcelMgr;
	local string Biome;

	MissionMgr = `TACTICALMISSIONMGR;
	ParcelMgr = `PARCELMGR;

	GeneratedMission = EmptyData;
	GeneratedMission.MissionID = ObjectID;
	GeneratedMission.Mission = MissionMgr.GetMissionDefinitionForSourceReward(Source, MissionReward.DataName);
	GeneratedMission.LevelSeed = (bUseSpecifiedLevelSeed) ? LevelSeedOverride : class'Engine'.static.GetEngine().GetSyncSeed();
	GeneratedMission.BattleDesc = "";

	GeneratedMission.MissionQuestItemTemplate = MissionMgr.ChooseQuestItemTemplate(Source, MissionReward, GeneratedMission.Mission, (DarkEvent.ObjectID > 0));

	if(GeneratedMission.Mission.sType == "")
	{
		`Redscreen("GetMissionDataForSourceReward() failed to generate a mission with: \n"
						$ " Source: " $ Source $ "\n RewardType: " $ MissionReward.DisplayName);
	}

	// find a plot that supports the biome and the mission
	Biome = class'X2StrategyGameRulesetDataStructures'.static.GetBiome(Get2DLocation());

	// do a weighted selection of our plot
	GeneratedMission.Plot = SelectPlotDefinition(GeneratedMission.Mission, Biome);

	// the plot we find should either have no defined biomes, or the requested biome type
	`assert( (GeneratedMission.Plot.ValidBiomes.Length == 0) || (GeneratedMission.Plot.ValidBiomes.Find( Biome ) != -1) );
	if (GeneratedMission.Plot.ValidBiomes.Length > 0)
	{
		GeneratedMission.Biome = ParcelMgr.GetBiomeDefinition(Biome);
	}

	if(GetMissionSource().BattleOpName != "")
	{
		GeneratedMission.BattleOpName = GetMissionSource().BattleOpName;
	}
	else
	{
		GeneratedMission.BattleOpName = class'XGMission'.static.GenerateOpName(false);
	}

	GenerateMissionFlavorText();
}

//---------------------------------------------------------------------------------------
function PickIntelOptions()
{
	local XComTacticalMissionManager MissionMgr;
	local MissionIntelOption IntelOption;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate IntelOptionTemplate;
	local StrategyCost EmptyCost;
	local ArtifactCost IntelCost;
	local name IntelOptionName;
	local bool bValid;
	local float PriceDelta;
	local int idx, iOptions, IntelQuantity;

	MissionMgr = `TACTICALMISSIONMGR;
	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

	for (idx = 0; idx < class'X2StrategyGameRulesetDataStructures'.default.MaxIntelOptionsPerMission; idx++)
	{
		if (idx == 0) // The first intel option should always be pulled from the guaranteed deck
			IntelOptionName = MissionMgr.GetNextIntelPurchaseableHackReward(true);
		else
			IntelOptionName = MissionMgr.GetNextIntelPurchaseableHackReward();
		
		bValid = true;

		// Check if this reward, or a mutually exclusive option, is already selected
		for (iOptions = 0; iOptions < IntelOptions.Length; iOptions++)
		{
			IntelOptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(IntelOptions[iOptions].IntelRewardName);
			if (IntelOptions[iOptions].IntelRewardName == IntelOptionName || IntelOptionTemplate.MutuallyExclusiveRewards.Find(IntelOptionName) != INDEX_NONE)
			{
				bValid = false;
			}
		}

		if (bValid)
		{
			IntelOptionTemplate = HackRewardTemplateManager.FindHackRewardTemplate(IntelOptionName);

			// Randomly choose an intel cost between the min and max values, along with an applied random variance
			IntelQuantity = IntelOptionTemplate.MinIntelCost + `SYNC_RAND(IntelOptionTemplate.MaxIntelCost - IntelOptionTemplate.MinIntelCost + 1);
			PriceDelta = float(IntelQuantity) * (float(`SYNC_RAND(class'X2StrategyGameRulesetDataStructures'.default.MissionIntelOptionPriceVariance)) / 100.0);
			if (class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
			{
				PriceDelta = -PriceDelta;
			}
			IntelCost.Quantity = IntelQuantity + PriceDelta;
			IntelCost.ItemTemplateName = 'Intel';

			IntelOption.IntelRewardName = IntelOptionName;
			IntelOption.Cost = EmptyCost; // Reset the cost each time
			IntelOption.Cost.ResourceCosts.AddItem(IntelCost);

			IntelOptions.AddItem(IntelOption);
		}
	}
}

//---------------------------------------------------------------------------------------

// Ask ResHQ to pick a Point of Interest which will be spawned if the mission is successfully completed
// Assumes game state logic is handled in the class that calls this function
function PickPOI(XComGameState NewGameState)
{
	local XComGameState_HeadquartersResistance ResHQ;

	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	// Choose a random POI to be spawned if the mission is successful
	POIToSpawn = ResHQ.ChoosePOI(NewGameState);
}

function bool HasDarkEvent()
{
	return (DarkEvent.ObjectID != 0);
}

function XComGameState_DarkEvent GetDarkEvent()
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState;

	History = `XCOMHISTORY;
	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(DarkEvent.ObjectID));

	return DarkEventState;
}

function X2MissionSourceTemplate GetMissionSource()
{
	local X2StrategyElementTemplateManager StratMgr;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	return X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate(Source));
}

function GenerateMissionFlavorText()
{
	local X2MissionFlavorTextTemplate FlavorTextTemplate;

	if(FlavorText == "" || SuccessText == "" || FailureText == "")
	{
		// Special Handling for first GOp
		if(Source == 'MissionSource_GuerillaOp' && !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T2_M0_CompleteGuerillaOps'))
		{
			FlavorTextTemplate = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetMissionFlavorText(self, , 'GOp_First');
		}
		else
		{
			FlavorTextTemplate = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetMissionFlavorText(self);
		}
		
		if(FlavorTextTemplate != none)
		{
			if(FlavorText == "")
			{
				FlavorText = FlavorTextTemplate.FlavorText[`SYNC_RAND(FlavorTextTemplate.FlavorText.Length)];
			}

			if(SuccessText == "")
			{
				SuccessText = FlavorTextTemplate.CouncilSpokesmanSuccessText[`SYNC_RAND(FlavorTextTemplate.CouncilSpokesmanSuccessText.Length)];
			}

			if(FailureText == "")
			{
				FailureText = FlavorTextTemplate.CouncilSpokesmanFailureText[`SYNC_RAND(FlavorTextTemplate.CouncilSpokesmanFailureText.Length)];
			}

			if(PartialSuccessText == "" && FlavorTextTemplate.CouncilSpokesmanPartialSuccessText.Length > 0)
			{
				PartialSuccessText = FlavorTextTemplate.CouncilSpokesmanPartialSuccessText[`SYNC_RAND(FlavorTextTemplate.CouncilSpokesmanPartialSuccessText.Length)];
			}
		}

		if(FlavorText == "" || SuccessText == "" || FailureText == "")
		{
			FlavorTextTemplate = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetMissionFlavorText(self, true);

			if(FlavorTextTemplate != none)
			{
				if(FlavorText == "")
				{
					FlavorText = FlavorTextTemplate.FlavorText[`SYNC_RAND(FlavorTextTemplate.FlavorText.Length)];
				}

				if(SuccessText == "")
				{
					SuccessText = FlavorTextTemplate.CouncilSpokesmanSuccessText[`SYNC_RAND(FlavorTextTemplate.CouncilSpokesmanSuccessText.Length)];
				}
				
				if(FailureText == "")
				{
					FailureText = FlavorTextTemplate.CouncilSpokesmanFailureText[`SYNC_RAND(FlavorTextTemplate.CouncilSpokesmanFailureText.Length)];
				}

				if(PartialSuccessText == "" && FlavorTextTemplate.CouncilSpokesmanPartialSuccessText.Length > 0)
				{
					PartialSuccessText = FlavorTextTemplate.CouncilSpokesmanPartialSuccessText[`SYNC_RAND(FlavorTextTemplate.CouncilSpokesmanPartialSuccessText.Length)];
				}
			}
		}
	}
}

//Returns a string describing the goal / facility
function string GetMissionDescription()
{
	return class'X2MissionTemplateManager'.static.GetMissionTemplateManager().GetMissionDisplayName(GeneratedMission.Mission.MissionName);
}

//Returns a string describing the geographi location of the mission site
function string GetLocationDescription()
{
	local X2StrategyElementTemplateManager StrategyElementTemplateManager;
	local X2MissionSiteDescriptionTemplate MissionSiteDescriptionTemplate;
	local XComParcelManager ParcelManager;
	local int Index;
	local string DescriptionString;

	ParcelManager = `PARCELMGR;
	StrategyElementTemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for( Index = 0; Index < ParcelManager.arrPlotTypes.Length; ++Index )
	{
		if( ParcelManager.arrPlotTypes[Index].strType == GeneratedMission.Plot.strType )
		{
			MissionSiteDescriptionTemplate = X2MissionSiteDescriptionTemplate(StrategyElementTemplateManager.FindStrategyElementTemplate(ParcelManager.arrPlotTypes[Index].MissionSiteDescriptionTemplate));
			break;
		}
	}

	if( MissionSiteDescriptionTemplate != none )
	{
		DescriptionString = MissionSiteDescriptionTemplate.GetMissionSiteDescriptionFn(MissionSiteDescriptionTemplate.DescriptionString, self);
	}

	return DescriptionString;
}

//---------------------------------------------------------------------------------------
// Reward type, could change to template name instead of enum
function X2RewardTemplate GetRewardType()
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(Rewards[0].ObjectID));

	return RewardState.GetMyTemplate();
}

//---------------------------------------------------------------------------------------
// Remaining hours until expiration (used for UI)
function int GetHoursRemaining()
{
	return class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(ExpirationDateTime, `STRATEGYRULES.GameTime);
}

//---------------------------------------------------------------------------------------
// Sets the mission expiration datetime under the current conditions
function SetProjectedExpirationDateTime(TDateTime StartTime)
{
	ExpirationDateTime = StartTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddTime(ExpirationDateTime, TimeUntilDespawn);
}

//---------------------------------------------------------------------------------------
function PauseMissionTimer()
{
	UpdateTimeRemaining();

	// Set expiration datetime to unreachable future
	ExpirationDateTime.m_iYear = 9999;
}

//---------------------------------------------------------------------------------------
function ResumeMissionTimer()
{
	TimerStartDateTime = `STRATEGYRULES.GameTime;
	SetProjectedExpirationDateTime(TimerStartDateTime);
}

//---------------------------------------------------------------------------------------
// When pausing there is a need to store the remaining time until expiration
function UpdateTimeRemaining()
{
	TimeUntilDespawn -= class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(`STRATEGYRULES.GameTime, TimerStartDateTime);
}

//---------------------------------------------------------------------------------------
function SetBuildTime(int Hours)
{
	BuildStartTime = GetCurrentTime();
	BuildEndTime = BuildStartTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(BuildEndTime, Hours);
}

//---------------------------------------------------------------------------------------
function int GetBuildHoursRemaining()
{
	if(!bBuilding)
	{
		return 0;
	}

	return class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(BuildEndTime, GetCurrentTime());
}

//---------------------------------------------------------------------------------------
function string GetMissionTypeString()
{
	return GetRewardType().DisplayName;
}

function bool GetShadowChamberStrings()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	//local XComGameState_WorldRegion RegionState;
	local int ForceLevel, AlertLevel, NumUnits;
	local array<X2CharacterTemplate> TemplatesToSpawn;
	local X2CharacterTemplate TemplateToSpawn;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ForceLevel = AlienHQ.GetForceLevel();

	//RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(Region.ObjectID));
	AlertLevel = GetMissionDifficulty();

	if(CacheSelectedMissionData(ForceLevel, AlertLevel))
	{
		GetShadowChamberMissionInfo(NumUnits, TemplatesToSpawn);

		m_strShadowCount = String(NumUnits);
		m_strShadowCrew = "";

		foreach TemplatesToSpawn(TemplateToSpawn)
		{
			if( TemplateToSpawn.bIsCivilian || TemplateToSpawn.bHideInShadowChamber )
			{
				continue;
			}

			if(m_strShadowCrew != "")
			{
				m_strShadowCrew = m_strShadowCrew $ ", ";
			}

			if(XComHQ.HasSeenCharacterTemplate(TemplateToSpawn))
			{
				m_strShadowCrew = m_strShadowCrew $ TemplateToSpawn.strCharacterName;
			}
			else
			{
				m_strShadowCrew = m_strShadowCrew $ Class'UIUtilities_Text'.static.GetColoredText(m_strEnemyUnknown, eUIState_Bad);
			}
		}

		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function string GetRewardAmountString()
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local int idx;
	local string strTemp;

	History = `XCOMHISTORY;
	strTemp = "";

	if(GetMissionSource().GetMissionRewardStringFn != none)
	{
		strTemp = GetMissionSource().GetMissionRewardStringFn(self);
	}

	for(idx = 0; idx < Rewards.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(Rewards[idx].ObjectID));

		if(RewardState != none)
		{
			strTemp $= RewardState.GetRewardString();
			
			if(idx < (Rewards.Length - 1))
			{
				strTemp $= ", ";
			}
		}
	}

	return strTemp;
}

//---------------------------------------------------------------------------------------
function string GetRewardIcon()
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local int idx;

	History = `XCOMHISTORY;
	for(idx = 0; idx < Rewards.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(Rewards[idx].ObjectID));

		if(RewardState != none)
		{
			return RewardState.GetRewardIcon();
		}
	}

	return "";
}

//---------------------------------------------------------------------------------------
function CleanUpRewards(XComGameState NewGameState)
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local int idx;
	local bool bStartState;

	bStartState = (NewGameState.GetContext().IsStartState());
	History = `XCOMHISTORY;

	for(idx = 0; idx < Rewards.Length; idx++)
	{
		if(bStartState)
		{
			RewardState = XComGameState_Reward(NewGameState.GetGameStateForObjectID(Rewards[idx].ObjectID));
		}
		else
		{
			RewardState = XComGameState_Reward(History.GetGameStateForObjectID(Rewards[idx].ObjectID));
		}

		if(RewardState != none)
		{
			RewardState.CleanUpReward(NewGameState);
			NewGameState.RemoveStateObject(RewardState.ObjectID);
		}
	}
}

function name GetMissionSuccessEventID()
{
	return name(GeneratedMission.Mission.sType $ "_Success");
}

function name GetMissionFailureEventID()
{
	return name(GeneratedMission.Mission.sType $ "_Failure");
}

//---------------------------------------------------------------------------------------
function int GetMissionDifficulty(optional bool bDisplayOnly = false)
{
	local X2MissionSourceTemplate MissionSource;
	local int Difficulty, CampaignDifficulty;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	MissionSource = GetMissionSource();

	if(ManualDifficultySetting > 0)
	{
		Difficulty = ManualDifficultySetting;
	}
	else
	{
		if(MissionSource != none && MissionSource.GetMissionDifficultyFn != none)
		{
			Difficulty = MissionSource.GetMissionDifficultyFn(self);
		}
		else
		{
			`RedScreen("No difficulty function for Mission.  Defaulting to medium difficulty @gameplay -mnauta");
			Difficulty = 2;
		}
	}

	if(!bDisplayOnly)
	{
		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		CampaignDifficulty = `DifficultySetting;
		Difficulty += class'X2StrategyGameRulesetDataStructures'.default.CampaignDiffModOnMissionDiff[CampaignDifficulty];
		if(MissionSource != none && MissionSource.bIgnoreDifficultyCap)
		{
			Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty, Difficulty);
		}
		else
		{
			Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty,
							   class'X2StrategyGameRulesetDataStructures'.default.CampaignDiffMaxDiff[CampaignDifficulty]);
		}
		

		if(XComHQ.TacticalGameplayTags.Find('DarkEvent_ShowOfForce') != INDEX_NONE)
		{
			++Difficulty;
		}
	}
	else
	{
		Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty,
						   class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty);
	}

	return Difficulty;
}

function string GetMissionDifficultyLabel()
{
	local string Text;
	local eUIState ColorState;
	local int Difficulty;

	Difficulty = GetMissionDifficulty(true);
	Text = class'X2StrategyGameRulesetDataStructures'.default.MissionDifficultyLabels[Difficulty];

	switch(Difficulty)
	{
	case 1: ColorState = eUIState_Good;     break;
	case 2: ColorState = eUIState_Normal;   break;
	case 3: ColorState = eUIState_Warning;  break;
	case 4: ColorState = eUIState_Bad;      break;
	}

	return class'UIUtilities_Text'.static.GetColoredText(Text, ColorState);
}

function bool MakesDoom()
{
	return bMakesDoom;
}

//---------------------------------------------------------------------------------------
//----------- XComGameState_GeoscapeEntity Implementation -------------------------------
//---------------------------------------------------------------------------------------

protected function bool CanInteract()
{
	return Available;
}

//---------------------------------------------------------------------------------------
function bool AboutToExpire()
{
	return (Expiring && class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(ExpirationDateTime, `STRATEGYRULES.GameTime) <
		class'X2StrategyGameRulesetDataStructures'.default.MissionAboutToExpireHours);
}

function class<UIStrategyMapItem> GetUIClass()
{
	if(MakesDoom())
	{
		return class'UIStrategyMapItem_Mission'; //bsg-jneal (8.30.16): added DOOM to mission map items, use that class now
	}

	return class'UIStrategyMapItem_Mission';
}

function string GetUIWidgetFlashLibraryName()
{
	//bsg-jneal (8.30.16): added DOOM to mission map items, use that class now
	//if(MakesDoom())
	//{
	//	return "MI_alienFacility";
	//}

	//return "MI_region"; // bsg-jneal (7.22.16): reusing region button for missions
	return "SimpleHint";
}

function string GetUIPinImagePath()
{
	return "";
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	local X2MissionSourceTemplate MissionSource;
	local string OverworldMeshPath;
	local Object MeshObject;

	MissionSource = GetMissionSource();
	OverworldMeshPath = "";

	if(MissionSource.GetOverworldMeshPathFn != none)
	{
		OverworldMeshPath = MissionSource.GetOverworldMeshPathFn(self);
	}

	if(OverworldMeshPath == "" && MissionSource.OverworldMeshPath != "")
	{
		OverworldMeshPath = MissionSource.OverworldMeshPath;
	}

	if(OverworldMeshPath != "")
	{
		MeshObject = `CONTENT.RequestGameArchetype(OverworldMeshPath);

		if(MeshObject != none && MeshObject.IsA('StaticMesh'))
		{
			return StaticMesh(MeshObject);
		}
	}

	return none;
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 0.8;
	ScaleVector.Y = 0.8;
	ScaleVector.Z = 0.8;

	return ScaleVector;
}

function Rotator GetMeshRotator()
{
	local Rotator MeshRotation;

	MeshRotation.Roll = 0;
	MeshRotation.Pitch = 0;
	MeshRotation.Yaw = 0;

	return MeshRotation;
}

function bool ShouldBeVisible()
{
	return (Available || bBuilding);
}

//function bool ShowFadedPin()
//{
//	return (bNotAtThreshold || bBuilding);
//}

function bool RequiresSquad()
{
	return true;
}

function SelectSquad()
{
	local XGStrategy StrategyGame;
	
	BeginInteraction();
	
	StrategyGame = `GAME;
	StrategyGame.PrepareTacticalBattle(ObjectID);

	// Player cannot leave squad select on the final two missions
	if (GetMissionSource().DataName == 'MissionSource_Broadcast' || GetMissionSource().DataName == 'MissionSource_Final' ||
		(GetMissionSource().DataName == 'MissionSource_GuerillaOp' && !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape')))
	{
		`HQPRES.UISquadSelect(true);
	}
	else
	{
		`HQPRES.UISquadSelect();
	}
}

// Complete the squad select interaction; the mission will not begin until this destination has been reached
function SquadSelectionCompleted()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Skyranger SkyrangerState;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// skip the geoscape when launching the 2nd tutorial mission
	if( XComHQ.GetObjectiveStatus('T0_M3_WelcomeToHQ') == eObjectiveState_InProgress )
	{
		ConfirmMission();
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Load Squad onto Skyranger");
		SkyrangerState = XComGameState_Skyranger(NewGameState.CreateStateObject(class'XComGameState_Skyranger', XComHQ.SkyrangerRef.ObjectID));
		SkyrangerState.SquadOnBoard = true;
		NewGameState.AddStateObject(SkyrangerState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		InteractionComplete(false);

		// after completing the squad selection, update the flight destination of the skyranger to the objective
		XComHQ.UpdateFlightStatus();
	}
}

function SquadSelectionCancelled()
{
	ClearIntelOptions();
	ResetLaunchMissionWarning();
	InteractionComplete(true); // RTB after backing out of squad selection
}

function DestinationReached()
{
	BeginInteraction();

	`HQPRES.UISkyrangerArrives();
}

function ConfirmMission()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XGStrategy StrategyGame;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Launch Mission Selected");
	`XEVENTMGR.TriggerEvent('LaunchMissionSelected', , , NewGameState);
	if (GetMissionSource().DataName == 'MissionSource_Final')
	{
		`XEVENTMGR.TriggerEvent('FinalMissionSquadSelected', , , NewGameState);
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	// return the Skyranger to the Avenger upon returning from the mission
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ.SetPendingPointOfTravel(XComHQ);

	StrategyGame = `GAME;

	if(StrategyGame.SimCombatNextMission)
	{
		StrategyGame.SimCombatNextMission = false;
		`HQPRES.m_bExitFromSimCombat = true;
		`HQPRES.ExitStrategyMap();
		class'X2StrategyGame_SimCombat'.static.SimCombat();
	}
	else
	{
		// Launch this Mission!
		StrategyGame.LaunchTacticalBattle(ObjectID);
	}
}

simulated function ClearIntelOptions()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local MissionIntelOption IntelOption;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Mission Intel Options");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	foreach PurchasedIntelOptions(IntelOption)
	{
		XComHQ.TacticalGameplayTags.RemoveItem(IntelOption.IntelRewardName);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function ResetLaunchMissionWarning()
{
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;
	
	if (bHasSeenLaunchMissionWarning)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Launch Mission Warning");
		MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', ObjectID));
		NewGameState.AddStateObject(MissionState);
		MissionState.bHasSeenLaunchMissionWarning = false;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}	
}

function CancelMission()
{
	ClearIntelOptions();
	ResumePsiOperativeTraining();
	ResetLaunchMissionWarning();

	`XSTRATEGYSOUNDMGR.PlayGeoscapeMusic();
	InteractionComplete(true);
}

simulated function ResumePsiOperativeTraining()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_HeadquartersProjectPsiTraining PsiProjectState;
	local XComGameState_FacilityXCom FacilityState;
	local StaffUnitInfo UnitInfo;
	local int idx, SlotIndex;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for (idx = 0; idx < XComHQ.Squad.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[idx].ObjectID));

		if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
		{
			PsiProjectState = XComHQ.GetPsiTrainingProject(UnitState.GetReference());
			if (PsiProjectState != none) // A paused Psi Training project was found for the unit
			{
				// Get the Psi Chamber facility and staff the unit in it if there is an open slot
				FacilityState = XComHQ.GetFacilityByName('PsiChamber'); // Only one Psi Chamber allowed, so safe to do this
				SlotIndex = FacilityState.GetEmptySoldierStaffSlotIndex();
				if (SlotIndex >= 0)
				{
					// Restart the paused training project
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Resume Psi Op Training");
					PsiProjectState = XComGameState_HeadquartersProjectPsiTraining(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectPsiTraining', PsiProjectState.ObjectID));
					NewGameState.AddStateObject(PsiProjectState);
					PsiProjectState.bForcePaused = false;

					UnitInfo.UnitRef = UnitState.GetReference();
					FacilityState.GetStaffSlot(SlotIndex).FillSlot(NewGameState, UnitInfo);
					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
				}
			}
		}
	}
}

function UpdateGameBoard()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local UIStrategyMap StrategyMap;
	local int Count;
	
	History = `XCOMHISTORY;
	StrategyMap = `HQPRES.StrategyMap2D;
	
	// Don't let any missions expire while the Avenger or Skyranger are flying
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight)
	{
		if (Expiring && class'X2StrategyGameRulesetDataStructures'.static.LessThan(ExpirationDateTime, GetCurrentTime()))
		{
			if (GetMissionSource().DataName == 'MissionSource_GuerillaOp')
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Guerilla Op Mission Expired");
				`XEVENTMGR.TriggerEvent('GuerillaOpComplete', , , NewGameState);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}

			History = `XCOMHISTORY;
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Expired");
			// Only show the mission expired popup if this is only mission of the same mission source (Avoids multiple popups)
			Count = 0;
			foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
			{
				if(MissionState.Available && MissionState.GetMissionSource().DataName == self.GetMissionSource().DataName)
				{
					Count++;
				}
			}

			if(Count == 1)
			{
				ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
				ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
				NewGameState.AddStateObject(ResistanceHQ);
				ResistanceHQ.ExpiredMission = self.GetReference();

				// Only record expired GOps once
				if (GetMissionSource().DataName == 'MissionSource_GuerillaOp')
				{
					class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_GuerrillaOpsFailed');
				}
			}

			if (GetMissionSource().OnExpireFn != none)
			{
				GetMissionSource().OnExpireFn(NewGameState, self);
			}

			RemoveEntity(NewGameState);

			`XEVENTMGR.TriggerEvent('MissionExpired', , , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if (bNeedsBuildStartPopup)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Done Building Popup flag");
			MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', self.ObjectID));
			NewGameState.AddStateObject(MissionState);
			MissionState.bNeedsBuildStartPopup = false;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			MissionBuildStartPopup();
		}
		else if (bNeedsBuildCompletePopup)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Done Building Popup flag");
			MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', self.ObjectID));
			NewGameState.AddStateObject(MissionState);
			MissionState.bNeedsBuildCompletePopup = false;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			MissionBuildingCompletePopup();
		}
		else if (bBuilding && class'X2StrategyGameRulesetDataStructures'.static.LessThan(BuildEndTime, GetCurrentTime()))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Done Building");
			MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', self.ObjectID));
			NewGameState.AddStateObject(MissionState);
			MissionState.bBuilding = false;
			MissionState.Available = true;
			MissionState.bNeedsBuildCompletePopup = true;

			`XEVENTMGR.TriggerEvent('MissionDoneBuilding', MissionState, MissionState, NewGameState);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if(bNeedsDoomPopup)
		{
			DoomAddedPopup();
		}
	}
}

//---------------------------------------------------------------------------------------
simulated public function DoomAddedPopup()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionSite MissionState;
	local UIAlert Alert;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Doom Popup flag");
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', self.ObjectID));
	NewGameState.AddStateObject(MissionState);
	MissionState.bNeedsDoomPopup = false;
	
	AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.bHasSeenDoomPopup = true; // Ensure the doom popup is only shown to the player once
	
	`XEVENTMGR.TriggerEvent('OnDoomPopup', , , NewGameState);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`GAME.GetGeoscape().Pause();

	Alert = `HQPRES.Spawn(class'UIAlert', `HQPRES);
	Alert.eAlert = eAlert_Doom;
	Alert.Mission = MissionState;
	Alert.RegionRef = MissionState.Region;
	Alert.fnCallback = `HQPRES.DoomAlertCB;
	Alert.SoundToPlay = "Geoscape_DoomIncrease";
	`HQPRES.ScreenStack.Push(Alert);
}

function RemoveEntity(XComGameState NewGameState)
{
	local bool SubmitLocally;

	if( NewGameState == None )
	{
		SubmitLocally = true;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Despawned");
	}

	// clean up the rewards for this mission
	CleanUpRewards(NewGameState);

	// remove this mission from the history
	NewGameState.RemoveStateObject(ObjectID);

	if( SubmitLocally )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	Remove3DUI();
	if(`HQPRES != none && `HQPRES.StrategyMap2D != none)
	{
		Available = false;
		RemoveMapPin();
		`HQPRES.StrategyMap2D.UpdateMissions();
	}
}

function AttemptSelectionCheckInterruption()
{
	// Mission sites should never trigger interruption states since they are so important, so just
	// jump straight to the selection
	AttemptSelection();
}

protected function bool DisplaySelectionPrompt()
{
	`HQPRES.OnMissionSelected(self);

	return true;
}

function MissionSelected()
{
	`HQPRES.OnMissionSelected(self);
}

function NotAtThresholdPopup()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = "Need Resistance Contact";
	DialogData.strText = "You need to make contact with the Resistance in the region before we can take on this mission.";
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	DialogData.fnCallback = DefaultResumeCallback;
	`HQPRES.UIRaiseDialog(DialogData);
}

simulated private function DefaultResumeCallback(eUIAction eAction)
{
	InteractionComplete(false);
}

function MissionBuildingInProgressPopup()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = "Mission Preparations in Progress";
	DialogData.strText = "This region's resistance is still gathering assets for this mission.  Preparations will complete in" 
		@ class'UIUtilities_Text'.static.GetTimeRemainingString(GetBuildHoursRemaining()) $ ".";
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	DialogData.fnCallback = DefaultResumeCallback;
	`HQPRES.UIRaiseDialog(DialogData);
}

function MissionBuildingCompletePopup()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = "Mission Preparations Complete";
	DialogData.strText = "The resistance has finished gathering assets and the mission in" @ GetWorldRegion().GetMyTemplate().DisplayName @ "is now available.  We should take on this operation as soon as possible.";
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	DialogData.fnCallback = DefaultResumeCallback;
	`HQPRES.UIRaiseDialog(DialogData);
}

function MissionBuildStartPopup()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = "Mission Preparations Commencing";
	DialogData.strText = "Thanks to your efforts in rallying the Resistance, our forces have identified a lead in" @ GetWorldRegion().GetMyTemplate().DisplayName $ ". We will focus on this site until it is available for a strike.";
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	DialogData.fnCallback = DefaultResumeCallback;
	`HQPRES.UIRaiseDialog(DialogData);
}

simulated function string GetMissionObjectiveText()
{
	return class'X2MissionTemplateManager'.static.GetMissionTemplateManager().GetMissionDisplayName(GeneratedMission.Mission.MissionName);
}

simulated function bool IsVIPMission()
{
	return (class'XComTacticalMissionManager'.default.VIPMissionFamilies.Find(GeneratedMission.Mission.MissionFamily) != INDEX_NONE);
}

simulated function bool HasRewardVIP()
{
	local XComGameState_BattleData BattleData;
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	return BattleData.RewardUnits.Length > 0;
}

simulated function StateObjectReference GetRewardVIP()
{
	local StateObjectReference NoneRef;
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	// NOTE: What do we do if there are more than 1 reward unit?
	if(BattleData.RewardUnits.Length > 0)
	{
		return BattleData.RewardUnits[0];
	}
	return NoneRef;
}

simulated function int GetRewardVIPStatus(XComGameState_Unit Unit)
{
	local XComGameState_BattleData BattleData;

	if(Unit == none)
		return eVIPStatus_Unknown;
	
	if(Unit.IsDead())
		return eVIPStatus_Killed;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(!BattleData.OneStrategyObjectiveCompleted())
		return eVIPStatus_Lost;

	if(Unit.IsSoldier())
		return eVIPStatus_Awarded;

	if(Unit.IsCivilian())
		return eVIPStatus_Recovered;

	return eVIPStatus_Unknown;
}

function HandleUpdateLocation()
{
	SetMissionData(GetRewardType(), false, 0);
}

function string GetUIButtonIcon()
{
	local string StrButtonIcon;

	switch(Source)
	{
	case 'MissionSource_LandedUFO':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Advent";
		break;
	case 'MissionSource_AlienNetwork':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Alien";
		break;
	case 'MissionSource_Council':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Council";
		break;
	case 'MissionSource_GuerillaOp':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_GOPS";
		break;
	case 'MissionSource_Retaliation':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Retaliation";
		break;
	case 'MissionSource_BlackSite':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Blacksite";
		break;
	case 'MissionSource_Forge':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Forge";
		break;
	case 'MissionSource_PsiGate':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_PsiGate";
		break;
	case 'MissionSource_Broadcast':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_FinalMission";
		break;
	case 'MissionSource_Final':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_AlienFortress";
		break;
	case 'MissionSource_SupplyRaid':
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_SupplyRaid";
		break;
	default:
		StrButtonIcon = "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_GoldenPath";
	};

	return StrButtonIcon;
}

native function bool IsTerrorSite();

//----------------------------------------------------------------
//----------------------------------------------------------------
//---------------------------------------------------------------------------------------
DefaultProperties
{    
	TerrorSourceName = "MissionSource_Retaliation"
}
