
class UIAlert extends UIX2SimpleScreen;

enum EAlertType
{
	eAlert_CouncilComm,
	eAlert_GOps,
	eAlert_Retaliation,
	eAlert_AlienFacility,
	eAlert_Control,
	eAlert_Doom,//5
	eAlert_HiddenDoom,
	eAlert_UFOInbound,
	eAlert_UFOEvaded,
	eAlert_Objective,
	eAlert_Contact, //10
	eAlert_Outpost,
	eAlert_ContactMade,
	eAlert_OutpostBuilt,
	eAlert_ContinentBonus,
	eAlert_BlackMarket,// 15
	eAlert_RegionUnlocked,
	eAlert_RegionUnlockedMission,

	eAlert_ResearchComplete,
	eAlert_ItemComplete,
	eAlert_ProvingGroundProjectComplete,//20
	eAlert_FacilityComplete,
	eAlert_UpgradeComplete,
	eAlert_ShadowProjectComplete,
	eAlert_ClearRoomComplete,
	eAlert_TrainingComplete,//25
	eAlert_SoldierPromoted,
	eAlert_PsiSoldierPromoted,

	eAlert_BuildSlotOpen,
	eAlert_ClearRoomSlotOpen,
	eAlert_StaffSlotOpen, // 30
	eAlert_BuildSlotFilled,
	eAlert_ClearRoomSlotFilled,
	eAlert_StaffSlotFilled,
	eAlert_SuperSoldier,

	eAlert_ResearchAvailable,
	eAlert_ItemAvailable,// 35
	eAlert_ItemReceived,
	eAlert_ItemUpgraded,
	eAlert_ProvingGroundProjectAvailable,
	eAlert_FacilityAvailable,
	eAlert_UpgradeAvailable,// 40
	eAlert_ShadowProjectAvailable,
	eAlert_NewStaffAvailable,

	eAlert_XCOMLives,
	eAlert_HelpContact,
	eAlert_HelpOutpost,// 45 
	eAlert_HelpResHQGoods,
	eAlert_HelpHavenOps,
	eAlert_HelpNewRegions,
	eAlert_HelpMissionLocked,

	eAlert_SoldierShaken,//50 
	eAlert_SoldierShakenRecovered,

	eAlert_NewScanningSite,
	eAlert_ScanComplete,

	eAlert_DarkEvent,

	eAlert_BlackMarketAvailable,//55 
	eAlert_ResourceCacheAvailable,
	eAlert_ResourceCacheComplete,

	eAlert_SupplyRaid,
	eAlert_LandedUFO,
	eAlert_CouncilMission,// 60

	eAlert_CustomizationsAvailable,
	eAlert_ForceUnderstrength,
	eAlert_MissionExpired,
	eAlert_WoundedSoldiersAllowed,
	eAlert_PsiTrainingComplete,//65 
	eAlert_TimeSensitiveMission,
	eAlert_PsiOperativeIntro,
	eAlert_WeaponUpgradesAvailable,
	eAlert_AlienVictoryImminent, // 69
	eAlert_InstantResearchAvailable,
	eAlert_NewStaffAvailableSmall,

	eAlert_LowIntel, // 72
	eAlert_LowSupplies,
	eAlert_LowScientists,
	eAlert_LowEngineers,
	eAlert_PsiLabIntro,
	eAlert_LowScientistsSmall,
	eAlert_LowEngineersSmall,
	eAlert_SupplyDropReminder,
	eAlert_PowerCoilShielded, // 80
	eAlert_StaffInfo,
	eAlert_ItemReceivedProvingGround,
	eAlert_LaunchMissionWarning,
};

struct TAlertCompletedInfo
{
	var String strName;
	var String strHeaderLabel;
	var String strBody;
	var String strHelp;
	var String strHeadImage1;
	var String strHeadImage2;
	var String strImage;
	var String strConfirm;
	var String strCarryOn;
	var EUIState eColor;
	var LinearColor clrAlert;
	var int Staff1ID;
	var int Staff2ID;
	var string strStaff1Title;
	var string strStaff2Title; 
	var string strHeaderIcon;
};

struct TAlertAvailableInfo
{
	var String strTitle;
	var String strName;
	var String strBody;
	var String strHelp;
	var String strImage;
	var String strConfirm;
	var EUIState eColor;
	var LinearColor clrAlert;
	var String strHeadImage1;
	var int Staff1ID;
	var string strStaff1Title;
	var string strHeaderIcon;
};

struct TAlertPOIAvailableInfo
{
	var Vector2D zoomLocation;
	var String strTitle;
	var String strLabel;
	var String strBody;
	var String strImage;
	var String strReport;
	var String strReward;
	var String strRewardIcon;
	var String strDurationLabel;
	var String strDuration;
	var String strInvestigate;
	var String strIgnore;
	var String strFlare;
	var String strUIIcon;
	var EUIState eColor;
	var LinearColor clrAlert;
};

struct TAlertHelpInfo
{
	var String strHeader;
	var String strTitle;
	var String strDescription;
	var String strImage;
	var String strConfirm;
	var String strCarryOn;
};

var public localized String m_strCouncilCommTitle;
var public localized String m_strCouncilCommConfirm;

var public localized String m_strCouncilMissionTitle;
var public localized String m_strCouncilMissionLabel;
var public localized String m_strCouncilMissionBody;
var public localized String m_strCouncilMissionFlare;
var public localized String m_strCouncilMissionConfirm;
var public localized String m_strCouncilMissionImage;

var public localized String m_strGOpsTitle;
var public localized String m_strGOpsTitle_Sing;
var public localized String m_strGOpsSubtitle;
var public localized String m_strGOpsBody;
var public localized String m_strGOpsBody_Sing;
var public localized String m_strGOpsFlare;
var public localized String m_strGOpsConfirm;
var public localized String m_strGOpsConfirm_Sing;
var public localized String m_strGOpsImage;

var public localized String m_strRetaliationTitle;
var public localized String m_strRetaliationLabel;
var public localized String m_strRetaliationBody;
var public localized String m_strRetaliationFlare;
var public localized String m_strRetaliationConfirm;
var public localized String m_strRetaliationImage;

var public localized String m_strSupplyRaidTitle;
var public localized String m_strSupplyRaidLabel;
var public localized String m_strSupplyRaidBody;
var public localized String m_strSupplyRaidFlare;
var public localized String m_strSupplyRaidConfirm;
var public localized String m_strSupplyRaidImage;
var public localized String m_strSupplyRaidHeader;

var public localized String m_strLandedUFOTitle;
var public localized String m_strLandedUFOLabel;
var public localized String m_strLandedUFOBody;
var public localized String m_strLandedUFOFlare;
var public localized String m_strLandedUFOConfirm;
var public localized String m_strLandedUFOImage;

var public localized String m_strFacilityTitle;
var public localized String m_strFacilityLabel;
var public localized String m_strFacilityBody;
var public localized String m_strFacilityConfirm;
var public localized String m_strFacilityImage;

var public localized String m_strControlLabel;
var public localized String m_strControlBody;
var public localized String m_strControlFlare;
var public localized String m_strControlConfirm;
var public localized String m_strControlImage;

var public localized String m_strDoomTitle;
var public localized String m_strDoomLabel;
var public localized String m_strDoomBody;
var public localized String m_strDoomConfirm;
var public localized String m_strDoomImage;
var public localized String m_strHiddenDoomLabel;
var public localized String m_strHiddenDoomBody;

var public localized String m_strUFOInboundTitle;
var public localized String m_strUFOInboundLabel;
var public localized String m_strUFOInboundBody;
var public localized String m_strUFOInboundConfirm;
var public localized String m_strUFOInboundImage;
var public localized String m_strUFOInboundDistanceLabel;
var public localized String m_strUFOInboundDistanceUnits;
var public localized String m_strUFOInboundSpeedLabel;
var public localized String m_strUFOInboundSpeedUnits;
var public localized String m_strUFOInboundTimeLabel;

var public localized String m_strUFOEvadedTitle;
var public localized String m_strUFOEvadedLabel;
var public localized String m_strUFOEvadedBody;
var public localized String m_strUFOEvadedConfirm;
var public localized String m_strUFOEvadedImage;

var public localized String m_strObjectiveTitle;
var public localized String m_strObjectiveFlare;
var public localized String m_strObjectiveTellMeMore;

var public localized String m_strContactTitle;
var public localized String m_strContactCostLabel;
var public localized String m_strContactCostHelp;
var public localized String m_strContactTimeLabel;
var public localized String m_strContactBody;
var public localized String m_strContactNeedResComms;
var public localized String m_strContactConfirm;
var public localized String m_strContactHelp;

var public localized String m_strOutpostTitle;
var public localized String m_strOutpostCostLabel;
var public localized String m_strOutpostTimeLabel;
var public localized String m_strOutpostBody;
var public localized String m_strOutpostConfirm;
var public localized String m_strOutpostReward;
var public localized String m_strOutpostHelp;

var public localized String m_strContactMadeTitle;
var public localized String m_strContactMadeIncome;
var public localized String m_strContactMadeBody;

var public localized String m_strOutpostBuiltTitle;
var public localized String m_strOutpostBuiltIncome;
var public localized String m_strOutpostBuiltBody;

var public localized String m_strContinentTitle;
var public localized String m_strContinentFlare;
var public localized String m_strContinentBonusLabel;

var public localized String m_strUnlockedLabel;
var public localized String m_strUnlockedBody;
var public localized String m_strFirstUnlockedBody;
var public localized String m_strUnlockedHelp;
var public localized String m_strUnlockedFlare;
var public localized String m_strUnlockedConfirm;
var public localized String m_strUnlockedImage;

var public localized String m_strPOITitle;
var public localized String m_strPOILabel;
var public localized String m_strPOIBody;
var public localized String m_strPOIReport;
var public localized String m_strPOIReward;
var public localized String m_strPOIDuration;
var public localized String m_strPOIFlare;
var public localized String m_strPOIInvestigate;
var public localized String m_strPOIImage;

var public localized String m_strPOICompleteLabel;
var public localized String m_strPOICompleteFlare;
var public localized String m_strPOIReturnToHQ;

var public localized String m_strResourceCacheAvailableTitle;
var public localized String m_strResourceCacheAvailableBody;

var public localized String m_strResourceCacheCompleteTitle;
var public localized String m_strResourceCacheCompleteLabel;
var public localized String m_strResourceCacheCompleteBody;
var public localized String m_strResourceCacheCompleteFlare;
var public localized String m_strResourceCacheCompleteImage;

var public localized String m_strBlackMarketAvailableBody;
var public localized String m_strBlackMarketDuration;
var public localized String m_strBlackMarketTitle;
var public localized String m_strBlackMarketLabel;
var public localized String m_strBlackMarketBody;
var public localized String m_strBlackMarketConfirm;
var public localized String m_strBlackMarketImage;
var public localized String m_strBlackMarketFooterLeft;
var public localized String m_strBlackMarketFooterRight;
var public localized String m_strBlackMarketLogoString;

// The Text that will fill out the header of the UIScreen when eAlert == eAlert_Objective.
var string				ObjectiveUIHeaderText;

// The Text that will fill out the body of the UIScreen when eAlert == eAlert_Objective.
var string				ObjectiveUIBodyText;

// The path to the image that will fill out the UIScreen when eAlert == eAlert_Objective.
var string				ObjectiveUIImagePath;

// The Text that will fill out the array of additional strings of the UIScreen when eAlert == eAlert_Objective.
var array<string>		ObjectiveUIArrayText;

var public localized String m_strResearchCompleteLabel;
var public localized String m_strResearchProjectComplete;
var public localized String m_strAssignNewResearch;
var public localized String m_strCarryOn;
var public localized String m_strResearchIntelReward;

var public localized String m_strShadowProjectCompleteLabel;
var public localized String m_strShadowProjectComplete;
var public localized String m_strViewReport;

var public localized String m_strItemCompleteLabel;
var public localized String m_strManufacturingComplete;
var public localized String m_strAssignNewProjects;

var public localized String m_strProvingGroundProjectCompleteLabel;
var public localized String m_strProvingGroundProjectComplete;

var public localized String m_strFacilityContructedLabel;
var public localized String m_strConstructionComplete;
var public localized String m_strAssignNewConstruction;
var public localized String m_strViewFacility;

var public localized String m_strUpgradeContructedLabel;
var public localized String m_strUpgradeComplete;
var public localized String m_strAssignNewUpgrade;

var public localized String m_strClearRoomCompleteLabel;
var public localized String m_strClearRoomComplete;
var public localized String m_strBuilderAvailable;
var public localized String m_strViewRoom;
var public localized String m_strClearRoomLoot;

var public localized String m_strTrainingCompleteLabel;
var public localized String m_strTrainingComplete;
var public localized String m_strSoldierPromoted;
var public localized String m_strPsiSoldierPromoted;
var public localized String m_strViewSoldier;
var public localized String m_strNewAbilityLabel;

var public localized String m_strPsiTrainingCompleteLabel;
var public localized String m_strPsiTrainingCompleteRank;
var public localized String m_strPsiTrainingCompleteHelp;
var public localized String m_strPsiTrainingComplete;
var public localized String m_strContinueTraining;

var public localized String m_strIntroToPsiLab;
var public localized String m_strIntroToPsiLabBody;

var public localized String m_strPsiOperativeIntroTitle;
var public localized String m_strPsiOperativeIntro;
var public localized String m_strPsiOperativeIntroHelp;

