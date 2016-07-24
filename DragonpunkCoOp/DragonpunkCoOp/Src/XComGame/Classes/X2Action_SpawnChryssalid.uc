//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SpawnChryssalid extends X2Action;

var vector VisualizationLocation;
var Rotator FacingRot;

var private CustomAnimParams Params;
var private AnimNodeSequence PlayingSequence;

var protected TTile		CurrentTile;

function Init(const out VisualizationTrack InTrack)
{
	local XComGameState_Unit UnitState;

	super.Init(InTrack);

	// if our visualizer hasn't been created yet, make sure it is created here.
	if (Unit == none)
	{
		UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
		`assert(UnitState != none);

		UnitState.SyncVisualizer(StateChangeContext.AssociatedState);
		Unit = XGUnit(UnitState.GetVisualizer());
		`assert(Unit != none);
	}

	Params.AnimName = 'NO_CocoonHatch';
	Params.BlendTime = 0.0f;
	Params.HasDesiredEndingAtom = true;
	Params.DesiredEndingAtom.Scale = 1.0f;
	Params.DesiredEndingAtom.Translation = Unit.Location;
	Params.DesiredEndingAtom.Rotation = QuatFromRotator(FacingRot);
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:
	// Update the visibility
	VisualizationLocation.Z = Unit.GetDesiredZForLocation(VisualizationLocation);

	// Set the pawn's location and rotation to jump into the desired tile
	UnitPawn.SetLocation(VisualizationLocation);
	UnitPawn.SetRotation(FacingRot);
	
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);
	
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// Show the unit
	Unit.m_bForceHidden = false;
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);

	FinishAnim(PlayingSequence);

	CompleteAction();
}

defaultproperties
{
	bCauseTimeDilationWhenInterrupting = true
}