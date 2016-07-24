//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_DestructionSphere.uc
//  AUTHOR:  David Burchanowski  --  12/17/2013
//  PURPOSE: This object represents the instance data for an XComDestructionSphere actor
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_DestructionSphere extends XComGameState_BaseObject;

var privatewrite bool Detonated;             // Has this sphere been detonated?
var privatewrite bool DamageSphereVisible;   // Is the visual effect to preview the damage visible?
var privatewrite TTile TileLocation;         // Tile location of the sphere actor in the world

function SetDamageSphereVisible(bool Visible)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_DestructionSphere NewSphereState;

	History = `XCOMHISTORY;

	// can't adjust visibility if we've already been detonated
	if(Detonated) return;

	// create the new game state to contain this change
	NewGameState = History.CreateNewGameState(true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext());

	// add our updated state to the new state frame
	NewSphereState = XComGameState_DestructionSphere(NewGameState.CreateStateObject(class'XComGameState_DestructionSphere', ObjectID));
	NewSphereState.DamageSphereVisible = Visible;
	NewGameState.AddStateObject(NewSphereState);

	// And submit
	`TACTICALRULES.SubmitGameState(NewGameState);

	`XEVENTMGR.TriggerEvent('DestructionSphereUpdated', self, self, NewGameState);
}

function OnBeginTacticalPlay()
{
	local XComDestructionSphere SphereActor;
	local XComWorldData WorldData;
	local TTile Tile;
	local Object ThisObj;

	super.OnBeginTacticalPlay();

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'DestructionSphereUpdated', OnSyncVisualizer, ELD_OnVisualizationBlockCompleted);

	// find our sphere actor and sync it
	WorldData = `XWORLD;
	foreach `BATTLE.AllActors(class'XComDestructionSphere', SphereActor)
	{
		Tile = WorldData.GetTileCoordinatesFromPosition(SphereActor.Location);
		if(Tile == TileLocation)
		{
			SphereActor.SyncToGameState();
			break;
		}
	}
}

function EventListenerReturn OnSyncVisualizer(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComDestructionSphere Visualizer;
	local XComGameStateHistory History;

	if(EventData == self)
	{
		History = `XCOMHISTORY;
		Visualizer = XComDestructionSphere(History.GetVisualizer(ObjectID));
		if(Visualizer != none)
		{
			Visualizer.SyncToGameState();
		}
	}

	return ELR_NoInterrupt;
}

function Explode()
{
	local XComWorldData WorldData;
	local XComDestructionSphere SphereActor;
	local XComGameStateHistory History;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState NewGameState;
	local XComGameState_DestructionSphere NewSphereState;
	local XComGameState_Unit UnitState;
	local vector UnitLocation;
	local array<name> DamageTypes;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	// grab our visualizer actor
	SphereActor = XComDestructionSphere(History.GetVisualizer(ObjectID));
	`assert(SphereActor != none);
	if(SphereActor == none) return;

	// ensure we aren't trying to explode more than once
	if(Detonated) return;

	// create the new game state to contain this change
	NewGameState = History.CreateNewGameState(true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext());

	// add our updated state to the new state frame
	NewSphereState = XComGameState_DestructionSphere(NewGameState.CreateStateObject(class'XComGameState_DestructionSphere', ObjectID));
	NewSphereState.Detonated = true;
	NewSphereState.DamageSphereVisible = false;
	NewGameState.AddStateObject(NewSphereState);

	// add a damage event to the new state frame
	DamageEvent = XComGameState_EnvironmentDamage(NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage'));	
	DamageEvent.DamageAmount = SphereActor.DamageAmount;
	DamageEvent.DamageTypeTemplateName = 'Explosion';
	DamageEvent.HitLocation = SphereActor.Location;
	DamageEvent.PhysImpulse = 0;
	DamageEvent.DamageRadius = SphereActor.DamageRadiusTiles * class'XComWorldData'.const.WORLD_StepSize;	
	DamageEvent.DamageCause = GetReference();
	DamageEvent.DamageSource = DamageEvent.DamageCause;
	DamageEvent.bRadialDamage = true;
	DamageEvent.bSpawnExplosionVisuals = false;
	NewGameState.AddStateObject(DamageEvent);

	// add all damaged units to the new frame
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		UnitLocation = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);
		
		if(VSize(UnitLocation - SphereActor.Location) < DamageEvent.DamageRadius)
		{
			DamageTypes.AddItem( 'Explosion' );

			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));

			UnitState.TakeDamage( NewGameState, SphereActor.UnitDamageAmount, 0, 0, , , , true, DamageTypes );

			NewGameState.AddStateObject(UnitState);
		}
	}

	// And submit
	`TACTICALRULES.SubmitGameState(NewGameState);

	`XEVENTMGR.TriggerEvent('DestructionSphereUpdated', self, self, NewGameState);
}

static function XComGameState_DestructionSphere GetStateObject(XComDestructionSphere SphereActor)
{
	local XComWorldData WorldData;
	local XComGameStateHistory History;
	local XComGameState_DestructionSphere ObjectState;
	local XComGameState NewGameState;
	local bool SubmitState;
	local TTile TestTileLocation;

	`assert(SphereActor != none);

	History = `XCOMHISTORY;

	// first see if it's already cached on the actor
	if(SphereActor.ObjectID >= 0)
	{
		ObjectState = XComGameState_DestructionSphere(History.GetGameStateForObjectID(SphereActor.ObjectID));
		`assert(ObjectState != none);
		return ObjectState;
	}
	
	// Find the object at the actor's location
	TestTileLocation = `XWORLD.GetTileCoordinatesFromPosition(SphereActor.Location);
	foreach History.IterateByClassType(class'XComGameState_DestructionSphere', ObjectState)
	{
		if( TestTileLocation == ObjectState.TileLocation)
		{
			History.SetVisualizer(ObjectState.ObjectID, SphereActor);
			return ObjectState;
		}
	}

	// if it doesn't exist, then we need to create it
	SubmitState = false;

	// first see if we are in the start state
	NewGameState = History.GetStartState();
	
	// no start state or supplied game state, make our own
	if( NewGameState == none )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState();
		SubmitState = true;
	}
	
	ObjectState = XComGameState_DestructionSphere(NewGameState.CreateStateObject(class'XComGameState_DestructionSphere'));
	History.SetVisualizer(ObjectState.ObjectID, SphereActor);

	WorldData = `XWORLD;
	ObjectState.TileLocation = WorldData.GetTileCoordinatesFromPosition(SphereActor.Location);
	NewGameState.AddStateObject(ObjectState);

	if( `TACTICALRULES != None && SubmitState )
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
	}

	return ObjectState;
}

DefaultProperties
{	
}