var public localized String m_strStaffSlotOpenLabel;
var public localized String m_strBuildStaffSlotOpen;
var public localized String m_strClearRoomStaffSlotOpen;
var public localized String m_strEngStaffSlotOpen;
var public localized String m_strSciStaffSlotOpen;
var public localized String m_strStaffSlotOpenBenefit;
var public localized String m_strDoctorHonorific;

var public localized String m_strStaffSlotFilledTitle;
var public localized String m_strStaffSlotFilledLabel;
var public localized String m_strClearRoomSlotFilledLabel;
var public localized String m_strClearRoomSlotFilled;
var public localized String m_strConstructionSlotFilledLabel;
var public localized String m_strConstructionSlotFilled;

var public localized String m_strAttentionCommander;
var public localized String m_strNewStaffAvailableTitle;
var public localized String m_strNewSoldierAvailableTitle;
var public localized String m_strNewSoldierAvailable;
var public localized String m_strNewSciAvailable;
var public localized String m_strNewEngAvailable;
var public localized String m_strNewStaffAvailableSlots;

var public localized String m_strStaffInfoTitle;
var public localized String m_strStaffInfoBonus;

var public localized String m_strNewResearchAvailable;
var public localized String m_strInstantResearchAvailable;
var public localized String m_strInstantResearchAvailableBody;
var public localized String m_strNewShadowProjectAvailable;
var public localized String m_strNewFacilityAvailable;
var public localized String m_strNewUpgradeAvailable;
var public localized String m_strNewItemAvailable;
var public localized String m_strNewItemReceived;
var public localized String m_strNewItemReceivedProvingGround;
var public localized String m_strItemReceivedInInventory;
var public localized String m_strNewItemUpgraded;
var public localized String m_strNewProvingGroundProjectAvailable;

var public localized String m_strSoldierShakenTitle;
var public localized String m_strSoldierShakenHeader;
var public localized String m_strSoldierShaken;
var public localized String m_strSoldierShakenHelp;

var public localized String m_strSoldierShakenRecoveredTitle;
var public localized String m_strSoldierShakenRecovered;
var public localized String m_strSoldierShakenRecoveredHelp;

var public localized String m_strDarkEventLabel;
var public localized String m_strDarkEventBody;

var public localized String m_strMissionExpiredLabel;
var public localized String m_strMissionExpiredFlare;
var public localized String m_strMissionExpiredLostContact;
var public localized String m_strMissionExpiredImage;

var public localized String m_strTimeSensitiveMissionLabel;
var public localized String m_strTimeSensitiveMissionText;
var public localized String m_strTimeSensitiveMissionFlare;
var public localized String m_strTimeSensitiveMissionImage;
var public localized String m_strFlyToMission;
var public localized String m_strSkipTimeSensitiveMission;

var public localized String m_strItemUnlock;
var public localized String m_strFacilityUnlock;
var public localized String m_strUpgradeUnlock;
var public localized String m_strResearchUnlock;
var public localized String m_strProjectUnlock;

var public localized String m_strWeaponUpgradesAvailableTitle;
var public localized String m_strWeaponUpgradesAvailableBody;

var public localized String m_strNewCustomizationsAvailableTitle;
var public localized String m_strNewCustomizationsAvailableBody;

var public localized String m_strForceUnderstrengthTitle;
var public localized String m_strForceUnderstrengthBody;

var public localized String m_strWoundedSoldiersAllowedTitle;
var public localized String m_strWoundedSoldiersAllowedBody;

var public localized String m_strAlienVictoryImminentTitle;
var public localized String m_strAlienVictoryImminentBody;
var public localized String m_strAlienVictoryImminentImage;

var public localized String m_strHelpResHQGoodsTitle;
var public localized String m_strHelpResHQGoodsHeader;
var public localized String m_strHelpResHQGoodsDescription;
var public localized String m_strHelpResHQGoodsImage;
var public localized String m_strRecruitNewStaff;

var public localized String m_strLowIntelTitle;
var public localized String m_strLowIntelHeader;
var public localized String m_strLowIntelDescription;
var public localized String m_strLowIntelBody;
var public localized String m_strLowIntelImage;
var public localized array<String> m_strLowIntelList;

var public localized String m_strLowSuppliesTitle;
var public localized String m_strLowSuppliesHeader;
var public localized String m_strLowSuppliesDescription;
var public localized String m_strLowSuppliesBody;
var public localized String m_strLowSuppliesImage;
var public localized array<String> m_strLowSuppliesList;

var public localized String m_strLowScientistsTitle;
var public localized String m_strLowScientistsHeader;
var public localized String m_strLowScientistsDescription;
var public localized String m_strLowScientistsBody;
var public localized String m_strLowScientistsImage;
var public localized array<String> m_strLowScientistsList;

var public localized String m_strLowEngineersTitle;
var public localized String m_strLowEngineersHeader;
var public localized String m_strLowEngineersDescription;
var public localized String m_strLowEngineersBody;
var public localized String m_strLowEngineersImage;
var public localized array<String> m_strLowEngineersList;

var public localized String m_strLowScientistsSmallTitle;
var public localized String m_strLowScientistsSmallBody;

var public localized String m_strLowEngineersSmallTitle;
var public localized String m_strLowEngineersSmallBody;

var public localized String m_strSupplyDropReminderTitle;
var public localized String m_strSupplyDropReminderBody;

var public localized String m_strPowerCoilShieldedTitle;
var public localized String m_strPowerCoilShieldedBody;
var public localized array<String> m_strPowerCoilShieldedList;

var public localized String m_strLaunchMissionWarningHeader;
var public localized String m_strLaunchMissionWarningTitle;

var EAlertType eAlert;
var XComGameState_MissionSite Mission;
var StaffUnitInfo UnitInfo;
var array<StaffUnitInfo> BuilderInfoList;
var StateObjectReference RoomRef;
var StateObjectReference FacilityRef;
var StateObjectReference RegionRef;
var StateObjectReference ContinentRef;
var StateObjectReference TechRef;
var StateObjectReference DarkEventRef;
var StateObjectReference POIRef;
var StateObjectReference UFORef;
var X2SpecialRoomFeatureTemplate SpecialRoomFeatureTemplate;
var X2FacilityTemplate FacilityTemplate;
var X2FacilityUpgradeTemplate UpgradeTemplate;
var X2StaffSlotTemplate StaffSlotTemplate;
var X2ItemTemplate ItemTemplate;
var X2AbilityTemplate AbilityTemplate;
var bool bAlertTransitionsToMission; // Flag if the alert will transition to mission blades, which will restore the camera when they are closed
var bool bRestoreCameraPosition; // Flag for when an alert should restore the camera to a saved position when it is closed
var bool bRestoreCameraPositionOnReceiveFocus; // Flag for when an alert should restore the camera when it receives focus (only used for TellMeMore)
var delegate<AlertCallback> fnCallback;
var Texture2D StaffPicture;

var string SoundToPlay;
var bool bSoundPlayed;

var name EventToTrigger;
var Object EventData;
var bool bEventTriggered;

var bool bInstantInterp;

var UIPanel LibraryPanel, ButtonGroup;
var UIButton Button1, Button2;

delegate AlertCallback(eUIAction eAction, UIAlert AlertData, optional bool bInstant = false);
delegate OnClickedDelegate(UIButton Button);

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	BuildAlert();
}

simulated function OnInit()
{
	local XComGameState NewGameState;

	super.OnInit();

	if (Movie.Pres.ScreenStack.IsTopScreen(self))
	{
		PlaySFX(SoundToPlay);
		bSoundPlayed = true;
		
		if (EventToTrigger != '')
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("New Popup Event");
			`XEVENTMGR.TriggerEvent(EventToTrigger, EventData, EventData, NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			bEventTriggered = true;
		}
	}
}

simulated function BuildAlert()
{
	BindLibraryItem();

	switch( eAlert )
	{
	case eAlert_CouncilComm:
		BuildCouncilCommAlert();
		break;
	case eAlert_GOps:
		BuildGOpsAlert();
		break;
	case eAlert_CouncilMission:
		BuildCouncilMissionAlert();
		break;
	case eAlert_Retaliation:
		BuildRetaliationAlert();
		break;
	case eAlert_SupplyRaid:
		BuildSupplyRaidAlert();
		break;
	case eAlert_LandedUFO:
		BuildLandedUFOAlert();
		break;
	case eAlert_AlienFacility:
		BuildFacilityAlert();
		break;
	case eAlert_Control:
		BuildControlAlert();
		break;
	case eAlert_Doom:
		BuildDoomAlert();
		break;
	case eAlert_HiddenDoom:
		BuildHiddenDoomAlert();
		break;
	case eAlert_UFOInbound:
		BuildUFOInboundAlert();
		break;
	case eAlert_UFOEvaded:
		BuildUFOEvadedAlert();
		break;
	case eAlert_Objective:
		BuildObjectiveAlert();
		break;
	case eAlert_Contact:
		BuildContactAlert();
		break;
	case eAlert_Outpost:
		BuildOutpostAlert();
		break;
	case eAlert_ContactMade:
		BuildContactMadeAlert();
		break;
	case eAlert_OutpostBuilt:
		BuildOutpostBuiltAlert();
		break;
	case eAlert_ContinentBonus:
		BuildContinentAlert();
		break;
	case eAlert_RegionUnlocked:
	case eAlert_RegionUnlockedMission:
		BuildRegionUnlockedAlert();
		break;
	case eAlert_BlackMarketAvailable:
		BuildBlackMarketAvailableAlert();
		break;
	case eAlert_BlackMarket:
		BuildBlackMarketAlert();
		break;
	case eAlert_ResearchComplete:
		BuildResearchCompleteAlert();
		break;
	case eAlert_ItemComplete:
		BuildItemCompleteAlert();
		break;
	case eAlert_ProvingGroundProjectComplete:
		BuildProvingGroundProjectCompleteAlert();
		break;
	case eAlert_FacilityComplete:
		BuildFacilityCompleteAlert();
		break;
	case eAlert_UpgradeComplete:
		BuildUpgradeCompleteAlert();
		break;
	case eAlert_ShadowProjectComplete:
		BuildShadowProjectCompleteAlert();
		break;
	case eAlert_ClearRoomComplete:
		BuildClearRoomCompleteAlert();
		break;
	case eAlert_TrainingComplete:
		BuildTrainingCompleteAlert(m_strTrainingCompleteLabel);
		break;
	case eAlert_SoldierPromoted:
		BuildTrainingCompleteAlert(m_strSoldierPromoted);
		break;
	case eAlert_PsiTrainingComplete:
		BuildPsiTrainingCompleteAlert(m_strPsiTrainingCompleteLabel);
		break;
	case eAlert_PsiSoldierPromoted:
		BuildPsiTrainingCompleteAlert(m_strPsiSoldierPromoted);
		break;
	case eAlert_PsiLabIntro:
		BuildPsiLabIntroAlert();
		break;
	case eAlert_PsiOperativeIntro:
		BuildPsiOperativeIntroAlert();
		break;
	case eAlert_BuildSlotOpen:
		BuildConstructionSlotOpenAlert();
		break;
	case eAlert_ClearRoomSlotOpen:
		BuildClearRoomSlotOpenAlert();
		break;
	case eAlert_StaffSlotOpen:
		BuildStaffSlotOpenAlert();
		break;
	case eAlert_BuildSlotFilled:
		BuildConstructionSlotFilledAlert();
		break;
	case eAlert_ClearRoomSlotFilled:
		BuildClearRoomSlotFilledAlert();
		break;
	case eAlert_StaffSlotFilled:
		BuildStaffSlotFilledAlert();
		break;
	case eAlert_SuperSoldier:
		BuildSuperSoldierAlert();
		break;
	case eAlert_ResearchAvailable:
		BuildResearchAvailableAlert();
		break;
	case eAlert_InstantResearchAvailable:
		BuildInstantResearchAvailableAlert();
		break;
	case eAlert_ItemAvailable:
		BuildItemAvailableAlert();
		break;
	case eAlert_ItemReceived:
		BuildItemReceivedAlert();
		break;
	case eAlert_ItemReceivedProvingGround:
		BuildItemReceivedProvingGroundAlert();
		break;
	case eAlert_ItemUpgraded:
		BuildItemUpgradedAlert();
		break;
	case eAlert_ProvingGroundProjectAvailable:
		BuildProvingGroundProjectAvailableAlert();
		break;
	case eAlert_FacilityAvailable:
		BuildFacilityAvailableAlert();
		break;
	case eAlert_UpgradeAvailable:
		BuildUpgradeAvailableAlert();
		break;
	case eAlert_ShadowProjectAvailable:
		BuildShadowProjectAvailableAlert();
		break;
	case eAlert_NewStaffAvailable:
	case eAlert_NewStaffAvailableSmall:
		BuildNewStaffAvailableAlert();
		break;
	case eAlert_StaffInfo:
		BuildStaffInfoAlert();
		break;

	case eAlert_SoldierShaken:
		BuildSoldierShakenAlert();
		break;
	case eAlert_SoldierShakenRecovered:
		BuildSoldierShakenRecoveredAlert();
		break;
	case eAlert_WeaponUpgradesAvailable:
		BuildWeaponUpgradesAvailableAlert();
		break;
	case eAlert_CustomizationsAvailable:
		BuildSoldierCustomizationsAvailableAlert();
		break;
	case eAlert_ForceUnderstrength:
		BuildForceUnderstrengthAlert();
		break;
	case eAlert_WoundedSoldiersAllowed:
		BuildWoundedSoldiersAllowedAlert();
		break;

	case eAlert_HelpResHQGoods:
		BuildHelpResHQGoodsAlert();
		break;

	case eAlert_NewScanningSite:
		BuildPointOfInterestAlert();
		break;
	case eAlert_ScanComplete:
		BuildPointOfInterestCompleteAlert();
		break;
	case eAlert_ResourceCacheAvailable:
		BuildResourceCacheAvailableAlert();
		break;
	case eAlert_ResourceCacheComplete:
		BuildResourceCacheCompleteAlert();
		break;
	case eAlert_DarkEvent:
		BuildDarkEventAlert();
		break;
	case eAlert_MissionExpired:
		BuildMissionExpiredAlert();
		break;
	case eAlert_TimeSensitiveMission:
		BuildTimeSensitiveMissionAlert();
		break;
	case eAlert_AlienVictoryImminent:
		BuildAlienVictoryImminentAlert();
		break;

	case eAlert_LowIntel:
		BuildLowIntelAlert();
		break;
	case eAlert_LowSupplies:
		BuildLowSuppliesAlert();
		break;
	case eAlert_LowScientists:
		BuildLowScientistsAlert();
		break;
	case eAlert_LowEngineers:
		BuildLowEngineersAlert();
		break;
	case eAlert_LowScientistsSmall:
		BuildLowScientistsSmallAlert();
		break;
	case eAlert_LowEngineersSmall:
		BuildLowEngineersSmallAlert();
		break;
	case eAlert_SupplyDropReminder:
		BuildSupplyDropReminderAlert();
		break;
	case eAlert_PowerCoilShielded:
		BuildPowerCoilShieldedAlert();
		break;
	case eAlert_LaunchMissionWarning:
		BuildLaunchMissionWarningAlert();
		break;

	default:
		AddBG(MakeRect(0, 0, 1000, 500), eUIState_Normal).SetAlpha(0.75f);
		break;
	}

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
}

simulated function BindLibraryItem()
{
	local Name AlertLibID;

	AlertLibID = GetLibraryID();
	if( AlertLibID != '' )
	{
		LibraryPanel = Spawn(class'UIPanel', self);
		LibraryPanel.bAnimateOnInit = false; 
		LibraryPanel.InitPanel('AlertLibraryPanel', AlertLibID);
		LibraryPanel.SetSelectedNavigation();

		ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
		ButtonGroup.bAnimateOnInit = false;
		ButtonGroup.bCascadeFocus = false;
		ButtonGroup.InitPanel('ButtonGroup', '');
		ButtonGroup.SetSelectedNavigation();

		Button1 = Spawn(class'UIButton', ButtonGroup);
		Button1.bAnimateOnInit = false;
		Button1.SetResizeToText(false);
		Button1.InitButton('Button0', "", OnConfirmClicked);

		Button2 = Spawn(class'UIButton', ButtonGroup);
		Button2.bAnimateOnInit = false; 
		Button2.SetResizeToText(false);
		Button2.InitButton('Button1', "", OnCancelClicked);
		
		//TODO: bsteiner: remove this when the strategy map handles it's own visibility
		`HQPRES.StrategyMap2D.Hide();
	}
}

