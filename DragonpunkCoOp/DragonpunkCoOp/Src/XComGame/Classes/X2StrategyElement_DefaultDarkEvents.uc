//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultDarkEvents.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultDarkEvents extends X2StrategyElement
	config(GameData);

var config array<int> MinorBreakthroughDoom;
var config array<int> MajorBreakthroughDoom;
var config array<float> MidnightRaidsScalar;
var config array<float> RuralCheckpointsScalar;
var config array<int> NewConstructionReductionDays;
var config array<float> AlienCypherScalar;
var config array<int> ResistanceInformantReductionDays;

var localized string MinorBreakthroughDoomLabel;
var localized string MajorBreakthroughDoomLabel;
var localized string DayLabel;
var localized string DaysLabel;
var localized string WeekLabel;
var localized string WeeksLabel;
var localized string BlockLabel;
var localized string BlocksLabel;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> DarkEvents;

	DarkEvents.AddItem(CreateMinorBreakthroughTemplate());
	DarkEvents.AddItem(CreateMajorBreakthroughTemplate());
	DarkEvents.AddItem(CreateHunterClassTemplate());
	DarkEvents.AddItem(CreateMidnightRaidsTemplate());
	DarkEvents.AddItem(CreateRuralCheckpointsTemplate());
	DarkEvents.AddItem(CreateAlloyPaddingTemplate());
	DarkEvents.AddItem(CreateAlienCypherTemplate());
	DarkEvents.AddItem(CreateResistanceInformantTemplate());
	DarkEvents.AddItem(CreateNewConstructionTemplate());
	DarkEvents.AddItem(CreateInfiltratorTemplate());
	DarkEvents.AddItem(CreateInfiltratorChryssalidTemplate());
	DarkEvents.AddItem(CreateRapidResponseTemplate());
	DarkEvents.AddItem(CreateVigilanceTemplate());
	DarkEvents.AddItem(CreateShowOfForceTemplate());
	DarkEvents.AddItem(CreateViperRoundsTemplate());

	return DarkEvents;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateMinorBreakthroughTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_MinorBreakthrough');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Avatar";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 10;
	Template.MaxActivationDays = 15;
	Template.MinDurationDays = 0;
	Template.MaxDurationDays = 0;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 10;
	Template.MinWeight = 1;
	Template.MaxWeight = 10;
	Template.WeightDeltaPerPlay = 0;
	Template.WeightDeltaPerActivate = -2;
	Template.MutuallyExclusiveEvents.AddItem('DarkEvent_MajorBreakthrough');
	Template.bNeverShowObjective = true;

	Template.OnActivatedFn = ActivateMinorBreakthrough;
	Template.CanActivateFn = CanActivateMinorBreakthrough;
	Template.CanCompleteFn = CanCompleteMinorBreakthrough;
	Template.GetSummaryFn = GetMinorBreakthroughSummary;
	Template.GetPreMissionTextFn = GetMinorBreakthroughPreMissionText;

	return Template;
}
//---------------------------------------------------------------------------------------
function bool CanActivateMinorBreakthrough(XComGameState_DarkEvent DarkEventState)
{
	return (!AtFirstMonth() && !AtMaxDoom());
}
//---------------------------------------------------------------------------------------
function bool CanCompleteMinorBreakthrough(XComGameState_DarkEvent DarkEventState)
{
	return (!AtMaxDoom());
}
//---------------------------------------------------------------------------------------
function ActivateMinorBreakthrough(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	GetAlienHQ(NewGameState).AddDoomToRandomFacility(NewGameState, GetMinorBreakthroughDoom(), default.MinorBreakthroughDoomLabel);
}
//---------------------------------------------------------------------------------------
function string GetMinorBreakthroughSummary(string strSummaryText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetBlocksString(GetMinorBreakthroughDoom());
	return `XEXPAND.ExpandString(strSummaryText);
}
//---------------------------------------------------------------------------------------
function string GetMinorBreakthroughPreMissionText(string strPreMissionText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetBlocksString(GetMinorBreakthroughDoom());
	return `XEXPAND.ExpandString(strPreMissionText);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateMajorBreakthroughTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_MajorBreakthrough');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Avatar2";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 28;
	Template.MinDurationDays = 0;
	Template.MaxDurationDays = 0;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 6;
	Template.MinWeight = 1;
	Template.MaxWeight = 6;
	Template.WeightDeltaPerPlay = 0;
	Template.WeightDeltaPerActivate = -2;
	Template.MutuallyExclusiveEvents.AddItem('DarkEvent_MinorBreakthrough');
	Template.bNeverShowObjective = true;

	Template.OnActivatedFn = ActivateMajorBreakthrough;
	Template.CanActivateFn = CanActivateMajorBreakthrough;
	Template.CanCompleteFn = CanCompleteMajorBreakthrough;
	Template.GetSummaryFn = GetMajorBreakthroughSummary;
	Template.GetPreMissionTextFn = GetMajorBreakthroughPreMissionText;

	return Template;
}
//---------------------------------------------------------------------------------------
function ActivateMajorBreakthrough(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	GetAlienHQ(NewGameState).AddDoomToRandomFacility(NewGameState, GetMajorBreakthroughDoom(), default.MajorBreakthroughDoomLabel);
}
//---------------------------------------------------------------------------------------
function bool CanActivateMajorBreakthrough(XComGameState_DarkEvent DarkEventState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	return (ResistanceHQ.NumMonths >= 2 && !AtMaxDoom());
}
//---------------------------------------------------------------------------------------
function bool CanCompleteMajorBreakthrough(XComGameState_DarkEvent DarkEventState)
{
	return (!AtMaxDoom());
}
//---------------------------------------------------------------------------------------
function string GetMajorBreakthroughSummary(string strSummaryText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetBlocksString(GetMajorBreakthroughDoom());
	return `XEXPAND.ExpandString(strSummaryText);
}
//---------------------------------------------------------------------------------------
function string GetMajorBreakthroughPreMissionText(string strPreMissionText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetBlocksString(GetMajorBreakthroughDoom());
	return `XEXPAND.ExpandString(strPreMissionText);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateHunterClassTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_HunterClass');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_UFO";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 14;
	Template.MaxActivationDays = 28;
	Template.MinDurationDays = 0;
	Template.MaxDurationDays = 0;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 10;
	Template.MinWeight = 1;
	Template.MaxWeight = 10;
	Template.WeightDeltaPerPlay = 0;
	Template.WeightDeltaPerActivate = -4;

	Template.OnActivatedFn = ActivateHunterClass;
	Template.CanActivateFn = CanActivateHunterClass;

	return Template;
}
//---------------------------------------------------------------------------------------
function ActivateHunterClass(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_UFO NewUFOState;

	NewUFOState = XComGameState_UFO(NewGameState.CreateStateObject(class'XComGameState_UFO'));
	NewUFOState.OnCreation(NewGameState, false);
	NewGameState.AddStateObject(NewUFOState);
}

