//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_OverTheShoulder.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Matinee driven camera for over the should camera shots
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_OverTheShoulder extends X2Camera
	config(Camera)
	native;

// Associates a target with a matinee camera, so that when tabbing between targets we can
// guarantee that every target always goes back to the same camera
struct native X2Camera_OverTheShoulder_TargetCam
{
	var Actor Target;
	var SeqAct_Interp Matinee;
};

// helper struct for sorting candidate matinees
struct native X2Camera_OverTheShoulder_SortHelper
{
	var SeqAct_Interp Matinee;
	var float Weight;
};

// helper struct that keeps scoring info for the last camera to pass through DebugForceCameraSelection
struct native X2Camera_OverTheShoulder_ScoreDebugHelper
{
	var float TransparencyPenaltyPercentage; // Percentage of a full block penalty that transparent objects should incur when doing traces
	var float FiringUnitHeadBlockedScorePenalty;
	var float FiringUnitWaistBlockedScorePenalty;
	var float CantSeeFiringUnitAtAllPenalty;		// Both Head and Waist are blocked, this tends to indicate the Firing unit is behind a wall, which is bad
	var float TargetedLocationBlockedScorePenalty;
	var float BlockedStartLocationPenalty;	// The camera is colliding with something in a small area where the camera is being positioned
	var float CrosscutScorePenalty;    // Penalty incurred when the camera will break screen-direction rules
	var float LookAtBackPenalty;   // Penalty incurred when the camera is looking at a unit's back
	var float PriorityPenalty;
	var float TotalScore;
	var float SampleCount;
};

// Configuration of various parameters
var private const config CameraAnimIniEntry CameraShake;
var private const config float TransparencyPenaltyPercentage; // Percentage of a full block penalty that transparent objects should incur when doing traces
var private const config float FiringUnitHeadBlockedScorePenalty;
var private const config float FiringUnitWaistBlockedScorePenalty;
var private const config float CantSeeFiringUnitAtAllPenalty;		// Both Head and Waist are blocked, this tends to indicate the Firing unit is behind a wall, which is bad
var private const config float TargetedLocationBlockedScorePenalty;
var private const config float BlockedStartLocationPenalty;	// The camera is colliding with something in a small area where the camera is being positioned, likely the camera is INSIDE of something.
var private const config float CrosscutScorePenalty;    // Penalty incurred when the camera will break screen-direction rules
var private const config float LookAtBackPenalty;   // Penalty incurred when the camera is looking at a unit's back
var private const config InterpCurveFloat RetargetLocationCurve;
var private const config InterpCurveFloat RetargetRotationCurve;
var private const config float RetargetDurationMin;
var private const config float RetargetDurationMax;
var private const config float RetargetDurationMaxTiles;
var private const config float TetherDuration;
var private const config float TraceWidth; // in unreal units, extent radius of the trace for geometry blocking the camera view
var private const config float BlockedStartLocationWidth; // in unreal units, extent radius of the point checked for the camera start location, keep this fairly small, mainly look for the camera being inside something
var private const config float MinTilesBetweenTraceSamples;
var private const config float BlockedByPawnsExtentPenalty;
var private const config float BlockedByPawnsZeroExtentPenalty;
var private const config float MinZeroExtentPenaltyScalar;

var private const config float PriorityPenalty[MatineeSelectionPriority.EnumCount];

// The unit doing the action this camera is looking at. To be filled out by the camera creator
var XGUnitNativeBase FiringUnit;

// The prefix that indicates which matinees this camera should consider for use. Any Matinee that starts with
// this prefix will be added to the list.
var string CandidateMatineeCommentPrefix;

// The Matinee we are currently using 
var protected X2MatineeInfo MatineeInfo;

// The current time we are sampling the Matinee, in Matinee space.
var protected float MatineeTime;

// The actor the firing unit is targeting
var protected Actor TargetActor;

// 0.0-1.0 fade from previous targeted matinee to new targeted matinee 
var private float RetargetTransitionAlpha;

// The camera's values when we decided to retarget
var private TPOV RetargetTPOV;

// The length of this transition
var private float RetargetDuration;

var private array<X2Camera_OverTheShoulder_TargetCam> SavedTargetCams;

// By default, this camera will center the DOF radius on the target. If this is set to true, will focus the shooter instead
var bool DOFFocusShooter;

// True if this ots cam should blend
var bool ShouldBlend;

// True if we should hide the UI while this camera is active. Should probably be true for all but the targeting cams.
var bool ShouldHideUI;

