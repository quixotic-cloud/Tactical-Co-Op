//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComEarth extends Actor
	config(GameCore)
	native;

const NUM_TILES = 3;
const ROOT_TILE = 1;

// after beginning a zoom change on the geoscape, the amount of time, in seconds, for it to complete
var const config float fZoomInterpolationDuration;

var LevelStreaming Levels[NUM_TILES];

var private vector2D v2ViewLoc;

var private vector2D v2SavedViewLoc;
var private float fSavedZoom;

var float fCurvature;
var float fCameraPitchScalar;
var float fCurrentZoom;
var float fTargetZoom;
var float fZoomInterpolationSpeed;
var private float fViewYMin;
var private float fViewYMax;

var float fZoomedInCurvature;  // The stored value because fZoomedInCurvature will get set to zero when zoomed out
var float fZoomedInPitchScalar; // The stored value because fCameraPitchScalar will get set to zero when zoomed out

var Actor PlacedActor; // HACK!  Hack to get curvature set on Avenger

var XComLevelActor OverworldActor;
var array<MaterialInstanceConstant> OverworldMaterials;
var float LocalSeconds; //Local time, in seconds

var float UnrRotPerSecond;				 //Time of day on the map is controlled by rotating an actor. This figure converts from seconds to unreal rotation units.
var float StartOffset;

var float Width;
var float Height;
var float XOffset;

var float ViewDistance;

function Init()
{
}

function InitTiles()
{
	local vector vLoc;
	local rotator UseRotation;

	// extra maps for wrapping
	//  0 Real_Level 1

	vLoc.X = XOffset - GetWidth();
	vLoc.Y = GetHeight();
	Levels[0] = `MAPS.AddStreamingMap("OverWorld_Root_Dev", vLoc, , true);

	vLoc.X = XOffset;
	Levels[1] = `MAPS.AddStreamingMap("OverWorld_Root_Dev", vLoc, , true);

	vLoc.X = XOffset + GetWidth();
	Levels[2] = `MAPS.AddStreamingMap("OverWorld_Root_Dev", vLoc, , true);

	`XENGINE.AddStreamingTextureSlaveLocation(vLoc, UseRotation, 999999.0f, false);

	UnrRotPerSecond = 0.75851851851851851851851851851852f; //65536 (unreal units per 360 deg rotation) / 86400 (seconds in a day)
	StartOffset = 50000; //The strategy clock is on GMT, so start with midnight in the appropriate spot... tweaked a bit to account for art
}

function BindOverworldMaterials()
{
	local int Index;
	local XComLevelActor CandidateActor;

	foreach WorldInfo.AllActors(class'XComLevelActor', CandidateActor)
	{
		if(CandidateActor.Tag == 'OverworldMesh')
		{
			OverworldActor = CandidateActor;
			for(Index = 0; Index < OverworldActor.StaticMeshComponent.Materials.Length; ++Index)
			{
				OverworldMaterials.AddItem(MaterialInstanceConstant(OverworldActor.StaticMeshComponent.GetMaterial(Index)));
			}
		}
	}
}

function Show(bool bShow)
{
	local PlayerController PC;
	local int i;

	foreach WorldInfo.AllControllers(class'PlayerController', PC)
	{
		for( i = 0; i < NUM_TILES; ++i)
		{
			PC.ClientUpdateLevelStreamingStatus(Levels[i].PackageName, true, bShow, true );
		}
	}
}

native function SetCurvature(float fAmt, optional bool bSetZoomedInCurvature=true);
native function SetCurvatureOnActor(Actor inActor, float fAmt);

native function SetWholeWorldView(bool bWholeWorld);

function PlaceActorOnEarth(Actor inActor, vector2D inCoords, optional int inYaw, optional int inPitch)
{
	local rotator LocalRot;
	local vector vLoc;

	LocalRot.Yaw = InYaw;

	vLoc = ConvertEarthToWorld(inCoords);
		
	inActor.SetLocation( vLoc );
	inActor.SetRotation( LocalRot );
	
	if (PlacedActor == none)
	{
		PlacedActor = inActor;
		SetCurvatureOnActor(inActor, fZoomedInCurvature);
	}
}


function vector OffsetTranslationForTile(int tile, vector loc)
{
	local vector vLoc;
	local int col;

	if (tile == ROOT_TILE)
		return loc;
	
	col = tile - 1;

	vLoc = loc;
	vLoc.x += GetWidth() * col;
	return vLoc;
}

function vector ConvertEarthToWorldByTile(int tile, vector2D inCoords)
{
	local vector vLoc;
	local int col;
	
	col = tile - 1;

	inCoords.X = WrapF(inCoords.X, 0.0f, 1.0f);
	inCoords.Y = WrapF(inCoords.Y, 0.0f, 1.0f);

	vLoc.x = (inCoords.X*GetWidth() + XOffset);	
	vLoc.y = (inCoords.Y*GetHeight());
	vLoc.z = 0.1f;

	vLoc.x += GetWidth() * col;

	return vLoc;
}

