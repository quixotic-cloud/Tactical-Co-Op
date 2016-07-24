//---------------------------------------------------------------------------------------
//  FILE:    X2CameraStack.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Manages the camera stack in tactical gameplay
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
/// The camera stack keeps track of and arbitrates all in-flight camera requests from the game.
/// Game systems that want to control the camera should subclass X2Camera and add an instace of their camera subclass
/// to the camera stack with AddCamera(). When they no longer desire camera control call RemoveCamera().
///
/// Note that any number of cameras may be on the stack. DO NOT attempt to directly interact with or interfere with
/// cameras added by other game systems! This system is designed so that user systems don't need to care
/// about how or why other cameras are designed, and to prevent unneeded complexity from multiple things juggling the
/// same camera state as was done in the base game. If you camera doesn't get focus and you think it should, talk to 
/// David Burchanowski. Remember, only YOU can prevent pre-release camera bug stomping agony.
///
/// Example: Let's assume that three different aliens are being shot at in a replay at the same time a gas tank explodes.
/// Four cameras should be created, and the appropriate priorites set. X2Action_ShootAtAlien should add a camera for each 
/// of the aliens that are fired at. Whatever manages the explosion should likewise add it's own camera instance. None of 
/// these systems are aware that the other cameras even exist, nor do they need to care. Likewise, the actual functionality 
/// of each of the cameras is completely transparent to the camera stack, it acts exclusively as an arbiter. In this way, we 
/// can reduce bugs caused by system cross chatter and minimize accidental bugs. You can't accidentally break other systems
/// by changing unshared codepaths.
class X2CameraStack extends Object
	config(Camera);

/// <summary>
/// Track camera anims currently playing on the stack
/// </summary>
struct X2CameraAnimInst
{
	var CameraAnimInst AnimInstance; // unreal instance of the camera anim that is playing
	var bool GlobalAnim; // if true, this anim will not be cleaned up on active camera change. Only valid for non-looping anims 
	var bool PendingCleanup; // on active camera change, used to mark anims that need to be cleaned up
};

/// <summary>
/// Array of camera anims playing currently
/// </summary>
var private array<X2CameraAnimInst> CameraAnims;

/// <summary>
/// Curve to smoothly blend between cameras
/// </summary>
var private const config InterpCurveFloat BlendCurve;

/// <summary>
/// Current stack of cameras. The 0th index camera is the bottom of the stack. Conversely, the active camera is 
/// at index Length - 1.
/// </summary>
var private array<X2Camera> Cameras;

/// <summary>
/// The currently active camera. Reevaluated every update tick.
/// </summary>
var private X2Camera ActiveCamera;

/// <summary>
/// The last look at camera that was activated
/// </summary>
var private X2Camera_LookAt LastActiveLookAtCamera;

/// <summary>
/// Current alpha of the active blend
/// </summary>
var private float BlendAlpha;

/// <summary>
/// Current blend duration
/// </summary>
var private float BlendDuration;

/// <summary>
/// TPOV when we started blending.
/// </summary>
var private TPOV BlendPOV;

/// <summary>
/// Sentinel value to help us detect cameras that fail activation (by removing themselves during activation)
/// </summary>
var private X2Camera PendingActiveCamera;

/// <summary>
/// Gets the final, aggregated camera point of view information for the cameras currently on the stack
/// </summary>
function TPOV GetCameraLocationAndOrientation()
{
	local TPOV EffectiveTPOV;
	local float SmoothAlpha;

	if(ActiveCamera != none)
	{
		EffectiveTPOV = ActiveCamera.GetCameraLocationAndOrientation();
		
		// if needed, blend
		if(BlendAlpha < 1.0)
		{
			// for now, simple sin blend. We can replace this with a fancier curve later
			SmoothAlpha = class'Helpers'.static.S_EvalInterpCurveFloat(BlendCurve, BlendAlpha);

			EffectiveTPOV.Location = VLerp(BlendPOV.Location, EffectiveTPOV.Location, SmoothAlpha);
		
			// convert orientation to vectors and blend those. It looks nice
			EffectiveTPOV.Rotation = RLerp(BlendPOV.Rotation, EffectiveTPOV.Rotation, SmoothAlpha, true);
			EffectiveTPOV.FOV = Lerp(BlendPOV.FOV, EffectiveTPOV.FOV, SmoothAlpha);
		}
	}

	return EffectiveTPOV;
}

function bool ContainsCameraOfClass(name ClassName)
{
	local int i;

	for (i = 0; i < Cameras.Length; i++)
	{
		if (Cameras[i].IsA(ClassName))
		{
			return true;
		}
	}

	return false;
}

