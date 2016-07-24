//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItemAnim3D
//  AUTHOR:  Joe Weinhoffer -- 07/2015
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItemAnim3D extends Actor implements(IMouseInteractionInterface);

var UIStrategyMapItem MapItem;
var StateObjectReference GeoscapeEntityRef;

var Vector AnimVelocity;			// Velocity used to drive animations
var Vector AnimAcceleration;		// Acceleration used to drive animations

// Mesh Component (3D UI)
const NUM_TILES = 3;
const ROOT_TILE = 1;
var SkeletalMeshComponent SkeletalMeshs[NUM_TILES];

// ctor
simulated function UIStrategyMapItemAnim3D InitMapItemAnim3D()
{
	local int i;
	local SkeletalMeshComponent curItem;

	for (i = 0; i < NUM_TILES; ++i)
	{
		curItem = new(self) class'SkeletalMeshComponent';
		curItem.bUpdateSkelWhenNotRendered = false;
		SkeletalMeshs[i] = curItem;
		AttachComponent(curItem);
	}

	return self;
}

function SetUpAnimMapItem(SkeletalMesh UIMesh, AnimTree UIAnimTree, AnimSet UIAnimSet)
{
	local int i;
	for (i = 0; i < NUM_TILES; ++i)
	{
		SkeletalMeshs[i].SetSkeletalMesh(UIMesh);
		SkeletalMeshs[i].SetAnimTreeTemplate(UIAnimTree);
		SkeletalMeshs[i].AnimSets.AddItem(UIAnimSet);
		SkeletalMeshs[i].UpdateAnimations();

		SetUpAnimNodes(i);
	}
}

function SetUpAnimNodes(int MeshIndex)
{
	// Should be implemented in subclasses to set up access to specific animations or animation nodes
}

function SetMeshTranslation(vector loc)
{
	local int i;
	local vector offsetVec;

	for (i = 0; i < NUM_TILES; ++i)
	{
		offsetVec = `EARTH.OffsetTranslationForTile(i, Location + loc);
		SkeletalMeshs[i].SetTranslation(offsetVec - Location);
	}
}

function SetScale3D(vector scale)
{
	local int i;
	for (i = 0; i < NUM_TILES; ++i)
	{
		SkeletalMeshs[i].SetScale3D(scale);
	}
}

function vector GetScale3D()
{
	return SkeletalMeshs[ROOT_TILE].Scale3D;
}

function SetMeshRotation(Rotator rot)
{
	local int i;
	for (i = 0; i < NUM_TILES; ++i)
	{
		SkeletalMeshs[i].SetRotation(rot);
	}
}

function Rotator GetMeshRotation()
{
	return SkeletalMeshs[ROOT_TILE].Rotation;
}

function SetMeshHidden(bool hidden)
{
	local int i;
	for (i = 0; i < NUM_TILES; ++i)
	{
		SkeletalMeshs[i].SetHidden(hidden);
	}
}

function Vector GetAnimVelocityInputs()
{
	return AnimVelocity;
}

function SetAnimVelocityInputs(Vector NewVelocity)
{
	AnimVelocity = NewVelocity;
}

function Vector GetAnimAccelerationInputs()
{
	return AnimAcceleration;
}

function SetAnimAccelerationInputs(Vector NewAcceleration)
{
	AnimAcceleration = NewAcceleration;
}

function SetHoverMaterialValue(float Value)
{
	local MaterialInstanceConstant MICMat;
	local int i;

	for( i = 0; i < NUM_TILES; ++i)
	{
		MICMat = MaterialInstanceConstant(SkeletalMeshs[i].GetMaterial(0));
		if(MICMat != none)
			MICMat.SetScalarParameterValue('Hover', Value);
	}
}

//Handle the incoming mouse event
function bool OnMouseEvent(int cmd, int Actionmask, optional Vector MouseWorldOrigin, optional Vector MouseWorldDirection, optional Vector HitLocation)
{
	local array<string> args;

	args.Length = 0;
	if (MapItem != none)
	{
		MapItem.OnMouseEvent(cmd, args);
		return true;
	}

	return false;
}

//--------------------------------------------------------------------------------------- 
DefaultProperties
{
}