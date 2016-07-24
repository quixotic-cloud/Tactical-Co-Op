//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MissionNarrative_DefaultNarrativeSet.uc
//  AUTHOR:  David Burchanowski  --  1/29/2015
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MissionNarrative_DefaultNarrativeSet extends X2MissionNarrative;

static function array<X2DataTemplate> CreateTemplates()
{
    local array<X2MissionNarrativeTemplate> Templates;

    Templates.AddItem(AddDefaultRecoverMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultRecover_ADVMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultRecover_TrainMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultRecover_VehicleMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultRecover_FlightDeviceMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultDestroyRelayMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultExtractMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultRescue_AdventCellMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultRescue_VehicleMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultSupplyRaidATTMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultSupplyRaidTrainMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultSupplyRaidConvoyMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultHackMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultHack_ADVMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultHack_TrainMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultProtectDeviceMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultNeutralizeTargetMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultNeutralize_VehicleMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultAssaultAlienFortressMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultAdventFacilityBlacksiteMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultAdventFacilityForgeMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultAdventFacilityPsiGateMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultCentralNetworkBroadcastMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultSabotageMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultSabotageCCMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultSecureUFOMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultAvengerDefenseMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultTerrorMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultTutorialMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultDemoMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultTestMissionNarrativeTemplate());
    Templates.AddItem(AddDefaultMultiplayerMissionNarrativeTemplate());

    return Templates;
}

