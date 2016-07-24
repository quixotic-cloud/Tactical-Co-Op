class SeqAct_SkipAI extends SequenceAction;

var bool bSkipAI;

event Activated()
{
	XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer()).m_bSkipAI = bSkipAI;
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Skip AI"
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Bool',LinkDesc="Skip AI",PropertyName=bSkipAI)
}