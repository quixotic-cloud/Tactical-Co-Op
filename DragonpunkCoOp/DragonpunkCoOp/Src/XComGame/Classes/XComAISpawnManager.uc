//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComAISpawnManager.uc    
//  AUTHOR:  Dan Kaplan --  8/25/2014
//  PURPOSE: AI spawning-related code.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComAISpawnManager extends Object
	native dependson(XGGameData);

const MIN_FORCE_LEVEL = 1;
const MAX_FORCE_LEVEL = 20;
const MIN_ALERT_LEVEL = 1;
const MAX_ALERT_LEVEL = 4;

const MIN_SPAWN_NODE_SPACING = 3.0;

// A curve specifying the point value for pods based on the Force level.
var() RawDistributionFloat ForceLevelToIdealPodPointValueCurve;

// A curve specifying the point value modifier for pods based on the alert level.
var() RawDistributionFloat AlertLevelToPodPointValueModifierCurve;

// A normalized curve specifying the weighting that should be applied to patrol nodes relative to the spawn location
// of each pod.  This weighting is multiplied against the Ideal Patrol Range determined using the 
// "PointValueToIdealPatrolRangeCurve" above.
var() RawDistributionFloat NormalizedDistanceToPatrolWeightingCurve;

// Pods will never spawn within this range of XCom (specified in meters).
var() float XComExclusionDistance;

// Civilians will never spawn within this range of XCom (specified in meters).
var() float CivilianExclusionDistance;

// The Base Exclusion range (at Alert level 500) in meters.
var() float BaseExclusionRange;

// The Base Roam range (at Alert level 500) in meters.
var() float BaseRoamRange;

// In tiles, the distance away from the pod's center at which group members should spawn.
var() int IdealPodMemberSpawnDistance;

// When more points are allocated to a group than desired, this value modifies that overage value before it is passed 
// along to the spawning for the next group.
var() float PointOverageModifier;

// The minimum angle offset from the most recent point of interest to determine where to location the next reinforcement group
var() float MinReinforcementAngleOffset;

// The minimum angle offset from the most recent point of interest to determine where to location the next reinforcement group
var() float MaxReinforcementAngleOffset;

// IF true, then group size will be respected completely; else it will be dependent on not exceeding the Ideal point value.
var() bool MaxGroupSizeTakesPrecedenceOverPointValues;

var() float MinRequiredHackSpawnDistance;
var() float IdealHackDistanceToLOP;
var() float HackDistanceToLOPWeight;
var() float HackDistanceRandomWeight;


struct native LeaderLevelBump
{
	var() int DifficultyLevel;
	var() int ForceLevelBump;
	var() float ChanceToApply;
};

var() array<LeaderLevelBump> LeaderLevelBumps;

struct native DummyInclusionExclusionList
{
	var Array<Name> TheList;
	var bool bInclude;
};

struct native CombinedSpawnRestrictions
{
	var bool CiviliansRestricted;
	var bool AdventRestricted;
	var bool AliensRestricted;

	// need to account for the size of the native inclusion/exclusion list
	var native noexport DummyInclusionExclusionList DummyLeaderList;
	var native noexport DummyInclusionExclusionList DummyFollowerList;

	structcpptext
	{
		/** Constructors */
		FCombinedSpawnRestrictions() 
		{
			appMemzero(this, sizeof(FCombinedSpawnRestrictions));
		}
		FCombinedSpawnRestrictions(EEventParm)
		{
			appMemzero(this, sizeof(FCombinedSpawnRestrictions));
		}

		TInclusionExclusionList<FName> LeaderInclusionExclusionList;
		TInclusionExclusionList<FName> FollowerInclusionExclusionList;

		UBOOL CharacterTemplatePermitted(const class UX2CharacterTemplate& TestTemplate, UBOOL TestLeaderInclusionExclusion) const;

		void Clear()
		{
			LeaderInclusionExclusionList.Clear();
			FollowerInclusionExclusionList.Clear();
			CiviliansRestricted = AdventRestricted = AliensRestricted = FALSE;
		}
	}
};

