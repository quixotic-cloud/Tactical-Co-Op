//---------------------------------------------------------------------------------------
//  FILE:    XComAkSwitchVolume.uc
//  AUTHOR:  David Burchanowski
//           
//  PURPOSE: Allows the LDs to modify sound ambience and other sound parameters
//  based on where the camera is in the world
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComAkSwitchVolume extends Volume
	placeable;

struct AkSwitchVolumePair
{
	var() name AkSwitch;
	var() name SwitchValue;
};

// Array of akSwitches that should fire when the camera enters this volume
var() array<AkSwitchVolumePair> EntrySwitches;

// Array of akSwitches that should fire when the camera exits this volume
var() array<AkSwitchVolumePair> ExitSwitches;

// allows us to easily keep track of when we enter or leave the switch volume
var private bool WasInVolume;

// prevents us from updating the switches every frame. Only need to update if the camera is moving
var private vector LastCheckLocation;

// cached off to prevent grabbing the camera every frame
var private XComCamera Camera;

// only check if we are in the volume every half tile or so. Audio enviromenments don't need to be super
// precise, so err on the side of not sucking down CPU cycles
var private float MinDistanceBetweenChecksSquared;

simulated event Tick(float DeltaTime)
{
	local bool IsInVolume;
	local AkSwitchVolumePair SwitchPair;

	super.Tick(DeltaTime);

	if(Camera == none)
	{
		Camera = XComCamera(GetALocalPlayerController().PlayerCamera);
		MinDistanceBetweenChecksSquared = class'XComWorldData'.const.WORLD_HalfStepSize * class'XComWorldData'.const.WORLD_HalfStepSize;
	}

	// only check if we are in the switch volume if we've actually moved
	if(VSizeSq(Camera.CameraCache.POV.Location - LastCheckLocation) > MinDistanceBetweenChecksSquared)
	{
		IsInVolume = EncompassesPoint(Camera.CameraCache.POV.Location);
		
		if(WasInVolume && !IsInVolume)
		{
			foreach ExitSwitches(SwitchPair)
			{
				SetState(SwitchPair.AkSwitch, SwitchPair.SwitchValue);
			}
		}
		else if(!WasInVolume && IsInVolume)
		{
			foreach EntrySwitches(SwitchPair)
			{
				SetState(SwitchPair.AkSwitch, SwitchPair.SwitchValue);
			}
		}

		WasInVolume = IsInVolume;
		LastCheckLocation = Camera.CameraCache.POV.Location;
	}
}

defaultproperties
{
	Begin Object Name=BrushComponent0
		CollideActors=false
		bAcceptsLights=false
		LightingChannels=(Dynamic=false,bInitialized=false)
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
		CanBlockCamera=false // FIRAXIS jboswell
		bDisableAllRigidBody=true
	End Object

	bStatic=false; // necessary to enable ticking
}