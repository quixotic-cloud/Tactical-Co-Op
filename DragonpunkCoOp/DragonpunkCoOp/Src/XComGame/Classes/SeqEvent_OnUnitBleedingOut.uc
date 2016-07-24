class SeqEvent_OnUnitBleedingOut extends SeqEvent_X2GameState;

var XComGameState_Unit Unit;

static function FireEvent(XComGameState_Unit BleedingOutUnit)
{
	local array<SequenceObject> Events;
	local SeqEvent_OnUnitBleedingOut Event;
	local Sequence GameSeq;
	local int Index;

	if(BleedingOutUnit == none)
	{
		`Redscreen("SeqEvent_OnUnitBleedingOut called, but no unit provided!");
		return;
	}

	// Get the gameplay sequence.
	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	if (GameSeq == None) return;

	GameSeq.FindSeqObjectsByClass(class'SeqEvent_OnUnitBleedingOut', true, Events);
	for (Index = 0; Index < Events.length; Index++)
	{
		Event = SeqEvent_OnUnitBleedingOut(Events[Index]);
		`assert(Event != None);

		Event.Unit = BleedingOutUnit;
		Event.CheckActivate(BleedingOutUnit.GetVisualizer(), none);
	}
}

defaultproperties
{
	ObjName="On Unit Bleeding Out"
	ObjCategory="Unit"
	bPlayerOnly=FALSE
	MaxTriggerCount=0

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
}