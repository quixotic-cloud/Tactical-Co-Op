//-----------------------------------------------------------
//
//-----------------------------------------------------------
class SeqEvent_OnStrategyRoomEntered extends SequenceEvent;

var name RoomName;

event Activated()
{
	local int i;
	
	for (i = 0; i < OutputLinks.Length; i++)
	{
		if (string(RoomName) == OutputLinks[i].LinkDesc)
		{
			OutputLinks[i].bDisabled = false;
		}
		else OutputLinks[i].bDisabled = true;
	}
}

/**
 * Return the version number for this class.  Child classes should increment this method by calling Super then adding
 * a individual class version to the result.  When a class is first created, the number should be 0; each time one of the
 * link arrays is modified (VariableLinks, OutputLinks, InputLinks, etc.), the number that is added to the result of
 * Super.GetObjClassVersion() should be incremented by 1.
 *
 * @return	the version number for this specific class.
 */
static event int GetObjClassVersion()
{
	return Super.GetObjClassVersion() + 0;
}

defaultproperties
{
	ObjCategory="Cinematic"
	ObjName="On Room Entered"

	bPlayerOnly=FALSE
	MaxTriggerCount=0
	
	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="Base")
	OutputLinks(1)=(LinkDesc="MissionControl")

	VariableLinks.Empty

	bAutoActivateOutputLinks=false
}