simulated function Name GetLibraryID()
{
	//This gets the Flash library name to load in a panel. No name means no library asset yet. 
	switch( eAlert )
	{
	case eAlert_CouncilComm:					return 'Alert_CouncilReport';
	case eAlert_GOps:							return 'Alert_GuerrillaOpsSplash';
	case eAlert_CouncilMission:					return 'Alert_CouncilMissionSplash';
	case eAlert_Retaliation:					return 'Alert_RetaliationSplash'; 
	case eAlert_SupplyRaid:						return 'Alert_SupplyRaidSplash';
	case eAlert_LandedUFO:						return 'Alert_SupplyRaidSplash';
	case eAlert_AlienFacility:					return 'Alert_AlienSplash';
	case eAlert_Control:						return ''; //Deprecated?
	case eAlert_Doom:							return 'Alert_AlienSplash';
	case eAlert_HiddenDoom:						return 'Alert_AlienSplash';
	case eAlert_UFOInbound:						return 'Alert_AlienSplash';
	case eAlert_UFOEvaded:						return 'Alert_AlienSplash';
	case eAlert_Objective:						return 'Alert_NewObjective';
	case eAlert_Contact:						return 'Alert_MakeContact';
	case eAlert_Outpost:						return 'Alert_MakeContact';
	case eAlert_ContactMade:					return 'Alert_ContactMade';
	case eAlert_OutpostBuilt:					return 'Alert_ContactMade';
	case eAlert_ContinentBonus:					return 'Alert_NewRegion';
	case eAlert_RegionUnlocked:					return 'Alert_NewRegion';
	case eAlert_RegionUnlockedMission:			return ''; //Deprecated?
	case eAlert_BlackMarketAvailable:			return 'Alert_POI';
	case eAlert_BlackMarket:					return 'Alert_BlackMarket';

	case eAlert_ResearchComplete:				return 'Alert_Complete';
	case eAlert_ItemComplete:					return 'Alert_Complete';
	case eAlert_ProvingGroundProjectComplete:	return 'Alert_Complete';
	case eAlert_FacilityComplete:				return 'Alert_Complete';
	case eAlert_UpgradeComplete:				return 'Alert_Complete';
	case eAlert_ShadowProjectComplete:			return 'Alert_Complete';
	case eAlert_ClearRoomComplete:				return 'Alert_Complete';
	case eAlert_TrainingComplete:				return 'Alert_TrainingComplete';
	case eAlert_PsiTrainingComplete:			return 'Alert_TrainingComplete';
	case eAlert_SoldierPromoted:				return 'Alert_TrainingComplete';
	case eAlert_PsiSoldierPromoted:				return 'Alert_TrainingComplete';
	case eAlert_PsiLabIntro:					return 'Alert_ItemAvailable';
	case eAlert_PsiOperativeIntro:				return 'Alert_AssignStaff';

	case eAlert_BuildSlotOpen:					return 'Alert_OpenStaff';
	case eAlert_ClearRoomSlotOpen:				return 'Alert_OpenStaff';
	case eAlert_StaffSlotOpen:					return 'Alert_OpenStaff';
	case eAlert_BuildSlotFilled:				return 'Alert_AssignStaff';
	case eAlert_ClearRoomSlotFilled:			return 'Alert_AssignStaff';
	case eAlert_StaffSlotFilled:				return 'Alert_AssignStaff';
	case eAlert_SuperSoldier:                   return 'Alert_AssignStaff';

	case eAlert_ResearchAvailable:				return 'Alert_ItemAvailable';
	case eAlert_InstantResearchAvailable:		return 'Alert_ItemAvailable';
	case eAlert_ItemAvailable:					return 'Alert_ItemAvailable';

	case eAlert_ItemReceived:					return 'Alert_ItemAvailable';
	case eAlert_ItemReceivedProvingGround:		return 'Alert_ProvingGroundAvailable';
	case eAlert_ItemUpgraded:					return 'Alert_ItemAvailable';

	case eAlert_ProvingGroundProjectAvailable:	return 'Alert_ItemAvailable';
	case eAlert_FacilityAvailable:				return 'Alert_ItemAvailable';
	case eAlert_UpgradeAvailable:				return 'Alert_ItemAvailable';
	case eAlert_ShadowProjectAvailable:			return 'Alert_ItemAvailable';//'Alert_ShadowChamberAvailable';
	case eAlert_NewStaffAvailable:				return 'Alert_NewStaff';
	case eAlert_NewStaffAvailableSmall:			return 'Alert_NewStaffSmall';
	case eAlert_StaffInfo:						return 'Alert_NewStaff';

	case eAlert_XCOMLives:						return 'Alert_Help';

	case eAlert_HelpContact:					return 'Alert_Help';
	case eAlert_HelpOutpost:					return 'Alert_Help';
	case eAlert_HelpNewRegions:					return 'Alert_Help';
	case eAlert_HelpResHQGoods:					return 'Alert_Help';
	case eAlert_HelpHavenOps:					return 'Alert_Help';
	case eAlert_HelpMissionLocked:				return 'Alert_Help';

	case eAlert_SoldierShaken:					return 'Alert_AssignStaff';
	case eAlert_SoldierShakenRecovered:			return 'Alert_AssignStaff';
	case eAlert_WeaponUpgradesAvailable:		return 'Alert_ItemAvailable';
	case eAlert_CustomizationsAvailable:		return 'Alert_XComGeneric';
	case eAlert_ForceUnderstrength:				return 'Alert_XComGeneric';
	case eAlert_WoundedSoldiersAllowed:			return 'Alert_XComGeneric';

	case eAlert_NewScanningSite:				return 'Alert_POI';
	case eAlert_ScanComplete:					return 'Alert_POI';
	case eAlert_ResourceCacheAvailable:			return 'Alert_POI';
	case eAlert_ResourceCacheComplete:			return 'Alert_POI';
	case eAlert_DarkEvent:						return 'Alert_DarkEventActive';
	case eAlert_MissionExpired:					return 'Alert_AlienSplash';
	case eAlert_TimeSensitiveMission:			return 'Alert_AlienSplash';
	case eAlert_AlienVictoryImminent:			return 'Alert_AlienSplash';

	case eAlert_LowIntel:						return 'Alert_Warning';
	case eAlert_LowSupplies:					return 'Alert_Warning';
	case eAlert_LowScientists:					return 'Alert_Warning';
	case eAlert_LowEngineers:					return 'Alert_Warning';
	case eAlert_LowScientistsSmall:				return 'Alert_XComGeneric';
	case eAlert_LowEngineersSmall:				return 'Alert_XComGeneric';
	case eAlert_SupplyDropReminder:				return 'Alert_XComGeneric';
	case eAlert_PowerCoilShielded:				return 'Alert_XComGeneric';
	case eAlert_LaunchMissionWarning:			return 'Alert_XComGeneric';

	default:
		return ''; 
	}
}
simulated function RefreshNavigation()
{
	if( Button1.IsVisible() )
	{
		ButtonGroup.Navigator.SetSelected(Button1);
	}
	else
	{
		Button1.DisableNavigation();
		ButtonGroup.Navigator.SetSelected(Button2);
	}

	if( !Button2.IsVisible() )
	{
		Button2.DisableNavigation();
	}
}

simulated function BuildCouncilCommAlert() 
{
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strCouncilCommTitle);
	LibraryPanel.MC.QueueString(m_strCouncilCommConfirm);
	LibraryPanel.MC.EndOp();

	Button2.Hide();
}

