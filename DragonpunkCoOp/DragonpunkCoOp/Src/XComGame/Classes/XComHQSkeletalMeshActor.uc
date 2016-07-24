/** JMS - A skeletal mesh actor specifically for the HQ. 5/24/12 */
class XComHQSkeletalMeshActor extends SkeletalMeshActor
	native(Level);

/** When the skeletal mesh is further than this distance, force composite all lights into the DLE. */
var() float fForceCompositeLightsDistance;

native function UpdateDLE();

simulated event Tick(float DeltaTime)
{
	UpdateDLE();
}

defaultproperties
{
	Physics=PHYS_Interpolating
}