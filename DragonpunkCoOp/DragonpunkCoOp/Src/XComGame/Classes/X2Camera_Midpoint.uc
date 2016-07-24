//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_Midpoint.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Camera that keeps all points of interest within the safe zone.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_Midpoint extends X2Camera_LookAt
	config(Camera)
	native;

// amount of zoom to add if possible when switching to this camera. Will be removed when this camera finishes
var private const config float AccentZoom;

// percentage of the total FOV in which to frame the midpoingt shot. For example, with a 60 degree FOV 
// camera, a framing percentage of 0.6 would frame the shot within the inner 0.6 * 60 = 36 degrees
// of the camera fov. You can also think of this as the width of the framed shot in screen space. 0.6 would
// fit the shot within the inner 0.6 percent of the screen.
var private const config float FramingFOVPercentage;

// all focus points that are contained by this camera
var protected array<Vector> FocusPoints;

// all actors that must be framed by this camera
var protected array<Actor> FocusActors;

// the lookat point that will frame all focus points and actors
var private Vector CachedLookAt;

// if true, will only do building cutouts for actors the camera is framing
var bool OnlyCutDownForActors;

// Where did our zoom start?
var private float StartingZoom;

// Zoom of the camera before us, so we can restore it
var private float SavedZoom;

// where did the camera start from? Used to allow us to interpolate the zoom 1:1 as we move to
// the new lookat location
var private Vector StartingLookAt;

// used to smoothly interpolate zoom with rotation
var private Rotator StartingRotationForZoom;

// we only want to zoom in the first time we become active. Subsequent activations should have us start zoomed.
// otherwise if we are interrupted with matinee cams, etc, we will zoom in when it finishes, instead of out
var private bool FirstActivation;

// no adjusting of the zoom, that will just mess with our framing
function ZoomCamera(float Amount);

// no adjusting of the pitch either
function PitchCamera(float Degrees);

protected function InterpolateZoom(float DeltaTime)
{
	local float Alpha;

	// after the user requests a yaw, smoothly interpolate the zoom with whatever yaw change the wanted.
	// The zoom will have changed to take the new midpoint framing into account, and it looks way better if
	// the rotation and zoom change all blend together 
	if(StartingRotationForZoom != TargetRotation)
	{
		// smoothly interpolate with yaw
		Alpha = (CurrentRotation.Yaw - StartingRotationForZoom.Yaw) / float(TargetRotation.Yaw - StartingRotationForZoom.Yaw);
		CurrentZoom = Lerp(StartingZoom, TargetZoom, Alpha);
		return;
	}

	if(VSizeSq(StartingLookAt - CachedLookAt) < 1.0f)
	{
		// exceedingly small midpoint adjustments will cause a very fast zoom interpolation in the code
		// block below, which will feel like a hitch. So if we detect this is the case, then don't do that.
		// just use the normal zoom interpolation logic
		super.InterpolateZoom(DeltaTime);
	}
	else
	{
		// interpolate the zoom smoothly over our transition from the old camera location
		// to the midpoint location
		if(CachedLookAt != StartingLookAt) // guard against divide by zero
		{
			Alpha = VSize2D(CurrentLookAt - StartingLookAt) / VSize2D(CachedLookAt - StartingLookAt);
			CurrentZoom = Lerp(StartingZoom, TargetZoom, Alpha);
		}
		else
		{
			CurrentZoom = TargetZoom;
		}
	}
}

protected function InterpolateRotation(float DeltaTime)
{
	super.InterpolateRotation(DeltaTime);

	// once our rotation arrives, reset the zoom interpolating variable to release zoom control back to
	// the usual zoom interpolating thing
	if(TargetRotation == CurrentRotation)
	{
		StartingRotationForZoom = CurrentRotation;
	}
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	// save the original zoom so we can restore it when we deactivate
	SavedZoom = LastActiveLookAtCamera.TargetZoom;
		
	// keep track of where we started from
	StartingZoom = CurrentZoom;
	StartingLookAt = CurrentLookAt;
	StartingRotationForZoom = CurrentRotation;

	// note that if something tried and failed to activate, we will get control back immediately.
	// since visually nothing changed for the user, treat this case as a first activation
	// so that we initialize with the same parameters and don't do the small zoom out. Otherwise the
	// camera will visually pop
	if(FirstActivation || PreviousActiveCamera == self)
	{
		// add a small bit of extra zoom as an accent to the framing of the camera.
		TargetZoom += AccentZoom;
		FirstActivation = false;
	}
	else
	{
		CurrentZoom = SavedZoom + AccentZoom; // zoom out
		TargetZoom = CurrentZoom;
	}

	RecomputeLookatPointAndZoom();

	if(PreviousActiveCamera != LastActiveLookAtCamera)
	{
		// not blending from another lookat camera, so just snap to our focus point
		CurrentZoom = TargetZoom;
		CurrentLookAt = CachedLookAt;
	}
}

