//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_RushCam.uc
//  AUTHOR:  David Burchanowski  --  3/16/2015
//  PURPOSE: Camera that follows a rushing unit
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_RushCam extends X2Camera
	implements(X2VisualizationMgrObserverInterface)
	config(Camera)
	native;

var private const config float FollowPitchInDegrees; // ideal pitch of the vector from the camera to the unit
var private const config float FollowYawInDegrees; // ideal yaw of the vector from the camera to the unit
var private const config float FOVInDegrees; // fov to use while following the unit 
var private const config float CameraYawInDegrees; // camera yaw relative to the follow yaw
var private const config float CameraFollowDistanceInTiles;
var private const config float OffsetBlendTime; // approximate time, in seconds, to blend to a new camera offset
var private const config string CameraShake; // camera shake to play for the duration of the rush

// ability that this camera should be following
var XComGameStateContext_Ability AbilityToFollow;

var private XGUnitNativeBase UnitToFollow; // cached reference to the unit we are following
var private Vector UnitDestination;
var private TPOV CachedCameraLocation; // cached locaiton of our camera, so we only compute it once in the update

var private float TargetOffset;
var private float CurrentOffset;

// Determines if anything the camera cares about is blocking the los between the specified point
private native function bool IsTraceBlocked(const out Vector TraceStart, const out Vector TraceEnd);

// given the initial starting offset, returns a new absolute offset if the starting offset was blocked, or
// the starting offset if it was not blocked
private native function float FindNearestUnblockedOffset(const out Vector UnitLocation, const out Rotator UnitRotation, float StartingOffset);

// for the given offset, returns the location and orientation of the camera that should follow the unit
private native function GetFollowingLocationAndRotation(const out Vector UnitLocation,
												 const out Rotator UnitRotation,
												 FLOAT OffsetAngle,
												 out Vector FollowLocation,
												 out Rotator FollowRotation);

function Added()
{
	local XComGameStateHistory History;

	super.Added();

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	History = `XCOMHISTORY;
	UnitToFollow = XGUnit(History.GetVisualizer(AbilityToFollow.InputContext.SourceObject.ObjectID));
	`assert(UnitToFollow != none);

	UnitDestination = UnitToFollow.VisualizerUsePath.GetEndPoint();

	// this never changes, so just set it once here
	CachedCameraLocation.FOV = FOVInDegrees;
}

function Removed()
{
	super.Removed();

	`XCOMVISUALIZATIONMGR.RemoveObserver(self);
}

function Activated(TPOV CurrentTPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	local Vector UnitLocation;
	local Rotator ToDestination;

	super.Activated(CurrentTPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	UnitLocation = UnitToFollow.GetLocation();

	// prime the camera offsets so that we aren't blocked on the first frame
	ToDestination = Rotator(UnitDestination - UnitLocation);
	TargetOffset = FindNearestUnblockedOffset(UnitLocation, ToDestination, TargetOffset);
	CurrentOffset = TargetOffset;

	PlayCameraAnim(CameraShake,,, true);

	XComTacticalController(`BATTLE.GetALocalPlayerController()).CinematicModeToggled(true, true, true, true, false, false);
}

function UpdateCamera(float DeltaTime)
{
	local X2Camera_ClimbLadderCam LadderCam;
	local int CurrentPathNodeIndex;
	local Vector UnitLocation;
	local Vector Delta;
	local eTraversalType CurrentTraversal;
	local Rotator ToDestination;
	local float NewTargetOffset;

	// first check if we want to cut to a ladder cam
	CurrentPathNodeIndex = UnitToFollow.VisualizerUsePath.GetPathIndexFromPathDistance(UnitToFollow.GetPawn().m_fDistanceMovedAlongPath);
	CurrentTraversal = UnitToFollow.VisualizerUsePath.GetTraversalType(CurrentPathNodeIndex);
	if(CurrentTraversal == eTraversal_ClimbLadder 
		|| CurrentTraversal == eTraversal_DropDown
		|| CurrentTraversal == eTraversal_JumpUp)
	{
		LadderCam = new class'X2Camera_ClimbLadderCam';
		LadderCam.UnitToFollow = UnitToFollow;
		LadderCam.TraversalStartPosition = UnitToFollow.VisualizerUsePath.GetPoint(CurrentPathNodeIndex);
		LadderCam.TraversalEndPosition = UnitToFollow.VisualizerUsePath.GetPoint(CurrentPathNodeIndex + 1);
		PushCamera(LadderCam);
		return;
	}

	UnitLocation = UnitToFollow.GetLocation();
	Delta = UnitDestination - UnitLocation;

	// check for arrival
	if(VSizeSq(Delta) < (class'XComWorldData'.const.WORLD_StepSize * class'XComWorldData'.const.WORLD_StepSize))
	{
		RemoveSelfFromCameraStack();
		return;
	}

	ToDestination = Rotator(Delta);

	// check if we can return to our desired behind the back location (or stay there)
	NewTargetOffset = FindNearestUnblockedOffset(UnitLocation, ToDestination, 0.0f);

	if(NewTargetOffset != 0.0f)
	{
		// our desired camera location is blocked, so adjust from the previous offset. This makes sure that
		// any adjustments we need to do are relative to the previous offset camera. keeps it from swinging 
		// around crazily
		NewTargetOffset = FindNearestUnblockedOffset(UnitLocation, ToDestination, TargetOffset);
	}

	TargetOffset = NewTargetOffset;
	CurrentOffset = Lerp(CurrentOffset, TargetOffset, OffsetBlendTime > 0.0f ? DeltaTime / OffsetBlendTime : 1.0f);

	GetFollowingLocationAndRotation(UnitLocation, ToDestination, CurrentOffset, CachedCameraLocation.Location, CachedCameraLocation.Rotation);

	// add in the extra yaw so the unit is framed perfectly in the center of the image
	CachedCameraLocation.Rotation.Yaw += CameraYawInDegrees * DegToUnrRot;
}
	
function TPOV GetCameraLocationAndOrientation()
{
	return CachedCameraLocation;
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);

event OnVisualizationIdle()
{
	// safety check, if the visualization goes completely idle, then 
	// we'd better stop the rush cam since the move has to be complete
	`Redscreen("Rush cam had to be removed with OnVisualizationIdle(), something terrible has happened.");
	RemoveSelfFromCameraStack();
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	// automatically remove ourself when the move is finished being visualized as a safety fallback
	if(AbilityToFollow.GetLastStateInInterruptChain().HistoryIndex == AssociatedGameState.HistoryIndex)
	{
		RemoveSelfFromCameraStack();
	}
}

defaultproperties
{
	Priority=eCameraPriority_CharacterMovementAndFraming
}

