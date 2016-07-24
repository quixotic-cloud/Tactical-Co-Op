//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_RemoveTargetingCamera extends X2Action;

var X2Camera_Cinescript CinescriptCamera;

var bool bCameraRemovedCompleted;

static function bool RemoveTargetingCamera(XGUnit InUnit)
{
	local XGUnit kParent;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local bool bRemoved; //Flag to indicate whether a camera *could* have been removed

	if(InUnit == none) 
	{
		return bRemoved;
	}
	else if(InUnit.TargetingCamera != none)
	{
		`CAMERASTACK.RemoveCamera(InUnit.TargetingCamera);
		InUnit.TargetingCamera = none;
		bRemoved = true;
	}
	else if (InUnit.m_bSubsystem)
	{
		History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(InUnit.ObjectID));
		kParent = XGUnit(History.GetVisualizer(UnitState.OwningObjectId));
		if (kParent != None && kParent.TargetingCamera != None)
		{
			`CAMERASTACK.RemoveCamera(kParent.TargetingCamera);
			kParent.TargetingCamera = none;
			bRemoved = true;
		}
	}

	return bRemoved;
}
//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	
	//We only sleep here if a camera could have been removed and thus necessitates a transition
    if( RemoveTargetingCamera(Unit) && !bNewUnitSelected )
	{
		// Give it a moment to settle back to the default camera (or whichever camera has priority). Otherwise the next action
		// will begin mid-camera transition
		Sleep(1.0 * GetDelayModifier());
	}
	bCameraRemovedCompleted = true;

	CompleteAction();
}

function CompleteAction()
{
	if (!bCameraRemovedCompleted)
	{
		RemoveTargetingCamera(Unit);
		bCameraRemovedCompleted = true;
	}
	super.CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}

DefaultProperties
{
	bCauseTimeDilationWhenInterrupting = false
	bCameraRemovedCompleted = false
}