struct native PodSpawnInfo
{
	var XGAIGroup SpawnedPod;
	var Vector SpawnLocation;
	var float ExclusionDistance;
	var float MaxGroupSize;

	var ETeam Team;

	// The Name of this encounter, used for determining when a specific group has been engaged/defeated
	var Name EncounterID;

	// The list of character templates that have been selected to fill out this pod
	var deprecated array<X2CharacterTemplate> SelectedCharacterTemplates;
	var array<Name> SelectedCharacterTemplateNames;

	var int ForceLevelRestriction;

	// If true, this pod will not drop loot
	var bool bGroupDoesNotAwardLoot;


	// How wide should this group's encounter band be?
	var float EncounterZoneWidth;

	// How deep should this group's encounter band be?
	var float EncounterZoneDepth;

	// The offset from the LOP for this group.
	var float EncounterZoneOffsetFromLOP;

	// The offset along the LOP for this group.
	var float EncounterZoneOffsetAlongLOP;

	// If specified, this group will attempt to spawn on the tagged actor's location.  If no actor is found with this tag, Redscreen + do not spawn the group.
	var Name SpawnLocationActorTag;

	// Skip reinforcement soldier bark
	var bool SkipSoldierVO;

	// Encounter definition force spawn via psi gate
	var bool bForceSpawnViaPsiGate;
};


struct native EncounterZone
{
	var Vector2D Origin;
	var Vector2D SideA;
	var Vector2D SideB;
};

var int ForceLevel;
var int AlertLevel;
var bool AtMaxAlertLevel;
var XComGameState SpawnGameState;
var Vector XComSpawnLocationCache;
var Vector ObjectiveLocationCache;
var array<TTile> AllPossibleSpawnNodes;

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// 'Public' functions
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////////////////
// The Spawn Manager

// Get this singleton.
native static function XComAISpawnManager GetSpawnManager();

//------------------------------------------------------------------------------------------------
// Encounter Zone helpers
native static function EncounterZone BuildEncounterZone(
	const out Vector ObjectiveLoc, 
	const out Vector XComLoc, 
	float PatrolDepth,
	float PatrolWidth,
	float OffsetFromLOP,
	float OffsetAlongLOP);
native static function bool PointInEncounterZone(const out Vector TestPoint, const out EncounterZone TestZone);

//------------------------------------------------------------------------------------------------

// Spawn all NPC characters on the current map, using the specified ForceLevel and AlertLevel.
function native SpawnAllAliens(int InForceLevel, int InAlertLevel, XComGameState NewGameState, optional XComGameState_MissionSite MissionSiteState);

// Choose, based on current difficulty level, how much of a Force Level bump to provide for a pod leader in the pending mission
function native int GetLeaderForceLevelMod();

// Select the group members to fill out the specified ConfigurableEncounter, at the specified ForceLevel & AlertLevel
function native SelectSpawnGroup(
	out PodSpawnInfo SpawnInfo, 
	const out MissionDefinition MissionDef,
	const out ConfigurableEncounter Encounter, 
	int InForceLevel, 
	int InAlertLevel, 
	out Array<X2CharacterTemplate> SelectedCharacterTemplates, 
	out float AlienLeaderWeight,
	out float AlienFollowerWeight,
	out int LeaderForceLevelMod);

// Choose a location at which to spawn a reinforcements spawner
function native Vector SelectReinforcementsLocation(
	const ref XComGameState_AIReinforcementSpawner InstigatingSpawner,
	const out Vector TargetLocation,
	int IdealSpawnTilesOffset,
	bool bSpawnViaPsiGate);

function native SelectPodAtLocation(out PodSpawnInfo SpawnInfo, int InForceLevel, int InAlertLevel);

function native XGAIGroup SpawnPodAtLocation(ref XComGameState NewGameState, out PodSpawninfo SpawnInfo);

function native RollForTimedLoot(out Array<XComGameState_Unit> NewUnits, out ref XComGameState_HeadquartersXCom XComHQ, const out MissionSchedule CurrentMissionSchedule);

