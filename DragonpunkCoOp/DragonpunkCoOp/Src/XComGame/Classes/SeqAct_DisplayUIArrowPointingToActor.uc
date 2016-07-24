//-----------------------------------------------------------
//Show a special mission arrow pointing at an actor. 
//
//  This class remains purely so that existing actions don't disappear from kismet scripts
//  before we can convert them all to SeqAct_DisplayUIArrowPointingToUnit .
//
//-----------------------------------------------------------
class SeqAct_DisplayUIArrowPointingToActor extends SequenceAction
	dependson(XGTacticalScreenMgr)
	deprecated;

var Object kTarget;
var vector offset;
var int iCount; 
var bool bShow; 

event Activated()
{
	// Do not use me! Use SeqAct_DisplayUIArrowPointingToUnit instead.
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Arrow Pointing at Actor"
	iCount = -1;
	bCallHandler = false
	
	InputLinks.Empty;
	InputLinks(0)=(LinkDesc="yellow")
	InputLinks(1)=(LinkDesc="unused")
	InputLinks(2)=(LinkDesc="red")
	InputLinks(3)=(LinkDesc="blue")
	InputLinks(4)=(LinkDesc="gray")

	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",bWriteable=true,PropertyName=kTarget)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Vector Offset",bWriteable=true,PropertyName=offset)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Bool',LinkDesc="bShow?",bWriteable=true,PropertyName=bShow)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Int',LinkDesc="Counter",bWriteable=true,PropertyName=iCount)
}
