//-----------------------------------------------------------
//Event triggers when a player's turn ends
//-----------------------------------------------------------
class SeqEvent_OnPlayerEndingTurn extends SequenceEvent
	deprecated;

event Activated()
{
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="On Player Ending Turn"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	OutputLinks(0)=(LinkDesc="Out")

	//VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Firing Unit",PropertyName=FiringUnit,bWriteable=TRUE)

	//bAutoActivateOutputLinks=true
}
