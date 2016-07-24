class XComDestructibleActor_Action_PlaySoundCue extends XComDestructibleActor_Action
	native(Destruction);

var(XComDestructibleActor_Action) SoundCue Sound;
var(XComDestructibleActor_Action) float Delay;

var private float TimeSinceStarted;

native function Activate();
native function Deactivate();
native function Load(float InTimeInState);
native function bool Validate();

// Called every frame while this action is active
native function Tick(float DeltaTime);


defaultproperties
{
	Delay = 0
	TimeSinceStarted = 0
}
