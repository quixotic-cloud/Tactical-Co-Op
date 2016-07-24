//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ApplyWeaponDamageToTerrain extends X2Action config(Camera)
	native(Core);

var const config float CameraShakeIntensity_Large;
var const config int CameraShakeTileThreshold_Large;
var const config string CameraShake_Large;

var const config float CameraShakeIntensity_Medium;
var const config int CameraShakeTileThreshold_Medium;
var const config string CameraShake_Medium;

var const config float CameraShakeIntensity_Small;
var const config int CameraShakeTileThreshold_Small;
var const config string CameraShake_Small;

var const float delayPartialActivation;

var private XComGameState_EnvironmentDamage DamageEvent;
var private XComGameState_Destructible TargetedDestructible;
var private float DamageInfluenceRadiusMultiplier;

var private bool bRequiresTick;
var private bool bFinishedTick;
var private array<TTile> partialActiveTiles;

struct native DelayTile
{
	var float currentTick;
	var TTile tile;
};

var private array<DelayTile> fullPartialTiles;


function DoPartialTileUpdate(out array<TTile> tiles)
{
	bRequiresTick = true;
	partialActiveTiles = tiles;
}

function FinishPartialTileUpdate()
{
	bRequiresTick = false;
	bFinishedTick = true;

	partialActiveTiles.length = 0;
}

// It's possible there are mutliple damage events in this game state. If that is the case,
// then we need to find the one that matches the damage dealt to the targeted destructible
native function XComGameState_EnvironmentDamage FindMatchingDamageEvent(XComGameStateContext Context);