simulated function BuildGOpsAlert()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local int MissionCount;
	local bool bMultipleMissions;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	History = `XCOMHISTORY;
	MissionCount = 0;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_GuerillaOp' && MissionState.Available)
		{
			MissionCount++;
		}
	}

	bMultipleMissions = (MissionCount > 1);
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateGuerrillaOpsSplash");
	LibraryPanel.MC.QueueString(bMultipleMissions ? m_strGOpsTitle : m_strGOpsTitle_Sing);
	LibraryPanel.MC.QueueString(m_strGOpsSubtitle);
	LibraryPanel.MC.QueueString(bMultipleMissions ? m_strGOpsBody : m_strGOpsBody_Sing);
	LibraryPanel.MC.QueueString(m_strGOpsImage);
	LibraryPanel.MC.QueueString(bMultipleMissions ? m_strGOpsConfirm : m_strGOpsConfirm_Sing);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

	if(!class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape'))
	{
		Button2.Hide();
	}
}

simulated function Hide()
{
	super.Hide();
}

simulated function BuildCouncilMissionAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateCouncilSplashData");
	LibraryPanel.MC.QueueString(m_strCouncilMissionTitle);
	LibraryPanel.MC.QueueString(m_strCouncilMissionLabel);
	LibraryPanel.MC.QueueString(m_strCouncilMissionBody);
	LibraryPanel.MC.QueueString(m_strCouncilMissionFlare);
	LibraryPanel.MC.QueueString(m_strCouncilMissionConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

}

simulated function BuildRetaliationAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateRetaliationSplash");
	LibraryPanel.MC.QueueString(m_strRetaliationTitle);
	LibraryPanel.MC.QueueString(m_strRetaliationLabel);
	LibraryPanel.MC.QueueString(m_strRetaliationBody);
	LibraryPanel.MC.QueueString(m_strRetaliationFlare);
	LibraryPanel.MC.QueueString(m_strRetaliationImage);
	LibraryPanel.MC.QueueString(m_strRetaliationConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildSupplyRaidAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateSupplyRaidSplashData");
	LibraryPanel.MC.QueueString(m_strSupplyRaidHeader);
	LibraryPanel.MC.QueueString(m_strSupplyRaidTitle);
	LibraryPanel.MC.QueueString(m_strSupplyRaidBody);
	LibraryPanel.MC.QueueString(m_strSupplyRaidImage);
	LibraryPanel.MC.QueueString(m_strSupplyRaidFlare);
	LibraryPanel.MC.QueueString(m_strSupplyRaidConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildLandedUFOAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateSupplyRaidSplashData");
	LibraryPanel.MC.QueueString(m_strLandedUFOLabel);
	LibraryPanel.MC.QueueString(m_strLandedUFOTitle);
	LibraryPanel.MC.QueueString(m_strLandedUFOBody);
	LibraryPanel.MC.QueueString(m_strLandedUFOImage);
	LibraryPanel.MC.QueueString(m_strLandedUFOFlare);
	LibraryPanel.MC.QueueString(m_strLandedUFOConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildFacilityAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	BuildAlienSplashAlert(m_strFacilityTitle, m_strFacilityLabel, m_strFacilityBody, m_strFacilityImage, m_strFacilityConfirm, m_strOK);
}

// UFO inbound, doom generation, alien facility, UFO active, alien facility constructed, and any other negative generic popup needed 
function BuildAlienSplashAlert(String strHeader, String strTitle, String strDescription, String strImage, String strButton1Label, String strButton2Label)
{
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(strHeader);
	LibraryPanel.MC.QueueString(strTitle);
	LibraryPanel.MC.QueueString(strDescription);
	LibraryPanel.MC.QueueString(strImage);
	LibraryPanel.MC.QueueString(strButton1Label);
	LibraryPanel.MC.QueueString(strButton2Label);
	LibraryPanel.MC.EndOp();

	if( strButton2Label == "" )
		Button2.Hide();
}


simulated function XComGameState_WorldRegion GetRegion()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));
}

simulated function BuildControlAlert()
{
	local TRect rAlert, rPos;
	local LinearColor clrControl;
	local String strControl;
	local XGParamTag ParamTag;

	clrControl = MakeLinearColor(0.75, 0.0, 0, 1);

	// Save Camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f);
	}

	// BG
	rAlert = AnchorRect(MakeRect(0, 0, 750, 600), eRectAnchor_Center);
	rPos = VSubRect(rAlert, 0, 0.15f);
	AddBG(rPos, eUIState_Warning);

	// Header
	rPos = VSubRect(rAlert, 0, 0.15f);
	AddHeader(rPos, class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName), clrControl, m_strControlLabel);

	// Image
	rPos = VSubRect(rAlert, 0.15f, 0.8f);
	rPos = HSubRect(rPos, 0.0f, 0.6f);
	AddBG(rPos, eUIState_Warning);

	rPos = VSubRect(rAlert, 0.3f, 0.7f);
	rPos = HSubRect(rPos, 0.0f, 0.6f);
	AddImage(rPos, m_strControlImage, eUIState_Bad);

	rPos = VSubRect(rAlert, 0.15f, 0.8f);
	rPos = HSubRect(rPos, 0.6f, 1.0f);
	AddBG(rPos, eUIState_Warning);
	
	// OK Button
	rPos = VSubRect(rAlert, 0.45f, 0.55f);
	rPos = HSubRect(rPos, 0.7f, 0.8f);
	AddButton(rPos, m_strOK, OnCancelClicked);

	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	strControl = `XEXPAND.ExpandString(m_strControlBody);

	rPos = VSubRect(rAlert, 0.7, 1.0f);
	AddBG(rPos, eUIState_Warning);
	AddText(rPos, strControl);

	//Flare Left
	rPos = MakeRect(0, 1080 / 2 - 50 / 2, rAlert.fLeft, 50);
	AddBG(rPos, eUIState_Warning).SetAlpha(0.5f);
	AddHeader(rPos, m_strControlFlare, clrControl);

	//Flare Right
	rPos = MakeRect(rAlert.fRight, 1080 / 2 - 50 / 2, 1920 - rAlert.fRight, 50);
	AddBG(rPos, eUIState_Warning).SetAlpha(0.5f);
	AddHeader(rPos, m_strControlFlare, clrControl);
}
simulated function BuildDoomAlert()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;

	// Save camera
	bAlertTransitionsToMission = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	BuildAlienSplashAlert(m_strDoomTitle, `XEXPAND.ExpandString(m_strDoomLabel), `XEXPAND.ExpandString(m_strDoomBody), m_strDoomImage, m_strDoomConfirm, m_strIgnore);
}
simulated function BuildHiddenDoomAlert()
{
	BuildAlienSplashAlert(m_strDoomTitle, m_strHiddenDoomLabel, m_strHiddenDoomBody, m_strDoomImage, m_strAccept, "");
}
simulated function BuildUFOInboundAlert()
{
	local XComGameState_UFO UFOState;
	local String strBody, strStats;

	UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(UFORef.ObjectID));
	
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Stat Text
	strStats $= m_strUFOInboundDistanceLabel @ UFOState.GetDistanceToAvenger() @ m_strUFOInboundDistanceUnits $ "\n";
	strStats $= m_strUFOInboundSpeedLabel @ UFOState.GetInterceptionSpeed() @ m_strUFOInboundSpeedUnits $ "\n";
	strStats $= m_strUFOInboundTimeLabel @ UFOState.GetTimeToIntercept();
	strBody = m_strUFOInboundBody $ "\n\n" $ strStats;

	BuildAlienSplashAlert(m_strUFOInboundTitle, m_strUFOInboundLabel, strBody, m_strUFOInboundImage, m_strUFOInboundConfirm, "");
}

simulated function BuildUFOEvadedAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	BuildAlienSplashAlert(m_strUFOEvadedTitle, m_strUFOEvadedLabel, m_strUFOEvadedBody, m_strUFOEvadedImage, m_strUFOEvadedConfirm, m_strIgnore);
}

simulated function BuildObjectiveAlert()
{
	local string SubObjectives;
	local int iSubObj;
	//local XComGameState NewGameState;
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Can only be used to trigger voice only lines
	XComHQPresentationLayer(Movie.Pres).UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.Avenger_Objective_Added');
	//NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Narrative UI Closed");
	//`XEVENTMGR.TriggerEvent('NarrativeUICompleted', , , NewGameState);
	//`GAMERULES.SubmitGameState(NewGameState);

	// Subobjectives
	for( iSubObj = 0; iSubObj < ObjectiveUIArrayText.Length; iSubObj++ )
	{
		SubObjectives $= "-" @ ObjectiveUIArrayText[iSubObj] $ "\n";
	}
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strObjectiveFlare);
	LibraryPanel.MC.QueueString(m_strObjectiveTitle);
	LibraryPanel.MC.QueueString(ObjectiveUIHeaderText);
	LibraryPanel.MC.QueueString(ObjectiveUIBodyText);
	LibraryPanel.MC.QueueString(SubObjectives);
	LibraryPanel.MC.QueueString(class'UIUtilities_Image'.const.MissionObjective_GoldenPath);
	LibraryPanel.MC.QueueString(ObjectiveUIImagePath);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strObjectiveTellMeMore);
	LibraryPanel.MC.EndOp();
	
	Button2.OnClickedDelegate = TellMeMore;

	// Don't show the Tell Me More button if tutorial is active
	if (class'UIUtilities_Strategy'.static.GetXComHQ().AnyTutorialObjectivesInProgress())
	{
		Button2.Hide();
	}
}

simulated function String GetDateString()
{
	return class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`GAME.GetGeoscape().m_kDateTime);
}
simulated static function array<String> GetItemUnlockStrings(array<X2ItemTemplate> arrNewItems)
{
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for( i = 0; i < arrNewItems.Length; i++ )
	{
		ParamTag.StrValue0 = arrNewItems[i].GetItemFriendlyName(, false);
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strItemUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetFacilityUnlockStrings(array<X2FacilityTemplate> arrNewFacilities)
{
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for( i = 0; i < arrNewFacilities.Length; i++ )
	{
		ParamTag.StrValue0 = arrNewFacilities[i].DisplayName;
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strFacilityUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetUpgradeUnlockStrings(array<X2FacilityUpgradeTemplate> arrNewUpgrades)
{
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for (i = 0; i < arrNewUpgrades.Length; i++)
	{
		ParamTag.StrValue0 = arrNewUpgrades[i].DisplayName;
		ParamTag.StrValue1 = arrNewUpgrades[i].FacilityName;
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strUpgradeUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetResearchUnlockStrings(array<StateObjectReference> arrNewTechs)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for( i = 0; i < arrNewTechs.Length; i++ )
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(arrNewTechs[i].ObjectID));
		ParamTag.StrValue0 = TechState.GetDisplayName();
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strResearchUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetProjectUnlockStrings(array<StateObjectReference> arrNewProjects)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState; 
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for (i = 0; i < arrNewProjects.Length; i++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(arrNewProjects[i].ObjectID));
		ParamTag.StrValue0 = TechState.GetDisplayName();
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strProjectUnlock));
	}

	return arrStrings;
}
//simulated function String GetObjectiveTitle()
//{
//	return "OBJECTIVE TITLE";
//}
//simulated function String GetObjectiveImage()
//{
//	return "img:///UILibrary_ProtoImages.Proto_AlienBase";
//}
//simulated function String GetObjectiveDesc()
//{
//	return "Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description.";
//}
//
//simulated function array<String> GetSubObjectives()
//{
//	local array<String> arrSubobjectives;
//
//	arrSubobjectives.AddItem("Subobjective 1");
//	arrSubobjectives.AddItem("Subobjective 2");
//	arrSubobjectives.AddItem("Subobjective 3");
//	arrSubobjectives.AddItem("Subobjective 4");
//	arrSubobjectives.AddItem("Subobjective 5");
//
//	return arrSubobjectives;
//}

simulated function BuildContactAlert()
{
	local bool bCanAfford;
	local string ContactCost;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;	
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f);
	}
	
	bCanAfford = CanAffordContact();
	ContactCost = GetContactCostString();
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strContactTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	
	LibraryPanel.MC.QueueString(m_strContactCostLabel);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(ContactCost, bCanAfford ? eUIState_Normal : eUIState_Bad));
	LibraryPanel.MC.QueueString(GetContactCostHelp());
	
	LibraryPanel.MC.QueueString(GetContactTimeLabel());
	LibraryPanel.MC.QueueString(GetContactTimeString());

	LibraryPanel.MC.QueueString(GetContactBody());
	LibraryPanel.MC.QueueString(m_strContactHelp);
	LibraryPanel.MC.QueueString(m_strContactConfirm);
	LibraryPanel.MC.QueueString(m_strCancel);
	LibraryPanel.MC.EndOp();
	
	Button1.SetDisabled(!bCanAfford || !CanMakeContact());
}

simulated function String GetContactCostHelp()
{
	local XGParamTag ParamTag;
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = GetRegion().ContactIntelCost[`DIFFICULTYSETTING];

	return `XEXPAND.ExpandString(m_strContactCostHelp);
}
simulated function String GetContactCostString()
{
	return class'UIUtilities_Strategy'.static.GetStrategyCostString(GetRegion().CalcContactCost(), GetRegion().ContactCostScalars);
}
simulated function bool CanAffordContact()
{
	return XCOMHQ().CanAffordAllStrategyCosts(GetRegion().CalcContactCost(), GetRegion().ContactCostScalars);
}
simulated function bool CanMakeContact()
{
	return (XCOMHQ().GetRemainingContactCapacity() > 0);
}
simulated function String GetContactTimeLabel()
{
	return m_strContactTimeLabel;
}
simulated function String GetContactTimeString()
{
	local int iMinDays, iMaxDays;

	GetRegion().MakeContactETA(iMinDays, iMaxDays);

	if (iMinDays == iMaxDays)
		return iMinDays@m_strDays;
	else
		return iMinDays@"-"@iMaxDays@m_strDays;
}
simulated function String GetContactBody()
{
	local XGParamTag ParamTag;
	local string ContactBody;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	ParamTag.IntValue0 = GetRegion().GetSupplyDropReward(true);
	ContactBody = `XEXPAND.ExpandString(m_strContactBody);

	if (!CanMakeContact())
		ContactBody $= "\n" $ class'UIUtilities_Text'.static.GetColoredText(m_strContactNeedResComms, eUIState_Bad);

	return ContactBody;
}

simulated function BuildOutpostAlert()
{
	local bool bCanAfford; 
	local string OutpostCost; 

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f);
	}

	bCanAfford = XCOMHQ().CanAffordAllStrategyCosts(GetRegion().CalcOutpostCost(), GetRegion().OutpostCostScalars);
	OutpostCost = class'UIUtilities_Strategy'.static.GetStrategyCostString(GetRegion().CalcOutpostCost(), GetRegion().OutpostCostScalars);
	
	//--------------------- 

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strOutpostTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	
	LibraryPanel.MC.QueueString(m_strContactCostLabel); //reusing string here.
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(OutpostCost, bCanAfford ? eUIState_Normal : eUIState_Bad));
	LibraryPanel.MC.QueueString("");
	
	LibraryPanel.MC.QueueString(m_strOutpostTimeLabel);
	LibraryPanel.MC.QueueString(GetOutpostTimeString());

	LibraryPanel.MC.QueueString(GetOutpostBody());
	LibraryPanel.MC.QueueString(m_strOutpostHelp);
	LibraryPanel.MC.QueueString(m_strOutpostConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

	Button1.SetDisabled(!bCanAfford);

	//--------------------- 

	//LibraryPanel.MC.BeginFunctionOp("UpdateReward");
	//LibraryPanel.MC.QueueString(m_strReward);
	//LibraryPanel.MC.EndOp();
}

