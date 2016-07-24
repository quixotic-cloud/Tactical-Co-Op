//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultFacilities.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultFacilities extends X2StrategyElement config(GameData);

var config array<name> BridgeCinematicObjectives;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Facilities;

	// Core Facilities
	Facilities.AddItem(CreateCommandersQuartersTemplate());
	Facilities.AddItem(CreateBridgeTemplate());
	Facilities.AddItem(CreatePowerCoreTemplate());
	Facilities.AddItem(CreateHangarTemplate());
	Facilities.AddItem(CreateLivingQuartersTemplate());
	Facilities.AddItem(CreateBarMemorialTemplate());
	Facilities.AddItem(CreateStorageTemplate());

	// Additional Facilities
	Facilities.AddItem(CreateLaboratoryTemplate());
	Facilities.AddItem(CreateWorkshopTemplate());
	Facilities.AddItem(CreateProvingGroundTemplate());
	Facilities.AddItem(CreatePowerRelayTemplate());
	Facilities.AddItem(CreateAdvancedWarfareCenterTemplate());
	Facilities.AddItem(CreateShadowChamberTemplate());
	Facilities.AddItem(CreateOfficerTrainingSchoolTemplate());
	Facilities.AddItem(CreateUFODefenseTemplate());
	Facilities.AddItem(CreateResistanceCommsTemplate());
	Facilities.AddItem(CreatePsiChamberTemplate());	

	return Facilities;
}

//---------------------------------------------------------------------------------------
// Helper function for calculating project time
static function int GetFacilityBuildDays(int iNumDays)
{
	return (iNumDays * class'XComGameState_HeadquartersXCom'.default.XComHeadquarters_DefaultConstructionWorkPerHour * 24);
}

// #######################################################################################
// -------------------- CORE FACILITIES --------------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
// COMMANDERS QUARTERS
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateCommandersQuartersTemplate()
{
	local X2FacilityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'CommandersQuarters');
	Template.iPower = -1;
	Template.bIsCoreFacility = true;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = true; 
	Template.MapName = "AVG_QuartersCommander_A";
	Template.AnimMapName = "";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin";
	Template.ForcedMapIndex = 0;
	Template.NeedsAttentionNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Incoming_Transmission";
	Template.SelectFacilityFn = SelectFacility;
	Template.UIFacilityGridID = 'CommanderHighlight';

	Template.UIFacilityClass = class'UIFacility_CIC';
	Template.FacilityEnteredAkEvent = "Play_AvengerCommanderQuarters_Unoccupied";

	Template.BaseMinFillerCrew = 0;	
	Template.MaxFillerCrew = 0;

	return Template;
}

//---------------------------------------------------------------------------------------
// BRIDGE
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateBridgeTemplate()
{
	local X2FacilityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'CIC');
	Template.iPower = -1;
	Template.bIsCoreFacility = true;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = true;
	Template.MapName = "AVG_CIC_A";
	Template.AnimMapName = "AVG_CIC_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin";
	Template.ForcedMapIndex = 15;
	Template.NeedsAttentionNarrative = "X2NarrativeMoments.Strategy.Avenger_Commander_Bridge";
	Template.SelectFacilityFn = SelectFacilityBridge;
	Template.UIFacilityGridID = 'CICHighlight';
	
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');
	Template.FillerSlots.AddItem('Crew');

	Template.UIFacilityClass = None;
	Template.FacilityEnteredAkEvent = "Play_AvengerBridgeCIC_Unoccupied";

	Template.BaseMinFillerCrew = 2;
	Template.MaxFillerCrew = 17;

	return Template;
}

static function SelectFacilityBridge(StateObjectReference FacilityRef, optional bool bForceInstant = false)
{
	local XComHQPresentationLayer HQPres;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Objective CinematicObjectiveState;
	local bool bDontEnterStrategyMap;
	local name ObjectiveName;

	SelectFacility(FacilityRef);
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// When the broadcast objective is active,we don't want to jump into the Geoscape because a cinematic and popup need to trigger
	// PendingNarrativeTriggers will have length > 0 if the Broadcast event was just triggered when SelectFacility was called.
	foreach default.BridgeCinematicObjectives(ObjectiveName)
	{		
		CinematicObjectiveState = XComHQ.GetObjective(ObjectiveName);
		if (CinematicObjectiveState.GetStateOfObjective() == eObjectiveState_InProgress && CinematicObjectiveState.PendingNarrativeTriggers.Length > 0)
		{
			bDontEnterStrategyMap = true;
			break;
		}		
	}
	HQPres = `HQPRES;

	if( XComHQ.GetObjectiveStatus('T0_M3_WelcomeToHQ') == eObjectiveState_InProgress )
	{
		//Find the CIC facility and start the camera transitioning to the starting point and fade to blakck for the bink
		HQPres.CameraTransitionToCIC();
	}
	else if(!bDontEnterStrategyMap)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("AntFarm_Camera_Zoom_In");


		HQPres.ClearToFacilityMainMenu();
		HQPres.m_kFacilityGrid.Hide(); //Specific visual request to hide instantly on the selection, and not wait for the UI screen stack change. 
		HQPres.UIEnterStrategyMap(true);
	}
}

//---------------------------------------------------------------------------------------
// POWER CORE
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePowerCoreTemplate()
{
	local X2FacilityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'PowerCore');
	Template.iPower = 12;
	Template.bIsCoreFacility = true;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = true;
	Template.MapName = "AVG_PowerCore_A";
	Template.AnimMapName = "AVG_PowerCore_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin";
	Template.ForcedMapIndex = 1;
	Template.NeedsAttentionNarrative = "X2NarrativeMoments.Strategy.Avenger_Commander_ResearchLabs";
	Template.SelectFacilityFn = SelectFacility;
	Template.OnLeaveFacilityInterruptFn = InterruptCheckpowerCore;
	Template.IsFacilityProjectActiveFn = IsResearchProjectActive;
	Template.GetQueueMessageFn = GetResearchQueueMessage;
	Template.NeedsAttentionFn = PowerCoreNeedsAttention;
	Template.UIFacilityGridID = 'PowerCoreHighlight';
	
	Template.UIFacilityClass = class'UIFacility_Powercore';
	Template.FacilityEnteredAkEvent = "Play_AvengerPowerCore";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 0;

	return Template;
}

function bool PowerCoreNeedsAttention(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return (!XComHQ.HasResearchProject() && XComHQ.HasTechsAvailableForResearch() && !XComHQ.HasActiveShadowProject());
}

function InterruptCheckpowerCore(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(FacilityState.LeaveFacilityInterruptCallback != none)
	{
		if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M1_WelcomeToLabs') && 
		   (!XComHQ.HasResearchProject() && !XComHQ.HasActiveShadowProject() && XComHQ.HasTechsAvailableForResearchWithRequirementsMet()) &&
		   `HQPRES.ScreenStack.HasInstanceOf(class'UIFacility_PowerCore'))
		{
			LeavePowerCoreWithoutResearchPopup();
		}
		else
		{
			FacilityState.LeaveFacilityInterruptCallback(true);
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear facility interrupt delegate");
			FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));
			NewGameState.AddStateObject(FacilityState);
			FacilityState.LeaveFacilityInterruptCallback = none;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