native function UpdatePartialTileUpdate( float fDelta );

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);

	// usually, the track object is the damage state
	DamageEvent = XComGameState_EnvironmentDamage(InTrack.StateObject_NewState);

	// it may be a targeted explosion against a single destructible, however
	if(DamageEvent == none)
	{
		TargetedDestructible = XComGameState_Destructible(InTrack.StateObject_NewState);
		DamageEvent = FindMatchingDamageEvent(StateChangeContext);
	}

	// if the thing isn't targetable, it's okay to not have a damage state.
	// the visualizer will updated from regular environmental damage
	if ((DamageEvent == none) && XComDestructibleActor(TargetedDestructible.GetVisualizer()).IsTargetable())
	{
		`Redscreen("X2Action_ApplyWeaponDamageToTerrain: No Damage event found!");
	}
}

simulated state Executing
{
	simulated event BeginState(name nmPrevState)
	{
		super.BeginState(nmPrevState);
	}

	simulated function SpawnExplosionParticles()
	{
		local ParticleSystem Explosion;

		Explosion = ParticleSystem(DynamicLoadObject("FX_Explosion_Grenade_Launcher.P_Grenade_Launcher_Explosion", class'ParticleSystem'));
		WorldInfo.MyEmitterPool.SpawnEmitter(Explosion, DamageEvent.HitLocation);
	}

	simulated function ShowDamagePopup()
	{	
		local XComUIBroadcastWorldMessage kBroadcastWorldMessage;
		local XComDestructibleActor DestructibleActor;
		local Vector DisplayLocation;
		local UIUnitFlag UnitFlags;
		local XComPresentationLayer PresentationLayer;

		PresentationLayer = `PRES;

		if(TargetedDestructible != none)
		{
			DestructibleActor = XComDestructibleActor(TargetedDestructible.GetVisualizer());
			if(DestructibleActor != None)
			{
				DisplayLocation = DestructibleActor.GetTargetingFocusLocation();

				kBroadcastWorldMessage = class'UIWorldMessageMgr'.static.DamageDisplay(DisplayLocation, DestructibleActor.GetVisualizedStateReference(), "", eTeam_All, class'XComUIBroadcastWorldMessage_DamageDisplay', DamageEvent.DamageAmount);
				if(kBroadcastWorldMessage != none)
				{
					XComUIBroadcastWorldMessage_DamageDisplay(kBroadcastWorldMessage).Init_DisplayDamage(eUIBWMDamageDisplayType_Hit, DisplayLocation, DestructibleActor.GetVisualizedStateReference(), DamageEvent.DamageAmount, eTeam_All);
				}

				UnitFlags = `PRES.m_kUnitFlagManager.GetFlagForObjectID( DestructibleActor.ObjectID );
				UnitFlags.RespondToNewGameState(StateChangeContext.GetLastStateInInterruptChain( ), false);
			}
		}

		PresentationLayer.m_kUnitFlagManager.RealizeCover( -1, StateChangeContext.AssociatedState.HistoryIndex );
	}

	function NearbyUnitsUpdateStance()
	{
		local XComGameState_Unit UnitState;
		local XGUnit UnitVisualizer;
		local XComGameStateHistory History;
		local float DistanceFromHitLocation;
		local float CheckForStanceUpdateRadius;
		local float FlinchRadius;

		CheckForStanceUpdateRadius = DamageEvent.DamageRadius + class'XComWorldData'.const.WORLD_StepSize * DamageInfluenceRadiusMultiplier;

		//Threshold for cosmetic / incidental environmental damage such as door kicks, window smashes, bullets passing through things. We don't want gratuitous flinching.
		if(DamageEvent.DamageRadius <= 16.0f) 
		{
			FlinchRadius = DamageEvent.DamageRadius + (class'XComWorldData'.const.WORLD_StepSize * 2.0f);
		}
		else
		{
			FlinchRadius = CheckForStanceUpdateRadius;
		}
		

		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if(UnitState.IsAlive() && !UnitState.bRemovedFromPlay)
			{
				UnitVisualizer = XGUnit(UnitState.GetVisualizer());
				if (UnitVisualizer.GetPawn().Physics != PHYS_RigidBody)
				{
					DistanceFromHitLocation = VSize(UnitVisualizer.Location - DamageEvent.HitLocation);
					if(DistanceFromHitLocation <= CheckForStanceUpdateRadius)
					{
						//Notify nearby units that they may need to change their stance
						UnitVisualizer.IdleStateMachine.CheckForStanceUpdateOnIdle();

						//If the unit isn't doing anything, play a flinch
						if(UnitVisualizer.GetNumVisualizerTracks() == 0 && DistanceFromHitLocation <= FlinchRadius)
						{
							UnitVisualizer.IdleStateMachine.PerformFlinch();
						}
					}
				}
			}
		}
	}

	function InitiateCameraShakeAndDistort()
	{		
		local string ShakeAnim;
		local float Intensity;

		if(DamageEvent.DamageTiles.Length < default.CameraShakeTileThreshold_Medium)
		{
			ShakeAnim = default.CameraShake_Small;
			Intensity = default.CameraShakeIntensity_Small;
		}
		else if(DamageEvent.DamageTiles.Length < default.CameraShakeTileThreshold_Large)
		{
			ShakeAnim = default.CameraShake_Medium;
			Intensity = default.CameraShakeIntensity_Medium;
		}
		else
		{
			ShakeAnim = default.CameraShake_Large;
			Intensity = default.CameraShakeIntensity_Large;
		}
				
		`CAMERASTACK.PlayCameraAnim(ShakeAnim, 1.0f, Intensity, false, true);
		`PRES.StartDistortUI(2.5f);
	}


	simulated event Tick(float fDeltaT)
	{
		if (bRequiresTick)
		{
			UpdatePartialTileUpdate(fDeltaT);
		}
		else if (bFinishedTick)
		{
			//foreach DamageEvent.FractureTiles(iterTile)
			//{
			//	//iterTile.Z = 92;
			//	`SHAPEMGR.DrawTile(iterTile, 0, 255, 255, 0.4);
			//}

			if (DamageEvent.DamageTiles.Length > default.CameraShakeTileThreshold_Small)
			{
				InitiateCameraShakeAndDistort();
			}

			`XWORLD.HandleDestructionVisuals(DamageEvent);
		}
	}

Begin:

	if(DamageEvent != none)
	{
		NearbyUnitsUpdateStance();

		if (bRequiresTick)
		{
			while (!bFinishedTick)
			{
				sleep(0.01f);
			}
		}
		else
		{
			if (DamageEvent.DamageTiles.Length > default.CameraShakeTileThreshold_Small)
			{
				InitiateCameraShakeAndDistort();
			}

			`XWORLD.HandleDestructionVisuals(DamageEvent);

			`XEVENTMGR.TriggerEvent('HandleDestructionVisuals', self, self, none);
		}

		ShowDamagePopup();

		// temporary until we figure out how damage is going to be visualized, spawn
		// an explosion for explosion damage
		if(DamageEvent.bSpawnExplosionVisuals)
		{
			SpawnExplosionParticles();
		}
	}

	CompleteAction();
}

DefaultProperties
{
	DamageInfluenceRadiusMultiplier = 5.0

	delayPartialActivation = 0.5;
}