simulated function String GetOutpostTimeString()
{
	local int iMinDays, iMaxDays;

	GetRegion().BuildHavenETA(iMinDays, iMaxDays);

	if (iMinDays == iMaxDays)
		return iMinDays@m_strDays;
	else
		return iMinDays@"-"@iMaxDays@m_strDays;
}
simulated function String GetOutpostBody()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	ParamTag.IntValue0 = GetRegion().GetSupplyDropReward(,true);
	return `XEXPAND.ExpandString(m_strOutpostBody);
}

simulated function BuildContactMadeAlert()
{
	local String strContact;
	local XGParamTag ParamTag;
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if( bInstantInterp )
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f);
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	strContact = `XEXPAND.ExpandString(m_strContactMadeBody);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strContactMadeTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strContact);
	LibraryPanel.MC.QueueString(m_strContactMadeIncome);
	LibraryPanel.MC.QueueString(GetContactIncomeString());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(""); //reward label
	LibraryPanel.MC.QueueString(""); //reward value
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}
simulated function String GetContactIncomeString()
{
	return GetRegion().GetSupplyDropReward() @ m_strSupplies;
}
simulated function BuildOutpostBuiltAlert()
{
	local String strBody;
	local XGParamTag ParamTag;

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f);
	}

	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	strBody = `XEXPAND.ExpandString(m_strOutpostBuiltBody);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strOutpostBuiltTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strBody);
	LibraryPanel.MC.QueueString(m_strOutpostBuiltIncome);
	LibraryPanel.MC.QueueString(GetContactIncomeString());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();

}
simulated function BuildContinentAlert()
{
	local X2GameplayMutatorTemplate ContinentBonus;
	local string BonusInfo, BonusSummary;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetContinent().Get2DLocation(), 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetContinent().Get2DLocation(), 0.75f);
	}

	ContinentBonus = GetContinent().GetContinentBonus();

	BonusInfo = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ContinentBonus.DisplayName);
	BonusInfo = class'UIUtilities_Text'.static.GetColoredText(BonusInfo, eUIState_Good);
	BonusInfo = m_strContinentBonusLabel $"\n" @ BonusInfo;

	BonusSummary = ContinentBonus.SummaryText;
	if (ContinentBonus.GetMutatorValueFn != None)
	{
		BonusSummary = Repl(BonusSummary, "%VALUE", ContinentBonus.GetMutatorValueFn());
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strContinentTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetContinent().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(BonusInfo);
	LibraryPanel.MC.QueueString(BonusSummary);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}
simulated function XComGameState_Continent GetContinent()
{
	return XComGameState_Continent(`XCOMHISTORY.GetGameStateForObjectID(ContinentRef.ObjectID));
}
simulated function BuildRegionUnlockedAlert()
{
	local String strUnlocked, strUnlockedHelp;
	local XGParamTag ParamTag;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f);
	}

	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	if( eAlert == eAlert_RegionUnlocked )
	{
		if( IsFirstUnlock() )
		{
			ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
			strUnlocked = `XEXPAND.ExpandString(m_strFirstUnlockedBody);
			strUnlockedHelp = m_strUnlockedHelp;
		}
		else
		{
			ParamTag.StrValue0 = GetUnlockingNeighbor(GetRegion()).GetMyTemplate().DisplayName;
			ParamTag.StrValue1 = GetRegion().GetMyTemplate().DisplayName;
			strUnlocked = `XEXPAND.ExpandString(m_strUnlockedBody);
			strUnlockedHelp = m_strUnlockedHelp;
		}
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strUnlockedFlare);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strUnlocked);
	LibraryPanel.MC.QueueString(strUnlockedHelp);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function bool IsFirstUnlock()
{
	return GetUnlockingNeighbor(GetRegion()) == XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(XCOMHQ().StartingRegion.ObjectID));
}

simulated function XComGameState_WorldRegion GetUnlockingNeighbor(XComGameState_WorldRegion Region)
{
	local StateObjectReference NeighborRegionRef;
	local XComGameState_WorldRegion Neighbor;

	foreach Region.LinkedRegions(NeighborRegionRef)
	{
		Neighbor = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(NeighborRegionRef.ObjectID));

		if( Neighbor.HaveMadeContact() )
		{
			return Neighbor;
		}
	}

	return None;
}

simulated function BuildPointOfInterestAlert()
{
	local XComGameStateHistory History;
	local XGParamTag ParamTag;
	local XComGameState_PointOfInterest POIState;
	local TAlertPOIAvailableInfo kInfo;
	
	History = `XCOMHISTORY;
	POIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(POIRef.ObjectID));
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = POIState.GetResistanceRegionName();
	
	kInfo.zoomLocation = POIState.Get2DLocation();
	kInfo.strTitle = m_strPOITitle;
	kInfo.strLabel = m_strPOILabel;
	kInfo.strBody = m_strPOIBody;
	kInfo.strImage = m_strPOIImage;
	kInfo.strReport = POIState.GetDisplayName();
	kInfo.strReward = POIState.GetRewardDescriptionString();
	kInfo.strRewardIcon = POIState.GetRewardIconString();
	kInfo.strDurationLabel = m_strPOIDuration;
	kInfo.strDuration = class'UIUtilities_Text'.static.GetTimeRemainingString(POIState.GetNumScanHoursRemaining());
	kInfo.strInvestigate = m_strPOIInvestigate;
	kInfo.strIgnore = m_strNotNow;
	kInfo.strFlare = m_strPOIFlare;
	kInfo.strUIIcon = POIState.GetUIButtonIcon();
	kInfo.eColor = eUIState_Normal;
	kInfo.clrAlert = MakeLinearColor(0.75f, 0.75f, 0, 1);
		
	BuildPointOfInterestAvailableAlert(kInfo);
	
	if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M10_IntroToBlacksite') == eObjectiveState_InProgress)
	{
		Button2.Hide();
	}
}

simulated function BuildBlackMarketAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_BlackMarket BlackMarketState;
	local TAlertPOIAvailableInfo kInfo;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
		
	kInfo.zoomLocation = BlackMarketState.Get2DLocation();
	kInfo.strTitle = m_strPOITitle;
	kInfo.strLabel = m_strPOILabel;
	kInfo.strBody = m_strBlackMarketAvailableBody; 
	kInfo.strImage = m_strPOIImage;
	kInfo.strReport = BlackMarketState.GetDisplayName();
	kInfo.strDurationLabel = m_strBlackMarketDuration;
	kInfo.strDuration = class'UIUtilities_Text'.static.GetTimeRemainingString(BlackMarketState.GetNumScanHoursRemaining());
	kInfo.strInvestigate = m_strPOIInvestigate;
	kInfo.strIgnore = m_strIgnore;
	kInfo.strFlare = m_strPOIFlare;
	kInfo.strUIIcon = BlackMarketState.GetUIButtonIcon();
	kInfo.eColor = eUIState_Normal;
	kInfo.clrAlert = MakeLinearColor(0.75f, 0.75f, 0, 1);

	BuildPointOfInterestAvailableAlert(kInfo);
}

simulated function BuildResourceCacheAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResourceCache CacheState;
	local TAlertPOIAvailableInfo kInfo;

	History = `XCOMHISTORY;
	CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));
		
	kInfo.zoomLocation = CacheState.Get2DLocation();
	kInfo.strTitle = m_strResourceCacheAvailableTitle;
	kInfo.strLabel = m_strPOILabel;
	kInfo.strBody = m_strResourceCacheAvailableBody; 
	kInfo.strImage = m_strPOIImage;
	kInfo.strReport = CacheState.GetDisplayName();
	kInfo.strReward = CacheState.GetTotalResourceAmount();
	kInfo.strRewardIcon = "";
	kInfo.strInvestigate = m_strPOIInvestigate;
	kInfo.strIgnore = m_strIgnore;
	kInfo.strFlare = m_strPOIFlare;
	kInfo.strUIIcon = CacheState.GetUIButtonIcon();
	kInfo.eColor = eUIState_Normal;
	kInfo.clrAlert = MakeLinearColor(0.75f, 0.75f, 0, 1);

	BuildPointOfInterestAvailableAlert(kInfo);
}

simulated function BuildPointOfInterestAvailableAlert(TAlertPOIAvailableInfo kInfo)
{
	local String strPOIBody, strFirstParam, strFirstParamLabel;
	local bool bIncludeDuration;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(kInfo.zoomLocation, 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(kInfo.zoomLocation, 0.75f);
	}

	// Body
	strPOIBody = `XEXPAND.ExpandString(kInfo.strBody) $ "\n";

	// If duration is included, set their values as the first params to display
	if (kInfo.strDurationLabel != "" && kInfo.strDuration != "")
	{
		strFirstParamLabel = kInfo.strDurationLabel;
		strFirstParam = kInfo.strDuration;
		bIncludeDuration = true;
	}
	else // Otherwise use the reward label and string as defaults
	{
		strFirstParamLabel = m_strPOIReward;
		strFirstParam = kInfo.strReward;
	}
		
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(kInfo.strTitle);
	LibraryPanel.MC.QueueString(kInfo.strReport);
	LibraryPanel.MC.QueueString(strPOIBody);
	LibraryPanel.MC.QueueString(kInfo.strRewardIcon);
	LibraryPanel.MC.QueueString(strFirstParamLabel);
	LibraryPanel.MC.QueueString(strFirstParam);
	LibraryPanel.MC.QueueString(kInfo.strUIIcon);
	LibraryPanel.MC.QueueString(kInfo.strImage);
	LibraryPanel.MC.QueueString(kInfo.strInvestigate);
	LibraryPanel.MC.QueueString(kInfo.strIgnore);

	// If duration is included, add the rewards at the end if there is one
	if (bIncludeDuration && kInfo.strReport != "")
	{
		LibraryPanel.MC.QueueString(m_strPOIReward);
		LibraryPanel.MC.QueueString(kInfo.strReward);
	}

	LibraryPanel.MC.EndOp();
}

simulated function BuildPointOfInterestCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;
	local String strPOIBody;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	History = `XCOMHISTORY;
	POIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(POIRef.ObjectID));

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Body
	strPOIBody = POIState.GetSummary();

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strPOICompleteLabel);
	LibraryPanel.MC.QueueString(POIState.GetDisplayName());
	LibraryPanel.MC.QueueString(strPOIBody);
	LibraryPanel.MC.QueueString(POIState.GetRewardIconString());
	LibraryPanel.MC.QueueString(m_strPOIReward);
	LibraryPanel.MC.QueueString(POIState.GetRewardValuesString());
	LibraryPanel.MC.QueueString(class'UIUtilities_Image'.const.MissionIcon_POI);
	LibraryPanel.MC.QueueString(POIState.GetImage());
	LibraryPanel.MC.QueueString(m_strPOIReturnToHQ);
	LibraryPanel.MC.QueueString(m_strOk);
	LibraryPanel.MC.EndOp();

	if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M0_CompleteGuerillaOps') == eObjectiveState_InProgress)
	{
		Button1.Hide();
	}
}