static function vector ConvertEarthToWorld(vector2D inCoords, optional bool bWrap=true)
{
	local vector vLoc;

	// wrap earthspace coordinates
	if(bWrap)
	{
		inCoords.X = WrapF(inCoords.X, 0.0f, 1.0f);
		inCoords.Y = WrapF(inCoords.Y, 0.0f, 1.0f);
	}

	// Convert to World coords
	vLoc.x = (inCoords.X*GetWidth() + default.XOffset);	
	vLoc.y = (inCoords.Y*GetHeight());
	vLoc.z = 0.1f;

	return vLoc;
}

static function vector2D ConvertWorldToUV(vector inCoords)
{
	local vector2D vLoc;

	vLoc.x = inCoords.X / 384.0f;
	vLoc.y = (inCoords.Y + 21.0f) / 234.0f;

	vLoc.X = WrapF(vLoc.X, 0.0f, 1.0f);
	vLoc.Y = WrapF(vLoc.Y, 0.0f, 1.0f);

	return vLoc;
}

static function vector2D ConvertWorldToEarth(vector inCoords)
{
	local vector2D vLoc;

	// Convert to World coords
	vLoc.x = (inCoords.X - default.XOffset) / GetWidth();
	vLoc.y = (inCoords.Y / GetHeight());

	vLoc.X = WrapF(vLoc.X, 0.0f, 1.0f);
	vLoc.Y = WrapF(vLoc.Y, 0.0f, 1.0f);

	return vLoc;
}

// An obviously naive and incorrect function, but relies on the planar mapping of the world
function int ConvertEarthCoordsToMiles(float CoordSize)
{
	local int iMiles;

	iMiles = CoordSize * 24901;
	iMiles /= 2;

	return iMiles;
}

static function float GetWidth()
{
	return default.Width;
}

static function float GetHeight()
{
	return default.Height;
}

function vector2D GetViewLocation()
{
	return v2ViewLoc;
}

function MoveViewLocation(vector2D inDelta)
{
	v2ViewLoc.X += inDelta.X;
	v2ViewLoc.Y += inDelta.Y;

	v2ViewLoc.X = WrapF(v2ViewLoc.X, 0.0f, 1.0f);
	v2ViewLoc.Y = FClamp(v2ViewLoc.Y, fViewYMin, fViewYMax);
}

function SetViewLocation(vector2D inCoords)
{
	local Vector2D newViewLoc;

	newViewLoc.X = WrapF(inCoords.X, 0.0f, 1.0f);	
	newViewLoc.Y = FClamp(inCoords.Y, fViewYMin, fViewYMax);
	
	if (v2ViewLoc == newViewLoc)
		return;

	v2ViewLoc = newViewLoc;
}

function SaveViewLocation()
{
	v2SavedViewLoc = v2ViewLoc;
}

function SaveZoomLevel()
{
	fSavedZoom = fTargetZoom;
}

function RestoreSavedViewLocation()
{
	v2ViewLoc = v2SavedViewLoc;
}

function RestoreSavedZoomLevel()
{
	SetCurrentZoomLevel(fSavedZoom);
}

function vector GetWorldViewLocation()
{
	local vector vLoc;

	// Convert to World coords
	vLoc.x = WrapF(v2ViewLoc.X, 0.0f, 1.0f)*GetWidth() + XOffset;	
	vLoc.y = FClamp(v2ViewLoc.Y, fViewYMin, fViewYMax)*GetHeight();	
	vLoc.z = 0.1f;

	return vLoc;
}
	
function vector GetNearestWorldViewLocation(const out vector curLoc)
{
	local vector vLoc;
	local Vector2D nearestLoc;
	local Vector2D fromLoc;
	
	fromLoc.x = (curLoc.X - XOffset) / GetWidth();
	fromLoc.y = curLoc.X / GetHeight();

	nearestLoc = GetClosestWrappedCoordinate(fromLoc, v2ViewLoc);

	vLoc.x = nearestLoc.X*GetWidth() + XOffset;
	vLoc.y = FClamp(v2ViewLoc.Y, fViewYMin, fViewYMax)*GetHeight();	
	vLoc.z = 0.1f;

	return vLoc;
}