// The camera will "tether" to the current target. As the target or shooter move, we will
// keep a weighted average of the previous camera target locations. This gives the impression that
// the camera is on a tether, lazily tracking the motion of the shooter and target, as opposed to
// either remaining static or else being rigidly attached.
var private TPOV TetherTPOV;

// keep track of whether we are "dirty" and need to reset the target
var private bool TargetDirty;

// debug focused array to store and show the scores for the various candidate cameras
var private array<X2Camera_OverTheShoulder_SortHelper> CandidateCameraScores;

// stores data from the last run of DebugForceCameraSelection
var private X2Camera_OverTheShoulder_ScoreDebugHelper DebugScoreData;

// true while the current targeting camera was forced
var private bool bCurrentCameraForced;

// helper array for computing LOS blocking scores. All actors in this array don't count as blocking if encountered
var private array<Actor> ActorsToIgnoreForLineOfSightChecks;

var bool bDrawDebugInfo;

// if true, this camera will always play the best matinee that can be found. Otherwise, it will only play
// if it can find a matinee that is not blocked, or it's following another OTS camera as a blend.
var bool ShouldAlwaysShow;

/// <summary>
/// Returns a value from 0 to 1 based on how "clear" the visibility is from location1 to location2
/// BlockedDistanceScalar will be filled with a value from 0 to 1 indicating how far from start to end the collision happened.
/// </summary>
private native function FLOAT IsLineOfSightBlockedBetweenLocations(Vector Location1, Vector Location2, float Extent, int AdditionalTraceFlags, optional float ModifierIfOnlyBlockedByPawns = 1.0f, optional out float BlockedDistanceScalar);

/// <summary>
/// Scores the given matinee for visual obstructions. Lower scores are better matches, a score of 0 is fully unblocked
/// </summary>
private native function float GetMatineeObstructionScore(X2MatineeInfo InMatineeInfo);

/// <summary>
/// Gets the location of the thing we are shooting at. Will be a head for units, location for other things.
/// </summary>
native function Vector GetTargetLocation(optional bool bUsePredictedTargetHeadLocation = true);

/// <summary>
/// Computes the TPOV that should be used in game for the given parameters
/// </summary>
protected native function TPOV ComputeCameraLocationAndOrientationAtTime(X2MatineeInfo Matinee, XComUnitPawnNativeBase ShooterPawn, bool bUsePredictedHeadPos, Vector TargetLocation, float Time);

/// <summary>
/// Returns the head location as close as we can easily predicted for the shooter when targeting the target location.
/// </summary>
static native function Vector GetPredictedHeadLocation(XComUnitPawnNativeBase ShooterPawn, Actor TargetOfShooter);

/// <summary>
/// Grabs all of the matinees that are available for this OTS cam, based on the 
/// </summary>
protected function bool GetCandidateMatinees(out array<SeqAct_Interp> CandidateMatinees)
{
	local array<SequenceObject> FoundMatinees;
	local SeqAct_Interp Matinee;
	local Sequence GameSeq;
	local int Index;

	if(CandidateMatineeCommentPrefix == "")
	{
		return false;
	}

	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	GameSeq.FindSeqObjectsByClass(class'SeqAct_Interp', true, FoundMatinees);
	for (Index = 0; Index < FoundMatinees.length; Index++)
	{
		Matinee = SeqAct_Interp(FoundMatinees[Index]);
		if(Instr(Matinee.ObjComment, CandidateMatineeCommentPrefix,, true) == 0)
		{
			CandidateMatinees.AddItem(Matinee);
		}
	}

	return CandidateMatinees.Length > 0;
}

