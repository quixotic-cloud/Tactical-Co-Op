//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_UpdateWorldEffects.uc
//  AUTHOR:  Ryan McFall  --  8/8/2014
//  PURPOSE: This context is created in response to the start of a turn, where world effects
//           such as fire, smoke, poison, acid, and others perform game play effects.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameStateContext_UpdateWorldEffects extends XComGameStateContext
	native( Core );

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	local XComGameState NewGameState;	
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	NewGameState = History.CreateNewGameState(true, self);
	
	//Update the tile data / effects
	`XWORLD.BuildGameplayTileEffectUpdate(NewGameState);
	`XEVENTMGR.TriggerEvent( 'GameplayTileEffectUpdate', none, none, NewGameState );

	//Effects can apply updates to the game state in a general way. Fire applies burning to units, damage to the environment, for example.

	return NewGameState;
}

protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{	
	local X2Effect ApplyEffect;
	local VisualizationTrack BuildTrack;	
	local VisualizationTrack EmptyTrack;
	local XComGameState_WorldEffectTileData TileDataStateObject;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_Unit UnitState;
	local StateObjectReference EffectStateRef;
	local XComGameState_Effect EffectState;
	local bool bAnyUnitEffects;

	foreach AssociatedState.IterateByClassType(class'XComGameState_WorldEffectTileData', TileDataStateObject)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = TileDataStateObject;
		BuildTrack.StateObject_NewState = TileDataStateObject;

		if( TileDataStateObject.StoredTileData.Length > 0 )
		{
			//Assume that effect names are the same for each tile
			ApplyEffect = X2Effect(class'Engine'.static.FindClassDefaultObject(string(TileDataStateObject.StoredTileData[0].Data.EffectName)));
			if( ApplyEffect != none )
			{
				ApplyEffect.AddX2ActionsForVisualization(AssociatedState, BuildTrack, 'AA_Success');
			}
			else
			{
				`redscreen("UpdateWorldEffects context failed to build visualization, could not resolve class from name:"@TileDataStateObject.StoredTileData[0].Data.EffectName@"!");
			}

			VisualizationTracks.AddItem(BuildTrack);
		}
	}

	foreach AssociatedState.IterateByClassType(class'XComGameState_EnvironmentDamage', DamageEvent)
	{
		BuildTrack = EmptyTrack;
		//Don't necessarily have a previous state, so just use the one we know about
		BuildTrack.StateObject_OldState = DamageEvent; 
		BuildTrack.StateObject_NewState = DamageEvent;

		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack(BuildTrack, self); //This is my weapon, this is my gun

		VisualizationTracks.AddItem(BuildTrack);
	}

	foreach AssociatedState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		bAnyUnitEffects = false;
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = UnitState;
		BuildTrack.StateObject_NewState = UnitState;

		foreach UnitState.AffectedByEffects(EffectStateRef)
		{
			EffectState = XComGameState_Effect(AssociatedState.GetGameStateForObjectID(EffectStateRef.ObjectID));
			if( EffectState != None )
			{
				//Assume that effect names are the same for each tile
				ApplyEffect = EffectState.GetX2Effect();
				if( ApplyEffect != none )
				{
					ApplyEffect.AddX2ActionsForVisualization(AssociatedState, BuildTrack, 'AA_Success');
					bAnyUnitEffects = true;
				}
			}
		}

		if( bAnyUnitEffects )
		{
			VisualizationTracks.AddItem(BuildTrack);
		}
	}
}

function string SummaryString()
{
	return "XComGameStateContext_UpdateWorldEffects";
}