private function Vector2D GetClosestWrappedCoordinate(Vector2D v2Start, Vector2D v2End)
{
	local Vector2D v2LeftWrap, v2RightWrap;
	local float OrigDist, LeftDist, RightDist;

	// Get the wrapped coords
	v2LeftWrap = v2End;
	v2LeftWrap.X -= 1.0;
	v2RightWrap = v2End;
	v2RightWrap.X += 1.0;

	// Get distances
	OrigDist = V2DSize(v2End - v2Start);
	LeftDist = V2DSize(v2LeftWrap - v2Start);
	RightDist = V2DSize(v2RightWrap - v2Start);

	if(OrigDist <= LeftDist && OrigDist <= RightDist)
	{
		return v2End;
	}
	else if(LeftDist <= RightDist)
	{
		return v2LeftWrap;
	}
	else
	{
		return v2RightWrap;
	}
}


function SetTime(TDateTime DateTime)
{	
	local int Index;
	local float PitchValue;
	local Rotator LightRotation;
	local Vector LightVector;
	local LinearColor MaterialParamValue;	

	LocalSeconds = DateTime.m_fTime;	
	PitchValue = StartOffset + (LocalSeconds * UnrRotPerSecond * -1.0f);
	LightRotation.Yaw = int(195 * class'Object'.const.DegToUnrRot);
	LightVector = vector(LightRotation);
	LightRotation.Yaw = 0;
	LightRotation.Pitch = int(PitchValue);
	LightVector = LightVector << LightRotation;
	MaterialParamValue.R = LightVector.X;
	MaterialParamValue.G = LightVector.Y;
	MaterialParamValue.B = LightVector.Z;
	MaterialParamValue.A = 1.0;

	if(OverworldMaterials.Length == 0)
	{
		BindOverworldMaterials();
	}

	for(Index = 0; Index < OverworldMaterials.Length; ++Index)
	{
		OverworldMaterials[Index].SetVectorParameterValue('TOD_Vector', MaterialParamValue);
	}
}

function SetPitch(float fAmt)
{
   	fCameraPitchScalar = fAmt;
	fZoomedInPitchScalar = fAmt;
}

function float GetViewDistance()
{
	return ViewDistance * fCurrentZoom;
}

function float GetZoomLevel(float LocalViewDistance)
{
	return LocalViewDistance / ViewDistance;
}

function SetCurrentZoomLevel(float fZoom)
{
	//Put some limits on zoom so you can't zoom through the world or to infinity and beyond
	fTargetZoom = FClamp(fZoom, 0.60, 1.75);

	// determine the speed. Interpolation duration <= 0 disables interpolation, so if that is the case,
	// just set the zoom speed to 0 as well
	fZoomInterpolationSpeed = fZoomInterpolationDuration > 0.0f ? (abs(fTargetZoom - fCurrentZoom) * (1.0f / (fZoomInterpolationDuration))) : 0.0f;
}

function ApplyImmediateZoomOffset(float fZoomOffset)
{
	//Put some limits on zoom so you can't zoom through the world or to infinity and beyond
	fTargetZoom += fZoomOffset;
	fTargetZoom = FClamp(fTargetZoom, 0.60, 1.75);

	// No interpolation for 1:1 zooming operations; interpolation will be re-applied from setting on next
	// call of SetCurrentZoomLevel if switching to eg. Mouse Wheel
	fZoomInterpolationSpeed = 0.0f;
}

function simulated float ComputeYMin()
{	
	return 0.1784 * fCurrentZoom - 0.0353;
}

function simulated float ComputeYMax()
{
	return -0.223 * fCurrentZoom + 1.1148;
}

simulated event Tick(float DeltaTime)
{
	local float Delta;
	local float MinZoom;

	super.Tick(DeltaTime);

	// interpolate the camera zoom
	Delta = fTargetZoom - fCurrentZoom;
	if(Delta != 0)
	{
		// this will cause the zoom to fully interpolate whatever distance remained on the last
		// zoom tick in 2 seconds
		if(fZoomInterpolationSpeed > 0.0f)
		{
			fCurrentZoom += Sgn(Delta) * fMin(abs(Delta), DeltaTime * fZoomInterpolationSpeed);
		}
		else
		{
			// if no zoom speed, just snap to the target immediately
			fCurrentZoom = fTargetZoom;
		}

		MinZoom = 0.32f;
		fCameraPitchScalar = FClamp((MinZoom + fCurrentZoom) - 0.25f, 0.1f, 1.0f);
		fViewYMin = ComputeYMin();
		fViewYMax = ComputeYMax();
	}
}

defaultproperties
{
	fCurvature = 0.0f
	fZoomedInCurvature = 0.000003125f
	fCameraPitchScalar = 1.0f
	fZoomedInPitchScalar = 0.98f

	fSavedZoom = 0.0f;

	Width = 384
	Height = 192
	XOffset = 10000

	ViewDistance = 75
	fTargetZoom=1.0f
	fCurrentZoom=1.0f
	fZoomInterpolationSpeed=1.0f
	fViewYMin = 0.125f;
	fViewYMax = 0.875f;
}
