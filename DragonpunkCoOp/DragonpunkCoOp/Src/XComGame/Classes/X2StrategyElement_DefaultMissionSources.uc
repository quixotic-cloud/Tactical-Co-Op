//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultMissionSources.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultMissionSources extends X2StrategyElement
	config(GameData);

var config int			GOpIgnoreDarkEventCompleteWithinDays;

var config array<int>		BlacksiteMinDoomRemoval;
var config array<int>		BlacksiteMaxDoomRemoval;
var config array<int>		ForgeMinDoomRemoval;
var config array<int>		ForgeMaxDoomRemoval;
var config array<int>		PsiGateMinDoomRemoval;
var config array<int>		PsiGateMaxDoomRemoval;

var config array<DoomAddedData>		FacilityStartingDoom;
var config array<DoomAddedData>		FortressStartingDoom;

var config int			PercentChanceLandedUFO;
var config float		CouncilMissionSupplyScalar;
var config int			MissionMinDuration; // Hours
var config int			MissionMaxDuration; // Hours
var config int			MaxNumGuerillaOps;
var config array<MissionMonthDifficulty> GuerillaOpMonthlyDifficulties;
var config array<int>	EasyMonthlyDifficultyAdd;
var config array<int>	NormalMonthlyDifficultyAdd;
var config array<int>	ClassicMonthlyDifficultyAdd;
var config array<int>	ImpossibleMonthlyDifficultyAdd;

var public localized String m_strStopDoomProduction;
var public localized String m_strDoomLabel;
var public localized String m_strDoomSingular;
var public localized String m_strDoomPlural;
var public localized String m_strDoomRange;
var public localized String m_strFacilityDestroyed;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> MissionSources;

	MissionSources.AddItem(CreateStartTemplate('MissionSource_Start'));
	MissionSources.AddItem(CreateRecoverFlightDeviceTemplate());
	MissionSources.AddItem(CreateGuerillaOpTemplate());
	MissionSources.AddItem(CreateSupplyRaidTemplate());
	MissionSources.AddItem(CreateRetaliationTemplate());
	MissionSources.AddItem(CreateCouncilTemplate());
	MissionSources.AddItem(CreateLandedUFOTemplate());
	MissionSources.AddItem(CreateAvengerDefenseTemplate());
	MissionSources.AddItem(CreateBlackMarketTemplate());
	MissionSources.AddItem(CreateIntelBuyTemplate());
	MissionSources.AddItem(CreateChallengeModeTemplate());
	MissionSources.AddItem(CreateMultiplayerTemplate());
	MissionSources.AddItem(CreateAlienNetworkTemplate());

	// Golden Path
	MissionSources.AddItem(CreateMissionSource_BlackSiteTemplate());
	MissionSources.AddItem(CreateMissionSource_ForgeTemplate());
	MissionSources.AddItem(CreateMissionSource_PsiGateTemplate());
	MissionSources.AddItem(CreateMissionSource_BroadcastTemplate());

	// Final Mission
	MissionSources.AddItem(CreateFinalTemplate());

	return MissionSources;
}

// START MISSION
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateStartTemplate(Name TemplateName)
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, TemplateName);
	Template.bStart = true;
	Template.bSkipRewardsRecap = true;
	Template.DifficultyValue = 1;	
	Template.OnSuccessFn = StartOnComplete;
	Template.OnFailureFn = StartOnComplete;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;

	return Template;
}
function StartOnComplete(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	XComHQ.bJustWentOnFirstMission = true;
	MissionState.RemoveEntity(NewGameState);
}

// RECOVER FLIGHT DEVICE
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateRecoverFlightDeviceTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_RecoverFlightDevice');
	Template.bSkipRewardsRecap = true;
	Template.DifficultyValue = 1;
	Template.OnSuccessFn = RecoverFlightDeviceOnComplete;
	Template.OnFailureFn = RecoverFlightDeviceOnComplete;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Flight_Device";

	return Template;
}
function RecoverFlightDeviceOnComplete(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	MissionState.RemoveEntity(NewGameState);
}

// GUERILLA OPS
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateGuerillaOpTemplate()
{
	local X2MissionSourceTemplate Template;
	local RewardDeckEntry DeckEntry;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_GuerillaOp');
	Template.bIncreasesForceLevel = false;
	Template.bShowRewardOnPin = true;
	Template.OnSuccessFn = GuerillaOpOnSuccess;
	Template.OnFailureFn = GuerillaOpOnFailure;
	Template.OnExpireFn = GuerillaOpOnExpire;
	Template.DifficultyValue = 1;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.GorillaOps";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Guerrilla_Ops";
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromMonth;
	Template.SpawnMissionsFn = SpawnGuerillaOpsMissions;
	Template.MissionPopupFn = GuerillaOpsPopup;
	Template.WasMissionSuccessfulFn = StrategyObjectivePlusSweepCompleted;

	DeckEntry.RewardName = 'Reward_Supplies';
	DeckEntry.Quantity = 3;
	Template.RewardDeck.AddItem(DeckEntry);
	DeckEntry.RewardName = 'Reward_Scientist';
	DeckEntry.Quantity = 3;
	Template.RewardDeck.AddItem(DeckEntry);
	DeckEntry.RewardName = 'Reward_Engineer';
	DeckEntry.Quantity = 3;
	Template.RewardDeck.AddItem(DeckEntry);
	DeckEntry.RewardName = 'Reward_Soldier';
	DeckEntry.Quantity = 1;
	Template.RewardDeck.AddItem(DeckEntry);
	DeckEntry.RewardName = 'Reward_Intel';
	DeckEntry.Quantity = 2;
	Template.RewardDeck.AddItem(DeckEntry);

	return Template;
}
function GuerillaOpOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(MissionState.HasDarkEvent())
	{
		StopMissionDarkEvent(NewGameState, MissionState);
	}

	GiveRewards(NewGameState, MissionState);
	SpawnPointOfInterest(NewGameState, MissionState);
	CleanUpGuerillaOps(NewGameState, MissionState.ObjectID);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_GuerrillaOpsCompleted');
}
function GuerillaOpOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_DarkEvent DarkEventState;
	local XComGameState_BattleData BattleData;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	DarkEventState = MissionState.GetDarkEvent();
	if(DarkEventState != none)
	{
		// Completed objective then aborted or wiped still cancels dark event
		if(BattleData.OneStrategyObjectiveCompleted())
		{
			StopMissionDarkEvent(NewGameState, MissionState);
		}
		else
		{
			// Set the Dark Event to activate immediately
			DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
			NewGameState.AddStateObject(DarkEventState);
			DarkEventState.EndDateTime = `STRATEGYRULES.GameTime;
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, DarkEventState.GetPostMissionText(false), true);
		}
	}
	
	CleanUpGuerillaOps(NewGameState, MissionState.ObjectID);
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_GuerrillaOpsFailed');
}

function GuerillaOpOnExpire(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_DarkEvent DarkEventState;
	local int HoursRemaining, HoursToRemove;

	if (MissionState.HasDarkEvent())
	{
		// Set the Dark Event to activate within a minimum window
		DarkEventState = XComGameState_DarkEvent(NewGameState.CreateStateObject(class'XComGameState_DarkEvent', MissionState.GetDarkEvent().ObjectID));
		NewGameState.AddStateObject(DarkEventState);

		HoursRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(DarkEventState.EndDateTime, `STRATEGYRULES.GameTime);

		if (HoursRemaining > (default.GOpIgnoreDarkEventCompleteWithinDays * 24))
		{
			// Randomly choose how much time is taken off the dark event so it ends up within the minimum completion days
			HoursToRemove = HoursRemaining - `SYNC_RAND_STATIC(default.GOpIgnoreDarkEventCompleteWithinDays * 24 + 1);
		}

		DarkEventState.DecreaseActivationTimer(HoursToRemove);
	}

	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
}

function CleanUpGuerillaOps(XComGameState NewGameState, int CurrentMissionID)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local array<int> CleanedUpMissionIDs;


	foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_GuerillaOp' && MissionState.Available)
		{
			if(MissionState.ObjectID != CurrentMissionID)
			{
				class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
			}

			CleanedUpMissionIDs.AddItem(MissionState.ObjectID);
			MissionState.RemoveEntity(NewGameState);
		}
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_GuerillaOp' && MissionState.Available && CleanedUpMissionIDs.Find(MissionState.ObjectID) == INDEX_NONE)
		{
			if(MissionState.ObjectID != CurrentMissionID)
			{
				class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
			}

			CleanedUpMissionIDs.AddItem(MissionState.ObjectID);
			MissionState.RemoveEntity(NewGameState);
		}
	}

	`XEVENTMGR.TriggerEvent('GuerillaOpComplete', , , NewGameState);
}

function SpawnGuerillaOpsMissions(XComGameState NewGameState, int MissionMonthIndex)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local array<XComGameState_Reward> MissionRewards;
	local array<StateObjectReference> AvoidRegions, ExcludeRegions, FacilityRegions, DarkEvents;
	local StateObjectReference POIToSpawn;
	local float MissionDuration;
	local int NumOps, idx, RandIndex;
	local array<name> ExcludeList;
	local MissionMonthDifficulty Difficulty;
	local XComGameState_MissionCalendar CalendarState;

	CalendarState = GetMissionCalendar(NewGameState);

	// Set Popup flag
	CalendarState.MissionPopupSources.AddItem('MissionSource_GuerillaOp');

	// Calculate Mission Expiration timer (same for each op)
	MissionDuration = float((default.MissionMinDuration + `SYNC_RAND(default.MissionMaxDuration - default.MissionMinDuration + 1)) * 3600);

	// Clear AvoidRegions, ExcludeRegions (avoids compile warning)
	AvoidRegions.Length = 0;
	ExcludeRegions.Length = 0;

	// Exclude Golden Path Mission Regions
	AvoidRegions = GetGoldenPathMissionRegions();

	// Exclude Alien Facility Regions
	FacilityRegions = GetAlienFacilityMissionRegions();
	for(idx = 0; idx < FacilityRegions.Length; idx++)
	{
		AvoidRegions.AddItem(FacilityRegions[idx]);
	}

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	NumOps = GetNumberOfGuerillaOps(CalendarState);

	// Grab Mission Difficulties
	Difficulty = GetGuerillOpDifficulty();

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	DarkEvents = AlienHQ.ChosenDarkEvents;

	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	POIToSpawn = ResHQ.ChoosePOI(NewGameState); // Choose a random POI to be spawned if the mission is successful

	for(idx = 0; idx < NumOps; idx++)
	{
		RegionState = GetGuerillaOpRegion(ExcludeRegions, AvoidRegions);
		MissionRewards.Length = 0;
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(SelectGuerillaOpRewardType(ExcludeList, CalendarState)));
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(RewardState);
		RewardState.GenerateReward(NewGameState, , RegionState.GetReference());
		MissionRewards.AddItem(RewardState);

		MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_GuerillaOp'));
		MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite'));
		NewGameState.AddStateObject(MissionState);
		MissionState.ManualDifficultySetting = Difficulty.Difficulties[idx % Difficulty.Difficulties.Length];

		if(DarkEvents.Length > 0)
		{
			RandIndex = `SYNC_RAND_STATIC(DarkEvents.Length);
			MissionState.DarkEvent = DarkEvents[RandIndex];
			DarkEvents.Remove(RandIndex, 1);
		}

		MissionState.BuildMission(MissionSource, RegionState.GetRandom2DLocationInRegion(), RegionState.GetReference(), MissionRewards, true, true, , MissionDuration);

		// All of the GOps options will spawn the same POI if successful
		MissionState.POIToSpawn = POIToSpawn;
	}

	CalendarState.CreatedMissionSources.AddItem('MissionSource_GuerillaOp');
}



