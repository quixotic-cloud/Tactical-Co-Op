//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_UnitProperty.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitProperty extends X2Condition native(Core);

/** Simple properties on the unit */
var bool    ExcludeAlive;
var bool    ExcludeDead;
var bool    ExcludeRobotic;
var bool    ExcludeOrganic;
var bool    ExcludeCivilian;        // excludes based on character template property, not team
var bool    ExcludeNonCivilian;     // excludes based on character template property, not team
var bool    ExcludeCosmetic;        // if a unit is flagged as cosmetic, ignore it
var bool	ExcludeImpaired;
var bool	ExcludePanicked;
var bool    ExcludeInStasis;
var bool	ExcludeTurret;
var bool    IsAdvent;
var bool    ExcludeNoCover;         //  checks if the target has cover or not
var bool    ExcludeNoCoverToSource; //  checks the cover between the target and source
var bool    ExcludeFullHealth;      //  ignore target if it is at full HP, unless it is affected by a persistent damage type listed in X2Ability_DefaultAbilitySet's MedikitHealEffectTypes
var bool    IsBleedingOut;
var bool    IsUnspotted;
var bool    CanBeCarried;
var bool    IsOutdoors;
var bool	IsConcealed;
var bool    ExcludeConcealed;       //  normally visibility rules take care of this - this is only for MeetsCondition, not MeetsConditionWithSource
var bool	IsImpaired;
var bool    HasClearanceToMaxZ;
var bool    ExcludeAlien;
var bool    ExcludeStunned;
var bool    IsPlayerControlled;
var bool    ExcludeUnrevealedAI;
var bool    IncludeWeakAgainstTechLikeRobot;
var bool	ImpairedIgnoresStuns;
var bool    IsScampering;

var int		MinRank;
var int		MaxRank;

var array<name> ExcludeSoldierClasses;  // condition will fail if the unit has a soldier class in this list. non-soldiers will always pass.
var array<name> RequireSoldierClasses;  // condition will fail if the unit's soldier class does not appear in this list (if it is not empty). non-soldiers will always fail.

/** Properties to match against the source unit */
var bool    ExcludeHostileToSource;     //  disallow units that are hostile to the source
var bool    ExcludeFriendlyToSource;    //  disallow units that are friendly to the source
var bool    TreatMindControlledSquadmateAsHostile;   //  if a squadmate is mind controlled (i.e. it used to be your enemy), normally they are considered friendly. consider them hostile instead.
var bool    ExcludeSquadmates;          //  target unit's team must be different than the sources (e.g. civilians and aliens would meet this for xcom)
var bool    RequireSquadmates;          //  target unit and source unit teams must be the same (e.g. xcom and xcom only, no civilians or aliens allowed)
var bool    RequireWithinRange;         //  requires that the target be within some range to the source
var float   WithinRange;                //  allowed VSize (in unreal units) between source and target positions
var bool    RequireWithinMinRange;      //  requires that the target be within a minimum range from the source
var float   WithinMinRange;             //  allowed VSize (in unreal units) between source and target positions
var bool    BeingCarriedBySource;

var bool	FailOnNonUnits;				//  defines whether this condition should return a failure for non units ('AA_NotAUnit') or just pass through (success)

native function name MeetsCondition(XComGameState_BaseObject kTarget);
native function name MeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource);

DefaultProperties
{
	/** Setting up defaults for normal attacks */
	ExcludeDead=true;
	ExcludeFriendlyToSource=true;
	ExcludeCosmetic=true;
	ExcludeInStasis=true;

	MinRank=0;
	MaxRank=100000;

	FailOnNonUnits=false; //Users must explicitly flag whether their condition can return 'AA_NotAUnit'
}