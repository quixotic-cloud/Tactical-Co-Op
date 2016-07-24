//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_InitUI extends X2Action;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function bool CheckInterrupted()
{
	return false;
}

function InitUI()
{
	local XComPresentationLayer Pres;

	Pres = XComPresentationLayer(XComTacticalController(GetALocalPlayerController()).Pres);

	Pres.OnTacticalReadyForUI();
	Pres.Get2DMovie().Show();
}

simulated state Executing
{
Begin:
	InitUI();

	CompleteAction();
}

DefaultProperties
{
}
