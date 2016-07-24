//---------------------------------------------------------------------------------------
//  FILE:    XComLootDropActor.uc
//  AUTHOR:  Dan Kaplan  --  10/30/2015
//  PURPOSE: Provides the visualizer for loot drop objects
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComLootDropActor extends DynamicPointInSpace
	native(Destruction);


// Looting variables
var protected StaticMeshComponent LootMarkerMesh;


native function SetLootMarker(bool bVisible, int ExpirationCount, const out TTile TileLocation);


defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=LootMarkerMeshComponent
		HiddenEditor=true
		HiddenGame=true
		HideDuringCinematicView=true
		AbsoluteRotation=true // the billboard shader will break if rotation is in the matrix
		AbsoluteTranslation=true
		StaticMesh=StaticMesh'UI_3D.Waypoint.LootStatus'
	End Object
	Components.Add(LootMarkerMeshComponent)
	LootMarkerMesh=LootMarkerMeshComponent
}