function bool ShouldBlendFromCamera(X2Camera PreviousActiveCamera)
{
	return ShouldBlend || (X2Camera_OTSTargeting(PreviousActiveCamera) != none);
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	local XComTacticalController LocalController;
	local X2Camera_OTSTargeting PreviousOTSTargetingCam;
	local bool FoundMatinee;

	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	if(PreviousActiveCamera == self)
	{
		// no need to reinit if we are becoming active again
		return;
	}

	// we're going to force a matinee update, so clear the target dirty flag
	TargetDirty = false;

	PreviousOTSTargetingCam = X2Camera_OTSTargeting(PreviousActiveCamera);

	if (PreviousOTSTargetingCam != none && ShouldBlendFromCamera(PreviousOTSTargetingCam))
	{
		// if the previous active camera was also an OTS targeting cam, just pick the closest camera from the new set to the end of the last one.
		// this makes the blends look super nice
		FoundMatinee = SelectClosestMatinee(PreviousOTSTargetingCam);
	}
	else if(TargetActor != none)
	{
		// select a new matinee based on the location of the previous active camera
		FoundMatinee = SelectMatinee(CurrentPOV.Rotation);
	}

	if(!FoundMatinee)
	{
		if(ShouldAlwaysShow)
		{
			// data error! We couldn't find the requested matinee or otherwise are unable to play one
			`Redscreen("Could not find any valid ots matinees for prefix " $ CandidateMatineeCommentPrefix $ ". This is probably a data bug, talk to a camera artist.");
		}
			
		RemoveSelfFromCameraStack();
		return;
	}

	`log("X2Camera_OverTheShoulderShot selected " $ MatineeInfo.Matinee.ObjComment $ " to target with.");

	// don't retarget, just instantly snap to the newly activated matinee
	RetargetTransitionAlpha = 1.0;

	PlayCameraAnim(CameraShake.AnimPath, CameraShake.Rate, CameraShake.Intensity, true);

	LocalController = XComTacticalController(`BATTLE.GetALocalPlayerController());

	if(ShouldHideUI)
	{
		if (`CHEATMGR != None && `CHEATMGR.bHideWorldMessagesInOTS)
		{
			`PRES.GetWorldMessenger().SetShowDuringCinematic(false);
		}
	}

	// hide the UI
	LocalController.CinematicModeToggled(true, true, true, ShouldHideUI, false, false);

	`BATTLE.SetFOW(false);
}

function Deactivated()
{
	super.Deactivated();

	if(MatineeInfo != none)
	{
		MatineeInfo.TriggerCompletionEvents();
	}

	if(ShouldHideUI)
	{
		if (`CHEATMGR != None && `CHEATMGR.bHideWorldMessagesInOTS)
		{
			`PRES.GetWorldMessenger().SetShowDuringCinematic(true);
		}
	}

	`BATTLE.SetFOW(true);
}

/// <summary>
/// Selects and caches the matinee that will begin closest to the given point, regardless
/// of obstruction or other considerations
/// </summary>
protected function bool SelectClosestMatinee(X2Camera_OverTheShoulder PreviousOTSCam)
{
	local array<SeqAct_Interp> CandidateMatinees;
	local SeqAct_Interp Matinee;
	local float MatineeDistance;
	local SeqAct_Interp ClosestMatinee;
	local float ClosestMatineeDistance;
	local TPOV CameraLocation;
	local TPOV OldCameraLocation;
	local int SuffixIndex;
	local string DesiredSuffix;
	local int DesiredSuffixLength;

	if(!GetCandidateMatinees(CandidateMatinees))
	{
		return false;
	}

	if(MatineeInfo == none)
	{
		MatineeInfo = new class'X2MatineeInfo';
	}

	// first try suffix matching. The artists like to explicitly pair matinees, and match them up by giving them the same
	// suffix in the form of a letter_number.
	SuffixIndex = Instr(PreviousOTSCam.MatineeInfo.Matinee.ObjComment, "_L_",, true);
	if(SuffixIndex == INDEX_NONE)
	{
		SuffixIndex = Instr(PreviousOTSCam.MatineeInfo.Matinee.ObjComment, "_R_",, true);
	}

	if(SuffixIndex != INDEX_NONE)
	{
		DesiredSuffix = Mid(PreviousOTSCam.MatineeInfo.Matinee.ObjComment, SuffixIndex);
		DesiredSuffixLength = Len(DesiredSuffix);
		foreach CandidateMatinees(Matinee)
		{
			if(Right(Matinee.ObjComment, DesiredSuffixLength) == DesiredSuffix)
			{
				ClosestMatinee = Matinee;
				break;
			}
		}
	}

	// if suffix matching didn't find a matinee, go with the closest one
	if(ClosestMatinee == none)
	{
		OldCameraLocation = ComputeCameraLocationAndOrientationAtTime(PreviousOTSCam.MatineeInfo, FiringUnit.GetPawn(), false, GetTargetLocation(), PreviousOTSCam.MatineeInfo.GetMatineeDuration());

		foreach CandidateMatinees(Matinee)
		{
			MatineeInfo.InitFromMatinee(Matinee);
			CameraLocation = ComputeCameraLocationAndOrientationAtTime(MatineeInfo, FiringUnit.GetPawn(), true, GetTargetLocation(), 0.0);
			MatineeDistance = VSize(CameraLocation.Location - OldCameraLocation.Location);
		
			if(ClosestMatinee == none || MatineeDistance < ClosestMatineeDistance)
			{
				ClosestMatinee = Matinee;
				ClosestMatineeDistance = MatineeDistance;
			}
		}
	}

	if(ClosestMatinee != none)
	{
		MatineeInfo.InitFromMatinee(ClosestMatinee);
		ResetTether();
		return true;
	}
	else
	{
		return false;
	}
}

/// <summary>
/// Sorts matinees by priority flag
/// </summary>
private function int MatineePrioritySort(SeqAct_Interp Matinee1, SeqAct_Interp Matinee2)
{
	return Matinee1.SelectionPriority > Matinee2.SelectionPriority ? -1 : 1;
}

/// <summary>
/// Selects and caches an appropriate matinee for the given units.
/// </summary>
protected function bool SelectMatinee(Rotator OldCameraOrientation)
{
	local array<SeqAct_Interp> CandidateMatinees;
	local SeqAct_Interp CandidateMatinee;
	local int SavedCamIndex;
	local Vector UnitFacing;
	local float Score;
	local SeqAct_Interp BestMatinee;
	local int BestScore;
	local X2Camera_OverTheShoulder_SortHelper ScoreItem;
	local XComTacticalCheatManager CheatManager;

	if(MatineeInfo == none)
	{
		MatineeInfo = new class'X2MatineeInfo';
	}

	CheatManager = `CHEATMGR;

	// check if we have already selected a matinee for the current target
	SavedCamIndex = SavedTargetCams.Find('Target', TargetActor);
	if(SavedCamIndex != INDEX_NONE)
	{
		MatineeInfo.InitFromMatinee(SavedTargetCams[SavedCamIndex].Matinee);
		ResetTether();
		return true;
	}

	// before doing any scoring, make sure this is up to date
	UpdateActorsToIgnoreForLineOfSightChecksArray();

	// check if the previous matinee is okay (unblocked)
	if(GetMatineeObstructionScore(MatineeInfo) == 0)
	{
		BestMatinee = MatineeInfo.Matinee;
	}

	// if the previous one wasn't unblocked, try to find a better one
	if(BestMatinee == none)
	{
		CandidateCameraScores.Length = 0;
		if(!GetCandidateMatinees(CandidateMatinees))
		{
			// mayday! No matinees are available to play
			return false;
		}

		UnitFacing = GetUnitFacing();

		// roughly sort the matinees by priority so that we favor matinees that are considered "better"
		CandidateMatinees.RandomizeOrder();
		CandidateMatinees.Sort(MatineePrioritySort);

		// scan through all matinees until we find one that doesn't have blocked LOS to the shooter or target
		// note that if all of them are blocked, MatineeInfo will still be inited with the last one we tried
		// when we drop out of the loop, so we'll end up using that one as a failsafe
		BestScore = 1000; // make this large, since smaller numbers are better
		foreach CandidateMatinees(CandidateMatinee)
		{
			MatineeInfo.InitFromMatinee(CandidateMatinee);

			Score = GetMatineeObstructionScore(MatineeInfo);

			if(!ShouldAlwaysShow && Score != 0)
			{
				// this matinee is blocked and we don't want to show blocked matinees, so skip it
				continue;
			}

			if(CrosscutScorePenalty != 0 && !CheatManager.DisableCrosscutFail && WillMatineeCrossCut(MatineeInfo, OldCameraOrientation))
			{
				Score += CrosscutScorePenalty;
			}

			if(LookAtBackPenalty != 0 && !CheatManager.DisableLookAtBackFail && WillMatineeLookAtUnitsBack(MatineeInfo, UnitFacing) && (CheatManager == none || !CheatManager.bDisableLookAtBackPenalty))
			{
				Score += LookAtBackPenalty;
			}

			// add in any penalty from the priority
			Score += PriorityPenalty[MatineeInfo.Matinee.SelectionPriority];

			if(Score < BestScore)
			{
				BestScore = Score;
				BestMatinee = MatineeInfo.Matinee;
			}

`if(`notdefined(FINAL_RELEASE))
			ScoreItem.Weight = Score;
			ScoreItem.Matinee = CandidateMatinee;
			CandidateCameraScores.AddItem(ScoreItem);						

`else // Only perform this optimization if we are in final release scripts.
			if(BestScore == 0)
			{
				// a perfect score! No need to keep looking
				break;
			}
`endif
		}
	}

	// initalize the new matinee
	if(BestMatinee != none)
	{
		MatineeInfo.InitFromMatinee(BestMatinee);
		ResetTether();

		// save this to the target cam array so we keep using it for this target
		SavedTargetCams.Add(1);
		SavedTargetCams[SavedTargetCams.Length - 1].Target = TargetActor;
		SavedTargetCams[SavedTargetCams.Length - 1].Matinee = MatineeInfo.Matinee;
		return true;
	}
	else
	{
		return false;
	}
}

