
class UI_Definitions 
	extends Object 
	native;


enum EUIDialogBoxDisplay
{
	eDialog_Normal, //cyan
	eDialog_NormalWithImage, //cyan with image
	eDialog_Warning, //red
	eDialog_Alert   //yellow
};


enum EUIAction
{
	eUIAction_Accept,   // User initiated
	eUIAction_Cancel,   // User initiated
	eUIAction_Closed    // Automatically closed by system
};

// When modifying this enum, you must also update Utilities.as (Flash) 
enum EUIState
{
	eUIState_Normal,
	eUIState_Faded,
	eUIState_Header,
	eUIState_Disabled,
	eUIState_Good,
	eUIState_Bad,
	eUIState_Warning,
	eUIState_Highlight,
	eUIState_Cash,
	eUIState_Psyonic,
	eUIState_Warning2
};

enum EImage
{
	eImage_None,

	eImage_XComBadge,
	eImage_MiniWorld,

	// Weapons
	eImage_Pistol,
	eImage_Rifle,
	eImage_Shotgun,
	eImage_LMG,
	eImage_SniperRifle,
	eImage_RocketLauncher,

	eImage_LaserPistol,
	eImage_LaserRifle,
	eImage_LaserHeavy,
	eImage_LaserSniperRifle,
	eImage_ArcThrower,

	eImage_PlasmaPistol,
	eImage_PlasmaLightRifle,
	eImage_PlasmaHeavy,
	eImage_PlasmaRifle,
	eImage_PlasmaSniperRifle,

	// Items
	eImage_FragGrenade,
	eImage_SmokeGrenade,
	eImage_AlienGrenade,
	eImage_Medikit,

	// Armor
	eImage_Kevlar,
	eImage_SkeletonSuit,
	eImage_Carapace,
	eImage_Beast,
	eImage_Archangel,
	eImage_Titan,
	eImage_Ghost,
	eImage_Goliath,
	eImage_PsiArmor,

	// Foundry Items
	eImage_Flamethrower,
	eImage_AlloyCannon,
	eImage_FlashBang,
	eImage_BlasterLauncher,

	// Alien Artifacts
	eImage_Alloys,
	eImage_Elerium,
	eImage_FogPod,
	eImage_Mummy,
	eImage_CommStation,
	eImage_MedicalStation,
	eImage_UFOFlight,	
	eImage_UFONavigation,	
	eImage_UFOPowerSource,
	eImage_UFOFusionCannon,
	eImage_AlienFood,          
	eImage_AlienEntertainment,
	eImage_AlienStasisTank,
	eImage_AlienSurgery,       
	eImage_HyperwaveBeacon,
	eImage_PsiLink,
	eImage_ExaltIntel,

	eImage_AlloyFabrication,


	eImage_DamagedUFONavigation,
	eImage_DamagedUFOPowerSource,
	eImage_DamagedUFOFusionCannon,
	eImage_DamagedAlienFood,          
	eImage_DamagedAlienEntertainment,
	eImage_DamagedAlienStasisTank,
	eImage_DamagedAlienSurgery,       
	eImage_DamagedHyperwaveBeacon,

	// Vehicles
	eImage_SHIV_I,
	eImage_SHIV_II,
	eImage_SHIV_III,
	eImage_SHIV_Laser,
	eImage_SHIV_Plasma, 
	eImage_Skyranger,
	eImage_Interceptor,
	eImage_Firestorm,
	eImage_InterceptorLaunch,

	eImage_Squad,
	eImage_Alpha,
	eImage_ChiefScientist,
	eImage_ChiefEngineer,
	eImage_CommClerk,
	eImage_MugshotMale,
	eImage_MugshotFemale,
	eImage_Pilot,
	eImage_FundingMember,

	//UFO
	eImage_SmallScout,
	eImage_LargeScout,	
	eImage_Abductor,	
	eImage_SupplyShip,	
	eImage_Battleship,	
	eImage_EtherealUFO,	

