/**     FracturedWorldDataStaticMeshComponent.uc
 *		Author: Jeremy Shopf
 *		Purpose: A fractured static mesh component that can utilize the world tile data.
 */

class XComTileFracMeshComponent extends FracturedStaticMeshComponent
	native(Destruction);

// Mask for visibility bit
const NULL_NEIGHBOR = 0xFFFFFFFF;
const DECO_N = 0x1;
const DECO_S = 0x2;
const DECO_W = 0x4;
const DECO_E = 0x8;

const VISIBILITY_SHIFT = 12;
const NEW_DECO_SHIFT = 16;

struct native ChunkNeighborhood
{
	var bool bPrevBoundary;

	var init array<INT> NeighborChunkIDs; // chunk id is a bitfield 31-16 is the actor ID, 
										  //                        15-12 are the deco mesh type ID corresponding to the entry in DecoMeshTypeInstances, 
										  //                        11-0 is the chunk index
	structdefaultproperties
	{
	}
};

/** Maps chunk ID to neighboring (in world-space) chunk IDs */
var transient array<ChunkNeighborhood> ChunkNeighbors;

// Returns an int encoding information about visible fragments bordering non-visible fragments
// 0x0fff encodes fragment ID
// 0xf000 encodes which directions are not visible
native function GetBoundaryFragmentData(out array<int> BoundaryVisibleFragments ); // FIRAXIS ADDITION
native function GetBoundaryFragmentDataExt(out array<int> BoundaryVisibleFragments, out array<int> NewBoundaryVisibleFragments, optional bool bCollectNewFragments=true ); // FIRAXIS ADDITION

cpptext
{

	virtual void InitializeVertexColorBuffer(); 

	/** Update the vertex color buffer. Requires knowledge of the fracture chunks removed during last damage. */
	virtual void UpdateVertexColorBuffer(); 

	/** Calculates vertex colors of boundary visible fragments based on neighbor's visibility */
	void CalculateVertexValuesFromFragments( UFracturedStaticMesh* InFracturedMesh, TMap<INT,INT>& VertToValue);

	void CalculateVertexValuesFromWorldData( UFracturedStaticMesh* InFracturedMesh, TMap<INT,INT>& VertToValue);

}

defaultproperties
{
		WireframeColor=(R=0,G=128,B=255,A=255)
		bAllowApproximateOcclusion=TRUE
		bForceDirectLightMap=false
		BlockRigidBody=TRUE
		bAcceptsStaticDecals=TRUE   //Firaxis RAM - allowing decals to project onto fractured mesh actors
		bAcceptsDynamicDecals=TRUE
		bAcceptsDecalsDuringGameplay=TRUE //Firaxis RAM - allowing decals to project onto fractured mesh actors
		bUseDynamicIndexBuffer=TRUE
		bUseDynamicIBWithHiddenFragments=TRUE

		bCastDynamicShadow=false
		bCastStaticShadow=true
		bUsePrecomputedShadows=false

		BlockNonZeroExtent=TRUE
		BlockZeroExtent=TRUE
		CanBlockCamera=true

		bReceiverOfDecalsEvenIfHidden=TRUE // Prevent decals getting deleted when hiding this actor through building vis system.
}