/// <summary>
/// returns true if the given matinee will cause a "cross-cut" from the old camera location.
/// A cross cut happens when the previous camera was looking at the shooters left side,
/// but the new camera would be looking at his right. Or vice versa.
/// </summary>
protected native function bool WillMatineeCrossCut(X2MatineeInfo Matinee, const out Rotator OldOrientation);

/// <summary>
/// returns true if the given matinee will cause a "cross-cut" from the old camera location.
/// A cross cut happens when the previous camera was looking at the shooters left side,
/// but the new camera would be looking at his right. Or vice versa.
/// </summary>
protected native function bool WillMatineeLookAtUnitsBack(X2MatineeInfo Matinee, const out Vector UnitFacing);

/// <summary>
/// Updates the ActorsToIgnoreForLineOfSightChecks array with the appropriate actors
/// </summary>
function UpdateActorsToIgnoreForLineOfSightChecksArray()
{
	local array<XComGameState_Unit> AttachedUnits;
	local XComGameState_Unit AttachedUnit;
	local XGUnit AttachedVisualizer;

	ActorsToIgnoreForLineOfSightChecks.Length = 0;

	ActorsToIgnoreForLineOfSightChecks.AddItem(FiringUnit);
	ActorsToIgnoreForLineOfSightChecks.AddItem(FiringUnit.GetPawn());
	ActorsToIgnoreForLineOfSightChecks.AddItem(TargetActor);

	FiringUnit.GetVisualizedGameState().GetAttachedUnits(AttachedUnits);
	foreach AttachedUnits(AttachedUnit)
	{
		AttachedVisualizer = XGUnit(AttachedUnit.GetVisualizer());
		if(AttachedUnit != none)
		{
			ActorsToIgnoreForLineOfSightChecks.AddItem(AttachedVisualizer);
			ActorsToIgnoreForLineOfSightChecks.AddItem(AttachedVisualizer.GetPawn());
		}
	}
}

