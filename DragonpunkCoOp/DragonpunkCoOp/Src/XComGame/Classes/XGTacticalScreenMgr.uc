//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGTacticalScreenMgr extends Actor dependson(XGNarrative);

enum ETableCategories
{
	eCat_City,
	// Labs
	eCat_TechName,
	// Engineering
	eCat_ItemName,
	eCat_Progress,
	eCat_Quantity,
	eCat_Due,
	eCat_Cash,
	eCat_Alloys,
	eCat_Elerium,
	eCat_Time,
	eCat_Engineers,
	eCat_Scientists,
	eCat_Power,
	// Soldier
	eCat_Flag,
	eCat_Name,
	eCat_Nickname,
	eCat_Country,
	eCat_Loadout,
	eCat_Status,
	eCat_Promotion,
	eCat_Rank,
	eCat_Ability,
	eCat_NewPerks,
	// Base
	eCat_OnStaff,

	// Alien Activity
	eCat_Fear,
	eCat_Funding,
	eCat_Reward,

	eCat_MissionFactor,
	eCat_MissionResult,
	eCat_MissionRating,

	eCat_Artifact,
	eCat_Recovered,
	eCat_Blank,
};

enum EButton
{
	eButton_None,
	eButton_A,
	eButton_X,
	eButton_Y,
	eButton_B,
	eButton_Start,
	eButton_Back,
	eButton_Up,
	eButton_Down,
	eButton_Left,
	eButton_Right,
	eButton_LBumper,
	eButton_RBumper,
	eButton_LTrigger,
	eButton_RTrigger,
	eButton_LStick,
	eButton_RStick,
};


enum EOTSImages
{
	eOTSImage_Will_I,
	eOTSImage_SquadSize_I,
	eOTSImage_XP_I,
	eOTSImage_HP_I,
	eOTSImage_Squadsize_II,
	eOTSImage_XP_II,
	eOTSImage_HP_II
};


enum EFoundryImages
{
	eFoundryImage_SHIV,			
	eFoundryImage_SHIVHeal,			
	eFoundryImage_CaptureDrone,	
	eFoundryImage_MedikitII,			
	eFoundryImage_ArcThrowerII,
	eFoundryImage_LaserCoolant,
	eFoundryImage_SHIVLaser,		
	eFoundryImage_SHIVPlasma,
	eFoundryImage_Flight,	
	eFoundryImage_AlienGrenade,
	eFoundryImage_AdvancedConstruction,
	eFoundryImage_VehicleRepair,	
	eFoundryImage_PistolI,	
	eFoundryImage_PistolII,
	eFoundryImage_PistolIII,	
	eFoundryImage_SHIVSuppression,
	eFoundryImage_StealthSatellites,
	eFoundryImage_ScopeUpgrade,	
	eFoundryImage_AdvancedServomotors,
	eFoundryImage_ShapedArmor,
	eFoundryImage_EleriumFuel,
	eFoundryImage_SentinelDrone,
	eFoundryImage_TacticalRigging,
	eFoundryImage_MECCloseCombat,

};

