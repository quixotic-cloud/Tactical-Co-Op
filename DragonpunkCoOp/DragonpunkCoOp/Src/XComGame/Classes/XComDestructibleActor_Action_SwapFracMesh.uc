class XComDestructibleActor_Action_SwapFracMesh extends XComDestructibleActor_Action
	native(Destruction);

var (XComDestructibleActor_Action) XComFracLevelActor    SwapMesh;

native function NativePreActivate();
native function Activate();

// Called when it is time for this event to fire
event PreActivate()
{
	super.PreActivate( );
	NativePreActivate( );
}

defaultproperties
{
}