/// <summary>
/// Determines the direction the firing units feet are facing. Note that we can't just check the pelvis bone
/// direction because they may not have turned to face the target yet, so do a bit of work
/// to determine where they *will* be facing when they finish moving. This also isn't strictly the facing,
/// but it's close. We just want to make sure the camera lies on the correct side of the unit->target line.
/// </summary>
protected function Vector GetUnitFacing()
{
	local Vector ShooterFeetLocation;
	local Vector TargetGroundLocation;
	local Vector FromShooterToTarget;
	local UnitPeekSide OutPeekSide;
	local int OutCoverIndex;
	local int OutCanSeeFromDefault;
	local int OutRequiresLean;
	local Vector Facing;

	TargetGroundLocation = GetTargetLocation();

	if (FiringUnit.GetDirectionInfoForPosition(TargetGroundLocation, OutCoverIndex, OutPeekSide, OutCanSeeFromDefault, OutRequiresLean))
	{
		// when the unit is in cover, we put the camera on the same side as the stepout they will use,
		// which should be the same direction as they are facing
		Facing = FiringUnit.GetExitCoverPosition(OutCoverIndex, OutPeekSide) - FiringUnit.GetLocation();
	}
	else
	{
		// otherwise, when not in cover, facing is always on the right side of the unit (no lefties)
		ShooterFeetLocation = FiringUnit.GetPawn().GetFeetLocation();
		FromShooterToTarget = TargetGroundLocation - ShooterFeetLocation;
		Facing = FromShooterToTarget cross vect(0, 0, -1); // get perpendicular vector along the vertical plane
	}

	Facing = Normal(Facing);

	// FiringUnit.DrawDebugSphere(FiringUnit.Location + Facing * 80, 20, 20, 255, 255, 255, true);
	// FiringUnit.DrawDebugLine(FiringUnit.Location, FiringUnit.Location + Facing * 80, 255, 255, 255, true);

	return Facing;
}

function UpdateCamera(float DeltaTime)
{
	local float SlomoRate;

	super.UpdateCamera(DeltaTime);

	CheckForTargetChange();

	MatineeInfo.TriggerEvents(MatineeTime, DeltaTime);

	if(MatineeInfo.SampleSlomoTrack(MatineeTime, SlomoRate))
	{
		class'WorldInfo'.static.GetWorldInfo().Game.SetGameSpeed(SlomoRate);
	}

	MatineeTime = fMin(MatineeTime + DeltaTime, MatineeInfo.GetMatineeDuration());
	RetargetTransitionAlpha = fMin(RetargetTransitionAlpha + DeltaTime / RetargetDuration, 1.0);

	UpdateTether(DeltaTime);
}