simulated function LeavePowerCoreWithoutResearchPopup()
{
	local TDialogueBoxData kData;

	kData.strTitle = class'UIFacility_PowerCore'.default.m_strLabsExitWithoutProjectTitle;
	kData.strText = class'UIFacility_PowerCore'.default.m_strLabsExitWithoutProjectBody;
	kData.strAccept = class'UIFacility_PowerCore'.default.m_strLabsExitWithoutProjectStay;
	kData.strCancel = class'UIFacility_PowerCore'.default.m_strLabsExitWithoutProjectLeave;
	kData.eType = eDialog_Warning;
	kData.fnCallback = OnLeavePowerCoreWithoutResearchPopupCallback;

	`HQPRES.UIRaiseDialog(kData);
}

simulated function OnLeavePowerCoreWithoutResearchPopupCallback(eUIAction eAction)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if(FacilityState.GetMyTemplateName() == 'PowerCore')
		{
			break;
		}
	}

	if(eAction == eUIAction_Accept)
	{
		FacilityState.LeaveFacilityInterruptCallback(false);
		`HQPRES.UIChooseResearch();
		
	}
	else
	{
		FacilityState.LeaveFacilityInterruptCallback(true);
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear facility interrupt delegate");
	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
	NewGameState.AddStateObject(FacilityState);
	FacilityState.LeaveFacilityInterruptCallback = none;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function bool IsResearchProjectActive(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return XComHQ.HasResearchProject();
}

function string GetResearchQueueMessage(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local string strStatus, description, time;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	if (!XComHQ.HasResearchProject())
	{
		strStatus = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strNoActiveResearch, eUIState_Bad);
	}
	else
	{
		// get data
		description = XComHQ.GetCurrentResearchTech().GetDisplayName();

		if (XComHQ.GetCurrentResearchProject().GetCurrentNumHoursRemaining() < 0)
			time = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
		else
			time = class'UIUtilities_Text'.static.GetTimeRemainingString(XComHQ.GetCurrentResearchProject().GetCurrentNumHoursRemaining());

		strStatus = description $":" @ time;
	}

	return strStatus;
}

//---------------------------------------------------------------------------------------
// HANGAR
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateHangarTemplate()
{
	local X2FacilityTemplate Template;
	local AuxMapInfo MapInfo;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'Hangar');
	Template.iPower = -1;
	Template.bIsCoreFacility = true;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = true;
	Template.MapName = "AVG_Armory_A";
	Template.AnimMapName = "AVG_Armory_A_Anim";
	
	MapInfo.MapName = "CIN_SoldierIntros";
	MapInfo.InitiallyVisible = true;
	Template.AuxMaps.AddItem(MapInfo);

	MapInfo.MapName = "AVG_Armory_CAP";
	MapInfo.InitiallyVisible = false;
	Template.AuxMaps.AddItem(MapInfo);

	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin";
	Template.ForcedMapIndex = 2;
	Template.NeedsAttentionNarrative = "X2NarrativeMoments.Strategy.Avenger_Commander_Armory";
	Template.SelectFacilityFn = SelectFacility;
	Template.GetQueueMessageFn = GetHangarQueueMessage;
	Template.NeedsAttentionFn = ArmoryNeedsAttention;
	Template.UIFacilityGridID = 'ArmoryHighlight';
	
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Any');
	Template.FillerSlots.AddItem('Any');
	Template.FillerSlots.AddItem('Any');
	Template.FillerSlots.AddItem('Any');
	Template.FillerSlots.AddItem('Any');
	Template.FillerSlots.AddItem('Any');
	

	Template.UIFacilityClass = class'UIFacility_Armory';
	Template.FacilityEnteredAkEvent = "Play_AvengerArmory_Unoccupied";

	Template.BaseMinFillerCrew = 2;
	Template.MaxFillerCrew = 6;

	return Template;
}

