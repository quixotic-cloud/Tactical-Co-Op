class XComBuildingVolume extends Volume
	placeable
	dependson(VisGroupActor)
	native(Level);

struct native ExternalMeshHidingGroup
{
	var() string GroupName <DisplayName="Name"|ToolTip="Name of this mesh group for organization purposes">;
	var() bool bEnabled;
	var() array<Actor> m_aActors <DisplayName="Actors"|ToolTip="Actors (XComDestructibleLevelActors, XComLevelActors, XComFracLevelActors) that will go into scanline mode when in this current floor">;
	structdefaultproperties
	{
		bEnabled=true
	}
};

struct native FloorActorInfo
{
	var Actor   ResidentActor;
	var byte    CutdownFloor;

	structcpptext
	{
		FFloorActorInfo( AActor* InResidentActor, INT InCutdownFloor ) : ResidentActor(InResidentActor), CutdownFloor(InCutdownFloor) {}

		UBOOL operator==(const FFloorActorInfo &Other) const
		{
			return ResidentActor == Other.ResidentActor;
		}
	}
};

struct native Floor
{
	var float fCenterZ;
	var float fExtent;
	var() init array<XComFloorVolume> FloorVolumes<ToolTip=The XComFloor volumes that mark up this floor. NOTE: you have to hit CTRL+C here.>;
	var() array<string> ExternalMeshGroupNames <DisplayName="External Mesh Groups">;
	// Indices into XComBuildingVolume.ExternalMeshGroups that this Floor uses.
	var array<int> ExternalMeshGroupIndices;
	// Array of all actors from the Touching array.
	// - Appended with m_aInclusionActors.
	// - Then filtered by type and m_aExclusionActors.
	var init array<FloorActorInfo> m_aCachedActors;
	// Emitters have no collision, so this is in a separate array.
	var init array<Emitter> m_aCachedEmitters;
	// Array of particle system components (not placed particles) that need to be hidden with the floor
	var init array<ParticleSystemComponent> m_uCachedParticleComponents;

	var init array<AmbientSound> m_aCachedSounds;

	structcpptext
	{
		void ProcessVisibilityChange( INT nFloorIdx, INT nFloorToRevealIdx, UBOOL bHide ,FLOAT fCutdownHeight, FLOAT fCutoutHeight );
	}
};

var() init  array<Floor> Floors;
var() editoronly init  array<VisGroupActor> VisGroupsToHideWhenOccluding;
// VisGroupsToHideWhenOccluding translated to vis group indices for runtime
var   init  array<int> VisGroupIdxToHideWhenOccluding;
var()       array<ExternalMeshHidingGroup> ExternalMeshGroups;
var() bool IsUfo<ToolTip=Whether this building is a UFO, plays spooky music>;
var() bool IsDropShip<ToolTip=Whether this building is a drop ship>;
var() bool IsInside<ToolTip=Only turn this off if this is a special building vol (ie. encompasses an ENTIRE level). Otherwise, cursor/buildingshader can be adversely affected.>;
var() bool m_bAllowBuildingReveal<DisplayName=Allow Building Reveal?|ToolTip=Whether to allow any floor volume in this building volume to be used for building revealing>;
var() bool m_bIsInternalBuilding<ToolTip=Defines whether or not this defines a building within a building>;

/* True when a Floor Volume in thie building is marked as an Empty Floor (i.e. a room that span multiple floors.) */
var bool m_bHasMultipleFloorRoom;

var transient bool IsHot; // jboswell: taken from XGBuilding

// True if we're doing debug voodoo with the command WhatsOnMyFloors/etc
// this should NEVER be on for final release.
var bool bDebuggingThisBuilding;

var protected transient int LastShownLowerFloor;
var protected transient int LastShownUpperFloor;

var bool bOccludingCursor;
var bool bPrevOccludingCursor;

// The last vis. related heights set on the building
var native transient float fCurrentCutdownHeight;
var native transient float fCurrentCutoutHeight;


var XGLevelNativeBase m_kLevel;

var array<X2EnvMapCaptureActor> InternalCaptureActors;

native function CacheFloorCenterAndExtent();
native function CacheBuildingVolumeInChildrenFloorVolumes();
native function RebuildCachedActors();
native function RebuildCachedEnvCaptures();
native function CacheStreamedInActors();

