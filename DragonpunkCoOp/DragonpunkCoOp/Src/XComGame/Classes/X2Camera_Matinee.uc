//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_Matinee.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Camera that plays the matinee cams in tactical.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_Matinee extends X2Camera
	dependson(X2MatineeInfo)
	native;

/// <summary>
/// If true, the camera will do extra processing to dynamically detect and avoid blocking situations after selection.
/// This is const global, and exists only too allow easily disabling the detection from an ini switch
/// </summary>
var private const config bool AllowDynamicBlockDetection;

/// <summary>
/// If TRUE, this matinee camera will allow camera sequences that cross cut from the game camera
/// </summary>
var privatewrite config bool AllowCrossCuts;

/// <summary>
/// Contains information about the matinee we will be sampling
/// </summary>
var privatewrite X2MatineeInfo MatineeInfo;

/// <summary>
/// The current time in the matinee playback.
/// </summary>
var private float MatineeTime;

/// <summary>
/// Cached here so that we only need to call SampleDirectorTrack once per frame.
/// </summary>
var private PostProcessSettings CachedPostProcessParameters;

/// <summary>
/// A prefix used for specifying the available matinee pool
/// </summary>
var private string MatineeCommentPrefix;

/// <summary>
/// The Actor this matinee will be centered on.
/// </summary>
var private Actor MatineeFocusActor;

/// <summary>
/// The location this matinee will be centered on. Only used if UseExplicitSamplingOrigin is true.
/// </summary>
var private Vector MatineeSamplingOrigin;

/// <summary>
/// The facing of this matinee. Only used if UseExplicitSamplingOrigin is true.
/// </summary>
var private Rotator MatineeSamplingFacing;

/// <summary>
/// If true, the matinee will be placed at MatineeSamplingOrigin with MatineeSamplingFacing, instead of deriving it's location from 
/// </summary>
var private bool UseExplicitSamplingOrigin;

/// <summary>
/// These actors will not affect camera blocking determinations
/// </summary>
var array<Actor> ActorsToIgnoreForBlockingDetermination;

/// <summary>
/// If set to true, this camera will blend from the previous camera when it is activated
/// </summary>
var bool ShouldBlend;
var bool ShouldShowCursor;

/// <summary>
/// If set to true, this camera will hide the UI while it runs
/// </summary>
var bool ShouldHideUI;

/// <summary>
/// If true the matinee camera will not care about blocking volumes or crosscutting and play the matinee regardless.
/// </summary>
var bool ShouldAlwaysShow;

/// <summary>
/// If true, this matinee camera will automatically pop itself when the end of the matinee is reached
/// </summary>
var bool PopWhenFinished;

// If true, will update the event track on this matinee
var bool UpdateEventTrack;

// If the matinee should become blocked at any point, these structure will contain the adjusted camera location.
// we interpolate to the adjusted location to prevent jumps, so we need to store both the target and the actual
// locations
var private bool CameraIsBlockingAdjusted;
var private TPOV BlockingAdjustedCameraLocation;
var private TPOV CachedCameraLocation;

/// <summary>
/// returns true if the given matinee will cause a "cross-cut" from the old camera location.
/// A cross cut happens when the previous camera was looking at the focus actor's left side,
/// but the new camera would be looking at his right. Or vice versa.
/// </summary>
protected native function bool WillMatineeCrossCut(const out Rotator OldCameraOrientation) const;

/// <summary>
/// Scores the given matinee for visibility. Higher scores indicate more blocking geometry.
/// </summary>
private function native bool IsMatineeBlocked(SeqAct_Interp Matinee, Actor FocusActor);

/// <summary>
/// Ensures that base actors are added to the ActorsToIgnoreForBlockingDetermination array. Should be called before
/// doing blocking determinations
/// </summary>
private function native AddFocusUnitToIgnoreActors();

