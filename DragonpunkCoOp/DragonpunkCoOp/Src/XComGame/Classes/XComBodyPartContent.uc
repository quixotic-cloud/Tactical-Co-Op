//---------------------------------------------------------------------------------------
//  FILE:    XComBodyPartContent.uc
//  AUTHOR:  Ryan McFall  --  5/28/2013
//  PURPOSE: Generalized container object for use with the soldier customization system. Holds
//           a skeletal mesh reference that will be attached to a character pawn actor.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComBodyPartContent extends Actor
	native(Unit)
	hidecategories(Movement,Display,Attachment,Actor,Collision,Physics,Debug,Object,Advanced);

var() SkeletalMesh SkeletalMesh;
var() bool OverrideMaterialOnlyForMSAA <ToolTip = "Only use the override material if MSAA is enabled. Mainly used for Dithered Translucency.">;
var() MaterialInterface OverrideMaterial <ToolTip = "Allows a material override to specified for this body part. The material will be assigned to the skeletal mesh when the part is attached">;
var() array<SkeletalMesh> FallbackSkeletalMeshes <ToolTip = "Used in a context specific way by different body parts. Hair, for instance, uses these as 'hat hair'">;
var() PhysicsAsset UsePhysicsAsset<ToolTip = "Specifies that this body part should be an attached physics prop.">;
var() array<PhysicsAsset> FallbackPhysicsAssets<ToolTip = "Physics assets to use in conjunction with FallbackSkeletalMeshes">;
var() name SocketName<ToolTip = "Specifies the socket this prop should attach to, if it is a physics prop.">;
var() MorphTargetSet UseMorphTargetSet<ToolTip = "If set, attaches a morph target set to the skeletal mesh for this body part">;
var() bool bHideFacialHair<ToolTip = "Indicates whether this body part should hide 3d model facial hair when it is used">;
var() bool bHideWithUnderlay<ToolTip = "Set to TRUE to indicate that this part should NOT show when a character is wearing the underlay">;

native static function bool ShouldUseOverrideMaterial();