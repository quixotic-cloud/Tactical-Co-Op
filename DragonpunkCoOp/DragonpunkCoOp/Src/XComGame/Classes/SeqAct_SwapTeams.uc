class SeqAct_SwapTeams extends SequenceAction;

var XComGameState_Unit Unit;
var() ETeam DestinationTeam;

event Activated()
{
	if( Unit != none )
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