cpptext
{
	virtual void PreSave();
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PreEditChange(UProperty* PropertyAboutToChange);
	virtual void PostLoad();
	virtual void PostDuplicate();

	UBOOL IsActorInFloor( const FFloorActorInfo& InActor, INT InFloor );
	INT  RemoveActorFromFloorsAbove( const FFloorActorInfo& InActorInfo, INT InFloor );
	void RemoveActorFromFloor( const FFloorActorInfo& InActor, INT InFloor );
	void CacheExternalMeshGroups();
	//void RebuildCachedActors();
	void UpdateFloorVolumeReferences(bool bSetToNull);
	INT  DetermineFloorFromZ( FLOAT InWorldZ, FLOAT& OutMaxZ, FLOAT& OutMinZ );
	UBOOL AllFloorsAreRevealed();

	static void PostLoadBlueprint( AXComBlueprint *Blueprint, FFloorActorInfo *Info = NULL );
}

simulated native function ChangeExternalMeshHidingGroups(out Floor FloorToChange, bool bHide);
simulated native function bool GetCenterHeightAndExtent(int iFloorIndex, out float fCenter, out float fExtent);

simulated native function CutoutAllVisGroups(bool bCutout);

simulated function vector2d GetBounds()
{
	return vect2d( BrushComponent.Bounds.BoxExtent.X, BrushComponent.Bounds.BoxExtent.Y );
}

// MHU - SCRIPT DEBUGGING only, used to track reveal bugs - reroute ShowFloor calls through this function.
simulated event ShowFloor_ScriptDebug( int iFloor)
{
  // Uncomment the below log or the switch statement to debug floor...
  //`log("ShowFloor"@self@iFloor);

	ShowFloor(iFloor);
}
simulated native function ShowFloor( int iFloor);
simulated native function ShowFloors( int iLowerFloor, int iUpperFloor );

// MHU - SCRIPT DEBUGGING only, used to track reveal bugs - reroute HideFloor calls through this function.
simulated event HideFloors_ScriptDebug( bool bUseFade )
{
   //`log("HideFloors"@self@bUseFade);
	HideFloors(bUseFade);
}
simulated native function HideFloors(bool bUseFade);

// MHU - Please note that floor volume reveals should 
//       utilize pawn reveal logic in OnXComPawnUpdateBuildingVisibility.
simulated native function RevealAllFloors ();

simulated native function HideAllFloorsThenRevealFirstFloor ();

// MHU - TODO - Nativize below function post XGUnit & Pawn unification.
//       Returns a range from 0 - (Floors.Length - 1).
simulated function int GetLowestOccupiedFloor()
{
	local Floor kFloor;
	local XComFloorVolume kFloorVolume;

	local int iFloorOccupied;
	local int i;

	iFloorOccupied = Floors.Length - 1; // MHU - Top floor occupied is the highest valid floor.

	for (i = 0; i < Floors.Length; i++)
	{
		kFloor = Floors[i];
		foreach kFloor.FloorVolumes(kFloorVolume)
		{
			if( kFloorVolume.ContainsValidUnit() && kFloorVolume.m_bUseForBuildingReveal )
			{
				return i;
			}
		}
	}

	return iFloorOccupied;
}

simulated function int GetHighestOccupiedFloor()
{
	local Floor kFloor;
	local XComFloorVolume kFloorVolume;

	local int iFloorOccupied;
	local int i;

	iFloorOccupied = Floors.Length - 1; 

	for (i = iFloorOccupied; i >= 0; i--)
	{
		kFloor = Floors[i];
		foreach kFloor.FloorVolumes(kFloorVolume)
		{
			if( kFloorVolume.ContainsValidUnit() && kFloorVolume.m_bUseForBuildingReveal )
			{
				return i;
			}
		}
	}

	return iFloorOccupied;
}

simulated function float GetLowestHeightForCurrentFloor()
{
	local Floor kFloor;
	local float fLowestHeight, fHeight;
	local XComFloorVolume kFloorVolume;
	local BoxSphereBounds kBounds;

	// LastShownFloor starts at one
	kFloor = Floors[LastShownLowerFloor-1];

	fLowestHeight = 99999.0;

	foreach kFloor.FloorVolumes(kFloorVolume)
	{
		kBounds = kFloorVolume.BrushComponent.Bounds;
		fHeight = kBounds.Origin.Z-kBounds.BoxExtent.Z;

		if( fHeight < fLowestHeight )
			fLowestHeight = fHeight;
	}

	return fLowestHeight;
}

simulated function int GetLastShownUpperFloor()
{
	return LastShownUpperFloor;
}

defaultproperties
{
	IsInside=true
	bOccludingCursor=false
	bPrevOccludingCursor=false
	LastShownUpperFloor=666 // A number of floors we will never expect to have
	LastShownLowerFloor=666
	BrushColor=(R=7,G=255,B=82,A=255)
	m_bAllowBuildingReveal=true
	bColored=TRUE
	m_bHasMultipleFloorRoom=FALSE

	// never set this here, only in the console command
	bDebuggingThisBuilding=FALSE
}

