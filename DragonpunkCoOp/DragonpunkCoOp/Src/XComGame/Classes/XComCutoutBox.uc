//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComCutoutBox.cpp
//  AUTHOR:  Elliot Pace
//  PURPOSE: This is a box that moves around with the cursor, encapsulating the cutout.  This way
//           we can keep track of all cutout actors and unflag them as necessary.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComCutoutBox extends StaticMeshActor 
	dependson(XComBuildingVisPOI)
	native;

enum ECardinalAxis
{
	POS_X,
	NEG_X,
	POS_Y,
	NEG_Y
};

var transient ECardinalAxis  TraceDirections[2];

var transient native array<XComBuildingVolume> TouchedBuildingVolumes;

var transient bool m_bEnabled;
var transient vector OwnerPosition;

native function UpdateBoxDimensions(vector CameraLocation, float MaxWidth);

cpptext
{
	void ClampBoxExtentsToBuilding( AVolume *InVolume, FVector OutCorners[4], FLOAT& MaxZ );
}

simulated event UpdateCutoutBox(vector InPosition, vector CameraDirection, float MaxWidth)
{
	local TPOV CameraPOV;
	
	if( XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()) == none )
		return;	

	m_bEnabled = true;
	OwnerPosition = InPosition;

	CameraPOV = `CAMERASTACK.GetCameraLocationAndOrientation();

	UpdateBoxDimensions(CameraPOV.Location, MaxWidth);
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local XComBuildingVolume BuildingVolume;

	super.Touch(Other,OtherComp,Hitlocation,HitNormal);

	BuildingVolume = XComBuildingVolume(Other);
	if( BuildingVolume != none && TouchedBuildingVolumes.Find(BuildingVolume) == INDEX_NONE )
	{
		TouchedBuildingVolumes.AddItem(BuildingVolume);
	}
}

event UnTouch( Actor Other )
{
	local XComBuildingVolume BuildingVolume;

	super.UnTouch(Other);

	BuildingVolume = XComBuildingVolume(Other);
	if( BuildingVolume != none )
	{
		TouchedBuildingVolumes.RemoveItem(Other);
	}
}

defaultproperties
{
	bStatic=FALSE
	bWorldGeometry=FALSE
	bMovable=TRUE
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'FX_Visibility.Meshes.ASE_UnitCube'
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		CollideActors=TRUE
		BlockActors=FALSE
		BlockZeroExtent=FALSE
		BlockNonZeroExtent=FALSE
		BlockRigidBody=FALSE
		AlwaysCheckCollision=TRUE
		CanBlockCamera=FALSE
		Translation=(X=0.0,Y=0.0,Z=0.0)
	End Object
	CollisionType=COLLIDE_TouchAll
	bCollideActors=TRUE
	bBlockActors=FALSE
	BlockRigidBody=FALSE
	bHidden=TRUE
	bNoEncroachCheck=true;

	TickGroup=TG_PostAsyncWork
}
