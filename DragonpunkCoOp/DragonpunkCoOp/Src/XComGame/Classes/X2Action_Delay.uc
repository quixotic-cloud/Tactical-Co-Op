//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Delay extends X2Action;

var float Duration; // In seconds
var bool bIgnoreZipMode; // If true, zip mode will not affect this action

event bool BlocksAbilityActivation()
{
	return false;
}

function bool ShouldPlayZipMode()
{
	return !bIgnoreZipMode && super.ShouldPlayZipMode();
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event Tick(float DeltaTime)
	{
		Duration -= DeltaTime;
	}

Begin:
	Duration = Duration * GetDelayModifier();
	TimeoutSeconds = Duration + 1.0f;

	while(Duration > 0)
	{
		sleep(0.0);
	}

	CompleteAction();
}

defaultproperties
{

}

