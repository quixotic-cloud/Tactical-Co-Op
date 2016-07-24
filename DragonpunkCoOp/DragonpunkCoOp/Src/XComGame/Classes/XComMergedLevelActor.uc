/*
 * XComMergedLevelActor
 *      An XComLevelActor extended to track the individual level actors that were merged into it
 *      
 *      Jeremy Shopf 07/6/10
 */

class XComMergedLevelActor extends XComLevelActor 
	native(Level)
	placeable; 
	
var() bool bTest;

// Keep track of meshes and transforms to "undo". Currently only restores
//          the mesh and transforms
struct native UndoEntry
{
	var StaticMesh pStaticMesh;                  // The static mesh used 
	var Matrix     kTransformToComponentSpace;   // Transform from merged actor's component to the actor's component being merged 
	var Vector     kOriginDelta;
};

var Array<UndoEntry> m_kOriginalMeshes;
var Rotator m_kRotationAtMerge;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}



native function UndoMerge();

defaultproperties
{

}
