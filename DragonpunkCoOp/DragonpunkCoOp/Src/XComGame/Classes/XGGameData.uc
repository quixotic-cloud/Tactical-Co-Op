//-----------------------------------------------------------
// Common definitions for the entire game
//-----------------------------------------------------------
class XGGameData extends Object
	native
	dependson(UI_Definitions);

struct native InclusionExclusionList
{
	// The name of this list
	var name				ListID;

	// The list of names to be Included or Excluded
	var array<name>			TemplateName;

	// If true, this functions as an inclusion ist; if false it functions as an exclusion list
	var bool				bIncludeNames;
};

struct native ConfigurableEncounter
{
	// The name of this encounter (used in conjunction with Mission triggers)
	var name				EncounterID;

	// A hard limit on the maximum number of group members that this encounter should contain
	var int					MaxSpawnCount;

	// If >0, this value overrides the Force Level for the next group to spawn.
	var int					OffsetForceLevel;

	// If >0, this value overrides the AlertLevel for the next group to spawn.
	var int					OffsetAlertLevel;

	// The name of an Inclusion/Exclusion list of character types that are permitted to spawn as part of this encounter as a group leader.
	var Name				LeaderInclusionExclusionCharacterTypes;

	// The name of an Inclusion/Exclusion list of character types that are permitted to spawn as part of this encounter as a group follower.
	var Name				FollowerInclusionExclusionCharacterTypes;

	// When constructing this encounter, the leader (index 0) and followers will be selected first from these template names; 
	// the remainder will be filled out using normal encounter construction rules.
	var array<Name>			ForceSpawnTemplateNames;

	// This encounter will only be available if the current Alert Level is greater than or equal to this value.
	var int					MinRequiredAlertLevel;

	// This encounter will only be available if the current Alert Level is less than or equal to this value.
	var int					MaxRequiredAlertLevel;

	// This encounter will only be available if the current Force Level is greater than or equal to this value.
	var int					MinRequiredForceLevel;

	// This encounter will only be available if the current Force Level is less than or equal to this value.
	var int					MaxRequiredForceLevel;

	// If configured as a reinforcement encounter, this is the number of turns until the group spawns for this encounter.
	var int					ReinforcementCountdown;

	// If configured as a reinforcement encounter, if true this group will spawn via Psi Gate; if false, the group will spawn via ATT.
	var bool				bSpawnViaPsiGate;

	// If true, this encounter group will not drop loot.
	var bool				bGroupDoesNotAwardLoot;

	// The team that this encounter group should spawn into.
	var ETeam				TeamToSpawnInto;

	// Whether to skip soldier VO
	var bool				SkipSoldierVO;

	structdefaultproperties
	{
		MaxSpawnCount = 10
		ReinforcementCountdown = 1
		MinRequiredAlertLevel = 0
		MaxRequiredAlertLevel = 1000
		MinRequiredForceLevel = 0
		MaxRequiredForceLevel = 20
		TeamToSpawnInto = eTeam_Alien
	}
};

struct native ConditionalEncounter
{
	// The name of an ConfigurableEncounter.
	var Name				EncounterID;

	// If specified, this group will only attempt to spawn if the specified Tag is present in the TacticalGameplayTags list on the XComHQ.
	var Name				IncludeTacticalTag;

	// If specified, this group will only attempt to spawn if the specified Tag is NOT present in the TacticalGameplayTags list on the XComHQ.
	var Name				ExcludeTacticalTag;
};

struct native EncounterBucket
{
	// The name of this bucket.
	var Name EncounterBucketID;

	// The list of possible encounters and the conditions under which they are permissible. 
	// When evaluated, the first eligible encounter in this list will be selected.
	var array<ConditionalEncounter> EncounterIDs;
};

struct native PrePlacedEncounterPair
{
	// The name of an ConfigurableEncounter or an EncounterBucket.
	var Name				EncounterID;

	// How wide should this encounter band be?
	var float				EncounterZoneWidth;

	// If >= 0, this specifies the height of the encounter band (In Tiles).
	var float				EncounterZoneDepthOverride;

	// This specifies the offset from the LOP that this encounter band should be centered (In Tiles).
	var float				EncounterZoneOffsetFromLOP;

	// In which encounter zone should this group spawn and reside?
	var float				EncounterZoneOffsetAlongLOP;

	// If specified, this group will attempt to spawn on the tagged actor's location.
	var Name				SpawnLocationActorTag;

	// If specified, this group will only attempt to spawn if the specified Tag is present in the TacticalGameplayTags list on the XComHQ.
	var Name				IncludeTacticalTag;