function native CleanupReplacementActorsOnLevelLoad();
function final native HookReplacementActorVisualizersOnLevelLoad();

// Spawn a particular unit of the specified character template type, associated with the specified team.  
// External call to support the DropUnit cheats
function StateObjectReference CreateUnit( Vector Position, Name CharacterTemplateName, ETeam Team, bool bAddToStartState, optional bool RollForLoot, optional XComGameState NewGameState, optional const XComGameState_Unit ReanimatedFromUnit = None, optional string CharacerPoolName )
{
	local XComGameState_Unit NewUnitState;
	local StateObjectReference NewUnitRef;
	local X2CharacterTemplate CharacterTemplate;
	local array<name> ValidNames;
	local name TemplateNameIt;
	local XComGameStateHistory History;
	local XComGameStateContext_TacticalGameRule StateChangeContainer;
	local X2GameRuleset RuleSet;
	local X2EventManager EventManager;
	local bool NeedsToSubmitGameState;
	local StateObjectReference ItemRef;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;

	CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharacterTemplateName);
	if( CharacterTemplate == None )
	{
		`log("No character template named" @ CharacterTemplateName @ "was found.");
		`Log("Valid character template names:");
		class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().GetTemplateNames(ValidNames);
		foreach ValidNames(TemplateNameIt)
		{
			`Log(TemplateNameIt);
		}
		return NewUnitRef;
	}

	if (bAddToStartState)
	{
		NewGameState = History.GetStartState();

		if(NewGameState == none)
		{
			`assert(false); // attempting to add to start state after the start state has been locked down!
		}
	}

	if( NewGameState == None )
	{		
		StateChangeContainer = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());
		StateChangeContainer.GameRuleType = eGameRule_UnitAdded;
		NewGameState = History.CreateNewGameState(true, StateChangeContainer);
		NeedsToSubmitGameState = true;
	}
	else
	{
		NeedsToSubmitGameState = false;
	}

	NewUnitState = CreateUnitInternal(Position, CharacterTemplate, Team, NewGameState, RollForLoot, true, ReanimatedFromUnit, CharacerPoolName);

	RuleSet = `XCOMGAME.GameRuleset;
	`assert(RuleSet != none);

	// Trigger that this unit has been spawned
	EventManager = `XEVENTMGR;
	EventManager.TriggerEvent('UnitSpawned', NewUnitState, NewUnitState);

	// make sure any cosmetic units have also been created
	foreach NewUnitState.InventoryItems(ItemRef)
	{
		ItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(ItemRef.ObjectID));
		ItemState.CreateCosmeticItemUnit(NewGameState);
	}

	if( NeedsToSubmitGameState )
	{
		// Update the context about the unit we are added
		XComGameStateContext_TacticalGameRule(NewGameState.GetContext()).UnitRef = NewUnitState.GetReference();

		if( !RuleSet.SubmitGameState(NewGameState) )
		{
			`log("WARNING! DropUnit could not add NewGameState to the history because the rule set disallowed it!");
		}
	}

	return NewUnitState.GetReference();
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// 'Private' functions
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

