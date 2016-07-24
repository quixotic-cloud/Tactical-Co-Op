//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_ReflexActionReveal.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Camera that gives us a nice angle for viewing the reflexing unit and his revealed enemies
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_ReflexActionReveal extends X2Camera_MidpointTimed;

var X2Action_Reflex ReflexActionToShow;

function Added()
{
	// add the focus points from the action units before we do the base camera init
	AddFocusPoints();
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	LookAtDuration = 2.0f;

	// use the alien angles for the reflex reveals
	TargetRotation.Pitch = AlienTurnPitch * DegToUnrRot;
	TargetRotation.Yaw += (AlienTurnYaw - HumanTurnYaw)  * DegToUnrRot;
	TargetRotation.Roll = AlienTurnRoll  * DegToUnrRot;
	TargetFOV = AlienTurnFOV;

	RecomputeLookatPointAndZoom();
}

function Deactivated()
{
	super.Deactivated();

	// restore the human orienation and angles. Since reflex only happens on the human turn this is safe
	TargetRotation.Pitch = HumanTurnPitch * DegToUnrRot;
	TargetRotation.Yaw -= (AlienTurnYaw - HumanTurnYaw)  * DegToUnrRot;
	TargetRotation.Roll = HumanTurnRoll  * DegToUnrRot;
	TargetFOV = HumanTurnFOV;
}

public function AddFocusPoints()
{
	local XComGameState_Unit UnitState;		
	local XGUnit Visualizer;

	`assert(ReflexActionToShow != none);
	foreach ReflexActionToShow.StateChangeContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		Visualizer = XGUnit(UnitState.GetVisualizer());

		FocusPoints.AddItem(Visualizer.GetPawn().GetHeadLocation());
		FocusPoints.AddItem(Visualizer.GetPawn().GetFeetLocation());
	}
}