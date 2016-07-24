class XComRenderablePathComponent extends PrimitiveComponent
	native;

var MaterialInterface PathingMaterial;

var int                         iPathLengthOffset;
var float                       fRibbonWidth;
var float                       fEmitterTimeStep;

enum ConcealmentUsage
{
	eCU_NoConcealment,
	eCU_WithConcealment
};

var ConcealmentUsage     PathType;

struct native XComPathRenderData
{
	var int VertexCount;	
	var int IndexCount;

	var int MaxVertexBufferSize;
	var int MaxIndexBufferSize;

	var native pointer VertexData{void};
	var native pointer IndexData{WORD};

	structcpptext
	{
		FXComPathRenderData()
		:	VertexData(NULL),
			IndexData(NULL),
			VertexCount(0),
			IndexCount(0),
			MaxVertexBufferSize(0),
			MaxIndexBufferSize(0)
		{}
	}
};

var transient native XComPathRenderData GameThreadRenderData;

cpptext
{
	/**
	 * Creates a proxy to represent the primitive to the scene manager in the rendering thread.
	 * @return The proxy object.
	 */
	virtual FPrimitiveSceneProxy* CreateSceneProxy();

	virtual void BeginDestroy();

	virtual void ClearPathRenderData();

	virtual void UpdateBorderSceneProxy();
}

native function bool UpdatePathRenderData( InterpCurveVector Spline, float PathLength, XComPathingPawn InPawn, vector CameraLocation );

native function SetMaterial( MaterialInterface InMat );

defaultproperties
{
	iPathLengthOffset=0
	fRibbonWidth=2
	fEmitterTimeStep=10
	PathType=eCU_NoConcealment //Setting this seems to not actually work, be careful if you change it to need something other than 0 - eCU_NoConcealment
}