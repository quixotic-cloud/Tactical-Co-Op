//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_HideLoadingScreen extends X2Action;

var private XComPresentationLayer PresentationLayer;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function bool CheckInterrupted()
{
	return false;
}

function HideLoadingScreen()
{
	local XComPresentationLayer Pres;

	Pres = XComPresentationLayer(XComTacticalController(GetALocalPlayerController()).Pres);

	if( class'XComEngine'.static.IsLoadingMoviePlaying() )
	{	
		Pres.HideLoadingScreen();		
	}
}

function SetCameraFade()
{
	PresentationLayer = `PRES;
	PresentationLayer.HUDHide();

	XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).ClientSetCameraFade(true, MakeColor(0,0,0), vect2d(0,1), 0.0);
}

simulated state Executing
{
Begin:
	SetCameraFade();

	Sleep(0.0f); //Let the camer fade take effect

	HideLoadingScreen();

	CompleteAction();
}

DefaultProperties
{
}
