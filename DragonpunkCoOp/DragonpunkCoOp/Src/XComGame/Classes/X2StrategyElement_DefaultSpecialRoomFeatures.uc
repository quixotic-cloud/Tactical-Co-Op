//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultSpecialRoomFeatures.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultSpecialRoomFeatures extends X2StrategyElement
	config(GameData);

var config int                          FacilityGridMinIndex;
var config int                          FacilityGridMaxIndex;

//---------------------------------------------------------------------------------------
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Features;

	Features.AddItem(CreatePowerCoilTemplate());
	Features.AddItem(CreateAlienMachineryTemplate());
	Features.AddItem(CreateAlienDebrisTemplate());
	Features.AddItem(CreateEmptyRoomTemplate());

	return Features;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePowerCoilTemplate()
{
	local X2SpecialRoomFeatureTemplate Template;
	local StrategyNames CarrierNames;

	`CREATE_X2TEMPLATE(class'X2SpecialRoomFeatureTemplate', Template, 'SpecialRoomFeature_PowerCoil');
	Template.UnclearedMapNames.AddItem("AVG_ER_PowerCoil_A");
	Template.UnclearedMapNames.AddItem("AVG_ER_PowerCoil02_A");
	Template.UnclearedMapNames.AddItem("AVG_ER_PowerCoil03_A");
	Template.ClearedMapNames.AddItem("AVG_ER_PowerCoilCap_A");
	Template.UnclearedLightingMapName_Pristine = "AVG_ER_PowerCoil_A_Pristine";
	Template.UnclearedLightingMapName_Damaged = "AVG_ER_PowerCoil_A_Damaged";
	Template.UnclearedLightingMapName_Disabled = "AVG_ER_PowerCoil_A_Disabled";
	Template.ClearedLightingMapName_Pristine = "AVG_ER_PowerCoilCap_A_Pristine";
	Template.ClearedLightingMapName_Damaged = "AVG_ER_PowerCoilCap_A_Damaged";
	Template.ClearedLightingMapName_Disabled = "AVG_ER_PowerCoilCap_A_Disabled";
	
	// Set up Easy, Normal, and Classic loot tables
	CarrierNames.Names.AddItem('PowerCoilLevel3');
	CarrierNames.Names.AddItem('PowerCoilLevel4');	
	Template.LootCarrierNames.AddItem(CarrierNames); // Easy
	Template.LootCarrierNames.AddItem(CarrierNames); // Normal
	Template.LootCarrierNames.AddItem(CarrierNames); // Classic

	// Set up Expert loot tables
	CarrierNames.Names.Length = 0;
	CarrierNames.Names.AddItem('PowerCoilLevel3_Expert');
	CarrierNames.Names.AddItem('PowerCoilLevel4_Expert');
	Template.LootCarrierNames.AddItem(CarrierNames); // Expert

	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_ExposedPowerCoil";
	
	Template.PointsToComplete = 1200;
	Template.CostIncreasePerDepth = 50;
	Template.LowestRowAllowed = 3;
	Template.MinTotalAllowed = 2;
	Template.MaxTotalAllowed = 2;

	Template.ExclusiveRoomIndices.AddItem(9);
	Template.ExclusiveRoomIndices.AddItem(11);
	Template.ExclusiveRoomIndices.AddItem(13);

	Template.bHasLoot = true;
	Template.bBlocksConstruction = true;
	Template.bAddsBuildSlot = true;
	Template.StartProjectAkEvent = "ConfirmWork_ShieldPowerCore";
	Template.RoomAmbientAkEvent = "Play_AvengerAmbience_ExposedCoil";
	Template.GetDepthBasedLootTableNameFn = GetDepthBasedLootTableName;
	Template.GetDepthBasedNumBuildSlotsFn = GetDepthBasedNumBuildSlots;
	Template.OnClearFn = OnShieldPowerCoil;
	
	return Template;
}

//---------------------------------------------------------------------------------------
static function OnShieldPowerCoil(XComGameState NewGameState, XComGameState_HeadquartersRoom RoomState)
{
	RoomState.ConstructionBlocked = false;
	RoomState.bHasShieldedPowerCoil = true;

	GiveRecoveredLoot(NewGameState, RoomState);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAlienMachineryTemplate()
{
	local X2SpecialRoomFeatureTemplate Template;
	local StrategyNames CarrierNames;

	`CREATE_X2TEMPLATE(class'X2SpecialRoomFeatureTemplate', Template, 'SpecialRoomFeature_AlienMachinery');
	Template.UnclearedMapNames.AddItem("AVG_ER_AlienMachinery_A");
	Template.UnclearedMapNames.AddItem("AVG_ER_AlienMachinery02_A");
	Template.UnclearedMapNames.AddItem("AVG_ER_AlienMachinery03_A");
	Template.UnclearedLightingMapName_Pristine = "AVG_ER_AlienMachinery_A_Pristine";
	Template.UnclearedLightingMapName_Damaged = "AVG_ER_AlienMachinery_A_Damaged";
	Template.UnclearedLightingMapName_Disabled = "AVG_ER_AlienMachinery_A_Disabled";
	
	// Set up Easy, Normal, and Classic loot tables
	CarrierNames.Names.AddItem('AlienMachineryLevel2');
	CarrierNames.Names.AddItem('AlienMachineryLevel3');
	CarrierNames.Names.AddItem('AlienMachineryLevel4');
	Template.LootCarrierNames.AddItem(CarrierNames); // Easy
	Template.LootCarrierNames.AddItem(CarrierNames); // Normal
	Template.LootCarrierNames.AddItem(CarrierNames); // Classic

	// Set up Expert loot tables
	CarrierNames.Names.Length = 0;
	CarrierNames.Names.AddItem('AlienMachineryLevel2_Expert');
	CarrierNames.Names.AddItem('AlienMachineryLevel3_Expert');
	CarrierNames.Names.AddItem('AlienMachineryLevel4_Expert');
	Template.LootCarrierNames.AddItem(CarrierNames); // Expert
	
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_AlienMachinery";

	Template.PointsToComplete = 1200;
	Template.LowestRowAllowed = 2;
	Template.CostIncreasePerDepth = 25;
	Template.bRemoveOnClear = true;
	Template.bHasLoot = true;
	Template.bBlocksConstruction = true;
	Template.bAddsBuildSlot = true;
	Template.bFillAvenger = true;
	Template.StartProjectAkEvent = "ConfirmWork_ClearRoom";
	Template.RoomAmbientAkEvent = "Play_AvengerAmbience_AlienMachinery";
	Template.GetDepthBasedLootTableNameFn = GetDepthBasedLootTableName;
	Template.GetDepthBasedNumBuildSlotsFn = GetDepthBasedNumBuildSlots;
	Template.OnClearFn = OnClearAlienRemains;
	
	return Template;
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAlienDebrisTemplate()
{
	local X2SpecialRoomFeatureTemplate Template;
	local StrategyNames CarrierNames;

	`CREATE_X2TEMPLATE(class'X2SpecialRoomFeatureTemplate', Template, 'SpecialRoomFeature_AlienDebris');
	Template.UnclearedMapNames.AddItem("AVG_ER_AlienDebris_A");
	Template.UnclearedMapNames.AddItem("AVG_ER_AlienDebris02_A");
	Template.UnclearedMapNames.AddItem("AVG_ER_AlienDebris03_A");
	Template.UnclearedLightingMapName_Pristine = "AVG_ER_AlienDebris_A_Pristine";
	Template.UnclearedLightingMapName_Damaged = "AVG_ER_AlienDebris_A_Damaged";
	Template.UnclearedLightingMapName_Disabled = "AVG_ER_AlienDebris_A_Disabled";
	
	// Set up Easy, Normal, and Classic loot tables
	CarrierNames.Names.AddItem('AlienDebrisLevel1');
	CarrierNames.Names.AddItem('AlienDebrisLevel2');
	CarrierNames.Names.AddItem('AlienDebrisLevel3');
	CarrierNames.Names.AddItem('AlienDebrisLevel4');
	Template.LootCarrierNames.AddItem(CarrierNames); // Easy
	Template.LootCarrierNames.AddItem(CarrierNames); // Normal
	Template.LootCarrierNames.AddItem(CarrierNames); // Classic

	// Set up Expert loot tables
	CarrierNames.Names.Length = 0;
	CarrierNames.Names.AddItem('AlienDebrisLevel1_Expert');
	CarrierNames.Names.AddItem('AlienDebrisLevel2_Expert');
	CarrierNames.Names.AddItem('AlienDebrisLevel3_Expert');
	CarrierNames.Names.AddItem('AlienDebrisLevel4_Expert');
	Template.LootCarrierNames.AddItem(CarrierNames); // Expert
	
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_AlienDebris";

	Template.PointsToComplete = 1200;
	Template.CostIncreasePerDepth = 25;
	Template.bRemoveOnClear = true;
	Template.bHasLoot = true;
	Template.bBlocksConstruction = true;
	Template.bFillAvenger = true;
	Template.StartProjectAkEvent = "ConfirmWork_ClearRoom";
	Template.RoomAmbientAkEvent = "Play_AvengerAmbience_AlienDebris";
	Template.GetDepthBasedLootTableNameFn = GetDepthBasedLootTableName;
	Template.GetDepthBasedNumBuildSlotsFn = GetDepthBasedNumBuildSlots;
	Template.OnClearFn = OnClearAlienRemains;
	
	return Template;
}

//---------------------------------------------------------------------------------------
static function OnClearAlienRemains(XComGameState NewGameState, XComGameState_HeadquartersRoom RoomState)
{
	RoomState.ConstructionBlocked = false;

	GiveRecoveredLoot(NewGameState, RoomState);
}

//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateEmptyRoomTemplate()
{
	local X2SpecialRoomFeatureTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SpecialRoomFeatureTemplate', Template, 'SpecialRoomFeature_EmptyRoom');
	Template.LowestRowAllowed = 1;
	Template.HighestRowAllowed = 1;
	Template.MinTotalAllowed = 1;
	Template.MaxTotalAllowed = 1;
	Template.bBlocksConstruction = false;

	return Template;
}

//////////////////////////////////////////////////////////////////////////////////////////
//------------------------HELPER FUNCTIONS & DELEGATES----------------------------------//
//////////////////////////////////////////////////////////////////////////////////////////

//---------------------------------------------------------------------------------------
static function GiveRecoveredLoot(XComGameState NewGameState, XComGameState_HeadquartersRoom RoomState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Item ItemState;
	local name LootName;
	local int idx;
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(RoomState.Loot.LootToBeCreated.Length > 0)
	{
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

		// First give each piece of loot to XComHQ so it can be collected
		// It will be actually added to the inventory after the HeadquartersOrder finishes processing, in HeadquartersProjectClearRoom
		foreach RoomState.Loot.LootToBeCreated(LootName)
		{
			ItemTemplate = ItemTemplateManager.FindItemTemplate(LootName);
			ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
			NewGameState.AddStateObject(ItemState);
			XComHQ.PutItemInInventory(NewGameState, ItemState, true);
		}

		RoomState.Loot.LootToBeCreated.Length = 0;

		// Then create the loot string for the room
		for (idx = 0; idx < XComHQ.LootRecovered.Length; idx++)
		{
			ItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(XComHQ.LootRecovered[idx].ObjectID));

			if (ItemState != none)
			{
				if( RoomState.strLootGiven != "" )
				{
					RoomState.strLootGiven $= ", ";
				}

				RoomState.strLootGiven $= ItemState.GetMyTemplate().GetItemFriendlyName() $ " x" $ ItemState.Quantity;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
static function name GetDepthBasedLootTableName(XComGameState_HeadquartersRoom RoomState)
{
	local X2SpecialRoomFeatureTemplate SpecialRoomFeature;
	local int RowNum, RowOffset;

	SpecialRoomFeature = RoomState.GetSpecialFeature();	
	RowNum = RoomState.GridRow;

	// If the lowest row allowed is set, calculate the appropriate offset
	if (SpecialRoomFeature.LowestRowAllowed > 0)
		RowOffset = SpecialRoomFeature.LowestRowAllowed - 1;

	return SpecialRoomFeature.LootCarrierNames[`DIFFICULTYSETTING].Names[RowNum - RowOffset]; // The index gives the loot table for the level which the feature is placed at
}

