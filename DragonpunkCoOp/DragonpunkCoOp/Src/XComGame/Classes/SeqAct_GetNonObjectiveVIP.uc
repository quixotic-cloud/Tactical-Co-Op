class SeqAct_GetNonObjectiveVIP extends SequenceAction;

var XComGameState_Unit Unit;

event Activated()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;

	History = `XCOMHISTORY;

	// Create the unit state. This takes a few different paths depending on whether we are in the start state
	// and if we have a reward unit to use
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	Unit = none;
	if(BattleData.RewardUnits.Length > 0)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(BattleData.RewardUnits[0].ObjectID));
		if(Unit.GetTeam() != eTeam_XCom)
		{
			`Redscreen("SeqAct_GetNonObjectiveVIP: VIP is not on the XCom team, this is probably a bug! Talk to David B.");
		}
	}
}

defaultproperties
{
	ObjName="Get Non-Objective VIP"
	ObjCategory="Procedural Missions"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit,bWriteable=true)
}