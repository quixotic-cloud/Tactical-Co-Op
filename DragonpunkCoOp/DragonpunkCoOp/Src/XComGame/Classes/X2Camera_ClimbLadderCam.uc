//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_ClimbLadderCam.uc
//  AUTHOR:  David Burchanowski  --  3/13/2015
//  PURPOSE: Camera that nicely frames a unit climbing a ladder
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_ClimbLadderCam extends X2Camera
	config(Camera);

var private const config float DistanceFromLadderInTiles; // ground plane distance to push the camera out from the ladder
var private const config float DistanceAboveLadderInTiles; // relative offset from the top of the ladder to place the camera
var private const config string CameraShake; // camera shake to play for the duration of the ladder climb

var XGUnitNativeBase UnitToFollow; // cached reference to the unit we are following
var Vector TraversalStartPosition; // tile the climb or descent should start on
var Vector TraversalEndPosition; // tile the climb or descent should end on

var private Vector CameraLocation; // fixed location that the camera will be following the unit from 
var int StartingTraversalNode; // 

// determines the fixed location from which the camera will track the ladder climb
private function bool DetermineCameraLocation()
{
	local Vector LadderNormal;
	local Vector LadderOffset;
	local Vector HorizontalOffset;
	local float HorizontalOffsetAmount;

	LadderNormal = TraversalStartPosition - TraversalEndPosition;
	LadderNormal.Z = 0;
	LadderNormal = Normal(LadderNormal);

	// if going down the ladder, need to invert the normal direction
	if(TraversalEndPosition.Z < TraversalStartPosition.Z)
	{
		LadderNormal *= -1.0f;
	}
	
	// add in a random skew to the ladder offset so that it isn't always right behind him
	HorizontalOffsetAmount = (`SYNC_FRAND()) * 2.0f - 1.0f; // random horizontal offset from -1, 1
	HorizontalOffset = LadderNormal cross (vect(0, 0, 1) * HorizontalOffsetAmount); 
	LadderNormal = Normal(LadderNormal + HorizontalOffset);

	// and push it out the desired amount
	LadderOffset = LadderNormal * DistanceFromLadderInTiles * class'XComWorldData'.const.WORLD_StepSize;

	// put the camera at the top of the ladder
	CameraLocation.X = LadderOffset.X + TraversalEndPosition.X;
	CameraLocation.Y = LadderOffset.Y + TraversalEndPosition.Y;
	CameraLocation.Z = FMax(TraversalEndPosition.Z, TraversalStartPosition.Z) + DistanceAboveLadderInTiles * class'XComWorldData'.const.WORLD_StepSize;

	// TODO? add support for detecting camera blocks
	return true;
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	StartingTraversalNode = UnitToFollow.VisualizerUsePath.GetPathIndexFromPathDistance(UnitToFollow.GetPawn().m_fDistanceMovedAlongPath);

	if(!DetermineCameraLocation())
	{
		RemoveSelfFromCameraStack();
	}

	PlayCameraAnim(CameraShake,,, true);
}

function UpdateCamera(float DeltaTime)
{
	local int CurrentTraversalNode;

	CurrentTraversalNode = UnitToFollow.VisualizerUsePath.GetPathIndexFromPathDistance(UnitToFollow.GetPawn().m_fDistanceMovedAlongPath);;

	if(CurrentTraversalNode != StartingTraversalNode)
	{
		RemoveSelfFromCameraStack();
	}
}

function TPOV GetCameraLocationAndOrientation()
{
	local TPOV Result;

	Result.Location = CameraLocation;
	Result.FOV = 55;
	Result.Rotation = Rotator(UnitToFollow.GetLocation() - Result.Location);

	return Result;
}

defaultproperties
{
	Priority=eCameraPriority_CharacterMovementAndFraming
}

