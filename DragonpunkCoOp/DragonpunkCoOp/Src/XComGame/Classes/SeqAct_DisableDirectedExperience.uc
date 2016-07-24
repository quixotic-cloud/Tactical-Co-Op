/**
 * Sequence action to disable a Directed Tactical Experience.
 */
class SeqAct_DisableDirectedExperience extends SequenceAction;

var() XComDirectedTacticalExperience DirectedExperience;

event Activated()
{
	if (DirectedExperience != none)
	{
		DirectedExperience.DisableDTE();
	}
}

defaultproperties
{
	ObjName="Disable Directed Experience"
	ObjCategory="Tutorial"
	bCallHandler = false

	VariableLinks.Empty
}
