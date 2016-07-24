//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XGTacticalGameCoreNativeBase extends Actor
	dependson (XGTacticalGameCoreData)
	native(Core)
	config(GameCore)
	abstract;

// Gameplay values
const SCREEN_PC_BUFFER = 0.25f;           //  percent of screen space to consider as "off screen" for PC input purposes
const GRENADE_TOUCH_RADIUS = 46.0f;

// Close Combat Values
const CC_RANGE = 3.0f;                  // The radius, in meters, at which close combat is triggered

// UI Values
const HP_PER_TICK = 1;                  // How may HP are represented by an individual block displayed by the UI
const HP_PULSE_PCT = 25;                // If the HP are at or below this percentage, then we will pulse the controller.

// Jetpack
const JETPACK_FUEL_HOVER_COST = 1;

// MHU - Slow motion parameters. 
const TIMEDILATION_APPROACHRATE = 15.0f;  // MHU - Linear approach rate (how fast) to reach the desired time dilation values specified below.

const TIMEDILATION_MODE_NORMAL = 1.0f;
const TIMEDILATION_MODE_VICTIMOFOVERWATCH = 0.01f;
const TIMEDILATION_MODE_REACTIONFIRING = 0.4f;
// MHU - DO NOT CHANGE THE BELOW VALUE. We don't trigger reaction fire when pod activations are playing (too many things fighting for camera control)
const TIMEDILATION_MODE_TRIGGEREDPODACTIVATION = 0.0f; 

const NATIVE_RADTODEG = 57.295779513082321600f;
const NATIVE_DEGTORAD = 0.017453292519943296f;
const FLANKINGTOLERANCE = 3.0f; //Degrees - gives the flank check some wiggle room in case the target or the shooter are not centered in their tiles

const MAX_FORCE_LEVEL_UI_VAL = 20;
// jboswell: these are here because they need to be native
enum EGender
{
	eGender_None,
	eGender_Male,
	eGender_Female
};

enum ECharacterRace
{
	eRace_Caucasian,
	eRace_African,
	eRace_Asian,
	eRace_Hispanic,
};

enum ECivilianType
{
	eCivilian_Warm,
	eCivilian_Cold,
	eCivilian_Formal,
	eCivilian_Soldier,
};

//World Data Structures
//==========================================================================================

enum ECoverDir
{
	eCD_North,
	eCD_South,
	eCD_East,
	eCD_West,
};

enum ETraversalType
{
	eTraversal_None,
	eTraversal_Normal,
	eTraversal_ClimbOver,
	eTraversal_ClimbOnto,
	eTraversal_ClimbLadder,
	eTraversal_DropDown,
	eTraversal_Grapple,
	eTraversal_Landing,
	eTraversal_BreakWindow,
	eTraversal_KickDoor,
	eTraversal_WallClimb, //Chryssalid invisible ladder - Keep wall climb before JumpUp because chrysallid can do both, and this makes him use wall climbs rather than Jump up where possible.
	eTraversal_JumpUp, //Thin man multi-story leap ( reverse drop down )
	eTraversal_Ramp, //The traversal type entering or leaving a ramp
	eTraversal_BreakWall, // This is not strictly a traversal type, but instructs the pathing system that the unit can pass through walls like large units can (and apply damage to the environment)
	eTraversal_Phasing, // This is not strictly a traversal type, but instructs the pathing system that the unit can pass through walls like large units can
	
	// the next three flying traversals are not baked into the level data, they are generated at pathing time
	// and exist as means to describe these traversals to the 
	eTraversal_Launch, // transitioning from running to flying
	eTraversal_Flying, // in flight
	eTraversal_Land, // transitioning from flying to landing
	eTraversal_Teleport,
	eTraversal_Unreachable,
};

enum EPathType
{
	ePathType_Normal,
	ePathType_PathObject,
	ePathType_Dropdown
};

struct native XComCoverPoint
{
	var int X;
	var int Y;
	var int Z;

	var Vector TileLocation;
	var Vector ShieldLocation;
	var Vector CoverLocation;
	var int Flags;

	structcpptext
	{
		FXComCoverPoint()
			: X(0), Y(0), Z(0)
			, TileLocation(0.0f, 0.0f, 0.0f)
			, ShieldLocation(0.0f, 0.0f, 0.0f)
			, CoverLocation(0.0f, 0.0f, 0.0f)
			, Flags(0)
		{
		}

		explicit FXComCoverPoint(INT ThankYouEpic)
			: X(0), Y(0), Z(0)
			, TileLocation(0.0f, 0.0f, 0.0f)
			, ShieldLocation(0.0f, 0.0f, 0.0f)
			, CoverLocation(0.0f, 0.0f, 0.0f)
			, Flags(0)
		{
		}

		FORCEINLINE void SetIndices(INT InX, INT InY, INT InZ)
		{
			X = InX;
			Y = InY;
			Z = InZ;
		}

		UBOOL operator==(const FXComCoverPoint &Other) const
		{
			return X == Other.X && Y == Other.Y && Z == Other.Z;
		}

		UBOOL operator!=(const FXComCoverPoint &Other) const
		{  
			return !(*this == Other);
		}

		friend inline DWORD GetTypeHash(const FXComCoverPoint &Cover)
		{
			return Cover.X*1024+Cover.Y*128+Cover.Z;
		}
	}
};

