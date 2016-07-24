//-----------------------------------------------------------
// Headquarters base view
//-----------------------------------------------------------
class XComCamState_HQ_BaseView extends XComCamState_HQ;

var() rotator					IsometricRotation;

var transient CameraActor               CamActor;

// On console, we bring the camera in closer to help with render thread perf.
var const float m_fPCDefaultViewDistance;
var const float m_fPCDefaultMinViewDistance;

static function float GetPlatformViewDistance()
{
// 	if( class'WorldInfo'.static.IsConsoleBuild() )
// 	{
// 		return class'XComCamState_HQ_BaseView'.default.m_fConsoleDefaultViewDistance;
// 	}

	return class'XComCamState_HQ_BaseView'.default.m_fPCDefaultViewDistance;
}

function Init( PlayerController ForPlayer )
{
	InitCameraState( ForPlayer );

	foreach WorldInfo.AllActors(class'CameraActor', CamActor)
	{
		if (CamActor.Tag == 'MissionControl')
			break;
	}
}

function GetView(float DeltaTime, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
/*	// focus is always on pawn
	out_Focus = PCOwner.Pawn.Location;

	// always use isometric rotation
	out_Rotation = IsometricRotation;

	out_ViewDistance = ViewDistance;

	PCOwner.SetRotation( out_Rotation );*/

	local vector AdjustedCamActorLoc;

	AdjustedCamActorLoc = CamActor.Location;
	AdjustedCamActorLoc.Y = GetPlatformViewDistance(); 


	out_ViewDistance = ViewDistance;
	out_Focus = AdjustedCamActorLoc;
	out_Rotation = CamActor.Rotation;
	out_FOV = CamActor.FOVAngle;
	PCOwner.SetRotation( out_Rotation );

	out_PPSettings = CamActor.CamOverridePostProcess;
	out_PPOverrideAlpha = CamActor.CamOverridePostProcessAlpha;
}

function CameraActor GetCameraActor()
{
	return CamActor;
}

DefaultProperties
{
	m_fPCDefaultViewDistance=1500f
	m_fPCDefaultMinViewDistance=-1000f

	IsometricRotation=(Pitch=0,Yaw=0)
	ViewDistance=0.0f
}
