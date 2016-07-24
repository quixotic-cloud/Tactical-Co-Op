//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_RemoveUnit extends X2Action;

var private XGUnit TrackUnit;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	TrackUnit = XGUnit(Track.TrackActor);
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event BeginState(Name PreviousStateName)
	{
		local XComUnitPawn Pawn;
		local TTile CurrentTile;

		Pawn = TrackUnit.GetPawn( );

		TrackUnit.m_bForceHidden = true;
		CurrentTile = `XWORLD.GetTileCoordinatesFromPosition( TrackUnit.Location );
		`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility( TrackUnit, CurrentTile );

		Pawn.SetHidden( true );
		if (Pawn.m_TurretBaseActor != none)
		{
			Pawn.m_TurretBaseActor.SetHidden( true );
		}
	}

Begin:

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}
