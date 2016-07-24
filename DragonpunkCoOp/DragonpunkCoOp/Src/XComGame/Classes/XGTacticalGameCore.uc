//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGTacticalGameCore extends XGTacticalGameCoreNativeBase
	config(GameCore);

enum EAbilityIconBehavior
{
	eAbilityIconBehavior_AlwaysShow,
	eAbilityIconBehavior_ShowIfAvailable,
	eAbilityIconBehavior_NeverShow,
	eAbilityIconBehavior_HideIfOtherAvailable,      //  only hides if another named ability is available, otherwise acts as AlwaysShow
	eAbilityIconBehavior_ShowIfAvailableOrNoTargets,
	eAbilityIconBehavior_HideSpecificErrors,        //  another field will specify which errors should hide the icon
};

// these enums are indices into an array of localized strings that are sent 'raw' i.e. not expanded.
// used to make replicating the message a whole lot easier, all thats needed is one class and the index. -tsmith 
enum EUnexpandedLocalizedStrings
{
	eULS_Speed,
	eULS_LightningReflexesUsed,
	eULS_UnitNotStunned,
	eULS_Panicking,
	eULS_Poisoned,
	eULS_Shredded,
	eULS_TracerBeam,
	eULS_AbilityErrMultiShotFail,
	eULS_AbilityCurePoisonFlyover,
	eULS_AbilityOpportunistFlyover,
	eULS_ReactionFireActive,
	eULS_ReactionFireDisabled,
	eULS_InTheZoneProc,
	eULS_DoubleTapProc,
	eULS_ExecutionerProc,
	eULS_SecondaryHeartProc,
	eULS_NeuralDampingProc,
	eULS_NeuralFeedbackProc,
	eULS_AdrenalNeurosympathyProc,
	eULS_ReactiveTargetingSensorsProc,
	eULS_RegenPheromones,
	eULS_AdrenalineSurge,
	eULS_Strangled,
	eULS_Stealth,
	eULS_ShivModuleDisabled,
	eULS_CoveringFireProc,
	eULS_CloseCombatProc,
	eULS_SentinelModuleProc,
	eULS_CatchingBreath,
	eULS_FlashBangDisorient,
	eULS_FlashBangDaze_DEPRECATED,
	eULS_StealthChargeBurn,
	eULS_StealthDeactivated,
	eULS_Immune,
	eULS_AutoThreatAssessmentFlyover,
	eULS_AdvancedFireControlFlyover,
	eULS_WeaponDisabled,
	eULS_EMPDisabled,
	eULS_YellActivated,
	eULS_CommLinkActivated,
};

enum EExpandedLocalizedStrings
{
	eELS_UnitHoverFuel,
	eELS_UnitHoverEnabled,
	eELS_UnitReflectedAttack,
	eELS_WeaponOverheated,
	eELS_WeaponCooledDown,
	eELS_AbilityErrFailed,
	eELS_UnitInCloseCombat,
	eELS_UnitReactionShot,
	eELS_UnitCriticallyWounded,
	eELS_SoldierDied,
	eELS_TankDied,
	eELS_UnitIsStunned,
	eELS_UnitRecovered,
	eELS_UnitStabilized,
	eELS_UnitBleedOut,
	eELS_UnitBledOut,
	eELS_UnitReturnDeath,
	eELS_UnitBoneMarrowHPRegen,
	eELS_UnitRepairServosRegen,
	eELS_UnitPsiDrainTarget,
	eELS_UnitPsiDrainCaster,
};

var privatewrite bool               m_bInitialized;

var init localized string           m_aUnexpandedLocalizedStrings[EUnexpandedLocalizedStrings.EnumCount]<BoundEnum=EUnexpandedLocalizedStrings>;
var init localized string           m_aExpandedLocalizedStrings[EExpandedLocalizedStrings.EnumCount]<BoundEnum=EExpandedLocalizedStrings>;
var init localized string           m_aSoldierMPTemplate[EMPTemplate.EnumCount]<BoundEnum=EMPTemplate>;
var init localized string           m_aSoldierMPGeneModTemplate[EMPGeneModTemplateType.EnumCount]<BoundEnum=EMPGeneModTemplateType>;
var init localized string           m_aSoldierMPGeneModTemplateTacticalText[EMPGeneModTemplateType.EnumCount]<BoundEnum=EMPGeneModTemplateType>;
var init localized string           m_aSoldierMPMECSuitTemplate[EMPMECSuitTemplateType.EnumCount]<BoundEnum=EMPMECSuitTemplateType>;
var init localized string           m_aSoldierMPMECSuitTemplateTacticalText[EMPMECSuitTemplateType.EnumCount]<BoundEnum=EMPMECSuitTemplateType>;
var init localized string           m_aSoldierMPTemplateTacticalText[EMPTemplate.EnumCount]<BoundEnum=EMPTemplate>;

var init localized string           GeneMods;
var init localized string           EmptyLoadout;

var config string       AOEHitMaterialLoc;
var config string		AOEFriendlyMaterialLoc;
var config string       ScanningProtocolMaterialLoc;

simulated function string GetMPTemplateName(int eTemplate)
{
	return m_aSoldierMPTemplate[eTemplate];
}

simulated function string GetMPGeneModTemplateName(int eTemplate)
{
	return m_aSoldierMPGeneModTemplate[eTemplate];
}

simulated function string GetMPMECSuitTemplateName(int eTemplate)
{
	return m_aSoldierMPMECSuitTemplate[eTemplate];
}

simulated function String GetLocalizedItemName(EItemType Idx)
{
	return "LEGACY STRING - STOP USING THIS";
}

//------------------------------------------------------
simulated event Init()
{

	m_bInitialized = true;
}

// MHU - This is different from CalcRelativeHeightBonus because
//       WeaponRange is retrieved and utilized differently vs regular stat
//       application methods.
// This should be called whenever there is a Z difference between two units of RELATIVE_HEIGHT_BONUS_ZDIFF
simulated function float CalcRelativeHeightWeaponRangeBonus()
{
	return RELATIVE_HEIGHT_BONUS_WEAPON_RANGE;
}
//------------------------------------------------------

//-------------------------------------------------------------------------
simulated static function int GetPrimaryWeapon( TInventory kInventory )
{
	local int i, iWeapon;

	for( i = 0; i < kInventory.iNumLargeItems; i++ )
	{
		iWeapon = kInventory.arrLargeItems[i];

		if( iWeapon != -1 )
			return iWeapon;
	}

	return kInventory.iPistol;
}

simulated static function string GetRankString( int iRank, optional bool bAbbreveiated, optional bool bPsi )
{
	return "LEGACY STRING - STOP USING THIS";
}

static final function bool Roll( int iChance )
{
	return Rand( 100 ) < iChance;
}

defaultproperties
{
	//RemoteRole=ROLE_SimulatedProxy
	//bAlwaysRelevant=true
	RemoteRole=ROLE_None
	bAlwaysRelevant=false
}	
