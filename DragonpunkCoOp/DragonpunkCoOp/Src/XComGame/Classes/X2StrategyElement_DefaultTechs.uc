//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultTechs.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultTechs extends X2StrategyElement config(GameData);

var config array<int> MinAdventDatapadIntel;
var config array<int> MaxAdventDatapadIntel;
var config array<int> MinAlienDatapadIntel;
var config array<int> MaxAlienDatapadIntel;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Techs;

	// Weapon Techs
	Techs.AddItem(CreateModularWeaponsTemplate());
	Techs.AddItem(CreateGaussWeaponsTemplate());
	Techs.AddItem(CreateMagnetizedWeaponsTemplate());
	Techs.AddItem(CreatePlasmaRifleTemplate());
	Techs.AddItem(CreateHeavyPlasmaTemplate());
	Techs.AddItem(CreatePlasmaSniperTemplate());
	Techs.AddItem(CreateAlloyCannonTemplate());

	// Armor Techs
	Techs.AddItem(CreateHybridMaterialsTemplate());
	Techs.AddItem(CreatePlatedArmorTemplate());
	Techs.AddItem(CreateEXOSuitTemplate());
	Techs.AddItem(CreateSpiderSuitTemplate());
	Techs.AddItem(CreatePoweredArmorTemplate());
	Techs.AddItem(CreateWraithSuitTemplate());
	Techs.AddItem(CreateWARSuitTemplate());

	// Elerium Tech
	Techs.AddItem(CreateEleriumTemplate());

	// Psionics
	Techs.AddItem(CreatePsionicsTemplate());

	// Alien Facility Lead
	Techs.AddItem(CreateFacilityLeadTemplate());

	// Intel Techs
	Techs.AddItem(CreateAdventDatapadTemplate());
	Techs.AddItem(CreateAlienDatapadTemplate());

	// Autopsy Techs
	Techs.AddItem(CreateAlienBiotechTemplate());
	Techs.AddItem(CreateAutopsySectoidTemplate());
	Techs.AddItem(CreateAutopsyViperTemplate());
	Techs.AddItem(CreateAutopsyMutonTemplate());
	Techs.AddItem(CreateAutopsyBerserkerTemplate());
	Techs.AddItem(CreateAutopsyArchonTemplate());
	Techs.AddItem(CreateAutopsyGatekeeperTemplate());
	Techs.AddItem(CreateAutopsyAndromedonTemplate());
	Techs.AddItem(CreateAutopsyFacelessTemplate());
	Techs.AddItem(CreateAutopsyChryssalidTemplate());
	Techs.AddItem(CreateAutopsyAdventTrooperTemplate());
	Techs.AddItem(CreateAutopsyAdventStunLancerTemplate());
	Techs.AddItem(CreateAutopsyAdventShieldbearerTemplate());
	Techs.AddItem(CreateAutopsyAdventMECTemplate());
	Techs.AddItem(CreateAutopsyAdventTurretTemplate());
	Techs.AddItem(CreateAutopsySectopodTemplate());

	// Golden Path Techs & Shadow Chamber Projects
	Techs.AddItem(CreateResistanceCommunicationsTemplate());
	Techs.AddItem(CreateResistanceRadioTemplate());
	Techs.AddItem(CreateAutopsyAdventOfficerTemplate());
	Techs.AddItem(CreateAlienEncryptionTemplate());
	Techs.AddItem(CreateCodexBrainPt1Template());
	Techs.AddItem(CreateCodexBrainPt2Template());
	Techs.AddItem(CreateBlacksiteDataTemplate());
	Techs.AddItem(CreateForgeStasisSuitTemplate());
	Techs.AddItem(CreatePsiGateTemplate());
	Techs.AddItem(CreateAutopsyAdventPsiWitchTemplate());
	
	// Proving Grounds Projects
	Techs.AddItem(CreateSkulljackTemplate());
	Techs.AddItem(CreateExperimentalAmmoTemplate());
	Techs.AddItem(CreateExperimentalGrenadeTemplate());
	Techs.AddItem(CreateExperimentalArmorTemplate());
	Techs.AddItem(CreateBluescreenTemplate());
	Techs.AddItem(CreateBattlefieldMedicineTemplate());
	Techs.AddItem(CreatePlasmaGrenadeTemplate());
	Techs.AddItem(CreateAdvancedGrenadesTemplate());
	Techs.AddItem(CreateSkullminingTemplate());
	Techs.AddItem(CreateHeavyWeaponsTemplate());
	Techs.AddItem(CreateAdvancedHeavyWeaponsTemplate());

	return Techs;
}

//---------------------------------------------------------------------------------------
// Helper function for calculating project time
static function int StafferXDays(int iNumScientists, int iNumDays)
{
	return (iNumScientists * 5) * (24 * iNumDays); // Scientists at base skill level
}

