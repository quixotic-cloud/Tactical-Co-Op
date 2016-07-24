class SeqAct_EnableGlobalAbilityForUnit extends SequenceAction;

var() name AbilityName;
var XComGameState_Unit Unit;

event Activated()
{
	local XComGameState NewGameState;
	local XComGameState_Unit NewUnitState;

	if (Unit != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Kismet - EnableGlobalAbilityForUnit");
		NewUnitState = XComGameState_Unit(NewGameState.CreateStateObject(Unit.Class, Unit.ObjectID));
		NewUnitState.EnableGlobalAbilityForUnit(AbilityName);
		NewGameState.AddStateObject(NewUnitState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

DefaultProperties
{
	ObjName="Enable Global Ability For Unit"
	ObjCategory="Unit"
	bCallHandler=false
	bAutoActivateOutputLinks=true;

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}