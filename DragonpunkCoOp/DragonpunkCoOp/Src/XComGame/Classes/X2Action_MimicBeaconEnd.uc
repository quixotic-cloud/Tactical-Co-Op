//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_MimicBeaconEnd extends X2Action;

var name AnimationName;

//Cached info for performing the action
//*************************************
var protected TTile CurrentTile;
var	protected CustomAnimParams Params;
//*************************************

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	if( AnimationName != '' )
	{
		Params.AnimName = AnimationName;
		
//		`PRES.m_kUnitFlagManager.RespondToNewGameState(Unit, StateChangeContext.GetLastStateInInterruptChain(), true);
		FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	}

	Unit.m_bForceHidden = true;
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);

	CompleteAction();
}