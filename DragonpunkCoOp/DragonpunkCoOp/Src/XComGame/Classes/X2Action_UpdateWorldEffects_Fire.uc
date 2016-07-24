//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_UpdateWorldEffects_Fire extends X2Action;

var private array<ParticleSystem> FireParticleSystems;

var private bool syncWithOtherAction;
var private bool endSync;

var private array<TTile> PendingTiles;

var private array<TTile> ActivatedTiles;

var bool bCenterTile;

function SetParticleSystems(array<ParticleSystem> SetFireParticleSystems)
{
	FireParticleSystems = SetFireParticleSystems;
}

function BeginSyncWithOtherAction()
{
	syncWithOtherAction = true;
}

function EndSyncWithOtherAction()
{
	syncWithOtherAction = false;
	endSync = true;
}

function SetActiveTiles(out array<TTile> tiles)
{
	local int i, j;
	local bool foundTile;

	PendingTiles.length = 0;
	for (i = 0; i < tiles.length; i++)
	{
		foundTile = false;
		for (j = 0; j < ActivatedTiles.length; j++)
		{
			if (tiles[i] == ActivatedTiles[j])
			{
				foundTile = true;
				break;
			}
		}

		if (foundTile == false)
		{
			PendingTiles.AddItem(tiles[i]);
		}
	}
}

simulated state Executing
{
	simulated event Tick( float fDeltaT )
	{	
		local int i;

		if (syncWithOtherAction)
		{
			`log( "Syncing with another action " @ self );
			if (PendingTiles.length > 0)
			{
				`XWORLD.UpdateVolumeEffects_PartialUpdate(XComGameState_WorldEffectTileData(Track.StateObject_NewState), PendingTiles, true, FireParticleSystems, bCenterTile);
				for (i = 0; i < PendingTiles.length; i++)
				{
					ActivatedTiles.AddItem(PendingTiles[i]);
				}
				PendingTiles.length = 0;
			}
		}
		else if (endSync)
		{
			`log( "ending sync with another action" );
			`XWORLD.UpdateVolumeEffects_PartialUpdate(XComGameState_WorldEffectTileData(Track.StateObject_NewState), ActivatedTiles, false, FireParticleSystems, bCenterTile);
			CompleteAction();
		}
		else
		{
			`XWORLD.UpdateVolumeEffects(XComGameState_WorldEffectTileData(Track.StateObject_NewState), FireParticleSystems, bCenterTile);		
			CompleteAction();
		}
	}

Begin:
	//`XWORLD.UpdateVolumeEffects(XComGameState_WorldEffectTileData(Track.StateObject_NewState), FireParticleSystems, false);
	//CompleteAction();
}

defaultproperties
{
	syncWithOtherAction = false;
	endSync = false;
	bCenterTile = false;
}

