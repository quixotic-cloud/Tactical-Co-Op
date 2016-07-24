class X2Effect_SpawnChryssalid extends X2Effect_SpawnUnit;

function vector GetSpawnLocation(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit TargetUnitState;
	local XComGameStateHistory History;
	local TTile TileLocation, NeighborTileLocation;
	local XComWorldData World;
	local Actor TileActor;
	local vector SpawnLocation;

	World = `XWORLD;
	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(TargetUnitState != none);

	TileLocation = TargetUnitState.TileLocation;
	NeighborTileLocation = TileLocation;

	for (NeighborTileLocation.X = TileLocation.X - 1; NeighborTileLocation.X <= TileLocation.X + 1; ++NeighborTileLocation.X)
	{
		for (NeighborTileLocation.Y = TileLocation.Y - 1; NeighborTileLocation.Y <= TileLocation.Y + 1; ++NeighborTileLocation.Y)
		{
			TileActor = World.GetActorOnTile(NeighborTileLocation);

			// If the tile is empty and is on the same z as this unit's location
			if (TileActor == none && (World.GetFloorTileZ(NeighborTileLocation, false) == World.GetFloorTileZ(TileLocation, false)))
			{
				SpawnLocation = World.GetPositionFromTileCoordinates(NeighborTileLocation);
				return SpawnLocation;
			}
		}
	}

	SpawnLocation = World.GetPositionFromTileCoordinates(TileLocation);
	return SpawnLocation;
}

function ETeam GetTeam(const out EffectAppliedData ApplyEffectParameters)
{
	return GetSourceUnitsTeam(ApplyEffectParameters);
}

function OnSpawnComplete(const out EffectAppliedData ApplyEffectParameters, StateObjectReference NewUnitRef, XComGameState NewGameState)
{
	local XComGameState_Unit ChryssalidPupGameState;
	local int HalfLife;

	ChryssalidPupGameState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(NewUnitRef.ObjectID));
	`assert(ChryssalidPupGameState != none);

	HalfLife = ChryssalidPupGameState.GetCurrentStat(eStat_HP) / 2;
	ChryssalidPupGameState.SetBaseMaxStat(eStat_HP, HalfLife);
	ChryssalidPupGameState.SetCurrentStat(eStat_HP, HalfLife);
}

function AddSpawnVisualizationsToTracks(XComGameStateContext Context, XComGameState_Unit SpawnedUnit, out VisualizationTrack SpawnedUnitTrack,
										XComGameState_Unit EffectTargetUnit, optional out VisualizationTrack EffectTargetUnitTrack)
{
	local XComGameStateHistory History;
	local X2Action_SpawnChryssalid ShowUnitAction;
	local XGUnit SourceUnitActor, SpawnedUnitActor;
	local vector TowardsTarget;
	local Rotator FacingRot;

	History = `XCOMHISTORY;

	SourceUnitActor = XGUnit(History.GetVisualizer(EffectTargetUnit.ObjectID));
	SpawnedUnitActor = XGUnit(History.GetVisualizer(SpawnedUnit.ObjectID));

	TowardsTarget = SpawnedUnitActor.Location - SourceUnitActor.Location;
	TowardsTarget.Z = 0;
	TowardsTarget = Normal(TowardsTarget);
	FacingRot = Rotator(TowardsTarget);

	// Show the spawned unit, using the tile and rotation for the visualizer
	ShowUnitAction = X2Action_SpawnChryssalid(class'X2Action_SpawnChryssalid'.static.AddToVisualizationTrack(SpawnedUnitTrack, Context));
	ShowUnitAction.VisualizationLocation = SourceUnitActor.Location;
	ShowUnitAction.FacingRot = FacingRot;
}

defaultproperties
{
	UnitToSpawnName="Chryssalid"
	bKnockbackAffectsSpawnLocation=false
}