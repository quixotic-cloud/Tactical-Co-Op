//-----------------------------------------------------------
//Enables or disables a unit's moves and ai
//-----------------------------------------------------------
class SeqAct_SetUnitEnabled extends SequenceAction;

var XComGameState_Unit Unit;

event Activated()
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	if (Unit == none) return;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_SetUnitEnabled: " @ Unit.GetVisualizer() @ " (" @ Unit.ObjectID @ ")");

	NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
	NewUnitState.bDisabled = InputLinks[1].bHasImpulse;
	
	NewGameState.AddStateObject(NewUnitState);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Set Unit Enabled"
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")
	
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}
