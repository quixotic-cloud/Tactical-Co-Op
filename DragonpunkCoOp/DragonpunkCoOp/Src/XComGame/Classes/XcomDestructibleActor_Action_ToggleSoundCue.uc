class XcomDestructibleActor_Action_ToggleSoundCue extends XcomDestructibleActor_Action
	native(Destruction);

var(XComDestructibleActor_Action) AmbientSound Sound<ToolTip="The sound to toggle when damaged.">;

var() bool bStopOnly<ToolTip="only allow us to STOP the sound, not re-start it">;

native function Activate();

defaultproperties
{
	bStopOnly = true;
}