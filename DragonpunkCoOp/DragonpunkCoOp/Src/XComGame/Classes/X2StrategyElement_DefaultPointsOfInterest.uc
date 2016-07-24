//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultPointsOfInterest.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultPointsOfInterest extends X2StrategyElement
	dependson(X2PointOfInterestTemplate);

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreatePOISuppliesTemplate());
	Templates.AddItem(CreatePOIIntelTemplate());
	Templates.AddItem(CreatePOIAlloysTemplate());
	Templates.AddItem(CreatePOIAlloysEleriumTemplate());
	Templates.AddItem(CreatePOIScientistTemplate());
	Templates.AddItem(CreatePOIEngineerTemplate());
	Templates.AddItem(CreatePOIRookiesTemplate());
	Templates.AddItem(CreatePOISoldierTemplate());
	Templates.AddItem(CreatePOIAvengerPowerTemplate());
	Templates.AddItem(CreatePOIAvengerResCommsTemplate());
	Templates.AddItem(CreatePOIIncreaseIncomeTemplate());
	Templates.AddItem(CreatePOIReducedContactTemplate());
	Templates.AddItem(CreatePOISupplyRaidTemplate());
	Templates.AddItem(CreatePOIGuerillaOpTemplate());
	Templates.AddItem(CreatePOILootTableTemplate());
	Templates.AddItem(CreatePOIHeavyWeaponTemplate());
	Templates.AddItem(CreatePOIGrenadeAmmoTemplate());
	Templates.AddItem(CreatePOIFacilityLeadTemplate());
	Templates.AddItem(CreatePOIGamescomTemplate());

	return Templates;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOISuppliesTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Supplies');

	Template.IsRewardNeededFn = IsSuppliesRewardNeeded;

	return Template;
}
function bool IsSuppliesRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2PointOfInterestTemplate POITemplate;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	POITemplate = POIState.GetMyTemplate();

	if (XComHQ.GetSupplies() <= POITemplate.IsNeededAmount[`DIFFICULTYSETTING])
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIIntelTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Intel');

	Template.IsRewardNeededFn = IsIntelRewardNeeded;

	return Template;
}
function bool IsIntelRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.GetIntel() < class'UIUtilities_Strategy'.static.GetMinimumContactCost())
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIAlloysTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Alloys');

	Template.IsRewardNeededFn = IsAlloysRewardNeeded;

	return Template;
}
function bool IsAlloysRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2PointOfInterestTemplate POITemplate;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	POITemplate = POIState.GetMyTemplate();

	if (XComHQ.GetAlienAlloys() <= POITemplate.IsNeededAmount[`DIFFICULTYSETTING])
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIAlloysEleriumTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_AlloysElerium');

	Template.IsRewardNeededFn = IsEleriumRewardNeeded;

	return Template;
}
function bool IsEleriumRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2PointOfInterestTemplate POITemplate;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	POITemplate = POIState.GetMyTemplate();

	if (XComHQ.GetEleriumDust() <= POITemplate.IsNeededAmount[`DIFFICULTYSETTING])
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIScientistTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Scientist');
	
	Template.bStaffPOI = true;
	Template.IsRewardNeededFn = IsScientistRewardNeeded;
	Template.CanAppearFn = CanScientistPOIAppear;

	return Template;
}
function bool IsScientistRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MinScientists, NumScientists, iMonthsPassed;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);

	// Calculate the minimum amount of scientists the player should have at this time
	if (iMonthsPassed > 0)
	{
		MinScientists = XComHQ.StartingScientistMinCap[`DIFFICULTYSETTING] + (XComHQ.ScientistMinCapIncrease[`DIFFICULTYSETTING] * iMonthsPassed);
		NumScientists = XComHQ.GetNumberOfScientists();
	}

	return (NumScientists < MinScientists);
}
function bool CanScientistPOIAppear(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_PointOfInterest EngineerPOIState;
	local TDateTime CurrentTime;
	local int MaxScientists, iMonthsPassed;
		
	// If on the staff timer and one has already appeared, do not appear
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	if (ResHQ.bStaffPOISpawnedDuringTimer)
	{
		return false;
	}

	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, ResHQ.StartTime);
	
	// Calculate the maximum amount of scientists allowed at this time
	MaxScientists = XComHQ.StartingScientistMaxCap[`DIFFICULTYSETTING] + (XComHQ.ScientistMaxCapIncrease[`DIFFICULTYSETTING] * iMonthsPassed);
	if (XComHQ.GetNumberOfScientists() >= MaxScientists)
	{
		return false;
	}
	
	// If there have been more Sci POIs than Eng POIs spawned, do not appear
	EngineerPOIState = ResHQ.GetPOIStateFromTemplateName('POI_Engineer');
	if (EngineerPOIState != none)
	{
		return (POIState.NumSpawns <= EngineerPOIState.NumSpawns);
	}

	return true;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIEngineerTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Engineer');

	Template.bStaffPOI = true;
	Template.IsRewardNeededFn = IsEngineerRewardNeeded;
	Template.CanAppearFn = CanEngineerPOIAppear;

	return Template;
}
function bool IsEngineerRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime StartDateTime, CurrentTime;
	local int MinEngineers, NumEngineers, iMonthsPassed;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	StartDateTime = class'UIUtilities_Strategy'.static.GetResistanceHQ().StartTime;
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, StartDateTime);

	// Calculate the minimum amount of scientists the player should have at this time
	if (iMonthsPassed > 0)
	{
		MinEngineers = XComHQ.StartingEngineerMinCap[`DIFFICULTYSETTING] + (XComHQ.EngineerMinCapIncrease[`DIFFICULTYSETTING] * iMonthsPassed);
		NumEngineers = XComHQ.GetNumberOfEngineers();
	}

	return (NumEngineers < MinEngineers);
}
function bool CanEngineerPOIAppear(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_PointOfInterest ScientistPOIState;
	local TDateTime CurrentTime;
	local int MaxEngineers, iMonthsPassed;

	// If on the staff timer and one has already appeared, do not appear
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	if (ResHQ.bStaffPOISpawnedDuringTimer)
	{
		return false;
	}
		
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();
	iMonthsPassed = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(CurrentTime, ResHQ.StartTime);

	// Calculate the maximum amount of engineers allowed at this time
	MaxEngineers = XComHQ.StartingEngineerMaxCap[`DIFFICULTYSETTING] + (XComHQ.EngineerMaxCapIncrease[`DIFFICULTYSETTING] * iMonthsPassed);
	if (XComHQ.GetNumberOfEngineers() >= MaxEngineers)
	{
		return false;
	}

	// If there have been more Eng POIs than Sci POIs spawned, do not appear
	ScientistPOIState = ResHQ.GetPOIStateFromTemplateName('POI_Scientist');
	if (ScientistPOIState != none)
	{
		return (POIState.NumSpawns <= ScientistPOIState.NumSpawns);
	}

	return true;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIRookiesTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Rookies');

	Template.IsRewardNeededFn = IsRookiesRewardNeeded;

	return Template;
}
function bool IsRookiesRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2PointOfInterestTemplate POITemplate;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	POITemplate = POIState.GetMyTemplate();

	if (XComHQ.GetNumberOfDeployableSoldiers() < POITemplate.IsNeededAmount[`DIFFICULTYSETTING])
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOISoldierTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Soldier');

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIAvengerPowerTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_AvengerPower');

	Template.IsRewardNeededFn = IsPowerRewardNeeded;

	return Template;
}
function bool IsPowerRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2PointOfInterestTemplate POITemplate;
	local int PowerDifferential;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	POITemplate = POIState.GetMyTemplate();

	PowerDifferential = XComHQ.GetPowerProduced() - XComHQ.GetPowerConsumed();
	if (PowerDifferential <= POITemplate.IsNeededAmount[`DIFFICULTYSETTING])
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIAvengerResCommsTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_AvengerResComms');

	Template.IsRewardNeededFn = IsResCommsRewardNeeded;
	Template.CanAppearFn = CanResCommsAppear;

	return Template;
}
function bool IsResCommsRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2PointOfInterestTemplate POITemplate;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	POITemplate = POIState.GetMyTemplate();

	if (XComHQ.GetRemainingContactCapacity() <= POITemplate.IsNeededAmount[`DIFFICULTYSETTING])
	{
		return true;
	}

	return false;
}
function bool CanResCommsAppear(XComGameState_PointOfInterest POIState)
{
	return (class'UIUtilities_Strategy'.static.GetXComHQ().IsContactResearched());
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIIncreaseIncomeTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_IncreaseIncome');

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIReducedContactTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_ReducedContact');
	
	Template.CanAppearFn = CanResCommsAppear;

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOISupplyRaidTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_SupplyRaid');

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIGuerillaOpTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_GuerillaOp');

	Template.CanAppearFn = CanGOpsAppear;

	return Template;
}
function bool CanGOpsAppear(XComGameState_PointOfInterest POIState)
{
	return (class'UIUtilities_Strategy'.static.GetAlienHQ().ChosenDarkEvents.Length > 0);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOILootTableTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_LootTable');

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIHeavyWeaponTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_HeavyWeapon');

	Template.CanAppearFn = CanHeavyWeaponPOIAppear;

	return Template;
}
function bool CanHeavyWeaponPOIAppear(XComGameState_PointOfInterest POIState)
{
	return (class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched('EXOSuit') ||
	class'UIUtilities_Strategy'.static.GetXComHQ().IsTechResearched('WARSuit'));
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIGrenadeAmmoTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_GrenadeAmmo');

	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIFacilityLeadTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_FacilityLead');

	Template.IsRewardNeededFn = IsFacilityLeadRewardNeeded;
	Template.CanAppearFn = CanFacilityLeadAppear;

	return Template;
}
function bool IsFacilityLeadRewardNeeded(XComGameState_PointOfInterest POIState)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Missions;
	local float fDoomPercent;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();
	Missions = AlienHQ.GetValidFacilityDoomMissions(true);
	fDoomPercent = (1.0 * AlienHQ.GetCurrentDoom()) / AlienHQ.GetMaxDoom();

	if (fDoomPercent >= 0.75 && Missions.Length > 0)
	{
		return true;
	}

	return false;
}
function bool CanFacilityLeadAppear(XComGameState_PointOfInterest POIState)
{
	return (class'UIUtilities_Strategy'.static.GetAlienHQ().bHasSeenFacility);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePOIGamescomTemplate()
{
	local X2PointOfInterestTemplate Template;

	`CREATE_X2POINTOFINTEREST_TEMPLATE(Template, 'POI_Gamescom');

	Template.CanAppearFn = CanGamescomPOIAppear;

	return Template;
}
function bool CanGamescomPOIAppear(XComGameState_PointOfInterest POIState)
{
	return false;
}