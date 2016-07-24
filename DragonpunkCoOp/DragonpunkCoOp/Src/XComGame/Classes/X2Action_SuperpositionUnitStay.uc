//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_SuperpositionUnitStay extends X2Action;

var XGUnit OriginalCodex;

//Cached info for the unit performing the action
//*************************************
var protected TTile CurrentTile;
var protected CustomAnimParams AnimParams;

var private AnimNodeSequence ChangeSequence;
//*************************************

function bool CheckInterrupted()
{
	return false;
}

function bool IsTimedOut()
{
	return false;
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{
	// Notify the original codex that it may now teleport
	VisualizationMgr.SendInterTrackMessage(VisualizationBlockContext.InputContext.SourceObject);
}

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(false, false);
	UnitPawn.EnableRMAInteractPhysics(false);
	UnitPawn.bSkipIK = true;

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	UnitPawn.RestoreAnimSetsToDefault();
	UnitPawn.UpdateAnimations();

	// Then copy the facing to match the source
	Unit.GetPawn().SetLocation(OriginalCodex.GetPawn().Location);
	Unit.GetPawn().SetRotation(OriginalCodex.GetPawn().Rotation);

	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'HL_CloneStay';
	AnimParams.BlendTime = 0.0f;

	ChangeSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	Unit.m_bForceHidden = false;
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);

	FinishAnim(ChangeSequence);

	UnitPawn.EnableFootIK(true);
	UnitPawn.bSkipIK = false;

	CompleteAction();
}