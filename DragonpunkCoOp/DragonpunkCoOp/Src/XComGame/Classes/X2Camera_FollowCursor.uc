//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_FollowCursor.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Simple camera that just tracks the 3d cursor. The default
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_FollowCursor extends X2Camera_LookAt;

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);
}

/// <summary>
/// Get's the current desired look at location
/// </summary>
protected function Vector GetCameraLookat()
{
	local Vector Result;
	local XCom3DCursor Cursor;

	Cursor = `CURSOR;
	
	Result = Cursor.Location;
	Result.Z = Cursor.m_fLogicalCameraFloorHeight;

	return Result;
}

function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local XCom3DCursor Cursor;
	local XComTacticalController TacticalController;
	local XComPawn ActivePawn;
	local vector Offset;
	local TPOV CameraPOV;
	local bool bIgnoreCursor;
	local TFocusPoints FocusPoint;
	local Plane FloorPlane;
	local vector ProjectedPoint;
	local vector CameraToCursorNoZ;
	local vector CursorLocation;
	
	Cursor = `CURSOR;
	bIgnoreCursor = false;

	CameraPOV = GetCameraLocationAndOrientation();
	FocusPoint.vCameraLocation = CameraPOV.Location;

	TacticalController = XComTacticalController(`LEVEL.GetALocalPlayerController());
	ActivePawn = TacticalController.GetActivePawn();

	// the cursor location (the thing the user is pointing at) is of interest	
	if (DisableFocusPointExpiration() == false && Cursor != none && bIgnoreCursor == false && HidePathing() != true)
	{		
		FloorPlane.X = 0;
		FloorPlane.Y = 0;
		FloorPlane.Z = 1.0;
		FloorPlane.W = Cursor.m_fLogicalCameraFloorHeight + 1; // Offset to ensure in proper volume if needed;

		Offset = vect(0, 0, 0);
		Offset.Z = Cursor.CollisionComponent.Bounds.BoxExtent.Z;

		CursorLocation = Cursor.Location - Offset;

		CameraToCursorNoZ = CursorLocation - CameraPOV.Location;
		CameraToCursorNoZ.Z = 0;
		CameraToCursorNoZ = Normal(CameraToCursorNoZ);

		//// Offset the projection ray X units towards the camera (NoZ)
		RayPlaneIntersection(CameraPOV.Location, (CursorLocation - (CameraToCursorNoZ * 25.0f)) - CameraPOV.Location, FloorPlane, ProjectedPoint);

		FocusPoint.vFocusPoint = ProjectedPoint;
		FocusPoint.vCameraLocation = CameraPOV.Location;
		OutFocusPoints.AddItem(FocusPoint);
	}

	// Removed the Movement Puck as a focus point.

	// the path destination is of interest (it might not be the same as the cursor location if the cursor location is not reachable).
	//if (PathingIsVisible && TacticalController.m_kPathingPawn.PathTiles.Length > 0)
	//{

	//	PathingPawnDestinationTile = TacticalController.m_kPathingPawn.PathTiles[TacticalController.m_kPathingPawn.PathTiles.Length - 1];
	//	if (!WorldData.GetFloorPositionForTile(PathingPawnDestinationTile, PathingPawnDestination))
	//	{
	//		PathingPawnDestination = WorldData.GetPositionFromTileCoordinates(PathingPawnDestinationTile);
	//	}

	//	PathingPawnDestination.Z += 1; // kick the floor location up a bit so it isn't co-planer with the floor

	//	//If we are on a ramp tile, don't 
	//	if (WorldData.IsRampTile(PathingPawnDestinationTile) && Cursor != none)
	//	{
	//		bIgnoreCursor = true;
	//	}

	//	WorldData.GetFloorTileForPosition(ActivePawn.Location, ScratchTile);
	//	if (PathingPawnDestinationTile != ScratchTile)
	//	{
	//		FocusPoint.vFocusPoint = PathingPawnDestination;
	//		FocusPoint.vCameraLocation = FocusPoint.vFocusPoint - (Vector(CameraPOV.Rotation) * 9999.0f);
	//		OutFocusPoints.AddItem(FocusPoint);
	//	}
	//}

	// the active unit, if any, is of interest
	if (ActivePawn != none && DisableFocusPointExpiration() == false)
	{
		FocusPoint.vFocusPoint = ActivePawn.Location;
		if (ActivePawn.CollisionComponent != none)
			FocusPoint.vFocusPoint.Z = ActivePawn.Location.Z - ActivePawn.CollisionComponent.Bounds.BoxExtent.Z;

		FocusPoint.vCameraLocation = CameraPOV.Location;

		OutFocusPoints.AddItem(FocusPoint);
	}
}

function bool GetCameraIsPrimaryFocusOn()
{
	return true;
}

function bool DisableFocusPointExpiration()
{
	return false;
}

defaultproperties
{
	Priority=eCameraPriority_Default
	HidePathingWhenActive=false
}
