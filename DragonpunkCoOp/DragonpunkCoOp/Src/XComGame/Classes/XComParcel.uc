//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComParcel.uc    
//  AUTHOR:  Casey O'Toole  --  4/9/2013
//  PURPOSE: Parcels, streamed into Plots
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParcel extends Actor
	  placeable
	  native(Core)
	  dependson(XComParcelManager);

const MAX_PARCEL_ENTRANCES = 8;

// Mesh references for editor visualization
var() StaticMeshComponent ParcelMesh; // (visible only in EDITOR).
var() StaticMeshComponent ParcelNorthFacingMesh; // (visible only in EDITOR).
var() StaticMeshComponent ParcelEastFacingMesh; // (visible only in EDITOR).
var() StaticMeshComponent ParcelSouthFacingMesh; // (visible only in EDITOR).
var() StaticMeshComponent ParcelWestFacingMesh; // (visible only in EDITOR).

// size data
var() int SizeX;
var() int SizeY;

// Entrance and facing data
var() bool bFacingNorth;
var() bool bFacingEast;
var() bool bFacingSouth;
var() bool bFacingWest;

//Should only be used while generating a map. Do not assume it is valid outside that process
var ParcelDefinition ParcelDef;

//  __0___1__
// |         |
// 7         2
// |         |
// 6         3
// |__5___4__|

//  __0__
// |     |
// 7     2
// |     |
// 6     3
// |__4__|

//  __0__
// |     |
// 6     2
// |__4__|

var() bool bHasEntranceN1; // Has N1 Entrance
var() bool bHasEntranceN2; // Has N2 Entrance
var() bool bHasEntranceE1; // Has E1 Entrance
var() bool bHasEntranceE2; // Has E2 Entrance
var() bool bHasEntranceS1; // Has S1 Entrance
var() bool bHasEntranceS2; // Has S2 Entrance
var() bool bHasEntranceW1; // Has W1 Entrance
var() bool bHasEntranceW2; // Has W2 Entrance

var XComParcelEntrance arrEntrances[MAX_PARCEL_ENTRANCES];
var EParcelFacingType eFacing;    // The direction the parcel should must match facing

// Zone and layer data
var() array<string> arrForceZoneTypes;  // Array of zones that are possible for the parcel
var array<string> arrRequiredLayers;

// Objective and spawning data
var() bool CanBeObjectiveParcel;

var private array<XComLevelActor> SpawnedEntrances;

function EParcelSizeType GetSizeType()
{
	if (SizeX == class'XComParcelManager'.const.SMALLEST_PARCEL_SIZE*2 && SizeY == class'XComParcelManager'.const.SMALLEST_PARCEL_SIZE*2)
	{
		return eParcelSizeType_Large;
	}
	else if (SizeX == class'XComParcelManager'.const.SMALLEST_PARCEL_SIZE && SizeY == class'XComParcelManager'.const.SMALLEST_PARCEL_SIZE*2)
	{
		return eParcelSizeType_Medium;
	}
	else
	{
		return eParcelSizeType_Small;
	}
}

function CleanupSpawnedEntrances()
{
	local XComLevelActor Entrance;

	foreach SpawnedEntrances(Entrance)
	{
		Entrance.Destroy();
	}

	SpawnedEntrances.Length = 0;
}

event PreBeginPlay()
{
	local Rotator r;
	local float ToDegrees;
	ToDegrees = 90.0f/16384.0f;
	r = Rotation;
	r.Yaw = abs(r.Yaw);

	// Convert all rotations to be either 0 or 90 degrees
	if (r.Yaw*ToDegrees > 135 && r.Yaw*ToDegrees < 225)
	{
		r.Yaw = 0;
	}
	else if (r.Yaw*ToDegrees < 45 || r.Yaw*ToDegrees > 315)
	{
		r.Yaw = 0;
	}
	else
	{
		r.Yaw = 16384;
	}

	SetRotation(r);

	super.PreBeginPlay();
}

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PostLoad();
	virtual void PostScriptDestroyed();
	virtual void PostEditMove(UBOOL bFinished);

	void UpdateEditorFacingMesh();
}

native function ResetDefaultEntrances();

