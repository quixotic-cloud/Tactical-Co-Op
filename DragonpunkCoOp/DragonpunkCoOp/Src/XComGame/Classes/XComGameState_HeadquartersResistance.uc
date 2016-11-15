//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersResistance.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for the resistance's HQ in the 
//           X-Com 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersResistance extends XComGameState_BaseObject native(Core) config(GameData);

// Basic Info
var() TDateTime                           StartTime;
var() array<StateObjectReference>         Recruits;
var array<Commodity>					  ResistanceGoods;
var array<StateObjectReference>			  PersonnelGoods; // Subset of Resistance goods storing the personnel options each month
var array<TResistanceActivity>			  ResistanceActivities;
var int									  NumMonths;
var array<name>							  SoldierClassDeck;   //Soldier classes to randomly pick from when generating rewards

// Timers
var() TDateTime							  MonthIntervalStartTime;
var() TDateTime							  MonthIntervalEndTime;
var float							      MonthIntervalTimeRemaining;

// POI Timers
var() TDateTime							  ForceStaffPOITime;
var() bool								  bStaffPOISpawnedDuringTimer;

// Modifiers
var int									  SupplyDropPercentIncrease; // AllIn Continent bonus
var int									  IntelRewardPercentIncrease; // SpyRing Continent bonus
var int									  RecruitCostModifier; // ToServeMankind Continent bonus
var float								  RecruitScalar; // Midnight raids
var float								  SupplyDropPercentDecrease; // Rural Checkpoints
var float								  SavedSupplyDropPercentDecrease; // Saved value since dark events get deactivated on end of month before Monthly Report is shown

// Flags
var bool								  bInactive; // Resistance isn't active at the beginning of the tutorial
var() bool								  bEndOfMonthNotify;
var() bool								  bHasSeenNewResistanceGoods;
var() bool								  bIntelMode; // If scanning at Resistance HQ is intel mode
var() bool								  bFirstPOIActivated; // If ResHQ should spawn the first POI upon the next Geoscape entry
var() bool								  bFirstPOISpawned; // Has the first POI been spawned yet

// Resistance Scanning Mode
var() name								  ResistanceMode;

// VIP Rewards
var string								  VIPRewardsString;

// Rewards Recap
var string								  RecapRewardsString;
var array<string>						  RecapGlobalEffectsGood;
var array<string>						  RecapGlobalEffectsBad;

// POIs
var array<StateObjectReference>			  ActivePOIs; // All of the POIs currently active on the map

// Expired Mission
var StateObjectReference				  ExpiredMission;

// Config Vars
var config int							  MinSuppliesInterval;
var config int							  MaxSuppliesInterval;
var config array<int>					  RecruitSupplyCosts;
var config int							  RecruitOrderTime;
var config array<int>					  StartingNumRecruits;
var config array<int>					  RefillNumRecruits;
var config ECharacterPoolSelectionMode	  RecruitsCharacterPoolSelectionMode;
var config array<int>					  BaseGoodsCost;
var config array<int>					  GoodsCostVariance;
var config array<int>					  GoodsCostIncrease;
var config array<int>					  ResHQToggleCost;
var config int							  NumToRemoveFromSoldierDeck;
var config array<StrategyCostScalar>	  ResistanceGoodsCostScalars;
var config array<int>					  AdditionalPOIChance;
var config array<float>					  NeededPOIWeightModifier;
var config int							  StartingStaffPOITimerDays;
var config int							  StaffPOITimerDays;

// Popup Text
var localized string					  SupplyDropPopupTitle;
var localized string					  SupplyDropPopupPerRegionText;
var localized string					  SupplyDropPopupBonusText;
var localized string					  SupplyDropPopupTotalText;
var localized string					  IntelDropPopupPerRegionText;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Set-up Resistance HQ at the start of the game
static function SetUpHeadquarters(XComGameState StartState, optional bool bTutorialEnabled = false)
{
	local XComGameState_HeadquartersResistance ResistanceHQ;

	//Locate the resistance HQ in the same region
	ResistanceHQ = XComGameState_HeadquartersResistance(StartState.CreateStateObject(class'XComGameState_HeadquartersResistance'));

	// Set Start Date
	class'X2StrategyGameRulesetDataStructures'.static.SetTime(ResistanceHQ.StartTime, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH, 
		class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );

	// Set the active flag
	ResistanceHQ.bInactive = bTutorialEnabled;
	ResistanceHQ.SetProjectedMonthInterval(ResistanceHQ.StartTime);

	ResistanceHQ.ForceStaffPOITime = ResistanceHQ.StartTime;
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(ResistanceHQ.ForceStaffPOITime, ResistanceHQ.StartingStaffPOITimerDays);

	ResistanceHQ.SupplyDropPercentDecrease = 0.0f;

	// Used to create the resistance recruits here, moved to XComHQ setup so character pool characters fill staff first

	// Create Resistance Activities List
	ResistanceHQ.ResetActivities();

	// Start in Intel mode
	ResistanceHQ.ResistanceMode = 'ResistanceMode_Intel';
	ResistanceHQ.bIntelMode = true;

	// Add to start state
	StartState.AddStateObject(ResistanceHQ);
}

