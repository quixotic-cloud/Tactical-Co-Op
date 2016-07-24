//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersAlien.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for the alien player's HQ in the 
//           X-Com 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersAlien extends XComGameState_BaseObject native(Core) config(GameData);

// Alien AI Actions
var() array<name> Actions;

// Alien Facilities
var bool bBuildingFacility;
var int MinDesiredLinkDistance;
var int MaxDesiredLinkDistance;
var TDateTime FacilityBuildStartTime;
var TDateTime FacilityBuildEndTime;
var float FacilityBuildTimeRemaining;
var bool bEndOfMonthComplete;

// AI Mode
var() string AIMode; // reflects current state of what the AI is doing
var() TDateTime AIModeIntervalStartTime;
var() TDateTime AIModeIntervalEndTime;
var() float AIModeTotalTimeSpent;

// Force Level
var() int ForceLevel;
var() TDateTime ForceLevelIntervalStartTime;
var() TDateTime ForceLevelIntervalEndTime;

// UFOs
var() bool bHasPlayerSeenLandedUFOMission; // Has the player seen a Landed UFO mission
var() bool bHasGoldenPathUFOAppeared; // Has a UFO spawned from a Golden Path mission yet (guaranteed one per game)
var() bool bHasPlayerBeenIntercepted; // Has the player been intercepted by a UFO
var() bool bHasPlayerAvoidedUFO; // Has the player avoided being hunted by a UFO

// Doom
var() int Doom; // Permanent irreversible doom
var() int NextFacilityDoomToAdd; // Calculated value to add at next interval
var() int NextFortressDoomToAdd; // Calculated value to add at next interval
var() bool bGeneratingFacilityDoom;
var() TDateTime FacilityDoomIntervalStartTime;
var() TDateTime FacilityDoomIntervalEndTime;
var() float	FacilityDoomTimeRemaining;
var() bool bGeneratingFortressDoom;
var() TDateTime FortressDoomIntervalStartTime;
var() TDateTime FortressDoomIntervalEndTime;
var() float	FortressDoomTimeRemaining;
var() array<PendingDoom> PendingDoomData; // Doom to be handled on the geoscape (for camera pans, add/remove sequences)
var() StateObjectReference PendingDoomEntity; // Entity to pan to if there is pending doom
var() name PendingDoomEvent; // Event to trigger upon handling of pending doom
var() int DoomHoursToAddOnResume; // Needed for delays from facility destruction during Lose Mode
var() int FacilityHoursToAddOnResume; // Needed for delays from facility destruction during Lose Mode
var() bool bThrottlingDoom; // Are we throttling doom (for lower difficulties)
var() float DoomThrottleTimeScalar; // Multiply doom/facility times by this when throttling
var() bool bAcceleratingDoom; // Are we accelerating doom?  skipping missions starts this off
var() float DoomAccelerateTimeScalar; // Multiply doom/facility times by this when accelerating

var() bool bHasSeenDoomMeter; // if the player has seen the doom meter yet
var() bool bHasSeenDoomPopup; // Has the player seen the doom popup
var() bool bHasSeenHiddenDoomPopup; // Has the player seen the hidden doom popup
var() bool bHasSeenFortress; // Has the player seen the alien fortress
var() bool bHasSeenFacility; // Has the player seen an alien facility
var() bool bNeedsDoomPopup;
var() bool bHasHeardFacilityWarningHalfway; // Has the player heard the warning for the doom meter being halfway full
var() bool bHasHeardFacilityWarningAlmostDone; // Has the player heard the warning for the doom meter being 3/4 full
var() bool bHasSeenRetaliation; // Has the player seen a retaliation mission

var array<DoomGenData> FacilityDoomData;

// Dark Events
var array<StateObjectReference> ChosenDarkEvents; // Cards the AI plays
var array<StateObjectReference> ActiveDarkEvents; // Dark events that have a duration which are currently in play

// Cost Scalars
var array<StrategyCostScalar> CostScalars; // Alien Operations can scale prices of things

// FLAG OF TOTAL VICTORY OVER PUNY HUMANS
var() bool bAlienFullGameVictory;

// Captured soldier info
var array<StateObjectReference> CapturedSoldiers; // soldiers that have been abandoned in missions

// For Preview Build
var bool bPreviewBuild;

// Store Lose Timer Time Remaining
var float LoseTimerTimeRemaining;

// Config vars
var const config array<int> AlienHeadquarters_LoseModeDuration; // Hours
var const config array<int> AlienHeadquarters_LoseModeDurationVariance; // Hours
var const config array<int> AlienHeadquarters_MinLoseModeDuration; // Hours
var const config int AlienHeadquarters_StartingForceLevel;
var const config int AlienHeadquarters_MaxForceLevel;
var const config array<int> AlienHeadquarters_ForceLevelInterval; // In Hours
var const config array<int> AlienHeadquarters_ForceLevelIntervalVariance; // In Hours
var const config array<int> AlienHeadquarters_DoomStartValue;
var const config array<int> AlienHeadquarters_DoomMaxValue;

var const config array<float> DoomThrottleMinPercents; // Doom Percent we start throttling doom
var const config array<float> DoomThrottleScalars; // Multiply doom/facility times by this when throttling
var const config array<float> DoomAccelerateScalars; // Multiply doom/facility times by this when accelerating
var const config array<int> DoomProjectGracePeriod; // Time after recovering from Lose Mode where doom projects don't progress
var const config array<AlienFacilityBuildData> StartingFacilityBuildData;
var const config array<AlienFacilityBuildData> MonthlyFacilityBuildData;
var const config array<int> MinFortressAppearDays;
var const config array<int> MaxFortressAppearDays;
var const config array<int> MinFortressDoomInterval;
var const config array<int> MaxFortressDoomInterval;
var const config array<int> MinFortressStartingDoomInterval;
var const config array<int> MaxFortressStartingDoomInterval;

var config int FirstMonthNumDarkEvents;
var config int NumDarkEvents;

var config array<int> MaxFacilities;

var config array<int> FacilityDestructionDoomDelay;

var config array<DoomAddedData>		FacilityDoomAdd;
var config array<DoomAddedData>		FortressDoomAdd;

// Doom Generation
var config array<DoomGenData> FacilityDoomGen;

// For Doom Generation Function (no longer used)
var config array<int> DesiredDoomDays; // If no player action doom meter fills in this amount of days
var config array<int> ProjectedDoomFromDarkEvents; // Avg. Amount of doom from dark events over campaign
var config array<int> ProjectedFacilityDoomRemoved; // Avg. Amount of doom removed from destroying facilities
var config array<int> ProjectedFacilitiesDestroyed; // Avg. Amount of facilities destroyed
var config array<int> NumDoomGenSpeeds; // How many different speeds of doom generation
var config array<float> DoomGenMaxDeviation; // How much slower/faster than the avg gen speed are we allowed to go
var config array<float> DoomGenVariance; // at a gen speed what is the variance allowed (for min/max gen time calculation)
var config array<float> DoomGenScalar; // Scalar to apply after everything else


var localized string FacilityDoomLabel;
var localized string HiddenDoomLabel;

