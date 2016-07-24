//-----------------------------------------------------------
// Whether or not we are in the tutorial.
//-----------------------------------------------------------
class SeqAct_AllowFiring extends SequenceAction;

var() bool Allow;

event Activated()
{
	// If firing is not allowed by the DTE, call a Kismet event.
	if( `TACTICALGRI.DirectedExperience != none )
	{
		`TACTICALGRI.DirectedExperience.SetFiringIsAllowed(Allow);
	}
}


defaultproperties
{
	ObjCategory="Tutorial"
	ObjName="Allow Unit Firing"

	VariableLinks.Empty
}
