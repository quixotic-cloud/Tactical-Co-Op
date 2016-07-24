class SeqAct_SoldierChatter extends SequenceAction;

event Activated()
{
	if (InputLinks[0].bHasImpulse)
	{
		`BATTLE.m_kDesc.m_bDisableSoldierChatter = false;
	}
	else
	{
		`BATTLE.m_kDesc.m_bDisableSoldierChatter = true;
	}
}

defaultproperties
{
	ObjCategory="Sound"
	ObjName="Modify Soldier Chatter"
	bCallHandler=false

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")
}
