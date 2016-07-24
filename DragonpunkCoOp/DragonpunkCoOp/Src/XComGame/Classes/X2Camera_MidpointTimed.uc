//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_MidpointTimed.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Camera that keeps all points of interest within the safe zone and removes itself when a timer expires.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_MidpointTimed extends X2Camera_Midpoint;

var float LookAtDuration; //Any negative value is treated as this camera never automatically ending. Something else must manually remove the camera.
var privatewrite bool HasArrived; // have we arrived at our destination?
var privatewrite bool AreAllFocusPointsInFrustum; // are all of our focus points now within the camera's field of view?

// while this camera will remove itself when it times out, you can still have a handle to it
// and poll to see when the timer expires
var privatewrite bool HasTimerExpired;

function UpdateCamera(float DeltaTime)
{
	local TPOV CameraLocation;
	local Vector FocusPoint;

	super.UpdateCamera(DeltaTime);

	// arrival when we are within one unit of the destination and the zoom is less that 1% off.
	HasArrived = HasArrived || (VSizeSq(GetCameraLookat() - CurrentLookAt) < 1 && abs(TargetZoom - CurrentZoom) < 0.01f);

	if(!AreAllFocusPointsInFrustum)
	{
		// check if all focus points are within the camera frustum yet.
		// we ignore actors, who are moving and always in frame already anyway
		AreAllFocusPointsInFrustum = true;
		CameraLocation = GetCameraLocationAndOrientation();
		foreach FocusPoints(FocusPoint)
		{
			if(!IsPointWithinCameraFrustum(CameraLocation, FocusPoint))
			{
				AreAllFocusPointsInFrustum = false;
				break;
			}
		}
	}

	if (HasArrived && LookAtDuration >= 0.0)
	{
		LookAtDuration -= DeltaTime;

		if(LookAtDuration <= 0.0)
		{
			HasTimerExpired = true;
			RemoveSelfFromCameraStack();
		}
	}
}

defaultproperties
{
	LookAtDuration=2.0
	Priority=eCameraPriority_GameActions
}