//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Action_CameraFollowUnit extends X2Action 
	dependson(X2Camera)
	config(Camera);

// ability that this action should be framing
var XComGameStateContext_Ability AbilityToFrame;
var bool bLockFloorZ;

// the camera that will frame the ability
var X2Camera_FollowMovingUnit FollowCamera;

//Path data set from ParsePath. These are set into the unit and then referenced for the rest of the path
var private PathingInputData		CurrentMoveData;
var private PathingResultData		CurrentMoveResultData;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	Unit.CurrentMoveData = CurrentMoveData;
	Unit.CurrentMoveResultData = CurrentMoveResultData;
}

function ParsePathSetParameters(const out PathingInputData InputData, const out PathingResultData ResultData)
{
	CurrentMoveData = InputData;
	CurrentMoveResultData = ResultData;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:

	if( !bNewUnitSelected )
	{
		// create the camera to frame the action
		FollowCamera = new class'X2Camera_FollowMovingUnit';
		FollowCamera.Unit = XGUnit(Track.TrackActor);
		FollowCamera.MoveAbility = AbilityToFrame;
		FollowCamera.Priority = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityToFrame.InputContext.AbilityTemplateName).CameraPriority;
		FollowCamera.bLockFloorZ = bLockFloorZ;
		`CAMERASTACK.AddCamera(FollowCamera);

		// wait for it to get to the lookat point on screen
		while( FollowCamera != None && !FollowCamera.HasArrived && FollowCamera.IsLookAtValid() )
		{
			Sleep(0.0);
		}
	}
	
	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}

event HandleNewUnitSelection()
{
	if( FollowCamera != None )
	{
		`CAMERASTACK.RemoveCamera(FollowCamera);
		FollowCamera = None;
	}
}
