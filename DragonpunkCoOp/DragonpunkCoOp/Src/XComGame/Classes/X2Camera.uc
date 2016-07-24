//---------------------------------------------------------------------------------------
//  FILE:    X2Camera.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Base class for all cameras in X2
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

/// X2Camera is the mechanism by which the tactical game systems control and interact with the camera.
/// Systems that desire camera control should subclass X2Camera and implement the desired camera behavior,
/// then submit the camera to the X2CameraStack with X2CameraStack.AddCamera(). Do not worry if your camera
/// is not chosen by the stack, nor attempt to hack the stack to force your camera to be used. There is a
/// lot of interesting stuff to look at in XCom. Just set the desired priority type, and if you find that
/// insufficient, see David Burchanowski to work on a solution to the problem.
///
/// See X2CameraStack for more information on how this system is designed to work.
///
/// Please do NOT modify this class without talking to me (David B).
class X2Camera extends Object 
	config(Camera)
	native;

/// <summary>
/// Common structure for specifying camera shakes in the ini files. Allows the artists to adjust them without programmer
/// intervention.
/// </summary>
struct native CameraAnimIniEntry
{
	var string AnimPath;
	var float Intensity;
	var float Rate;

	structdefaultproperties
	{
		Intensity=1.0
		Rate=1.0
	}
};

struct native TFocusPoints
{
	var vector vFocusPoint;
	var vector vCameraLocation;
	var float fDelay;
	var float fCutoutHeightLimit;

	structdefaultproperties
	{
		fDelay = 0.25f
	}
};

// the order of this enum is imporant, as each entry's int value doubles as its
// priority (higher number = higher priority)
enum ECameraPriority
{
	eCameraPriority_Default, // Exlusively for the "default" camera, right now the cursor tracking camera
	eCameraPriority_EnemyHeadLookat, // for the lookat camera that is used when you hover over a UI alien head
	eCameraPriority_CharacterMovementAndFraming, // Units moving to and fro, but not a special action.
	eCameraPriority_LookAt,
	eCameraPriority_GameActions, // for game actions, explosions, and other sundry things that may be nice to look at
	eCameraPriority_Kismet, // for kismet lookats.
	eCameraPriority_Cinematic, // for matinees and other such full screen, attention grabbing happenings
};

/// <summary>
/// This will be the duration used for any blend transition TO this camera
/// </summary>
var privatewrite config float BlendDuration;

/// <summary>
/// Priority of this camera. Cameras with higher priority will be given precedence over lower priority cameras in the camera stack.
/// </summary>
var ECameraPriority Priority;

/// <summary>
/// Any camera can electively push another camera on top of itself. This allows you to build complex
/// camera sequences from simpler camera objects.
/// </summary>
var privatewrite X2Camera ChildCamera;

/// <summary>
/// If false, will only call this camera's update function if it is currently the active camera
/// </summary>
var bool UpdateWhenInactive;

/// <summary>
/// If true, hides
/// </summary>
var bool HidePathingWhenActive;

/// <summary>
/// Set to true when this camera fails activation. i.e., it removes itself during it's activation call
/// </summary>
var bool FailedActivation;

/// <summary>
/// if true, this camera will not slowdown or speed time when time is dilated
/// </summary>
var bool IgnoreSlomo;

/// <summary>
/// Get the frustum planes for the given TPOV
/// </summary>
native static final function GetFrustumPlanes(const out TPOV CameraLocation, out Plane TopPlane, out Plane BottomPlane, out Plane LeftPlane, out Plane RightPlane);

/// <summary>
/// Utility function to guarantee an unblocked line of sight to the target location. If the line trace from 
/// CameraLocation to TargetLocation is blocked, will adjust CameraLocation and CameraRotation to
/// find an unblocked location.
/// ActorsToIgnore contains a list of actors that should not be considered as blocking the trace.
/// Returns true if the camera was adjusted, or false otherwise
/// </summary>
native static final function bool AdjustCameraForBlockage(out Vector CameraLocation, 
														  out Rotator CameraRotation,
														  const out Vector TargetLocation,
														  optional const out array<Actor> ActorsToIgnore) const;

