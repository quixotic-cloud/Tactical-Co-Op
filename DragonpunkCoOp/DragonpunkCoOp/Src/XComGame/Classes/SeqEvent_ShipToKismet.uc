class SeqEvent_ShipToKismet extends SequenceEvent;

var Object Ship1, Ship2, Ship3, Ship4, Firestorm1, Firestorm2, Firestorm3, Firestorm4;

event Activated()
{
	OutputLinks[0].bDisabled = false;
}

static event int GetObjClassVersion()
{
	return Super.GetObjClassVersion() + 3;
}

defaultproperties
{
	ObjName="Ship To Kismet"
	ObjCategory="Cinematic"
	bPlayerOnly=false
	MaxTriggerCount=0

	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Ship 1",PropertyName=Ship1,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Ship 2",PropertyName=Ship2,bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Object',LinkDesc="Ship 3",PropertyName=Ship3,bWriteable=TRUE)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Object',LinkDesc="Ship 4",PropertyName=Ship4,bWriteable=TRUE)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Object',LinkDesc="Firestorm 1",PropertyName=Firestorm1,bWriteable=TRUE)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Object',LinkDesc="Firestorm 2",PropertyName=Firestorm2,bWriteable=TRUE)
	VariableLinks(6)=(ExpectedType=class'SeqVar_Object',LinkDesc="Firestorm 3",PropertyName=Firestorm3,bWriteable=TRUE)
	VariableLinks(7)=(ExpectedType=class'SeqVar_Object',LinkDesc="Firestorm 4",PropertyName=Firestorm4,bWriteable=TRUE)
}