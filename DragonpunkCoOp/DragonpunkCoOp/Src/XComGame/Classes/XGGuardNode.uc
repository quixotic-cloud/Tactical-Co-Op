//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGGuardNode.uc    
//  AUTHOR:  Alex Cheng  --  10/15/2013
//  PURPOSE: XGGuardNode:   Spawn point for parcel guards and objective guards.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XGGuardNode extends XComAlienPod
	  native(AI)
	  hidecategories(XCAP_Patrol, XComAlienPod, XCAP_AlienType, XCAP_Contingent, XCAP_Triggered, XCAP_Group, XCAP_Mesh)
	  placeable
	  implements(X2SpawnNode);

var() array<ObjectiveSpawnPossibility> arrObjectiveInteractableObjects<DisplayName=Objective Interactable Objects>;
var() bool bFillFirst<DisplayName=Fill First>;

var() bool m_bIsObjectiveGuard;
var   IntPoint m_kTileBoundsMin, m_kTileBoundsMax;
var   XComParcel m_kParcel; // assigned parcel, for parcel guards.
var   bool m_bBoundsSet;
var   vector m_vInitialLocation;

simulated function Init()
{
	// To do - determine if this is an objective guard.  HOW DO WE KNOW THIS?!?
	//local ObjectiveSpawnInfo kObjective;
	//kObjective = `TACTICALMISSIONMGR.GetObjectiveSpawnInfoByType(`TACTICALMISSIONMGR.ActiveMission.sType);
	//if (kObjective.

	m_vInitialLocation = Location;
	super.Init();
}

//------------------------------------------------------------------------------------------------
function InitParcel()
{
	// To do: set parcel.
	m_kParcel = `PARCELMGR.GetContainingParcel(Location);
}

//------------------------------------------------------------------------------------------------
// Specify tile boundary
function InitBounds()
{
	local int iSightRadiusTiles;
	// Define parcel guard bounds.
	if (!m_bIsObjectiveGuard)
	{
		if (m_kParcel == None)
			InitParcel();

		if (m_kParcel != None)
		{
			// Get parcel bounds.
			m_kParcel.GetTileBounds(m_kTileBoundsMin, m_kTileBoundsMax);
			m_bBoundsSet = true;
		}
	}
	if (m_bBoundsSet)
	{
		`ASSERT(IsWithinBounds(Location) && IsWithinBounds(m_vInitialLocation));
		// Extend bounds based on the alien's sight range.  OR USE DEFAULT SIGHT RANGE.
		if (m_arrAlien.Length > 0)
			iSightRadiusTiles = `METERSTOTILES(m_arrAlien[0].GetSightRadius());
		else
			iSightRadiusTiles = `METERSTOTILES(25); // Using 25 meters as default sight range.

		m_kTileBoundsMin.X -= iSightRadiusTiles;
		m_kTileBoundsMin.Y -= iSightRadiusTiles;
		m_kTileBoundsMax.X += iSightRadiusTiles;
		m_kTileBoundsMax.Y += iSightRadiusTiles;

		`ASSERT(IsWithinBounds(Location) && IsWithinBounds(m_vInitialLocation));
	}
}

//------------------------------------------------------------------------------------------------
function bool IsWithinBounds(vector vLoc)
{
	local TTile kTile;
	kTile = `XWORLD.GetTileCoordinatesFromPosition(vLoc);
	if (kTile.X >= m_kTileBoundsMin.X && kTile.Y >= m_kTileBoundsMin.Y
		&& kTile.X <= m_kTileBoundsMax.X && kTile.Y <= m_kTileBoundsMax.Y)
		return true;
	return false;
}

//------------------------------------------------------------------------------------------------

cpptext
{
	/////////////////////////////////////
	// X2SpawnNode implementation
	virtual const FVector& GetSpawnLocation() const;
	virtual AXGAIGroup* CreateSpawnGroup() const;
};

//------------------------------------------------------------------------------------------------
defaultproperties
{
	bEdShouldSnap=True
	Layer=Markup
}