// #######################################################################################
// -------------------- WEAPON TECHS -----------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateModularWeaponsTemplate()
{
	local X2TechTemplate Template;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'ModularWeapons');
	Template.PointsToComplete = 720;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Modular_Weapons";
	Template.SortingTier = 1;
	Template.ResearchCompletedFn = ModularWeaponsResearchCompleted;

	// Requirements
	Template.Requirements.RequiredObjectives.AddItem('T0_M1_WelcomeToLabs');
	Template.Requirements.bVisibleIfObjectivesNotMet = true;

	return Template;
}

static function ModularWeaponsResearchCompleted(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local XComGameState_HeadquartersXCom XComHQ, NewXComHQ;
	local XComGameStateHistory History;	

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewXComHQ.bModularWeapons = true;
	NewGameState.AddStateObject(NewXComHQ);
}

static function X2DataTemplate CreateMagnetizedWeaponsTemplate()
{
	local X2TechTemplate Template;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'MagnetizedWeapons');
	Template.PointsToComplete = 6500;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Magnetized_Weapons";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('ModularWeapons');
	
	return Template;
}

static function X2DataTemplate CreateGaussWeaponsTemplate()
{
	local X2TechTemplate Template;
//	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'GaussWeapons');
	Template.PointsToComplete = 3840;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Gauss_Weapons";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('MagnetizedWeapons');

	// Cost
	//Resources.ItemTemplateName = 'EleriumDust';
	//Resources.Quantity = 10;
	//Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreatePlasmaRifleTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'PlasmaRifle');
	Template.PointsToComplete = 8000;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_PlasmaRifle";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Tech_Elerium');

	// Cost
	Resources.ItemTemplateName='AlienAlloy';
	Resources.Quantity=10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreateHeavyPlasmaTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'HeavyPlasma');
	Template.PointsToComplete = 4000;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Heavy_Plasma";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PlasmaRifle');

	// Cost
	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreatePlasmaSniperTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'PlasmaSniper');
	Template.PointsToComplete = 4500;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_PlasmaSniper";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PlasmaRifle');

	// Cost
	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreateAlloyCannonTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AlloyCannon');
	Template.PointsToComplete = 2000;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Alloy_Cannon";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PlasmaRifle');

	// Cost
	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}


static function X2DataTemplate CreatePsionicsTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Psionics');
	Template.PointsToComplete = 6000;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Psionics";
	
	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsySectoid');

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);
	
	return Template;
}

// #######################################################################################
// -------------------- ARMOR TECHS ------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateHybridMaterialsTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'HybridMaterials');
	Template.PointsToComplete = 720;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Nanofiber_Materials";

	// Requirements
	Template.Requirements.RequiredObjectives.AddItem('T0_M1_WelcomeToLabs');
	Template.Requirements.bVisibleIfObjectivesNotMet = true;

	// Cost
	Artifacts.ItemTemplateName = 'CorpseAdventTrooper';
	Artifacts.Quantity = 2;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}
static function X2DataTemplate CreatePlatedArmorTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'PlatedArmor');
	Template.PointsToComplete = 7200;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_PlatedArmor";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('HybridMaterials');

	// Cost
	Resources.ItemTemplateName='AlienAlloy';
	Resources.Quantity = 10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function X2DataTemplate CreateEXOSuitTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'EXOSuit');
	Template.PointsToComplete = StafferXDays(1, 7);
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_EXOSuit";

	Template.bProvingGround = true;
	Template.bArmor = true;
	Template.bRepeatable = true;
	Template.ResearchCompletedFn = GiveRandomItemReward;

	// Randomized Item Rewards
	Template.ItemRewards.AddItem('HeavyPlatedArmor');

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PlatedArmor');

	// Cost
	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseAdventTrooper';
	Artifacts.Quantity = 2;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}
static function X2DataTemplate CreateSpiderSuitTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'SpiderSuit');
	Template.PointsToComplete = StafferXDays(1, 7);
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_SpiderSuit";
	
	Template.bProvingGround = true;
	Template.bArmor = true;
	Template.bRepeatable = true;
	Template.ResearchCompletedFn = GiveRandomItemReward;

	// Randomized Item Rewards
	Template.ItemRewards.AddItem('LightPlatedArmor');

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PlatedArmor');

	// Cost
	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'CorpseAdventStunLancer';
	Artifacts.Quantity = 2;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}
