class SeqAct_CallReinforcements extends SequenceAction
	dependson(XComAISpawnManager);

// If >1, this value overrides the number of AI turns until reinforcements are spawned.
var() int OverrideCountdown;

// If bUseOverrideTargetLocation is true, this value overrides the target location for the next reinforcement group to spawn.
var() Vector OverrideTargetLocation;
var() bool bUseOverrideTargetLocation;

// When spawning using the OverrideTargatLocation, offset the spawner by this amount of tiles.
var() int IdealSpawnTilesOffset;

// The Name of the Reinforcement Encounter (defined in DefaultMissions.ini) that will be called in
var() Name EncounterID;

event Activated()
{
	class'XComGameState_AIReinforcementSpawner'.static.InitiateReinforcements(EncounterID, OverrideCountdown, bUseOverrideTargetLocation, OverrideTargetLocation, IdealSpawnTilesOffset, , true);
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Call Reinforcements"
	bConvertedForReplaySystem=true
}