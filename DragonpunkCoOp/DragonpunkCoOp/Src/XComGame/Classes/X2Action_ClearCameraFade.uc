//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ClearCameraFade extends X2Action;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:
	`PRES.HUDShow();

	//Lifts the black filter applied to the camera during load
	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(false);

	`XTACTICALSOUNDMGR.StartAllAmbience();

	CompleteAction();
}

DefaultProperties
{
}