	// Vehicle upgrades
	eImage_PhoenixCannon,
	eImage_AvalancheMissile,
	eImage_LaserCannon,
	eImage_PlasmaBeam,
	eImage_EmpCannon,
	eImage_FusionLance,

	// Structures
	eImage_TowerMissile,
	eImage_TowerLaser,
	eImage_TowerPlasma,
	eImage_TowerHyperwave,

	eImage_TileRock,
	eImage_TileRockSteam,
	eImage_TileAccessLift,
	eImage_TileConstruction,
	eImage_TileExcavated,
	eImage_TileBeingExcavated,
	eImage_FacilityAccessLift,
	eImage_FacilityAlienContainment,
	eImage_FacilityEleriumGenerator,
	eImage_FacilityGear,
	eImage_FacilityFoundry,
	eImage_FacilityGenerator,
	eImage_FacilityRadar,
	eImage_FacilityLivingQuarters,
	eImage_FacilityPsiLabs,
	eImage_FacilitySuperComputer,
	eImage_FacilityLargeRadar,
	eImage_FacilityThermoGenerator,
	eImage_FacilityOTS,
	eImage_FacilityOTS2,
	eImage_FacilityXBC,
	eImage_FacilityUber,


	// Staff
	eImage_Soldier,
	eImage_Scientist,
	eImage_Engineer,

	eImage_Sectoid,
	eImage_SectoidCommander,
	eImage_Floater,
	eImage_FloaterHeavy,
	eImage_Muton,
	eImage_MutonElite,
	eImage_MutonCommander,
	eImage_Chryssalid,
	eImage_Zombie,
	eImage_Thinman,
	eImage_Cyberdisc,
	eImage_Ethereal,
	eImage_Sectopod,
	eImage_Drone,
	eImage_Outsider,
	eImage_Mechtoid,
	eImage_Seeker,
	eImage_ExaltOperative,
	eImage_ExaltSniper, 
	eImage_ExaltHeavy,
	eImage_ExaltMedic,
	eImage_ExaltEliteOperative,
	eImage_ExaltEliteSniper, 
	eImage_ExaltEliteHeavy,
	eImage_ExaltEliteMedic,

	eImage_SectoidBust,
	eImage_SectoidCommanderBust,
	eImage_FloaterBust,
	eImage_FloaterHeavyBust,
	eImage_MutonBust,
	eImage_MutonEliteBust,
	eImage_MutonCommanderBust,
	eImage_ChryssalidBust,
	eImage_ZombieBust,
	eImage_ThinmanBust,
	eImage_CyberdiscBust,
	eImage_EtherealBust,
	eImage_SectopodBust,
	eImage_DroneBust,

	eImage_NorthAmerica,
	eImage_SouthAmerica,
	eImage_Africa,
	eImage_Asia,
	eImage_Europe,

	// Misc
	eImage_Geoscape,
	eImage_RadarUFO,
	eImage_Warp,
	eImage_Temple,
	eImage_UFO,
	eImage_AlienBase,
	eImage_UFOCrash,
	eImage_Interception,
	eImage_Lasers,
	eImage_UFOEngine,
	eImage_LivingQuarters,
	eImage_MCUFOScramble,
	eImage_MCIntercept,
	eImage_MCAbduction,
	eImage_MCUFOLanded,
	eImage_MCUFOCrash,
	eImage_MCInterceptionLost,
	eImage_MCTerror,
	eImage_MCTerror2,
	eImage_Lock,
	eImage_AlienTower,
	eImage_Research,
	eImage_Static,
	eImage_DarkLeader,
	eImage_Intro,
	eImage_MissionControl,
	eImage_Labs,
	eImage_Shipping,
	eImage_Artifacts,
	eImage_Panic,
	eImage_News,
	eImage_Army,
	eImage_MummyDeck,
	eImage_AutopsyDeck,
	eImage_BootDeck,
	eImage_DisassemblyDeck,
	eImage_GeniusDeck,
	eImage_Abduction,
	eImage_Abduction2,
	eImage_Beacon,
	eImage_BeginTurn,
	eImage_WeaponsCache,
	eImage_Township,
	eImage_Deck1,
	eImage_Deck2,
	eImage_Device,