static function X2DataTemplate CreatePoweredArmorTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'PoweredArmor');
	Template.PointsToComplete = 9000;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_PoweredArmor";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Tech_Elerium');

	// Cost
	Resources.ItemTemplateName='AlienAlloy';
	Resources.Quantity = 20;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreateWraithSuitTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'WraithSuit');
	Template.PointsToComplete = StafferXDays(1, 10);
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_WraithSuit";
	
	Template.bProvingGround = true;
	Template.bArmor = true;
	Template.bRepeatable = true;
	Template.ResearchCompletedFn = GiveRandomItemReward;

	// Randomized Item Rewards
	Template.ItemRewards.AddItem('LightPoweredArmor');

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PoweredArmor');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateWARSuitTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'WARSuit');
	Template.PointsToComplete = StafferXDays(1, 10);
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_WARSuit";

	Template.bProvingGround = true;
	Template.bArmor = true;
	Template.bRepeatable = true;
	Template.ResearchCompletedFn = GiveRandomItemReward;

	// Randomized Item Rewards
	Template.ItemRewards.AddItem('HeavyPoweredArmor');

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PoweredArmor');

	// Cost
 	Resources.ItemTemplateName = 'Supplies';
 	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

// #######################################################################################
// -------------------- ELERIUM TECH -----------------------------------------------------
// #######################################################################################
 
static function X2DataTemplate CreateEleriumTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Tech_Elerium');
	Template.PointsToComplete = 5000;
	Template.SortingTier = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_Elerium";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('GaussWeapons');
	Template.Requirements.RequiredTechs.AddItem('PlatedArmor');

	// Cost
	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 20;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

// #######################################################################################
// -------------------- FACILITY TECHS ---------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateFacilityLeadTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources, Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Tech_AlienFacilityLead');
	Template.PointsToComplete = 1080;
	Template.RepeatPointsIncrease = 2080;
	Template.bRepeatable = true;
	Template.SortingTier = 3;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Facility_Lead";
	Template.ResearchCompletedFn = FacilityLeadCompleted;

	Template.Requirements.RequiredItems.AddItem('FacilityLeadItem');
	Template.Requirements.SpecialRequirementsFn = IsFacilityMissionAvailable;

	Resources.ItemTemplateName = 'Intel';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);
	Artifacts.ItemTemplateName = 'FacilityLeadItem';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

// #######################################################################################
// -------------------- INTEL TECHS ------------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateAdventDatapadTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Tech_AdventDatapad');
	Template.PointsToComplete = 1800;
	Template.RepeatPointsIncrease = 800;
	Template.bRepeatable = true;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Advent_Datapad";
	Template.SortingTier = 3;
	Template.ResearchCompletedFn = IntelTechCompleted;

	// Requirements
	Template.Requirements.RequiredItems.AddItem('AdventDatapad');

	// Cost
	Artifacts.ItemTemplateName = 'AdventDatapad';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAlienDatapadTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Tech_AlienDatapad');
	Template.PointsToComplete = 3000;
	Template.RepeatPointsIncrease = 840;
	Template.bRepeatable = true;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.IC_Alien_Datapad_Decryption";
	Template.SortingTier = 3;
	Template.ResearchCompletedFn = IntelTechCompleted;

	// Requirements
	Template.Requirements.RequiredItems.AddItem('AlienDatapad');

	// Cost
	Artifacts.ItemTemplateName = 'AlienDatapad';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

function IntelTechCompleted(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int IntelAmount, TechID;

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
	
	if(TechState.GetMyTemplateName() == 'Tech_AdventDatapad')
	{
		IntelAmount = GetMinAdventDatapadIntel() + `SYNC_RAND(GetMaxAdventDatapadIntel() - GetMinAdventDatapadIntel() + 1);
	}
	else if(TechState.GetMyTemplateName() == 'Tech_AlienDatapad')
	{
		IntelAmount = GetMinAlienDatapadIntel() + `SYNC_RAND(GetMaxAlienDatapadIntel() - GetMinAlienDatapadIntel() + 1);
	}
	
	// Check for Spy Ring Continent Bonus
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	IntelAmount += Round(float(IntelAmount) * (float(ResistanceHQ.IntelRewardPercentIncrease) / 100.0));

	TechID = TechState.ObjectID;
	TechState = XComGameState_Tech(NewGameState.GetGameStateForObjectID(TechID));

	if(TechState == none)
	{
		TechState = XComGameState_Tech(NewGameState.CreateStateObject(class'XComGameState_Tech', TechID));
		NewGameState.AddStateObject(TechState);
	}

	TechState.IntelReward = IntelAmount;
	XComHQ.AddResource(NewGameState, 'Intel', IntelAmount);
}

// #######################################################################################
// -------------------- AUTOPSY TECHS ---------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateAlienBiotechTemplate()
{
	local X2TechTemplate Template;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AlienBiotech');
	Template.PointsToComplete = 1080;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Alien_Biotech";
	Template.IsPriorityFn = AlienBiotechPriority;
	Template.SortingTier = 1;
	Template.bJumpToLabs = true;

	return Template;
}

