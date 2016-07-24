//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComParcelEntrance.uc    
//  AUTHOR:  Casey O'Toole  --  4/9/2013
//  PURPOSE: Parcel entrances (driveway, street entrance, or sidewalk if unused)
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComParcelEntrance extends Actor
	  native(Core)
	  dependson(XComParcelManager);
	  //hidecategories(Display, Attachment, Collision, Physics, Advanced, Mobile, Debug);

var() vector vOffset;

var() EEntranceLengthType eLength;

var StaticMeshComponent StaticMesh;

var StaticMesh EditorMeshx1;
var StaticMesh EditorMeshx2;
var StaticMesh EditorMeshx3;
var StaticMesh EditorMeshx4;
var StaticMesh EditorMeshx5;
var StaticMesh EditorMeshx6;

native function SetEditorMesh();

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
}

defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=false     // precomputed lighting is used until the static mesh is changed
		bCastShadows=false // there will be a static shadow so no need to cast a dynamic shadow
		bSynthesizeSHLight=false
		bSynthesizeDirectionalLight=true; // get rid of this later if we can
		bDynamic=true     // using a static light environment to save update time
		bForceNonCompositeDynamicLights=TRUE // needed since we are using a static light environment
		bUseBooleanEnvironmentShadowing=FALSE
		TickGroup=TG_DuringAsyncWork
	End Object
	Components.Add(MyLightEnvironment)

	Begin Object Class=StaticMeshComponent Name=EditorStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'Parcel.Meshes.DriveParcel_x1'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
	End Object
	StaticMesh=EditorStaticMeshComponent
	Components.Add(EditorStaticMeshComponent)

	DrawScale3D=(X=1,Y=1,Z=1)

	EditorMeshx1=StaticMesh'Parcel.Meshes.DriveParcel_x1'
	EditorMeshx2=StaticMesh'Parcel.Meshes.DriveParcel_x2'
	EditorMeshx3=StaticMesh'Parcel.Meshes.DriveParcel_x3'
	EditorMeshx4=StaticMesh'Parcel.Meshes.DriveParcel_x4'
	EditorMeshx5=StaticMesh'Parcel.Meshes.DriveParcel_x5'
	EditorMeshx6=StaticMesh'Parcel.Meshes.DriveParcel_x6'

	//bCollideWhenPlacing=false
	//bCollideActors=false
	//bStaticCollision=true
	//bCanStepUpOn=false
	bWorldGeometry=true
	bPathColliding=true
	bCanStepUpOn=true
	bCollideActors=true
	bBlockActors=true
	bLockLocation=true

	bEdShouldSnap=true

	vOffset=(X=0,Y=0,Z=-16)
}