//---------------------------------------------------------------------------------------
function XComGameState_WorldRegion GetGuerillaOpRegion(out array<StateObjectReference> ExcludeRegions, array<StateObjectReference> AvoidRegions)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_WorldRegion> ContactRegions, StrictValidRegions, LooseValidRegions;

	History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
			if(RegionState.HaveMadeContact())
			{
				// Grab all contacted regions regions for fall-through case
				ContactRegions.AddItem(RegionState);

				if(AvoidRegions.Find('ObjectID', RegionState.GetReference().ObjectID) == INDEX_NONE)
				{
					// Not in same region as GP or Facility
					LooseValidRegions.AddItem(RegionState);

					if(ExcludeRegions.Find('ObjectID', RegionState.GetReference().ObjectID) == INDEX_NONE)
					{
						// Not in same region as another current GOP
						StrictValidRegions.AddItem(RegionState);
					}
				}
			}
		}

	if(StrictValidRegions.Length > 0)
	{
		RegionState = StrictValidRegions[`SYNC_RAND(StrictValidRegions.Length)];
	}
	else if(LooseValidRegions.Length > 0)
	{
		RegionState = LooseValidRegions[`SYNC_RAND(LooseValidRegions.Length)];
	}
	else
	{
		RegionState = ContactRegions[`SYNC_RAND(ContactRegions.Length)];
	}

	ExcludeRegions.AddItem(RegionState.GetReference());

	return RegionState;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfGuerillaOps(XComGameState_MissionCalendar CalendarState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int NumOps;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NumOps = XComHQ.GetCurrentResContacts(true);

	if(CalendarState.HasCreatedMissionOfSource('MissionSource_GuerillaOp'))
	{
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		NumOps = Clamp(NumOps, 0, AlienHQ.ChosenDarkEvents.Length);
	}

	return Clamp(NumOps, 0, default.MaxNumGuerillaOps);
}

//---------------------------------------------------------------------------------------
function MissionMonthDifficulty GetGuerillOpDifficulty()
{
	local TDateTime StartDate;
	local array<MissionMonthDifficulty> MissionDifficulties;
	local MissionMonthDifficulty MissionDifficulty, HighestMissionDifficulty;
	local int iMonth, idx;

	class'X2StrategyGameRulesetDataStructures'.static.SetTime(StartDate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
															  class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);

	iMonth = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(class'XComGameState_GeoscapeEntity'.static.GetCurrentTime(), StartDate) + 1;
	MissionDifficulties = GetGuerillaOpMonthlyDifficulties();

	for(idx = 0; idx < MissionDifficulties.Length; idx++)
	{
		MissionDifficulty = MissionDifficulties[idx];

		if(MissionDifficulty.Month == iMonth)
		{
			// found a match
			return MissionDifficulty;
		}

		if(MissionDifficulty.Month > HighestMissionDifficulty.Month)
		{
			HighestMissionDifficulty = MissionDifficulty;
		}
	}

	// Past the end of array, use the latest month data
	return HighestMissionDifficulty;
}

//---------------------------------------------------------------------------------------
function CreateGuerillaOpRewards(XComGameState_MissionCalendar CalendarState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local array<name> Rewards;
	local int idx, SourceIndex;
	local MissionRewardDeck RewardDeck;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_GuerillaOp'));
	Rewards = GetShuffledRewardDeck(MissionSource.RewardDeck);

	SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_GuerillaOp');

	if(SourceIndex == INDEX_NONE)
	{
		RewardDeck.MissionSource = 'MissionSource_GuerillaOp';
		CalendarState.MissionRewardDecks.AddItem(RewardDeck);
		SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_GuerillaOp');
	}

	// Append to end of current list
	for(idx = 0; idx < Rewards.Length; idx++)
	{
		CalendarState.MissionRewardDecks[SourceIndex].Rewards.AddItem(Rewards[idx]);
	}
}

//---------------------------------------------------------------------------------------
function name SelectGuerillaOpRewardType(out array<name> ExcludeList, XComGameState_MissionCalendar CalendarState)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local X2RewardTemplate RewardTemplate;
	local name RewardType;
	local bool bSingleRegion, bFoundNeededReward;
	local int SourceIndex, ExcludeIndex, idx;
	local MissionRewardDeck ExcludeDeck;
	local array<name> SkipList;
	
	SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_GuerillaOp');
	ExcludeIndex = CalendarState.MissionRewardExcludeDecks.Find('MissionSource', 'MissionSource_GuerillaOp');

	if(ExcludeIndex == INDEX_NONE)
	{
		ExcludeDeck.MissionSource = 'MissionSource_GuerillaOp';
		CalendarState.MissionRewardExcludeDecks.AddItem(ExcludeDeck);
		ExcludeIndex = CalendarState.MissionRewardExcludeDecks.Find('MissionSource', 'MissionSource_GuerillaOp');
	}

	// Refill the deck if empty
	if(SourceIndex == INDEX_NONE || CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length == 0)
	{
		CreateGuerillaOpRewards(CalendarState);
	}

	SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_GuerillaOp');

	bSingleRegion = (GetNumberOfGuerillaOps(CalendarState) == 1);

	if(bSingleRegion && NeedToResetSingleRegionExcludes(ExcludeList, CalendarState))
	{
		CalendarState.MissionRewardExcludeDecks[ExcludeIndex].Rewards.Length = 0;
	}

	// Guarantee engineer on first guerrilla ops you see
	if(!CalendarState.HasCreatedMissionOfSource('MissionSource_GuerillaOp') && ExcludeList.Length == 0)
	{
		RewardType = 'Reward_Engineer';
		ExcludeList.AddItem(RewardType);
		idx = CalendarState.MissionRewardDecks[SourceIndex].Rewards.Find(RewardType);

		if(idx != INDEX_NONE)
		{
			CalendarState.MissionRewardDecks[SourceIndex].Rewards.Remove(idx, 1);
		}
	}
	else
	{
		while(RewardType == '')
		{
			TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
			
			// Check if there is a valid reward that the player badly needs, if so use it as the reward
			for (idx = 0; idx < CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length; idx++)
			{
				if (ExcludeList.Find(CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx]) == INDEX_NONE)
				{
					if (SkipList.Find(CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx]) == INDEX_NONE)
					{
						if (!bSingleRegion || CalendarState.MissionRewardExcludeDecks[ExcludeIndex].Rewards.Find(CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx]) == INDEX_NONE)
						{
							RewardType = CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx];
							RewardTemplate = X2RewardTemplate(TemplateManager.FindStrategyElementTemplate(RewardType));
							if (RewardTemplate != none)
							{
								if (RewardTemplate.IsRewardNeededFn != none && RewardTemplate.IsRewardNeededFn())
								{
									CalendarState.MissionRewardDecks[SourceIndex].Rewards.Remove(idx, 1);
									ExcludeList.AddItem(RewardType);
									bFoundNeededReward = true;
									break;
								}
								else // If the reward does not have have an IsRewardNeededFn, or it has failed, add it to the skip list so that reward type isn't checked again
								{
									SkipList.AddItem(RewardType);
									RewardType = ''; // Clear the reward type
								}
							}
						}
					}
				}
			}

			if (!bFoundNeededReward)
			{
				for (idx = 0; idx < CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length; idx++)
				{
					if (ExcludeList.Find(CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx]) == INDEX_NONE)
					{
						if (!bSingleRegion || CalendarState.MissionRewardExcludeDecks[ExcludeIndex].Rewards.Find(CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx]) == INDEX_NONE)
						{
							RewardType = CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx];
							RewardTemplate = X2RewardTemplate(TemplateManager.FindStrategyElementTemplate(RewardType));
							if (RewardTemplate != none)
							{
								if (RewardTemplate.IsRewardAvailableFn == none || RewardTemplate.IsRewardAvailableFn())
								{
									CalendarState.MissionRewardDecks[SourceIndex].Rewards.Remove(idx, 1);
									ExcludeList.AddItem(RewardType);
									break;									
								}
								else // If IsRewardAvailableFn fails, add it to the exclude list so that reward type isn't checked again
								{
									ExcludeList.AddItem(RewardType);
									RewardType = ''; // Clear the reward type
								}
							}
						}
					}
				}
			}

			if(RewardType == '')
			{
				// If we're starting over with a new reward deck, wipe the old one to get rid of any excluded stragglers
				CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length = 0;
				CreateGuerillaOpRewards(CalendarState);
			}
		}
	}

	if(bSingleRegion)
	{
		CalendarState.MissionRewardExcludeDecks[ExcludeIndex].Rewards.AddItem(RewardType);
	}
	else
	{
		CalendarState.MissionRewardExcludeDecks[ExcludeIndex].Rewards.Length = 0;
	}

	return RewardType;
}

function bool NeedToResetSingleRegionExcludes(array<name> ExcludeList, XComGameState_MissionCalendar CalendarState)
{
	local array<name> DeckRewardTypes;
	local int SourceIndex, ExcludeIndex, idx;

	// Grab Reward types already picked for this round of GOps
	for(idx = 0; idx < ExcludeList.Length; idx++)
	{
		if(DeckRewardTypes.Find(ExcludeList[idx]) == INDEX_NONE)
		{
			DeckRewardTypes.AddItem(ExcludeList[idx]);
		}
	}

	SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_GuerillaOp');

	// Grab Rewards in the reward deck
	for(idx = 0; idx < CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length; idx++)
	{
		if(DeckRewardTypes.Find(CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx]) == INDEX_NONE)
		{
			DeckRewardTypes.AddItem(CalendarState.MissionRewardDecks[SourceIndex].Rewards[idx]);
		}
	}

	ExcludeIndex = CalendarState.MissionRewardExcludeDecks.Find('MissionSource', 'MissionSource_GuerillaOp');

	for(idx = 0; idx < DeckRewardTypes.Length; idx++)
	{
		if(CalendarState.MissionRewardExcludeDecks[ExcludeIndex].Rewards.Find(DeckRewardTypes[idx]) == INDEX_NONE)
		{
			return false;
		}
	}

	return true;
}

function GuerillaOpsPopup()
{
	`HQPRES.UIGOpsMission();
}

// SUPPLY RAID
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateSupplyRaidTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_SupplyRaid');
	Template.bIncreasesForceLevel = false;
	Template.bShowRewardOnPin = true;
	Template.bSkipRewardsRecap = true;
	Template.bDisconnectRegionOnFail = true;
	Template.OnSuccessFn = SupplyRaidOnSuccess;
	Template.OnFailureFn = SupplyRaidOnFailure;
	Template.OnExpireFn = SupplyRaidOnExpire;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.SupplyRaid_AdvConvoy";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Supply_Raid";
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromMonth;
	Template.CreateMissionsFn = CreateSupplyRaidMission;
	Template.SpawnMissionsFn = SpawnSupplyRaidMission;
	Template.MissionPopupFn = SupplyRaidPopup;
	Template.GetOverworldMeshPathFn = GetSupplyRaidOverworldMeshPath;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;

	return Template;
}
function string GetSupplyRaidOverworldMeshPath(XComGameState_MissionSite MissionState)
{
	local name ObjectiveName;

	ObjectiveName = MissionState.GeneratedMission.Mission.MissionName;
	
	switch(ObjectiveName)
	{
	case 'SupplyLineRaidATT':
		return "UI_3D.Overwold_Final.SupplyRaid_AdvTroopTrans";
	case 'SupplyLineRaidTrain':
		return "UI_3D.Overwold_Final.SupplyRaid_AdvTrain";
	case 'SupplyLineRaidConvoy':
		return "UI_3D.Overwold_Final.SupplyRaid_AdvConvoy";
	default:
		break;
	}

	return "";
}
function SupplyRaidOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	GiveRewards(NewGameState, MissionState);
	SpawnPointOfInterest(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_SupplyRaidsCompleted');
}
function SupplyRaidOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, true);
	}
	
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_SupplyRaidsFailed');
}

