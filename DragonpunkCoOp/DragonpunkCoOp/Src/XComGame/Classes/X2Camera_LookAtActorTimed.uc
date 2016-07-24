//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_LookAtActorTimed.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Camera that looks at a unit for a specified duration, and then removes itself from the stack
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_LookAtActorTimed extends X2Camera_LookAtActor;

var float LookAtDuration; //Any negative value is treated as this camera never automatically ending. Something else must manually remove the camera.

// while this camera will remove itself when it times out, you can still have a handle to it
// and poll to see when the timer expires
var privatewrite bool HasTimerExpired;

function UpdateCamera(float DeltaTime)
{
	super.UpdateCamera(DeltaTime);
	
	if(HasArrived && LookAtDuration >= 0.0)
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
	LookAtDuration=2.0
	HasArrived=false
}