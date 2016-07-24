//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Action_CameraRemove extends X2Action 
	dependson(X2Camera)
	config(Camera);

var X2Action_CameraLookAt CameraActionToRemove;

//------------------------------------------------------------------------------------------------
simulated state Executing
{

Begin:

	CompleteAction();
}

function CompleteAction()
{
	if (CameraActionToRemove.GetCamera() != none)
		`CAMERASTACK.RemoveCamera(CameraActionToRemove.GetCamera());

	super.CompleteAction();
}

defaultproperties
{
}
