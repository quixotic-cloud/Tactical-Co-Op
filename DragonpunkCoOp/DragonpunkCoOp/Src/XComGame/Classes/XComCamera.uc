//---------------------------------------------------------------------------------------
//  FILE:    XComCamera.uc
//  AUTHOR:  David Burchanowski  --  2/14/2014
//  PURPOSE: Provides the bridge from the X2 Camera stack to tactical gameplay.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

/// This class provides the needed abstraction/shim/interface layer to get the X2Camera/X2CameraStack system
/// to play nice with the Unreal camera system. Please let me (David) know about any changes you make at this level.
/// Almost all of your changes should be made strictly to X2Camera subclasses. Let's keep this thing modular!
class XComCamera extends XComCameraBase
	native
	config(Camera);

cpptext
{
	// There is some weird black magic that happens at the very end of the render pipe, where everything is considered to be 16x9 
	// and then the view matrix adjusts to the correct aspect. This function gets the necessary values to "undo" that.
	// See ULocalPlayer::GetAxisMultipliers
	static FVector2D GetAspectCorrection();
	static FVector2D GetAspectCorrectionForUI();
}

var private const config float DOF_MaxFarBlurAmount;
var private const config float DOF_MaxNearBlurAmount;
var private const config float DOF_FocusMinInnerRadius;
var private const config float DOF_FalloffExponent;
var private const config float DOF_BlurKernelSize;
var private const config float DOF_FocusInnerRadiusRatio;

static native function Vector2D GetAspectCorrectionScript();

simulated function Init()
{
}

event PostBeginPlay()
{
	super.PostBeginPlay();

	// create the camera stack
	CameraStack = new class'X2CameraStack';
}

// Yaw Camera by fDegrees
simulated function YawCamera(float Degrees)
{
	local XComTacticalSoundManager SoundMgr;

	SoundMgr = `XTACTICALSOUNDMGR;

	if( Degrees > 45 )
	{
		SoundMgr.PlaySoundEvent("TacticalUI_Camera_Rotation_Clockwise");
	}
	else if( Degrees < -45 )
	{
		SoundMgr.PlaySoundEvent("TacticalUI_Camera_Rotation_Counter_Clockwise");
	}

	CameraStack.YawCameras(Degrees);
}

// controller and key scroll input. 
simulated function ScrollCamera(float XOffset, float YOffset)
{
	local Vector2D Offset;

	Offset.X = XOffset;
	Offset.Y = YOffset;

	CameraStack.ScrollCameras(Offset);
}

// window edge scroll input
simulated function EdgeScrollCamera(float XOffset, float YOffset)
{
	local Vector2D Offset;

	Offset.X = XOffset;
	Offset.Y = YOffset;

	CameraStack.EdgeScrollCameras(Offset);
}

// raw (unsmoothed) scrolling input. To support Steam controllers and such which have their own smoothing functionality
simulated event RawScrollCamera(float XOffset, float YOffset)
{
	local Vector2D Offset;

	Offset.X = XOffset;
	Offset.Y = YOffset;

	CameraStack.RawScrollCameras(Offset);
}

// zooms the camera.
simulated function ZoomCamera(float Amount)
{
	CameraStack.ZoomCameras(Amount);
}

/**
 * Performs camera update.
 * Called once per frame after all actors have been ticked.
 */
simulated event UpdateCamera(float DeltaTime)
{
	super.UpdateCamera(DeltaTime);
	UpdateWorldInfoDOF(DeltaTime);
}

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	CameraStack.UpdateCameras(DeltaTime);
	OutVT.POV = CameraStack.GetCameraLocationAndOrientation();
	ApplyCameraModifiers(DeltaTime, OutVT.POV);
}

event bool ShowTargetingOutlines()
{
	return CameraStack.ShowTargetingOutlines();
}

event bool ShouldUnitUse3rdPersonStyleOutline(XGUnitNativeBase Unit)
{
	return CameraStack.ShouldUnitUse3rdPersonStyleOutline(Unit);
}

event bool ShouldUnitUseScanline(XGUnitNativeBase Unit)
{
	return CameraStack.ShouldUnitUseScanline(Unit);
}

event OnAnimNotifyCinescript(string EventLabel)
{
	CameraStack.OnCinescriptAnimNotify(EventLabel);
}

simulated protected function ApplyModifiers( float DeltaTime, out TPOV out_POV );
simulated function PostProcessInput();

protected function XComPresentationLayer PRES()
{
	return XComPresentationLayer(XComTacticalController(Owner).Pres);
}

protected function UpdateWorldInfoDOF(float DeltaTime)
{
	local float DistanceToFocusPoint;
	local float FocusInnerRadius;
	local Vector FocusPoint;

	if(CameraStack.GetCameraPostProcessOverrides(WorldInfo.DefaultPostProcessSettings))
	{
		// the camera is providing dof parameters
		if(CameraStack.GetCameraDOFFocusPoint(FocusPoint))
		{
			WorldInfo.DefaultPostProcessSettings.DOF_FocusPosition = FocusPoint;
			WorldInfo.DefaultPostProcessSettings.DOF_FocusType = FOCUS_Position;
			WorldInfo.DefaultPostProcessSettings.bOverride_DOF_FocusType = true;
		}
	}
	else if(CameraStack.GetCameraDOFFocusPoint(FocusPoint))
	{
		// the camera hasn't provided dof parameters, but it does define a focus point, so use the default parameters
		WorldInfo.DefaultPostProcessSettings.bEnableDOF = true;
		WorldInfo.DefaultPostProcessSettings.DOF_FocusPosition = FocusPoint;
		WorldInfo.DefaultPostProcessSettings.DOF_FocusType = FOCUS_Position;

		WorldInfo.DefaultPostProcessSettings.DOF_MaxFarBlurAmount  = DOF_MaxFarBlurAmount;
		WorldInfo.DefaultPostProcessSettings.DOF_MaxNearBlurAmount = DOF_MaxNearBlurAmount;
		WorldInfo.DefaultPostProcessSettings.DOF_FalloffExponent   = DOF_FalloffExponent;
		WorldInfo.DefaultPostProcessSettings.DOF_BlurKernelSize	   = DOF_BlurKernelSize; 

		// focus inner radius is a bit of a special snowflake, it should get larger with distance from
		// the camera
		DistanceToFocusPoint = VSize(CameraCache.POV.Location - FocusPoint); 
		FocusInnerRadius = Max(DistanceToFocusPoint * DOF_FocusInnerRadiusRatio, DOF_FocusMinInnerRadius);
		WorldInfo.DefaultPostProcessSettings.DOF_FocusInnerRadius  = FocusInnerRadius; 

		WorldInfo.DefaultPostProcessSettings.bOverride_EnableDOF = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_DOF_FalloffExponent = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_DOF_BlurKernelSize = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_DOF_MaxNearBlurAmount = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_DOF_MaxFarBlurAmount = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_DOF_FocusType = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_DOF_FocusInnerRadius = true;
		WorldInfo.DefaultPostProcessSettings.bOverride_DOF_FocusPosition = true;
	}
	else
	{
		// no overrides desired
		//WorldInfo.DefaultPostProcessSettings = EmptyOverrides;
		WorldInfo.DefaultPostProcessSettings.bEnableDOF = false;
	}
}

// This view is only used for the XComProfileGrid actor
simulated state ProfileGridView
{
	simulated protected function UpdateCameraView( float DeltaTime, out TPOV out_POV )
	{
		out_POV = CameraCache.POV;
	}

	simulated function PostProcessInput()
	{
	}
}

defaultproperties
{
	CameraStyle=ThirdPerson
	DefaultFOV=50
}



