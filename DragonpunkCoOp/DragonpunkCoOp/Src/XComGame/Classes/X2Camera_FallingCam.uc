//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_FallingCam.uc
//  AUTHOR:  Ryan McFall  --  9/18/2015
//  PURPOSE: Camera that nicely frames units falling to their deaths
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_FallingCam extends X2Camera
	config(Camera);

var private const config float DistanceFromFallInTiles; // ground plane distance to push the camera out from the Fall
var private const config float DistanceBelowFallInTiles; // relative offset from the top of the Fall to place the camera
var private const config string CameraShake; // camera shake to play for the duration of the Fall climb

var XGUnitNativeBase UnitToFollow; // cached reference to the unit we are following
var Vector TraversalStartPosition; // tile the climb or descent should start on
var Vector TraversalEndPosition; // tile the climb or descent should end on

var private Vector CameraLocation; // fixed location that the camera will be following the unit from 

// determines the fixed location from which the camera will track the Fall climb
private function bool DetermineCameraLocation()
{
	local Vector FallNormal;
	local Vector FallOffset;
	local Vector HorizontalOffset;
	local float HorizontalOffsetAmount;
	local VoxelRaytraceCheckResult OutResult;
	local float OffsetX;
	local float OffsetY;
	local int XIndex;
	local int YIndex;
	local bool bFoundStartPosition;

	OffsetX = -class'XComWorldData'.const.WORLD_StepSize;
	OffsetY = -class'XComWorldData'.const.WORLD_StepSize;
	for(XIndex = 0; XIndex < 3 && !bFoundStartPosition; ++XIndex)
	{
		for(YIndex = 0; YIndex < 3 && !bFoundStartPosition; ++YIndex)
		{
			HorizontalOffset = TraversalStartPosition;
			HorizontalOffset.X += OffsetX;
			HorizontalOffset.Y += OffsetY;
			if(!`XWORLD.VoxelRaytrace_Locations(HorizontalOffset, TraversalEndPosition, OutResult))
			{
				TraversalStartPosition += HorizontalOffset;
				bFoundStartPosition = true;
			}
			OffsetY += class'XComWorldData'.const.WORLD_StepSize;
		}
		OffsetX += class'XComWorldData'.const.WORLD_StepSize;
	}
	
	if(bFoundStartPosition)
	{
		FallNormal = TraversalStartPosition - TraversalEndPosition;
		FallNormal.Z = 0;
		FallNormal = Normal(FallNormal);

		// if going down the Fall, need to invert the normal direction
		if(TraversalEndPosition.Z < TraversalStartPosition.Z)
		{
			FallNormal *= -1.0f;
		}

		// add in a random skew to the Fall offset so that it isn't always right behind him
		HorizontalOffsetAmount = (`SYNC_FRAND()) * 2.0f - 1.0f; // random horizontal offset from -1, 1
		HorizontalOffset = FallNormal cross(vect(0, 0, 1) * HorizontalOffsetAmount);
		FallNormal = Normal(FallNormal + HorizontalOffset);

		// and push it out the desired amount
		FallOffset = FallNormal * DistanceFromFallInTiles * class'XComWorldData'.const.WORLD_StepSize;

		// put the camera at the top of the Fall
		CameraLocation.X = FallOffset.X + TraversalEndPosition.X;
		CameraLocation.Y = FallOffset.Y + TraversalEndPosition.Y;
		CameraLocation.Z = TraversalEndPosition.Z + (DistanceBelowFallInTiles * class'XComWorldData'.const.WORLD_StepSize);

		return true;
	}
		
	return false;
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	if(!DetermineCameraLocation())
	{
		RemoveSelfFromCameraStack();
	}

	PlayCameraAnim(CameraShake,,, true);
}

function UpdateCamera(float DeltaTime)
{
	
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
	Priority=eCameraPriority_GameActions
}

