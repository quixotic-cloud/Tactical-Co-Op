//-----------------------------------------------------------
//Event triggers when the civilian turn ends
//-----------------------------------------------------------
class SeqEvent_OnCivilianEndingTurn extends SequenceEvent
	deprecated;

event Activated()
{
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="On Civilian Ending Turn"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	OutputLinks(0)=(LinkDesc="Out")
}
