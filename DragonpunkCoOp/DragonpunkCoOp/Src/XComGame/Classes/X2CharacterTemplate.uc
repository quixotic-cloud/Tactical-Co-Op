//---------------------------------------------------------------------------------------
//  FILE:    X2CharacterTemplate.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2CharacterTemplate extends X2DataTemplate config(GameData_CharacterStats)
	native(core)
	dependson(X2TacticalGameRulesetDataStructures, X2StrategyGameRulesetDataStructures, XGNarrative);

struct native ForceLevelSpawnWeight
{
	// The minimum force level at which this spawn weights will be applied
	var() int MinForceLevel;

	// The maximum force level at which this spawn weights will be applied
	var() int MaxForceLevel;

	// The weight for this character type to spawn
	var() float SpawnWeight;

	// The weight for this character type to spawn when alert level is maxed
	var() float MaxAlertSpawnWeight;
};

// This is the name of the character group this template belongs to.  For each character group, the first time a unit of that group is seen by XCom will be 
// treated as a big reveal, and the group will also be used as the classification mechanic for the Shadow Chamber to identify unique enemy types.  
// Templates which do not specify a group will not have big reveals and will not appear in the Shadow Chamber display.
var(X2CharacterTemplate) config Name        CharacterGroupName;

var(X2CharacterTemplate) config float CharacterBaseStats[ECharStatType.EnumCount]<BoundEnum=ECharStatType>;
var(X2CharacterTemplate) int UnitSize;
var(X2CharacterTemplate) int UnitHeight;
var(X2CharacterTemplate) config float XpKillscore;
var(X2CharacterTemplate) config int DirectXpAmount;
var(X2CharacterTemplate) int MPPointValue;
var(X2CharacterTemplate) class<XGAIBehavior> BehaviorClass;
var(X2CharacterTemplate) float VisionArcDegrees;	// The limit, in degrees, of this unit's vision

var(X2CharacterTemplate) array<name> Abilities;
var(X2CharacterTemplate) LootCarrier Loot;
var(X2CharacterTemplate) LootCarrier TimedLoot;
var(X2CharacterTemplate) LootCarrier VultureLoot;
var(X2CharacterTemplate) name        DefaultLoadout;
var(X2CharacterTemplate) name        RequiredLoadout;
var(X2CharacterTemplate) array<AttachedComponent> SubsystemComponents;
var(X2CharacterTemplate) config array<name> HackRewards;       //  Names of HackRewardTemplates that are available for this unit
var(X2CharacterTemplate) config Vector AvengerOffset;       //  Used for offseting cosmetic pawns from their owning pawn in the avenger

// Any requirements to be met before this character template is permitted to spawn using normal spawning rules.
var(X2CharacterTemplate) StrategyRequirement SpawnRequirements;

// The configuration values for the spawn weights for this character template at each Force Level
var(X2CharacterTemplate) config array<ForceLevelSpawnWeight> UntetheredLeaderLevelSpawnWeights;
var(X2CharacterTemplate) config array<ForceLevelSpawnWeight> LeaderLevelSpawnWeights;
var(X2CharacterTemplate) config array<ForceLevelSpawnWeight> FollowerLevelSpawnWeights;
var(X2CharacterTemplate) config array<ForceLevelSpawnWeight> CivilianLevelSpawnWeights;

// The maximum number of characters of this type that can spawn into the same spawning group (pod).
var(X2CharacterTemplate) config int MaxCharactersPerGroup;

// The list of Characters (specified by template name) which can ever be selected as followers when this Character
// is selected as a Pod Leader.
var(X2CharacterTemplate) config array<Name> SupportedFollowers;
	
// Traversal flags
var(Pathing)bool bCanUse_eTraversal_Normal;
var(Pathing)bool bCanUse_eTraversal_ClimbOver;
var(Pathing)bool bCanUse_eTraversal_ClimbOnto;
var(Pathing)bool bCanUse_eTraversal_ClimbLadder;
var(Pathing)bool bCanUse_eTraversal_DropDown;
var(Pathing)bool bCanUse_eTraversal_Grapple;
var(Pathing)bool bCanUse_eTraversal_Landing;
var(Pathing)bool bCanUse_eTraversal_BreakWindow;
var(Pathing)bool bCanUse_eTraversal_KickDoor;
var(Pathing)bool bCanUse_eTraversal_JumpUp;
var(Pathing)bool bCanUse_eTraversal_WallClimb;
var(Pathing)bool bCanUse_eTraversal_Phasing;
var(Pathing)bool bCanUse_eTraversal_BreakWall;
var(Pathing)bool bCanUse_eTraversal_Launch;
var(Pathing)bool bCanUse_eTraversal_Flying;
var(Pathing)bool bCanUse_eTraversal_Land;
var(Pathing)int  MaxFlightPitchDegrees; // when flying up/down, how far is the unit allowed to pitch into the flight path?
var(Pathing)float SoloMoveSpeedModifier;	// Play rate of the run animations when the character moves alone.

