//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Fire_Flamethrower extends X2Action_Fire config(GameCore);

var config string SecondaryFire_ParticleEffectPath;
var config float LengthUpdateSpeed;
var config float SweepDuration;
var config float FireChance_Level1, FireChance_Level2, FireChance_Level3;
var config array<Name> ParticleSystemsForLength;

var X2AbilityMultiTarget_Cone coneTemplate;
var float ConeLength, ConeWidth;

var Vector StartLocation, EndLocation;
var Vector UnitDir, ConeDir;

var Vector SweepEndLocation_Begin, SweepEndLocation_End;
var float ArcDelta, ConeAngle;


var private bool beginAimingAnim; //need to know when aiming has occurred and is finished
var private bool endAimingAnim;

var private float currDuration;

var XComGameState_Ability AbilityState;
var array<TTile> SecondaryTiles;

var private float CurrentFlameLength;
var private float TargetFlameLength;
var private bool bWaitingToFire;

var private array<StateObjectReference> alreadySignaledTracks;

function bool FindTrack(StateObjectReference find)
{
	local int i;
	for (i = 0; i < alreadySignaledTracks.Length; i++)
	{
		if (find == alreadySignaledTracks[i])
		{
			return true;
		}
	}

	return false;
}

function bool FindTile(TTile tile, out array<TTile> findArray)
{
	local TTile iter;
	foreach findArray(iter)
	{
		if (iter == tile)
		{
			return true;
		}
	}

	return false;
}

function bool FindSameXYTile(TTile tile, out array<TTile> findArray)
{
	local TTile iter;
	foreach findArray(iter)
	{
		if (iter.X == tile.X && iter.Y == tile.Y)
		{
			return true;
		}
	}

	return false;
}


function Init(const out VisualizationTrack InTrack)
{
	local Vector TempDir;

	super.Init(InTrack);

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	if (AbilityState.GetMyTemplate().TargetingMethod == class'X2TargetingMethod_Cone')
	{
		coneTemplate = X2AbilityMultiTarget_Cone(AbilityState.GetMyTemplate().AbilityMultiTargetStyle);

		ConeLength = coneTemplate.GetConeLength(AbilityState);
		ConeWidth = coneTemplate.GetConeEndDiameter(AbilityState) * 1.35;

		StartLocation = UnitPawn.Location;
		EndLocation = AbilityContext.InputContext.TargetLocations[0];
		
		ConeDir = EndLocation - StartLocation;
		UnitDir = Normal(ConeDir);

		ConeAngle = ConeWidth / ConeLength;

		ArcDelta = ConeAngle / SweepDuration;

		TempDir.x = UnitDir.x * cos(-ConeAngle / 2) - UnitDir.y * sin(-ConeAngle / 2);
		TempDir.y = UnitDir.x * sin(-ConeAngle / 2) + UnitDir.y * cos(-ConeAngle / 2);
		TempDir.z = UnitDir.z;

		SweepEndLocation_Begin = StartLocation + (TempDir * ConeLength);

		TempDir.x = UnitDir.x * cos(ConeAngle / 2) - UnitDir.y * sin(ConeAngle / 2);
		TempDir.y = UnitDir.x * sin(ConeAngle / 2) + UnitDir.y * cos(ConeAngle / 2);
		TempDir.z = UnitDir.z;

		SweepEndLocation_End = StartLocation + (TempDir * ConeLength);

		SecondaryTiles = AbilityContext.InputContext.VisibleNeighborTiles;
	}

	currDuration = 0.0;
	beginAimingAnim = false;
	endAimingAnim = false;

	CurrentFlameLength = -1.0;
	TargetFlameLength = -1.0;
}

function AddProjectileVolley(X2UnifiedProjectile NewProjectile)
{
	bWaitingToFire = false;
}

