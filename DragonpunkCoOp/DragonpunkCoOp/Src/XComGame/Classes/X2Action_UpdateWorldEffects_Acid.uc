//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UpdateWorldEffects_Acid extends X2Action;

var private array<ParticleSystem> AcidParticleSystems;
var bool bCenterTile;

function SetParticleSystems(array<ParticleSystem> SetAcidParticleSystems)
{
	AcidParticleSystems = SetAcidParticleSystems;
}

simulated state Executing
{
Begin:
	`XWORLD.UpdateVolumeEffects(XComGameState_WorldEffectTileData(Track.StateObject_NewState), AcidParticleSystems, bCenterTile);

	CompleteAction();
}

defaultproperties
{
	bCenterTile = false;
}

