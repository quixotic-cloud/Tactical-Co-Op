/**
 * Ends a Sub Sequence in an Directed Tactical Experience.
 * This disables the current sub sequence and begins the next one.
 */
class SeqAct_EndSubSequence extends SequenceAction;

event Activated()
{
	local XComTacticalGRI TacticalGRI;
	local XComDirectedTacticalExperience DirectedExperience;

	TacticalGRI = `TACTICALGRI;
	if (TacticalGRI != none)
	{
		DirectedExperience = TacticalGRI.DirectedExperience;
		if (DirectedExperience != none)
			DirectedExperience.MoveToNextSequence();
	}
}

defaultproperties
{
	ObjCategory="Tutorial"
	ObjName="End DTE Sequence"
	bCallHandler=false

	VariableLinks.Empty
}