static function X2DataTemplate CreateAutopsySectoidTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsySectoid');
	Template.PointsToComplete = 1080;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsySectoid";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Sectoid";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseSectoid');
	Template.Requirements.RequiredScienceScore = 10;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseSectoid';
	Artifacts.Quantity = 6;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseSectoid';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyViperTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyViper');
	Template.PointsToComplete = 1800;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyViper";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Viper";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseViper');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseViper';
	Artifacts.Quantity = 5;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseViper';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyMutonTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyMuton');
	Template.PointsToComplete = 2880;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyMuton";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Muton";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseMuton');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseMuton';
	Artifacts.Quantity = 5;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseMuton';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyBerserkerTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyBerserker');
	Template.PointsToComplete = 2880;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyBerserker";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Berserker";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseBerserker');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseBerserker';
	Artifacts.Quantity = 5;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseBerserker';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyArchonTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyArchon');
	Template.PointsToComplete = 4000;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyArchon";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Archon";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseArchon');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseArchon';
	Artifacts.Quantity = 3;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseArchon';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyGatekeeperTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyGatekeeper');
	Template.PointsToComplete = 4800;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyGatekeeper";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Gatekeeper";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseGatekeeper');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseGatekeeper';
	Artifacts.Quantity = 3;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseGatekeeper';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyAndromedonTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAndromedon');
	Template.PointsToComplete = 4200;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyAndromedon";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Andromedon";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAndromedon');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseAndromedon';
	Artifacts.Quantity = 4;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseAndromedon';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyFacelessTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyFaceless');
	Template.PointsToComplete = 1080;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyFaceless";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Faceless";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseFaceless');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseFaceless';
	Artifacts.Quantity = 3;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseFaceless';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyChryssalidTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyChryssalid');
	Template.PointsToComplete = 3600;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyCryssalid";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Chryssalid";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseChryssalid');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseChryssalid';
	Artifacts.Quantity = 15;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseChryssalid';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyAdventTrooperTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAdventTrooper');
	Template.PointsToComplete = 960;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyAdventTrooper";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_AdventTrooper";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAdventTrooper');
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventOfficer');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseAdventTrooper';
	Artifacts.Quantity = 10;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseAdventTrooper';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

// CreateAutopsyAdventOfficerTemplate ... See Golden Path techs, below

static function X2DataTemplate CreateAutopsyAdventStunLancerTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAdventStunLancer');
	Template.PointsToComplete = 1800;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyAdventStunLancer";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_AdventStunlancer";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAdventStunLancer');
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventOfficer');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseAdventStunLancer';
	Artifacts.Quantity = 4;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseAdventStunLancer';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyAdventShieldbearerTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAdventShieldbearer');
	Template.PointsToComplete = 1500;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyAdventShieldbearer";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_AdventShieldbearer";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAdventShieldbearer');
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventOfficer');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseAdventShieldbearer';
	Artifacts.Quantity = 4;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseAdventShieldbearer';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyAdventMECTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAdventMEC');
	Template.PointsToComplete = 2400;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyMEC";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_AdventMEC";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAdventMEC');
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventOfficer');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseAdventMEC';
	Artifacts.Quantity = 3;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseAdventMEC';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsyAdventTurretTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAdventTurret');
	Template.PointsToComplete = 960;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsyAdventTurret";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_AdventTurret";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAdventTurret');
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventOfficer');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseAdventTurret';
	Artifacts.Quantity = 3;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseAdventTurret';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateAutopsySectopodTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsySectopod');
	Template.PointsToComplete = 5040;
	Template.strImage = "img:///UILibrary_StrategyImages.ScienceIcons.IC_AutopsySextopod";
	Template.bAutopsy = true;
	Template.bCheckForceInstant = true;
	Template.SortingTier = 2;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Sectopod";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseSectopod');

	// Instant Requirements. Will become the Cost if the tech is forced to Instant.
	Artifacts.ItemTemplateName = 'CorpseSectopod';
	Artifacts.Quantity = 3;
	Template.InstantRequirements.RequiredItemQuantities.AddItem(Artifacts);

	// Cost
	Artifacts.ItemTemplateName = 'CorpseSectopod';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

// #######################################################################################
// -------------------- GOLDEN PATH TECHS ------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateResistanceCommunicationsTemplate()
{
	local X2TechTemplate Template;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'ResistanceCommunications');
	Template.PointsToComplete = 1650;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Resistance_Communications";
	Template.ResearchCompletedFn = ResistanceCommsCompleted;
	Template.SortingTier = 1;

	Template.IsPriorityFn = AlwaysPriority;

	// Requirements
	Template.Requirements.RequiredObjectives.AddItem('T2_M0_CompleteGuerillaOps');

	return Template;
}