//---------------------------------------------------------------------------------------
function bool CanActivateHunterClass(XComGameState_DarkEvent DarkEventState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	
	return (!AlienHQ.bHasPlayerBeenIntercepted ? true : (!OnNormalOrEasier() && !AtFirstMonth()));
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateMidnightRaidsTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_MidnightRaids');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Crackdown";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 10;
	Template.MaxActivationDays = 21;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateMidnightRaids;
	Template.OnDeactivatedFn = DeactivateMidnightRaids;
	Template.CanActivateFn = CanActivateMidnightRaids;
	Template.GetSummaryFn = GetMidnightRaidsSummary;
	Template.GetPreMissionTextFn = GetMidnightRaidsPreMissionText;

	return Template;
}
//---------------------------------------------------------------------------------------
function ActivateMidnightRaids(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	NewGameState.AddStateObject(ResistanceHQ);

	ResistanceHQ.RecruitScalar = GetMidnightRaidsScalar();
}
//---------------------------------------------------------------------------------------
function DeactivateMidnightRaids(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	NewGameState.AddStateObject(ResistanceHQ);

	ResistanceHQ.RecruitScalar = 1.0f;
}
//---------------------------------------------------------------------------------------
function bool CanActivateMidnightRaids(XComGameState_DarkEvent DarkEventState)
{
	return (!OnNormalOrEasier() || !AtFirstMonth());
}
//---------------------------------------------------------------------------------------
function string GetMidnightRaidsSummary(string strSummaryText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(GetPercent(GetMidnightRaidsScalar()));
	return `XEXPAND.ExpandString(strSummaryText);
}
//---------------------------------------------------------------------------------------
function string GetMidnightRaidsPreMissionText(string strPreMissionText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(GetPercent(GetMidnightRaidsScalar()));
	return `XEXPAND.ExpandString(strPreMissionText);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateRuralCheckpointsTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_RuralCheckpoints');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_SuppliesSeized";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = true;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 0;
	Template.MaxDurationDays = 0;
	Template.bInfiniteDuration = true;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateRuralCheckpoints;
	Template.OnDeactivatedFn = DeactivateRuralCheckpoints;
	Template.GetSummaryFn = GetRuralCheckpointsSummary;
	Template.GetPreMissionTextFn = GetRuralCheckpointsPreMissionText;

	return Template;
}
//---------------------------------------------------------------------------------------
function ActivateRuralCheckpoints(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	NewGameState.AddStateObject(ResistanceHQ);

	ResistanceHQ.SupplyDropPercentDecrease = GetRuralCheckpointsScalar();
}
//---------------------------------------------------------------------------------------
function DeactivateRuralCheckpoints(XComGameState NewGameState, StateObjectReference InRef)
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

	ResistanceHQ.SupplyDropPercentDecrease = 0.0f;
}
//---------------------------------------------------------------------------------------
function string GetRuralCheckpointsSummary(string strSummaryText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(GetPercent(GetRuralCheckpointsScalar()));
	return `XEXPAND.ExpandString(strSummaryText);
}
//---------------------------------------------------------------------------------------
function string GetRuralCheckpointsPreMissionText(string strPreMissionText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(GetPercent(GetRuralCheckpointsScalar()));
	return `XEXPAND.ExpandString(strPreMissionText);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAlloyPaddingTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_AlloyPadding');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_NewArmor";
	Template.bRepeatable = false;
	Template.bTactical = true;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = 0;
	Template.WeightDeltaPerActivate = -2;

	Template.OnActivatedFn = ActivateTacticalDarkEvent;
	Template.OnDeactivatedFn = DeactivateTacticalDarkEvent;

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAlienCypherTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_AlienCypher');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Cryptography";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateAlienCypher;
	Template.OnDeactivatedFn = DeactivateAlienCypher;
	Template.GetSummaryFn = GetAlienCypherSummary;
	Template.GetPreMissionTextFn = GetAlienCypherPreMissionText;

	return Template;
}
//---------------------------------------------------------------------------------------
function ActivateAlienCypher(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local StrategyCostScalar IntelScalar;
	local XComGameState_BlackMarket BlackMarketState;

	IntelScalar.ItemTemplateName = 'Intel';
	IntelScalar.Scalar = GetAlienCypherScalar();
	IntelScalar.Difficulty = `DIFFICULTYSETTING; // Set to the current difficulty

	GetAlienHQ(NewGameState).CostScalars.AddItem(IntelScalar);
	BlackMarketState = GetAndAddBlackMarket(NewGameState);
	BlackMarketState.PriceReductionScalar = (1.0f / IntelScalar.Scalar);
}
//---------------------------------------------------------------------------------------
function DeactivateAlienCypher(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_BlackMarket BlackMarketState;
	local int idx;

	AlienHQ = GetAlienHQ(NewGameState);

	for(idx = 0; idx < AlienHQ.CostScalars.Length; idx++)
	{
		if(AlienHQ.CostScalars[idx].ItemTemplateName == 'Intel' && AlienHQ.CostScalars[idx].Scalar == GetAlienCypherScalar())
		{
			AlienHQ.CostScalars.Remove(idx, 1);
			break;
		}
	}

	BlackMarketState = GetAndAddBlackMarket(NewGameState);
	BlackMarketState.PriceReductionScalar = 1.0f;
}
//---------------------------------------------------------------------------------------
function string GetAlienCypherSummary(string strSummaryText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(GetPercent(GetAlienCypherScalar()));
	return `XEXPAND.ExpandString(strSummaryText);
}
//---------------------------------------------------------------------------------------
function string GetAlienCypherPreMissionText(string strPreMissionText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(GetPercent(GetAlienCypherScalar()));
	return `XEXPAND.ExpandString(strPreMissionText);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateResistanceInformantTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_ResistanceInformant');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Traitor";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 0;
	Template.MaxDurationDays = 0;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;
	Template.bNeverShowObjective = true;

	Template.OnActivatedFn = ActivateResistanceInformant;
	Template.GetSummaryFn = GetResistanceInformantSummary;
	Template.GetPreMissionTextFn = GetResistanceInformantPreMissionText;

	return Template;
}
//---------------------------------------------------------------------------------------
function ActivateResistanceInformant(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameStateHistory History;
	local XComGameState_MissionCalendar CalendarState;
	local float TimeToRemove;
	local TDateTime SpawnDate;
	local int Index;

	History = `XCOMHISTORY;
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
	CalendarState = XComGameState_MissionCalendar(NewGameState.CreateStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));
	NewGameState.AddStateObject(CalendarState);
	TimeToRemove = float(GetResistanceInformantReductionDays() * 24 * 60 * 60);

	Index = CalendarState.CurrentMissionMonth.Find('MissionSource', 'MissionSource_Retaliation');

	if(Index != INDEX_NONE)
	{
		SpawnDate = CalendarState.CurrentMissionMonth[Index].SpawnDate;
		class'X2StrategyGameRulesetDataStructures'.static.RemoveTime(SpawnDate, TimeToRemove);
		CalendarState.CurrentMissionMonth[Index].SpawnDate = SpawnDate;
	}
	else
	{
		CalendarState.RetaliationSpawnTimeDecrease = TimeToRemove;
	}
}
//---------------------------------------------------------------------------------------
function string GetResistanceInformantSummary(string strSummaryText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetTimeString(GetResistanceInformantReductionDays());
	return `XEXPAND.ExpandString(strSummaryText);
}
//---------------------------------------------------------------------------------------
function string GetResistanceInformantPreMissionText(string strPreMissionText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetTimeString(GetResistanceInformantReductionDays());
	return `XEXPAND.ExpandString(strPreMissionText);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateNewConstructionTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_NewConstruction');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_NewConstruction";
	Template.bRepeatable = true;
	Template.bTactical = false;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 0;
	Template.MaxDurationDays = 0;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;
	Template.bNeverShowObjective = true;

	Template.OnActivatedFn = ActivateNewConstruction;
	Template.CanActivateFn = CanActivateMajorBreakthrough;
	Template.CanCompleteFn = CanActivateNewConstruction;
	Template.GetSummaryFn = GetNewConstructionSummary;
	Template.GetPreMissionTextFn = GetNewConstructionPreMissionText;

	return Template;
}
//---------------------------------------------------------------------------------------
function bool CanActivateNewConstruction(XComGameState_DarkEvent DarkEventState)
{
	return (HaveSeenFacility() && !AtMaxFacilities());
}
//---------------------------------------------------------------------------------------
function bool CanCompleteNewConstruction(XComGameState_DarkEvent DarkEventState)
{
	return (!AtMaxFacilities());
}
//---------------------------------------------------------------------------------------
function ActivateNewConstruction(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local float Reduction;
	
	AlienHQ = GetAlienHQ(NewGameState);
	Reduction = float(GetNewConstructionReductionDays() * 24 * 3600);
	class'X2StrategyGameRulesetDataStructures'.static.RemoveTime(AlienHQ.FacilityBuildEndTime, Reduction);
}
//---------------------------------------------------------------------------------------
function string GetNewConstructionSummary(string strSummaryText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetTimeString(GetNewConstructionReductionDays());
	return `XEXPAND.ExpandString(strSummaryText);
}
//---------------------------------------------------------------------------------------
function string GetNewConstructionPreMissionText(string strPreMissionText)
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetTimeString(GetNewConstructionReductionDays());
	return `XEXPAND.ExpandString(strPreMissionText);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateInfiltratorTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_Infiltrator');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Faceless";
	Template.bRepeatable = true;
	Template.bTactical = true;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 3;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateTacticalDarkEvent;
	Template.OnDeactivatedFn = DeactivateTacticalDarkEvent;
	Template.CanActivateFn = CanActivateInfiltrator;

	return Template;
}

