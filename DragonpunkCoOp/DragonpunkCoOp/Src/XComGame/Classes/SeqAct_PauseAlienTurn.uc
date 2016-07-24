class SeqAct_PauseAlienTurn extends SequenceAction;

var() bool PauseAlienTurn;

event Activated()
{
	XGAIPlayer(XGBattle_SP(`BATTLE).GetAIPlayer()).m_bPauseAlienTurn = PauseAlienTurn;
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Pause Alien Turn"
}