struct native ViewerInfo
{
	var int TileX;
	var int TileY;
	var int TileZ;
	var float SightRadius;
	var int SightRadiusRaw;
	var int SightRadiusTiles;
	var int SightRadiusTilesSq;
	var Actor AssociatedActor;
	var Vector PositionOffset;
	var bool bNeedsTextureUpdate;
	var bool bHasSeenXCom; //RAM - a flag for aliens to store whether an XCom unit has ever been within their sight radius

	structcpptext
	{
	FViewerInfo() :
	AssociatedActor(NULL)
	{
	}

	FViewerInfo(EEventParm)
	{
		appMemzero(this, sizeof(FViewerInfo));
	}
	}
};

struct native PathingTraversalData
{
	var TTile Tile;
	var float AStarG_Modifier;		
	var bool bLargeUnitOnly;
	var bool bPhasingUnitOnly;

	//Cached information relating to path object traversals ( climb onto, drop down, etc. )
	var Actor PathObject;
	var init array<ETraversalType>  TraversalTypes;
	var init array<Vector>          Positions;

	structcpptext
	{
		FPathingTraversalData()
			: PathObject(NULL)
			, Tile(0, 0, 0)
			, AStarG_Modifier(0.0f)
			, bLargeUnitOnly(false)
			, bPhasingUnitOnly(false)
		{
		}
	}
};

struct native FloorTileData
{
	var Vector FloorLocation;
	var Vector FloorNormal;	
	var Vector AltFloorNormal;
	var Actor  FloorActor;	
	var Actor  FloorVolume; // The floor volume this tile is inside of, if there is one
	var init array<PathingTraversalData> Neighbors;
	var byte RampDirection; //Uses flag setup of TileDataBlocksPathingXXX
	var byte SupportedUnitSize;

	structcpptext //RAM - the bizarre formatting is necessary for it to be properly formatted in the H
	{

	FFloorTileData() :
		FloorLocation( 0, 0, 0 ),
		FloorNormal( 0, 0, 0 ),
		AltFloorNormal(0, 0, 0),
		FloorActor(NULL),
		FloorVolume(NULL),
		RampDirection(0),
		SupportedUnitSize(0)
	{		
	}

	}
};

struct native FlightTraversalNeighbor
{
	var TTile NeighborTile;
	var Actor BlockingActor;

	structcpptext
	{
		FFlightTraversalNeighbor() : BlockingActor(0)
		{		
		}
	}
};

// note that unlike floor traversal data, flight tile data is not exhaustive. If there is no
// entry in the matrix for an air tile, it does not mean that flight is invalid. It means it is valid
// and unrestricted.
struct native FlightTileData
{
	var array<FlightTraversalNeighbor> Neighbors;

	structcpptext
	{
		FFlightTileData()
		{		
			memset(this, 0, sizeof(FFlightTileData));
		}
	}
};

struct native VolumeEffectTileData
{
	/**This is the X2Effect associated with creating this tile data*/
	var name EffectName;

	/**This X2Effect is applied each turn*/
	var name TurnUpdateEffectName;

	var int SourceStateObjectID;      //  if effect was applied by an ability from a unit, this is that unit
	var int ItemStateObjectID;        //  the weapon associated with the ability that created the effect, if any

	/**This tracks how many turns this effect has remaining. This is not an absolute value, it depends on how the effect is updated*/
	var int NumTurns;
	/**If > 0, will cause this effect to spread from this tile out to a tile radius of NumHops*/
	var int NumHops;
	/**The template to use for the fire particles*/
	var ParticleSystem VolumeEffectParticleTemplate;
	/**Tracks the fire effect for this tile*/
	var ParticleSystemComponent VolumeEffectParticles;
	/**Controls for the particle effect*/
	var int Intensity;
	/**ADVANCED USE: If non-zero, specifies that in addition to updating the game play tile data in world data this effect also modifies the dynamic flags for the tile. This
	 *               permits the effect status to modify voxel ray trace results. This is a flag, so it must be a power of 2*/
	var int DynamicFlagUpdateValue;

	var bool LDEffectTile; // This tile data was placed by an LD and should follow slightly different rules than normal.
	// turns don't decrement as normal, only spread when in view of the player

	var init array<TTile> ParticleSystemCoveredTiles;	// all the tiles that this effect data is covering.
	var TTile CoveringTile;								// the tile that has the particle effect covering this tile

