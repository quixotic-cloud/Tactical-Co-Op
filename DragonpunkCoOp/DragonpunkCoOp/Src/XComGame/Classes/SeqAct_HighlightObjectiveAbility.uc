class SeqAct_HighlightObjectiveAbility extends SequenceAction;

var() name AbilityName;

event Activated()
{
	if(InputLinks[0].bHasImpulse == InputLinks[1].bHasImpulse)
	{
		`Redscreen("SeqAct_HighlightObjectiveAbility:\n Both enable and disable links are set!\n" $ Name);
	}

	class'XComGameState_BattleData'.static.HighlightObjectiveAbility(AbilityName, InputLinks[0].bHasImpulse);
}

DefaultProperties
{
	ObjName="Enable/Disable Objective Ability Highlight"
	ObjCategory="Unit"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
}