	// If specified, this group will only attempt to spawn if the specified Tag is NOT present in the TacticalGameplayTags list on the XComHQ.
	var Name				ExcludeTacticalTag;

	structdefaultproperties
	{
		EncounterZoneWidth = 36.0
		EncounterZoneDepthOverride = -1.0
	}
};

struct native MissionSchedule
{
	// The Identifier for this mission schedule
	var name				ScheduleID;

	// The ideal length of this schedule, in XCom turn count
	var float				IdealTurnCount;

	// The ideal number of XCom turns until the objective is completed
	var float				IdealObjectiveCompletion;

	// The ideal number of tiles away from the objective at which XCom will spawn
	var int					IdealXComSpawnDistance;

	// The absolute minimum number of tiles away from the objective at which XCom will spawn
	var int					MinXComSpawnDistance;

	// The list of encounters pre-placed on the map
	var array<PrePlacedEncounterPair>	PrePlacedEncounters;

	// This Mission Schedule will only be available if the current Alert Level is greater than or equal to this value.
	var int					MinRequiredAlertLevel;

	// This Mission Schedule will only be available if the current Alert Level is less than or equal to this value.
	var int					MaxRequiredAlertLevel;

	// This Mission Schedule will only be available if the current Force Level is greater than or equal to this value.
	var int					MinRequiredForceLevel;

	// This Mission Schedule will only be available if the current Force Level is less than or equal to this value.
	var int					MaxRequiredForceLevel;

	// The maximum number of turrets that are allowed to spawn for this mission schedule.
	var int					MaxTurrets;

	// The ideal ratio between Encounters with an Alien as a leader vs. Encounters with an Advent as a leader.
	var float				AlienToAdventLeaderRatio;

	// For Alien-led groups, the ideal ratio between selecting Aliens as followers vs. Advent as followers.
	var float				AlienToAdventFollowerRatio;

	// The average number of advent soldiers who should drop timed loot when killed in this mission.
	var float				AverageAdventTimedLoot;

	// The average number of aliens who should drop timed loot when killed in this mission.
	var float				AverageAlienTimedLoot;

	// If true, the XCom squad will start this mission with Squad Concealment.
	var bool				XComSquadStartsConcealed;

	// If true, encounter groups will be forcibly selected when spawning pre-placed encounter groups, even if the mission site had already selected groups.  
	// This should be set to true for multi-part mission schedules beyond the initial map.
	var bool				bForceReselectAllGroupsForSpawn;

	// This defines how deep in the encounter zone units are allowed to spawn and patrol (In Tiles).
	// Encounters defined as guard groups will also use this value as their patrol width (square patrol zone).
	var float				EncounterZonePatrolDepth;

	// This defines how wide (along the LOP) the band should be to accept turrets (In Tiles).
	var float				TurretZoneWidth;

	// This defines how far away from the Objective (along the LOP) the Turret Zone should sit (In Tiles).
	var float				TurretZoneObjectiveOffset;

	// This defines the maximum number of security tower that will spawn in for this mission.
	var int					MaxSecurityTowersToSpawn;

	// If specified, this schedule will only be used if the specified Tag is present in the TacticalGameplayTags list on the XComHQ.
	var Name				IncludeTacticalTag;

	// If specified, this schedule will only be used if the specified Tag is NOT present in the TacticalGameplayTags list on the XComHQ.
	var Name				ExcludeTacticalTag;

	structdefaultproperties
	{
		MinRequiredAlertLevel = 0
		MaxRequiredAlertLevel = 1000
		MinRequiredForceLevel = 0
		MaxRequiredForceLevel = 20
		MaxTurrets = 2
		XComSquadStartsConcealed = true
		AverageAdventTimedLoot = 1.0
		AverageAlienTimedLoot = 1.0
		AlienToAdventLeaderRatio = 0.67
		AlienToAdventFollowerRatio = 0.5
		EncounterZonePatrolDepth = 8.0
		TurretZoneWidth = 16.0
		TurretZoneObjectiveOffset = 0.0
		MaxSecurityTowersToSpawn = 2
	}
};

struct native ObjectiveLootTable
{
	var name LootTableName;
	var int ForceLevel; // Min force level
};

struct native MissionObjectiveDefinition
{
	// The name of this objective; must match the objective name of a Kismet action "Objective Completed" for this mission type.
	var Name ObjectiveName;

	// The Loot table that will be rolled on and awarded to XCOm on successful completion of this objective (based on force level).
	var array<ObjectiveLootTable> SuccessLootTables;

	// If true, this is a tactical mission objective, whose completion is required to auto-evac all XCom soldiers and 
	// earn the TacticalObjectiveLootBucket of all Auto-loot map rewards.
	var bool bIsTacticalObjective;

