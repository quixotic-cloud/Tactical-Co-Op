class SeqEvent_OnInteractiveObjectBeginPlay extends SeqEvent_X2GameState;

var XComGameState_InteractiveObject InteractiveObject;

static function FireEvent(XComGameState_InteractiveObject InteractiveObjectState)
{
	local array<SequenceObject> Events;
	local SeqEvent_OnInteractiveObjectBeginPlay Event;
	local Sequence GameSeq;
	local int Index;

	if( InteractiveObjectState == None )
	{
		return;
	}

	// Get the gameplay sequence.
	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	if( GameSeq == None )
	{
		return;
	}

	GameSeq.FindSeqObjectsByClass(class'SeqEvent_OnInteractiveObjectBeginPlay', true, Events);
	for (Index = 0; Index < Events.length; Index++)
	{
		Event = SeqEvent_OnInteractiveObjectBeginPlay(Events[Index]);
		if( Event != None )
		{
			Event.InteractiveObject = InteractiveObjectState;
			Event.CheckActivate(InteractiveObjectState.GetVisualizer(), None);
		}
	}
}

defaultproperties
{
	ObjName="On Interactive Object Begin Play";
	ObjCategory="Gameplay";
	bPlayerOnly=FALSE;
	MaxTriggerCount=0;

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="InteractiveObject",PropertyName=InteractiveObject,bWriteable=true)
}