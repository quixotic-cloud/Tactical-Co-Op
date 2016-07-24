//---------------------------------------------------------------------------------------
//  FILE:    X2Action_RevealArea.uc
//  AUTHOR:  Adam Smith
//  DATE:    24 Jul 2015
//  PURPOSE: Action to reveal FOW using the Gremlin
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_RevealArea extends X2Action;

var Vector TargetLocation;
var float ScanningRadius;
var int AssociatedObjectID;
var bool bDestroyViewer;

simulated state Executing
{
	function CreateFOWViewer()
	{
		local DynamicPointInSpace Viewer;

		Viewer = DynamicPointInSpace(`XWORLD.CreateFOWViewer(TargetLocation, ScanningRadius));
		Viewer.SetObjectID(AssociatedObjectID);
	}

	function DestroyFOWViewer()
	{
		local DynamicPointInSpace Viewer;

		foreach `XWORLDINFO.AllActors(class'DynamicPointInSpace', Viewer)
		{
			if( Viewer.ObjectID == AssociatedObjectID )
			{
				`XWORLD.DestroyFOWViewer(Viewer);
			}
		}
	}

Begin:
	if( bDestroyViewer )
	{
		DestroyFOWViewer();
	}
	else
	{
		CreateFOWViewer();
	}

	CompleteAction();
}

defaultproperties
{
	ScanningRadius = 768.0; //8 tiles
}
