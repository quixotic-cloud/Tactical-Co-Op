//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_FrameVisualizationActions.uc
//  AUTHOR:  Ryan McFall  --  10/06/2015
//  PURPOSE: Used to frame an arbitrary sequence of actions. Originally built to provide
//			 better framing for cars detonating from damage over time.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_FrameVisualizationActions extends X2Camera
	implements(X2VisualizationMgrObserverInterface);

var private Actor LookAtActor;
var private Vector LookAtLocation;
var private int StopFramingAtHistoryIndex;
var private float LingerDuration; //A delay to apply to the removal call once the StopFramingAtHistoryIndex has been hit

// child camera we will push to do the actual framing
var private X2Camera_LookAt LookAtCamera;

function Added()
{
	super.Added();

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	CreateFramingCamera();
}

function Removed()
{
	super.Removed();

	`XCOMVISUALIZATIONMGR.RemoveObserver(self);
}

function SetupCamera(Actor InLookAtActor, const out Vector InLookAtLocation, XComGameStateContext EventChainStart, float InLingerDuration)
{
	LookAtActor = InLookAtActor;
	LookAtLocation = InLookAtLocation;
	StopFramingAtHistoryIndex = EventChainStart.GetLastStateInEventChain().HistoryIndex;
	LingerDuration = InLingerDuration;
}

private function CreateFramingCamera()
{
	local X2Camera_LookAtActor LookAtActorCamera;
	local X2Camera_LookAtLocation LookAtLocationCamera;

	// destroy any previous framing camera
	LookAtCamera = none;
	
	if(LookAtActor != none)
	{
		// this ability has only an activating unit, just move to look at him
		LookAtActorCamera = new class'X2Camera_LookAtActor';
		LookAtActorCamera.ActorToFollow = LookAtActor;
		LookAtActorCamera.UpdateWhenInactive = true;
		PushCamera(LookAtActorCamera);
		LookAtCamera = LookAtActorCamera;
	}
	else
	{
		// this ability has only an activating unit, just move to look at him
		LookAtLocationCamera = new class'X2Camera_LookAtLocation';
		LookAtLocationCamera.LookAtLocation = LookAtLocation;
		LookAtLocationCamera.UpdateWhenInactive = true;
		PushCamera(LookAtLocationCamera);
		LookAtCamera = LookAtLocationCamera;
	}

	ChildCamera.UpdateWhenInactive = true;
}

public function bool HasArrived()
{
	local X2Camera_LookAtActor LookAtActorCamera;
	local X2Camera_LookAtLocation LookAtLocationCamera;

	LookAtActorCamera = X2Camera_LookAtActor(LookAtCamera);
	LookAtLocationCamera = X2Camera_LookAtLocation(LookAtCamera);

	if(LookAtLocationCamera != none)
	{
		return LookAtLocationCamera.HasArrived;
	}
	else if(LookAtActorCamera != none)
	{
		return LookAtActorCamera.HasArrived;
	}
	else
	{
		return true; // somehow we didn't create a camera
	}
}

event OnVisualizationIdle()
{
	if(LingerDuration > 0.0f)
	{
		`BATTLE.SetTimer(LingerDuration, false, nameof(RemoveSelfFromCameraStack), self);
	}
	else
	{
		RemoveSelfFromCameraStack();
	}
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	if(AssociatedGameState.HistoryIndex > StopFramingAtHistoryIndex)
	{
		if(LingerDuration > 0.0f)
		{
			`BATTLE.SetTimer(LingerDuration, false, nameof(RemoveSelfFromCameraStack), self);
		}
		else
		{
			RemoveSelfFromCameraStack();
		}
	}
}

function string GetDebugDescription()
{
	return super.GetDebugDescription() $ " - Frame until " $ StopFramingAtHistoryIndex;
}

defaultproperties
{
	UpdateWhenInactive=true
	Priority=eCameraPriority_LookAt
}