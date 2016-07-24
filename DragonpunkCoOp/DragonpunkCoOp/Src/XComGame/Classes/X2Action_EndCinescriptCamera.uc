//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor.
//-----------------------------------------------------------
class X2Action_EndCinescriptCamera extends X2Action;

var X2Camera_Cinescript CinescriptCamera;
var bool bForceEndImmediately;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function CompleteAction()
{
	super.CompleteAction();

	//Failsafe in case this action is forcibly shut down, which is something visualization mgr can do. The camera stack will ignore the request if it 
	//was already processed in the latent code block
	`CAMERASTACK.RemoveCamera(CinescriptCamera);
}

event bool BlocksAbilityActivation()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	`CAMERASTACK.RemoveCamera(CinescriptCamera);

	// if requested, wait a few moments before finishing the action and allowing the next one to start. 
	// Some of the abilities end fairly abruptly and this gives the artists a bit more control 
	// to allow the user to see the results of the ability and "settle" into the new state of the game
	if (!bForceEndImmediately && !bNewUnitSelected)
	{
		Sleep(CinescriptCamera.CameraDefinition.ExtraAbilityEndDelay * GetDelayModifier());
	}

	CompleteAction();
}