	structcpptext
	{
		FVolumeEffectTileData() :
		EffectName(NAME_None),
		TurnUpdateEffectName(NAME_None),
		NumTurns(0),
		NumHops(0),
		VolumeEffectParticleTemplate(NULL),
		VolumeEffectParticles(NULL),
		Intensity(0),
		DynamicFlagUpdateValue(0),
		SourceStateObjectID(0),
		ItemStateObjectID(0),
		LDEffectTile(false),
		ParticleSystemCoveredTiles(0),
		CoveringTile( -1, -1, -1 )
		{
		}
		FVolumeEffectTileData( EEventParm )
		{
			appMemzero( this, sizeof(FVolumeEffectTileData) );
		}
	}
};

struct native CoverTileData
{
	var Vector ShieldLocation;
	var Vector CoverLocation;

	structcpptext
	{

	FCoverTileData( ) : 
		CoverLocation(0, 0, 0), ShieldLocation(0, 0, 0)
	{
	}

	}
};

struct native XComInteractPoint
{
	var Vector Location;
	var Rotator Rotation;
	var XComInteractiveLevelActor InteractiveActor;
	var name InteractSocketName;
	var int ModifyTileStaticFlags; //TileStatic flags that should be set / unset based on interactions

	structcpptext
	{
		FXComInteractPoint() :
			Location(0,0,0),
			Rotation(0,0,0),
			InteractiveActor(NULL),
			InteractSocketName(NAME_None)
		{
		}

		UBOOL operator==(const FXComInteractPoint &Other)
		{
			return (Location == Other.Location && 
				Rotation == Other.Rotation && 
				InteractiveActor == Other.InteractiveActor && 
				InteractSocketName == Other.InteractSocketName &&
				ModifyTileStaticFlags == Other.ModifyTileStaticFlags);
		}
	}
};

struct native PeekAroundInfo
{
	var int     bHasPeekaround;
	var int		bRequiresLean;	//Set to 1 if this peek around does not allow for full step out animation. The character will lean instead.
	var vector  PeekaroundLocation;
	var vector	DistanceCheckLocation;	//Cached value representing a point near the top of the tile that can be used in distance comparisons against the 'default' tile
	var vector  PeekaroundDirectionFromCoverPt;
	var TTile   PeekTile;

	structcpptext
	{
	FPeekAroundInfo()
	{
		appMemzero(this, sizeof(FPeekAroundInfo));
	}
	FPeekAroundInfo(EEventParm)
	{
		appMemzero(this, sizeof(FPeekAroundInfo));
	}
	FORCEINLINE UBOOL operator==(const FPeekAroundInfo &Other) const
	{
		return (bHasPeekaround == Other.bHasPeekaround) && 
			   PeekaroundLocation == Other.PeekaroundLocation &&
			   PeekaroundDirectionFromCoverPt == Other.PeekaroundDirectionFromCoverPt &&
			   PeekTile == Other.PeekTile;		
	}
	}
};

struct native CoverDirectionPeekData
{
	var PeekAroundInfo LeftPeek;
	var PeekAroundInfo RightPeek;
	var vector  CoverDirection;
	var int     bHasCover;

	structcpptext
	{
	FCoverDirectionPeekData()
	{
		appMemzero(this, sizeof(FCoverDirectionPeekData));
	}
	FCoverDirectionPeekData(EEventParm)
	{
		appMemzero(this, sizeof(FCoverDirectionPeekData));
	}
	FORCEINLINE UBOOL operator==(const FCoverDirectionPeekData &Other) const
	{
		return (LeftPeek == Other.LeftPeek) && 
			   RightPeek == Other.RightPeek &&
			   CoverDirection == Other.CoverDirection &&
			   bHasCover == Other.bHasCover;
	}
	}
};

struct native CachedCoverAndPeekData
{
	var CoverDirectionPeekData CoverDirectionInfo[4];
	var vector  DefaultVisibilityCheckLocation;	
	var TTile   DefaultVisibilityCheckTile;
	var int     bDefaultTileValid;	

	structcpptext
	{
	FCachedCoverAndPeekData()
	{
		appMemzero(this, sizeof(FCachedCoverAndPeekData));
	}
	FCachedCoverAndPeekData(EEventParm)
	{
		appMemzero(this, sizeof(FCachedCoverAndPeekData));
	}
	FORCEINLINE UBOOL operator==(const FCachedCoverAndPeekData &Other) const
	{
		return (CoverDirectionInfo[0] == Other.CoverDirectionInfo[0]) && 
			   (CoverDirectionInfo[1] == Other.CoverDirectionInfo[1]) && 
			   (CoverDirectionInfo[2] == Other.CoverDirectionInfo[2]) && 
			   (CoverDirectionInfo[3] == Other.CoverDirectionInfo[3]) && 
			   DefaultVisibilityCheckLocation == Other.DefaultVisibilityCheckLocation &&
			   DefaultVisibilityCheckTile == Other.DefaultVisibilityCheckTile &&
			   bDefaultTileValid == Other.bDefaultTileValid;
	}
	}
};

