class SeqAct_SetDTESequenceIndex extends SequenceAction;

var XComDirectedTacticalExperience DirectedExperience;
var() int Index;

event Activated()
{
	if (DirectedExperience != none)
	{
		DirectedExperience.m_iNextSequenceOverride = Index;
	}
}

defaultproperties
{
	ObjName="Set Squence Index"
	ObjCategory="Tutorial"
	bCallHandler = false

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Directed Tactical Environment", PropertyName=DirectedExperience)
}