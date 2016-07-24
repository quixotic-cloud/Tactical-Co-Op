//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Unit.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: This object represents the instance data for a unit in the tactical game for
//           X-Com
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Unit extends XComGameState_BaseObject 
	implements(X2GameRulesetVisibilityInterface, X2VisualizedInterface, Lootable, UIQueryInterfaceUnit, Damageable, Hackable) 
	dependson(XComCoverInterface)
	native(Core);

//IMPORTED FROM XGStrategySoldier
//@TODO - rmcfall/jbouscher - Refactor these enums? IE. make location a state object reference to something? and make status based on the location?
//*******************************************
enum ESoldierStatus
{
	eStatus_Active,     // not otherwise on a mission or in training
	eStatus_OnMission,  // a soldier out on a dropship
	eStatus_PsiTesting, // a rookie currently training as a Psi Operative
	eStatus_PsiTraining,// a soldier currently learning a new Psi ability
	eStatus_Training,	// a soldier currently training as a specific class or retraining abilities
	eStatus_Healing,    // healing up
	eStatus_Dead,       // ain't nobody comes back from this
};

enum ESoldierLocation
{
	eSoldierLoc_Barracks,
	eSoldierLoc_Dropship,
	eSoldierLoc_Infirmary,
	eSoldierLoc_Morgue,
	eSoldierLoc_PsiLabs,
	eSoldierLoc_PsiLabsCinematic,  // This solider is currently involved in the Psionics narrative moment matinee
	eSoldierLoc_Armory,
	eSoldierLoc_Gollup,
	eSoldierLoc_Outro,
	eSoldierLoc_MedalCeremony,    // Being awarded a medal
};

enum ENameType
{
	eNameType_First,
	eNameType_Last,
	eNameType_Nick,
	eNameType_Full,
	eNameType_Rank,
	eNameType_RankLast,
	eNameType_RankFull,
	eNameType_FullNick,
};

enum EAlertLevel
{
	eAL_None,
	eAL_Green,
	eAL_Yellow,
	eAL_Red,
};

enum EReflexActionState
{
	eReflexActionState_None,               //The default state, the reflex mechanic is not active on this unit	
	eReflexActionState_SelectAction,       //This state is active while the player decides what action to take with their reflex action
	eReflexActionState_ExecutingAction,    //This state is active while the reflex action is being performed
	eReflexActionState_AIScamper,          //This state is unique to the AI and the reflex action it receives when moving to red-alert during X-Com's turn
};

enum EIdleTurretState
{
	eITS_None,
	eITS_AI_Inactive,			// Initial state when on AI team.
	eITS_AI_ActiveTargeting,	// AI team active state, has targets visible.
	eITS_AI_ActiveAlerted,		// AI team active state, has no targets visible.
	eITS_XCom_Inactive,			// Inactive gun-down state on turn after having been hacked.
	eITS_XCom_ActiveTargeting,	// XCom-controlled active state, has targets visible.
	eITS_XCom_ActiveAlerted,	// XCom-controlled active state, has no targets visible.
};

//*******************************************

var() protected name                             m_TemplateName;
var() protected{mutable} transient X2CharacterTemplate     m_CharTemplate;
var() protected name	                         m_SoldierClassTemplateName;
var() protected X2SoldierClassTemplate           m_SoldierClassTemplate;
var   protected name                             m_MPCharacterTemplateName;
var   protected X2MPCharacterTemplate            m_MPCharacterTemplate;
var() bool                                       bAllowedTypeSoldier; //For character pool use - how might this unit be used
var() bool                                       bAllowedTypeVIP;     //"
var() bool                                       bAllowedTypeDarkVIP; //"
var() string                                     PoolTimestamp;       //Time the character was added to character pool
var() protectedwrite array<SCATProgression>      m_SoldierProgressionAbilties;
var() protected int                              m_SoldierRank;
var() int										 StartingRank; // For reward soldiers and cheating up ranks
var() protected int                              m_iXp;
var() protected array<StateObjectReference>      KilledUnits, KillAssists;
var() int										 WetWorkKills;
var() int                                        PsiCredits;    //  Accumulated from taking feedback and treated as XP for Kills/KAs
var() bool                                       bRankedUp;     //  To prevent ranking up more than once after a tactical match.
var() int						                 iNumMissions;
var() int                                        LowestHP;      //  Tracks lowest HP during a tactical match so that strategy heals a soldier based on that.
var() int										 HighestHP;		// Tracks highest HP during a tactical match (b/c armor effects add health, needed to calculate wounds)

var() protected name							 PersonalityTemplateName;
var() protected X2SoldierPersonalityTemplate	 PersonalityTemplate;

var() privatewrite bool bTileLocationAmbiguous; //Indicates that this unit is in the midst of being thrown in rag doll form. The TileLocation will be set when it comes to rest.
var() privatewrite TTile TileLocation;       //Location of the unit on the battle map
var() privatewrite TTile TurnStartLocation;  //Recorded at the start of the unit's turn
var() rotator MoveOrientation;
var() protectedwrite bool bRemovedFromPlay;   // No longer on the battlefield
var() bool bDisabled;          // Unit can take no turns and processes no ai

var() protected CharacterStat CharacterStats[ECharStatType.EnumCount];
var() int               UnitSize;           //Not a stat because it can't change... unless we implement shrink rays. or embiggeners (preposterous)
var() int				UnitHeight;
var() bool              bGeneratesCover;
var() ECoverForceFlag   CoverForceFlag;     //Set when a unit generates cover

var() protectedwrite array<StateObjectReference> InventoryItems;    //Items this units is carrying
var() array<StateObjectReference> MPBaseLoadoutItems;				//Base loadout items for this MP unit, cannot be removed
var() bool bIgnoreItemEquipRestrictions;							//Set to TRUE if this unit should be allowed to gain items without regard for inventory space or class.
var() privatewrite StateObjectReference ControllingPlayer;          //Which player is in control of us
var() array<StateObjectReference> Abilities;                        //Abilities this unit can use - filled out at the start of a tactical battle
var() protected array<TraversalChange> TraversalChanges;            //Cache of traversal changes applied by effects
var() protectedwrite array<StateObjectReference> AffectedByEffects; //List of XComGameState_Effects this unit is the target of
var() protectedwrite array<name> AffectedByEffectNames;				//Parallel to AffectedByEffects with the EffectName
var() protectedwrite array<StateObjectReference> AppliedEffects;    //List of XComGameState_Effects this unit is the source of
var() protectedwrite array<name> AppliedEffectNames;				//Parallel to AppliedEffects with the EffectName
var() array<name> ActionPoints;                                     //Action points available for use this turn
var() array<name> ReserveActionPoints;                              //Action points available for use during the enemy turn
var() array<name> SkippedActionPoints;                              //When the turn is skipped, any ActionPoints remaining are copied into here
var() int StunnedActionPoints, StunnedThisTurn;                     //Number of stunned action points remaining, and stunned actions consumed this turn
var() int Ruptured;                                                 //Ruptured amount is permanent extra damage this unit suffers from each attack.
var() int Shredded;                                                 //Shredded amount is always subtracted from any armor mitigation amount.
var() int Untouchable;                                              //Number of times this unit can freely dodge attacks.

//Store death related information
var() array<name> KilledByDamageTypes;								//Array of damage types from the effect that dealt the killing blow to this unit

var() array<DamageResult> DamageResults;
var() array<name> HackRewards;                  //Randomly chosen from the character template's rewards

var() bool bTriggerRevealAI;                    //Indicates whether this unit will trigger an AI reveal sequence
var() EReflexActionState ReflexActionState;	    //Unit is currently being forced to take a reflex action
var() protectedwrite LootResults PendingLoot;	//Results of rolling for loot 
var() bool bAutoLootEnabled;					//If true, this unit will automatically award it's basic loot table to the Mission Sweep loot pool when it dies
var() bool bKilledByExplosion;
var() bool bGotFreeFireAction;
var() bool bLightningReflexes;                  //Has active lightning reflexes - reaction fire against this target will miss
var() bool bBleedingOut;
var() bool bUnconscious;
var() bool bInStasis;
var() bool bBodyRecovered;                      //If the unit was killed, indicates if the body was recovered successfully
var() bool bTreatLowCoverAsHigh;                //GetCoverTypeFromLocation will return CT_Standing instead of CT_MidLevel
var() bool bPanicked;							// Unit is panicking.
var() bool bStasisLanced;                       // Unit has been hit by a Stasis Lance and is vulnerable to hacking.
var() bool bHasBeenHacked;                      // Unit has been hacked after being Stasis Lanced
var() bool bFallingApplied;
var   int  UserSelectedHackReward;
var() bool bCaptured;                           // unit was abandoned and has been captured by the aliens
var() bool bIsSuperSoldier;						// unit is a summoned super soldier
var() bool bIsSpecial;							// unit is part of a special faction
var() bool bSpawnedFromAvenger;					// unit was spawned from the avenger for a defense mission
var() TDateTime m_RecruitDate;
var() TDateTime m_KIADate; 
var() string m_strCauseOfDeath;
var() string m_strKIAOp;                       // Operation unit died on
var() string m_strEpitaph;

var array<AppearanceInfo> AppearanceStore;

var private native Map_Mirror UnitValues{TMap<FName, FUnitValue>};
var private array<SquadmateScore> SoldierRelationships;

// Alertness and concealment vars
var() private{private} bool m_bConcealed; // In full cover, not flanked or moving from a concealed location
var() bool bConcealedWithHeightAdvantage; //Set to true by passive effects / class abilities.
var() bool m_bSpotted;	// Visible to enemy.
var() bool m_bSubsystem; // This unit is a subsystem of another unit.

var int m_iTeamsThatAcknowledgedMeByVO; // Bitflags for remembering which teams have played VO due to seeing this unit.

var() EIdleTurretState IdleTurretState;

//var int m_SuppressionHistoryIndex;
var XComGameStateContext_Ability m_SuppressionAbilityContext;
var StateObjectReference m_SpawnedCocoonRef; // Units may die while parthenogenic poison is on them, thus causing a cocoon to grow out of them
var StateObjectReference m_MultiTurnTargetRef; // Some abilities are delayed and the source should keep looking at the target, this allows that

var array<Name> CurrentHackRewards; // The template name of the current hack rewards in effect on this unit.

var StateObjectReference ConcealmentBrokenByUnitRef; // The ref of the unit that saw this unit, causing it to lose concealment
var bool bUnitWasFlanked;	// true if concealment was broken due to being flanked

var int MPSquadLoadoutIndex;	// index into the mp squad array

var() array<int> HackRollMods;	// A set of modifiers for the current hack


//================================== BEGIN LEGACY CODE SUPPORT ==============================================
//                           DO NOT USE THESE VARIABLES FOR NEW FEATURES
/**
 *  THESE VARS HAVE BEEN COPIED FROM TSoldier AND ARE NOT REFACTORED YET
 */
var() protected string      strFirstName;
var() protected string      strLastName;
var() protected string      strNickName;
var() protected string      strBackground;
var() protected name        nmCountry;
var() TAppearance           kAppearance;
/**
 *  END TSoldier VARS
 */

/**
 *  THESE VARS HAVE BEEN COPIED FROM TCharacter AND ARE NOT REFACTORED YET
 */
var() protected int         aTraversals[ETraversalType.EnumCount]<FGDEIgnore=true>;

/**
 *  END TCharacter VARS
 */

var StateObjectReference	StaffingSlot;
var() int					SkillValue; // Non-soldier XP
var() float					SkillLevelBonus; // From staffing slots
var() bool					bHasPsiGift;
var() bool					bRolledForPsiGift;

// Healing Flags
var() bool							bIsShaken; // Unit is Shaken after being gravely injured
var() bool							bIsShakenRecovered; // Unit has recovered from being Shaken
var() bool							bSeenShakenPopup; // If the Shaken popup has been presented to the player for this unit
var() bool							bNeedsShakenRecoveredPopup; // If the Shaken recovered needs to be presented to the player for this unit
var() int							SavedWillValue; // The unit's old Will value before they were shaken
var() int							MissionsCompletedWhileShaken;
var() int							UnitsKilledWhileShaken;

// New Class Popup
var() bool							bNeedsNewClassPopup; // If the new class popup has been presented to the player for this unit

// Advanced Warfare Abilities
var() bool							bRolledForAWCAbility;
var() bool							bSeenAWCAbilityPopup; // If the AWC Ability popup has been presented to the player for this unit
var() array<ClassAgnosticAbility>	AWCAbilities;

// Psi Abilities - only for Psi Operatives
var() array<SCATProgression>		PsiAbilities;

// Old Inventory Items (before items made available b/c of healing, etc.)
var() array<EquipmentInfo>	OldInventoryItems;

//@TODO - rmcfall - Copied wholesale from strategy. Decide whether these values are still relevant or not!
//*********************************************************************************************************
var private eSoldierStatus      HQStatus;
var private ESoldierLocation    HQLocation;
var int						    m_iEnergy;
var int						    m_iInjuryPoints;
var int                         m_iInjuryHours;
var string                      m_strKIAReport;
var bool					    m_bPsiTested;
var bool					    bForcePsiGift;
var transient XComUnitPawn      m_kPawn;

var duplicatetransient Array<XComGameState_Unit_AsyncLoadRequest> m_asynchronousLoadRequests;

var transient bool bIsInCreate;
var transient bool bHandlingAsyncRequests;

var private transient int CachedUnitDataStateObjectId;


delegate OnUnitPawnCreated( XComGameState_Unit Unit);

//================================== END LEGACY CODE SUPPORT ==============================================


native function GetVisibilityForLocation(const out TTile FromLocation, out array<TTile> VisibilityTiles) const;

//================================== Visibility Interface ==============================================
/// <summary>
/// Used to supply a tile location to the visibility system to use for visibility checks
/// </summary>
native function NativeGetVisibilityLocation(out array<TTile> VisibilityTiles) const;
native function NativeGetKeystoneVisibilityLocation(out TTile VisibilityTile) const;

function GetVisibilityLocation(out array<TTile> VisibilityTiles)
{
	NativeGetVisibilityLocation(VisibilityTiles);
}

function GetKeystoneVisibilityLocation(out TTile VisibilityTile)
{
	NativeGetKeystoneVisibilityLocation(VisibilityTile);
}

native function float GetVisionArcDegrees();

event GetVisibilityExtents(out Box VisibilityExtents)
{
	local Vector HalfTileExtents;
	local TTile MaxTile;

	HalfTileExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;

	MaxTile = TileLocation;
	MaxTile.X += UnitSize - 1;
	MaxTile.Y += UnitSize - 1;
	MaxTile.Z += UnitHeight - 1;

	VisibilityExtents.Min = `XWORLD.GetPositionFromTileCoordinates( TileLocation ) - HalfTileExtents;
	VisibilityExtents.Max = `XWORLD.GetPositionFromTileCoordinates( MaxTile ) + HalfTileExtents;
	VisibilityExtents.IsValid = 1;
}

function SetVisibilityLocationFromVector( const out Vector VisibilityLocation )
{
	local TTile TempTile;

	TempTile = `XWORLD.GetTileCoordinatesFromPosition(VisibilityLocation);

	SetVisibilityLocation(TempTile);
}

/// <summary>
/// Used by the visibility system to manipulate this state object's VisibilityTile while analyzing game state changes
/// </summary>
event SetVisibilityLocation(const out TTile VisibilityTile)
{
	local array<Object> PreFilterObjects;
	local X2EventManager EventManager;
	local XComWorldData WorldData;
	local Vector NewUnitLocation, OldUnitLocation;
	local Object TestObject;
	local Volume TestVolume;
	local bool NeedsToCheckVolumeTouches, NeedsToCheckExitTouches;
	local XComGroupSpawn Exit;
	local array<TTile> AllVisibilityTiles;
	local TTile AllVisibilityTilesIter;


	if( TileLocation != VisibilityTile )
	{
		// if there are any listeners for 'UnitTouchedVolume', get the volumes and test this unit's movement against those 
		// volumes to determine if a touch event occurred
		EventManager = `XEVENTMGR;

		NeedsToCheckVolumeTouches = EventManager.GetPreFiltersForEvent( 'UnitTouchedVolume', PreFilterObjects );

		Exit = `PARCELMGR.LevelExit;
		NeedsToCheckExitTouches = ( 
			Exit != None && 
			Exit.IsVisible() && 
			EventManager.AnyListenersForEvent( 'UnitTouchedExit' ) );

		WorldData = `XWORLD;
		if( NeedsToCheckVolumeTouches || NeedsToCheckExitTouches )
		{
			NewUnitLocation = WorldData.GetPositionFromTileCoordinates(VisibilityTile);
			OldUnitLocation = WorldData.GetPositionFromTileCoordinates(TileLocation);
		}

		//Clear the stored peek and cover data around the OLD location. It will be reconstructed the next time it is needed ( for visibility ). This is necessary since our move could have
		//effects on nearby tiles ( such as requiring an adjacent unit to need to lean / step out a shorter distance )
		GetVisibilityLocation(AllVisibilityTiles);
		foreach AllVisibilityTiles(AllVisibilityTilesIter)
		{
			WorldData.ClearVisibilityDataAroundTile(AllVisibilityTilesIter);
		}

		TileLocation = VisibilityTile;
		bRequiresVisibilityUpdate = true;

		//Clear the stored peek and cover data around the NEW location. It will be reconstructed the next time it is needed ( for visibility ). This is necessary since our move could have
		//effects on nearby tiles ( such as requiring an adjacent unit to need to lean / step out a shorter distance )
		GetVisibilityLocation(AllVisibilityTiles);
		foreach AllVisibilityTiles(AllVisibilityTilesIter)
		{
			WorldData.ClearVisibilityDataAroundTile(AllVisibilityTilesIter);
		}

		if( NeedsToCheckVolumeTouches )
		{
			foreach PreFilterObjects(TestObject)
			{
				TestVolume = Volume(TestObject);

				if( TestVolume.ContainsPoint(NewUnitLocation) &&
					!TestVolume.ContainsPoint(OldUnitLocation) )
				{
					EventManager.TriggerEvent( 'UnitTouchedVolume', self, TestVolume, GetParentGameState() );
				}
			}
		}

		if( NeedsToCheckExitTouches )
		{
			if( Exit.IsLocationInside(NewUnitLocation) &&
				!Exit.IsLocationInside(OldUnitLocation) )
			{
				EventManager.TriggerEvent( 'UnitTouchedExit', self,, GetParentGameState() );
			}
		}
		ApplyToSubsystems(SetVisibilityLocationSub);
	}
}

function SetVisibilityLocationSub( XComGameState_Unit kSubsystem )
{
	kSubsystem.SetVisibilityLocation(TileLocation);
}

private simulated function string GenerateAppearanceKey(int eGender, name ArmorTemplate)
{
	local string GenderArmor;
	local X2BodyPartTemplate ArmorPartTemplate;
	local X2BodyPartTemplateManager BodyPartMgr;

	if (eGender == -1)
	{
		eGender = kAppearance.iGender;
	}

	if (ArmorTemplate == '')
	{
		BodyPartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
		ArmorPartTemplate = BodyPartMgr.FindUberTemplate("Torso", kAppearance.nmTorso);
		if (ArmorPartTemplate == none)
		{
			return "";
		}

		ArmorTemplate = ArmorPartTemplate.ArmorTemplate;
	}

	GenderArmor = string(ArmorTemplate) $ eGender;
	return GenderArmor;
}

simulated function StoreAppearance(optional int eGender = -1, optional name ArmorTemplate)
{
	local AppearanceInfo info;
	local int idx;
	local string GenderArmor;

	GenderArmor = GenerateAppearanceKey(eGender, ArmorTemplate);
	`assert(GenderArmor != "");

	info.GenderArmorTemplate = GenderArmor;
	info.Appearance = kAppearance;

	idx = AppearanceStore.Find('GenderArmorTemplate', GenderArmor);
	if (idx != -1)
	{
		AppearanceStore[idx] = info;
	}
	else
	{
		AppearanceStore.AddItem(info);
	}
}

simulated function bool HasStoredAppearance(optional int eGender = -1, optional name ArmorTemplate)
{
	local string GenderArmor;
	GenderArmor = GenerateAppearanceKey(eGender, ArmorTemplate);
	return (AppearanceStore.Find('GenderArmorTemplate', GenderArmor) != -1);
}

simulated function GetStoredAppearance(out TAppearance appearance, optional int eGender = -1, optional name ArmorTemplate)
{
	local string GenderArmor;
	local int idx;
	local name UnderlayTorso;
	local name UnderlayArms;
	local name UnderlayLegs;

	GenderArmor = GenerateAppearanceKey(eGender, ArmorTemplate);
	`assert(GenderArmor != "");

	idx = AppearanceStore.Find('GenderArmorTemplate', GenderArmor);
	`assert(idx != -1);

	//Save the underlay settings
	UnderlayTorso = appearance.nmTorso_Underlay;
	UnderlayArms = appearance.nmArms_Underlay;
	UnderlayLegs = appearance.nmLegs_Underlay;

	appearance = AppearanceStore[idx].Appearance;

	//Restore. Put this in a helper method if we need to do more of this
	appearance.nmTorso_Underlay = UnderlayTorso;
	appearance.nmArms_Underlay = UnderlayArms;
	appearance.nmLegs_Underlay = UnderlayLegs;
}

native function XComGameState_Item GetPrimaryWeapon();
native function XComGameState_Item GetSecondaryWeapon();

/// <summary>
/// Used to determine whether a target is in range or not
/// </summary>
event float GetVisibilityRadius()
{
	return GetCurrentStat(eStat_SightRadius);
}

//Apply unit specific logic to determine whether the target is visible or not. The result of this method is used to set CheckVisibilityInfo.bVisibleGameplay, don't use
//CheckVisibilityInfo.bVisibleGameplay in this method. Also, when updating logic in this function make sure that the mechanics being considered set bRequiresVisibilityUpdate
//when updating the object's state. This function will not be called / vis not updated unless game play logic flags the new state as having changed visibility.
event UpdateGameplayVisibility(out GameRulesCache_VisibilityInfo InOutVisibilityInfo)
{
	local XComGameState_Unit kTargetCurrent;
	local XComGameState_Unit kTargetPrevious;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local XComGameState_BaseObject TargetPreviousState;
	local XComGameState_BaseObject TargetCurrentState;
	local bool bUnalerted;
	local bool bUnitCanUseCover;

	if( InOutVisibilityInfo.bVisibleBasic )
	{
		if( bRemovedFromPlay )
		{
			InOutVisibilityInfo.bVisibleBasic = false;
			InOutVisibilityInfo.bVisibleGameplay = false;
			InOutVisibilityInfo.GameplayVisibleTags.AddItem('RemovedFromPlay');
		}
		else
		{
			InOutVisibilityInfo.bVisibleGameplay = InOutVisibilityInfo.bVisibleBasic; //Defaults to match bVisibleBasic
			History = `XCOMHISTORY;

			//Handle the case where we are a type of unit that cannot take cover ( and thus does not have peeks )
			if(!InOutVisibilityInfo.bVisibleFromDefault && !CanTakeCover())
			{
				InOutVisibilityInfo.bVisibleBasic = false;
				InOutVisibilityInfo.bVisibleGameplay = false;
				InOutVisibilityInfo.GameplayVisibleTags.AddItem('PeekNotAvailable_Source');
			}
		
			History.GetCurrentAndPreviousGameStatesForObjectID(InOutVisibilityInfo.TargetID, TargetPreviousState, TargetCurrentState);
			kTargetCurrent = XComGameState_Unit(TargetCurrentState);
			if(kTargetCurrent != none)
			{
				//Check to see whether the target moved. If so, visibility is not permitted to use peeks against the target
				kTargetPrevious = XComGameState_Unit(TargetPreviousState);
				if(kTargetPrevious != none && kTargetPrevious.TileLocation != kTargetCurrent.TileLocation)
				{					
					InOutVisibilityInfo.bTargetMoved = true;					
				}

				//Support for targeting non cover taking units with their peeks. Looks pretty bad though so it is gated by a config option...
				if(kTargetCurrent.ControllingPlayerIsAI())
				{
					bUnalerted = kTargetCurrent.GetCurrentStat(eStat_AlertLevel) == 0;
					bUnitCanUseCover = kTargetCurrent.GetMyTemplate().bCanTakeCover || class'X2Ability_DefaultAbilitySet'.default.bAllowPeeksForNonCoverUnits;

					//Handle the case where the target's peeks should be unavailable. Either because they are moving or for some other game mechanics reason.
					if(!InOutVisibilityInfo.bVisibleToDefault && (bUnalerted || !bUnitCanUseCover))
					{
						InOutVisibilityInfo.bVisibleBasic = false;
						InOutVisibilityInfo.bVisibleGameplay = false;
						InOutVisibilityInfo.GameplayVisibleTags.AddItem('PeekNotAvailable_Target');
					}
				}

				if(kTargetCurrent.bRemovedFromPlay)
				{
					InOutVisibilityInfo.bVisibleBasic = false;
					InOutVisibilityInfo.bVisibleGameplay = false;
					InOutVisibilityInfo.GameplayVisibleTags.AddItem('RemovedFromPlay');
				}
				else
				{
					//AI units have special visibility rules with respect to their alert level and enemies
					if(IsEnemyUnit(kTargetCurrent) && kTargetCurrent.IsConcealed())
					{
						InOutVisibilityInfo.bVisibleGameplay = false;
						InOutVisibilityInfo.GameplayVisibleTags.AddItem('concealed');
					}
						
					//Check effects that modify visibility for target - Do This Last!
					foreach kTargetCurrent.AffectedByEffects(EffectRef)
					{
						EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
						EffectState.GetX2Effect().ModifyGameplayVisibilityForTarget(InOutVisibilityInfo, self, kTargetCurrent);
					}
				}
			}
		}
	}
}

function int GetSoldierRank()
{
	return m_SoldierRank;
}

function name GetSoldierClassTemplateName()
{
	if(IsMPCharacter())
		return m_MPCharacterTemplateName;

	return m_SoldierClassTemplateName;
}

simulated function bool HasHeightAdvantageOver(XComGameState_Unit OtherUnit, bool bAsAttacker)
{
	local int BonusZ;

	if (bAsAttacker)
		BonusZ = GetHeightAdvantageBonusZ();

	return TileLocation.Z + BonusZ >= (OtherUnit.TileLocation.Z + class'X2TacticalGameRuleset'.default.UnitHeightAdvantage);
}

simulated function int GetHeightAdvantageBonusZ()
{
	local UnitValue SectopodHeight;
	local int BonusZ;

	if (GetUnitValue(class'X2Ability_Sectopod'.default.HighLowValueName, SectopodHeight))
	{
		if (SectopodHeight.fValue == class'X2Ability_Sectopod'.const.SECTOPOD_HIGH_VALUE)
			BonusZ = class'X2Ability_Sectopod'.default.HEIGHT_ADVANTAGE_BONUS;
	}

	return BonusZ;
}

/// <summary>
/// Applies to queries that need to know whether a given target is an 'enemy' of the source
/// </summary>
event bool TargetIsEnemy(int TargetObjectID, int HistoryIndex = -1)
{	
	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit UnitState;
	local XComGameState_Destructible DestructibleState;

	// is this an enemy unit?
	TargetState = `XCOMHISTORY.GetGameStateForObjectID(TargetObjectID, , HistoryIndex);

	UnitState = XComGameState_Unit(TargetState);
	if( UnitState != none )
	{
		return IsEnemyUnit(UnitState);
	}

	DestructibleState = XComGameState_Destructible(TargetState);
	if(DestructibleState != none)
	{
		return DestructibleState.TargetIsEnemy(ObjectID, HistoryIndex);
	}

	return false;
}

/// <summary>
/// Applies to queries that need to know whether a given target is an 'ally' of the source
/// </summary>
event bool TargetIsAlly(int TargetObjectID, int HistoryIndex = -1)
{	
	local XComGameState_Unit TargetState;	

	//Only other units can be allies atm
	TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetObjectID, , HistoryIndex));
	if( TargetState != none )
	{
		return !IsEnemyUnit(TargetState);
	}

	return false;
}

event bool ShouldTreatLowCoverAsHighCover( )
{
	return bTreatLowCoverAsHigh;
}

/// <summary>
/// Allows for the determination of whether a unit should visible or not to a given player
/// </summary>
event int GetAssociatedPlayerID()
{
	return ControllingPlayer.ObjectID;
}

event EForceVisibilitySetting ForceModelVisible()
{
	local XComTacticalCheatManager CheatMgr;
	local XGUnit UnitVisualizer;
	local XComUnitPawn UnitPawn;
	local XComGameState_BattleData BattleData;
	local X2Action CurrentTrackAction;

	//Scampering enemies always have their model visible regardless of what the game state says
	if( ReflexActionState == eReflexActionState_AIScamper )
	{
		return eForceVisible;
	}

	UnitVisualizer = XGUnit(GetVisualizer());
	UnitPawn = UnitVisualizer.GetPawn();

	if(UnitPawn.m_bInMatinee)
	{
		return eForceVisible;
	}

	if(UnitPawn.m_bHiddenForMatinee)
	{
		return eForceNotVisible;
	}

	if (UnitPawn.bScanningProtocolOutline)
	{
		return eForceVisible;
	}

	CheatMgr = `CHEATMGR;
	if(CheatMgr != none && CheatMgr.ForceAllUnitsVisible)
	{
		return eForceVisible;
	}
	
	if( bRemovedFromPlay )
	{
		//If a unit was removed from play, but is still playing an action (usually, evacuating right now) don't hide them.
		CurrentTrackAction = `XCOMVISUALIZATIONMGR.GetCurrentTrackActionForVisualizer(UnitVisualizer, false);
		if (CurrentTrackAction == None || CurrentTrackAction.bCompleted) //No action / finished action, time to hide them
			return eForceNotVisible;
	}

	//Force bodies to be visible
	if (!IsAlive() || IsBleedingOut() || IsStasisLanced() || IsUnconscious())
	{
		return eForceVisible;
	}

	//If our controlling player is local	
	if (ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID())
	{
		return eForceVisible;
	}

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if( GetTeam() == eTeam_Neutral &&  BattleData.AreCiviliansAlwaysVisible() )
	{
		return eForceVisible;
	}

	// If this unit is not owned by the local player AND is Concealed, should be invisible
	if( (UnitVisualizer.GetPlayer() != XComTacticalController(`BATTLE.GetALocalPlayerController()).m_XGPlayer) &&
		IsConcealed() )
	{
		return eForceNotVisible;
	}

	return UnitVisualizer.ForceVisibility;
}

//================================== End Visibility Interface ==============================================

event OnStateSubmitted()
{	
	GetMyTemplate();

	`assert(m_CharTemplate != none);
}

native function bool GetUnitValue(name nmValue, out UnitValue kUnitValue);
native function SetUnitFloatValue(name nmValue, const float fValue, optional EUnitValueCleanup eCleanup=eCleanup_BeginTurn);
native function ClearUnitValue(name nmValue);
native function CleanupUnitValues(EUnitValueCleanup eCleanupType);
native function string UnitValues_ToString();

native function bool GetSquadmateScore(int iSquadmateID, out SquadmateScore kSquadmateScore);
native function SetSquadmateScore(int iSquadmateID, const int iScore, bool bUpdateStatus);
native function AddToSquadmateScore(int iSquadmateID, const int iScoreToAdd, optional bool bUpdateStatus=false);
native function ClearSquadmateScore(int iSquadmateID);
native function OnSoldierMoment(int iSquadmateID);

function SetInitialState(XGUnit UnitActor)
{
	local XGItem Item;
	local int i;
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local XComGameState_Item ItemState;
	
	History = `XCOMHISTORY;

	History.SetVisualizer(ObjectID, UnitActor);
	UnitActor.SetObjectIDFromState(self);

	`XWORLD.GetFloorTileForPosition(UnitActor.Location, TileLocation, false);

	UnitActor.m_kReachableTilesCache.SetCacheUnit(self);

	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitActor.m_kPlayer.ObjectID));
	ControllingPlayer = PlayerState.GetReference();

	for(i = 0; i < eSlot_Max; i++)
	{
		Item = UnitActor.GetInventory().GetItem(ELocation(i));
		if( Item == none )
			continue;

		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Item.ObjectID));
		InventoryItems.AddItem(ItemState.GetReference());
	}
}

function AddStreamingCinematicMaps()
{
	// add the streaming map if we're not at level initialization time
	//	should make this work when using dropUnit etc
	local XComGameStateHistory History;
	local X2CharacterTemplateManager TemplateManager;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit kGameStateUnit;
	local string MapName;

	History = `XCOMHISTORY;
	if (History.GetStartState() == none)
	{

		kGameStateUnit = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

		TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		CharacterTemplate = TemplateManager.FindCharacterTemplate(kGameStateUnit.GetMyTemplateName());
		if (CharacterTemplate != None)
		{
			foreach CharacterTemplate.strMatineePackages(MapName)
			{
				if(MapName != "")
				{
					`MAPS.AddStreamingMap(MapName, , , false).bForceNoDupe = true;
				}
			}
		}

	}

}



function PostCreateInit(XComGameState NewGameState, X2CharacterTemplate kTemplate, int iPlayerID, TTile UnitTile, bool bEnemyTeam, bool bUsingStartState, bool PerformAIUpdate, optional const XComGameState_Unit ReanimatedFromUnit = None, optional string CharacterPoolName)
{
	local XComGameStateHistory History;
	local XGCharacterGenerator CharGen;
	local TSoldier Soldier;
	local XComGameState_Unit kSubSystem, Unit;
	local XComGameState_Player PlayerState;
	local name SubTemplateName;
	local X2CharacterTemplate kSubTemplate;
	local array<StateObjectReference> arrNewSubsystems;
	local StateObjectReference kSubsystemRef;
	local AttachedComponent SubComponent;

	//Character pool support
	local bool bDropCharacterPoolUnit;
	local CharacterPoolManager CharacterPool;
	local XComGameState_Unit CharacterPoolUnitState;
		
	History = `XCOMHISTORY;

	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(iPlayerID));
	SetControllingPlayer(PlayerState.GetReference());
	SetVisibilityLocation(UnitTile);
		
	bDropCharacterPoolUnit = CharacterPoolName != "";

	//If our pawn is gotten from our appearance, and we don't yet have a torso - it means we need to generate an appearance. This should
	//generally ONLY happen when running from tactical as appearances should be generated within the campaign/strategy game normally.
	if(kTemplate.bAppearanceDefinesPawn && (kAppearance.nmTorso == '' || bDropCharacterPoolUnit))
	{				
		if(bDropCharacterPoolUnit)
		{
			CharacterPool = `CHARACTERPOOLMGR;
			CharacterPoolUnitState = CharacterPool.GetCharacter(CharacterPoolName);
		}

		if(CharacterPoolUnitState != none)
		{
			SetTAppearance(CharacterPoolUnitState.kAppearance);
			SetCharacterName(CharacterPoolUnitState.GetFirstName(), CharacterPoolUnitState.GetLastName(), CharacterPoolUnitState.GetNickName());
			SetCountry(CharacterPoolUnitState.GetCountry());
		}
		else
		{
			CharGen = `XCOMGRI.Spawn(kTemplate.CharacterGeneratorClass);
			`assert(CharGen != none);
			Soldier = CharGen.CreateTSoldier(kTemplate.DataName);
			SetTAppearance(Soldier.kAppearance);
			SetCharacterName(Soldier.strFirstName, Soldier.strLastName, Soldier.strNickName);
			SetCountry(Soldier.nmCountry);
		}
	}

	if( CharGen != none )
	{
		CharGen.Destroy();
	}

	ApplyInventoryLoadout(NewGameState);

	bTriggerRevealAI = bEnemyTeam;

	if (HackRewards.Length == 0 && kTemplate.HackRewards.Length > 0)
	{
		HackRewards = class'X2HackRewardTemplateManager'.static.SelectHackRewards(kTemplate.HackRewards);
	}

	SetupActionsForBeginTurn();

	NewGameState.AddStateObject(self);

	if( !bUsingStartState )
	{
		// If not in start state, we need to initialize the abilities here.
		`TACTICALRULES.InitializeUnitAbilities(NewGameState, self);
	}

	// copy over any pending loot from the old unit to this new unit
	if( ReanimatedFromUnit != None )
	{
		PendingLoot = ReanimatedFromUnit.PendingLoot;

		if( GetMyTemplate().strPawnArchetypes.Length > 1 )
		{
			// This type of unit may have a gender, so copy the gender from
			// the copied unit
			kAppearance = ReanimatedFromUnit.kAppearance;
		}
	}

	if( PerformAIUpdate )
	{
		XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer()).AddNewSpawnAIData(NewGameState);
	}

	if( GetTeam() == eTeam_Alien )
	{
		if( `TACTICALMISSIONMGR.ActiveMission.AliensAlerted )
		{
			SetCurrentStat(eStat_AlertLevel, `ALERT_LEVEL_YELLOW);
		}
	}

	class'XGUnit'.static.CreateVisualizer(NewGameState, self, PlayerState, ReanimatedFromUnit);

	if(kTemplate.bIsTurret)
	{
		InitTurretState();
	}

	if(!kTemplate.bIsCosmetic)
	{
		`XWORLD.SetTileBlockedByUnitFlag(self);
	}

	// Handle creation of subsystems here.
	if (!m_bSubsystem) // Should not be more than 1 level of subsystems.
	{
		foreach kTemplate.SubsystemComponents(SubComponent)
		{
			SubTemplateName = SubComponent.SubsystemTemplateName;
			kSubTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(SubTemplateName);
			if (kSubTemplate == none)
			{
				`log("No character subtemplate named" @ SubTemplateName @ "was found.");
				continue;
			}

			kSubSystem = kSubTemplate.CreateInstanceFromTemplate(NewGameState);
			kSubSystem.m_bSubsystem = true;
			arrNewSubsystems.AddItem(kSubSystem.GetReference());
			kSubSystem.PostCreateInit(NewGameState, kSubTemplate, iPlayerID, UnitTile, bEnemyTeam, bUsingStartState, PerformAIUpdate);
		}

		if (arrNewSubsystems.Length > 0)
		{
			// Update the Unit GameState to include these subsystems.
			Unit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
			if (Unit != none)
			{
				foreach arrNewSubsystems(kSubsystemRef)
				{
					kSubSystem = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', kSubsystemRef.ObjectID));
					Unit.AddComponentObject(kSubSystem);
					`Assert(kSubSystem.OwningObjectId > 0);
					NewGameState.AddStateObject(kSubsystem);
				}
				NewGameState.AddStateObject(Unit);
			}
		}
	}


	AddStreamingCinematicMaps();

}

function InitTurretState()
{
	local XGUnit kUnit;

	if( GetNumVisibleEnemyUnits() > 0 )
	{
		if( GetTeam() == eTeam_Alien )
		{
			IdleTurretState = eITS_AI_ActiveTargeting;
		}
		else
		{
			IdleTurretState = eITS_XCom_ActiveTargeting;
		}
	}
	else
	{
		if( GetTeam() == eTeam_Alien )
		{
			IdleTurretState = eITS_AI_ActiveAlerted;
		}
		else
		{
			IdleTurretState = eITS_XCom_ActiveTargeting;
		}
	}

	kUnit = XGUnit(GetVisualizer());
	if(!kUnit.IdleStateMachine.IsDormant())
	{
		kUnit.IdleStateMachine.GoDormant();
	}
}

function bool AutoRunBehaviorTree(Name OverrideNode = '', int RunCount = 1, int HistoryIndex = -1, bool bOverrideScamper = false, bool bInitFromPlayerEachRun=false)
{
	local X2AIBTBehaviorTree BTMgr;
	BTMgr = `BEHAVIORTREEMGR;
	if( bOverrideScamper )
	{
		BTMgr.RemoveFromBTQueue(ObjectID, true);
	}
	if( BTMgr.QueueBehaviorTreeRun(self, String(OverrideNode), RunCount, HistoryIndex, , , , bInitFromPlayerEachRun) )
	{
		BTMgr.TryUpdateBTQueue();
		return true;
	}
	return false;
}

// start of turn - clear red alert state if no perfect knowledge remains (no visibility on enemy units)
function EventListenerReturn OnPlayerTurnBegun(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_AIUnitData AIGameState;
	local int AIUnitDataID;
	local StateObjectReference KnowledgeOfUnitRef;
	local StateObjectReference AbilityRef;
	local XComGameState_Effect RedAlertEffectState, YellowAlertEffectState;
	local X2TacticalGameRuleset Ruleset;
	local XComGameStateContext_Ability NewAbilityContext;
	local XComGameState_Ability AbilityState;

	if(ControllingPlayer.ObjectID == XComGameState_Player(EventSource).ObjectID)
	{
		History = `XCOMHISTORY;
		Ruleset = X2TacticalGameRuleset(`XCOMGAME.GameRuleset);

		// check for loss of red alert state
		if( GetCurrentStat(eStat_AlertLevel) == `ALERT_LEVEL_RED )
		{
			AIUnitDataID = GetAIUnitDataID();
			if( AIUnitDataID > 0 )
			{
				AIGameState = XComGameState_AIUnitData(History.GetGameStateForObjectID(AIUnitDataID));
				if( !AIGameState.HasAbsoluteKnowledge(KnowledgeOfUnitRef) )
				{
					RedAlertEffectState = GetUnitAffectedByEffectState('RedAlert');
					if( RedAlertEffectState != None && !RedAlertEffectState.bRemoved ) // Don't remove an effect that's already been removed.
					{
						// remove RED ALERT
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RemoveRedAlertStatus");
						RedAlertEffectState.RemoveEffect(NewGameState, GameState);
						Ruleset.SubmitGameState(NewGameState);

						`LogAI("ALERTEFFECTS:Removed Red Alert effect from unit "$ ObjectID @", to be replaced with YellowAlert effect.");

						// add YELLOW ALERT (if necessary)
						YellowAlertEffectState = GetUnitAffectedByEffectState('YellowAlert');
						if( YellowAlertEffectState == None || YellowAlertEffectState.bRemoved )
						{
							AbilityRef = FindAbility('YellowAlert');
							if( AbilityRef.ObjectID > 0 )
							{
								AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

								if( AbilityState != None )
								{
									NewAbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, ObjectID);
									if( NewAbilityContext.Validate() )
									{
										Ruleset.SubmitGameStateContext(NewAbilityContext);
									}
								}
							}
						}
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function bool UpdateTurretState( bool UpdateIdleStateMachine=true )
{
	local EIdleTurretState eOldState;
	local int nVisibleEnemies;
	// Update turret state
	eOldState = IdleTurretState;
	nVisibleEnemies = GetNumVisibleEnemyUnits();
	// Handle stunned state.  
	if( StunnedActionPoints > 0 || StunnedThisTurn > 0 ) // Stunned state.
	{
		if( ControllingPlayerIsAI() )
		{
			IdleTurretState = eITS_AI_Inactive;
		}
		else
		{
			IdleTurretState = eITS_XCom_Inactive;
		}
	}
	// Otherwise the unit is active.
	else
	{
		if( nVisibleEnemies > 0 )
		{
			if( GetTeam() == eTeam_Alien )
			{
				IdleTurretState = eITS_AI_ActiveTargeting;
			}
			else
			{
				IdleTurretState = eITS_XCom_ActiveTargeting;
			}
		}
		else
		{
			if( GetTeam() == eTeam_Alien )
			{
				IdleTurretState = eITS_AI_ActiveAlerted;
			}
			else
			{
				IdleTurretState = eITS_XCom_ActiveTargeting;
			}
		}
	}

	if( UpdateIdleStateMachine )
	{
		XGUnit(GetVisualizer()).UpdateTurretIdle(IdleTurretState);
	}
	if(eOldState != IdleTurretState)
	{
		return true;
	}
	return false;
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local XComGameState_Player PlayerState;
	local XGUnit UnitVisualizer;
	local XComHumanPawn HumanPawnVisualizer;
	local Vector ObjectiveLoc;
	local Vector DirToObj;
	local X2ArmorTemplate ArmorTemplate;

	if (GameState == none)
	{
		GameState = GetParentGameState( );
	}

	UnitVisualizer = XGUnit(GetVisualizer());
	if( UnitVisualizer == none || m_bSubsystem)
	{
		PlayerState = XComGameState_Player( `XCOMHISTORY.GetGameStateForObjectID( ControllingPlayer.ObjectID ) );

		class'XGUnit'.static.CreateVisualizer(GameState, self, PlayerState);
		UnitVisualizer = XGUnit(GetVisualizer());
		//`assert(UnitVisualizer != none);
		if (!UnitVisualizer.IsAI())
		{
			if (!`TACTICALMISSIONMGR.GetObjectivesCenterPoint(ObjectiveLoc))
			{
				// If there is no objective, they look at the origin 
				ObjectiveLoc = vect(0, 0, 0);
			}
			
			UnitVisualizer.GetPawn().SetFocalPoint(ObjectiveLoc);
			if (GetCoverTypeFromLocation() == CT_None)
			{
				DirToObj = ObjectiveLoc - UnitVisualizer.GetPawn().Location;
				DirToObj.Z = 0;
				UnitVisualizer.GetPawn().SetRotation(Rotator(DirToObj));
			}
		}


		// Set the correct wwise switch value.  Per request from the sound designers, this, "allows us to 
		// change the soldier Foley based on the type of armor the soldier is waring"  mdomowicz 2015_07_22
		if(IsASoldier() && GetItemInSlot(eInvSlot_Armor, GameState) != none)
		{
			ArmorTemplate = X2ArmorTemplate(GetItemInSlot(eInvSlot_Armor, GameState).GetMyTemplate());
			HumanPawnVisualizer = XComHumanPawn(UnitVisualizer.GetPawn());

			if (ArmorTemplate != None && HumanPawnVisualizer != None)
			{
				HumanPawnVisualizer.SetSwitch('SoldierArmor', ArmorTemplate.AkAudioSoldierArmorSwitch);
			}
		}
	}

	return UnitVisualizer;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
	local XGUnit UnitVisualizer;
	local name EffectName;
	local XComGameState_Effect EffectState;
	local int x, y, z, ShooterEffectIndex;
	local array<XComPerkContent> Perks;
	local array<XGUnit> Targets;
	local XComGameState_Unit TargetState;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect_Persistent TargetEffect;
	local bool bAssociatedSourceEffect;
	
	if(GameState == none)
	{
		GameState = GetParentGameState();
	}

	UnitVisualizer = XGUnit( GetVisualizer( ) );
	UnitVisualizer.m_kPlayer = XGPlayer(`XCOMHISTORY.GetVisualizer(ControllingPlayer.ObjectID));
	UnitVisualizer.m_kPlayerNativeBase = UnitVisualizer.m_kPlayer;
	UnitVisualizer.SetTeamType(GetTeam());

	if( UnitVisualizer.m_kPlayer == none )
	{
		`RedScreen("[@gameplay] SyncVisualizer: No unit visualizer for " $ GetFullName());
	}

	// Spawning system is meant to do this but since our sync created the visualizer we want it right away
	UnitVisualizer.m_bForceHidden = false;

	UnitVisualizer.GetPawn().GameStateResetVisualizer(self);

	//Units also set up visualizers for their items, since the items are dependent on the unit visualizer
	UnitVisualizer.ApplyLoadoutFromGameState(self, GameState);

	for (x = 0; x < AppliedEffectNames.Length; ++x)
	{
		EffectName = AppliedEffectNames[x];
		EffectState = XComGameState_Effect( `XCOMHISTORY.GetGameStateForObjectID( AppliedEffects[ x ].ObjectID ) );

		AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( EffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName );
		if (AbilityTemplate.bSkipPerkActivationActions && AbilityTemplate.bSkipPerkActivationActionsSync)
		{
			continue;
		}

		Perks.Length = 0;
		class'XComPerkContent'.static.GetAssociatedPerks( Perks, UnitVisualizer.GetPawn(), EffectState.ApplyEffectParameters.AbilityInputContext.AbilityTemplateName );
		for (y = 0; y < Perks.Length; ++y)
		{
			if (Perks[y].AssociatedEffect == EffectName)
			{
				if (!Perks[y].IsInState('DurationActive'))
				{
					if (AbilityTemplate != none)
					{
						for (ShooterEffectIndex = 0; ShooterEffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++ShooterEffectIndex)
						{
							TargetEffect = X2Effect_Persistent( AbilityTemplate.AbilityShooterEffects[ ShooterEffectIndex ] );

							if ((TargetEffect != none) &&
								(TargetEffect.EffectName == Perks[ y ].AssociatedEffect))
							{
								bAssociatedSourceEffect = true;
								break;
							}
						}
					}

					Targets.Length = 0;

					TargetState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( EffectState.ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID ) );
					if (TargetState != none)
					{
						Targets.AddItem( XGUnit( TargetState.GetVisualizer( ) ) );
					}
					for (z = 0; z < EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets.Length; ++z)
					{
						TargetState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets[ z ].ObjectID ) );
						if (TargetState != none)
						{
							Targets.AddItem( XGUnit( TargetState.GetVisualizer( ) ) );
						}
					}

					Perks[ y ].OnPerkLoad( UnitVisualizer, Targets, EffectState.ApplyEffectParameters.AbilityInputContext.TargetLocations, bAssociatedSourceEffect );
				}
				else
				{
					TargetState = XComGameState_Unit( `XCOMHISTORY.GetGameStateForObjectID( EffectState.ApplyEffectParameters.AbilityInputContext.PrimaryTarget.ObjectID ) );
					if (TargetState != none)
					{
						Perks[ y ].AddPerkTarget(XGUnit( TargetState.GetVisualizer( ) ), true);
					}
				}

				if(!Perks[ y ].CasterDurationFXOnly && !Perks[ y ].TargetDurationFXOnly)
				{
					// It is possible this perk is for only the target or source.
					// Only break if that is not the case.
					break;
				}
			}
		}
	}

	if( bRemovedFromPlay )
	{
		// Force invisible and clear blocking tile.
		RemoveUnitFromPlay();
	}
	else
	{
		if(IsAlive() && !IsIncapacitated())
		{
			UnitVisualizer.GetPawn().UpdateAnimations();
		}
		
		if( UnitVisualizer.m_kBehavior == None )
		{
			UnitVisualizer.InitBehavior();
		}
	}

	if( IsTurret() && IsAlive() )
	{
		UpdateTurretState(true);
	}

	if( bGeneratesCover )
	{
		class'X2Effect_GenerateCover'.static.UpdateWorldCoverData( self, GameState );
	}

	// Don't Ragdoll cocoons
	if (m_SpawnedCocoonRef.ObjectID != 0)
	{
		UnitVisualizer.GetPawn().RagdollFlag = eRagdoll_Never;
	}

	UnitVisualizer.VisualizedAlertLevel = UnitVisualizer.GetAlertLevel(self);

	if( GetMyTemplate().bLockdownPodIdleUntilReveal && UnitVisualizer.VisualizedAlertLevel != eAL_Green )
	{
		UnitVisualizer.GetPawn().GetAnimTreeController().SetAllowNewAnimations(true);
	}
}

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack )
{
	local int x;
	local name EffectName;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persistent;
	local X2AbilityTemplate Template;

	// run through the applied effects and see if anything needs to sync
	for (x = 0; x < AppliedEffectNames.Length; ++x)
	{
		EffectName = AppliedEffectNames[ x ];
		EffectState = XComGameState_Effect( `XCOMHISTORY.GetGameStateForObjectID( AppliedEffects[ x ].ObjectID ) );

		Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager( ).FindAbilityTemplate( EffectState.ApplyEffectParameters.EffectRef.SourceTemplateName );
		if ((Template != none) && (Template.BuildAppliedVisualizationSyncFn != none))
		{
			Template.BuildAppliedVisualizationSyncFn(EffectName, EffectState.GetParentGameState(), BuildTrack ); 
		}
	}

	// find world effects and apply them since those aren't referenced in two places
	for (x = 0; x < AffectedByEffectNames.Length; ++x)
	{
		EffectName = AffectedByEffectNames[ x ];
		EffectState = XComGameState_Effect( `XCOMHISTORY.GetGameStateForObjectID( AffectedByEffects[ x ].ObjectID ) );

		if (EffectState.ApplyEffectParameters.EffectRef.LookupType != TELT_WorldEffect)
		{
			Template = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager( ).FindAbilityTemplate( EffectState.ApplyEffectParameters.EffectRef.SourceTemplateName );
			if ((Template != none) && (Template.BuildAffectedVisualizationSyncFn != none))
			{
				Template.BuildAffectedVisualizationSyncFn( EffectName, EffectState.GetParentGameState( ), BuildTrack );
			}
		}

		Persistent = EffectState.GetX2Effect( );
		if (Persistent != none)
		{
			Persistent.AddX2ActionsForVisualization_Sync( EffectState.GetParentGameState( ), BuildTrack );
		}
	}
}

function CheckFirstSightingOfEnemyGroup(XComGameState GameState, bool bSquadViewerStateNotRequired)
{
	local XComGameState_Unit EnemyUnit, GroupLeaderUnitState;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_AIGroup AIGroupState;
	local XComGameState_AIGroup NewGroupState;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> EnemyUnits;
	local int HistoryIndex;
	local int i;
	local XComGameState_SquadViewer SquadViewerState;
	local bool bThisUnitIsXCom, bPlayFirstSighting;
	local int SourceID, TargetID;

	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	History = `XCOMHISTORY;
	`assert(GameState != none);
	HistoryIndex = GameState.HistoryIndex;

	// See if we have a squad viewer (battle scanner ability)
	for (i = 0; i < GameState.GetNumGameStateObjects(); i++)
	{
		if (GameState.GetGameStateForObjectIndex(i).IsA('XComGameState_SquadViewer'))
		{
			SquadViewerState = XComGameState_SquadViewer(GameState.GetGameStateForObjectIndex(i));
		}
	}

	// We want the visibility from the XCom unit to the target.
	// If this unit is not XCom, then the enemy is and that should be the source.
	bThisUnitIsXCom = GetTeam() == eTeam_XCom;

	if ((bSquadViewerStateNotRequired ||
		(SquadViewerState != none)) &&
		!(bThisUnitIsXCom && IsMindControlled()))
	{
		foreach History.IterateByClassType(class'XComGameState_Unit', EnemyUnit)
		{
			if( EnemyUnit.IsAlive() &&
				IsEnemyUnit(EnemyUnit) )
			{
				EnemyUnits.AddItem(EnemyUnit);
			}
		}

		foreach EnemyUnits(EnemyUnit)
		{
			if (!bThisUnitIsXCom && EnemyUnit.IsMindControlled())
			{
				// If this unit is not XCom, then the enemy must be.
				// If the XCom unit is mindcontrolled, then do not do
				// first sight checks.
				continue;
			}

			if (SquadViewerState != none && !bSquadViewerStateNotRequired)
			{
				SourceID = SquadViewerState.ObjectID;
				TargetID = EnemyUnit.ObjectID;
				if (!bThisUnitIsXCom)
				{
					SourceID = EnemyUnit.ObjectID;
					TargetID = SquadViewerState.ObjectID;
				}

				// Check visibility from squad viewer (battle scanner)
				VisibilityMgr.GetVisibilityInfo(SourceID, TargetID, OutVisibilityInfo, HistoryIndex);
			}
			else
			{
				SourceID = ObjectID;
				TargetID = EnemyUnit.ObjectID;
				if (!bThisUnitIsXCom)
				{
					SourceID = EnemyUnit.ObjectID;
					TargetID = ObjectID;
				}

				VisibilityMgr.GetVisibilityInfo(SourceID, TargetID, OutVisibilityInfo, HistoryIndex);
			}

			if( OutVisibilityInfo.bVisibleGameplay ) //APC- changed to VisibleGameplay from VisibleBasic, was viewing Burrowed Chryssalid locations.
			{										 
				AIGroupState = EnemyUnit.GetGroupMembership();

				// If we have a AIGroupState, we are and alien, lets make sure the visible unit is not a neutral unit
				if (AIGroupState == none && GetGroupMembership() != none && EnemyUnit.GetTeam() != eTeam_Neutral)
				{
					// This is an AI moving, let the sighting happen this way too by switching the sighting unit to be the AIGroupstate
					AIGroupState = GetGroupMembership();
				}
				
				if (AIGroupState != None && !AIGroupState.EverSightedByEnemy && AIGroupState.RevealInstigatorUnitObjectID <= 0)
				{
					GroupLeaderUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[0].ObjectID));

					if( GroupLeaderUnitState != none && GroupLeaderUnitState.GetTeam() != eTeam_Neutral )
					{
						CharacterTemplate = GroupLeaderUnitState.GetMyTemplate();

						if (`CHEATMGR == none || !`CHEATMGR.DisableFirstEncounterVO)
						{
							bPlayFirstSighting = false;

							if( GroupLeaderUnitState.IsAlive() )
							{
								XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
								bPlayFirstSighting = (XComHQ != None) && !XComHQ.HasSeenCharacterTemplate(CharacterTemplate);
							}

							// If this group has not scampered OR the character template hasn't been seen before, 
							if (!AIGroupState.bProcessedScamper || bPlayFirstSighting)
							{
								// first time sighting an enemy group, want to force a camera look at for this group
								NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("First Sighting Of Enemy Group [" $ AIGroupState.ObjectID $ "]");
								XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForFirstSightingOfEnemyGroup;

								NewGroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', AIGroupState.ObjectID));
								NewGameState.AddStateObject(NewGroupState);
								NewGroupState.EverSightedByEnemy = true;

								if (bPlayFirstSighting)
								{
									// Update the HQ state to record that we saw this enemy type
									XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(XComHQ.Class, XComHQ.ObjectID));
									XComHQ.AddSeenCharacterTemplate(CharacterTemplate);
									NewGameState.AddStateObject(XComHQ);
								}

								`TACTICALRULES.SubmitGameState(NewGameState);

								DoAmbushTutorial();
							}
						}

						for( i = 0; i < CharacterTemplate.SightedEvents.Length; i++ )
						{
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Sighted event");
							`XEVENTMGR.TriggerEvent(CharacterTemplate.SightedEvents[i], , , NewGameState);
							`TACTICALRULES.SubmitGameState(NewGameState);
						}
					}
				}
			}
		}
	}
}

function DoAmbushTutorial()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	if (XComHQ != None && !XComHQ.bHasPlayedAmbushTutorial && IsConcealed())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Ambush Tutorial");
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForAmbushTutorial;

		// Update the HQ state to record that we saw this enemy type
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(XComHQ.Class, XComHQ.ObjectID));
		XComHQ.bHasPlayedAmbushTutorial = true;
		NewGameState.AddStateObject(XComHQ);

		`TACTICALRULES.SubmitGameState(NewGameState);

		class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistoryExplicit(class'XLocalizedData'.default.AmbushTutorialTitle,
																							class'XLocalizedData'.default.AmbushTutorialText,
																							class'UIUtilities_Image'.static.GetTutorialImage_Ambush());
	}
}

function BuildVisualizationForAmbushTutorial(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local X2Action_PlayNarrative NarrativeAction;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));

	NarrativeAction = X2Action_PlayNarrative(class'X2Action_PlayNarrative'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	NarrativeAction.Moment = XComNarrativeMoment'X2NarrativeMoments.CENTRAL_Tactical_Tutorial_Mission_Two_Ambush';
	NarrativeAction.WaitForCompletion = false;

	BuildTrack.StateObject_OldState = UnitState;
	BuildTrack.StateObject_NewState = UnitState;
	OutVisualizationTracks.AddItem(BuildTrack);

}

function EventListenerReturn OnUnitMoveFinished(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit EventUnit;
	local XComGameStateContext_TacticalGameRule NewContext;	

	EventUnit = XComGameState_Unit(EventData);

	if( EventUnit.ObjectID == ObjectID )
	{
		if( CanTakeCover() )
		{
			NewContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_ClaimCover);
			NewContext.UnitRef = GetReference();
			`XCOMGAME.GameRuleset.SubmitGameStateContext(NewContext);
		}

		// Civilians should not do this, otherwise it can trigger first seen narratives from civvie moves
		if (GetTeam() != eTeam_Neutral)
		{
			CheckFirstSightingOfEnemyGroup(GameState, true);
		}

		// TODO: update the EventMgr & move this to a PreSubmit deferral

		// dkaplan - 8/12/15 - we no longer update detection modifiers based on cover; we may want to revisit this for expansion
	}

	return ELR_NoInterrupt;
}

function BuildVisualizationForFirstSightingOfEnemyGroup(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, GroupLeaderUnitState, GroupUnitState;
	local X2Action_PlayEffect EffectAction;	
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_AIGroup AIGroupState;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2Action_UpdateUI UpdateUIAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local bool bPlayedVO;
	local int Index;
	local X2Action_Delay DelayAction;
	local XComGameStateContext Context;

	Context = VisualizeGameState.GetContext();
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}
	
	if (XComHQ == none)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));		
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
	{
		// always center the camera on the enemy group for a few seconds and clear the FOW
		EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
		EffectAction.CenterCameraOnEffectDuration = 5.0;
		EffectAction.RevealFOWRadius = class'XComWorldData'.const.WORLD_StepSize * 5.0f;
		EffectAction.FOWViewerObjectID = AIGroupState.m_arrMembers[0].ObjectID; //Setting this to be a unit makes it possible for the FOW viewer to reveal units
		EffectAction.EffectLocation = AIGroupState.GetGroupMidpoint(VisualizeGameState.HistoryIndex);
		EffectAction.bWaitForCameraArrival = true;
		EffectAction.bWaitForCameraCompletion = false;

		UpdateUIAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, Context));
		UpdateUIAction.UpdateType = EUIUT_Pathing_Concealment;

		// if there is an HQ in this game state, it means that this unit is being shown for the first time, so we need to perform that intro narrative
		GroupLeaderUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[0].ObjectID));
		if( XComHQ != None && GroupLeaderUnitState != None && GroupLeaderUnitState.IsAlive() )
		{
			// iterating through all SightedNarrativeMoments on the character template
			CharacterTemplate = GroupLeaderUnitState.GetMyTemplate();

			EffectAction.NarrativeToPlay = CharacterTemplate.SightedNarrativeMoments.Length > 0 ? CharacterTemplate.SightedNarrativeMoments[0] : none;
		}
		else if (!bPlayedVO && SoundAndFlyOver != none && !GroupLeaderUnitState.GetMyTemplate().bIsTurret)
		{
			if (GroupLeaderUnitState.IsAdvent())
			{
				bPlayedVO = true;
				if (UnitState.IsConcealed())
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'EnemyPatrolSpotted', eColor_Good);
				}
				else
				{
					SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'ADVENTsighting', eColor_Good);
				}
			}
			else
			{
				// Iterate through other units to see if there are advent units
				for (Index = 1; Index < AIGroupState.m_arrMembers.Length; Index++)
				{
					GroupUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[Index].ObjectID));
					if (!bPlayedVO && GroupUnitState.IsAdvent())
					{
						bPlayedVO = true;
						if (UnitState.IsConcealed())
						{
							SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'EnemyPatrolSpotted', eColor_Good);
						}
						else
						{
							SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'ADVENTsighting', eColor_Good);
						}
						break;
					}
				}
			}
		}

		class'X2Action_BlockAbilityActivation'.static.AddToVisualizationTrack(BuildTrack, Context);

		// pause a few seconds
		DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, Context));
		DelayAction.Duration = 5.0;

		BuildTrack.StateObject_OldState = UnitState;
		BuildTrack.StateObject_NewState = UnitState;
		OutVisualizationTracks.AddItem(BuildTrack);
	}
}

function RegisterForEvents()
{
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	EventManager = `XEVENTMGR;
	ThisObj = self;
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(ControllingPlayer.ObjectID));

	if (!GetMyTemplate().bIsCosmetic)
	{
		// Cosmetic units should not get these events as it causes them to break concealment and trigger alerts
		EventManager.RegisterForEvent(ThisObj, 'ObjectMoved', OnUnitEnteredTile, ELD_OnStateSubmitted, , ThisObj);
		EventManager.RegisterForEvent(ThisObj, 'UnitMoveFinished', OnUnitMoveFinished, ELD_OnStateSubmitted, , ThisObj);
	}
	EventManager.RegisterForEvent(ThisObj, 'UnitTakeEffectDamage', OnUnitTookDamage, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnPlayerTurnBegun, ELD_OnStateSubmitted, , PlayerState);
	EventManager.RegisterForEvent(ThisObj, 'EffectBreakUnitConcealment', OnEffectBreakUnitConcealment, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'EffectEnterUnitConcealment', OnEffectEnterUnitConcealment, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'AlertDataTriggerAlertAbility', OnAlertDataTriggerAlertAbility, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', OnUnitRemovedFromPlay, ELD_OnVisualizationBlockCompleted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', OnUnitRemovedFromPlay_GameState, ELD_OnStateSubmitted, , ThisObj);
	EventManager.RegisterForEvent(ThisObj, 'UnitDied', OnThisUnitDied, ELD_OnStateSubmitted, , ThisObj);
}

function RefreshEventManagerRegistrationOnLoad()
{
	RegisterForEvents();
}

/// <summary>
/// "Transient" variables that should be cleared when this object is added to a start state
/// </summary>
function OnBeginTacticalPlay()
{
	local X2EventManager EventManager;

	super.OnBeginTacticalPlay();

	EventManager = `XEVENTMGR;

	EventManager.TriggerEvent( 'OnUnitBeginPlay', self, self );

	LowestHP = GetCurrentStat(eStat_HP);
	HighestHP = GetCurrentStat(eStat_HP);

	RegisterForEvents();

	CleanupUnitValues(eCleanup_BeginTactical);

	//Units removed from play in previous tactical play are no longer removed, unless they are explicitly set to remain so.
	//However, this update happens too late to get caught in the usual tile-data build.
	//So, if we're coming back into play, make sure to update the tile we now occupy.
	if (bRemovedFromPlay && !GetMyTemplate().bDontClearRemovedFromPlay)
	{
		bRemovedFromPlay = false;
		`XWORLD.SetTileBlockedByUnitFlag(self);
	}

	bRequiresVisibilityUpdate = true;
}

function OnEndTacticalPlay()
{
	local XComGameStateHistory History;
	local StateObjectReference EmptyReference, EffectRef;
	local XComGameState_Effect EffectState;
	local LootResults EmptyLootResults;
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnEndTacticalPlay();

	History = `XCOMHISTORY;
	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.UnRegisterFromEvent(ThisObj, 'ObjectMoved');
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitMoveFinished' );
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitTakeEffectDamage');
	EventManager.UnRegisterFromEvent(ThisObj, 'AbilityActivated');
	EventManager.UnRegisterFromEvent(ThisObj, 'PlayerTurnBegun');
	EventManager.UnRegisterFromEvent(ThisObj, 'EffectBreakUnitConcealment');
	EventManager.UnRegisterFromEvent(ThisObj, 'EffectEnterUnitConcealment');
	EventManager.UnRegisterFromEvent(ThisObj, 'AlertDataTriggerAlertAbility');
	EventManager.UnRegisterFromEvent(ThisObj, 'UnitDied');

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != None)
		{
			EffectState.GetX2Effect().UnitEndedTacticalPlay(EffectState, self);
		}
	}

	TileLocation.X = -1;
	TileLocation.Y = -1;
	TileLocation.Z = -1;
	
	bDisabled = false;	
	Abilities.Length = 0;
	ReflexActionState = eReflexActionState_None;
	PendingLoot = EmptyLootResults;
	AffectedByEffectNames.Length = 0;
	AffectedByEffects.Length = 0;
	AppliedEffectNames.Length = 0;
	AppliedEffects.Length = 0;
	DamageResults.Length = 0;
	Ruptured = 0;
	bTreatLowCoverAsHigh = false;
	m_SpawnedCocoonRef = EmptyReference;
	m_MultiTurnTargetRef = EmptyReference;
	m_SuppressionAbilityContext = None;
	bPanicked = false;
	bInStasis = false;
	m_bConcealed = false;
	bGeneratesCover = false;
	CoverForceFlag = CoverForce_Default;

	TraversalChanges.Length = 0;
	ResetTraversals();

	if (!GetMyTemplate().bIgnoreEndTacticalHealthMod)
	{
		EndTacticalHealthMod();
	}

	if (!GetMyTemplate().bIgnoreEndTacticalRestoreArmor)
	{
		Shredded = 0;
	}

	if (GetMyTemplate().OnEndTacticalPlayFn != none)
	{
		GetMyTemplate().OnEndTacticalPlayFn(self);
	}
}

// Health is adjusted after tactical play so that units that only took armor damage still require heal time
function EndTacticalHealthMod()
{
	local float HealthPercent, NewHealth;
	local int RoundedNewHealth, HealthLost;

	HealthLost = HighestHP - LowestHP;

	// If Dead or never injured, return
	if(LowestHP <= 0 || HealthLost <= 0)
	{
		return;
	}

	// Calculate health percent
	HealthPercent = (float(HighestHP - HealthLost) / float(HighestHP));

	// Calculate and apply new health value
	NewHealth = (HealthPercent * GetBaseStat(eStat_HP));
	RoundedNewHealth = Round(NewHealth);
	RoundedNewHealth = Clamp(RoundedNewHealth, 1, (int(GetBaseStat(eStat_HP)) - 1));
	SetCurrentStat(eStat_HP, RoundedNewHealth);
}

/**
 *  These functions should exist on all data instance classes, but they are not implemented as an interface so
 *  the correct classes can be used for type checking, etc.
 *  
 *  function <TemplateManagerClass> GetMyTemplateManager()
 *      @return the manager which should be available through a static function on XComEngine.
 *      
 *  function name GetMyTemplateName()
 *      @return the name of the template this instance was created from. This should be saved in a private field separate from a reference to the template.
 *      
 *  function <TemplateClass> GetMyTemplate()
 *      @return the template used to create this instance. Use a private variable to cache it, as it shouldn't be saved in a checkpoint.
 *      
 *  function OnCreation(<TemplateClass> Template)
 *      @param Template this instance should base itself on, which is as meaningful as you need it to be.
 *      Cache a reference to the template now, store its name, and perform any other required setup.
 */

static function X2CharacterTemplateManager GetMyTemplateManager()
{
	return class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

/// <summary>
/// Called immediately prior to loading, this method is called on each state object so that its resources can be ready when the map completes loading. Request resources
/// should output an array of strings containing archetype paths to load
/// </summary>
event RequestResources(out array<string> ArchetypesToLoad)
{
	local X2CharacterTemplate CharacterTemplate;
	local X2BodyPartTemplate BodyPartTemplate;
	local X2BodyPartTemplateManager PartManager;	
	local int Index;

	super.RequestResources(ArchetypesToLoad);

	//Load the character pawn(s)
	CharacterTemplate = GetMyTemplate();
	for(Index = 0; Index < CharacterTemplate.strPawnArchetypes.Length; ++Index)
	{
		ArchetypesToLoad.AddItem(CharacterTemplate.strPawnArchetypes[Index]);
	}
	
	//Load the character's body parts
	if(CharacterTemplate.bAppearanceDefinesPawn || CharacterTemplate.bForceAppearance)
	{
		PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

		if(kAppearance.nmPawn != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Pawn", kAppearance.nmPawn);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmTorso != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Torso", kAppearance.nmTorso);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);

			BodyPartTemplate = PartManager.FindUberTemplate("Torso", kAppearance.nmTorso_Underlay);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmHead != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Head", kAppearance.nmHead);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}
				
		if(kAppearance.nmHelmet != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Helmets", kAppearance.nmHelmet);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}
				
		if(kAppearance.nmFacePropLower != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("FacePropsLower", kAppearance.nmFacePropLower);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmHaircut != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Hair", kAppearance.nmHaircut);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmBeard != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Beards", kAppearance.nmBeard);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmFacePropUpper != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("FacePropsUpper", kAppearance.nmFacePropUpper);
			if( BodyPartTemplate != None )
			{
				ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
			}
		}

		if(kAppearance.nmArms != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Arms", kAppearance.nmArms);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmLegs != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Legs", kAppearance.nmLegs);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmEye != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Eyes", kAppearance.nmEye);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmTeeth != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Teeth", kAppearance.nmTeeth);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmPatterns != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Patterns", kAppearance.nmPatterns);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmWeaponPattern != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Patterns", kAppearance.nmWeaponPattern);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmTattoo_LeftArm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Tattoos", kAppearance.nmTattoo_LeftArm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmTattoo_RightArm != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Tattoos", kAppearance.nmTattoo_RightArm);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		if(kAppearance.nmScars != '')
		{
			BodyPartTemplate = PartManager.FindUberTemplate("Scars", kAppearance.nmScars);
			ArchetypesToLoad.AddItem(BodyPartTemplate.ArchetypeName);
		}

		//Don't load voices as part of this - they are caught when the pawn loads, or the voice previewed
	}
}

simulated native function X2CharacterTemplate GetMyTemplate() const;

simulated function X2CharacterTemplate GetOwnerTemplate()
{
	local XComGameState_Unit kOwner;
	if (OwningObjectId > 0)
	{
		kOwner = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwningObjectId));
		return kOwner.GetMyTemplate();
	}
	return none;
}

//Call to update the character's stored personality template
simulated function UpdatePersonalityTemplate()
{
	PersonalityTemplateName = '';
	PersonalityTemplate = none;
	PersonalityTemplate = GetPersonalityTemplate();
}

simulated function X2SoldierPersonalityTemplate GetPersonalityTemplate()
{
	local array<X2StrategyElementTemplate> PersonalityTemplates;
	if(PersonalityTemplate == none)
	{		
		if(PersonalityTemplateName == '')
		{			
			PersonalityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
			PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplates[kAppearance.iAttitude]);
		}
		else
		{
			PersonalityTemplate = X2SoldierPersonalityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(PersonalityTemplateName));
		}
	}

	return PersonalityTemplate;
}

simulated function X2SoldierPersonalityTemplate GetPhotoboothPersonalityTemplate()
{
	local X2SoldierPersonalityTemplate PhotoboothPersonalityTemplate;

	if (GetMyTemplate().PhotoboothPersonality != '')
	{
		PhotoboothPersonalityTemplate = X2SoldierPersonalityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(GetMyTemplate().PhotoboothPersonality));
		if (PhotoboothPersonalityTemplate != none)
		{
			return PhotoboothPersonalityTemplate;
		}
	}

	return class'X2StrategyElement_DefaultSoldierPersonalities'.static.Personality_ByTheBook();
}

function GiveRandomPersonality()
{
	local array<X2StrategyElementTemplate> PersonalityTemplates;
	local XGUnit UnitVisualizer;
	local XComHumanPawn HumanPawn;
	local int iChoice;

	PersonalityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
	iChoice = `SYNC_RAND(PersonalityTemplates.Length);

	PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplates[iChoice]);
	PersonalityTemplateName = PersonalityTemplate.DataName;
	kAppearance.iAttitude = iChoice; // Attitude needs to be in sync
	
	//Update the appearance stored in our visualizer if we have one
	UnitVisualizer = XGUnit(GetVisualizer());
	if (UnitVisualizer != none && UnitVisualizer.GetPawn() != none)
	{
		HumanPawn = XComHumanPawn(UnitVisualizer.GetPawn());
		if (HumanPawn != none)
		{
			HumanPawn.SetAppearance(kAppearance, false);
		}
	}
}

simulated function name GetComponentSocket()
{
	local X2CharacterTemplate kOwnerTemplate;
	local name SocketName;
	local int CompIndex;
	kOwnerTemplate = GetOwnerTemplate();
	if( kOwnerTemplate != None )
	{
		CompIndex = kOwnerTemplate.SubsystemComponents.Find('SubsystemTemplateName', m_TemplateName);
		if( CompIndex != -1 )
		{
			SocketName = kOwnerTemplate.SubsystemComponents[CompIndex].SocketName;
		}
		else
		{
			`Warn("Could not find this component from owner's SubsystemComponents list! TemplateName="@m_TemplateName@"OwnerName="$kOwnerTemplate.DataName);
		}
	}
	return SocketName;
}

function OnCreation(X2CharacterTemplate CharTemplate)
{
	local int i;
	local ECharStatType StatType;

	m_CharTemplate = CharTemplate;
	m_TemplateName = CharTemplate.DataName;

	UnitSize = CharTemplate.UnitSize;
	UnitHeight = CharTemplate.UnitHeight;

	//bConcealed = false;
	//AlertStatus = eAL_Green;
	if (IsSoldier())
	{
		// if we specify a non-default soldier class, start the unit off at squaddie rank so they get the base
		// class abilities (this will also set them to the default class)
		if(CharTemplate.DefaultSoldierClass != '' && CharTemplate.DefaultSoldierClass != class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
		{
			SetXPForRank(1);
			StartingRank = 1;
			RankUpSoldier(GetParentGameState(), CharTemplate.DefaultSoldierClass);
		}
		else
		{
			SetSoldierClassTemplate(class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass);
		}
	}

	for (i = 0; i < eStat_MAX; ++i)
	{
		StatType = ECharStatType(i);
		CharacterStats[i].Type = StatType;
		SetBaseMaxStat( StatType, CharTemplate.CharacterBaseStats[i] );
		SetCurrentStat( StatType, GetMaxStat(StatType) );
	}

	LowestHP = GetCurrentStat(eStat_HP);
	HighestHP = GetCurrentStat(eStat_HP);

	if (CharTemplate.OnStatAssignmentCompleteFn != none)
	{
		CharTemplate.OnStatAssignmentCompleteFn(self);
	}

	//RAM - not all stats should start at CharacterMax. Perhaps there is a better way to do this, but for now we can set these here...
	SetCurrentStat(eStat_AlertLevel, `ALERT_LEVEL_GREEN );
	if( !m_CharTemplate.bIsSoldier && !m_CharTemplate.bIsCivilian )
	{
		//If this is an alien or advent, adjust their sight radius according to the patrol setting
		SetBaseMaxStat( eStat_SightRadius, CharTemplate.CharacterBaseStats[eStat_SightRadius] - class'X2Ability_AlertMechanics'.default.GREENALERT_SIGHT_REDUCTION );
		SetCurrentStat( eStat_SightRadius, GetMaxStat(eStat_SightRadius) );
	}

	if(CharTemplate.bAppearanceDefinesPawn)
	{
		if(CharTemplate.bForceAppearance)
		{
			kAppearance = CharTemplate.ForceAppearance;

			if(CharTemplate.ForceAppearance.nmFlag != '')
			{
				SetCountry(CharTemplate.ForceAppearance.nmFlag);
			}
		}
		else if(CharTemplate.bHasFullDefaultAppearance)
		{
			kAppearance = CharTemplate.DefaultAppearance;

			if(CharTemplate.DefaultAppearance.nmFlag != '')
			{
				SetCountry(CharTemplate.ForceAppearance.nmFlag);
			}
		}
	}

	//If a gender is wanted and we are a null gender, set one
	if(CharTemplate.bSetGenderAlways && kAppearance.iGender == 0)
	{
		kAppearance.iGender = (Rand(2) == 0) ? eGender_Female : eGender_Male;
	}

	// If the character has a forced name, set it here
	if(CharTemplate.strForcedFirstName != "" || CharTemplate.strForcedLastName != "" || CharTemplate.strForcedNickName != "")
	{
		SetCharacterName(CharTemplate.strForcedFirstName, CharTemplate.strForcedLastName, CharTemplate.strForcedNickName);
	}

	ResetTraversals();
}

event RollForTimedLoot()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2LootTableManager LootManager;

	LootManager = class'X2LootTableManager'.static.GetLootTableManager();

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if( XComHQ != none && XComHQ.SoldierUnlockTemplates.Find('VultureUnlock') != INDEX_NONE )
	{
		// vulture loot roll
		LootManager.RollForLootCarrier(m_CharTemplate.VultureLoot, PendingLoot);
	}
	else
	{
		// roll on regular timed loot if vulture is not enabled
		LootManager.RollForLootCarrier(m_CharTemplate.TimedLoot, PendingLoot);
	}
}

function RollForAutoLoot(XComGameState NewGameState)
{
	local LootResults PendingAutoLoot;
	local XComGameState_BattleData BattleDataState;
	local XComGameStateHistory History;
	local Name LootTemplateName;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item NewItem;
	local int VisualizeLootIndex;
	local bool AnyAlwaysRecoverLoot;

	if( m_CharTemplate.Loot.LootReferences.Length > 0)
	{
		class'X2LootTableManager'.static.GetLootTableManager().RollForLootCarrier(m_CharTemplate.Loot, PendingAutoLoot);

		if( PendingAutoLoot.LootToBeCreated.Length > 0 )
		{
			AnyAlwaysRecoverLoot = false;

			VisualizeLootIndex = NewGameState.GetContext().HasPostBuildVisualization(VisualizeAutoLoot);
			//Remove any previous VisualizeAutoLoot call as the function only needs to happen once per new game state.
			if (VisualizeLootIndex != INDEX_NONE)
			{
				NewGameState.GetContext().PostBuildVisualizationFn.Remove(VisualizeLootIndex, 1);
			}
			//Add the loot message at the end of the list.
			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeAutoLoot);

			History = `XCOMHISTORY;
			BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
			BattleDataState = XComGameState_BattleData(NewGameState.CreateStateObject(class'XComGameState_BattleData', BattleDataState.ObjectID));
			ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

			foreach PendingAutoLoot.LootToBeCreated(LootTemplateName)
			{
				ItemTemplate = ItemTemplateManager.FindItemTemplate(LootTemplateName);
				if( bKilledByExplosion )
				{
					if( ItemTemplate.LeavesExplosiveRemains )
					{
						if( ItemTemplate.ExplosiveRemains != '' )
						{
							ItemTemplate = ItemTemplateManager.FindItemTemplate(ItemTemplate.ExplosiveRemains);     //  item leaves a different item behind due to explosive death
						}
					}
					else
					{
						ItemTemplate = None;
					}
				}

				if( ItemTemplate != None )
				{
					if( ItemTemplate.bAlwaysRecovered )
					{
						XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
						XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
						NewGameState.AddStateObject(XComHQ);

						NewItem = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
						NewGameState.AddStateObject(NewItem);

						NewItem.OwnerStateObject = XComHQ.GetReference();
						XComHQ.PutItemInInventory(NewGameState, NewItem, true);

						AnyAlwaysRecoverLoot = true;
					}
					else
					{
						BattleDataState.AutoLootBucket.AddItem(ItemTemplate.DataName);
					}
				}
			}

			NewGameState.AddStateObject(BattleDataState);

			if( AnyAlwaysRecoverLoot )
			{
				NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeAlwaysRecoverLoot);
			}
		}
	}
}

function VisualizeAutoLoot(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComPresentationLayer Presentation;
	local XComGameState_BattleData OldBattleData, NewBattleData;
	local XComGameStateHistory History;
	local int LootBucketIndex;
	local VisualizationTrack BuildTrack;
	local X2Action_PlayWorldMessage MessageAction;
	local XGParamTag kTag;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<Name> UniqueItemNames;
	local array<int> ItemQuantities;
	local int ExistingIndex;

	Presentation = `PRES;
	History = `XCOMHISTORY;

	// add a message for each loot drop
	NewBattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	NewBattleData = XComGameState_BattleData(History.GetGameStateForObjectID(NewBattleData.ObjectID, , VisualizeGameState.HistoryIndex));
	OldBattleData = XComGameState_BattleData(History.GetGameStateForObjectID(NewBattleData.ObjectID, , VisualizeGameState.HistoryIndex - 1));

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = History.GetVisualizer(ObjectID);

	MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for( LootBucketIndex = OldBattleData.AutoLootBucket.Length; LootBucketIndex < NewBattleData.AutoLootBucket.Length; ++LootBucketIndex )
	{
		ExistingIndex = UniqueItemNames.Find(NewBattleData.AutoLootBucket[LootBucketIndex]);
		if( ExistingIndex == INDEX_NONE )
		{
			UniqueItemNames.AddItem(NewBattleData.AutoLootBucket[LootBucketIndex]);
			ItemQuantities.AddItem(1);
		}
		else
		{
			++ItemQuantities[ExistingIndex];
		}
	}

	for( LootBucketIndex = 0; LootBucketIndex < UniqueItemNames.Length; ++LootBucketIndex )
	{
		kTag.StrValue0 = ItemTemplateManager.FindItemTemplate(UniqueItemNames[LootBucketIndex]).GetItemFriendlyName();
		kTag.IntValue0 = ItemQuantities[LootBucketIndex];
		MessageAction.AddWorldMessage(`XEXPAND.ExpandString(Presentation.m_strAutoLoot));
	}

	OutVisualizationTracks.AddItem(BuildTrack);
}

function VisualizeAlwaysRecoverLoot(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComPresentationLayer Presentation;
	local XComGameState_HeadquartersXCom OldXComHQ, NewXComHQ;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local Name ItemTemplateName;
	local int LootBucketIndex;
	local VisualizationTrack BuildTrack;
	local X2Action_PlayWorldMessage MessageAction;
	local XGParamTag kTag;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<Name> UniqueItemNames;
	local array<int> ItemQuantities;
	local int ExistingIndex;

	Presentation = `PRES;
	History = `XCOMHISTORY;

	// add a message for each loot drop
	NewXComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NewXComHQ = XComGameState_HeadquartersXCom(History.GetGameStateForObjectID(NewXComHQ.ObjectID, , VisualizeGameState.HistoryIndex));
	OldXComHQ = XComGameState_HeadquartersXCom(History.GetGameStateForObjectID(NewXComHQ.ObjectID, , VisualizeGameState.HistoryIndex - 1));

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = History.GetVisualizer(ObjectID);

	MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for( LootBucketIndex = OldXComHQ.LootRecovered.Length; LootBucketIndex < NewXComHQ.LootRecovered.Length; ++LootBucketIndex )
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(NewXComHQ.LootRecovered[LootBucketIndex].ObjectID));
		ItemTemplateName = ItemState.GetMyTemplateName();
		ExistingIndex = UniqueItemNames.Find(ItemTemplateName);
		if( ExistingIndex == INDEX_NONE )
		{
			UniqueItemNames.AddItem(ItemTemplateName);
			ItemQuantities.AddItem(1);
		}
		else
		{
			++ItemQuantities[ExistingIndex];
		}
	}

	for( LootBucketIndex = 0; LootBucketIndex < UniqueItemNames.Length; ++LootBucketIndex )
	{
		kTag.StrValue0 = ItemTemplateManager.FindItemTemplate(UniqueItemNames[LootBucketIndex]).GetItemFriendlyName();
		kTag.IntValue0 = ItemQuantities[LootBucketIndex];
		MessageAction.AddWorldMessage(`XEXPAND.ExpandString(Presentation.m_strAutoLoot));
	}

	OutVisualizationTracks.AddItem(BuildTrack);
}


function ResetTraversals()
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = GetMyTemplate();
	aTraversals[eTraversal_Normal]       = int(CharTemplate.bCanUse_eTraversal_Normal);	
	aTraversals[eTraversal_ClimbOver]    = int(CharTemplate.bCanUse_eTraversal_ClimbOver);	
	aTraversals[eTraversal_ClimbOnto]    = int(CharTemplate.bCanUse_eTraversal_ClimbOnto);	
	aTraversals[eTraversal_ClimbLadder]  = int(CharTemplate.bCanUse_eTraversal_ClimbLadder);	
	aTraversals[eTraversal_DropDown]     = int(CharTemplate.bCanUse_eTraversal_DropDown);	
	aTraversals[eTraversal_Grapple]      = int(CharTemplate.bCanUse_eTraversal_Grapple);	
	aTraversals[eTraversal_Landing]      = int(CharTemplate.bCanUse_eTraversal_Landing);	
	aTraversals[eTraversal_BreakWindow]  = int(CharTemplate.bCanUse_eTraversal_BreakWindow);	
	aTraversals[eTraversal_KickDoor]     = int(CharTemplate.bCanUse_eTraversal_KickDoor);	
	aTraversals[eTraversal_JumpUp]       = int(CharTemplate.bCanUse_eTraversal_JumpUp);	
	aTraversals[eTraversal_WallClimb]    = int(CharTemplate.bCanUse_eTraversal_WallClimb);
	aTraversals[eTraversal_Phasing]      = int(CharTemplate.bCanUse_eTraversal_Phasing);
	aTraversals[eTraversal_BreakWall]    = int(CharTemplate.bCanUse_eTraversal_BreakWall);
	aTraversals[eTraversal_Launch]       = int(CharTemplate.bCanUse_eTraversal_Launch);
	aTraversals[eTraversal_Flying]       = int(CharTemplate.bCanUse_eTraversal_Flying);
	aTraversals[eTraversal_Land]         = int(CharTemplate.bCanUse_eTraversal_Land);
}

native function int GetRank();

function bool IsVeteran()
{
	return GetRank() >= class'X2StrategyGameRulesetDataStructures'.default.VeteranSoldierRank;
}

function SetSoldierClassTemplate(name TemplateName)
{
	m_SoldierClassTemplateName = TemplateName;
	m_SoldierClassTemplate = GetSoldierClassTemplate();
}

function SetMPCharacterTemplate(name TemplateName)
{
	m_MPCharacterTemplateName = TemplateName;
	m_MPCharacterTemplate = class'X2MPCharacterTemplateManager'.static.GetMPCharacterTemplateManager().FindMPCharacterTemplate(m_MPCharacterTemplateName);
}

function name GetMPCharacterTemplateName()
{
	return m_MPCharacterTemplateName;
}

function bool IsMPCharacter()
{
	return (m_MPCharacterTemplateName != '');
}

function X2MPCharacterTemplate GetMPCharacterTemplate()
{
	return m_MPCharacterTemplate;
}

function ClearSoldierClassTemplate()
{
	m_SoldierClassTemplateName = '';
	m_SoldierClassTemplate = none;
}

native function X2SoldierClassTemplate GetSoldierClassTemplate();

function RollForAWCAbility()
{
	local ClassAgnosticAbility HiddenTalent;
	local array<SoldierClassAbilityType> EligibleAbilities;
	local int AbilityRank, Idx, RemIdx;
	local X2SoldierClassTemplate SoldierClassTemplate;

	if(!bRolledForAWCAbility)
	{
		bRolledForAWCAbility = true;
		EligibleAbilities = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().GetCrossClassAbilities(GetSoldierClassTemplate());
		
		SoldierClassTemplate = GetSoldierClassTemplate();
		for (Idx = 0; Idx < SoldierClassTemplate.ExcludedAbilities.Length; ++Idx)
		{
			RemIdx = EligibleAbilities.Find('AbilityName', SoldierClassTemplate.ExcludedAbilities[Idx]);
			if (RemIdx != INDEX_NONE)
				EligibleAbilities.Remove(RemIdx, 1);
		}			

		if(EligibleAbilities.Length > 0)
		{
			AbilityRank = class'XComGameState_HeadquartersXCom'.default.XComHeadquarters_MinAWCTalentRank + `SYNC_RAND_STATIC(
			class'XComGameState_HeadquartersXCom'.default.XComHeadquarters_MaxAWCTalentRank - class'XComGameState_HeadquartersXCom'.default.XComHeadquarters_MinAWCTalentRank + 1);
			if (AbilityRank == m_SoldierRank) // If the rolled ability rank is the soldier's current rank, don't give them the ability
			{
				AbilityRank--;
			}

			HiddenTalent.AbilityType = EligibleAbilities[`SYNC_RAND_STATIC(EligibleAbilities.Length)];
			HiddenTalent.iRank = AbilityRank;
			AWCAbilities.AddItem(HiddenTalent);
		}
	}
}

function bool NeedsAWCAbilityUpdate()
{
	// deprecated
	return NeedsAWCAbilityPopup();
}

function bool NeedsAWCAbilityPopup()
{
	local int idx;
	
	if (!bSeenAWCAbilityPopup)
	{
		for(idx = 0; idx < AWCAbilities.Length; idx++)
		{
			if(AWCAbilities[idx].bUnlocked)
			{
				return true;
			}
		}
	}

	return false;
}

function array<name> GetAWCAbilityNames()
{
	local array<name> AWCAbilityNames;
	local int idx;

	for (idx = 0; idx < AWCAbilities.Length; idx++)
	{
		if (AWCAbilities[idx].bUnlocked)
		{
			AWCAbilityNames.AddItem(AWCAbilities[idx].AbilityType.AbilityName);
		}
	}

	return AWCAbilityNames;
}

function RollForPsiAbilities()
{
	local SCATProgression PsiAbility;
	local array<SCATProgression> PsiAbilityDeck;
	local int NumRanks, iRank, iBranch, idx;

	NumRanks = m_SoldierClassTemplate.GetMaxConfiguredRank();
		
	for (iRank = 0; iRank < NumRanks; iRank++)
	{
		for (iBranch = 0; iBranch < 2; iBranch++)
		{
			PsiAbility.iRank = iRank;
			PsiAbility.iBranch = iBranch;
			PsiAbilityDeck.AddItem(PsiAbility);
		}
	}

	while (PsiAbilityDeck.Length > 0)
	{
		// Choose an ability randomly from the deck
		idx = `SYNC_RAND(PsiAbilityDeck.Length);
		PsiAbility = PsiAbilityDeck[idx];
		PsiAbilities.AddItem(PsiAbility);
		PsiAbilityDeck.Remove(idx, 1);
	}
}

function array<SoldierClassAbilityType> GetEarnedSoldierAbilities()
{
	local X2SoldierClassTemplate ClassTemplate;
	local array<SoldierClassAbilityType> EarnedAbilities, AbilityTree;
	local SoldierClassAbilityType Ability;
	local int i;

	ClassTemplate = GetSoldierClassTemplate();
	if (ClassTemplate != none)
	{
		for (i = 0; i < m_SoldierProgressionAbilties.Length; ++i)
		{
			if (ClassTemplate.GetMaxConfiguredRank() <= m_SoldierProgressionAbilties[i].iRank)
				continue;
			AbilityTree = ClassTemplate.GetAbilityTree(m_SoldierProgressionAbilties[i].iRank);
			if (AbilityTree.Length <= m_SoldierProgressionAbilties[i].iBranch)
				continue;
			Ability = AbilityTree[m_SoldierProgressionAbilties[i].iBranch];
			EarnedAbilities.AddItem(Ability);
		}
	}

	for(i = 0; i < AWCAbilities.Length; ++i)
	{
		if(AWCAbilities[i].bUnlocked && m_SoldierRank >= AWCAbilities[i].iRank)
		{
			EarnedAbilities.AddItem(AWCAbilities[i].AbilityType);
		}
	}

	return EarnedAbilities;
}

//  Looks for the Ability inside the unit's earned soldier abilities. If bSearchAllAbilties is true, it will use FindAbility to see if the unit currently has the ability at all.
native function bool HasSoldierAbility(name Ability, optional bool bSearchAllAbilities = true);

function bool HasGrenadePocket()
{
	local name CheckAbility;

	foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksGrenadePocket(CheckAbility)
	{
		if (HasSoldierAbility(CheckAbility))
			return true;
	}
	return false;
}

function bool HasAmmoPocket()
{
	local name CheckAbility;

	foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksAmmoPocket(CheckAbility)
	{
		if (HasSoldierAbility(CheckAbility))
			return true;
	}
	return false;
}

function bool HasExtraUtilitySlot()
{
	local XComGameState_Item ItemState;

	ItemState = GetItemInSlot(eInvSlot_Armor);
	if (ItemState != none)
	{
		return X2ArmorTemplate(ItemState.GetMyTemplate()).bAddsUtilitySlot;
	}
	return false;
}

function bool HasHeavyWeapon(optional XComGameState CheckGameState)
{
	local XComGameState_Item ItemState;
	local name CheckAbility;

	foreach class'X2AbilityTemplateManager'.default.AbilityUnlocksHeavyWeapon(CheckAbility)
	{
		if (HasSoldierAbility(CheckAbility))
			return true;
	}

	ItemState = GetItemInSlot(eInvSlot_Armor, CheckGameState);
	if (ItemState != none)
	{
		return ItemState.AllowsHeavyWeapon();
	}
	return false;
}

function bool BuySoldierProgressionAbility(XComGameState NewGameState, int iAbilityRank, int iAbilityBranch)
{
	local SCATProgression ProgressAbility;
	local bool bSuccess;
	local name AbilityName;
	local X2AbilityTemplate AbilityTemplate;

	bSuccess = false;

	// Update only if the selection is valid
	AbilityName = m_SoldierClassTemplate.GetAbilityName(iAbilityRank, iAbilityBranch);
	if (AbilityName == '')
	{
		return bSuccess;
	}

	//Silently ignore duplicates, returning success.
	foreach m_SoldierProgressionAbilties(ProgressAbility)
	{
		if (ProgressAbility.iBranch == iAbilityBranch && ProgressAbility.iRank == iAbilityRank)
		{
			bSuccess = true;
			return bSuccess;
		}
	}

	ProgressAbility.iRank = iAbilityRank;
	ProgressAbility.iBranch = iAbilityBranch;

	m_SoldierProgressionAbilties.AddItem(ProgressAbility);
	bSuccess = true;

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
	if (AbilityTemplate != none && AbilityTemplate.SoldierAbilityPurchasedFn != none)
		AbilityTemplate.SoldierAbilityPurchasedFn(NewGameState, self);

	return bSuccess;
}

function ResetSoldierRank()
{
	local int i;
	local ECharStatType StatType;
	local X2CharacterTemplate Template;

	Template = GetMyTemplate();
	m_SoldierRank = 0;
	m_SoldierProgressionAbilties.Length = 0;

	for (i = 0; i < eStat_MAX; ++i)
	{
		StatType = ECharStatType(i);
		CharacterStats[i].Type = StatType;
		SetBaseMaxStat( StatType, Template.CharacterBaseStats[i] );
		SetCurrentStat( StatType, GetMaxStat(StatType) );
	}
}

function ResetSoldierAbilities()
{
	//local int idx;

	m_SoldierProgressionAbilties.Length = 0;
	
	// remove any AWC abilities which were previously unlocked
	//for (idx = 0; idx < AWCAbilities.Length; idx++)
	//{
	//	if (AWCAbilities[idx].bUnlocked)
	//	{
	//		AWCAbilities.Remove(idx, 1);
	//		idx--;
	//	}
	//}
}

function bool HasSpecialBond(XComGameState_Unit BondMate)
{
	local SquadmateScore CurrentScore;

	if(GetSquadmateScore(BondMate.ObjectID, CurrentScore))
	{
		return (CurrentScore.eRelationship == eRelationshipState_SpecialBond);
	}

	return false;
}

// Returns a string of this unit's current location
function string GetLocation()
{
	if (StaffingSlot.ObjectID != 0)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffingSlot.ObjectID)).GetLocationDisplayString();
	}

	return class'XLocalizedData'.default.SoldierStatusAvailable;
}

// Returns staffing slot they are in (none if not staffed)
function XComGameState_StaffSlot GetStaffSlot()
{
	if (StaffingSlot.ObjectID != 0)
	{
		return XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffingSlot.ObjectID));
	}

	return none;
}

// Returns headquarters room they are in (none if not in staffing slot)
function XComGameState_HeadquartersRoom GetRoom()
{
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	if (StaffingSlot.ObjectID != 0)
	{
		StaffSlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffingSlot.ObjectID));
		return XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(StaffSlotState.Room.ObjectID));
	}
	
	return none;
}

function int GetUnitPointValue()
{
	local XComGameState ParentGameState;
	local XComGameState_Item ItemGameState;
	local int Points;

	if(GetMPCharacterTemplate() != none)
	{
		Points = GetMPCharacterTemplate().Cost;
		
		// only soldiers are allowed to customize their items and therefore affect the cost. otherwise its just the MP character type cost. -tsmith
		if(IsSoldier())
		{
			ParentGameState = GetParentGameState();
			foreach ParentGameState.IterateByClassType(class'XComGameState_Item', ItemGameState)
			{
				if (ItemGameState.OwnerStateObject.ObjectID != ObjectId)
					continue;

				if(ItemIsInMPBaseLoadout(ItemGameState.GetMyTemplateName()))
				{
					if(GetNumItemsByTemplateName(ItemGameState.GetMyTemplateName(), ParentGameState) > 1)
					{
						Points += ItemGameState.GetMyTemplate().MPCost / GetNumItemsByTemplateName(ItemGameState.GetMyTemplateName(), ParentGameState);
					}
					continue;
				}

				Points += ItemGameState.GetMyTemplate().MPCost;
			}
		}
	}
	else
	{
		Points = 0;
	}
	
	return Points;
}

function protected MergeAmmoAsNeeded(XComGameState StartState)
{
	local XComGameState_Item ItemIter, ItemInnerIter;
	local X2WeaponTemplate MergeTemplate;
	local int Idx, InnerIdx, BonusAmmo;

	for (Idx = 0; Idx < InventoryItems.Length; ++Idx)
	{
		ItemIter = XComGameState_Item(StartState.GetGameStateForObjectID(InventoryItems[Idx].ObjectID));
		if (ItemIter != none && !ItemIter.bMergedOut)
		{
			MergeTemplate = X2WeaponTemplate(ItemIter.GetMyTemplate());
			if (MergeTemplate != none && MergeTemplate.bMergeAmmo)
			{
				BonusAmmo = GetBonusWeaponAmmoFromAbilities(ItemIter, StartState);
				ItemIter.MergedItemCount = 1;
				for (InnerIdx = Idx + 1; InnerIdx < InventoryItems.Length; ++InnerIdx)
				{
					ItemInnerIter = XComGameState_Item(StartState.GetGameStateForObjectID(InventoryItems[InnerIdx].ObjectID));
					if (ItemInnerIter != none && ItemInnerIter.GetMyTemplate() == MergeTemplate)
					{
						BonusAmmo += GetBonusWeaponAmmoFromAbilities(ItemInnerIter, StartState);
						ItemInnerIter.bMergedOut = true;
						ItemInnerIter.Ammo = 0;
						ItemIter.MergedItemCount++;
					}
				}
				ItemIter.Ammo = ItemIter.GetClipSize() * ItemIter.MergedItemCount + BonusAmmo;
			}
		}
	}
}

function protected int GetBonusWeaponAmmoFromAbilities(XComGameState_Item ItemState, XComGameState StartState)
{
	local array<SoldierClassAbilityType> SoldierAbilities;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local int Bonus, Idx;

	//  Note: This function is called prior to abilities being generated for the unit, so we only inspect
	//          1) the earned soldier abilities
	//          2) the abilities on the character template

	Bonus = 0;
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	SoldierAbilities = GetEarnedSoldierAbilities();

	for (Idx = 0; Idx < SoldierAbilities.Length; ++Idx)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(SoldierAbilities[Idx].AbilityName);
		if (AbilityTemplate != none && AbilityTemplate.GetBonusWeaponAmmoFn != none)
			Bonus += AbilityTemplate.GetBonusWeaponAmmoFn(self, ItemState);
	}

	CharacterTemplate = GetMyTemplate();
	
	for (Idx = 0; Idx < CharacterTemplate.Abilities.Length; ++Idx)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(CharacterTemplate.Abilities[Idx]);
		if (AbilityTemplate != none && AbilityTemplate.GetBonusWeaponAmmoFn != none)
			Bonus += AbilityTemplate.GetBonusWeaponAmmoFn(self, ItemState);
	}

	return Bonus;
}

function array<AbilitySetupData> GatherUnitAbilitiesForInit(optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local name AbilityName, UnlockName;
	local AbilitySetupData Data, EmptyData;
	local array<AbilitySetupData> arrData, arrAdditional;
	local X2AbilityTemplateManager AbilityTemplateMan;
	local X2AbilityTemplate AbilityTemplate;
	local X2CharacterTemplate CharacterTemplate;
	local array<XComGameState_Item> CurrentInventory;
	local XComGameState_Item InventoryItem;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2SoldierAbilityUnlockTemplate AbilityUnlockTemplate;
	local array<SoldierClassAbilityType> EarnedSoldierAbilities;
	local int i, j, OverrideIdx;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate WeaponUpgradeTemplate;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

	if(StartState != none)
		MergeAmmoAsNeeded(StartState);

	AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	CharacterTemplate = GetMyTemplate();

	//  Gather default abilities if allowed
	if (!CharacterTemplate.bSkipDefaultAbilities)
	{
		foreach class'X2Ability_DefaultAbilitySet'.default.DefaultAbilitySet(AbilityName)
		{
			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
			if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
			{
				Data = EmptyData;
				Data.TemplateName = AbilityName;
				Data.Template = AbilityTemplate;
				arrData.AddItem(Data);
			}
			else if (AbilityTemplate == none)
			{
				`RedScreen("DefaultAbilitySet array specifies unknown ability:" @ AbilityName);
			}
		}
	}
	//  Gather character specific abilities
	foreach CharacterTemplate.Abilities(AbilityName)
	{
		AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
		if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
		{
			Data = EmptyData;
			Data.TemplateName = AbilityName;
			Data.Template = AbilityTemplate;
			arrData.AddItem(Data);
		}
		else if (AbilityTemplate == none)
		{
			`RedScreen("Character template" @ CharacterTemplate.DataName @ "specifies unknown ability:" @ AbilityName);
		}
	}
	//  Gather abilities from the unit's inventory
	CurrentInventory = GetAllInventoryItems(StartState);
	foreach CurrentInventory(InventoryItem)
	{
		if (InventoryItem.bMergedOut || InventoryItem.InventorySlot == eInvSlot_Unknown)
			continue;
		EquipmentTemplate = X2EquipmentTemplate(InventoryItem.GetMyTemplate());
		if (EquipmentTemplate != none)
		{
			foreach EquipmentTemplate.Abilities(AbilityName)
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
				if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
				{
					Data = EmptyData;
					Data.TemplateName = AbilityName;
					Data.Template = AbilityTemplate;
					Data.SourceWeaponRef = InventoryItem.GetReference();
					arrData.AddItem(Data);
				}
				else if (AbilityTemplate == none)
				{
					`RedScreen("Equipment template" @ EquipmentTemplate.DataName @ "specifies unknown ability:" @ AbilityName);
				}
			}
		}
		//  Gather abilities from any weapon upgrades
		WeaponUpgradeTemplates = InventoryItem.GetMyWeaponUpgradeTemplates();
		foreach WeaponUpgradeTemplates(WeaponUpgradeTemplate)
		{
			foreach WeaponUpgradeTemplate.BonusAbilities(AbilityName)
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
				if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
				{
					Data = EmptyData;
					Data.TemplateName = AbilityName;
					Data.Template = AbilityTemplate;
					Data.SourceWeaponRef = InventoryItem.GetReference();
					arrData.AddItem(Data);
				}
				else if (AbilityTemplate == none)
				{
					`RedScreen("Weapon upgrade template" @ WeaponUpgradeTemplate.DataName @ "specifies unknown ability:" @ AbilityName);
				}
			}
		}
	}
	//  Gather soldier class abilities
	EarnedSoldierAbilities = GetEarnedSoldierAbilities();
	for (i = 0; i < EarnedSoldierAbilities.Length; ++i)
	{
		AbilityName = EarnedSoldierAbilities[i].AbilityName;
		AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
		if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
		{
			Data = EmptyData;
			Data.TemplateName = AbilityName;
			Data.Template = AbilityTemplate;
			if (EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Unknown)
			{
				foreach CurrentInventory(InventoryItem)
				{
					if (InventoryItem.bMergedOut)
						continue;
					if (InventoryItem.InventorySlot == EarnedSoldierAbilities[i].ApplyToWeaponSlot)
					{
						Data.SourceWeaponRef = InventoryItem.GetReference();

						if (EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Utility)
						{
							//  stop searching as this is the only valid item
							break;
						}
						else
						{
							//  add this item if valid and keep looking for other utility items
							if (InventoryItem.GetWeaponCategory() == EarnedSoldierAbilities[i].UtilityCat)							
							{
								arrData.AddItem(Data);
							}
						}
					}
				}
				//  send an error if it wasn't a utility item (primary/secondary weapons should always exist)
				if (Data.SourceWeaponRef.ObjectID == 0 && EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Utility)
				{
					`RedScreen("Soldier ability" @ AbilityName @ "wants to attach to slot" @ EarnedSoldierAbilities[i].ApplyToWeaponSlot @ "but no weapon was found there.");
				}
			}
			//  add data if it wasn't on a utility item
			if (EarnedSoldierAbilities[i].ApplyToWeaponSlot != eInvSlot_Utility)
			{
				if (AbilityTemplate.bUseLaunchedGrenadeEffects)     //  could potentially add another flag but for now this is all we need it for -jbouscher
				{
					//  populate a version of the ability for every grenade in the inventory
					foreach CurrentInventory(InventoryItem)
					{
						if (InventoryItem.bMergedOut) 
							continue;

						if (X2GrenadeTemplate(InventoryItem.GetMyTemplate()) != none)
						{ 
							Data.SourceAmmoRef = InventoryItem.GetReference();
							arrData.AddItem(Data);
						}
					}
				}
				else
				{
					arrData.AddItem(Data);
				}
			}
		}
	}
	//  Add abilities based on the player state
	if (PlayerState != none && PlayerState.IsAIPlayer())
	{
		foreach class'X2Ability_AlertMechanics'.default.AlertAbilitySet(AbilityName)
		{
			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
			if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
			{
				Data = EmptyData;
				Data.TemplateName = AbilityName;
				Data.Template = AbilityTemplate;
				arrData.AddItem(Data);
			}
			else if (AbilityTemplate == none)
			{
				`RedScreen("AlertAbilitySet array specifies unknown ability:" @ AbilityName);
			}
		}
	}
	if (PlayerState != none && PlayerState.SoldierUnlockTemplates.Length > 0)
	{
		foreach PlayerState.SoldierUnlockTemplates(UnlockName)
		{
			AbilityUnlockTemplate = X2SoldierAbilityUnlockTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(UnlockName));
			if (AbilityUnlockTemplate == none)
				continue;
			if (!AbilityUnlockTemplate.UnlockAppliesToUnit(self))
				continue;

			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityUnlockTemplate.AbilityName);
			if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
			{
				Data = EmptyData;
				Data.TemplateName = AbilityUnlockTemplate.AbilityName;
				Data.Template = AbilityTemplate;
				arrData.AddItem(Data);
			}
		}
	}

	if( bIsShaken )
	{
		AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate('ShakenPassive');
		if( AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE )
		{
			Data = EmptyData;
			Data.TemplateName = 'ShakenPassive';
			Data.Template = AbilityTemplate;
			arrData.AddItem(Data);
		}
	}

	//  Check for ability overrides - do it BEFORE adding additional abilities so we don't end up with extra ones we shouldn't have
	for (i = arrData.Length - 1; i >= 0; --i)
	{
		if (arrData[i].Template.OverrideAbilities.Length > 0)
		{
			for (j = 0; j < arrData[i].Template.OverrideAbilities.Length; ++j)
			{
				OverrideIdx = arrData.Find('TemplateName', arrData[i].Template.OverrideAbilities[j]);
				if (OverrideIdx != INDEX_NONE)
				{
					arrData[OverrideIdx].Template = arrData[i].Template;
					arrData[OverrideIdx].TemplateName = arrData[i].TemplateName;
					//  only override the weapon if requested. otherwise, keep the original source weapon for the override ability
					if (arrData[i].Template.bOverrideWeapon)
						arrData[OverrideIdx].SourceWeaponRef = arrData[i].SourceWeaponRef;
				
					arrData.Remove(i, 1);
					break;
				}
			}
		}
	}
	//  Add any additional abilities
	for (i = 0; i < arrData.Length; ++i)
	{
		foreach arrData[i].Template.AdditionalAbilities(AbilityName)
		{
			AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(AbilityName);
			if (AbilityTemplate != none && !AbilityTemplate.bUniqueSource || arrData.Find('TemplateName', AbilityTemplate.DataName) == INDEX_NONE)
			{
				Data = EmptyData;
				Data.TemplateName = AbilityName;
				Data.Template = AbilityTemplate;
				Data.SourceWeaponRef = arrData[i].SourceWeaponRef;
				arrAdditional.AddItem(Data);
			}			
		}
	}
	//  Move all of the additional abilities into the return list
	for (i = 0; i < arrAdditional.Length; ++i)
	{
		if( arrData.Find('TemplateName', arrAdditional[i].TemplateName) == INDEX_NONE )
		{
			arrData.AddItem(arrAdditional[i]);
		}
	}
	//  Check for ability overrides AGAIN - in case the additional abilities want to override something
	for (i = arrData.Length - 1; i >= 0; --i)
	{
		if (arrData[i].Template.OverrideAbilities.Length > 0)
		{
			for (j = 0; j < arrData[i].Template.OverrideAbilities.Length; ++j)
			{
				OverrideIdx = arrData.Find('TemplateName', arrData[i].Template.OverrideAbilities[j]);
				if (OverrideIdx != INDEX_NONE)
				{
					arrData[OverrideIdx].Template = arrData[i].Template;
					arrData[OverrideIdx].TemplateName = arrData[i].TemplateName;
					//  only override the weapon if requested. otherwise, keep the original source weapon for the override ability
					if (arrData[i].Template.bOverrideWeapon)
						arrData[OverrideIdx].SourceWeaponRef = arrData[i].SourceWeaponRef;
				
					arrData.Remove(i, 1);
					break;
				}
			}
		}
	}	
	
	if (XComHQ != none)
	{
		// remove any abilities whose requirements are not met
		for( i = arrData.Length - 1; i >= 0; --i )
		{
			if( !XComHQ.MeetsAllStrategyRequirements(arrData[i].Template.Requirements) )
			{
				arrData.Remove(i, 1);
			}
		}
	}
	else
	{
		`log("No XComHeadquarters data available to filter unit abilities");
	}

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.FinalizeUnitAbilitiesForInit(self, arrData, StartState, PlayerState, bMultiplayerDisplay);
	}

	return arrData;
}

//IMPORTED FROM XGStrategySoldier
//@TODO - rmcfall - Evaluate and replace?
//=============================================================================================
simulated function string GetFirstName()
{
	return strFirstName;
}

simulated function string GetLastName()
{
	return strLastName;
}

simulated function string GetNickName(optional bool noQuotes = false)
{
	if (strNickName == "")
	{
		return "";
	}
	//once Quoted by either '' or "", stop appending quote to the nickname
	else if (!noQuotes && (Left(strNickName, 1) != "'" && Right(strNickName, 1) != "'") )
	{
		return "'"$strNickName$"'";
	}
	else
	{
		return strNickName;
	}
}

simulated function SetUnitName( string firstName, string lastName, string nickName )
{
	strFirstName = firstName; 
	strLastName = lastName; 
	strNickname = nickName;
}

function string GetFullName()
{
	return GetName(eNameType_Full);
}

function string GetName( ENameType eType )
{
	local bool bFirstNameBlank;

	if(IsMPCharacter())
		return GetMPName(eType);

	if (IsSoldier() || IsCivilian())
	{
		bFirstNameBlank = (strFirstName == "");
		switch( eType )
		{
		case eNameType_First:
			return strFirstName;
			break;
		case eNameType_Last:
			return strLastName;
			break;
		case eNameType_Nick:
			if( strNickName != "" )
			{			
				if( Left(strNickName, 1) != "'" && Right(strNickName, 1) != "'")//bsg lmordarski (5/29/2012) - prevent single quotes from being added multiple times
				{
					return "'"$strNickName$"'";
				}
				else
				{
					return strNickName;
				}
			}
			else
				return " ";
			break;
		case eNameType_Full:
			if(bFirstNameBlank)
				return strLastName;
			return strFirstName @ strLastName;
			break;
		case eNameType_Rank:
			return `GET_RANK_STR(m_SoldierRank, m_SoldierClassTemplateName);
			break;
		case eNameType_RankLast:
			return `GET_RANK_ABBRV(m_SoldierRank, m_SoldierClassTemplateName) @ strLastName;
			break;
		case eNameType_RankFull:
			if(bFirstNameBlank)
				return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strLastName;
			return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strFirstName @ strLastName;
			break;
		case eNameType_FullNick:
			if(strNickName != "")
			{
				if(bFirstNameBlank)
					return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ "'"$strNickName$"'" @ strLastName;
				return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strFirstName @ "'"$strNickName$"'" @ strLastName;
			}
			else
			{
				if(bFirstNameBlank)
					return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strLastName;
				return `GET_RANK_ABBRV( m_SoldierRank, m_SoldierClassTemplateName ) @ strFirstName @ strLastName;
			}
				
			break;
		}

		return "???";
	}
	return GetMyTemplate().strCharacterName;
}

// Aliens can have human names in MP
function string GetMPName( ENameType eType )
{
	switch( eType )
	{
	case eNameType_First:
		return strFirstName;
		break;
	case eNameType_Last:
		return strLastName;
		break;
	case eNameType_Nick:
		if( strNickName != "" )
		{			
			if( Left(strNickName, 1) != "'" && Right(strNickName, 1) != "'")//bsg lmordarski (5/29/2012) - prevent single quotes from being added multiple times
			{
				return "'"$strNickName$"'";
			}
			else
			{
				return strNickName;
			}
		}
		else
			return " ";
		break;
	case eNameType_Full:
		return strFirstName @ strLastName;
		break;
	case eNameType_Rank:
		return `GET_RANK_STR(m_SoldierRank, m_MPCharacterTemplateName);
		break;
	case eNameType_RankLast:
		return `GET_RANK_ABBRV(m_SoldierRank, m_MPCharacterTemplateName) @ strLastName;
		break;
	case eNameType_RankFull:
		return `GET_RANK_ABBRV( m_SoldierRank, m_MPCharacterTemplateName ) @ strFirstName @ strLastName;
		break;
	case eNameType_FullNick:
		if(IsSoldier())
		{
			if(strNickName != "")
				return `GET_RANK_ABBRV( m_SoldierRank, m_MPCharacterTemplateName ) @ strFirstName @ "'"$strNickName$"'" @ strLastName;
			else
				return `GET_RANK_ABBRV( m_SoldierRank, m_MPCharacterTemplateName ) @ strFirstName @ strLastName;
		}
		else
		{
			if(strNickName != "")
				return strFirstName @ "'"$strNickName$"'" @ strLastName;
			else
				return strFirstName @ strLastName;
		}
		
		break;
	}
}

function string GetBackground()
{
	return strBackground;
}

function SetBackground(string NewBackground)
{
	strBackground = NewBackground;
}

function bool HasBackground()
{
	return strBackground != "";
}

function GenerateBackground(optional string ForceBackgroundStory)
{
	local XGParamTag LocTag;
	local TDateTime Birthday;
	local X2CharacterTemplate CharTemplate;	
	local string BackgroundStory;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));	
	
	LocTag.StrValue0 = GetCountryTemplate().DisplayName;
	strBackground = `XEXPAND.ExpandString(class'XLocalizedData'.default.CountryBackground);
	strBackground $= "\n";

	Birthday.m_iMonth = Rand(12) + 1;
	Birthday.m_iDay = (Birthday.m_iMonth == 2 ? Rand(27) : Rand(30)) + 1;
	Birthday.m_iYear = class'X2StrategyGameRulesetDataStructures'.default.START_YEAR - int(RandRange(25, 35));
	LocTag.StrValue0 = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Birthday);

	strBackground $= `XEXPAND.ExpandString(class'XLocalizedData'.default.DateOfBirthBackground);

	CharTemplate = GetMyTemplate();
	if(ForceBackgroundStory == "")
	{
		if(kAppearance.iGender == eGender_Female)
		{
			BackgroundStory = CharTemplate.strCharacterBackgroundFemale[`SYNC_RAND(CharTemplate.strCharacterBackgroundFemale.Length)];
		}
		else
		{
			BackgroundStory = CharTemplate.strCharacterBackgroundMale[`SYNC_RAND(CharTemplate.strCharacterBackgroundMale.Length)];
		}
	}
	else
	{
		BackgroundStory = ForceBackgroundStory;
	}	

	if(BackgroundStory != "")
	{		
		LocTag.StrValue0 = GetCountryTemplate().DisplayNameWithArticleLower;
		LocTag.StrValue1 = GetFirstName();
		strBackground $= "\n\n" $ `XEXPAND.ExpandString(BackgroundStory);
	}
}

function SetTAppearance(const out TAppearance NewAppearance)
{
	kAppearance = NewAppearance;
}

function SetHQLocation(ESoldierLocation NewLocation)
{
	HQLocation = NewLocation;
}

function ESoldierLocation GetHQLocation()
{
	return HQLocation;
}

function int RollStat( int iLow, int iHigh, int iMultiple )
{
	local int iSpread, iNewStat; 

	iSpread = iHigh - iLow;

	iNewStat = iLow + `SYNC_RAND( iSpread/iMultiple + 1 ) * iMultiple;

	if( iNewStat == iHigh && `SYNC_RAND(2) == 0 )
		iNewStat += iMultiple;

	return iNewStat;
}

function bool ModifySkillValue(int iDelta)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int OldValue, ThresholdValue;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	OldValue = SkillValue;

	if(XComHQ.bCrunchTime)
	{
		iDelta = Round(float(iDelta) * 1.25);
	}

	SkillValue += iDelta;

	if(GetMyTemplate().SkillLevelThresholds.Length > 0)
	{
		ThresholdValue = GetMyTemplate().SkillLevelThresholds[GetSkillLevel()];

		if(OldValue < ThresholdValue && SkillValue >= ThresholdValue)
		{
			return true;
		}
	}

	return false;
}

function SetSkillLevel(int iSkill)
{
	if(iSkill >= GetMyTemplate().SkillLevelThresholds.Length)
	{
		iSkill = GetMyTemplate().SkillLevelThresholds.Length - 1;
	}

	SkillValue = GetMyTemplate().SkillLevelThresholds[iSkill];
}

function int GetSkillLevel(optional bool bIncludeSkillBonus = false)
{
	local int idx, SkillLevel;

	SkillLevel = 0;

	if (GetMyTemplate().SkillLevelThresholds.Length > 0)
	{
		for (idx = 0; idx < GetMyTemplate().SkillLevelThresholds.Length; idx++)
		{
			if (SkillValue >= GetMyTemplate().SkillLevelThresholds[idx])
			{
				SkillLevel = idx;
			}
		}

		if (bIncludeSkillBonus) //check whether to include the workshop / lab skill bonuses
		{
			SkillLevel += SkillLevelBonus;			
		}
	}

	return SkillLevel;
}

function int GetSkillLostByReassignment()
{
	local int SkillLost;

	SkillLost = 0;

	if (GetRoom() != none)
	{
		if ((IsAnEngineer() && GetRoom().GetFacility().GetMyTemplateName() == 'Workshop') ||
			(IsAScientist() && GetRoom().GetFacility().GetMyTemplateName() == 'Laboratory'))
		{
			//Staffers in lab or shop double their contribution, so the skill lost is equal to 1x their skill if they move
			SkillLost = GetSkillLevel();
		}
	}

	return SkillLost;
}

function bool IsAtMaxSkillLevel()
{
	if(GetMyTemplate().SkillLevelThresholds.Length > 0)
	{
		if(GetSkillLevel() == (GetMyTemplate().SkillLevelThresholds.Length-1))
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	return true;
}

function bool IsASoldier()
{
	return(GetMyTemplate().bIsSoldier);
}

function bool IsAnEngineer()
{
	return(GetMyTemplate().bIsEngineer);
}

function bool IsAScientist()
{
	return(GetMyTemplate().bIsScientist);
}

// Staffing gameplay
function bool CanBeStaffed()
{
	return(IsAlive() && GetMyTemplate().bStaffingAllowed);
}

// Staffing visually
function bool CanAppearInBase()
{
	return(IsAlive() && GetMyTemplate().bAppearInBase);
}

function RandomizeStats()
{
	local int iMultiple;

	if( `GAMECORE.IsOptionEnabled( eGO_RandomRookieStats ) )
	{
		iMultiple = 5;
		SetBaseMaxStat( eStat_Offense, RollStat( class'XGTacticalGameCore'.default.LOW_AIM, class'XGTacticalGameCore'.default.HIGH_AIM, iMultiple ) );

		iMultiple = 1;
		SetBaseMaxStat( eStat_Mobility, RollStat( class'XGTacticalGameCore'.default.LOW_MOBILITY, class'XGTacticalGameCore'.default.HIGH_MOBILITY, iMultiple ) );

		iMultiple = 2;
		SetBaseMaxStat( eStat_Will, RollStat( class'XGTacticalGameCore'.default.LOW_WILL, class'XGTacticalGameCore'.default.HIGH_WILL, iMultiple ) );
	}
}

function bool HasPsiGift()
{
	return bHasPsiGift;
}

function ESoldierStatus GetStatus()
{
	return HQStatus;
}

function SetStatus(ESoldierStatus NewStatus)
{
	HQStatus = NewStatus;
}

function string GetStatusString()
{
	local string FormattedStatus, Status, TimeLabel;
	local int TimeValue;

	GetStatusStringsSeparate(Status, TimeLabel, TimeValue);

	FormattedStatus = Status @ "(" $ string(TimeValue) @ TimeLabel $")";

	return FormattedStatus;
}

function GetStatusStringsSeparate(out string Status, out string TimeLabel, out int TimeValue)
{
	local bool bProjectExists;
	local int iHours, iDays;
	
	if( IsInjured() )
	{
		Status = GetWoundStatus(iHours);
		if (Status != "")
			bProjectExists = true;
	}
	else if (IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
	{
		Status = GetTrainingStatus(iHours);
		if (Status != "")
			bProjectExists = true;
	}
	else if( IsDead() )
	{
		Status = "KIA";
	}
	else
	{
		Status = "";
	}
	
	if (bProjectExists)
	{
		iDays = iHours / 24;

		if (iHours % 24 > 0)
		{
			iDays += 1;
		}

		TimeValue = iDays;
		TimeLabel = class'UIUtilities_Text'.static.GetDaysString(iDays);
	}
}
//-------------------------------------------------------------------------
// Returns a UI state (color) that matches the soldier's status
function int GetStatusUIState()
{
	switch ( GetStatus() )
	{
	case eStatus_Active:
		if(IsDead())
			return eUIState_Bad;
		else 
			return eUIState_Good;
	case eStatus_Healing:
		return eUIState_Bad;
	case eStatus_OnMission:
		return eUIState_Highlight;
	case eStatus_PsiTesting:
	case eStatus_Training:
		return eUIState_Disabled;
	}

	return eUIState_Normal;
}

// For mission summary UI
simulated function bool WasInjuredOnMission()
{
	return (GetCurrentStat(eStat_HP) > 0 && LowestHP < HighestHP);
}

simulated function bool IsInjured()
{
	return GetCurrentStat(eStat_HP) > 0 && GetCurrentStat(eStat_HP) < GetMaxStat(eStat_HP);
}

// Is the Soldier at the most-serious level of injury, given the number of hours in the heal project
simulated function bool IsGravelyInjured(int iHoursToHeal)
{
	local array<int> WoundStates;
	local int idx;

	WoundStates = class'X2StrategyGameRulesetDataStructures'.default.WoundStates[`DifficultySetting].WoundStateLengths;
		
	for (idx = 0; idx < WoundStates.Length; idx++)
	{
		if (iHoursToHeal < WoundStates[idx] || idx == (WoundStates.Length - 1))
		{
			break;
		}
	}
	
	// If the loop broke at the highest wound state, return true
	return (idx == (WoundStates.Length - 1));
}

//This will update the character's appearance with a random scar. Only call if this state object is already part of a game state transaction.
simulated function GainRandomScar()
{
	local X2BodyPartTemplateManager PartTemplateManager;
	local X2SimpleBodyPartFilter BodyPartFilter;
	local X2BodyPartTemplate SelectedScar;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;
	SelectedScar = PartTemplateManager.GetRandomUberTemplate("Scars", BodyPartFilter, BodyPartFilter.FilterAny);

	//Update our appearance
	kAppearance.nmScars = SelectedScar.DataName;
}

simulated function bool IsTraining()
{
	return (GetStatus() == eStatus_Training);
}

simulated function bool IsPsiTraining()
{
	return (GetStatus() == eStatus_PsiTesting);
}

simulated function bool IsPsiAbilityTraining()
{
	return (GetStatus() == eStatus_PsiTraining);
}

simulated function bool IgnoresInjuries()
{
	local X2SoldierClassTemplate ClassTemplate;

	ClassTemplate = GetSoldierClassTemplate();
	if (ClassTemplate != none)
	{
		return ClassTemplate.bIgnoreInjuries;
	}

	return false;
}

function name GetCountry()
{
	return nmCountry;
}

function X2CountryTemplate GetCountryTemplate()
{
	return X2CountryTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(nmCountry));
}

function bool HasHealingProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', HealProject)
	{
		if(HealProject.ProjectFocus == self.GetReference())
		{
			return true;
		}
	}

	return false;
}

// For infirmary -- low->high in severity
function int GetWoundState(out int iHours, optional bool bPausedProject = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local array<int> WoundStates;
	local int idx;
	
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectHealSoldier', HealProject)
	{
		if(HealProject.ProjectFocus == self.GetReference())
		{
			if (bPausedProject)
				iHours = HealProject.GetProjectedNumHoursRemaining();
			else
				iHours = HealProject.GetCurrentNumHoursRemaining();
		
			WoundStates = class'X2StrategyGameRulesetDataStructures'.default.WoundStates[`DifficultySetting].WoundStateLengths;
			for(idx = 0; idx < WoundStates.Length; idx++)
			{
				if(iHours < WoundStates[idx] || idx == (WoundStates.Length - 1))
				{					
					return idx;
				}
			}
		}
	}

	// Soldier isn't injured
	return -1;
}

function string GetWoundStatus(optional out int iHours, optional bool bIgnorePaused = false)
{
	local array<string> WoundStatusStrings;
	local int idx;
	
	WoundStatusStrings = class'X2StrategyGameRulesetDataStructures'.default.WoundStatusStrings;
	idx = GetWoundState(iHours);

	if (iHours == -1) // Heal project is paused
	{
		idx = GetWoundState(iHours, true); // Calculate the projected hours instead of actual
		if (bIgnorePaused)
			return WoundStatusStrings[idx]; // If we are ignoring the paused status, return the normal heal status string
		else
			return GetMyTemplate().strCharacterHealingPaused; // Otherwise return special paused heal string
	}
	else if (idx >= 0)
		return WoundStatusStrings[idx];
	else
		return ""; // Soldier isn't injured
}

function string GetTrainingStatus(optional out int iHours)
{
	local XComGameStateHistory History;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectTrainRookie TrainProject;
	local XComGameState_HeadquartersProjectRespecSoldier RespecProject;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;

	History = `XCOMHISTORY;

	if (StaffingSlot.ObjectID != 0)
	{
		StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(StaffingSlot.ObjectID));
		
		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectTrainRookie', TrainProject)
		{
			if (TrainProject.ProjectFocus == self.GetReference())
			{
				iHours = TrainProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}

		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectRespecSoldier', RespecProject)
		{
			if (RespecProject.ProjectFocus == self.GetReference())
			{
				iHours = RespecProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}

		foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectPsiTraining', PsiProject)
		{
			if (PsiProject.ProjectFocus == self.GetReference())
			{
				iHours = PsiProject.GetCurrentNumHoursRemaining();
				return StaffSlot.GetBonusDisplayString();
			}
		}
	}

	// Soldier isn't training
	return "";
}

function SetCountry( name nmNewCountry )
{
	local XGUnit UnitVisualizer;
	local XComHumanPawn HumanPawn;

	nmCountry = nmNewCountry;
	kAppearance.nmFlag = nmNewCountry; //iFlag needs to be in sync

	//Update the appearance stored in our visualizer if we have one
	UnitVisualizer = XGUnit(GetVisualizer());	
	if( UnitVisualizer != none && UnitVisualizer.GetPawn() != none )
	{
		HumanPawn = XComHumanPawn(UnitVisualizer.GetPawn());
		if( HumanPawn != none )
		{
			HumanPawn.SetAppearance(kAppearance, false);
		}
	}
}

native function ECoverType GetCoverTypeFromLocation();

native function bool IsInWorldEffectTile(const out name WorldEffectName);

function bool CanBleedOut()
{
	local bool CanBleedOut, EffectsAllowBleedOut;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	CanBleedOut = GetMyTemplate().bCanBeCriticallyWounded && `TACTICALRULES != none && !IsBleedingOut();

	EffectsAllowBleedOut = true;
	if( CanBleedOut )
	{
		// Check with effects on the template to see if it can bleed out
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if( EffectState != none )
			{
				EffectTemplate = EffectState.GetX2Effect();
				EffectsAllowBleedOut = EffectTemplate.DoesEffectAllowUnitToBleedOut(self);

				if( !EffectsAllowBleedOut )
				{
					break;
				}
			}
		}
	}

	return CanBleedOut && EffectsAllowBleedOut;
}

function bool ShouldBleedOut(int OverkillDamage)
{
	local int Chance;
	local int Roll, RollOutOf;
	local XComGameState_HeadquartersXCom XComHQ;

	`log("ShouldBleedOut called for" @ ToString(),,'XCom_HitRolls');
	if (CanBleedOut())
	{
		if(`CHEATMGR != none && `CHEATMGR.bForceCriticalWound)
		{
			return true;
		}
		else
		{
			Chance = class'X2StatusEffects'.static.GetBleedOutChance(self, OverkillDamage);
			RollOutOf = class'X2StatusEffects'.default.BLEEDOUT_ROLL;

			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ != none && XComHQ.SoldierUnlockTemplates.Find('StayWithMeUnlock') != INDEX_NONE)
			{
				`log("Applying bonus chance for StayWithMeUnlock...",,'XCom_HitRolls');
				RollOutOf = class'X2StatusEffects'.default.BLEEDOUT_BONUS_ROLL;
			}

			Roll = `SYNC_RAND(RollOutOf);
			`log("Chance to bleed out:" @ Chance @ "Rolled:" @ Roll,,'XCom_HitRolls');
			`log("Bleeding out!", Roll <= Chance, 'XCom_HitRolls');
			`log("Dying!", Roll > Chance, 'XCom_HitRolls');
			return Roll <= Chance;
		}
	}
	`log("Unit cannot possibly bleed out. Dying.",,'XCom_HitRolls');
	return false;
}

protected function bool ApplyBleedingOut(XComGameState NewGameState)
{
	local EffectAppliedData ApplyData;
	local X2Effect BleedOutEffect;
	local string LogMsg;

	if (NewGameState != none)
	{
		BleedOutEffect = class'X2StatusEffects'.static.CreateBleedingOutStatusEffect();
		ApplyData.PlayerStateObjectRef = ControllingPlayer;
		ApplyData.SourceStateObjectRef = GetReference();
		ApplyData.TargetStateObjectRef = GetReference();
		ApplyData.EffectRef.LookupType = TELT_BleedOutEffect;
		if (BleedOutEffect.ApplyEffect(ApplyData, self, NewGameState) == 'AA_Success')
		{
			LogMsg = class'XLocalizedData'.default.BleedingOutLogMsg;
			LogMsg = repl(LogMsg, "#Unit", GetName(eNameType_RankFull));
			`COMBATLOG(LogMsg);
			return true;
		}
	}
	return false;
}

simulated function int GetBleedingOutTurnsRemaining()
{
	local XComGameState_Effect BleedOutEffect;

	if( IsBleedingOut() )
	{
		BleedOutEffect = GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
		if( BleedOutEffect != none )
		{
			return BleedOutEffect.iTurnsRemaining;
		}
	}
	return 0;
}

function bool IsLootable(XComGameState NewGameState)
{
	local bool EffectsAllowLooting;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	EffectsAllowLooting = true;
	// Check with effects on the template to see if it can bleed out
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if( EffectState != none )
		{
			EffectTemplate = EffectState.GetX2Effect();
			EffectsAllowLooting = EffectTemplate.DoesEffectAllowUnitToBeLooted(NewGameState, self);

			if( !EffectsAllowLooting )
			{
				break;
			}
		}
	}

	// no loot drops in Challenge Mode
	if (History.GetSingleGameStateObjectForClass( class'XComGameState_ChallengeData', true ) != none)
	{
		return false;
	}

	return EffectsAllowLooting;
}

function int GetAIPlayerDataID(bool bIgnorePlayerID=false)
{
	local XComGameState_AIPlayerData AIData;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_AIPlayerData', AIData)
	{
		if (bIgnorePlayerID || AIData.m_iPlayerObjectID == ControllingPlayer.ObjectID)
			return AIData.ObjectID;
	}
	return 0;
}

function int GetAIUnitDataID()
{
	local XComGameState_AIUnitData AIData;
	local XComGameStateHistory History;


	if (CachedUnitDataStateObjectId != INDEX_NONE)
		return CachedUnitDataStateObjectID;

	History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_AIUnitData', AIData)
	{
		if (AIData.m_iUnitObjectID == ObjectID)
		{
			CachedUnitDataStateObjectId = AIData.ObjectID;
			return AIData.ObjectID;
		}
	}
	return -1;
}

function AddRupturedValue(const int Rupture)
{
	if (Rupture > Ruptured)
		Ruptured = Rupture;
}

function int GetRupturedValue()
{
	return Ruptured;
}

function AddShreddedValue(const int Shred)
{
	Shredded += Shred;
}

function TakeEffectDamage( const X2Effect DmgEffect, const int DamageAmount, const int MitigationAmount, const int ShredAmount, const out EffectAppliedData EffectData,
						   XComGameState NewGameState, optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false,
						   optional array<Name> AppliedDamageTypes )
{
	if( AppliedDamageTypes.Length == 0 )
	{
		AppliedDamageTypes = DmgEffect.DamageTypes;
	}
	TakeDamage(NewGameState, DamageAmount, MitigationAmount, ShredAmount, EffectData, DmgEffect, EffectData.SourceStateObjectRef, DmgEffect.IsExplosiveDamage(),
			   AppliedDamageTypes, bForceBleedOut, bAllowBleedout, bIgnoreShields);
}

event TakeDamage( XComGameState NewGameState, const int DamageAmount, const int MitigationAmount, const int ShredAmount, optional EffectAppliedData EffectData, 
						optional Object CauseOfDeath, optional StateObjectReference DamageSource, optional bool bExplosiveDamage = false, optional array<name> DamageTypes,
						optional bool bForceBleedOut = false, optional bool bAllowBleedout = true, optional bool bIgnoreShields = false )
{
	local int ShieldHP, DamageAmountBeforeArmor, DamageAmountBeforeArmorMinusShield, 
		      PostShield_MitigationAmount, PostShield_DamageAmount, PostShield_ShredAmount, 
		      DamageAbsorbedByShield;
	local DamageResult DmgResult;
	local string LogMsg;
	local Object ThisObj;
	local X2EventManager EventManager;
	local int OverkillDamage;
	local int iAIDataID;
	local XComGameState_AIPlayerData kAIData;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent PersistentEffect;

	//  Cosmetic units should not take damage
	if (GetMyTemplate( ).bIsCosmetic)
		return;

	// already dead units should not take additional damage
	if (IsDead( ))
	{
		return;
	}

	if (`CHEATMGR != none && `CHEATMGR.bInvincible == true && GetTeam( ) == eTeam_XCom)
	{
		LogMsg = class'XLocalizedData'.default.UnitInvincibleLogMsg;
		LogMsg = repl( LogMsg, "#Unit", GetName( eNameType_RankFull ) );
		`COMBATLOG(LogMsg);
		return;
	}
	if (`CHEATMGR != none && `CHEATMGR.bAlwaysBleedOut)
	{
		bForceBleedOut = true;
	}

	ShieldHP = GetCurrentStat( eStat_ShieldHP );
	PostShield_MitigationAmount = MitigationAmount;
	PostShield_DamageAmount = DamageAmount;
	PostShield_ShredAmount = ShredAmount;
	DamageAbsorbedByShield = 0;
	if ((ShieldHP > 0) && !bIgnoreShields) //If there is a shield, then shield should take all damage from both armor and hp, before spilling back to armor and hp
	{
		DamageAmountBeforeArmor = DamageAmount + MitigationAmount;
		DamageAmountBeforeArmorMinusShield = DamageAmountBeforeArmor - ShieldHP;

		if (DamageAmountBeforeArmorMinusShield > 0) //partial shield, needs to recompute armor
		{
			DamageAbsorbedByShield = ShieldHP;  //The shield took as much damage as possible
			PostShield_MitigationAmount = DamageAmountBeforeArmorMinusShield;
			if (PostShield_MitigationAmount > MitigationAmount) //damage is more than what armor can take
			{
				PostShield_DamageAmount = (DamageAmountBeforeArmorMinusShield - MitigationAmount);
				PostShield_MitigationAmount = MitigationAmount;
			}
			else //Armor takes the rest of the damage
			{
				PostShield_DamageAmount = 0;
			}

			// Armor is taking damage, which might cause shred. We shouldn't shred more than the
			// amount of armor used.
			PostShield_ShredAmount = min(PostShield_ShredAmount, PostShield_MitigationAmount);
		}
		else //shield took all, armor doesn't need to take any
		{
			PostShield_MitigationAmount = 0;
			PostShield_DamageAmount = 0;
			DamageAbsorbedByShield = DamageAmountBeforeArmor;  //The shield took a partial hit from the damage
			PostShield_ShredAmount = 0;
		}
	}

	AddShreddedValue(PostShield_ShredAmount);  // Add the new PostShield_ShredAmount

	DmgResult.Shred = PostShield_ShredAmount;
	DmgResult.DamageAmount = PostShield_DamageAmount;
	DmgResult.MitigationAmount = PostShield_MitigationAmount;
	DmgResult.ShieldHP = DamageAbsorbedByShield;
	DmgResult.SourceEffect = EffectData;
	DmgResult.Context = NewGameState.GetContext( );
	DamageResults.AddItem( DmgResult );

	if (DmgResult.MitigationAmount > 0)
		LogMsg = class'XLocalizedData'.default.MitigatedDamageLogMsg;
	else
		LogMsg = class'XLocalizedData'.default.UnmitigatedDamageLogMsg;

	LogMsg = repl( LogMsg, "#Unit", GetName( eNameType_RankFull ) );
	LogMsg = repl( LogMsg, "#Damage", DmgResult.DamageAmount );
	LogMsg = repl( LogMsg, "#Mitigated", DmgResult.MitigationAmount );
	`COMBATLOG(LogMsg);

	//Damage removes ReserveActionPoints(Overwatch)
	if ((DamageAmount + MitigationAmount) > 0)
	{
		ReserveActionPoints.Length = 0;
	}

	SetUnitFloatValue( 'LastEffectDamage', DmgResult.DamageAmount, eCleanup_BeginTactical );
	ThisObj = self;
	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent( 'UnitTakeEffectDamage', ThisObj, ThisObj, NewGameState );

	// Apply damage to the shielding
	if (DamageAbsorbedByShield > 0)
	{
		ModifyCurrentStat( eStat_ShieldHP, -DamageAbsorbedByShield );

		if( GetCurrentStat(eStat_ShieldHP) <= 0 )
		{
			// The shields have been expended, remove the shields
			EventManager.TriggerEvent('ShieldsExpended', ThisObj, ThisObj, NewGameState);
		}
	}

	OverkillDamage = (GetCurrentStat( eStat_HP )) - DmgResult.DamageAmount;
	if (OverkillDamage <= 0)
	{
		bKilledByExplosion = bExplosiveDamage;
		KilledByDamageTypes = DamageTypes;
		History = `XCOMHISTORY;

		if (bForceBleedOut || (bAllowBleedout && ShouldBleedOut( -OverkillDamage )))
		{
			foreach AffectedByEffects(EffectRef)
			{
				EffectState = XComGameState_Effect(NewGameState.GetGameStateForObjectID(EffectRef.ObjectID));
				if (EffectState == none)
					EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				if (EffectState == none || EffectState.bRemoved)
					continue;
				PersistentEffect = EffectState.GetX2Effect();
				if (PersistentEffect == none)
					continue;
				if (PersistentEffect.PreBleedoutCheck(NewGameState, self, EffectState))
				{
					`COMBATLOG("Effect" @ PersistentEffect.FriendlyName @ "is handling the PreBleedoutCheck - unit should bleed out but the effect is handling it");
					return;
				}
			}
			if (ApplyBleedingOut( NewGameState ))
			{
				return;
			}
			else
			{
				`RedScreenOnce("Unit" @ GetName(eNameType_Full) @ "should have bled out but ApplyBleedingOut failed. Killing it instead. -jbouscher @gameplay");
			}
		}
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(NewGameState.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState == none)
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState == none || EffectState.bRemoved)
				continue;
			PersistentEffect = EffectState.GetX2Effect();
			if (PersistentEffect == none)
				continue;
			if (PersistentEffect.PreDeathCheck(NewGameState, self, EffectState))
			{
				`COMBATLOG("Effect" @ PersistentEffect.FriendlyName @ "is handling the PreDeathCheck - unit should be dead but the effect is handling it");
				return;
			}
		}

		SetCurrentStat( eStat_HP, 0 );
		OnUnitDied( NewGameState, CauseOfDeath, DamageSource, , EffectData );
		return;
	}

	// Apply damage to the HP
	ModifyCurrentStat( eStat_HP, -DmgResult.DamageAmount );

	if (CanEarnXp( ))
	{
		if (GetCurrentStat( eStat_HP ) < (GetMaxStat( eStat_HP ) * 0.5f))
		{
			`TRIGGERXP('XpLowHealth', GetReference( ), GetReference( ), NewGameState);
		}
	}
	if (GetCurrentStat( eStat_HP ) < LowestHP)
		LowestHP = GetCurrentStat( eStat_HP );

	iAIDataID = GetAIPlayerDataID( true );
	if (iAIDataID > 0)
	{
		// Update AIPlayerData stats.
		kAIData = XComGameState_AIPlayerData( NewGameState.CreateStateObject( class'XComGameState_AIPlayerData', iAIDataID ) );
		kAIData.OnTakeDamage( ObjectID, ControllingPlayerIsAI( ) );
		NewGameState.AddStateObject( kAIData );
	}
}

function OnUnitBledOut(XComGameState NewGameState, Object CauseOfDeath, const out StateObjectReference SourceStateObjectRef, optional const out EffectAppliedData EffectData)
{
	OnUnitDied(NewGameState, CauseOfDeath, SourceStateObjectRef,, EffectData);
}

protected function OnUnitDied(XComGameState NewGameState, Object CauseOfDeath, const out StateObjectReference SourceStateObjectRef, bool ApplyToOwnerAndComponents = true, optional const out EffectAppliedData EffectData)
{
	local XComGameState_Unit Killer, Owner, Comp, KillAssistant, Iter, NewUnitState;
	local XComGameStateHistory History;
	local int iComponentID;
	local bool bAllDead;
	local int iAIDataID;
	local XComGameState_AIPlayerData kAIData;
	local X2EventManager EventManager;
	local string LogMsg;
	local XComGameState_Ability AbilityStateObject;
	local UnitValue RankUpValue;
	local XComGameState_BattleData BattleData;
	local XComGameState_HeadquartersXCom XComHQ;
	local Name CharacterGroupName, CharacterDeathEvent;
	//local XComGameState_BaseObject SourceOfDeath;

	LogMsg = class'XLocalizedData'.default.UnitDiedLogMsg;
	LogMsg = repl(LogMsg, "#Unit", GetName(eNameType_RankFull));
	`COMBATLOG(LogMsg);

	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	m_strKIAOp = BattleData.m_strOpName;
	m_KIADate = BattleData.LocalTime;

	NewGameState.GetContext().PostBuildVisualizationFn.AddItem(UnitDeathVisualizationWorldMessage);
	NewGameState.GetContext().SetVisualizerUpdatesState(true); //This unit will be rag-dolling, which will move it, so notify the history system

	//TODO: BRW - figure out proper way to do this
	//`assert(DamageResults.Length > 0);
	//SourceOfDeath = XComGameState_BaseObject(History.GetGameStateForObjectID(DamageResults[DamageResults.Length - 1].SourceEffect.SourceStateObjectRef.ObjectID));
	//m_strCauseOfDeath = SourceOfDeath.GetMyTemplateName();
	
	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('UnitDied', self, self, NewGameState);
	
	`XACHIEVEMENT_TRACKER.OnUnitDied(self, NewGameState, CauseOfDeath, SourceStateObjectRef, ApplyToOwnerAndComponents, EffectData, bKilledByExplosion);

	// Golden Path special triggers
	CharacterDeathEvent = GetMyTemplate().DeathEvent;
	if (CharacterDeathEvent != '')
	{
		CharacterGroupName = GetMyTemplate().CharacterGroupName;
		if (CharacterGroupName != 'Cyberus' || AreAllCodexInLineageDead(NewGameState))
		{
			EventManager.TriggerEvent(CharacterDeathEvent, self, self, NewGameState);
		}
	}

	Killer = XComGameState_Unit( History.GetGameStateForObjectID( SourceStateObjectRef.ObjectID ) );
	if( GetTeam() == eTeam_Alien )
	{
		if( SourceStateObjectRef.ObjectID != 0 )
		{	
			if (Killer != none && Killer.CanEarnXp())
			{
				Killer = XComGameState_Unit(NewGameState.CreateStateObject(Killer.Class, Killer.ObjectID));
				Killer.KilledUnits.AddItem(GetReference());

				// If the Wet Work GTS bonus is active, increment the Wet Work kill counter
				XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
				if (XComHQ != none && XComHQ.SoldierUnlockTemplates.Find('WetWorkUnlock') != INDEX_NONE)
				{
					Killer.WetWorkKills++;
				}

				if (Killer.bIsShaken)
				{
					Killer.UnitsKilledWhileShaken++; //confidence boost towards recovering from being Shaken
				}

				CheckForFlankingEnemyKill(NewGameState, Killer);

				//  Check for and trigger event to display rank up message if applicable
				if (Killer.IsSoldier() && Killer.CanRankUpSoldier())
				{
					Killer.GetUnitValue('RankUpMessage', RankUpValue);
					if (RankUpValue.fValue == 0)
					{
						EventManager.TriggerEvent('RankUpMessage', Killer, Killer, NewGameState);
						Killer.SetUnitFloatValue('RankUpMessage', 1, eCleanup_BeginTactical);
					}
				}

				NewGameState.AddStateObject(Killer);

				//  All team mates that are alive and able to earn XP will be credited with a kill assist (regardless of their actions)
				foreach History.IterateByClassType(class'XComGameState_Unit', Iter)
				{
					if (Iter != Killer && Iter.ControllingPlayer.ObjectID == Killer.ControllingPlayer.ObjectID && Iter.CanEarnXp() && Iter.IsAlive())
					{
						KillAssistant = XComGameState_Unit(NewGameState.CreateStateObject(Iter.Class, Iter.ObjectID));
						KillAssistant.KillAssists.AddItem(GetReference());

						//  jbouscher: current desire is to only display the rank up message based on a full kill, commenting this out for now.
						//  Check for and trigger event to display rank up message if applicable
						//if (KillAssistant.IsSoldier() && KillAssistant.CanRankUpSoldier())
						//{
						//	RankUpValue.fValue = 0;
						//	KillAssistant.GetUnitValue('RankUpMessage', RankUpValue);
						//	if (RankUpValue.fValue == 0)
						//	{
						//		EventManager.TriggerEvent('RankUpMessage', KillAssistant, KillAssistant, NewGameState);
						//		KillAssistant.SetUnitFloatValue('RankUpMessage', 1, eCleanup_BeginTactical);
						//	}
						//}		

						NewGameState.AddStateObject(KillAssistant);
					}
				}

				`TRIGGERXP('XpKillShot', SourceStateObjectRef, GetReference(), NewGameState);
			}

			if (Killer != none && Killer.GetMyTemplate().bIsTurret && Killer.GetTeam() == eTeam_XCom && Killer.IsMindControlled())
			{
				`ONLINEEVENTMGR.UnlockAchievement(AT_KillWithHackedTurret);
			}
		}

		// when enemies are killed with pending loot, start the loot expiration timer
		if( IsLootable(NewGameState) )
		{
			if( HasAvailableLoot() )
			{
				MakeAvailableLoot(NewGameState);
			}
			else if( PendingLoot.LootToBeCreated.Length > 0 )
			{
				NewGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeLootDestroyedByExplosives);
			}

			RollForAutoLoot(NewGameState);
		}
		else
		{
			NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
			NewGameState.AddStateObject(NewUnitState);
			NewUnitState.PendingLoot.LootToBeCreated.Length = 0;
		}
	}
	else if( GetTeam() == eTeam_XCom )
	{
		if( IsLootable(NewGameState) )
		{
			DropCarriedLoot(NewGameState);
		}
	}

	m_strCauseOfDeath = class'UIBarMemorial_Details'.static.FormatCauseOfDeath( self, Killer, NewGameState.GetContext() );

	if (ApplyToOwnerAndComponents)
	{
		// If is component, attempt to apply to owner.
		if ( m_bSubsystem && OwningObjectId > 0)
		{
			// Check all other components of our owner object.
			Owner = XComGameState_Unit(History.GetGameStateForObjectID(OwningObjectId));
			bAllDead = true;
			foreach Owner.ComponentObjectIds(iComponentID)
			{
				if (iComponentID == ObjectID) // Skip this one.
					continue;
				Comp = XComGameState_Unit(History.GetGameStateForObjectID(iComponentID));
				if (Comp != None && Comp.IsAlive())
				{
					bAllDead = false;
					break;
				}
			}
			if (bAllDead && Owner.IsAlive())
			{
				Owner = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OwningObjectId));
				Owner.SetCurrentStat(eStat_HP, 0);
				Owner.OnUnitDied(NewGameState, CauseOfDeath, SourceStateObjectRef, false, EffectData);
				NewGameState.AddStateObject(Owner);
			}
		}
		else
		{
			// If we are the owner, and we're dead, set all the components as dead.
			foreach ComponentObjectIds(iComponentID)
			{
				Comp = XComGameState_Unit(History.GetGameStateForObjectID(iComponentID));
				if (Comp != None && Comp.IsAlive())
				{
					Comp = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', iComponentID));
					Comp.SetCurrentStat(eStat_HP, 0);
					Comp.OnUnitDied(NewGameState, CauseOfDeath, SourceStateObjectRef, false, EffectData);
					NewGameState.AddStateObject(Comp);
				}
			}
		}
	}

	iAIDataID = GetAIPlayerDataID();
	if (iAIDataID > 0 && !m_bSubsystem)
	{
		// Update AIPlayerData stats.
		kAIData = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', iAIDataID));
		kAIData.OnUnitDeath(ObjectID, ControllingPlayerIsAI());
		NewGameState.AddStateObject(kAIData);
	}
	LowestHP = 0;

	// finally send a kill mail: soldier/alien and alien/soldier
	Killer = none;
	if( SourceStateObjectRef.ObjectID != 0 )
	{
		Killer = XComGameState_Unit(History.GetGameStateForObjectID(SourceStateObjectRef.ObjectID));
	}
	EventManager.TriggerEvent('KillMail', self, Killer, NewGameState);

	// send weapon ability that did the killing
	AbilityStateObject = XComGameState_Ability(NewGameState.GetGameStateForObjectID(EffectData.AbilityStateObjectRef.ObjectID));
	if (AbilityStateObject == none)
	{
		AbilityStateObject = XComGameState_Ability(History.GetGameStateForObjectID(EffectData.AbilityStateObjectRef.ObjectID));
	}

	if (AbilityStateObject != none)
	{
		EventManager.TriggerEvent('WeaponKillType', AbilityStateObject, Killer);
	}

}

function UnitDeathVisualizationWorldMessage(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComPresentationLayer Presentation;
	local XComGameStateHistory History;
	local VisualizationTrack BuildTrack;
	local X2Action_PlayWorldMessage MessageAction;
	local X2Action_UpdateFOW FOWUpdateAction;
	local XGParamTag kTag;

	Presentation = `PRES;
	History = `XCOMHISTORY;

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = History.GetVisualizer(ObjectID);

	MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = GetFullName();
	MessageAction.AddWorldMessage(`XEXPAND.ExpandString(Presentation.m_strUnitDied));

	FOWUpdateAction = X2Action_UpdateFOW(class'X2Action_UpdateFOW'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	FOWUPdateAction.Remove = true;

	OutVisualizationTracks.AddItem(BuildTrack);
}


function CheckForFlankingEnemyKill(XComGameState NewGameState, XComGameState_Unit Killer)
{
	local array<StateObjectReference> OutFlankingEnemies;
	local int Index, KillerID;
	local XComGameState_Unit FlankedSoldier;

	if (!`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		class'X2TacticalVisibilityHelpers'.static.GetEnemiesFlankedBySource(ObjectID, OutFlankingEnemies);
		KillerID = Killer.ObjectID;
		for (Index = OutFlankingEnemies.Length - 1; Index > -1; --Index)
		{
			FlankedSoldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OutFlankingEnemies[Index].ObjectID));
			if ((OutFlankingEnemies[Index].ObjectID != KillerID) && (FlankedSoldier.CanEarnSoldierRelationshipPoints(Killer))) // pmiller - so that you can't have a relationship with yourself
			{
				FlankedSoldier = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', OutFlankingEnemies[Index].ObjectID));
				FlankedSoldier.AddToSquadmateScore(Killer.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_KillFlankingEnemy);
				NewGameState.AddStateObject(FlankedSoldier);
				Killer.AddToSquadmateScore(OutFlankingEnemies[Index].ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_KillFlankingEnemy);
			}
		}
	}
}

native function SetBaseMaxStat( ECharStatType Stat, float Amount, optional ECharStatModApplicationRule ApplicationRule = ECSMAR_Additive );
native function float GetBaseStat( ECharStatType Stat ) const;
native function float GetMaxStat( ECharStatType Stat );
native function float GetCurrentStat( ECharStatType Stat ) const;
native function ModifyCurrentStat(ECharStatType Stat, float Delta);
native function SetCurrentStat( ECharStatType Stat, float NewValue );
native function GetStatModifiers(ECharStatType Stat, out array<XComGameState_Effect> Mods, out array<float> ModValues);

native function ApplyEffectToStats( const ref XComGameState_Effect SourceEffect, optional XComGameState NewGameState );
native function UnApplyEffectFromStats( const ref XComGameState_Effect SourceEffect, optional XComGameState NewGameState );

function GiveStandardActionPoints()
{
	local int i, PointsToGive;

	//  Clear any leftover action points or reserved action points
	ActionPoints.Length = 0;
	ReserveActionPoints.Length = 0;
	SkippedActionPoints.Length = 0;
	//  Retrieve standard action points per turn
	PointsToGive = class'X2CharacterTemplateManager'.default.StandardActionsPerTurn;
	//  Subtract any stunned action points
	StunnedThisTurn = 0;
	if( StunnedActionPoints > 0 )
	{
		if( StunnedActionPoints >= PointsToGive )
		{
			StunnedActionPoints -= PointsToGive;
			StunnedThisTurn = PointsToGive;
			PointsToGive = 0;
		}
		else
		{
			PointsToGive -= StunnedActionPoints;
			StunnedThisTurn = StunnedActionPoints;
			StunnedActionPoints = 0;
		}
	}
	//  Issue non-stunned standard action points
	for( i = 0; i < PointsToGive; ++i )
	{
		ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
	}
}

function SetupActionsForBeginTurn()
{
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent EffectTemplate;
	local UnitValue MovesThisTurn;

	GiveStandardActionPoints();

	if( ActionPoints.Length > 0 )
	{
		History = `XCOMHISTORY;
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectTemplate = EffectState.GetX2Effect();
			EffectTemplate.ModifyTurnStartActionPoints(self, ActionPoints, EffectState);
		}
	}

	Untouchable = 0;                    //  untouchable only lasts until the start of your next turn, so always clear it out
	bGotFreeFireAction = false;                                                      //Reset FreeFireAction flag
	GetUnitValue('MovesThisTurn', MovesThisTurn);
	SetUnitFloatValue('MovesLastTurn', MovesThisTurn.fValue, eCleanup_BeginTactical); 
	CleanupUnitValues(eCleanup_BeginTurn);
	TurnStartLocation = TileLocation;
}

function int NumAllActionPoints()
{
	return ActionPoints.Length;
}

function int NumAllReserveActionPoints()
{
	return ReserveActionPoints.Length;
}

function bool HasValidMoveAction()
{
	local GameRulesCache_Unit UnitCache;
	local AvailableAction Action;
	local XComGameStateHistory History;
	local XComGameState_Ability Ability;

	//  retrieve cached action info - check if movement is valid first.
	`TACTICALRULES.GetGameRulesCache_Unit(GetReference(), UnitCache);
	if( UnitCache.bAnyActionsAvailable )
	{
		History = `XCOMHISTORY;
		foreach UnitCache.AvailableActions(Action)
		{
			Ability = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
			if( Ability.IsAbilityPathing() )
			{
				return (Action.AvailableCode == 'AA_Success');
			}
		}
	}
	return false;
}


event int NumActionPointsForMoving()
{
	local array<name> MoveTypes;
	local int i, Count;

	MoveTypes = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().GetStandardMoveAbilityActionTypes();
	for (i = 0; i < MoveTypes.Length; ++i)
	{
		Count += NumActionPoints(MoveTypes[i]);
	}
	return Count;
}

function int NumActionPoints(optional name Type=class'X2CharacterTemplateManager'.default.StandardActionPoint)
{
	return InternalNumActionPoints(ActionPoints, Type);
}

function int NumReserveActionPoints(optional name Type=class'X2CharacterTemplateManager'.default.StandardActionPoint)
{
	return InternalNumActionPoints(ReserveActionPoints, Type);
}

protected function int InternalNumActionPoints(const out array<name> Actions, name Type)
{
	local int i, Count;

	for (i = 0; i < Actions.Length; ++i)
	{
		if (Actions[i] == Type)
			Count++;
	}
	return Count;
}

function string GetKIAOp()
{
	return m_strKIAOp;
}

function string GetCauseOfDeath()
{
	return m_strCauseOfDeath;
}

function TDateTime GetKIADate()
{
	return m_KIADate;
}

function int GetNumKills()
{
	return KilledUnits.Length;
}

function int GetNumKillsFromAssists()
{
	local X2SoldierClassTemplate ClassTemplate;
	local int Assists;

	ClassTemplate = GetSoldierClassTemplate();
	if (ClassTemplate != none)
	{
		if (KillAssists.Length > 0 && ClassTemplate.KillAssistsPerKill > 0)
			Assists = KillAssists.Length / ClassTemplate.KillAssistsPerKill;
		if (PsiCredits > 0 && ClassTemplate.PsiCreditsPerKill > 0)
			Assists += PsiCredits / ClassTemplate.PsiCreditsPerKill;
	}
	
	return Assists;
}

simulated function int GetNumMissions()
{
	return iNumMissions;
}

function SetHasPsiGift()
{
	bHasPsiGift = true;
}

function name GetVoice()
{
	return kAppearance.nmVoice;
}

function SetVoice(name Voice)
{
	kAppearance.nmVoice = Voice;
}

function bool HasAvailablePerksToAssign()
{
	local int i;
	local X2SoldierClassTemplate ClassTemplate;
	local array<SoldierClassAbilityType> AbilityTree;

	if(m_SoldierRank == 0 || m_SoldierClassTemplateName == '' || m_SoldierClassTemplateName == 'PsiOperative')
		return false;

	ClassTemplate = GetSoldierClassTemplate();
	AbilityTree = ClassTemplate.GetAbilityTree(m_SoldierRank - 1);
	for(i = 0; i < AbilityTree.Length; ++i)
	{
		if(HasSoldierAbility(AbilityTree[i].AbilityName))
			return false;
	}

	return true;
}

function EnableGlobalAbilityForUnit(name AbilityName)
{
	local X2AbilityTemplateManager AbilityMan;
	local X2AbilityTemplate Template;
	local name AllowedName;

	AbilityMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Template = AbilityMan.FindAbilityTemplate(AbilityName);
	if (Template != none)
	{
		AllowedName = name("AllowedAbility_" $ string(AbilityName));
		SetUnitFloatValue(AllowedName, 1, eCleanup_BeginTactical);
	}
}

//=============================================================================================

function SetCharacterName(string First, string Last, string Nick)
{
	strFirstName = First;
	strLastName = Last;
	strNickName = Nick;
}

simulated function XComUnitPawn GetPawnArchetype( string strArchetype="", optional const XComGameState_Unit ReanimatedFromUnit = None )
{
	local Object kPawn;

	if(strArchetype == "")
	{
		strArchetype = GetMyTemplate().GetPawnArchetypeString(self, ReanimatedFromUnit);
	}

	kPawn = `CONTENT.RequestGameArchetype(strArchetype);
	if (kPawn != none && kPawn.IsA('XComUnitPawn'))
		return XComUnitPawn(kPawn);
	return none;
}

function OnAsyncLoadRequestComplete(XComGameState_Unit_AsyncLoadRequest alr)
{
    if( true ) //! bIsInCreate ) 
    {
        // now that we're ensured that the archetype has been loaded we can go ahead and create the pawn
        //UnitPawn = CreatePawn(alr.PawnOwner, alr.UseLocation, alr.UseRotation, alr.bForceMenuState);

        alr.PawnCreatedCallback(self);

        self.m_asynchronousLoadRequests.RemoveItem(alr);
    }
    else
	{
        alr.bIsComplete = true;
	}

}

simulated function CreatePawnAsync( Actor PawnOwner, vector UseLocation, rotator UseRotation, delegate<OnUnitPawnCreated> Callback )
{
    local XComGameState_Unit_AsyncLoadRequest alr;
    local string strArchetype;

	strArchetype = GetMyTemplate().GetPawnArchetypeString(self);

    alr = new class'XComGameState_Unit_AsyncLoadRequest';

    alr.ArchetypeName = strArchetype;
    alr.PawnOwner = PawnOwner;
    alr.UseLocation = UseLocation;
    alr.UseRotation = UseRotation;
    alr.bForceMenuState = false;

    alr.PawnCreatedCallback = Callback;
    alr.OnAsyncLoadComplete_UnitCallback = OnAsyncLoadRequestComplete;

    m_asynchronousLoadRequests.AddItem(alr);


    `CONTENT.RequestGameArchetype(strArchetype, alr, alr.OnObjectLoaded, true);
}

/*
function HandleAsyncRequests()
{
	local XComUnitPawn SpawnedPawn;
    local XComGameState_Unit_AsyncLoadRequest alr;

    bHandlingAsyncRequests = true;

    // this call can force the already queued up request to flush, but we can't call it again from inside the completion delegate
    //  handle that mess here
    if(m_asynchronousLoadRequests.Length != 0 )
    {
        while( m_asynchronousLoadRequests.Length != 0 && m_asynchronousLoadRequests[0].bIsComplete)
        {       
            alr = m_asynchronousLoadRequests[0];
            SpawnedPawn = CreatePawn(alr.PawnOwner, alr.UseLocation, alr.UseRotation);
            alr.PawnCreatedCallback(SpawnedPawn);
            m_asynchronousLoadRequests.RemoveItem(alr);
        }
    }

    bHandlingAsyncRequests = false;

}
*/

simulated function XComUnitPawn CreatePawn( Actor PawnOwner, vector UseLocation, rotator UseRotation, optional bool bForceMenuState = false )
{
	local XComUnitPawn UnitPawnArchetype;
	local XComUnitPawn SpawnedPawn;
	local XComGameStateHistory History;
	local XComHumanPawn HumanPawn;
	local X2CharacterTemplate CharacterTemplate;
	local bool bInHistory;

    bIsInCreate = true;

	History = `XCOMHISTORY;
	bInHistory = !bForceMenuState && History.GetGameStateForObjectID(ObjectID) != none;

	UnitPawnArchetype = GetPawnArchetype();

	SpawnedPawn = class'Engine'.static.GetCurrentWorldInfo().Spawn( UnitPawnArchetype.Class, PawnOwner, , UseLocation, UseRotation, UnitPawnArchetype, true, eTeam_All );
	SpawnedPawn.SetPhysics(PHYS_None);
	SpawnedPawn.SetVisible(true);
	SpawnedPawn.ObjectID = ObjectID;

	CharacterTemplate = GetMyTemplate();
	HumanPawn = XComHumanPawn(SpawnedPawn);
	if(HumanPawn != none && CharacterTemplate.bAppearanceDefinesPawn)
	{		
		HumanPawn.SetAppearance(kAppearance);
		
		if (CharacterTemplate.bForceAppearance)
		{
			HumanPawn.UpdateAppearance(CharacterTemplate.ForceAppearance);
		}
	}

	if(!bInHistory)
	{
		SpawnedPawn.SetMenuUnitState(self);
	}

    bIsInCreate = false;

	//Trigger to allow mods access to the newly created pawn
	`XEVENTMGR.TriggerEvent('OnCreateCinematicPawn', SpawnedPawn, self);

	return SpawnedPawn;
}

simulated function bool HasBackpack()
{
	return true; // all units now have a backpack
	//return GetMaxStat(eStat_BackpackSize) > 0 && GetItemInSlot(eInvSlot_Mission) == none && !HasHeavyWeapon();
}

simulated native function XComGameState_Item GetItemGameState(StateObjectReference ItemRef, optional XComGameState CheckGameState, optional bool bExcludeHistory = false);

simulated native function XComGameState_Item GetItemInSlot(EInventorySlot Slot, optional XComGameState CheckGameState, optional bool bExcludeHistory = false);

simulated function array<XComGameState_Item> GetAllItemsInSlot(EInventorySlot Slot, optional XComGameState CheckGameState, optional bool bExcludeHistory=false, optional bool bHasSize = false)
{
	local int i;
	local XComGameState_Item kItem;
	local array<XComGameState_Item> Items;
	
	`assert(Slot == eInvSlot_Backpack || Slot == eInvSlot_Utility || Slot == eInvSlot_CombatSim);     //  these are the only multi-item slots
	
	for (i = 0; i < InventoryItems.Length; ++i)
	{
		kItem = GetItemGameState(InventoryItems[i], CheckGameState, bExcludeHistory);
		if (kItem != none && kItem.InventorySlot == Slot && (!bHasSize || kItem.GetMyTemplate().iItemSize > 0))
			Items.AddItem(kItem);
	}
	return Items;
}


simulated function GetAttachedUnits(out array<XComGameState_Unit> AttachedUnits, optional XComGameState GameState)
{
	local XComGameState_Item ItemIterator;
	local XComGameState_Unit AttachedUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Item', ItemIterator)
	{
		if (ObjectID == ItemIterator.AttachedUnitRef.ObjectID && ItemIterator.CosmeticUnitRef.ObjectID > 0)
		{
			AttachedUnit = XComGameState_Unit(History.GetGameStateForObjectID(ItemIterator.CosmeticUnitRef.ObjectID, , (GameState != none) ? GameState.HistoryIndex : - 1 ));
			AttachedUnits.AddItem(AttachedUnit);
		}
	}
}

simulated function XComGameState_Item GetBestMedikit(optional XComGameState CheckGameState, optional bool bExcludeHistory)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item, BestMedikit;

	Items = GetAllItemsInSlot(eInvSlot_Utility, CheckGameState, bExcludeHistory);
	foreach Items(Item)
	{
		if (Item.GetWeaponCategory() == class'X2Item_DefaultUtilityItems'.default.MedikitCat)
		{
			if (BestMedikit == none || BestMedikit.Ammo < Item.Ammo)
			{
				BestMedikit = Item;
			}
		}
	}
	return BestMedikit;
}

function name DefaultGetRandomUberTemplate_WarnAboutFilter(string PartType, X2SimpleBodyPartFilter Filter)
{
	`log("WARNING:"@ `ShowVar(self) $": Unable to find a GetRandomUberTemplate for '"$PartType$"' Filter:"@Filter.DebugString_X2SimpleBodyPartFilter(), , 'XCom_Templates');
	return '';
}

function bool AddItemToInventory(XComGameState_Item Item, EInventorySlot Slot, XComGameState NewGameState, optional bool bAddToFront)
{
	local X2BodyPartTemplate ArmorPartTemplate, BodyPartTemplate;
	local X2BodyPartTemplateManager BodyPartMgr;
	local X2SimpleBodyPartFilter Filter;
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = Item.GetMyTemplate();
	if (CanAddItemToInventory(ItemTemplate, Slot, NewGameState, Item.Quantity))
	{
		if( ItemTemplate.OnEquippedFn != None )
		{
			ItemTemplate.OnEquippedFn(Item, self, NewGameState);
		}

		Item.InventorySlot = Slot;
		Item.OwnerStateObject = GetReference();

		if (Slot == eInvSlot_Backpack)
		{
			AddItemToBackpack(Item, NewGameState);
		}
		else
		{			
			if(bAddToFront)
				InventoryItems.InsertItem(0, Item.GetReference());
			else
				InventoryItems.AddItem(Item.GetReference());
		}

		if (Slot == eInvSlot_Mission)
		{
			//  @TODO gameplay: in tactical, if there are any items in the backpack, they must be dropped on a nearby tile for pickup by another soldier
			//  this would only happen if a soldier picked up a mission item from a dead soldier.
			//  in HQ, a soldier would never have items sitting around in the backpack
		}
		else if (Slot == eInvSlot_Armor)
		{
			if(!IsMPCharacter() && X2ArmorTemplate(Item.GetMyTemplate()).bAddsUtilitySlot)
			{
				SetBaseMaxStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems] + 1.0f);
				SetCurrentStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems] + 1.0f);
			}

			//  must ensure appearance matches 
			if (GetMyTemplate().bAppearanceDefinesPawn)
			{
				BodyPartMgr = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
				ArmorPartTemplate = BodyPartMgr.FindUberTemplate("Torso", kAppearance.nmTorso);

				//Here to handle cases where the character has changed gender and armor at the same time
				if(EGender(kAppearance.iGender) != ArmorPartTemplate.Gender)
				{
					ArmorPartTemplate = none;
				}

				if (IsSoldier() && (ArmorPartTemplate == none || (ArmorPartTemplate.ArmorTemplate != '' && ArmorPartTemplate.ArmorTemplate != Item.GetMyTemplateName())))
				{
					//  setup filter based on new armor
					Filter = `XCOMGAME.SharedBodyPartFilter;
					Filter.Set(EGender(kAppearance.iGender), ECharacterRace(kAppearance.iRace), '');
					Filter.SetTorsoSelection('ForceArmorMatch', Item.GetMyTemplateName()); //ForceArmorMatch will make the system choose a torso based on the armor type

					//  need to pick a new torso, which will necessitate updating arms and legs
					ArmorPartTemplate = BodyPartMgr.GetRandomUberTemplate("Torso", Filter, Filter.FilterTorso);
					kAppearance.nmTorso = (ArmorPartTemplate != none) ? ArmorPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Torso", Filter);
					//  update filter to include specific torso data to match
					Filter.Set(EGender(kAppearance.iGender), ECharacterRace(kAppearance.iRace), kAppearance.nmTorso);

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Arms", Filter, Filter.FilterByTorsoAndArmorMatch);
					if(BodyPartTemplate == none)
					{
						kAppearance.nmArms = '';

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("LeftArm", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmLeftArm = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("LeftArm", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("RightArm", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmRightArm = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("RightArm", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("LeftArmDeco", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmLeftArmDeco = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("LeftArmDeco", Filter);

						BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("RightArmDeco", Filter, Filter.FilterByTorsoAndArmorMatch);
						kAppearance.nmRightArmDeco = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("RightArmDeco", Filter);
					}
					else
					{
						kAppearance.nmArms = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Arms", Filter);
						kAppearance.nmLeftArm = '';
						kAppearance.nmRightArm = '';
						kAppearance.nmLeftArmDeco = '';
						kAppearance.nmRightArmDeco = '';
					}

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Legs", Filter, Filter.FilterByTorsoAndArmorMatch);
					kAppearance.nmLegs = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter("Legs", Filter);

					BodyPartTemplate = BodyPartMgr.GetRandomUberTemplate("Helmets", Filter, Filter.FilterByTorsoAndArmorMatch);
					kAppearance.nmHelmet = (BodyPartTemplate != none) ? BodyPartTemplate.DataName : kAppearance.nmHelmet;

					if (ArmorPartTemplate != none && HasStoredAppearance(kAppearance.iGender, ArmorPartTemplate.ArmorTemplate))
					{
						GetStoredAppearance(kAppearance, kAppearance.iGender, ArmorPartTemplate.ArmorTemplate);
					}
				}
			}
		}
		else if(Slot == eInvSlot_CombatSim)
		{
			ApplyCombatSimStats(Item);
		}
		return true;
	}
	return false;
}

simulated function bool CanAddItemToInventory(const X2ItemTemplate ItemTemplate, const EInventorySlot Slot, optional XComGameState CheckGameState, optional int Quantity=1)
{
	local int i, iUtility;
	local XComGameState_Item kItem;
	local X2WeaponTemplate WeaponTemplate;
	local X2GrenadeTemplate GrenadeTemplate;
	local X2ArmorTemplate ArmorTemplate;

	if( bIgnoreItemEquipRestrictions )
		return true;

	if (ItemTemplate != none)
	{
		WeaponTemplate = X2WeaponTemplate(ItemTemplate);
		ArmorTemplate = X2ArmorTemplate(ItemTemplate);
		GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);

		if(class'X2TacticalGameRulesetDataStructures'.static.InventorySlotIsEquipped(Slot))
		{
			if (IsSoldier() && WeaponTemplate != none)
			{
				if (!GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate))
					return false;
			}

			if (IsSoldier() && ArmorTemplate != none)
			{
				if (!GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate))
					return false;
			}

			if (!IsMPCharacter() && !RespectsUniqueRule(ItemTemplate, Slot, CheckGameState))
				return false;
		}

		switch(Slot)
		{
		case eInvSlot_Loot:
		case eInvSlot_Backpack: 
			return true;
		case eInvSlot_Mission:
			return GetItemInSlot(eInvSlot_Mission) == none;
		case eInvSlot_Utility:
			iUtility = 0;
			for (i = 0; i < InventoryItems.Length; ++i)
			{
				kItem = GetItemGameState(InventoryItems[i], CheckGameState);
				if (kItem != none && kItem.InventorySlot == eInvSlot_Utility)
					iUtility += kItem.GetItemSize();
			}
			if(GetMPCharacterTemplate() != none)
			{
				return iUtility + ItemTemplate.iItemSize <= GetMPCharacterTemplate().NumUtilitySlots;
			}
			return (iUtility + ItemTemplate.iItemSize <= GetCurrentStat(eStat_UtilityItems));
		case eInvSlot_GrenadePocket:
			if (!HasGrenadePocket())
				return false;
			if (GetItemInSlot(eInvSlot_GrenadePocket, CheckGameState) != none)
				return false;
			return (GrenadeTemplate != none);
		case eInvSlot_AmmoPocket:
			if (!HasAmmoPocket())
				return false;
			if (GetItemInSlot(eInvSlot_AmmoPocket, CheckGameState) != none)
				return false;
			return ItemTemplate.ItemCat == 'ammo';
		case eInvSlot_HeavyWeapon:
			if (!HasHeavyWeapon(CheckGameState))
				return false;
			if (WeaponTemplate ==  none)
				return false;
			return (GetItemInSlot(eInvSlot_HeavyWeapon, CheckGameState) == none);
		case eInvSlot_CombatSim:
			return (ItemTemplate.ItemCat == 'combatsim' && GetCurrentStat(eStat_CombatSims) > 0);
		default:
			return (GetItemInSlot(Slot, CheckGameState) == none);
		}
	}
	return false;
}

public function bool RespectsUniqueRule(const X2ItemTemplate ItemTemplate, const EInventorySlot Slot, optional XComGameState CheckGameState, optional int SkipObjectID)
{
	local int i;
	local bool bUniqueCat;
	local bool bUniqueWeaponCat;
	local XComGameState_Item kItem;
	local X2ItemTemplate UniqueItemTemplate;
	local X2WeaponTemplate WeaponTemplate, UniqueWeaponTemplate;
	local X2ItemTemplatemanager ItemTemplateManager;

	if (!class'X2TacticalGameRulesetDataStructures'.static.InventorySlotBypassesUniqueRule(Slot))
	{
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
		bUniqueCat = ItemTemplateManager.ItemCategoryIsUniqueEquip(ItemTemplate.ItemCat);

		WeaponTemplate = X2WeaponTemplate(ItemTemplate);
		if (!bUniqueCat && WeaponTemplate != none)
			bUniqueWeaponCat = ItemTemplateManager.ItemCategoryIsUniqueEquip(WeaponTemplate.WeaponCat);
	
		if (bUniqueCat || bUniqueWeaponCat)
		{
			for (i = 0; i < InventoryItems.Length; ++i)
			{
				if(InventoryItems[i].ObjectID == SkipObjectID)
					continue;

				kItem = GetItemGameState(InventoryItems[i], CheckGameState);
				if (kItem != none)
				{
					if (class'X2TacticalGameRulesetDataStructures'.static.InventorySlotBypassesUniqueRule(kItem.InventorySlot))
						continue;

					UniqueItemTemplate = kItem.GetMyTemplate();
					if (bUniqueCat)
					{
						if (UniqueItemTemplate.ItemCat == ItemTemplate.ItemCat)
							return false;
					}
					if (bUniqueWeaponCat)
					{
						UniqueWeaponTemplate = X2WeaponTemplate(UniqueItemTemplate);
						if (UniqueWeaponTemplate.WeaponCat == WeaponTemplate.WeaponCat)
							return false;
					}
				}
			}
		}
	}

	return true;
}

protected simulated function bool AddItemToBackpack(XComGameState_Item Item, XComGameState NewGameState)
{
	local array<XComGameState_Item> BackpackItems;
	local XComGameState_Item BackpackItem, NewBackpackItem;
	local X2ItemTemplate ItemTemplate;
	local int AvailableQuantity, UseQuantity;

	//  First look to distribute all available quantity into existing stacks
	ItemTemplate = Item.GetMyTemplate();
	BackpackItems = GetAllItemsInSlot(eInvSlot_Backpack, NewGameState);
	foreach BackpackItems(BackpackItem)
	{
		AvailableQuantity = 0;
		if (BackpackItem.GetMyTemplate() == ItemTemplate)
		{
			if (BackpackItem.Quantity < ItemTemplate.MaxQuantity)
			{
				AvailableQuantity = ItemTemplate.MaxQuantity - BackpackItem.Quantity;
				UseQuantity = min(AvailableQuantity, Item.Quantity);
				NewBackpackItem = XComGameState_Item(NewGameState.CreateStateObject(BackpackItem.Class, BackpackItem.ObjectID));
				NewBackpackItem.Quantity += UseQuantity;
				NewGameState.AddStateObject(NewBackpackItem);
				Item.Quantity -= UseQuantity;
				if (Item.Quantity < 1)
					break;
			}
		}
	}
	if (Item.Quantity < 1)
	{
		//  item should be destroyed as it was collated into other existing items
		NewGameState.RemoveStateObject(Item.ObjectID);
	}
	else
	{
		InventoryItems.AddItem(Item.GetReference());
		ModifyCurrentStat(eStat_BackpackSize, -Item.GetItemSize());
	}	
	return true;
}

simulated function ApplyCombatSimStats(XComGameState_Item CombatSim, optional bool bLookupBonus = true, optional bool bForceBonus = false)
{
	local bool bHasBonus, bWasInjured;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local float MaxStat, NewMaxStat;
	local int i, Boost;

	History = `XCOMHISTORY;
	bHasBonus = bForceBonus;
	if (bLookupBonus && !bHasBonus)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if (XComHQ != none)
		{
			bHasBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;
		}
	}
	bWasInjured = IsInjured();
	for(i = 0; i < CombatSim.StatBoosts.Length; i++)
	{
		Boost = CombatSim.StatBoosts[i].Boost;
		if (bHasBonus)
		{
			if (X2EquipmentTemplate(CombatSim.GetMyTemplate()).bUseBoostIncrement)
				Boost += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement;
			else
				Boost += Round(Boost * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue);
		}

		MaxStat = GetMaxStat(CombatSim.StatBoosts[i].StatType);
		NewMaxStat = MaxStat + Boost;
		SetBaseMaxStat(CombatSim.StatBoosts[i].StatType, NewMaxStat);

		if(CombatSim.StatBoosts[i].StatType != eStat_HP || !bWasInjured)
		{
			SetCurrentStat(CombatSim.StatBoosts[i].StatType, NewMaxStat);
		}
	}
}

simulated function UnapplyCombatSimStats(XComGameState_Item CombatSim, optional bool bLookupBonus = true)
{
	local bool bHasBonus;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local float MaxStat, NewMaxStat;
	local int i, Boost;

	History = `XCOMHISTORY;
	if (bLookupBonus)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if (XComHQ != none)
		{
			bHasBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;
		}
	}
	for (i = 0; i < CombatSim.StatBoosts.Length; ++i)
	{
		Boost = CombatSim.StatBoosts[i].Boost;
		if (bHasBonus)
		{
			if (X2EquipmentTemplate(CombatSim.GetMyTemplate()).bUseBoostIncrement)
				Boost += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement;
			else
				Boost += Round(Boost * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue);
		}

		MaxStat = GetMaxStat(CombatSim.StatBoosts[i].StatType);
		NewMaxStat = MaxStat - Boost;
		SetBaseMaxStat(CombatSim.StatBoosts[i].StatType, NewMaxStat);

		if(GetCurrentStat(CombatSim.StatBoosts[i].StatType) > NewMaxStat)
		{
			SetCurrentStat(CombatSim.StatBoosts[i].StatType, NewMaxStat);
		}
	}
}

simulated function bool RemoveItemFromInventory(XComGameState_Item Item, optional XComGameState ModifyGameState)
{
	local X2ItemTemplate ItemTemplate;
	local X2ArmorTemplate ArmorTemplate;
	local int RemoveIndex;

	if (CanRemoveItemFromInventory(Item, ModifyGameState))
	{				
		RemoveIndex = InventoryItems.Find('ObjectID', Item.ObjectID);
		`assert(RemoveIndex != INDEX_NONE);

		ItemTemplate = Item.GetMyTemplate();

		// If the item to remove is armor and this unit is a soldier, store appearance settings
		ArmorTemplate = X2ArmorTemplate(ItemTemplate);
		if (ArmorTemplate != none && IsSoldier())
		{
			StoreAppearance(kAppearance.iGender, ArmorTemplate.DataName);
		}

		if( ItemTemplate.OnUnequippedFn != None )
		{
			ItemTemplate.OnUnequippedFn(Item, self, ModifyGameState);

			//  find the removed item again, in case it got handled somehow in the above
			RemoveIndex = InventoryItems.Find('ObjectID', Item.ObjectID);
			if (RemoveIndex == INDEX_NONE)          //  must have been removed already, although that's kind of naughty
			{
				`RedScreen("Attempt to remove item" @ Item.GetMyTemplateName() @ "properly may have failed due to OnUnequippedFn -jbouscher @gameplay");
			}
		}		

		if (RemoveIndex != INDEX_NONE)
			InventoryItems.Remove(RemoveIndex, 1);

		Item.OwnerStateObject.ObjectID = 0;

		switch(Item.InventorySlot)
		{
		case eInvSlot_Armor:
			if(!IsMPCharacter() && X2ArmorTemplate(Item.GetMyTemplate()).bAddsUtilitySlot)
			{
				SetBaseMaxStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems]);
				SetCurrentStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems]);
			}
			break;
		case eInvSlot_Backpack:
			ModifyCurrentStat(eStat_BackpackSize, Item.GetItemSize());
			break;
		case eInvSlot_CombatSim:
			UnapplyCombatSimStats(Item);
			break;
		}

		Item.InventorySlot = eInvSlot_Unknown;
		return true;
	}
	return false;
}

simulated function bool CanRemoveItemFromInventory(XComGameState_Item Item, optional XComGameState CheckGameState)
{
	local name TemplateName;
	local StateObjectReference Ref;

	// Check for bad items due to outdated saves
	if(Item.GetMyTemplate() == none)
		return true;

	if (Item.GetItemSize() == 0)
		return false;

	TemplateName = Item.GetMyTemplateName();
	if(IsMPCharacter() && ItemIsInMPBaseLoadout(TemplateName) && GetNumItemsByTemplateName(TemplateName, CheckGameState) == 1)
		return false;

	foreach InventoryItems(Ref)
	{
		if (Ref.ObjectID == Item.ObjectID)
			return true;
	}
	return false;
}

simulated function bool ItemIsInMPBaseLoadout(name ItemTemplateName)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local bool bFoundLoadout;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if (Loadout.LoadoutName == m_MPCharacterTemplate.Loadout)
		{
			bFoundLoadout = true;
			break;
		}
	}
	if (bFoundLoadout)
	{
		foreach Loadout.Items(LoadoutItem)
		{
			if(LoadoutItem.Item == ItemTemplateName)
				return true;
		}
	}

	return false;
}

simulated function int GetNumItemsByTemplateName(name ItemTemplateName, optional XComGameState CheckGameState)
{
	local int i, NumItems;
	local XComGameState_Item Item;
	NumItems = 0;
	for (i = 0; i < InventoryItems.Length; ++i)
	{
		Item = GetItemGameState(InventoryItems[i], CheckGameState);
		if(Item != none && Item.GetMyTemplateName() == ItemTemplateName)
			NumItems++;
	}
	return NumItems;
}

simulated function array<XComGameState_Item> GetAllInventoryItems(optional XComGameState CheckGameState, optional bool bExcludePCS = false)
{
	local int i;
	local XComGameState_Item Item;
	local array<XComGameState_Item> Items;

	for (i = 0; i < InventoryItems.Length; ++i)
	{
		Item = GetItemGameState(InventoryItems[i], CheckGameState);

		if(Item != none && (!bExcludePCS || (bExcludePCS && Item.GetMyTemplate().ItemCat != 'combatsim')))
		{
			Items.AddItem(Item);
		}
	}
	return Items;
}

simulated function bool HasItemOfTemplateClass(class<X2ItemTemplate> TemplateClass, optional XComGameState CheckGameState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;

	Items = GetAllInventoryItems(CheckGameState);
	foreach Items(Item)
	{
		if(Item.GetMyTemplate().Class == TemplateClass)
		{
			return true;
		}
	}

	return false;
}
simulated function bool HasItemOfTemplateType(name TemplateName, optional XComGameState CheckGameState)
{
	local array<XComGameState_Item> Items;
	local XComGameState_Item Item;

	Items = GetAllInventoryItems(CheckGameState);
	foreach Items(Item)
	{
		if(Item.GetMyTemplateName() == TemplateName)
		{
			return true;
		}
	}

	return false;
}

simulated function bool HasLoadout(name LoadoutName, optional XComGameState CheckGameState)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local bool bFoundLoadout;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if(Loadout.LoadoutName == LoadoutName)
		{
			bFoundLoadout = true;
			break;
		}
	}

	if(bFoundLoadout)
	{
		foreach Loadout.Items(LoadoutItem)
		{
			if(!HasItemOfTemplateType(LoadoutItem.Item, CheckGameState))
			{
				return false;
			}
		}

		return true;
	}

	return false;
}

/**
 *  Functions below here are for querying this XComGameState_Unit's template data.
 *  These functions can return results that are not exactly the template data if instance data overrides it,
 *  so if you really need the pure template data you'll have to call GetMyTemplate() and look at it yourself.
 */

simulated function bool CanBeCriticallyWounded()
{
	return GetMyTemplate().bCanBeCriticallyWounded;
}

simulated function bool CanBeTerrorist()
{
	return GetMyTemplate().bCanBeTerrorist;
}

simulated function class<XGAIBehavior> GetBehaviorClass()
{
	return GetMyTemplate().BehaviorClass;
}

simulated native function bool IsAdvent() const;

simulated native function bool IsAlien() const;

simulated native function bool IsTurret() const;

// Required for specialized ACV alien heads.
simulated function int IsACV()
{
	local name TemplateName;
	TemplateName = GetMyTemplateName();
	switch (TemplateName)
	{
		case 'ACV':
			return 1;
		break;
		
		case 'ACVCannonChar':
			return 2;
		break;
		
		case 'ACVTreads':
			return 3;
		break;
		
		default:
			return 0;
		break;
	}
}

simulated function bool IsAfraidOfFire()
{
	return GetMyTemplate().bIsAfraidOfFire && !IsImmuneToDamage('Fire');
}

simulated function bool IsPsionic()
{
	return GetMyTemplate().bIsPsionic || IsPsiOperative();
}

simulated function bool HasScorchCircuits()
{
	return FindAbility('ScorchCircuits').ObjectID != 0;
}

simulated function bool IsMeleeOnly()
{
	return GetMyTemplate().bIsMeleeOnly;
}

simulated native function bool IsCivilian() const;
simulated native function bool IsRobotic() const;
simulated native function bool IsSoldier() const;
simulated native function bool CanScamper() const;
simulated native function bool CanTakeCover() const;
simulated native function bool IsDead() const;
simulated native function bool IsAlive() const;
simulated native function bool IsBleedingOut() const;
simulated native function bool IsStasisLanced() const;
simulated native function bool IsUnconscious() const;
simulated native function bool IsBurning() const;
simulated native function bool IsAcidBurning() const;
simulated native function bool IsConfused() const;
simulated native function bool IsDisoriented() const;
simulated native function bool IsPoisoned() const;
simulated native function bool IsInStasis() const;
simulated native function bool IsUnitAffectedByEffectName(name EffectName) const;
simulated native function XComGameState_Effect GetUnitAffectedByEffectState(name EffectName) const;
simulated native function bool IsUnitAffectedByDamageType(name DamageType) const;
simulated native function bool IsUnitApplyingEffectName(name EffectName) const;
simulated native function XComGameState_Effect GetUnitApplyingEffectState(name EffectName) const;
simulated native function bool IsImpaired(optional bool bIgnoreStunned) const;
simulated native function bool IsInCombat() const;
simulated native function bool IsPanicked() const;
simulated native function bool CanEarnXp() const;
simulated native function float GetXpKillscore() const;
simulated native function int GetDirectXpAmount() const;
simulated native function bool HasClearanceToMaxZ() const;
simulated native function bool IsStunned() const;
simulated native function bool IsMindControlled() const;
simulated native function ETeam GetPreviousTeam() const;        //  if mind controlled, the team the unit was on before being mind controlled. otherwise, the current team.
simulated native function bool BlocksPathingWhenDead() const;

function bool IsAbleToAct()
{
	return IsAlive() && !IsIncapacitated() && !IsStunned() && !IsPanicked();
}

function bool IsIncapacitated()
{
	return IsBleedingOut() || IsUnconscious() || IsStasisLanced();
}


simulated function AddAffectingEffect(XComGameState_Effect Effect)
{
	AffectedByEffects.AddItem(Effect.GetReference());
	AffectedByEffectNames.AddItem(Effect.GetX2Effect().EffectName);
}

simulated function RemoveAffectingEffect(XComGameState_Effect Effect)
{
	local int Idx;
	local name strName;

	Idx = AffectedByEffects.Find('ObjectID', Effect.ObjectID);
	if(Idx != INDEX_NONE)
	{
		AffectedByEffectNames.Remove(Idx, 1);
		AffectedByEffects.Remove(Idx, 1);
	}
	else
	{
		`Redscreen("AffectedByEffectNames: No effect found-" @Effect @"Name:"@ Effect.GetX2Effect().EffectName@"\nArray length:" @AffectedByEffectNames.Length); 
		foreach AffectedByEffectNames(strName)
		{
			`Redscreen("EffectName:"@strName); 
		}
	}
}

simulated function AddAppliedEffect(XComGameState_Effect Effect)
{
	AppliedEffects.AddItem(Effect.GetReference());
	AppliedEffectNames.AddItem(Effect.GetX2Effect().EffectName);
}

simulated function RemoveAppliedEffect(XComGameState_Effect Effect)
{
	local int Idx;
	local name strName;

	Idx = AppliedEffects.Find('ObjectID', Effect.ObjectID);
	if (Idx != INDEX_NONE)
	{
		AppliedEffectNames.Remove(Idx, 1);
		AppliedEffects.Remove(Idx, 1);
	}
	else
	{
		`Redscreen("AppliedEffectNames: No effect found-" @Effect @"Name:"@ Effect.GetX2Effect().EffectName@"\nArray length:" @AppliedEffectNames.Length); 
		foreach AppliedEffectNames(strName)
		{
			`Redscreen("EffectName:"@strName); 
		}
	}
}

simulated function bool IsHunkeredDown()
{
	return IsUnitAffectedByEffectName('HunkerDown');
}

native function bool ShouldAvoidPathingNearCover() const;
native function bool ShouldAvoidWallSmashPathing() const;
native function bool ShouldAvoidDestructionPathing() const;
native function bool ShouldExtraAvoidDestructionPathing() const;

simulated native function bool IsBeingCarried();
simulated native function bool CanBeCarried();

native function bool IsImmuneToDamageCharacterTemplate(name DamageType) const;

event bool IsImmuneToDamage(name DamageType)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	
	if( IsImmuneToDamageCharacterTemplate(DamageType) )
	{
		return true;
	}

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState.GetX2Effect().ProvidesDamageImmunity(EffectState, DamageType))
			return true;
	}
	return false;
}

event bool IsAlreadyTakingEffectDamage(name DamageType)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState.GetX2Effect().DamageTypes.Find(DamageType) != INDEX_NONE)
			return true;
	}
	return false;
}

native function bool IsImmuneToWorldHazard(name WorldEffectName) const;

native function bool IsPlayerControlled() const;
simulated native function bool ControllingPlayerIsAI() const;

delegate SubSystemFnPtr(XComGameState_Unit kSubsystem);

function SetControllingPlayerSub(XComGameState_Unit kSubsystem)
{
	kSubsystem.SetControllingPlayer(ControllingPlayer);
}

simulated function SetControllingPlayer( StateObjectReference kPlayerRef )
{
	local bool ShouldTriggerEvent;
	local XComGameState_Unit PreviousState;

	//We should trigger an event if this is a team change (i.e. not initial setup).
	//So, check that the unit exists previously.
	PreviousState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	if (PreviousState != None && PreviousState != self && kPlayerRef != ControllingPlayer)
		ShouldTriggerEvent = true;

	`assert( kPlayerRef.ObjectID != 0 );
	ControllingPlayer = kPlayerRef;
	bRequiresVisibilityUpdate = true; //Changing teams requires updated visibility

	//Actually trigger the event, only after we've actually altered ControllingPlayer
	if (ShouldTriggerEvent)
		`XEVENTMGR.TriggerEvent('UnitChangedTeam', self, self, XComGameState(Outer));
}

simulated function ApplyToSubsystems( delegate<SubSystemFnPtr> FunctionPtr)
{
	local XComGameState_Unit kSubsystem;
	local int ComponentID;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	if (!m_bSubsystem)
	{
		foreach ComponentObjectIds(ComponentID)
		{
			kSubsystem = XComGameState_Unit(History.GetGameStateForObjectID(ComponentID));
			if (kSubsystem != None)
			{
				FunctionPtr(kSubsystem);
			}
		}
	}
}

simulated native function bool WasConcealed(int HistoryIndex) const;
simulated native function bool IsSpotted() const;
simulated native function bool IsConcealed() const;
simulated native function bool IsIndividuallyConcealed() const;
simulated native function bool IsSquadConcealed() const;
//  IMPORTANT: Only X2Effect_RangerStealth should call this function. Otherwise, the rest of the gameplay stuff won't be in sync with the bool!!!
simulated native function SetIndividualConcealment(bool bIsConcealed, XComGameState NewGameState);

event OnConcealmentEntered(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.TriggerEvent('UnitConcealmentEntered', ThisObj, ThisObj, NewGameState);

	// clear the concealment breaker ref whenever we enter concealment
	ConcealmentBrokenByUnitRef.ObjectID = -1;
}

event OnConcealmentBroken(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.TriggerEvent('UnitConcealmentBroken', ThisObj, ThisObj, NewGameState);
}

function RankUpTacticalVisualization()
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Rank Up");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForRankUp;

	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	NewGameState.AddStateObject(NewUnitState);

	`TACTICALRULES.SubmitGameState(NewGameState);
}

function BuildVisualizationForRankUp(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local X2Action_PlayWorldMessage MessageAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_Delay DelayAction;
	local X2Action_CameraLookAt LookAtAction;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local XComGameState_Unit UnitState;
	local string Display;

	History = `XCOMHISTORY;

	// Add a track for the instigator
	//****************************************************************************************
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		// the first unit is the instigating unit for this block
		break;
	}

	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = UnitState;
	BuildTrack.TrackActor = History.GetVisualizer(UnitState.ObjectID);

	// Camera pan to the instigator
	// wait for the camera to arrive
	if (!UnitState.IsConcealed())
	{
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		LookAtAction.LookAtObject = UnitState;
		LookAtAction.UseTether = false;
		LookAtAction.BlockUntilActorOnScreen = true;
	}

	// show the event notices message
	Display = Repl(class'UIEventNoticesTactical'.default.RankUpMessage, "%NAME", UnitState.GetName(eNameType_RankLast));

	MessageAction = X2Action_PlayWorldMessage(class'X2Action_PlayWorldMessage'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	MessageAction.AddWorldMessage(Display, class'UIEventNoticesTactical'.default.RankUpIcon);

	// play the revealed flyover on the instigator
	Display = Repl(class'UIEventNoticesTactical'.default.RankUpMessage, "%NAME", UnitState.GetName(eNameType_FullNick));

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundFX.SoldierPromotedCue', Display, '', eColor_Good); 

	// pause a few seconds
	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	DelayAction.Duration = 2.0;

	OutVisualizationTracks.AddItem(BuildTrack);
}

function EnterConcealment()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Concealment Gained");
	EnterConcealmentNewGameState(NewGameState);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

function EnterConcealmentNewGameState(XComGameState NewGameState)
{
	local XComGameState_Unit NewUnitState;

	if( NewGameState.GetContext().PostBuildVisualizationFn.Find(BuildVisualizationForConcealment_Entered_Individual) == INDEX_NONE ) // we only need to visualize this once
	{
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BuildVisualizationForConcealment_Entered_Individual);
	}

	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	NewUnitState.SetIndividualConcealment(true, NewGameState);
	NewGameState.AddStateObject(NewUnitState);
}

function BreakConcealment(optional XComGameState_Unit ConcealmentBreaker, optional bool UnitWasFlanked)
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Concealment Broken");
	BreakConcealmentNewGameState(NewGameState, ConcealmentBreaker, UnitWasFlanked);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

function BreakConcealmentNewGameState(XComGameState NewGameState, optional XComGameState_Unit ConcealmentBreaker, optional bool UnitWasFlanked)
{
	local XComGameState_Unit NewUnitState, UnitState;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local bool bRetainConcealment;

	History = `XCOMHISTORY;

	if( NewGameState.GetContext().PostBuildVisualizationFn.Find(BuildVisualizationForConcealment_Broken_Individual) == INDEX_NONE ) // we only need to visualize this once
	{
		NewGameState.GetContext().PostBuildVisualizationFn.AddItem(BuildVisualizationForConcealment_Broken_Individual);
	}

	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	NewUnitState.SetIndividualConcealment(false, NewGameState);
	if( ConcealmentBreaker != None )
	{
		NewUnitState.ConcealmentBrokenByUnitRef = ConcealmentBreaker.GetReference();
		NewUnitState.bUnitWasFlanked = UnitWasFlanked;
	}
	NewGameState.AddStateObject(NewUnitState);

	// break squad concealment
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(ControllingPlayer.ObjectID));
	if( PlayerState.bSquadIsConcealed )
	{
		PlayerState = XComGameState_Player(NewGameState.CreateStateObject(class'XComGameState_Player', PlayerState.ObjectID));
		PlayerState.bSquadIsConcealed = false;
		NewGameState.AddStateObject(PlayerState);

		`XEVENTMGR.TriggerEvent('SquadConcealmentBroken', PlayerState, PlayerState, NewGameState);

		// break concealment on each other squad member
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if( UnitState.ControllingPlayer.ObjectID == PlayerState.ObjectID && UnitState.IsIndividuallyConcealed() )
			{
				bRetainConcealment = false;
				foreach UnitState.AffectedByEffects(EffectRef)
				{
					EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
					if( EffectState != none )
					{
						if( EffectState.GetX2Effect().RetainIndividualConcealment(EffectState, UnitState) )
						{
							bRetainConcealment = true;
							break;
						}
					}
				}

				if( !bRetainConcealment )
				{
					NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
					NewUnitState.SetIndividualConcealment(false, NewGameState);
					NewGameState.AddStateObject(NewUnitState);
				}
			}
		}
	}
}


//Different wrappers because we need to pass these as delegates and can't simply curry the one function

private function BuildVisualizationForConcealment_Entered_Individual(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{	BuildVisualizationForConcealmentChanged(VisualizeGameState, OutVisualizationTracks, true);	}

private function BuildVisualizationForConcealment_Broken_Individual(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{	BuildVisualizationForConcealmentChanged(VisualizeGameState, OutVisualizationTracks, false);	}

simulated static function BuildVisualizationForConcealmentChanged(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks, bool NowConcealed)
{
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_UpdateUI UIUpdateAction;
	local X2Action_CameraLookAt LookAtAction;
	local X2Action_SendInterTrackMessage SendMessageAction;
	local X2Action_ConnectTheDots ConnectTheDots;
	local X2Action_Delay DelayAction;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local XComGameState_Unit ConcealmentChangeFocusUnitState;
	local XComGameState_Unit UnitState, OldUnitState;
	local XComGameState_Player PlayerState, OldPlayerState;
	local array<XComGameState_Unit> AllConcealmentChangedUnitStates;
	local XComGameState_Unit NonInstigatingUnitState;
	local XComGameStateContext Context;
	local bool bIsSquadConcealEvent;
	local int UnitIndex;
	local bool bCreatedConcealBreakerTracks;
	local X2Action_WaitForAbilityEffect WaitAction;
	local float LookAtDuration;

	LookAtDuration = 0.5f;

	History = `XCOMHISTORY;
	Context = VisualizeGameState.GetContext();

	// determine the best concealment-changed unit to focus the event on
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		OldUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
		if( UnitState.IsIndividuallyConcealed() != OldUnitState.IsIndividuallyConcealed() )
		{
			AllConcealmentChangedUnitStates.AddItem(UnitState);

			if( ConcealmentChangeFocusUnitState == None || UnitState.ConcealmentBrokenByUnitRef.ObjectID > 0 )
			{
				ConcealmentChangeFocusUnitState = UnitState;
			}
		}
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		OldPlayerState = XComGameState_Player(History.GetGameStateForObjectID(PlayerState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
		if (PlayerState.bSquadIsConcealed != OldPlayerState.bSquadIsConcealed)
		{
			bIsSquadConcealEvent = true;
			break;
		}
	}

	//Add a track for each revealed unit.
	for (UnitIndex = 0; UnitIndex < AllConcealmentChangedUnitStates.Length; UnitIndex++)
	{
		UnitState = AllConcealmentChangedUnitStates[UnitIndex];

		if (UnitState.GetMyTemplate().bIsCosmetic)
			continue;


		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = UnitState;
		BuildTrack.TrackActor = History.GetVisualizer(UnitState.ObjectID);

		//The instigator gets special treatment.  For Individual reveal events, every unit is the instigator
		if( UnitState == ConcealmentChangeFocusUnitState || !bIsSquadConcealEvent )
		{
			// if a specific enemy broke concealment, draw a visible connection between that unit and this
			if (UnitState.ConcealmentBrokenByUnitRef.ObjectID > 0 && !bCreatedConcealBreakerTracks)
			{
				// Only crate concealmentbreakertracks once
				bCreatedConcealBreakerTracks = true;
				CreateConcealmentBreakerTracks(VisualizeGameState, UnitState, OutVisualizationTracks);

				// Unit must wait for concealment breaker tracks to signal us
				class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);	
			}
			else if (!bIsSquadConcealEvent && UnitIndex != 0)
			{
				// If we are not a squad conceal event and we're not the first unit, we need to wait for the previous unit to send us a message before we proceed so the units actions
				// advance in sequence rather than simultaneously
				WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
				WaitAction.ChangeTimeoutLength(12.0f + UnitIndex * 2);
			}

			// Camera pan to the instigator
			// wait for the camera to arrive
			LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTrack(BuildTrack, Context));
			LookAtAction.LookAtObject = UnitState;
			LookAtAction.UseTether = false;
			LookAtAction.BlockUntilActorOnScreen = true;
			LookAtAction.LookAtDuration = LookAtDuration;

			// animate in the HUD status update
			UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, Context));
			if (`TUTORIAL != none)
			{
				// Needs to be set for the tutorial to enter concealement at the proper time because an active unit is not set when this is visualized
				UIUpdateAction.SpecificID = UnitState.ObjectID; 
			}
			UIUpdateAction.UpdateType = EUIUT_HUD_Concealed;

			// update the concealment flag on all revealed units
			UIUpdateAction = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, Context));
			UIUpdateAction.SpecificID = -1;
			UIUpdateAction.UpdateType = EUIUT_UnitFlag_Concealed;

			// signal other units visualization
			if (bIsSquadConcealEvent)
			{
				foreach AllConcealmentChangedUnitStates(NonInstigatingUnitState)
				{
					SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
					SendMessageAction.SendTrackMessageToRef.ObjectID = NonInstigatingUnitState.ObjectID;
				}
			}

			//Instigator gets flyover with sound
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
			if (NowConcealed)
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundTacticalUI.Concealment_Concealed_Cue', class'X2StatusEffects'.default.ConcealedFriendlyName, bIsSquadConcealEvent ? 'EnterSquadConcealment' : '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Concealed);
			}
			else
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue'SoundTacticalUI.Concealment_Unconcealed_Cue', class'X2StatusEffects'.default.RevealedFriendlyName, bIsSquadConcealEvent ? 'SquadConcealmentBroken' : 'ConcealedSpotted', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Revealed);
			}

			// pause a few seconds
			DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, Context));
			DelayAction.Duration = bIsSquadConcealEvent ? 0.5 : LookAtDuration;

			// cleanup the connect the dots vis if there was one
			if( UnitState.ConcealmentBrokenByUnitRef.ObjectID > 0 )
			{
				ConnectTheDots = X2Action_ConnectTheDots(class'X2Action_ConnectTheDots'.static.AddToVisualizationTrack(BuildTrack, Context));
				ConnectTheDots.bCleanupConnection = true;
			}

			if (!bIsSquadConcealEvent)
			{
				if (UnitIndex + 1 < AllConcealmentChangedUnitStates.Length)
				{
					// Send the next unit a message so it can start
					SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
					SendMessageAction.SendTrackMessageToRef.ObjectID = AllConcealmentChangedUnitStates[UnitIndex + 1].ObjectID;
				}
			}
		}
		else
		{
			//Everyone else waits for the instigator
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

			//Everyone else, if we're showing them, just gets visual flyovers
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
			if (NowConcealed)
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'X2StatusEffects'.default.ConcealedFriendlyName, '', eColor_Good, class'UIUtilities_Image'.const.UnitStatus_Concealed);
			}
			else
			{
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'X2StatusEffects'.default.RevealedFriendlyName, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Revealed);
			}
		}

		//Update flashlight status on everyone (turn on lights if revealed)
		class'X2Action_UpdateFlashlight'.static.AddToVisualizationTrack(BuildTrack, Context);

		//Subsequent units are not the instigator.
		OutVisualizationTracks.AddItem(BuildTrack);
	}
}

static function CreateConcealmentBreakerTracks(XComGameState VisualizeGameState, XComGameState_Unit UnitState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack ConcealmentBreakerBuildTrack;
	local TTile UnitTileLocation;
	local Vector UnitLocation;
	local VisualizationTrack EmptyTrack;
	local XComGameStateHistory History;
	local XComGameState_Unit ConcealmentBrokenByUnitState;
	local X2Action_MoveTurn MoveTurnAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_ConnectTheDots ConnectTheDots;
	local X2Action_Delay DelayAction;
	local X2Action_SendInterTrackMessage SendMessageAction;
	local XComGameStateContext Context;
	local X2Action_PlayEffect EffectAction;
	local XComGameState_AIGroup AIGroup;

	History = `XCOMHISTORY;
	Context = VisualizeGameState.GetContext();

	UnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
	UnitLocation = `XWORLD.GetPositionFromTileCoordinates(UnitTileLocation);

	// visualization of the concealment breaker
	ConcealmentBrokenByUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitState.ConcealmentBrokenByUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex));

	ConcealmentBreakerBuildTrack = EmptyTrack;
	ConcealmentBreakerBuildTrack.StateObject_OldState = History.GetGameStateForObjectID(ConcealmentBrokenByUnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	ConcealmentBreakerBuildTrack.StateObject_NewState = ConcealmentBrokenByUnitState;
	ConcealmentBreakerBuildTrack.TrackActor = History.GetVisualizer(ConcealmentBrokenByUnitState.ObjectID);

	// connect the dots
	ConnectTheDots = X2Action_ConnectTheDots(class'X2Action_ConnectTheDots'.static.AddToVisualizationTrack(ConcealmentBreakerBuildTrack, Context));
	ConnectTheDots.bCleanupConnection = false;
	ConcealmentBrokenByUnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
	ConnectTheDots.SourceLocation = `XWORLD.GetPositionFromTileCoordinates(UnitTileLocation);
	ConnectTheDots.TargetLocation = UnitLocation;

	// center the camera on the enemy group for a few seconds and clear the FOW
	AIGroup = ConcealmentBrokenByUnitState.GetGroupMembership();
	EffectAction = X2Action_PlayEffect(class'X2Action_PlayEffect'.static.AddToVisualizationTrack(ConcealmentBreakerBuildTrack, Context));
	EffectAction.CenterCameraOnEffectDuration = 1.25f;
	EffectAction.RevealFOWRadius = class'XComWorldData'.const.WORLD_StepSize * 5.0f;
	EffectAction.FOWViewerObjectID = UnitState.ObjectID; //Setting this to be a unit makes it possible for the FOW viewer to reveal units
	EffectAction.EffectLocation = AIGroup != none ? AIGroup.GetGroupMidpoint(VisualizeGameState.HistoryIndex) : ConcealmentBrokenByUnitState.GetVisualizer().Location;
	EffectAction.bWaitForCameraArrival = true;
	EffectAction.bWaitForCameraCompletion = false;

	// add flyover for "I Saw You!"
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(ConcealmentBreakerBuildTrack, Context));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None,
		UnitState.bUnitWasFlanked ?
	class'X2StatusEffects'.default.SpottedFlankedConcealedUnitFriendlyName :
	class'X2StatusEffects'.default.SpottedConcealedUnitFriendlyName,
		'',
		eColor_Bad,
	class'UIUtilities_Image'.const.UnitStatus_Revealed, 
		, 
		, 
		, 
	class'UIWorldMessageMgr'.const.FXS_MSG_BEHAVIOR_READY);

	// Turn to face target unit
	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTrack(ConcealmentBreakerBuildTrack, Context));
	MoveTurnAction.m_vFacePoint = UnitLocation;

	// pause a few seconds
	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(ConcealmentBreakerBuildTrack, Context));
	DelayAction.Duration = 1.25;

	// begin the rest of the concealment break vis for the unit that was spotted
	SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(ConcealmentBreakerBuildTrack, Context));
	SendMessageAction.SendTrackMessageToRef.ObjectID = UnitState.ObjectID;

	OutVisualizationTracks.AddItem(ConcealmentBreakerBuildTrack);
}

// unit makes an attack - alert to enemies with vision of the attacker
function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Ability ActivatedAbilityState;
	local XComGameStateContext_Ability ActivatedAbilityStateContext;
	local XComGameState_Unit SourceUnitState, EnemyInSoundRangeUnitState;
	local XComGameState_Item WeaponState;
	local int SoundRange;
	local TTile SoundTileLocation;
	local Vector SoundLocation;
	local array<StateObjectReference> Enemies;
	local StateObjectReference EnemyRef;
	local XComGameStateHistory History;
	local bool bRetainConcealment;

	ActivatedAbilityStateContext = XComGameStateContext_Ability(GameState.GetContext());

	// do not process concealment breaks or AI alerts during interrupt processing
	if( ActivatedAbilityStateContext.InterruptionStatus == eInterruptionStatus_Interrupt )
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	ActivatedAbilityState = XComGameState_Ability(EventData);

	// check for reasons to break the concealment
	if( IsConcealed() )
	{
		bRetainConcealment = ActivatedAbilityState.RetainConcealmentOnActivation(ActivatedAbilityStateContext);
		if (!bRetainConcealment)
			BreakConcealment();
	}

	if (ActivatedAbilityState.IsAbilityInputTriggered() || ActivatedAbilityState.GetMyTemplate().bCausesCheckFirstSightingOfEnemyGroup)
	{
		CheckFirstSightingOfEnemyGroup(GameState, ActivatedAbilityState.GetMyTemplate().bCausesCheckFirstSightingOfEnemyGroup);
	}

	if( ActivatedAbilityState.DoesAbilityCauseSound() )
	{
		if( ActivatedAbilityStateContext != None && ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID > 0 )
		{
			SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.SourceObject.ObjectID));
			WeaponState = XComGameState_Item(GameState.GetGameStateForObjectID(ActivatedAbilityStateContext.InputContext.ItemObject.ObjectID));

			SoundRange = WeaponState.GetItemSoundRange();
			if( SoundRange > 0 )
			{
				if( WeaponState.SoundOriginatesFromOwnerLocation() && ActivatedAbilityStateContext.InputContext.TargetLocations.Length > 0 )
				{
					SoundLocation = ActivatedAbilityStateContext.InputContext.TargetLocations[0];
					SoundTileLocation = `XWORLD.GetTileCoordinatesFromPosition(SoundLocation);
				}
				else
				{
					GetKeystoneVisibilityLocation(SoundTileLocation);
				}

				GetEnemiesInRange(SoundTileLocation, SoundRange, Enemies);

				`LogAI("Weapon sound @ Tile("$SoundTileLocation.X$","@SoundTileLocation.Y$","@SoundTileLocation.Z$") - Found"@Enemies.Length@"enemies in range ("$SoundRange$" meters)");
				foreach Enemies(EnemyRef)
				{
					EnemyInSoundRangeUnitState = XComGameState_Unit(History.GetGameStateForObjectID(EnemyRef.ObjectID));

					// this was the targeted unit
					if( EnemyInSoundRangeUnitState.ObjectID == ActivatedAbilityStateContext.InputContext.PrimaryTarget.ObjectID )
					{
						UnitAGainsKnowledgeOfUnitB(EnemyInSoundRangeUnitState, SourceUnitState, GameState, eAC_TakingFire, false);
					}
					// this unit just overheard the sound
					else
					{
						UnitAGainsKnowledgeOfUnitB(EnemyInSoundRangeUnitState, SourceUnitState, GameState, eAC_DetectedSound, false);
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

// unit moves - alert for him for other units he sees from the new location
// unit moves - alert for other units towards this unit
function EventListenerReturn OnUnitEnteredTile(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit OtherUnitState, ThisUnitState;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local GameRulesCache_VisibilityInfo VisibilityInfoFromThisUnit, VisibilityInfoFromOtherUnit;
	local float ConcealmentDetectionDistance;
	local XComGameState_AIGroup AIGroupState;
	local XComGameStateContext_Ability SourceAbilityContext;
	local XComGameState_InteractiveObject InteractiveObjectState;
	local XComWorldData WorldData;
	local Vector CurrentPosition, TestPosition;
	local TTile CurrentTileLocation;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent PersistentEffect;
	local XComGameState NewGameState;
	local XComGameStateContext_EffectRemoved EffectRemovedContext;

	WorldData = `XWORLD;
	History = `XCOMHISTORY;

	ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

	// cleanse burning on entering water
	ThisUnitState.GetKeystoneVisibilityLocation(CurrentTileLocation);
	if( ThisUnitState.IsBurning() && WorldData.IsWaterTile(CurrentTileLocation) )
	{
		foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
		{
			if( EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == ObjectID )
			{
				PersistentEffect = EffectState.GetX2Effect();
				if( PersistentEffect.EffectName == class'X2StatusEffects'.default.BurningName )
				{
					EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
					NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
					EffectState.RemoveEffect(NewGameState, NewGameState, true); //Cleansed

					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
		}
	}

	SourceAbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if( SourceAbilityContext != None )
	{
		// concealment for this unit is broken when stepping into a new tile if the act of stepping into the new tile caused environmental damage (ex. "broken glass")
		// if this occurred, then the GameState will contain either an environmental damage state or an InteractiveObject state
		if( ThisUnitState.IsConcealed() && SourceAbilityContext.ResultContext.bPathCausesDestruction )
		{
			ThisUnitState.BreakConcealment();
		}

		ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));

		// check if this unit is a member of a group waiting on this unit's movement to complete 
		// (or at least reach the interruption step where the movement should complete)
		AIGroupState = ThisUnitState.GetGroupMembership();
		if( AIGroupState != None &&
			AIGroupState.IsWaitingOnUnitForReveal(ThisUnitState) &&
			(SourceAbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt ||
			(AIGroupState.FinalVisibilityMovementStep > INDEX_NONE &&
			AIGroupState.FinalVisibilityMovementStep <= SourceAbilityContext.ResultContext.InterruptionStep)) )
		{
			AIGroupState.StopWaitingOnUnitForReveal(ThisUnitState);
		}
	}

	// concealment may be broken by moving within range of an interactive object 'detector'
	if( ThisUnitState.IsConcealed() )
	{
		ThisUnitState.GetKeystoneVisibilityLocation(CurrentTileLocation);
		CurrentPosition = WorldData.GetPositionFromTileCoordinates(CurrentTileLocation);
		
		foreach History.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObjectState)
		{
			if( InteractiveObjectState.DetectionRange > 0.0 && !InteractiveObjectState.bHasBeenHacked )
			{
				TestPosition = WorldData.GetPositionFromTileCoordinates(InteractiveObjectState.TileLocation);

				if( VSizeSq(TestPosition - CurrentPosition) <= Square(InteractiveObjectState.DetectionRange) )
				{
					ThisUnitState.BreakConcealment();
					ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
					break;
				}
			}
		}
	}

	// concealment may also be broken if this unit moves into detection range of an enemy unit
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	foreach History.IterateByClassType(class'XComGameState_Unit', OtherUnitState)
	{
		// don't process visibility against self
		if( OtherUnitState.ObjectID == ThisUnitState.ObjectID )
		{
			continue;
		}

		VisibilityMgr.GetVisibilityInfo(ThisUnitState.ObjectID, OtherUnitState.ObjectID, VisibilityInfoFromThisUnit);

		if( VisibilityInfoFromThisUnit.bVisibleBasic )
		{
			// check if the other unit is concealed, and this unit's move has revealed him
			if( OtherUnitState.IsConcealed() &&
			    OtherUnitState.UnitBreaksConcealment(ThisUnitState) &&
				VisibilityInfoFromThisUnit.TargetCover == CT_None )
			{
				ConcealmentDetectionDistance = OtherUnitState.GetConcealmentDetectionDistance(ThisUnitState);
				if( VisibilityInfoFromThisUnit.DefaultTargetDist <= Square(ConcealmentDetectionDistance) )
				{
					OtherUnitState.BreakConcealment(ThisUnitState, true);

				// have to refresh the unit state after broken concealment
				OtherUnitState = XComGameState_Unit(History.GetGameStateForObjectID(OtherUnitState.ObjectID));
			}
			}

			// generate alert data for this unit about other units
			UnitASeesUnitB(ThisUnitState, OtherUnitState, GameState);
		}

		// only need to process visibility updates from the other unit if it is still alive
		if( OtherUnitState.IsAlive() )
		{
			VisibilityMgr.GetVisibilityInfo(OtherUnitState.ObjectID, ThisUnitState.ObjectID, VisibilityInfoFromOtherUnit);

			if( VisibilityInfoFromOtherUnit.bVisibleBasic )
			{
				// check if this unit is concealed and that concealment is broken by entering into an enemy's detection tile
				if( ThisUnitState.IsConcealed() && UnitBreaksConcealment(OtherUnitState) )
				{
					ConcealmentDetectionDistance = GetConcealmentDetectionDistance(OtherUnitState);
					if( VisibilityInfoFromOtherUnit.DefaultTargetDist <= Square(ConcealmentDetectionDistance) )
					{
						ThisUnitState.BreakConcealment(OtherUnitState);

						// have to refresh the unit state after broken concealment
						ThisUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
					}
				}

				// generate alert data for other units that see this unit
				if( VisibilityInfoFromOtherUnit.bVisibleBasic && !ThisUnitState.IsConcealed() )
				{
					//  don't register an alert if this unit is about to reflex
					AIGroupState = OtherUnitState.GetGroupMembership();
					if (AIGroupState == none || AIGroupState.EverSightedByEnemy)
						UnitASeesUnitB(OtherUnitState, ThisUnitState, GameState);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

static function UnitASeesUnitB(XComGameState_Unit UnitA, XComGameState_Unit UnitB, XComGameState AlertInstigatingGameState)
{
	local EAlertCause AlertCause;
	local XComGameState_AIGroup UnitBGroup;

	AlertCause = eAC_None;

	if (!UnitA.IsDead() && !UnitB.IsDead())
	{
		`XEVENTMGR.TriggerEvent('UnitSeesUnit', UnitA, UnitB, AlertInstigatingGameState);
	}

	if( (!UnitB.IsDead() || !UnitA.HasSeenCorpse(UnitB.ObjectID)) && UnitB.GetTeam() != eTeam_Neutral )
	{
		if( UnitB.IsDead() )
		{
			AlertCause = eAC_DetectedNewCorpse;
			UnitA.MarkCorpseSeen(UnitB.ObjectID);
		}
		else if( UnitA.IsEnemyUnit(UnitB) )
		{
			if(!UnitB.IsConcealed())
			{
				AlertCause = eAC_SeesSpottedUnit;
			}
		}
		else if( UnitB.GetCurrentStat(eStat_AlertLevel) > 0 )
		{
			// Prevent alerting the group if this is a fallback unit. (Fallback is not meant to aggro the other group)
			UnitBGroup = UnitB.GetGroupMembership();
			if( UnitBGroup == None || !UnitBGroup.IsFallingBack() )
			{
				AlertCause = eAC_SeesAlertedAllies;
			}
		}

		UnitAGainsKnowledgeOfUnitB(UnitA, UnitB, AlertInstigatingGameState, AlertCause, true);
	}
}

static function UnitAGainsKnowledgeOfUnitB(XComGameState_Unit UnitA, XComGameState_Unit UnitB, XComGameState AlertInstigatingGameState, EAlertCause AlertCause, bool bUnitAIsMidMove)
{
	local XComGameStateHistory History;
	local AlertAbilityInfo AlertInfo;	
	local X2TacticalGameRuleset Ruleset;
	local XComGameState_AIGroup AIGroupState;
	local XComGameStateContext_Ability SourceAbilityContext;
	local bool bStartedRedAlert;
	local bool bGainedRedAlert;
	local bool bAlertDataSuccessfullyAdded;

	if( AlertCause != eAC_None )
	{
		History = `XCOMHISTORY;
		UnitB.GetKeystoneVisibilityLocation(AlertInfo.AlertTileLocation);
		AlertInfo.AlertUnitSourceID = UnitB.ObjectID;
		AlertInfo.AnalyzingHistoryIndex = History.GetCurrentHistoryIndex();
		
		bAlertDataSuccessfullyAdded = UnitA.UpdateAlertData(AlertCause, AlertInfo);

		bStartedRedAlert = UnitA.GetCurrentStat(eStat_AlertLevel) == `ALERT_LEVEL_RED;
		AIGroupState = UnitA.GetGroupMembership();
		if( bAlertDataSuccessfullyAdded && (AIGroupState != none) )
		{
			// If the AlertData was not added successfully, then do not process the AlertAbility
			// based upon the AlertCause
			AIGroupState.ApplyAlertAbilityToGroup(AlertCause);
		}
		UnitA = XComGameState_Unit(History.GetGameStateForObjectID(UnitA.ObjectID));
		bGainedRedAlert = !bStartedRedAlert && UnitA.GetCurrentStat(eStat_AlertLevel) == `ALERT_LEVEL_RED;

		if( AIGroupState != None && //Verify we have a valid group here
		    !AIGroupState.bProcessedScamper && //That we haven't scampered already
		    UnitA.bTriggerRevealAI ) //We are able to scamper 			
		{
			if(class'XComGameState_AIUnitData'.static.DoesCauseReflexMoveActivate(AlertCause)) //The cause of our concern can result in a scamper
			{
				Ruleset = X2TacticalGameRuleset(`XCOMGAME.GameRuleset);

				// if AI is active player and is currently moving, then reveal. The camera system / reveal action will worry about whether it can frame this as a pod reveal or not
				if(Ruleset.UnitActionPlayerIsAI() && bUnitAIsMidMove)
				{
					AIGroupState.InitiateReflexMoveActivate(UnitB, AlertCause);
				}
				// otherwise, reveal iff XCom has visibility of the current unit location
				else if(class'X2TacticalVisibilityHelpers'.static.GetNumEnemyViewersOfTarget(UnitA.ObjectID) > 0)
				{
					SourceAbilityContext = XComGameStateContext_Ability(AlertInstigatingGameState.GetContext());
					// If this is a move interrupt, flag the behavior tree to kick off after the move ends.
					if( SourceAbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt 
					   && SourceAbilityContext.InputContext.MovementPaths.Length > 0 )
					{
						`BEHAVIORTREEMGR.bWaitingOnEndMoveEvent = true;
					}
					AIGroupState.InitiateReflexMoveActivate(UnitB, AlertCause);
					if( !`BEHAVIORTREEMGR.IsScampering() )
					{
						// Clear the flag if no one is set to scamper.
						`BEHAVIORTREEMGR.bWaitingOnEndMoveEvent = false;
					}
				}
			}
			else if(bGainedRedAlert)
			{				
				`redscreen("Warning: AI gained a red alert status by cause "$ AlertCause $" that was not valid for scamper. Units shouldn't enter red alert without scampering! @gameplay" );
			}
		}
	}
}

// Returns true if the AlertCause was successfully added as AlertData to the unit
function bool UpdateAlertData(EAlertCause AlertCause, AlertAbilityInfo AlertInfo)
{
	local XComGameState_AIUnitData AIUnitData_NewState;
	local XComGameState NewGameState;
	local int AIUnitDataID;
	local bool bResult;

	bResult = false;

	AIUnitDataID = GetAIUnitDataID();
	if( AIUnitDataID > 0 )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UpdateAlertData [" $ ObjectID @ AlertCause @ AlertInfo.AlertUnitSourceID $ "]");

		AIUnitData_NewState = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', AIUnitDataID));
		bResult = AIUnitData_NewState.AddAlertData(ObjectID, AlertCause, AlertInfo, NewGameState);
		if( bResult )
		{
			NewGameState.AddStateObject(AIUnitData_NewState);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		else
		{
			NewGameState.PurgeGameStateForObjectID(AIUnitData_NewState.ObjectID);
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
	}

	return bResult;
}

function ApplyAlertAbilityForNewAlertData(EAlertCause AlertCause)
{
	local StateObjectReference AbilityRef;
	local XComGameStateContext_Ability NewAbilityContext;
	local X2TacticalGameRuleset Ruleset;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;

	if( class'XComGameState_AIUnitData'.static.IsCauseAggressive(AlertCause) && GetCurrentStat(eStat_AlertLevel) < `ALERT_LEVEL_RED )
	{
		// go to red alert
		AbilityRef = FindAbility('RedAlert');
	}
	else if(class'XComGameState_AIUnitData'.static.IsCauseSuspicious(AlertCause) && GetCurrentStat(eStat_AlertLevel) < `ALERT_LEVEL_YELLOW)
	{
		// go to yellow alert
		AbilityRef = FindAbility('YellowAlert');
	}

	// process the alert ability
	if( AbilityRef.ObjectID > 0 )
	{
		History = `XCOMHISTORY;

		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));

		if( AbilityState != None )
		{
			NewAbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, ObjectID);
			NewAbilityContext.ResultContext.iCustomAbilityData = AlertCause;
			if( NewAbilityContext.Validate() )
			{
				Ruleset = X2TacticalGameRuleset(`XCOMGAME.GameRuleset);
				Ruleset.SubmitGameStateContext(NewAbilityContext);
			}
		}
	}
}

function EventListenerReturn OnAlertDataTriggerAlertAbility(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit AlertedUnit;

	local XComGameState_AIUnitData AIGameState;
	local int AIUnitDataID;
	local EAlertCause AlertCause;
	local XComGameState NewGameState;

	AlertedUnit = XComGameState_Unit(EventSource);
	
	if( AlertedUnit.IsAlive() )
	{
		AIUnitDataID = AlertedUnit.GetAIUnitDataID();
		if( AIUnitDataID == INDEX_NONE )
		{
			return ELR_NoInterrupt; // This may be a mind-controlled soldier. If so, we don't need to update their alert data.
		}
		AIGameState = XComGameState_AIUnitData(GameState.GetGameStateForObjectID(AIUnitDataID));
		`assert(AIGameState != none);

		AlertCause = eAC_None;

		if( AIGameState.RedAlertCause != eAC_None )
		{
			AlertCause = AIGameState.RedAlertCause;
		}
		else if( AIGameState.YellowAlertCause != eAC_None )
		{
			AlertCause =  AIGameState.YellowAlertCause;
		}

		if( AlertCause != eAC_None )
		{
			AlertedUnit.ApplyAlertAbilityForNewAlertData(AlertCause);

			// Clear the stored AlertCause
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Alerted Unit Update");
			AIGameState = XComGameState_AIUnitData(NewGameState.CreateStateObject(class'XComGameState_AIUnitData', AIGameState.ObjectID));
			NewGameState.AddStateObject(AIGameState);

			AIGameState.RedAlertCause = eAC_None;
			AIGameState.YellowAlertCause = eAC_None;

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnThisUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComWorldData WorldData;
	local XComGameState_Unit DeadUnit;

	if( !m_CharTemplate.bBlocksPathingWhenDead )
	{
		WorldData = `XWORLD;
		DeadUnit = XComGameState_Unit(EventData);
		WorldData.ClearTileBlockedByUnitFlag(DeadUnit);
	}

	return ELR_NoInterrupt;
}

// Unit takes damage - alert for himself
// unit takes damage - alert to allies with vision of the damagee
function EventListenerReturn OnUnitTookDamage(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit Damagee, Damager, DamageObserver;
	local XComGameStateContext_Ability AbilityContext;
	local array<GameRulesCache_VisibilityInfo> DamageObserverInfos;
	local GameRulesCache_VisibilityInfo DamageObserverInfo;
	local TTile DamageeTileLocation;
	local bool DamageeWasKilled;
	local XComGameStateHistory History;
	local X2GameRulesetVisibilityManager VisibilityMgr;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if( AbilityContext != None )
	{
		Damager = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	}
	Damagee = XComGameState_Unit(EventSource);

	// damaged unit gains direct (though not necessarily absolute) knowledge of the attacker
	DamageeWasKilled = Damagee.IsDead();
	if( !DamageeWasKilled )
	{
		UnitAGainsKnowledgeOfUnitB(Damagee, Damager, GameState, eAC_TookDamage, false);
	}
	
	// all other allies with visibility to the damagee gain indirect knowledge of the attacker
	Damagee.GetKeystoneVisibilityLocation(DamageeTileLocation);
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	VisibilityMgr.GetAllViewersOfLocation(DamageeTileLocation, DamageObserverInfos, class'XComGameState_Unit', -1);
	foreach DamageObserverInfos(DamageObserverInfo)
	{
		if( DamageObserverInfo.bVisibleGameplay )
		{
			DamageObserver = XComGameState_Unit(History.GetGameStateForObjectID(DamageObserverInfo.SourceID));
			if( DamageObserver != None && DamageObserver.IsAlive() )
			{
				if( DamageeWasKilled )
				{
					if( DamageObserver.IsEnemyUnit(Damager) )
					{
						// aliens in the same pod detect their ally (and by extension themselves) under fire, 
						// aliens in other pods just detect the corpse
						if(Damagee.GetGroupMembership().m_arrMembers.Find('ObjectID', DamageObserver.ObjectID) != INDEX_NONE)
						{
							UnitAGainsKnowledgeOfUnitB(DamageObserver, Damager, GameState, eAC_TakingFire, false);
						}
						else
						{
							UnitAGainsKnowledgeOfUnitB(DamageObserver, Damager, GameState, eAC_DetectedNewCorpse, false);
						}
					}

					DamageObserver.MarkCorpseSeen(Damagee.ObjectID);
				}
				else if( DamageObserver.IsEnemyUnit(Damager) )
				{
					UnitAGainsKnowledgeOfUnitB(DamageObserver, Damager, GameState, eAC_DetectedAllyTakingDamage, false);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnEffectBreakUnitConcealment(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	BreakConcealment();

	return ELR_NoInterrupt;
}

function EventListenerReturn OnEffectEnterUnitConcealment(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	EnterConcealment();

	return ELR_NoInterrupt;
}

function GetEnemiesInRange(TTile kLocation, int nMeters, out array<StateObjectReference> OutEnemies)
{
	local vector vCenter, vLoc;
	local float fDistSq;
	local XComGameState_Unit kUnit;
	local XComGameStateHistory History;
	local float AudioDistanceRadius, UnitHearingRadius, RadiiSumSquared;

	History = `XCOMHISTORY;
	vCenter = `XWORLD.GetPositionFromTileCoordinates(kLocation);
	AudioDistanceRadius = `METERSTOUNITS(nMeters);
	fDistSq = Square(AudioDistanceRadius);

	foreach History.IterateByClassType(class'XComGameState_Unit', kUnit)
	{
		if( IsEnemyUnit(kUnit) && kUnit.IsAlive() )
		{
			vLoc = `XWORLD.GetPositionFromTileCoordinates(kUnit.TileLocation);
			UnitHearingRadius = kUnit.GetCurrentStat(eStat_HearingRadius);

			RadiiSumSquared = fDistSq;
			if( UnitHearingRadius != 0 )
			{
				RadiiSumSquared = Square(AudioDistanceRadius + UnitHearingRadius);
			}

			if( VSizeSq(vLoc - vCenter) < RadiiSumSquared )
			{
				OutEnemies.AddItem(kUnit.GetReference());
			}
		}
	}
}


native function float GetConcealmentDetectionDistance(const ref XComGameState_Unit DetectorUnit) const;

simulated function bool CanFlank()
{
	return !IsMeleeOnly();
}

/// <summary>
/// Returns true if this unit is flanked
/// </summary>
/// <param name="FlankedBy">Filter the results of this method by a specific viewer</param>
/// <param name="bOnlyVisibleFlankers">If set to TRUE, then the method will only return true if this unit can see the flankers. Use this to avoid revealing positions of hidden enemies</param>
simulated function bool IsFlanked(optional StateObjectReference FlankedBy, bool bOnlyVisibleFlankers = false, int HistoryIndex = -1)
{
	local int i;
	local array<StateObjectReference> FlankingEnemies;

	if (GetTeam() == eTeam_Neutral)
	{
		if(bOnlyVisibleFlankers)
		{
			// This may need to switch between XCom or Aliens based on Popular Support.
			class'X2TacticalVisibilityHelpers'.static.GetVisibleFlankersOfTarget(GetReference().ObjectID, eTeam_XCom, FlankingEnemies, HistoryIndex);
		}
		else
		{
			class'X2TacticalVisibilityHelpers'.static.GetFlankersOfTarget(GetReference().ObjectID, eTeam_XCom, FlankingEnemies, HistoryIndex);
		}
	}
	else
	{
		if(bOnlyVisibleFlankers)
		{
			class'X2TacticalVisibilityHelpers'.static.GetVisibleFlankingEnemiesOfTarget(GetReference().ObjectID, FlankingEnemies, HistoryIndex);
		}
		else
		{
			class'X2TacticalVisibilityHelpers'.static.GetFlankingEnemiesOfTarget(GetReference().ObjectID, FlankingEnemies, HistoryIndex);
		}
	}

	if(FlankedBy.ObjectID <= 0)
		return FlankingEnemies.Length > 0;

	for(i = 0; i < FlankingEnemies.Length; ++i)
	{
		if(FlankingEnemies[i].ObjectID == FlankedBy.ObjectID)
			return true;
	}

	return false;
}

simulated event bool IsFlankedAtLocation(const vector Location)
{
	local array<StateObjectReference> FlankingEnemies;

	class'X2TacticalVisibilityHelpers'.static.GetFlankingEnemiesOfLocation(Location, ControllingPlayer.ObjectID, FlankingEnemies);

	return FlankingEnemies.Length > 0;
}

simulated function bool IsPsiOperative()
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	SoldierClassTemplate = GetSoldierClassTemplate();
	return SoldierClassTemplate != none && SoldierClassTemplate.DataName == 'PsiOperative';
}

simulated function bool HasSquadsight()
{
	return IsUnitAffectedByEffectName(class'X2Effect_Squadsight'.default.EffectName);
}

function int TileDistanceBetween(XComGameState_Unit OtherUnit)
{
	local XComWorldData WorldData;
	local vector UnitLoc, TargetLoc;
	local float Dist;
	local int Tiles;

	if (OtherUnit == none || OtherUnit == self || TileLocation == OtherUnit.TileLocation)
		return 0;

	WorldData = `XWORLD;
	UnitLoc = WorldData.GetPositionFromTileCoordinates(TileLocation);
	TargetLoc = WorldData.GetPositionFromTileCoordinates(OtherUnit.TileLocation);
	Dist = VSize(UnitLoc - TargetLoc);
	Tiles = Dist / WorldData.WORLD_StepSize;      //@TODO gameplay - surely there is a better check for finding the number of tiles between two points
	return Tiles;
}

simulated function bool UseLargeArmoryScale() // Add your template name here if the model is too large to fit in normal position
{
	return GetMyTemplate().bIsTooBigForArmory;
}

simulated native function ETeam GetTeam() const;
simulated native function ETeam GetEnemyTeam(optional ETeam MyTeam = eTeam_None) const;     //  pass in MyTeam to get the enemy for that team; none will mean to get the enemy team for the unit's current team
simulated native function bool IsEnemyUnit(XComGameState_Unit IsEnemy);
simulated native function bool IsFriendlyUnit(XComGameState_Unit IsFriendly);
simulated native function bool UnitBreaksConcealment(XComGameState_Unit OtherUnit);

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

simulated event bool HasLoot()
{
	return HasUnexplodedLoot();
}

simulated event bool HasAvailableLoot()
{
	return HasLoot() && IsDead() && !IsBeingCarried();
}

protected simulated function bool HasUnexplodedLoot()
{
	local int i;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;

	if(class'XComGameState_Cheats'.static.GetCheatsObject().DisableLooting)
	{
		return false;
	}

	if (PendingLoot.AvailableLoot.Length > 0)
		return true;

	if (PendingLoot.LootToBeCreated.Length == 0)
		return false;

	if (!bKilledByExplosion)
		return true;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	for (i = 0; i < PendingLoot.LootToBeCreated.Length; ++i)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate(PendingLoot.LootToBeCreated[i]);
		if (ItemTemplate != none)
		{
			if (ItemTemplate.LeavesExplosiveRemains)
				return true;
		}
	}
	return false;
}

function DropCarriedLoot(XComGameState ModifyGameState)
{
	local XComGameState_Unit NewUnit;
	local array<XComGameState_Item> Items;

	NewUnit = XComGameState_Unit(ModifyGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	ModifyGameState.AddStateObject(NewUnit);

	Items = NewUnit.GetAllItemsInSlot(eInvSlot_Backpack, ModifyGameState);

	class'XComGameState_LootDrop'.static.CreateLootDrop(ModifyGameState, Items, self, false);
}

function VisualizeLootDropped(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local VisualizationTrack BuildTrack;

	// loot fountain
	History = `XCOMHISTORY;
	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);

	BuildTrack.TrackActor = History.GetVisualizer(ObjectID);

	class'X2Action_LootFountain'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());

	OutVisualizationTracks.AddItem(BuildTrack);
}


function Lootable MakeAvailableLoot(XComGameState ModifyGameState)
{
	local name LootName;
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Item NewItem, SearchItem;
	local XComGameState_Unit NewUnit;
	local StateObjectReference Ref;
	local array<XComGameState_Item> CreatedLoots;
	local bool bStacked;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local bool AnyAlwaysRecoverLoot;

	AnyAlwaysRecoverLoot = false;
	History = `XCOMHISTORY;


	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	NewUnit = XComGameState_Unit(ModifyGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	ModifyGameState.AddStateObject(NewUnit);

	CreatedLoots.Length = 0;
	
	//  copy any objects that have already been created into the new game state
	foreach NewUnit.PendingLoot.AvailableLoot(Ref)
	{
		NewItem = XComGameState_Item(ModifyGameState.CreateStateObject(class'XComGameState_Item', Ref.ObjectID));
		ModifyGameState.AddStateObject(NewItem);
	}
	//  create new items for all loot that hasn't been created yet
	foreach NewUnit.PendingLoot.LootToBeCreated(LootName)
	{		
		ItemTemplate = ItemTemplateManager.FindItemTemplate(LootName);
		if (ItemTemplate != none)
		{
			if (bKilledByExplosion && !ItemTemplate.LeavesExplosiveRemains)
				continue;                                                                               //  item leaves nothing behind due to explosive death
			if (bKilledByExplosion && ItemTemplate.ExplosiveRemains != '')
				ItemTemplate = ItemTemplateManager.FindItemTemplate(ItemTemplate.ExplosiveRemains);     //  item leaves a different item behind due to explosive death
			
			if (ItemTemplate != none)
			{
				bStacked = false;
				if (ItemTemplate.MaxQuantity > 1)
				{
					foreach CreatedLoots(SearchItem)
					{
						if (SearchItem.GetMyTemplate() == ItemTemplate)
						{
							if (SearchItem.Quantity < ItemTemplate.MaxQuantity)
							{
								SearchItem.Quantity++;
								bStacked = true;
								break;
							}
						}
					}
					if (bStacked)
						continue;
				}
				
				NewItem = ItemTemplate.CreateInstanceFromTemplate(ModifyGameState);
				ModifyGameState.AddStateObject(NewItem);



				if( ItemTemplate.bAlwaysRecovered )
				{
					XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
					XComHQ = XComGameState_HeadquartersXCom(ModifyGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					ModifyGameState.AddStateObject(XComHQ);

					NewItem.OwnerStateObject = XComHQ.GetReference();
					XComHQ.PutItemInInventory(ModifyGameState, NewItem, true);

					AnyAlwaysRecoverLoot = true;
				}
				else
				{

					CreatedLoots.AddItem(NewItem);
					//NewUnit.AddItemToInventory(NewItem, eInvSlot_Loot, ModifyGameState);
					//NewUnit.PendingLoot.AvailableLoot.AddItem(NewItem.GetReference());
				}
			}
		}
	}
	NewUnit.PendingLoot.LootToBeCreated.Length = 0;	

	class'XComGameState_LootDrop'.static.CreateLootDrop(ModifyGameState, CreatedLoots, self, true);

	if( AnyAlwaysRecoverLoot )
	{
		ModifyGameState.GetContext().PostBuildVisualizationFn.AddItem(VisualizeAlwaysRecoverLoot);
	}

	return NewUnit;
}

function VisualizeLootDestroyedByExplosives(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local VisualizationTrack BuildTrack;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_Delay DelayAction;

	History = `XCOMHISTORY;

	History.GetCurrentAndPreviousGameStatesForObjectID(ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = History.GetVisualizer(ObjectID);

	DelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	DelayAction.Duration = 1.5;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, class'XLocalizedData'.default.LootExplodedMsg, '', eColor_Bad);

	OutVisualizationTracks.AddItem(BuildTrack);
}

function VisualizeLootFountain(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	class'Helpers'.static.VisualizeLootFountainInternal(self, VisualizeGameState, OutVisualizationTracks);
}

function bool GetLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	return class'Helpers'.static.GetLootInternal(self, ItemRef, LooterRef, ModifyGameState);
}

function bool LeaveLoot(StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	return class'Helpers'.static.LeaveLootInternal(self, ItemRef, LooterRef, ModifyGameState);
}

function UpdateLootSparklesEnabled(bool bHighlightObject)
{
	XGUnit(GetVisualizer()).UpdateLootSparklesEnabled(bHighlightObject, self);
}

function array<StateObjectReference> GetAvailableLoot()
{
	return PendingLoot.AvailableLoot;
}

function AddLoot(StateObjectReference ItemRef, XComGameState ModifyGameState)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item Item;

	NewUnitState = XComGameState_Unit(ModifyGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	ModifyGameState.AddStateObject(NewUnitState);

	Item = XComGameState_Item(ModifyGameState.CreateStateObject(class'XComGameState_Item', ItemRef.ObjectID));
	ModifyGameState.AddStateObject(Item);

	NewUnitState.AddItemToInventory(Item, eInvSlot_Backpack, ModifyGameState);
}

function RemoveLoot(StateObjectReference ItemRef, XComGameState ModifyGameState)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item Item;

	NewUnitState = XComGameState_Unit(ModifyGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	ModifyGameState.AddStateObject(NewUnitState);

	Item = XComGameState_Item(ModifyGameState.CreateStateObject(class'XComGameState_Item', ItemRef.ObjectID));
	ModifyGameState.AddStateObject(Item);

	NewUnitState.RemoveItemFromInventory(Item, ModifyGameState);
}

function string GetLootingName()
{
	local string strName;

	if (strFirstName != "" || strLastName != "")
		strName = GetName(eNameType_Full);
	else
		strName = GetMyTemplate().strCharacterName;

	return strName;
}

simulated function TTile GetLootLocation()
{
	return TileLocation;
}

function SetLoot(const out LootResults NewLoot)
{
	if (bReadOnly)
	{
		`RedScreen("XComGameState_Unit::SetLoot - This cannot run on a read only object: " $ObjectID);
	}
	PendingLoot = NewLoot;
}

//  This should only be used when initially creating a unit, never after a unit has already been established with inventory.
function ApplyInventoryLoadout(XComGameState ModifyGameState, optional name NonDefaultLoadout)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local bool bFoundLoadout;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Item NewItem;
	local name UseLoadoutName, RequiredLoadout;
	local X2SoldierClassTemplate SoldierClassTemplate;

	if (NonDefaultLoadout != '')      
	{
		//  If loadout is specified, always use that.
		UseLoadoutName = NonDefaultLoadout;
	}
	else
	{
		//  If loadout was not specified, use the character template's default loadout, or the squaddie loadout for the soldier class (if any).
		UseLoadoutName = GetMyTemplate().DefaultLoadout;
		SoldierClassTemplate = GetSoldierClassTemplate();
		if (SoldierClassTemplate != none && SoldierClassTemplate.SquaddieLoadout != '')
			UseLoadoutName = SoldierClassTemplate.SquaddieLoadout;
	}

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if (Loadout.LoadoutName == UseLoadoutName)
		{
			bFoundLoadout = true;
			break;
		}
	}
	if (bFoundLoadout)
	{
		foreach Loadout.Items(LoadoutItem)
		{
			EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(LoadoutItem.Item));
			if (EquipmentTemplate != none)
			{
				NewItem = EquipmentTemplate.CreateInstanceFromTemplate(ModifyGameState);

				//Transfer settings that were configured in the character pool with respect to the weapon. Should only be applied here
				//where we are handing out generic weapons.
				if(EquipmentTemplate.InventorySlot == eInvSlot_PrimaryWeapon || EquipmentTemplate.InventorySlot == eInvSlot_SecondaryWeapon)
				{
					NewItem.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
					NewItem.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
				}

				AddItemToInventory(NewItem, EquipmentTemplate.InventorySlot, ModifyGameState);
				ModifyGameState.AddStateObject(NewItem);
			}
		}
	}
	//  Always apply the template's required loadout.
	RequiredLoadout = GetMyTemplate().RequiredLoadout;
	if (RequiredLoadout != '' && RequiredLoadout != UseLoadoutName && !HasLoadout(RequiredLoadout, ModifyGameState))
		ApplyInventoryLoadout(ModifyGameState, RequiredLoadout);

	// Give Kevlar armor if Unit's armor slot is empty
	if(IsASoldier() && GetItemInSlot(eInvSlot_Armor, ModifyGameState) == none)
	{
		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('KevlarArmor'));
		NewItem = EquipmentTemplate.CreateInstanceFromTemplate(ModifyGameState);
		AddItemToInventory(NewItem, eInvSlot_Armor, ModifyGameState);
		ModifyGameState.AddStateObject(NewItem);
	}
}

//  Called only when ranking up from rookie to squaddie. Applies items per configured loadout, safely removing
//  items and placing them back into HQ's inventory.
function ApplySquaddieLoadout(XComGameState GameState, optional XComGameState_HeadquartersXCom XHQ = none)
{
	local X2ItemTemplateManager ItemTemplateMan;
	local X2EquipmentTemplate ItemTemplate;
	local InventoryLoadout Loadout;
	local name SquaddieLoadout;
	local bool bFoundLoadout;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> UtilityItems;
	local int i;

	`assert(GameState != none);

	SquaddieLoadout = GetSoldierClassTemplate().SquaddieLoadout;
	ItemTemplateMan = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach ItemTemplateMan.Loadouts(Loadout)
	{
		if (Loadout.LoadoutName == SquaddieLoadout)
		{
			bFoundLoadout = true;
			break;
		}
	}
	if (bFoundLoadout)
	{
		for (i = 0; i < Loadout.Items.Length; ++i)
		{
			ItemTemplate = X2EquipmentTemplate(ItemTemplateMan.FindItemTemplate(Loadout.Items[i].Item));
			if (ItemTemplate != none)
			{
				ItemState = none;
				if (ItemTemplate.InventorySlot == eInvSlot_Utility)
				{
					//  If we can't add a utility item, remove the first one. That should fix it. If not, we may need more logic later.
					if (!CanAddItemToInventory(ItemTemplate, ItemTemplate.InventorySlot, GameState))
					{
						UtilityItems = GetAllItemsInSlot(ItemTemplate.InventorySlot, GameState);
						if (UtilityItems.Length > 0)
						{
							ItemState = UtilityItems[0];
						}
					}
				}
				else
				{
					//  If we can't add an item, there's probably one occupying the slot already, so remove it.
					if (!CanAddItemToInventory(ItemTemplate, ItemTemplate.InventorySlot, GameState))
					{
						ItemState = GetItemInSlot(ItemTemplate.InventorySlot, GameState);
					}
				}
				//  ItemState will be populated with an item we need to remove in order to place the new item in (if any).
				if (ItemState != none)
				{
					if (ItemState.GetMyTemplateName() == ItemTemplate.DataName)
						continue;
					if (!RemoveItemFromInventory(ItemState, GameState))
					{
						`RedScreen("Unable to remove item from inventory. Squaddie loadout will be affected." @ ItemState.ToString());
						continue;
					}

					if(XHQ != none)
					{
						XHQ.PutItemInInventory(GameState, ItemState);
					}
				}
				if (!CanAddItemToInventory(ItemTemplate, ItemTemplate.InventorySlot, GameState))
				{
					`RedScreen("Unable to add new item to inventory. Squaddie loadout will be affected." @ ItemTemplate.DataName);
					continue;
				}
				ItemState = ItemTemplate.CreateInstanceFromTemplate(GameState);

				//Transfer settings that were configured in the character pool with respect to the weapon. Should only be applied here
				//where we are handing out generic weapons.
				if(ItemTemplate.InventorySlot == eInvSlot_PrimaryWeapon || ItemTemplate.InventorySlot == eInvSlot_SecondaryWeapon)
				{
					ItemState.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
					ItemState.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
				}

				AddItemToInventory(ItemState, ItemTemplate.InventorySlot, GameState);
				GameState.AddStateObject(ItemState);
			}
			else
			{
				`RedScreen("Unknown item template" @ Loadout.Items[i].Item @ "specified in loadout" @ SquaddieLoadout);
			}
		}
	}

	// Give Kevlar armor if Unit's armor slot is empty
	if(IsASoldier() && GetItemInSlot(eInvSlot_Armor, GameState) == none)
	{
		ItemTemplate = X2EquipmentTemplate(ItemTemplateMan.FindItemTemplate('KevlarArmor'));
		ItemState = ItemTemplate.CreateInstanceFromTemplate(GameState);
		AddItemToInventory(ItemState, eInvSlot_Armor, GameState);
		GameState.AddStateObject(ItemState);
	}
}

//------------------------------------------------------
// Apply the best infinite armor, weapons, grenade, and utility items from the inventory
function ApplyBestGearLoadout(XComGameState NewGameState)
{
	local XComGameState_Item EquippedArmor, EquippedPrimaryWeapon, EquippedSecondaryWeapon; // Default slots
	local XComGameState_Item EquippedHeavyWeapon, EquippedGrenade, EquippedUtilityItem; // Special slots
	local array<XComGameState_Item> EquippedUtilityItems; // Utility Slots
	local array<X2ArmorTemplate> BestArmorTemplates;
	local array<X2WeaponTemplate> BestPrimaryWeaponTemplates, BestSecondaryWeaponTemplates, BestHeavyWeaponTemplates;
	local array<X2GrenadeTemplate> BestGrenadeTemplates;
	local array<X2EquipmentTemplate> BestUtilityTemplates;
	local int idx;
	
	// Armor Slot
	EquippedArmor = GetItemInSlot(eInvSlot_Armor, NewGameState);
	BestArmorTemplates = GetBestArmorTemplates();
	UpgradeEquipment(NewGameState, EquippedArmor, BestArmorTemplates, eInvSlot_Armor);

	// Primary Weapon Slot
	EquippedPrimaryWeapon = GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
	BestPrimaryWeaponTemplates = GetBestPrimaryWeaponTemplates();
 	UpgradeEquipment(NewGameState, EquippedPrimaryWeapon, BestPrimaryWeaponTemplates, eInvSlot_PrimaryWeapon);
	
	// Secondary Weapon Slot
	if (NeedsSecondaryWeapon())
	{
		EquippedSecondaryWeapon = GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState);
		BestSecondaryWeaponTemplates = GetBestSecondaryWeaponTemplates();
		UpgradeEquipment(NewGameState, EquippedSecondaryWeapon, BestSecondaryWeaponTemplates, eInvSlot_SecondaryWeapon);
	}

	// Heavy Weapon
	if (HasHeavyWeapon())
	{
		EquippedHeavyWeapon = GetItemInSlot(eInvSlot_HeavyWeapon, NewGameState);
		BestHeavyWeaponTemplates = GetBestHeavyWeaponTemplates();
		UpgradeEquipment(NewGameState, EquippedHeavyWeapon, BestHeavyWeaponTemplates, eInvSlot_HeavyWeapon);
	}

	// Grenade Pocket
	if (HasGrenadePocket())
	{
		EquippedGrenade = GetItemInSlot(eInvSlot_GrenadePocket, NewGameState);
		BestGrenadeTemplates = GetBestGrenadeTemplates();
		UpgradeEquipment(NewGameState, EquippedGrenade, BestGrenadeTemplates, eInvSlot_GrenadePocket);
	}

	// Utility Slot
	EquippedUtilityItems = GetAllItemsInSlot(eInvSlot_Utility, NewGameState, , true);
	BestUtilityTemplates = GetBestUtilityItemTemplates();
	for (idx = 0; idx < EquippedUtilityItems.Length; idx++)
	{
		EquippedUtilityItem = EquippedUtilityItems[idx];
		if (UpgradeEquipment(NewGameState, EquippedUtilityItem, BestUtilityTemplates, eInvSlot_Utility))
			break; // Only need to replace one utility item, so break if successful
	}

	// Always validate the loadout after upgrading everything
	ValidateLoadout(NewGameState);
}

//------------------------------------------------------
// Apply the best infinite armor, weapons, grenade, and utility items from the inventory
function array<X2EquipmentTemplate> GetBestGearForSlot(EInventorySlot Slot)
{
	local array<X2EquipmentTemplate> EmptyList;

	switch (Slot)
	{
	case eInvSlot_Armor:
		return GetBestArmorTemplates();
		break;
	case eInvSlot_PrimaryWeapon:
		return GetBestPrimaryWeaponTemplates();
		break;
	case eInvSlot_SecondaryWeapon:
		return GetBestSecondaryWeaponTemplates();
		break;
	case eInvSlot_HeavyWeapon:
		return GetBestHeavyWeaponTemplates();
		break;
	case eInvSlot_GrenadePocket:
		return GetBestGrenadeTemplates();
		break;
	case eInvSlot_Utility:
		return GetBestUtilityItemTemplates();
		break;
	}

	EmptyList.Length = 0;
	return EmptyList;
}

function bool UpgradeEquipment(XComGameState NewGameState, XComGameState_Item CurrentEquipment, array<X2EquipmentTemplate> UpgradeTemplates, EInventorySlot Slot, optional out XComGameState_Item UpgradeItem)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item EquippedItem;
	local X2EquipmentTemplate UpgradeTemplate;
	local int idx;

	if(UpgradeTemplates.Length == 0)
	{
		return false;
	}

	// Grab HQ Object
	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
	}
	
	if (CurrentEquipment == none)
	{
		// Make an instance of the best equipment we found and equip it
		UpgradeItem = UpgradeTemplates[0].CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(UpgradeItem);

		//Transfer weapon customization options. Should only be applied here when we are handing out generic weapons.
		if (Slot == eInvSlot_PrimaryWeapon || Slot == eInvSlot_SecondaryWeapon)
		{
			UpgradeItem.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
			UpgradeItem.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
		}
		
		return AddItemToInventory(UpgradeItem, Slot, NewGameState, (Slot == eInvSlot_Utility));
	}
	else
	{
		for(idx = 0; idx < UpgradeTemplates.Length; idx++)
		{
			UpgradeTemplate = UpgradeTemplates[idx];

			if(UpgradeTemplate.Tier > CurrentEquipment.GetMyTemplate().Tier)
			{
				if(X2WeaponTemplate(UpgradeTemplate) != none && X2WeaponTemplate(UpgradeTemplate).WeaponCat != X2WeaponTemplate(CurrentEquipment.GetMyTemplate()).WeaponCat)
				{
					continue;
				}

				// Remove the equipped item and put it back in HQ inventory
				EquippedItem = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', CurrentEquipment.ObjectID));
				NewGameState.AddStateObject(EquippedItem);
				RemoveItemFromInventory(EquippedItem, NewGameState);
				XComHQ.PutItemInInventory(NewGameState, EquippedItem);

				// Make an instance of the best equipment we found and equip it
				UpgradeItem = UpgradeTemplate.CreateInstanceFromTemplate(NewGameState);
				NewGameState.AddStateObject(UpgradeItem);
				
				//Transfer weapon customization options. Should only be applied here when we are handing out generic weapons.
				if (Slot == eInvSlot_PrimaryWeapon || Slot == eInvSlot_SecondaryWeapon)
				{
					UpgradeItem.WeaponAppearance.iWeaponTint = kAppearance.iWeaponTint;
					UpgradeItem.WeaponAppearance.nmWeaponPattern = kAppearance.nmWeaponPattern;
				}

				return AddItemToInventory(UpgradeItem, Slot, NewGameState);
			}
		}
	}

	return false;
}

//------------------------------------------------------
// After loadout change verify # of slots/valid items in slots
function ValidateLoadout(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item EquippedArmor, EquippedPrimaryWeapon, EquippedSecondaryWeapon; // Default slots
	local XComGameState_Item EquippedHeavyWeapon, EquippedGrenade, EquippedAmmo, UtilityItem; // Special slots
	local array<XComGameState_Item> EquippedUtilityItems; // Utility Slots
	local int idx;

	// Grab HQ Object
	History = `XCOMHISTORY;
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
	}

	// Armor Slot
	EquippedArmor = GetItemInSlot(eInvSlot_Armor, NewGameState);
	if(EquippedArmor == none)
	{
		EquippedArmor = GetDefaultArmor(NewGameState);
		AddItemToInventory(EquippedArmor, eInvSlot_Armor, NewGameState);
	}

	// Primary Weapon Slot
	EquippedPrimaryWeapon = GetItemInSlot(eInvSlot_PrimaryWeapon, NewGameState);
	if(EquippedPrimaryWeapon == none)
	{
		EquippedPrimaryWeapon = GetBestPrimaryWeapon(NewGameState);
		AddItemToInventory(EquippedPrimaryWeapon, eInvSlot_PrimaryWeapon, NewGameState);
	}

	// Check Ammo Item compatibility (utility slot)
	EquippedUtilityItems = GetAllItemsInSlot(eInvSlot_Utility, NewGameState, ,true);
	for(idx = 0; idx < EquippedUtilityItems.Length; idx++)
	{
		if(X2AmmoTemplate(EquippedUtilityItems[idx].GetMyTemplate()) != none && 
		   !X2AmmoTemplate(EquippedUtilityItems[idx].GetMyTemplate()).IsWeaponValidForAmmo(X2WeaponTemplate(EquippedPrimaryWeapon.GetMyTemplate())))
		{
			EquippedAmmo = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', EquippedUtilityItems[idx].ObjectID));
			NewGameState.AddStateObject(EquippedAmmo);
			RemoveItemFromInventory(EquippedAmmo, NewGameState);
			XComHQ.PutItemInInventory(NewGameState, EquippedAmmo);
			EquippedAmmo = none;
			EquippedUtilityItems.Remove(idx, 1);
			idx--;
		}
	}

	// Secondary Weapon Slot
	EquippedSecondaryWeapon = GetItemInSlot(eInvSlot_SecondaryWeapon, NewGameState);
	if(EquippedSecondaryWeapon == none && NeedsSecondaryWeapon())
	{
		EquippedSecondaryWeapon = GetBestSecondaryWeapon(NewGameState);
		AddItemToInventory(EquippedSecondaryWeapon, eInvSlot_SecondaryWeapon, NewGameState);
	}
	else if(EquippedSecondaryWeapon != none && !NeedsSecondaryWeapon())
	{
		EquippedSecondaryWeapon = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', EquippedSecondaryWeapon.ObjectID));
		NewGameState.AddStateObject(EquippedSecondaryWeapon);
		RemoveItemFromInventory(EquippedSecondaryWeapon, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedSecondaryWeapon);
		EquippedSecondaryWeapon = none;
	}

	// Heavy Weapon Slot
	EquippedHeavyWeapon = GetItemInSlot(eInvSlot_HeavyWeapon, NewGameState);
	if(EquippedHeavyWeapon == none && HasHeavyWeapon(NewGameState))
	{
		EquippedHeavyWeapon = GetBestHeavyWeapon(NewGameState);
		AddItemToInventory(EquippedHeavyWeapon, eInvSlot_HeavyWeapon, NewGameState);
	}
	else if(EquippedHeavyWeapon != none && !HasHeavyWeapon(NewGameState))
	{
		EquippedHeavyWeapon = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', EquippedHeavyWeapon.ObjectID));
		NewGameState.AddStateObject(EquippedHeavyWeapon);
		RemoveItemFromInventory(EquippedHeavyWeapon, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedHeavyWeapon);
		EquippedHeavyWeapon = none;
	}

	// Grenade Pocket
	EquippedGrenade = GetItemInSlot(eInvSlot_GrenadePocket, NewGameState);
	if(EquippedGrenade == none && HasGrenadePocket())
	{
		EquippedGrenade = GetBestGrenade(NewGameState);
		AddItemToInventory(EquippedGrenade, eInvSlot_GrenadePocket, NewGameState);
	}
	else if(EquippedGrenade != none && !HasGrenadePocket())
	{
		EquippedGrenade = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', EquippedGrenade.ObjectID));
		NewGameState.AddStateObject(EquippedGrenade);
		RemoveItemFromInventory(EquippedGrenade, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, EquippedGrenade);
		EquippedGrenade = none;
	}

	// UtilitySlots (Already grabbed equipped)
	if(!IsMPCharacter())
	{
		if(X2ArmorTemplate(EquippedArmor.GetMyTemplate()).bAddsUtilitySlot)
		{
			SetBaseMaxStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems] + 1.0f);
			SetCurrentStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems] + 1.0f);
		}
		else
		{
			SetBaseMaxStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems]);
			SetCurrentStat(eStat_UtilityItems, GetMyTemplate().CharacterBaseStats[eStat_UtilityItems]);
		}
	}

	// Remove Extra Utility Items
	for(idx = GetCurrentStat(eStat_UtilityItems); idx < EquippedUtilityItems.Length; idx++)
	{
		if(idx >= EquippedUtilityItems.Length)
		{
			break;
		}

		UtilityItem = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', EquippedUtilityItems[idx].ObjectID));
		NewGameState.AddStateObject(UtilityItem);
		RemoveItemFromInventory(UtilityItem, NewGameState);
		XComHQ.PutItemInInventory(NewGameState, UtilityItem);
		UtilityItem = none;
		EquippedUtilityItems.Remove(idx, 1);
		idx--;
	}

	// Equip Default Utility Item in first slot if needed
	while(EquippedUtilityItems.Length < 1 && GetCurrentStat(eStat_UtilityItems) > 0)
	{
		UtilityItem = GetBestUtilityItem(NewGameState);
		AddItemToInventory(UtilityItem, eInvSlot_Utility, NewGameState);
		EquippedUtilityItems.AddItem(UtilityItem);
	}
}

//------------------------------------------------------
function XComGameState_Item GetDefaultArmor(XComGameState NewGameState)
{
	local array<X2ArmorTemplate> ArmorTemplates;
	local XComGameState_Item ItemState;

	ArmorTemplates = GetBestArmorTemplates();

	if (ArmorTemplates.Length == 0)
	{
		return none;
	}

	ItemState = ArmorTemplates[`SYNC_RAND(ArmorTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);
	
	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestPrimaryWeapon(XComGameState NewGameState)
{
	local array<X2WeaponTemplate> PrimaryWeaponTemplates;
	local XComGameState_Item ItemState;

	PrimaryWeaponTemplates = GetBestPrimaryWeaponTemplates();

	if (PrimaryWeaponTemplates.Length == 0)
	{
		return none;
	}
	
	ItemState = PrimaryWeaponTemplates[`SYNC_RAND(PrimaryWeaponTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);
	
	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestSecondaryWeapon(XComGameState NewGameState)
{
	local array<X2WeaponTemplate> SecondaryWeaponTemplates;
	local XComGameState_Item ItemState;

	SecondaryWeaponTemplates = GetBestSecondaryWeaponTemplates();

	if (SecondaryWeaponTemplates.Length == 0)
	{
		return none;
	}

	ItemState = SecondaryWeaponTemplates[`SYNC_RAND(SecondaryWeaponTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);
	
	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestHeavyWeapon(XComGameState NewGameState)
{
	local array<X2WeaponTemplate> HeavyWeaponTemplates;
	local XComGameState_Item ItemState;

	HeavyWeaponTemplates = GetBestHeavyWeaponTemplates();

	if(HeavyWeaponTemplates.Length == 0)
	{
		return none;
	}
	
	ItemState = HeavyWeaponTemplates[`SYNC_RAND(HeavyWeaponTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);

	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestGrenade(XComGameState NewGameState)
{
	local array<X2GrenadeTemplate> GrenadeTemplates;
	local XComGameState_Item ItemState;

	GrenadeTemplates = GetBestGrenadeTemplates();

	if(GrenadeTemplates.Length == 0)
	{
		return none;
	}

	ItemState = GrenadeTemplates[`SYNC_RAND(GrenadeTemplates.Length)].CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);

	return ItemState;
}

//------------------------------------------------------
function XComGameState_Item GetBestUtilityItem(XComGameState NewGameState)
{
	local array<X2EquipmentTemplate> UtilityItemTemplates;
	local XComGameState_Item ItemState;

	UtilityItemTemplates = GetBestUtilityItemTemplates();

	if (UtilityItemTemplates.Length == 0)
	{
		return none;
	}

	ItemState = X2WeaponTemplate(UtilityItemTemplates[`SYNC_RAND(UtilityItemTemplates.Length)]).CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);
	
	return ItemState;
}

//------------------------------------------------------
function array<X2ArmorTemplate> GetBestArmorTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2ArmorTemplate ArmorTemplate, BestArmorTemplate;
	local array<X2ArmorTemplate> BestArmorTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default armor template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		BestArmorTemplate = X2ArmorTemplate(DefaultEquipment[idx]);
		if (BestArmorTemplate != none)
		{
			BestArmorTemplates.AddItem(BestArmorTemplate);
			HighestTier = BestArmorTemplate.Tier;
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better armor as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			ArmorTemplate = X2ArmorTemplate(ItemState.GetMyTemplate());

			if (ArmorTemplate != none && ArmorTemplate.bInfiniteItem && (BestArmorTemplate == none || 
				(BestArmorTemplates.Find(ArmorTemplate) == INDEX_NONE && ArmorTemplate.Tier >= BestArmorTemplate.Tier))
				&& GetSoldierClassTemplate().IsArmorAllowedByClass(ArmorTemplate))
			{
				BestArmorTemplate = ArmorTemplate;
				BestArmorTemplates.AddItem(ArmorTemplate);
				HighestTier = BestArmorTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestArmorTemplates.Length; idx++)
	{
		if(BestArmorTemplates[idx].Tier < HighestTier)
		{
			BestArmorTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestArmorTemplates;
}

//------------------------------------------------------
function array<X2WeaponTemplate> GetBestPrimaryWeaponTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2WeaponTemplate WeaponTemplate, BestWeaponTemplate;
	local array<X2WeaponTemplate> BestWeaponTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default primary weapon template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		if (X2WeaponTemplate(DefaultEquipment[idx]) != none && DefaultEquipment[idx].InventorySlot == eInvSlot_PrimaryWeapon)
		{
			BestWeaponTemplate = X2WeaponTemplate(DefaultEquipment[idx]);
			BestWeaponTemplates.AddItem(BestWeaponTemplate);
			HighestTier = BestWeaponTemplate.Tier;
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better primary weapon as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

			if (WeaponTemplate != none && WeaponTemplate.bInfiniteItem && (BestWeaponTemplate == none || (BestWeaponTemplates.Find(WeaponTemplate) == INDEX_NONE && WeaponTemplate.Tier >= BestWeaponTemplate.Tier)) && 
				WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon && GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate))
			{
				BestWeaponTemplate = WeaponTemplate;
				BestWeaponTemplates.AddItem(BestWeaponTemplate);
				HighestTier = BestWeaponTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestWeaponTemplates.Length; idx++)
	{
		if(BestWeaponTemplates[idx].Tier < HighestTier)
		{
			BestWeaponTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestWeaponTemplates;
}

//------------------------------------------------------
function array<X2WeaponTemplate> GetBestSecondaryWeaponTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2WeaponTemplate WeaponTemplate, BestWeaponTemplate;
	local array<X2WeaponTemplate> BestWeaponTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default secondary weapon template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		if (X2WeaponTemplate(DefaultEquipment[idx]) != none && DefaultEquipment[idx].InventorySlot == eInvSlot_SecondaryWeapon)
		{
			BestWeaponTemplate = X2WeaponTemplate(DefaultEquipment[idx]);
			BestWeaponTemplates.AddItem(BestWeaponTemplate);
			HighestTier = BestWeaponTemplate.Tier;
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better secondary weapon as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

			if(WeaponTemplate != none && WeaponTemplate.bInfiniteItem && (BestWeaponTemplate == none || (BestWeaponTemplates.Find(WeaponTemplate) == INDEX_NONE && WeaponTemplate.Tier >= BestWeaponTemplate.Tier)) &&
				WeaponTemplate.InventorySlot == eInvSlot_SecondaryWeapon && GetSoldierClassTemplate().IsWeaponAllowedByClass(WeaponTemplate))
			{
				BestWeaponTemplate = WeaponTemplate;
				BestWeaponTemplates.AddItem(BestWeaponTemplate);
				HighestTier = BestWeaponTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestWeaponTemplates.Length; idx++)
	{
		if(BestWeaponTemplates[idx].Tier < HighestTier)
		{
			BestWeaponTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestWeaponTemplates;
}

//------------------------------------------------------
function array<X2WeaponTemplate> GetBestHeavyWeaponTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2WeaponTemplate HeavyWeaponTemplate, BestHeavyWeaponTemplate;
	local array<X2WeaponTemplate> BestHeavyWeaponTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default heavy weapon template
	BestHeavyWeaponTemplate = X2WeaponTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Item_HeavyWeapons'.default.FreeHeavyWeaponToEquip));
	BestHeavyWeaponTemplates.AddItem(BestHeavyWeaponTemplate);
	HighestTier = BestHeavyWeaponTemplate.Tier;

	if( XComHQ != none )
	{
		// Try to find a better grenade as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			HeavyWeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());

			if(HeavyWeaponTemplate != none && HeavyWeaponTemplate.bInfiniteItem && (BestHeavyWeaponTemplate == none || 
				(BestHeavyWeaponTemplates.Find(HeavyWeaponTemplate) == INDEX_NONE && HeavyWeaponTemplate.Tier >= BestHeavyWeaponTemplate.Tier)) &&
				HeavyWeaponTemplate.InventorySlot == eInvSlot_HeavyWeapon && GetSoldierClassTemplate().IsWeaponAllowedByClass(HeavyWeaponTemplate))
			{
				BestHeavyWeaponTemplate = HeavyWeaponTemplate;
				BestHeavyWeaponTemplates.AddItem(BestHeavyWeaponTemplate);
				HighestTier = BestHeavyWeaponTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestHeavyWeaponTemplates.Length; idx++)
	{
		if(BestHeavyWeaponTemplates[idx].Tier < HighestTier)
		{
			BestHeavyWeaponTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestHeavyWeaponTemplates;
}

//------------------------------------------------------
function array<X2GrenadeTemplate> GetBestGrenadeTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2GrenadeTemplate GrenadeTemplate, BestGrenadeTemplate;
	local array<X2GrenadeTemplate> BestGrenadeTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default grenade template
	BestGrenadeTemplate = X2GrenadeTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(class'X2Ability_GrenadierAbilitySet'.default.FreeGrenadeForPocket));
	BestGrenadeTemplates.AddItem(BestGrenadeTemplate);
	HighestTier = BestGrenadeTemplate.Tier;

	if( XComHQ != none )
	{
		// Try to find a better grenade as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			GrenadeTemplate = X2GrenadeTemplate(ItemState.GetMyTemplate());

			if(GrenadeTemplate != none && GrenadeTemplate.bInfiniteItem && (BestGrenadeTemplate == none || (BestGrenadeTemplates.Find(GrenadeTemplate) == INDEX_NONE && GrenadeTemplate.Tier >= BestGrenadeTemplate.Tier)))
			{
				BestGrenadeTemplate = GrenadeTemplate;
				BestGrenadeTemplates.AddItem(BestGrenadeTemplate);
				HighestTier = BestGrenadeTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestGrenadeTemplates.Length; idx++)
	{
		if(BestGrenadeTemplates[idx].Tier < HighestTier)
		{
			BestGrenadeTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestGrenadeTemplates;
}

//------------------------------------------------------
function array<X2EquipmentTemplate> GetBestUtilityItemTemplates()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2EquipmentTemplate> DefaultEquipment;
	local X2EquipmentTemplate UtilityTemplate, BestUtilityTemplate;
	local array<X2EquipmentTemplate> BestUtilityTemplates;
	local XComGameState_Item ItemState;
	local int idx, HighestTier;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// First get the default utility template
	DefaultEquipment = GetCompleteDefaultLoadout();
	for (idx = 0; idx < DefaultEquipment.Length; idx++)
	{
		if (DefaultEquipment[idx].InventorySlot == eInvSlot_Utility)
		{
			BestUtilityTemplate = DefaultEquipment[idx];
			BestUtilityTemplates.AddItem(BestUtilityTemplate);
			HighestTier = BestUtilityTemplate.Tier;
			break;
		}
	}

	if( XComHQ != none )
	{
		// Try to find a better utility item as an infinite item in the inventory
		for (idx = 0; idx < XComHQ.Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[idx].ObjectID));
			UtilityTemplate = X2EquipmentTemplate(ItemState.GetMyTemplate());

			if(UtilityTemplate != none && UtilityTemplate.bInfiniteItem && (BestUtilityTemplate == none || (BestUtilityTemplates.Find(UtilityTemplate) == INDEX_NONE && UtilityTemplate.Tier >= BestUtilityTemplate.Tier))
			   && UtilityTemplate.InventorySlot == eInvSlot_Utility)
			{
				BestUtilityTemplate = UtilityTemplate;
				BestUtilityTemplates.AddItem(BestUtilityTemplate);
				HighestTier = BestUtilityTemplate.Tier;
			}
		}
	}

	for(idx = 0; idx < BestUtilityTemplates.Length; idx++)
	{
		if(BestUtilityTemplates[idx].Tier < HighestTier)
		{
			BestUtilityTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return BestUtilityTemplates;
}

//------------------------------------------------------
function bool NeedsSecondaryWeapon()
{
	return GetRank() > 0;
}

//------------------------------------------------------
// Clear the loadout and remove the item game states (used in Debug Strategy)
function BlastLoadout(XComGameState ModifyGameState)
{
	local int idx;

	for(idx = 0; idx < InventoryItems.Length; idx++)
	{
		ModifyGameState.RemoveStateObject(InventoryItems[idx].ObjectID);
	}

	InventoryItems.Length = 0;
}

//  This is for clearing the list out after the unit's inventory has been converted into a soldier kit, none of the items should be destroyed.
function EmptyInventoryItems()
{
	InventoryItems.Length = 0;
}

// Makes this soldiers items available, but stores references to those items so they can attempt to reequip them
function MakeItemsAvailable(XComGameState NewGameState, optional bool bStoreOldItems = true, optional array<EInventorySlot> SlotsToClear)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> AllItems;
	local EInventorySlot eSlot;
	local EquipmentInfo OldEquip;
	local int idx;
	local bool bClearAll;

	History = `XCOMHISTORY;
	bClearAll = (SlotsToClear.Length == 0);

	// Grab HQ Object
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
	}

	// Remove all items, store references to them, and place in HQ inventory
	AllItems = GetAllInventoryItems(NewGameState, true);

	for(idx = 0; idx <AllItems.Length; idx++)
	{
		eSlot = AllItems[idx].InventorySlot;
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(AllItems[idx].ObjectID));

		if(bClearAll || SlotsToClear.Find(eSlot) != INDEX_NONE)
		{
			ItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', ItemState.ObjectID));
			NewGameState.AddStateObject(ItemState);

			if(CanRemoveItemFromInventory(ItemState, NewGameState))
			{
				RemoveItemFromInventory(ItemState, NewGameState);

				if(bStoreOldItems)
				{
					OldEquip.EquipmentRef = ItemState.GetReference();
					OldEquip.eSlot = eSlot;
					OldInventoryItems.AddItem(OldEquip);
				}
				
				XComHQ.PutItemInInventory(NewGameState, ItemState);
			}
		}
	}

	// Equip required loadout if needed
	if(GetMyTemplate().RequiredLoadout != '' && !HasLoadout(GetMyTemplate().RequiredLoadout, NewGameState))
	{
		ApplyInventoryLoadout(NewGameState, GetMyTemplate().RequiredLoadout);
	}

	ApplyBestGearLoadout(NewGameState);
}

// Combines rookie and squaddie loadouts so that things like kevlar armor and grenades are included
private function array<X2EquipmentTemplate> GetCompleteDefaultLoadout()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local InventoryLoadout Loadout;
	local InventoryLoadoutItem LoadoutItem;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<X2EquipmentTemplate> CompleteDefaultLoadout;
	local bool bCanAdd;
	local int idx;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// First grab squaddie loadout if possible
	SoldierClassTemplate = GetSoldierClassTemplate();

	if(SoldierClassTemplate != none && SoldierClassTemplate.SquaddieLoadout != '')
	{
		foreach ItemTemplateManager.Loadouts(Loadout)
		{
			if(Loadout.LoadoutName == SoldierClassTemplate.SquaddieLoadout)
			{
				foreach Loadout.Items(LoadoutItem)
				{
					EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(LoadoutItem.Item));

					if(EquipmentTemplate != none)
					{
						CompleteDefaultLoadout.AddItem(EquipmentTemplate);
					}
				}

				break;
			}
		}
	}

	// Next grab default loadout
	foreach ItemTemplateManager.Loadouts(Loadout)
	{
		if(Loadout.LoadoutName == GetMyTemplate().DefaultLoadout)
		{
			foreach Loadout.Items(LoadoutItem)
			{
				EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate(LoadoutItem.Item));

				if(EquipmentTemplate != none)
				{
					bCanAdd = true;
					for(idx = 0; idx < CompleteDefaultLoadout.Length; idx++)
					{
						if(EquipmentTemplate.InventorySlot == CompleteDefaultLoadout[idx].InventorySlot)
						{
							bCanAdd = false;
							break;
						}
					}

					if(bCanAdd)
					{
						CompleteDefaultLoadout.AddItem(EquipmentTemplate);
					}
				}
			}

			break;
		}
	}

	return CompleteDefaultLoadout;
}

// Equip old items (after recovering from an injury, etc.)
function EquipOldItems(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState, InvItemState;
	local array<XComGameState_Item> UtilityItems;
	local X2EquipmentTemplate ItemTemplate;
	local int idx, InvIndex;

	History = `XCOMHISTORY;

	if(OldInventoryItems.Length == 0)
	{
		return;
	}

	// Sort the old inventory items (armors need to be equipped first)
	OldInventoryItems.Sort(SortOldEquipment);

	// Grab HQ Object
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
	}

	// Try to find old items
	for(idx = 0; idx < OldInventoryItems.Length; idx++)
	{
		ItemState = none;
		InvIndex = XComHQ.Inventory.Find('ObjectID', OldInventoryItems[idx].EquipmentRef.ObjectID);

		if(InvIndex != INDEX_NONE)
		{
			// Found the actual item
			XComHQ.GetItemFromInventory(NewGameState, XComHQ.Inventory[InvIndex], InvItemState);
		}
		else
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(OldInventoryItems[idx].EquipmentRef.ObjectID));

			// Try to find an unmodified item with the same template
			for(InvIndex = 0; InvIndex < XComHQ.Inventory.Length; InvIndex++)
			{
				InvItemState = XComGameState_Item(History.GetGameStateForObjectID(XComHQ.Inventory[InvIndex].ObjectID));

				if(InvItemState != none && !InvItemState.HasBeenModified() && InvItemState.GetMyTemplateName() == ItemState.GetMyTemplateName())
				{
					XComHQ.GetItemFromInventory(NewGameState, XComHQ.Inventory[InvIndex], InvItemState);
					break;
				}

				InvItemState = none;
			}
		}

		if(InvItemState != none)
		{
			if(XComGameState_Item(NewGameState.GetGameStateForObjectID(InvItemState.ObjectID)) == none)
			{
				InvItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', InvItemState.ObjectID));
				NewGameState.AddStateObject(InvItemState);
			}

			ItemTemplate = X2EquipmentTemplate(InvItemState.GetMyTemplate());
			if(ItemTemplate != none)
			{
				ItemState = none;

				if(OldInventoryItems[idx].eSlot == eInvSlot_Utility)
				{
					if(!CanAddItemToInventory(ItemTemplate, OldInventoryItems[idx].eSlot, NewGameState))
					{
						UtilityItems = GetAllItemsInSlot(eInvSlot_Utility, NewGameState, , true);

						ItemState = UtilityItems[UtilityItems.Length - 1];
					}
				}
				else
				{
					//  If we can't add an item, there's probably one occupying the slot already, so remove it.
					if(!CanAddItemToInventory(ItemTemplate, OldInventoryItems[idx].eSlot, NewGameState))
					{
						ItemState = GetItemInSlot(OldInventoryItems[idx].eSlot, NewGameState);
					}
				}

				//  ItemState will be populated with an item we need to remove in order to place the new item in (if any).
				if(ItemState != none)
				{
					if(XComGameState_Item(NewGameState.GetGameStateForObjectID(ItemState.ObjectID)) == none)
					{
						ItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', ItemState.ObjectID));
						NewGameState.AddStateObject(ItemState);
					}

					if(!RemoveItemFromInventory(ItemState, NewGameState))
					{
						XComHQ.PutItemInInventory(NewGameState, InvItemState);
						continue;
					}

					XComHQ.PutItemInInventory(NewGameState, ItemState);
				}

				if(!CanAddItemToInventory(ItemTemplate, OldInventoryItems[idx].eSlot, NewGameState))
				{
					XComHQ.PutItemInInventory(NewGameState, InvItemState);
					continue;
				}

				if(ItemTemplate.IsA('X2WeaponTemplate'))
				{
					if(ItemTemplate.InventorySlot == eInvSlot_PrimaryWeapon)
						InvItemState.ItemLocation = eSlot_RightHand;
					else
						InvItemState.ItemLocation = X2WeaponTemplate(ItemTemplate).StowedLocation;
				}

				AddItemToInventory(InvItemState, OldInventoryItems[idx].eSlot, NewGameState);
			}
		}
	}

	OldInventoryItems.Length = 0;
	ApplyBestGearLoadout(NewGameState);
}

private function int SortOldEquipment(EquipmentInfo OldEquipA, EquipmentInfo OldEquipB)
{
	return (int(OldEquipB.eSlot) - int(OldEquipA.eSlot));
}


//------------------------------------------------------
// A ham handed way of ensuring that we don't double up on names
static function NameCheck( XGCharacterGenerator CharGen, XComGameState_Unit Soldier, ENameType NameType )
{
	local int iCounter;
	local string FirstName;
	local string LastName;

	iCounter = 10;

	while( NameMatch(Soldier, NameType) && iCounter > 0 )
	{
		FirstName = Soldier.GetFirstName();
		LastName = Soldier.GetLastName();
		CharGen.GenerateName( Soldier.kAppearance.iGender, Soldier.GetCountry(), FirstName, LastName, Soldier.kAppearance.iRace );
		iCounter--;
	}
}

//------------------------------------------------------
static function bool NameMatch( XComGameState_Unit Soldier, ENameType NameType )
{
	local XComGameState_Unit OtherSoldier;
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', OtherSoldier, eReturnType_Reference)
	{
		if( Soldier == OtherSoldier )
			continue;
		if( OtherSoldier.GetName(NameType) == Soldier.GetName(NameType) )
			return true;
	}

	return false;
}


function string Stat_ToString(const out CharacterStat Stat)
{
	local String Str;
	Str = `ShowEnum(ECharStatType, Stat.Type, Type) @ `ShowVar(Stat.CurrentValue, CurrentValue) @ `ShowVar(Stat.BaseMaxValue, BaseMaxValue) @ `ShowVar(Stat.MaxValue, MaxValue);
	return Str;
}

function string CharacterStats_ToString()
{
	local string Str;
	local int i;

	for (i = 0; i < eStat_MAX; ++i)
	{
		Str $= Stat_ToString(CharacterStats[i]) $ "\n";
	}
	return Str;
}


function bool HasSeenCorpse( int iCorpseID )
{
	local XComGameState_AIUnitData AIGameState;
	local int AIUnitDataID;
	AIUnitDataID = GetAIUnitDataID();
	if( AIUnitDataID > 0 )
	{
		AIGameState = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(AIUnitDataID));
		return AIGameState.HasSeenCorpse(iCorpseID);
	}
	return false;
}

function MarkCorpseSeen(int CorpseID)
{
	local int AIUnitDataID;
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule NewContext;

	History = `XCOMHISTORY;
	AIUnitDataID = GetAIUnitDataID();
	if( AIUnitDataID > 0 && CorpseID > 0 )
	{
		`logAI("Marking Corpse#"$CorpseID@"seen to AI #" $ ObjectID);
		NewContext = class'XComGameStateContext_TacticalGameRule'.static.BuildContextFromGameRule(eGameRule_MarkCorpseSeen);
		NewContext.AIRef = History.GetGameStateForObjectID(AIUnitDataID).GetReference();
		NewContext.UnitRef = History.GetGameStateForObjectID(CorpseID).GetReference();
		`XCOMGAME.GameRuleset.SubmitGameStateContext(NewContext);
	}
}

function int GetNumVisibleEnemyUnits( bool bAliveOnly=true, bool bBreakOnAnyHits=false, bool bIncludeUnspotted=false, int HistoryIndex=-1, bool bIncludeIncapacitated=false, bool bIncludeCosmetic=false )
{
	local int NumVisibleEnemies;
	local array<StateObjectReference> VisibleUnits;
	local StateObjectReference kObjRef;
	local XComGameState_Unit kEnemy;
	local bool bSpottedOnly;
	if (!bIncludeUnspotted && ControllingPlayerIsAI())
	{
		bSpottedOnly = true;
	}

	NumVisibleEnemies = 0;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(ObjectID, VisibleUnits);
	foreach VisibleUnits(kObjRef)
	{
		kEnemy = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kObjRef.ObjectID, , HistoryIndex));
		if (kEnemy != None && kEnemy.IsAlive() && (!bSpottedOnly || kEnemy.IsSpotted()))
		{
			if(   ( !bIncludeIncapacitated && kEnemy.IsIncapacitated() )
			   || ( !bIncludeCosmetic && kEnemy.GetMyTemplate().bIsCosmetic ) )
			{
				continue;
			}

			NumVisibleEnemies++; 
			if (bBreakOnAnyHits)
				break;// In case we want to just return 1 if any visible enemies.
		}
	}
	return NumVisibleEnemies;
}

function ApplyTraversalChanges(const X2Effect_PersistentTraversalChange TraversalChange)
{
	local int i;

	for (i = 0; i < TraversalChange.aTraversalChanges.Length; ++i)
	{
		TraversalChanges.AddItem(TraversalChange.aTraversalChanges[i]);
	}
	UpdateTraversals();
}

function UnapplyTraversalChanges(const X2Effect_PersistentTraversalChange TraversalChange)
{
	local int i, j;

	for (i = 0; i < TraversalChange.aTraversalChanges.Length; ++i)
	{
		for (j = 0; j < TraversalChanges.Length; ++j)
		{
			if (TraversalChanges[j].Traversal == TraversalChange.aTraversalChanges[i].Traversal)
			{
				if (TraversalChanges[j].bAllowed == TraversalChange.aTraversalChanges[i].bAllowed)
				{
					TraversalChanges.Remove(j, 1);
					break;
				}
			}
		}
	}
	UpdateTraversals();
}

function UpdateTraversals()
{
	local int i, j;
	local bool EffectAllows, EffectDisallows;
	
	ResetTraversals();

	if (TraversalChanges.Length > 0)
	{
		for (i = eTraversal_Normal; i < eTraversal_Unreachable; ++i)
		{
			EffectAllows = false;
			EffectDisallows = false;
			for (j = 0; j < TraversalChanges.Length; ++j)
			{
				if (TraversalChanges[j].Traversal == i)
				{
					if (TraversalChanges[j].bAllowed)
					{
						//  if an effect allows the traversal, it will be enabled as long as no other effect disallows it
						EffectAllows = true;
					}
					else
					{
						//  if an effect disallows the traversal, it will be disabled
						EffectDisallows = true;
						break;
					}
				}
			}
			if (EffectDisallows)
				aTraversals[i] = 0;
			else if (EffectAllows)
				aTraversals[i] = 1;
		}
	}
}

function SetSoldierProgression(const out array<SCATProgression> Progression)
{
	m_SoldierProgressionAbilties = Progression;
}

//  returns the amount of excess xp that was wasted by not being able to rank up more than once
function int AddXp(int Delta)
{
	local int NewXp, RankXp, ExcessXp;

	NewXp = m_iXp + Delta;

	if (m_SoldierRank + 2 < `GET_MAX_RANK)
	{
		//  a soldier cannot gain enough xp to gain 2 levels at the end of one mission, so restrict xp to just below that amount
		RankXp = class'X2ExperienceConfig'.static.GetRequiredXp(m_SoldierRank + 2) - 1;
	}
	else
	{
		//  don't let a soldier accumulate xp beyond max rank
		RankXp = class'X2ExperienceConfig'.static.GetRequiredXp(`GET_MAX_RANK);		
	}
	RankXp = max(RankXp, 0);
	if (NewXp > RankXp)
	{
		ExcessXp = NewXp - RankXp;
		NewXp = RankXp;
	}
	m_iXp = NewXp;
	m_iXp = max(m_iXp, 0);

	return ExcessXp;
}

function SetXPForRank(int SoldierRank)
{
	m_iXp = class'X2ExperienceConfig'.static.GetRequiredXp(SoldierRank);
}

function int GetXPValue()
{
	return m_iXp;
}

function bool CanRankUpSoldier()
{
	local int NumKills;

	if (m_SoldierRank + 1 < `GET_MAX_RANK && !bRankedUp)
	{
		NumKills = GetNumKills();

		//  Increase kills for WetWork bonus if appropriate
		NumKills += Round(WetWorkKills * class'X2ExperienceConfig'.default.NumKillsBonus);
		
		//  Add number of kills from assists
		NumKills += GetNumKillsFromAssists();

		// Add required kills of StartingRank
		NumKills += class'X2ExperienceConfig'.static.GetRequiredKills(StartingRank);

		//  Check required xp if that system is enabled
		if (class'X2ExperienceConfig'.default.bUseFullXpSystem)
		{
			if (m_iXp < class'X2ExperienceConfig'.static.GetRequiredXp(m_SoldierRank + 1))
				return false;
		}

		if ( NumKills >= class'X2ExperienceConfig'.static.GetRequiredKills(m_SoldierRank + 1)
			&& (GetStatus() != eStatus_PsiTesting && GetStatus() != eStatus_Training) 
			&& !GetSoldierClassTemplate().bBlockRankingUp)
			return true;
	}

	return false;
}

function RankUpSoldier(XComGameState NewGameState, optional name SoldierClass, optional bool bRecoveredFromBadClassData)
{
	local X2SoldierClassTemplate Template;
	local int RankIndex, i, MaxStat, NewMaxStat, StatVal;
	local bool bInjured;
	local array<SoldierClassStatType> StatProgression;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<SoldierClassAbilityType> AbilityTree;
	
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	bInjured = IsInjured();

	if (!class'X2ExperienceConfig'.default.bUseFullXpSystem)
		bRankedUp = true;

	RankIndex = m_SoldierRank;
	if (m_SoldierRank == 0)
	{
		if(SoldierClass == '')
		{
			`RedScreen("Invalid SoldierClass passed into RankUpSoldier function. This might break class assignment, please inform sbatista and provide a save.\n\n" $ GetScriptTrace());
			SoldierClass = XComHQ.SelectNextSoldierClass();
		}

		SetSoldierClassTemplate(SoldierClass);
		
		if (GetSoldierClassTemplateName() == 'PsiOperative')
		{
			RollForPsiAbilities();

			// Adjust the soldiers appearance to have white hair and purple eyes - not permanent
			kAppearance.iHairColor = 25;
			kAppearance.iEyeColor = 19;
		}
		else
		{
			// Add new Squaddie abilities to the Unit if they aren't a Psi Op
			AbilityTree = GetSoldierClassTemplate().GetAbilityTree(0);
			for (i = 0; i < AbilityTree.Length; ++i)
			{
				BuySoldierProgressionAbility(NewGameState, 0, i);
			}

			bNeedsNewClassPopup = true;
		}
	}
	
	Template = GetSoldierClassTemplate();
	
	// Attempt to recover from having an invalid class
	if(Template == none)
	{
		`RedScreen("Invalid ClassTemplate detected, this unit has been reset to Rookie and given a new promotion. Please inform sbatista and provide a save.\n\n" $ GetScriptTrace());
		ResetRankToRookie();

		// This check prevents an infinite loop in case a valid class is not found
		if(!bRecoveredFromBadClassData)
		{
			RankUpSoldier(NewGameState, XComHQ.SelectNextSoldierClass(), true);
			return;
		}
	}

	if (RankIndex >= 0 && RankIndex < Template.GetMaxConfiguredRank())
	{
		m_SoldierRank++;

		StatProgression = Template.GetStatProgression(RankIndex);
		if (m_SoldierRank > 0)
		{
			for (i = 0; i < class'X2SoldierClassTemplateManager'.default.GlobalStatProgression.Length; ++i)
			{
				StatProgression.AddItem(class'X2SoldierClassTemplateManager'.default.GlobalStatProgression[i]);
			}
		}

		for (i = 0; i < StatProgression.Length; ++i)
		{
			StatVal = StatProgression[i].StatAmount;
			//  add random amount if any
			if (StatProgression[i].RandStatAmount > 0)
			{
				StatVal += `SYNC_RAND(StatProgression[i].RandStatAmount);
			}
			MaxStat = GetMaxStat(StatProgression[i].StatType);
			//  cap the new value if required
			if (StatProgression[i].CapStatAmount > 0)
			{
				if (StatVal + MaxStat > StatProgression[i].CapStatAmount)
					StatVal = StatProgression[i].CapStatAmount - MaxStat;
			}

			// If the Soldier has been shaken, save any will bonus from ranking up to be applied when they recover
			if (StatProgression[i].StatType == eStat_Will && bIsShaken)
			{
				SavedWillValue += StatVal;
			}
			else
			{				
				NewMaxStat = MaxStat + StatVal;
				SetBaseMaxStat(StatProgression[i].StatType, NewMaxStat);
				if (StatProgression[i].StatType != eStat_HP || !bInjured)
				{
					SetCurrentStat(StatProgression[i].StatType, NewMaxStat);
				}
			}
		}

		`XEVENTMGR.TriggerEvent('UnitRankUp', self, , NewGameState);
	}

	if (m_SoldierRank == class'X2SoldierClassTemplateManager'.default.NickNameRank)
	{
		if (strNickName == "" && Template.RandomNickNames.Length > 0)
		{
			strNickName = GenerateNickname();
		}
	}

	if (XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		if(XComHQ != none)
		{
			NewGameState.AddStateObject(XComHQ);

			if(XComHQ.HighestSoldierRank < m_SoldierRank)
			{
				XComHQ.HighestSoldierRank = m_SoldierRank;
			}
		
			// If this soldier class can gain AWC abilities and the player has built an AWC
			if (Template.bAllowAWCAbilities && XComHQ.HasFacilityByName('AdvancedWarfareCenter'))
			{
				RollForAWCAbility(); // Roll for AWC abilities if they haven't been already generated

				// If you have reached the rank for one of your hidden abilities, unlock it
				for (i = 0; i < AWCAbilities.Length; i++)
				{
					if (!AWCAbilities[i].bUnlocked && AWCAbilities[i].iRank == m_SoldierRank)
					{
						AWCAbilities[i].bUnlocked = true;
					}
				}
			}
		}
	}
}

// Show the promotion icon (in strategy)
function bool ShowPromoteIcon()
{
	return (IsAlive() && !bCaptured && (CanRankUpSoldier() || HasAvailablePerksToAssign()));
}

function String GenerateNickname()
{
	local X2SoldierClassTemplate Template;
	local int iNumChoices, iChoice;

	Template = GetSoldierClassTemplate();
	iNumChoices = Template.RandomNickNames.Length;

	if( kAppearance.iGender == eGender_Female )
	{
		iNumChoices += Template.RandomNickNames_Female.Length;
	}
	else if( kAppearance.iGender == eGender_Male )
	{
		iNumChoices += Template.RandomNickNames_Male.Length;
	}

	iChoice = `SYNC_RAND(iNumChoices);

	if( iChoice < Template.RandomNickNames.Length )
	{
		return Template.RandomNickNames[iChoice];
	}
	else
	{
		iChoice -= Template.RandomNickNames.Length;
	}

	if( kAppearance.iGender == eGender_Female )
	{
		return Template.RandomNickNames_Female[iChoice];
	}
	else if( kAppearance.iGender == eGender_Male )
	{
		return Template.RandomNickNames_Male[iChoice];
	}

	return "";
}

function ResetRankToRookie()
{
	local int idx;

	// soldier becomes a rookie
	m_SoldierRank = 0;
	ClearSoldierClassTemplate();

	// reset soldier stats
	for(idx = 0; idx < eStat_MAX; idx++)
	{
		SetBaseMaxStat(ECharStatType(idx), GetMyTemplate().CharacterBaseStats[ECharStatType(idx)]);
		SetCurrentStat(ECharStatType(idx), GetMyTemplate().CharacterBaseStats[ECharStatType(idx)]);
	}

	// reset XP to squaddie threshold
	SetXPForRank(m_SoldierRank + 1);
}

function array<int> GetPCSRanks()
{
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<int> ValidRanks;
	local int RankIndex, StatIndex;
	local array<SoldierClassStatType> StatProgression;

	if(GetMyTemplate().CharacterBaseStats[eStat_CombatSims] > 0)
	{
		ValidRanks.AddItem(0);
	}

	// Does not matter which class we grab, all should have same combat sim stats
	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate('Ranger');

	for(RankIndex = 0; RankIndex < SoldierClassTemplate.GetMaxConfiguredRank(); RankIndex++)
	{
		StatProgression = SoldierClassTemplate.GetStatProgression(RankIndex);
		for(StatIndex = 0; StatIndex < StatProgression.Length; StatIndex++)
		{
			if(StatProgression[StatIndex].StatType == eStat_CombatSims && StatProgression[StatIndex].StatAmount > 0)
			{
				ValidRanks.AddItem(RankIndex+1);
			}
		}
	}

	return ValidRanks;
}

function bool IsSufficientRankToEquipPCS()
{
	local int i, Rank;
	local array<int> ValidRanks;

	Rank = GetRank();
	ValidRanks = GetPCSRanks();

	for(i = 0; i < ValidRanks.Length; ++i)
	{
		if(Rank >= ValidRanks[i])
			return true;
	}

	return false;
}

native simulated function StateObjectReference FindAbility(name AbilityTemplateName, optional StateObjectReference MatchSourceWeapon, optional array<StateObjectReference> ExcludeSourceWeapons) const;
/*  the below code was moved into native but describes the implementation accurately
{
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local StateObjectReference ObjRef, EmptyRef, IterRef;
	local int ComponentID;
	local XComGameState_Unit kSubUnit;
	local bool bSkip;

	History = `XCOMHISTORY;
	foreach Abilities(ObjRef)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(ObjRef.ObjectID));
		if (AbilityState.GetMyTemplateName() == AbilityTemplateName)
		{
			bSkip = false;
			foreach ExcludeSourceWeapons(IterRef)
			{
				if (IterRef.ObjectID != 0 && IterRef == AbilityState.SourceWeapon)
				{
					bSkip = true;
					break;
				}
			}
			if (bSkip)
				continue;

			if (MatchSourceWeapon.ObjectID == 0 || AbilityState.SourceWeapon == MatchSourceWeapon)
				return ObjRef;
		}
	}

	if (!m_bSubsystem) // limit 1-depth recursion.
	{
		foreach ComponentObjectIds(ComponentID)
		{
			kSubUnit = XComGameState_Unit(History.GetGameStateForObjectID(ComponentID));
			if (kSubUnit != None)
			{
				ObjRef = kSubUnit.FindAbility(AbilityTemplateName, MatchSourceWeapon, ExcludeSourceWeapons);
				if (ObjRef.ObjectID > 0)
					return ObjRef;
			}
		}
	}

	return EmptyRef;
}
*/

function EvacuateUnit(XComGameState NewGameState)
{
	local XComGameState_Unit NewUnitState, CarriedUnitState;
	local XComGameState_Effect CarryEffect, BleedOutEffect;
	local XComGameStateHistory History;
	local bool bFoundCarry;

	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(Class, ObjectID));
	NewUnitState.bRemovedFromPlay = true;
	NewUnitState.bRequiresVisibilityUpdate = true;
	NewGameState.AddStateObject(NewUnitState);

	`XEVENTMGR.TriggerEvent( 'UnitRemovedFromPlay', self, self, NewGameState );			
	`XEVENTMGR.TriggerEvent( 'UnitEvacuated', self, self, NewGameState );			

	`XWORLD.ClearTileBlockedByUnitFlag(NewUnitState);

	CarryEffect = NewUnitState.GetUnitAffectedByEffectState(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
	if (CarryEffect != none)
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', CarriedUnitState)
		{
			CarryEffect = CarriedUnitState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
			if (CarryEffect != none && CarryEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID == ObjectID)
			{
				bFoundCarry = true;
				break;
			}
		}
		if (bFoundCarry)
		{
			CarriedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(CarriedUnitState.Class, CarriedUnitState.ObjectID));				
			if (CarriedUnitState.IsBleedingOut())
			{
				//  cleanse the effect so the unit is rendered unconscious
				BleedOutEffect = CarriedUnitState.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.BleedingOutName);
				BleedOutEffect.RemoveEffect(NewGameState, NewGameState, true);

				// Achievement: Evacuate a soldier whose bleed-out timer is still running
				if (CarriedUnitState.IsAlive() && CarriedUnitState.IsPlayerControlled())
				{
					`ONLINEEVENTMGR.UnlockAchievement(AT_EvacRescue);
				}

			}
			if (NewUnitState.ObjectID != CarriedUnitState.ObjectID && CarriedUnitState.CanEarnSoldierRelationshipPoints(NewUnitState))
			{
				NewUnitState.AddToSquadmateScore(CarriedUnitState.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_CarrySoldier);
				CarriedUnitState.AddToSquadmateScore(NewUnitState.ObjectID, class'X2ExperienceConfig'.default.SquadmateScore_CarrySoldier);
			}
			CarryEffect.RemoveEffect(NewGameState, NewGameState, true);           //  Stop being carried
			CarriedUnitState.bBodyRecovered = true;
			CarriedUnitState.bRemovedFromPlay = true;
			CarriedUnitState.bRequiresVisibilityUpdate = true;
			NewGameState.AddStateObject(CarriedUnitState);

			`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', CarriedUnitState, CarriedUnitState, NewGameState);
			`XEVENTMGR.TriggerEvent('UnitEvacuated', CarriedUnitState, CarriedUnitState, NewGameState);

			`XWORLD.ClearTileBlockedByUnitFlag(CarriedUnitState);

		}
	}
}
function EventListenerReturn OnUnitRemovedFromPlay(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	RemoveUnitFromPlay();
	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitRemovedFromPlay_GameState(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Removed From Play");

	// This needs to create a new version of the unit since this is an event callback
	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ObjectID));
	NewUnitState.RemoveStateFromPlay();
	NewGameState.AddStateObject(NewUnitState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	return ELR_NoInterrupt;
}

// Needed for simcombat @mnauta
function SimEvacuate()
{
	bRemovedFromPlay = true;
	bRequiresVisibilityUpdate = true;
}

// Different than RemoveUnitFromPlay so that we just do the state change.
function RemoveStateFromPlay( )
{
	bRemovedFromPlay = true;
	bRequiresVisibilityUpdate = true;
}

// Needed for simcombat @mnauta
function SimGetKill(StateObjectReference EnemyRef)
{
	KilledUnits.AddItem(EnemyRef);
}

function ClearKills()
{
	KilledUnits.Length = 0;
}

function CopyKills(XComGameState_Unit CopiedUnitState)
{
	KilledUnits = CopiedUnitState.GetKills();
}

function CopyKillAssists(XComGameState_Unit CopiedUnitState)
{
	KillAssists = CopiedUnitState.GetKillAssists();
}

function array<StateObjectReference> GetKills()
{
	return KilledUnits;
}

function array <StateObjectReference> GetKillAssists()
{
	return KillAssists;
}

// Is unit provided a critical function in the strategy layer
function bool IsUnitCritical()
{
	local XComGameState_StaffSlot StaffSlotState;
	
	if (StaffingSlot.ObjectID != 0)
	{
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffingSlot.ObjectID));
		return (!StaffSlotState.CanStaffBeMoved());
	}

	return false;
}

function RemoveUnitFromPlay()
{
	local XGUnit UnitVisualizer;

	bRemovedFromPlay = true;
	bRequiresVisibilityUpdate = true;

	UnitVisualizer = XGUnit(GetVisualizer());
	if( UnitVisualizer != none )
	{
		UnitVisualizer.SetForceVisibility(eForceNotVisible);
		UnitVisualizer.DestroyBehavior();
	}
}

function ClearRemovedFromPlayFlag()
{
	local XGUnit UnitVisualizer;

	if (!GetMyTemplate().bDontClearRemovedFromPlay)
	{
		bRemovedFromPlay = false;
	}
	
	bRequiresVisibilityUpdate = true;

	UnitVisualizer = XGUnit(GetVisualizer());
	if( UnitVisualizer != none )
	{
		UnitVisualizer.SetForceVisibility(eForceNone);
	}
}

function int GetWeakenedWillModifications()
{
	local int TotalMod;

	TotalMod = 0;
	if( AffectedByEffectNames.Find(class'X2AbilityTemplateManager'.default.DisorientedName) != INDEX_NONE )
	{
		TotalMod += class'X2StatusEffects'.default.DISORIENTED_WILL_ADJUST;
	}

	if( IsPanicked() )
	{
		TotalMod += class'X2StatusEffects'.default.PANIC_WILL_ADJUST;
	}

	if( AffectedByEffectNames.Find(class'X2AbilityTemplateManager'.default.ConfusedName) != INDEX_NONE )
	{
		TotalMod += class'X2StatusEffects'.default.CONFUSED_WILL_ADJUST;
	}

	if( StunnedActionPoints > 0 )
	{
		TotalMod += class'X2StatusEffects'.default.STUNNED_WILL_ADJUST;
	}

	return TotalMod;
}

///////////////////////////////////////
// UI Summaries interface

simulated function EUISummary_UnitStats GetUISummary_UnitStats()
{
	local int i;
	local XComGameState_XpManager XpMan;
	local EUISummary_UnitStats Summary; 
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;

	Summary.CurrentHP = GetCurrentStat(eStat_HP);
	Summary.MaxHP = GetMaxStat(eStat_HP);
	Summary.Aim = GetCurrentStat(eStat_Offense);
	Summary.Tech = GetCurrentStat(eStat_Hacking);
	Summary.Defense = GetCurrentStat(eStat_Defense);
	Summary.Will = GetCurrentStat(eStat_Will);
	Summary.Dodge = GetCurrentStat(eStat_Dodge);
	Summary.Armor = GetCurrentStat(eStat_ArmorMitigation);
	Summary.PsiOffense = GetCurrentStat(eStat_PsiOffense);
	Summary.UnitName = GetName(eNameType_Full);

	History = `XCOMHISTORY;
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			EffectTemplate = EffectState.GetX2Effect();
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Offense, Summary.Aim);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Hacking, Summary.Tech);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Defense, Summary.Defense);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Will, Summary.Will);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_Dodge, Summary.Dodge);
			EffectTemplate.ModifyUISummaryUnitStats(EffectState, self, eStat_PsiOffense, Summary.PsiOffense);
		}
	}

	/* Debug Values */
	if (`CHEATMGR != none && `CHEATMGR.bDebugXp)
	{
		Summary.Xp = m_iXp;
		foreach History.IterateByClassType(class'XComGameState_XpManager', XpMan)
		{
			break;
		}
		for (i = 0; i < XpMan.UnitXpShares.Length; ++i)
		{
			if (XpMan.UnitXpShares[i].UnitRef.ObjectID == ObjectID)
			{
				Summary.XpShares = XpMan.UnitXpShares[i].Shares;
				break;
			}
		}
		Summary.SquadXpShares = XpMan.SquadXpShares;
		Summary.EarnedPool = XpMan.EarnedPool;
	}	
	/* End Debug Values */

	return Summary; 
}

simulated function array<UISummary_UnitEffect> GetUISummary_UnitEffectsByCategory(EPerkBuffCategory Category)
{
	local UISummary_UnitEffect Item, EmptyItem;  
	local array<UISummary_UnitEffect> List; 
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persist;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;

	History = `XCOMHISTORY;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bDisplayInUI && Persist.BuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, self))
			{
				Item = EmptyItem;
				FillSummaryUnitEffect(EffectState, Persist, false, Item);
				List.AddItem(Item);
			}
		}
	}
	foreach AppliedEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			Persist = EffectState.GetX2Effect();
			if (Persist != none && Persist.bSourceDisplayInUI && Persist.SourceBuffCategory == Category && Persist.IsEffectCurrentlyRelevant(EffectState, self))
			{
				Item = EmptyItem;
				FillSummaryUnitEffect(EffectState, Persist, true, Item);
				List.AddItem(Item);
			}
		}
	}
	if (Category == ePerkBuff_Penalty)
	{
		if (GetRupturedValue() > 0)
		{
			Item = EmptyItem;
			Item.AbilitySourceName = 'eAbilitySource_Standard';
			Item.Icon = class 'X2StatusEffects'.default.RuptureIcon;
			Item.Name = class'X2StatusEffects'.default.RupturedFriendlyName;
			Item.Description = class'X2StatusEffects'.default.RupturedFriendlyDesc;
			List.AddItem(Item);
		}
	}

	return List; 
}

private simulated function FillSummaryUnitEffect(const XComGameState_Effect EffectState, const X2Effect_Persistent Persist, const bool bSource, out UISummary_UnitEffect Summary)
{
	local X2AbilityTag AbilityTag;

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = EffectState;

	if (bSource)
	{
		Summary.Name = Persist.SourceFriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.SourceFriendlyDescription);
		Summary.Icon = Persist.SourceIconLabel;
		Summary.Cooldown = 0; //TODO @jbouscher @bsteiner
		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}
	else
	{
		Summary.Name = Persist.FriendlyName;
		Summary.Description = `XEXPAND.ExpandString(Persist.FriendlyDescription);
		Summary.Icon = Persist.IconImage;
		Summary.Cooldown = 0; //TODO @jbouscher @bsteiner
		Summary.Charges = 0; //TODO @jbouscher @bsteiner
		Summary.AbilitySourceName = Persist.AbilitySourceName;
	}

	AbilityTag.ParseObj = None;
}
simulated function array<string> GetUISummary_UnitStatusIcons()
{
	local array<string> List;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent Persist;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		Persist = EffectState.GetX2Effect();
		if( Persist.bDisplayInUI && Persist.IsEffectCurrentlyRelevant(EffectState, self) )
		{
			List.AddItem(Persist.StatusIcon);
		}
	}

	if( StunnedActionPoints > 0 )
	{
		List.AddItem(class'UIUtilities_Image'.const.UnitStatus_Stunned);
	}

	return List;
}

simulated function array<UISummary_Ability> GetUISummary_Abilities()
{
	local array<UISummary_Ability> UIAbilities; 
	local XComGameState_Ability AbilityState;   //Holds INSTANCE data for the ability referenced by AvailableActionInfo. Ie. cooldown for the ability on a specific unit
	local X2AbilityTemplate AbilityTemplate; 
	local int i, len; 

	len = Abilities.Length;
	for(i = 0; i < len; i++)
	{	
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(Abilities[i].ObjectID));
		if( AbilityState == none) 
			continue; 

		AbilityTemplate = AbilityState.GetMyTemplate(); 
		if( !AbilityTemplate.bDisplayInUITooltip )
			continue; 

		//Add to our list of abilities 
		UIAbilities.AddItem( AbilityState.GetUISummary_Ability(self) );
	}

	return UIAbilities; 
}

simulated function int GetUISummary_StandardShotHitChance(XGUnit Target)
{
	local XComGameStateHistory History;
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local X2TacticalGameRuleset TacticalRules;
	local GameRulesCache_Unit OutCachedAbilitiesInfo;
	local AvailableAction StandardShot;
	local ShotBreakdown kBreakdown;
	local StateObjectReference TargetRef; 
	local int Index;
	local int TargetIndex;

	local int iHitChance;

	History = `XCOMHISTORY;
	TacticalRules = `TACTICALRULES;

	//Show the standard shot % to hit if it is available
	TacticalRules.GetGameRulesCache_Unit(self.GetReference(), OutCachedAbilitiesInfo);
	for( Index = 0; Index < OutCachedAbilitiesInfo.AvailableActions.Length; ++Index )
	{		
		StandardShot = OutCachedAbilitiesInfo.AvailableActions[Index];
		SelectedAbilityState = XComGameState_Ability( History.GetGameStateForObjectID(StandardShot.AbilityObjectRef.ObjectID) );
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();	

		if( SelectedAbilityTemplate.DisplayTargetHitChance && StandardShot.AvailableCode == 'AA_Success' )
		{
			//Find our target
			for( TargetIndex = 0; TargetIndex < StandardShot.AvailableTargets.Length; ++TargetIndex )
			{
				TargetRef = StandardShot.AvailableTargets[TargetIndex].PrimaryTarget;
				if( Target.ObjectID == TargetRef.ObjectID )
				{
					iHitChance = SelectedAbilityState.LookupShotBreakdown(GetReference(), TargetRef, StandardShot.AbilityObjectRef, kBreakdown);
					break;
				}								
			}
		}
	}

	return iHitChance;
}

simulated function GetUISummary_TargetableUnits(out array<StateObjectReference> arrVisibleUnits, out array<StateObjectReference> arrSSEnemies, out array<StateObjectReference> arrCurrentlyAffectable, XComGameState_Ability CurrentAbility, int HistoryIndex)
{
	local XComGameState_BaseObject Target;
	local XComGameState_Unit EnemyUnit;
	local XComGameState_Destructible DestructibleObject;
	local array<StateObjectReference> arrHackableObjects;
	local AvailableAction ActionInfo;
	local StateObjectReference TargetRef;
	local int i, j;
	local GameRulesCache_Unit UnitCache;

	arrCurrentlyAffectable.Length = 0;
	//  retrieve cached action info
	`TACTICALRULES.GetGameRulesCache_Unit(GetReference(), UnitCache);  // note, the unit cache is acting on current (latest history index) information, so this may not be technically correct

	foreach UnitCache.AvailableActions(ActionInfo)
	{
		// only show heads for abilities which have icons in the hud. Otherwise non-targeted abilities and passives will cause targets
		// to show as available
		if( (CurrentAbility == None && class'UITacticalHUD_AbilityContainer'.static.ShouldShowAbilityIcon(ActionInfo)) 
			|| (CurrentAbility != none && ActionInfo.AbilityObjectRef.ObjectID == CurrentAbility.ObjectID) )
		{
			for( j = 0; j < ActionInfo.AvailableTargets.Length; ++j )
			{
				TargetRef = ActionInfo.AvailableTargets[j].PrimaryTarget;
				if( TargetRef.ObjectID > 0 && arrCurrentlyAffectable.Find('ObjectID', TargetRef.ObjectID) == INDEX_NONE )
				{
					Target = `XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID, , HistoryIndex);
					EnemyUnit = XComGameState_Unit(Target);
					if (EnemyUnit == none || !EnemyUnit.GetMyTemplate().bIsCosmetic)
					{
						arrCurrentlyAffectable.AddItem(TargetRef);
					}
				}
			}
		}
	}

	arrVisibleUnits.Length = 0;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyTargetsForUnit(ObjectID, arrVisibleUnits, , HistoryIndex);

	//  Check for squadsight
	if( HasSquadsight() )
	{
		class'X2TacticalVisibilityHelpers'.static.GetAllSquadsightEnemiesForUnit(ObjectID, arrSSEnemies, HistoryIndex, true);
	}
	for( i = 0; i < arrSSEnemies.length; i++ )
	{
		arrVisibleUnits.AddItem(arrSSEnemies[i]);
	}

	//Remove cosmetic and deceased units from the enemy array
	if( arrVisibleUnits.Length > 0 )
	{
		for( i = arrVisibleUnits.Length - 1; i >= 0; i-- )
		{
			Target = `XCOMHISTORY.GetGameStateForObjectID(arrVisibleUnits[i].ObjectID, , HistoryIndex);
			EnemyUnit = XComGameState_Unit(Target);
			if( EnemyUnit != none && ( !EnemyUnit.IsAlive() || EnemyUnit.GetMyTemplate().bIsCosmetic ) )
			{
				arrVisibleUnits.Remove(i, 1);
			}
			else
			{
				DestructibleObject = XComGameState_Destructible(Target);
				if( DestructibleObject != none && !DestructibleObject.IsTargetable(GetTeam()) )
				{
					arrVisibleUnits.Remove(i, 1);
				}
			}
		}
	}

	//Add all hackable objects to the array 
	class'X2TacticalVisibilityHelpers'.static.GetHackableObjectsInRangeOfUnit(ObjectID, arrHackableObjects, , HistoryIndex, FindAbility('IntrusionProtocol').ObjectID > 0);
	for( i = 0; i < arrHackableObjects.length; i++ )
	{
		arrVisibleUnits.AddItem(arrHackableObjects[i]);
	}
}

simulated function int GetUIStatFromInventory(ECharStatType Stat, optional XComGameState CheckGameState)
{
	local int Result;
	local XComGameState_Item InventoryItem;
	local X2EquipmentTemplate EquipmentTemplate;
	local array<XComGameState_Item> CurrentInventory;

	//  Gather abilities from the unit's inventory
	CurrentInventory = GetAllInventoryItems(CheckGameState);
	foreach CurrentInventory(InventoryItem)
	{
		EquipmentTemplate = X2EquipmentTemplate(InventoryItem.GetMyTemplate());
		if (EquipmentTemplate != none)
		{
			// Don't include sword boosts or any other equipment in the EquipmentExcludedFromStatBoosts array
			if(class'UISoldierHeader'.default.EquipmentExcludedFromStatBoosts.Find(EquipmentTemplate.DataName) == INDEX_NONE)
				Result += EquipmentTemplate.GetUIStatMarkup(Stat, InventoryItem);
		}
	}	

	return Result;
}

simulated function int GetUIStatFromAbilities(ECharStatType Stat)
{
	local int Result, i;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> SoldierAbilities;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;
	
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	SoldierAbilities = GetEarnedSoldierAbilities();
	for (i = 0; i < SoldierAbilities.Length; ++i)
	{
		AbilityName = SoldierAbilities[i].AbilityName;
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);

		if (AbilityTemplate != none)
		{
			Result += AbilityTemplate.GetUIStatMarkup(Stat);
		}
	}

	return Result;
}

///////////////////////////////////////
function int GetRelationshipChanges(XComGameState_Unit OldState)
{
	local int i, j;

	if (SoldierRelationships.Length != OldState.SoldierRelationships.Length && (OldState.SoldierRelationships.Length != 0))
	{
		for (i = 0; i < SoldierRelationships.Length; ++i)
		{
			for (j = 0; j < OldState.SoldierRelationships.Length; ++j)
			{
				if (SoldierRelationships[i].SquadmateObjectRef == OldState.SoldierRelationships[j].SquadmateObjectRef)
				{
					break;
				}
				else if (j == (OldState.SoldierRelationships.Length - 1))
				{
					return SoldierRelationships[i].Score;
				}
			}
		}
	}
	else if ( (SoldierRelationships.Length == OldState.SoldierRelationships.Length) && (SoldierRelationships.Length > 0) )
	{
		for (i = 0; i < SoldierRelationships.Length; ++i)
		{
			for (j = 0; j < SoldierRelationships.Length; ++j)
			{
				if (SoldierRelationships[i].SquadmateObjectRef == OldState.SoldierRelationships[j].SquadmateObjectRef &&
					SoldierRelationships[i].Score != OldState.SoldierRelationships[j].Score)
				{
					return (SoldierRelationships[i].Score - OldState.SoldierRelationships[j].Score);
				}
			}
		}
	}
	else if (OldState.SoldierRelationships.Length == 0 && SoldierRelationships.Length > 0)
	{
		return SoldierRelationships[0].Score;
	}

	return -1;
}

function string GetSoldierRelationshipFlyOverString(int iDiff)
{
	local string strXP, strPoints;

	if (iDiff != -1)
	{
		strXP = class'XLocalizedData'.default.RelationshipChanged;
		if (iDiff > 0)
		{
			strPoints = "+" $ iDiff;
			`BATTLE.ReplaceText(strXP, "<Amount>", strPoints);
		}
		else
		{
			strPoints = "" $ iDiff;
			`BATTLE.ReplaceText(strXP, "<Amount>", strPoints);
		}
		return strXP;
	}
}

static function SetUpBuildTrackForSoldierRelationship(out VisualizationTrack BuildTrack, XComGameState VisualizeGameState, int UnitID)
{
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver      SoundAndFlyOver;
	local XComGameState_Unit                NewStateUnit, OldStateUnit;
	local int                               iDiff;
	local string                            RelationshipString;
	local XComGameState_BaseObject          NewStateBaseObject, OldStateBaseObject;

	History = `XCOMHISTORY;

	NewStateUnit = XComGameState_Unit(BuildTrack.StateObject_NewState);
	OldStateUnit = XComGameState_Unit(BuildTrack.StateObject_OldState);

	History.GetCurrentAndPreviousGameStatesForObjectID(UnitID, OldStateBaseObject, NewStateBaseObject, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	NewStateUnit = XComGameState_Unit(NewStateBaseObject);
	OldStateUnit = XComGameState_Unit(OldStateBaseObject);
	if (NewStateUnit.IsSoldier() && !NewStateUnit.IsAlien())
	{
		iDiff = NewStateUnit.GetRelationshipChanges(OldStateUnit);
		if (iDiff != -1 && `CHEATMGR.bDebugSoldierRelationships)
		{
			RelationshipString = NewStateUnit.GetSoldierRelationshipFlyOverString(iDiff);
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, RelationshipString, '', eColor_Purple);
		}
	}
}

function bool CanEarnSoldierRelationshipPoints(XComGameState_Unit OtherUnit)
{
	if (IsDead() || OtherUnit.IsDead() || bRemovedFromPlay)
	{
		return false;
	}
	else if (!CanEarnXP() || !OtherUnit.CanEarnXp())
	{
		return false;
	}
	else
	{
		return true;
	}
}

///////////////////////////////////////
// Damageable interface

//  NOTE - Armor parameter no longer used - now returns all armor on the unit, less Shred
simulated event float GetArmorMitigation(const out ArmorMitigationResults Armor)
{
	local float Total;
	local ArmorMitigationResults ArmorResults;

	class'X2AbilityArmorHitRolls'.static.RollArmorMitigation(Armor, ArmorResults, self);
	Total = ArmorResults.TotalMitigation;
	Total -= Shredded;
	Total = max(0, Total);

	return Total;
}

simulated function float GetArmorMitigationForUnitFlag()
{
	local float Total;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local X2Effect_BonusArmor ArmorEffect;

	Total = 0;
	
	Total += GetCurrentStat(eStat_ArmorMitigation);

	if (AffectedByEffects.Length > 0)
	{
		History = `XCOMHISTORY;
		foreach AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			ArmorEffect = X2Effect_BonusArmor(EffectState.GetX2Effect());
			if (ArmorEffect != none)
			{
				Total += ArmorEffect.GetArmorMitigation(EffectState, self);
			}
		}
	}

	Total -= Shredded;
	Total = max(0, Total);

	return Total;
}

// Accessor Method for SoldierRelationships
function array<SquadmateScore> GetSoldierRelationships()
{
	return SoldierRelationships;
}

function string SafeGetCharacterNickName()
{
	return strNickName;
}

function string SafeGetCharacterLastName()
{
	return strLastName;
}

function string SafeGetCharacterFirstName()
{
	return strFirstName;
}

function bool FindAvailableNeighborTile(out TTile OutTileLocation)
{
	local TTile NeighborTileLocation;
	local XComWorldData World;
	local Actor TileActor;

	World = `XWORLD;

	NeighborTileLocation = TileLocation;

	for (NeighborTileLocation.X = TileLocation.X - 1; NeighborTileLocation.X <= TileLocation.X + 1; ++NeighborTileLocation.X)
	{
		for (NeighborTileLocation.Y = TileLocation.Y - 1; NeighborTileLocation.Y <= TileLocation.Y + 1; ++NeighborTileLocation.Y)
		{
			TileActor = World.GetActorOnTile(NeighborTileLocation);

			// If the tile is empty and is on the same z as this unit's location
			if (TileActor == none && (World.GetFloorTileZ(NeighborTileLocation, false) == World.GetFloorTileZ(TileLocation, false)))
			{
				OutTileLocation = NeighborTileLocation;
				return true;
			}
		}
	}
	
	return false;
}

delegate bool ValidateTileDelegate(const out TTile TileOption, const out TTile SourceTile)
{
	return true;
}

function bool FindAvailableNeighborTileWeighted(Vector PreferredDirection, out TTile OutTileLocation, optional delegate<ValidateTileDelegate> IsValidTileFn=ValidateTileDelegate)
{
	local TTile NeighborTileLocation;
	local XComWorldData World;
	local Actor TileActor;

	local Vector ToNeighbor;
	local TTile BestTile;
	local float DotToPreferred;
	local float BestDot;
	local bool FoundTile;

	World = `XWORLD;

	BestDot = -1.0f; // Exact opposite of preferred direction
	FoundTile = false;
	NeighborTileLocation = TileLocation;
	for (NeighborTileLocation.X = TileLocation.X - 1; NeighborTileLocation.X <= TileLocation.X + 1; ++NeighborTileLocation.X)
	{
		for (NeighborTileLocation.Y = TileLocation.Y - 1; NeighborTileLocation.Y <= TileLocation.Y + 1; ++NeighborTileLocation.Y)
		{
			if (abs(NeighborTileLocation.X - TileLocation.X) > 0 && abs(NeighborTileLocation.Y - TileLocation.Y) > 0)
			{
				continue;
			}
			TileActor = World.GetActorOnTile(NeighborTileLocation);

			// If the tile is empty and is on the same z as this unit's location
			if (TileActor == none && (World.GetFloorTileZ(NeighborTileLocation, false) == TileLocation.Z))
			{
				if( !IsValidTileFn(NeighborTileLocation, TileLocation) )
				{
					continue;
				}

				ToNeighbor = Normal(World.GetPositionFromTileCoordinates(NeighborTileLocation) - World.GetPositionFromTileCoordinates(TileLocation));
				DotToPreferred = NoZDot(PreferredDirection, ToNeighbor);
				if (DotToPreferred >= BestDot)
				{
					BestDot = DotToPreferred;
					BestTile = NeighborTileLocation;
					FoundTile = true;
				}
			}
		}
	}

	if (FoundTile)
	{
		OutTileLocation = BestTile;
	}

	return FoundTile;
}

function XComGameState_AIGroup GetGroupMembership( optional XComGameState NewGameState=None)
{
	local XComGameStateHistory History;
	local XComGameState_AIGroup AIGroupState;
	local int GroupUnitIndex;

	if( NewGameState != None)
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
		{
			for( GroupUnitIndex = 0; GroupUnitIndex < AIGroupState.m_arrMembers.Length; ++GroupUnitIndex )
			{
				if( AIGroupState.m_arrMembers[GroupUnitIndex].ObjectID == ObjectID )
				{
					return AIGroupState;
				}
			}
		}
	}

	History = `XCOMHISTORY;
	// find the group this unit belongs to
	foreach History.IterateByClassType(class'XComGameState_AIGroup', AIGroupState)
	{
		for( GroupUnitIndex = 0; GroupUnitIndex < AIGroupState.m_arrMembers.Length; ++GroupUnitIndex )
		{
			if( AIGroupState.m_arrMembers[GroupUnitIndex].ObjectID == ObjectID )
			{
				return AIGroupState;
			}
		}
	}

	return None;
}

function bool IsGroupLeader(optional XComGameState NewGameState=None)
{
	local XComGameState_AIGroup Group;
	Group = GetGroupMembership(NewGameState);
	if( Group == None || (Group.m_arrMembers.Length > 0 && Group.m_arrMembers[0].ObjectID == ObjectID) )
	{
		return true;
	}
	return false;
}

// Adds an extra layer of gameplay finesse to unit tile blocking. By default, all units
// block all other units from occupying the same tile they are on. This allows that to
// be overridden, so that a unit can selectively allow other units to occupy the
// tile they are on.
event bool DoesBlockUnitPathing(const XComGameState_Unit TestUnit)
{
	local XComGameState_Effect EffectState, HighestRankEffect;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local EGameplayBlocking CurrentBlocking, TempBlocking;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// until told otherwise, all units block all other units if they are in the same time
	CurrentBlocking = eGameplayBlocking_Blocks;

	//Check effects that modify blocking
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

		if( EffectState != none )
		{
			EffectTemplate = EffectState.GetX2Effect();

			if( EffectTemplate != none )
			{
				TempBlocking = EffectTemplate.ModifyGameplayPathBlockingForTarget(self, TestUnit);

				// This Unit blocks/does not block the TestUnit depending on the highest ranked
				// effect that modifies blocking
				if( (TempBlocking != eGameplayBlocking_DoesNotModify) && (CurrentBlocking != TempBlocking) &&
					((HighestRankEffect == none) || (EffectTemplate.IsThisEffectBetterThanExistingEffect(HighestRankEffect))) )
				{
					CurrentBlocking = TempBlocking;
					HighestRankEffect = EffectState;
				}
			}
		}
	}

	if( CurrentBlocking == eGameplayBlocking_Blocks )
	{
		return true;
	}

	// This Unit does not block the TestUnit
	return false;
}

// Adds an extra layer of gameplay finesse to unit tile blocking. By default, all units
// block all other units from occupying the same tile they are on. This allows that to
// be overridden, so that a unit can selectively allow other units to block pathing to the
// tile that they are on
event bool DoesBlockUnitDestination(const XComGameState_Unit TestUnit)
{
	local XComGameState_Effect EffectState, HighestRankEffect;
	local StateObjectReference EffectRef;
	local X2Effect_Persistent EffectTemplate;
	local EGameplayBlocking CurrentBlocking, TempBlocking;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// until told otherwise, all units block all other units if they are in the same time
	CurrentBlocking = eGameplayBlocking_Blocks;

	//Check effects that modify blocking
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

		if( EffectState != none )
		{
			EffectTemplate = EffectState.GetX2Effect();

			if( EffectTemplate != none )
			{
				TempBlocking = EffectTemplate.ModifyGameplayDestinationBlockingForTarget(self, TestUnit);

				// This Unit blocks/does not block the TestUnit depending on the highest ranked
				// effect that modifies blocking
				if( (TempBlocking != eGameplayBlocking_DoesNotModify) && (CurrentBlocking != TempBlocking) &&
					((HighestRankEffect == none) || (EffectTemplate.IsThisEffectBetterThanExistingEffect(HighestRankEffect))) )
				{
					CurrentBlocking = TempBlocking;
					HighestRankEffect = EffectState;
				}
			}
		}
	}

	if( CurrentBlocking == eGameplayBlocking_Blocks )
	{
		return true;
	}

	// This Unit does not block the TestUnit
	return false;
}

native function bool IsUnrevealedAI( int HistoryIndex=INDEX_NONE ) const;

function int GetSuppressors(optional out array<StateObjectReference> Suppressors)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent Effect;
	History = `XCOMHISTORY;
	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if( EffectState != None )
		{
			Effect = EffectState.GetX2Effect();  
			if( Effect.IsA('X2Effect_Suppression') )
			{
				Suppressors.AddItem(EffectState.ApplyEffectParameters.SourceStateObjectRef);
			}
		}
	}
	return Suppressors.Length;
}

// From X2AIBTDefaultActions - moving here so serialization of the delegate works
simulated function SoldierRescuesCivilian_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local XComGameStateContext Context;
	local VisualizationTrack BuildTrack;
	local XComGameState_Unit UnitState;

	if (VisualizeGameState.GetNumGameStateObjects() > 0)
	{
		UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectIndex(0));
		BuildTrack.StateObject_OldState = UnitState;
		BuildTrack.StateObject_NewState = UnitState;
		BuildTrack.TrackActor = UnitState.GetVisualizer();

		Context = VisualizeGameState.GetContext();
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'CivilianRescue', eColor_Good);

		OutVisualizationTracks.AddItem(BuildTrack);
	}
}

function bool CanAbilityHitUnit(name AbilityName)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent Effect;
	local bool bCanHit;

	History = `XCOMHISTORY;
	bCanHit = true;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if( EffectState != None )
		{
			Effect = EffectState.GetX2Effect();
			if(Effect != none)
			{
				bCanHit = bCanHit && Effect.CanAbilityHitUnit(AbilityName);

				if(!bCanHit)
				{
					break;
				}
			}
		}
	}

	return bCanHit;
}

// Checks to see if all Codex that originated from an original Codex are dead
function bool AreAllCodexInLineageDead(XComGameState NewGameState/*, XComGameState_Unit UnitState*/)
{
	local XComGameState_Unit TestUnitInNewGameState, TestUnit;
	local XComGameStateHistory History;
	local UnitValue OriginalCodexObjectIDValue;
	local float UnitStateOriginalCodexObjectID, TestUnitOriginalCodexObjectID;
	
	History = `XCOMHISTORY;

	UnitStateOriginalCodexObjectID = ObjectID;
	if(GetUnitValue(class'X2Ability_Cyberus'.default.OriginalCyberusValueName, OriginalCodexObjectIDValue))
	{
		// If the UnitState has a value for OriginalCyberusValueName, use that since it is the original Codex of its group
		UnitStateOriginalCodexObjectID = OriginalCodexObjectIDValue.fValue;
	}

	foreach History.IterateByClassType(class'XComGameState_Unit', TestUnit)
	{
		if( (TestUnit.ObjectID != ObjectID) &&
			(TestUnit.GetMyTemplateName() == GetMyTemplateName()) )
		{
			// The TestUnit is not the same as UnitState but is the same template
			TestUnitInNewGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(TestUnit.ObjectID));
			if( TestUnitInNewGameState != none )
			{
				// Check units in the unsubmitted GameState if possible
				TestUnit = TestUnitInNewGameState;
			}

			if( !TestUnit.bRemovedFromPlay &&
				TestUnit.IsAlive() )
			{
				// If the TestUnit is in play and alive
				TestUnitOriginalCodexObjectID = TestUnit.ObjectID;
				if(TestUnit.GetUnitValue(class'X2Ability_Cyberus'.default.OriginalCyberusValueName, OriginalCodexObjectIDValue))
				{
					// If the UnitState has a value for OriginalCyberusValueName, use that since it is the original Codex of its group
					TestUnitOriginalCodexObjectID = OriginalCodexObjectIDValue.fValue;
				}

				if( TestUnitOriginalCodexObjectID == UnitStateOriginalCodexObjectID )
				{
					// If the living TestUnit has the same original codex value, UnitState is not the last
					// of its kind.
					return false;
				}
			}
		}
	}

	return true;
}

function TTile GetDesiredTileForAttachedCosmeticUnit()
{
	local TTile TargetTile;

	TargetTile = TileLocation;
	TargetTile.Z += GetDesiredZTileOffsetForAttachedCosmeticUnit();

	return TargetTile;
}

// if this unit is an attached unit (cosmetic flying gremlin and such), we need to 
// put them high enough off the ground that they don't collide with the owning unit. To that end,
// this function determines if any extra bump is needed. Basically, any unit taller than two units
// will lack clearence for the gremlin, and need to have it bumped up
function int GetDesiredZTileOffsetForAttachedCosmeticUnit()
{
	return max(UnitHeight - 2, 0);
}

////////////////////////////////////////////////////////////////////////////////////////
// Hackable interface

function array<int> GetHackRewardRollMods()
{
	return HackRollMods;
}

function SetHackRewardRollMods(const out array<int> RollMods)
{
	HackRollMods = RollMods;
}

function bool HasBeenHacked()
{
	return bHasBeenHacked;
}

function int GetUserSelectedHackOption()
{
	return UserSelectedHackReward;
}

function array<Name> GetHackRewards(Name HackAbilityName)
{
	local Name HackTemplateName;
	local X2CharacterTemplate MyTemplate;
	local X2HackRewardTemplate HackTemplate;
	local X2HackRewardTemplateManager HackTemplateManager;
	local array<Name> ApprovedHackRewards;

	MyTemplate = GetMyTemplate();
	HackTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

	foreach MyTemplate.HackRewards(HackTemplateName)
	{
		HackTemplate = HackTemplateManager.FindHackRewardTemplate(HackTemplateName);

		if( HackTemplate != None && HackTemplate.HackAbilityTemplateRestriction == HackAbilityName && HackTemplate.IsHackRewardCurrentlyPossible() )
		{
			ApprovedHackRewards.AddItem(HackTemplateName);

			if( ApprovedHackRewards.Length == 3 )
			{
				break;
			}
		}
	}

	if (ApprovedHackRewards.Length != 3 && ApprovedHackRewards.Length != 0 )
	{
		`RedScreen("[@design, #dkaplan] Not exactly 3 hack rewards selected for :" @ HackAbilityName);
	}
	return ApprovedHackRewards;
}

function bool HasOverrideDeathAnimOnLoad(out Name DeathAnim)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect HighestRankEffectState, EffectState;
	local X2Effect_Persistent HighestRankEffectTemplate, EffectTemplate;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != None)
		{
			EffectTemplate = EffectState.GetX2Effect();

			if ((EffectTemplate != none ) &&
				(HighestRankEffectState == none) || (EffectTemplate.IsThisEffectBetterThanExistingEffect(HighestRankEffectState)))
			{
				HighestRankEffectState = EffectState;
				HighestRankEffectTemplate = EffectTemplate;
			}
		}
	}

	if (HighestRankEffectState != none)
	{
		return HighestRankEffectTemplate.HasOverrideDeathAnimOnLoad(DeathAnim);
	}

	return false;
}

////////////////////////////////////////////////////////////////////////////////////////
// cpptext

cpptext
{
	FCharacterStat& GetCharacterStat(ECharStatType StatType);
	const FCharacterStat& GetCharacterStat(ECharStatType StatType) const;

	virtual void Serialize(FArchive& Ar);

	// ----- X2GameRulesetVisibilityInterface -----
	virtual UBOOL CanEverSee() const
	{
		return UXComWorldData::Instance()->TileOnBoard(TileLocation);
	}

	virtual UBOOL CanEverBeSeen() const
	{
		return UXComWorldData::Instance()->TileOnBoard(TileLocation);
	}
	// ----- end X2GameRulesetVisibilityInterface -----
};

////////////////////////////////////////////////////////////////////////////////////////
// defprops

DefaultProperties
{
	UnitSize = 1;
	UnitHeight = 2;
	CoverForceFlag = CoverForce_Default;
	MPSquadLoadoutIndex = INDEX_NONE;
	CachedUnitDataStateObjectId = INDEX_NONE;
}
