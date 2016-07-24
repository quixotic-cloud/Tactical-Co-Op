//-----------------------------------------------------------
// Base class for headquarters camera state classes
//-----------------------------------------------------------
class XComCamState_HQ_FreeMovement extends XComCamState_HQ;

var private Vector m_vInitialFocus; 
var private Vector m_vTargetFocus; 

var private float  m_fInitialViewDistance; 
var private float  m_fTargetViewDistance;

var private rotator m_fCurrentAddRot;
var private rotator m_fTargetAddRot;

var transient CameraActor               CamActor;

function Init( PlayerController ForPlayer, vector initialFocus, float initialViewDistance )
{
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'CameraActor', CamActor)
	{
		if (CamActor.Tag == 'Base')
			break;
	}

	if(CamActor != none)
	{
		m_fCurrentAddRot = CamActor.Rotation;
		m_fTargetAddRot = CamActor.Rotation;
	}

	initialViewDistance = initialViewDistance + initialFocus.Y;
	//initialFocus.Y = 0;

	m_vInitialFocus = initialFocus;
	m_vTargetFocus = initialFocus;

	m_fInitialViewDistance = ViewDistance;//initialViewDistance;
	m_fTargetViewDistance = m_fInitialViewDistance;
	InitCameraState( ForPlayer );
}

function SetTargetFocus(vector targetFocus)
{
	m_vTargetFocus = targetFocus;
	m_vTargetFocus.Y = 0;
}

function GetView(float DeltaTime, out vector out_Focus, out rotator out_Rotation, out float out_ViewDistance, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
	out_Focus = InterpFocus(DeltaTime);
	out_ViewDistance = InterpViewDistance( DeltaTime );
	
	if(CamActor != none)
	{
		out_Rotation = CamActor.Rotation;
		out_FOV = CamActor.FOVAngle;
		out_PPSettings = CamActor.CamOverridePostProcess;
		out_PPOverrideAlpha = CamActor.CamOverridePostProcessAlpha;
	}
	
	PCOwner.SetRotation( out_Rotation );
}

protected function float InterpViewDistance( float DeltaTime )
{
	m_fInitialViewDistance += (m_fTargetViewDistance - m_fInitialViewDistance) * DeltaTime*4;

	return m_fInitialViewDistance;//FMax(m_fInitialViewDistance, 128);
}

protected function vector InterpFocus( float DeltaTime )
{
	m_vInitialFocus += (m_vTargetFocus - m_vInitialFocus) * FMin(1.0f, DeltaTime*10);

	return m_vInitialFocus;
}

function LookAt( Vector vLoc )
{
	m_vTargetFocus = vLoc;
	//m_vTargetFocus.Y = 0;
}

function SetViewDistance( float fDist )
{ 
	m_fTargetViewDistance = fDist;
	//m_fInitialViewDistance = GetCurrentViewDistance();
	//m_TViewDistanceBlend = 0.0;

	//if (m_fTargetViewDistance >= (class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance() - class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance()/10))
	//{
	//	`HQ.m_kBase.SetAvengerCapVisibility(true);
	//}
	//else
	//{
		`GAME.GetGeoscape().m_kBase.SetAvengerCapVisibility(false);
		`GAME.GetGeoscape().m_kBase.SetPostMissionSequenceVisibility(false);
	//}
}

DefaultProperties
{
	ViewDistance=500.0f
}
