class X2Effect_GenerateCover extends X2Effect_Persistent
	dependson(XComCoverInterface);

var ECoverForceFlag CoverType;
var bool bRemoveWhenMoved;
var bool bRemoveOnOtherActivation;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (bRemoveWhenMoved)
		EventMgr.RegisterForEvent(EffectObj, 'ObjectMoved', EffectGameState.GenerateCover_ObjectMoved, ELD_OnStateSubmitted, , UnitState);
	else
		EventMgr.RegisterForEvent(EffectObj, 'ObjectMoved', EffectGameState.GenerateCover_ObjectMoved_UpdateVisualization, ELD_OnVisualizationBlockCompleted, , UnitState);

	if (bRemoveOnOtherActivation)
		EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', EffectGameState.GenerateCover_AbilityActivated, ELD_OnStateSubmitted, , UnitState);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != None)
	{
		UnitState.bGeneratesCover = true;
		UnitState.CoverForceFlag = CoverType;
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != None)
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.bGeneratesCover = false;
		UnitState.CoverForceFlag = CoverForce_Default;
		NewGameState.AddStateObject(UnitState);
	}

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);
	UpdateWorldCoverData(XComGameState_Unit(BuildTrack.StateObject_NewState), VisualizeGameState);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);
	UpdateWorldCoverData(XComGameState_Unit(BuildTrack.StateObject_NewState), VisualizeGameState);
}

static function UpdateWorldCoverData(XComGameState_Unit NewUnitState, XComGameState GameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit OldUnitState;
	local int EventChainIdx;

	History = `XCOMHISTORY;
	EventChainIdx = GameState.GetContext().EventChainStartIndex;
	if (EventChainIdx != INDEX_NONE)
	{
		OldUnitState = XComGameState_Unit(History.GetGameStateForObjectID(NewUnitState.ObjectID, , EventChainIdx - 1));
	}
	else
	{
		OldUnitState = XComGameState_Unit(History.GetPreviousGameStateForObject(NewUnitState));
	}
	`assert(OldUnitState != none);
	if (OldUnitState.TileLocation == NewUnitState.TileLocation)
	{
		OldUnitState = XComGameState_Unit(History.GetPreviousGameStateForObject(OldUnitState));
	}	

	DoRebuildTile(NewUnitState.TileLocation);

	if ((OldUnitState.TileLocation != NewUnitState.TileLocation) && !`XWORLD.IsTileOutOfRange(OldUnitState.TileLocation));        //  will not be different at tactical match startup
		DoRebuildTile(OldUnitState.TileLocation);
}

protected static function DoRebuildTile(const out TTile OriginalTile)
{
	local XComWorldData WorldData;
	local TTile RebuildTile;
	local array<TTile> ChangeTiles;
	local StateObjectReference UnitRef;
	local XGUnit Unit;
	local CachedCoverAndPeekData CachedData;

	local array<StateObjectReference> Units;
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	WorldData = `XWORLD;

	RebuildTile = OriginalTile;
	RebuildTile.X -= 1;
	ChangeTiles.AddItem( RebuildTile );
	RebuildTile.X += 2;
	ChangeTiles.AddItem( RebuildTile );

	RebuildTile = OriginalTile;
	RebuildTile.Y -= 1;
	ChangeTiles.AddItem( RebuildTile );
	RebuildTile.Y += 2;
	ChangeTiles.AddItem( RebuildTile );

	foreach ChangeTiles(RebuildTile)
	{
		WorldData.DebugRebuildTileData( RebuildTile );

		UnitRef = WorldData.GetUnitOnTile( RebuildTile );
		if (UnitRef.ObjectID > 0)
		{
			Unit = XGUnit( `XCOMHISTORY.GetVisualizer( UnitRef.ObjectId ) );
			if (Unit != none)
			{
				WOrldData.CacheVisibilityDataForTile( RebuildTile, CachedData );
				Unit.IdleStateMachine.CheckForStanceUpdate();
				Units.AddItem( UnitRef );
			}
			}
		}

	if (Units.Length > 0)
	{
		`XCOMHISTORY.RemoveHistoryLock( );
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "GenerateCover effect" );

		foreach Units(UnitRef)
		{
			NewUnitState = XComGameState_Unit( NewGameState.CreateStateObject( class'XComGameState_Unit', UnitRef.ObjectID ) );
			NewUnitState.bRequiresVisibilityUpdate = true;
			NewGameState.AddStateObject( NewUnitState );
		}

		`TACTICALRULES.SubmitGameState( NewGameState );
		`XCOMHISTORY.AddHistoryLock( );
	}
}

DefaultProperties
{
	CoverType = CoverForce_High
	EffectName = "GenerateCover"
	DuplicateResponse = eDupe_Ignore
	bRemoveWhenMoved = true
	bRemoveOnOtherActivation = true
}