function bool ArmoryNeedsAttention(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return ((XComHQ.bModularWeapons && XComHQ.HasWeaponUpgradesInInventory() && !XComHQ.bHasSeenWeaponUpgradesPopup) || XComHQ.NeedSoldierShakenPopup() || XComHQ.HasSoldiersToPromote());
}

function string GetHangarQueueMessage(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local string strStatus;
	local int iAvailable, iWounded;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	iAvailable = XComHQ.GetNumberOfDeployableSoldiers();
	iWounded = XComHQ.GetNumberOfInjuredSoldiers();

	strStatus $= class'XLocalizedData'.default.FacilityGridEngineering_SoldiersLabel @ class'UIUtilities_Text'.static.GetColoredText(class'XLocalizedData'.default.FacilityGridEngineering_AvailableLabel @ iAvailable $ ", ", eUIState_Good);
	strStatus $= class'UIUtilities_Text'.static.GetColoredText(class'XLocalizedData'.default.FacilityGridEngineering_WoundedLabel @ iWounded $", ", eUIState_Bad);
	strStatus $= class'XLocalizedData'.default.FacilityGridEngineering_UnvailableLabel @(XComHQ.GetNumberOfSoldiers() - iAvailable - iWounded);
	
	return strStatus;
}

//---------------------------------------------------------------------------------------
// LIVING QUARTERS
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateLivingQuartersTemplate()
{
	local X2FacilityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'LivingQuarters');
	Template.iPower = -1;
	Template.bIsCoreFacility = true;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_LivingQuarters_A";
	Template.AnimMapName = "AVG_LivingQuarters_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin";
	Template.ForcedMapIndex = 16;
	Template.NeedsAttentionNarrative = "X2NarrativeMoments.Strategy.Avenger_Commander_CrewQuarters";
	Template.SelectFacilityFn = SelectFacility;
	
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');

	Template.UIFacilityClass = class'UIFacility_LivingQuarters';
	Template.FacilityEnteredAkEvent = "Play_AvengerLivingQuarters_Unoccupied";

	Template.BaseMinFillerCrew = 2;
	Template.MaxFillerCrew = 15;

	return Template;
}

private static function OnPersonnelSelected(StateObjectReference selectedUnitRef)
{
	`HQPRES.UIArmory_MainMenu(selectedUnitRef);
}

//---------------------------------------------------------------------------------------
// BAR MEMORIAL
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateBarMemorialTemplate()
{
	local X2FacilityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate_Memorial', Template, 'BarMemorial');
	Template.iPower = -1;
	Template.bIsCoreFacility = true;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = true;
	Template.MapName = "AVG_Memorial_A";
	Template.AnimMapName = "AVG_Memorial_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin";
	Template.ForcedMapIndex = 18;
	Template.SelectFacilityFn = SelectFacility;

	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	
	Template.BaseMinFillerCrew = 2;
	Template.MaxFillerCrew = 17;

	Template.UIFacilityClass = class'UIFacility_BarMemorial';
	Template.FacilityEnteredAkEvent = "Play_AvengerMemorial_Unoccupied";

	return Template;
}

//---------------------------------------------------------------------------------------
// STORAGE
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateStorageTemplate()
{
	local X2FacilityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'Storage');
	Template.iPower = -1;
	Template.bIsCoreFacility = true;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = true;
	Template.MapName = "AVG_Storage_A";
	Template.AnimMapName = "AVG_Storage_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin";
	Template.ForcedMapIndex = 17;
	Template.NeedsAttentionNarrative = "X2NarrativeMoments.Strategy.Avenger_Commander_Engineering";
	Template.UIFacilityGridID = 'EngineeringHighlight';
	Template.SelectFacilityFn = SelectFacility;
	//Template.OnLeaveFacilityInterruptFn = InterruptCheckStorage;	

	Template.UIFacilityClass = class'UIFacility_Storage';
	Template.FacilityEnteredAkEvent = "Play_AvengerEngineering_Unoccupied";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 0;

	return Template;
}

// #######################################################################################
// -------------------- ADDITIONAL FACILITIES --------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
// LABORATORY
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateLaboratoryTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'Laboratory');
	
	Template.ScienceBonus = 0;
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_Laboratory_A";
	Template.AnimMapName = "AVG_Laboratory_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_Laboratory";
	Template.StaffSlots.AddItem('LaboratoryStaffSlot');
	Template.StaffSlots.AddItem('LaboratoryStaffSlot');
	Template.StaffSlotsLocked = 1;
	Template.CalculateStaffingRequirementFn = CalculateLabStaffingRequirement;
	Template.OnFacilityBuiltFn = OnLaboratoryBuilt;
	Template.OnFacilityRemovedFn = OnLaboratoryRemoved;
	Template.SelectFacilityFn = SelectFacility;
	Template.IsFacilityProjectActiveFn = IsResearchProjectActive;
	Template.Upgrades.AddItem('Laboratory_AdditionalResearchStation');
	Template.FillerSlots.AddItem('Scientist');
	Template.FillerSlots.AddItem('Scientist');

	Template.MatineeSlotsForUpgrades.AddItem('ScientistSlot4');
	Template.MatineeSlotsForUpgrades.AddItem('ScientistSlot8');
	Template.MatineeSlotsForUpgrades.AddItem('ScientistSlot9');

	Template.UIFacilityClass = class'UIFacility_Labs';
	Template.FacilityEnteredAkEvent = "Play_AvengerLaboratory_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_Lab_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Strategy.Avenger_Lab_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Labratory_Construction";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 4;

	// Requirements

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(20);
	Template.iPower = -3;
	Template.UpkeepCost = 35;
	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 125;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function CalculateLabStaffingRequirement(X2FacilityTemplate Template, out int RequiredScience, out int RequiredEngineering)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	RequiredScience = (Template.Requirements.RequiredScienceScore * ((XComHQ.GetNumberOfFacilitiesOfType(Template)+XComHQ.GetNumberBuildingOfFacilitiesOfType(Template)) + 1));
	RequiredEngineering = Template.Requirements.RequiredEngineeringScore;
}

static function OnLaboratoryBuilt(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	if (XComHQ.bLabBonus)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Laboratory Built");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.ResearchEffectivenessPercentIncrease += class'X2StrategyElement_DefaultContinentBonuses'.default.PursuitOfKnowledgeBonus[`DIFFICULTYSETTING];
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

