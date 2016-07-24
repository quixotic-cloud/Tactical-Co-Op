class SeqEvent_OnUnitUnconscious extends SeqEvent_X2GameState;

var XComGameState_Unit Unit;

static function FireEvent(XComGameState_Unit UnconciousUnit)
{
	local array<SequenceObject> Events;
	local SeqEvent_OnUnitUnconscious Event;
	local Sequence GameSeq;
	local int Index;

	if(UnconciousUnit == none)
	{
		`Redscreen("SeqEvent_OnUnitUnconscious called, but no unit provided!");
		return;
	}

	// Get the gameplay sequence.
	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	if (GameSeq == None) return;

	GameSeq.FindSeqObjectsByClass(class'SeqEvent_OnUnitUnconscious', true, Events);
	for (Index = 0; Index < Events.length; Index++)
	{
		Event = SeqEvent_OnUnitUnconscious(Events[Index]);
		`assert(Event != None);

		Event.Unit = UnconciousUnit;
		Event.CheckActivate(UnconciousUnit.GetVisualizer(), none);
	}
}

defaultproperties
{
	ObjName="On Unit Unconscious"
	ObjCategory="Unit"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}