simulated function BuildResourceCacheCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResourceCache CacheState;
	local TAlertPOIAvailableInfo kInfo;

	History = `XCOMHISTORY;
	CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));

	kInfo.zoomLocation = CacheState.Get2DLocation();
	kInfo.strTitle = m_strResourceCacheCompleteTitle;
	kInfo.strLabel = m_strResourceCacheCompleteLabel;
	kInfo.strBody = m_strResourceCacheCompleteBody;
	kInfo.strImage = m_strResourceCacheCompleteImage;
	kInfo.strReport = CacheState.GetDisplayName();
	kInfo.strReward = "";
	kInfo.strRewardIcon = "";
	kInfo.strInvestigate = m_strPOIReturnToHQ;
	kInfo.strIgnore = m_strIgnore;
	kInfo.strFlare = m_strResourceCacheCompleteFlare;
	kInfo.strUIIcon = CacheState.GetUIButtonIcon();
	
	BuildPointOfInterestAvailableAlert(kInfo);
}

simulated function BuildBlackMarketAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strBlackMarketTitle);
	LibraryPanel.MC.QueueString(m_strBlackMarketLabel);
	LibraryPanel.MC.QueueString(m_strBlackMarketBody);
	LibraryPanel.MC.QueueString(m_strBlackMarketImage);
	LibraryPanel.MC.QueueString(m_strBlackMarketConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.QueueString(m_strBlackMarketFooterLeft);
	LibraryPanel.MC.QueueString(m_strBlackMarketFooterRight);
	LibraryPanel.MC.QueueString(m_strBlackMarketLogoString);
	LibraryPanel.MC.EndOp();
}

function BuildHelpResHQGoodsAlert()
{
	local TAlertHelpInfo Info;
	
	Info.strTitle = m_strHelpResHQGoodsTitle;
	Info.strHeader = m_strHelpResHQGoodsHeader;
	Info.strDescription = m_strHelpResHQGoodsDescription;
	Info.strImage = m_strHelpResHQGoodsImage;

	Info.strConfirm = m_strRecruitNewStaff;
	Info.strCarryOn = m_strIgnore;

	BuildHelpAlert(Info);
}

function BuildHelpAlert(TAlertHelpInfo Info)
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(Info.strHeader);
	LibraryPanel.MC.QueueString(Info.strTitle);
	LibraryPanel.MC.QueueString(Info.strDescription);
	LibraryPanel.MC.QueueString(Info.strImage);
	LibraryPanel.MC.QueueString(Info.strConfirm);
	LibraryPanel.MC.QueueString(Info.strCarryOn);
	LibraryPanel.MC.EndOp();

	if( Info.strConfirm == "" )
		Button1.Hide();

	if( Info.strCarryOn == "" )
		Button2.Hide();
}

simulated function BuildResearchCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_WorldRegion RegionState;
	local TAlertCompletedInfo kInfo;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	kInfo.strName = TechState.GetDisplayName();
	kInfo.strHeaderLabel = m_strResearchCompleteLabel;
	kInfo.strBody = m_strResearchProjectComplete;

	if (TechState.GetMyTemplate().UnlockedDescription != "")
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

		// Datapads
		if (TechState.IntelReward > 0)
		{
			ParamTag.StrValue0 = string(TechState.IntelReward);
		}

		// Facility Leads
		if (TechState.RegionRef.ObjectID != 0)
		{
			RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(TechState.RegionRef.ObjectID));
			ParamTag.StrValue0 = RegionState.GetDisplayName();
		}

		kInfo.strBody $= "\n" $ `XEXPAND.ExpandString(TechState.GetMyTemplate().UnlockedDescription);
	}

	kInfo.strConfirm = m_strAssignNewResearch;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = TechState.GetImage();
	kInfo = FillInTyganAlertComplete(kInfo);
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildShadowProjectCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertCompletedInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	kInfo.strName = TechState.GetDisplayName();
	kInfo.strHeaderLabel = m_strShadowProjectCompleteLabel;
	kInfo.strBody = m_strShadowProjectComplete;
	kInfo.strConfirm = m_strViewReport;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = TechState.GetImage();

	kInfo = FillInShenAlertComplete(kInfo);
	
	kInfo.strHeadImage2 = "img:///UILibrary_Common.Head_Tygan";
	kInfo.Staff2ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadScientistRef();
	kInfo.strStaff2Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadScientist];

	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering; //TODO: combo image? 

	kInfo.eColor = eUIState_Psyonic;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.0, 0.75, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildItemCompleteAlert()
{
	local TAlertCompletedInfo kInfo;

	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strHeaderLabel = m_strItemCompleteLabel;
	kInfo.strBody = m_strManufacturingComplete;
	kInfo.strConfirm = m_strAssignNewProjects;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.strHeadImage2 = "";
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildProvingGroundProjectCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertCompletedInfo kInfo;
	local XGParamTag kTag;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	kInfo.strName = TechState.GetDisplayName();
	kInfo.strHeaderLabel = m_strProvingGroundProjectCompleteLabel;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = kInfo.strName;

	kInfo.strBody = `XEXPAND.ExpandString(m_strProvingGroundProjectComplete);
	kInfo.strConfirm = m_strAssignNewProjects;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = TechState.GetImage();
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildFacilityCompleteAlert()
{
	local TAlertCompletedInfo kInfo;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Unit UnitState;
	local string CompletedStr, UnitName;
	local XComNarrativeMoment CompleteNarrative;
	
	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	FacilityTemplate = FacilityState.GetMyTemplate();

	// Set up the string displaying extra info about the new facility's benefit
	CompletedStr = Repl(FacilityTemplate.CompletedSummary, "%VALUE", FacilityTemplate.GetFacilityInherentValueFn(FacilityRef));
	if (UnitState != None) // If there was a builder clearing the room, add a string indicating that they are now available
	{
		CompletedStr $= "\n" $ m_strBuilderAvailable;

		if (UnitInfo.bGhostUnit) // If the builder was a ghost, the unit who created it will still be staffed and have its name
			UnitName = UnitState.GetStaffSlot().GetMyTemplate().GhostName;
		else
			UnitName = UnitState.GetFullName();
		
		CompletedStr = Repl(CompletedStr, "%BUILDERNAME", UnitName);
	}
	CompletedStr = class'UIUtilities_Text'.static.GetColoredText(CompletedStr, eUIState_Good, 20);
	     
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strHeaderLabel = m_strFacilityContructedLabel;
	kInfo.strBody = CompletedStr;
	kInfo.strConfirm = m_strViewFacility;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = FacilityTemplate.strImage;	
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	if (FacilityTemplate.DataName == 'ShadowChamber')
		kInfo.strCarryOn = "";

	BuildCompleteAlert(kInfo);

	if(FacilityTemplate.FacilityCompleteNarrative != "")
	{
		CompleteNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityTemplate.FacilityCompleteNarrative));
		if(CompleteNarrative != None)
		{
			`HQPRES.UINarrative(CompleteNarrative);
		}
	}
}

