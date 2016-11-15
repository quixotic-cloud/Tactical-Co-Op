//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMouseGuard_RotatePawn.uc
//  AUTHOR:  Sam Batista 8/25/15
//  PURPOSE: Displays a movieclip that intercepts all mouse activity, and rotates an actor
//           if user clicks and drags the mouse across its surface.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMouseGuard_RotatePawn extends UIMouseGuard
	config(UI);

var bool bMouseIn;
var bool bRotatingPawn;
var bool bCanRotate;
var Rotator ActorRotation;
var Vector2D MouseLocation;
var Actor ActorPawn;

var private Vector2D StickVector;
var config float StickRotationMultiplier;
var config float DragRotationMultiplier;
var config float WheelRotationMultiplier;

simulated function SetActorPawn(Actor NewPawn, optional Rotator NewRotation)
{
	local Rotator ZeroRotation;

	ActorPawn = NewPawn;
	if(ActorPawn != none)
		SetTimer(0.01f, true, nameof(OnUpdate));
	else
		ClearTimer(nameof(OnUpdate));

	if(NewRotation != ZeroRotation)
		ActorRotation = NewRotation;
	else if(ActorRotation == ZeroRotation && ActorPawn != none)
		ActorRotation = ActorPawn.Rotation;
}

simulated function UpdateStickVector(float newX, float newY)
{
	StickVector.X = newX;
	bRotatingPawn = newX > 0.2f || newX < -0.2f;
}

simulated function OnUpdate()
{
	local Vector2D MouseDelta;
	local Quat StartRotation;
	local Quat GoalRotation;
	local Quat ResultRotation;
	local Rotator RotatorLerp;
	local float RotatorDiff;

	if( ActorPawn != none )
	{
		if(bRotatingPawn && bCanRotate)
		{
			MouseDelta = Movie.Pres.m_kUIMouseCursor.m_v2MouseFrameDelta;
			ActorRotation.Yaw += -1 * MouseDelta.X * DragRotationMultiplier;
			if( `ISCONTROLLERACTIVE )
			{
				ActorRotation.Yaw -= 1.0 * StickVector.X * StickRotationMultiplier;
				}
		}
	
		RotatorDiff = RDiff(ActorPawn.Rotation, ActorRotation);
		if(Abs(RotatorDiff) > 1)
		{
			StartRotation = QuatFromRotator(ActorPawn.Rotation);
			GoalRotation = QuatFromRotator(ActorRotation);
	
			ResultRotation = QuatSlerp(StartRotation, GoalRotation, 0.1f, true);
			RotatorLerp = QuatToRotator(ResultRotation);
			ActorPawn.SetRotation(RotatorLerp);
		}
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:
		bRotatingPawn = true;
		Movie.Pres.m_kUIMouseCursor.UpdateMouseLocation();
		// missing break here is purposeful, no touchy
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		bMouseIn = true;
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		bRotatingPawn = false;
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
		bRotatingPawn = false;
		// missing break here is purposeful, no touchy
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		bMouseIn = false;
		break;
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if(bCanRotate)
	{
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
			if(bMouseIn) RotateInPlace(-1);
			return true;
		case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
			if(bMouseIn) RotateInPlace(1);
			return true;
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_LEFT:
			RotateInPlace(1);
			return true;
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_RSTICK_RIGHT:
			RotateInPlace(-1);
			return true;
		}
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function RotateInPlace(int Dir)
{
	local XComHumanPawn HumanPawn;
	ActorRotation.Yaw += 45.0f * class'Object'.const.DegToUnrRot * WheelRotationMultiplier * Dir;
	
	HumanPawn = XComHumanPawn(ActorPawn);
	if( HumanPawn != None )
	{
		HumanPawn.CustomizationRotationSet = false;
	}
}

simulated function OnReceiveFocus()
{
	local XComHumanPawn HumanPawn;

	super.OnReceiveFocus();
	if(ActorPawn != none)
	{
		ActorRotation = ActorPawn.Rotation;
		SetTimer(0.01f, true, nameof(OnUpdate));

		HumanPawn = XComHumanPawn(ActorPawn);
		if( HumanPawn != None )
		{
			HumanPawn.CustomizationRotationSet = false;
		}
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	ClearTimer(nameof(OnUpdate));
}

simulated function OnRemoved()
{
	SetActorPawn(none);
	super.OnRemoved();
}

simulated function SetCanRotate(bool Rotate)
{
	bCanRotate = Rotate;
}

defaultproperties
{
	bCanRotate = true;
}