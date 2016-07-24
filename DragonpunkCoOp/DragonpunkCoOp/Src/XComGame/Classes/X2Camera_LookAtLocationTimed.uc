//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_LookAtActor.uc
//  AUTHOR:  David Burchanowski  --  3/7/2014
//  PURPOSE: Camera that looks at a location for the specified duration.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_LookAtLocationTimed extends X2Camera_LookAtLocation;

var float LookAtDuration; //Any negative value is treated as this camera never automatically ending. Something else must manually remove the camera.

// while this camera will remove itself when it times out, you can still have a handle to it
// and poll to see when the timer expires
var privatewrite bool HasTimerExpired;

function UpdateCamera(float DeltaTime)
{
	super.UpdateCamera(DeltaTime);

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
	Priority=eCameraPriority_GameActions
}