/// <summary>
/// Utility function to determine if the given trace is blocked for camera purposes.
///
/// Returns true if the trace was blocked, and false otherwise
/// </summary>
native static final function bool IsLineOfSightBlockedToLocation(const out Vector TraceStart,
																 const out Vector TraceEnd,
																 optional const out array<Actor> ActorsToIgnore) const;

/// <summary>
/// Returns true if the given point lies within the given camera frustum
/// </summary>
native static final function bool IsPointWithinCameraFrustum(const out TPOV CameraLocation, Vector Point);

native static final function OverridePPSettings(out PostProcessSettings ToOverride, const out PostProcessSettings OverrideWith);

/// <summary>
/// Allows cameras to selectively use a generic blend function from the specified previously active camera
/// </summary>
function bool ShouldBlendFromCamera(X2Camera PreviousActiveCamera)
{
	return false;
}

/// <summary>
/// Called when this camera becomes "active", i.e. it is contributing to the final camera location
/// CurrentPOV contains the actual location/orientation of the game camera at the time this camera is activated,
/// so that the activated camera can initialize itself to match the current camera as closely as possible.
/// PreviousActiveCamera is exactly what it sounds like, for more precise inits.
/// LastActiveLookAtCamera is the last lookat camera that was active, however long ago that was. This is to allow
/// the game cameras to maintain user preferences for zoom, orientation, etc after activating non-lookat cameras
/// </summary>
function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera);

/// <summary>
/// Called when this camera ceases to be "active", i.e. it is no longer contributing to the final camera location.
/// </summary>
function Deactivated();

/// <summary>
/// Called when this camera is added to the stack.
/// </summary>
function Added();

/// <summary>
/// Called when this camera is removed from the stack. Note that this happens before the camera is deactivated (it will remain active
/// until the end of the frame).
/// </summary>
function Removed()
{
	local X2Camera ChildCameraIterator;

	// fire remove on all child cameras as well
	ChildCameraIterator = ChildCamera;
	while(ChildCameraIterator != none)
	{
		ChildCameraIterator.Removed();
		ChildCameraIterator = ChildCameraIterator.ChildCamera;
	}
}

/// <summary>
/// Pushes a new camera on top of this one. This camera will be suspended until the pushed camera
/// is removed.
/// </summary>
function PushCamera(X2Camera CameraToPush)
{
	if(ChildCamera != none)
	{
		PopCamera();
	}

	ChildCamera = CameraToPush;
	ChildCamera.Added();
}

/// <summary>
/// Pops the camera above this one, and any children it has.
/// </summary>
function PopCamera()
{
	ChildCamera.Removed();
	ChildCamera = none;
}

/// <summary>
/// Updates this camera. Subclassed cameras that vary over time should override this function
/// </summary>
function UpdateCamera(float DeltaTime);

/// <summary>
/// Returns the current point of view of this camera. Subclassed cameras should override this function. 
/// </summary>
function TPOV GetCameraLocationAndOrientation();

/// <summary>
/// If this camera would have been the active camera, yields to the next camera in line. Useful for having a 
/// camera that is "waiting" for some condition to become active.
/// </summary>
function bool YieldIfActive()
{
	return false;
}

/// <summary>
/// Returns the current focus point of this camera. This is used for building cutdown, transparency, etc. Basically,
/// visibility to this point will be cleared so you can see it. The first item in the array will be considered to have the
/// priority with regards to building visibility and building cutdown.
/// </summary>
function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local TFocusPoints FocusPoint;
	FocusPoint.vFocusPoint = vect(0, 0, 99999);
	FocusPoint.vCameraLocation = vect(0, 0, 99999);
	OutFocusPoints.AddItem(FocusPoint);
}

/// <summary>
/// If you return true, you must fill out the focus point value.
/// This value will be used for depth of field calculations. If you don't need DOF effects, this function can be
/// ignored by subclasses.
/// </summary>
function bool GetCameraDOFFocusPoint(out vector FocusPoint)
{
	return false;
}

