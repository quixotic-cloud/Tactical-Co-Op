//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_LookAtActor.uc
//  AUTHOR:  Ryan McFall  --  3/5/2014
//  PURPOSE: Camera that looks at a location.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_LookAtLocation extends X2Camera_LookAt;

var Vector LookAtLocation;
var privatewrite bool HasArrived;
var bool UseTether; // Should this tether to the safe zone, or center on the unit

function UpdateCamera(float DeltaTime)
{
	local TPOV CameraLocation;

	super.UpdateCamera(DeltaTime);

	if( UseTether )
	{
		// check to see if we've finished our transition to the target. 
		// Consider it complete once the lookat point is on screen.
		CameraLocation = GetCameraLocationAndOrientation();

		HasArrived = HasArrived || IsPointWithinCameraFrustum(CameraLocation, GetCameraLookat());
	}
	else
	{
		HasArrived = HasArrived || (VSizeSq(GetCameraLookat() - CurrentLookAt) < 4096.0f);
	}
}

/// <summary>
/// Get's the current desired look at location. Override in derived classes
/// </summary>
protected function Vector GetCameraLookat()
{
	if(UseTether)
	{
		return GetTetheredLookatPoint(LookAtLocation, GetCameraLocationAndOrientation());
	}
	else
	{
		return LookAtLocation;
	}
}

defaultproperties
{
	Priority=eCameraPriority_GameActions
}