//---------------------------------------------------------------------------------------
static function StrategyCost GetDepthBasedCost(XComGameState_HeadquartersRoom RoomState)
{
	local X2SpecialRoomFeatureTemplate SpecialRoomFeature;
	local StrategyCost Cost, NewCost;
	local ArtifactCost NewResourceCost;
	local int idx, RowNum, RowOffset, CostMultiplier;

	SpecialRoomFeature = RoomState.GetSpecialFeature();
	Cost = SpecialRoomFeature.Cost;	
	RowNum = RoomState.GridRow;

	// If the lowest row allowed is set, calculate the appropriate offset
	if (SpecialRoomFeature.LowestRowAllowed > 0)
		RowOffset = SpecialRoomFeature.LowestRowAllowed - 1;
			
	CostMultiplier = RowNum - RowOffset; // The multiplier is the number of rows above the first one where the special feature can appear
			
	// Iterate through each resource cost and add the specified cost per depth
	// Assuming that each feature only requires supplies (a resource) to clear
	for (idx = 0; idx < Cost.ResourceCosts.Length; idx++)
	{
		NewResourceCost.ItemTemplateName = Cost.ResourceCosts[idx].ItemTemplateName;
		NewResourceCost.Quantity = Cost.ResourceCosts[idx].Quantity + CostMultiplier * SpecialRoomFeature.CostIncreasePerDepth;
		NewCost.ResourceCosts.AddItem(NewResourceCost);
	}

	return NewCost;
}

//---------------------------------------------------------------------------------------
static function int GetDepthBasedNumBuildSlots(XComGameState_HeadquartersRoom RoomState)
{
	local X2SpecialRoomFeatureTemplate SpecialRoomFeature;
	local int RowNum, NumBuildSlots;

	SpecialRoomFeature = RoomState.GetSpecialFeature();
	RowNum = RoomState.GridRow;
			
	if (RowNum % 2 == 0)
	{
		NumBuildSlots = RowNum / 2; // Rows 0 and 1 will add 0, Rows 2 and 3 will add 1, etc
	}
	else
	{
		NumBuildSlots = (RowNum - 1) / 2;
	}

	if (SpecialRoomFeature.bAddsBuildSlot)
		NumBuildSlots++;

	return NumBuildSlots;
}