//---------------------------------------------------------------------------------------
function CreateRecruits(XComGameState StartState)
{
	local XComGameState_Unit NewSoldierState;
	local XComOnlineProfileSettings ProfileSettings;
	local int Index;

	assert(StartState != none);
	ProfileSettings = `XPROFILESETTINGS;

	for(Index = 0; Index < GetStartingNumRecruits(); ++Index)
	{
		NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, ProfileSettings.Data.m_eCharPoolUsage);
		NewSoldierState.RandomizeStats();
		if(!NewSoldierState.HasBackground())
			NewSoldierState.GenerateBackground();
		NewSoldierState.ApplyInventoryLoadout(StartState);
		StartState.AddStateObject(NewSoldierState);
		Recruits.AddItem(NewSoldierState.GetReference());
	}

	RecruitScalar = 1.0f;
}

//---------------------------------------------------------------------------------------
function BuildSoldierClassDeck()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local int i;

	if(SoldierClassDeck.Length != 0)
	{
		SoldierClassDeck.Length = 0;
	}
	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(Template);

		if(!SoldierClassTemplate.bMultiplayerOnly)
		{
			for(i = 0; i < SoldierClassTemplate.NumInDeck; ++i)
			{
				SoldierClassDeck.AddItem(SoldierClassTemplate.DataName);
			}
		}
	}
	if(default.NumToRemoveFromSoldierDeck >= SoldierClassDeck.Length)
	{
		`RedScreen("Soldier class deck problem. No elements removed. @gameplay_engineers Author: mnauta");
		return;
	}
	for(i = 0; i < default.NumToRemoveFromSoldierDeck; ++i)
	{
		SoldierClassDeck.Remove(`SYNC_RAND(SoldierClassDeck.Length), 1);
	}
}

//---------------------------------------------------------------------------------------
function name SelectNextSoldierClass()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local name RetName;
	local int idx;
	local array<name> NeededClasses, RewardClasses;

	History = `XCOMHISTORY;

	if(SoldierClassDeck.Length == 0)
	{
		BuildSoldierClassDeck();
	}
	 
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NeededClasses = XComHQ.GetNeededSoldierClasses();

	for(idx = 0; idx < SoldierClassDeck.Length; idx++)
	{
		if(NeededClasses.Find(SoldierClassDeck[idx]) != INDEX_NONE)
		{
			RewardClasses.AddItem(SoldierClassDeck[idx]);
		}
	}

	if(RewardClasses.Length == 0)
	{
		BuildSoldierClassDeck();

		for(idx = 0; idx < SoldierClassDeck.Length; idx++)
		{
			if(NeededClasses.Find(SoldierClassDeck[idx]) != INDEX_NONE)
			{
				RewardClasses.AddItem(SoldierClassDeck[idx]);
			}
		}
	}

	`assert(SoldierClassDeck.Length != 0);
	`assert(RewardClasses.Length != 0);
	RetName = RewardClasses[`SYNC_RAND(RewardClasses.Length)];
	SoldierClassDeck.Remove(SoldierClassDeck.Find(RetName), 1);

	return RetName;
}

//#############################################################################################
//----------------   UPDATE AND TIME MANAGEMENT   ---------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// returns true if an internal value has changed (lots of time checks)
function bool Update(XComGameState NewGameState)
{
	local UIStrategyMap StrategyMap;
	local bool bUpdated;

	StrategyMap = `HQPRES.StrategyMap2D;
	bUpdated = false;
	
	// Don't trigger end of month while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (!bInactive && class'X2StrategyGameRulesetDataStructures'.static.LessThan(MonthIntervalEndTime, `STRATEGYRULES.GameTime))
		{
			OnEndOfMonth(NewGameState);
			bUpdated = true;
		}
	}

	return bUpdated;
}

//---------------------------------------------------------------------------------------
function OnEndOfMonth(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_BlackMarket BlackMarket;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	GiveSuppliesReward(NewGameState);
	SetProjectedMonthInterval(`STRATEGYRULES.GameTime);
	CleanUpResistanceGoods(NewGameState);
	SetUpResistanceGoods(NewGameState);
	RefillRecruits(NewGameState);
	ResetMonthlyMissingPersons(NewGameState);

	SavedSupplyDropPercentDecrease = SupplyDropPercentDecrease; // Save the supply drop decrease caused by any Dark Events before they are reset

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.EndOfMonth(NewGameState);

	BlackMarket = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	BlackMarket = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', BlackMarket.ObjectID));
	NewGameState.AddStateObject(BlackMarket);
	BlackMarket.ResetBlackMarketGoods(NewGameState);

	NumMonths++;
}

//---------------------------------------------------------------------------------------
function RefillRecruits(XComGameState NewGameState)
{
	local array<StateObjectReference> NewRecruitList;
	local XComGameState_Unit SoldierState;
	local XComOnlineProfileSettings ProfileSettings;
	local int idx;

	ProfileSettings = `XPROFILESETTINGS;

	for(idx = 0; idx < GetRefillNumRecruits(); idx++)
	{
		SoldierState = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, ProfileSettings.Data.m_eCharPoolUsage);
		SoldierState.RandomizeStats();
		if(!SoldierState.HasBackground())
			SoldierState.GenerateBackground();
		SoldierState.ApplyInventoryLoadout(NewGameState);
		NewGameState.AddStateObject(SoldierState);
		NewRecruitList.AddItem(SoldierState.GetReference());
	}

	for(idx = 0; idx < Recruits.Length; idx++)
	{
		NewRecruitList.AddItem(Recruits[idx]);
	}

	Recruits = NewRecruitList;
}

//---------------------------------------------------------------------------------------
function ResetMonthlyMissingPersons(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
		NewGameState.AddStateObject(RegionState);
		RegionState.UpdateMissingPersons();
		RegionState.NumMissingPersonsThisMonth = 0;
	}
}

