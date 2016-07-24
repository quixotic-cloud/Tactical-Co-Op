//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SetUnitFacing extends X2Action;

var float FacingDegrees;
var private XComUnitPawn PawnToFace;

function Init(const out VisualizationTrack InTrack)
{
	local XComGameState_Unit UnitState;

	super.Init(InTrack);

	// if our visualizer hasn't been created yet, make sure it is created here.
	UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
	`assert(UnitState != none);

	UnitState.SyncVisualizer(StateChangeContext.AssociatedState);
	Unit = XGUnit(UnitState.GetVisualizer());
	`assert(Unit != none);

	PawnToFace = Unit.GetPawn();
	`assert(PawnToFace != none);
}

simulated state Executing
{
	function SetFacing()
	{
		local Rotator Facing;

		Facing = PawnToFace.Rotation;
		Facing.Yaw = FacingDegrees * DegToUnrRot;
		PawnToFace.SetRotation(Facing);
	}

Begin:
	SetFacing();

	CompleteAction();
}

DefaultProperties
{
}