simulated function BuildUpgradeCompleteAlert()
{
	local TAlertCompletedInfo kInfo;

	kInfo.strName = UpgradeTemplate.DisplayName;
	kInfo.strHeaderLabel = m_strUpgradeContructedLabel;
	kInfo.strBody = m_strUpgradeComplete;
	kInfo.strConfirm = m_strAssignNewUpgrade;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = UpgradeTemplate.strImage;
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildClearRoomCompleteAlert()
{
	local TAlertCompletedInfo kInfo;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_Unit UnitState;
	local StaffUnitInfo CurrentBuilderInfo;
	local string BuilderAvailableStr;
	local string UnitString;

	History = `XCOMHISTORY;
	RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(RoomRef.ObjectID));

	kInfo.strName = SpecialRoomFeatureTemplate.ClearingCompletedText;
	kInfo.strHeaderLabel = m_strClearRoomCompleteLabel;
	kInfo.strBody = m_strClearRoomComplete;

	// If there were builders clearing the room, add a string indicating that they are now available
	if (BuilderInfoList.Length > 0)
	{
		UnitString = "";
		foreach BuilderInfoList(CurrentBuilderInfo)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(CurrentBuilderInfo.UnitRef.ObjectID));
			if (Len(UnitString) > 0)
			{
				UnitString $= ", ";
			}
			
			if (CurrentBuilderInfo.bGhostUnit) // If the builder was a ghost, the unit who created it will still be staffed and have its name
				UnitString $= UnitState.GetStaffSlot().GetMyTemplate().GhostName;
			else
				UnitString $= UnitState.GetName(eNameType_Full);
		}
		BuilderAvailableStr = m_strBuilderAvailable;
		BuilderAvailableStr = Repl(BuilderAvailableStr, "%BUILDERNAME", UnitString);
		BuilderAvailableStr = class'UIUtilities_Text'.static.GetColoredText(BuilderAvailableStr, eUIState_Good, 20);
		kInfo.strBody $= "\n" $ BuilderAvailableStr;
	}
	
	kInfo.strBody $= "\n" $ m_strClearRoomLoot @ RoomState.strLootGiven;
	
	kInfo.strConfirm = m_strViewRoom;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = SpecialRoomFeatureTemplate.strImage;
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildTrainingCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate TrainedAbilityTemplate;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local int i;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(1, ClassTemplate.DataName));
	
	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTree = ClassTemplate.GetAbilityTree(0);
	for( i = 0; i < AbilityTree.Length; ++i )
	{
		TrainedAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);

		if( TrainedAbilityTemplate.bHideOnClassUnlock ) continue;

		// Ability Name
		AbilityName = TrainedAbilityTemplate.LocFriendlyName != "" ? TrainedAbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ TrainedAbilityTemplate.DataName $ "'");

		// Ability Description
		AbilityDescription = TrainedAbilityTemplate.HasLongDescription() ? TrainedAbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ TrainedAbilityTemplate.DataName $ "'");
		AbilityIcon = TrainedAbilityTemplate.IconImage;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString(GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityIcon);
	LibraryPanel.MC.QueueString(m_strNewAbilityLabel);
	LibraryPanel.MC.QueueString(AbilityName);
	LibraryPanel.MC.QueueString(AbilityDescription);
	LibraryPanel.MC.QueueString(m_strViewSoldier);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();

	// Hide "View Soldier" button if player is on top of avenger, prevents ui state stack issues
	if(Movie.Pres.ScreenStack.IsInStack(class'UIArmory_Promotion'))
		Button1.Hide();
}

simulated function BuildPsiTrainingCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	// Ability Name
	AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");

	// Ability Description
	AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
	AbilityIcon = AbilityTemplate.IconImage;

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString(GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityIcon);
	LibraryPanel.MC.QueueString(m_strNewAbilityLabel);
	LibraryPanel.MC.QueueString(AbilityName);
	LibraryPanel.MC.QueueString(AbilityDescription);
	LibraryPanel.MC.QueueString(m_strContinueTraining);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();

	// Hide "Continue Training" button if player is on top of avenger, prevents ui state stack issues
	if(Movie.Pres.ScreenStack.IsInStack(class'UIArmory_Promotion'))
		Button1.Hide();
}

simulated function BuildPsiLabIntroAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strIntroToPsiLab;
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strBody = m_strIntroToPsiLabBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = FacilityTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildPsiOperativeIntroAlert()
{
	local XComGameState_Unit UnitState;
	local String IntroPsiOpTitle, IntroPsiOpBody;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	IntroPsiOpTitle = m_strPsiOperativeIntroTitle;
	IntroPsiOpTitle = Repl(IntroPsiOpTitle, "%UNITNAME", Caps(UnitState.GetName(eNameType_FullNick)));

	IntroPsiOpBody = Repl(m_strPsiOperativeIntroHelp, "%UNITNAME", UnitState.GetFullName());

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(IntroPsiOpTitle); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(UnitState.GetSoldierClassTemplate().IconImage); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(m_strPsiOperativeIntro); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(IntroPsiOpBody); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString(GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function BuildConstructionSlotOpenAlert()
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom Facility;
	local string SlotOpenStr;

	RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));
	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomState.GetBuildFacilityProject().ProjectFocus.ObjectID));

	SlotOpenStr = m_strBuildStaffSlotOpen;
	SlotOpenStr = Repl(SlotOpenStr, "%FACILITYNAME", Facility.GetMyTemplate().DisplayName);
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotOpenLabel);
	LibraryPanel.MC.QueueString(Caps(Facility.GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(SlotOpenStr);
	LibraryPanel.MC.QueueString("" /*optional benefit string*/);
	LibraryPanel.MC.QueueString(Facility.GetMyTemplate().strImage);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();

	ButtonGroup.Navigator.HorizontalNavigation = true;
}

simulated function BuildClearRoomSlotOpenAlert()
{
	local XComGameState_HeadquartersRoom RoomState;
	local string SlotOpenStr;
	
	RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(RoomRef.ObjectID));

	SlotOpenStr = m_strClearRoomStaffSlotOpen;
	SlotOpenStr = Repl(SlotOpenStr, "%CLEARTEXT", RoomState.GetSpecialFeature().ClearingInProgressText);
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotOpenLabel);
	LibraryPanel.MC.QueueString(Caps(RoomState.GetSpecialFeature().UnclearedDisplayName));
	LibraryPanel.MC.QueueString(SlotOpenStr);
	LibraryPanel.MC.QueueString("" /*optional benefit string*/);
	LibraryPanel.MC.QueueString(RoomState.GetSpecialFeature().strImage);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	
	ButtonGroup.Navigator.HorizontalNavigation = true;
}

simulated function BuildStaffSlotOpenAlert()
{
	local XComGameState_FacilityXCom FacilityState;
	local string SlotOpenStr, SlotBenefitStr;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityTemplate = FacilityState.GetMyTemplate();

	// Info displayed is different if the open staff slot is for a scientist or an engineer
	if (StaffSlotTemplate.bEngineerSlot)
	{
		SlotOpenStr = m_strEngStaffSlotOpen;	
	}
	else if (StaffSlotTemplate.bScientistSlot)
	{
		SlotOpenStr = m_strSciStaffSlotOpen;
	}
	SlotOpenStr = Repl(SlotOpenStr, "%FACILITYNAME", FacilityTemplate.DisplayName);
	
	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = m_strStaffSlotOpenBenefit @ StaffSlotTemplate.BonusEmptyText;
	SlotBenefitStr = SlotBenefitStr;
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotOpenLabel);
	LibraryPanel.MC.QueueString(Caps(FacilityTemplate.DisplayName));
	LibraryPanel.MC.QueueString(SlotOpenStr);
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(FacilityTemplate.strImage);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();

	ButtonGroup.Navigator.HorizontalNavigation = true;
}

simulated function TAlertCompletedInfo FillInShenAlertComplete(TAlertCompletedInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Shen";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadEngineerRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadEngineer];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering_Black;

	return kInfo;
}

simulated function TAlertCompletedInfo FillInTyganAlertComplete(TAlertCompletedInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Tygan";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadScientistRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadScientist];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Science_Black;

	return kInfo;
}

simulated function BuildCompleteAlert(TAlertCompletedInfo kInfo)
{
	local XGParamTag ParamTag;
	local XComGameState_Unit Staff;

	Staff = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kInfo.Staff1ID));

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}
	
	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = kInfo.strName;
	kInfo.strBody = `XEXPAND.ExpandString(kInfo.strBody);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueNumber(int(eAlert));
	LibraryPanel.MC.QueueString(kInfo.strHeaderLabel);
	LibraryPanel.MC.QueueString(kInfo.strName);
	LibraryPanel.MC.QueueString(kInfo.strName);
	LibraryPanel.MC.QueueString(kInfo.strBody);
	LibraryPanel.MC.QueueString(kInfo.strStaff1Title);
	LibraryPanel.MC.QueueString(Staff.GetName(eNameType_Full));
	LibraryPanel.MC.QueueString(kInfo.strHeaderIcon);
	LibraryPanel.MC.QueueString(kInfo.strImage);
	LibraryPanel.MC.QueueString(kInfo.strHeadImage1);
	LibraryPanel.MC.QueueString(kInfo.strConfirm);
	LibraryPanel.MC.QueueString(kInfo.strCarryOn);
	LibraryPanel.MC.EndOp();

	if (kInfo.strCarryOn == "")
	{
		Button2.Hide();
	}
}

simulated function BuildResearchAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	kInfo.strTitle = m_strNewResearchAvailable;
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = TechState.GetSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildInstantResearchAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;
	local string StrBody;
	
	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	StrBody = Repl(m_strInstantResearchAvailableBody, "%TECHNAME", TechState.GetDisplayName());
	StrBody = Repl(StrBody, "%UNITNAME", TechState.GetMyTemplate().AlertString);

	kInfo.strTitle = Repl(m_strInstantResearchAvailable, "%TECHNAME", Caps(TechState.GetDisplayName()));
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = StrBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildShadowProjectAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	kInfo.strTitle = m_strNewShadowProjectAvailable;
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = TechState.GetSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Psyonic;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.0, 0.75, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemAvailableAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strNewItemAvailable;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemReceivedAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strNewItemReceived;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary() $ "\n\n" $ Repl(m_strItemReceivedInInventory, "%ITEMNAME", ItemTemplate.GetItemFriendlyName(, false));
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemReceivedProvingGroundAlert()
{
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;
	local string TitleStr;
		
	TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(TechRef.ObjectID));
	TitleStr = Repl(m_strNewItemReceivedProvingGround, "%PROJECTNAME", Caps(TechState.GetDisplayName()));

	kInfo.strTitle = TitleStr;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary() $ "\n\n" $ Repl(m_strItemReceivedInInventory, "%ITEMNAME", ItemTemplate.GetItemFriendlyName(, false));
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemUpgradedAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strNewItemUpgraded;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildProvingGroundProjectAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	kInfo.strTitle = m_strNewProvingGroundProjectAvailable;
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = TechState.GetSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning; 
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildFacilityAvailableAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strNewFacilityAvailable;
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strBody = FacilityTemplate.Summary;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = FacilityTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildUpgradeAvailableAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strNewUpgradeAvailable;
	kInfo.strName = UpgradeTemplate.DisplayName;
	kInfo.strBody = UpgradeTemplate.Summary;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = UpgradeTemplate.strImage;
	kInfo.strConfirm = m_strAccept;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildNewStaffAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local array<XComGameState_StaffSlot> arrStaffSlots;
	local X2SoldierClassTemplate ClassTemplate;
	local string StaffAvailableTitle, StaffAvailableStr, StaffBonusStr, UnitTypeIcon;
	local float BonusAmt;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	arrStaffSlots = XCOMHQ().GetAllEmptyStaffSlotsForUnit(UnitState);

	// First set up the string describing the inherent bonus of the new staff member
	if (UnitState.IsAScientist())
	{
		BonusAmt = (UnitState.GetSkillLevel() * 100.0) / XCOMHQ().GetScienceScore(true);
				
		StaffBonusStr = m_strNewSciAvailable;
		StaffBonusStr = Repl(StaffBonusStr, "%AVENGERBONUS", Round(BonusAmt));
		StaffAvailableTitle = m_strNewStaffAvailableTitle;
		StaffAvailableStr = m_strDoctorHonorific @ UnitState.GetFullName();

		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Science;
	}
	else if (UnitState.IsAnEngineer())
	{
		BonusAmt = XCOMHQ().GetNumberOfEngineers();

		StaffBonusStr = m_strNewEngAvailable;
		StaffBonusStr = Repl(StaffBonusStr, "%AVENGERBONUS", int(BonusAmt));
		StaffAvailableTitle = m_strNewStaffAvailableTitle;
		StaffAvailableStr = UnitState.GetFullName();

		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Engineer;
	}
	else if (UnitState.IsASoldier())
	{
		if (arrStaffSlots.Length > 0)
			StaffBonusStr = m_strNewEngAvailable; // "New staffing opportunities available!"
		else
			StaffBonusStr = m_strNewSoldierAvailable; // "Awaiting orders in the Armory!"
		StaffAvailableTitle = m_strNewSoldierAvailableTitle;
		StaffAvailableStr = UnitState.GetName(eNameType_RankFull);

		ClassTemplate = UnitState.GetSoldierClassTemplate();
		UnitTypeIcon = ClassTemplate.IconImage;
	}

	// Then, if there are staffing slots available for the new staff, detail what benefits they could provide
	if (arrStaffSlots.Length > 0)
	{
		LibraryPanel.MC.BeginFunctionOp("UpdateFacilityList");
		
		foreach arrStaffSlots(StaffSlot)
		{
			if (StaffSlot.GetFacility() == none)
			{
				Room = StaffSlot.GetRoom();
				if (Room.UnderConstruction)
				{
					Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().GetFacilityProject(Room.GetReference()).ProjectFocus.ObjectID));
					LibraryPanel.MC.QueueString(Facility.GetMyTemplate().DisplayName);
				}
				else
					LibraryPanel.MC.QueueString(Room.GetSpecialFeature().UnclearedDisplayName);
			}
			else
				LibraryPanel.MC.QueueString(StaffSlot.GetFacility().GetMyTemplate().DisplayName);

			LibraryPanel.MC.QueueString(StaffSlot.GetBonusDisplayString());
		}

		LibraryPanel.MC.EndOp();
	}

	if(UnitState.GetMyTemplate().strAcquiredText != "")
	{
		StaffBonusStr = UnitState.GetMyTemplate().strAcquiredText;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strAttentionCommander);
	LibraryPanel.MC.QueueString(StaffAvailableTitle);
	LibraryPanel.MC.QueueString(UnitTypeIcon);
	LibraryPanel.MC.QueueString(StaffAvailableStr);
	LibraryPanel.MC.QueueString(StaffBonusStr);	
	LibraryPanel.MC.QueueString(GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(m_strAccept);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function BuildStaffInfoAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local array<XComGameState_StaffSlot> arrStaffSlots;
	local X2SoldierClassTemplate ClassTemplate;
	local string StaffAvailableStr, UnitTypeIcon;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	arrStaffSlots = XCOMHQ().GetAllEmptyStaffSlotsForUnit(UnitState);
	
	// First set up the string describing the inherent bonus of the new staff member
	if (UnitState.IsAScientist())
	{		
		StaffAvailableStr = m_strDoctorHonorific @ UnitState.GetFullName();
		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Science;
	}
	else if (UnitState.IsAnEngineer())
	{	
		StaffAvailableStr = UnitState.GetFullName();
		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Engineer;
	}
	else if (UnitState.IsASoldier())
	{
		StaffAvailableStr = UnitState.GetName(eNameType_RankFull);

		ClassTemplate = UnitState.GetSoldierClassTemplate();
		UnitTypeIcon = ClassTemplate.IconImage;
	}

	// Then, if there are staffing slots available for the new staff, detail what benefits they could provide
	if (arrStaffSlots.Length > 0)
	{
		LibraryPanel.MC.BeginFunctionOp("UpdateFacilityList");

		foreach arrStaffSlots(StaffSlot)
		{
			if (StaffSlot.GetFacility() == none)
			{
				Room = StaffSlot.GetRoom();
				if (Room.UnderConstruction)
				{
					Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().GetFacilityProject(Room.GetReference()).ProjectFocus.ObjectID));
					LibraryPanel.MC.QueueString(Facility.GetMyTemplate().DisplayName);
				}
				else
					LibraryPanel.MC.QueueString(StaffSlot.GetRoom().GetSpecialFeature().UnclearedDisplayName);
			}
			else
				LibraryPanel.MC.QueueString(StaffSlot.GetFacility().GetMyTemplate().DisplayName);

			LibraryPanel.MC.QueueString(StaffSlot.GetBonusDisplayString());
		}

		LibraryPanel.MC.EndOp();
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strAttentionCommander);
	LibraryPanel.MC.QueueString(m_strStaffInfoTitle);
	LibraryPanel.MC.QueueString(UnitTypeIcon);
	LibraryPanel.MC.QueueString(StaffAvailableStr);
	LibraryPanel.MC.QueueString(m_strStaffInfoBonus);
	LibraryPanel.MC.QueueString(GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(m_strAccept);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function BuildConstructionSlotFilledAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom Facility;
	local string SlotFilledStr, SlotBenefitStr, strFacilityTypeIcon;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(RoomRef.ObjectID));
	Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(RoomState.GetBuildFacilityProject().ProjectFocus.ObjectID));

	// If the unit is a ghost, use the slot that it is located in, instead of its owning unit
	if (UnitInfo.bGhostUnit)
		SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));
	else
		SlotState = UnitState.GetStaffSlot();

	SlotFilledStr = m_strConstructionSlotFilledLabel;
	SlotFilledStr = Repl(SlotFilledStr, "%FACILITYNAME", Caps(Facility.GetMyTemplate().DisplayName));

	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = m_strConstructionSlotFilled;
	SlotBenefitStr = Repl(SlotBenefitStr, "%UNITNAME", SlotState.GetNameDisplayString());
	SlotBenefitStr = Repl(SlotBenefitStr, "%AVENGERBONUS", RoomState.GetBuildSlot().GetMyTemplate().GetAvengerBonusAmountFn(UnitState));
	
	if( UnitState.IsAScientist() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Science;
	}
	else if( UnitState.IsAnEngineer() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotFilledTitle);
	LibraryPanel.MC.QueueString(Caps(Facility.GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strFacilityTypeIcon);
	LibraryPanel.MC.QueueString(Caps(SlotState.GetNameDisplayString()));
	LibraryPanel.MC.QueueString(SlotFilledStr);
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(UnitInfo.bGhostUnit ? "img:///FX_Avenger_DecoScreen.GremlinPortrait_Conv" : GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function BuildClearRoomSlotFilledAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersRoom RoomState;
	local string SlotFilledStr, SlotBenefitStr, strFacilityTypeIcon;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(RoomRef.ObjectID));

	// If the unit is a ghost, use the slot that it is located in, instead of its owning unit
	if (UnitInfo.bGhostUnit)
		SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));
	else
		SlotState = UnitState.GetStaffSlot();

	SlotFilledStr = m_strClearRoomSlotFilledLabel;
	SlotFilledStr = Repl(SlotFilledStr, "%CLEARTEXT", Caps(RoomState.GetSpecialFeature().ClearingInProgressText));

	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = m_strClearRoomSlotFilled;
	SlotBenefitStr = Repl(SlotBenefitStr, "%UNITNAME", SlotState.GetNameDisplayString());
	SlotBenefitStr = Repl(SlotBenefitStr, "%CLEARTEXT", RoomState.GetSpecialFeature().ClearText);
	SlotBenefitStr = Repl(SlotBenefitStr, "%AVENGERBONUS", RoomState.GetBuildSlot().GetMyTemplate().GetAvengerBonusAmountFn(UnitState));
	
	if( UnitState.IsAScientist() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Science;
	}
	else if( UnitState.IsAnEngineer() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotFilledTitle);
	LibraryPanel.MC.QueueString(Caps(RoomState.GetSpecialFeature().UnclearedDisplayName));
	LibraryPanel.MC.QueueString(strFacilityTypeIcon);
	LibraryPanel.MC.QueueString(Caps(SlotState.GetNameDisplayString()));
	LibraryPanel.MC.QueueString(SlotFilledStr);
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(UnitInfo.bGhostUnit ? "img:///FX_Avenger_DecoScreen.GremlinPortrait_Conv" : GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function BuildStaffSlotFilledAlert()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot SlotState;
	local string SlotFilledStr, SlotBenefitStr, strFacilityTypeIcon;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	
	// If the unit is a ghost, use the slot that it is located in, instead of its owning unit
	if (UnitInfo.bGhostUnit)
		SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(UnitInfo.GhostLocation.ObjectID));
	else
		SlotState = UnitState.GetStaffSlot();

	SlotFilledStr = m_strStaffSlotFilledLabel;
	SlotFilledStr = Repl(SlotFilledStr, "%FACILITYNAME", Caps(FacilityState.GetMyTemplate().DisplayName));

	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = StaffSlotTemplate.FilledText;
	SlotBenefitStr = Repl(SlotBenefitStr, "%UNITNAME", SlotState.GetNameDisplayString());
	SlotBenefitStr = Repl(SlotBenefitStr, "%SKILL", StaffSlotTemplate.GetContributionFromSkillFn(UnitState));
	SlotBenefitStr = Repl(SlotBenefitStr, "%AVENGERBONUS", StaffSlotTemplate.GetAvengerBonusAmountFn(UnitState));

	if( UnitState.IsAScientist() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Science;
	}
	else if( UnitState.IsAnEngineer() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotFilledTitle);
	LibraryPanel.MC.QueueString(Caps(FacilityState.GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strFacilityTypeIcon);
	LibraryPanel.MC.QueueString(Caps(SlotState.GetNameDisplayString()));
	LibraryPanel.MC.QueueString(SlotState.GetBonusDisplayString());
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(UnitInfo.bGhostUnit ? "img:///FX_Avenger_DecoScreen.GremlinPortrait_Conv" : GetOrStartWaitingForStaffImage());

	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function string GetOrStartWaitingForStaffImage()
{
	local XComPhotographer_Strategy Photo;
	local X2ImageCaptureManager CapMan;

	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	Photo = `GAME.StrategyPhotographer;

	StaffPicture = CapMan.GetStoredImage(UnitInfo.UnitRef, name("UnitPicture"$UnitInfo.UnitRef.ObjectID));
	if (StaffPicture == none)
	{
		// if we have a photo queued then setup a callback so we can sqap in the image when it is taken
		if (!Photo.HasPendingHeadshot(UnitInfo.UnitRef, UpdateAlertImage))
		{
			Photo.AddHeadshotRequest(UnitInfo.UnitRef, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Head_Armory', 512, 512, UpdateAlertImage);
		}

		return "";
	}

	return "img:///"$PathName(StaffPicture);
}


simulated function UpdateAlertImage(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local X2ImageCaptureManager CapMan;
	local string TextureName;

	// only care about call backs for the unit we care about
	if (ReqInfo.UnitRef.ObjectID != UnitInfo.UnitRef.ObjectID)
		return;

	// only want the callback for the larger image
	if (ReqInfo.Height != 512)
		return;
	
	TextureName = "UnitPicture"$ReqInfo.UnitRef.ObjectID;
	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	StaffPicture = RenderTarget.ConstructTexture2DScript(CapMan, TextureName, false, false, false);
	CapMan.StoreImage(ReqInfo.UnitRef, StaffPicture, name(TextureName));

	LibraryPanel.MC.BeginFunctionOp("UpdateImage");
	LibraryPanel.MC.QueueString("img:///"$PathName(StaffPicture));
	LibraryPanel.MC.EndOp();
}

simulated function BuildSuperSoldierAlert()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(class'XComOnlineEventMgr'.default.m_sXComHeroSummonTitle); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(UnitState.GetSoldierClassTemplate() != none ? UnitState.GetSoldierClassTemplate().IconImage : ""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(""); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(class'XComOnlineEventMgr'.default.m_sXComHeroSummonText); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString(""); //IMAGE (UPDATED IN PRESENTATION LAYER)
	LibraryPanel.MC.QueueString(class'UIDialogueBox'.default.m_strDefaultAcceptLabel); //OK
	LibraryPanel.MC.QueueString(class'UIDialogueBox'.default.m_strDefaultCancelLabel); //CANCEL
	LibraryPanel.MC.EndOp();
}

simulated function BuildSoldierShakenAlert()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(m_strSoldierShakenTitle); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(m_strSoldierShaken); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(m_strSoldierShakenHelp); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString(GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function BuildSoldierShakenRecoveredAlert()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(m_strSoldierShakenRecoveredTitle); //SOLDIER RECOVERED FROM SHAKEN 
	LibraryPanel.MC.QueueString(""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(m_strSoldierShakenRecovered); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(m_strSoldierShakenRecoveredHelp); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString(GetOrStartWaitingForStaffImage());
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.Hide();
}

simulated function BuildWeaponUpgradesAvailableAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strWeaponUpgradesAvailableTitle;
	kInfo.strName = "";
	kInfo.strBody = m_strWeaponUpgradesAvailableBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Modular_Weapons";
	kInfo.strConfirm = m_strAccept;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildSoldierCustomizationsAvailableAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strNewCustomizationsAvailableTitle); // Title
	LibraryPanel.MC.QueueString(m_strNewCustomizationsAvailableBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide();
}

simulated function BuildForceUnderstrengthAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strForceUnderstrengthTitle); // Title
	LibraryPanel.MC.QueueString(m_strForceUnderstrengthBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide();
}

simulated function BuildWoundedSoldiersAllowedAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strWoundedSoldiersAllowedTitle); // Title
	LibraryPanel.MC.QueueString(m_strWoundedSoldiersAllowedBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide();
}

simulated function TAlertAvailableInfo FillInShenAlertAvailable(TAlertAvailableInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Shen";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadEngineerRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadEngineer];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering_Black;

	return kInfo;
}

simulated function TAlertAvailableInfo FillInTyganAlertAvailable(TAlertAvailableInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Tygan";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadScientistRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadScientist];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Science_Black;

	return kInfo;
}

simulated function BuildAvailableAlert(TAlertAvailableInfo kInfo)
{
	local string UnitName;
	local XComGameState_Unit Staff;

	Staff = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kInfo.Staff1ID));
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	if(Staff.IsASoldier())
		UnitName = Staff.GetName(eNameType_RankFull);
	else
		UnitName = Staff.GetName(eNameType_Full);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(kInfo.strTitle);
	LibraryPanel.MC.QueueString(kInfo.strName);
	LibraryPanel.MC.QueueString(kInfo.strBody);
	LibraryPanel.MC.QueueString(kInfo.strStaff1Title);
	LibraryPanel.MC.QueueString(UnitName);
	LibraryPanel.MC.QueueString(kInfo.strImage);
	LibraryPanel.MC.QueueString(kInfo.strHeadImage1);
	LibraryPanel.MC.QueueString(kInfo.strConfirm);
	LibraryPanel.MC.QueueString(""); //Optional second button param that we don't currently use, but may in the future.
	LibraryPanel.MC.EndOp();

	//Since we aren't using it yet: 
	Button2.Hide();
}

simulated function BuildDarkEventAlert()
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState;

	History = `XCOMHISTORY;
	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(DarkEventRef.ObjectID));

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertType: " $ eAlert);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strDarkEventLabel);
	LibraryPanel.MC.QueueString(DarkEventState.GetDisplayName());
	LibraryPanel.MC.QueueString(DarkEventState.GetSummary());
	LibraryPanel.MC.QueueString(DarkEventState.GetQuote());
	LibraryPanel.MC.QueueString(DarkEventState.GetQuoteAuthor());
	LibraryPanel.MC.QueueString(DarkEventState.GetImage());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	Button2.Hide();

}