// #######################################################################################
// -------------------- INITIALIZATION ---------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
static function SetUpHeadquarters(XComGameState StartState)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> arrAIActions;
	local X2StrategyElementTemplate AIAction;
	local TDateTime StartDate;
	local int ForceLevelInterval, FortressAppearHours;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// Create the Alien HQ state object
	AlienHQ = XComGameState_HeadquartersAlien(StartState.CreateStateObject(class'XComGameState_HeadquartersAlien'));
	StartState.AddStateObject(AlienHQ);

	// Grab the Start Date
	class'X2StrategyGameRulesetDataStructures'.static.SetTime(StartDate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
															  class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);
	// Set Starting Force Level
	AlienHQ.ForceLevel = default.AlienHeadquarters_StartingForceLevel;
	ForceLevelInterval = AlienHQ.GetForcelLevelInterval();

	if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		ForceLevelInterval += `SYNC_RAND_STATIC(AlienHQ.GetForcelLevelIntervalVariance());
	}
	else
	{
		ForceLevelInterval -= `SYNC_RAND_STATIC(AlienHQ.GetForcelLevelIntervalVariance());
	}

	AlienHQ.ForceLevelIntervalStartTime = StartDate;														 
	AlienHQ.ForceLevelIntervalEndTime = AlienHQ.ForceLevelIntervalStartTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(AlienHQ.ForceLevelIntervalEndTime, ForceLevelInterval);

	// Start Building Facilities
	AlienHQ.bBuildingFacility = true;
	AlienHQ.MinDesiredLinkDistance = AlienHQ.GetStartingFacilityBuildData().MinLinkDistance;
	AlienHQ.MaxDesiredLinkDistance = AlienHQ.GetStartingFacilityBuildData().MaxLinkDistance;
	AlienHQ.SetFacilityBuildTime(StartDate, AlienHQ.GetStartingFacilityBuildData());

	// Start Fortress Reveal Timer
	AlienHQ.bGeneratingFortressDoom = true;
	AlienHQ.FortressDoomIntervalStartTime = StartDate;
	AlienHQ.FortressDoomIntervalEndTime = StartDate;
	FortressAppearHours = (AlienHQ.GetMinFortressAppearDays() * 24) + `SYNC_RAND_STATIC((AlienHQ.GetMaxFortressAppearDays() * 24) - (AlienHQ.GetMinFortressAppearDays() * 24) + 1);
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(AlienHQ.FortressDoomIntervalEndTime, FortressAppearHours);
	AlienHQ.FortressDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(AlienHQ.FortressDoomIntervalEndTime, AlienHQ.FortressDoomIntervalStartTime);

	// Set AI Mode
	AlienHQ.AIMode = "StartPhase";

	// Aggregate actions
	AlienHQ.Actions.Length = 0;
	arrAIActions = StratMgr.GetAllTemplatesOfClass(class'X2AlienStrategyActionTemplate');
	foreach arrAIActions(AIAction)
	{
		AlienHQ.Actions.AddItem(X2AlienStrategyActionTemplate(AIAction).DataName);
	}

	// Doom
	AlienHQ.Doom = AlienHQ.GetStartingDoom();
	AlienHQ.SetupDoomGenerationValues();
}

//---------------------------------------------------------------------------------------
function SetUpDoomGenerationValues()
{
	local int idx, CampaignDifficulty;

	CampaignDifficulty = `DifficultySetting;

	for(idx = 0; idx < default.FacilityDoomGen.Length; idx++)
	{
		if(default.FacilityDoomGen[idx].Difficulty == CampaignDifficulty)
		{
			FacilityDoomData.AddItem(default.FacilityDoomGen[idx]);
		}
	}
}

//---------------------------------------------------------------------------------------
// Old Doom Generation formula
//function SetupDoomGenerationValues()
//{
//	local int AvgMonthDays, CurrentDays, GenDays;
//	local int TotalDoom, ProjectedFacilities, DoomPerFacility;
//	local int idx, DistToMedianIndex, MaxDistToMedianIndex;
//	local float AvgDoomDays, CurrentAvgDoomDays, MedianIndex;
//	local AlienFacilityBuildData FacilityData;
//	local DoomGenData DoomGen;
//	local bool bLessThanMedian;
//
//	// Using 1 to calculate even though other difficulties can change this value
//	DoomPerFacility = 1;
//
//	// Subtract out starting doom and doom from dark events
//	TotalDoom = GetMaxDoomAtDifficulty() - GetStartingDoom();
//	TotalDoom -= GetProjectedDoomFromDarkEvents();
//
//	// Add Doom for projected facility removal and GP objectives
//	TotalDoom += GetProjectedFacilityDoomRemoved();
//	TotalDoom += GetTotalGPDoomToBeRemoved();
//
//	// Calculate Facilities built
//	AvgMonthDays = 30;
//	ProjectedFacilities = 0;
//	FacilityData = GetStartingFacilityBuildData();
//	CurrentDays = ((FacilityData.MinBuildDays + FacilityData.MaxBuildDays) / 2);
//
//	// Days Facilities will be producing doom
//	GenDays = GetDesiredDoomDays() - CurrentDays;
//
//	while(CurrentDays < GetDesiredDoomDays() && ProjectedFacilities < (GetMaxFacilities() + GetProjectedFacilitiesDestroyed()))
//	{
//		ProjectedFacilities++;
//		FacilityData = GetMonthlyFacilityBuildData((CurrentDays/AvgMonthDays));
//		CurrentDays += ((FacilityData.MinBuildDays + FacilityData.MaxBuildDays) / 2);
//	}
//
//	// Subtract out doom added when facilities are built
//	TotalDoom -= (DoomPerFacility * ProjectedFacilities);
//
//	// Subtract out fortress starting doom
//	TotalDoom -= class'X2StrategyGameRulesetDataStructures'.static.RollForDoomAdded(class'X2StrategyElement_DefaultMissionSources'.default.FortressStartingDoom[`DifficultySetting]);
//
//	// Calculate and subtract out doom generated by fortress
//	CurrentDays = ((GetMinFortressAppearDays() + GetMaxFortressAppearDays()) / 2);
//	CurrentDays = GetDesiredDoomDays() - CurrentDays;
//	TotalDoom -= (CurrentDays / ((GetMinFortressDoomInterval() + GetMaxFortressDoomInterval()) / 2 / 24));
//
//	// Average amount of days per doom generated
//	AvgDoomDays = float(GenDays) / float(TotalDoom);
//
//	// Generated different Gen speeds (less than median = slower, more than median = faster)
//	MedianIndex = float(GetNumDoomGenSpeeds() - 1) / 2.0f;
//	for(idx = 0; idx < GetNumDoomGenSpeeds(); idx++)
//	{
//		DoomGen.NumFacilities = (idx + 1);
//
//		// Get Distance to median
//		if(Abs(float(idx) - MedianIndex) < 0.4f)
//		{
//			DistToMedianIndex = 0;
//		}
//		else
//		{
//			DistToMedianIndex = Round(Abs(float(idx) - MedianIndex));
//		}
//
//		if(idx == 0)
//		{
//			MaxDistToMedianIndex = DistToMedianIndex;
//		}
//
//		bLessThanMedian = (float(idx) < MedianIndex);
//
//		// Average Doom Days for this Gen Speed
//		if(bLessThanMedian)
//		{
//			CurrentAvgDoomDays = AvgDoomDays + ((float(DistToMedianIndex) / float(MaxDistToMedianIndex)) * GetDoomGenMaxDeviation() * AvgDoomDays);
//		}
//		else
//		{
//			CurrentAvgDoomDays = AvgDoomDays - ((float(DistToMedianIndex) / float(MaxDistToMedianIndex)) * GetDoomGenMaxDeviation() * AvgDoomDays);
//		}
//
//		CurrentAvgDoomDays *= GetDoomGenScalar();
//
//		// Calculate Min and Max interval for this Gen Speed
//		DoomGen.MinInterval = Round(24.0f * (CurrentAvgDoomDays - (CurrentAvgDoomDays * GetDoomGenVariance())));
//		DoomGen.MaxInterval = Round(24.0f * (CurrentAvgDoomDays + (CurrentAvgDoomDays * GetDoomGenVariance())));
//
//		FacilityDoomData.AddItem(DoomGen);
//	}
//}

//---------------------------------------------------------------------------------------
private function int GetTotalGPDoomToBeRemoved()
{
	local float TotalDoomToRemove;

	TotalDoomToRemove = 0.0f;

	// Get doom from objectives
	TotalDoomToRemove += class'X2StrategyElement_DefaultObjectives'.static.GetAverageKillCodexDoom();
	TotalDoomToRemove += class'X2StrategyElement_DefaultObjectives'.static.GetAverageKillAvatarDoom();

	// Get doom from GP missions
	TotalDoomToRemove += (class'X2StrategyElement_DefaultMissionSources'.static.GetAverageGPDoomRemoval());

	return Round(TotalDoomToRemove);
}