//---------------------------------------------------------------------------------------
function bool CanActivateInfiltrator(XComGameState_DarkEvent DarkEventState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return XComHQ.HasSeenCharacterTemplate(class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Faceless'));
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateInfiltratorChryssalidTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_InfiltratorChryssalid');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Chryssalid";
	Template.bRepeatable = true;
	Template.bTactical = true;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 3;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateTacticalDarkEvent;
	Template.OnDeactivatedFn = DeactivateTacticalDarkEvent;
	Template.CanActivateFn = CanActivateInfestation;

	return Template;
}

//---------------------------------------------------------------------------------------
function bool CanActivateInfestation(XComGameState_DarkEvent DarkEventState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return XComHQ.HasSeenCharacterTemplate(class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Chryssalid'));
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateRapidResponseTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_RapidResponse');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_RapidResponse";
	Template.bRepeatable = false;
	Template.bTactical = true;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateTacticalDarkEvent;
	Template.OnDeactivatedFn = DeactivateTacticalDarkEvent;

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateVigilanceTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_Vigilance');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_Vigilance";
	Template.bRepeatable = true;
	Template.bTactical = true;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateTacticalDarkEvent;
	Template.OnDeactivatedFn = DeactivateTacticalDarkEvent;

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateShowOfForceTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_ShowOfForce');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_ShowOfForce";
	Template.bRepeatable = true;
	Template.bTactical = true;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateTacticalDarkEvent;
	Template.OnDeactivatedFn = DeactivateTacticalDarkEvent;
	Template.CanActivateFn = CanActivateShowOfForce;

	return Template;
}

//---------------------------------------------------------------------------------------
function bool CanActivateShowOfForce(XComGameState_DarkEvent DarkEventState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	return (ResistanceHQ.NumMonths >= 3 && `DifficultySetting >= 3);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateViperRoundsTemplate()
{
	local X2DarkEventTemplate Template;

	`CREATE_X2TEMPLATE(class'X2DarkEventTemplate', Template, 'DarkEvent_ViperRounds');
	Template.Category = "DarkEvent";
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.DarkEvent_ViperRounds";
	Template.bRepeatable = false;
	Template.bTactical = true;
	Template.bLastsUntilNextSupplyDrop = false;
	Template.MaxSuccesses = 0;
	Template.MinActivationDays = 21;
	Template.MaxActivationDays = 35;
	Template.MinDurationDays = 28;
	Template.MaxDurationDays = 28;
	Template.bInfiniteDuration = false;
	Template.StartingWeight = 5;
	Template.MinWeight = 1;
	Template.MaxWeight = 5;
	Template.WeightDeltaPerPlay = -2;
	Template.WeightDeltaPerActivate = 0;

	Template.OnActivatedFn = ActivateTacticalDarkEvent;
	Template.OnDeactivatedFn = DeactivateTacticalDarkEvent;
	Template.CanActivateFn = CanActivateViperRounds;

	return Template;
}

//---------------------------------------------------------------------------------------
function bool CanActivateViperRounds(XComGameState_DarkEvent DarkEventState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	return (ResistanceHQ.NumMonths >= 2);
}

// #######################################################################################
// -------------------- HELPERS ----------------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
function ActivateTacticalDarkEvent(XComGameState NewGameState, StateObjectReference InRef, optional bool bReactivate = false)
{
	local XComGameState_DarkEvent DarkEventState;
	local Name DarkEventTemplateName;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(InRef.ObjectID));
	DarkEventTemplateName = DarkEventState.GetMyTemplateName();

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if( XComHQ.TacticalGameplayTags.Find(DarkEventTemplateName) == INDEX_NONE )
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);

		XComHQ.TacticalGameplayTags.AddItem(DarkEventTemplateName);
	}
}

