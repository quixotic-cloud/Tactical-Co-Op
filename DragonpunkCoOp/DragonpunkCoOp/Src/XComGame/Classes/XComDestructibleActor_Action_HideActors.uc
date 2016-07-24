class XComDestructibleActor_Action_HideActors extends XComDestructibleActor_Action
	native(Destruction);


/* Amount of time to delay the actual mesh swap */
var (XComDestructibleActor_Action) float Delay;
var (XComDestructibleActor_Action) array<XComDestructibleActor> ActorsToHide;

/* Amount of time since this action was activated. */
var float ElapsedTime;

native function NativePreActivate();
native function Activate();

// Called when it is time for this event to fire
event PreActivate()
{
	super.PreActivate( );

	NativePreActivate( );
}

// Called every frame while this action is active 
native function Tick(float DeltaTime);

defaultproperties
{
	Delay=0.0;
	ElapsedTime=0.0;
}