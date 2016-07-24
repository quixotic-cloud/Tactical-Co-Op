//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_AndromedonRobotSpawn extends X2Action;

//Cached info for the unit performing the action
//*************************************
var protected XGUnit			RobotUnit;
var protected TTile				CurrentTile;
var protected CustomAnimParams	AnimParams;

var private XComGameStateContext_Ability StartingAbility;
var private XComGameState_Ability AbilityState;
var private AnimNodeSequence ChangeSequence;
var private bool bReceivedSetVisibleMessage;

// Set by visualizer so we know who to change form from
var XGUnit						AndromedonUnit;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	super.Init(InTrack);

	History = `XCOMHISTORY;
	RobotUnit = XGUnit(Track.TrackActor);
	StartingAbility = XComGameStateContext_Ability(StateChangeContext);
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(StartingAbility.InputContext.AbilityRef.ObjectID));
}

function bool CheckInterrupted()
{
	return false;
}

function HandleTrackMessage()
{
	bReceivedSetVisibleMessage = true;
}

function VisualSwap()
{
	// Hide the associated Andromedon
	AndromedonUnit.m_bForceHidden = true;
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(AndromedonUnit.Location);
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(AndromedonUnit, CurrentTile);

	// Show the robot
	RobotUnit.SetForceVisibility(eForceVisible);
	RobotUnit.m_bForceHidden = false;
	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(RobotUnit.Location);
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(RobotUnit, CurrentTile);
	RobotUnit.SetForceVisibility(eForceNone);
}

function CompleteAction()
{
	if( !bReceivedSetVisibleMessage )
	{
		VisualSwap();
		UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}

	super.CompleteAction();
}

simulated state Executing
{
	function ChangePerkTarget()
	{
		local XComUnitPawn CasterPawn;
		local int x;

		CasterPawn = XGUnit(`XCOMHISTORY.GetVisualizer(StartingAbility.InputContext.SourceObject.ObjectID)).GetPawn();
		for( x = 0; x < CasterPawn.arrPawnPerkContent.Length; ++x )
		{
			if( CasterPawn.arrPawnPerkContent[x].AssociatedAbility == AbilityState.GetMyTemplateName() )
			{
				CasterPawn.arrPawnPerkContent[x].AddPerkTarget(RobotUnit);
				CasterPawn.arrPawnPerkContent[x].RemovePerkTarget(AndromedonUnit);
			}
		}
	}

	function CopyFacing()
	{
		RobotUnit.GetPawn().SetLocation(AndromedonUnit.GetPawn().Location);
		RobotUnit.GetPawn().SetRotation(AndromedonUnit.GetPawn().Rotation);
	}

Begin:
	RobotUnit.GetPawn().EnableRMA(false, false);
	RobotUnit.GetPawn().EnableRMAInteractPhysics(false);
	RobotUnit.GetPawn().bSkipIK = true;

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	UnitPawn.RestoreAnimSetsToDefault();
	UnitPawn.UpdateAnimations();

	// Then copy the facing to match the source
	CopyFacing();

	// Start the animation at the same time as the Andromedon
	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'HL_RobotBattleSuitStart';
	AnimParams.BlendTime = 0.0f;

	ChangeSequence = RobotUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);

	while( !bReceivedSetVisibleMessage )
	{
		sleep(0.0);
	}

	VisualSwap();

	FinishAnim(ChangeSequence);

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);

	CompleteAction();
}

defaultproperties
{
	bReceivedSetVisibleMessage=false
}