//---------------------------------------------------------------------------------------
function GiveSuppliesReward(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_ResourceCache CacheState;
	local int TotalReward;

	History = `XCOMHISTORY;
	TotalReward = GetSuppliesReward();
	bEndOfMonthNotify = true;	
	
	if (TotalReward > 0)
	{
		CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));
		CacheState.ShowResourceCache(NewGameState, TotalReward);
	}
}

//---------------------------------------------------------------------------------------
function int GetSuppliesReward(optional bool bUseSavedPercentDecrease)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local int SupplyReward;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	SupplyReward = 0;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		SupplyReward += RegionState.GetSupplyDropReward();
	}

	SupplyReward += Round(float(SupplyReward) * (float(SupplyDropPercentIncrease) / 100.0));

	// Subtract the upkeep from the Avenger facilities
	SupplyReward -= XComHQ.GetFacilityUpkeepCost();
	
	// Before the Monthly Report, use the saved decrease value, it will already have been reset when the Dark Event deactivated at months end otherwise
	if (bUseSavedPercentDecrease)
		SupplyReward -= Round(float(SupplyReward) * SavedSupplyDropPercentDecrease);
	else
		SupplyReward -= Round(float(SupplyReward) * SupplyDropPercentDecrease);

	return SupplyReward;
}

//---------------------------------------------------------------------------------------
function SetProjectedMonthInterval(TDateTime Start, optional float TimeRemaining = -1.0)
{
	local int HoursToAdd;

	MonthIntervalStartTime = Start;
	MonthIntervalEndTime = MonthIntervalStartTime;

	if(TimeRemaining > 0)
	{
		class'X2StrategyGameRulesetDataStructures'.static.AddTime(MonthIntervalEndTime, TimeRemaining);
	}
	else
	{
		HoursToAdd = default.MinSuppliesInterval + `SYNC_RAND(
			default.MaxSuppliesInterval-default.MinSuppliesInterval+1);
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(MonthIntervalEndTime, HoursToAdd);
	}
}

simulated public function EndOfMonthPopup()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Supplies Reward Popup Handling");
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', self.ObjectID));
	NewGameState.AddStateObject(ResistanceHQ);
	ResistanceHQ.bEndOfMonthNotify = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	`GAME.GetGeoscape().Pause();

	`HQPRES.UIMonthlyReport();
}

simulated function array<TResistanceActivity> GetMonthlyActivity(optional bool bAliens)
{
	local array<TResistanceActivity> arrActions;
	local TResistanceActivity ActivityStruct;
	local int idx;
	
	for(idx = 0; idx < ResistanceActivities.Length; idx++)
	{
		ActivityStruct = ResistanceActivities[idx];

		if(ActivityShouldAppearInReport(ActivityStruct))
		{
			ActivityStruct.Rating = GetActivityTextState(ActivityStruct);
			if ((ActivityStruct.Rating == eUIState_Bad && bAliens) ||
				(ActivityStruct.Rating == eUIState_Good && !bAliens))
			{
				arrActions.AddItem(ActivityStruct);
			}
		}
	}

	return arrActions;
}