const TINVENTORY_MAX_LARGE_ITEMS = 16;
const TINVENTORY_MAX_SMALL_ITEMS = 16;
const TINVENTORY_MAX_CUSTOM_ITEMS = 16;

const RELATIVE_HEIGHT_BONUS_ZDIFF = 192.0f;
const RELATIVE_HEIGHT_BONUS_WEAPON_RANGE = 1.5f;

struct native TInventory
{
	/***************************************************************************
	 * WARNING!!!
	 * if this struct grows beyond 256 bytes you need to replicate each piece
	 * seperately in whatever instanced object it is attached to.
	 * see XGCharacter::ReplicatedTCharacter_XXX for the pattern.
	 ***************************************************************************/
	var int iArmor<BoundEnum=EItemType>;                 				// EItemType
	var int iPistol<BoundEnum=EItemType>;                				// The pistol slot (A pistol is required)
	var const   int arrLargeItems[TINVENTORY_MAX_LARGE_ITEMS];
	var const   int iNumLargeItems;
	var const   int arrSmallItems[TINVENTORY_MAX_SMALL_ITEMS]; 	    // Any small items this unit is carrying 
	var const   int iNumSmallItems;
	var const   int arrCustomItems[TINVENTORY_MAX_CUSTOM_ITEMS];    // This array holds custom items (psionics/plague/etc)
	var const   int iNumCustomItems;
	/***************************************************************************
	 * WARNING!!!
	 * if this struct grows beyond 256 bytes you need to replicate each piece
	 * seperately in whatever instanced object it is attached to.
	 * see XGCharacter::ReplicatedTCharacter_XXX for the pattern.
	 ***************************************************************************/
};

struct native TCharacter
{
	/***************************************************************************
	 * WARNING!!!
	 * if you change/add ANY data members of the struct then you MUST change/add
	 * the corresponing XGCharacter::ReplicatedTCharacter_XXX variable -tsmith
	 ***************************************************************************/
	var string      strName<FGDEIndex=0>;
	var name        TemplateName;              // CharacterTemplate Name
	var TInventory  kInventory;
	var int         aTraversals[ETraversalType.EnumCount]<FGDEIgnore=true>;
	var bool        bHasPsiGift;
	var class<XGAIBehavior> BehaviorClass<FGDEIgnore=true>;
	/***************************************************************************
	 * WARNING!!!
	 * if you change/add ANY data members of the struct then you MUST change/add
	 * the corresponing XGCharacter::ReplicatedTCharacter_XXX variable -tsmith
	 ***************************************************************************/
};

struct native TAppearance
{
	/***************************************************************************
	 * WARNING!!!
	 * if this struct grows beyond 256 bytes you need to replicate each piece
	 * seperately in whatever instanced object it is attached to.
	 * see XGCharacter::ReplicatedTCharacter_XXX for the pattern.
	 ***************************************************************************/
	var name nmHead; // Head content to use ( morphs + additive anim )	
	var int iGender; // EGender
	var int iRace; // ECharacterRace
	var name nmHaircut;
	var int iHairColor; // jboswell: Pixel in the color palette texture (0, iHairColor)
	var int iFacialHair; // jboswell: Index into MIC for face/skin material
	var name nmBeard;		
	var int iSkinColor; // jboswell: which color from the skin color palette, if needed
	var int iEyeColor; // jboswell: which color from the eye color palette, if needed
	var name nmFlag; // jboswell: name of Country Template, copied from TSoldier during creation	
	var int iVoice; // mdomowicz 2015_05_26 : no longer used, but kept to avoid serialization changes in CharacterPoolManager.cpp, for now.
	var int iAttitude; // ECharacterAttitude
	var int iArmorDeco; // EArmorKit
	var int iArmorTint;
	var int iArmorTintSecondary;
	var int iWeaponTint;	
	var int iTattooTint;
	var name nmWeaponPattern;
	var name nmPawn; //Specifies the base pawn to use ( for humans, this is set from gender )
	var name nmTorso;
	var name nmArms;
	var name nmLegs;
	var name nmHelmet;
	var name nmEye;
	var name nmTeeth;
	var name nmFacePropLower;
	var name nmFacePropUpper;
	var name nmPatterns;
	var name nmVoice;
	var name nmLanguage;
	var name nmTattoo_LeftArm;
	var name nmTattoo_RightArm;
	var name nmScars;
	var name nmTorso_Underlay;
	var name nmArms_Underlay;
	var name nmLegs_Underlay;
	var name nmFacePaint;

	//Added to support armors that allow left arm / right arm customization
	var name nmLeftArm;		
	var name nmRightArm;	
	var name nmLeftArmDeco;	
	var name nmRightArmDeco;
};

