/**
 * Removes a unit from the battle without killing them.
 */
class SeqAct_ExitLevel extends SequenceAction;

var XComGameState_Unit Unit;

event Activated()
{
	local XComGameState NewGameState;

	if(Unit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_ExitLevel: " @ Unit.GetVisualizer() @ " (" @ Unit.ObjectID @ ")");
		Unit.EvacuateUnit(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

defaultproperties
{
	ObjName="Unit Exit Level"
	ObjCategory="Unit"
	bCallHandler=false
	bAutoActivateOutputLinks=true;

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit,bWriteable=TRUE)
}