	// TECHS
	eImage_XenoBiology,
	eImage_AlienWeaponry,

	// Images from Original
	eImage_OldUFO,
	eImage_OldInterception,
	eImage_OldFunding,
	eImage_OldAssault,
	eImage_OldResearch,
	eImage_OldManufacture,
	eImage_OldRetaliation,
	eImage_OldSoldier,
	eImage_OldHangar,
	eImage_OldTerror,

	eImage_Satellite,

	// Ship Consumables
	eImage_IntConsumableHit,
	eImage_IntConsumableDodge,
	eImage_IntConsumableBoost,
};


struct TText
{
	var string  strValue;
	var int     iState;
};

struct TButtonText
{
	var string  strValue;
	var int     iState;
	var int     iButton;
};

struct TLabeledText
{
	var string  strValue;
	var string  strLabel;
	var int     iState;
	var bool    bNumber;
};

struct TImage
{
	var int     iImage;
	var string  strLabel;
	var int     iState;
	var string  strPath;     // This is an optional way to load an image
};

struct TMenuOption
{
	var string  strText;
	var string  strHelp;
	var int     iState;
};

struct TMenu
{
	var string              strLabel;
	var array<TMenuOption>  arrOptions;
	var bool                bTakesNoInput;    // Is this just a non-interactive list?
};

struct TTableMenuHeader
{
	var array<string>   arrStrings;
	var array<int>      arrStates;
};

struct TTableMenuOption
{
	var array<string>   arrStrings;
	var array<int>      arrStates;  
	var int             iState;
	var string          strHelp;
};

struct TTableMenu
{
	var array<int>              arrCategories;
	var TTableMenuHeader        kHeader;
	var array<TTableMenuOption> arrOptions;
	var bool                    bTakesNoInput;    // Is this just a non-interactive table?
};

struct TProgressGraph
{
	var TText txtTitle;
	var int iProgressState;
	var int iPercentProgress;
};

struct TGraphNode
{
	var int iID;
	var TText txtName;
	var TText txtHelp;
	var int iState;
	var array<int> arrLinks;
};

struct TButtonBar
{
	var array<TButtonText> arrButtons;
};

struct TCostSummary
{
	var array<TText> arrRequirements;
	var string strHelp;
};

struct TTechSummary
{
	var TImage imgItem;
	var TText txtTitle;
	var TText txtSummary;
	var TLabeledText txtProgress;
	var TText txtRequirementsLabel; 
	var bool bCanAfford;
	var TCostSummary kCost;
};

