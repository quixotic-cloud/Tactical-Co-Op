class X2Effect_SwitchToRobot extends X2Effect_SpawnUnit;

function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetTargetUnitsTeam(ApplyEffectParameters, true);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit DeadUnitGameState;
	local X2EventManager EventManager;
	local XComGameState_Unit RobotGameState;

	EventManager = `XEVENTMGR;

	DeadUnitGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( DeadUnitGameState == none )
	{
		DeadUnitGameState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID, eReturnType_Reference));
	}
	`assert(DeadUnitGameState != none);

	// Remove the Andromedon unit from play
	EventManager.TriggerEvent('UnitRemovedFromPlay', DeadUnitGameState, DeadUnitGameState, NewGameState);

	// The Robot needs to be messaged to reboot
	RobotGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	`assert(RobotGameState != none);

	EventManager.TriggerEvent('AndromedonToRobot', RobotGameState, RobotGameState, NewGameState);
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationTrack SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationTrack EffectTargetUnitTrack)
{
	local XComGameStateHistory History;
	local X2Action_AndromedonRobotSpawn RobotSpawn;

	History = `XCOMHISTORY;

	// The Spawned unit should appear and play its change animation
	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context);

	// The Spawned unit should appear and play its change animation
	RobotSpawn = X2Action_AndromedonRobotSpawn(class'X2Action_AndromedonRobotSpawn'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
	RobotSpawn.AndromedonUnit = XGUnit(History.GetVisualizer(EffectTargetUnit.ObjectID));
}

defaultproperties
{
	UnitToSpawnName="AndromedonRobot"
	bClearTileBlockedByTargetUnitFlag=true
}