var(Flags)bool bIsTooBigForArmory;
var(Flags)bool bCanBeCriticallyWounded;
var(Flags)bool bCanBeCarried;                   // true if this unit can be carried when incapacitated
var(Flags)bool bCanBeRevived;					// true if this unit can be revived by Revival Protocol ability
var(Flags)bool bCanBeTerrorist;                 // Is it applicable to use this unit on a terror mission? (eu/ew carryover)
var(Flags)bool bDiesWhenCaptured;				// true if unit dies instead of going MIA
var(Flags)bool bAppearanceDefinesPawn;          // If true, the appearance information assembles a unit pawn. True for soldiers & civilians, false for Aliens & Advent (they're are all one piece)
var(Flags)bool bIsAfraidOfFire;                 // will panic when set on fire - only applies to flamethrower
var(Flags)bool bIsAlien;                        // used by targeting 
var(Flags)bool bIsAdvent;                       // used by targeting 
var(Flags)bool bIsCivilian;                     // used by targeting
var(Flags)bool bDisplayUIUnitFlag;              // used by UnitFlag
var(Flags)bool bNeverSelectable;                // used by TacticalController
var(Flags)bool bIsHostileCivilian;				// used by spawning
var(Flags)bool bIsPsionic;                      // used by targeting 
var(Flags)bool bIsRobotic;                      // used by targeting 
var(Flags)bool bIsSoldier;                      // used by targeting 
var(Flags)bool bIsCosmetic;						// true if this unit is visual only, and has no effect on game play or has a separate game state for game play ( such as the gremlin )
var(Flags)bool bIsTurret;                       // true iff this character is a turret
var(Flags)bool bCanTakeCover;                   // by default should be true, but certain large units, like mecs and andromedons, etc, don't take cover, so set to false.
var(Flags)bool bIsExalt;                        // used by targeting; deprecated - (eu/ew carryover)
var(Flags)bool bIsEliteExalt;                   // used by targeting; deprecated - (eu/ew carryover)
var(Flags)bool bSkipDefaultAbilities;	        // Will not add the default ability set (Move, Dash, Fire, Hunker Down).
var(Flags)bool bDoesNotScamper;			        // Unit will not scamper when encountering the enemy.
var(Flags)bool bDoesAlwaysFly;                  //TODO dslonneger: this needs to be removed/updated when the the X2 flying system is overhauled
												//Units that always fly will not be snapped to the ground while alive
var(Flags)bool bAllowSpawnInFire;				// If true, this unit can spawn in fire-occupied tiles
var(Flags)bool bAllowSpawnInPoison;				// If true, this unit can spawn in poison-occupied tiles
var(Flags)bool bAllowSpawnFromATT;				// If true, this unit can be spawned from an Advent Troop Transport
var(Flags)bool bFacesAwayFromPod;				// If true, this unit will face away from the pod instead of towards it
var(Flags)bool bLockdownPodIdleUntilReveal;		// If true, this unit will not be able to do anything between the pod idle and the reveal (won't turn to face)
var(Flags)bool bWeakAgainstTechLikeRobot;		// If true, this unit can be hit by tech (i.e. bluescreen rounds, emp, etc) like a robotic unit

var(Flags)bool bIsMeleeOnly;					//true if this unit has no ranged attacks. Used primarily for flank checks

var(Flags)bool bUsePoolSoldiers;                //Character pool - Which pool category this character falls under
var(Flags)bool bUsePoolVIPs;                    //"
var(Flags)bool bUsePoolDarkVIPs;                //"

var(Flags)bool bIsScientist;					// used for staffing
var(Flags)bool bIsEngineer;						// used for staffing
var(Flags)bool bStaffingAllowed;				// used for staffing gameplay
var(Flags)bool bAppearInBase;					// used for the unit visually appearing as a filler unit in the base
var(Flags)bool bWearArmorInBase;				// if this unit should wear their full armor around the base instead of an underlay
var array<name> AppearInStaffSlots;				// if bAppearInBase is true, the character will still be allowed to appear in staff slots in this list

