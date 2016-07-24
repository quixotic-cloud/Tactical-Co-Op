/**
 * Sequence action to change which Directed Tactical Experience is currently active.
 */
class SeqAct_SetActiveDirectedExperience extends SequenceAction;

var() XComDirectedTacticalExperience DirectedExperience;

event Activated()
{
	local XComTacticalGRI TacticalGRI;
	local XComDirectedTacticalExperience ActiveDirectedExperience;

	TacticalGRI = `TACTICALGRI;
	if (TacticalGRI != none)
	{
		ActiveDirectedExperience = TacticalGRI.DirectedExperience;
		if (ActiveDirectedExperience != DirectedExperience)
		{
			if (ActiveDirectedExperience != none)
			{
				ActiveDirectedExperience.DisableDTE();
				TacticalGRI.DirectedExperience = none;
			}

			if (DirectedExperience != none)
			{
				DirectedExperience.EnableDTE();
			}
		}
	}
}

defaultproperties
{
	ObjName="Set Active Directed Experience"
	ObjCategory="Tutorial"
	bCallHandler = false

	VariableLinks.Empty
}
