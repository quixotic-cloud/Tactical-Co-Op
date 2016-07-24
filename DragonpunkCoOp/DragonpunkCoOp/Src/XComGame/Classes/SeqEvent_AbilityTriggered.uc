class SeqEvent_AbilityTriggered extends SeqEvent_GameEventTriggered
	native;

cpptext
{
	/** Fill dynamic list values */
	virtual void GetDynamicListValues(const FString& ListName, TArray<FString>& Values);

#if WITH_EDITOR
	virtual FString GetDisplayTitle() const;
#endif
}

// list of abilities that this event is listenting for
var() privatewrite string AbilityTemplateFilter<DynamicList = "AbilityTemplateFilter">;

var private string AbilityTemplate;

function EventListenerReturn EventTriggered(Object EventData, Object EventSource, XComGameState GameState, Name InEventID)
{
	local XComGameState_Ability Ability;
	
	Ability = XComGameState_Ability(EventData);
	if(Ability != none && GameState != none && 
	   XComGameStateContext_Ability(GameState.GetContext()).ResultContext.InterruptionStep <= 0) //Only trigger this on the first interrupt step
	{
		AbilityTemplate = string(Ability.GetMyTemplate().DataName);

		if(AbilityTemplateFilter == "" || AbilityTemplateFilter == AbilityTemplate)
		{
			return super.EventTriggered(EventData, EventSource, GameState, InEventID);
		}
	}

	return ELR_NoInterrupt;
}

DefaultProperties
{
	EventID="AbilityActivated"
	ObjCategory="Unit"
	ObjName="Unit Activated Ability"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=RelevantUnit,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="AbilityTemplate",PropertyName=AbilityTemplate,bWriteable=TRUE)
}