var(Flags)bool bBlocksPathingWhenDead;          // If true, units cannot path into or through the tile(s) this unit is on when dead.
var(Flags)bool bCanTickEffectsEveryAction;      // If true, persistent effects will be allowed to honor the bCanTickEveryAction flag
var(Flags)bool bManualCooldownTick;             // If true, ability cooldowns will not automatically decrease at the start of this unit's turn

var(Flags)bool bHideInShadowChamber;			// If true, do not display this enemy in pre-mission Shadow Chamber lists
var(Flags)bool bDontClearRemovedFromPlay;		// Used for strategy state units, should not change their bRemovedFromPlay status when entering tactical

var(X2CharacterTemplate) array<string> strPawnArchetypes;
var(X2CharacterTemplate) localized string strCharacterName;
var(X2CharacterTemplate) localized array<string> strCharacterBackgroundMale;
var(X2CharacterTemplate) localized array<string> strCharacterBackgroundFemale;
var(X2CharacterTemplate) localized string strCharacterHealingPaused; // Unique string to display if the character's healing project is paused
var(X2CharacterTemplate) localized string strForcedFirstName; // Certain characters have set names
var(X2CharacterTemplate) localized string strForcedLastName; // Certain characters have set names
var(X2CharacterTemplate) localized string strForcedNickName; // Certain characters have set names
var(X2CharacterTemplate) localized string strCustomizeDesc; // Certain characters need unique strings to describe their customization options
var(X2CharacterTemplate) localized string strAcquiredText; // Certain characters need to display additional information in their unit acquired pop-up
var(X2CharacterTemplate) config array<string> strMatineePackages;    // names of the packages that contains this character's cinematic matinees
var(X2CharacterTemplate) string strTargetingMatineePrefix;  // prefix of the character specific targeting matinees for this character
var(X2CharacterTemplate) string strIntroMatineeSlotPrefix;  // prefix of the matinee groups this character can fill in mission intros
var(X2CharacterTemplate) string strLoadingMatineeSlotPrefix;  // prefix of the matinee groups this character can fill in the loading interior
var(X2CharacterTemplate) string strHackIconImage;               // The path to the icon for the hacking UI
var(X2CharacterTemplate) string strTargetIconImage;             // The path to the icon for the targeting UI

// if this delegate is specified, it will be called to determine the appropriate reveal to play.
// otherwise, the default is to use RevealMatineePrefix, and if that is blank, the matinee package name
var(X2CharacterTemplate) delegate<GetRevealMatineePrefix> GetRevealMatineePrefixFn;
var(X2CharacterTemplate) string RevealMatineePrefix;

var(X2CharacterTemplate) bool bSetGenderAlways; //This flag indicates that this character should always get a gender assigned, use on characters where bAppearanceDefinesPawn is FALSE but they want a gender anyways
var(X2CharacterTemplate) bool bForceAppearance; //Indicates that this character should use ForceAppearance to set its appearance
var(X2CharacterTemplate) bool bHasFullDefaultAppearance; // This character's default appearance should be used when creating the unit (not just by the character generator)
var(X2CharacterTemplate) config TAppearance ForceAppearance; //If bForceAppearance and bAppearanceDefinesPawn are true, this structure can be used to force this character type to use a certain appearance
var(X2CharacterTemplate) config TAppearance DefaultAppearance; //Use to force a set of default appearance settings for this character. For instance - setting their armor tint to a specific value
var(X2CharacterTemplate) class<UICustomize> UICustomizationMenuClass; // UI menu class for customizing this soldier
var(X2CharacterTemplate) class<UICustomize> UICustomizationInfoClass; // UI info class for customizing this soldier
var(X2CharacterTemplate) class<UICustomize> UICustomizationPropsClass; // UI props class for customizing this soldier
var(X2CharacterTemplate) class<XComCharacterCustomization> CustomizationManagerClass; // Customization manager for this soldier class
var(X2CharacterTemplate) class<XGCharacterGenerator> CharacterGeneratorClass;   // customize the class used for character generation stuff (random appearances, names, et cetera)
var(X2CharacterTemplate) name                        DefaultSoldierClass;   // specific soldier class to set on creation
var(X2CharacterTemplate) name						 PhotoboothPersonality; // if this character uses a different personality than the default in the photobooth


