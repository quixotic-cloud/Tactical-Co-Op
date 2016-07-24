//----------------------------------------------------------------------------
//  Copyright 2011, Firaxis Games
//
//  3D interface elements connection to route the mouse input from its level actor over to its GFxMovie-rendertexture.
//

class UIDisplay_LevelActor extends XComLevelActor;

var public UIMovie_3D m_kMovie; 

var vector LockedDisplayInitialLocation;
var rotator LockedDisplayInitialRotation;
var float LockedDisplayDistanceFromCamera;

// locks the current display relative to the camera. Allows a display actor to track with the camera,
// so that the UI display to the user remains consistent through camera location changes 
function SetLockedToCamera(bool LockedToCamera)
{
	local XComBaseCamera UseCamera;

	if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game) != none && `HQPRES != none)
	{
		UseCamera = `HQPRES.GetCamera();
	}
	else
	{
		UseCamera = XComShellPresentationLayer(`PRESBASE).GetCamera();
	}

	if (LockedToCamera)
	{
		// only setup the offsets if we weren't already locked (Distance > 0 indicates we are locked)
		if (LockedDisplayDistanceFromCamera == 0.0f)
		{
			LockedDisplayInitialLocation = Location;
			LockedDisplayInitialRotation = Rotation;
			LockedDisplayDistanceFromCamera = VSize(UseCamera.CameraCache.POV.Location - Location);
		}
	}
	else if (LockedDisplayDistanceFromCamera != 0.0f)
	{
		SetLocation(LockedDisplayInitialLocation);
		SetRotation(LockedDisplayInitialRotation);
		LockedDisplayDistanceFromCamera = 0.0f;
	}

	// if aren't tracking, don't tick. It's just a waste of cycles
	SetTickIsDisabled(!LockedToCamera);
}

simulated event Tick(float DeltaTime)
{
	local XComBaseCamera UseCamera;
	local vector CameraNormal;

	// if we another UI display becomes active while we are still locked,
	// automatically unlock ourself and stop ticking
	if(m_kMovie == none)
	{
		SetLockedToCamera(false);
		return;
	}
	
	if(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game) != none && `HQPRES != none)
	{
		UseCamera = `HQPRES.GetCamera();
	}
	else
	{
		UseCamera = XComShellPresentationLayer(`PRESBASE).GetCamera();
	}

	// update the UI location to maintain the same relative distance from the camera
	CameraNormal = Vector(UseCamera.CameraCache.POV.Rotation);
	SetLocation(UseCamera.CameraCache.POV.Location + CameraNormal * LockedDisplayDistanceFromCamera);
	SetRotation(UseCamera.CameraCache.POV.Rotation);
}

//----------------------------------------------------------------------------
//  CALLBACK from Input - HUD mouse interaction in the world 
//  Occurs when Flash sends an "OnInit" fscommand. 
//
function bool OnMouseEvent(int cmd, 
						   int ActionMask, 
						   optional Vector MouseWorldOrigin, 
						   optional Vector MouseWorldDirection, 
						   optional Vector HitLocation)
{
	//Send mouse location over to the movie 
	if( m_kMovie != none )
		m_kMovie.SetMouseLocation(class'Helpers'.static.GetUVCoords(StaticMeshComponent, MouseWorldOrigin, MouseWorldDirection));
	return true;
}
//----------------------------------------------------------------------------

defaultproperties
{
	bStatic=false
	bMovable=true

	// need to tick after the camera so that our locked position isn't a frame behind
	TickGroup=TG_PostUpdateWork
}
