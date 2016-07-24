class XComFracInstData extends Object
	native(Level);

struct native DecoMeshType
{
	/* The mesh to use for the in-wall deco. */
	var() StaticMesh        DecoStaticMesh;
	/* The probability this mesh should be chosen. */
	var() INT               ProbabilityWeight<ClampMin = 1 | ClampMax = 255>;
	/* Apply random axis-flipping of the deco mesh to add variation. */
	var() bool              bRandomAxisFlip;
	/* This deco mesh has a different material on each side, don't flip that axis. */
	var() bool              bTwoSided;
	/* Whether this mesh is horizontal or vertical */
	var() bool              bHorizontal;

	structdefaultproperties
	{
		DecoStaticMesh = StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Hor_A'
		ProbabilityWeight = 1
		bRandomAxisFlip = true
		bTwoSided = false
		bHorizontal = false
	}

};

var() Array<DecoMeshType> DecoMeshes;

var() editinline FractureEffect FractureEffect;
var() editinline FractureEffect DustEffect;

defaultproperties
{
	DecoMeshes(0) = (DecoStaticMesh = StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Hor_A', bHorizontal = true);
	DecoMeshes(1) = (DecoStaticMesh = StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Hor_B', bHorizontal = true);
	DecoMeshes(2) = (DecoStaticMesh = StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Vert_A', bHorizontal = false);
	DecoMeshes(3) = (DecoStaticMesh = StaticMesh'FractureDeco.Meshes.FracDeco_Brick_Vert_B', bHorizontal = false);
}