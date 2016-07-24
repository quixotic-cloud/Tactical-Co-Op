//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ShowSpawnedUnit extends X2Action;

var bool bUseOverride;
var vector OverrideVisualizationLocation;
var Rotator OverrideFacingRot;
var bool bWaitToShow, bReceivedShowMessage;
var protected TTile		CurrentTile;

// list of all units to unhide, both the original actor and his attached cosmetics
var protected array<XGUnit> UnitsToUnhide;

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference ItemRef;
	local XComGameState_Item ItemState;
	local XComGameState_Unit CosmeticUnit;
	local XGUnit CosmeticUnitVisualizer;

	super.Init(InTrack);

	UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
	`assert(UnitState != none);

	// if our visualizer hasn't been created yet, make sure it is created here.
	if (Unit == none)
	{
		UnitState.SyncVisualizer(StateChangeContext.AssociatedState);
		Unit = XGUnit(UnitState.GetVisualizer());
		`assert(Unit != none);
	}

	UnitsToUnhide.AddItem(Unit);

	History = `XCOMHISTORY;

	// also show all of the unit's cosmetic units
	foreach UnitState.InventoryItems(ItemRef)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
		if(ItemState != none && ItemState.CosmeticUnitRef.ObjectID > 0)
		{
			CosmeticUnit = XComGameState_Unit(History.GetGameStateForObjectID(ItemState.CosmeticUnitRef.ObjectID,, StateChangeContext.AssociatedState.HistoryIndex));
			CosmeticUnit.SyncVisualizer(StateChangeContext.AssociatedState);
			CosmeticUnitVisualizer = XGUnit(CosmeticUnit.GetVisualizer()); 
			`assert(CosmeticUnitVisualizer != none);

			UnitsToUnhide.AddItem(CosmeticUnitVisualizer);
		}
	}
}

function HandleTrackMessage()
{
	bReceivedShowMessage = true;
}

function bool CheckInterrupted()
{
	return false;
}

function ChangeTimeoutLength( float newTimeout )
{
	TimeoutSeconds = newTimeout;
}

protected function PrepareToShowUnits()
{
	local XGUnit ShownUnit;
	local XComUnitPawn ShownUnitPawn;

	foreach UnitsToUnhide(ShownUnit)
	{
		ShownUnitPawn = ShownUnit.GetPawn();

		if( bUseOverride )
		{
			OverrideVisualizationLocation.Z = ShownUnit.GetDesiredZForLocation(OverrideVisualizationLocation);

			ShownUnitPawn.SetLocation(OverrideVisualizationLocation);
			ShownUnitPawn.SetRotation(OverrideFacingRot);
		}

		CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);

		ShownUnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		ShownUnitPawn.RestoreAnimSetsToDefault();
		ShownUnitPawn.UpdateAnimations();

		ShownUnit.IdleStateMachine.PlayIdleAnim();
	}
}

protected function ClearForceHiddenFlags()
{
	local XGUnit ShownUnit;

	foreach UnitsToUnhide(ShownUnit)
	{
		ShownUnit.m_bForceHidden = false;
	}
}

simulated state Executing
{
Begin:
	PrepareToShowUnits();

	while( bWaitToShow && !bReceivedShowMessage )
	{
		Sleep(0.0f);
	}

	ClearForceHiddenFlags();

	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);

	CompleteAction();
}

DefaultProperties
{
	bUseOverride=false
	bWaitToShow=false
}