simulated state Executing
{
	simulated event Tick(float fDeltaT)
	{
		UpdateAim(fDeltaT);
	}

	simulated function UpdateAim(float DT)
	{
		local ParticleSystemComponent p;
		local int i;
		local float angle;
		local Vector TempDir, lineEndLoc;
		local float length;
		local TTile tile, tempTile;
		local TTile iterTile;
		local XComGameState_Unit targetObject;

		local array<TTile> cornerTiles;

		local StateObjectReference Target;
		local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
		local XComGameState_InteractiveObject InteractiveObject;
		local XComGameState_WorldEffectTileData WorldEffectTileData;
		local array<X2Action> worldEffectFireActionArray;
		local X2Action_UpdateWorldEffects_Fire worldEffectFireAction;
		local X2Action_ApplyWeaponDamageToTerrain terrainDamage;
		local Vector SetParticleVector;

		local array<TTile> lineTiles;
	
		local vector HitNormal;
		local Actor HitActor;

		//find endlocation of target arc
		angle = ArcDelta * currDuration;
		angle = angle - (ConeAngle / 2);

		TempDir.x = UnitDir.x * cos(angle) - UnitDir.y * sin(angle);
		TempDir.y = UnitDir.x * sin(angle) + UnitDir.y * cos(angle);
		TempDir.z = UnitDir.z;

		EndLocation = StartLocation + (TempDir * ConeLength);

		//Modify EndLocation based on any hits against the world
		`XWORLD.WorldTrace(StartLocation, EndLocation, EndLocation, HitNormal, HitActor, 4);
		
		//`SHAPEMGR.DrawLine(StartLocation, EndLocation, 6, MakeLinearColor(1.0f, 0.5f, 0.5f, 0.7f));
		//`SHAPEMGR.DrawLine(StartLocation, SweepEndLocation_Begin, 6, MakeLinearColor(0.0f, 0.0f, 1.0f, 1.0f));
		//`SHAPEMGR.DrawLine(StartLocation, SweepEndLocation_End, 6, MakeLinearColor(1.0f, 1.0f, 0.0f, 1.0f));
		//`SHAPEMGR.DrawSphere(EndLocation, Vect(10, 10, 10), MakeLinearColor(0.0f, 1.0f, 0.0f, 1.0f));

		if (UnitPawn.AimEnabled)
		{
			if (!beginAimingAnim)
			{
				beginAimingAnim = true;
			}

			tile = `XWORLD.GetTileCoordinatesFromPosition(EndLocation);

			//find all the tiles in the current line of fire
			tempTile = tile;
			//tempTile.Z = 0;
			lineTiles.AddItem(tempTile);
			lineEndLoc = EndLocation;
			while (VSize(lineEndLoc - StartLocation) > class'XComWorldData'.const.WORLD_StepSize)
			{
				lineEndLoc -= (TempDir * class'XComWorldData'.const.WORLD_HalfStepSize);
				tempTile = `XWORLD.GetTileCoordinatesFromPosition(lineEndLoc);
				//tempTile.Z = 0;
				if (FindTile(tempTile, lineTiles) == false)
				{
					lineTiles.AddItem(tempTile);
				}
			}

			//find all the possible secondarytiles to the line of fire
			cornerTiles.length = 0;
			foreach lineTiles(iterTile)
			{
				tempTile = iterTile;
				tempTile.X += 1;
				if (FindTile(tempTile, SecondaryTiles))
				{
					cornerTiles.AddItem(tempTile);
					SecondaryTiles.RemoveItem(tempTile);
				}

				tempTile = iterTile;
				tempTile.X -= 1;
				if (FindTile(tempTile, SecondaryTiles))
				{
					cornerTiles.AddItem(tempTile);
					SecondaryTiles.RemoveItem(tempTile);
				}

				tempTile = iterTile;
				tempTile.Y += 1;
				if (FindTile(tempTile, SecondaryTiles))
				{
					cornerTiles.AddItem(tempTile);
					SecondaryTiles.RemoveItem(tempTile);
				}

				tempTile = iterTile;
				tempTile.Y -= 1;
				if (FindTile(tempTile, SecondaryTiles))
				{
					cornerTiles.AddItem(tempTile);
					SecondaryTiles.RemoveItem(tempTile);
				}
			}

			//blend aim anim
			//`log("Endlocation " @ EndLocation @ " angle : " @ angle @ " ConeAngle: " @ ConeAngle );
			UnitPawn.TargetLoc = EndLocation;
		}

		if( beginAimingAnim && !UnitPawn.AimEnabled && !bWaitingToFire )
		{
			endAimingAnim = true;
		}

		//foreach AbilityContext.InputContext.VisibleTargetedTiles(iterTile)
		//{
		//	//iterTile.Z = 92;
		//	`SHAPEMGR.DrawTile(iterTile, 0, 255, 0);
		//}
		//foreach AbilityContext.InputContext.VisibleNeighborTiles(iterTile)
		//{
		//	iterTile.Z = 92;
		//	`SHAPEMGR.DrawTile(iterTile, 0, 0, 255);
		//}
		//foreach CornerTiles(iterTile)
		//{
		//	iterTile.Z = 92;
		//	`SHAPEMGR.DrawTile(iterTile, 0, 0, 255);
		//}
		//foreach lineTiles(iterTile)
		//{
		//	//iterTile.Z = 92;
		//	`SHAPEMGR.DrawTile(iterTile, 0, 0, 5, 0.8 );
		//}

		length = VSize(EndLocation - StartLocation);

		TargetFlameLength = length;

		if (CurrentFlameLength == -1.0)
		{
			CurrentFlameLength = length;
		}
		else
		{
			if (CurrentFlameLength < TargetFlameLength)
			{
				CurrentFlameLength = Min(TargetFlameLength, CurrentFlameLength + (LengthUpdateSpeed / DT));

			}
			else if (CurrentFlameLength > TargetFlameLength)
			{
				CurrentFlameLength = Max(TargetFlameLength, CurrentFlameLength - (LengthUpdateSpeed / DT));
			}
		}


		SetParticleVector.X = CurrentFlameLength;
		SetParticleVector.Y = CurrentFlameLength;
		SetParticleVector.Z = CurrentFlameLength;

		foreach UnitPawn.AllOwnedComponents(class'ParticleSystemComponent', p)
		{
			if( ParticleSystemsForLength.Find(p.Template.Name) != INDEX_NONE )
			{
				p.SetFloatParameter('Flamethrower_Length', CurrentFlameLength);
				p.SetVectorParameter('Flamethrower_Length', SetParticleVector);
			}
		}


		//send intertract updates if the tiles are in line
		foreach AbilityContext.InputContext.MultiTargets(Target)
		{
			targetObject = XComGameState_Unit(History.GetGameStateForObjectID(Target.ObjectID));
			if (FindSameXYTile(targetObject.TileLocation, lineTiles) && (!FindTrack(Target)) )
			{
				VisualizationMgr.SendInterTrackMessage(Target);
				alreadySignaledTracks.AddItem(Target);
			}
		}

		foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
		{
				Target = EnvironmentDamageEvent.GetReference();
				if (!FindTrack(Target))
				{
					VisualizationMgr.SendInterTrackMessage(Target);
					alreadySignaledTracks.AddItem(Target);
				}

				worldEffectFireActionArray = `XCOMVISUALIZATIONMGR.GetCurrentWorldEffectTrackAction(class'X2Action_ApplyWeaponDamageToTerrain', class'X2Action_WaitForAbilityEffect', VisualizeGameState.HistoryIndex, Target);
				for (i = 0; i < worldEffectFireActionArray.length; i++)
				{
					terrainDamage = X2Action_ApplyWeaponDamageToTerrain(worldEffectFireActionArray[i]);
					if (terrainDamage != none)
					{
						if (!endAimingAnim)
						{
							terrainDamage.DoPartialTileUpdate(lineTiles);
						}
						else
						{
							terrainDamage.FinishPartialTileUpdate();
						}
					}
				}
		}

		foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
		{
			Target = InteractiveObject.GetReference();
			if (FindSameXYTile(InteractiveObject.TileLocation, lineTiles) && (!FindTrack(Target)))
			{
				VisualizationMgr.SendInterTrackMessage(Target);
				alreadySignaledTracks.AddItem(Target);
			}
		}

		foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldEffectTileData)
		{
			Target = WorldEffectTileData.GetReference();
			worldEffectFireActionArray = `XCOMVISUALIZATIONMGR.GetCurrentWorldEffectTrackAction(class'X2Action_UpdateWorldEffects_Fire', class'X2Action_WaitForAbilityEffect', VisualizeGameState.HistoryIndex, Target );
			if (worldEffectFireActionArray.length > 0 && beginAimingAnim)
			{
				for (i = 0; i < worldEffectFireActionArray.length; i++)
				{
					worldEffectFireAction = X2Action_UpdateWorldEffects_Fire(worldEffectFireActionArray[i]);
					if (worldEffectFireAction != none)
					{
						if (!endAimingAnim)
						{
							if (!FindTrack(Target))
							{
								worldEffectFireAction.BeginSyncWithOtherAction();
								VisualizationMgr.SendInterTrackMessage(Target);
								alreadySignaledTracks.AddItem(Target);
							}

							worldEffectFireAction.SetActiveTiles(lineTiles);
						}
						else
						{
							worldEffectFireAction.EndSyncWithOtherAction();
						}
					}
				}
			}

		}

		//play the secondarytile effects
		if (cornerTiles.length > 0)
		{
			foreach cornerTiles(iterTile)
			{
				WorldInfo.MyEmitterPool.SpawnEmitter(ParticleSystem(DynamicLoadObject(SecondaryFire_ParticleEffectPath, class'ParticleSystem')), `XWORLD.GetPositionFromTileCoordinates(iterTile));
				//`SHAPEMGR.DrawTile(iterTile, 155, 0, 250, 0.6);
			}
		}

		if( !bWaitingToFire )
		{
			//update tick
			currDuration += DT;
		}

		if (endAimingAnim && currDuration >= SweepDuration)
		{
			CompleteAction();
		}
	}

Begin:
	if (XGUnit(PrimaryTarget).GetTeam() == eTeam_Neutral)
	{
		FOWViewer = `XWORLD.CreateFOWViewer(XGUnit(PrimaryTarget).GetPawn().Location, class'XComWorldData'.const.WORLD_StepSize * 3);

		XGUnit(PrimaryTarget).SetForceVisibility(eForceVisible);
		XGUnit(PrimaryTarget).GetPawn().UpdatePawnVisibility();

		// Sleep long enough for the fog to be revealed
		Sleep(1.0f * GetDelayModifier());
	}

	Unit.CurrentFireAction = self;
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams));
	
}

DefaultProperties
{
	NotifyTargetTimer = 0.75;
	TimeoutSeconds = 10.0f; //Should eventually be an estimate of how long we will run
	bNotifyMultiTargetsAtOnce = true
	bWaitingToFire = true;	
}
