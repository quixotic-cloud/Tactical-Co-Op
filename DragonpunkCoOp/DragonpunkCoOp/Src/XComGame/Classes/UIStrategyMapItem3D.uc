//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem3D
//  AUTHOR:  Mark Nauta -- 04/2015
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem3D extends Actor implements(IMouseInteractionInterface);

var UIStrategyMapItem MapItem;
var StateObjectReference GeoscapeEntityRef;

// Mesh Component (3D UI)
const NUM_TILES = 3;
const ROOT_TILE = 1;
var StaticMeshComponent OverworldMeshs[NUM_TILES];

// ctor
simulated function UIStrategyMapItem3D InitMapItem3D()
{
	local int i;
	local StaticMeshComponent curItem;

	for( i = 0; i < NUM_TILES; ++i)
	{
		curItem = new(self) class'StaticMeshComponent';
		OverworldMeshs[i] = curItem;
		AttachComponent(curItem);
	}

	return self;
}

function SetStaticMesh(StaticMesh UIMesh)
{
	local int i;
	for( i = 0; i < NUM_TILES; ++i)
	{
		OverworldMeshs[i].SetStaticMesh(UIMesh);
	}
}

function SetMeshTranslation(vector loc)
{
	local int i;
	local vector offsetVec;

	for( i = 0; i < NUM_TILES; ++i)
	{
		offsetVec = `EARTH.OffsetTranslationForTile(i, Location + loc);
		OverworldMeshs[i].SetTranslation(offsetVec - Location);
	}
}

function SetScale3D(vector scale)
{
	local int i;
	for( i = 0; i < NUM_TILES; ++i)
	{
		OverworldMeshs[i].SetScale3D(scale);
	}
}

function vector GetScale3D()
{
	return OverworldMeshs[ROOT_TILE].Scale3D;
}

function SetMeshRotation(Rotator rot)
{
	local int i;
	for( i = 0; i < NUM_TILES; ++i)
	{
		OverworldMeshs[i].SetRotation(rot);
	}
}

function Rotator GetMeshRotation()
{
	return OverworldMeshs[ROOT_TILE].Rotation;
}

function SetMeshHidden(bool hidden)
{
	local int i;
	for( i = 0; i < NUM_TILES; ++i)
	{
		OverworldMeshs[i].SetHidden(hidden);
	}
}

function SetHoverMaterialValue(float Value)
{
	local MaterialInstanceConstant MICMat;
	local int i;

	for( i = 0; i < NUM_TILES; ++i)
	{
		MICMat = MaterialInstanceConstant(OverworldMeshs[i].GetMaterial(0));
		if(MICMat != none)
			MICMat.SetScalarParameterValue('Hover', Value);
	}
}

function MaterialInterface GetMeshMaterial(int idx)
{
	return OverworldMeshs[ROOT_TILE].GetMaterial(idx);
}

function SetMeshMaterial(int matIdx, MaterialInterface mat)
{
	local int i;
	for( i = 0; i < NUM_TILES; ++i)
	{
		OverworldMeshs[i].SetMaterial(matIdx, mat);
	}
}

//Handle the incoming mouse event
function bool OnMouseEvent(int cmd, int Actionmask, optional Vector MouseWorldOrigin, optional Vector MouseWorldDirection, optional Vector HitLocation)
{
	local array<string> args;

	args.Length = 0;
	if(MapItem != none)
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