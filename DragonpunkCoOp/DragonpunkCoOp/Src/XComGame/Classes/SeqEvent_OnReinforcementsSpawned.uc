class SeqEvent_OnReinforcementsSpawned extends SeqEvent_GameEventTriggered;

event RegisterEvent()
{
	EventID = 'SpawnReinforcementsComplete';

	super.RegisterEvent();
}

function EventListenerReturn EventTriggered(Object EventData, Object EventSource, XComGameState GameState, Name InEventID)
{
	local XComGameState_AIReinforcementSpawner ReinforcementsState;

	ReinforcementsState = XComGameState_AIReinforcementSpawner(EventData);

	if( ReinforcementsState != None && ReinforcementsState.bKismetInitiatedReinforcements )
	{
		// no unit associated with this event, just fire it with the battle actor
		CheckActivate(`BATTLE, none);
	}

	return ELR_NoInterrupt;
}

DefaultProperties
{
	ObjName="Reinforcements Spawned"
}