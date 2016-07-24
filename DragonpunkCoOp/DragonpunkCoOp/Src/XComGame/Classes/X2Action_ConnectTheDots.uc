//---------------------------------------------------------------------------------------
//  FILE:    X2Action_ConnectTheDots.uc
//  AUTHOR:  Dan Kaplan
//  DATE:    8/13/15
//  PURPOSE: Visualizer to create a visible connection between a source to a target.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_ConnectTheDots extends X2Action;

var float RenderCapsuleRadius;

var vector SourceLocation; // location of the source object
var vector TargetLocation; // location of the target object
var bool bCleanupConnection;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	private function CreateConnection()
	{
		local XComTacticalController TacticalController;
		TacticalController = XComTacticalController(`LEVEL.GetALocalPlayerController());

		// draw from source to target
		TacticalController.m_kPathingPawn.SetVisible(true); // force the pathing pawn visible
		TacticalController.m_kPathingPawn.UpdateConcealmentTilesVisibility(true);
		TacticalController.m_kPathingPawn.SetConcealmentBreakRenderTiles(SourceLocation, TargetLocation, RenderCapsuleRadius);
	}

	private function CleanupConnection()
	{
		local XComTacticalController TacticalController;
		TacticalController = XComTacticalController(`LEVEL.GetALocalPlayerController());

		// cleanup the connection visualization
		TacticalController.m_kPathingPawn.ClearConcealmentBreakRenderTiles();
		TacticalController.m_kPathingPawn.UpdateConcealmentTilesVisibility(false);

		if( !TacticalController.IsInState('ActiveUnit_Moving') )
		{
			TacticalController.m_kPathingPawn.SetVisible(false); // reset the pathing pawn to not visible unless we're in the state where it should remain visible
		}
	}

	function ResetTimeDilation()
	{
		local X2VisualizerInterface VisualizerInterface;

		VisualizerInterface = X2VisualizerInterface(Track.TrackActor);
		if(VisualizerInterface != None)
		{
			VisualizerInterface.SetTimeDilation(1.0f);
		}
	}

Begin:

	//This action is the start of a sequence that should never be time dilated. Since it can interrupt the movement of the unit
	//representing the track actor however, make sure we are not time dilated.
	ResetTimeDilation();

	if( !bCleanupConnection )
	{
		CreateConnection();
	}
	else
	{
		CleanupConnection();
	}

	CompleteAction();
}

defaultproperties
{
	RenderCapsuleRadius=100
}