simulated function name GetResistanceMoodEvent()
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ResistanceActivityTemplate ActivityTemplate;
	local TResistanceActivity ActivityStruct;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int idx, iMissionsFailed, iDoomReduced;
	local float DoomRatio;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for (idx = 0; idx < ResistanceActivities.Length; idx++)
	{
		ActivityStruct = ResistanceActivities[idx];
		ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityStruct.ActivityTemplateName));

		// Count the number of missions which were failed
		if (ActivityTemplate.bMission && ActivityTemplate.bAlwaysBad)
		{
			iMissionsFailed += ActivityStruct.Count;
		}

		// Count the amount of doom the player reduced
		if (ActivityTemplate.DataName == 'ResAct_AvatarProgressReduced')
		{
			iDoomReduced += ActivityStruct.Count;
		}
	}

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	DoomRatio = (AlienHQ.GetCurrentDoom() * 1.0) / AlienHQ.GetMaxDoom();

	if (iMissionsFailed >= 2 && iDoomReduced == 0)
	{
		return 'MonthlyReport_Bad';
	}
	else if (iMissionsFailed >= 1 || (iDoomReduced == 0 && DoomRatio >= 0.66))
	{
		return 'MonthlyReport_Moderate';
	}
	else
	{
		return 'MonthlyReport_Good';
	}
}

simulated private function EndOfMonthPopupCallback(eUIAction eAction)
{
	`GAME.GetGeoscape().Resume();

	if(`GAME.GetGeoscape().IsScanning())
		`HQPRES.StrategyMap2D.ToggleScan();
}

//---------------------------------------------------------------------------------------
function ResetActivities()
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> Activities;
	local X2ResistanceActivityTemplate ActivityTemplate;
	local TResistanceActivity ActivityStruct, EmptyActivityStruct;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	Activities = StratMgr.GetAllTemplatesOfClass(class'X2ResistanceActivityTemplate');
	ResistanceActivities.Length = 0;

	for(idx = 0; idx < Activities.Length; idx++)
	{
		ActivityTemplate = X2ResistanceActivityTemplate(Activities[idx]);
		ActivityStruct = EmptyActivityStruct;
		ActivityStruct.ActivityTemplateName = ActivityTemplate.DataName;
		ActivityStruct.Title = ActivityTemplate.DisplayName;
		ResistanceActivities.AddItem(ActivityStruct);
	}
}

//---------------------------------------------------------------------------------------
function IncrementActivityCount(name ActivityTemplateName, optional int DeltaCount=1)
{
	local int ActivityIndex;

	ActivityIndex = ResistanceActivities.Find('ActivityTemplateName', ActivityTemplateName);

	if(ActivityIndex != INDEX_NONE)
	{
		ResistanceActivities[ActivityIndex].Count += DeltaCount;
		ResistanceActivities[ActivityIndex].LastIncrement = DeltaCount;
	}
}

//---------------------------------------------------------------------------------------
static function RecordResistanceActivity(XComGameState NewGameState, name ActivityTemplateName, optional int DeltaCount=1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local X2ResistanceActivityTemplate ActivityTemplate;
	local X2StrategyElementTemplateManager StratMgr;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if (ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance', true /* AllowNULL */));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', (ResistanceHQ == none) ? -1 : ResistanceHQ.ObjectID));
		NewGameState.AddStateObject(ResistanceHQ);
	}
	
	ResistanceHQ.IncrementActivityCount(ActivityTemplateName, DeltaCount);

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager( );
	ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityTemplateName));
	`XEVENTMGR.TriggerEvent('ResistanceActivity', ActivityTemplate, ResistanceHQ, NewGameState);
}

//---------------------------------------------------------------------------------------
function bool ActivityShouldAppearInReport(TResistanceActivity ActivityStruct)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ResistanceActivityTemplate ActivityTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityStruct.ActivityTemplateName));

	if(ActivityTemplate != none)
	{
		if(ActivityStruct.Count == 0)
		{
			return false;
		}

		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function EUIState GetActivityTextState(TResistanceActivity ActivityStruct)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ResistanceActivityTemplate ActivityTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ActivityTemplate = X2ResistanceActivityTemplate(StratMgr.FindStrategyElementTemplate(ActivityStruct.ActivityTemplateName));

	if(ActivityTemplate != none)
	{
		if(ActivityTemplate.bAlwaysBad)
		{
			return eUIState_Bad;
		}
		
		if(ActivityTemplate.bAlwaysGood)
		{
			return eUIState_Good;
		}
		
		if((ActivityStruct.Count >= ActivityTemplate.MinGoodValue && ActivityStruct.Count <= ActivityTemplate.MaxGoodValue))
		{
			return eUIState_Good;
		}
		else
		{
			return eUIState_Bad;
		}
	}
}

//#############################################################################################
//----------------   SCANNING MODE   ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
function X2ResistanceModeTemplate GetResistanceMode()
{
	return X2ResistanceModeTemplate(GetMyTemplateManager().FindStrategyElementTemplate(ResistanceMode));
}

//---------------------------------------------------------------------------------------
function ActivateResistanceMode(XComGameState NewGameState)
{
	GetResistanceMode().OnActivatedFn(NewGameState, self.GetReference());
}

//---------------------------------------------------------------------------------------
function DeactivateResistanceMode(XComGameState NewGameState)
{
	GetResistanceMode().OnDeactivatedFn(NewGameState, self.GetReference());
}

