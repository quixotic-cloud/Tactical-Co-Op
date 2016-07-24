//-----------------------------------------------------------
// Whether or not we are in the tutorial.
//-----------------------------------------------------------
class SeqAct_AllowAlienDamage extends SequenceAction;

var() bool Allow;

event Activated()
{
	// If firing is not allowed by the DTE, call a Kismet event.
	if( `TACTICALGRI.DirectedExperience != none )
	{
		`TACTICALGRI.DirectedExperience.SetAliensDealDamage(Allow);
	}
}


defaultproperties
{
	ObjCategory="Tutorial"
	ObjName="Allow Alien Damage"

	VariableLinks.Empty
}
