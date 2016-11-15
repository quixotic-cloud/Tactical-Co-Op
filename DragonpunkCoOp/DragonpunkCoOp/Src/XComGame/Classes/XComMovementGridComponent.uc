/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class XComMovementGridComponent extends PrimitiveComponent
	config(game)
	native(Level);

var transient const globalconfig float      MovementBorderWidth; // Width the of ribbon to create;
var transient const globalconfig float      MovementBorderHeightOffset; // z height Offset from the floor
var transient const globalconfig float      MovementBorderLengthFactor; // factor to determine how far from the tile's corner the edge will be placed, 
																		// which determines the size of 45 degree connectors
var transient const globalconfig float      CurveSmoothing; // Factor for smoothing out curves.
var transient const globalconfig float      CurveResolution; // Density of curve segments.
var transient const globalconfig float      UVTilingDistance; // Distance in which UV will transition from 0 to 1

var transient TTile                         LastCacheOrigin;
var transient XGUnitNativeBase              LastUnit;
var transient int                           LastCursorZPosition;
var transient int							LastHistoryIndex;

var transient bool                          bCustomHidden;
var transient bool                          bCinematicHidden;
var transient bool                          bUIHidden;

var transient bool                          bUsedHeightConstraints;
var transient bool                          bIsGrappleMove;

var transient native bool                   bUsingMouseMaterial;

var MaterialInstanceConstant	BorderMaterial;	//MIC to use for this particular grid component

var native int                  SizeOfPreviousMapping;
var native int                  SizeOfPreviousEdges;
var native int                  SizeOfPreviousRampTiles;
var native int                  SizeOfPreviousMinTiles;

var native int                  DebugTileX;
var native int                  DebugTileY;
var native int                  DebugTileZ;

var int CachedStage7Hash;

struct native XComMovementGridRenderData
{
	var int VertexCount;	
	var int IndexCount;

	var int MaxVertexBufferSize;
	var int MaxIndexBufferSize;

	var int CachedStage7Hash;

	var native pointer VertexData{void};
	var native pointer IndexData{WORD};

	structcpptext
	{
		FXComMovementGridRenderData()
		:	VertexData(NULL),
			IndexData(NULL),
			VertexCount(0),
			IndexCount(0),
			CachedStage7Hash(0),
			MaxVertexBufferSize(0),
			MaxIndexBufferSize(0)
		{}
	}
};

var transient native XComMovementGridRenderData GameThreadRenderData;

cpptext
{
	/**
	 * Creates a proxy to represent the primitive to the scene manager in the rendering thread.
	 * @return The proxy object.
	 */
	virtual FPrimitiveSceneProxy* CreateSceneProxy();

	virtual void BeginDestroy();

	void VerifyBorderMaterial(UBOOL bUsingMouse, UBOOL bGrappleMove);
	void SetBorderRelevance(FLOAT InRelevance);
	void SetIndicateUseRestOfMoves(FLOAT InRelevance);
	void SetColorParameter(FLinearColor BorderColor);

	void ClearMovementGridMesh();

	void StartUpdateTask(AXGUnitNativeBase* Unit, UBOOL bIsUsingMouse, FLOAT PCMinUnits, FLOAT PCMaxUnits, UBOOL bGrappleMove);
	void MainUpdate(UBOOL bIsUsingMouse, FLOAT PCMinUnits, FLOAT PCMaxUnits, UBOOL bGrappleMove);
	void SpecialMovementUpdate(const TArray<FTTile> TargetTiles);
	
	void UpdateBorderSceneProxy();
	void UpdateBorderData(UBOOL bIsUsingMouse, UBOOL bGrappleMove);
}

function native SetCustomHidden(bool bHidden);
function native SetCinematicHidden(bool bHidden);
function native SetUIHidden(bool bHidden);
function native ClearMovementGridScript();

function native UpdateCursorHeightHiding( Vector CursorPos );

defaultproperties
{
	bDisableAllRigidBody=true
	bCustomHidden=true
	bCinematicHidden=false
	bUIHidden=false
	bUsedHeightConstraints=true
	bUsingMouseMaterial=false
	bIsGrappleMove=false
	TranslucencySortPriority=1000
	bTranslucentIgnoreFOW=true

	DebugTileX=-1
	DebugTileY=-1
	DebugTileZ=-1
}
