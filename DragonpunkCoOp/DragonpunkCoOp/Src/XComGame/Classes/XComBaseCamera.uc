//-----------------------------------------------------------
// Handles camera states and interpolation
//-----------------------------------------------------------
class XComBaseCamera extends XComCameraBase
	abstract;

struct CameraStateOrientation
{
	var transient vector	Focus;
	var transient rotator	Rotation;
	var transient float		ViewDistance;
	var transient float     FOV;
	var transient PostProcessSettings PPSettings;
	var transient float	PPOverrideAlpha;
};

var transient XComCameraState			CameraState/*, OldCameraState*/;
var transient CameraStateOrientation	OldCameraStateOrientation;
var transient CameraStateOrientation	LastCameraStateOrientation;

var transient bool						bHasOldCameraState;
var transient float						AnimTime, TotalAnimTime;

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	// don't let our delta time hitch
	DeltaTime = FMin( DeltaTime, 0.0333f );	

	// if we have an OldCameraState, then we are interpolating
	if ( bHasOldCameraState )
	{
		InterpCameraState(DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation, OutVT.POV.FOV, CamPostProcessSettings, CamOverridePostProcessAlpha);
	}
	else
	{
		UpdateCameraState( DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation, OutVT.POV.FOV, CamPostProcessSettings, CamOverridePostProcessAlpha );
	}


	// Apply camera modifiers at the end (view shakes for example)
	ApplyCameraModifiers(DeltaTime, OutVT.POV);
}

function XComCameraState SetCameraState( class<XComCameraState> NewStateClass, float InInterpTime )
{
//	`log( "SetCameraState:"@CameraState@NewStateClass@InInterpTime@bHasOldCameraState @ "    " @ WorldInfo.TimeSeconds );

	bHasOldCameraState = false;

	// notify the current camera state that it is ending
	if ( CameraState != none )
	{
		CameraState.EndCameraState();

		if ( InInterpTime > 0.0f )
		{
			bHasOldCameraState = true;
			OldCameraStateOrientation = LastCameraStateOrientation;
		}
	}

	CameraState = new NewStateClass;

	AnimTime = 0.0f;
	TotalAnimTime = InInterpTime;

	if ( !bHasOldCameraState )
	{
		SetTimer( 0.001f, false, 'OnCameraInterpolationComplete' );
	}
	else
	{
		ClearTimer( 'OnCameraInterpolationComplete' );
	}

	return CameraState;
}

protected function UpdateCameraState( float DeltaTime, out vector out_Location, out rotator out_Rotation, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha )
{
	GetCameraStateView( CameraState, DeltaTime, LastCameraStateOrientation );

	out_Location = LastCameraStateOrientation.Focus - vector(LastCameraStateOrientation.Rotation) * LastCameraStateOrientation.ViewDistance;
	out_Rotation = LastCameraStateOrientation.Rotation;
	out_FOV = LastCameraStateOrientation.FOV;
	out_PPSettings = LastCameraStateOrientation.PPSettings;
	out_PPOverrideAlpha = LastCameraStateOrientation.PPOverrideAlpha;
}

protected function InterpCameraState(float DeltaTime, out vector out_Location, out rotator out_Rotation, out float out_FOV, out PostProcessSettings out_PPSettings, out float out_PPOverrideAlpha)
{
	local float tVal;

	//GetCameraStateView( OldCameraState, DeltaTime, ViewFocus1, ViewRot1, ViewDist1 );
	GetCameraStateView( CameraState, DeltaTime, LastCameraStateOrientation );

	AnimTime += DeltaTime;

	tVal = GetDoubleTweenedRatio( FMin( AnimTime / TotalAnimTime, 1.0f ) );

	LastCameraStateOrientation.Focus = VLerp( OldCameraStateOrientation.Focus, LastCameraStateOrientation.Focus, tVal );
	LastCameraStateOrientation.Rotation =   RLerp( OldCameraStateOrientation.Rotation, LastCameraStateOrientation.Rotation, tVal, true );
	LastCameraStateOrientation.ViewDistance =  Lerp( OldCameraStateOrientation.ViewDistance, LastCameraStateOrientation.ViewDistance, tVal );
	LastCameraStateOrientation.FOV =  Lerp( OldCameraStateOrientation.FOV, LastCameraStateOrientation.FOV, tVal );	
	LastCameraStateOrientation.PPOverrideAlpha = Lerp(OldCameraStateOrientation.PPOverrideAlpha, LastCameraStateOrientation.PPOverrideAlpha, tVal);
	class'Helpers'.static.OverridePPSettings(LastCameraStateOrientation.PPSettings, OldCameraStateOrientation.PPSettings, 1.0f - tVal);

	out_Location = LastCameraStateOrientation.Focus - vector(LastCameraStateOrientation.Rotation) * LastCameraStateOrientation.ViewDistance;
	out_Rotation = LastCameraStateOrientation.Rotation;
	out_FOV = LastCameraStateOrientation.FOV;//DefaultFOV;
	out_PPOverrideAlpha = LastCameraStateOrientation.PPOverrideAlpha;
	out_PPSettings = LastCameraStateOrientation.PPSettings;

	if ( AnimTime >= TotalAnimTime )
	{
//		`log( "Interp Done!" @ AnimTime @ TotalAnimTime @ "     " @  WorldInfo.TimeSeconds );
		bHasOldCameraState = false;
		OnCameraInterpolationComplete();
	}
}

protected function GetCameraStateView( XComCameraState CamState, float DeltaTime, out CameraStateOrientation NewOrientation )
{
	if (CamState != none)
		CamState.GetView( DeltaTime, NewOrientation.Focus, NewOrientation.Rotation, NewOrientation.ViewDistance, NewOrientation.FOV, NewOrientation.PPSettings, NewOrientation.PPOverrideAlpha );
}

protected function OnCameraInterpolationComplete();

final function float GetDoubleTweenedRatio( float tVal )
{
	if ( tVal < 0.50f )
	{
		return GetTweenedRatio( tVal * 2.0f, 2.0f, 1.0f ) * 0.50f;
	}
	else
	{
		return 0.50f + ( GetTweenedRatio( ( tVal - 0.50f ) * 2.0f, 2.0f, 0.0f ) * 0.50f );
	}
}

DefaultProperties
{

}
