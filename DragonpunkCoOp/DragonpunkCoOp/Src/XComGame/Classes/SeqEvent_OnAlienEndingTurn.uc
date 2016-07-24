//-----------------------------------------------------------
//Event triggers when the alien turn ends
//-----------------------------------------------------------
class SeqEvent_OnAlienEndingTurn extends SequenceEvent
	deprecated;

event Activated()
{
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="On Alien Ending Turn"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	OutputLinks(0)=(LinkDesc="Out")
}