function DeactivateTacticalDarkEvent(XComGameState NewGameState, StateObjectReference InRef)
{
	local XComGameState_DarkEvent DarkEventState;
	local Name DarkEventTemplateName;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(InRef.ObjectID));
	DarkEventTemplateName = DarkEventState.GetMyTemplateName();

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if( XComHQ.TacticalGameplayTags.Find(DarkEventTemplateName) != INDEX_NONE )
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);

		XComHQ.TacticalGameplayTags.RemoveItem(DarkEventTemplateName);
	}
}

//---------------------------------------------------------------------------------------
// HQ is assumed to be in NewGameState already, based on how the events get activated
function XComGameState_HeadquartersAlien GetAlienHQ(XComGameState NewGameState)
{
	local XComGameState_HeadquartersAlien AlienHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	return AlienHQ;
}

//---------------------------------------------------------------------------------------
function bool AtFirstMonth()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	return (ResistanceHQ.NumMonths == 0);
}

//---------------------------------------------------------------------------------------
function bool AtMaxDoom()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (AlienHQ.AtMaxDoom());
}

//---------------------------------------------------------------------------------------
function bool AtMaxFacilities()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Facilities;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Facilities = AlienHQ.GetValidFacilityDoomMissions();

	return (Facilities.Length >= AlienHQ.GetMaxFacilities());
}

