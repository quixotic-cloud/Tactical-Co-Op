// stores information about the bounds this xcom pawn is inside/outside of

class XComPawnIndoorOutdoorInfo extends Object
	native(Level)
	dependson(XComFloorVolume);

// Building Volumes contain a list of floor volumes and info about each floor.
// Floor Volumes contain a reference to the Building Volume they are inside.

// The list of floor volumes that the pawn is currently inside of.
var array<XComFloorVolume> CurrentFloorVolumes;

// NOTE: If you're inside an XComFloorVolume, you MUST also
// be inside a BuildingVolume, else it's an error in the map
// and things will get VERY confused.
//
// The reverse is not true, however. You can be in a building volume
// but not in a floor volume, in which case you are OUTSIDE.
var XComBuildingVolume CurrentBuildingVolume;
var XComBuildingVolume PreviousBuildingVolume;

var protected int iCachedCurrentFloorNumber;
var protected int iCachedLowestFloorNumber;
var protected int iCachedBestMatchingFloorNumber;
var protected int iCachedLowestOccupiedFloorNumber;
var float fLowestFloorHalfHeight;
var float fLowestFloorLocationZ;
var float fLowestFloorCursorUpperZFactor;
var EFloorVolumeType eLowestFloorVolumeType;
var bool  m_bShouldRevealFloors; // Cache whether or not all floor volumes we're in want us to reveal the building
var bool  m_bForceRaycast; // When indoor/outdoor status changes, we want a raycast for building hiding to occur the same frame

var IXComBuildingVisInterface BuildingVisActor;

