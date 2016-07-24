//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_StartCinescriptCamera extends X2Action;

var X2Camera_Cinescript CinescriptCamera;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:

	CompleteAction();
}

function CompleteAction()
{
	// If the targeting camera wasn't previously removed, do it here
	class'X2Action_RemoveTargetingCamera'.static.RemoveTargetingCamera(Unit);

	if (!bNewUnitSelected)
	{
		`CAMERASTACK.AddCamera(CinescriptCamera);
	}

	super.CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}

event HandleNewUnitSelection()
{
	if( CinescriptCamera != None )
	{
		`CAMERASTACK.RemoveCamera(CinescriptCamera);
		CinescriptCamera = None;
	}
}

defaultproperties
{
	bCauseTimeDilationWhenInterrupting = true
}