private function CheckForTargetChange()
{
	local bool ShouldRetarget;
	local TPOV NewTPOV;
	local float RotationRetargetAlpha;
	local float LocationRetargetAlpha;
	local float FinalRetargetAlpha;

	if(!TargetDirty)
	{
		return;
	}

	TargetDirty = false;

	// if we already have a matinee selected, attempt to to retarget from it
	ShouldRetarget = MatineeInfo != none;

	if(ShouldRetarget)
	{
		// backup the current TPOV so we can transition from it
		RetargetTPOV = GetCameraLocationAndOrientation();
		RetargetTransitionAlpha = 0.0;
	}

	// Update the selected matinee (in case the new target would be blocked using the current matinee)
	SelectMatinee(GetCameraLocationAndOrientation().Rotation);

	if(ShouldRetarget)
	{
		// now that we have decided on a new matinee, we can determine how long we want it to take
		// to transition to it

		// base duration, based on angular distance
		RotationRetargetAlpha = Vector(RetargetTPOV.Rotation) dot Vector(NewTPOV.Rotation); // -1.0, 1.0
		RotationRetargetAlpha = 1.0f - FClamp((RotationRetargetAlpha + 1.0f) / 2.0f, 0.0f, 1.0f); // 0.0, 1.0

		// now check if we need a longer duration because the camera location is going
		// to make a large location adjustment, but a small angular adjustment
		LocationRetargetAlpha = VSize(NewTPOV.Location - RetargetTPOV.Location) / (RetargetDurationMaxTiles * class'XComWorldData'.const.WORLD_StepSize);
		LocationRetargetAlpha = FClamp(LocationRetargetAlpha, 0.0f, 1.0f);

		FinalRetargetAlpha = FMax(RotationRetargetAlpha, LocationRetargetAlpha);
		RetargetDuration = Lerp(RetargetDurationMin, RetargetDurationMax, FinalRetargetAlpha);
	}
}

private function UpdateTether(float DeltaTime)
{
	local TPOV TargetTPOV;
	local float TetherAlpha;

	TargetTPOV = ComputeCameraLocationAndOrientationAtTime(MatineeInfo, FiringUnit.GetPawn(), false, GetTargetLocation(false), MatineeTime);
	TargetTPOV.Rotation = Normalize(TargetTPOV.Rotation);

	if(RetargetTransitionAlpha < 1.0)
	{
		TetherTPOV = TargetTPOV;
	}
	else
	{
		TetherAlpha = FClamp(DeltaTime / TetherDuration, 0.0, 1.0);
		TetherTPOV.Location = VLerp(TetherTPOV.Location, TargetTPOV.Location, TetherAlpha);
		TetherTPOV.Rotation = RLerp(TetherTPOV.Rotation, TargetTPOV.Rotation, TetherAlpha, true);
		TetherTPOV.FOV = Lerp(TetherTPOV.FOV, TargetTPOV.FOV, TetherAlpha);
	}
}

