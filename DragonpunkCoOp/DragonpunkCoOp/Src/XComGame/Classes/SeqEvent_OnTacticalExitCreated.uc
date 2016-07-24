//-----------------------------------------------------------
//Event triggers when the tactical exit is created
//-----------------------------------------------------------
class SeqEvent_OnTacticalExitCreated extends SequenceEvent;

event Activated()
{
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="On Tactical Exit Created"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	OutputLinks(0)=(LinkDesc="Out")
}