// Internal call to construct a unit of a particular CharacterTemplate type, at the specified Position, on the 
// specified team, as part of the specified game state.
private event XComGameState_Unit CreateUnitInternal( Vector Position, X2CharacterTemplate CharacterTemplate, ETeam Team, XComGameState NewGameState, bool bRollForLoot, bool PerformAIUpdate, XComGameState_Unit ReanimatedFromUnit, optional string CharacerPoolName )
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Player PlayerState;
	local bool bUsingStartState, bFoundExistingPlayerState;
	local TTile UnitTile;

	History = `XCOMHISTORY;

	bUsingStartState = (NewGameState == History.GetStartState());

	// find the player matching the requested team ID... 
	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if( PlayerState.GetTeam() == Team )
		{
			bFoundExistingPlayerState = true;
			break;
		}
	}

	// ... or create one if it does not yet exist
	if( !bFoundExistingPlayerState )
	{
		PlayerState = class'XComGameState_Player'.static.CreatePlayer(NewGameState, Team);
		NewGameState.AddStateObject(PlayerState);
	}
	
	// create the unit
	UnitTile = `XWORLD.GetTileCoordinatesFromPosition(Position);
	UnitState = CharacterTemplate.CreateInstanceFromTemplate(NewGameState);
	UnitState.PostCreateInit(NewGameState, CharacterTemplate, PlayerState.ObjectID, UnitTile, Team == eTeam_Alien, bUsingStartState, PerformAIUpdate, ReanimatedFromUnit, CharacerPoolName);

	// Auto loot
	UnitState.bAutoLootEnabled = bRollForLoot;

	//// Timed Loot
	//if( bRollForTimedLoot )
	//{
	//	UnitState.RollForTimedLoot();
	//}

	if( !CharacterTemplate.bIsCosmetic && `PRES.m_kUnitFlagManager != none )
	{
		`PRES.m_kUnitFlagManager.AddFlag(UnitState.GetReference());
	}

	return UnitState;
}

