class XComDestructibleActor_Action extends Object within XComDestructibleActor
	native(Destruction)
	abstract
	editinlinenew
	hidecategories(Object)
	collapsecategories;

//var deprecated float m_fTimeOffset<DisplayName=TimeOffset|Tooltip=Amount of time to wait after the actor takes damage before running this action>;
var() bool bEnabled<Tooltip=Use this to enable / disable archetype events on instanced destructible actors>;
var transient bool bActivated;
var transient bool bNeedsTick;

// Called when it is time for this event to fire
event PreActivate() // actions for changes to self/tile data
{
}

event PreActivateResponse() // actions for submitting any new gamestates
{
}

// Called when it is time for this event to fire
native function Activate();

// Some actions need to tick for some amount of time
native function bool NeedsTick();

// Called when the owner is transitioning to a new state, cleanup time
native function Deactivate();

// Called every frame while this action is active
native function Tick(float DeltaTime);

// Called after loading from save, allows this action to jump to a specific time in its lifespan
native function Load(float InTimeInState);

// Allows the system to discern whether an action is valid or not
native function bool Validate();

defaultproperties
{
	bActivated = false
	bEnabled = true
	bNeedsTick = false
}