//-----------------------------------------------------------
// Whether or not we are in the tutorial.
//-----------------------------------------------------------
class SeqAct_IsTutorial extends SequenceCondition;

event Activated()
{
	if (`BATTLE.m_kDesc.m_bIsTutorial)
	{
		OutputLinks[0].bHasImpulse = true;
	}
	else
	{
		OutputLinks[1].bHasImpulse = false;
	}
}


defaultproperties
{
	ObjCategory="Xcom Game"
	ObjName="Is Tutorial"

	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="True")
	OutputLinks(1)=(LinkDesc="False")
}
