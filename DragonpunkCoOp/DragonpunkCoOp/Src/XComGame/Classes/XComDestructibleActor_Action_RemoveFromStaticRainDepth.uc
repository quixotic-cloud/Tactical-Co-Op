class XComDestructibleActor_Action_RemoveFromStaticRainDepth extends XComDestructibleActor_Action
	native(Destruction);


var (XComDestructibleActor_Action) XComLevelActor ActorToHide;

native function Activate();

// Called when it is time for this event to fire
event PreActivate()
{
	super.PreActivate( );
}

defaultproperties
{
}