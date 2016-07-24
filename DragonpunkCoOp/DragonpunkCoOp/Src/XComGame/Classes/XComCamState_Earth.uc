//-----------------------------------------------------------
// Base class for headquarters camera state classes
//-----------------------------------------------------------
class XComCamState_Earth extends XComCamState_HQ;

var XComHeadquartersCamera m_kCamera;
var const float fFOV;

function Init( PlayerController ForPlayer, XComHeadquartersCamera Camera )
{
	m_kCamera = Camera;
	InitCameraState( ForPlayer );
		
	`GAME.GetGeoscape().m_kBase.SetAvengerCapVisibility(false);
	`GAME.GetGeoscape().m_kBase.SetPostMissionSequenceVisibility(false);
	`EARTH.Show(true);
}

function AddRotationDelta( rotator Delta )
{
	local rotator kViewRotation;

	kViewRotation = m_kCamera.m_kEarthViewRotation;

	kViewRotation += Delta;
	kViewRotation.Pitch = clamp(kViewRotation.Pitch, -16384, 16384);
	
	if (kViewRotation.Yaw < -65536)
	{
		kViewRotation.Yaw = kViewRotation.Yaw + 65536;
	}
	else if(kViewRotation.Yaw > 65536)
	{
		kViewRotation.Yaw = kViewRotation.Yaw - 65536;
	}

	m_kCamera.m_kEarthViewRotation = kViewRotation;
}

function GetView(float DeltaTime, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
	local XComEarth Geoscape;

	Geoscape = `EARTH;

	m_kCamera.m_kEarthViewRotation.Yaw = -16384;
	m_kCamera.m_kEarthViewRotation.Roll = 0;
	m_kCamera.m_kEarthViewRotation.Pitch = int(float(-16384) * Geoscape.fCameraPitchScalar);


	out_Focus = Geoscape.GetNearestWorldViewLocation(m_kCamera.OldCameraStateOrientation.Focus);
	out_Focus.Z = 0.0f;
	out_Rotation = m_kCamera.m_kEarthViewRotation;
	out_ViewDistance = Geoscape.GetViewDistance();
	out_FOV = fFOV;

	out_PPSettings = m_kCamera.CamPostProcessSettings;
	out_PPOverrideAlpha = m_kCamera.CamOverridePostProcessAlpha;

}

DefaultProperties
{
	ViewDistance=18000
	fFOV = 90.0f
}