function SupplyRaidOnExpire(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, false);
		`XEVENTMGR.TriggerEvent('SkippedMissionLostContact', , , NewGameState);
	}
	
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_SupplyRaidsFailed');
}

function CreateSupplyRaidMission(XComGameState NewGameState, int MissionMonthIndex)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local array<XComGameState_Reward> MissionRewards;
	local StateObjectReference RegionRef;
	local Vector2D v2Loc;
	local XComGameState_MissionSite MissionState;
	local X2MissionSourceTemplate MissionSource;
	local XComGameState_MissionCalendar CalendarState;
	local bool bSeenUFO, bForceLandedUFO;

	CalendarState = GetMissionCalendar(NewGameState);
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));

	MissionRewards.Length = 0;
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(RewardState);
	MissionRewards.AddItem(RewardState);
	
	// If the player has seen a UFO but not a Landed UFO mission, force one to happen next
	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	bSeenUFO = (AlienHQ.bHasPlayerBeenIntercepted || AlienHQ.bHasPlayerAvoidedUFO);
	if (bSeenUFO && !AlienHQ.bHasPlayerSeenLandedUFOMission)
	{
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
		AlienHQ.bHasPlayerSeenLandedUFOMission = true;
		bForceLandedUFO = true;
	}
	
	// Roll on whether this should be a Supply Raid or Landed UFO mission
	if (bForceLandedUFO || (bSeenUFO && class'X2StrategyGameRulesetDataStructures'.static.Roll(PercentChanceLandedUFO)))
	{
		MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_LandedUFO'));
	}
	else
	{
		MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_SupplyRaid'));
	}

	// Build Mission, region and loc will be determined later so defer computing biome/plot data
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite'));
	NewGameState.AddStateObject(MissionState);
	MissionState.BuildMission(MissionSource, v2Loc, RegionRef, MissionRewards, false, false, , , , , false);
	CalendarState.CurrentMissionMonth[MissionMonthIndex].Missions.AddItem(MissionState.GetReference());

	CalendarState.CreatedMissionSources.AddItem(MissionSource.DataName);
}

function SpawnSupplyRaidMission(XComGameState NewGameState, int MissionMonthIndex)
{
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Reward RewardState;
	local float MissionDuration;
	local int iReward;
	local XComGameState_MissionCalendar CalendarState;

	CalendarState = GetMissionCalendar(NewGameState);

	// Calculate Mission Expiration timer (same for each op)
	MissionDuration = float((default.MissionMinDuration + `SYNC_RAND(default.MissionMaxDuration - default.MissionMinDuration + 1)) * 3600);

	// Spawn the supply raid from the current mission event		
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', CalendarState.CurrentMissionMonth[MissionMonthIndex].Missions[0].ObjectID));
	NewGameState.AddStateObject(MissionState);
	MissionState.TimeUntilDespawn = MissionDuration;
	MissionState.Available = true;
	MissionState.Expiring = true;
	MissionState.TimerStartDateTime = `STRATEGYRULES.GameTime;
	MissionState.SetProjectedExpirationDateTime(MissionState.TimerStartDateTime);
	RegionState = GetRandomContactedRegion();
	MissionState.Region = RegionState.GetReference();
	MissionState.Location = RegionState.GetRandomLocationInRegion();

	// Generate Rewards
	for(iReward = 0; iReward < MissionState.Rewards.Length; iReward++)
	{
		RewardState = XComGameState_Reward(NewGameState.CreateStateObject(class'XComGameState_Reward', MissionState.Rewards[iReward].ObjectID));
		NewGameState.AddStateObject(RewardState);
		RewardState.GenerateReward(NewGameState, , MissionState.Region);
	}

	MissionState.SetMissionData(MissionState.GetRewardType(), false, 0);
	`HQPRES.StrategyMap2D.GetMapItem(MissionState).InitStatic3DUI(MissionState);

	MissionState.PickPOI(NewGameState);

	// Set Popup flag
	CalendarState.MissionPopupSources.AddItem(MissionState.Source);
}