	// If true, this is a strategy mission objective, whose completion is required to have this mission count as a success for strategy objective purposes.
	var bool bIsStrategyObjective;

	// If true, this is a triad mission objective, whose completion is required to affect Triad reduction in strategy for the region this mission occurs in.
	var bool bIsTriadObjective;

	// If true, this objective has been successfully completed.
	var bool bCompleted;
};

struct native MissionIntroSequence
{
	var array<string> MatineeCommentPrefixes;
};

struct native MissionIntroDefinition
{
	var string MatineePackage; // Map package the intro missions are in
	var array<MissionIntroSequence> MatineeSequences; // Sequence of matinees to play in the intro, by tag. 
	var name MatineeBaseTag; // tag of the actor the matinee is based on, to be centered on the soldier spawn
};

struct native MissionDefinition
{
	var name                MissionName;
	var string              sType;
	var string              MissionFamily;
	var array<string>       MapNames;
	var string              SpawnTag; // allows the LDs to limit OSP selection to a specific OSP actor
	var array<string>       RequiredMissionItem; // one of these items must be equppied to start the mission
	var bool                ObjectiveSpawnsOnPCP; // true to indicate that the objective spawns on a PCP, and not a plot
	var bool				DisablePanic;		// Disable panic completely for this mission.
	var int                 MaxSoldiers;        // overrides the number of soldiers that can be taken into the mission. <= 0 uses default value 

	var bool                    OverrideDefaultMissionIntro;
	var MissionIntroDefinition  MissionIntroOverride;
	
	var bool				AllowDeployWoundedUnits;   // if true, wounded soldiers can be included in the squad for this mission

	var array<name>			SpecialSoldiers; // if a special soldier character is required for this mission

	var array<string>       RequiredPlotObjectiveTags;
	var array<string>       ExcludedPlotObjectiveTags;

	var array<string>       RequiredParcelObjectiveTags;
	var array<string>       ExcludedParcelObjectiveTags;

	var int                 iExitFromObjectiveMinTiles;
	var int                 iExitFromObjectiveMaxTiles;

	var int                 MinCivilianCount; // minimum number of civilians to spawn on the map. If 0, disables civilian spawning. Overrides plot type setting if specified.
	var bool                CiviliansAreAlienTargets; // if true, civilians are considered targets by the aliens in this mission
	var bool				CiviliansAlwaysVisible;   
	var bool				AliensAlerted; // True if all AI starts out in Yellow alert.

	var bool				DisallowCheckpointPCPs;	// If true, no checkpoint PCPs will spawn for this mission type

	var int					Difficulty;

	// The list of possible mission schedules for this mission type.
	var array<name>			MissionSchedules;

	// The list of all mission objectives that are available for completion as part of this mission.
	var array<MissionObjectiveDefinition> MissionObjectives;

	structdefaultproperties
	{
		iExitFromObjectiveMaxTiles=10000
		MinCivilianCount=-1
	}
};

struct native PlotTypeDefinition
{
	var string strType;
	var bool bUseEmptyClosedEntrances;  // Entrances that are "closed" use no mesh
	var name MissionSiteDescriptionTemplate;
	var int MinCivilianCount; // minimum number of civilians to spawn on maps of this type. If 0, disables civilian spawning, -1 uses default spawning values
	var string strDecoEditorLayer;
	var bool ExcludeFromRetailBuilds;

	structdefaultproperties
	{
		MinCivilianCount=-1
	}
};


struct native PlotLootDefinition
{
	var string PlotType;
	var string OSPMissionType;
	var string LootActorArchetype;
	var int DesiredSpawnCount;

	structdefaultproperties
	{
		DesiredSpawnCount=1
	}
};

enum MultiplayerPlotIndex
{
	MPI_Test,
	MPI_Facility,
	MPI_SmallTown,
	MPI_Shanty,
	MPI_Slums,
	MPI_Wilderness,
	MPI_CityCenter,
	MPI_Rooftops
};

enum MultiplayerBiomeIndex
{
	MBI_Temperate,
	MBI_Arid,
	MBI_Tundra,
};

struct native PlotDefinition
{
	var string MapName;
	var string strType;
	var array<string> ValidBiomes;
	var array<MultiplayerBiomeIndex> ValidBiomeFriendlyNames;
	var array<string> ObjectiveTags; // list of tags to match the include/exclude tag lists on a mission
	var float Weight;
	var bool ExcludeFromStrategy;
	var float InitialCameraFacingDegrees;
	var bool ExcludeFromRetailBuilds;
	var MultiplayerPlotIndex FriendlyNameIndex;
	var int FloorCount; // number of floors on this plot
	var float CursorFloorOffset; // if the floor of the plot isn't centered at Z=0, indicates where the base floor is
	var string AudioPlotTypeOverride; // if specified, will use the specified string for the Biome switch (which is the same as gameplay PlotType) in wWise