function ResistanceCommsCompleted(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(RegionState.ResistanceLevel == eResLevel_Unlocked)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.CreateStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
			NewGameState.AddStateObject(RegionState);
			RegionState.bUnlockedPopup = true;
		}
	}
}

static function X2DataTemplate CreateResistanceRadioTemplate()
{
	local X2TechTemplate Template;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'ResistanceRadio');
	Template.PointsToComplete = 2160;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Resistance_Radio";
	Template.SortingTier = 1;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('ResistanceCommunications');

	return Template;
}

static function X2DataTemplate CreateAutopsyAdventOfficerTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost ArtifactReq;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAdventOfficer');
	Template.PointsToComplete = 1200;
	Template.TutorialPointsToComplete = StafferXDays(2, 3);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Advent_Officer";
	Template.bAutopsy = true;
	Template.SortingTier = 1;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_AdventOfficer";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAdventOfficer');

	// Cost
	ArtifactReq.ItemTemplateName = 'CorpseAdventOfficer';
	ArtifactReq.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(ArtifactReq);
	
	Template.IsPriorityFn = AdventOfficerPriority;
	Template.bJumpToLabs = true;

	return Template;
}

static function X2DataTemplate CreateSkulljackTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Skulljack');
	Template.PointsToComplete = StafferXDays(1, 14);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Skulljack";
	Template.ResearchCompletedFn = GiveRandomItemReward;
	Template.SortingTier = 1;

	// Item Reward
	Template.ItemRewards.AddItem('Skulljack');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Template.bProvingGround = true;
	Template.IsPriorityFn = SkulljackPriority;
	Template.bRepeatable = true;

	return Template;
}

static function X2DataTemplate CreateAlienEncryptionTemplate()
{
	local X2TechTemplate Template;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AlienEncryption');
	Template.PointsToComplete = 2880;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.IC_Alien_Encryption";
	Template.SortingTier = 1;

	// Requirements
	Template.Requirements.RequiredItems.AddItem('BlacksiteDataCube');
	Template.Requirements.AlternateRequiredItems.AddItem('CorpseCyberus');

	Template.IsPriorityFn = AlwaysPriority;

	return Template;
}

// Shadow Projects
static function X2DataTemplate CreateCodexBrainPt1Template()
{
	local X2TechTemplate Template;
	local ArtifactCost ArtifactReq;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'CodexBrainPt1');
	Template.PointsToComplete = 2500;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Codex_Brain_Pt1";
	Template.bShadowProject = true;
	Template.SortingTier = 1;

	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseCyberus');
	Template.Requirements.RequiredFacilities.AddItem('ShadowChamber');

	Template.Requirements.RequiredEngineeringScore = 0;
	Template.Requirements.RequiredScienceScore = 15;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;
	Template.IsPriorityFn = AlwaysPriority;

	// Cost
	ArtifactReq.ItemTemplateName = 'CorpseCyberus';
	ArtifactReq.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(ArtifactReq);

	return Template;
}

static function X2DataTemplate CreateCodexBrainPt2Template()
{
	local X2TechTemplate Template;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'CodexBrainPt2');
	Template.PointsToComplete = 6000;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Codex_Brain_Pt2";
	Template.bShadowProject = true;
	Template.SortingTier = 1;

	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredTechs.AddItem('CodexBrainPt1');
	Template.Requirements.RequiredFacilities.AddItem('ShadowChamber');

	Template.Requirements.RequiredEngineeringScore = 0;
	Template.Requirements.RequiredScienceScore = 25;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;
	Template.IsPriorityFn = AlwaysPriority;

	return Template;
}

static function X2DataTemplate CreateBlacksiteDataTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost ArtifactReq;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'BlacksiteData');
	Template.PointsToComplete = 2250;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Blacksite_Vial";
	Template.bShadowProject = true;
	Template.SortingTier = 1;

	Template.Requirements.RequiredItems.AddItem('BlacksiteDataCube');
	Template.Requirements.RequiredFacilities.AddItem('ShadowChamber');

	Template.Requirements.RequiredEngineeringScore = 0;
	Template.Requirements.RequiredScienceScore = 15;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;
	Template.IsPriorityFn = AlwaysPriority;

	// Cost
	ArtifactReq.ItemTemplateName = 'BlacksiteDataCube';
	ArtifactReq.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(ArtifactReq);

	return Template;
}