struct native ExtensibleAppearanceElement
{
	var name PartType;
	var name Selection;
};

struct native TWeaponAppearance
{
	/***************************************************************************
	 * WARNING!!!
	 * if this struct grows beyond 256 bytes you need to replicate each piece
	 * seperately in whatever instanced object it is attached to.
	 * see XGCharacter::ReplicatedTCharacter_XXX for the pattern.
	 ***************************************************************************/
	var int iWeaponTint;
	var int iWeaponDeco;
	var name nmWeaponPattern;

	structdefaultproperties
	{
		iWeaponTint=INDEX_NONE
		iWeaponDeco=INDEX_NONE
	}
};

struct native TSoldier
{
	/***************************************************************************
	 * WARNING!!!
	 * if you change/add ANY data members of the struct then you MUST change/add
	 * the corresponing XGCharacter::ReplicatedTCharacter_XXX variable -tsmith
	 ***************************************************************************/
	var int             iID;
	var string      	strFirstName;
	var string      	strLastName;
	var string      	strNickName;
	var int         	iRank;
	var int             iPsiRank;
	var name         	nmCountry;
	var int             iXP;
	var int             iPsiXP;
	var TAppearance     kAppearance;
	/***************************************************************************
	 * WARNING!!!
	 * if you change/add ANY data members of the struct then you MUST change/add
	 * the corresponing XGCharacter::ReplicatedTCharacter_XXX variable -tsmith
	 ***************************************************************************/
};

struct native TVolume
{
	/***************************************************************************
	 * WARNING!!!
	 * if this struct grows beyond 256 bytes you need to replicate each piece
	 * seperately in whatever instanced object it is attached to.
	 * see XGCharacter::ReplicatedTCharacter_XXX for the pattern.
	 ***************************************************************************/
	var EVolumeType     eType;        // The type of volume
	var int             iDuration;    // The duration, if any, of this volume.
	var float           fRadius;      // The radius of this volume
	var float           fHeight;      // The height of this volume
	var Color           clrVolume;    // What is the color of this volume?
	var int             aEffects[EVolumeEffect.EnumCount];    // The effects applied to any unit who enters this volume
	/***************************************************************************
	 * WARNING!!!
	 * if this struct grows beyond 256 bytes you need to replicate each piece
	 * seperately in whatever instanced object it is attached to.
	 * see XGCharacter::ReplicatedTCharacter_XXX for the pattern.
	 ***************************************************************************/
};

var localized string m_strYearSuffix;
var localized string m_strMonthSuffix;
var localized string m_strDaySuffix;

// Tactical consts
var config array<float> FragmentBalance;

var config array<float> TerrorInfectionChance;

var config array<float> ThinManPlagueSlider; // 0-10+ range, 0=never, 5=avg
var config array<float> DeathBlossomSlider;  // Only used when there are targets in the area.
var config array<float> BloodCallSlider;     // Only used when there are mutons available to target.
var config array<float> AlienGrenadeSlider;  // Used when grenade will only hit one target.  (when multiple targets can be hit, auto-use)
var config array<float> SmokeGrenadeSlider;  
var config array<int> MaxActiveAIUnits;      // Limit the maximum number of aliens that can attack the player at one time.

var config float CLOSE_RANGE;                   // In meters

var config int AI_REINFORCEMENTS_DEFAULT_ARRIVAL_TIME;

// Strategy consts
var config int AI_TERRORIZE_MOST_PANICKED;          // Chance the most panicked country will be the terror target
var config int LATE_UFO_CHANCE;                     // Chance that later missions will be a UFO
var config int EARLY_UFO_CHANCE;                     // Chance that earlier missions will be a UFO
var config int  UFO_LIMIT;
var config int UFO_INTERCEPTION_PCT;
var config array<int> UFOAlloys;
var config float MIN_WRECKED_ALLOYS;
var config float MAX_WRECKED_ALLOYS;
var config float MAX_LOST_WRECKED_ELERIUM;
var config float MIN_LOST_WRECKED_ELERIUM;

