//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultFacilityUpgrades.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultFacilityUpgrades extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Upgrades;

	// Workshop
	Upgrades.AddItem(CreateWorkshop_AdditionalWorkbenchTemplate());

	// Lab
	Upgrades.AddItem(CreateLaboratory_AdditionalResearchStationTemplate());

	// Power Relay
	Upgrades.AddItem(CreatePowerRelay_PowerConduitTemplate());
	Upgrades.AddItem(CreatePowerRelay_EleriumConduitTemplate());
	
	// Resistance Comms
	Upgrades.AddItem(CreateResistanceComms_AdditionalCommStation());

	// UFO Defense
	Upgrades.AddItem(CreateDefenseFacility_QuadTurrets());

	// Shadow Chamber
	Upgrades.AddItem(CreateShadowChamber_Destroyed());
	Upgrades.AddItem(CreateShadowChamber_CelestialGate());

	// Psi Chamber
	Upgrades.AddItem(CreatePsiChamber_SecondCell());
	
	return Upgrades;
}

//---------------------------------------------------------------------------------------
// WORKSHOP UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateWorkshop_AdditionalWorkbenchTemplate()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'Workshop_AdditionalWorkbench');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_Workshop_AdditionalWorkbench";
	Template.OnUpgradeAddedFn = Workshop_AdditionalWorkbenchOnUpgradeAdded;

	// Stats
	Template.iPower = -2;
	Template.UpkeepCost = 40;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 100;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function Workshop_AdditionalWorkbenchOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
	Facility.UnlockStaffSlot(NewGameState);
}

//---------------------------------------------------------------------------------------
// LABORATORY UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateLaboratory_AdditionalResearchStationTemplate()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'Laboratory_AdditionalResearchStation');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_Laboratory_AdditionalResearchStation";
	Template.OnUpgradeAddedFn = Laboratory_AdditionalResearchStationOnUpgradeAdded;

	// Stats
	Template.iPower = -3;
	Template.UpkeepCost = 40;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 125;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function Laboratory_AdditionalResearchStationOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
	Facility.UnlockStaffSlot(NewGameState);
}

//---------------------------------------------------------------------------------------
// POWER RELAY UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePowerRelay_PowerConduitTemplate()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'PowerRelay_PowerConduit');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PowerConduitUpgrade";
	Template.OnUpgradeAddedFn = PowerRelay_PowerConduitOnUpgradeAdded;

	// Stats
	Template.iPower = 2;
	Template.UpkeepCost = 10;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 80;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function PowerRelay_PowerConduitOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
	Facility.UnlockStaffSlot(NewGameState);
}

static function X2DataTemplate CreatePowerRelay_EleriumConduitTemplate()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'PowerRelay_EleriumConduit');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_EleriumConduitUpgrade";
	Template.OnUpgradeAddedFn = PowerRelay_EleriumConduitOnUpgradeAdded;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Tech_Elerium');

	// Stats
	Template.iPower = 6;
	Template.UpkeepCost = 20;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 150;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 20;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function PowerRelay_EleriumConduitOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
}

//---------------------------------------------------------------------------------------
// RESISTANCE COMMS UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateResistanceComms_AdditionalCommStation()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'ResistanceComms_AdditionalCommStation');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.iPower = -4;
	Template.UpgradeValue = 1;
	Template.UpkeepCost = 35;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_ResistanceComms_AdditionalCommStation";
	Template.OnUpgradeAddedFn = ResistanceComms_AdditionalCommStationOnUpgradeAdded;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('ResistanceRadio');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 125;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function ResistanceComms_AdditionalCommStationOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
	Facility.CommCapacity += Upgrade.GetMyTemplate().UpgradeValue;
	Facility.UnlockStaffSlot(NewGameState);
}

//---------------------------------------------------------------------------------------
// UFO DEFENSE UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateDefenseFacility_QuadTurrets()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'DefenseFacility_QuadTurrets');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.iPower = -2;
	Template.UpkeepCost = 10;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_UFODefense_QuadTurret";
	Template.OnUpgradeAddedFn = DefenseFacility_QuadTurretsOnUpgradeAdded;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function DefenseFacility_QuadTurretsOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	if (Facility.HasFilledEngineerSlot())
		XComHQ.TacticalGameplayTags.AddItem('AvengerDefenseTurretsMk2_Upgrade');
	else
		XComHQ.TacticalGameplayTags.AddItem('AvengerDefenseTurrets_Upgrade');

	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
}

//---------------------------------------------------------------------------------------
// SHADOW CHAMBER UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateShadowChamber_Destroyed()
{
	local X2FacilityUpgradeTemplate Template;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'ShadowChamber_Destroyed');
	Template.PreviousMapName = "Pre_ShadowChamber_CelestialGate";
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.iPower = 0;
	Template.UpkeepCost = 0;
	Template.bHidden = true;

	return Template;
}

static function X2DataTemplate CreateShadowChamber_CelestialGate()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'ShadowChamber_CelestialGate');
	Template.PreviousMapName = "ShadowChamber_Destroyed";
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.iPower = -4;
	Template.UpkeepCost = 50;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_ShadowChamber_PsionicGate";
	Template.bPriority = true;
	Template.OnUpgradeAddedFn = ShadowChamber_CelestialGateOnUpgradeAdded;

	// Requirements
	Template.Requirements.RequiredItems.AddItem('PsiGateArtifact');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 200;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function ShadowChamber_CelestialGateOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
}

//---------------------------------------------------------------------------------------
// PSI CHAMBER UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePsiChamber_SecondCell()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'PsiChamber_SecondCell');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.iPower = -5;
	Template.UpkeepCost = 50;
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab_SecondCell";
	Template.OnUpgradeAddedFn = PsiChamber_SecondCellOnUpgradeAdded;
	
	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 225;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 15;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}
static function PsiChamber_SecondCellOnUpgradeAdded(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	Facility.PowerOutput += Upgrade.GetMyTemplate().iPower;
	Facility.UpkeepCost += Upgrade.GetMyTemplate().UpkeepCost;
	Facility.UnlockStaffSlot(NewGameState);
}