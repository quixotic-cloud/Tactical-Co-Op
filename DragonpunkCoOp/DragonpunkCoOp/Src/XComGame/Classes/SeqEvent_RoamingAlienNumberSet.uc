class SeqEvent_RoamingAlienNumberSet extends SequenceEvent;

var int iNumAliens;

event Activated()
{
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Num Overmind Aliens to Spawn"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Int',LinkDesc="Alien Number",PropertyName=iNumAliens)
}