function TPOV GetCameraLocationAndOrientation()
{
	local TPOV BlendedTPOV;
	local InterpCurveVector RetargetLocationVectorCurve;
	local InterpCurvePointVector VectorCurvePoint;
	local float TangentAttenuation;
	local float Delta;
	local vector UpVector;
	local float Alpha;

	// see if we need blend from a previous target to the current tethered location
	if(RetargetTransitionAlpha < 1.0)
	{
		// blend nicely between the new camera location and the previous target's camera location
		// We use different curves for location and rotation to give andrew more control
		RetargetTPOV.Rotation = Normalize(RetargetTPOV.Rotation);

		// Since just lerping between the previous and new target camera location could cause the camera
		// to clip through a dude's head, we build a curve for the location to traverse which uses
		// the old and new camera orientations as the control points. This will build a nice curve
		// around the soldier which won't clip his body in the worst case.

		// This is set to the length of the interpolation so that when we do our cross to get the curve tangents,
		// the magnitude of the curve perturbation is proportional to the distance we need to move.
		// This is equivalent to taking the cross of the unit vectors and then scaling, 
		// but abusing associativity to make the code simpler
		UpVector.Z = VSize(TetherTPOV.Location - RetargetTPOV.Location) * 2;

		// make sure the direction we take around his head matches the direction of the yaw rotation
		Delta = Normalize(RetargetTPOV.Rotation - TetherTPOV.Rotation).Yaw * UnrRotToDeg;
		if(Delta > 0 || abs(Delta) > 180)
		{
			UpVector.Z = -UpVector.Z;
		}

		// attenuate the tangent control points on the curve by the difference in facing of the current and target
		// camera facings. For transitions where the camera facing doesn't change much but the change distance is
		// long, it would create a weird s-curve if we didn't attenuate it down.
		// Attenuation goes from 0 for cameras that are facing in the exact same direction, to 1 for cameras
		// that are facing in exactly opposite directions
		TangentAttenuation = (Vector(RetargetTPOV.Rotation) dot Vector(TetherTPOV.Rotation)); 
		TangentAttenuation = TangentAttenuation * -0.5 + 0.5; // convert from [-1..1], to [1..0]

		VectorCurvePoint.InVal = 0.0f;
		VectorCurvePoint.OutVal = RetargetTPOV.Location;
		VectorCurvePoint.InterpMode = CIM_CurveAuto;
		VectorCurvePoint.ArriveTangent = Vector(RetargetTPOV.Rotation) cross UpVector * TangentAttenuation;
		VectorCurvePoint.LeaveTangent = VectorCurvePoint.ArriveTangent;
		RetargetLocationVectorCurve.Points.AddItem(VectorCurvePoint);

		VectorCurvePoint.InVal = 1.0f;
		VectorCurvePoint.OutVal = TetherTPOV.Location;
		VectorCurvePoint.ArriveTangent = Vector(TetherTPOV.Rotation) cross UpVector * TangentAttenuation;
		VectorCurvePoint.LeaveTangent = VectorCurvePoint.ArriveTangent;
		RetargetLocationVectorCurve.Points.AddItem(VectorCurvePoint);

		Alpha = class'Helpers'.static.S_EvalInterpCurveFloat(RetargetLocationCurve, RetargetTransitionAlpha);
		BlendedTPOV.Location = class'Helpers'.static.S_EvalInterpCurveVector(RetargetLocationVectorCurve, Alpha);

		Alpha = class'Helpers'.static.S_EvalInterpCurveFloat(RetargetRotationCurve, RetargetTransitionAlpha);
		BlendedTPOV.Rotation = RLerp(RetargetTPOV.Rotation, TetherTPOV.Rotation, Alpha, true);

		//`Battle.DrawDebugSphere(BlendedTPOV.Location, 4, 6, 255, 255, UpVector.Z < 0 ? 0 : 255, true);
		//`Battle.DrawDebugLine(BlendedTPOV.Location, BlendedTPOV.Location + Vector(BlendedTPOV.Rotation) * 8, 255, 255, 255, true);

		BlendedTPOV.FOV = Lerp(RetargetTPOV.FOV, TetherTPOV.FOV, Alpha);
		return BlendedTPOV;
	}
	else
	{
		return TetherTPOV;
	}
}

/// <summary>
/// Should be called by gameplay with a new target has been selected with tab. Will attempt to use the same
/// matinee camera if possible
/// </summary>
function SetTarget(Actor NewTarget, optional Vector CurrentCameraLocation)
{
	if(NewTarget != TargetActor)
	{
		TargetDirty = true;
		TargetActor = NewTarget;
	}
}

protected function ResetTether()
{
	local TPOV NewTPOV;
	NewTPOV = ComputeCameraLocationAndOrientationAtTime(MatineeInfo, FiringUnit.GetPawn(), false, GetTargetLocation(), 0);
	TetherTPOV = NewTPOV;
}

function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local TFocusPoints FocusPoint;

	FocusPoint.vFocusPoint = GetTargetLocation();
	FocusPoint.vCameraLocation = GetCameraLocationAndOrientation().Location;
	OutFocusPoints.AddItem(FocusPoint);
}

function bool GetCameraDOFFocusPoint(out vector FocusPoint)
{
	if(DOFFocusShooter)
	{
		FiringUnit.GetPawn().GetHeadLocation();
	}
	else
	{
		FocusPoint = GetTargetLocation();
	}

	return true;
}

function string GetDebugDescription()
{
	if(MatineeInfo != None && MatineeInfo.Matinee != none)
	{
		return super.GetDebugDescription() $ " - " $ MatineeInfo.Matinee.ObjComment $ " - " $ MatineeTime $ "s";
	}
	else
	{
		return super.GetDebugDescription() $ " - No matinee selected";
	}
}