	structdefaultproperties
	{
		InitialCameraFacingDegrees=1 // use 1 as a sentinel for unset, as it's unlikely anybody would ever shift the camera just one degree
		Weight=1.0
		ExcludeFromRetailBuilds=false
		FloorCount=3
		CursorFloorOffset=-16 // most plots are sunk into the ground by 16 units
	}
};

struct native BiomeDefinition
{
	var string strType;
	var string strDecoEditorLayer;
};

struct native GeneratedMissionData
{
	var int                     MissionID;          //  matches up with the XGMission's m_iID
	var MissionDefinition       Mission;
	var PlotDefinition			Plot;
	var BiomeDefinition			Biome;
	var int						LevelSeed;
	var string					BattleDesc;
	var string					BattleOpName;

	var name					MissionQuestItemTemplate;
};

//-----------------------------------------------------------
// 06/09/2011 - MHU - Notes regarding enum changes as per Casey/JBos
//   WARNING:
//     Enum changes ideally should be done at the end of the list due
//     to the serialization that's done when saving objects that
//     depend on those enums.
//     Changes to the middle of an enum will result in an incorrect
//     (outdated) enum selection for players with older savedata.
//     This is especially true for PIE users (Level Designers) where
//     savedata isn't resaved like it does in the regular game.
//   SOLUTION: 
//     If readability takes priority when altering enums, please request
//     LDs and other users to delete their old savedata.
//-----------------------------------------------------------
enum EDifficultyLevel
{
	eDifficulty_Easy,
	eDifficulty_Normal,
	eDifficulty_Hard,
	eDifficulty_Classic,
};

enum EGameplayOption
{
	// Unlocked when Second Wave is enabled
	eGO_RandomDamage,               // Damage is much more random
	eGO_RandomFunding,              // Random distribution of overall funding
	eGO_RandomRookieStats,          // Random starting stats
	eGO_RandomStatProgression,      // Soldier stats advance randomly
	eGO_RandomPerks,                // Some perks are still class locked but most are not and appear randomly
	eGO_RandomSeed,                 // Generate a new random seed when loading a save game 

		// Unlocked when beating game at Normal Difficulty
	eGO_WoundsAffectStats,          // Soldier HP affects all stats in combat
	eGO_CritOnFlank,                // Guaranteed Critical Hit on flanking
	eGO_InterrogateForPsi,          // Must interrogate a psi alien to unlock the Psi Labs
	eGO_Marathon,                   // Game takes longer

		// Unlocked at Hard
	eGO_PanicAffectsFunding,        // The more panicked a country is, the less it will pay
	eGO_VariableAbductionRewards,   // Abduction rewards are random
	eGO_EscalatingSatelliteCosts,   // Each satellite costs more money to build
	eGO_UltraRarePsionics,          // Psionics are extremely rare
	eGO_ThirstForBlood,             // Allow non-cover-taking aliens to shoot upon pod reveal activation.

		// Unlocked at Classic
	eGO_DecliningFunding,           // Funding declines over time to half of its initial levels
	eGO_DegradingElerium,           // Elerium degrades over time            
	eGO_LoseGearOnDeath,            // When a soldier dies, you lose all of their gear
	eGO_MorePower,                  // Facilities require more power

	// EWI default unlocks 
	eGO_AimingAngles,

	//  Unlocked at Easy
	eGO_MindHatesMatter,            //  No Psi gift with Gene mods, no Gene mods with Psi gift
};

enum EProfileStats
{
	eProfile_NewGameCount,
	eProfile_TutorialComplete,
	eProfile_HighestDifficultyPlayed,
	eProfile_PreferredVolume,
	eProfile_WonGameFronNorthAmerica,
	eProfile_FLContinentsWonFrom,
	eProfile_AliensKilled,
	eProfile_AliensKilledFromExplosions,
	eProfile_GamesCompleted,
	eProfile_EasyGamesCompleted,
	eProfile_NormalGamesCompleted,
	eProfile_HardGamesCompleted,
	eProfile_ClassicGamesCompleted,
	eProfile_UFOsShotDown,
	eProfile_ProgenyComplete,
	eProfile_SlingshotComplete,
};

enum EPlayerEndTurnType
{
	ePlayerEndTurnType_TurnNotOver,
	ePlayerEndTurnType_PlayerInput,
	ePlayerEndTurnType_TimerExpired,
	ePlayerEndTurnType_AllUnitsDone,
	ePlayerEndTurnType_AI,
};