//---------------------------------------------------------------------------------------
function bool HaveSeenFacility()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (AlienHQ.bHasSeenFacility);
}

//---------------------------------------------------------------------------------------
function bool OnNormalOrEasier()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings SettingsState;

	History = `XCOMHISTORY;
	SettingsState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	return (SettingsState.DifficultySetting <= 1);
}

//---------------------------------------------------------------------------------------
function int GetPercent(float fScalar)
{
	local int PercentToReturn;

	PercentToReturn = Round(fScalar * 100.0f);
	PercentToReturn = Abs(PercentToReturn - 100);

	return PercentToReturn;
}

//---------------------------------------------------------------------------------------
function string GetTimeString(int NumDays)
{
	local int NumWeeks;

	if(NumDays < 7)
	{
		if(NumDays == 1)
		{
			return string(NumDays) @ default.DayLabel;
		}
		else
		{
			return string(NumDays) @ default.DaysLabel;
		}
	}

	NumWeeks = NumDays / 7;

	if(NumWeeks == 1)
	{
		return string(NumWeeks) @ default.WeekLabel;
	}

	return string(NumWeeks) @ default.WeeksLabel;
}

//---------------------------------------------------------------------------------------
function string GetBlocksString(int NumBlocks)
{
	if(NumBlocks == 1)
	{
		return string(NumBlocks) @ default.BlockLabel;
	}

	return string(NumBlocks) @ default.BlocksLabel;
}

//---------------------------------------------------------------------------------------
function XComGameState_BlackMarket GetAndAddBlackMarket(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_BlackMarket BlackMarketState;

	foreach NewGameState.IterateByClassType(class'XComGameState_BlackMarket', BlackMarketState)
	{
		break;
	}

	if(BlackMarketState == none)
	{
		History = `XCOMHISTORY;
		BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
		BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', BlackMarketState.ObjectID));
		NewGameState.AddStateObject(BlackMarketState);
	}

	return BlackMarketState;
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetMinorBreakthroughDoom()
{
	return default.MinorBreakthroughDoom[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetMajorBreakthroughDoom()
{
	return default.MajorBreakthroughDoom[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetMidnightRaidsScalar()
{
	return default.MidnightRaidsScalar[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetRuralCheckpointsScalar()
{
	return default.RuralCheckpointsScalar[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetNewConstructionReductionDays()
{
	return default.NewConstructionReductionDays[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetAlienCypherScalar()
{
	return default.AlienCypherScalar[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetResistanceInformantReductionDays()
{
	return default.ResistanceInformantReductionDays[`DifficultySetting];
}