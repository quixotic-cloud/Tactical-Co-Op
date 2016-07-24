//---------------------------------------------------------------------------------------
//  FILE:    X2Action_PlaySyncedMeleeAnimation.uc
//  AUTHOR:  Dan Kaplan
//  DATE:    6/4/2015
//  PURPOSE: Visualization for synced animations between Source & Target units in a melee attack.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_PlaySyncedMeleeAnimation extends X2Action;

//Cached info for the unit performing the action and the target object
//*************************************
var XGUnit                      SourceXGUnit;
var XComUnitPawn                SourceUnitPawn;

var XGUnit                      TargetXGUnit;
var XComUnitPawn                TargetUnitPawn;

var CustomAnimParams            Params;

var vector                      OriginalSourceHeading;
var vector                      OriginalTargetHeading;
var vector                      SourceToTarget;

//*************************************

var Name SourceAnim;
var Name TargetAnim;

//*************************************


function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;	
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;
	local XComGameState_Unit TargetUnit;

	super.Init(InTrack);
	
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	SourceXGUnit = XGUnit(UnitState.GetVisualizer());
	SourceUnitPawn = SourceXGUnit.GetPawn();
	OriginalSourceHeading = vector(SourceUnitPawn.Rotation);

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	TargetXGUnit = XGUnit(TargetUnit.GetVisualizer());
	TargetUnitPawn = TargetXGUnit.GetPawn();
	OriginalTargetHeading = vector(TargetUnitPawn.Rotation);

	SourceToTarget = TargetUnitPawn.Location - SourceUnitPawn.Location;
	SourceToTarget = Normal(SourceToTarget);
	SourceToTarget.Z = 0;
}

function bool IsTimedOut()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:

	// turn the unit(s) to face each other
	if( TargetXGUnit != None )
	{
		TargetXGUnit.IdleStateMachine.ForceHeading(-SourceToTarget);
	}
	SourceXGUnit.IdleStateMachine.ForceHeading(SourceToTarget);
	
	while( SourceXGUnit.IdleStateMachine.IsEvaluatingStance() || 
		  (TargetXGUnit != None && TargetXGUnit.IdleStateMachine.IsEvaluatingStance()) )
	{
		Sleep(0.0f);
	}

	// Start hacking anims
	if( TargetUnitPawn != None && TargetAnim != '' )
	{
		Params.AnimName = TargetAnim;
		Params.Looping = false;
		TargetUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	}

	Params.AnimName = SourceAnim;
	Params.Looping = false;
	FinishAnim(SourceUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	// return to previous facing
	if( TargetXGUnit != None )
	{
		TargetXGUnit.IdleStateMachine.ForceHeading(OriginalTargetHeading);
	}
	SourceXGUnit.IdleStateMachine.ForceHeading(OriginalSourceHeading);
	while( SourceXGUnit.IdleStateMachine.IsEvaluatingStance() ||
		  (TargetXGUnit != None && TargetXGUnit.IdleStateMachine.IsEvaluatingStance()) )
	{
		Sleep(0.0f);
	}

	CompleteAction();
}

defaultproperties
{
	SourceAnim = ""
	TargetAnim = ""
}

