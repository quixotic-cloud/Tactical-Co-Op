class SeqAct_LoseBattle extends SequenceAction
	deprecated;

var bool bLoseMission;

event Activated()
{
	bLoseMission = true;
	`BATTLE.IsBattleDone();
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Lose Battle"

	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")

	bLoseMission=false
}