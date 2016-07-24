//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UnitToFacelessChangeForm extends X2Action;

//Cached info for performing the action
//*************************************
var protected TTile				CurrentTile;
var protected CustomAnimParams	AnimParams;

// Set by visualizer so we know who to change form from
var StateObjectReference FacelessUnitReference;
//*************************************

function bool CheckInterrupted()
{
	return false;
}

function bool IsTimedOut()
{
	return false;
}

simulated state Executing
{
Begin:
	//Wait for the idle state machine to return to idle
	while(UnitPawn.m_kGameUnit.IdleStateMachine.IsEvaluatingStance())
	{
		Sleep(0.0f);
	}

	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	UnitPawn.bSkipIK = true;

	// Source Unit plays change form animation then hides
	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'NO_ChangeForm';
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

	Unit.m_bForceHidden = true;
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);

	VisualizationMgr.SendInterTrackMessage(FacelessUnitReference);

	UnitPawn.EnableFootIK(true);
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	// Source Unit

	CompleteAction();
}

defaultproperties
{
	bCauseTimeDilationWhenInterrupting = true
}