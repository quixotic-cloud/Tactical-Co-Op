//-----------------------------------------------------------
//
//-----------------------------------------------------------
class SeqEvent_MissionControl extends SequenceEvent;

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
	ObjName="Mission Control"

	bPlayerOnly=FALSE
	MaxTriggerCount=0
	
	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="FundingCouncilOn")
	OutputLinks(1)=(LinkDesc="FundingCouncilOff")
	OutputLinks(2)=(LinkDesc="HoloGlobeOn")
	OutputLinks(3)=(LinkDesc="HoloGlobeOff")
	OutputLinks(4)=(LinkDesc="GlobeOn")
	OutputLinks(5)=(LinkDesc="GlobeOff")

	VariableLinks.Empty

	bAutoActivateOutputLinks=false
}