function SupplyRaidPopup()
{
	`HQPRES.UISupplyRaidMission();
}

// RETALIATION
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateRetaliationTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_Retaliation');
	Template.bIncreasesForceLevel = false;
	Template.bDisconnectRegionOnFail = true;
	Template.DifficultyValue = 1;
	Template.OnSuccessFn = RetaliationOnSuccess;
	Template.OnFailureFn = RetaliationOnFailure;
	Template.OnExpireFn = RetaliationOnExpire;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.Retaliation";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Retaliation";
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromMonth;
	Template.CreateMissionsFn = CreateRetaliationMission;
	Template.SpawnMissionsFn = SpawnRetaliationMission;
	Template.MissionPopupFn = RetaliationPopup;
	Template.WasMissionSuccessfulFn = StrategyObjectivePlusSweepCompleted;

	return Template;
}
function RetaliationOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	GiveRewards(NewGameState, MissionState);
	ModifyContinentSupplyYield(NewGameState, MissionState, class'XComGameState_WorldRegion'.static.GetRetaliationSuccessSupplyChangePercent());
	SpawnPointOfInterest(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_RetaliationsStopped');
}

function RetaliationOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{	
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, true);
	}
	else
	{
		ModifyRegionSupplyYield(NewGameState, MissionState, class'XComGameState_WorldRegion'.static.GetRegionDisconnectSupplyChangePercent(), , true);
	}

	MissionState.RemoveEntity(NewGameState);	
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);	
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_RetaliationsFailed');
}

function RetaliationOnExpire(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, false);
		`XEVENTMGR.TriggerEvent('SkippedMissionLostContact', , , NewGameState);
	}
	else
	{
		ModifyRegionSupplyYield(NewGameState, MissionState, class'XComGameState_WorldRegion'.static.GetRegionDisconnectSupplyChangePercent(), , false);
	}
	
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_RetaliationsFailed');	
}

function CreateRetaliationMission(XComGameState NewGameState, int MissionMonthIndex)
{
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local array<XComGameState_Reward> MissionRewards;
	local StateObjectReference RegionRef;
	local Vector2D v2Loc;
	local XComGameState_MissionSite MissionState;
	local X2MissionSourceTemplate MissionSource;
	local TDateTime SpawnDate;
	local XComGameState_MissionCalendar CalendarState;

	CalendarState = GetMissionCalendar(NewGameState);
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// Retaliation missions don't have a strategy resource reward
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(RewardState);
	MissionRewards.AddItem(RewardState);

	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_Retaliation'));
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite'));
	NewGameState.AddStateObject(MissionState);

	// Build Mission, region and loc will be determined later so defer computing biome/plot data
	MissionState.BuildMission(MissionSource, v2Loc, RegionRef, MissionRewards, false, false, , , , , false);
	CalendarState.CurrentMissionMonth[MissionMonthIndex].Missions.AddItem(MissionState.GetReference());
	SpawnDate = CalendarState.CurrentMissionMonth[MissionMonthIndex].SpawnDate;
	class'X2StrategyGameRulesetDataStructures'.static.RemoveTime(SpawnDate, CalendarState.RetaliationSpawnTimeDecrease);
	CalendarState.CurrentMissionMonth[MissionMonthIndex].SpawnDate = SpawnDate;
	CalendarState.RetaliationSpawnTimeDecrease = 0;

	CalendarState.CreatedMissionSources.AddItem('MissionSource_Retaliation');
}

function SpawnRetaliationMission(XComGameState NewGameState, int MissionMonthIndex)
{
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Reward RewardState;
	local float MissionDuration;
	local int iReward;
	local XComGameState_MissionCalendar CalendarState;
	local XComGameState_HeadquartersAlien AlienHQ;

	CalendarState = GetMissionCalendar(NewGameState);

	// Set Popup flag
	CalendarState.MissionPopupSources.AddItem('MissionSource_Retaliation');

	// Calculate Mission Expiration timer
	MissionDuration = float((default.MissionMinDuration + `SYNC_RAND(default.MissionMaxDuration - default.MissionMinDuration + 1)) * 3600);

	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', CalendarState.CurrentMissionMonth[MissionMonthIndex].Missions[0].ObjectID));
	NewGameState.AddStateObject(MissionState);
	MissionState.Available = true;
	MissionState.Expiring = true;
	MissionState.TimeUntilDespawn = MissionDuration;
	MissionState.TimerStartDateTime = `STRATEGYRULES.GameTime;
	MissionState.SetProjectedExpirationDateTime(MissionState.TimerStartDateTime);
	RegionState = GetRandomContactedRegion();
	MissionState.Region = RegionState.GetReference();
	MissionState.Location = RegionState.GetRandomLocationInRegion();

	// Generate Rewards
	for(iReward = 0; iReward < MissionState.Rewards.Length; iReward++)
	{
		RewardState = XComGameState_Reward(NewGameState.CreateStateObject(class'XComGameState_Reward', MissionState.Rewards[iReward].ObjectID));
		NewGameState.AddStateObject(RewardState);
		RewardState.GenerateReward(NewGameState, , MissionState.Region);
	}

	// Set Mission Data
	MissionState.SetMissionData(MissionState.GetRewardType(), false, 0);

	MissionState.PickPOI(NewGameState);

	// Flag AlienHQ as having spawned a Retaliation mission
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	if (AlienHQ == none)
	{
		AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
	}

	AlienHQ.bHasSeenRetaliation = true;

	`XEVENTMGR.TriggerEvent('RetaliationMissionSpawned', MissionState, MissionState, NewGameState);
}

function RetaliationPopup()
{
	`HQPRES.UIRetaliationMission();
}

// COUNCIL
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateCouncilTemplate()
{
	local X2MissionSourceTemplate Template;
	local RewardDeckEntry DeckEntry;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_Council');
	Template.bIncreasesForceLevel = false;
	Template.bDisconnectRegionOnFail = true;
	Template.OnSuccessFn = CouncilOnSuccess;
	Template.OnFailureFn = CouncilOnFailure;
	Template.OnExpireFn = CouncilOnExpire;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.Council_VIP";
	Template.MissionImage = "img://UILibrary_Common.Councilman_small";
	Template.GetMissionDifficultyFn = GetCouncilMissionDifficulty;
	Template.SpawnMissionsFn = SpawnCouncilMission;
	Template.MissionPopupFn = CouncilPopup;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;
	Template.RequireLaunchMissionPopupFn = CouncilRequireLaunchMissionPopup;

	DeckEntry.RewardName = 'Reward_Supplies';
	DeckEntry.Quantity = 1;
	Template.RewardDeck.AddItem(DeckEntry);
	DeckEntry.RewardName = 'Reward_Scientist';
	DeckEntry.Quantity = 1;
	Template.RewardDeck.AddItem(DeckEntry);
	DeckEntry.RewardName = 'Reward_Engineer';
	DeckEntry.Quantity = 1;
	Template.RewardDeck.AddItem(DeckEntry);
	DeckEntry.RewardName = 'Reward_SoldierCouncil';
	DeckEntry.Quantity = 1;
	Template.RewardDeck.AddItem(DeckEntry);

	return Template;
}
function CouncilOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local array<int> ExcludeIndices;

	ExcludeIndices = GetCouncilExcludeRewards(MissionState);
	MissionState.bUsePartialSuccessText = (ExcludeIndices.Length > 0);
	GiveRewards(NewGameState, MissionState, ExcludeIndices);
	SpawnPointOfInterest(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_CouncilMissionsCompleted');
}
function CouncilOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, true);
	}
	
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_CouncilMissionsFailed');
}
function CouncilOnExpire(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, false);
		`XEVENTMGR.TriggerEvent('SkippedMissionLostContact', , , NewGameState);
	}
	
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_CouncilMissionsFailed');
}
function array<int> GetCouncilExcludeRewards(XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local array<int> ExcludeIndices;
	local int idx;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	`assert(BattleData.m_iMissionID == MissionState.ObjectID);

	for(idx = 0; idx < BattleData.MapData.ActiveMission.MissionObjectives.Length; idx++)
	{
		if(BattleData.MapData.ActiveMission.MissionObjectives[idx].ObjectiveName == 'Capture' &&
		   !BattleData.MapData.ActiveMission.MissionObjectives[idx].bCompleted)
		{
			ExcludeIndices.AddItem(1);
		}
	}

	return ExcludeIndices;
}