static function X2MissionNarrativeTemplate AddDefaultRecoverMissionNarrativeTemplate(optional name TemplateName = 'DefaultRecover')
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, TemplateName);

	Template.MissionType = "Recover";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Recover.Recover_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjSpotted";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjReacquired";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Recover.SKY_RecoGEN_ItemSecured";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDropped";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagThree";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagLast";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedEnemyRemain";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedMissionOver";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Recover.Recover_AllEnemiesDefeatedContinue";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredNoRNF";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredWithRNF";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[22]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[23]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultRecover_ADVMissionNarrativeTemplate(optional name TemplateName = 'DefaultRecover_ADV')
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, TemplateName);

    Template.MissionType = "Recover_ADV";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Recover.Recover_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjSpotted";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjReacquired";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Recover.SKY_RecoGEN_ItemSecured";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDropped";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagThree";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagLast";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedEnemyRemain";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedMissionOver";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Recover.Recover_AllEnemiesDefeatedContinue";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredNoRNF";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredWithRNF";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[22]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[23]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";


    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultRecover_TrainMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultRecover_Train');

	Template.MissionType = "Recover_Train";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Recover.Recover_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjSpotted";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjReacquired";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Recover.SKY_RecoGEN_ItemSecured";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDropped";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagThree";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagLast";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedEnemyRemain";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedMissionOver";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Recover.Recover_AllEnemiesDefeatedContinue";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredNoRNF";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredWithRNF";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[22]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[23]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";


    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultRecover_VehicleMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultRecover_Vehicle');

	Template.MissionType = "Recover_Vehicle";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Recover.Recover_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjSpotted";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjReacquired";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Recover.SKY_RecoGEN_ItemSecured";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDropped";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagThree";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Recover.Recover_TimerNagLast";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedEnemyRemain";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedMissionOver";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Recover.Recover_AllEnemiesDefeatedContinue";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredNoRNF";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.Recover.Recover_ObjAcquiredWithRNF";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[22]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[23]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultRecover_FlightDeviceMissionNarrativeTemplate(optional name TemplateName = 'DefaultRecover_FlightDevice')
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, TemplateName);

    Template.MissionType = "Recover_FlightDevice";
    Template.NarrativeMoments[0]="X2NarrativeMoments.CEN_FlightDevice_Intro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.T_Setup_Phase_Flight_Device_Spotted_Central";
    Template.NarrativeMoments[2]="X2NarrativeMoments.CEN_FlightDevice_TimerNagThree";
    Template.NarrativeMoments[3]="X2NarrativeMoments.CEN_FlightDevice_TimerNagLast";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.Recover.Recover_STObjDestroyedMissionOver";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.Recover.Recover_AllEnemiesDefeatedContinue";
    Template.NarrativeMoments[6]="X2NarrativeMoments.Setup_Phase_Flight_Device_Recovered";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_HeavyLossesIncurred";
    Template.NarrativeMoments[11]="X2NarrativeMoments.CEN_FlightDevice_TimerStarted";
    Template.NarrativeMoments[12]="X2NarrativeMoments.CEN_Setup_Phase_Flight_Device_Recovered_NO_HOSTILES_ALT";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultSupplyRaidATTMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultSupplyRaidATT');

    Template.MissionType = "SupplyRaidATT";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_TacIntroATT";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_ManyCratesDestroyed";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_FirstCrateDestroyed";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.support.T_Support_Alien_Tech_Crate_Spotted_Central";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_AllCratesDestroyed";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultSupplyRaidTrainMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultSupplyRaidTrain');

    Template.MissionType = "SupplyRaidTrain";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_TacIntroTRN";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_ManyCratesDestroyed";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_FirstCrateDestroyed";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.support.T_Support_Alien_Tech_Crate_Spotted_Central";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_AllCratesDestroyed";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";


    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultSupplyRaidConvoyMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultSupplyRaidConvoy');

    Template.MissionType = "SupplyRaidConvoy";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_TacIntroCVY";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_ManyCratesDestroyed";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_FirstCrateDestroyed";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.support.T_Support_Alien_Tech_Crate_Spotted_Central";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.SupplyRaid.SupplyRaid_AllCratesDestroyed";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";


    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultDestroyRelayMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultDestroyRelay');

	Template.MissionType = "DestroyRelay";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_STObjSpotted";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_ObjectDestroyed";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_TimerBurnout";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_ProceedToSweep";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_TimerNagThree";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_TimerNagLast";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_AllEnemiesDefeated_Continue";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultExtractMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultExtract');

	Template.MissionType = "Extract";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.CEN_ExtrGEN_STObjDestroyed";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.Extract.Extract_CEN_VIPKilled_Continue";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.Extract.Central_Extract_VIP_TimerNagThree";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.Extract.Central_Extract_VIP_TimerNagSix";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Extract.Central_Extract_VIP_TimerNagLast";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Extract.Central_Extract_VIP_Timer_Expired";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.CEN_ExtrGEN_Intro_01";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_SecureRetreat";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Extract.Central_Extract_VIP_Evac_Destroyed";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_AdviseRetreat";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[18]="X2NarrativeMoments.T_Extraction_Reminder_Squad_Not_Concealed_A_Central";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultRescue_AdventCellMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultRescue_AdventCell');

	Template.MissionType = "Rescue_AdventCell";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.RescueVIP.CEN_RescVEH_Intro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPSpotted";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.RescueVIP.Rescue_CEN_VIPAcquired";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerExpired";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagThree";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagSix";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagLast";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Neutralize.CEN_Neut_TargetLost";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.CEN_ExtrGEN_STObjDestroyed";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_RNFInbound";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_AdviseRetreat";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_SecureRetreat";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_EvacDestroyed";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultRescue_VehicleMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultRescue_Vehicle');

	Template.MissionType = "Rescue_Vehicle";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.RescueVIP.CEN_RescVEH_Intro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPSpotted";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.RescueVIP.Rescue_CEN_VIPAcquired";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerExpired";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagThree";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagSix";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagLast";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Neutralize.CEN_Neut_TargetLost";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.CEN_ExtrGEN_STObjDestroyed";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_RNFInbound";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_AdviseRetreat";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_SecureRetreat";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_EvacDestroyed";


    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultHackMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultHack');

	Template.MissionType = "Hack";

    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Hack.Hack_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalSpotted";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerNagThree";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerNagLast";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerBurnout";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalDestroyedEnemyRemain";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalDestroyedMissionOver";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_AreaSecured_02";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Hack.Central_Hack_TerminalHackedWithRNF";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Hack.CEN_Hack_TerminalHacked";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    
    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultHack_ADVMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultHack_ADV');

    Template.MissionType = "Hack_ADV";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Hack.Hack_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalSpotted";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerNagThree";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerNagLast";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerBurnout";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalDestroyedEnemyRemain";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalDestroyedMissionOver";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_AreaSecured_02";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Hack.Central_Hack_TerminalHackedWithRNF";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Hack.CEN_Hack_TerminalHacked";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultHack_TrainMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultHack_Train');

	Template.MissionType = "Hack_Train";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Hack.Hack_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalSpotted";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerNagThree";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerNagLast";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Hack.Hack_TimerBurnout";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalDestroyedEnemyRemain";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Hack.Hack_TerminalDestroyedMissionOver";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_AreaSecured_02";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Hack.Central_Hack_TerminalHackedWithRNF";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Hack.CEN_Hack_TerminalHacked";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    
    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultProtectDeviceMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultProtectDevice');

	Template.MissionType = "ProtectDevice";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.ProtectDevice.T_Protect_Device_PrDv_Intro";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.ProtectDevice.T_Protect_Device_PrDv_ProceedToSweep";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.ProtectDevice.T_Protect_Device_PrDv_STObjDestroyed";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.General.CEN_Gen_BurnoutSecured_02";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[12]="X2NarrativeMoments.T_Protect_Device_Sighted_Central";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultNeutralizeTargetMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultNeutralizeTarget');

	Template.MissionType = "NeutralizeTarget";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPSpotted";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPKilledAfterCapture";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPExecuted";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.Neutralize.CEN_Neut_TargetInCustody";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagThree";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagSix";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagLast";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerExpired";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_RNFInbound";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_AdviseRetreat";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_SecureRetreat";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_EvacDestroyed";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
	Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.support.T_Support_Reminder_Knock_Out_VIP_Central_01";
    
    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultNeutralize_VehicleMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultNeutralize_Vehicle');

	Template.MissionType = "Neutralize_Vehicle";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPSpotted";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.SKY_ExtrGEN_STObjSecured";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPKilledAfterCapture";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_VIPExecuted";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.Neutralize.CEN_Neut_TargetInCustody";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagThree";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagSix";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerNagLast";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_TimerExpired";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_RNFInbound";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_AdviseRetreat";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Neutralize.Neutralize_SecureRetreat";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_EvacDestroyed";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
	Template.NarrativeMoments[21]="X2NarrativeMoments.TACTICAL.support.T_Support_Reminder_Knock_Out_VIP_Central_01";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultAssaultAlienFortressMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultAssaultAlienFortress');

    Template.MissionType = "GP_Fortress";
    Template.NarrativeMoments[0]="X2NarrativeMoments.T_Final_Mission_The_Fortress";
    Template.NarrativeMoments[1]="X2NarrativeMoments.T_Final_Mission_XCOM_Avatar_Has_Died";
    Template.NarrativeMoments[2]="X2NarrativeMoments.T_Final_Mission_Final_Showdown_Begins";
    Template.NarrativeMoments[3]="X2NarrativeMoments.T_Final_Mission_Enemy_Avatar_1_Has_Died";
    Template.NarrativeMoments[4]="X2NarrativeMoments.T_Final_Mission_Final_Set_One";
    Template.NarrativeMoments[5]="X2NarrativeMoments.T_Final_Mission_Final_Set_Two";
    Template.NarrativeMoments[6]="X2NarrativeMoments.T_Final_Mission_Final_Set_Three";
    Template.NarrativeMoments[7]="X2NarrativeMoments.T_Final_Mission_Final_Set_Four";
    Template.NarrativeMoments[8]="X2NarrativeMoments.T_Final_Mission_First_Set_One";
    Template.NarrativeMoments[9]="X2NarrativeMoments.T_Final_Mission_First_Set_Two";
    Template.NarrativeMoments[10]="X2NarrativeMoments.T_Final_Mission_First_Set_Three";
    Template.NarrativeMoments[11]="X2NarrativeMoments.T_Final_Mission_First_Set_Four";
    Template.NarrativeMoments[12]="X2NarrativeMoments.T_Final_Mission_First_Set_Five";
    Template.NarrativeMoments[13]="X2NarrativeMoments.T_Final_Mission_First_Set_Six";
    Template.NarrativeMoments[14]="X2NarrativeMoments.T_Final_Mission_Middle_Set_One";
    Template.NarrativeMoments[15]="X2NarrativeMoments.T_Final_Mission_Middle_Set_Two";
    Template.NarrativeMoments[16]="X2NarrativeMoments.T_Final_Mission_Middle_Set_Three";
    Template.NarrativeMoments[17]="X2NarrativeMoments.T_Final_Mission_Middle_Set_Four";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultAdventFacilityBlacksiteMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultAdventFacilityBlacksite');

    Template.MissionType = "GP_Blacksite";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Blacksite.Blacksite_SecureRetreat";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.Blacksite.Blacksite_TacIntro";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Blacksite.Blacksite_STWin_HL";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Blacksite.Blacksite_STWin";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Blacksite.Blacksite_FailureSquadWipe";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Blacksite.Blacksite_FailureAbortHL";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Blacksite.Blacksite_FailureAbort";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Blacksite.CEN_Blacksite_STObjTwoSpotted";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Blacksite.CEN_Blacksite_Mission_STObjAcquired";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Blacksite.CEN_Blacksite_Mission_STObjDropped";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Recover.SKY_RecoGEN_ItemSecured";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.Blacksite.CEN_Blacksite_STObjReacquired";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.RescueVIP.Central_Rescue_VIP_RNFInbound";  
    Template.NarrativeMoments[17]="X2NarrativeMoments.T_Blacksite_Interior_Reveal_ALT";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultAdventFacilityForgeMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultAdventFacilityForge');

    Template.MissionType = "GP_Forge";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Forge.Forge_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.T_Forge_Interior_Reveal";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.Forge.Forge_MissionSquadWipe";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.Forge.Forge_MissionFailure";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.Forge.CEN_Forge_TacOutro";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.Forge.Forge_SecureRetreat";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Forge.Forge_AdviseRetreat";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Forge.Forge_PrototypeDropped";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Forge.Forge_PrototypeReacquired";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Neutralize.CEN_Neut_TargetInCustody";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Neutralize.CEN_Neut_TargetInCustody";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Forge.Forge_PrototypeSpotted";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Forge.Forge_PrototypeAcquired";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultAdventFacilityPsiGateMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultAdventFacilityPsiGate');

    Template.MissionType = "GP_PsiGate";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.PsiGate.PsiGate_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.PsiGate.PsiGate_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.PsiGate.PsiGate_AllEnemiesDefeated";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.PsiGate.T_Psi_Gate_Gateway_Spotted_Central_P1";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.PsiGate.PsiGate_MissionFailure";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.PsiGate.CEN_PsiGate_FailureSquadWipe";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.PsiGate.CEN_PsiGate_STWin";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultCentralNetworkBroadcastMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultCentralNetworkBroadcast');

    Template.MissionType = "GP_Broadcast";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Broadcast.Broadcast_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.Broadcast.Broadcast_ObjSpotted";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.Broadcast.Broadcast_ArrayHacked";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.Broadcast.Broadcast_FailureSquadWipe";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultSabotageMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultSabotage');

	Template.MissionType = "Sabotage";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_BombDetonated";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_TacIntro";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_BombSpotted";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_ConsiderRetreat";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_BombPlantedNoRNF";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_CompletionNag";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_RNFIncoming";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_SignalJammed";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_AllEnemiesDefeatedContinue";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_AllEnemiesDefeatedObjCompleted";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_SecureRetreat";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultSabotageCCMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultSabotageCC');

    Template.MissionType = "SabotageCC";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_BombDetonated";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_HeavyLossesIncurred";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_TacIntro";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_BombSpotted";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_CompletionNag";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_AllEnemiesDefeated";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_AreaSecuredMissionEnd";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_BombPlantedEnd";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.SabotageCC.SabotageCC_BombPlantedContinue";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultSecureUFOMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultSecureUFO');

    Template.MissionType = "SecureUFO";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.SecureUFO.SecureUFO_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.SecureUFO.SecureUFO_DistressResponse";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.SecureUFO.SecureUFO_DistressLocated";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.SecureUFO.SecureUFO_DistressInitiated";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.SecureUFO.SecureUFO_DistressDeactivatedEnd";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.SecureUFO.SecureUFO_DistressDeactivatedEnd";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultAvengerDefenseMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultAvengerDefense');

	Template.MissionType = "AvengerDefense";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_TacIntro";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_DisruptorSighted";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_ClearForTakeoff";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_ClearForTakeoffHL";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_DisruptorDestroyed";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_FailureSquadWipe";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_FirstBoardingWarning";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_HeavyLosses";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_HLOnExtract";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_HostileInThreatZone";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_HostileKilledClear";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_HostileKilledRemaining";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_MultipleHostilesInThreatZone";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_OutroSuccess";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_OutroSuccessHL";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_ShipBoarded";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_XCOMReinforced";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_RNFFirst";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.Sabotage.Sabotage_RNFIncoming";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.AvengerDefense.AvengerDefense_ForcesExhausted";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultTerrorMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultTerror');

	Template.MissionType = "Terror";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Terror.Terror_AllEnemiesDefeated";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.General.GenTactical_SecureRetreat";
    Template.NarrativeMoments[2]="X2NarrativeMoments.TACTICAL.General.GenTactical_ConsiderRetreat";
    Template.NarrativeMoments[3]="X2NarrativeMoments.TACTICAL.Terror.Terror_AdviseRetreat";
    Template.NarrativeMoments[4]="X2NarrativeMoments.TACTICAL.General.GenTactical_PartialEVAC";
    Template.NarrativeMoments[5]="X2NarrativeMoments.TACTICAL.General.GenTactical_FullEVAC";
    Template.NarrativeMoments[6]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[7]="X2NarrativeMoments.TACTICAL.Terror.Terror_TacIntro";
    Template.NarrativeMoments[8]="X2NarrativeMoments.TACTICAL.Terror.Terror_SaveCompleteT1";
    Template.NarrativeMoments[9]="X2NarrativeMoments.TACTICAL.Terror.Terror_SaveCompleteT2";
    Template.NarrativeMoments[10]="X2NarrativeMoments.TACTICAL.Terror.Terror_SaveCompleteT3";
    Template.NarrativeMoments[11]="X2NarrativeMoments.TACTICAL.Terror.Terror_CivilianKilledT1";
    Template.NarrativeMoments[12]="X2NarrativeMoments.TACTICAL.Terror.Terror_CivilianKilledT2";
    Template.NarrativeMoments[13]="X2NarrativeMoments.TACTICAL.Terror.Terror_CivilianKilledT3";
    Template.NarrativeMoments[14]="X2NarrativeMoments.TACTICAL.Terror.Terror_CivilianWipe";
    Template.NarrativeMoments[15]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[16]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroFailure";
    Template.NarrativeMoments[17]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroPartialSuccess";
    Template.NarrativeMoments[18]="X2NarrativeMoments.TACTICAL.General.GenTactical_MissionExtroTotalSuccess";
    Template.NarrativeMoments[19]="X2NarrativeMoments.TACTICAL.General.GenTactical_TacWinOnly";
    Template.NarrativeMoments[20]="X2NarrativeMoments.TACTICAL.General.GenTactical_SquadWipe";
    Template.NarrativeMoments[21]="X2NarrativeMoments.T_Retaliation_Reminder_Squad_Not_Concealed_C_Central";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultTutorialMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultTutorial');

    Template.MissionType = "Tutorial_01";
    Template.NarrativeMoments[0]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_01";         
    Template.NarrativeMoments[1]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_01";         
    Template.NarrativeMoments[2]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_02";         
    Template.NarrativeMoments[3]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_03";         
    Template.NarrativeMoments[4]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_04";         
    Template.NarrativeMoments[5]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_05";         
    Template.NarrativeMoments[6]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_06";         
    Template.NarrativeMoments[7]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_07";         
    Template.NarrativeMoments[8]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_08";         
    Template.NarrativeMoments[9]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_09";         
    Template.NarrativeMoments[10]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Ramirez_10";          
    Template.NarrativeMoments[11]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_11";         
    Template.NarrativeMoments[12]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_12";         
    Template.NarrativeMoments[13]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_13";         
    Template.NarrativeMoments[14]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_14";         
    Template.NarrativeMoments[15]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_15";         
    Template.NarrativeMoments[16]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_16";         
    Template.NarrativeMoments[17]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_17";         
    Template.NarrativeMoments[18]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_18";         
    Template.NarrativeMoments[19]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_19";         
    Template.NarrativeMoments[20]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_20";         
    Template.NarrativeMoments[21]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_21";         
    Template.NarrativeMoments[22]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_22";         
    Template.NarrativeMoments[23]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_23";         
    Template.NarrativeMoments[24]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_24";         
    Template.NarrativeMoments[25]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Ramirez_25";          
    Template.NarrativeMoments[26]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Ramirez_26";          
    Template.NarrativeMoments[27]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_27";         
    Template.NarrativeMoments[28]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_28";         
    Template.NarrativeMoments[29]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_29";         
    Template.NarrativeMoments[30]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_30";         
    Template.NarrativeMoments[31]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_31";         
    Template.NarrativeMoments[32]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_32";         
    Template.NarrativeMoments[33]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_33";         
    Template.NarrativeMoments[34]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_34";          
    Template.NarrativeMoments[35]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_35";         
    Template.NarrativeMoments[36]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_36";          
    Template.NarrativeMoments[37]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_37";            
    Template.NarrativeMoments[38]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_38";          
    Template.NarrativeMoments[39]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_39";         
    Template.NarrativeMoments[40]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_40";          
    Template.NarrativeMoments[41]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_41";         
    Template.NarrativeMoments[42]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_42";          
    Template.NarrativeMoments[43]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_43";         
    Template.NarrativeMoments[44]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_44";          
    Template.NarrativeMoments[45]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_45";         
    Template.NarrativeMoments[46]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_46";          
    Template.NarrativeMoments[47]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_47";          
    Template.NarrativeMoments[48]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_48";            
    Template.NarrativeMoments[49]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_49";          
    Template.NarrativeMoments[50]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_50";         
    Template.NarrativeMoments[51]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_51";          
    Template.NarrativeMoments[52]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_52";          
    Template.NarrativeMoments[53]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_53";          
    Template.NarrativeMoments[54]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_54";            
    Template.NarrativeMoments[55]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_55";          
    Template.NarrativeMoments[56]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_56";            
    Template.NarrativeMoments[57]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Osei_57";         
    Template.NarrativeMoments[58]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_58";            
    Template.NarrativeMoments[59]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_59";         
    Template.NarrativeMoments[60]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_60";            
    Template.NarrativeMoments[61]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_61";          
    Template.NarrativeMoments[62]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_62";          
    Template.NarrativeMoments[63]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_63";         
    Template.NarrativeMoments[64]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_64";          
    Template.NarrativeMoments[65]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_65";          
    Template.NarrativeMoments[66]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_66";         
    Template.NarrativeMoments[67]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_67";          
    Template.NarrativeMoments[68]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_68";          
    Template.NarrativeMoments[69]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_69";            
    Template.NarrativeMoments[70]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_70";          
    Template.NarrativeMoments[71]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_71";         
    Template.NarrativeMoments[72]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Shen_72";         
    Template.NarrativeMoments[73]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_73";          
    Template.NarrativeMoments[74]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_74";            
    Template.NarrativeMoments[75]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_75";          
    Template.NarrativeMoments[76]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_76";            
    Template.NarrativeMoments[77]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_77";          
    Template.NarrativeMoments[78]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Kelly_78";            
    Template.NarrativeMoments[79]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Central_79";  
    Template.NarrativeMoments[80]="X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_FacilityReveal";
    Template.NarrativeMoments[81]="X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_AdventResponse";
    Template.NarrativeMoments[82]="X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_CentralCurbStomp";
    Template.NarrativeMoments[83]="X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_RescueCommander";
    Template.NarrativeMoments[84]="X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_SkyrangerEvac";
    Template.NarrativeMoments[85]="X2NarrativeMoments.T_Setup_Phase_Avoid_Detection_Shen";
    Template.NarrativeMoments[86]="X2NarrativeMoments.T_Setup_Phase_Cars_make_poor_cover_Shen";
    Template.NarrativeMoments[87]="X2NarrativeMoments.TACTICAL.TUTORIAL.Tutorial_CIN_SkyrangerEvac";
    Template.NarrativeMoments[88]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Ramirez_01";
    Template.NarrativeMoments[89]="X2NarrativeMoments.T_Tutorial_Osei_Concealed";
    Template.NarrativeMoments[90]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Osei_02";
    Template.NarrativeMoments[91]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Shen_03";
    Template.NarrativeMoments[92]="X2NarrativeMoments.T_Tutorial_Osei_WILD_05";
    Template.NarrativeMoments[93]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Shen_04";
    Template.NarrativeMoments[94]="X2NarrativeMoments.T_Tutorial_Osei_WILD_09";
    Template.NarrativeMoments[95]="X2NarrativeMoments.T_Tutorial_Osei_WILD_03";
    Template.NarrativeMoments[96]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Central_05";
    Template.NarrativeMoments[97]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Kelly_06";
    Template.NarrativeMoments[98]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Osei_07";
    Template.NarrativeMoments[99]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Central_08";
    Template.NarrativeMoments[100]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Central_09";
    Template.NarrativeMoments[101]="X2NarrativeMoments.T_Tutorial_Kelly_Confirmations_8";
    Template.NarrativeMoments[102]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Central_10";
    Template.NarrativeMoments[103]="X2NarrativeMoments.T_Tutorial_Kelly_Taking_Fire_03";
    Template.NarrativeMoments[104]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Central_11";
    Template.NarrativeMoments[105]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Central_12";
    Template.NarrativeMoments[106]="X2NarrativeMoments.T_Setup_Phase_Combat_Tutorial_Pickup_Osei_MissShot";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultDemoMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultDemo');

    Template.MissionType = "Demo_01";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.Demo.Demo_IntroBINK";
    Template.NarrativeMoments[1]="X2NarrativeMoments.TACTICAL.Tutorial.Tutorial_FreeTest";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultTestMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultTestMission');

    Template.MissionType = "TestMission";
    Template.NarrativeMoments[0]="X2NarrativeMoments.TACTICAL.DestroyObject.DestroyObject_ObjectDestroyed";

    return Template;
}

static function X2MissionNarrativeTemplate AddDefaultMultiplayerMissionNarrativeTemplate()
{
    local X2MissionNarrativeTemplate Template;

    `CREATE_X2MISSIONNARRATIVE_TEMPLATE(Template, 'DefaultMultiplayer');

    return Template;
}