function bool ActiveCameraHidesPath()
{
	return ActiveCamera != none ? ActiveCamera.HidePathing() : true;
}

function bool ActiveCameraHidesBorder()
{
	return ActiveCamera != none ? ActiveCamera.HidePathingBorder() : true;
}

/// <summary>
/// Adds the specified X2Camera to the camera stack
/// </summary>
function AddCamera(X2Camera Camera)
{
	local X2Camera CameraCheck;
	local int Index;

	if(Camera == none) 
	{
		`Redscreen("Attempted to add none camera in X2CameraStack::AddCamera");
		return;
	}

	if(Camera.FailedActivation)
	{
		`Redscreen("Attempted to add a camera in X2CameraStack::AddCamera that has already failed activation: " $ Camera.GetDebugDescription());
		return;
	}

	// don't add the same camera twice
	for (Index = 0; Index < Cameras.Length; Index++)
	{
		CameraCheck = Cameras[Index];
		while(CameraCheck != none)
		{
			if(CameraCheck == Camera)
			{
				`Redscreen("Attempting to add a camera that is already in the camera stack!");
				return;
			}

			CameraCheck = CameraCheck.ChildCamera;
		}
	}

	// find the appropriate place in the stack to put this camera based on priority
	for(Index = 0; Index < Cameras.Length; Index++)
	{
		if(Cameras[Index].Priority > Camera.Priority)
		{
			Cameras.InsertItem(Index, Camera);
			break;
		}
	}

	if(Index >= Cameras.Length)
	{
		// we didn't insert the camera because it is highest priority, so append here
		Cameras.AddItem(Camera);
	}

	Camera.Added();
}

/// <summary>
/// Removes the specified X2Camera from the camera stack
/// </summary>
function RemoveCamera(X2Camera Camera)
{
	local X2Camera BaseCamera;
	local int Index;

	if (Camera == none)
	{
		`RedScreen("RemoveCamera called for a null Camera\n" $ GetScriptTrace());
	}

	// detect failed activations
	if(PendingActiveCamera == Camera)
	{
		Camera.FailedActivation = true;
	}

	for(Index = 0; Index < Cameras.Length; Index++)
	{
		// check each base camera (the one at the bottom of the chain)
		BaseCamera = Cameras[Index];
		if(Cameras[Index] == Camera)
		{
			// remove this camera
			Cameras.Remove(Index, 1);
			Camera.Removed();
			return;
		}
		
		// check down the camera chain as well
		while(BaseCamera != none)
		{
			if(Camera == BaseCamera.ChildCamera)
			{
				BaseCamera.PopCamera();
				return;
			}

			BaseCamera = BaseCamera.ChildCamera;
		}
	}

	`log("Attempting to remove camera: " $ Camera.Name $ "that was never added!", , 'XComCameraMgr');
}

/// <summary>
/// Does common logic to activate a newly active camera
/// </summary>
private function ActivateNewActiveCamera(X2Camera NewActiveCamera, X2Camera PreviousActiveCamera)
{
	local X2Camera_LookAt LookAtCamera;
	local TPOV BlankTPOV;

	if (ActiveCamera != none)
		ActiveCamera.Deactivated();

	if(NewActiveCamera != none)
	{
		PendingActiveCamera = NewActiveCamera;
		if(PreviousActiveCamera != none)
		{
			NewActiveCamera.Activated(PreviousActiveCamera.GetCameraLocationAndOrientation(), PreviousActiveCamera, LastActiveLookAtCamera);
		}
		else
		{
			NewActiveCamera.Activated(BlankTPOV, none, LastActiveLookAtCamera);
		}
		PendingActivecamera = none;

		LookAtCamera = X2Camera_LookAt(NewActiveCamera);
		if(LookAtCamera != none)
		{
			LastActiveLookAtCamera = LookAtCamera;
		}

		if(PreviousActiveCamera != none 
			&& PreviousActiveCamera != NewActiveCamera
			&& NewActiveCamera.ShouldBlendFromCamera(PreviousActiveCamera))
		{
			BlendAlpha = 0.0;
			BlendDuration = NewActiveCamera.BlendDuration;
			BlendPOV = PreviousActiveCamera.GetCameraLocationAndOrientation();
		}
		else
		{
			BlendAlpha = 1.0;
			BlendDuration = 1.0f;
		}
	}

	ActiveCamera = NewActiveCamera;
}

/// <summary>
/// Updates all cameras in the camera stack. Should only be called from the stack owner
/// </summary>
public function UpdateCameras(float Deltatime)
{
	local int Index;
	local X2Camera BaseCamera;
	local float SlomoAdjustedDeltaTime;

	DetermineNewActiveCamera();

	SlomoAdjustedDeltaTime = DeltaTime / class'WorldInfo'.static.GetWorldInfo().TimeDilation; //Undo any time dilation for the camera

	for(Index = Cameras.Length - 1; Index >= 0; --Index) // <apc> reversed order since UpdateCamera can potentially delete itself from the stack.
	{
		BaseCamera = Cameras[Index];

		while(BaseCamera != none)
		{
			if(BaseCamera == ActiveCamera || BaseCamera.UpdateWhenInactive)
			{
				BaseCamera.UpdateCamera(BaseCamera.IgnoreSlomo ? SlomoAdjustedDeltaTime : DeltaTime);
			}

			BaseCamera = BaseCamera.ChildCamera;
		}
	}

	if(BlendDuration != 0.0f)
	{
		BlendAlpha = fMin(BlendAlpha + DeltaTime / BlendDuration, 1.0); 
	}
	else
	{
		BlendAlpha = 1.0f;
	}
}

/// <summary>
/// Prints debug info to the screen so the user can see what the camera stack is doing
/// </summary>
simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string DebugString;
	local int CameraIndex;
	local X2Camera CameraEntry;
	local int StackDepth;
	local string Padding;

	if(!XComTacticalCheatManager(`XCOMGRI.GetALocalPlayerController().CheatManager).bDebugCameras)
	{
		return;
	}

	Padding = "-----------------------------"; // just a bunch of indents we can pull from

	DebugString = "===================================\n";
	DebugString $= "=======    Camera Stack   ========\n";
	DebugString $= "===================================\n\n";

	// walk the stack backwards so that the active camera appears at the top of the list
	Cameras[Cameras.Length - 1].DrawDebugLabel(kCanvas);
	for(CameraIndex = Cameras.Length - 1; CameraIndex >= 0; CameraIndex--)
	{
		StackDepth = 0;
		CameraEntry = Cameras[CameraIndex];
		while(CameraEntry != none)
		{
			DebugString $= Left(Padding, StackDepth * 3) $ CameraEntry.GetDebugDescription() $ "\n";
			CameraEntry = CameraEntry.ChildCamera;
			StackDepth++;
		}

		DebugString $= "\n";
	}
	
	// draw a background box so the text is readable
	kCanvas.SetPos(10, 150);
	kCanvas.SetDrawColor(0, 0, 0, 100);
	kCanvas.DrawRect(400, 200);

	// draw the text
	kCanvas.SetPos(10, 150);
	kCanvas.SetDrawColor(0,255,0);
	kCanvas.DrawText(DebugString);
}

