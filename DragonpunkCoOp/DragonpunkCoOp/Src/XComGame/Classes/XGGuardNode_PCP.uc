//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XGGuardNode_PCP.uc    
//  AUTHOR:  Alex Cheng  --  4/1/2014
//  PURPOSE: XGGuardNode_PCP:   Spawn point for PCP guards.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XGGuardNode_PCP extends Actor
	native(AI)
	placeable
	hidecategories(Display, Attachment, Collision, Physics, Mobile, Debug, Actor)
	implements(X2SpawnNode);

var() array<XComSpawnPointNativeBase> m_arrSpawnPoint<DisplayName=Spawn Points>;
var()  bool m_bAlienEligible; // Can be filled with non-Advent units.
var()   bool m_bFillFirst;
var   editoronly	vector vMove;
var   editoronly	bool bIsInMove;
var() editoronly    bool bMoveWithPoints;
var   IntPoint m_kTileBoundsMin, m_kTileBoundsMax;
var   XComParcel m_kParcel; // assigned parcel, for parcel guards.
var   bool m_bBoundsSet;
var   vector m_vInitialLocation;
var() StaticMeshComponent NodeMesh; // (visible only in EDITOR).

cpptext
{
	//virtual void PreEditChange(UProperty* PropertyThatWillChange);
	//virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);
	virtual void PreEditMove();
	virtual void PostEditMove(UBOOL bFinished);
	//virtual void PostLoad();
	virtual void Spawned();
	//void UpdateRelatedPodArrows( UBOOL bOnLoad=FALSE );
	//UBOOL IsLinkedTo( const AXComAlienPathNode* kNode ) const;
	void SpawnInitialPoints();

	/////////////////////////////////////
	// X2SpawnNode implementation
	virtual const FVector& GetSpawnLocation() const;
	virtual AXGAIGroup* CreateSpawnGroup() const;
}

//native function GetAllConnectedNodes( out array<XComAlienPathNode> arrNodeList_out );

simulated function Init()
{
	m_vInitialLocation = Location;
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
	if (m_kParcel == None)
		InitParcel();

	if (m_kParcel != None)
	{
		// Get parcel bounds.
		m_kParcel.GetTileBounds(m_kTileBoundsMin, m_kTileBoundsMax);
		m_bBoundsSet = true;
	}

	if (m_bBoundsSet)
	{
		`ASSERT(IsWithinBounds(Location) && IsWithinBounds(m_vInitialLocation));
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
defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=AlienPodStaticMeshComponent
		HiddenGame=true
		StaticMesh=StaticMesh'VignetteConstructionPack.Meshes.ASE_CryssalidPod'
		bUsePrecomputedShadows=FALSE //Bake Static Lights, Zel
		LightingChannels=(BSP=FALSE,Static=TRUE,Dynamic=TRUE,CompositeDynamic=TRUE,bInitialized=TRUE)//Bake Static Lights, Zel
		WireframeColor=(R=255,G=0,B=255,A=255)
		Scale=0.25		
	End Object
	NodeMesh = AlienPodStaticMeshComponent
	Components.Add(AlienPodStaticMeshComponent)

	bEdShouldSnap=True
	bMoveWithPoints=True
	Layer=Markup
}