// enum hacks to get around unreal scripts shittyness that doesnt allow constants in one file to be used in static array declarations in another file -tsmith 
// so we can use EnumName.EnumCount for the array size and then eEnumName_MAX for looping and such. -tsmith 
enum ENumPlayers
{
	eNumPlayers_0,
	eNumPlayers_1,
	eNumPlayers_2,
	eNumPlayers_3,
};

enum EShipType
{
	eShip_None,
	eShip_Interceptor,
	eShip_Skyranger,
	eShip_Firestorm,
	eShip_UFOSmallScout,
	eShip_UFOLargeScout,
	eShip_UFOAbductor,
	eShip_UFOSupply,
	eShip_UFOBattle,
	eShip_UFOEthereal
};

enum EMissionType
{
	eMission_None,

	eMission_SP_START,
	eMission_Abduction,
	eMission_Crash,
	eMission_LandedUFO,
	eMission_HQAssault,
	eMission_AlienBase,
	eMission_TerrorSite,
	eMission_Final,
	eMission_Special,
	eMission_DLC,
	eMission_ExaltRaid,
	eMission_AlienFacility,
	eMission_SP_END,

	eMission_MP_START,
	eMission_MPDeathmatch,
	eMission_MPControl,
	eMission_MP_END,

	eMission_Strategy,
	eMission_ReturnToBase,

	eMission_All,
};

enum EMissionTime
{
	eMissionTime_None,
	eMissionTime_Night,
	eMissionTime_Day,
	eMissionTime_DuskDawn,
};

enum EMissionRegion
{
	eMissionRegion_None,
	eMissionRegion_Any,
	eMissionRegion_NorthAmerica,
	eMissionRegion_Europe,
	eMissionRegion_Asia,
	eMissionRegion_SouthHemi,
}; 

enum EItemType
{
	eItem_NONE,
};

enum EUnitType
{
	UNIT_TYPE_Soldier<DisplayName=Soldier>,
	UNIT_TYPE_Tank<DisplayName=Tank>,
	UNIT_TYPE_Alien<DisplayName=Alien>,
	UNIT_TYPE_AlienInUFO<DisplayName=Alien in UFO>,
	UNIT_TYPE_Loot<DisplayName=Loot>,
	UNIT_TYPE_Animal<DisplayName=Animal>,
	UNIT_TYPE_Civilian<DisplayName=Civilian>,
	UNIT_TYPE_Player<DisplayName=Player>,
	UNIT_TYPE_MPTeamOne<DisplayName=MPTeamOne>,
	UNIT_TYPE_MPTeamTwo<DisplayName=MPTeamTwo>,
	UNIT_TYPE_CovertOperative<DisplayName=Covert Operative>,
 };

enum EWorldRegion
{
	eWorldRegion_AtlanticSeaboard,
	eWorldRegion_PacificSeaboard,
	eWorldRegion_CentralAmerica,
	eWorldRegion_SouthAmerica,
	eWorldRegion_WestAfrica,
	eWorldRegion_SouthAfrica,
	eWorldRegion_WesternEurope,
	eWorldRegion_EasternEurope,
	eWorldRegion_SouthAsia,
	eWorldRegion_EastAsia,

	eWorldRegion_GreatPlains,
	eWorldRegion_NorthAmerica,
	eWorldRegion_Antarctica,
	eWorldRegion_NortheastAfrica,
	eWorldRegion_Scandinavia,
	eWorldRegion_CentralAsia,

	eWorldRegion_Yukon,
	eWorldRegion_Amazon,
	eWorldRegion_Greenland,
	eWorldRegion_SubSaharanAfrica,
	eWorldRegion_MiddleEast,
	eWorldRegion_Siberia,
	eWorldRegion_SoutheastAsia,
	eWorldRegion_Australia,
};

enum EContinent
{
	eContinent_NorthAmerica,//0
	eContinent_SouthAmerica,//1
	eContinent_Europe,//2
	eContinent_Asia,//3
	eContinent_Africa,//4
};

enum ESalvageType
{
	eSalvage_NONE,
	eSalvage_Food,
	eSalvage_Supplies,
	eSalvage_Alloys,
	eSalvage_Elerium,
	eSalvage_Web,
	eSalvage_Item,
	eSalvage_END,
};

/*
 * CAUTION: When adding a new material type, please make an entry for it in the following places:
 * - OLD: UNUSED: HitEffectContainer class (so bullet impacts will spawn for this material type.)
 * - Any FootstepSoundCollection classes that exist in any UPK files
 */