function ParentTouchedOrUntouched(Actor A, bool bTouched)
{
	local XComFloorVolume FloorVolume;
	local int iIndex;

	FloorVolume = XComFloorVolume(A);

	// If we're not touching a floor volume OR 
	//     we're touching a floor volume but aren't inside it, early-out
	if (FloorVolume == none )
		return;

	if (bTouched)
	{
		iIndex = CurrentFloorVolumes.Find(FloorVolume);
		if (iIndex == INDEX_NONE)
			CurrentFloorVolumes.AddItem(FloorVolume);
	}
	else
	{	
		iIndex = CurrentFloorVolumes.Find(FloorVolume);
		if (iIndex == INDEX_NONE)
			`warn("Asked to remove a floor volume from our list but we're NOT inside it? -Dom");
		else
		{
			CurrentFloorVolumes.Remove(iIndex, 1);
		}
	}

	CheckForFloorVolumeEvents();
	return;
	
}

private function CacheBestMatchingFloor()
{
	local XComFloorVolume kFloorVolume, kClosestFloorVolume;
	local XComPawn kPawn;
	local XComBuildingVisPOI kPOI;
	local BoxSphereBounds kBounds;
	local float fPawnDistToFloorVolume, fSmallestDistToFloorVolume, fHeightToUse;

	kPawn = XComPawn(BuildingVisActor);
	kPOI = XComBuildingVisPOI(BuildingVisActor);

	if( kPawn != none )
	{
		fHeightToUse = kPawn.Location.Z - kPawn.GetCollisionHeight();
	}
	else if( kPOI != none )
	{
		fHeightToUse = kPOI.Location.Z;
	}

	if (kPawn != none || kPOI != none )
	{
		fPawnDistToFloorVolume = 0;
		foreach CurrentFloorVolumes(kFloorVolume)
		{
			kBounds = kFloorVolume.BrushComponent.Bounds;
			
			fPawnDistToFloorVolume = fHeightToUse - kBounds.Origin.Z;
			if (fSmallestDistToFloorVolume == 0 ||
				fPawnDistToFloorVolume < fSmallestDistToFloorVolume)
			{
				kClosestFloorVolume = kFloorVolume;
				fSmallestDistToFloorVolume = fPawnDistToFloorVolume;
			}
		}

		if (kClosestFloorVolume != none)
			iCachedBestMatchingFloorNumber = kClosestFloorVolume.FloorNumber;
	}
	else
		iCachedBestMatchingFloorNumber = iCachedLowestFloorNumber;
	
}

function bool IsOnRoof()
{
	// In most cases, we are on the roof if inside a building volume and on the top floor, of a
	// building with more than one floor.  This should not be trusted for gameplay, but only for minor features
	// like the XComWeatherControl.
	if (CurrentBuildingVolume == none)
		return false;
	return (iCachedCurrentFloorNumber == CurrentBuildingVolume.Floors.Length && CurrentBuildingVolume.Floors.Length > 1);
}

private function CacheLowestOccupiedFloor()
{
	if (CurrentBuildingVolume != none)
	{
		iCachedLowestOccupiedFloorNumber = CurrentBuildingVolume.GetLowestOccupiedFloor() + 1;
	}
	else
		iCachedLowestOccupiedFloorNumber = 9999;
}

function bool JustLeftBuildingWithinABuilding()
{
	// MHU - Written for easy debugging, please don't change.
	local bool bResult;

	bResult = CurrentBuildingVolume != none && !CurrentBuildingVolume.m_bIsInternalBuilding && 
			  PreviousBuildingVolume != none && PreviousBuildingVolume.m_bIsInternalBuilding;

	if (bResult)
		return true;
	else
		return false;
}

function bool IsSamePreviousAndCurrentBuilding()
{
	return (CurrentBuildingVolume != none &&
			PreviousBuildingVolume == CurrentBuildingVolume);
}

function bool JustEnteredBuildingWithinABuilding()
{
	// MHU - Written for easy debugging, please don't change.
	local bool bResult;

	bResult =  (PreviousBuildingVolume != none && !PreviousBuildingVolume.m_bIsInternalBuilding &&
			   CurrentBuildingVolume != none && CurrentBuildingVolume.m_bIsInternalBuilding);

	if (bResult)
		return true;
	else
		return false;
}

function bool JustEnteredBuilding()
{
	return (PreviousBuildingVolume == none && CurrentBuildingVolume != none);
}

function CheckForFloorVolumeEvents()
{
	local int i;
	local XComFloorVolume FloorVolume;	
	
	local bool bContainsFloorVolumeWithInternalBuilding;

	PreviousBuildingVolume = CurrentBuildingVolume;
	CurrentBuildingVolume = none;
	iCachedCurrentFloorNumber = 0;
	iCachedLowestFloorNumber = 0;
	eLowestFloorVolumeType = eFloor_MAX;

	foreach CurrentFloorVolumes(FloorVolume)
	{
		if (FloorVolume.CachedBuildingVolume != none && FloorVolume.CachedBuildingVolume.m_bIsInternalBuilding)
		{
			bContainsFloorVolumeWithInternalBuilding = true;
			break;
		}
	}

	// MHU - Begin caching important data for the floor that we're in. 
	//       This list is processing in reverse order
	//       as the last floor volume is the latest floor volume touched.
	for (i=CurrentFloorVolumes.Length - 1; i >= 0; i--)
	{
		FloorVolume = CurrentFloorVolumes[i];

		// MHU - Constrain to process internal buildings if required.
		if (bContainsFloorVolumeWithInternalBuilding)
		{
			if (!FloorVolume.CachedBuildingVolume.m_bIsInternalBuilding)
				continue;
		}
        
		// MHU - We only process floor volumes associated w/ one building volume at a time.
		if (CurrentBuildingVolume != none && 
			FloorVolume.CachedBuildingVolume != CurrentBuildingVolume)
		{
			continue;			
		}
		
		// MHU - CurrentBuildingVolume should belong to the latest floor volume touched.
		CurrentBuildingVolume = CurrentFloorVolumes[i].CachedBuildingVolume;

		// MHU - 1. Caching highest floor we are overlapping
		if (FloorVolume.FloorNumber > iCachedCurrentFloorNumber)
			iCachedCurrentFloorNumber = FloorVolume.FloorNumber;

		// MHU - 2. Caching lowest floor we are overlapping
		if (FloorVolume.FloorNumber < iCachedLowestFloorNumber || iCachedLowestFloorNumber == 0)
		{
			iCachedLowestFloorNumber = FloorVolume.FloorNumber;
			fLowestFloorHalfHeight = FloorVolume.BrushComponent.Bounds.BoxExtent.Z;
			fLowestFloorLocationZ = FloorVolume.BrushComponent.Bounds.Origin.Z;
			fLowestFloorCursorUpperZFactor = FloorVolume.m_FloorCursorUpperZFactor;
			eLowestFloorVolumeType = FloorVolume.m_FloorVolumeType;
		}

		//DrawDebugBox(FloorVolume.BrushComponent.Bounds.Origin,vect(5,5,5),0,255,0,false);
		//DrawDebugBox(FloorVolume.Location,vect(5,5,5),255,0,0,false);
	}

	// MHU - 3. Cache best matching floor number.
	CacheBestMatchingFloor();

	// MHU - 4. Caching lowest occupied floor (1 is the 1st floor, 2 is the 2nd floor, etc)
	CacheLowestOccupiedFloor();
}

// returns true if any volumes we are in have the "counts as indoors" flag set
simulated native function bool IsInside();

// returns true if any volumes we are in have the "inside of ufo" flag set
simulated native function bool IsInsideUfo();

// returns true if any volumes we are in have the "inside of ufo" flag set
simulated native function bool IsInsideDropship();

// zero means outside / not in a Floor volume
// 1 means first floor
// 2 means 2nd floor / etc
// this is based on the field 'Floor' in IndoorOutdoorVolume
function int GetCurrentFloorNumber()
{
	return iCachedCurrentFloorNumber;
}

function int GetLowestFloorNumber()
{
	return iCachedLowestFloorNumber;
}

function float GetLowestFloorHalfHeight()
{
	return fLowestFloorHalfHeight;
}

function float GetLowestFloorLocationZ()
{
	return fLowestFloorLocationZ;
}

function float GetLowestFloorCursorUpperZFactor()
{
	return fLowestFloorCursorUpperZFactor;
}

function EFloorVolumeType GetLowestFloorVolumeType()
{
	return eLowestFloorVolumeType;
}

function float GetLowestOccupiedFloorNumber()
{
	return iCachedLowestOccupiedFloorNumber;
}

function native XComBuildingVolume GetLastBuildingVolume();

defaultproperties
{
	iCachedCurrentFloorNumber=0 // outside

	iCachedLowestFloorNumber=0
	fLowestFloorHalfHeight=0
	fLowestFloorLocationZ=0
	fLowestFloorCursorUpperZFactor=0
	eLowestFloorVolumeType=eFloor_Default;
	m_bShouldRevealFloors=true;
	m_bForceRaycast=false;
}