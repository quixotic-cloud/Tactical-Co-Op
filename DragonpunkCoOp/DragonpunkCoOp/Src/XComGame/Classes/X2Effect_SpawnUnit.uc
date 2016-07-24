class X2Effect_SpawnUnit extends X2Effect_Persistent
	abstract;

var name UnitToSpawnName;
var bool bClearTileBlockedByTargetUnitFlag; // The spawned unit will be placed in the same tile as the target
var bool bCopyTargetAppearance;
var bool bKnockbackAffectsSpawnLocation;

var private name SpawnUnitTriggerName;
var privatewrite name SpawnedUnitValueName;
var private name SpawnedThisTurnUnitValueName;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnitState;

	TargetUnitState = XComGameState_Unit(kNewTargetState);
	`assert(TargetUnitState != none);

	TriggerSpawnEvent(ApplyEffectParameters, TargetUnitState, NewGameState);
}

// It is possible this effect gets added to a unit the same turn it is knocked back. The Knockback sets the target unit's
// tile location in ApplyEffectToWorld, so this possibly needs to update the spawned unit's location as well.
simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnitState, SpawnedUnitState;
	local UnitValue SpawnedUnitValue;
	local TTile TargetUnitTile, SpawnedUnitTile;

	if( bKnockbackAffectsSpawnLocation )
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_Unit', TargetUnitState)
		{
			if( TargetUnitState.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedThisTurnUnitValueName, SpawnedUnitValue) )
			{
				SpawnedUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(SpawnedUnitValue.fValue));
				if( SpawnedUnitState != none )
				{
					TargetUnitState.NativeGetKeystoneVisibilityLocation(TargetUnitTile);
					SpawnedUnitState.NativeGetKeystoneVisibilityLocation(SpawnedUnitTile);

					if( TargetUnitTile != SpawnedUnitTile )
					{
						SpawnedUnitState.SetVisibilityLocation(TargetUnitTile);
					}
				}

				SpawnedUnitValue.fValue = 0;
				TargetUnitState.ClearUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedThisTurnUnitValueName);
			}
		}
	}
}

function TriggerSpawnEvent(const out EffectAppliedData ApplyEffectParameters, XComGameState_Unit EffectTargetUnit, XComGameState NewGameState)//, XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit TargetUnitState, SpawnedUnit, CopiedUnit;
	local XComGameStateHistory History;
	local XComAISpawnManager SpawnManager;
	local StateObjectReference NewUnitRef;
	local XComWorldData World;
	local XComGameState_AIGroup GroupState;

	History = `XCOMHISTORY;
	SpawnManager = `SPAWNMGR;
	World = `XWORLD;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(TargetUnitState != none);

	if( bClearTileBlockedByTargetUnitFlag )
	{
		World.ClearTileBlockedByUnitFlag(TargetUnitState);
	}

	if( bCopyTargetAppearance )
	{
		CopiedUnit = TargetUnitState;
	}

	// Spawn the new unit
	NewUnitRef = SpawnManager.CreateUnit(GetSpawnLocation(ApplyEffectParameters), GetUnitToSpawnName(ApplyEffectParameters), GetTeam(ApplyEffectParameters), false, false, NewGameState, CopiedUnit);
	SpawnedUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	SpawnedUnit.bTriggerRevealAI = false;
	// Don't allow scamper
	GroupState = SpawnedUnit.GetGroupMembership(NewGameState);
	if( GroupState != None )
	{
		GroupState = XComGameState_AIGroup(NewGameState.CreateStateObject(class'XComGameState_AIGroup', GroupState.ObjectID));
		GroupState.bProcessedScamper = true;
		NewGameState.AddStateObject(GroupState);
	}

	EffectTargetUnit.SetUnitFloatValue(default.SpawnedUnitValueName, NewUnitRef.ObjectID, eCleanup_BeginTurn);
	EffectTargetUnit.SetUnitFloatValue(default.SpawnedThisTurnUnitValueName, NewUnitRef.ObjectID, eCleanup_BeginTurn);

	OnSpawnComplete(ApplyEffectParameters, NewUnitRef, NewGameState);
}

function name GetUnitToSpawnName(const out EffectAppliedData ApplyEffectParameters)
{
	return UnitToSpawnName;
}

// Returns a vector that the new unit should be spawned in given TileLocation
function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters)
{
	local XComWorldData World;
	local XComGameState_Unit TargetUnitState;
	local XComGameStateHistory History;
	local vector SpawnLocation;

	World = `XWORLD;
	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(TargetUnitState != none);

	SpawnLocation = World.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);

	return SpawnLocation;
}

// Helper functions to quickly get teams for inheriting classes
protected function ETeam GetTargetUnitsTeam(const out EffectAppliedData ApplyEffectParameters, optional bool UseOriginalTeam=false)
{
	local XComGameState_Unit TargetUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Defaults to the team of the unit that this effect is on
	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(TargetUnit != none);

	if( UseOriginalTeam )
	{
		return GetUnitsOriginalTeam(TargetUnit);
	}

	return TargetUnit.GetTeam();
}

protected function ETeam GetSourceUnitsTeam(const out EffectAppliedData ApplyEffectParameters, optional bool UseOriginalTeam=false)
{
	local XComGameState_Unit SourceUnit;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// Defaults to the team of the unit that this effect is on
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(SourceUnit != none);

	if( UseOriginalTeam )
	{
		return GetUnitsOriginalTeam(SourceUnit);
	}

	return SourceUnit.GetTeam();
}

// Things like mind control may change a unit's team. This grabs the team the unit was originally on.
protected function ETeam GetUnitsOriginalTeam(const out XComGameState_Unit UnitGameState)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	// find the original game state for this unit
	UnitState = XComGameState_Unit(History.GetOriginalGameStateRevision(UnitGameState.ObjectID));
	`assert(UnitState != none);

	return UnitState.GetTeam();
}

// Find the units that were spawned this GameState
static function FindNewlySpawnedUnit(XComGameState VisualizeGameState, out array<XComGameState_Unit> SpawnedUnits)
{
	local XComGameStateHistory History;
	local XComGameState_Unit SpawnedUnit;
	local XComGameState_Unit ExistedPreviousFrame;
	local int NumGameStates;
	local int scan;

	History = `XCOMHISTORY;

	NumGameStates = VisualizeGameState.GetNumGameStateObjects();
	SpawnedUnits.Length = 0;

	for( scan = 0; scan < NumGameStates; ++scan )
	{
		SpawnedUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectIndex(scan));
		if( SpawnedUnit != None )
		{
			// If we exist in this game state but not the previous one we are a new unit
			ExistedPreviousFrame = XComGameState_Unit(History.GetGameStateForObjectID(SpawnedUnit.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
			if( ExistedPreviousFrame == None )
			{
				SpawnedUnits.AddItem(SpawnedUnit);
			}
		}
	}
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationTrack SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationTrack EffectTargetUnitTrack )
{
	class'X2Action_ShowSpawnedUnit'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context);
}

// Get the team that this unit should be added to
function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters);

// Any clean up or final updates that need to occur after the unit is spawned
function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState);

defaultproperties
{
	SpawnUnitTriggerName="SpawnUnit"
	SpawnedUnitValueName="SpawnedUnitValue"
	SpawnedThisTurnUnitValueName="SpawnedThisTurnUnitValue"
	bClearTileBlockedByTargetUnitFlag=false
	bCopyTargetAppearance=false
	bKnockbackAffectsSpawnLocation=true

	DuplicateResponse=eDupe_Allow
	bCanBeRedirected=false
}