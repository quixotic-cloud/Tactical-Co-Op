//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_Falling.uc
//  AUTHOR:  Russell Aasland  --  8/8/2014
//  PURPOSE: This context is used with falling events that require their own game state
//           object.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameStateContext_Falling extends XComGameStateContext
	native(Core)
	config(GameCore);

var() StateObjectReference FallingUnit;
var() TTile StartLocation;

var() array<TTile> LandingLocations;
var() array<TTile> EndingLocations;

var() array<StateObjectReference> LandedUnits;

var const config int MinimumFallingDamage;

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	local XComGameState NewGameState;
	local XComGameState_Unit FallingUnitState, LandedUnitState;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_EnvironmentDamage WorldDamage;
	local XGUnit Unit;
	local float FallingDamage;
	local TTile Tile;
	local TTile LastEndLocation;
	local StateObjectReference LandedUnit;
	local int x;
	local int iStoryHeightInTiles;
	local int iNumStoriesFallen;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	
	FallingUnitState = XComGameState_Unit(History.GetGameStateForObjectID(FallingUnit.ObjectID));
	CharacterTemplate = FallingUnitState.GetMyTemplate();

	if(CharacterTemplate.bCanUse_eTraversal_Flying) //Flying units are immune to falling
	{
		return none;
	}

	SetDesiredVisualizationBlockIndex( History.GetEventChainStartIndex( ) );
	NewGameState = History.CreateNewGameState( true, self );

	FallingUnitState = XComGameState_Unit( NewGameState.CreateStateObject( class'XComGameState_Unit', FallingUnit.ObjectID ) );

	if (CharacterTemplate.bIsTurret) // turrets don't fall
	{
		FallingDamage = FallingUnitState.GetCurrentStat( eStat_HP );
		FallingUnitState.TakeDamage( NewGameState, FallingDamage, 0, 0, , , , , , , , true );
		FallingUnitState.bFallingApplied = true;
		FallingUnitState.RemoveStateFromPlay( );

		NewGameState.AddStateObject( FallingUnitState );
	}
	else
	{
		LastEndLocation = EndingLocations[EndingLocations.Length - 1];

		FallingUnitState.SetVisibilityLocation(LastEndLocation);


		// Damage calculation for falling, per designer instructions via Hansoft,
		//     "Falling DMG should be flat for XCOM: Should be 2 damage per floor."
		// Note: Griffin says this rule should apply to all units, not just "for XCOM".
		// mdomowicz 2015_08_06
		iStoryHeightInTiles = 4;
		iNumStoriesFallen = (StartLocation.Z - LastEndLocation.Z) / iStoryHeightInTiles;
		FallingDamage = 2 * iNumStoriesFallen;


		if(FallingDamage < MinimumFallingDamage)
		{
			FallingDamage = MinimumFallingDamage;
		}

		if((StartLocation.Z - LastEndLocation.Z >= iStoryHeightInTiles) || (LandedUnits.Length > 0))
		{
			FallingUnitState.TakeDamage(NewGameState, FallingDamage, 0, 0, , , , , , , , true);
		}

		foreach LandedUnits(LandedUnit)
		{
			Unit = XGUnit(`XCOMHISTORY.GetVisualizer(LandedUnit.ObjectID));
			if(Unit != none)
			{
				LandedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', LandedUnit.ObjectID));

				LandedUnitState.TakeDamage(NewGameState, FallingDamage, 0, 0, , , , , , , , true);

				NewGameState.AddStateObject(LandedUnitState);
			}
		}

		NewGameState.AddStateObject(FallingUnitState);

		Tile = StartLocation;
		for(x = 0; x < LandingLocations.Length; ++x)
		{
			while(Tile != LandingLocations[x])
			{
				--Tile.Z;

				WorldDamage = XComGameState_EnvironmentDamage(NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage'));

				WorldDamage.DamageTypeTemplateName = 'Falling';
				WorldDamage.DamageCause = FallingUnitState.GetReference();
				WorldDamage.DamageSource = WorldDamage.DamageCause;
				WorldDamage.bRadialDamage = false;
				WorldDamage.HitLocationTile = Tile;
				WorldDamage.DamageTiles.AddItem(WorldDamage.HitLocationTile);

				WorldDamage.DamageDirection.X = 0.0f;
				WorldDamage.DamageDirection.Y = 0.0f;
				WorldDamage.DamageDirection.Z = (Tile.Z == LandingLocations[x].Z) ? 1.0f : -1.0f; // change direction of landing tile so as to not destroy the floor they should be landing on

				WorldDamage.DamageAmount = (FallingUnitState.UnitSize == 1) ? 10 : 100; // Large Units smash through more things
				WorldDamage.bAffectFragileOnly = false;

				NewGameState.AddStateObject(WorldDamage);
			}

			Tile = EndingLocations[x];
		}

		`XEVENTMGR.TriggerEvent('UnitMoveFinished', FallingUnitState, FallingUnitState, NewGameState);
	}

	return NewGameState;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	local VisualizationTrack BuildTrack;	
	local VisualizationTrack EmptyTrack;
	local XComGameState_EnvironmentDamage DamageEventStateObject;
	local XGUnit Unit;
	local TTile LastEndLocation;
	local StateObjectReference LandedUnit;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameState_Unit FallingUnitState;
	local XComGameState_Effect TestEffect;
	local bool PartOfCarry;
	local X2Action_MoveTeleport MoveTeleport;
	local vector PathEndPos;
	local PathingInputData PathingData;
	local PathingResultData ResultData;

	BuildTrack = EmptyTrack;
	BuildTrack.TrackActor = `XCOMHISTORY.GetVisualizer(FallingUnit.ObjectID);
	`XCOMHISTORY.GetCurrentAndPreviousGameStatesForObjectID(FallingUnit.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);
	
	class'X2Action_WaitForWorldDamage'.static.AddToVisualizationTrack( BuildTrack, self );
	
	if (XComGameState_Unit(BuildTrack.StateObject_OldState).GetMyTemplate().bIsTurret)
	{
		class'X2Action_RemoveUnit'.static.AddToVisualizationTrack( BuildTrack, self );

		class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack( BuildTrack, self );

		VisualizationTracks.AddItem( BuildTrack );

		return;
	}
	
	PartOfCarry = false;
	FallingUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(FallingUnit.ObjectID));
	if( FallingUnitState != None )
	{
		TestEffect = FallingUnitState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
		if( TestEffect != None )
		{
			PartOfCarry = true;
		}

		TestEffect = FallingUnitState.GetUnitAffectedByEffectState(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
		if( TestEffect != None )
		{
			PartOfCarry = true;
		}
	}

	if (XGUnit(BuildTrack.TrackActor).GetPawn().RagdollFlag == ERagdoll_Never)
	{
		PathEndPos = `XWORLD.GetPositionFromTileCoordinates( XComGameState_Unit(BuildTrack.StateObject_NewState).TileLocation );
		MoveTeleport = X2Action_MoveTeleport( class'X2Action_MoveTeleport'.static.AddToVisualizationTrack( BuildTrack, self ) );
		MoveTeleport.ParsePathSetParameters( 0, PathEndPos, 0, PathingData, ResultData );
		MoveTeleport.SnapToGround = true;
	}
	else if( PartOfCarry )
	{
		class'X2Action_UnitFallingNoRagdoll'.static.AddToVisualizationTrack(BuildTrack, self);
	}
	else
	{
		class'X2Action_UnitFalling'.static.AddToVisualizationTrack(BuildTrack, self);
	}

	LastEndLocation = EndingLocations[ EndingLocations.Length - 1 ];
	if (StartLocation.Z - LastEndLocation.Z >= 4)
	{
		class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, self);
	}

	//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
	TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
	if (TargetVisualizerInterface != none)
		TargetVisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, BuildTrack);
		
	VisualizationTracks.AddItem(BuildTrack);

	foreach LandedUnits( LandedUnit )
	{
		Unit = XGUnit(`XCOMHISTORY.GetVisualizer(LandedUnit.ObjectID));
		if (Unit != none)
		{
			BuildTrack = EmptyTrack;
			BuildTrack.TrackActor = `XCOMHISTORY.GetVisualizer( LandedUnit.ObjectID );
			`XCOMHISTORY.GetCurrentAndPreviousGameStatesForObjectID(LandedUnit.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);

			class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, self);

			TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
			if (TargetVisualizerInterface != none)
				TargetVisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, BuildTrack);

			VisualizationTracks.AddItem(BuildTrack);
		}
	}

	// add visualization of environment damage
	foreach AssociatedState.IterateByClassType( class'XComGameState_EnvironmentDamage', DamageEventStateObject )
	{
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = DamageEventStateObject;
		BuildTrack.StateObject_NewState = DamageEventStateObject;
		BuildTrack.TrackActor = `XCOMHISTORY.GetVisualizer(DamageEventStateObject.ObjectID);//`XCOMHISTORY.GetVisualizer(FallingUnit.ObjectID);
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, self);
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack( BuildTrack, self );
		VisualizationTracks.AddItem( BuildTrack );
	}

	AddVisualizationFromFutureGameStates(AssociatedState, VisualizationTracks, VisTrackInsertedInfoArray);
}

function string SummaryString()
{
	return "XComGameStateContext_Falling";
}