class SeqEvent_OnUnitKilled extends SeqEvent_X2GameState;

var XComGameState_Unit Unit;
var string EncounterID;
var int EncounterUnitsRemaining;

static function FireEvent(XComGameState_Unit KilledUnit)
{
	local array<SequenceObject> Events;
	local SeqEvent_OnUnitKilled Event;
	local Sequence GameSeq;
	local int Index;
	local XComGameStateHistory History;
	local XComGameState_AIGroup AIGroupState;
	local XComGameState_Unit AIGroupMemberState;
	local int GroupUnitIndex;

	if(KilledUnit == none)
	{
		`Redscreen("SeqEvent_OnUnitKilled called, but no unit provided!");
		return;
	}

	// Get the gameplay sequence.
	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	if (GameSeq == None) return;

	GameSeq.FindSeqObjectsByClass(class'SeqEvent_OnUnitKilled', true, Events);
	for (Index = 0; Index < Events.length; Index++)
	{
		Event = SeqEvent_OnUnitKilled(Events[Index]);
		`assert(Event != None);

		Event.Unit = KilledUnit;
			
		AIGroupState = KilledUnit.GetGroupMembership();

		// update the EncounterID and number of remaining living group members from this group
		Event.EncounterID = string(AIGroupState.EncounterID);
		Event.EncounterUnitsRemaining = 0;

		History = `XCOMHISTORY;
		for( GroupUnitIndex = 0; GroupUnitIndex < AIGroupState.m_arrMembers.Length; ++GroupUnitIndex )
		{
			AIGroupMemberState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroupState.m_arrMembers[GroupUnitIndex].ObjectID));
			if( AIGroupMemberState.IsAlive() )
			{
				++Event.EncounterUnitsRemaining;
			}
		}

		Event.CheckActivate(KilledUnit.GetVisualizer(), none);
	}
}

defaultproperties
{
	ObjName="On Unit Killed";
	ObjCategory="Unit";
	bPlayerOnly=FALSE;
	MaxTriggerCount=0;

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="EncounterID",PropertyName=EncounterID)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int',LinkDesc="EncounterUnitsRemaining",PropertyName=EncounterUnitsRemaining)
}