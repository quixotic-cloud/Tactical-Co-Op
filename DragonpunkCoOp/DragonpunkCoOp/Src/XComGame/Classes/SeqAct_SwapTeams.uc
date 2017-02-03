class SeqAct_SwapTeams extends SequenceAction;

var XComGameState_Unit Unit;
var() ETeam DestinationTeam;

event Activated()
{
	local array<StateObjectReference> VisibleUnits;
	class'X2TacticalVisibilityHelpers'.static.GetAllVisibleUnitsOnTeamForSource(Unit.ObjectID,eTeam_XCOM,VisibleUnits);
	if( Unit.GetTeam() != eTeam_XCOM && Unit.GetMyTemplate().Abilities.Find('Evac') != -1 && VisibleUnits.Length > 0)
	{
		`BATTLE.SwapTeams(Unit, DestinationTeam);
		OutputLinks[0].bHasImpulse = true;
	}
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Swap Teams"
	bCallHandler = false
	DestinationTeam = eTeam_XCom

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	bAutoActivateOutputLinks = true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}