//---------------------------------------------------------------------------------------
function name SelectCouncilMissionRewardType(XComGameState_MissionCalendar CalendarState)
{
	local X2StrategyElementTemplateManager TemplateManager;
	local X2RewardTemplate RewardTemplate;
	local name RewardType;
	local int SourceIndex, Index;
	local bool bFoundNeededReward;
	local array<name> SkipList;

	SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_Council');

	// Refill the deck if empty
	if(SourceIndex == INDEX_NONE || CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length == 0)
	{
		CreateCouncilMissionRewards(CalendarState);
	}

	SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_Council');

	// first council mission is always a scientist reward
	if(!CalendarState.HasCreatedMissionOfSource('MissionSource_Council'))
	{
		RewardType = 'Reward_Scientist';
		Index = CalendarState.MissionRewardDecks[SourceIndex].Rewards.Find(RewardType);

		if(Index != INDEX_NONE)
		{
			CalendarState.MissionRewardDecks[SourceIndex].Rewards.Remove(Index, 1);
		}
	}
	else
	{
		while (RewardType == '')
		{
			TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

			// Check if there is a reward that the player badly needs, if so use it as the reward
			for (Index = 0; Index < CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length; Index++)
			{
				if (SkipList.Find(CalendarState.MissionRewardDecks[SourceIndex].Rewards[Index]) == INDEX_NONE)
				{
					RewardType = CalendarState.MissionRewardDecks[SourceIndex].Rewards[Index];
					RewardTemplate = X2RewardTemplate(TemplateManager.FindStrategyElementTemplate(RewardType));
					if (RewardTemplate != none)
					{
						if (RewardTemplate.IsRewardNeededFn != none && RewardTemplate.IsRewardNeededFn())
						{
							CalendarState.MissionRewardDecks[SourceIndex].Rewards.Remove(Index, 1);
							bFoundNeededReward = true;
							break;
						}
						else // If the reward does not have have an IsRewardNeededFn, or it has failed, add it to the skip list so that reward type isn't checked again
						{
							SkipList.AddItem(RewardType);
							RewardType = ''; // Clear the reward type
						}
					}
				}
			}

			if (!bFoundNeededReward)
			{
				// take the first reward that is valid for this point in the game
				for (Index = 0; Index < CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length; Index++)
				{
					RewardType = CalendarState.MissionRewardDecks[SourceIndex].Rewards[Index];
					RewardTemplate = X2RewardTemplate(TemplateManager.FindStrategyElementTemplate(RewardType));
					if (RewardTemplate != none && (RewardTemplate.IsRewardAvailableFn == none || RewardTemplate.IsRewardAvailableFn()))
					{
						CalendarState.MissionRewardDecks[SourceIndex].Rewards.Remove(Index, 1);
						break;
					}
					else
					{
						RewardType = ''; // Clear the reward type
					}
				}
			}

			if (RewardType == '')
			{
				// If we're starting over with a new reward deck, wipe the old one to get rid of any excluded stragglers
				CalendarState.MissionRewardDecks[SourceIndex].Rewards.Length = 0;
				CreateCouncilMissionRewards(CalendarState);
			}
		}
	}

	return RewardType;
}

//---------------------------------------------------------------------------------------
function CreateCouncilMissionRewards(XComGameState_MissionCalendar CalendarState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local array<name> Rewards;
	local int idx, SourceIndex;
	local MissionRewardDeck RewardDeck;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_Council'));
	Rewards = GetShuffledRewardDeck(MissionSource.RewardDeck);

	SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_Council');

	if(SourceIndex == INDEX_NONE)
	{
		RewardDeck.MissionSource = 'MissionSource_Council';
		CalendarState.MissionRewardDecks.AddItem(RewardDeck);
		SourceIndex = CalendarState.MissionRewardDecks.Find('MissionSource', 'MissionSource_Council');
	}

	// Append to end of current list
	for(idx = 0; idx < Rewards.Length; idx++)
	{
		CalendarState.MissionRewardDecks[SourceIndex].Rewards.AddItem(Rewards[idx]);
	}
}

function SpawnCouncilMission(XComGameState NewGameState, int MissionMonthIndex)
{
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local X2MissionSourceTemplate MissionSource;
	local array<XComGameState_Reward> MissionRewards;
	local float MissionDuration;
	local XComGameState_MissionCalendar CalendarState;

	CalendarState = GetMissionCalendar(NewGameState);

	// Set Popup flag
	CalendarState.MissionPopupSources.AddItem('MissionSource_Council');

	// Calculate Mission Expiration timer
	MissionDuration = float((default.MissionMinDuration + `SYNC_RAND(default.MissionMaxDuration - default.MissionMinDuration + 1)) * 3600);
	
	RegionState = GetRandomContactedRegion();

	// Generate the mission reward
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(SelectCouncilMissionRewardType(CalendarState)));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(RewardState);
	if (RewardState.GetMyTemplateName() == 'Reward_Supplies')
		RewardState.GenerateReward(NewGameState, default.CouncilMissionSupplyScalar, RegionState.GetReference());
	else
		RewardState.GenerateReward(NewGameState, , RegionState.GetReference());
	MissionRewards.AddItem(RewardState);
	
	// All Council Missions also give an Intel reward
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Intel'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(RewardState);
	RewardState.GenerateReward(NewGameState, , RegionState.GetReference());
	MissionRewards.AddItem(RewardState);
	
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_Council'));
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite'));
	NewGameState.AddStateObject(MissionState);

	MissionState.BuildMission(MissionSource, RegionState.GetRandom2DLocationInRegion(), RegionState.GetReference(), MissionRewards, true, true, , MissionDuration);

	MissionState.PickPOI(NewGameState);

	`XEVENTMGR.TriggerEvent('CouncilMissionSpawned', MissionState, MissionState, NewGameState);
	
	CalendarState.CreatedMissionSources.AddItem('MissionSource_Council');
}

function CouncilPopup()
{
	`HQPRES.UICouncilMission();
}

function bool CouncilRequireLaunchMissionPopup(XComGameState_MissionSite MissionState)
{
	// If this is a neutralize mission, make sure a soldier can carry them out
	if (MissionState.GeneratedMission.Mission.MissionName == 'NeutralizeTarget')
	{
		return IsNoCarryUnitSoldierInSquad(MissionState);
	}

	return false;
}

// LANDED UFO
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateLandedUFOTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_LandedUFO');
	Template.bIncreasesForceLevel = false;
	Template.bSkipRewardsRecap = true;
	Template.bDisconnectRegionOnFail = true;
	Template.OnSuccessFn = LandedUFOOnSuccess;
	Template.OnFailureFn = LandedUFOOnFailure;
	Template.OnExpireFn = LandedUFOOnExpire;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.Landed_UFO";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_UFO_Landed";
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromMonth;
	Template.MissionPopupFn = LandedUFOPopup;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;

	return Template;
}

function LandedUFOOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	GiveRewards(NewGameState, MissionState);
	SpawnPointOfInterest(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_LandedUFOsCompleted');
}
function LandedUFOOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{	
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, true);
	}
	
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_LandedUFOsFailed');
}
function LandedUFOOnExpire(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, false);
		`XEVENTMGR.TriggerEvent('SkippedMissionLostContact', , , NewGameState);
	}
	
	class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_LandedUFOsFailed');		
}

function LandedUFOPopup()
{
	`HQPRES.UILandedUFOMission();
}

// AVENGER DEFENSE
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAvengerDefenseTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_AvengerDefense');
	Template.DifficultyValue = 3;
	Template.bSkipRewardsRecap = true;
	Template.CustomMusicSet = 'Tutorial';
	Template.CustomLoadingMovieName_Intro = "1080_LoadingScreen5.bk2";
	Template.bRequiresSkyRangerTravel = false;
	Template.OnSuccessFn = AvengerDefenseOnSuccess;
	Template.OnFailureFn = AvengerDefenseOnFailure;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;

	return Template;
}

function AvengerDefenseOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_UFO UFOState;
	local XComGameState_MissionSiteAvengerDefense AvengerDefense;

	AvengerDefense = XComGameState_MissionSiteAvengerDefense(MissionState);
	if (AvengerDefense != none)
	{
		UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AvengerDefense.AttackingUFO.ObjectID));
		UFOState.RemoveEntity(NewGameState);
	}

	GiveRewards(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvengerDefenseCompleted');
}
function AvengerDefenseOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	FinalMissionOnFailure(NewGameState, MissionState);
}

// BLACK MARKET
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateBlackMarketTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_BlackMarket');
	Template.DifficultyValue = 2;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;

	return Template;
}

// INTEL BUY
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateIntelBuyTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_IntelBuy');
	Template.DifficultyValue = 2;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;

	return Template;
}

// CHALLENGE MODE
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateChallengeModeTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_ChallengeMode');
	Template.bChallengeMode = true;
	Template.DifficultyValue = 2;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;

	return Template;
}

// MULTIPLAYER
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateMultiplayerTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_Multiplayer');
	Template.bMultiplayer = true;
	Template.DifficultyValue = 2;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;

	return Template;
}

// ALIEN NETWORK
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAlienNetworkTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_AlienNetwork');
	Template.bIncreasesForceLevel = false;
	Template.bAlienNetwork = true;
	Template.DifficultyValue = 3;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.AlienFacility";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Advent_Facility";
	Template.OnSuccessFn = AlienNetworkOnSuccess;
	Template.OnFailureFn = AlienNetworkOnFailure;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromDoom;
	Template.CalculateStartingDoomFn = CalculateAlienNetworkStartingDoom;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;
	Template.bMakesDoom = true;
	Template.bIgnoreDifficultyCap = true;

	return Template;
}
function int CalculateAlienNetworkStartingDoom()
{
	return class'X2StrategyGameRulesetDataStructures'.static.RollForDoomAdded(GetFacilityStartingDoom());
}
function AlienNetworkOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_WorldRegion RegionState;
	local StateObjectReference EmptyRef;
	local PendingDoom DoomPending;
	local int DoomToRemove;
	local XGParamTag ParamTag;

	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResHQ.AttemptSpawnRandomPOI(NewGameState);

	AlienHQ = GetAndAddAlienHQ(NewGameState);
	
	AlienHQ.DelayDoomTimers(AlienHQ.GetFacilityDestructionDoomDelay());
	AlienHQ.DelayFacilityTimer(AlienHQ.GetFacilityDestructionDoomDelay());

	RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));

	if (RegionState == none)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
		NewGameState.AddStateObject(RegionState);
	}

	GiveRewards(NewGameState, MissionState);
	RegionState.AlienFacility = EmptyRef;
	  
	if(MissionState.Doom > 0)
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		DoomToRemove = MissionState.Doom;
		DoomPending.Doom = -DoomToRemove;
		ParamTag.StrValue0 = MissionState.GetWorldRegion().GetDisplayName();
		DoomPending.DoomMessage = `XEXPAND.ExpandString(default.m_strFacilityDestroyed);
		AlienHQ.PendingDoomData.AddItem(DoomPending);

		ParamTag.StrValue0 = string(DoomToRemove);

		if(DoomToRemove == 1)
		{
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedSingular), false);
		}
		else
		{
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedPlural), false);
		}
	}

	MissionState.RemoveEntity(NewGameState);
	class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, class'UIRewardsRecap'.default.m_strAvatarProjectDelayed, false);
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AlienFacilitiesDestroyed');
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgressReduced', DoomToRemove);
}

function AlienNetworkOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	if(!IsInStartingRegion(MissionState))
	{
		LoseContactWithMissionRegion(NewGameState, MissionState, true);
	}
}

// #######################################################################################
// -------------------- GOLDEN PATH ------------------------------------------------------
// #######################################################################################

// GOLDEN PATH MISSIONs
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateMissionSource_BlackSiteTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_BlackSite');
	Template.bIncreasesForceLevel = false;
	Template.bGoldenPath = true;
	Template.OnSuccessFn = GoldenPathMissionOnSuccess;
	Template.DifficultyValue = 3;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.Blacksite";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Blacksite";
	Template.ResistanceActivity = 'ResAct_BlacksiteCompleted';
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.CalculateDoomRemovalFn = CalculateBlacksiteDoomRemoval;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;
	Template.SpawnUFOChance = 25;

	return Template;
}

function CalculateBlacksiteDoomRemoval(XComGameState_MissionSite MissionState)
{
	MissionState.FixedDoomToRemove = GetBlacksiteMinDoomRemoval() + `SYNC_RAND(GetBlacksiteMaxDoomRemoval() - GetBlacksiteMinDoomRemoval() + 1);
}

static function X2DataTemplate CreateMissionSource_ForgeTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_Forge');
	Template.bIncreasesForceLevel = false;
	Template.bGoldenPath = true;
	Template.OnSuccessFn = GoldenPathMissionOnSuccess;
	Template.DifficultyValue = 3;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.Forge";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Forged";
	Template.ResistanceActivity = 'ResAct_ForgeCompleted';
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.CalculateDoomRemovalFn = CalculateForgeDoomRemoval;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;
	Template.CanLaunchMissionFn = IsCarryUnitSoldierInSquad;
	Template.RequireLaunchMissionPopupFn = IsNoCarryUnitSoldierInSquad;
	Template.SpawnUFOChance = 75;

	return Template;
}

function CalculateForgeDoomRemoval(XComGameState_MissionSite MissionState)
{
	MissionState.FixedDoomToRemove = GetForgeMinDoomRemoval() + `SYNC_RAND(GetForgeMaxDoomRemoval() - GetForgeMinDoomRemoval() + 1);
}

static function X2DataTemplate CreateMissionSource_PsiGateTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_PsiGate');
	Template.bIncreasesForceLevel = false;
	Template.bGoldenPath = true;
	Template.OnSuccessFn = GoldenPathMissionOnSuccess;
	Template.DifficultyValue = 3;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.PsiGate";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_PsiGate";
	Template.ResistanceActivity = 'ResAct_PsiGateCompleted';
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.CalculateDoomRemovalFn = CalculatePsiGateDoomRemoval;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;
	Template.SpawnUFOChance = 100;

	return Template;
}

function CalculatePsiGateDoomRemoval(XComGameState_MissionSite MissionState)
{
	MissionState.FixedDoomToRemove = GetPsiGateMinDoomRemoval() + `SYNC_RAND(GetPsiGateMaxDoomRemoval() - GetPsiGateMinDoomRemoval() + 1);
}


static function X2DataTemplate CreateMissionSource_BroadcastTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_Broadcast');
	Template.bIncreasesForceLevel = false;
	Template.bGoldenPath = true;
	Template.bSkipRewardsRecap = true;
	Template.bIntelHackRewards = true;
	Template.OnSuccessFn = BroadcastMissionOnSuccess;
	Template.DifficultyValue = 3;
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.GP_BroadcastOfTruth";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Sky_Tower";
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;
	Template.CustomLoadingMovieName_Outro = "CIN_TP_BroadcastTruth.bk2";
	Template.CustomLoadingMovieName_OutroSound = "X2_031_BroadcastTheTruth";

	return Template;
}

function GoldenPathMissionOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersResistance ResHQ;
	
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResHQ.AttemptSpawnRandomPOI(NewGameState);

	SpawnUFO(NewGameState, MissionState);
	GiveRewards(NewGameState, MissionState);
	RemoveGPDoom(NewGameState, MissionState);
	RemoveIntelRewards(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);

	if (MissionState.GetMissionSource().ResistanceActivity != '')
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, MissionState.GetMissionSource().ResistanceActivity);
}

function BroadcastMissionOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	GiveRewards(NewGameState, MissionState);
	RemoveGPDoom(NewGameState, MissionState);
	RemoveIntelRewards(NewGameState, MissionState);
	MissionState.RemoveEntity(NewGameState);

	if (MissionState.GetMissionSource().ResistanceActivity != '')
	class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, MissionState.GetMissionSource().ResistanceActivity);
}

// FINAL MISSION
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateFinalTemplate()
{
	local X2MissionSourceTemplate Template;

	`CREATE_X2TEMPLATE(class'X2MissionSourceTemplate', Template, 'MissionSource_Final');
	Template.bGoldenPath = true;
	Template.bSkipRewardsRecap = true;
	Template.DifficultyValue = 4;
	Template.bMakesDoom = true;
	Template.CustomMusicSet = 'AlienFortress';
	Template.bRequiresSkyRangerTravel = false;
	Template.CustomLoadingMovieName_Outro = "CIN_Victory.bk2";
	Template.CustomLoadingMovieName_OutroSound = "X2_033_Victory";
	Template.OverworldMeshPath = "UI_3D.Overwold_Final.AlienFortress";
	Template.MissionImage = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Alien_Fortress";
	Template.OnSuccessFn = FinalMissionOnSuccess;
	Template.OnFailureFn = FinalMissionOnFailure;
	Template.GetMissionDifficultyFn = GetMissionDifficultyFromTemplate;
	Template.CalculateStartingDoomFn = CalculateFinalStartingDoom;
	Template.GetOverworldMeshPathFn = GetFinalOverworldMeshPath;
	Template.WasMissionSuccessfulFn = OneStrategyObjectiveCompleted;

	return Template;
}

function string GetFinalOverworldMeshPath(XComGameState_MissionSite MissionState)
{
	if(MissionState.bNotAtThreshold)
	{
		return "UI_3D.Overwold_Final.AvatarProject";
	}

	return "UI_3D.Overwold_Final.AlienFortress";
}

function int CalculateFinalStartingDoom()
{
	return class'X2StrategyGameRulesetDataStructures'.static.RollForDoomAdded(default.FortressStartingDoom[`DifficultySetting]);
}

function FinalMissionOnSuccess(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
	}

	// A WINNER IS YOU, COMMANDER
	XComHQ.bXComFullGameVictory = true;
	MissionState.RemoveEntity(NewGameState);

	`XACHIEVEMENT_TRACKER.FinalMissionOnSuccess();
}

function FinalMissionOnFailure(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersAlien AlienHQ;

	AlienHQ = GetAndAddAlienHQ(NewGameState);

	// YOU HAVE FAILED
	AlienHQ.bAlienFullGameVictory = true;
	MissionState.RemoveEntity(NewGameState);
}

// #######################################################################################
// -------------------- GENERIC FUNCTIONS ------------------------------------------------
// #######################################################################################
static function IncreaseForceLevel(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	if(MissionState.GetMissionSource().bIncreasesForceLevel)
	{
		History = `XCOMHISTORY;

		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
		{
			break;
		}

		if(AlienHQ == none)
		{
			AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
			AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
			NewGameState.AddStateObject(AlienHQ);
		}

		AlienHQ.IncreaseForceLevel();
	}
}
function GiveRewards(XComGameState NewGameState, XComGameState_MissionSite MissionState, optional array<int> ExcludeIndices)
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local int idx;

	History = `XCOMHISTORY;

	// First Check if we need to exclude some rewards
	for(idx = 0; idx < MissionState.Rewards.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[idx].ObjectID));
		if(RewardState != none)
		{
			if(ExcludeIndices.Find(idx) != INDEX_NONE)
			{
				RewardState.CleanUpReward(NewGameState);
				NewGameState.RemoveStateObject(RewardState.ObjectID);
				MissionState.Rewards.Remove(idx, 1);
				idx--;
			}
		}
	}

	class'XComGameState_HeadquartersResistance'.static.SetRecapRewardString(NewGameState, MissionState.GetRewardAmountString());

	// @mnauta: set VIP rewards string is deprecated, leaving blank
	class'XComGameState_HeadquartersResistance'.static.SetVIPRewardString(NewGameState, "" /*REWARDS!*/);

	for(idx = 0; idx < MissionState.Rewards.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[idx].ObjectID));

		// Give rewards
		if(RewardState != none)
		{
			RewardState.GiveReward(NewGameState);
		}

		// Remove the reward state objects
		NewGameState.RemoveStateObject(RewardState.ObjectID);
	}

	MissionState.Rewards.Length = 0;
}