//
// enum of all achievements/trophies
//
// Note: DO NOT INSERT OR REMOVE ENUMS! Rename entries or append new at the end.
//
enum EAchievementType
{
	AT_OverthrowAny,					// Overthrow the aliens at any difficulty level
	AT_OverthrowClassic,				// Overthrow the aliens on Classic difficulty
	AT_OverthrowImpossible,				// Overthrow the aliens on Impossible difficulty
	AT_BuildExperimentalItem,			// Build an experimental item in the Proving Grounds
	AT_ContactRegion,					// Make contact with a region
	AT_CompleteTutorial,				// Complete the tactical tutorial
	AT_BuildResistanceComms,			// Build Resistance Comms
	AT_BuildShadowChamber,				// Build the Shadow Chamber
	AT_UpgradeFacility,					// Upgrade a facility
	AT_BlackMarket,						// Sell goods worth 1000 supplies to the Black Market (Can span multiple games)
	AT_CompletePOI,						// Complete a POI
	AT_RecoverBlackSiteData,			// Recover the Black Site Data
	AT_RecoverCodexBrain,				// Recover a Codex Brain
	AT_RecoverPsiGate,					// Recover the Psi Gate
	AT_CompleteAvatarAutopsy,			// Complete the Avatar Autopsy
	AT_KillAvatar,						// Kill an Avatar
	AT_InstaKillSectopod,				// Kill a Sectopod on the same turn you encounter it
	AT_GuerillaWarfare,					// Reach the objective item in a Guerilla Ops mission with the entire squad still concealed
	AT_Ambush,							// Complete a successful ambush
	AT_Hacker,							// Hack a Sectopod
	AT_EvacRescue,						// Evacuate a soldier whose bleed-out timer is still running
	AT_UpgradeWeapon,					// Upgrade a weapon
	AT_UpgradeWeaponSuperior,			// Completely upgrade a weapon with superior grade weapon upgrades
	AT_KillBerserkerMelee,				// Kill a Berserker in melee combat
	AT_KillViperStrangling,				// Kill a Viper who is strangling a squadmate
	AT_KillSectoidMindControlling,		// Kill a Sectoid who is currently mind controlling a squadmate
	AT_KillWithHackedTurret,			// Kill an enemy with a hacked turret
	AT_BuildEverySlot,					// Build a facility in every Avenger slot
	AT_SabotageFacility,				// Sabotage an alien facility
	AT_KillViaFalling,					// Cause an enemy to fall to its death
	AT_KillViaCarExplosion,				// Cause an enemy to die in a car explosion
	AT_WinGameClassicPlusByDate,		// Beat the game on Classic+ difficulty by <date - end of July?>
	AT_WinGameUsingConventionalGear,	// Beat the final mission using only conventional gear
	AT_WinGameClassicWithoutBuyingUpgrade,	// Beat the game on Classic+ difficulty without buying a Squad Size upgrade
	AT_WinGameClassicPlusNoLosses,		// Beat the game on Classic+ without losing a soldier
	AT_Kill500,							// Kill 500 aliens. (does not have to be in same game)
	AT_WinMultiplayerMatch,				// Win a multiplayer match.
	AT_BeatMissionSameClass,			// Beat a mission on Classic+ with a squad composed entirely of soldiers of the same class
	AT_BeatMissionNoCivilianDeath,		// Beat a Retaliation mission without any civilian deaths
	AT_HackGain3Rewards,				// Gain the best hack reward
	AT_KillWithEveryHeavyWeapon,		// Kill an enemy with every heavy weapon in the game(Doesn't have to be in the same game)
	AT_BuildRadioEveryContinent,		// Build a radio relay on every continent
	AT_GetAllContinentBonuses,			// Get all of the continent bonuses (does not have to be in same game)
	AT_BeatMissionJuneOrLater,			// Beat a mission in June or later using only Rookies
	AT_SkulljackEachAdventSoldierType,	// Skulljack each different type of ADVENT soldier(does not have to be in same game)
	AT_SkulljackAdventOfficer,			// Skulljack an ADVENT Officer
	AT_RecoverForgeItem,				// Recover the Forge Item
	AT_CreateDarkVolunteer,				// Create the Dark Volunteer
	AT_ApplyPCSUpgrade,					// Apply a PCS upgrade to a soldier
	AT_TripleKill,						// Kill 3 enemies in a single turn, with a single soldier, without explosives
	AT_IronMan,							// Beat the game on Classic+ difficulty in Ironman mode	

	// DLC 2 - Alien Hunters Achievements
	AT_CompleteAlienNest,				// Complete the Alien Nest mission
	AT_KillViperKing,					// Kill the Viper King
	AT_KillBerserkerQueen,				// Kill the Berserker Queen
	AT_KillArchonKing,					// Kill the Archon King
	AT_KillAllRulers,				// Kill all three alien rulers in one game
	AT_BuyAllHunterWeapons,				// Purchase the final tier Hunter Weapons
	AT_UseAllRulerArmorAbilities,		// Use all three alien ruler armor abilities in a single mission
	AT_UseRulerArmorAbilityOnRuler,		// Use an alien ruler armor ability against an alien ruler
	AT_KillRulerFirstEncounter,	// Kill an alien ruler the first time you encounter it
	AT_KillRulerDuringEscape,		// Kill an alien ruler during its reaction move as it tries to escape