// MAIN BALANCE
var config float TECH_TIME_BALANCE;                 // Changes time to research a tech
var config float ITEM_TIME_BALANCE;                 // Changes time to build an item
var config float ITEM_CREDIT_BALANCE;
var config float ITEM_ELERIUM_BALANCE;
var config float ITEM_ALLOY_BALANCE;     
var config float FACILITY_COST_BALANCE;             // Costs of facilities are multiplied by this balance factor
var config float FACILITY_MAINTENANCE_BALANCE;      // Facility maintenance is multipled by this balance factor
var config float FACILITY_TIME_BALANCE;             // Facility "Time To Build" is multiplied by this balance factor
var config array<float> ALLOY_UFO_BALANCE;
var config array<float> UFO_ELERIUM_PER_POWER_SOURCE;
// SCIENCE VALUES
var config int NUM_STARTING_SCIENTISTS;
var config int LAB_MINIMUM;                       // How many scientists are required to unlock the first labs?
var config int LAB_MULTIPLE;                      // How many scientists are required to unlock subsequent labs?
var config float LAB_BONUS;                         // Research increase gained by building a lab
var config float LAB_ADJACENCY_BONUS;               // Research increase gained by building adjacent to another lab
// ENGINEERING VALUES
var config int NUM_STARTING_ENGINEERS;
var config int WORKSHOP_MINIMUM;            // How many engineers are required to unlock the first workshop?
var config int WORKSHOP_MULTIPLE;           // How many engineers are required to unlock subsequent workshops?
var config int WORKSHOP_REBATE_PCT;
var config int WORKSHOP_ENG_BONUS;
var config int UPLINK_MULTIPLE;
var config int NEXUS_MULTIPLE;
// SOLDIER VALUES
var config int NUM_STARTING_SOLDIERS;
var config int LOW_AIM;
var config int HIGH_AIM;
var config int LOW_MOBILITY;
var config int HIGH_MOBILITY;
var config int LOW_WILL;
var config int HIGH_WILL;
var config float PSI_GIFT_CHANCE;         // WILL / PSI_GIFT_CHANCE
var config int PSI_TEST_LIMIT;            // Number of soldiers we let the player test before stepping in and just giving them a psi soldier.
var config int PSI_TRAINING_HOURS;        // Hours required to test a soldier for the gift
var config int PSI_NUM_TRAINING_SLOTS;    // Number of slots in the psi labs
var config int BASE_DAYS_INJURED;
var config int RAND_DAYS_INJURED;
var config int SOLDIER_COST;
var config int SOLDIER_COST_HARD;
var config int SOLDIER_COST_CLASSIC;
// HQ VALUES
var config int HQ_STARTING_MONEY;
var config array<int> BASE_FUNDING;
var config array<int> HQ_BASE_POWER;
var config int POWER_NORMAL;
var config int POWER_THERMAL;
var config int POWER_ELERIUM;
var config int POWER_ADJACENCY_BONUS;
var config int NUM_STARTING_STEAM_VENTS;      // Random of [1,NUM_STARTING_STEAM_VENTS)
var config int INTERCEPTOR_REFUEL_HOURS;      // Full refuel in 24 hours
var config int INTERCEPTOR_REPAIR_HOURS;      // Full repair in 1 week
var config int INTERCEPTOR_REARM_HOURS;       // Rearm takes one day
var config int INTERCEPTOR_TRANSFER_TIME;     // Transfer takes 3 days
var config int BASE_SKYRANGER_MAINTENANCE;
var config int SKYRANGER_CAPACITY;            // Num soldiers that can fit on the dropship (To start with)
var config int UPLINK_CAPACITY;
var config int UPLINK_ADJACENCY_BONUS;
var config int NEXUS_CAPACITY;
// BASE BUILDING
var config int BASE_EXCAVATE_CASH_COST;
var config int BASE_REMOVE_CASH_COST;
var config int BASE_EXCAVATE_DAYS;
var config int BASE_REMOVAL_DAYS;
// MISSION VALUES
var config int UFO_CRASH_TIMER;                
var config int TERROR_TIMER;                   
var config int UFO_LANDED_TIMER;               
var config int ABDUCTION_TIMER;                
// UFO VALUES
var config float UFO_PS_SURVIVE;
var config float UFO_NAV_SURVIVE;
var config float UFO_STASIS_SURVIVE;
var config float UFO_SURGERY_SURVIVE;
var config float UFO_ENTERTAINMENT_SURVIVE;
var config float UFO_FOOD_SURVIVE;
var config float UFO_HYPERWAVE_SURVIVE;
var config float UFO_FUSION_SURVIVE;
var config float UFO_PSI_LINK_SURVIVE;      
var config float UFO_FIND_STEALTH_SAT;
var config float UFO_FIND_SAT;
var config float UFO_SECOND_PASS_FIND_STEALTH_SAT;
var config float UFO_SECOND_PASS_FIND_SAT;
// PANIC VALUES
var config int PANIC_TERROR_CONTINENT;
var config int PANIC_TERROR_COUNTRY;
var config int PANIC_UFO_SHOOTDOWN;
var config int PANIC_UFO_ASSAULT;
var config int PANIC_SAT_DESTROYED_CONTINENT;
var config int PANIC_SAT_DESTROYED_COUNTRY;
var config int PANIC_SAT_ADDED_COUNTRY;
var config int PANIC_SAT_ADDED_CONTINENT;
var config int PANIC_ALIENBASE_CONQUERED;
var config int PANIC_ALIENBASE_CONQUERED_CLASSIC_AND_IMPOSSIBLE;
var config int PANIC_EXALT_RAIDED;
var config int PANIC_EXALT_RAIDED_CLASSIC_AND_IMPOSSIBLE;
var config int PANIC_UFO_IGNORED;
var config int PANIC_UFO_ESCAPED;
var config int PANIC_ABDUCTION_COUNTRY_EASY;
var config int PANIC_ABDUCTION_COUNTRY_NORMAL;
var config int PANIC_ABDUCTION_COUNTRY_HARD;
var config int PANIC_ABDUCTION_COUNTRY_CLASSIC;
var config int PANIC_ABDUCTION_CONTINENT_EASY;
var config int PANIC_ABDUCTION_CONTINENT_NORMAL;
var config int PANIC_ABDUCTION_CONTINENT_HARD;
var config int PANIC_ABDUCTION_CONTINENT_CLASSIC;
var config int PANIC_ABDUCTION_THWARTED_CONTINENT;
var config int PANIC_ABDUCTION_THWARTED_COUNTRY;
var config int STARTING_PANIC_EASY;
var config int STARTING_PANIC_NORMAL;
var config int STARTING_PANIC_HARD;
var config int STARTING_PANIC_CLASSIC;
var config int PANIC_DEFECT_THRESHHOLD_EASY;
var config int PANIC_DEFECT_THRESHHOLD_NORMAL;
var config int PANIC_DEFECT_THRESHHOLD_HARD;
var config int PANIC_DEFECT_THRESHHOLD_CLASSIC;
var config int PANIC_DEFECT_THRESHHOLD_NOT_HELPED_EASY;
var config int PANIC_DEFECT_THRESHHOLD_NOT_HELPED_NORMAL;
var config int PANIC_DEFECT_THRESHHOLD_NOT_HELPED_HARD;
var config int PANIC_DEFECT_THRESHHOLD_NOT_HELPED_CLASSIC;
var config int PANIC_DEFECTIONS_PER_MONTH_EASY;
var config int PANIC_DEFECTIONS_PER_MONTH_NORMAL;
var config int PANIC_DEFECTIONS_PER_MONTH_HARD;
var config int PANIC_DEFECTIONS_PER_MONTH_CLASSIC;
var config int PANIC_DEFECT_CHANCE_PER_BLOCK_EASY;
var config int PANIC_DEFECT_CHANCE_PER_BLOCK_NORMAL;
var config int PANIC_DEFECT_CHANCE_PER_BLOCK_HARD;
var config int PANIC_DEFECT_CHANCE_PER_BLOCK_CLASSIC;
var config array<float> SAT_HELP_DEFECT;
var config array<float> SAT_NEARBY_HELP_DEFECT;
var config array<int> SAT_PANIC_REDUCTION_PER_MONTH;
var config array<int> PANIC_5_REDUCTION_CHANCE;
var config array<int> PANIC_4_REDUCTION_CHANCE;
var config array<int> PANIC_LOW_REDUCTION_CHANCE;

