//---------------------------------------------------------------------------------------
//  FILE:    X2WaypointStaticMeshComponent.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Static mesh that show hazards, waypoints, and other visual markup on paths
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2WaypointStaticMeshComponent extends X2FadingStaticMeshComponent
	native(Unit)
	config(GameCore);

struct native HazardMarkerDefinition
{
	var name HazardIconName;        // name of the icon mapping
	var int MaterialIconIndex;  // index into the material mic for the hazard icon that represents this hazard

	structcpptext
	{
		FHazardMarkerDefinition()
		{
			appMemzero(this, sizeof(FHazardMarkerDefinition));
		}

		FHazardMarkerDefinition(EEventParm)
		{
			appMemzero(this, sizeof(FHazardMarkerDefinition));
		}

		UBOOL operator==(FHazardMarkerDefinition const& Other)
		{
			return Other.HazardIconName == HazardIconName && Other.MaterialIconIndex == MaterialIconIndex;
		}
	}
};

enum WaypointIconStatus
{
	WaypointIconStatus_Off,
	WaypointIconStatus_Set,
	WaypointIconStatus_Unset
};

var private const config string WaypointStaticMeshName; // mesh used to display the waypoint
var private const config string WaypointFadeoutStaticMeshName; // mesh used to fadeout the waypoint

var private const config int NumHazardMarkerSlots; // how many icon slots are on the waypoint/hazard marker mesh?
var private const config array<name> IconSlotParameterNames; // maps icon slots to parameter names
var private const config name WaypointStatusParameterName; // maps the waypoint status to a parameter name

var private const config array<HazardMarkerDefinition> HazardMarkerDefinitions; // waypoint hazard material parameter info

var private WaypointIconStatus WaypointStatus;
var private array<int> VisibleIconsIndices;

// must be called immediately after construction
native function Init();

// Sets an icon specified in HazardMarkerDefinitions to be visible or not
native function SetHazardIconVisible(name IconName, bool Visible); 

// Hides all hazard icons previous set with SetHazardIconVisible
native function HideAllHazardIcons(); 

// Sets the visiblity status of the waypoint placement icon
native function SetWaypointIconVisible(WaypointIconStatus InWaypointStatus);

// call after modifying the icon list or waypoint icon to update all material parameters
native private function UpdateMaterialParameters();

defaultproperties
{
	bOwnerNoSee=FALSE
	CastShadow=FALSE
	BlockNonZeroExtent=false
	BlockZeroExtent=false
	BlockActors=false
	CollideActors=false

	AbsoluteTranslation=true
	AbsoluteRotation=true
	bTranslucentIgnoreFOW=true
	TranslucencySortPriority=1000
}