function TemporarilyUnlockMissionRegion(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_WorldRegion RegionState;

	RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));

	if(RegionState == none)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
		NewGameState.AddStateObject(RegionState);
	}

	RegionState.Unlock(NewGameState);
}

function LoseContactWithMissionRegion(XComGameState NewGameState, XComGameState_MissionSite MissionState, bool bRecord)
{
	local XComGameState_WorldRegion RegionState;
	local XGParamTag ParamTag;
	local EResistanceLevelType OldResLevel;
	local int OldIncome, NewIncome, IncomeDelta;

	RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));

	if (RegionState == none)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
		NewGameState.AddStateObject(RegionState);
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = RegionState.GetMyTemplate().DisplayName;
	OldResLevel = RegionState.ResistanceLevel;
	OldIncome = RegionState.GetSupplyDropReward();

	RegionState.SetResistanceLevel(NewGameState, eResLevel_Unlocked);
	
	NewIncome = RegionState.GetSupplyDropReward();
	IncomeDelta = NewIncome - OldIncome;

	if (bRecord)
	{
		if(RegionState.ResistanceLevel < OldResLevel)
		{
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strRegionLostContact), true);
		}

		if(IncomeDelta < 0)
		{
			ParamTag.StrValue0 = string(-IncomeDelta);
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strDecreasedSupplyIncome), true);
		}
	}
}

function ModifyRegionSupplyYield(XComGameState NewGameState, XComGameState_MissionSite MissionState, float DeltaYieldPercent, optional int DeltaFromLevelChange = 0, optional bool bRecord = true)
{
	local XComGameState_WorldRegion RegionState;
	local XGParamTag ParamTag;
	local int TotalDelta, OldIncome, NewIncome;

	if (DeltaYieldPercent != 1.0)
	{
		// Region gets permanent supply bonus
		RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));
		TotalDelta = DeltaFromLevelChange;
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

		if (RegionState == none)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
			NewGameState.AddStateObject(RegionState);
		}
		
		OldIncome = RegionState.GetSupplyDropReward();
		RegionState.BaseSupplyDrop *= DeltaYieldPercent;

		if (RegionState.HaveMadeContact())
		{
			NewIncome = RegionState.GetSupplyDropReward();
			TotalDelta += (NewIncome - OldIncome);
		}
		
		if (bRecord)
		{
			if (DeltaYieldPercent < 1.0)
			{
				ParamTag.StrValue0 = RegionState.GetMyTemplate().DisplayName;
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strDecreasedRegionSupplyOutput), true);
				ParamTag.StrValue0 = string(-TotalDelta);
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strDecreasedSupplyIncome), true);
			}
			else
			{
				ParamTag.StrValue0 = RegionState.GetMyTemplate().DisplayName;
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strIncreasedRegionSupplyOutput), false);
				ParamTag.StrValue0 = string(TotalDelta);
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strIncreasedSupplyIncome), false);
			}
		}
	}
}

function ModifyContinentSupplyYield(XComGameState NewGameState, XComGameState_MissionSite MissionState, float DeltaYieldPercent, optional int DeltaFromLevelChange = 0, optional bool bRecord = true)
{
	local XComGameStateHistory History;
	local XComGameState_Continent ContinentState;
	local XComGameState_WorldRegion RegionState;
	local XGParamTag ParamTag;
	local int idx, TotalDelta, OldIncome, NewIncome;

	if(DeltaYieldPercent != 1.0)
	{
		// All Regions in continent get permanent supply bonus
		RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));
		TotalDelta = DeltaFromLevelChange;

		if(RegionState == none)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
			NewGameState.AddStateObject(RegionState);
		}

		History = `XCOMHISTORY;
		ContinentState = XComGameState_Continent(History.GetGameStateForObjectID(RegionState.Continent.ObjectID));

		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		
		
		for(idx = 0; idx < ContinentState.Regions.Length; idx++)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(ContinentState.Regions[idx].ObjectID));

			if(RegionState == none)
			{
				RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', ContinentState.Regions[idx].ObjectID));
				NewGameState.AddStateObject(RegionState);
			}

			OldIncome = RegionState.GetSupplyDropReward();
			RegionState.BaseSupplyDrop *= DeltaYieldPercent;

			if(RegionState.HaveMadeContact())
			{
				NewIncome = RegionState.GetSupplyDropReward();
				TotalDelta += (NewIncome - OldIncome);
			}
		}

		if(bRecord)
		{
			if(DeltaYieldPercent < 1.0)
			{
				ParamTag.StrValue0 = ContinentState.GetMyTemplate().DisplayName;
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strDecreasedContinentalSupplyOutput), true);
				ParamTag.StrValue0 = string(-TotalDelta);
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strDecreasedSupplyIncome), true);
			}
			else
			{
				ParamTag.StrValue0 = ContinentState.GetMyTemplate().DisplayName;
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strIncreasedContinentalSupplyOutput), false);
				ParamTag.StrValue0 = string(TotalDelta);
				class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strIncreasedSupplyIncome), false);
			}
		}
	}
}

function SpawnPointOfInterest(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;
	local XComGameState_BlackMarket BlackMarketState;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));

	if (!BlackMarketState.ShowBlackMarket(NewGameState))
	{
		if (MissionState.POIToSpawn.ObjectID != 0)
		{
			POIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(MissionState.POIToSpawn.ObjectID));

			if (POIState != none)
			{
				POIState = XComGameState_PointOfInterest(NewGameState.CreateStateObject(class'XComGameState_PointOfInterest', POIState.ObjectID));
				NewGameState.AddStateObject(POIState);
				POIState.Spawn(NewGameState);
			}
		}
	}
	else
	{
		class'XComGameState_HeadquartersResistance'.static.DeactivatePOI(NewGameState, MissionState.POIToSpawn);
	}
}

function SpawnUFO(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_UFO NewUFOState;

	// First get Alien HQ to check if a Golden Path UFO has spawned previously
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	if (AlienHQ == none)
	{
		AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
	}

	if (!AlienHQ.bHasGoldenPathUFOAppeared && MissionState.bSpawnUFO)
	{
		AlienHQ.bHasGoldenPathUFOAppeared = true;

		NewUFOState = XComGameState_UFO(NewGameState.CreateStateObject(class'XComGameState_UFO'));
		NewUFOState.OnCreation(NewGameState, true);
		NewGameState.AddStateObject(NewUFOState);
	}
}

function int GetMissionDifficultyFromDoom(XComGameState_MissionSite MissionState)
{
	local int Difficulty;

	Difficulty = MissionState.GetMissionSource().DifficultyValue;

	Difficulty += (MissionState.Doom/2);

	Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty, 5);

	return Difficulty;
}

function int GetMissionDifficultyFromTemplate(XComGameState_MissionSite MissionState)
{
	local int Difficulty;

	Difficulty = MissionState.GetMissionSource().DifficultyValue;

	Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty,
					   class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty);

	return Difficulty;
}

function int GetMissionDifficultyFromMonth(XComGameState_MissionSite MissionState)
{
	local TDateTime StartDate;
	local array<int> MonthlyDifficultyAdd;
	local int Difficulty, MonthDiff;

	class'X2StrategyGameRulesetDataStructures'.static.SetTime(StartDate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
		class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);

	Difficulty = 1;
	MonthDiff = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(class'XComGameState_GeoscapeEntity'.static.GetCurrentTime(), StartDate);
	MonthlyDifficultyAdd = GetMonthlyDifficultyAdd();

	if(MonthDiff >= MonthlyDifficultyAdd.Length)
	{
		MonthDiff = MonthlyDifficultyAdd.Length - 1;
	}

	Difficulty += MonthlyDifficultyAdd[MonthDiff];

	Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty,
						class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty);

	return Difficulty;
}

function int GetCouncilMissionDifficulty(XComGameState_MissionSite MissionState)
{
	local int Difficulty;

	Difficulty = GetMissionDifficultyFromMonth(MissionState);
	if(MissionState.GeneratedMission.Mission.sType != "Extract")
	{
		Difficulty--;
	}

	Difficulty = Clamp(Difficulty, class'X2StrategyGameRulesetDataStructures'.default.MinMissionDifficulty,
					   class'X2StrategyGameRulesetDataStructures'.default.MaxMissionDifficulty);

	return Difficulty;
}

function StopMissionDarkEvent(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersAlien AlienHQ;

	AlienHQ = GetAndAddAlienHQ(NewGameState);

	class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, MissionState.GetDarkEvent().GetPostMissionText(true), false);
	AlienHQ.CancelDarkEvent(MissionState.DarkEvent);
}

function RemoveGPDoom(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local int DoomToRemove;
	local XGParamTag ParamTag;
	local string DoomString;
	local XComGameState_MissionSite FortressMission;
	
	AlienHQ = GetAndAddAlienHQ(NewGameState);
	FortressMission = AlienHQ.GetFortressMission();

	// Remove Doom based on min/max amounts from mission
	DoomToRemove = MissionState.FixedDoomToRemove;
	DoomToRemove = Clamp(DoomToRemove, 0, FortressMission.Doom);

	if(DoomToRemove > 0)
	{
		DoomString = MissionState.GetMissionSource().DoomLabel;
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.StrValue0 = string(DoomToRemove);
		
		if(DoomToRemove == 1)
		{
			DoomString @= `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedSingular);
		}
		else
		{
			DoomString @= `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedPlural);
		}

		AlienHQ.RemoveDoomFromFortress(NewGameState, DoomToRemove, DoomString);

		if(MissionState.Source == 'MissionSource_Blacksite')
		{
			AlienHQ.PendingDoomEvent = 'BlacksiteDoomEvent';
		}
		else if(MissionState.Source == 'MissionSource_Forge')
		{
			AlienHQ.PendingDoomEvent = 'ForgeDoomEvent';
		}
		else if(MissionState.Source == 'MissionSource_PsiGate')
		{
			AlienHQ.PendingDoomEvent = 'PsiGateDoomEvent';
		}

		if(FortressMission.ShouldBeVisible())
		{
			class'XComGameState_HeadquartersResistance'.static.AddGlobalEffectString(NewGameState, DoomString, false);
		}
	}

	if(FortressMission.ShouldBeVisible())
	{
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AvatarProgressReduced', DoomToRemove);
	}
}

function RemoveIntelRewards(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local MissionIntelOption IntelOption;

	if (MissionState.PurchasedIntelOptions.Length > 0)
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}

		if (XComHQ == none)
		{
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			NewGameState.AddStateObject(XComHQ);
		}

		foreach MissionState.PurchasedIntelOptions(IntelOption)
		{
			XComHQ.TacticalGameplayTags.RemoveItem(IntelOption.IntelRewardName);
		}
	}
}

function XComGameState_MissionCalendar GetMissionCalendar(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_MissionCalendar CalendarState;

	foreach NewGameState.IterateByClassType(class'XComGameState_MissionCalendar', CalendarState)
	{
		break;
	}

	if(CalendarState == none)
	{
		History = `XCOMHISTORY;
		CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
		CalendarState = XComGameState_MissionCalendar(NewGameState.CreateStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));
		NewGameState.AddStateObject(CalendarState);
	}

	return CalendarState;
}

