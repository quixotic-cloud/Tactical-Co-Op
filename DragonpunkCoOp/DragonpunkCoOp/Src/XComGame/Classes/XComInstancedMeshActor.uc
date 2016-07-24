//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComInstancedMeshActor.uc
//  AUTHOR:  Marc Giordano  --  03/24/2010
//  PURPOSE: Represents a static mesh that can be instanced multiple times. All instances
//           will be rendered in a single draw call.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComInstancedMeshActor extends XComLevelActor
		native(Level)
		hidecategories(StaticMeshActor);

cpptext
{
	virtual void PostLoad();

	/**
	* Sets InstanceStartCullDistance and InstanceEndCullDistance.
	*/
	virtual void SetInstanceCullDistances(INT Mode, FLOAT EndCullDistance);
};

var() const editconst InstancedStaticMeshComponent InstancedMeshComponent;

native function UpdateMeshInstances();

defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_Actor'
		HiddenGame=TRUE
		AlwaysLoadOnClient=FALSE
		AlwaysLoadOnServer=FALSE
		Translation=(X=0,Y=0,Z=64)
	End Object
	Components.Add(Sprite)

	Begin Object Class=InstancedStaticMeshComponent Name=InstancedMeshComponent0
		CastShadow=false
		BlockNonZeroExtent=false
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=false
	End object
	InstancedMeshComponent=InstancedMeshComponent0
	Components.Add(InstancedMeshComponent0)
}