enum EMaterialType
{
	MaterialType_Default,
	MaterialType_Wood,
	MaterialType_Grass,
	MaterialType_Dirt,
	MaterialType_Water,
	MaterialType_Metal,
	MaterialType_ShallowWater,
	MaterialType_HumanFlesh,
	MaterialType_AlienFlesh,
	MaterialType_Foliage,
	MaterialType_Masonry,
	MaterialType_Cloth,
	MaterialType_Glass,
	MaterialType_Hay,
	MaterialType_Garbage,
	MaterialType_GroceryProduce,
	MaterialType_GroceryBoxes,
	MaterialType_GroceryCans,
	MaterialType_AsphaltTarRoof,
	MaterialType_WoodAndGlass,
	MaterialType_Mud,
	MaterialType_Plastic,
	MaterialType_MachineHuman,
	MaterialType_MachineAlien,
	MaterialType_Gravel,
	MaterialType_Alien_Panel,
};

enum EArmorKit
{
	eKit_None,

	eKit_AssaultRifle_Kevlar,
	eKit_AssaultRifle_Skeleton,
	eKit_AssaultRifle_Carapace,
	eKit_AssaultRifle_Ghost,
	eKit_AssaultRifle_Titan,

	eKit_Shotgun_Kevlar,
	eKit_Shotgun_Skeleton,
	eKit_Shotgun_Carapace,
	eKit_Shotgun_Ghost,
	eKit_Shotgun_Titan,

	eKit_LMG_Kevlar,
	eKit_LMG_Skeleton,
	eKit_LMG_Carapace,
	eKit_LMG_Ghost,
	eKit_LMG_Titan,

	eKit_SniperRifle_Kevlar,
	eKit_SniperRifle_Skeleton,
	eKit_SniperRifle_Carapace,
	eKit_SniperRifle_Ghost,
	eKit_SniperRifle_Titan,

	eKit_LaserAssaultRifle_Kevlar,
	eKit_LaserAssaultRifle_Skeleton,
	eKit_LaserAssaultRifle_Carapace,
	eKit_LaserAssaultRifle_Ghost,
	eKit_LaserAssaultRifle_Titan,

	eKit_HeavyLaser_Kevlar,
	eKit_HeavyLaser_Skeleton,
	eKit_HeavyLaser_Carapace,
	eKit_HeavyLaser_Ghost,
	eKit_HeavyLaser_Titan,

	eKit_LaserSniperRifle_Kevlar,
	eKit_LaserSniperRifle_Skeleton,
	eKit_LaserSniperRifle_Carapace,
	eKit_LaserSniperRifle_Ghost,
	eKit_LaserSniperRifle_Titan,

	eKit_PlasmaLightRifle_Kevlar,
	eKit_PlasmaLightRifle_Skeleton,
	eKit_PlasmaLightRifle_Carapace,
	eKit_PlasmaLightRifle_Ghost,
	eKit_PlasmaLightRifle_Titan,

	eKit_PlasmaAssaultRifle_Kevlar,
	eKit_PlasmaAssaultRifle_Skeleton,
	eKit_PlasmaAssaultRifle_Carapace,
	eKit_PlasmaAssaultRifle_Ghost,
	eKit_PlasmaAssaultRifle_Titan,

	eKit_AlloyCannon_Kevlar,
	eKit_AlloyCannon_Skeleton,
	eKit_AlloyCannon_Carapace,
	eKit_AlloyCannon_Ghost,
	eKit_AlloyCannon_Titan,

	eKit_HeavyPlasma_Kevlar,
	eKit_HeavyPlasma_Skeleton,
	eKit_HeavyPlasma_Carapace,
	eKit_HeavyPlasma_Ghost,
	eKit_HeavyPlasma_Titan,

	eKit_PlasmaSniperRifle_Kevlar,
	eKit_PlasmaSniperRifle_Skeleton,
	eKit_PlasmaSniperRifle_Carapace,
	eKit_PlasmaSniperRifle_Ghost,
	eKit_PlasmaSniperRifle_Titan,

	eKit_LaserAssaultGun_Kevlar,
	eKit_LaserAssaultGun_Skeleton,
	eKit_LaserAssaultGun_Carapace,
	eKit_LaserAssaultGun_Ghost,
	eKit_LaserAssaultGun_Titan,

	eKit_Deco_Kevlar_START,
	eKit_Deco_Kevlar0,
	eKit_Deco_Kevlar1,
	eKit_Deco_Kevlar2,
	eKit_Deco_Kevlar3,
	eKit_Deco_Kevlar4,
	eKit_Deco_Kevlar5,
	eKit_Deco_Kevlar6,
	eKit_Deco_Kevlar7,
	eKit_Deco_Kevlar8,
	eKit_Deco_Kevlar9,
	eKit_Deco_Kevlar10,
	eKit_Deco_Kevlar11,
	eKit_Deco_Kevlar_END,

