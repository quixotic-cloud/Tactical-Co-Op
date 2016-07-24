class SeqAct_GetDTESeqNum extends SequenceAction;

var int CurrentIndex;

event Activated()
{
	local XComDirectedTacticalExperience DirectedExperience;
	
	DirectedExperience = `TACTICALGRI.DirectedExperience;
	if (DirectedExperience != none)
	{
		CurrentIndex = DirectedExperience.CurrentSequence;		
	}
}

defaultproperties
{
	ObjName="Get DTE Sequence Num"
	ObjCategory="Tutorial"
	bCallHandler = false

	VariableLinks(1)=(ExpectedType=class'SeqVar_Int',LinkDesc="CurrentIndex",bWriteable=TRUE,PropertyName=CurrentIndex)
}