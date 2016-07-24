class SeqAct_GetUnitByCharacterTemplate extends SequenceAction;

var name CharacterTemplateName;
var XComGameState_Unit Unit;

event Activated()
{
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.GetMyTemplateName() == CharacterTemplateName)
		{
			return;
		}
	}

	// no such unit template was found
	`Redscreen("SeqAct_GetUnitByCharacterTemplate: Could not find a unit with template " $ string(CharacterTemplateName));
	Unit = none;
}

defaultproperties
{
	ObjName="Get Unit By Character Template"
	ObjCategory="Unit"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_Name',LinkDesc="Template",PropertyName=CharacterTemplateName)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit,bWriteable=true)
}