var config int OBJECTIVE_GUARD_POD_ALIEN_COUNT_EASY;
var config int OBJECTIVE_GUARD_POD_ALIEN_COUNT_NORMAL;
var config int OBJECTIVE_GUARD_POD_ALIEN_COUNT_HARD;
var config int OBJECTIVE_GUARD_POD_ALIEN_COUNT_CLASSIC;

var config int PARCEL_GUARD_POD_ALIEN_COUNT_EASY;
var config int PARCEL_GUARD_POD_ALIEN_COUNT_NORMAL;
var config int PARCEL_GUARD_POD_ALIEN_COUNT_HARD;
var config int PARCEL_GUARD_POD_ALIEN_COUNT_CLASSIC;

var config int PARCEL_PATROL_POD_ALIEN_COUNT_EASY;
var config int PARCEL_PATROL_POD_ALIEN_COUNT_NORMAL;
var config int PARCEL_PATROL_POD_ALIEN_COUNT_HARD;
var config int PARCEL_PATROL_POD_ALIEN_COUNT_CLASSIC;

var config int PLOT_PATROL_POD_ALIEN_COUNT_EASY;
var config int PLOT_PATROL_POD_ALIEN_COUNT_NORMAL;
var config int PLOT_PATROL_POD_ALIEN_COUNT_HARD;
var config int PLOT_PATROL_POD_ALIEN_COUNT_CLASSIC;

var config int MIN_ENEMY_SPAWNING_SPACING;

var config int REINFORCEMENTS_COOLDOWN_EASY;
var config int REINFORCEMENTS_COOLDOWN_NORMAL;
var config int REINFORCEMENTS_COOLDOWN_HARD;
var config int REINFORCEMENTS_COOLDOWN_CLASSIC;



