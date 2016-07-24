class SeqEvent_OnInteractiveObjectHacked extends SeqEvent_X2GameState;

var XComGameState_InteractiveObject InteractiveObject;
var XComGameState_Unit InteractingUnit;

static function FireEvent(XComGameState_InteractiveObject InteractiveObjectState, XComGameState_Unit Unit)
{
	local array<SequenceObject> Events;
	local SeqEvent_OnInteractiveObjectHacked Event;
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

	GameSeq.FindSeqObjectsByClass(class'SeqEvent_OnInteractiveObjectHacked', true, Events);
	for (Index = 0; Index < Events.length; Index++)
	{
		Event = SeqEvent_OnInteractiveObjectHacked(Events[Index]);
		if( Event != None )
		{
			Event.InteractiveObject = InteractiveObjectState;
			Event.InteractingUnit = Unit;
			Event.CheckActivate(InteractiveObjectState.GetVisualizer(), None);
		}
	}
}

defaultproperties
{
	ObjName="On Interactive Object Hacked";
	ObjCategory="Gameplay";
	bPlayerOnly=FALSE;
	MaxTriggerCount=0;

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="InteractiveObject",PropertyName=InteractiveObject,bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="InteractingUnit",PropertyName=InteractingUnit,bWriteable=true)
}