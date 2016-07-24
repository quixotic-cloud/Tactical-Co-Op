//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Actor_EvacZoneTarget.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Targeting visuals for the X2TargetingMethod_EvacZone targeting method
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2Actor_EvacZoneTarget extends StaticMeshActor 
	config(GameCore);

var const config string MeshPath, BadMeshPath;

var private StaticMesh ZoneMesh, BadMesh;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	ZoneMesh = StaticMesh(`CONTENT.RequestGameArchetype(default.MeshPath));
	`assert(ZoneMesh != none);	
	BadMesh = StaticMesh(`CONTENT.RequestGameArchetype(default.BadMeshPath));
	`assert(BadMesh != none);
}

simulated function ShowBadMesh()
{
	if (StaticMeshComponent.StaticMesh != BadMesh)
		StaticMeshComponent.SetStaticMesh(BadMesh);
}

simulated function ShowGoodMesh()
{
	if (StaticMeshComponent.StaticMesh != ZoneMesh)
		StaticMeshComponent.SetStaticMesh(ZoneMesh);
}

DefaultProperties
{
	Begin Object Name=StaticMeshComponent0
		bOwnerNoSee=FALSE
		CastShadow=FALSE
		CollideActors=FALSE
		BlockActors=FALSE
		BlockZeroExtent=FALSE
		BlockNonZeroExtent=FALSE
		BlockRigidBody=FALSE
		HiddenGame=FALSE
	End Object	

	bStatic=FALSE
	bWorldGeometry=FALSE
	bMovable=TRUE
}