	// DLC 3 - Shen's Last Gift Achievements
	AT_CompleteLostTowers,				// Complete the Lost Towers mission
	AT_PromoteSparkVanguard,			// Promote a SPARK to the Vanguard rank
	AT_BeatMissionThreeSparks,			// Beat a mission with three or more SPARKs
	AT_KillAvatarWithSpark,				// Kill an Avatar with a SPARK
	AT_BeatMissionHalfHealthSpark,		// A SPARK unit survives a mission it started with less than half health
	AT_BuyAllSparkGear,					// Outfit a SPARK with highest tier weapons and armor
	AT_HitThreeOverdriveShots,			// Hit three shots in a single turn with SPARK after using Overdrive
	AT_KillRobotWithSpark,				// Kill a robotic unit with a Spark
	AT_BuildSpark,						// Build a SPARK unit
	AT_KillPrimedDerelictMEC,			// Detonate a primed Derelict MEC
};

// STYLING 
enum EUIUtilities_TextStyle
{
	eUITextStyle_Body,
	eUITextStyle_Title,
	eUITextStyle_Tooltip_Title,
	eUITextStyle_Tooltip_H1,
	eUITextStyle_Tooltip_H2,
	eUITextStyle_Tooltip_Body,
	eUITextStyle_Tooltip_StatLabel,
	eUITextStyle_Tooltip_StatLabelRight,
	eUITextStyle_Tooltip_StatValue,
	eUITextStyle_Tooltip_AbilityValue,
	eUITextStyle_Tooltip_AbilityRight,
	eUITextStyle_Tooltip_HackHeaderLeft,
	eUITextStyle_Tooltip_HackHeaderRight,
	eUITextStyle_Tooltip_HackBodyLeft,
	eUITextStyle_Tooltip_HackBodyRight,
	eUITextStyle_Tooltip_HackH3Left,
	eUITextStyle_Tooltip_HackH3Right,
	eUITextStyle_Tooltip_HackStatValueLeft,
};

struct UISummary_ItemStat
{
	var string Label; 
	var string Value; 
	var EUIState LabelState; 
	var EUIState ValueState; 
	var EUIUtilities_TextStyle LabelStyle; 
	var EUIUtilities_TextStyle ValueStyle; 

	structdefaultproperties
	{
		LabelState = eUIState_Normal;
		ValueState = eUIState_Normal;
		LabelStyle = eUITextStyle_Tooltip_StatLabel;
		ValueStyle = eUITextStyle_Tooltip_StatValue; 
	}
};

enum EQuitReason
{
	QuitReason_None,           // No quit has occured
	QuitReason_UserQuit,       // The user manually quit to the start menu
	QuitReason_SignOut,        // The active user logged out
	QuitReason_LostDlcDevice,  // The storage device for DLC has been lost
	QuitReason_InactiveUser,   // An inactive user has logged in
	QuitReason_LostConnection, // Multiplayer area lost connection
	QuitReason_LostLinkConnection, // Multiplayer area lost ethernet connection
	QuitReason_OpponentDisconnected, // Multiplayer opponent disconnected
};

enum EUISound
{
	eSUISound_MenuOpen,
	eSUISound_MenuClose,
	eSUISound_MenuSelect,
	eSUISound_MenuClickNegative,
	eSUISound_SoldierPromotion,
};

enum EUIConfirmButtonStyle
{
	eUIConfirmButtonStyle_None,
	eUIConfirmButtonStyle_Default,
	eUIConfirmButtonStyle_X,
	eUIConfirmButtonStyle_Check,
	eUIConfirmButtonStyle_BuyEngineering,
	eUIConfirmButtonStyle_BuyScience,
	eUIConfirmButtonStyle_BuyCash,
};