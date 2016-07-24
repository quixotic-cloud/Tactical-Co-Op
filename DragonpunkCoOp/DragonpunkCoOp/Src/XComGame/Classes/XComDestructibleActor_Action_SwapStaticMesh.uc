class XComDestructibleActor_Action_SwapStaticMesh extends XComDestructibleActor_Action
	native(Destruction);

// jboswell: This is an enumeration because we tried using a bool and the serializer
// exploded. During investigation I noticed that all components are native/noexport
// and do their own serialization. I suspect there is a fumble during the handoff from
// native to script serialization having to do with bools/bitmasks
enum EMaterialOverrideMode
{
	OVERRIDE_Keep,
	OVERRIDE_Remove,
};

/* Static mesh to swap in */
var (XComDestructibleActor_Action) instanced StaticMeshCue    MeshCue;
/* Disable collision on actor after swap */
var (XComDestructibleActor_Action) bool bDisableCollision;
/* Determine how the material on the newly swapped mesh should be handled */
var (XComDestructibleActor_Action) EMaterialOverrideMode MaterialOverrideMode;
/* Amount of time to delay the actual mesh swap */
var (XComDestructibleActor_Action) float Delay;

/* Amount of time since this action was activated. */
var float ElapsedTime;

/* After activation the collision is disabled on the original mesh until the new swap mesh is brought in, 
 * which we want to use the existing collision settings (if not disabled with bDisableCollision) */
var transient Actor.ECollisionType CachedCollisionType; 

native function NativePreActivate();
native function Activate();

// Called every frame while this action is active 
native function Tick(float DeltaTime);

// Called when ElapsedTime > Delay
native function PerformMeshSwap();

// Called when it is time for this event to fire
event PreActivate()
{
	super.PreActivate( );
	NativePreActivate();
}

defaultproperties
{
	bDisableCollision = true;
	MaterialOverrideMode = OVERRIDE_Remove;
	Delay = 0.15;
}