//---------------------------------------------------------------------------------------
function array<name> GetShuffledRewardDeck(array<RewardDeckEntry> ConfigRewards)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int ForceLevel, idx, i, iTemp, iRand;
	local array<name> UnshuffledRewards, ShuffledRewards;
	local name EntryName;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ForceLevel = AlienHQ.GetForceLevel();

	// Add all applicable rewards to unshuffled deck
	for(idx = 0; idx < ConfigRewards.Length; idx++)
	{
		if(ConfigRewards[idx].ForceLevelGate <= ForceLevel)
		{
			for(i = 0; i < ConfigRewards[idx].Quantity; i++)
			{
				UnshuffledRewards.AddItem(ConfigRewards[idx].RewardName);
			}
		}
	}

	// Shuffle the deck
	iTemp = UnshuffledRewards.Length;
	for(idx = 0; idx < iTemp; idx++)
	{
		iRand = `SYNC_RAND(UnshuffledRewards.Length);
		EntryName = UnshuffledRewards[iRand];
		UnshuffledRewards.Remove(iRand, 1);
		ShuffledRewards.AddItem(EntryName);
	}

	return ShuffledRewards;
}

//---------------------------------------------------------------------------------------
function XComGameState_WorldRegion GetRandomContactedRegion()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_WorldRegion> ValidRegions, AllRegions;

	History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
			AllRegions.AddItem(RegionState);

			if(RegionState.ResistanceLevel >= eResLevel_Contact)
			{
				ValidRegions.AddItem(RegionState);
			}
		}

	if(ValidRegions.Length > 0)
	{
		return ValidRegions[`SYNC_RAND(ValidRegions.Length)];
	}

	return AllRegions[`SYNC_RAND(AllRegions.Length)];
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetGoldenPathMissionRegions()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local array<StateObjectReference> MissionRegions;

	History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
			if(MissionState.GetMissionSource().bGoldenPath && MissionState.Available)
			{
				MissionRegions.AddItem(MissionState.GetReference());
			}
		}

	return MissionRegions;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetAlienFacilityMissionRegions()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local array<StateObjectReference> MissionRegions;

	History = `XCOMHISTORY;

		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
			if(MissionState.GetMissionSource().bAlienNetwork)
			{
				MissionRegions.AddItem(MissionState.GetReference());
			}
		}

	return MissionRegions;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersAlien GetAndAddAlienHQ(XComGameState NewGameState)
{
	local XComGameState_HeadquartersAlien AlienHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	if(AlienHQ == none)
	{
		AlienHQ = XComGameState_HeadquartersAlien(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		NewGameState.AddStateObject(AlienHQ);
	}

	return AlienHQ;
}

//---------------------------------------------------------------------------------------
function bool IsInStartingRegion(XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(MissionState.Region.ObjectID));

	return (RegionState != none && RegionState.IsStartingRegion());
}

//---------------------------------------------------------------------------------------
function bool OneStrategyObjectiveCompleted(XComGameState_BattleData BattleDataState)
{
	return (BattleDataState.OneStrategyObjectiveCompleted());
}

//---------------------------------------------------------------------------------------
function bool StrategyObjectivePlusSweepCompleted(XComGameState_BattleData BattleDataState)
{
	return (BattleDataState.OneStrategyObjectiveCompleted() && BattleDataState.AllTacticalObjectivesCompleted());
}

//---------------------------------------------------------------------------------------
function bool IsCarryUnitSoldierInSquad(XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for (i = 0; i < XComHQ.Squad.Length; ++i)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Squad[i].ObjectID));
		if (UnitState != none && UnitState.GetMyTemplate().Abilities.Find('CarryUnit') != INDEX_NONE)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool IsNoCarryUnitSoldierInSquad(XComGameState_MissionSite MissionState)
{
	return !IsCarryUnitSoldierInSquad(MissionState);
}

// #######################################################################################
// -------------------- DIFFICULTY HELPERS -----------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
static function int GetBlacksiteMinDoomRemoval()
{
	return default.BlacksiteMinDoomRemoval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function int GetBlacksiteMaxDoomRemoval()
{
	return default.BlacksiteMaxDoomRemoval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function int GetForgeMinDoomRemoval()
{
	return default.ForgeMinDoomRemoval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function int GetForgeMaxDoomRemoval()
{
	return default.ForgeMaxDoomRemoval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function int GetPsiGateMinDoomRemoval()
{
	return default.PsiGateMinDoomRemoval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function int GetPsiGateMaxDoomRemoval()
{
	return default.PsiGateMaxDoomRemoval[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
static function float GetAverageGPDoomRemoval()
{
	local float AverageGPDoomRemoved;

	AverageGPDoomRemoved = ((float(GetBlacksiteMinDoomRemoval()) + float(GetBlacksiteMaxDoomRemoval())) / 2.0f);
	AverageGPDoomRemoved += ((float(GetForgeMinDoomRemoval()) + float(GetForgeMaxDoomRemoval())) / 2.0f);
	AverageGPDoomRemoved += ((float(GetPsiGateMinDoomRemoval()) + float(GetPsiGateMaxDoomRemoval())) / 2.0f);
	
	return AverageGPDoomRemoved;
}

//---------------------------------------------------------------------------------------
static function DoomAddedData GetFacilityStartingDoom()
{
	return default.FacilityStartingDoom[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function array<MissionMonthDifficulty> GetGuerillaOpMonthlyDifficulties()
{
	local array<MissionMonthDifficulty> MissionDifficulties;
	local int idx;

	for(idx = 0; idx < default.GuerillaOpMonthlyDifficulties.Length; idx++)
	{
		if(default.GuerillaOpMonthlyDifficulties[idx].CampaignDifficulty == `DifficultySetting)
		{
			MissionDifficulties.AddItem(default.GuerillaOpMonthlyDifficulties[idx]);
		}
	}

	return MissionDifficulties;
}

function array<int> GetMonthlyDifficultyAdd()
{
	switch(`DifficultySetting)
	{
	case 0:
		return default.EasyMonthlyDifficultyAdd;
	case 1:
		return default.NormalMonthlyDifficultyAdd;
	case 2:
		return default.ClassicMonthlyDifficultyAdd;
	case 3:	
		return default.ImpossibleMonthlyDifficultyAdd;
	}

	return default.NormalMonthlyDifficultyAdd;
}