/// <summary>
/// Prints debug info to the screen so the user can see what the camera stack is doing
/// </summary>
simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string DebugString;
	local int CameraIndex;

	DebugString = "===================================\n";
	DebugString $= "=======    OTS Camera Info   ========\n";
	DebugString $= "===================================\n\n";

	// information about what went into choosing this camera
	for(CameraIndex = 0; CameraIndex < CandidateCameraScores.Length; ++CameraIndex)
	{
		if(CandidateCameraScores[CameraIndex].Matinee == MatineeInfo.Matinee)
		{
			DebugString $= "-->";
		}
		DebugString $= "["$CameraIndex$"] [Score:"$CandidateCameraScores[CameraIndex].Weight$"] Matinee:" @ CandidateCameraScores[CameraIndex].Matinee.ObjComment @ "\n";
	}

	if(bCurrentCameraForced)
	{
		DebugString $= "Forced Camera Selection:" @ MatineeInfo.Matinee.ObjComment @ "\n\n";
		
		DebugString = DebugString $ "==============================================\n";
		DebugString = DebugString $ "["$ DebugScoreData.TransparencyPenaltyPercentage / DebugScoreData.SampleCount $"] TransparencyPenaltyPercentage\n";
		DebugString = DebugString $ "["$ DebugScoreData.FiringUnitHeadBlockedScorePenalty / DebugScoreData.SampleCount $"] FiringUnitHeadBlockedScorePenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.FiringUnitWaistBlockedScorePenalty / DebugScoreData.SampleCount $"] FiringUnitWaistBlockedScorePenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.CantSeeFiringUnitAtAllPenalty / DebugScoreData.SampleCount $"] CantSeeFiringUnitAtAllPenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.TargetedLocationBlockedScorePenalty / DebugScoreData.SampleCount $"] TargetedLocationBlockedScorePenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.BlockedStartLocationPenalty / DebugScoreData.SampleCount $"] BlockedStartLocationPenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.PriorityPenalty $"] PriorityPenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.CrosscutScorePenalty $"] CrosscutScorePenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.LookAtBackPenalty $"] LookAtBackPenalty \n";
		DebugString = DebugString $ "["$ DebugScoreData.SampleCount $"] SampleCount \n";
		DebugString = DebugString $ "==============================================\n";		
		DebugString = DebugString $ "Total:" @ DebugScoreData.TotalScore;
	}

	// draw a background box so the text is readable
	kCanvas.SetPos(870, 10);
	kCanvas.SetDrawColor(0, 0, 0, 100);
	kCanvas.DrawRect(400, 600);

	// draw the text
	kCanvas.SetPos(870, 10);
	kCanvas.SetDrawColor(0, 255, 0);
	kCanvas.DrawText(DebugString);
}

function DebugForceCameraSelection(int ForcedCameraIndex)
{	
	local Vector UnitFacing;
	local Rotator OldCameraOrientation;
	local float Score;

	FiringUnit.FlushPersistentDebugLines();
	bDrawDebugInfo = true;

	UpdateActorsToIgnoreForLineOfSightChecksArray();

	//Use CandidateCameraScores for consistency
	if(ForcedCameraIndex > -1 && ForcedCameraIndex < CandidateCameraScores.Length)
	{
		MatineeInfo.InitFromMatinee(CandidateCameraScores[ForcedCameraIndex].Matinee);

		//Score the matinee ... for science!
		//*************************************
		Score = GetMatineeObstructionScore(MatineeInfo);		

		// handled separately as we always want this score, even if ScoreCandidateMatinee is derived
		OldCameraOrientation = GetCameraLocationAndOrientation().Rotation;
		if(CrosscutScorePenalty != 0 && WillMatineeCrossCut(MatineeInfo, OldCameraOrientation))
		{
			DebugScoreData.CrosscutScorePenalty += CrosscutScorePenalty;			
			Score += DebugScoreData.CrosscutScorePenalty;
		}
		
		UnitFacing = GetUnitFacing();
		if(LookAtBackPenalty != 0 && WillMatineeLookAtUnitsBack(MatineeInfo, UnitFacing))
		{
			DebugScoreData.LookAtBackPenalty = LookAtBackPenalty;			
			Score += DebugScoreData.LookAtBackPenalty;
		}

		DebugScoreData.PriorityPenalty = PriorityPenalty[MatineeInfo.Matinee.SelectionPriority];

		DebugScoreData.TotalScore = Score;
		//*************************************
		
		ResetTether();
		RetargetDuration = 0.1f;

		bCurrentCameraForced = true;
	}
	else
	{
		SelectMatinee(GetCameraLocationAndOrientation().Rotation);
		bCurrentCameraForced = false;
	}

	bDrawDebugInfo = false;
}

defaultproperties
{
	RetargetTransitionAlpha=1.0
	RetargetDuration=1.0
	ShouldBlend=true
	ShouldHideUI=true
}