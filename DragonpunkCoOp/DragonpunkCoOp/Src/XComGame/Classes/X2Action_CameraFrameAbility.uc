//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Action_CameraFrameAbility extends X2Action 
	dependson(X2Camera)
	config(Camera);

// time, in seconds, to pause on the framed ability after the framing camera arrives
var const config float FrameDuration;

// ability that this action should be framing
var XComGameStateContext_Ability AbilityToFrame;

// the camera that will frame the ability
var X2Camera_FrameAbility FramingCamera;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:

	if( !bNewUnitSelected )
	{
		// create the camera to frame the action
		FramingCamera = new class'X2Camera_FrameAbility';
		FramingCamera.AbilityToFrame = AbilityToFrame;
		FramingCamera.Priority = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityToFrame.InputContext.AbilityTemplateName).CameraPriority;
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
		Sleep(FrameDuration * GetDelayModifier());
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