// #######################################################################################
// -------------------- UPDATE -----------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
// Loop through actions and perform any that are applicable
function Update(optional bool bActionsOnly = false)
{
	local name ActionName;
	local X2AlienStrategyActionTemplate Action;
	local X2StrategyElementTemplateManager StrategyElementMgr;
	local UIStrategyMap StrategyMap;

	StrategyElementMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	foreach Actions(ActionName)
	{
		Action = X2AlienStrategyActionTemplate(StrategyElementMgr.FindStrategyElementTemplate(ActionName));

		if(Action != none && Action.CanPerformAction())
		{
			Action.PerformActionFn();

			// Only perform one action in case HQ updates
			break;
		}
	}

	if(!bActionsOnly)
	{
		UpdateDarkEvents();

		StrategyMap = `HQPRES.StrategyMap2D;
		if(StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight)
		{
			HandlePendingDoom();
		}
	}
}

// #######################################################################################
// -------------------- FORCE LEVEL ------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
native function int GetForceLevel();

//---------------------------------------------------------------------------------------
function IncreaseForceLevel()
{
	local int ForceLevelInterval;

	ForceLevel = Clamp((ForceLevel+1), default.AlienHeadquarters_StartingForceLevel, default.AlienHeadquarters_MaxForceLevel);

	if(ForceLevel < default.AlienHeadquarters_MaxForceLevel)
	{
		// Reset timer if still below max force level
		ForceLevelInterval = GetForcelLevelInterval();

		if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
		{
			ForceLevelInterval += `SYNC_RAND(GetForcelLevelIntervalVariance());
		}
		else
		{
			ForceLevelInterval -= `SYNC_RAND(GetForcelLevelIntervalVariance());
		}

		ForceLevelIntervalStartTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
		ForceLevelIntervalEndTime = ForceLevelIntervalStartTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(ForceLevelIntervalEndTime, ForceLevelInterval);
	}
	else
	{
		// We don't need to increase force level anymore
		ForceLevelIntervalEndTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function EndOfMonth(XComGameState NewGameState)
{
	DeactivateEndOfMonthEvents(NewGameState);
	ExtendCurrentDarkEvents(NewGameState);
	ChooseDarkEvents(NewGameState);
}

// #######################################################################################
// -------------------- DOOM -------------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function int GetCurrentDoom(optional bool bIgnorePending = false)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local int TotalDoom;

	TotalDoom = Doom;
	History = `XCOMHISTORY;
	
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Available)
		{
			TotalDoom += MissionState.Doom;
		}	
	}

	if(!bIgnorePending)
	{
		TotalDoom -= GetPendingDoom();
	}

	return TotalDoom;
}

//---------------------------------------------------------------------------------------
function int GetMaxDoom()
{
	return GetMaxDoomAtDifficulty();
}

//---------------------------------------------------------------------------------------
function bool AtMaxDoom()
{
	return (GetCurrentDoom(true) >= GetMaxDoom());
}

//---------------------------------------------------------------------------------------
function ModifyDoom(optional int Amount = 1)
{
	Doom += Amount;
	Doom = Clamp(Doom, 0, GetMaxDoom());
}

//---------------------------------------------------------------------------------------
function OnFacilityDoomTimerComplete(XComGameState NewGameState)
{
	AddDoomToRandomFacility(NewGameState, NextFacilityDoomToAdd);
	
	//	if(!bHasSeenDoomPopup)
	//	{
	//		DoomAddedSite.bNeedsDoomPopup = true;
	//		DoomAddedSite = none;
	//	}

	StartGeneratingFacilityDoom();
}

//---------------------------------------------------------------------------------------
function OnFortressDoomTimerComplete(XComGameState NewGameState)
{
	AddDoomToFortress(NewGameState, NextFortressDoomToAdd);
	StartGeneratingFortressDoom();
}

//---------------------------------------------------------------------------------------
function MakeFortressAvailable(XComGameState NewGameState)
{
	local XComGameState_MissionSite MissionState;

	MissionState = GetAndAddFortressMission(NewGameState);

	if(!MissionState.Available)
	{
		bHasSeenFortress = true;
		MissionState.Available = true;
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgress', MissionState.Doom);
	}
}

//---------------------------------------------------------------------------------------
function array<XComGameState_MissionSite> GetValidFacilityDoomMissions(optional bool bExcludeUnlocked = false)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local array<XComGameState_MissionSite> Facilities;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.GetMissionSource().bAlienNetwork && MissionState.Available && MissionState.MakesDoom())
		{
			// If excluding unlocked missions, only add if the region has not been contacted and threshold not met
			if (bExcludeUnlocked)
			{
				if (!MissionState.GetWorldRegion().HaveMadeContact() && MissionState.bNotAtThreshold)
				{
					Facilities.AddItem(MissionState);
				}
			}
			else // Otherwise add all valid facilities
			{
				Facilities.AddItem(MissionState);
			}
		}
	}

	return Facilities;
}

//---------------------------------------------------------------------------------------
function StartGeneratingFacilityDoom()
{
	local int HoursToAdd;

	HoursToAdd = GetFacilityDoomHours();

	if(HoursToAdd < 0)
	{
		StopGeneratingFacilityDoom();
	}
	else
	{
		bGeneratingFacilityDoom = true;
		CalculateNextFacilityDoomToAdd();
		FacilityDoomIntervalStartTime = `STRATEGYRULES.GameTime;
		FacilityDoomIntervalEndTime = FacilityDoomIntervalStartTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(FacilityDoomIntervalEndTime, HoursToAdd);
		FacilityDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityDoomIntervalEndTime, FacilityDoomIntervalStartTime);
	}
}

//---------------------------------------------------------------------------------------
function CalculateNextFacilityDoomToAdd()
{
	NextFacilityDoomToAdd = class'X2StrategyGameRulesetDataStructures'.static.RollForDoomAdded(default.FacilityDoomAdd[`DifficultySetting]);
}

//---------------------------------------------------------------------------------------
function StartGeneratingFortressDoom(optional bool bFirstTime = false)
{
	local int HoursToAdd;

	if(bFirstTime)
	{
		HoursToAdd = GetMinFortressStartingDoomInterval() + `SYNC_RAND(GetMaxFortressStartingDoomInterval() - GetMinFortressStartingDoomInterval() + 1);
	}
	else
	{
		HoursToAdd = GetMinFortressDoomInterval() + `SYNC_RAND(GetMaxFortressDoomInterval() - GetMinFortressDoomInterval() + 1);
	}
	

	if(HoursToAdd < 0)
	{
		StopGeneratingFortressDoom();
	}
	else
	{
		if(bAcceleratingDoom)
		{
			HoursToAdd = Round(float(HoursToAdd) * DoomAccelerateTimeScalar);
		}
		else if(bThrottlingDoom)
		{
			HoursToAdd = Round(float(HoursToAdd) * DoomThrottleTimeScalar);
		}

		bGeneratingFortressDoom = true;
		CalculateNextFortressDoomToAdd();
		FortressDoomIntervalStartTime = `STRATEGYRULES.GameTime;
		FortressDoomIntervalEndTime = FortressDoomIntervalStartTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(FortressDoomIntervalEndTime, HoursToAdd);
		FortressDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FortressDoomIntervalEndTime, FortressDoomIntervalStartTime);
	}
}

//---------------------------------------------------------------------------------------
function CalculateNextFortressDoomToAdd()
{
	NextFortressDoomToAdd = class'X2StrategyGameRulesetDataStructures'.static.RollForDoomAdded(default.FortressDoomAdd[`DifficultySetting]);
}

//---------------------------------------------------------------------------------------
function int GetFacilityDoomHours()
{
	local array<XComGameState_MissionSite> Facilities;
	local DoomGenData ChosenDoomData;
	local int Hours;

	Facilities = GetValidFacilityDoomMissions();

	if(Facilities.Length == 0)
	{
		return -1;
	}

	ChosenDoomData = GetFacilityDoomData(Facilities.Length);

	Hours = (ChosenDoomData.MinInterval + `SYNC_RAND(ChosenDoomData.MaxInterval - ChosenDoomData.MinInterval + 1));

	if(bAcceleratingDoom)
	{
		Hours = Round(float(Hours) * DoomAccelerateTimeScalar);
	}
	else if(bThrottlingDoom)
	{
		Hours = Round(float(Hours) * DoomThrottleTimeScalar);
	}

	return Hours;
}

//---------------------------------------------------------------------------------------
private function DoomGenData GetFacilityDoomData(int NumFacilities)
{
	local DoomGenData HighestDoomData;
	local int idx;
	
	HighestDoomData = FacilityDoomData[0];

	for(idx = 0; idx < default.FacilityDoomData.Length; idx++)
	{
		if(NumFacilities == FacilityDoomData[idx].NumFacilities)
		{
			// Found exact match
			return FacilityDoomData[idx];
		}

		if(FacilityDoomData[idx].NumFacilities > HighestDoomData.NumFacilities)
		{
			HighestDoomData = FacilityDoomData[idx];
		}
	}

	// Didn't find match so use highest value
	return HighestDoomData;
}

//---------------------------------------------------------------------------------------
function UpdateFacilityDoomHours(bool bPickLower)
{
	local int NewHours, OldHours;

	OldHours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(FacilityDoomIntervalEndTime, `STRATEGYRULES.GameTime);
	NewHours = GetFacilityDoomHours();

	if(bPickLower && NewHours < OldHours)
	{
		class'X2StrategyGameRulesetDataStructures'.static.RemoveTime(FacilityDoomIntervalEndTime, float((OldHours - NewHours) * 3600));
	}
	else if(!bPickLower && NewHours > OldHours)
	{
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(FacilityDoomIntervalEndTime, (NewHours - OldHours));
	}
}

