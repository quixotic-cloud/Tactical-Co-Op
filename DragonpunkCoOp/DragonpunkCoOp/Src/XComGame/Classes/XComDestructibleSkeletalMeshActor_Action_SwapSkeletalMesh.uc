class XComDestructibleSkeletalMeshActor_Action_SwapSkeletalMesh extends XComDestructibleActor_Action within XComDestructibleSkeletalMeshActor
	native(Destruction);

var (XComDestructibleActor_Action) instanced SkeletalMeshCue    MeshCue;
var (XComDestructibleActor_Action) bool bDisableCollision;

native function Activate();

defaultproperties
{
	bDisableCollision = false;
}
