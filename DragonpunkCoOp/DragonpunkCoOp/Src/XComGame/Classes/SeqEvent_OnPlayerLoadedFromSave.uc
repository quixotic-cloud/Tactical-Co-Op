//-----------------------------------------------------------
//Event triggers when the player turn begins but only when loading from a save
//-----------------------------------------------------------
class SeqEvent_OnPlayerLoadedFromSave extends SequenceEvent;

event Activated()
{
}

defaultproperties
{
	ObjCategory="Save/Load"
	ObjName="On Player Loaded From Save"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	OutputLinks(0)=(LinkDesc="Out")
}
