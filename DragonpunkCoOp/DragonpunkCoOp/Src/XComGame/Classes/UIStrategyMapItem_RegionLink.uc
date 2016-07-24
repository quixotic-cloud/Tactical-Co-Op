//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_RegionLink
//  AUTHOR:  Mark Nauta
//  PURPOSE: This file represents a region link on the strategy map
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_RegionLink extends UIStrategyMapItem;

var string CurrentMaterialPath;
var vector CurrentScale;
var vector CurrentLocation;


simulated function UIStrategyMapItem InitMapItem(out XComGameState_GeoscapeEntity Entity)
{
	super.InitMapItem(Entity);
	InitLinkMesh();
	UpdateLinkMesh();

	return self;
}

function UpdateVisuals()
{
	super.UpdateVisuals();
	UpdateLinkMesh();
}

function UpdateLinkMesh()
{
	local MaterialInstanceConstant NewMaterial, NewMIC;
	local Object MaterialObject;
	local XComGameStateHistory History;
	local XComGameState_RegionLink RegionLinkState;
	local XComGameState_WorldRegion RegionStateA, RegionStateB;
	local vector NewScale, NewLocation;
	local string DesiredPath;
	local int idx;
	local float LinkDirection;

	History = `XCOMHISTORY;

	RegionLinkState = XComGameState_RegionLink(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	RegionStateA = XComGameState_WorldRegion(History.GetGameStateForObjectID(RegionLinkState.LinkedRegions[0].ObjectID));
	RegionStateB = XComGameState_WorldRegion(History.GetGameStateForObjectID(RegionLinkState.LinkedRegions[1].ObjectID));
	LinkDirection = 0.0;
	NewScale = MapItem3D.GetScale3D();
	NewLocation = RegionLinkState.GetWorldLocation();

	if(RegionStateA.ResistanceLevel == eResLevel_Unlocked && RegionStateB.HaveMadeContact())
	{
		DesiredPath = class'X2StrategyGameRulesetDataStructures'.default.RegionLinkUnlockedPath;
		NewScale.Y = 1.0;
		LinkDirection = 1.0;
	}
	else if(RegionStateB.ResistanceLevel == eResLevel_Unlocked && RegionStateA.HaveMadeContact())
	{
		DesiredPath = class'X2StrategyGameRulesetDataStructures'.default.RegionLinkUnlockedPath;
		NewScale.Y = 1.0;
	}
	else if (RegionLinkState.IsOnGPOrAlienFacilityPath())
	{
		DesiredPath = class'X2StrategyGameRulesetDataStructures'.default.RegionLinkDashedPath;
		NewScale.Y = 1.0;

		if (RegionStateB.HaveMadeContact())
			LinkDirection = 1.0;
	}
	else
	{
		DesiredPath = class'X2StrategyGameRulesetDataStructures'.default.RegionLinkLockedPath;
		NewScale.Y = 1.0;
	}

	if(DesiredPath != CurrentMaterialPath || NewScale != CurrentScale || NewLocation != CurrentLocation)
	{
		MapItem3D.SetScale3D(NewScale);
		SetLoc(RegionLinkState.Get2DLocation());
		SetLocation(NewLocation);
		MapItem3D.SetLocation(NewLocation);
		CurrentScale = NewScale;
		CurrentLocation = NewLocation;
		CurrentMaterialPath = DesiredPath;
		
		MaterialObject = `CONTENT.RequestGameArchetype(DesiredPath);

		if(MaterialObject != none && MaterialObject.IsA('MaterialInstanceConstant'))
		{
			NewMaterial = MaterialInstanceConstant(MaterialObject);
			NewMIC = new class'MaterialInstanceConstant';
			NewMIC.SetParent(NewMaterial);
			NewMIC.SetScalarParameterValue('RegionLinkLength', RegionLinkState.GetLinkDistance());
			NewMIC.SetScalarParameterValue('ReverseTrace', LinkDirection);
			MapItem3D.SetMeshMaterial(0, NewMIC);
			
			for(idx = 0; idx < MapItem3D.NUM_TILES; idx++)
			{
				MapItem3D.ReattachComponent(MapItem3D.OverworldMeshs[idx]);
			}
		}
	}
}

function InitLinkMesh()
{
	local XComGameState_RegionLink RegionLinkState;
	local Vector Translation;

	RegionLinkState = XComGameState_RegionLink(`XCOMHISTORY.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	Translation = RegionLinkState.GetWorldLocation() - Location;
	Translation.Z = 0.2f;

	MapItem3D.SetMeshTranslation(Translation);
	MapItem3D.SetScale3D(RegionLinkState.GetMeshScale());
	MapItem3D.SetMeshRotation(RegionLinkState.GetMeshRotator());
}

// Handle mouse hover special behavior
simulated function OnMouseIn()
{
}

// Clear mouse hover special behavior
simulated function OnMouseOut()
{
}

defaultproperties
{
	bIsNavigable = false;
}