private event UpdateAIPlayerData(XComGameState NewGameState)
{
	local XComGameState_AIPlayerData kPlayerData;
	local XGAIPlayer kAIPlayer;
	local int iAIDataID;

	kAIPlayer = XGAIPlayer(`BATTLE.GetAIPlayer());
	if( kAIPlayer != None )
	{
		iAIDataID = kAIPlayer.GetAIDataID();
		kPlayerData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(iAIDataID));
		if( kPlayerData != None )
		{
			kPlayerData = XComGameState_AIPlayerData(NewGameState.CreateStateObject(class'XComGameState_AIPlayerData', iAIDataID));
			kPlayerData.UpdateGroupData(NewGameState);
			NewGameState.AddStateObject(kPlayerData);
		}
	}
}

// Calculate the average location amongs all living XCom team members
native function Vector GetCurrentXComLocation();

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// Debugging functions
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

// TODO: this should ideally be implemented natively
static function Vector CastVector(Vector2D V2D)
{
	local Vector V;
	V.X = V2D.X;
	V.Y = V2D.Y;
	return V;
}

simulated function DrawDebugLabel(Canvas InCanvas)
{
	local SimpleShapeManager ShapeManager;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComTacticalMissionManager MissionManager;
	local MissionSchedule ActiveMissionSchedule;
	local XComGameState_AIGroup AIGroup;
	local XComGameState_Unit AIUnitState;
	local Vector ScaleVector;
	local Vector GroupLocation;
	local Vector ScreenPosition;
	local Vector XComLocation;
	local StateObjectReference AIRef;
	local string DebugString, GroupDebugString;
	local int AICount, AdventCount, AlienCount;
	local array<float> EncounterZoneWidths, EncounterZoneDepths, EncounterZoneOffsetFromLOPs, EncounterZoneOffsetAlongLOPs;
	local int CurrentEncounterZoneIndex;
	local EncounterZone DebugEncounterZone;
	local Vector CornerA, CornerB, CornerC, CornerD;
	local float SightRadius;
	local XGBattle Battle;
	local float XComToObjectiveTiles;

	Battle = `BATTLE;

	AICount = 0;
	AdventCount = 0;
	AlienCount = 0;
	ShapeManager = `SHAPEMGR;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	MissionManager = `TACTICALMISSIONMGR;
	MissionManager.GetActiveMissionSchedule(ActiveMissionSchedule);

	ScaleVector = vect(64, 64, 64);

	// drop the XCom start location and Objective location in Blue
	ShapeManager.DrawSphere(BattleData.MapData.SoldierSpawnLocation, ScaleVector, MakeLinearColor(0, 0, 1, 1));
	ShapeManager.DrawSphere(BattleData.MapData.ObjectiveLocation, ScaleVector, MakeLinearColor(0, 0, 1, 1));
	ShapeManager.DrawLine(BattleData.MapData.SoldierSpawnLocation, BattleData.MapData.ObjectiveLocation, 4, MakeLinearColor(0, 0, 1, 1));

	// draw XCom's current calculated location in Green
	XComLocation = GetCurrentXComLocation();
	ShapeManager.DrawSphere(XComLocation, ScaleVector, MakeLinearColor(0, 1, 0, 1));
	ShapeManager.DrawLine(XComLocation, BattleData.MapData.ObjectiveLocation, 8, MakeLinearColor(0, 1, 0, 1));

	SightRadius = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Soldier').CharacterBaseStats[eStat_SightRadius];
	Battle.DrawDebugCylinder(XComLocation, XComLocation + Vect(0, 0, 8), `METERSTOUNITS(SightRadius), 16, 0, 255, 0);

	DebugString = "===================================\n";
	DebugString $= "=======    Encounter Groups   ========\n";
	DebugString $= "===================================\n";

	// draw each AI group's current location in Purple and projected intercept in Orange
	foreach History.IterateByClassType(class'XComGameState_AIGroup', AIGroup)
	{
		// current location
		GroupLocation = AIGroup.GetGroupMidpoint();
		ShapeManager.DrawSphere(GroupLocation, ScaleVector, MakeLinearColor(1, 0, 1, 1));

		ScreenPosition = InCanvas.Project(GroupLocation);
		ScreenPosition.X += 10;
		ScreenPosition.Y -= 10;
		InCanvas.SetPos(ScreenPosition.X, ScreenPosition.Y);
		InCanvas.SetDrawColor(255, 0, 255);

		if( AIGroup.TurnCountForLastDestination >= 0 )
		{
			ShapeManager.DrawSphere(AIGroup.CurrentTargetLocation, ScaleVector, MakeLinearColor(1, 0.62, 0.224, 1));
			ShapeManager.DrawLine(GroupLocation, AIGroup.CurrentTargetLocation, 4, MakeLinearColor(1, 0.62, 0.224, 1));
		}

		GroupDebugString = string(AIGroup.EncounterID);
		if( AIGroup.MyEncounterZoneWidth < 10 )
		{
			GroupDebugString $= "  (Guard)";
		}
		InCanvas.DrawText(GroupDebugString);

		CurrentEncounterZoneIndex = EncounterZoneOffsetAlongLOPs.Find(AIGroup.MyEncounterZoneOffsetAlongLOP);
		if( CurrentEncounterZoneIndex == INDEX_NONE ||
			EncounterZoneWidths[CurrentEncounterZoneIndex] != AIGroup.MyEncounterZoneWidth ||
			EncounterZoneDepths[CurrentEncounterZoneIndex] != AIGroup.MyEncounterZoneDepth ||
			EncounterZoneOffsetFromLOPs[CurrentEncounterZoneIndex] != AIGroup.MyEncounterZoneOffsetFromLOP )
		{
			EncounterZoneWidths.AddItem(AIGroup.MyEncounterZoneWidth);
			EncounterZoneDepths.AddItem(AIGroup.MyEncounterZoneDepth);
			EncounterZoneOffsetFromLOPs.AddItem(AIGroup.MyEncounterZoneOffsetFromLOP);
			EncounterZoneOffsetAlongLOPs.AddItem(AIGroup.MyEncounterZoneOffsetAlongLOP);
		}

		// debug group list
		DebugString $= "\n(" $ AIGroup.MyEncounterZoneOffsetAlongLOP $ ")  " $ GroupDebugString $ "\n    ->";

		foreach AIGroup.m_arrMembers(AIRef)
		{
			AIUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIRef.ObjectID));
			DebugString $= "[" $ AIRef.ObjectID $ "]  " $ AIUnitState.GetMyTemplateName() $ "\n        ";

			++AICount;

			if( AIUnitState.IsAlien() )
			{
				++AlienCount;
			}
			else
			{
				++AdventCount;
			}
		}
	}

	InCanvas.SetPos(10, 150);
	InCanvas.SetDrawColor(0, 0, 0, 125);
	InCanvas.DrawRect(400, 450);

	// draw the text
	InCanvas.SetPos(15, 155);
	InCanvas.SetDrawColor(0, 255, 0);
	InCanvas.DrawText(DebugString);

	// additional mission info
	DebugString = "Mission = "$ ActiveMissionSchedule.ScheduleID
		$ ", Force Level = "$ BattleData.GetForceLevel()
		$ ", Alert Level = " $ BattleData.GetAlertLevel()
		$ ", Alien = " $ AlienCount
		$ ", Advent = " $ AdventCount
		$ ", Total = " $ AICount
		$ ", Difficulty = " $ `DIFFICULTYSETTING;

	// draw a background box so the text is readable
	InCanvas.SetPos(395, 5);
	InCanvas.SetDrawColor(0, 0, 0, 125);
	InCanvas.DrawRect(500, 20);

	InCanvas.SetPos(400, 10);
	InCanvas.SetDrawColor(0, 150, 255);
	InCanvas.DrawText(DebugString);


	// draw the encounter zones
	for( CurrentEncounterZoneIndex = 0; CurrentEncounterZoneIndex < EncounterZoneOffsetAlongLOPs.Length; ++CurrentEncounterZoneIndex )
	{
		DebugEncounterZone = BuildEncounterZone(
			BattleData.MapData.ObjectiveLocation, 
			XComLocation,
			EncounterZoneDepths[CurrentEncounterZoneIndex],
			EncounterZoneWidths[CurrentEncounterZoneIndex],
			EncounterZoneOffsetFromLOPs[CurrentEncounterZoneIndex],
			EncounterZoneOffsetAlongLOPs[CurrentEncounterZoneIndex]);

		CornerA = CastVector(DebugEncounterZone.Origin);
		CornerA.Z = BattleData.MapData.ObjectiveLocation.Z;
		CornerB = CornerA + CastVector(DebugEncounterZone.SideA);
		CornerC = CornerB + CastVector(DebugEncounterZone.SideB);
		CornerD = CornerA + CastVector(DebugEncounterZone.SideB);
		ShapeManager.DrawLine(CornerA, CornerB, 8, MakeLinearColor(1, 1, 0, 1));
		ShapeManager.DrawLine(CornerB, CornerC, 8, MakeLinearColor(1, 1, 0, 1));
		ShapeManager.DrawLine(CornerC, CornerD, 8, MakeLinearColor(1, 1, 0, 1));
		ShapeManager.DrawLine(CornerD, CornerA, 8, MakeLinearColor(1, 1, 0, 1));
	}

	// draw the turret zone in purple
	XComToObjectiveTiles = VSize2D(BattleData.MapData.ObjectiveLocation - XComLocation) / class'XComWorldData'.const.WORLD_StepSize;
	DebugEncounterZone = BuildEncounterZone(
		BattleData.MapData.ObjectiveLocation,
		XComLocation,
		XComToObjectiveTiles - ActiveMissionSchedule.TurretZoneObjectiveOffset,
		ActiveMissionSchedule.TurretZoneWidth,
		0.0,
		ActiveMissionSchedule.TurretZoneObjectiveOffset);

	CornerA = CastVector(DebugEncounterZone.Origin);
	CornerA.Z = BattleData.MapData.ObjectiveLocation.Z;
	CornerB = CornerA + CastVector(DebugEncounterZone.SideA);
	CornerC = CornerB + CastVector(DebugEncounterZone.SideB);
	CornerD = CornerA + CastVector(DebugEncounterZone.SideB);
	ShapeManager.DrawLine(CornerA, CornerB, 8, MakeLinearColor(1, 0, 1, 1));
	ShapeManager.DrawLine(CornerB, CornerC, 8, MakeLinearColor(1, 0, 1, 1));
	ShapeManager.DrawLine(CornerC, CornerD, 8, MakeLinearColor(1, 0, 1, 1));
	ShapeManager.DrawLine(CornerD, CornerA, 8, MakeLinearColor(1, 0, 1, 1));
}

function int GetTotalPointValue()
{
	local int TotalPoints;
	local XGAIGroup AIGroup;

	TotalPoints = 0;

	foreach `BATTLE.DynamicActors(class'XGAIGroup', AIGroup)
	{
		TotalPoints += AIGroup.GetGroupPointTotal();
	}

	return TotalPoints;
}

//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------
// cpptext
//------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------

cpptext
{
private:
	// Initialize this SpawnManager with all the information it needs to perform spawning.
	void PreSpawnInit(TArray<FTTile>& XComOccupiedTiles);
	void PostSpawnInit(INT NumGameStateObjectsPreSpawn);

	// Spawn all pre-placed units at the start of a mission
	void SpawnPreSpawnGroups(const TArray<FTTile>& XComOccupiedTiles, UXComGameState_MissionSite* MissionSiteState);
		
	// Select turrets onto the map according to the turret markup for the entire map.
	void SelectAndSpawnTurrets(const TArray<FTTile>& XComOccupiedTiles);

	// Select and Spawn a set of civilians on the map.
	void SelectAndSpawnCivilians(const TArray<FTTile>& XComOccupiedTiles);

	// Select and spawn replacement hackables on the map
	void SelectAndSpawnHackables();

	//------------------------------------------------------------------------------------------------

	// Determine if a particular spawn node is a valid spawn node given the state of all existing pods within the space.
	UBOOL NodeValidatesForSpawning( 
		const FPodSpawnInfo& PodSpawnInfo, 
		const TArray<FPodSpawnInfo>& ExistingPods, 
		const FCombinedSpawnRestrictions* SpawnRestrictions,
		UBOOL CheckLeaderCanSpawn);

	// Select a set of characters to fill out this pod.
	void SelectPodMembers(
		FPodSpawnInfo& PodSpawnInfo,
		FLOAT& LeaderIsAlienChance,
		FLOAT& FollowersAreAlienChance,
		const FCombinedSpawnRestrictions& SpawnRestrictions, 
		TArray<UX2CharacterTemplate*>& SelectedCharacterTemplates,
		INT LeaderForceLevelMod);

	// Spawn the specified pod of characters.
	void SpawnPod(FPodSpawnInfo& PodSpawnInfo, const TArray<FTTile>* RequiredNoLOSTiles, UBOOL bAllowSpawnInHazards);

	// Generates the location-specific spawn restrictions imposed by the level.
	void GetSpawnRestrictionsForLocation( FCombinedSpawnRestrictions& SpawnRestrictions, const FVector& SpawnLocation) const;

	// Select a turret type.
	const UX2CharacterTemplate* GetTurretTemplate(const class AXComTurretSelector& TurretSelector) const;

	// Select the Civilian type
	const UX2CharacterTemplate* SelectCivilianTemplate() const;
		
	// Select the leader of a pod.
	const UX2CharacterTemplate* SelectPodLeader( 
		UBOOL SelectAlien,
		const FPodSpawnInfo& SpawnInfo, 
		const FCombinedSpawnRestrictions& SpawnRestrictions,
		const TArray<UX2CharacterTemplate*>& SelectedCharacterTemplates) const;

	// Select a follower within a pod that already has a leader.
	const UX2CharacterTemplate* SelectPodFollower( 
		const UX2CharacterTemplate& PodLeader, 
		UBOOL SelectAlien,
		const FPodSpawnInfo& SpawnInfo, 
		const FCombinedSpawnRestrictions& SpawnRestrictions,
		const TArray<UX2CharacterTemplate*>& SelectedCharacterTemplates) const;

	// Spawn a specific character type into the map using the specified pod.
	UXComGameState_Unit* SpawnCharacterIntoPod(
		const UX2CharacterTemplate& CharacterTemplate,
		FPodSpawnInfo& SpawnInfo,
		const TArray<FTTile>* RequiredNoLOSTiles,
		UBOOL bAllowSpawnInHazards);

	// Search the area around the group location for a viable spawn point for the specified character.
	UBOOL FindSpawnLocationForCharacter(
		const UX2CharacterTemplate& CharacterTemplate,
		const AXGAIGroup& AIGroup,
		const TArray<FTTile>* RequiredNoLOSTiles,
		FTTile& OutSelectedTile,
		UBOOL bAllowSpawnInHazards) const;

	// Search the area around the specified tile location for a viable spawn point for the specified character.
	// If RequireClearSkiesAbove is TRUE, this function will only return resulting tiles that have vertical clearance to the top of the world.
	UBOOL FindSpawnLocationWithLOS(
		const UX2CharacterTemplate& CharacterTemplate,
		const FTTile& TargetTile,
		INT IdealSpawnDistance,
		const TArray<FTTile>* RequiredLOSTiles,
		const TArray<FTTile>* RequiredNoLOSTiles,
		FLOAT MaxSightRangeMeters,
		FTTile& OutSelectedTile,
		UBOOL bRequiresVerticalClearance,
		UBOOL bAllowSpawnInHazards) const;

	// Check if the specified tile is a viable spawn location for the given character template.
	UBOOL CanCharacterSpawnInTile(
		const FTTile& TargetTile,
		const UX2CharacterTemplate& CharacterTemplate,
		const TArray<FTTile>* RequiredLOSTiles,
		const TArray<FTTile>* RequiredNoLOSTiles,
		FLOAT MaxSightRangeMeters,
		UBOOL bRequiresVerticalClearance,
		UBOOL bAllowSpawnInHazards) const;

	// Determine if any of the RequiredLOSTiles have line of sight to the target tile
	UBOOL AnyLOSToTile(const FTTile& TargetTile, const TArray<FTTile>& RequiredLOSTiles, FLOAT MaxSightRangeMeters) const;

	// Helper to merge the general ForceLevel/AlertLevel configuration data defined on this SpawnManager 
	// with the Encounter specific spawn information specified, applying the results to the NewSpawnInfo
	void ApplyConfigurableEncounterToSpawnData(
		const FConfigurableEncounter& EncounterConfig, 
		FPodSpawnInfo& NewSpawnInfo,
		INT BaseForceLevel,
		INT BaseAlertLevel);

	// Update the cache of all possible spawn nodes for this spawn manager
	void CacheAllPossibleSpawnNodes();

	// Randomize the order of processing the list of available spawn nodes
	void RandomizePossibleSpawnNodes();
}

defaultproperties
{
	Begin Object Class=DistributionFloatConstantCurve Name=ForceLevelToIdealPodPointValueCurveDistribution
		ConstantCurve=(Points=((InVal=1.0,OutVal=15.0),(InVal=20.0,OutVal=75.0)))
	End Object
	ForceLevelToIdealPodPointValueCurve=(Distribution=ForceLevelToIdealPodPointValueCurveDistribution)

	Begin Object Class=DistributionFloatConstantCurve Name=ALTPPVMCD
	ConstantCurve=(Points=((InVal=0.0, OutVal=0.5), (InVal=1000.0, OutVal=1.5)))
	End Object
	AlertLevelToPodPointValueModifierCurve=(Distribution=ALTPPVMCD)

	Begin Object Class=DistributionFloatConstantCurve Name=NDTPWCD
	ConstantCurve=(Points=((InVal=0.0, OutVal=0.5), (InVal=1.0, OutVal=1.5)))
	End Object
	NormalizedDistanceToPatrolWeightingCurve=(Distribution=NDTPWCD)

	XComExclusionDistance=27.0
	CivilianExclusionDistance=32.0
	BaseExclusionRange=16.0
	BaseRoamRange=24.0
	IdealPodMemberSpawnDistance=3
	PointOverageModifier=1.0
	MinReinforcementAngleOffset=60.0
	MaxReinforcementAngleOffset=120.0
	MaxGroupSizeTakesPrecedenceOverPointValues=true


	MinRequiredHackSpawnDistance=2000.0
	IdealHackDistanceToLOP=4000.0
	HackDistanceToLOPWeight=1000.0
	HackDistanceRandomWeight=4000.0
}