function bool ShouldBlendFromCamera(X2Camera PreviousActiveCamera)
{
	return ShouldBlend;
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	local XComTacticalController LocalController;
	local XComPresentationLayer Pres;

	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	CenterMatinee();

	// choose the correct matinee to play. The user can either select a matinee explicitly, or else
	// provide a matinee comment prefix from which we will select the most appropriate candidate
	// based on obstruction
	if(MatineeCommentPrefix == "")
	{
		if(MatineeInfo == None || MatineeInfo.Matinee == none)
		{
			`RedScreen("Matinee Camera was activated before specifying a comment prefix or matinee!");
			RemoveSelfFromCameraStack();
			return;
		}

		// no extra setup needed here because SetMatinee() will have already initialized the MatineeInfo
	}
	else
	{
		if(!SelectMatineeFromComment(CurrentPOV.Rotation))
		{
			// nothing unblocked was found, so just bail rather than show a bad matinee
			RemoveSelfFromCameraStack();
			return;
		}
	}

	Pres = `PRES;
	Pres.GetActionIconMgr().ShowIcons(false);

	//World messages are special and are treated separately from the rest of the UI
	if(ShouldHideUI)
	{
		Pres.GetWorldMessenger().SetShowDuringCinematic(false);
	}

	// we'll use the full setcinematicmode function to revert this, but to set it well use only
	// part of the functionality. We don't want to override the camera.
	LocalController = XComTacticalController(`BATTLE.GetALocalPlayerController());
	LocalController.CinematicModeToggled(true, true, true, ShouldHideUI, false, ShouldShowCursor);

	`BATTLE.SetFOW(false);
}

function Deactivated()
{
	local XComPresentationLayer Pres;

	super.Deactivated();

	if(MatineeInfo != none && UpdateEventTrack)
	{
		MatineeInfo.TriggerCompletionEvents();
	}

	Pres = `PRES;
	Pres.GetActionIconMgr().ShowIcons(true);

	//World messages are special and are treated separately from the rest of the UI
	if(ShouldHideUI)
	{
		Pres.GetWorldMessenger().SetShowDuringCinematic(true);
	}

	`BATTLE.SetFOW(true);
}

/// <summary>
/// Centers the matinee on the given actor
/// </summary>
private function CenterMatinee()
{
	local XGUnit Unit;
	local XComUnitPawn UnitPawn;

	if(MatineeInfo != none)
	{
		if(UseExplicitSamplingOrigin)
		{
			MatineeInfo.SetSamplingOrigin(MatineeSamplingOrigin, MatineeSamplingFacing);
		}
		else if(MatineeFocusActor != none)
		{
			UnitPawn = XComUnitPawn(MatineeFocusActor);

			if(UnitPawn == none)
			{
				Unit = XGUnit(MatineeFocusActor);
				if(Unit != none)
				{
					UnitPawn = Unit.GetPawn();
				}
			}

			if(UnitPawn != none)
			{
				MatineeInfo.SetSamplingOrigin(UnitPawn.GetFeetLocation(), UnitPawn.Rotation);
			}
			else
			{
				MatineeInfo.SetSamplingOrigin(MatineeFocusActor.Location, MatineeFocusActor.Rotation);
			}
		}
	}
}

function SetExplicitMatineeLocation(Vector MatineeLocation, Rotator MatineeFacing)
{
	UseExplicitSamplingOrigin = true;
	MatineeSamplingOrigin = MatineeLocation;
	MatineeSamplingFacing = MatineeFacing;

	if(MatineeInfo != none)
	{
		MatineeInfo.SetSamplingOrigin(MatineeLocation, MatineeFacing);
	}
}

/// <summary>
/// Initializes this camera with the desired matinee. If Origin and Rotation are specified, the
/// camera will be adjusted so that the matinee's world origin is centered and oriented at that
/// location in the world.
/// </summary>
event SetMatinee(SeqAct_Interp Matinee, Actor FocusActor)
{
	if(MatineeInfo == none)
	{
		MatineeInfo = new class'X2MatineeInfo';
	}

	MatineeTime = 0;
	MatineeInfo.InitFromMatinee(Matinee);
	MatineeFocusActor = FocusActor;

	CenterMatinee();
}

protected function bool FocusActorWillCollide()
{
	if(MatineeFocusActor == none)
	{
		return false;
	}
}

/// <summary>
/// Finds any matinee that starts with the specified comment, and then initializes this camera with one of them. 
/// If Immediate is true, a camera matinee will be chosen immediately. Otherwise, the matinee will be chosen when this
/// camera is made active.
/// </summary>
function bool SetMatineeByComment(string MatineeComment, Actor FocusActor, optional bool Immediate = false)
{
	local TPOV CameraLocation;

	MatineeCommentPrefix = MatineeComment;
	MatineeFocusActor = FocusActor;

	if(Immediate)
	{
		CameraLocation = `CAMERASTACK.GetCameraLocationAndOrientation();
		if(!SelectMatineeFromComment(CameraLocation.Rotation))
		{
			return false;
		}
	}

	return true;
}

protected function bool IsMatineeValid(SeqAct_Interp Matinee, Actor FocusActor, Rotator OldCameraOrientation)
{
	local XComTacticalCheatManager CheatManager;

	CheatManager = `CHEATMGR;

	if (!ShouldAlwaysShow)
	{
		if (IsMatineeBlocked(Matinee, FocusActor))
		{
			CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@"Camera view blocked, CANCELLED";
			return false;
		}

		// ignore matinees that will cross cut if desired
		if(!CheatManager.DisableCrosscutFail && !AllowCrossCuts && WillMatineeCrossCut(OldCameraOrientation))
		{
			CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@"Camera will cross cut, CANCELLED";
			return false;
		}
	}

	return true;
}

/// <summary>
/// Sorts matinees by priority flag
/// </summary>
private function int MatineePrioritySort(SeqAct_Interp Matinee1, SeqAct_Interp Matinee2)
{
	// prioritize just continuing the matinee we are already playing (by putting it first in the list)
	if(MatineeInfo != none)
	{
		if(Matinee1 == MatineeInfo.Matinee)
		{
			return 1;
		}
		else if(Matinee2 == MatineeInfo.Matinee)
		{
			return -1;
		}
	}

	return Matinee1.SelectionPriority > Matinee2.SelectionPriority ? -1 : 1;
}

/// <summary>
/// Finds any matinee that starts with the specified comment, and then initializes this camera with one of them. 
/// </summary>
private function bool SelectMatineeFromComment(Rotator OldCameraOrientation)
{
	local array<SequenceObject> FoundMatinees;
	local array<SeqAct_Interp> MatchingMatinees;
	local SequenceObject MatineeObject;
	local SeqAct_Interp Matinee;
	local Sequence GameSeq;
	local XComTacticalCheatManager CheatManager;

	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	GameSeq.FindSeqObjectsByClass(class'SeqAct_Interp', true, FoundMatinees);

	CheatManager = `CHEATMGR;
	CheatManager.PodRevealDecisionRecord = "Selecting matinee for prefix:"@MatineeCommentPrefix@"\n";

	foreach FoundMatinees(MatineeObject)
	{	
		if(InStr(MatineeObject.ObjComment, MatineeCommentPrefix) == 0) // if the comment starts with this string
		{
			MatchingMatinees.AddItem(SeqAct_Interp(MatineeObject));

			CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@" Found:"@MatineeObject.ObjComment@"\n";
		}
	}

	CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@"\n\n";
	CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@"Testing Candidate Matinees:\n";

	if(MatchingMatinees.Length > 0)
	{
		// randomize the pool and coarsely sort by priority
		MatchingMatinees.RandomizeOrder();
		MatchingMatinees.Sort(MatineePrioritySort);

		// pick the first one that is completely unblocked
		foreach MatchingMatinees(Matinee)
		{
			CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@Matinee.ObjComment@":";
			if(IsMatineeValid(Matinee, MatineeFocusActor, OldCameraOrientation))
			{
				CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@"CAMERA SELECTED!";
				SetMatinee(Matinee, MatineeFocusActor);	
				return true;
			}
			CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@"\n";
		}
	}
	else
	{
		`Redscreen("X2Camera_Matinee: No matinees found for prefix " $ MatineeCommentPrefix); 
	}

	return false;
}

function UpdateCamera(float DeltaTime)
{
	local float MatineeDuration;
	local float SlomoRate;
	local TPOV CameraLocation;
	local vector TargetLocation;
	local float LerpAlpha;

	super.UpdateCamera(DeltaTime);

	if(MatineeInfo == none)
	{
		// we still haven't been activated the first time
		return;
	}

	if(UpdateEventTrack)
	{
		MatineeInfo.TriggerEvents(MatineeTime, DeltaTime);
	}

	if(MatineeInfo.SampleSlomoTrack(MatineeTime, SlomoRate))
	{
		class'WorldInfo'.static.GetWorldInfo().Game.SetGameSpeed(SlomoRate);
	}

	MatineeTime = MatineeTime + DeltaTime;
	
	// update the matinee time
	MatineeDuration = MatineeInfo.GetMatineeDuration();
	if(MatineeTime >= MatineeDuration)
	{
		if(MatineeInfo.Matinee.bLooping)
		{
			// looping matinee, so go back to the beginning
			MatineeTime = MatineeTime % MatineeDuration;
		}
		else
		{
			// not looping clamp to the end
			MatineeTime = MatineeDuration;

			if(PopWhenFinished)
			{
				RemoveSelfFromCameraStack();
				return;
			}
		}
	}

	// and then compute and cache the camera location
	// if the camera was ever blocked, stay there unless it get blocked again and needs further adjustment.
	// this prevents the camera from bouncing around a lot as it becomes blocked and then unblocked
	if(!CameraIsBlockingAdjusted)
	{
		// the camera is still clear, so continue sampling from the matinee
		MatineeInfo.SampleDirectorTrack(MatineeTime, CameraLocation, CachedPostProcessParameters);
	}
	else
	{
		CameraLocation = BlockingAdjustedCameraLocation;
	}

	// Don't want to do this for ShouldAlwaysShow cameras either, as they implicitly do not
	// care about blocking
	if(AllowDynamicBlockDetection && MatineeFocusActor != none && !ShouldAlwaysShow)
	{
		// ignore the matinee target and any additional ignore actors
		if(XGUnit(MatineeFocusActor) != none)
		{
			TargetLocation = XGUnit(MatineeFocusActor).GetPawn().GetHeadLocation();
		}
		else
		{
			TargetLocation = MatineeFocusActor.Location;
		}

		// check to see if our desired camera location is blocked and needs to be adjusted
		AddFocusUnitToIgnoreActors();
		if(AdjustCameraForBlockage(CameraLocation.Location, CameraLocation.Rotation, TargetLocation, ActorsToIgnoreForBlockingDetermination))
		{
			// blocked!
			BlockingAdjustedCameraLocation = CameraLocation;
			CameraIsBlockingAdjusted = true;

			if(CameraLocation.Location == vect(0,0,0))
			{
				// if this is the first frame the camera is active, then there is no cached location to interpolate from.
				CachedCameraLocation = CameraLocation;
			}
		}
	}
	else
	{
		CachedCameraLocation = CameraLocation;
	}

	if(CameraIsBlockingAdjusted)
	{
		// smoothly interpolate to the unblocked location
		LerpAlpha = fMin(DeltaTime * 2, 1.0f);
		CachedCameraLocation.Location = VLerp(CachedCameraLocation.Location, BlockingAdjustedCameraLocation.Location, LerpAlpha);
		CachedCameraLocation.Rotation = RLerp(CachedCameraLocation.Rotation, BlockingAdjustedCameraLocation.Rotation, LerpAlpha, true);
	}
	else
	{
		CachedCameraLocation = CameraLocation;
	}
}

function TPOV GetCameraLocationAndOrientation()
{
	return CachedCameraLocation;
}

function bool GetCameraPostProcessOverrides(out PostProcessSettings PostProcessOverrides)
{
	OverridePPSettings(PostProcessOverrides, CachedPostProcessParameters);
	return true;
}

function string GetDebugDescription()
{
	if(MatineeInfo != None && MatineeInfo.Matinee != none)
	{
		return super.GetDebugDescription() $ " - " $ MatineeInfo.Matinee.ObjComment;
	}
	else
	{
		return super.GetDebugDescription() $ " - No matinee selected";
	}
}

defaultproperties
{
	Priority=eCameraPriority_Cinematic
	PopWhenFinished=true
	ShouldHideUI=true
	ShouldAlwaysShow=false
	UpdateEventTrack=true	
}