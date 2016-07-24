/**
 * Waits for the Phase Manager to be active
 */
class SeqAct_WaitForPhaseManager extends SeqAct_XComWaitCondition;

event bool CheckCondition()
{
	local XGSetupPhaseManagerBase SetupPhaseManager;
	foreach GetWorldInfo().AllActors(class'XGSetupPhaseManagerBase', SetupPhaseManager)
	{
		break;
	}
	return (SetupPhaseManager != none);
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if (!bNot)
		return "Setup Phase Manager to be present.";
	else
		return "Setup Phase Manager to go away.";
}

defaultproperties
{
	ObjCategory="Wait Conditions"
	ObjName="Wait For Setup Phase Manager"
	bCallHandler=false;
}