var(X2CharacterTemplate) string strBehaviorTree;   	// By default all AI behavior trees use "GenericAIRoot".
var(X2CharacterTemplate) string strPanicBT;        // Behavior Tree for panicking units.
var(X2CharacterTemplate) string strScamperBT;      // Behavior Tree for scampering units.
var(X2CharacterTemplate) float AIMinSpreadDist;        // Distance (meters) to prefer being away from other teammates. (Destinations within this range get their scores devalued with multiplier below)
													//defaults to class'XGAIBehavior'.DEFAULT_AI_MIN_SPREAD_DISTANCE when unset.
var(X2CharacterTemplate) float AISpreadMultiplier;     // Multiplier value to apply to locations within above spread distance.  Should be in range (0..1).
												// defaults to class'XGAIBehavior'.DEFAULT_AI_SPREAD_WEIGHT_MULTIPLIER when unset.

var(X2CharacterTemplate) array<int> SkillLevelThresholds; // Used to determine non-soldier leveling

var(X2CharacterTemplate) array<XComNarrativeMoment> SightedNarrativeMoments;	// Add to array in order of conversation
var(X2CharacterTemplate) array<name>				SightedEvents;				// These events are triggered upon any sighting
var(X2CharacterTemplate) name						DeathEvent;					// This event is triggered when a unit of this character type is killed
var(X2CharacterTemplate) delegate<OnRevealEvent>	OnRevealEventFn;			// This event triggers when the character is revealed on a mission

var(X2CharacterTemplate) string SpeakerPortrait; // Portrait that shows in a comm link if spoken by this character

var(X2CharacterTemplate) string HQIdleAnim;
var(X2CharacterTemplate) string HQOffscreenAnim;
var(X2CharacterTemplate) string HQOnscreenAnimPrefix;
var(X2CharacterTemplate) Vector HQOnscreenOffset;

var(X2CharacterTemplate) name ReactionFireDeathAnim;	//The animation to play when killed by reaction fire.

var(X2CharacterTemplate) delegate<OnStatAssignmentComplete> OnStatAssignmentCompleteFn;
var(X2CharacterTemplate) delegate<OnEndTacticalPlay> OnEndTacticalPlayFn;
var(X2CharacterTemplate) bool bIgnoreEndTacticalHealthMod; // Do not adjust health at the end of tactical missions
var(X2CharacterTemplate) bool bIgnoreEndTacticalRestoreArmor; // Do not restore armor at the end of tactical missions
var(X2CharacterTemplate) delegate<OnCosmeticUnitCreated> OnCosmeticUnitCreatedFn;
var(X2CharacterTemplate) delegate<GetPhotographerPawnName> GetPhotographerPawnNameFn;

var array<name> ImmuneTypes;
var bool CanFlankUnits;

var bool bAllowRushCam; // should usually be turned off for very large units, as the camera will be too close
var bool bDisablePodRevealMovementChecks; // for stationary aliens, forces no checks for pod reveal matinees moving into walls

var private transient TAppearance FilterAppearance;

// some characters need to do different reveal matinees based on their current state.
// this delegate allows characters to specify that matinee prefix
delegate string GetRevealMatineePrefix(XComGameState_Unit UnitState);

// to modify game states after the character has been revealed
delegate OnRevealEvent(XComGameState_Unit UnitState);

// some characters need to have modified stats after they are created
delegate OnStatAssignmentComplete(XComGameState_Unit UnitState);

// to handle any special stuff after a cosmetic unit has been created in tactical - this should be placed on the "owning" unit template, not the cosmetic unit template
delegate OnCosmeticUnitCreated(XComGameState_Unit CosmeticUnit, XComGameState_Unit OwnerUnit, XComGameState_Item SourceItem, XComGameState StartGameState);

// some characters do not use the standard M/F soldier pawn when in the strategy layer
delegate name GetPhotographerPawnName();

// modify stats and game states when tactical play ends, such as health mods
delegate OnEndTacticalPlay(XComGameState_Unit UnitState);

function XComGameState_Unit CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit'));	 
	Unit.OnCreation(self);	

	return Unit;
}


private function bool FilterPawnWithGender(X2BodyPartTemplate Template)
{
	local bool bValidTemplate;

	bValidTemplate = Template.CharacterTemplate == DataName; //Verify that it fits this character type
	bValidTemplate = bValidTemplate && FilterAppearance.iGender == int(Template.Gender); //Verify gender

	return bValidTemplate;
}

