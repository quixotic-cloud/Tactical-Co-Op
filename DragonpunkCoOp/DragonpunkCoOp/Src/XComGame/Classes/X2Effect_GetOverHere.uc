class X2Effect_GetOverHere extends X2Effect;

static function bool IsTileValidForBind(const out TTile TileOption, const out TTile SourceTile)
{
	local XComWorldData World;
	local GameRulesCache_VisibilityInfo OutVisibilityInfo;
	local vector SourceLoc, TargetLoc;
	local ECoverType Cover;
	local float TargetCoverAngle;
	World = `XWORLD;
	// Match the tile visibility condition checks from the Bind ability template as much as possible. (X2Ability_Viper::CreateBindAbility)
	//   Actual conditions from Bind ability cannot be directly tested without the units in place 
	//	 i.e. gameplay visibility not tested via CanSeeTileToTile.
	if( World.CanSeeTileToTile(SourceTile, TileOption, OutVisibilityInfo) ) // Visible? 
	{
		if( OutVisibilityInfo.bVisibleFromDefault ) // No peeking!
		{
			// No high cover allowed for bind.  CanSeeTileToTile does not update TargetCover either, so we must check this manually.
			SourceLoc = World.GetPositionFromTileCoordinates(SourceTile);
			TargetLoc = World.GetPositionFromTileCoordinates(TileOption);
			Cover = World.GetCoverTypeForTarget(SourceLoc, TargetLoc, TargetCoverAngle);
			if( Cover != CT_Standing )
			{
				return true;
			}
		}
	}
	return false;
}

static function bool HasBindableNeighborTile(XComGameState_Unit SourceUnitState, vector PreferredDirection=vect(1,0,0), optional out TTile TeleportToTile )
{
	if( SourceUnitState.FindAvailableNeighborTileWeighted(PreferredDirection, TeleportToTile, IsTileValidForBind) )
	{
		return true;
	}
	return false;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnitState, TargetUnitState;
	local XComGameStateHistory History;
	local XComWorldData World;
	local TTIle TeleportToTile;
	local Vector PreferredDirection;
	local X2EventManager EventManager;

	History = `XCOMHISTORY;
	World = `XWORLD;

	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(SourceUnitState != none);
	TargetUnitState = XComGameState_Unit(kNewTargetState);
	`assert(TargetUnitState != none);

	PreferredDirection = Normal(World.GetPositionFromTileCoordinates(TargetUnitState.TileLocation) - World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation));

	// Prioritize selecting a tile that we can use the bind ability from.  (visible without peek, not high cover)
	if( HasBindableNeighborTile(SourceUnitState, PreferredDirection, TeleportToTile)
							// If that fails, select any valid neighbor tile.  Drop the validator.
		   || SourceUnitState.FindAvailableNeighborTileWeighted(PreferredDirection, TeleportToTile) )
	{
		EventManager = `XEVENTMGR;

		// Move the target to this space
		TargetUnitState.SetVisibilityLocation(TeleportToTile);

		EventManager.TriggerEvent('ObjectMoved', TargetUnitState, TargetUnitState, NewGameState);
		EventManager.TriggerEvent('UnitMoveFinished', TargetUnitState, TargetUnitState, NewGameState);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Unit TargetUnitState;
	local vector NewUnitLoc;
	local X2Action_ViperGetOverHereTarget GetOverHereTarget;
	local X2Action_ApplyWeaponDamageToUnit UnitAction;

	TargetUnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	`assert(TargetUnitState != none);
	
	// Move the target to this space
	if( EffectApplyResult == 'AA_Success' )
	{
		GetOverHereTarget = X2Action_ViperGetOverHereTarget(class'X2Action_ViperGetOverHereTarget'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		NewUnitLoc = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
		GetOverHereTarget.SetDesiredLocation(NewUnitLoc, XGUnit(BuildTrack.TrackActor));
	}
	else
	{
		UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		UnitAction.OriginatingEffect = self;
	}
} 