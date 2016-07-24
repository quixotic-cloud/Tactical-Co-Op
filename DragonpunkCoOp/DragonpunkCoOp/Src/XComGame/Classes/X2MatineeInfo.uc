//---------------------------------------------------------------------------------------
//  FILE:    X2MatineeInfo.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Utility class for making matinees more available to gameplay. Extracts curve information,
//           scores for position, etc.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2MatineeInfo extends Object 
	native;

cpptext
{
private:
	bool GetMoveTrackAndInstanceForGroup(UInterpGroup* Group, UInterpTrackInstMove** OutTrackInst, UInterpTrackMove** OutTrack);
	void ActivateOutputLink(INT OutputLinkIndex) const; // helper to activate the seqops attached to a given output link on the matinee
	UInterpData* GetMatineeData();
}

// The matinee we are inspecting
var privatewrite SeqAct_Interp Matinee;

// specifies a relative origin and orientation for sampling the matinee.
var privatewrite Vector SamplingOrigin;
var privatewrite Rotator SamplingOriginOrientation;

// Cached reference actor for evaluating matinee curves
var private X2MatineeInfoDummyActor CachedBogusReferenceActor;

// Cached objects needed to evaluate tracks. Rather than recreate them every frame we can just store them and fill them out again
// to save allocations and construction
var private InterpGroupInst BogusGroupInstance;
var private InterpTrackInstMove MoveTrackInst;
var private InterpTrackInstFloatProp FloatPropTrackInst;

// private helper functions
native private function X2MatineeInfoDummyActor GetBogusReferenceActor();

/// <summary>
/// Returns the duration of this matinee, in seconds
/// </summary>
native function float GetMatineeDuration();

/// <summary>
/// Sets the effective origin for sampling from the matinee. The basically "overlays" the matinee data at the
/// specified location, so that all samples will be automatically adjusted accordingly.
/// Example: If you have a matinee that is designed to have its origin and facing at the root
/// of a particular unit, you can call this function with that units location and facing as inputs.
/// Now all further samples will automatically be sampled in his coordinate space and returned in world space.
/// </summary>
native function SetSamplingOrigin(Vector InSamplingOrigin, Rotator InSamplingOriginOrientation);

/// <summary>
/// Samples the active movement track in the specified group at the specified time. If the group or the track is not found
/// this function zeros out the results
/// </summary>
native function SampleMovementTrack(name GroupName, float Time, out Vector Location, out Rotator Rotation);

/// <summary>
/// Samples the active movement track in the specified group relative to the active movement track in the specified reference group.
/// For example, let's say you have two track groups, one for a soldier and one for a camera. You want to positiion the camera
/// relative to the soldier as it is in the matinee. Calling this function with GroupName=Camera and RelativeToGroupName=Soldier
/// will return the worldspace deltas needed to place the camera relative to the soldier.
///
/// Ex (where Camera and Soldier are Actors in the world): 
///   SampleMovementTrackDelta('Camera', 'Soldier', 0.0, LocationDelta, RotationDelta);
///   Camera.Location = Soldier.Location + LocationDelta * Soldier.Rotation
///   Camera.Rotation = Soldier.Rotation + RotationDelta
/// </summary>
native function SampleMovementTrackRelative(name GroupName, name RelativeToGroupName, float Time, out Vector LocationDelta, out Rotator RotationDelta);

/// <summary>
/// Samples the active animation track in the specified group at the specified time, and return the location and orientation
/// of the root bone. Requires the animation controller of a unit, so that the correct animation scaling information can
/// be taken into account.
/// </summary>
native function SampleRootMotionFromAnimationTrack(name GroupName, float Time, XComAnimTreeController AnimController, out Vector Location, out Rotator Rotation);

/// <summary>
/// Samples the director track at Time for the camera location. Takes things like FOV and
/// camera cuts into account automatically.
/// </summary>
native function SampleDirectorTrack(float Time, out TPOV CameraLocation, optional out PostProcessSettings PostProcessOverrides);

/// <summary>
/// Samples the float property track in the given group for the given property name.
/// If no such property was found, it returns the specified default value.
/// </summary>
native function float SampleFloatPropertyTrack(name GroupName, float Time, name PropertyName, float DefaultValue);

/// <summary>
/// Samples the slomo track, if any exists. SlomoRate is left untouched and the function
/// returns false if no enabled slomo track exists on this matinee 
/// </summary>
native function bool SampleSlomoTrack(float Time, out float SlomoRate);

/// <summary>
/// Inspects the event track in the matinee and triggers all events that lie from
/// StartTime to StartTime + Duration.
/// </summary>
native function TriggerEvents(float StartTime, float Duration);

/// <summary>
/// Fires any events attached to the "completion" event on the matinee
/// </summary>
native function TriggerCompletionEvents();

/// <summary>
/// Must be called prior to use. Can be called again to init with a different matinee
/// </summary>
native function InitFromMatinee(SeqAct_Interp InMatinee);

/// <summary>
/// Draws the specified track's movement path
/// </summary>
function DebugDrawMovementTrack(name GroupName)
{
	local XGBattle Battle; // only used for access to the debug drawing functions
	local float MatineeDuration;
	local float CurrentTime;
	local float TimeIncrement;
	local Vector SamplePoint;
	local Vector PrevSamplePoint;
	local Rotator SampleRotation;

	Battle = `Battle;

	MatineeDuration = GetMatineeDuration();
	TimeIncrement = MatineeDuration / 20;

	SampleMovementTrack(GroupName, 0.0, SamplePoint, SampleRotation);

	for(CurrentTime = TimeIncrement; CurrentTime <= MatineeDuration; CurrentTime += TimeIncrement)
	{
		PrevSamplePoint = SamplePoint;
		SampleMovementTrack(GroupName, CurrentTime, SamplePoint, SampleRotation);

		Battle.DrawDebugLine(SamplePoint, PrevSamplePoint, 255, 255, 255, true);
	}
}