//---------------------------------------------------------------------------------------
function OnXCOMArrives()
{
	local XComGameState NewGameState;

	if (GetResistanceMode().OnXCOMArrivesFn != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Arrive Res HQ: Apply Scan Mode Bonus");	
		GetResistanceMode().OnXCOMArrivesFn(NewGameState, self.GetReference());
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function OnXCOMLeaves()
{
	local XComGameState NewGameState;

	if (GetResistanceMode().OnXCOMLeavesFn != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Leave Res HQ: Remove Scan Mode Bonus");
		GetResistanceMode().OnXCOMLeavesFn(NewGameState, self.GetReference());
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//#############################################################################################
//----------------   RESISTANCE GOODS   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function SetUpResistanceGoods(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> ResistanceModes;
	local XComGameState_Reward RewardState;
	local X2ResistanceModeTemplate ResistanceModeTemplate;
	local X2RewardTemplate RewardTemplate;
	local Commodity ForSaleItem, EmptyForSaleItem;
	local array<name> PersonnelRewardNames;
	local int idx, RewardIndex;
	local XComPhotographer_Strategy Photo;
	local bool bCanReward;

	StratMgr = GetMyTemplateManager();
			
	Photo = `GAME.StrategyPhotographer;

	// Grab All Resistance Modes
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_ResistanceMode'));
	ResistanceModes = StratMgr.GetAllTemplatesOfClass(class'X2ResistanceModeTemplate');
	for (idx = 0; idx < ResistanceModes.Length; idx++)
	{
		ResistanceModeTemplate = X2ResistanceModeTemplate(ResistanceModes[idx]);
		if (ResistanceModeTemplate.DataName != ResistanceMode)
		{
			ForSaleItem = EmptyForSaleItem;
			RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
			RewardState.RewardObjectTemplateName = ResistanceModeTemplate.DataName;
			NewGameState.AddStateObject(RewardState);
			ForSaleItem.RewardRef = RewardState.GetReference();

			// Resistance HQ Mode
			ForSaleItem.Title = ResistanceModeTemplate.DisplayName;
			ForSaleItem.Cost = GetResHQToggleCost();
			ForSaleItem.Desc = ResistanceModeTemplate.SummaryText;
			ForSaleItem.Image = ResistanceModeTemplate.ImagePath;
			ForSaleItem.CostScalars = ResistanceGoodsCostScalars;

			ResistanceGoods.AddItem(ForSaleItem);
		}
	}

	PersonnelRewardNames.AddItem('Reward_Scientist');
	PersonnelRewardNames.AddItem('Reward_Engineer');
	PersonnelRewardNames.AddItem('Reward_Soldier');

	for(idx = 0; idx < 2; idx++)
	{
		// Safety check in case both Sci and Eng are not available, give two soldiers
		if (PersonnelRewardNames.Length == 0)
			PersonnelRewardNames.AddItem('Reward_Soldier');

		// Reward
		RewardIndex = `SYNC_RAND(PersonnelRewardNames.Length);
		ForSaleItem = EmptyForSaleItem;
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(PersonnelRewardNames[RewardIndex]));

		// Check to make sure we have a reward template which can be given to the player at this time
		// Loop through all of the possible rewards until we find a valid one
		bCanReward = false;
		while (!bCanReward)
		{
			if (RewardTemplate.IsRewardAvailableFn == none || RewardTemplate.IsRewardAvailableFn())
				bCanReward = true;
			else
			{
				PersonnelRewardNames.Remove(RewardIndex, 1);

				// Safety check in case both Sci and Eng are not available, give two soldiers
				if (PersonnelRewardNames.Length == 0)
					PersonnelRewardNames.AddItem('Reward_Soldier');

				RewardIndex = `SYNC_RAND(PersonnelRewardNames.Length);
				RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(PersonnelRewardNames[RewardIndex]));	
			}
		}

		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(RewardState);
		RewardState.GenerateReward(NewGameState);
		ForSaleItem.RewardRef = RewardState.GetReference();

		// Commodity
		ForSaleItem.Title = RewardState.GetRewardString();
		ForSaleItem.Cost = GetForSaleItemCost();
		ForSaleItem.Desc = GetPersonnelRewardDescription(RewardState, RewardTemplate);
		ForSaleItem.Image = RewardState.GetRewardImage();
		ForSaleItem.CostScalars = ResistanceGoodsCostScalars;

		if(ForSaleItem.Image == "")
		{			
			if(!Photo.HasPendingHeadshot(RewardState.RewardObjectReference, OnUnitHeadCaptureFinished))
			{
				Photo.AddHeadshotRequest(RewardState.RewardObjectReference, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Head_Armory', 512, 512, OnUnitHeadCaptureFinished);
			}
		}

		ResistanceGoods.AddItem(ForSaleItem);
		PersonnelGoods.AddItem(RewardState.GetReference());

		PersonnelRewardNames.Remove(RewardIndex, 1);
	}

	bHasSeenNewResistanceGoods = false;
}

private function OnUnitHeadCaptureFinished(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local string TextureName;
	local Texture2D UnitPicture;
	local X2ImageCaptureManager CapMan;
	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	
	if (ReqInfo.Height == 512 && ReqInfo.Width == 512)
	{
		TextureName = "UnitPicture"$ReqInfo.UnitRef.ObjectID;
	}
	else
	{
		TextureName = "UnitPictureSmall"$ReqInfo.UnitRef.ObjectID;
	}

	UnitPicture = RenderTarget.ConstructTexture2DScript(CapMan, TextureName, false, false, false);	
	CapMan.StoreImage(ReqInfo.UnitRef, UnitPicture, name(TextureName));
}

function String GetPersonnelRewardDescription(XComGameState_Reward RewardState, X2RewardTemplate RewardTemplate)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	return UnitState.GetBackground();
}

//---------------------------------------------------------------------------------------
function CleanUpResistanceGoods(XComGameState NewGameState)
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local int idx;
	local bool bStartState;

	bStartState = (NewGameState.GetContext().IsStartState());
	History = `XCOMHISTORY;

	for(idx = 0; idx < ResistanceGoods.Length; idx++)
	{
		if(bStartState)
		{
			RewardState = XComGameState_Reward(NewGameState.GetGameStateForObjectID(ResistanceGoods[idx].RewardRef.ObjectID));
		}
		else
		{
			RewardState = XComGameState_Reward(History.GetGameStateForObjectID(ResistanceGoods[idx].RewardRef.ObjectID));
		}

		if(RewardState != none)
		{
			RewardState.CleanUpReward(NewGameState);
			NewGameState.RemoveStateObject(RewardState.ObjectID);
		}
	}

	ResistanceGoods.Length = 0;
	PersonnelGoods.Length = 0;
}

//---------------------------------------------------------------------------------------
function BuyResistanceGood(StateObjectReference RewardRef, optional bool bGrantForFree)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Reward RewardState;
	local StrategyCost FreeCost;
	local int ItemIndex, idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ItemIndex = ResistanceGoods.Find('RewardRef', RewardRef);

	if(ItemIndex != INDEX_NONE)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy Resistance Good");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);

		if( bGrantForFree )
		{
			ResistanceGoods[ItemIndex].Cost = FreeCost;
		}

		XComHQ.BuyCommodity(NewGameState, ResistanceGoods[ItemIndex]);
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', self.ObjectID));
		NewGameState.AddStateObject(ResistanceHQ);
		ResistanceHQ.ResistanceGoods.Remove(ItemIndex, 1);

		// If the reward was a resistance mode, remove all others from the goods list. Player can only switch modes once per month.
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
		if (RewardState.GetMyTemplateName() == 'Reward_ResistanceMode')
		{
			for (idx = 0; idx < ResistanceHQ.ResistanceGoods.Length; idx++)
			{
				RewardState = XComGameState_Reward(History.GetGameStateForObjectID(ResistanceHQ.ResistanceGoods[idx].RewardRef.ObjectID));
				if (RewardState.GetMyTemplateName() == 'Reward_ResistanceMode')
				{
					RewardState.CleanUpReward(NewGameState);
					NewGameState.RemoveStateObject(RewardState.ObjectID);
					ResistanceHQ.ResistanceGoods.Remove(idx, 1);
					idx--;
				}
			}
		}

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function StrategyCost GetForSaleItemCost()
{
	local StrategyCost Cost;
	local ArtifactCost ResourceCost;
	local int SupplyAmount, SupplyVariance;

	SupplyAmount = GetBaseGoodsCost() + (NumMonths * GetGoodsCostIncrease());
	SupplyVariance = Round((float(`SYNC_RAND(GetGoodsCostVariance())) / 100.0) * float(SupplyAmount));

	if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		SupplyVariance = -SupplyVariance;
	}

	SupplyAmount += SupplyVariance;

	// Make it a multiple of 5
	SupplyAmount = Round(float(SupplyAmount) / 5.0) * 5;

	ResourceCost.ItemTemplateName = 'Supplies';
	ResourceCost.Quantity = SupplyAmount;
	Cost.ResourceCosts.AddItem(ResourceCost);

	return Cost;
}

//---------------------------------------------------------------------------------------
function StrategyCost GetResHQToggleCost()
{
	local StrategyCost Cost;
	local ArtifactCost ResourceCost;
	
	ResourceCost.ItemTemplateName = 'Supplies';
	ResourceCost.Quantity = default.ResHQToggleCost[`DifficultySetting];
	Cost.ResourceCosts.AddItem(ResourceCost);

	return Cost;
}

//#############################################################################################
//----------------   RECRUITS   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetRecruitSupplyCost()
{
	return Round(float(default.RecruitSupplyCosts[`DIFFICULTYSETTING] + RecruitCostModifier) * RecruitScalar);
}

//---------------------------------------------------------------------------------------
// Give a recruit from the Resistance to XCom
function GiveRecruit(StateObjectReference RecruitReference)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local XComGameState_Unit UnitState;
	local int RecruitIndex;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Order Recruit");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	NewGameState.AddStateObject(ResistanceHQ);

	// Pay Cost and Order Recruit
	XComHQ.AddResource(NewGameState, 'Supplies', -ResistanceHQ.GetRecruitSupplyCost());
	
	if (RecruitOrderTime > 0)
	{
		XComHQ.OrderStaff(RecruitReference, RecruitOrderTime);
	}
	else // No delay in recruiting, so add the unit immediately
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', RecruitReference.ObjectID));
		`assert(UnitState != none);

		// If FNG is unlocked, rank up the soldier to Squaddie
		if (XComHQ.HasSoldierUnlockTemplate('FNGUnlock'))
		{
			UnitState.SetXPForRank(1);
			UnitState.StartingRank = 1;
			UnitState.RankUpSoldier(NewGameState, XComHQ.SelectNextSoldierClass());
			UnitState.ApplySquaddieLoadout(NewGameState, XComHQ);
		}

		NewGameState.AddStateObject(UnitState);
		UnitState.ApplyBestGearLoadout(NewGameState);
		XComHQ.AddToCrew(NewGameState, UnitState);
		XComHQ.HandlePowerOrStaffingChange(NewGameState);
	}

	// Remove from recruit list
	RecruitIndex = ResistanceHQ.Recruits.Find('ObjectID', RecruitReference.ObjectID);

	if(RecruitIndex != INDEX_NONE)
	{
		ResistanceHQ.Recruits.Remove(RecruitIndex, 1);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   REWARD RECAP   -----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function ClearVIPRewardsData()
{
	VIPRewardsString = "";
}

//---------------------------------------------------------------------------------------
function ClearRewardsRecapData()
{
	RecapRewardsString = "";
	RecapGlobalEffectsGood.Length = 0;
	RecapGlobalEffectsBad.Length = 0;
}

//---------------------------------------------------------------------------------------
static function SetRecapRewardString(XComGameState NewGameState, string RewardString)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if(ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		NewGameState.AddStateObject(ResistanceHQ);
	}

	ResistanceHQ.RecapRewardsString = RewardString;
}

static function SetVIPRewardString(XComGameState NewGameState, string RewardString)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if(ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		NewGameState.AddStateObject(ResistanceHQ);
	}

	ResistanceHQ.VIPRewardsString = RewardString;
}

//---------------------------------------------------------------------------------------
static function AddGlobalEffectString(XComGameState NewGameState, string EffectString, bool bBad)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResistanceHQ)
	{
		break;
	}

	if(ResistanceHQ == none)
	{
		History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		NewGameState.AddStateObject(ResistanceHQ);
	}

	if(bBad)
	{
		ResistanceHQ.RecapGlobalEffectsBad.AddItem(EffectString);
	}
	else
	{
		ResistanceHQ.RecapGlobalEffectsGood.AddItem(EffectString);
	}
}

// #######################################################################################
// --------------------------- POIS ------------------------------------------------------
// #######################################################################################

function XComGameState_PointOfInterest GetPOIStateFromTemplateName(name TemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
	{
		if (POIState.GetMyTemplateName() == TemplateName)
		{
			return POIState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function AttemptSpawnRandomPOI(optional XComGameState NewGameState)
{
	local bool bSubmitLocally;

	// If there are 2 or less POIs on the board, attempt to spawn a new one
	if (ActivePOIs.Length <= 2)
	{
		// If the roll succeeds or the player has just finished the first POI, spawn another one immediately
		if (class'X2StrategyGameRulesetDataStructures'.static.Roll(AdditionalPOIChance[`DIFFICULTYSETTING]) ||
		class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M0_CompleteGuerillaOps') == eObjectiveState_InProgress)
		{
			if (NewGameState == None)
			{
				bSubmitLocally = true;
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("POI Complete: Spawn another POI");
			}

			ChoosePOI(NewGameState, true);
			
			if (bSubmitLocally)
			{
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function StateObjectReference ChoosePOI(XComGameState NewGameState, optional bool bSpawnImmediately = false)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_PointOfInterest POIState;
	local array<XComGameState_PointOfInterest> POIDeck;
	local bool bStaffPOISpawnedFromTimer;
	
	ResHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ObjectID));
	NewGameState.AddStateObject(ResHQ);

	// If force staff POI timer is up and a staff POI has not been spawned, choose one to give
	if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ForceStaffPOITime, `STRATEGYRULES.GameTime))
	{
		// Timer is up and no staff POI was spawned, so force pick one
		if (!bStaffPOISpawnedDuringTimer)
		{
			POIDeck = BuildPOIDeck(true);
			bStaffPOISpawnedFromTimer = true;
		}
		
		// If a staff POI couldn't be found, or timer is up and staff was spawned already during its duration, pick from the full set
		// (Will exclude Staff POIs from the Deck because of their CanAppearFn logic until bStaffPOISpawnedDuringTimer is reset)
		if (bStaffPOISpawnedDuringTimer || POIDeck.Length == 0)
		{
			POIDeck = BuildPOIDeck();
		}

		// Reset the POI timer
		ResHQ.ForceStaffPOITime = `STRATEGYRULES.GameTime;
		class'X2StrategyGameRulesetDataStructures'.static.AddDays(ResHQ.ForceStaffPOITime, StaffPOITimerDays);
		ResHQ.bStaffPOISpawnedDuringTimer = false;
	}
	else
	{
		POIDeck = BuildPOIDeck();
	}

	POIState = DrawFromPOIDeck(POIDeck);

	if (POIState != none)
	{
		POIState = XComGameState_PointOfInterest(NewGameState.CreateStateObject(class'XComGameState_PointOfInterest', POIState.ObjectID));
		NewGameState.AddStateObject(POIState);
		
		ActivatePOI(NewGameState, POIState.GetReference());

		// If a staff POI was activated normally (not forced from the staff POI timer), then flag ResHQ
		if (!bStaffPOISpawnedFromTimer && POIState.GetMyTemplate().bStaffPOI)
		{
			ResHQ.bStaffPOISpawnedDuringTimer = true;
		}

		if (bSpawnImmediately)
		{
			POIState.Spawn(NewGameState);

			if( !ResHQ.bFirstPOISpawned )
			{
				ResHQ.bFirstPOISpawned = true;
			}
		}
	}

	return POIState.GetReference();
}

//---------------------------------------------------------------------------------------
function array<XComGameState_PointOfInterest> BuildPOIDeck(optional bool bOnlyStaffPOIs = false)
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState, ActivePOIState;
	local array<XComGameState_PointOfInterest> POIDeck;
	local int idx, Weight;
	local bool bValid;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
	{
		bValid = true;

		if (bOnlyStaffPOIs && !POIState.GetMyTemplate().bStaffPOI)
		{
			bValid = false;
		}

		for (idx = 0; idx < ActivePOIs.Length; idx++)
		{
			ActivePOIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(ActivePOIs[idx].ObjectID));

			if (ActivePOIState.ObjectID == POIState.ObjectID)
			{
				bValid = false;
			}
		}

		if (!POIState.CanAppear())
		{
			bValid = false;
		}

		if (bValid)
		{
			Weight = POIState.Weight;
			if (POIState.IsNeeded())
			{
				// Apply a weight modifier if the POI is needed by the player
				Weight *= NeededPOIWeightModifier[`DIFFICULTYSETTING]; 
			}

			for (idx = 0; idx < Weight; idx++)
			{
				POIDeck.AddItem(POIState);
			}
		}
	}

	return POIDeck;
}

//---------------------------------------------------------------------------------------
function XComGameState_PointOfInterest DrawFromPOIDeck(out array<XComGameState_PointOfInterest> POIEventDeck)
{
	local XComGameState_PointOfInterest POIEventState;

	if (POIEventDeck.Length == 0)
	{
		return none;
	}

	// Choose a POI randomly from the deck
	POIEventState = POIEventDeck[`SYNC_RAND_STATIC(POIEventDeck.Length)];

	return POIEventState;
}

//---------------------------------------------------------------------------------------
static function ActivatePOI(XComGameState NewGameState, StateObjectReference POIRef)
{
	local XComGameState_HeadquartersResistance ResHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}

	if (ResHQ == none)
	{
		ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
		NewGameState.AddStateObject(ResHQ);
	}

	// Add the POI to the activated list
	ResHQ.ActivePOIs.AddItem(POIRef);
}

//---------------------------------------------------------------------------------------
static function DeactivatePOI(XComGameState NewGameState, StateObjectReference POIRef)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local int idx;
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}

	if (ResHQ == none)
	{
		ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
		NewGameState.AddStateObject(ResHQ);
	}

	// Check Active POIs for the need to deactivate
	for (idx = 0; idx < ResHQ.ActivePOIs.Length; idx++)
	{
		if (ResHQ.ActivePOIs[idx].ObjectID == POIRef.ObjectID)
		{
			ResHQ.ActivePOIs.Remove(idx, 1);
			break;
		}
	}
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetStartingNumRecruits()
{
	return default.StartingNumRecruits[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetRefillNumRecruits()
{
	return default.RefillNumRecruits[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetBaseGoodsCost()
{
	return default.BaseGoodsCost[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetGoodsCostVariance()
{
	return default.GoodsCostVariance[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetGoodsCostIncrease()
{
	return default.GoodsCostIncrease[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}
