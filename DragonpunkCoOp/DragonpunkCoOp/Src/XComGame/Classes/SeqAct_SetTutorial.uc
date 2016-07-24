//-----------------------------------------------------------
// Whether or not we are in the tutorial.
//-----------------------------------------------------------
class SeqAct_SetTutorial extends SequenceAction;

var() bool TutorialMode;

event Activated()
{
	`BATTLE.m_kDesc.m_bIsTutorial = TutorialMode;
}


defaultproperties
{
	ObjCategory="Tutorial"
	ObjName="Set Tutorial Mode"

	VariableLinks.Empty
}
