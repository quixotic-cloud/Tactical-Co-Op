class XComDecoFracLevelActor extends XComFracLevelActor
	dependson(XComFracLevelActor, XComFracInstData)
	native(Destruction);
var() Array<DecoMeshType> DecoMeshes;

var int nRandomSeed;

const NULL_DECO = -1;

struct native ChunkDecoData
{
	var int    DecoMeshTypeIdx; // Corresponds to entry in DecoMeshes array, -1 == none
	var Matrix Transform;

	structdefaultproperties
	{
		DecoMeshTypeIdx=NULL_DECO;
	}
};

struct native ChunkDecoMeshes
{
	var init array<ChunkDecoData> ChunkDeco; // should be 4 entries corresponding to the 4 deco "sockets"
	var int specialSpacer;
};

var init Array<ChunkDecoMeshes> ChunksToDeco;

/** We cache the number of destroyed fragments so that we know when to update debris meshes. */
var int nCachedFragmentsVisible;

simulated event BreakOffPartsInRadius(vector Origin, float Radius, float RBStrength, bool bWantPhysChunksAndParticles)
{
	super.BreakOffPartsInRadius( Origin, Radius, RBStrength, bWantPhysChunksAndParticles );
}

event Destroyed()
{
	Deregister();
}

simulated native function SetHidden(bool bNewHidden);

/** Flag all primitive components as currently cutdown, immediately without fade. */
native simulated function SetPrimitiveCutdownFlagImm(bool bShouldCutdown);
/** Flag all primitive components as currently cutout, immediately without fade. */
native simulated function SetPrimitiveCutoutFlagImm(bool bShouldCutout);

native simulated function SetPrimitiveHidden(bool bInHidden);

/** Set vis fade on necessary primitive components */
native simulated function SetVisFadeFlag(bool bVisFade, optional bool bForceReattach=false );

/** Set the current and target cutout and height values. Allows the actor to determine which primitive
 *  component the values come from. */
native simulated function SetPrimitiveVisFadeValues( float fCutoutFade, float fTargetCutoutFade );

/** Set all the height values used for building visibility */
native simulated function SetPrimitiveVisHeight( float fCutdownHeight,     float fCutoutHeight, 
												 float fOpacityMaskHeight, float fPreviousOpacityMaskHeight );

native simulated function ChangeVisibilityAndHide( bool bShow, float fCutdownHeight, float fCutoutHeight );
native function Deregister();

cpptext
{	
	virtual void PostScriptDestroyed();
	virtual void PostLoad();
	virtual void PreSave();

	void AddDecoMeshInstance( const INT DecoMeshTypeIdx, FMatrix& Transform, const INT FracChunkID, const INT SocketIdx );
	UBOOL CalculateDecoTransformAndTest( const FDecoMeshType& DecoMeshType, const FVector& DecoMeshSocketOffset, const FMatrix& DecoLocalToFracLocal, const FVector& ChunkSizeLocal, UBOOL bMirrored, const FKAggregateGeom& FracMeshAggGeomWS,
										FMatrix& OutDecoInstanceTransform );

	UXComDestructionInstData* GetDestructionInstData();
}

defaultproperties
{

	Begin Object Name=FracturedStaticMeshComponent0
		bUseVertexColorDestruction=true;
	End Object

    nRandomSeed=-1;

	nCachedFragmentsVisible=-1;

	DecoMeshes(0)=(DecoStaticMesh=StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Hor_A',bHorizontal=true);
	DecoMeshes(1)=(DecoStaticMesh=StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Hor_B',bHorizontal=true);
	DecoMeshes(2)=(DecoStaticMesh=StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Vert_A',bHorizontal=false);
	DecoMeshes(3)=(DecoStaticMesh=StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Vert_B',bHorizontal=false);
}