//---------------------------------------------------------------------------------------
function StopGeneratingFacilityDoom()
{
	bGeneratingFacilityDoom = false;
	FacilityDoomIntervalEndTime.m_iYear = 9999;
}

//---------------------------------------------------------------------------------------
function StopGeneratingFortressDoom()
{
	bGeneratingFortressDoom = false;
	FortressDoomIntervalEndTime.m_iYear = 9999;
}

//---------------------------------------------------------------------------------------
function PauseDoomTimers()
{
	// Update Time remaining and set end time to unreachable future
	if(bGeneratingFacilityDoom)
	{
		FacilityDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityDoomIntervalEndTime, `STRATEGYRULES.GameTime);
		FacilityDoomIntervalEndTime.m_iYear = 9999;
	}

	if(bGeneratingFortressDoom)
	{
		FortressDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FortressDoomIntervalEndTime, `STRATEGYRULES.GameTime);
		FortressDoomIntervalEndTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function ResumeDoomTimers(optional bool bGracePeriod = false)
{
	local float TimeToAdd;

	TimeToAdd = (float(DoomHoursToAddOnResume) * 3600.0f);

	if(bGracePeriod)
	{
		TimeToAdd += float(GetDoomGracePeriod()) * 3600.0;
	}

	// Update the start time then calculate the end time using the time remaining
	if(bGeneratingFacilityDoom)
	{
		FacilityDoomIntervalStartTime = `STRATEGYRULES.GameTime;
		FacilityDoomIntervalEndTime = FacilityDoomIntervalStartTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityDoomIntervalEndTime, FacilityDoomTimeRemaining + TimeToAdd);
	}

	if(bGeneratingFortressDoom)
	{
		FortressDoomIntervalStartTime = `STRATEGYRULES.GameTime;
		FortressDoomIntervalEndTime = FortressDoomIntervalStartTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddTime(FortressDoomIntervalEndTime, FortressDoomTimeRemaining + TimeToAdd);
	}
}

function PostResumeDoomTimers()
{
	DoomHoursToAddOnResume = 0;
	FacilityHoursToAddOnResume = 0;
}

//---------------------------------------------------------------------------------------
function DelayDoomTimers(int NumHours)
{
	if(InLoseMode())
	{
		DoomHoursToAddOnResume = NumHours;
	}
	else
	{
		if(bGeneratingFacilityDoom)
		{
			class'X2StrategyGameRulesetDataStructures'.static.AddHours(FacilityDoomIntervalEndTime, NumHours);
			FacilityDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityDoomIntervalEndTime, GetCurrentTime());
		}

		if(bGeneratingFortressDoom)
		{
			class'X2StrategyGameRulesetDataStructures'.static.AddHours(FortressDoomIntervalEndTime, NumHours);
			FortressDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FortressDoomIntervalEndTime, GetCurrentTime());
		}
	}
}