static function X2DataTemplate CreateForgeStasisSuitTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost ArtifactReq;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'ForgeStasisSuit');
	Template.PointsToComplete = 2500;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Advent_Stasis_Suit";
	Template.bShadowProject = true;
	Template.SortingTier = 1;

	Template.Requirements.RequiredItems.AddItem('StasisSuitComponent');
	Template.Requirements.RequiredFacilities.AddItem('ShadowChamber');

	Template.Requirements.RequiredEngineeringScore = 0;
	Template.Requirements.RequiredScienceScore = 20;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;
	Template.IsPriorityFn = AlwaysPriority;

	// Cost
	ArtifactReq.ItemTemplateName = 'StasisSuitComponent';
	ArtifactReq.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(ArtifactReq);

	return Template;
}

static function X2DataTemplate CreatePsiGateTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'PsiGate');
	Template.PointsToComplete = 4000;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Psi_Gate_Project";
	Template.bShadowProject = true;
	Template.SortingTier = 1;

	Template.Requirements.RequiredUpgrades.AddItem('ShadowChamber_CelestialGate');
	Template.Requirements.RequiredFacilities.AddItem('ShadowChamber');

	Template.Requirements.RequiredEngineeringScore = 0;
	Template.Requirements.RequiredScienceScore = 20;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;
	Template.IsPriorityFn = AlwaysPriority;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 65;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreateAutopsyAdventPsiWitchTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost ArtifactReq;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AutopsyAdventPsiWitch');
	Template.PointsToComplete = 4000;
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Avatar";
	Template.bShadowProject = true;
	Template.SortingTier = 1;

	Template.TechStartedNarrative = "X2NarrativeMoments.Strategy.Autopsy_Avatar";

	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	Template.Requirements.RequiredItems.AddItem('CorpseAdventPsiWitch');
	Template.Requirements.RequiredTechs.AddItem('ForgeStasisSuit');
	Template.Requirements.RequiredTechs.AddItem('PsiGate');
	Template.Requirements.RequiredFacilities.AddItem('ShadowChamber');

	Template.Requirements.RequiredEngineeringScore = 0;
	Template.Requirements.RequiredScienceScore = 25;
	Template.Requirements.bVisibleIfTechsNotMet = true;
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = true;
	Template.bAutopsy = true;
	Template.IsPriorityFn = AlwaysPriority;

	// Cost
	ArtifactReq.ItemTemplateName = 'CorpseAdventPsiWitch';
	ArtifactReq.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(ArtifactReq);

	return Template;
}

// #######################################################################################
// -------------------- PROVING GROUND TECHS ---------------------------------------------
// #######################################################################################

// Skulljack project goes here - but is up in golden path list

static function X2DataTemplate CreateExperimentalAmmoTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'ExperimentalAmmo');
	Template.PointsToComplete = StafferXDays(1, 10);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Experimental_Ammo";
	Template.bProvingGround = true;
	Template.bRandomWeapon = true;
	Template.bRepeatable = true;
	Template.SortingTier = 3;
	Template.ResearchCompletedFn = GiveDeckedItemReward;
	
	Template.RewardDeck = 'ExperimentalAmmoRewards';

	// Cost
	//Resources.ItemTemplateName = 'Supplies';
// 	Resources.Quantity = 25;
// 	Template.Cost.ResourceCosts.AddItem(Resources);
	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateExperimentalGrenadeTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'ExperimentalGrenade');
	Template.PointsToComplete = StafferXDays(1, 10);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Experimental_Grenade";
	Template.bProvingGround = true;
	Template.bRandomWeapon = true;
	Template.bRepeatable = true;
	Template.SortingTier = 3;
	Template.ResearchCompletedFn = GiveDeckedItemReward;
	
	Template.RewardDeck = 'ExperimentalGrenadeRewards';

	// Cost
// 	Resources.ItemTemplateName = 'Supplies';
// 	Resources.Quantity = 50;
// 	Template.Cost.ResourceCosts.AddItem(Resources);
	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateExperimentalArmorTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	//local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'ExperimentalArmor');
	Template.PointsToComplete = StafferXDays(1, 12);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_ExperimentalArmor";
	Template.bProvingGround = true;
	Template.bArmor = true;
	Template.bRepeatable = true;
	Template.SortingTier = 3;
	Template.ResearchCompletedFn = GiveDeckedItemReward;
	
	Template.RewardDeck = 'ExperimentalArmorRewards';

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventShieldbearer');

	// Cost
// 	Resources.ItemTemplateName = 'Supplies';
// 	Resources.Quantity = 75;
// 	Template.Cost.ResourceCosts.AddItem(Resources);
	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateBluescreenTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	//local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Bluescreen');
	Template.PointsToComplete = StafferXDays(1, 12);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Bluescreen_Project";
	Template.bProvingGround = true;
	Template.SortingTier = 1;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventMEC');

	// Cost