/// <summary>
/// Returns the minimum floor level for which to reveal. -1 disables this functionality
/// </summary>
function bool GetCameraIsPrimaryFocusOn()
{
	return false;
}

/// <summary>
/// If you return true, the unreal camera will use the given post process overrides structure as the
/// new post process overrides
/// </summary>
function bool GetCameraPostProcessOverrides(out PostProcessSettings PostProcessOverrides)
{
	return false;
}

/// <summary>
/// Notifies the camera that the user is attempting to scroll with key input
/// </summary>
function ScrollCamera(Vector2D Offset);

/// <summary>
/// Notifies the camera that the user is attempting to scroll with the window edges
/// </summary>
function EdgeScrollCamera(Vector2D Offset);

/// <summary>
/// Notifies the camera that the user is attempting to scroll without smoothing
/// </summary>
function RawScrollCamera(Vector2D Offset);

/// <summary>
/// Notifies the camera that the user is attempting to Zoom.
/// Zoom is intended to go from 0.0 (no zoom) to 1.0 (max zoom).
/// Cameras are allowed to deviate from this but all incoming zoom tuning is built around that
/// assumption.
/// </summary>
function ZoomCamera(float ZoomAmount);

/// <summary>
/// Notifies the camera that the user is attempting to Yaw.
/// </summary>
function YawCamera(float Degrees);

/// <summary>
/// Notifies the camera that the user is attempting to adjust the camera pitch.
/// </summary>
function PitchCamera(float Degrees);

/// <summary>
/// Override this function to return true if your camera behavior wants buildings to cut down.
/// This is generally not desired for cinematic, over the shoulder and glam style cameras.
/// </summary>
function bool AllowBuildingCutdown()
{
	return false;
}

/// <summary>
/// Indicates if the camera should allow old focus points to expire. Setting to True will allow new focus points to remain while retaining old focus points.
/// </summary>
function bool DisableFocusPointExpiration()
{
	return false;
}

function bool HidePathing()
{
	return HidePathingWhenActive;
}

function bool HidePathingBorder()
{
	return HidePathingWhenActive;
}

/// <summary>
/// Override to notify rendering that this camera should use the 3rd person outline rendering
/// </summary>
function bool ShowTargetingOutlines()
{
	return false;
}

/// <summary>
/// Override to notify rendering that you want a particular unit to use the 3rd person style unit targeting outline
/// </summary>
function bool ShouldUnitUse3rdPersonStyleOutline(XGUnitNativeBase Unit)
{
	return false;
}

/// <summary>
/// Override to notify rendering that you do not want a particular unit to use scanline rendering
/// </summary>
function bool ShouldUnitUseScanline(XGUnitNativeBase Unit)
{
	return false;
}

/// <summary>
/// Utility function to allow cameras to remove themselves from the camera stack. Handy for self-managing or timed cameras.
/// </summary>
 protected function RemoveSelfFromCameraStack()
{
	local XGBattle Battle;
	local XComCamera Cam;

	Battle = `BATTLE;
	if(Battle == none) return;
	
	Cam = XComCamera(Battle.GetALocalPlayerController().PlayerCamera);
	if(Cam == none) return;

	Cam.CameraStack.RemoveCamera(self);
}

/// <summary>
/// Plays the requested camera anim. This will automatically be cleaned up when the camera is not active
/// </summary>
function PlayCameraAnim(string AnimPath, optional float Rate = 1.0f, optional float Intensity = 1.0, optional bool Loop = false)
{
	`CAMERASTACK.PlayCameraAnim(AnimPath, Rate, Intensity, Loop);
}

function string GetDebugDescription()
{
	return string(Name);
}

/// <summary>
/// Let the camera provide its own debug information as part of X2DebugCameras. Override in sub classes that need debugging.
/// </summary>
simulated function DrawDebugLabel(Canvas kCanvas);

defaultproperties
{
	Priority = eCameraPriority_GameActions
	FailedActivation = false
	HidePathingWhenActive = true
}