//---------------------------------------------------------------------------------------
function AddDoomToRandomFacility(XComGameState NewGameState, int DoomToAdd, optional string DoomMessage)
{
	local XComGameState_MissionSite MissionState;
	local array<XComGameState_MissionSite> Facilities;
	local PendingDoom DoomPending;
	local XGParamTag ParamTag;
	local int DoomDiff;

	DoomDiff = GetMaxDoom() - GetCurrentDoom(true);
	DoomToAdd = Clamp(DoomToAdd, 0, DoomDiff);

	Facilities = GetValidFacilityDoomMissions();

	if(Facilities.Length > 0)
	{
		MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', Facilities[`SYNC_RAND(Facilities.Length)].ObjectID));
		NewGameState.AddStateObject(MissionState);
		MissionState.Doom += DoomToAdd;
		DoomPending.Doom = DoomToAdd;

		if(DoomMessage != "")
		{
			DoomPending.DoomMessage = DoomMessage;
		}
		else
		{
			ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			ParamTag.StrValue0 = MissionState.GetWorldRegion().GetDisplayName();
			DoomPending.DoomMessage = `XEXPAND.ExpandString(default.FacilityDoomLabel);
		}
		
		PendingDoomData.AddItem(DoomPending);
		PendingDoomEntity = MissionState.GetReference();
		PendingDoomEvent = 'OnFacilityAddsDoom';

		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgress', DoomToAdd);
	}
	else
	{
		// Should not reach this case if coming from facility timer (only through dark events)
		AddDoomToFortress(NewGameState, DoomToAdd, DoomMessage);
	}
}

//---------------------------------------------------------------------------------------
function AddDoomToFortress(XComGameState NewGameState, int DoomToAdd, optional string DoomMessage, optional bool bCreatePendingDoom = true)
{
	local XComGameState_MissionSite MissionState;
	local PendingDoom DoomPending;
	local int DoomDiff;

	DoomDiff = GetMaxDoom() - GetCurrentDoom(true);
	DoomToAdd = Clamp(DoomToAdd, 0, DoomDiff);

	MissionState = GetAndAddFortressMission(NewGameState);

	if(MissionState != none)
	{
		MissionState.Doom += DoomToAdd;

		if(bCreatePendingDoom)
		{
			DoomPending.Doom = DoomToAdd;

			if(DoomMessage != "")
			{
				DoomPending.DoomMessage = DoomMessage;
			}
			else
			{
				DoomPending.DoomMessage = default.HiddenDoomLabel;
			}

			PendingDoomData.AddItem(DoomPending);
		}
		
		PendingDoomEntity = MissionState.GetReference();

		if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T5_M1_AutopsyTheAvatar'))
			PendingDoomEvent = 'OnFortressAddsDoomEndgame';
		else
			PendingDoomEvent = 'OnFortressAddsDoom';

		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgress', DoomToAdd);
	}
}

//---------------------------------------------------------------------------------------
function RemoveDoomFromFortress(XComGameState NewGameState, int DoomToRemove, optional string DoomMessage, optional bool bCreatePendingDoom = true)
{
	local XComGameState_MissionSite MissionState;
	local PendingDoom DoomPending;

	MissionState = GetAndAddFortressMission(NewGameState);
	DoomToRemove = Clamp(DoomToRemove, 0, MissionState.Doom);

	if(MissionState != none)
	{
		MissionState.Doom -= DoomToRemove;

		if(bCreatePendingDoom)
		{
			DoomPending.Doom = -DoomToRemove;

			if(DoomMessage != "")
			{
				DoomPending.DoomMessage = DoomMessage;
			}
			else
			{
				DoomPending.DoomMessage = default.HiddenDoomLabel;
			}

			PendingDoomData.AddItem(DoomPending);
			PendingDoomEntity = MissionState.GetReference();
		}
	}
}

//---------------------------------------------------------------------------------------
function XComGameState_MissionSite GetFortressMission()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Final')
		{
			return MissionState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_MissionSite GetAndAddFortressMission(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Final')
		{
			return MissionState;
		}
	}


	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Final')
		{
			MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
			NewGameState.AddStateObject(MissionState);
			return MissionState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function StartThrottlingDoom()
{
	local DoomGenData ChosenDoomData;
	local array<XComGameState_MissionSite> Facilities;
	local AlienFacilityBuildData FacilityData;
	local TDateTime CurrentTime;
	local float MaxTime;

	bThrottlingDoom = true;
	DoomThrottleTimeScalar = GetDoomThrottleScalar();

	// Only adjust doom timers if not In Lose Mode or accelerating doom
	if(!InLoseMode() && !bAcceleratingDoom)
	{
		CurrentTime = GetCurrentTime();

		if(bGeneratingFacilityDoom)
		{
			Facilities = GetValidFacilityDoomMissions();
			ChosenDoomData = GetFacilityDoomData(Facilities.Length);
			MaxTime = (float(ChosenDoomData.MaxInterval) * 3600.0f);
			FacilityDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityDoomIntervalEndTime, CurrentTime);

			// Prevent doubling up
			if(FacilityDoomTimeRemaining < MaxTime)
			{
				FacilityDoomTimeRemaining *= DoomThrottleTimeScalar;
				FacilityDoomIntervalEndTime = CurrentTime;
				class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityDoomIntervalEndTime, FacilityDoomTimeRemaining);
			}
		}

		if(bGeneratingFortressDoom)
		{
			MaxTime = (float(GetMaxFortressDoomInterval()) * 3600.0f);
			FortressDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FortressDoomIntervalEndTime, CurrentTime);

			// Prevent doubling up
			if(FortressDoomTimeRemaining < MaxTime)
			{
				FortressDoomTimeRemaining *= DoomThrottleTimeScalar;
				FortressDoomIntervalEndTime = CurrentTime;
				class'X2StrategyGameRulesetDataStructures'.static.AddTime(FortressDoomIntervalEndTime, FortressDoomTimeRemaining);
			}
		}

		if(bBuildingFacility)
		{
			FacilityData = GetMonthlyFacilityBuildData();
			MaxTime = (float(FacilityData.MaxBuildDays) * 24.0f * 3600.0f);
			FacilityBuildTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityBuildEndTime, CurrentTime);

			// Prevent doubling up
			if(FacilityBuildTimeRemaining < MaxTime)
			{
				FacilityBuildTimeRemaining *= DoomThrottleTimeScalar;
				FacilityBuildEndTime = CurrentTime;
				class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityBuildEndTime, FacilityBuildTimeRemaining);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function StopThrottlingDoom()
{
	// Let current timers play out as they are, regular values will be restored on next interval calculation
	bThrottlingDoom = false;
}

//---------------------------------------------------------------------------------------
function StartAcceleratingDoom()
{
	local TDateTime CurrentTime;
	local float ScalarToApply;

	ScalarToApply = GetDoomAccelerateScalar();

	if(bAcceleratingDoom)
	{
		DoomAccelerateTimeScalar *= ScalarToApply;
	}
	else
	{
		DoomAccelerateTimeScalar = ScalarToApply;
	}

	bAcceleratingDoom = true;
	
	if(bThrottlingDoom)
	{
		ScalarToApply /= DoomThrottleTimeScalar;
	}

	if(!InLoseMode())
	{
		CurrentTime = GetCurrentTime();

		if(bGeneratingFacilityDoom)
		{
			FacilityDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityDoomIntervalEndTime, CurrentTime);
			FacilityDoomTimeRemaining *= ScalarToApply;
			FacilityDoomIntervalEndTime = CurrentTime;
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityDoomIntervalEndTime, FacilityDoomTimeRemaining);
		}

		if(bGeneratingFortressDoom)
		{
			FortressDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FortressDoomIntervalEndTime, CurrentTime);
			FortressDoomTimeRemaining *= ScalarToApply;
			FortressDoomIntervalEndTime = CurrentTime;
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(FortressDoomIntervalEndTime, FortressDoomTimeRemaining);
		}

		if(bBuildingFacility)
		{
			FacilityBuildTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityBuildEndTime, CurrentTime);
			FacilityBuildTimeRemaining *= ScalarToApply;
			FacilityBuildEndTime = CurrentTime;
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityBuildEndTime, FacilityBuildTimeRemaining);
		}
	}
}

//---------------------------------------------------------------------------------------
function StopAcceleratingDoom()
{
	local TDateTime CurrentTime;

	// Adjust timers to regular or throttled values if applicable
	bAcceleratingDoom = false;

	if(InLoseMode())
	{
		// Only recalculate time remaining
		if(bGeneratingFacilityDoom)
		{
			FacilityDoomTimeRemaining /= DoomAccelerateTimeScalar;
		}

		if(bGeneratingFortressDoom)
		{
			FortressDoomTimeRemaining /= DoomAccelerateTimeScalar;
		}

		if(bBuildingFacility)
		{
			FacilityBuildTimeRemaining /= DoomAccelerateTimeScalar;
		}
	}
	else
	{
		// recalculate time remaining, extend timers
		CurrentTime = GetCurrentTime();

		if(bGeneratingFacilityDoom)
		{
			FacilityDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityDoomIntervalEndTime, CurrentTime);
			FacilityDoomTimeRemaining /= DoomAccelerateTimeScalar;
			FacilityDoomIntervalEndTime = CurrentTime;
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityDoomIntervalEndTime, FacilityDoomTimeRemaining);
		}

		if(bGeneratingFortressDoom)
		{
			FortressDoomTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FortressDoomIntervalEndTime, CurrentTime);
			FortressDoomTimeRemaining /= DoomAccelerateTimeScalar;
			FortressDoomIntervalEndTime = CurrentTime;
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(FortressDoomIntervalEndTime, FortressDoomTimeRemaining);
		}

		if(bBuildingFacility)
		{
			FacilityBuildTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityBuildEndTime, CurrentTime);
			FacilityBuildTimeRemaining /= DoomAccelerateTimeScalar;
			FacilityBuildEndTime = CurrentTime;
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityBuildEndTime, FacilityBuildTimeRemaining);
		}
	}
	
	DoomAccelerateTimeScalar = 0.0f;

	if(bThrottlingDoom)
	{
		// Have to apply the throttling values
		StartThrottlingDoom();
	}
}

//---------------------------------------------------------------------------------------
function bool InLoseMode()
{
	return (AIMode == "Lose");
}

// #######################################################################################
// -------------------- FACILITIES -------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function XComGameState_WorldRegion GetFacilityRegion()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_WorldRegion> ValidRegions, ContactRegions, FacilityRegions, PreferredRegions;
	local int MinLinkDistance, MaxLinkDistance, FacilityLinkDistance, CurrentDiff, idx;
	local array<int> LinkDistances;
	local bool bContact, bFacility;

	History = `XCOMHISTORY;
	MinLinkDistance = MinDesiredLinkDistance;
	MaxLinkDistance = MaxDesiredLinkDistance;

	// Grab all regions, contacted regions, facility regions, and the rest (preferred) 
	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		bContact = (RegionState.HaveMadeContact() || RegionState.bCanScanForContact);
		bFacility = (RegionState.AlienFacility.ObjectID != 0);

		if(bContact)
		{
			ContactRegions.AddItem(RegionState);
		}

		if(bFacility)
		{
			FacilityRegions.AddItem(RegionState);
		}

		if(!bContact && !bFacility)
		{
			// Ideally we pick one of the preferred regions
			PreferredRegions.AddItem(RegionState);
		}
	}

	// Try to find valid regions from the preferred list
	if(PreferredRegions.Length > 0)
	{
		// Optimization if only one preferred region
		if(PreferredRegions.Length == 1)
		{
			return PreferredRegions[0];
		}

		// Are there any preferred regions in the distance range we want?
		for(idx = 0; idx < PreferredRegions.Length; idx++)
		{
			FacilityLinkDistance = PreferredRegions[idx].FindClosestRegion(ContactRegions, RegionState);
			LinkDistances[idx] = FacilityLinkDistance;

			if(FacilityLinkDistance >= MinLinkDistance && FacilityLinkDistance <= MaxLinkDistance)
			{
				ValidRegions.AddItem(PreferredRegions[idx]);
			}
		}

		// If none are in the right range look for ones closest to the range (on either side)
		if(ValidRegions.Length == 0)
		{
			CurrentDiff = 100;

			for(idx = 0; idx < LinkDistances.Length; idx++)
			{
				if(MinLinkDistance - LinkDistances[idx] >= 0 && MinLinkDistance - LinkDistances[idx] < CurrentDiff)
				{
					CurrentDiff = MinLinkDistance - LinkDistances[idx];
				}
				else if(LinkDistances[idx] - MaxLinkDistance >= 0 && LinkDistances[idx] - MaxLinkDistance < CurrentDiff)
				{
					CurrentDiff = LinkDistances[idx] - MaxLinkDistance;
				}
			}

			for(idx = 0; idx < LinkDistances.Length; idx++)
			{
				if(MinLinkDistance - LinkDistances[idx] == CurrentDiff)
				{
					ValidRegions.AddItem(PreferredRegions[idx]);
				}
				else if(LinkDistances[idx] - MaxLinkDistance == CurrentDiff)
				{
					ValidRegions.AddItem(PreferredRegions[idx]);
				}
			}
		}

		// Optimization if only 1 valid region
		if(ValidRegions.Length == 1)
		{
			return ValidRegions[0];
		}

		// Pick one of the regions that is farthest from other facility regions
		LinkDistances.Length = 0;
		PreferredRegions.Length = 0;

		for(idx = 0; idx < ValidRegions.Length; idx++)
		{
			LinkDistances[idx] = ValidRegions[idx].FindClosestRegion(FacilityRegions, RegionState);
		}

		CurrentDiff = -100;

		for(idx = 0; idx < LinkDistances.Length; idx++)
		{
			if(LinkDistances[idx] > CurrentDiff)
			{
				CurrentDiff = LinkDistances[idx];
			}
		}

		for(idx = 0; idx < LinkDistances.Length; idx++)
		{
			if(LinkDistances[idx] == CurrentDiff)
			{
				PreferredRegions.AddItem(ValidRegions[idx]);
			}
		}

		// WE FINALLY FOUND SOME GOOD'UNS
		return PreferredRegions[`SYNC_RAND(PreferredRegions.Length)];
	}
	
	// Only valid regions are contacted regions.. boooooo
	for(idx = 0; idx < ContactRegions.Length; idx++)
	{
		// Can't have a facility (prefer not having an outpost)
		if(ContactRegions[idx].AlienFacility.ObjectID == 0)
		{
			ValidRegions.AddItem(ContactRegions[idx]);

			if(ContactRegions[idx].ResistanceLevel != eResLevel_Outpost && !ContactRegions[idx].bCanScanForOutpost)
			{
				PreferredRegions.AddItem(ContactRegions[idx]);
			}
		}
	}

	// Non outpost contact region
	if(PreferredRegions.Length > 0)
	{
		return PreferredRegions[`SYNC_RAND(PreferredRegions.Length)];
	}
	
	// Just put it anywhere, I don't care anymore
	if(ValidRegions.Length > 0)
	{
		return ValidRegions[`SYNC_RAND(ValidRegions.Length)];
	}

	// Good work on reaching this point. You don't get a facility now.
	return none;
}

//---------------------------------------------------------------------------------------
function AlienFacilityBuildData GetMonthlyFacilityBuildData(optional int SetMonth = -1)
{
	local TDateTime StartDate;
	local array<AlienFacilityBuildData> arrBuildData;
	local AlienFacilityBuildData FacilityData, HighestMonthFacilityData;
	local int iMonth, idx;

	if(SetMonth >= 0)
	{
		iMonth = SetMonth;
	}
	else
	{
		class'X2StrategyGameRulesetDataStructures'.static.SetTime(StartDate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
		class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);

		iMonth = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(GetCurrentTime(), StartDate) + 1;
	}

	arrBuildData = GetMonthlyFacilityBuildDataAtDifficulty();

	for(idx = 0; idx < arrBuildData.Length; idx++)
	{
		FacilityData = arrBuildData[idx];

		if(FacilityData.Month == iMonth)
		{
			// found a match
			return FacilityData;
		}

		if(FacilityData.Month > HighestMonthFacilityData.Month)
		{
			HighestMonthFacilityData = FacilityData;
		}
	}

	// Past the end of array, use the latest month data
	return HighestMonthFacilityData;
}

//---------------------------------------------------------------------------------------
function BuildAlienFacility(XComGameState NewGameState)
{
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local array<XComGameState_Reward> MissionRewards;
	local XComGameState_MissionSite MissionState;
	local X2MissionSourceTemplate MissionSource;
	local XComGameState_WorldRegion RegionState;

	// Grab Region
	RegionState = GetFacilityRegion();

	// Need valid region, and don't spawn facilities if doom timer is already counting down
	if(RegionState != none && !InLoseMode())
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
		NewGameState.AddStateObject(RegionState);

		// Create Mission
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(RewardState);
		MissionRewards.AddItem(RewardState);

		MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_AlienNetwork'));
		MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite'));
		NewGameState.AddStateObject(MissionState);

		MissionState.BuildMission(MissionSource, RegionState.GetRandom2DLocationInRegion(), RegionState.GetReference(), MissionRewards, true, false);

		// If the region has not yet been contacted, the facility is not at the threshold
		if (!RegionState.HaveMadeContact())
		{
			MissionState.bNotAtThreshold = true;
		}

		RegionState.bDoomFactoryPopup = true;
		RegionState.SetShortestPathToContactRegion(NewGameState);
		RegionState.AlienFacility = MissionState.GetReference();
		
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AlienFacilitiesBuilt');
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgress', MissionState.Doom);
	}
	
	StartBuildingFacilities();
}

//---------------------------------------------------------------------------------------
function SetFacilityBuildTime(TDateTime StartDate, AlienFacilityBuildData FacilityData)
{
	local int HoursToAdd;

	FacilityBuildStartTime = StartDate;
	FacilityBuildEndTime = FacilityBuildStartTime;

	HoursToAdd = ((FacilityData.MinBuildDays * 24) + `SYNC_RAND_STATIC((FacilityData.MaxBuildDays * 24) - (FacilityData.MinBuildDays * 24) + 1));

	if(bAcceleratingDoom)
	{
		HoursToAdd = Round(float(HoursToAdd) * DoomAccelerateTimeScalar);
	}
	else if(bThrottlingDoom)
	{
		HoursToAdd = Round(float(HoursToAdd) * DoomThrottleTimeScalar);
	}

	class'X2StrategyGameRulesetDataStructures'.static.AddHours(FacilityBuildEndTime, HoursToAdd);
	FacilityBuildTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityBuildEndTime, FacilityBuildStartTime);
}

//---------------------------------------------------------------------------------------
function StartBuildingFacilities()
{
	local AlienFacilityBuildData FacilityData;

	bBuildingFacility = true;

	FacilityData = GetMonthlyFacilityBuildData();
	MinDesiredLinkDistance = FacilityData.MinLinkDistance;
	MaxDesiredLinkDistance = FacilityData.MaxLinkDistance;
	SetFacilityBuildTime(GetCurrentTime(), FacilityData);
}

//---------------------------------------------------------------------------------------
function StopBuildingFacilities()
{
	bBuildingFacility = false;
	FacilityBuildEndTime.m_iYear = 9999;
}

//---------------------------------------------------------------------------------------
function PauseFacilityTimer()
{
	// Update Time remaining and set end time to unreachable future
	if(bBuildingFacility)
	{
		FacilityBuildTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityBuildEndTime, `STRATEGYRULES.GameTime);
		FacilityBuildEndTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function ResumeFacilityTimer(optional bool bGracePeriod = false)
{
	local float TimeToAdd;

	TimeToAdd = (float(FacilityHoursToAddOnResume) * 3600.0f);

	if(bGracePeriod)
	{
		TimeToAdd += float(GetDoomGracePeriod()) * 3600.0;
	}

	// Update the start time then calculate the end time using the time remaining
	if(bBuildingFacility)
	{
		FacilityBuildStartTime = `STRATEGYRULES.GameTime;
		FacilityBuildEndTime = FacilityBuildStartTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddTime(FacilityBuildEndTime, FacilityBuildTimeRemaining + TimeToAdd);
	}
}

//---------------------------------------------------------------------------------------
function DelayFacilityTimer(int NumHours)
{
	if(InLoseMode())
	{
		FacilityHoursToAddOnResume = NumHours;
	}
	else if(bBuildingFacility)
	{
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(FacilityBuildEndTime, NumHours);
		FacilityBuildTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(FacilityBuildEndTime, GetCurrentTime());
	}
}

// #######################################################################################
// -------------------- MISSING PERSONS --------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function int GetNumMissingPersons()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local int NumMissing;

	NumMissing = 0;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		NumMissing += RegionState.GetNumMissingPersons();
	}

	return NumMissing;
}

