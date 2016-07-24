class SeqAct_RedAlert extends SequenceAction;

var private XComGameState_Unit AlertUnit;

event Activated()
{
	local XComGameStateHistory History;
	local SeqVar_GameUnit kGameUnit;
	local XComGameState_Unit Unit;

	History = `XCOMHISTORY;

	foreach LinkedVariables(class'SeqVar_GameUnit', kGameUnit, "Alert Unit")
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(kGameUnit.IntValue));
		break;
	}

	if( Unit != none)
	{
		Unit.ApplyAlertAbilityForNewAlertData(eAC_TakingFire);
		Unit.GetGroupMembership().InitiateReflexMoveActivate(Unit, eAC_SeesSpottedUnit);
	}
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Red Alert"
	bConvertedForReplaySystem=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit', LinkDesc = "Alert Unit", PropertyName=AlertUnit)
}