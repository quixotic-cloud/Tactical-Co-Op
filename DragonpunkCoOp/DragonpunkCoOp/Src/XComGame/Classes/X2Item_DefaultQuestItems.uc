class X2Item_DefaultQuestItems extends X2Item;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;

	// Flight Device Quest Item
	Items.AddItem(CreateQuestItemFlightDevice());

	// GENERIC QUEST ITEMS

	// Recover
	Items.AddItem(CreateQuestItemPatrolRoutes());
	Items.AddItem(CreateQuestItemPersonnelFiles());
	Items.AddItem(CreateQuestItemSecurityWatchlist());
	Items.AddItem(CreateQuestItemOperationsList());
	Items.AddItem(CreateQuestItemSecurityBriefing());
	Items.AddItem(CreateQuestItemAlienDeployments());
	Items.AddItem(CreateQuestItemBiometricMarkers());
	Items.AddItem(CreateQuestItemResourceAllotments());
	Items.AddItem(CreateQuestItemGeneticTestingResults());
	Items.AddItem(CreateQuestItemWeaponsSchematics());
	Items.AddItem(CreateQuestItemAnatomicalStudy());
	Items.AddItem(CreateQuestItemAutopsyResults());
	Items.AddItem(CreateQuestItemSurgicalExamination());
	Items.AddItem(CreateQuestItemCryogenicExperiments());
	Items.AddItem(CreateQuestItemPsionicEvaluation());
	Items.AddItem(CreateQuestItemGeologicalSurvey());
	Items.AddItem(CreateQuestItemReconFootage());
	Items.AddItem(CreateQuestItemRelayTranscripts());
	Items.AddItem(CreateQuestItemInterrogationReports());
	Items.AddItem(CreateQuestItemStructuralAnalysis());
	Items.AddItem(CreateQuestItemMissingPersonsReport());

	//Hack
	Items.AddItem(CreateQuestItemDecryptionAlgorithms());
	Items.AddItem(CreateQuestItemAccessCodes());
	Items.AddItem(CreateQuestItemCollaboratorDatabase());
	Items.AddItem(CreateQuestItemArchivalFootage());
	Items.AddItem(CreateQuestItemEquipmentAllocations());
	Items.AddItem(CreateQuestItemChipCensusData());
	Items.AddItem(CreateQuestItemTroopMovements());
	Items.AddItem(CreateQuestItemEncryptionKeys());
	Items.AddItem(CreateQuestItemSensorData());
	Items.AddItem(CreateQuestItemDissectionReport());
	Items.AddItem(CreateQuestItemThermalImagingScan());
	Items.AddItem(CreateQuestItemAlienGeneticProfiles());
	Items.AddItem(CreateQuestItemDiagnosticReports());
	Items.AddItem(CreateQuestItemExposureTestingData());
	Items.AddItem(CreateQuestItemAtmosphericAnalysis());
	Items.AddItem(CreateQuestItemPsychologicalProfiles());
	Items.AddItem(CreateQuestItemPsionicFlowReadings());
	Items.AddItem(CreateQuestItemCivilianPositioningData());
	Items.AddItem(CreateQuestItemEnergyUsageData());
	Items.AddItem(CreateQuestItemGeneticMarkerList());
	Items.AddItem(CreateQuestItemChipResponseMetrics());

	// DARK EVENT QUEST ITEMS

	// Protect Device
	Items.AddItem(CreateQuestItemRefugeeMigrationData());
	Items.AddItem(CreateQuestItemPsionicFlowMeasurements());
	Items.AddItem(CreateQuestItemPathogenGrowthData());
	Items.AddItem(CreateQuestItemGeneticSamplingDemographics());
	Items.AddItem(CreateQuestItemDNASynthesisReport());
	Items.AddItem(CreateQuestItemExposureTestingResults());
	Items.AddItem(CreateQuestItemPatientLongevityStudies());
	Items.AddItem(CreateQuestItemRemoteReconnaissanceFootage());
	Items.AddItem(CreateQuestItemADVENTSystemSchematics());
	Items.AddItem(CreateQuestItemADVENTLogisticsReport());

	// Recover
	Items.AddItem(CreateQuestItemGeneticSequencingData());
	Items.AddItem(CreateQuestItemTissueSampleAnalysis());
	Items.AddItem(CreateQuestItemRemnantDisposalReport());
	Items.AddItem(CreateQuestItemViralDiffusionSummary());
	Items.AddItem(CreateQuestItemImplantRejectionAnalysis());
	Items.AddItem(CreateQuestItemPsychologicalRestraintData());
	Items.AddItem(CreateQuestItemChemicalCompositionReport());
	Items.AddItem(CreateQuestItemTherapyDisseminationFiles());
	Items.AddItem(CreateQuestItemSamplingRateAnalysis());
	Items.AddItem(CreateQuestItemSerumToxicityReport());

	// Hack
	Items.AddItem(CreateQuestItemTacticalSequenceAnalysis());
	Items.AddItem(CreateQuestItemPsionicTrackingData());
	Items.AddItem(CreateQuestItemTissueRejectionAnalysis());
	Items.AddItem(CreateQuestItemGeneticFilteringResults());
	Items.AddItem(CreateQuestItemAutomationSystemsDesign());
	Items.AddItem(CreateQuestItemProcessingFacilitySchematic());
	Items.AddItem(CreateQuestItemImplantConnectivityAudit());
	Items.AddItem(CreateQuestItemWeaponSystemsData());
	Items.AddItem(CreateQuestItemPlasmaFilteringAnalysis());
	Items.AddItem(CreateQuestItemMechanicalProcessingDesigns());

	return Items;
}

