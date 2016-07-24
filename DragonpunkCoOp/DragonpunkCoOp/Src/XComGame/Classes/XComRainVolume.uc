//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComRainVolume.uc
//  AUTHOR:  Jeremy Shopf -- 09/08/09
//  PURPOSE: Actor whose bounds are the volume in which rain can fall
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComRainVolume extends Actor
	hidecategories(Object)
	placeable;
	
DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		StaticMesh=StaticMesh'FX_Weather.cube_offset'
		HiddenGame=true
		bOwnerNoSee=false
		CastShadow=false
		Scale=640.0f
	End Object
	Components.Add(StaticMeshComponent0)

	bStatic=TRUE
	bNoDelete=TRUE
	bEdShouldSnap=TRUE
}
