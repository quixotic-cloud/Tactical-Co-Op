//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Action_CameraLookAt extends X2Action 
	dependson(X2Camera)
	config(Camera);

// even though this will be set in the ability context, it lives here so that the config value can be
// specified in the camera config
var const config float SelfTargetLookAtDuration;
var const config float MultiTargetLookAtDuration;

// fill out either an actor or a unit to look at.
var Actor LookAtActor;
var XComGameState_BaseObject LookAtObject;
var vector LookAtLocation; // location to look at. Only used if no actor or object are specified
var float LookAtDuration;
var bool UseTether;
var bool SnapToFloor;
var bool BlockUntilFinished;
var bool BlockUntilActorOnScreen;
var ECameraPriority DesiredCameraPriority;
var XComPresentationLayer PresentationLayer;

var private X2Camera_LookAtActorTimed LookAtActorCamera;
var private X2Camera_LookAtLocationTimed LookAtLocationCamera;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	PresentationLayer = `PRES;
}


function X2Camera GetCamera()
{
	if (LookAtActorCamera != none)
		return LookAtActorCamera;
	else if (LookAtLocationCamera != none)
		return LookAtLocationCamera;
	else 
		return none;
}

event bool BlocksAbilityActivation()
{
	return false;
}

event HandleNewUnitSelection()
{
	if( LookAtActorCamera != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtActorCamera);
		LookAtActorCamera = None;
	}
	if( LookAtLocationCamera != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtLocationCamera);
		LookAtLocationCamera = None;
	}
}


//------------------------------------------------------------------------------------------------
simulated state Executing
{
	private function bool GetLookAtActor()
	{
		local XComGameStateHistory History;

		if(LookAtObject != None)
		{
			History = `XCOMHISTORY;
			LookAtActor = History.GetVisualizer(LookAtObject.ObjectID);

			if(LookAtActor != none)
			{
				return false;
			}
		}
		
		return true;
	}

	private function bool ShouldUseLookAtActorCamera()
	{
		return LookAtActor != none || LookAtObject != none;
	}

Begin:

	if(ShouldUseLookAtActorCamera() && !bNewUnitSelected)
	{
		// if we're looking at a unit, we may need to wait for its visualizer to sync
		if(!GetLookAtActor())
		{
			Sleep(0.0);
		}
		
		LookAtActorCamera = new class'X2Camera_LookAtActorTimed';
		LookAtActorCamera.ActorToFollow = LookAtActor;
		LookAtActorCamera.LookAtDuration = LookAtDuration;
		LookAtActorCamera.UseTether = UseTether;
		LookAtActorCamera.SnapToFloor = SnapToFloor;
		LookAtActorCamera.Priority = DesiredCameraPriority;
		LookAtActorCamera.UpdateWhenInactive = false; // This must be false, otherwise actions can proceed while we are not looking at them!
		`CAMERASTACK.AddCamera(LookAtActorCamera);

		if(BlockUntilFinished)
		{
			while( LookAtActorCamera != None && !LookAtActorCamera.HasTimerExpired )
			{
				Sleep(0.0);
			}
		}
		else if(BlockUntilActorOnScreen)
		{
			//If BlockUntilActorOnScreen is set, release our grip on the actor track once the Location of our look-at target is on-screen. We also consider
			//this wait condition satisfied if we have reached our camera destination but the look at actor is not on screen ( the camera stack may have
			//another camera as the dominant one )
			while( LookAtActorCamera != None && !LookAtActorCamera.HasArrived && LookAtActorCamera.IsLookAtValid() )
			{
				Sleep(0.0);
			}
		}
	}
	else if (!bNewUnitSelected)
	{
		LookAtLocationCamera = new class'X2Camera_LookAtLocationTimed';
		LookAtLocationCamera.LookAtLocation = LookAtLocation;
		LookAtLocationCamera.LookAtDuration = LookAtDuration;
		LookAtLocationCamera.UseTether = UseTether;
		LookAtLocationCamera.Priority = DesiredCameraPriority;
		LookAtLocationCamera.UpdateWhenInactive = false; // This must be false, otherwise actions can proceed while we are not looking at them!
		`CAMERASTACK.AddCamera(LookAtLocationCamera);

		if(BlockUntilFinished)
		{
			while( LookAtLocationCamera != None && !LookAtLocationCamera.HasTimerExpired )
			{
				Sleep(0.0);
			}
		}
		else if(BlockUntilActorOnScreen)
		{
			while( LookAtLocationCamera != None && !LookAtLocationCamera.HasArrived && LookAtLocationCamera.IsLookAtValid() )
			{
				Sleep(0.0);
			}
		}
	}

	CompleteAction();
}

defaultproperties
{
	UseTether=true
	LookAtDuration=1
	BlockUntilFinished=false
	DesiredCameraPriority=eCameraPriority_LookAt
	SnapToFloor=true
}