// 	Resources.ItemTemplateName = 'Supplies';
// 	Resources.Quantity = 100;
// 	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateBattlefieldMedicineTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'BattlefieldMedicine');
	Template.PointsToComplete = StafferXDays(1, 8);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Battlefield_Medicine_Project";
	Template.bProvingGround = true;
	Template.SortingTier = 1;
	Template.ResearchCompletedFn = UpgradeItems;
	
	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyViper');

	// Cost
 	Resources.ItemTemplateName = 'Supplies';
 	Resources.Quantity = 50;
 	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);
	

	Artifacts.ItemTemplateName = 'CorpseViper';
	Artifacts.Quantity = 2;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreatePlasmaGrenadeTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'PlasmaGrenade');
	Template.PointsToComplete = StafferXDays(1, 10);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Plasma_Grenade_Project";
	Template.bProvingGround = true;
	Template.SortingTier = 1;
	Template.ResearchCompletedFn = UpgradeItems;
	
	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyMuton');

	// Cost
 	Resources.ItemTemplateName = 'Supplies';
 	Resources.Quantity = 75;
 	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreateAdvancedGrenadesTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AdvancedGrenades');
	Template.PointsToComplete = StafferXDays(1, 15);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Advanced_Grenade_Project";
	Template.bProvingGround = true;
	Template.SortingTier = 1;
	Template.ResearchCompletedFn = UpgradeItems;
	
	// Requirements
	Template.Requirements.RequiredTechs.AddItem('PlasmaGrenade');

	// Cost
 	Resources.ItemTemplateName = 'Supplies';
 	Resources.Quantity = 50;
 	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	Resources.ItemTemplateName = 'AlienAlloy';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 5;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreateSkullminingTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;
	local ArtifactCost Artifacts;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Skullmining');
	Template.PointsToComplete = StafferXDays(1, 10);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_SkullminingProject";
	Template.bProvingGround = true;
	Template.SortingTier = 1;

	Template.TechAvailableNarrative = "X2NarrativeMoments.Strategy.Shen_Support_Modify_Skulljack";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Skulljack');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

	return Template;
}

static function X2DataTemplate CreateHeavyWeaponsTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
//	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'HeavyWeapons');
	Template.PointsToComplete = StafferXDays(1, 12);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Heavy_Weapons_Project";
	Template.bProvingGround = true;
	Template.bRandomWeapon = true;
	Template.bRepeatable = true;
	Template.SortingTier = 3;
	Template.ResearchCompletedFn = GiveDeckedItemReward;
	
	Template.RewardDeck = 'ExperimentalHeavyWeaponRewards';

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('EXOSuit');

	// Cost
	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

// 	Resources.ItemTemplateName = 'AlienAlloy';
// 	Resources.Quantity = 10;
// 	Template.Cost.ResourceCosts.AddItem(Resources);
// 
// 	Resources.ItemTemplateName = 'EleriumDust';
// 	Resources.Quantity = 10;
// 	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2DataTemplate CreateAdvancedHeavyWeaponsTemplate()
{
	local X2TechTemplate Template;
	local ArtifactCost Artifacts;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'AdvancedHeavyWeapons');
	Template.PointsToComplete = StafferXDays(1, 15);
	Template.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_AdvHeavy_Weapons_Project";
	Template.bProvingGround = true;
	Template.bRandomWeapon = true;
	Template.bRepeatable = true;
	Template.SortingTier = 3;
	Template.ResearchCompletedFn = GiveDeckedItemReward;
	
	Template.RewardDeck = 'ExperimentalPoweredWeaponRewards';

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('WARSuit'); // Should be W.A.R. Suit

	// Cost
 	Resources.ItemTemplateName = 'Supplies';
 	Resources.Quantity = 50;
 	Template.Cost.ResourceCosts.AddItem(Resources);

	Artifacts.ItemTemplateName = 'EleriumCore';
	Artifacts.Quantity = 1;
	Template.Cost.ArtifactCosts.AddItem(Artifacts);

// 	Resources.ItemTemplateName = 'AlienAlloy';
// 	Resources.Quantity = 15;
// 	Template.Cost.ResourceCosts.AddItem(Resources);
// 
// 	Resources.ItemTemplateName = 'EleriumDust';
// 	Resources.Quantity = 15;
// 	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

