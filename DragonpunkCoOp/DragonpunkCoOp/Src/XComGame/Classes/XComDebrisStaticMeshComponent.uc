//---------------------------------------------------------------------------------------
//  FILE:    XComDebrisStaticMeshComponent.uc
//  AUTHOR:  Jeremy Shopf  --  7/25/2011
//  PURPOSE: A static mesh component that has appropriate defaults for debris meshes
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComDebrisStaticMeshComponent extends StaticMeshComponent
	native(Destruction);

defaultproperties
{
	// PrimitiveComponent stuff
	bAcceptsDecals=false;
	bUsePrecomputedShadows=true;
	bSelfShadowOnly=false;
	CastShadow=false;
	LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=FALSE,CompositeDynamic=FALSE,bInitialized=TRUE)
	bCutoutMask=false;
}