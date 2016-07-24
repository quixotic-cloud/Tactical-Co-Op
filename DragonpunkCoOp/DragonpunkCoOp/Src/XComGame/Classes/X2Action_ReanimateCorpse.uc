//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ReanimateCorpse extends X2Action
	config(GameCore);

var private const config float LookAtZombieDurationSec; // in seconds

//Cached info for the unit performing the action
//*************************************
var protected XGUnit			ReanimatedUnit;
var protected TTile				CurrentTile;
var protected CustomAnimParams	AnimParams;

var private XComGameState_Unit			ReanimatedUnitState;
var private XComGameState_Unit			DeadUnitState;
var private X2Camera_LookAtActorTimed	LookAtCam;
var private Actor						FOWViewer;					// The current FOW Viewer actor
var private bool						bReceivedStartMessage;

// Set by visualizer so we know who to mimic
var XGUnit						DeadUnit;
var bool						ShouldCopyAppearance;
var name                        ReanimationName;
var XComGameState_Ability       ReanimatorAbilityState;
var bool                        bWaitForDeadUnitMessage;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	super.Init(InTrack);

	History = `XCOMHISTORY;
	ReanimatedUnit = XGUnit(Track.TrackActor);

	ReanimatedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ReanimatedUnit.ObjectID));
	DeadUnitState = XComGameState_Unit(History.GetGameStateForObjectID(DeadUnit.ObjectID, ,  Track.BlockHistoryIndex));
}

function bool CheckInterrupted()
{
	return false;
}

function HandleTrackMessage()
{
	bReceivedStartMessage = true;
}

simulated state Executing
{	
	private function RequestLookAtCamera()
	{
		LookAtCam = new class'X2Camera_LookAtActorTimed';
		LookAtCam.ActorToFollow = ReanimatedUnit;
		LookAtCam.LookAtDuration = LookAtZombieDurationSec;
		LookAtCam.UseTether = false;
		`CAMERASTACK.AddCamera(LookAtCam);

		FOWViewer = `XWORLD.CreateFOWViewer(ReanimatedUnit.GetLocation(), 3 * class'XComWorldData'.const.WORLD_StepSize);
	}

	private function ClearLookAtCamera()
	{
		`CAMERASTACK.RemoveCamera(LookAtCam);
		LookAtCam = None;

		if (FOWViewer != None)
		{
			`XWORLD.DestroyFOWViewer(FOWViewer);
			FOWViewer = None;
		}
	}

Begin:

//	RequestLookAtCamera();
//
//	while (!LookAtCam.HasArrived)
//	{
//		Sleep(0.0);
//	}

	ReanimatedUnit.GetPawn().bSkipIK = false;
	ReanimatedUnit.GetPawn().EnableFootIK(true);
	ReanimatedUnit.GetPawn().EnableRMA(true, true);
	ReanimatedUnit.GetPawn().EnableRMAInteractPhysics(true);

	// Now blend in an animation to stand up
	AnimParams = default.AnimParams;
	AnimParams.AnimName = ReanimationName;
	AnimParams.BlendTime = 0.5f;
	AnimParams.HasDesiredEndingAtom = true;
	AnimParams.DesiredEndingAtom.Translation = `XWORLD.GetPositionFromTileCoordinates(ReanimatedUnitState.TileLocation);
	AnimParams.DesiredEndingAtom.Translation.Z = ReanimatedUnit.GetDesiredZForLocation(AnimParams.DesiredEndingAtom.Translation);
	AnimParams.DesiredEndingAtom.Rotation = QuatFromRotator(ReanimatedUnit.GetPawn().Rotation);
	AnimParams.DesiredEndingAtom.Scale = 1.0f;
	FinishAnim(ReanimatedUnit.GetPawn().GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));

//	ClearLookAtCamera();

	VisualizationMgr.SendInterTrackMessage(VisualizationBlockContext.InputContext.SourceObject);

	CompleteAction();
}

function CompleteAction()
{	
	ReanimatedUnit.GetPawn().EnableRMA(false, false);
	ReanimatedUnit.GetPawn().EnableRMAInteractPhysics(false);

	super.CompleteAction();
}

DefaultProperties
{
	ShouldCopyAppearance = true;
	TimeoutSeconds=30
	bWaitForDeadUnitMessage=false
	bReceivedStartMessage=false
}
