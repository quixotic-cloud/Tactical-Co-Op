//-----------------------------------------------------------
// Whether or not we are in the tutorial.
//-----------------------------------------------------------
class SeqAct_CantLose extends SequenceAction
	deprecated;

event Activated()
{
	XGBattle_SP(`BATTLE).GetHumanPlayer().m_bCantLose = true;
}


defaultproperties
{
	ObjCategory="Tutorial"
	ObjName="Cant Lose"
}
