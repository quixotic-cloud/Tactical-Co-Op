//-----------------------------------------------------------
//
//-----------------------------------------------------------

class SeqAct_MarkMissionAlreadyWon extends SequenceAction
	deprecated;

event Activated()
{
	local XComTacticalGRI kTacticalGRI;
	local XGBattle_SP kBattle;

	kTacticalGRI = `TACTICALGRI;
	kBattle = (kTacticalGRI != none) ? XGBattle_SP(kTacticalGRI.m_kBattle) : none;
	
	if(kBattle != none)
	{
		kBattle.m_bMissionAlreadyWon = InputLinks[0].bHasImpulse;
	}
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Mark Mission Already Won"

	InputLinks(0)=(LinkDesc="Mark")
	InputLinks(1)=(LinkDesc="Unmark")
	OutputLinks(0)=(LinkDesc="Out")
	VariableLinks.Empty()
}