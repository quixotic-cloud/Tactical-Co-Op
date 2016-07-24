//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComTacticalExit.uc    
//  AUTHOR:  Casey O'Toole  --  5/22/2013
//  PURPOSE: Level Exit 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComTacticalExit extends Actor
	  placeable;
	  //hidecategories(Display, Attachment, Collision, Physics, Advanced, Mobile, Debug);

var StaticMeshComponent StaticMesh;

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

	Begin Object Class=StaticMeshComponent Name=ExitStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'Parcel.Meshes.Parcel_Extraction' 
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		LightEnvironment=MyLightEnvironment
	End Object

	Components.Add(ExitStaticMeshComponent)
	StaticMesh = ExitStaticMeshComponent;

	bCollideWhenPlacing=false
	bCollideActors=true
	bStaticCollision=true
	bCanStepUpOn=false

	bEdShouldSnap=true

	Layer=Markup

	CollisionType=COLLIDE_TouchAllButWeapons

}