/// <summary>
/// Scans the camera stack and determines the new active camera
/// </summary>
function DetermineNewActiveCamera()
{
	local X2Camera NewActiveCamera;
	local X2Camera PreviousActiveCamera;
	local bool ActiveCameraChanged;
	local int ActiveCameraSwitchCount;
	local int CameraIndex;
	local int ChildCount;

	PreviousActiveCamera = ActiveCamera;

	// keep looping until the active camera has stabilized. Any given camera can yield during activation,
	// and so we want to make sure we end up with the correct camera
	do
	{
		ActiveCameraChanged = false;

		// determine the camera that should be active now
		for(CameraIndex = Cameras.Length - 1; CameraIndex >= 0; CameraIndex--)
		{
			if(!Cameras[CameraIndex].YieldIfActive())
			{
				NewActiveCamera = Cameras[CameraIndex];
				break;
			}
		}

		// Any given base level camera can have pushed any number of child cameras.
		// Move up until we find the top level one.
		if(NewActiveCamera != none)
		{
			while (NewActiveCamera.ChildCamera != none && !NewActiveCamera.ChildCamera.YieldIfActive())
			{
				NewActiveCamera = NewActiveCamera.ChildCamera;

				ChildCount++;
				if(ChildCount > 1000)
				{
					// runaway child camera stack!
					`assert(false);
					break;
				}
			}
		}

		// If the desired active camera has changed, init it
		if(NewActiveCamera != ActiveCamera) 
		{
			// mark all anims as pending cleanup. After the new active camera has been settled on, we will cleanup
			// any anims that the new active camera has not also requested
			MarkAllCameraAnimsAsPendingCleanup();

			ActivateNewActiveCamera(NewActiveCamera, PreviousActiveCamera);
			ActiveCameraChanged = true;
			++ActiveCameraSwitchCount;
		}

		if( ActiveCameraSwitchCount > 1000 )
		{
			`redscreen( "DetermineNewActiveCamera has entered an infinite loop! NewActiveCamera:"@NewActiveCamera@"ActiveCamera:"@ActiveCamera@"PreviousActiveCamera"@PreviousActiveCamera);
			break;
		}
	} until(!ActiveCameraChanged);

	// cleanup any anims that still need to cleaned up
	CleanupCameraAnims();
}

/// <summary>
/// Plays the requested camera anim on the currently active camera. This will automatically be cleaned up when the camera is not active.
/// if PlayGlobally is set to true, this cameraanim will not be stopped when the active camera changes
/// </summary>
function PlayCameraAnim(string AnimPath, optional float Rate = 1.0f, optional float Intensity = 1.0, optional bool Loop = false, optional bool GlobalAnim = false)
{
	local XGBattle Battle;
	local XComCamera Cam;
	local CameraAnim Anim;
	local X2CameraAnimInst AnimInstance;
	local int Index;

	Battle = `BATTLE;
	if(Battle == none) return;
	
	Cam = XComCamera(Battle.GetALocalPlayerController().PlayerCamera);
	if(Cam == none) return;

	Anim = CameraAnim(DynamicLoadObject(AnimPath, class'CameraAnim'));
	if(Anim == none)
	{
		`Redscreen("Camera anim " $ AnimPath $ " could not be loaded. Please talk to the camera artist about this.");
		return;
	}

	// make sure the anim will end
	if(Loop && GlobalAnim)
	{
		`Redscreen("Global camera anims cannot loop, or they will never finish! Disabling loop...");
		Loop = false;
	}

	// don't double up on the same anim
	for(Index = 0; Index < CameraAnims.Length; Index++)
	{
		if(PathName(CameraAnims[Index].AnimInstance.CamAnim) == AnimPath)
		{
			// this anim already exists. If it was marked as pending for cleanup, clear the flag, since
			// the new camera also wants to use this anim
			CameraAnims[Index].PendingCleanup = false;
			CameraAnims[Index].GlobalAnim = CameraAnims[Index].GlobalAnim || GlobalAnim;
			return;
		}
	}

	// no anim of this kind was playing, so start up a new one
	AnimInstance.AnimInstance = Cam.PlayCameraAnim(Anim, Rate, Intensity,,, Loop);
	AnimInstance.GlobalAnim = GlobalAnim;
	if(AnimInstance.AnimInstance != none)
	{
		CameraAnims.AddItem(AnimInstance);
	}
}

/// <summary>
/// Helper to mark all camera anims needing cleanup pending the active camera changing
/// </summary>
private function MarkAllCameraAnimsAsPendingCleanup()
{
	local int Index;

	for(Index = 0; Index < CameraAnims.Length; ++Index)
	{
		if(!CameraAnims[Index].GlobalAnim)
		{
			CameraAnims[Index].PendingCleanup = true;
		}
	}
}

/// <summary>
/// Helper to cleanup unneeded cameras after the active camera changes
/// </summary>
private function CleanupCameraAnims()
{
	local XGBattle Battle;
	local XComCamera Cam;
	local int Index;

	Battle = `BATTLE;
	if(Battle == none) return;
	
	Cam = XComCamera(Battle.GetALocalPlayerController().PlayerCamera);
	if(Cam == none) return;

	for(Index = CameraAnims.Length - 1; Index >= 0; Index--)
	{
		if(CameraAnims[Index].PendingCleanup)
		{
			Cam.StopCameraAnim(CameraAnims[Index].AnimInstance, true);
			CameraAnims.Remove(Index, 1);
		}
	}
}

/// <summary>
/// Notifies the cameras that the user wants to yaw them
/// </summary>
function YawCameras(float Degrees)
{
	if(ActiveCamera != none)
	{
		ActiveCamera.YawCamera(Degrees);
	}
}

/// <summary>
/// Notifies the cameras that the user wants to pitch them
/// </summary>
function PitchCameras(float Degrees)
{
	if (ActiveCamera != None)
	{
		ActiveCamera.PitchCamera(Degrees);
	}
}

/// <summary>
/// Notifies the cameras that the user wants to zoom them.
/// </summary>
function ZoomCameras(float Amount)
{
	if (ActiveCamera != None)
	{
		ActiveCamera.ZoomCamera(Amount);
	}
}

/// <summary>
/// Notifies the cameras that the user wants to scroll them with key input
/// </summary>
function ScrollCameras(Vector2D Offset)
{
	if (ActiveCamera != None)
	{
		ActiveCamera.ScrollCamera(Offset);
	}
}

/// <summary>
/// Notifies the cameras that the user wants to scroll them with mouse/window edge input
/// </summary>
function EdgeScrollCameras(Vector2D Offset)
{
	if (ActiveCamera != None)
	{
		ActiveCamera.EdgeScrollCamera(Offset);
	}
}

/// <summary>
/// Notifies the cameras that the user wants to scroll them without smoothing
/// </summary>
function RawScrollCameras(Vector2D Offset)
{
	if (ActiveCamera != None)
	{
		ActiveCamera.RawScrollCamera(Offset);
	}
}

/// <summary>
/// Finds and notifies any cinescript cameras that an anim notify was hit
/// </summary>
function OnCinescriptAnimNotify(string EventLabel)
{
	local X2Camera CameraIterator;
	local X2Camera_Cinescript CinescriptCamera;
	local int Index;

	for(Index = 0; Index < Cameras.Length; Index++)
	{
		CameraIterator = Cameras[Index];

		while(CameraIterator != none)
		{
			CinescriptCamera = X2Camera_Cinescript(CameraIterator);
			if(CinescriptCamera != none)
			{
				CinescriptCamera.OnAnimNotify(EventLabel);
			}
			CameraIterator = CameraIterator.ChildCamera;
		}
	}
}

/// <summary>
/// Returns true if buildings should cut down
/// </summary>
function bool AllowBuildingCutdown()
{
	return ActiveCamera != none ? ActiveCamera.AllowBuildingCutdown() : true;
}

/// <summary>
/// Returns true if focus points from previous frames should not expire
/// </summary>
function bool DisableFocusPointExpiration()
{
	return ActiveCamera != none ? ActiveCamera.DisableFocusPointExpiration() : false;
}

/// <summary>
/// Override to notify rendering that this camera should use the 3rd person outline rendering
/// </summary>
function bool ShowTargetingOutlines()
{
	return ActiveCamera != none ? ActiveCamera.ShowTargetingOutlines() : false;
}

/// <summary>
/// Returns true if the current camera state would like the specified unit to draw with
/// 3rd person style outlines
/// </summary>
function bool ShouldUnitUse3rdPersonStyleOutline(XGUnitNativeBase Unit)
{
	return ActiveCamera != none ? ActiveCamera.ShouldUnitUse3rdPersonStyleOutline(Unit) : false;
}

/// <summary>
/// Returns true if the current camera state would like the specified unit to draw with scanlines
/// </summary>
function bool ShouldUnitUseScanline(XGUnitNativeBase Unit)
{
	return ActiveCamera != none ? ActiveCamera.ShouldUnitUseScanline(Unit) : false;
}

/// <summary>
/// Gets the focal point of the current camera
/// </summary>
function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local TFocusPoints FocusPoint;

	if( ActiveCamera != none )
		ActiveCamera.GetCameraFocusPoints(OutFocusPoints);
	else
	{
		FocusPoint.vFocusPoint = vect(0, 0, 9999);
		FocusPoint.vCameraLocation = vect(0, 0, 9999);
		OutFocusPoints.AddItem(FocusPoint);
	}
}

/// <summary>
/// Gets the focal point of the current camera, for DOF. Doesn't have to be the same
/// as the normal focus point
/// </summary>
function bool GetCameraDOFFocusPoint(out Vector FocalPoint)
{
	return ActiveCamera != none ? ActiveCamera.GetCameraDOFFocusPoint(FocalPoint) : false;
}

function bool GetCameraIsPrimaryFocusOn()
{
	if( ActiveCamera != none )
		return ActiveCamera.GetCameraIsPrimaryFocusOn();
	else
		return false;
}

function bool GetCameraPostProcessOverrides(out PostProcessSettings PostProcessOverrides)
{
	return ActiveCamera != none ? ActiveCamera.GetCameraPostProcessOverrides(PostProcessOverrides) : false;
}

// don't depend on this, it will die in release
function DEBUGResetCameraStack()
{
	// clear everything except the default camera
	while(Cameras.Length > 1)
	{
		RemoveCamera(Cameras[1]);
	}
}

function DEBUGPrintCameraStack()
{	
	local int Index;

	`log("=================Camera Stack==================");
	for(Index = 0; Index < Cameras.Length; Index++)
	{
		`log(Index@":"@Cameras[Index]);
	}
	`log("===============================================");
}

defaultproperties
{
	BlendDuration=2.0 //Overridden in ActivateNewActiveCamera, but this value will be used until a camera is pushed onto the stack
}