//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_FollowCursor.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Override of X2Camera_FollowMouseCursor with minor adjustments to make it play well with the controller
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_FollowCursor extends X2Camera_FollowMouseCursor
	config(Camera);

// Keep track of the location of the cursor on the last frame so we can detect when it moves.
var vector PrevCursorLocation;

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	// move the lookat point to be relative to the 3d cursor
	LookAt -= `CURSOR.GetCursorFeetLocation();
}

/// <summary>
/// Get's the current desired look at location
/// </summary>
protected function Vector GetCameraLookat()
{
	local Vector Result;
	local XCom3DCursor Cursor;

	// When using the controller, the lookat offset is relative to the current location
	// of the 3D cursor in the world.
	Cursor = `CURSOR;
	Result = Cursor.Location + LookAt;
	Result.Z = Cursor.GetFloorMinZ(Cursor.m_iLastEffectiveFloorIndex);
	return Result;
}

function UpdateCamera(float DeltaTime)
{
	local XCom3DCursor Cursor;

	super.UpdateCamera(DeltaTime);

	// if the cursor moves, clear our scroll offset
	Cursor = `CURSOR;
	if (Cursor.Location != PrevCursorLocation)
	{
		LookAt = vect(0,0,0);
	}
	PrevCursorLocation = Cursor.Location;
}

protected function ClampLookAtToWorldBounds()
{
	local XCom3DCursor Cursor;
	local XComWorldData WorldData;
	local vector BoundsMin;
	local vector BoundsMax;
	local vector VerticalBuffer;

	// The only difference between this clamp function and the one in the base class is that this one
	// clamps the scroll while taking the cursor's current location into account.
	WorldData = `XWORLD;
	Cursor = `CURSOR;
	VerticalBuffer.Z = class'XComWorldData'.const.WORLD_FloorHeight * 3;
	BoundsMin = WorldData.Volume.CollisionComponent.Bounds.Origin - WorldData.Volume.CollisionComponent.Bounds.BoxExtent - VerticalBuffer;
	BoundsMax = WorldData.Volume.CollisionComponent.Bounds.Origin + WorldData.Volume.CollisionComponent.Bounds.BoxExtent + VerticalBuffer;
	LookAt.X = FClamp(Cursor.Location.X + LookAt.X, BoundsMin.X, BoundsMax.X) - Cursor.Location.X;
	LookAt.Y = FClamp(Cursor.Location.Y + LookAt.Y, BoundsMin.Y, BoundsMax.Y) - Cursor.Location.Y;
}

// No mouse edge scrolling allowed in controller mode
function EdgeScrollCamera(Vector2D Offset);

function bool HidePathing()
{
	return false;
}