class SeqEvent_OnMissionVictory extends SequenceEvent
	deprecated;

event Activated()
{
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="On Mission Victory"
	bPlayerOnly=FALSE
	MaxTriggerCount=0
	bAutoActivateOutputLinks=true

	OutputLinks(0)=(LinkDesc="Out")
}
