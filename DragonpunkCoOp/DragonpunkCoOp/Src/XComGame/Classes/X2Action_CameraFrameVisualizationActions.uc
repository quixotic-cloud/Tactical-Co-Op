//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Action_CameraFrameVisualizationActions extends X2Action 
	dependson(X2Camera)
	config(Camera);

// time, in seconds, to pause on the framed ability after the framing camera arrives
var float DelayAfterArrival;
var float DelayAfterActionsComplete;
var Actor LookAtActor;
var Vector LookAtLocation;

// the camera that will frame the actions
var X2Camera_FrameVisualizationActions FramingCamera;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:

	if( !bNewUnitSelected )
	{
		// create the camera to frame the action
		FramingCamera = new class'X2Camera_FrameVisualizationActions';
		FramingCamera.SetupCamera(LookAtActor, LookAtLocation, StateChangeContext, DelayAfterActionsComplete);
		`CAMERASTACK.AddCamera(FramingCamera);

		// wait for it to finish framing the scene
		while( FramingCamera != None && !FramingCamera.HasArrived() )
		{
			Sleep(0.0);
		}
	}
	
	if( !bNewUnitSelected )
	{
		// pause on the frame action before starting it
		Sleep(DelayAfterArrival * GetDelayModifier());
	}

	CompleteAction();
}

event HandleNewUnitSelection()
{
	if( FramingCamera != None )
	{
		`CAMERASTACK.RemoveCamera(FramingCamera);
		FramingCamera = None;
	}
}

