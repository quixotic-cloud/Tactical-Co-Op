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

var private int m_iFrame;			// Current frame
var private int m_iInterpInitialFrame;		// The frame that current smoothly-interpolated movement starts at
var private int m_iNumInterpFrames;		// The number of frames during which to interpolate to the target focus.
var private Vector m_vCurrentFocus;		// Where the camera currently focuses (interpolating between m_vInitialFocus and m_vTargetFocus).
var private float MidViewDistance;
var private float CloseViewDistance;
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
	m_vCurrentFocus = initialFocus;
	m_iFrame = 0;
	m_iNumInterpFrames = 1;

	m_fInitialViewDistance = ViewDistance;//initialViewDistance;
	m_fTargetViewDistance = m_fInitialViewDistance;
	InitCameraState( ForPlayer );
}

function SetTargetFocus(vector targetFocus)
{
	m_vTargetFocus = targetFocus;
	m_vTargetFocus.Y = 0;
	m_vInitialFocus = m_vCurrentFocus;
	m_iInterpInitialFrame = m_iFrame;
	m_iNumInterpFrames = 1;
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

	local float t;
	local int iInterpolationFrame;
	
	++m_iFrame; // This is valid because InterpFocus gets called every frame.
	iInterpolationFrame = m_iFrame - m_iInterpInitialFrame;

	if (iInterpolationFrame < m_iNumInterpFrames)
	{
		t = float(iInterpolationFrame) / float(m_iNumInterpFrames);

		t = 1.0f - (1.0f - t) * (1.0f - t) * (1.0f - t); //Smooth out, cubic

		m_vCurrentFocus = m_vInitialFocus + (m_vTargetFocus - m_vInitialFocus) * t;
	}
	else
	{
		m_vCurrentFocus = m_vTargetFocus;
	}
	
	return m_vCurrentFocus;
}

//<workshop> Fixing avenger zoom bug TTP 1796 - exiting a room while holding R2 AMS 2016/06/15
function bool FreeMovementInterpolationIsOccurring()
{
	local int iInterpolationFrame;
	
	//A one-frame interpolation takes place when the player moves the camera around manually.
	//Do not block trigger input in this case. TTP 6027 / BET 2016-07-05
	if(m_iNumInterpFrames < 2)
		return false;

	iInterpolationFrame = m_iFrame - m_iInterpInitialFrame;
	
	return iInterpolationFrame < m_iNumInterpFrames;
}

function LookAt(Vector vLoc, optional bool bUpdateY = true, optional int iNumInterpFrames = 30)
{
	m_vInitialFocus = m_vCurrentFocus;
	m_vTargetFocus = vLoc;
	if (!bUpdateY)
	{
		m_vTargetFocus.Y = m_vCurrentFocus.Y;
	}
	m_iInterpInitialFrame = m_iFrame;
	m_iNumInterpFrames = iNumInterpFrames;
}
function LookAtRoom(Vector vLoc, optional bool bUpdateY=true)
{
	//SetInitialViewDistance();
	LookAt(vLoc, bUpdateY, 15); // 15 = smooth yet swift interpolation
}
function LookAtImmediate(Vector vLoc, optional bool bUpdateY=true)
{
	LookAt(vLoc, bUpdateY, 1);  // 1 = immediate
}
function SetInitialViewDistance()
{
	SetViewDistance(ViewDistance); // Set to far view distance.
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

function float GetTargetViewDistance()
{
	return m_fTargetViewDistance;
}

function SetInitialFocus(Vector Location)
{
	m_vInitialFocus = Location;
}
DefaultProperties
{
	ViewDistance=500.0f
}