function Deactivated()
{
	super.Deactivated();
	
	// restore the original zoom so that subsequent lookat cams don't use our slightly zoomed in version
	TargetZoom = SavedZoom;
}

function AddFocusPoint(Vector FocusPoint)
{
	local Vector ExistingPoint;

	// need to do this loop manually because unreal is too dumb to resolve the overload in Find
	foreach FocusPoints(ExistingPoint)
	{
		if(ExistingPoint == FocusPoint)
		{
			return;
		}
	}

	ValidateFocusPoint(FocusPoint);
	FocusPoints.AddItem(FocusPoint);
}

function AddFocusActor(Actor FocusActor)
{
	if(FocusActor != none && FocusActors.Find(FocusActor) == INDEX_NONE)
	{
		FocusActors.AddItem(FocusActor);
	}
}

protected function Vector GetCameraLookAt()
{
	return CachedLookAt;
}

function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local array<vector> OutFocusLocations;
	local TFocusPoints FocusPoint;
	local int i;

	GetFocusPointsInternal(OutFocusLocations, OnlyCutDownForActors);

	for (i = 0; i < OutFocusLocations.Length; i++)
	{
		FocusPoint.vFocusPoint = OutFocusLocations[i];
		FocusPoint.vCameraLocation = FocusPoint.vFocusPoint - (Vector(GetCameraLocationAndOrientation().Rotation) * 9999.0f);
		OutFocusPoints.AddItem(FocusPoint);
	}
}

private function ValidateFocusPoint(out vector OutFocusPoint)
{
	local XComLevelVolume LevelVolume;

	LevelVolume = `XWORLD.Volume;
	if(!LevelVolume.EncompassesPoint(OutFocusPoint))
	{
		`RedscreenOnce("Midpoint camera has been given bad points to look at. Clamping, but talk to David B. if the callstack doesn't "
			$ "make the offending code obvious.\n" $ GetScriptTrace());
		OutFocusPoint = vect(0, 0, 0);
	}
}

