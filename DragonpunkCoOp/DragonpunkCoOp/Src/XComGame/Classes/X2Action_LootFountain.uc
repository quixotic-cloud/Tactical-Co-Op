//---------------------------------------------------------------------------------------
//  FILE:    X2Action_LootFountain.uc
//  AUTHOR:  Dan Kaplan
//  DATE:    5/25/2015
//  PURPOSE: Visualization for Loot Fountain.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_LootFountain extends X2Action;

//Cached info for the unit performing the action and the target object
//*************************************
var Actor						LootSourceVisualizer;
var XComUnitPawn				LootSourceUnitPawn;

// The length of time it will take each loot item to fountain out
var float						LootFountainTime;

var float						LootStartTimeSeconds;
var Vector						LootStartLoc;

var array<StateObjectReference>	LootItemRefs;

var Lootable					LootableObjectState;

//*************************************

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
	
	LootSourceVisualizer = InTrack.TrackActor;
	if(XGUnit(LootSourceVisualizer) != none)
	{
		LootSourceUnitPawn = XGUnit(LootSourceVisualizer).GetPawn();
	}

	LootableObjectState = Lootable(InTrack.StateObject_NewState);

	if( LootableObjectState != None )
	{
		LootItemRefs = LootableObjectState.GetAvailableLoot();
	}

}

function bool IsTimedOut()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{

	function BeginFountain()
	{
		local int CurrentLootID;
		local KActorSpawnable LootVisActor;
		local X2ItemTemplate ItemTemplate;
		local XComGameStateHistory History;
		local XComGameState_Item LootItemState;
		local Vector Impulse;

		History = `XCOMHISTORY;

		if( LootItemRefs.Length > 0 )
		{
			LootStartTimeSeconds = WorldInfo.TimeSeconds;

			CurrentLootID = LootItemRefs[0].ObjectID;
			LootVisActor = KActorSpawnable(History.GetVisualizer(CurrentLootID));

			// will usually have to create the visualizer here
			if( LootVisActor == None )
			{
				LootItemState = XComGameState_Item(History.GetGameStateForObjectID(CurrentLootID));
				ItemTemplate = LootItemState.GetMyTemplate();
				LootVisActor = Spawn(class'KActorSpawnable', , , LootSourceVisualizer.Location, LootSourceVisualizer.Rotation, , true);
				LootVisActor.StaticMeshComponent.SetStaticMesh(ItemTemplate.LootStaticMesh);
				LootVisActor.StaticMeshComponent.WakeRigidBody(, 6.0); // keep the rigid body physics awake and active for at least 3 seconds to ensure it settles completely
				// add a small upward impulse to the spawning loot
				Impulse.X = ((`SYNC_FRAND() * 2.0f) - 1.0f) * 5.0f;
				Impulse.Y = ((`SYNC_FRAND() * 2.0f) - 1.0f) * 5.0f;
				Impulse.Z = 20.0;
				LootVisActor.StaticMeshComponent.AddImpulse(Impulse);
				History.SetVisualizer(CurrentLootID, LootVisActor);
				PlayAKEvent(AkEvent'SoundTacticalUI.TacticalUI_LootDrop');
			}
		}
	}

	function UpdateFountain()
	{
		local float TimeSinceStart;

		TimeSinceStart = WorldInfo.TimeSeconds - LootStartTimeSeconds;

		if( TimeSinceStart >= LootFountainTime )
		{
			LootItemRefs.Remove(0, 1);
			BeginFountain();
		}
	}

Begin:

	//If the loot source is a unit pawn, give the ragdoll time to settle before setting off the loot fountain
	if(LootSourceUnitPawn != none)
	{	
		sleep(2.0f * GetDelayModifier());
	}
	
	BeginFountain();
	while( LootItemRefs.Length > 0 )
	{
		UpdateFountain();
		Sleep(0.001f);
	}

	LootableObjectState.UpdateLootSparklesEnabled(false);

	CompleteAction();
}

defaultproperties
{
	LootFountainTime = 0.15  //todo - shorten this
	LootStartTimeSeconds = -1.0
}

