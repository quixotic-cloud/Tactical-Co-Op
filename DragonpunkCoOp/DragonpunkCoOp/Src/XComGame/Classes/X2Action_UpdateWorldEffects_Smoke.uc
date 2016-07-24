//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UpdateWorldEffects_Smoke extends X2Action;

var private array<ParticleSystem> SmokeParticleSystems;
var bool bCenterTile;

function SetParticleSystems(array<ParticleSystem> SetSmokeParticleSystems)
{
	SmokeParticleSystems = SetSmokeParticleSystems;
}

simulated state Executing
{
Begin:	
	`XWORLD.UpdateVolumeEffects( XComGameState_WorldEffectTileData(Track.StateObject_NewState), SmokeParticleSystems, bCenterTile );

	CompleteAction();
}

defaultproperties
{
	bCenterTile = true;
}

