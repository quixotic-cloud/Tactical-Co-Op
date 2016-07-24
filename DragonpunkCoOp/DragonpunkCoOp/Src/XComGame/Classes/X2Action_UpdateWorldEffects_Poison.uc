//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UpdateWorldEffects_Poison extends X2Action;

var private array<ParticleSystem> PoisonParticleSystems;
var bool bCenterTile;

function SetParticleSystems(array<ParticleSystem> SetPoisonParticleSystems)
{
	PoisonParticleSystems = SetPoisonParticleSystems;
}

simulated state Executing
{
Begin:
	`XWORLD.UpdateVolumeEffects( XComGameState_WorldEffectTileData(Track.StateObject_NewState), PoisonParticleSystems, bCenterTile );

	CompleteAction();
}

defaultproperties
{
	bCenterTile = false;
}

