//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Burrow extends X2Action;

var private CustomAnimParams Params;
var private TTile CurrentTile;
var private bool bIsOwnerLocalPlayer;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	Params.AnimName = 'NO_BurrowStart';

	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);
	bIsOwnerLocalPlayer = Unit.GetPlayer() == XComTacticalController(`BATTLE.GetALocalPlayerController()).m_XGPlayer;
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	// The unit will be going under ground so we need to mark the Aux parameters dirty so that it will 
	// update to using scanlines if the owner is the local player
 	UnitPawn.bUseObstructionShader = bIsOwnerLocalPlayer;
	UnitPawn.UpdateAuxParameterState(!bIsOwnerLocalPlayer);

	if (!IsImmediateMode())
	{
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	}

	if( !bIsOwnerLocalPlayer )
	{
		// If the owner is not the local player, hide the unit
		Unit.m_bForceHidden = true;
		`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);
	}

	CompleteAction();
}