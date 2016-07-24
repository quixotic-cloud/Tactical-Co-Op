//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComAlienPod.uc    
//  AUTHOR:  Alex Cheng  --  9/23/2009
//  PURPOSE: XComAlienPods, clustered alien spawn locations with a purpose
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComAlienPod extends Actor
	  native(AI)
	  placeable
	  hidecategories(Display, Attachment, Collision, Physics, Mobile, Debug, Actor)
	  dependson(XComWorldData);

// Saved data
var array<XGUnit> m_arrAlien; // List of aliens spawned on the Pod.
// Editor variables
var(XCAP_Mesh) StaticMeshComponent PodMesh; // Mesh of aliens surrounding center (visible only in EDITOR).
var editoronly MaterialInterface kHighlight;

cpptext
{
	virtual void Spawned();
	virtual void PostLoad();
}

//------------------------------------------------------------------------------------------------
simulated function Init()
{
	CenterLocationOnTile();
	SetVisible(false);
}

//------------------------------------------------------------------------------------------------
function CenterLocationOnTile()
{
	local vector vCenter;
	local TTile tPos;

	tPos = `XWORLD.GetTileCoordinatesFromPosition(Location);
	vCenter = `XWORLD.GetPositionFromTileCoordinates(tPos);
	vCenter.Z = `XWORLD.GetFloorZForPosition(vCenter, true);
	SetLocation(vCenter);
}

//------------------------------------------------------------------------------------------------
defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=AlienPodStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'VignetteConstructionPack.Meshes.ASE_CryssalidPod'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
	End Object

	PodMesh=AlienPodStaticMeshComponent;
	Components.Add(AlienPodStaticMeshComponent)

	bCollideWhenPlacing=false
	bCollideActors=false
	bStaticCollision=true
	bCanStepUpOn=false

	kHighlight=MaterialInterface'FX_Visibility.Materials.MPar_PodGlow';

	bEdShouldSnap=True
}
