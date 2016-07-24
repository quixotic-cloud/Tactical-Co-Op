//-----------------------------------------------------------
//Trigger when code is passing units to kismet variables for matinee
//-----------------------------------------------------------
class SeqEvent_UnitToKismet extends SequenceEvent;

var Object  Unit1,Unit2,Unit3,Unit4,Unit5,Unit6;

event Activated()
{
	`log( "SeqEvent_UnitToKismet: "@Unit1);
	OutputLinks[0].bDisabled = false;
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
	return Super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjName="Unit To Kismet"
	ObjCategory="Cinematic"
	bPlayerOnly=false
	MaxTriggerCount=0

	bClientAndServer=true

	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 1",PropertyName=Unit1,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 2",PropertyName=Unit2,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 3",PropertyName=Unit3,bWriteable=TRUE)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 4",PropertyName=Unit4,bWriteable=TRUE)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 5",PropertyName=Unit5,bWriteable=TRUE)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Object',LinkDesc="Unit 6",PropertyName=Unit6,bWriteable=TRUE)
}