	eKit_Deco_Skeleton_START,
	eKit_Deco_Skeleton0,
	eKit_Deco_Skeleton1,
	eKit_Deco_Skeleton2,
	eKit_Deco_Skeleton3,
	eKit_Deco_Skeleton4,
	eKit_Deco_Skeleton5,
	eKit_Deco_Skeleton6,
	eKit_Deco_Skeleton7,
	eKit_Deco_Skeleton8,
	eKit_Deco_Skeleton9,
	eKit_Deco_Skeleton10,
	eKit_Deco_Skeleton11,
	eKit_Deco_Skeleton_END,

	eKit_Deco_Carapace_START,
	eKit_Deco_Carapace0,
	eKit_Deco_Carapace1,
	eKit_Deco_Carapace2,
	eKit_Deco_Carapace3,
	eKit_Deco_Carapace4,
	eKit_Deco_Carapace5,
	eKit_Deco_Carapace6,
	eKit_Deco_Carapace7,
	eKit_Deco_Carapace8,
	eKit_Deco_Carapace9,
	eKit_Deco_Carapace10,
	eKit_Deco_Carapace11,
	eKit_Deco_Carapace_END,

	eKit_Deco_Ghost_START,
	eKit_Deco_Ghost0,
	eKit_Deco_Ghost1,
	eKit_Deco_Ghost2,
	eKit_Deco_Ghost3,
	eKit_Deco_Ghost4,
	eKit_Deco_Ghost5,
	eKit_Deco_Ghost6,
	eKit_Deco_Ghost7,
	eKit_Deco_Ghost8,
	eKit_Deco_Ghost9,
	eKit_Deco_Ghost10,
	eKit_Deco_Ghost11,
	eKit_Deco_Ghost_END,

	eKit_Deco_Titan_START,
	eKit_Deco_Titan0,
	eKit_Deco_Titan1,
	eKit_Deco_Titan2,
	eKit_Deco_Titan3,
	eKit_Deco_Titan4,
	eKit_Deco_Titan5,
	eKit_Deco_Titan6,
	eKit_Deco_Titan7,
	eKit_Deco_Titan8,
	eKit_Deco_Titan9,
	eKit_Deco_Titan10,
	eKit_Deco_Titan11,
	eKit_Deco_Titan_END,

	eKit_Deco_Archangel_START,
	eKit_Deco_Archangel0,
	eKit_Deco_Archangel1,
	eKit_Deco_Archangel2,
	eKit_Deco_Archangel3,
	eKit_Deco_Archangel4,
	eKit_Deco_Archangel5,
	eKit_Deco_Archangel6,
	eKit_Deco_Archangel7,
	eKit_Deco_Archangel8,
	eKit_Deco_Archangel9,
	eKit_Deco_Archangel10,
	eKit_Deco_Archangel11,
	eKit_Deco_Archangel_END,

	eKit_Deco_Psi_START,
	eKit_Deco_Psi0,
	eKit_Deco_Psi1,
	eKit_Deco_Psi2,
	eKit_Deco_Psi3,
	eKit_Deco_Psi4,
	eKit_Deco_Psi5,
	eKit_Deco_Psi6,
	eKit_Deco_Psi7,
	eKit_Deco_Psi8,
	eKit_Deco_Psi9,
	eKit_Deco_Psi10,
	eKit_Deco_Psi11,
	eKit_Deco_Psi_END,

	eKit_Deco_Genemod_START,
	eKit_Deco_Genemod0,
	eKit_Deco_Genemod1,
	eKit_Deco_Genemod2,
	eKit_Deco_Genemod3,
	eKit_Deco_Genemod4,
	eKit_Deco_Genemod5,
	eKit_Deco_Genemod6,
	eKit_Deco_Genemod7,
	eKit_Deco_Genemod8,
	eKit_Deco_Genemod9,
	eKit_Deco_Genemod10,
	eKit_Deco_Genemod11,
	eKit_Deco_Genemod_END,
};

enum EDiscState
{
	eDS_None,
	eDS_Good,   // Active Unit
	eDS_Ready,  // Not Active, but hasn't used up his turn yet
	eDS_Hidden, // Dont show unit ring
	eDS_Bad,    // Alien
	eDS_Red,    // Visible & Red unit ring (for panicked state)
	eDS_ReactionAlien,
	eDS_ReactionHuman,
	//eDS_Hover,  //Mouse hovering over a unit for selection
	eDS_AttackTarget,
};