// #######################################################################################
// -------------------- DARK EVENTS ------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function ExtendCurrentDarkEvents(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_MissionCalendar CalendarState;
	local XComGameState_DarkEvent DarkEventState;
	local TDateTime GOpsDate;
	local float TimeToAdd;
	local int idx;

	History = `XCOMHISTORY;
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
	CalendarState.GetNextDateForMissionSource('MissionSource_GuerillaOp', GOpsDate);
	TimeToAdd = float(class'X2StrategyElement_DefaultMissionSources'.default.MissionMaxDuration * 3600);
	class'X2StrategyGameRulesetDataStructures'.static.AddTime(GOpsDate, TimeToAdd);
	TimeToAdd += class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(GOpsDate, `STRATEGYRULES.GameTime);

	for(idx = 0; idx < ChosenDarkEvents.Length; idx++)
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ChosenDarkEvents[idx].ObjectID));

		if(DarkEventState != none && class'X2StrategyGameRulesetDataStructures'.static.LessThan(DarkEventState.EndDateTime, GOpsDate))
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			class'X2StrategyGameRulesetDataStructures'.static.AddTime(DarkEventState.EndDateTime, TimeToAdd);
			DarkEventState.TimeRemaining += TimeToAdd;
		}
	}
}

//---------------------------------------------------------------------------------------
function bool HaveSecretDarkEvent()
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < ChosenDarkEvents.Length; idx++)
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ChosenDarkEvents[idx].ObjectID));

		if(DarkEventState != none && DarkEventState.bSecretEvent)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function ChooseDarkEvents(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_DarkEvent DarkEventState;
	local array<XComGameState_DarkEvent> DarkEventDeck;
	local int idx, NumEvents;
	local bool bNeedsSecret;

	DarkEventDeck = BuildDarkEventDeck();
	NumEvents = GetNumDarkEventsToPlay();

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	bNeedsSecret = false;

	if(ResistanceHQ.NumMonths > 0 && !HaveSecretDarkEvent())
	{
		bNeedsSecret = true;
	}

	for(idx = 0; idx < NumEvents; idx++)
	{
		DarkEventState = DrawFromDarkEventDeck(DarkEventDeck);

		if(DarkEventState != none)
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			DarkEventState.TimesPlayed++;
			DarkEventState.Weight += DarkEventState.GetMyTemplate().WeightDeltaPerPlay;
			DarkEventState.Weight = Clamp(DarkEventState.Weight, DarkEventState.GetMyTemplate().MinWeight, DarkEventState.GetMyTemplate().MaxWeight);
			DarkEventState.StartActivationTimer();
			ChosenDarkEvents.AddItem(DarkEventState.GetReference());

			if(bNeedsSecret && idx == (NumEvents - 1))
			{
				DarkEventState.bSecretEvent = true;
				DarkEventState.SetRevealCost();
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function int GetNumDarkEventsToPlay()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int NumEvents;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	if(ResistanceHQ.NumMonths == 0)
	{
		NumEvents = default.FirstMonthNumDarkEvents;
	}
	else
	{
		NumEvents = default.NumDarkEvents;
	}

	NumEvents -= ChosenDarkEvents.Length;

	return NumEvents;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_DarkEvent> BuildDarkEventDeck()
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState, ChosenEventState;
	local array<XComGameState_DarkEvent> DarkEventDeck;
	local int idx;
	local bool bValid;

	History = `XCOMHISTORY;
		
	foreach History.IterateByClassType(class'XComGameState_DarkEvent', DarkEventState)
	{
		if(ChosenDarkEvents.Find('ObjectID', DarkEventState.ObjectID) == INDEX_NONE &&
		   ActiveDarkEvents.Find('ObjectID', DarkEventState.ObjectID) == INDEX_NONE && 
		   DarkEventState.CanActivate())
		{
			bValid = true;

			for(idx = 0; idx < ChosenDarkEvents.Length; idx++)
			{
				ChosenEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ChosenDarkEvents[idx].ObjectID));

				if(ChosenEventState.GetMyTemplate().MutuallyExclusiveEvents.Find(DarkEventState.GetMyTemplateName()) != INDEX_NONE)
				{
					bValid = false;
				}
			}

			if(bValid)
			{
				for(idx = 0; idx < DarkEventState.Weight; idx++)
				{
					DarkEventDeck.AddItem(DarkEventState);
				}
			}
		}
	}

	return DarkEventDeck;
}

//---------------------------------------------------------------------------------------
function XComGameState_DarkEvent DrawFromDarkEventDeck(out array<XComGameState_DarkEvent> DarkEventDeck)
{
	local XComGameState_DarkEvent DarkEventState;
	local int idx;

	if(DarkEventDeck.Length == 0)
	{
		return none;
	}

	// Choose an event randomly from the deck
	DarkEventState = DarkEventDeck[`SYNC_RAND_STATIC(DarkEventDeck.Length)];

	// Remove all instances of that event and mutually exclusive events from the deck
	for(idx = 0; idx < DarkEventDeck.Length; idx++)
	{
		if(DarkEventDeck[idx].ObjectID == DarkEventState.ObjectID || 
		   DarkEventState.GetMyTemplate().MutuallyExclusiveEvents.Find(DarkEventDeck[idx].GetMyTemplateName()) != INDEX_NONE)
		{
			DarkEventDeck.Remove(idx, 1);
			idx--;
		}
	}

	return DarkEventState;
}

//---------------------------------------------------------------------------------------
function UpdateDarkEvents()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState NewGameState;
	local XComGameState_DarkEvent DarkEventState;
	local StateObjectReference ActivatedEventRef;
	local int idx;
	local bool bUpdateHQ;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Activate Dark Event");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', self.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	bUpdateHQ = false;

	// Check Active Dark Events for the need to deactivate
	for(idx = 0; idx < AlienHQ.ActiveDarkEvents.Length; idx++)
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(AlienHQ.ActiveDarkEvents[idx].ObjectID));

		if(DarkEventState != none && 
		   !DarkEventState.GetMyTemplate().bInfiniteDuration &&
		   !DarkEventState.GetMyTemplate().bLastsUntilNextSupplyDrop
		   && class'X2StrategyGameRulesetDataStructures'.static.LessThan(DarkEventState.EndDateTime, `STRATEGYRULES.GameTime))
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			DarkEventState.OnDeactivated(NewGameState);
			AlienHQ.ActiveDarkEvents.Remove(idx, 1);
			bUpdateHQ = true;
			idx--;
		}
	}

	// Check Chosen Dark Events for the need to activate
	for(idx = 0; idx < AlienHQ.ChosenDarkEvents.Length; idx++)
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(AlienHQ.ChosenDarkEvents[idx].ObjectID));

		if(DarkEventState != none && class'X2StrategyGameRulesetDataStructures'.static.LessThan(DarkEventState.EndDateTime, `STRATEGYRULES.GameTime))
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);

			if(DarkEventState.CanComplete())
			{
				ActivatedEventRef = DarkEventState.GetReference();
				DarkEventState.TimesSucceeded++;
				DarkEventState.Weight += DarkEventState.GetMyTemplate().WeightDeltaPerActivate;
				DarkEventState.Weight = Clamp(DarkEventState.Weight, DarkEventState.GetMyTemplate().MinWeight, DarkEventState.GetMyTemplate().MaxWeight);
				DarkEventState.OnActivated(NewGameState);

				if(DarkEventState.GetMyTemplate().MaxDurationDays > 0 || DarkEventState.GetMyTemplate().bLastsUntilNextSupplyDrop || DarkEventState.GetMyTemplate().bInfiniteDuration)
				{
					AlienHQ.ActiveDarkEvents.AddItem(DarkEventState.GetReference());

					if(DarkEventState.GetMyTemplate().MaxDurationDays > 0)
					{
						DarkEventState.StartDurationTimer();
					}
				}
			}
			else
			{
				// Clear data if can't complete event
				DarkEventState.bSecretEvent = false;
				DarkEventState.RevealCost.ResourceCosts.Length = 0;
				DarkEventState.RevealCost.ArtifactCosts.Length = 0;
			}

			AlienHQ.ChosenDarkEvents.Remove(idx, 1);
			bUpdateHQ = true;
			break;
			
		}
	}

	if(!bUpdateHQ)
	{
		NewGameState.PurgeGameStateForObjectID(AlienHQ.ObjectID);
	}

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		if(ActivatedEventRef.ObjectID != 0)
		{
			`GAME.GetGeoscape().Pause();
			`HQPRES.UIDarkEventActivated(ActivatedEventRef);
		}
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function CancelDarkEvent(StateObjectReference DarkEventRef)
{
	ChosenDarkEvents.RemoveItem(DarkEventRef);
}

