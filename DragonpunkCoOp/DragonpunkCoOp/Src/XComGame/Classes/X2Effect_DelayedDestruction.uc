//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_DelayedDestruction.uc
//  AUTHOR:  Russell Aasland - 11/21/2014
//  PURPOSE: Provides destructible actors with the ability to tie their destruction to a
//				fuse (of a sort) so that they
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_DelayedDestruction extends X2Effect_Persistent;

event X2Effect_Persistent GetPersistantTemplate( )
{
	local X2Effect_DelayedDestruction DestructionEffect;

	DestructionEffect = new class'X2Effect_DelayedDestruction';
	DestructionEffect.BuildPersistentEffect(1,,,,eGameRule_PlayerTurnBegin);
	DestructionEffect.bRemoveWhenSourceDies = true;
	DestructionEffect.bRemoveWhenTargetDies = true;

	return DestructionEffect;
}

static function bool DestructionEffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameStateHistory History;
	local XComGameState_Destructible DestructibleState;
	local XComDestructibleActor Actor;
	local XComGameState_EnvironmentDamage NewDamageEvent;

	if (kNewEffectState.iTurnsRemaining == 0)
	{
		History = `XCOMHISTORY;
		DestructibleState = XComGameState_Destructible( History.GetGameStateForObjectID( ApplyEffectParameters.TargetStateObjectRef.ObjectID ) );
		Actor = XComDestructibleActor( DestructibleState.GetVisualizer( ) );

		NewDamageEvent = XComGameState_EnvironmentDamage( NewGameState.CreateStateObject(class'XComGameState_EnvironmentDamage') );

		NewDamageEvent.DEBUG_SourceCodeLocation = "UC: X2Effect_DelayedDestruction:DestructionEffectTicked()";

		NewDamageEvent.HitLocation = Actor.Location;
		NewDamageEvent.DamageSource.ObjectID = Actor.ObjectID;

		NewDamageEvent.DestroyedActors.AddItem( XComDestructibleActor(DestructibleState.GetVisualizer()).GetActorId() );

		NewGameState.AddStateObject( NewDamageEvent );
	}

	return false;
}

static function EffectRemovedByDeathVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local ActorIdentifier ActorID;
	local XComDestructibleActor Destructible;
	local XComGameState_Destructible DestructibleState;
	local XComGameState_EnvironmentDamage DamageEvent;
	local XComGameState_EnvironmentDamage FallbackDamageEvent;
	local X2Action_CameraFrameVisualizationActions LookAtAction;

	DestructibleState = XComGameState_Destructible( BuildTrack.StateObject_NewState );

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', DamageEvent)
	{
		foreach DamageEvent.DestroyedActors( ActorID )
		{
			Destructible = `XWORLD.FindDestructibleActor( ActorId );

			if (Destructible.ObjectID == DestructibleState.ObjectID)
			{
				BuildTrack.StateObject_OldState = DamageEvent;
				BuildTrack.StateObject_NewState = DamageEvent;

				// request a pan over to the exploding object so we can see that it was destroyed
				LookAtAction = X2Action_CameraFrameVisualizationActions(class'X2Action_CameraFrameVisualizationActions'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
				LookAtAction.LookAtActor = none;
				LookAtAction.LookAtLocation = DamageEvent.HitLocation;				
				LookAtAction.DelayAfterArrival = 0.5f; //short delay to look at the object before it explodes
				LookAtAction.DelayAfterActionsComplete = 2.0f; //2 second delay after it explodes ( and the actions to explode it are technically complete )
				
				class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());

				return;
			}
		}

		FallbackDamageEvent = DamageEvent;
	}

	//Fallback - in situations where the destructible actor couldn't be resolved... just set up events based on the damage event. If there is one.
	if(BuildTrack.TrackActions.Length == 0 && FallbackDamageEvent != none)
	{
		BuildTrack.StateObject_OldState = FallbackDamageEvent;
		BuildTrack.StateObject_NewState = FallbackDamageEvent;

		// request a pan over to the exploding object so we can see that it was destroyed
		LookAtAction = X2Action_CameraFrameVisualizationActions(class'X2Action_CameraFrameVisualizationActions'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		LookAtAction.LookAtActor = none;
		LookAtAction.LookAtLocation = FallbackDamageEvent.HitLocation;
		LookAtAction.DelayAfterArrival = 0.5f; //short delay to look at the object before it explodes
		LookAtAction.DelayAfterActionsComplete = 2.0f; //2 second delay after it explodes ( and the actions to explode it are technically complete )

		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
	}
}

DefaultProperties
{
	bTickWhenApplied = false;
	EffectName = "DelayedDestruction";
	DuplicateResponse = eDupe_Ignore;
	EffectTickedFn = DestructionEffectTicked;
	EffectRemovedVisualizationFn = EffectRemovedByDeathVisualization;
}