// Temporarily kept as we transition away from enums for speech IDs to strings.
// Only needed because a few things have not yet transitioned over.
// mdomowicz 2015_06_03
enum ECharacterSpeech
{
	eCharSpeech_COUNT
};


enum ECharacterVoice
{
	eCharVoice_Male_BEGIN,
	eCharVoice_MaleSoldier1,
	eCharVoice_MaleSoldier2,
	eCharVoice_MaleSoldier3,
	eCharVoice_MaleSoldier4,
	eCharVoice_MaleSoldier5,
	eCharVoice_MaleSoldier6,
	eCharVoice_MaleSoldier7,
	eCharVoice_MaleSoldier8,
	eCharVoice_MaleSoldier9,
	eCharVoice_Male_END,

	eCharVoice_Female_BEGIN,
	eCharVoice_FemaleSoldier1,
	eCharVoice_FemaleSoldier2,
	eCharVoice_FemaleSoldier3,
	eCharVoice_FemaleSoldier4,
	eCharVoice_FemaleSoldier5,
	eCharVoice_FemaleSoldier6,
	eCharVoice_Female_END,

	eCharVoice_Brash_Male_BEGIN,
	eCharVoice_MaleSoldier1_Brash,
	eCharVoice_MaleSoldier2_Brash,
	eCharVoice_MaleSoldier3_Brash,
	eCharVoice_MaleSoldier4_Brash,
	eCharVoice_MaleSoldier5_Brash,
	eCharVoice_MaleSoldier6_Brash,
	eCharVoice_MaleSoldier7_Brash,
	eCharVoice_MaleSoldier8_Brash,
	eCharVoice_MaleSoldier9_Brash,
	eCharVoice_Brash_Male_END,

	eCharVoice_Brash_Female_BEGIN,
	eCharVoice_FemaleSoldier1_Brash,
	eCharVoice_FemaleSoldier2_Brash,
	eCharVoice_FemaleSoldier3_Brash,
	eCharVoice_Brash_Female_END,

	eCharVoice_Alien_BEGIN,
	eCharVoice_Sectoid,
	eCharVoice_Sectoid_Commander,
	eCharVoice_Floater,
	eCharVoice_Floater_Heavy,
	eCharVoice_Muton,
	eCharVoice_Muton_Elite,
	eCharVoice_Muton_Berserker,
	eCharVoice_ThinMan,
	eCharVoice_Elder,
	eCharVoice_CyberDisc,
	eCharVoice_Reaper,
	eCharVoice_Chryssalid,
	eCharVoice_Sectopod,
	eCharVoice_SectopodDrone,
	eCharVoice_Zombie,
	eCharVoice_Alien_END,

	eCharVoice_MaleMec_BEGIN,
	eCharVoice_MaleMec1,
	eCharVoice_MaleMec2,
	eCharVoice_MaleMec_END,

	eCharVoice_FemaleMec_BEGIN,
	eCharVoice_FemaleMec1,
	eCharVoice_FemaleMec2,
	eCharVoice_FemaleMec_END,

	eCharVoice_MaleBlueshirt_BEGIN,
	eCharVoice_MaleBlueshirt1,
	eCharVoice_MaleBlueshirt_END,

	eCharVoice_FemaleBlueshirt_BEGIN,
	eCharVoice_FemaleBlueshirt1,
	eCharVoice_FemaleBlueshirt_END,


};

enum ETipTypes
{
	eTip_Tactical,
	eTip_Strategy
};

enum EAlienPodType
{
	ePodType_Soldier,
	ePodType_Commander,
	ePodType_Secondary,
	ePodType_Roaming,
};
struct native TAlienPod
{
	var EAlienPodType eType;
	var name nMain;
	var name nSupport1;
	var name nSupport2;
};
struct native TAlienSquad
{
	var array<TAlienPod> arrPods;
	var int iNumDynamicAliens;
};

// MHU - Number of coverpoints that the XGUnitVisibilityInformation storing sytem
//       can handle. There should be the same number here as there are cover point directions
//       possible.
//       NOTE: We can't rely only on XComCoverNativeType's ECoverDir enums because
//             each of its index describes a specific orientation. The enum below
//             merely describes claimed cover points that can be of any orientation.
enum EUnitVisibilityInformation_CoverPoint
{
	eUVICP_CoverPointA,
	eUVICP_CoverPointB,
	eUVICP_CoverPointC,
	eUVICP_CoverPointD
};

cpptext
{
	NO_DEFAULT_CONSTRUCTOR(UXGGameData)
};


defaultproperties
{
}