// #######################################################################################
// -------------------- FLIGHT DEVICE ----------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateQuestItemFlightDevice()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'FlightDevice');
	Item.ItemCat = 'quest';
	Item.HideInLootRecovered = false;
	Item.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Flight_Device";

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");

	Item.RewardType.AddItem('Reward_None');

	return Item;
}

// #######################################################################################
// -------------------- GENERIC RECOVER --------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateQuestItemPatrolRoutes()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PatrolRoutes');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');

	return Item;
}

static function X2DataTemplate CreateQuestItemPersonnelFiles()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PersonnelFiles');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');

	return Item;
}

static function X2DataTemplate CreateQuestItemSecurityWatchlist()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'SecurityWatchlist');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');

	return Item;
}

static function X2DataTemplate CreateQuestItemOperationsList()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'OperationsList');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');

	return Item;
}

static function X2DataTemplate CreateQuestItemSecurityBriefing()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'SecurityBriefing');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');

	return Item;
}

static function X2DataTemplate CreateQuestItemAlienDeployments()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'AlienDeployments');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Soldier');

	return Item;
}

static function X2DataTemplate CreateQuestItemBiometricMarkers()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'BiometricMarkers');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');

	return Item;
}

static function X2DataTemplate CreateQuestItemResourceAllotments()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ResourceAllotments');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemGeneticTestingResults()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'GeneticTestingResults');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Soldier');

	return Item;
}

static function X2DataTemplate CreateQuestItemWeaponsSchematics()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'WeaponsSchematics');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemAnatomicalStudy()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'AnatomicalStudy');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");


	Item.RewardType.AddItem('Reward_Scientist');

	return Item;
}

static function X2DataTemplate CreateQuestItemAutopsyResults()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'AutopsyResults');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");


	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemSurgicalExamination()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'SurgicalExamination');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Scientist');

	return Item;
}

static function X2DataTemplate CreateQuestItemCryogenicExperiments()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'CryogenicExperiments');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");


	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemPsionicEvaluation()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PsionicEvaluation');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");


	Item.RewardType.AddItem('Reward_Scientist');

	return Item;
}

static function X2DataTemplate CreateQuestItemGeologicalSurvey()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'GeologicalSurvey');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemReconFootage()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ReconnaissanceFootage');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemRelayTranscripts()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'RelayTranscripts');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');

	return Item;
}

static function X2DataTemplate CreateQuestItemInterrogationReports()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'InterrogationReports');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemStructuralAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'StructuralAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

static function X2DataTemplate CreateQuestItemMissingPersonsReport()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'MissingPersonsReport');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");


	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	return Item;
}

