//---------------------------------------------------------------------------------------
//  FILE:    X2TargetingMethod_Grapple.uc
//  AUTHOR:  David Burchanowski  --  8/05/2015
//  PURPOSE: Targeting method for choosing a grapple location
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_Grapple extends X2TargetingMethod;

// Since targeting methods are not actors, we can't attach components to them. We do need
// to have a movement grid component and a pathing, however, so we spawn an actor to contain them.
var private X2GrapplePuck GrapplePuck;

function Init(AvailableAction InAction)
{
	local X2Camera_LookAtLocationTimed LookAtCamera;
	local vector TargetLocation;

	super.Init(InAction);

	// create the actor to draw the target location tiles on the ground
	GrapplePuck = `CURSOR.Spawn(class'X2GrapplePuck', `CURSOR);
	GrapplePuck.InitForUnitState(UnitState);

	// have a camera look at the default location
	if(GrapplePuck.GetGrappleTargetLocation(TargetLocation))
	{
		LookAtCamera = new class'X2Camera_LookAtLocationTimed';
		LookAtCamera.LookAtLocation = TargetLocation;
		LookAtCamera.LookAtDuration = 0.0f;
		`CAMERASTACK.AddCamera(LookAtCamera);
	}
}

function Update(float DeltaTime);

function Canceled()
{
	GrapplePuck.Destroy();
}

function Committed()
{
	GrapplePuck.ShowConfirmAndDestroy();
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	local Vector TargetLocation;

	TargetLocations.Length = 0;

	if(GrapplePuck.GetGrappleTargetLocation(TargetLocation))
	{
		TargetLocations.AddItem(TargetLocation);
	}
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	return TargetLocations.Length == 1 ? 'AA_Success' : 'AA_NoTargets';
}