private function GetFocusPointsInternal(out array<vector> OutFocusPoints, bool OnlyFocusActors)
{
	local Actor FocusActor;
	local XGUnit FocusUnit;
	local Vector FocusPoint;

	if(FocusActors.Length == 0 || !OnlyFocusActors)
	{
		OutFocusPoints = FocusPoints;
	}

	foreach FocusActors(FocusActor)
	{
		FocusUnit = XGUnit(FocusActor);
		if(FocusUnit != none)
		{
			// special case actors to include their head and their feet
			FocusPoint = FocusUnit.GetPawn().GetHeadLocation();
			ValidateFocusPoint(FocusPoint);
			OutFocusPoints.AddItem(FocusPoint);

			FocusPoint = FocusUnit.GetPawn().GetFeetLocation();
			ValidateFocusPoint(FocusPoint);
			OutFocusPoints.AddItem(FocusPoint);
		}
		else
		{
			FocusPoint = FocusActor.Location;
			ValidateFocusPoint(FocusPoint);
			OutFocusPoints.AddItem(FocusPoint);
		}
	}

	if(OutFocusPoints.Length == 0)
	{
		`RedscreenOnce("Somebody pushed a midpoint camera without specifying anything to look at! Looking at the origin.");
		FocusPoint = vect(0, 0, 0);
		OutFocusPoints.AddItem(FocusPoint);
	}
}

function YawCamera(float Degrees)
{
	super.YawCamera(Degrees);

	StartingRotationForZoom = CurrentRotation;
	StartingZoom = CurrentZoom;
	RecomputeLookatPointAndZoom();
}

private function float GetFloorZOfHighestFocusPoint(const out array<Vector> AllFocusPoints)
{
	local XCom3DCursor Cursor;
	local Vector FocusPoint;
	local int HighestFloor;
	local int Floor;

	Cursor = `CURSOR;

	foreach AllFocusPoints(FocusPoint)
	{
		Floor = Cursor.WorldZToFloor(FocusPoint);
		HighestFloor = Max(HighestFloor, Floor);
	}

	return Cursor.GetFloorMinZ(HighestFloor);
}

/// <summary>
/// Updates the lookat point. Since this is fairly expensive to compute, we only do it when needed
/// and then return the cached result on further calls to GetCameraLookAt().
/// </summary>
protected function RecomputeLookatPointAndZoom()
{
	local TPOV CameraPosition;
	local float FramingFOV;
	local Vector CameraNormal;
	local Vector GroundPlaneCameraNormal;
	local Vector FrustumTopVector;
	local Vector FrustumBottomVector;
	local Vector CenterPoint;
	local array<Vector> AllFocusPoints; // raw focus points as well as unit focus points

	local Vector FocusPoint;
	local Vector PointNearestToCamera;
	local Vector PointFurthestFromCamera;
	local float NearestScalarProjection;
	local float FurthestScalarProjection;
	local float ScalarProjection;

	local Vector FrustumIntersect;
	local float Ratio;

	// Explanation of what is going here (in case the math is hard to understand).
	// Since we know the direction the camera is facing in, we can compute the top and 
	// bottom planes of it's frustum. For proper framing, we want these planes to intersect
	// with the nearest and farthest lookat points. If you think about this in reverse, we can
	// now say that the place where these two planes intersect is where the camera should go.
	// So once we've calculated the desired angles for the top and bottom frustum planes, we 
	// overlay them on the lookat points and find where they intersect. The camera goes there.
	// After that, we just pull it back along it's normal (facing direction) until every point
	// lies cleanly within the frustum

	// get the camera normal
	CameraNormal = Vector(TargetRotation);

	// This algorithm will fit the frustum exactly, so we want to shrink the FOV a bit so there is some framing.
	FramingFOV = TargetFOV * FramingFOVPercentage;

	// now extract frustum vectors
	ExtractCameraFrustumVectors(CameraNormal, FramingFOV, FrustumTopVector, FrustumBottomVector);

	// get the nearest and furthest points along the camera's direction of view
	NearestScalarProjection = 100000;
	FurthestScalarProjection = -100000;

	GetFocusPointsInternal(AllFocusPoints, false);
	foreach AllFocusPoints(FocusPoint)
	{
		ScalarProjection = CameraNormal dot FocusPoint;
		
		if(ScalarProjection < NearestScalarProjection)
		{
			NearestScalarProjection = ScalarProjection;
			PointNearestToCamera = FocusPoint;
		}
		
		if(ScalarProjection > FurthestScalarProjection)
		{
			FurthestScalarProjection = ScalarProjection;
			PointFurthestFromCamera = FocusPoint;
		}
	}

	// get the world space average of all the focus points
	CenterPoint = ComputeCenterPoint(AllFocusPoints);

	// project the nearest and furthest points along the ground plane camera vector, so they are in line with the center point
	GroundPlaneCameraNormal = CameraNormal;
	GroundPlaneCameraNormal.Z = 0;
	GroundPlaneCameraNormal = Normal(GroundPlaneCameraNormal);
	PointNearestToCamera = CenterPoint + ProjectVectorOnto(PointNearestToCamera - CenterPoint, GroundPlaneCameraNormal);
	PointFurthestFromCamera = CenterPoint + ProjectVectorOnto(PointFurthestFromCamera - CenterPoint, GroundPlaneCameraNormal);

	// find the intersection point of the frustum vectors when they originate from our nearest and furthest focus points
	FrustumIntersect = LineIntersection(PointNearestToCamera, 
										PointNearestToCamera - FrustumBottomVector, 
										PointFurthestFromCamera, 
										PointFurthestFromCamera - FrustumTopVector);

	// debug stuff to help with seeing how these things relate
// 	`Battle.DrawDebugSphere(PointNearestToCamera, 20, 20, 255, 255, 255);
// 	`Battle.DrawDebugSphere(PointFurthestFromCamera, 20, 20, 255, 0, 0);
// 	`Battle.DrawDebugLine(PointNearestToCamera, PointNearestToCamera - FrustumBottomVector * 1000, 255, 255, 255);
// 	`Battle.DrawDebugLine(PointFurthestFromCamera, PointFurthestFromCamera - FrustumTopVector * 1000, 255, 0, 0);
// 	`Battle.DrawDebugSphere(FrustumIntersect, 20, 20, 0, 255, 0);

	// now that we have our camera location, pull it back along the normal until all points lie within the frustum
	CameraPosition.Location = FrustumIntersect;
	CameraPosition.Rotation = TargetRotation;
	CameraPosition.FOV = FramingFOV;

	PullbackCameraToContainPoints(CameraPosition, AllFocusPoints);

	// find the intersect of the camera ray and the desired look-at ground plane height
	CachedLookAt.Z = GetFloorZOfHighestFocusPoint(AllFocusPoints);
	Ratio = (CameraPosition.Location.Z - CachedLookAt.Z) / -CameraNormal.Z;
	CachedLookAt.X = (CameraNormal.X * Ratio) + CameraPosition.Location.X;
	CachedLookAt.Y = (CameraNormal.Y * Ratio) + CameraPosition.Location.Y;

	// adjust the zoom if needed so we can frame the entire scene.
	// determine how much zoom we will need to get the camera from it's current distance
	// from the lookat point to the desired distance from the lookat point
	TargetZoom = (VSize(CachedLookAt - CameraPosition.Location) - DistanceFromCursor) / ZoomedDistanceFromCursor;
}

// this is not a full solution. It does not handle degenerative cases, but due to the way the
// midpoint camera works this isn't a problem. 
// It also doesn't care if the lines don't actually intersect in 3space, it just assumes there they will pass very closely together.
// Lines are V1 to V2, V3 to V4. 
// Solution adapted from http://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
private static native function Vector LineIntersection(Vector V1, Vector V2, Vector V3, Vector V4);

/// <summary>
/// Computes vectors that are coplanar with the camera normal and run along the surface of the top and bottom
/// planes of the given frustum.
/// </summary>
private static function ExtractCameraFrustumVectors(Vector CameraNormal, float InFOV, out Vector FrustumTopVector, out Vector FrustumBottomVector)
{
	local float FrustumHalfWidth; 
	local float FrustumHalfHeight; // Distance from the camera normal to the top and bottom planes 1 unit along the camera normal 
	local Vector2D AspectCorrection;
	local Vector CameraUp; // vector that defines the up/down axis of the frustum space 
	local Vector CameraRight; // vector that defines the left/right axis of the frustum space

	AspectCorrection = class'XComCamera'.static.GetAspectCorrectionScript();

	// compute our frustum half height one unit from the camera location
	FrustumHalfWidth = tan((InFOV * DegToRad * 0.5) / AspectCorrection.X); // half width for t = 1 along the camera normal ray
	FrustumHalfHeight = tan((InFOV * DegToRad * 0.5) / AspectCorrection.Y); // half height for t = 1 along the camera normal ray

	// compute the camera orientation vectors. We can pretend roll doesn't exist, since the lookat cameras
	// generally don't. Also we ignore aspect. Since almost all monitors are wider than they are tall, this simply
	// results in extra padding on the sides of the frustum.
	CameraRight = vect(0, 0, 1) cross CameraNormal; 
	CameraUp = CameraNormal cross CameraRight;

	// scale to the frustum halfheight. No need to normalize first since the contruction vectors were also normalized.
	CameraRight = CameraRight * FrustumHalfWidth;
	CameraUp = CameraUp * FrustumHalfHeight;
	
	FrustumTopVector = Normal(CameraNormal + CameraUp);
	FrustumBottomVector = Normal(CameraNormal - CameraUp);
}

/// <summary>
/// Computes the center point of all focus points.
/// </summary>
private native function Vector ComputeCenterPoint(const out array<Vector> AllFocusPoints);

/// <summary>
/// Adjusts CameraPosition by pulling it back until the frustum contains the given points
/// </summary>
private native function PullbackCameraToContainPoints(out TPOV CameraPosition, const out array<Vector> Points);

/// <summary>
/// Returns the t value such that PointOnRay + RayDirection * t = PointOnPlane.
/// Both normals are assumed to be actually normalized. If not, the output of this function
/// is undefined.
/// </summary>
private native function float GetPlaneRayIntersectionTValue(const out Plane FrustumPlane, const out Vector PointOnRay, const out Vector RayDirection);

defaultproperties
{
	Priority=eCameraPriority_LookAt
	OnlyCutDownForActors=false
	FirstActivation=true
}