function GiveRandomItemReward(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local array<name> ItemRewards;
	local int iRandIndex;
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	ItemRewards = TechState.GetMyTemplate().ItemRewards;
	iRandIndex = `SYNC_RAND(ItemRewards.Length);
	ItemTemplate = ItemTemplateManager.FindItemTemplate(ItemRewards[iRandIndex]);

	GiveItemReward(NewGameState, TechState, ItemTemplate);
}

function GiveDeckedItemReward(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;	
	local X2CardManager CardManager;
	local string RewardName;

	CardManager = class'X2CardManager'.static.GetCardManager();
	CardManager.SelectNextCardFromDeck(TechState.GetMyTemplate().RewardDeck, RewardName);

	// Safety check in case the deck doesn't exist on old saves
	if (RewardName == "")
	{
		TechState.SetUpTechRewardDeck(TechState.GetMyTemplate());
		CardManager.SelectNextCardFromDeck(TechState.GetMyTemplate().RewardDeck, RewardName);
	}
	
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemTemplateManager.FindItemTemplate(name(RewardName));

	GiveItemReward(NewGameState, TechState, ItemTemplate);
}

function GiveItemReward(XComGameState NewGameState, XComGameState_Tech TechState, X2ItemTemplate ItemTemplate)
{	
	class'XComGameState_HeadquartersXCom'.static.GiveItem(NewGameState, ItemTemplate);

	TechState.ItemReward = ItemTemplate; // Needed for UI Alert display info
	TechState.bSeenResearchCompleteScreen = false; // Reset the research report for techs that are repeatable
}

function UpgradeItems(XComGameState NewGameState, XComGameState_Tech TechState)
{
	class'XComGameState_HeadquartersXCom'.static.UpgradeItems(NewGameState, TechState.GetMyTemplateName());
}

function bool AlwaysPriority()
{
	return true;
}

function bool AdventOfficerPriority()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.GetObjectiveStatus('T0_M6_WelcomeToLabsPt2') == eObjectiveState_InProgress)
	{
		return false;
	}

	return true;
}

function bool AlienBiotechPriority()
{
	local XComGameStateHistory History;
	local TDateTime StartDate;
	local int iMonth;
	local XComGameState_CampaignSettings SettingsState;

	History = `XCOMHISTORY;
	SettingsState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	if(SettingsState.bTutorialEnabled)
	{
		return true;
	}

	class'X2StrategyGameRulesetDataStructures'.static.SetTime(StartDate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
															  class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);

	iMonth = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInMonths(class'XComGameState_GeoscapeEntity'.static.GetCurrentTime(), StartDate);

	return (iMonth > 0);
}

function bool SkulljackPriority()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Item> InventoryItems;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Item InventoryItemState;
	local int iSoldier;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	// Skulljack is a priority when the objective to build it is active
	if (XComHQ.GetObjectiveStatus('T1_M2_S2_BuildSKULLJACK') == eObjectiveState_InProgress)
	{
		return true;
	}

	if (XComHQ.GetObjectiveStatus('T1_M2_S3_SKULLJACKCaptain') == eObjectiveState_InProgress ||
		XComHQ.GetObjectiveStatus('T1_M5_SKULLJACKCodex') == eObjectiveState_InProgress)
	{
		if (XComHQ.HasItemByName('SKULLJACK'))
		{
			return false;
		}

		Soldiers = XComHQ.GetSoldiers();
		for (iSoldier = 0; iSoldier < Soldiers.Length; iSoldier++)
		{
			InventoryItems = Soldiers[iSoldier].GetAllInventoryItems(, true);

			foreach InventoryItems(InventoryItemState)
			{
				if (InventoryItemState.GetMyTemplateName() == 'SKULLJACK')
				{
					return false;
				}
			}
		}
		
		return true; // If a Skulljack is not found, the project becomes a priority
	}
	
	return false; // If none of the Skulljack objectives are active, it is not a priority
}

function bool IsFacilityMissionAvailable()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Missions;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Missions = AlienHQ.GetValidFacilityDoomMissions(true);

	return (Missions.Length > 0);
}

function FacilityLeadCompleted(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Missions;
	local XComGameState_MissionSite FacilityMission;
	
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Missions = AlienHQ.GetValidFacilityDoomMissions(true);

	if (Missions.Length > 0)
	{
		FacilityMission = Missions[`SYNC_RAND(Missions.Length)];
		FacilityMission = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', FacilityMission.ObjectID));
		NewGameState.AddStateObject(FacilityMission);
		FacilityMission.bNotAtThreshold = false;

		TechState.RegionRef = FacilityMission.GetWorldRegion().GetReference();
	}
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

function int GetMinAdventDatapadIntel()
{
	return default.MinAdventDatapadIntel[`DifficultySetting];
}

function int GetMaxAdventDatapadIntel()
{
	return default.MaxAdventDatapadIntel[`DifficultySetting];
}

function int GetMinAlienDatapadIntel()
{
	return default.MinAlienDatapadIntel[`DifficultySetting];
}

function int GetMaxAlienDatapadIntel()
{
	return default.MaxAlienDatapadIntel[`DifficultySetting];
}