// CONTINENT BONUS
var config int CB_FUNDING_BONUS;
var config int CB_FUTURECOMBAT_BONUS;
var config int CB_AIRANDSPACE_BONUS;
var config int CB_EXPERT_BONUS;
// SECOND WAVE
var config int ENABLE_SECOND_WAVE;
var config float SW_COVER_INCREASE;
var config float SW_SATELLITE_INCREASE;
var config float SW_ELERIUM_HALFLIFE;   // 1 day
var config float SW_ELERIUM_LOSS;       // 5%
var config float SW_ABDUCTION_SITES;
var config float SW_RARE_PSI;           // Will / SW_RARE_PSI
var config float SW_MARATHON;
var config float SW_MORE_POWER;
var config float SW_AIMING_ANGLE_THRESHOLD;
var config float SW_AIMING_ANGLE_MINBONUS;
var config float SW_AIMING_ANGLE_MAXBONUS;

var config int SPECIES_POINT_LIMIT;

var config float KILL_CAM_MIN_DIST;
var config float RADIAL_DAMAGE_GLASS_BREAK_DISTANCE; //In tiles

cpptext
{
	virtual void PostReloadConfig(UProperty *Property);
}

simulated event Init();

//Needs to be accessed potentially in native code
native simulated function bool IsOptionEnabled( EGameplayOption eOption );

/**
 * Functions to modify TInventory's static arrays as if they were dynamic arrays.
 * 
 * XXXAdd: equivalent to dynamicarray.Add
 * 
 * XXXRemove: equivalent to dynamicarray.Remove
 * 
 * XXXAddItem: equivalent to dynamicarray.AddItem
 * 
 * XXXRemoveItem: equivalent to dynamicyarray.RemoveItem 
 * 
 * XXXSetItem: equivalent to dynamic array [] operator. i.e. passing in an index > num elements
 * will increase the number of elements in the array to fit. the only works if index is < the
 * static size of the array.
 * 
 * XXXClear: equivalent to dynamicarray.Length = 0. it clears the arrays elements and sets # of elements to zero.
 */
native static final function int    TInventoryLargeItemsAdd(out TInventory kInventory, int iCount);
native static final function int    TInventoryLargeItemsRemove(out TInventory kInventory, int idx, int iCount);
native static final function int    TInventoryLargeItemsAddItem(out TInventory kInventory, int iItem);
native static final function int    TInventoryLargeItemsRemoveItem(out TInventory kInventory, int iItem);
native static final function int    TInventoryLargeItemsSetItem(out TInventory kInventory, int idx, int iItem);
native static final function        TInventoryLargeItemsClear(out TInventory kInventory);

native static final function int    TInventorySmallItemsAdd(out TInventory kInventory, int iCount);
native static final function int    TInventorySmallItemsRemove(out TInventory kInventory, int idx, int iCount);
native static final function int    TInventorySmallItemsAddItem(out TInventory kInventory, int iItem);
native static final function int    TInventorySmallItemsRemoveItem(out TInventory kInventory, int iItem);
native static final function int    TInventorySmallItemsSetItem(out TInventory kInventory, int idx, int iItem);
native static final function        TInventorySmallItemsClear(out TInventory kInventory);

native static final function int    TInventoryCustomItemsAdd(out TInventory kInventory, int iCount);
native static final function int    TInventoryCustomItemsRemove(out TInventory kInventory, int idx, int iCount);
native static final function int    TInventoryCustomItemsAddItem(out TInventory kInventory, int iItem);
native static final function int    TInventoryCustomItemsRemoveItem(out TInventory kInventory, int iItem);
native static final function int    TInventoryCustomItemsSetItem(out TInventory kInventory, int idx, int iItem);
native static final function        TInventoryCustomItemsClear(out TInventory kInventory);
native static final function int    TInventoryCustomItemsFind(out TInventory kInventory, int iItem);

native static final function bool   TInventoryHasItemType(const out TInventory kInventory, int iItem);

native static final function class<XGAIBehavior> LookupBehaviorClass(string BehaviorName);

static final function EGender RandomGender()
{
	return EGender(1+rand(2));
}

//---PROXIMITY WEAPONS--------------------------------------------------
// the CLOSE_RANGE here refers to meters, not unreal units; this means that the closeness penalty for sniper rifles kicks in 
// when target is closer than about 8.6 cursor-steps (tiles), and the distance penalty for other weapons kicks in 
// beyond that distance
//--------------------------------------------------------------------
native simulated function int CalcRangeModForWeapon(int iWeapon, XGUnit kViewer, XGUnit kTarget);
native simulated function int CalcRangeModForWeaponAt(int iWeapon, XGUnit kViewer, XGUnit kTarget, vector vViewerLoc);

native simulated function Vector GetRocketLauncherFirePos( XComUnitPawnNativeBase kPawn, Vector TargetLocation, bool bRocketShot );

//native simulated function int CalcAimingAngleMod( XGUnitNativeBase FiringUnit, XGUnitNativeBase TargetUnit );

defaultproperties
{

}	