simulated function BuildMissionExpiredAlert()
{
	local XGParamTag ParamTag;
	local X2MissionSourceTemplate MissionSource;
	local String ExpiredStr;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = Mission.GetWorldRegion().GetMyTemplate().DisplayName;

	MissionSource = Mission.GetMissionSource();
	
	ExpiredStr = MissionSource.MissionExpiredText;
	if (MissionSource.bDisconnectRegionOnFail && !Mission.GetWorldRegion().IsStartingRegion())
	{
		ExpiredStr @= m_strMissionExpiredLostContact;
	}
	ExpiredStr = `XEXPAND.ExpandString(ExpiredStr);

	BuildAlienSplashAlert(m_strMissionExpiredLabel, MissionSource.MissionPinLabel, ExpiredStr, m_strMissionExpiredImage, m_strOK, "");
	
	//Unused in this alert. 
	Button2.Hide();
}

simulated function BuildTimeSensitiveMissionAlert()
{
	local XGParamTag ParamTag;
	local X2MissionSourceTemplate MissionSource;
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = Mission.GetWorldRegion().GetMyTemplate().DisplayName;

	MissionSource = Mission.GetMissionSource();
	
	BuildAlienSplashAlert(m_strTimeSensitiveMissionLabel, MissionSource.MissionPinLabel, `XEXPAND.ExpandString(m_strTimeSensitiveMissionText), m_strTimeSensitiveMissionImage, m_strFlyToMission, m_strSkipTimeSensitiveMission);
}

simulated function BuildAlienVictoryImminentAlert()
{
	BuildAlienSplashAlert("", m_strAlienVictoryImminentTitle, m_strAlienVictoryImminentBody, m_strTimeSensitiveMissionImage, m_strOK, "");
}

simulated function BuildLowIntelAlert()
{
	local TAlertHelpInfo Info;
	local string LowIntelBody;
	local int idx;

	LowIntelBody = m_strLowIntelDescription $ "\n\n" $ m_strLowIntelBody;
	for (idx = 0; idx < m_strLowIntelList.Length; idx++)
	{
		LowIntelBody $= "\n -" @ m_strLowIntelList[idx];
	}

	Info.strTitle = m_strLowIntelTitle;
	Info.strHeader = m_strLowIntelHeader;
	Info.strDescription = LowIntelBody;
	Info.strImage = m_strLowIntelImage;		
	Info.strCarryOn = m_strOK;

	BuildHelpAlert(Info);
}

simulated function BuildLowSuppliesAlert()
{
	local TAlertHelpInfo Info;
	local string LowSuppliesBody;
	local int idx;

	LowSuppliesBody = m_strLowSuppliesDescription $ "\n\n" $ m_strLowSuppliesBody;
	for (idx = 0; idx < m_strLowSuppliesList.Length; idx++)
	{
		LowSuppliesBody $= "\n -" @ m_strLowSuppliesList[idx];
	}

	Info.strTitle = m_strLowSuppliesTitle;
	Info.strHeader = m_strLowSuppliesHeader;
	Info.strDescription = LowSuppliesBody;
	Info.strImage = m_strLowSuppliesImage;
	Info.strCarryOn = m_strOK;

	BuildHelpAlert(Info);
}

simulated function BuildLowScientistsAlert()
{
	local TAlertHelpInfo Info;
	local string LowScientistsBody;
	local int idx;

	LowScientistsBody = m_strLowScientistsDescription $ "\n\n" $ m_strLowScientistsBody;
	for (idx = 0; idx < m_strLowScientistsList.Length; idx++)
	{
		LowScientistsBody $= "\n -" @ m_strLowScientistsList[idx];
	}

	Info.strTitle = m_strLowScientistsTitle;
	Info.strHeader = m_strLowScientistsHeader;
	Info.strDescription = LowScientistsBody;
	Info.strImage = m_strLowScientistsImage;
	Info.strCarryOn = m_strOK;

	BuildHelpAlert(Info);
}

simulated function BuildLowEngineersAlert()
{
	local TAlertHelpInfo Info;
	local string LowEngineersBody;
	local int idx;

	LowEngineersBody = m_strLowEngineersDescription $ "\n\n" $ m_strLowEngineersBody;
	for (idx = 0; idx < m_strLowEngineersList.Length; idx++)
	{
		LowEngineersBody $= "\n -" @ m_strLowEngineersList[idx];
	}

	Info.strTitle = m_strLowEngineersTitle;
	Info.strHeader = m_strLowEngineersHeader;
	Info.strDescription = LowEngineersBody;
	Info.strImage = m_strLowEngineersImage;
	Info.strCarryOn = m_strOK;

	BuildHelpAlert(Info);
}

simulated function BuildLowScientistsSmallAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strLowScientistsSmallTitle); // Title
	LibraryPanel.MC.QueueString(m_strLowScientistsSmallBody); // Body
	LibraryPanel.MC.QueueString(m_strTellMeMore); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();
}

simulated function BuildLowEngineersSmallAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strLowEngineersSmallTitle); // Title
	LibraryPanel.MC.QueueString(m_strLowEngineersSmallBody); // Body
	LibraryPanel.MC.QueueString(m_strTellMeMore); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();
}

simulated function BuildSupplyDropReminderAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strSupplyDropReminderTitle); // Title
	LibraryPanel.MC.QueueString(m_strSupplyDropReminderBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide();
}

simulated function BuildPowerCoilShieldedAlert()
{
	local string PowerCoilShieldedBody;
	local int idx;

	PowerCoilShieldedBody = m_strPowerCoilShieldedBody;
	for (idx = 0; idx < m_strPowerCoilShieldedList.Length; idx++)
	{
		PowerCoilShieldedBody $= "\n -" @ m_strPowerCoilShieldedList[idx];
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strPowerCoilShieldedTitle); // Title
	LibraryPanel.MC.QueueString(PowerCoilShieldedBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide();
}

simulated function BuildLaunchMissionWarningAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strLaunchMissionWarningHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strLaunchMissionWarningTitle); // Title
	LibraryPanel.MC.QueueString(Mission.GetMissionSource().MissionLaunchWarningText); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide();
}

//-------------- EVENT HANDLING --------------------------------------------------------

simulated function OnReceiveFocus()
{
	local XComGameState NewGameState;

	super.OnReceiveFocus();

	if (bRestoreCameraPositionOnReceiveFocus)
	{
		XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation(0.0f); // Do an instant restore of the camera
	}

	if (!bSoundPlayed)
	{
		PlaySFX(SoundToPlay);
	}
	
	if (!bEventTriggered && EventToTrigger != '')
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("New Popup Event");
		`XEVENTMGR.TriggerEvent(EventToTrigger, EventData, EventData, NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated function OnConfirmClicked(UIButton button)
{
	if( fnCallback != none )
	{
		fnCallback(eUIAction_Accept, self);
	}
	
	// The callbacks could potentially remove this screen, so make sure we haven't been removed already
	if( !bIsRemoved )
		CloseScreen();
}
simulated function OnCancelClicked(UIButton button)
{
	if (CanBackOut())
	{
		if (fnCallback != none)
		{
			fnCallback(eUIAction_Cancel, self);
		}

		if (!bIsRemoved)
			CloseScreen();
	}
}

simulated function TellMeMore(UIButton button) 
{
	bRestoreCameraPositionOnReceiveFocus = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	`HQPRES.UIViewObjectives(0);	
}

// Called when screen is removed from Stack
simulated function OnRemoved()
{
	//If removing an alert that moved the camera when it was displayed, restore the camera saved location
	// But skip any alert that next transitions to a Mission screen, since they will perform their own save & restore of the camera
	if (bRestoreCameraPosition && !bAlertTransitionsToMission)
	{
		XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation();
	}

	super.OnRemoved();
	
	PlaySFX("Play_MenuClose");
}

simulated function bool CanBackOut()
{
	if(eAlert == eAlert_GOps && !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape'))
	{
		return false;
	}

	if (eAlert == eAlert_NewScanningSite && !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M10_IntroToBlacksite'))
	{
		return false;
	}

	if (eAlert == eAlert_FacilityComplete && FacilityTemplate.DataName == 'ShadowChamber')
	{
		return false;
	}

	return true;
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local UIButton CurrentButton; 

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancelClicked(none);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			CurrentButton = UIButton(ButtonGroup.Navigator.GetSelected());

			if( CurrentButton != none )
				CurrentButton.Click();

			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxAlerts/Alerts";
	InputState = eInputState_Consume;
	bAlertTransitionsToMission = false;
	bRestoreCameraPosition = false;
	bConsumeMouseEvents = true;
}
