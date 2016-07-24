//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_SetDestructibleActorState.uc
//  AUTHOR:  Ryan McFall  --  01/11/2013
//  PURPOSE: This sequence action allows kismet sequences to control the state of 
//           destructible actors in a level.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_SetDestructibleActorState extends SequenceAction;

enum DestructibleActorState
{
	eDamaged,
	eDestroyed
};

var Actor   TargetActor;
var() DestructibleActorState SetState;

event Activated()
{	
	local XComGameStateHistory History;
	local XComGameState NewGameState;		
	local XComDestructibleActor TargetDestructible;		
	local XComGameState_EnvironmentDamage NewDamageEvent;
	local name CurrentState;

	TargetDestructible = XComDestructibleActor(TargetActor);
	if( TargetDestructible != none )
	{
		CurrentState = TargetDestructible.GetStateName();
		if( CurrentState != '_Dead' )
		{
			History = `XCOMHISTORY;

			NewGameState = History.CreateNewGameState( true, class'XComGameStateContext_AreaDamage'.static.CreateXComGameStateContext( ) );

			NewDamageEvent = XComGameState_EnvironmentDamage( NewGameState.CreateStateObject( class'XComGameState_EnvironmentDamage' ) );

			NewDamageEvent.DEBUG_SourceCodeLocation = "UC: SeqAct_SetDestructibleActorState:Activated()";
			NewDamageEvent.DamageAmount = 0;
			NewDamageEvent.DamageTypeTemplateName = 'Explosion';
			NewDamageEvent.HitLocation = TargetDestructible.StaticMeshComponent.Bounds.Origin;
			NewDamageEvent.Momentum.X = 0;
			NewDamageEvent.Momentum.Y = 0;
			NewDamageEvent.Momentum.Z = 0;
			NewDamageEvent.DamageRadius = 0;
			NewDamageEvent.bRadialDamage = false;
			NewDamageEvent.bCausesSurroundingAreaDamage = false;

			if (SetState == eDamaged)
			{
				NewDamageEvent.DamageActors.AddItem( TargetDestructible.GetActorId() );
			}
			else if (SetState == eDestroyed)
			{
				NewDamageEvent.DestroyedActors.AddItem( TargetDestructible.GetActorId( ) );
			}

			NewGameState.AddStateObject( NewDamageEvent );

			`TACTICALRULES.SubmitGameState( NewGameState );
		}
	}
	else
	{
		`warn("SeqAct_SetDestructibleActorState called on non destructible actor:"@TargetActor@" This sequence action requires a destructible actor input.");
	}
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Set DestructibleActor State"
	bCallHandler=false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)
}