//---------------------------------------------------------------------------------------
function DeactivateEndOfMonthEvents(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < ActiveDarkEvents.Length; idx++)
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ActiveDarkEvents[idx].ObjectID));

		if(DarkEventState != none && DarkEventState.GetMyTemplate().bLastsUntilNextSupplyDrop)
		{
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			DarkEventState.OnDeactivated(NewGameState);
			ActiveDarkEvents.Remove(idx, 1);
		}
	}
}

// #######################################################################################
// -------------------- TIMER HELPERS ----------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function TDateTime GetCurrentTime()
{
	return class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
}

//---------------------------------------------------------------------------------------
function float GetAIModeTimerFraction()
{
	local float TotalTime, SpentTime;

	// TODO: Handle Paused timer
	TotalTime = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(AIModeIntervalEndTime, AIModeIntervalStartTime);
	SpentTime = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(`STRATEGYRULES.GameTime, AIModeIntervalStartTime);

	return (SpentTime/TotalTime);
}

//---------------------------------------------------------------------------------------
function GetTimerDisplayValues(out int Days, out int Hours, out int Minutes, out int Seconds)
{
	Seconds = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(AIModeIntervalEndTime, `STRATEGYRULES.GameTime);
	Minutes = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMinutes(AIModeIntervalEndTime, `STRATEGYRULES.GameTime);
	Hours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(AIModeIntervalEndTime, `STRATEGYRULES.GameTime);
	Days = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(AIModeIntervalEndTime, `STRATEGYRULES.GameTime);
	
	Seconds -= (Minutes*60);
	Minutes -= (Hours*60);
	Hours -= (Days*24);

	if(Days < 0)
	{
		Days = 0;
		Hours = 0;
		Minutes = 0;
		Seconds = 0;
		return;
	}

	if(Minutes < 0)
	{
		Hours--;

		if(Hours < 0)
		{
			Days--;

			if(Days < 0)
			{
				Days = 0;
				Hours = 0;
				Minutes = 0;
				Seconds = 0;
				return;
			}

			Hours *= -1;
			Hours = 24 - Hours;
		}

		if(Hours >= 0)
		{
			Minutes *= -1;
			Minutes = 60 - Minutes;
		}
		else
		{
			Minutes = 0;
		}
	}
	else if(Hours < 0)
	{
		Days--;

		if(Days < 0)
		{
			Days = 0;
			Hours = 0;
			Minutes = 0;
			Seconds = 0;
			return;
		}

		Hours *= -1;
		Hours = 24 - Hours;
	}

	if(Seconds < 0)
	{
		Seconds *= -1;
		Seconds = 60 - Seconds;
	}
}

//---------------------------------------------------------------------------------------
function ExtendDoomTimer(int iHours)
{
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(AIModeIntervalEndTime, iHours);
}

//#############################################################################################
//----------------   PENDING DOOM   -----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetPendingDoom()
{
	local int idx, Count;

	Count = 0;

	for(idx = 0; idx < PendingDoomData.Length; idx++)
	{
		Count += PendingDoomData[idx].Doom;
	}

	return Count;
}

//---------------------------------------------------------------------------------------
function HandlePendingDoom()
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity EntityState;
	
	// Bounce out if nothing to do
	if(PendingDoomData.Length == 0)
	{
		return;
	}

	History = `XCOMHISTORY;
	EntityState = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(PendingDoomEntity.ObjectID));

	// If we have somewhere to pan start panning there
	if(PendingDoomEntity.ObjectID != 0 && EntityState != none && EntityState.ShouldBeVisible())
	{
		`HQPRES.DoomCameraPan(EntityState, (PendingDoomData[0].Doom < 0));
	}
	else
	{
		`HQPRES.NonPanClearDoom((PendingDoomData[0].Doom < 0));
	}
}

