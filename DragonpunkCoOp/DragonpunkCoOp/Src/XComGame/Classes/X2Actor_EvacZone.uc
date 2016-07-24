//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Actor_EvacZone.uc
//  AUTHOR:  Josh Bouscher, David Burchanowski
//  PURPOSE: Defines the actor that represents an evac zone in the world
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2Actor_EvacZone extends StaticMeshActor
	config(GameCore)
	placeable;

var private XComBlueprint EvacBlueprint;
var private int ObjectID;

private function EventListenerReturn OnTileDataChanged( Object EventData, Object EventSource, XComGameState GameState, Name EventID )
{
	local XComGameStateHistory History;
	local XComGameState_EvacZone EvacZoneState;
	local XComGameState NewGameState;
	local X2TacticalGameRuleset Rules;
	local XComGameState_Ability NewAbilityState;
	local name CurrentAbilityName;
	local XComGameState_Player NewPlayerState;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	Rules = `TACTICALRULES;

	EvacZoneState = XComGameState_EvacZone( History.GetGameStateForObjectID( ObjectID ) );

	if (!class'X2TargetingMethod_EvacZone'.static.ValidateEvacArea( EvacZoneState.CenterLocation, false ))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Invalidating Evac Zone" );

		// turn off the evac ability
		class'XComGameState_BattleData'.static.SetGlobalAbilityEnabled( 'Evac', false, NewGameState );

		//reset the cooldowns on the abilities
		foreach History.IterateByClassType( class'XComGameState_Ability', NewAbilityState )
		{
			// only want to reset the  evac abilities
			CurrentAbilityName = NewAbilityState.GetMyTemplateName( );
			if ((CurrentAbilityName != 'PlaceEvacZone') || !NewAbilityState.IsCoolingDown( ))
			{
				continue;
			}

			// skip units that aren't associated with the correct team
			UnitState = XComGameState_Unit( History.GetGameStateForObjectID( NewAbilityState.OwnerStateObject.ObjectID ) );
			if (UnitState.GetTeam( ) != EvacZoneState.Team)
			{
				continue;
			}

			// update the cooldown on the ability itself
			NewAbilityState = XComGameState_Ability( NewGameState.CreateStateObject( class'XComGameState_Ability', NewAbilityState.ObjectID ) );
			NewAbilityState.iCooldown = 0;
			NewGameState.AddStateObject( NewAbilityState );

			// update the cooldown on the player
			NewPlayerState = XComGameState_Player( NewGameState.GetGameStateForObjectID( UnitState.GetAssociatedPlayerID( ) ) );
			if (NewPlayerState == None)
			{
				NewPlayerState = XComGameState_Player( History.GetGameStateForObjectID( UnitState.GetAssociatedPlayerID( ) ) );
			}
			if (NewPlayerState.GetCooldown( CurrentAbilityName ) > 0)
			{
				NewPlayerState = XComGameState_Player( NewGameState.CreateStateObject( class'XComGameState_Player', NewPlayerState.ObjectID ) );
				NewPlayerState.SetCooldown( CurrentAbilityName, 0 );
				NewGameState.AddStateObject( NewPlayerState );
			}
		}

		Destroyed( );
		`XEVENTMGR.TriggerEvent( 'EvacZoneDestroyed', EvacZoneState, EvacZoneState );

		if (!Rules.SubmitGameState( NewGameState ))
		{
			`Redscreen("Failed to submit state from X2Actor_EvacZone.OnTileDataChanged()!");
		}
	}

	return ELR_NoInterrupt;
}

function InitEvacZone(XComGameState_EvacZone EvacZoneState)
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local vector FloorLocation;
	local Object ThisObj;

	if (EvacZoneState != none)
	{
		History = `XCOMHISTORY;

		//  link ourself to the state
		ObjectID = EvacZoneState.ObjectID;
		History.SetVisualizer(ObjectID, self);

		WorldData = `XWORLD;
		if (!WorldData.GetFloorPositionForTile( EvacZoneState.CenterLocation, FloorLocation ))
		{
			FloorLocation = WorldData.GetPositionFromTileCoordinates( EvacZoneState.CenterLocation );
		}

		// grab our location from the state
		SetLocation(FloorLocation);

		// create and place the blueprint that represents the evac zone, if it doesn't already exist
		if(EvacBlueprint == none)
		{
			EvacBlueprint = class'XComBlueprint'.static.ConstructGameplayBlueprint(EvacZoneState.GetEvacZoneBlueprintMap(), Location, rot(0,0,1), none);
		}

		ThisObj = self;
		`XEVENTMGR.RegisterForEvent( ThisObj, 'TileDataChanged', OnTileDataChanged, ELD_OnStateSubmitted );
	}
}

event Destroyed()
{
	local Object ThisObj;

	if(EvacBlueprint != none)
	{
		EvacBlueprint.Destroy();
	}

	if (ObjectID > -1)
	{
		ThisObj = self;
		`XEVENTMGR.UnRegisterFromEvent( ThisObj, 'TileDataChanged' );
	}
}

defaultproperties
{
	bStatic=FALSE
	bWorldGeometry=FALSE
	bMovable=TRUE
}