function SpawnEntranceActor(EParcelEntranceType eEntrance, bool bOn, bool bUseEmptyClosedEntrances, array<EntranceDefinition> arrDefinitions)
{
	local XComParcelEntrance Entrance;
	local EntranceDefinition SelectedDefinition;
	local Rotator SpawnRotation;
	local XComLevelActor SpawnedActor;

	Entrance = arrEntrances[eEntrance];
	if(Entrance == none)
	{
		return; // no entrance at this location
	}

	if (!bOn && bUseEmptyClosedEntrances)
	{
		// no need to spawn a closed entrance if the plot type doesn't use them
		return;
	}

	// get a random entrance definition that matches.
	arrDefinitions.RandomizeOrder();
	foreach arrDefinitions(SelectedDefinition)
	{
		if(SelectedDefinition.bIsClosed != bOn && SelectedDefinition.eLength == Entrance.eLength)
		{
			break;
		}
	}

	// create the entrance actor
	if(SelectedDefinition.kArchetype == none)
	{
		`Redscreen("Entrance archetype " $ SelectedDefinition.kArchetype $ " could not be loaded.");
	}
	else
	{
		SpawnRotation = Entrance.Rotation;
		SpawnRotation.Yaw -= DegToUnrRot * 90;
		SpawnedActor = Spawn(class'XComLevelActor', self,, Entrance.Location + Entrance.vOffset, SpawnRotation, SelectedDefinition.kArchetype, true);
	
		if(SpawnedActor != none)
		{
			SpawnedEntrances.AddItem(SpawnedActor);
		}
	}
}

function FixupEntrances(bool bUseEmptyClosedEntrances, array<EntranceDefinition> arrDefinitions)
{
	SpawnEntranceActor(EParcelEntranceType_N1, bHasEntranceN1 && ParcelDef.bHasEntranceN1, bUseEmptyClosedEntrances, arrDefinitions);
	SpawnEntranceActor(EParcelEntranceType_N2, bHasEntranceN2 && ParcelDef.bHasEntranceN2, bUseEmptyClosedEntrances, arrDefinitions);

	SpawnEntranceActor(EParcelEntranceType_E1, bHasEntranceE1 && ParcelDef.bHasEntranceE1, bUseEmptyClosedEntrances, arrDefinitions);
	SpawnEntranceActor(EParcelEntranceType_E2, bHasEntranceE2 && ParcelDef.bHasEntranceE2, bUseEmptyClosedEntrances, arrDefinitions);
		
	SpawnEntranceActor(EParcelEntranceType_S1, bHasEntranceS1 && ParcelDef.bHasEntranceS1, bUseEmptyClosedEntrances, arrDefinitions);
	SpawnEntranceActor(EParcelEntranceType_S2, bHasEntranceS2 && ParcelDef.bHasEntranceS2, bUseEmptyClosedEntrances, arrDefinitions);
				
	SpawnEntranceActor(EParcelEntranceType_W1, bHasEntranceW1 && ParcelDef.bHasEntranceW1, bUseEmptyClosedEntrances, arrDefinitions);
	SpawnEntranceActor(EParcelEntranceType_W2, bHasEntranceW2 && ParcelDef.bHasEntranceW2, bUseEmptyClosedEntrances, arrDefinitions);
}

function RestoreEntrances(StoredMapData_Parcel StoredParcelData)
{
	local StoredMapData_Entrance StoredEntranceData;
	local XComLevelActor EntranceArchetype;
	local XComLevelActor SpawnedEntrance;

	if(SpawnedEntrances.Length > 0)
	{
		`Redscreen("Attempting to restore entrances when entrances already exist. This should only happen once during parcel loading!");
	}

	foreach StoredParcelData.SpawnedEntrances(StoredEntranceData)
	{
		EntranceArchetype = XComLevelActor(DynamicLoadObject(StoredEntranceData.SpawnedArchetype, class'XComLevelActor'));

		if(EntranceArchetype != none)
		{
			SpawnedEntrance = Spawn(class'XComLevelActor', self,, StoredEntranceData.Location, StoredEntranceData.Rotation, EntranceArchetype, true);
			SpawnedEntrances.AddItem(SpawnedEntrance);
		}
		else
		{
			`Redscreen("Archetype " $ StoredEntranceData.SpawnedArchetype $ " not found when restoring entrance. Entrance will not be restored!");
		}
	}
}

function SaveEntrances(out StoredMapData_Parcel StoredParcelData)
{
	local StoredMapData_Entrance EntranceData;
	local XComLevelActor SpawnedEntrance;

	StoredParcelData.SpawnedEntrances.Length = 0;

	// save off the entrances
	foreach SpawnedEntrances(SpawnedEntrance)
	{
		EntranceData.Location = SpawnedEntrance.Location;
		EntranceData.Rotation = SpawnedEntrance.Rotation;
		EntranceData.SpawnedArchetype = class'Object'.static.PathName(SpawnedEntrance.ObjectArchetype);

		StoredParcelData.SpawnedEntrances.AddItem(EntranceData);
	}
}

//------------------------------------------------------------------------------------------------
function GetTileBounds( out IntPoint kMin, out IntPoint kMax )
{	
	local TTile Temp;
	local Vector BoundsMin;
	local Vector BoundsMax;

	BoundsMin = ParcelMesh.Bounds.Origin - ParcelMesh.Bounds.BoxExtent;
	Temp = `XWORLD.GetTileCoordinatesFromPosition(BoundsMin);
	kMin.X = Temp.X;
	kMin.Y = Temp.Y;

	BoundsMax = ParcelMesh.Bounds.Origin + ParcelMesh.Bounds.BoxExtent;
	Temp = `XWORLD.GetTileCoordinatesFromPosition(BoundsMax);
	kMax.X = Temp.X;
	kMax.Y = Temp.Y;
}
//------------------------------------------------------------------------------------------------

native function bool IsInsideBounds( const out vector vPoint ) const;

//------------------------------------------------------------------------------------------------

event Destroyed()
{
	local XComLevelActor Entrance;

	super.Destroyed();

	foreach SpawnedEntrances(Entrance)
	{
		Entrance.Destroy();
	}
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=true     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object

	//LightEnvironment=MyLightEnvironment;
	Components.Add(MyLightEnvironment)

	Begin Object Class=StaticMeshComponent Name=ParcelStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'Parcel.Meshes.Parcel'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
	End Object

	ParcelMesh=ParcelStaticMeshComponent;
	Components.Add(ParcelStaticMeshComponent)

	Begin Object Class=StaticMeshComponent Name=ParcelNorthFacingStaticMeshComponent
		HiddenGame=true
		HiddenEditor=true
		StaticMesh=StaticMesh'UI_Waypoint.Meshes.WaypointArrowB'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
		Scale3D=(X=0.5,Y=0.5,Z=0.5)
		Translation=(X=0,Y=0,Z=96)
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
	End Object

	Begin Object Class=StaticMeshComponent Name=ParcelEastFacingStaticMeshComponent
		HiddenGame=true
		HiddenEditor=true
		StaticMesh=StaticMesh'UI_Waypoint.Meshes.WaypointArrowB'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
		Scale3D=(X=0.5,Y=0.5,Z=0.5)
		Translation=(X=0,Y=0,Z=96)
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
	End Object

	Begin Object Class=StaticMeshComponent Name=ParcelSouthFacingStaticMeshComponent
		HiddenGame=true
		HiddenEditor=true
		StaticMesh=StaticMesh'UI_Waypoint.Meshes.WaypointArrowB'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
		Scale3D=(X=0.5,Y=0.5,Z=0.5)
		Translation=(X=0,Y=0,Z=96)
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
	End Object

	Begin Object Class=StaticMeshComponent Name=ParcelWestFacingStaticMeshComponent
		HiddenGame=true
		HiddenEditor=true
		StaticMesh=StaticMesh'UI_Waypoint.Meshes.WaypointArrowB'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
		Scale3D=(X=0.5,Y=0.5,Z=0.5)
		Translation=(X=0,Y=0,Z=96)
		BlockZeroExtent = FALSE
		BlockNonZeroExtent = FALSE
	End Object

	ParcelNorthFacingMesh=ParcelNorthFacingStaticMeshComponent;
	ParcelEastFacingMesh=ParcelEastFacingStaticMeshComponent;
	ParcelSouthFacingMesh=ParcelSouthFacingStaticMeshComponent;
	ParcelWestFacingMesh=ParcelWestFacingStaticMeshComponent;
	Components.Add(ParcelNorthFacingStaticMeshComponent)
	Components.Add(ParcelEastFacingStaticMeshComponent)
	Components.Add(ParcelSouthFacingStaticMeshComponent)
	Components.Add(ParcelWestFacingStaticMeshComponent)

	bCollideWhenPlacing=false
	bCollideActors=false
	bStaticCollision=true
	bCanStepUpOn=false

	bEdShouldSnap=true

	SizeX=SMALLEST_PARCEL_SIZE
	SizeY=SMALLEST_PARCEL_SIZE

	DrawScale3D=(X=16,Y=16,Z=1)

	CanBeObjectiveParcel=true
}