//---------------------------------------------------------------------------------------
function ClearPendingDoom()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local StateObjectReference EmptyRef;

	// Trigger doom event and clear first entry. will handle subsequent entries on following frames
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Pending Doom");

	if(PendingDoomEvent != '')
	{
		`XEVENTMGR.TriggerEvent(PendingDoomEvent, , , NewGameState);
	}

	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', self.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	// Set Doom message if there is one
	if(PendingDoomData[0].DoomMessage != "")
	{
		`HQPRES.StrategyMap2D.StrategyMapHUD.SetDoomMessage(AlienHQ.PendingDoomData[0].DoomMessage, (PendingDoomData[0].Doom < 0),false);
	}

	AlienHQ.PendingDoomData.Remove(0, 1);
	AlienHQ.PendingDoomEntity = EmptyRef;
	AlienHQ.PendingDoomEvent = '';
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetLoseModeDuration()
{
	return default.AlienHeadquarters_LoseModeDuration[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetLoseModeVariance()
{
	return default.AlienHeadquarters_LoseModeDurationVariance[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMinLoseModeDuration()
{
	return default.AlienHeadquarters_MinLoseModeDuration[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetDoomGracePeriod()
{
	return default.DoomProjectGracePeriod[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetStartingDoom()
{
	return default.AlienHeadquarters_DoomStartValue[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMaxDoomAtDifficulty()
{
	return default.AlienHeadquarters_DoomMaxValue[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function AlienFacilityBuildData GetStartingFacilityBuildData()
{
	local int Difficulty, idx;

	Difficulty = `DifficultySetting;

	for(idx = 0; idx < default.StartingFacilityBuildData.Length; idx++)
	{
		if(default.StartingFacilityBuildData[idx].Difficulty == Difficulty)
		{
			return default.StartingFacilityBuildData[idx];
		}
	}

	`RedScreen("Failed to find Alien Facility Build Data for difficulty. @gameplay -mnauta");
}

//---------------------------------------------------------------------------------------
function array<AlienFacilityBuildData> GetMonthlyFacilityBuildDataAtDifficulty()
{
	local array<AlienFacilityBuildData> arrBuildData;
	local int Difficulty, idx;

	arrBuildData.Length = 0;
	Difficulty = `DifficultySetting;

	for(idx = 0; idx < default.MonthlyFacilityBuildData.Length; idx++)
	{
		if(default.MonthlyFacilityBuildData[idx].Difficulty == Difficulty)
		{
			arrBuildData.AddItem(default.MonthlyFacilityBuildData[idx]);
		}
	}

	if(arrBuildData.Length == 0)
	{
		`RedScreen("Failed to find Alien Facility Build Data for difficulty. @gameplay -mnauta");
	}

	return arrBuildData;
}

//---------------------------------------------------------------------------------------
function int GetDesiredDoomDays()
{
	return default.DesiredDoomDays[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetProjectedDoomFromDarkEvents()
{
	return default.ProjectedDoomFromDarkEvents[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetProjectedFacilityDoomRemoved()
{
	return default.ProjectedFacilityDoomRemoved[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetProjectedFacilitiesDestroyed()
{
	return default.ProjectedFacilitiesDestroyed[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetNumDoomGenSpeeds()
{
	return default.NumDoomGenSpeeds[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetDoomGenMaxDeviation()
{
	return default.DoomGenMaxDeviation[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetDoomGenVariance()
{
	return default.DoomGenVariance[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetDoomGenScalar()
{
	return default.DoomGenScalar[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetForcelLevelInterval()
{
	return default.AlienHeadquarters_ForceLevelInterval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetForcelLevelIntervalVariance()
{
	return default.AlienHeadquarters_ForceLevelIntervalVariance[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMaxFacilities()
{
	return default.MaxFacilities[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMinFortressAppearDays()
{
	return default.MinFortressAppearDays[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMaxFortressAppearDays()
{
	return default.MaxFortressAppearDays[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMinFortressDoomInterval()
{
	return default.MinFortressDoomInterval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMaxFortressDoomInterval()
{
	return default.MaxFortressDoomInterval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMinFortressStartingDoomInterval()
{
	return default.MinFortressStartingDoomInterval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMaxFortressStartingDoomInterval()
{
	return default.MaxFortressStartingDoomInterval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetFacilityDestructionDoomDelay()
{
	return default.FacilityDestructionDoomDelay[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetDoomThrottleMinPercent()
{
	return default.DoomThrottleMinPercents[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetDoomThrottleScalar()
{
	return default.DoomThrottleScalars[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetDoomAccelerateScalar()
{
	return default.DoomAccelerateScalars[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
DefaultProperties
{    
}
