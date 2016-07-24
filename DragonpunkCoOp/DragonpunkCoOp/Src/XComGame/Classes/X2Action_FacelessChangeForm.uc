//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_FacelessChangeForm extends X2Action;

//Cached info for the unit performing the action
//*************************************
var protected XGUnit			FacelessUnit;
var protected TTile				CurrentTile;
var protected CustomAnimParams	AnimParams;

var private XComGameStateContext_Ability StartingAbility;
var private XComGameState_Ability AbilityState;
var private XComGameState_Unit FacelessUnitState;
var private AnimNodeSequence ChangeSequence;

// Set by visualizer so we know who to change form from
var XGUnit						SourceUnit;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	super.Init(InTrack);

	History = `XCOMHISTORY;
	FacelessUnit = XGUnit(Track.TrackActor);
	StartingAbility = XComGameStateContext_Ability(StateChangeContext);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(StartingAbility.InputContext.AbilityRef.ObjectID));
	FacelessUnitState = XComGameState_Unit(History.GetGameStateForObjectID(FacelessUnit.ObjectID));
}

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
	function ChangePerkTarget()
	{
		local XComUnitPawn CasterPawn;
		local array<XComPerkContent> Perks;
		local int x;

		CasterPawn = XGUnit(`XCOMHISTORY.GetVisualizer(StartingAbility.InputContext.SourceObject.ObjectID)).GetPawn();

		class'XComPerkContent'.static.GetAssociatedPerks( Perks, CasterPawn, StartingAbility.InputContext.AbilityTemplateName );
		for (x = 0; x < Perks.Length; ++x)
		{
			Perks[x].ReplacePerkTarget( SourceUnit, FacelessUnit );
		}
	}

	function CopyFacing()
	{
		FacelessUnit.GetPawn().SetLocation(SourceUnit.GetPawn().Location);
		FacelessUnit.GetPawn().SetRotation(SourceUnit.GetPawn().Rotation);
		FacelessUnit.GetPawn().EnableFootIK(false);
	}

Begin:
	// Show the faceless and play its change form animation
	FacelessUnit.GetPawn().EnableRMA(false, false);
	FacelessUnit.GetPawn().EnableRMAInteractPhysics(false);

	// Then copy the facing to match the source
	CopyFacing();

	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'NO_ChangeForm';
	AnimParams.BlendTime = 0.0f;
	
	ChangeSequence = FacelessUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	FacelessUnit.m_bForceHidden = false;
	FacelessUnit.SetForceVisibility(eForceVisible); // Force faceless unit visible.
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(FacelessUnit.Location);
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(FacelessUnit, CurrentTile);

	ChangePerkTarget();

	FinishAnim(ChangeSequence);

	FacelessUnit.GetPawn().EnableFootIK(true);

	VisualizationMgr.SendInterTrackMessage(StartingAbility.InputContext.SourceObject);

	FacelessUnit.SetForceVisibility(eForceNone); // Remove forced visibility.
	CompleteAction();
}