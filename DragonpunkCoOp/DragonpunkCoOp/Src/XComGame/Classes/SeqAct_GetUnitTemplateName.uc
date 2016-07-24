class SeqAct_GetUnitTemplateName extends SequenceAction;

var name CharacterTemplateName;
var string CharacterTemplateString;
var XComGameState_Unit Unit;

event Activated()
{
	if (Unit != none)
	{
		CharacterTemplateName = Unit.GetMyTemplateName();
		CharacterTemplateString = string(Unit.GetMyTemplateName());
	}
}

defaultproperties
{
	ObjName="Get Character Template name from Unit"
	ObjCategory="Unit"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit,bWriteable=false)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Name',LinkDesc="Template",PropertyName=CharacterTemplateName,bWriteable=true)
	VariableLinks(2)=(ExpectedType=class'SeqVar_String',LinkDesc="TemplateString",PropertyName=CharacterTemplateString,bWriteable=true)
}