static function OnLaboratoryRemoved(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Laboratory Removed");

	RemoveFacility(NewGameState, FacilityRef, NewXComHQ);

	if (NewXComHQ.bLabBonus)
	{
		NewXComHQ.ResearchEffectivenessPercentIncrease -= class'X2StrategyElement_DefaultContinentBonuses'.default.PursuitOfKnowledgeBonus[`DIFFICULTYSETTING];
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//---------------------------------------------------------------------------------------
// WORKSHOP
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateWorkshopTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'Workshop');
	Template.EngineeringBonus = 0;
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_Workshop_A";
	Template.AnimMapName = "AVG_Workshop_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_Workshop";
	Template.StaffSlots.AddItem('WorkshopStaffSlot');
	Template.StaffSlots.AddItem('WorkshopStaffSlot');
	Template.StaffSlotsLocked = 1;
	Template.CalculateStaffingRequirementFn = CalculateWorkshopStaffingRequirement;
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityRemovedFn = OnFacilityRemovedDefault;
	Template.CanFacilityBeRemovedFn = CanWorkshopBeRemoved;
	Template.IsFacilityProjectActiveFn = IsWorkshopProjectActive;
	Template.Upgrades.AddItem('Workshop_AdditionalWorkbench');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');

	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot1');	

	Template.UIFacilityClass = class'UIFacility_Workshop';
	Template.FacilityEnteredAkEvent = "Play_AvengerWorkshop_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_Workshop_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Strategy.Avenger_Workshop_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Workshop_Construction";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 4;

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(20);
	Template.iPower = -1;
	Template.UpkeepCost = 35;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 125;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function CalculateWorkshopStaffingRequirement(X2FacilityTemplate Template, out int RequiredScience, out int RequiredEngineering)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	RequiredEngineering = (Template.Requirements.RequiredEngineeringScore * ((XComHQ.GetNumberOfFacilitiesOfType(Template)+XComHQ.GetNumberBuildingOfFacilitiesOfType(Template)) + 1));
	RequiredScience = Template.Requirements.RequiredScienceScore;
}

static function bool CanWorkshopBeRemoved(StateObjectReference FacilityRef)
{
	return !IsWorkshopProjectActive(FacilityRef);
}

static function bool IsWorkshopProjectActive(StateObjectReference FacilityRef)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot SlotState;
	local int i;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		SlotState = FacilityState.GetStaffSlot(i);
		if (SlotState.IsStaffSlotBusy())
		{
			return true;
		}
	}
	return false;
}

//---------------------------------------------------------------------------------------
// PROVING GROUND
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateProvingGroundTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'ProvingGround');
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_ProvingGrounds_A";
	Template.AnimMapName = "AVG_ProvingGrounds_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_ProvingGrounds";
	Template.StaffSlots.AddItem('ProvingGroundStaffSlot');
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityRemovedFn = OnProvingGroundRemoved;
	Template.IsFacilityProjectActiveFn = IsProvingGroundProjectActive;
	Template.GetQueueMessageFn = GetProvingGroundQueueMessage;
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.FillerSlots.AddItem('Engineer');
	Template.bHideStaffSlotOpenPopup = true;

	Template.BaseMinFillerCrew = 1;

	Template.UIFacilityClass = class'UIFacility_ProvingGround';
	Template.FacilityEnteredAkEvent = "Play_AvengerProvingGround_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_ProvingGrounds_Complete";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_ProvingGrounds_Construction";

	Template.MaxFillerCrew = 4;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventOfficer');
	Template.Requirements.bVisibleIfPersonnelGatesNotMet = false;

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(14);
	Template.iPower = -3;
	Template.UpkeepCost = 25;
	
	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 100;
	Template.Cost.ResourceCosts.AddItem(Resources);
	
	// this is a GP priority facility
	Template.bPriority = true;

	return Template;
}

static function OnProvingGroundRemoved(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local StateObjectReference BuildItemRef;
	local int idx;
		
	// First cancel all of the active proving ground projects
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cancel All Proving Ground Projects");
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	if (FacilityState != none)
	{
		for (idx = 0; idx < FacilityState.BuildQueue.Length; idx++)
		{
			BuildItemRef = FacilityState.BuildQueue[idx];
			class'XComGameStateContext_HeadquartersOrder'.static.CancelProvingGroundProject(NewGameState, BuildItemRef);
		}
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState); // we need two separate NewGameStates because facility and XComHQ are changed in both

	// Then actually remove the facility
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Proving Ground Removed");
	RemoveFacility(NewGameState, FacilityRef, NewXComHQ);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
}

static function bool IsProvingGroundProjectActive(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

	return (FacilityState.BuildQueue.Length > 0);
}

static function string GetProvingGroundQueueMessage(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local StateObjectReference BuildItemRef;
	local string strStatus, Message;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

	//Show info about the first item in the build queue.
	if (FacilityState.BuildQueue.length == 0)
	{
		strStatus = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_ProvingGround'.default.m_strEmptyQueue, eUIState_Bad);
	}
	else
	{
		BuildItemRef = FacilityState.BuildQueue[0];
		ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(BuildItemRef.ObjectID));
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));

		if (ProvingGroundProject.GetCurrentNumHoursRemaining() < 0)
			Message = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
		else
			Message = class'UIUtilities_Text'.static.GetTimeRemainingString(ProvingGroundProject.GetCurrentNumHoursRemaining());

		strStatus = TechState.GetMyTemplate().DisplayName $ ":" @ Message;
	}

	return strStatus;
}

//---------------------------------------------------------------------------------------
// POWER RELAY
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePowerRelayTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'PowerRelay');
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = false;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_PowerRelay_A";
	Template.AnimMapName = "AVG_PowerRelay_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PowerRelay";
	Template.StaffSlots.AddItem('PowerRelayStaffSlot');
	Template.StaffSlots.AddItem('PowerRelayStaffSlot');
	Template.StaffSlotsLocked = 1;
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityRemovedFn = OnFacilityRemovedDefault;
	Template.CanFacilityBeRemovedFn = CanPowerRelayBeRemoved;
	Template.GetFacilityInherentValueFn = GetPowerRelayInherentValue;
	Template.Upgrades.AddItem('PowerRelay_PowerConduit');
	Template.Upgrades.AddItem('PowerRelay_EleriumConduit');
	Template.FillerSlots.AddItem('Engineer');

	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot2');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot3');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot5');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot9');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot10');	

	Template.UIFacilityClass = class'UIFacility_PowerGenerator';
	Template.FacilityEnteredAkEvent = "Play_AvengerPowerRelay_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Avenger_Power_Relay_now_operational";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Avenger_Power_Relay_upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Avenger_Power_Relay_construction_initiated";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 0;

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(12);
	Template.iPower = 3;
	Template.UpkeepCost = 10;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 80;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function bool CanPowerRelayBeRemoved(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local int TotalPower, FacilityPower, RequiredPower;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	TotalPower = XComHQ.GetPowerProduced();
	RequiredPower = XComHQ.GetPowerConsumed();
	FacilityPower = FacilityState.GetPowerOutput();

	return (TotalPower - FacilityPower >= RequiredPower);
}

static function int GetPowerRelayInherentValue(StateObjectReference FacilityRef)
{
	local XComGameState_FacilityXCom FacilityState;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	return FacilityState.GetPowerOutput();
}

//---------------------------------------------------------------------------------------
// ADVANCED WARFARE CENTER
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateAdvancedWarfareCenterTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate_Infirmary', Template, 'AdvancedWarfareCenter');
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_Infirmary_A";
	Template.AnimMapName = "AVG_Infirmary_A_Anim";
	Template.FlyInRemoteEvent = 'CIN_Flyin_Infirmary';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_AdvancedWarCenter";
	Template.StaffSlots.AddItem('AWCScientistStaffSlot');
	Template.StaffSlots.AddItem('AWCSoldierStaffSlot');
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityBuiltFn = OnAdvancedWarfareCenterBuilt;
	Template.OnFacilityRemovedFn = OnAdvancedWarfareCenterRemoved;
	Template.IsFacilityProjectActiveFn = IsAdvancedWarfareCenterProjectActive;
	Template.GetQueueMessageFn = GetAdvancedWarfareCenterQueueMessage;
	Template.BaseMinFillerCrew = 1;
	
	//Medics, Patients and Visitors are handled in a custom fashion
	Template.FillerSlots.AddItem('Scientist');
	Template.FillerSlots.AddItem('Scientist');
	Template.FillerSlots.AddItem('Scientist');
	Template.FillerSlots.AddItem('Scientist');	

	Template.UIFacilityClass = class'UIFacility_AdvancedWarfareCenter';
	Template.FacilityEnteredAkEvent = "Play_AvengerAdvancedWarfareCenter_Occupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Avenger_Advanced_Warfare_Center_now_operational";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Avenger_Advanced_Warfare_Center_upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Avenger_Advanced_Warfare_Center_construction_initiated";

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienBiotech');
	
	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(21);
	Template.iPower = -3;
	Template.UpkeepCost = 35;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 115;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function OnAdvancedWarfareCenterBuilt(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On AWC Built");

	for(idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if(UnitState != none && UnitState.IsASoldier() && UnitState.GetRank() >= 1)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.RollForAWCAbility();
		}
	}

	if(NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function OnAdvancedWarfareCenterRemoved(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	EmptyFacilityProjectStaffSlots(FacilityRef);
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Advanced Warfare Center Removed");

	RemoveFacility(NewGameState, FacilityRef, NewXComHQ);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function bool IsAdvancedWarfareCenterProjectActive(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectRespecSoldier RespecProject;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	
	if (XComHQ.GetNumberOfInjuredSoldiers() > 0)
	{
		return true;
	}

	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			RespecProject = XComHQ.GetRespecSoldierProject(StaffSlot.GetAssignedStaffRef());
			if (RespecProject != none)
			{
				return true;
			}
		}
	}
	return false;
}

static function string GetAdvancedWarfareCenterQueueMessage(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectRespecSoldier RespecProject;
	local string strStatus, Message;
	local int i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			RespecProject = XComHQ.GetRespecSoldierProject(StaffSlot.GetAssignedStaffRef());
			if (RespecProject != none)
			{
				if (RespecProject.GetCurrentNumHoursRemaining() < 0)
					Message = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
				else
					Message = class'UIUtilities_Text'.static.GetTimeRemainingString(RespecProject.GetCurrentNumHoursRemaining());

				strStatus = StaffSlot.GetBonusDisplayString() $ ":" @ Message;
				break;
			}
		}
	}

	return strStatus;
}

//---------------------------------------------------------------------------------------
// SHADOW CHAMBER
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateShadowChamberTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'ShadowChamber');
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_ShadowChamber_A";
	Template.AnimMapName = "AVG_ShadowChamber_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_ShadowChamber";
	Template.NeedsAttentionNarrative = "X2NarrativeMoments.Strategy.Avenger_Commander_ShadowChamber";
	Template.StaffSlots.AddItem('ShadowChamberShenStaffSlot');
	Template.StaffSlots.AddItem('ShadowChamberTyganStaffSlot');
	Template.StaffSlotsLocked = 2;
	Template.bHideStaffSlots = true;
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityRemovedFn = OnFacilityRemovedDefault;
	Template.CanFacilityBeRemovedFn = CanShadowChamberBeRemoved;
	Template.IsFacilityProjectActiveFn = IsShadowChamberProjectActive;
	Template.GetQueueMessageFn = GetShadowChamberQueueMessage;
	Template.Upgrades.AddItem('ShadowChamber_Destroyed');
	Template.Upgrades.AddItem('ShadowChamber_CelestialGate');

	Template.UIFacilityClass = class'UIFacility_ShadowChamber';
	Template.FacilityEnteredAkEvent = "Play_AvengerShadowChamber_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_ShadowChamber_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Avenger_Shadow_Chamber_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_ShadowChamber_Construction";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 0;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AlienEncryption');

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(14);
	Template.iPower = -5;
	Template.UpkeepCost = 30;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 125;
	Template.Cost.ResourceCosts.AddItem(Resources);

	// this is a GP priority facility
	Template.bPriority = true;

	return Template;
}

static function bool CanShadowChamberBeRemoved(StateObjectReference FacilityRef)
{
	return !IsShadowChamberProjectActive(FacilityRef);
}

static function bool IsShadowChamberProjectActive(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return XComHQ.HasShadowProject();
}

static function string GetShadowChamberQueueMessage(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local string strStatus, description, time;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if (XComHQ.HasShadowProject())
	{
		// get data
		description = XComHQ.GetCurrentShadowTech().GetDisplayName();

		if (XComHQ.GetCurrentShadowProject().GetCurrentNumHoursRemaining() < 0)
			time = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
		else
			time = class'UIUtilities_Text'.static.GetTimeRemainingString(XComHQ.GetCurrentShadowProject().GetCurrentNumHoursRemaining());

		strStatus = description $":" @ time;
	}

	return strStatus;
}

//---------------------------------------------------------------------------------------
// OFFICER TRAINING SCHOOL
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateOfficerTrainingSchoolTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'OfficerTrainingSchool');
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_GuerillaTacticsSchool_A";
	Template.AnimMapName = "AVG_GuerillaTacticsSchool_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_GuerrilaTacticsSchool";
	Template.StaffSlots.AddItem('OTSStaffSlot');
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityBuiltFn = OnGTSBuilt;
	Template.OnFacilityRemovedFn = OnGTSRemoved;
	Template.IsFacilityProjectActiveFn = IsGTSProjectActive;
	Template.GetQueueMessageFn = GetGTSQueueMessage;
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.FillerSlots.AddItem('Soldier');
	Template.BaseMinFillerCrew = 4;

	Template.UIFacilityClass = class'UIFacility_Academy';
	Template.FacilityEnteredAkEvent = "Play_AvengerGuerillaTacticsSchool_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_Academy_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Strategy.Avenger_Academy_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Academy_Construction";

	Template.MaxFillerCrew = 6 - Template.StaffSlots.Length;

	Template.SoldierUnlockTemplates.AddItem('HuntersInstinctUnlock');
	Template.SoldierUnlockTemplates.AddItem('HitWhereItHurtsUnlock');
	Template.SoldierUnlockTemplates.AddItem('CoolUnderPressureUnlock');
	Template.SoldierUnlockTemplates.AddItem('BiggestBoomsUnlock');
	Template.SoldierUnlockTemplates.AddItem('LightningStrikeUnlock');
	Template.SoldierUnlockTemplates.AddItem('WetWorkUnlock');
	Template.SoldierUnlockTemplates.AddItem('SquadSizeIUnlock');
	Template.SoldierUnlockTemplates.AddItem('SquadSizeIIUnlock');
	Template.SoldierUnlockTemplates.AddItem('IntegratedWarfareUnlock');
	Template.SoldierUnlockTemplates.AddItem('VengeanceUnlock');
	Template.SoldierUnlockTemplates.AddItem('VultureUnlock');
	Template.SoldierUnlockTemplates.AddItem('StayWithMeUnlock');
	//Template.SoldierUnlockTemplates.AddItem('FNGUnlock');
	
	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(14);
	Template.iPower = -3;
	Template.UpkeepCost = 25;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 85;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function OnGTSBuilt(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On GTS Built");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.RestoreSoldierUnlockTemplates();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function OnGTSRemoved(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	EmptyFacilityProjectStaffSlots(FacilityRef);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Guerrilla Tactics School Removed");
	RemoveFacility(NewGameState, FacilityRef, NewXComHQ);
	NewXComHQ.ClearSoldierUnlockTemplates();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function bool IsGTSProjectActive(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectTrainRookie RookieProject;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			RookieProject = XComHQ.GetTrainRookieProject(StaffSlot.GetAssignedStaffRef());
			if (RookieProject != none)
			{
				return true;
			}
		}
	}
	return false;
}

static function string GetGTSQueueMessage(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectTrainRookie RookieProject;
	local string strStatus, Message;
	local int i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			RookieProject = XComHQ.GetTrainRookieProject(StaffSlot.GetAssignedStaffRef());
			if (RookieProject != none)
			{
				if (RookieProject.GetCurrentNumHoursRemaining() < 0)
					Message = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
				else
					Message = class'UIUtilities_Text'.static.GetTimeRemainingString(RookieProject.GetCurrentNumHoursRemaining());

				strStatus = StaffSlot.GetBonusDisplayString() $ ":" @ Message;
				break;
			}
		}
	}

	return strStatus;
}

//---------------------------------------------------------------------------------------
// UFO DEFENSE
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateUFODefenseTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'UFODefense');
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_UFODefense_A";
	Template.AnimMapName = "AVG_UFODefense_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_UFODefense";
	Template.StaffSlots.AddItem('UFODefenseStaffSlot');
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityBuiltFn = OnDefenseFacilityBuilt;
	Template.OnFacilityRemovedFn = OnDefenseFacilityRemoved;
	Template.Upgrades.AddItem('DefenseFacility_QuadTurrets');
	Template.FillerSlots.AddItem('Engineer');

	Template.UIFacilityClass = class'UIFacility_UFODefense';
	Template.FacilityEnteredAkEvent = "Play_AvengerUFODefense_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_UFOdefense_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Strategy.Avenger_UFOdefense_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Defense_Array_Construction";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 4;


	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyAdventTurret');

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(14);
	Template.iPower = -2;
	Template.UpkeepCost = 10;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function OnDefenseFacilityBuilt(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Defense Facility Built");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.TacticalGameplayTags.AddItem('AvengerDefenseTurrets');

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function OnDefenseFacilityRemoved(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Defense Facility Removed");

	RemoveFacility(NewGameState, FacilityRef, NewXComHQ);
	
	NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurrets');
	NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurretsMk2');
	NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurrets_Upgrade');
	NewXComHQ.TacticalGameplayTags.RemoveItem('AvengerDefenseTurretsMk2_Upgrade');

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//---------------------------------------------------------------------------------------
// RESISTANCE COMMS
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreateResistanceCommsTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'ResistanceComms');
	Template.CommCapacity = 1;
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = false;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_ResistanceComms_A";
	Template.AnimMapName = "AVG_ResistanceComms_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_ResistanceComms";
	Template.StaffSlots.AddItem('ResCommsStaffSlot');
	Template.StaffSlots.AddItem('ResCommsBetterStaffSlot');
	Template.StaffSlotsLocked = 1;
	Template.GetFacilityInherentValueFn = GetResistanceCommsInherentValue;
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityRemovedFn = OnFacilityRemovedDefault;
	Template.CanFacilityBeRemovedFn = CanResistanceCommsBeRemoved;
	Template.Upgrades.AddItem('ResistanceComms_AdditionalCommStation');
	Template.FillerSlots.AddItem('Engineer');

	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot1');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot2');

	Template.UIFacilityClass = class'UIFacility_ResistanceComms';
	Template.FacilityEnteredAkEvent = "Play_AvengerResistanceComms_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_ResistanceComm_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Strategy.Avenger_ResistanceComm_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Resistance_Comm_Construction";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 4;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('ResistanceCommunications');

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(16);
	Template.iPower = -3;
	Template.UpkeepCost = 25;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 110;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function bool CanResistanceCommsBeRemoved(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local int TotalComms, FacilityComms, RequiredComms;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	TotalComms = XComHQ.GetPossibleResContacts();
	RequiredComms = XComHQ.GetCurrentResContacts();
	FacilityComms = FacilityState.CommCapacity;

	return (TotalComms - FacilityComms >= RequiredComms);
}

static function int GetResistanceCommsInherentValue(StateObjectReference FacilityRef)
{
	local XComGameState_FacilityXCom FacilityState;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	
	return FacilityState.CommCapacity;
}

//---------------------------------------------------------------------------------------
// PSI CHAMBER    
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePsiChamberTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'PsiChamber');
	Template.bIsCoreFacility = false;
	Template.bIsUniqueFacility = true;
	Template.bIsIndestructible = false;
	Template.MapName = "AVG_PsiLab_A";
	Template.AnimMapName = "AVG_PsiLab_A_Anim";
	Template.FlyInRemoteEvent = '';
	Template.strImage = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab";
	Template.StaffSlots.AddItem('PsiChamberScientistStaffSlot');
	Template.StaffSlots.AddItem('PsiChamberSoldierStaffSlot');
	Template.StaffSlots.AddItem('PsiChamberSoldierStaffSlot');
	Template.StaffSlotsLocked = 1;
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityRemovedFn = OnPsiChamberRemoved;
	Template.IsFacilityProjectActiveFn = IsPsiChamberProjectActive;
	Template.GetQueueMessageFn = GetPsiChamberQueueMessage;
	Template.Upgrades.AddItem('PsiChamber_SecondCell');
	Template.bHideStaffSlotOpenPopup = true;

	Template.UIFacilityClass = class'UIFacility_PsiLab';
	Template.FacilityEnteredAkEvent = "Play_AvengerPsiChamber_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_PsiLab_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Strategy.Avenger_PsiLab_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Psy_Lab_Construction";

	Template.BaseMinFillerCrew = 0;
	Template.MaxFillerCrew = 4;

	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot2');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot4');

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Psionics');

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(21);
	Template.iPower = -5;
	Template.UpkeepCost = 55;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 175;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Resources.ItemTemplateName = 'EleriumDust';
	Resources.Quantity = 10;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function OnPsiChamberRemoved(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	EmptyFacilityProjectStaffSlots(FacilityRef);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Psi Chamber Removed");

	RemoveFacility(NewGameState, FacilityRef, NewXComHQ);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function bool IsPsiChamberProjectActive(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			PsiProject = XComHQ.GetPsiTrainingProject(StaffSlot.GetAssignedStaffRef());
			if (PsiProject != none)
			{
				return true;
			}
		}
	}
	return false;
}

static function string GetPsiChamberQueueMessage(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;
	local string strStatus, Message;
	local int i;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			PsiProject = XComHQ.GetPsiTrainingProject(StaffSlot.GetAssignedStaffRef());
			if (PsiProject != none)
			{
				if (PsiProject.GetCurrentNumHoursRemaining() < 0)
					Message = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
				else
					Message = class'UIUtilities_Text'.static.GetTimeRemainingString(PsiProject.GetCurrentNumHoursRemaining());

				strStatus = StaffSlot.GetBonusDisplayString() $ ":" @ Message;
				break;
			}
		}
	}

	return strStatus;
}

// #######################################################################################
// -------------------- HELPERS ----------------------------------------------------------
// #######################################################################################

static function bool ClearUIIfNeeded()
{
	if( `HQPRES.ScreenStack.IsInStack(class'UIStrategyMap') )
	{
		`HQPRES.ClearUIToHUD();
		return true;
	}
	return false;
}

static function SelectFacility(StateObjectReference FacilityRef, optional bool bForceInstant = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local bool bInstantInterp;
	local Name FacilityEnteredEventName;
	local X2FacilityTemplate FacilityTemplate;
	local XComSoundManager SoundManager;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityTemplate = FacilityState.GetMyTemplate();
	
	SoundManager = `XSTRATEGYSOUNDMGR;
	SoundManager.PlaySoundEvent("Stop_AvengerAmbience");

	if( FacilityTemplate.FacilityEnteredAkEvent != "" )
	{
		SoundManager.PlaySoundEvent(FacilityTemplate.FacilityEnteredAkEvent);
	}
	else
	{
		SoundManager.PlaySoundEvent("Play_AvengerNoRoom");
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unmark needs attention");
	FacilityState = XComGameState_FacilityXCom(NewGameState.CreateStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));
	NewGameState.AddStateObject(FacilityState);
	FacilityState.ClearNeedsAttention();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if( FacilityTemplate.UIFacilityClass != None )
	{
		bInstantInterp = (ClearUIIfNeeded() || bForceInstant);

		`HQPRES.UIFacility(FacilityTemplate.UIFacilityClass, FacilityRef, bInstantInterp);

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entered Facility");
		FacilityEnteredEventName = Name("OnEnteredFacility_" $ FacilityTemplate.DataName);
		`XEVENTMGR.TriggerEvent(FacilityEnteredEventName, FacilityState, FacilityState, NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Entered Facility");
		FacilityEnteredEventName = Name("OnEnteredFacility_" $ FacilityTemplate.DataName);
		`XEVENTMGR.TriggerEvent(FacilityEnteredEventName, FacilityState, FacilityState, NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

static function OnFacilityRemovedDefault(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On Facility Removed");

	RemoveFacility(NewGameState, FacilityRef);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

// All of the Remove Facility functionality that needs to be completed every time
private static function RemoveFacility(XComGameState NewGameState, StateObjectReference FacilityRef, optional out XComGameState_HeadquartersXCom NewXComHQ)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersRoom Room;
	local StateObjectReference EmptyRef;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	Room = FacilityState.GetRoom();
	
	// Remove the facility from XComHQ's list
	NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(NewXComHQ);
	NewXComHQ.Facilities.RemoveItem(FacilityRef);

	// Clear the reference from the room it is located in and flag it to update the 3D map
	Room = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));
	NewGameState.AddStateObject(Room);
	Room.Facility = EmptyRef;
	Room.UpdateRoomMap = true;

	// Empty all of the staff slots
	FacilityState.EmptyAllStaffSlots(NewGameState);

	// Remove the facility game state	
	NewGameState.RemoveStateObject(FacilityRef.ObjectID);
}

// For staff slots that have special functions to stop HQ projects along with emptying the slot
private static function EmptyFacilityProjectStaffSlots(StateObjectReference FacilityRef)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot SlotState;
	local int idx;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	for (idx = 0; idx < FacilityState.StaffSlots.Length; idx++)
	{
		SlotState = FacilityState.GetStaffSlot(idx);
		if (SlotState.GetMyTemplate().EmptyStopProjectFn != none)
		{
			SlotState.EmptySlotStopProject();
		}
	}
}