// #######################################################################################
// -------------------- GENERIC HACK -----------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateQuestItemDecryptionAlgorithms()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'DecryptionAlgorithms');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");


	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemAccessCodes()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'AccessCodes');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemCollaboratorDatabase()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'CollaboratorDatabase');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemArchivalFootage()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ArchivalFootage');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemEquipmentAllocations()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'EquipmentAllocations');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemChipCensusData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ChipCensusData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemTroopMovements()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'TroopMovements');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Supplies');
	Item.RewardType.AddItem('Reward_Soldier');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemEncryptionKeys()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'EncryptionKeys');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemSensorData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'SensorData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemDissectionReport()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'DissectionReport');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemThermalImagingScan()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ThermalImagingScan');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemAlienGeneticProfiles()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'AlienGeneticProfiles');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemDiagnosticReports()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'DiagnosticReports');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemExposureTestingData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ExposureTestingData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemAtmosphericAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'AtmosphericAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPsychologicalProfiles()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PsychologicalProfiles');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Intel');
	Item.RewardType.AddItem('Reward_Scientist');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPsionicFlowReadings()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PsionicFlowReadings');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemCivilianPositioningData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'CivilianPositioningData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Soldier');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemEnergyUsageData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'EnergyUsageData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemGeneticMarkerList()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'GeneticMarkerList');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Scientist');

	Item.IsElectronicReward = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemChipResponseMetrics()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ChipResponseMetrics');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.MissionType.AddItem("ProtectDevice");

	Item.RewardType.AddItem('Reward_Scientist');
	Item.RewardType.AddItem('Reward_Engineer');

	Item.IsElectronicReward = true;

	return Item;
}

// #######################################################################################
// -------------------- DARK EVENT PROTECT -----------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateQuestItemRefugeeMigrationData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'RefugeeMigrationData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPsionicFlowMeasurements()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PsionicFlowMeasurements');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPathogenGrowthData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PathogenGrowthData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemGeneticSamplingDemographics()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'GeneticSamplingDemographics');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemDNASynthesisReport()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'DNASynthesisReport');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemExposureTestingResults()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ExposureTestingResults');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPatientLongevityStudies()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PatientLongevityStudies');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemRemoteReconnaissanceFootage()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'RemoteReconnaissanceFootage');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemADVENTSystemSchematics()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ADVENTSystemSchematics');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemADVENTLogisticsReport()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ADVENTLogisticsReport');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("ProtectDevice");
	Item.bDarkEventRelated = true;

	return Item;
}

// #######################################################################################
// -------------------- DARK EVENT RECOVER -----------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateQuestItemGeneticSequencingData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'GeneticSequencingData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemTissueSampleAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'TissueSampleAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemRemnantDisposalReport()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'RemnantDisposalReport');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemViralDiffusionSummary()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ViralDiffusionSummary');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemImplantRejectionAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ImplantRejectionAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPsychologicalRestraintData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PsychologicalRestraintData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemChemicalCompositionReport()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ChemicalCompositionReport');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemTherapyDisseminationFiles()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'TherapyDisseminationFiles');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemSamplingRateAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'SamplingRateAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemSerumToxicityReport()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'SerumToxicityReport');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Recover");
	Item.MissionType.AddItem("Recover_ADV");
	Item.MissionType.AddItem("Recover_Train");
	Item.MissionType.AddItem("Recover_Vehicle");
	Item.bDarkEventRelated = true;

	return Item;
}

// #######################################################################################
// -------------------- DARK EVENT HACK --------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateQuestItemTacticalSequenceAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'TacticalSequenceAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPsionicTrackingData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PsionicTrackingData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemTissueRejectionAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'TissueRejectionAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemGeneticFilteringResults()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'GeneticFilteringResults');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemAutomationSystemsDesign()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'AutomationSystemsDesign');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemProcessingFacilitySchematic()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ProcessingFacilitySchematic');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemImplantConnectivityAudit()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'ImplantConnectivityAudit');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemWeaponSystemsData()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'WeaponSystemsData');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemPlasmaFilteringAnalysis()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'PlasmaFilteringAnalysis');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}

static function X2DataTemplate CreateQuestItemMechanicalProcessingDesigns()
{
	local X2QuestItemTemplate Item;

	`CREATE_X2TEMPLATE(class'X2QuestItemTemplate', Item, 'MechanicalProcessingDesigns');
	Item.ItemCat = 'quest';

	Item.MissionType.AddItem("Hack");
	Item.MissionType.AddItem("Hack_ADV");
	Item.MissionType.AddItem("Hack_Train");
	Item.bDarkEventRelated = true;

	return Item;
}