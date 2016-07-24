class SeqEvent_DestructibleStatusChanged extends SequenceEvent;

defaultproperties
{
	ObjName="Destructible Actor Status Change"
	ObjCategory="Level"
	VariableLinks.Empty
	OutputLinks(0)=(LinkDesc="Damaged")
	OutputLinks(1)=(LinkDesc="Destroyed")
	OutputLinks(2)=(LinkDesc="Obliterated")
	bPlayerOnly=false

	MaxTriggerCount=0
}