private function bool FilterPawnWithoutGender(X2BodyPartTemplate Template)
{
	local bool bValidTemplate;

	bValidTemplate = Template.CharacterTemplate == DataName; //Verify that it fits this character type
	bValidTemplate = bValidTemplate && FilterAppearance.iGender == int(Template.Gender); //Verify gender

	return bValidTemplate;
}

simulated function string GetPawnArchetypeString(XComGameState_Unit kUnit, optional const XComGameState_Unit ReanimatedFromUnit = None)
{
	local string SelectedArchetype;
	local X2BodyPartTemplate ArmorPartTemplate;	

	//If bAppearanceDefinesPawn is set to TRUE, then the pawn's base mesh is the head, and the rest of the parts of the body are customizable
	if (bAppearanceDefinesPawn)
	{
		//Supporting legacy unit configurations, where nmTorso was the pawn		
		if(!bForceAppearance && kUnit.kAppearance.nmPawn == '')
		{
			FilterAppearance = kUnit.kAppearance;
			ArmorPartTemplate = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().GetRandomUberTemplate("Pawn", self, FilterPawnWithGender);
			if(ArmorPartTemplate == none)
			{
				ArmorPartTemplate = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().GetRandomUberTemplate("Pawn", self, FilterPawnWithoutGender);
			}
		}
		else
		{	
			FilterAppearance = bForceAppearance ? ForceAppearance : kUnit.kAppearance;
			ArmorPartTemplate = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().FindUberTemplate("Pawn", FilterAppearance.nmPawn);
		}
				
		if(ArmorPartTemplate != none)
		{
			return ArmorPartTemplate.ArchetypeName;
		}
			
		`assert(false);
	}

	
	//If we have a gender, assign a pawn based on that
	if(EGender(kUnit.kAppearance.iGender) != eGender_None)
	{
		SelectedArchetype = strPawnArchetypes[kUnit.kAppearance.iGender - 1];
	}
	
	//If the gender selection failed, or we are genderless then randomly pick from the list
	if(SelectedArchetype == "")
	{
		SelectedArchetype = strPawnArchetypes[`SYNC_RAND(strPawnArchetypes.Length)];
	}

	return SelectedArchetype;
}

native function bool IsSimCombatPodLeader(int ForceLevel);
native function bool IsSimCombatPodFollower(int ForceLevel);

cpptext
{
public:
	virtual void PostLoad();

	FLOAT GetUntetheredLeaderSpawnWeight(INT ForceLevel, UBOOL bMaxAlertLevel) const;
	FLOAT GetLeaderSpawnWeight(INT ForceLevel, UBOOL bMaxAlertLevel) const;
	FLOAT GetFollowerSpawnWeight(INT ForceLevel, UBOOL bMaxAlertLevel) const;
	FLOAT GetCivilianSpawnWeight(INT ForceLevel, UBOOL bMaxAlertLevel) const;
	
private:
	FLOAT GetSpawnWeightForForceLevel(const TArray<FForceLevelSpawnWeight>& SpawnWeights, INT ForceLevel, UBOOL bMaxAlertLevel) const;
};

DefaultProperties
{
	VisionArcDegrees=360
	TemplateAvailability=BITFIELD_GAMEAREA_Singleplayer // Defaulting all Character Templates to Singleplayer; NOTE: Must manually add Multiplayer to characters!
	bAllowSpawnFromATT=true
	AIMinSpreadDist=-1 // default value forces use of class'XGAIBehavior'.DEFAULT_AI_MIN_SPREAD_DISTANCE when unset
	strBehaviorTree = "GenericAIRoot"
	strPanicBT = "PanickedRoot"
	strScamperBT = "GenericScamperRoot"
	strTargetingMatineePrefix="CIN_Soldier_FF_StartPos"

	MaxFlightPitchDegrees=89
	SoloMoveSpeedModifier=1.0f;

	bIsHostileCivilian = false;
	CanFlankUnits = true;

	UnitSize = 1;
	UnitHeight = 2;

	bUsePoolSoldiers = false;
	bUsePoolVIPs = false;
	bUsePoolDarkVIPs = false;
	bDisplayUIUnitFlag=true;

	bAllowRushCam=true

	UICustomizationMenuClass = class'UICustomize_Menu'
	UICustomizationInfoClass = class'UICustomize_Info'
	UICustomizationPropsClass = class'UICustomize_Props'
	CustomizationManagerClass = class'XComCharacterCustomization'

	bShouldCreateDifficultyVariants=true
}