enum EInventoryImages
{
	eInventoryImage_EMPCannon,
	eInventoryImage_FusionLance,
	eInventoryImage_GunPod,
	eInventoryImage_LaserCannon,
	eInventoryImage_MissilePod,
	eInventoryImage_PlasmaCannon,
	eInventoryImage_AlienGrenade,
	eInventoryImage_AlienWeaponFragments,
	eInventoryImage_ArcThrower,
	eInventoryImage_ArmorArchangel,
	eInventoryImage_ArmorCarapace,
	eInventoryImage_ArmorGhost,
	eInventoryImage_ArmorKevlar,
	eInventoryImage_ArmorPsi,
	eInventoryImage_ArmorSkeleton,
	eInventoryImage_ArmorTitan,
	eInventoryImage_AssaultRifleModern,
	eInventoryImage_BattleScanner,
	eInventoryImage_ChitinPlating,
	eInventoryImage_CombatStims,
	eInventoryImage_DefenseMatrix,
	//eInventoryImage_EMPCannon,
	eInventoryImage_Firestorm,
	eInventoryImage_FlameThrower,
	eInventoryImage_FragGrenade,
	eInventoryImage_GrappleHook,
	eInventoryImage_Interceptor,
	eInventoryImage_LaserHeavy,
	eInventoryImage_LaserPistol,
	eInventoryImage_LaserRifle,
	eInventoryImage_LaserShotgun,
	eInventoryImage_LaserSniper,
	eInventoryImage_LMG,
	eInventoryImage_MedikitI,
	eInventoryImage_MedikitII,
	eInventoryImage_MindShield,
	eInventoryImage_MotionDetector,
	eInventoryImage_NanoFabricVest,
	eInventoryImage_Pistol,
	eInventoryImage_PlasmaBlasterLauncher,
	//eInventoryImage_PlasmaCannon,
	eInventoryImage_PlasmaHeavy,
	eInventoryImage_PlasmaPistol,
	eInventoryImage_PlasmaRifle,
	eInventoryImage_PlasmaRifleLight,
	eInventoryImage_PlasmaShotgun,
	eInventoryImage_PlasmaSniper,
	//eInventoryImage_ProximityMine,
	eInventoryImage_RocketLauncher,
	eInventoryImage_Satellite,
	eInventoryImage_SatelliteTargeting,
	eInventoryImage_Scope,
	eInventoryImage_SHIVI,
	eInventoryImage_SHIVII,
	eInventoryImage_SHIVIII,
	eInventoryImage_MECI,
	eInventoryImage_MECII,
	eInventoryImage_MECIII,
	eInventoryImage_SHIVGattlingGun,
	eInventoryImage_SHIVLaserCannon,
	eInventoryImage_Shotgun,
	eInventoryImage_SkeletonKey,
	eInventoryImage_SmokeGrenade,
	eInventoryImage_SniperRifle,
	//eInventoryImage_TargetPainter,
	eInventoryImage_UFOTracking,
	eInventoryImage_Xenobiology,
	eInventoryImage_RespiratorImplant,
	eInventoryImage_ReaperRounds,
	eInventoryImage_Flashbang,
	eInventoryImage_MimicBeacon,
	eInventoryImage_GasGrenade,
	eInventoryImage_GhostGrenade,
	eInventoryImage_NeedleGrenade,
	eInventoryImage_ExaltAssaultRifle,
	eInventoryImage_ExaltSniperRifle,
	eInventoryImage_ExaltHeavyMG,
	eInventoryImage_ExaltLaserAssaultRifle,
	eInventoryImage_ExaltLaserSniperRifle,
	eInventoryImage_ExaltLaserHeavyMG,
	eInventoryImage_ExaltRocketLauncher,
	eInventoryImage_MECChainGun,
	eInventoryImage_MECRailGun,
	eInventoryImage_MECParticleCannon,
	eInventoryImage_MECCivvies

};

enum ECreditImages
{
	eCreditImage_Weapons_I,
	eCreditImage_PlasmaWeapons,
	eCreditImage_AllWeapons,
	eCreditImage_Armor_I,
	eCreditImage_AllArmor,
	eCreditImage_UFOTech,
	eCreditImage_Flight,
	eCreditImage_Psionics,
	eCreditImage_AllAlienTech,
};

struct TTab
{
	var string  strTab;
	var int     iState;
};

struct TTabbedTableMenu
{
	var array<TTab>         arrTabs;
	var array<TTableMenu>   arrTableMenus;
};

var int                     m_iCurrentView;
var IScreenMgrInterface     m_kInterface;

var localized string        m_arrCategoryNames[ETableCategories.EnumCount]<BoundEnum=ETableCategories>;

function Init( optional int iView )
{
	GoToView( iView );
}

// This is the link to the actual UI screen
function IScreenMgrInterface GetUIScreen()
{
	if( m_kInterface != none ) 
		return m_kInterface;
	else if (Owner != none)
		return IScreenMgrInterface(Owner);

	return none;
}
function UpdateView()
{
	local IScreenMgrInterface Screen;

	Screen = GetUIScreen();
	if (Screen != none)
		Screen.GoToView( m_iCurrentView );
}

function GoToView( int iView )
{
	if( m_iCurrentView == iView )
		return;

	m_iCurrentView = iView;

	UpdateView();
}

static function array<string> GetHeaderStrings( array<int> arrCategories )
{
	local array<string> arrStrings;
	local int iCategory;

	for( iCategory = 0; iCategory < arrCategories.Length; iCategory++ )
	{
		arrStrings[iCategory] = class'XGTacticalScreenMgr'.default.m_arrCategoryNames[arrCategories[iCategory]];
	}

	return arrStrings;
}

// DEPREACTED: REMOVE - sbatista
static function array<int> GetHeaderStates( array<int> arrCategories )
{
	local array<int> arrStates;
	local int iState;
	local int iCategory;

	for( iCategory = 0; iCategory < arrCategories.Length; iCategory++ )
	{
		switch( arrCategories[iCategory] )
		{
		case eCat_Cash:
			iState = eUIState_Cash;
			break;
		default:
			iState = eUIState_Normal;
		}

		arrStates[iCategory] = iState;
	}

	return arrStates;
}

DefaultProperties
{
	m_iCurrentView=-1
}
