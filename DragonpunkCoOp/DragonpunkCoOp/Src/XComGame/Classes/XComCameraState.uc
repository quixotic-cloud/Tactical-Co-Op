//-----------------------------------------------------------
// Self-contained code for updating the camera in a particular state
//-----------------------------------------------------------
class XComCameraState extends Object
	abstract;
	
var transient PlayerController			PCOwner;
var transient WorldInfo					WorldInfo;


protected function InitCameraState( PlayerController ForPlayer )
{
	PCOwner = ForPlayer;
	WorldInfo = ForPlayer.WorldInfo;
}

function GetViewFromCameraName( CameraActor CamActor_, name CamName_, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha );
function GetView(float DeltaTime, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha);

// Returns the CameraActor we are currently Targeting.
function CameraActor GetCameraActor()
{
	return none;
}

function EndCameraState();
