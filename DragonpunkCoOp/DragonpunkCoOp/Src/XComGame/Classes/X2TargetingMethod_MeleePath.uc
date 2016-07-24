//---------------------------------------------------------------------------------------
//  FILE:    X2TargetingMethod_MeleePath.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Targeting method for activated melee attacks
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_MeleePath extends X2TargetingMethod;

var private X2MeleePathingPawn      PathingPawn;
var private XComActionIconManager   IconManager;
var private XComLevelBorderManager  LevelBorderManager;
var private XCom3DCursor            Cursor;
var private X2Camera_Midpoint		TargetingCamera; // deprecated
var private XGUnit					TargetUnit;

// the index of the last available target we were targeting
var private int LastTarget;

function Init(AvailableAction InAction)
{
	local XComPresentationLayer Pres;

	super.Init(InAction);

	Pres = `PRES;

	Cursor = `CURSOR;
	PathingPawn = Cursor.Spawn(class'X2MeleePathingPawn', Cursor);
	PathingPawn.SetVisible(true);
	PathingPawn.Init(UnitState, Ability);
	IconManager = Pres.GetActionIconMgr();
	LevelBorderManager = Pres.GetLevelBorderMgr();

	// force the initial updates
	IconManager.ShowIcons(true);
	LevelBorderManager.ShowBorder(true);
	IconManager.UpdateCursorLocation(true);
	LevelBorderManager.UpdateCursorLocation(Cursor.Location, true);

	DirectSelectNearestTarget();
}

private function DirectSelectNearestTarget()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local Vector SourceUnitLocation;
	local X2GameRulesetVisibilityInterface Target;
	local TTile TargetTile;

	local int TargetIndex;
	local float TargetDistanceSquared;
	local int ClosestTargetIndex;
	local float ClosestTargetDistanceSquared;

	if(Action.AvailableTargets.Length == 1)
	{
		// easy case. If only one target, they are the closest
		DirectSetTarget(0);
	}
	else
	{
		// iterate over each target in the target list and select the closest one to the source 
		ClosestTargetIndex = -1;

		History = `XCOMHISTORY;
		WorldData = `XWORLD;

		SourceUnitLocation = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);

		for (TargetIndex = 0; TargetIndex < Action.AvailableTargets.Length; TargetIndex++)
		{
			Target = X2GameRulesetVisibilityInterface(History.GetGameStateForObjectID(Action.AvailableTargets[TargetIndex].PrimaryTarget.ObjectID));
			`assert(Target != none);

			Target.GetKeystoneVisibilityLocation(TargetTile);
			TargetDistanceSquared = VSizeSq(WorldData.GetPositionFromTileCoordinates(TargetTile) - SourceUnitLocation);

			if(ClosestTargetIndex < 0 || TargetDistanceSquared < ClosestTargetDistanceSquared)
			{
				ClosestTargetIndex = TargetIndex;
				ClosestTargetDistanceSquared = TargetDistanceSquared;
			}
		}

		// we have a closest target now, so select it
		DirectSetTarget(ClosestTargetIndex);
	}
}

function Canceled()
{
	PathingPawn.Destroy();
	IconManager.ShowIcons(false);
	LevelBorderManager.ShowBorder(false);
}

function Committed()
{
	Canceled();
}

function bool AllowMouseConfirm()
{
	return true;
}

function Update(float DeltaTime)
{
	IconManager.UpdateCursorLocation();
	LevelBorderManager.UpdateCursorLocation(Cursor.Location);
}

function NextTarget()
{
	DirectSetTarget(LastTarget + 1);
}

function DirectSetTarget(int TargetIndex)
{
	local XComPresentationLayer Pres;
	local UITacticalHUD TacticalHud;
	local XComGameStateHistory History;
	local XComGameState_BaseObject Target;
	local X2Camera_LookAtActorTimed LookAtCamera;

	// advance the target counter
	LastTarget = TargetIndex % Action.AvailableTargets.Length;

	// put the targeting reticle on the new target
	Pres = `PRES;
	TacticalHud = Pres.GetTacticalHUD();
	TacticalHud.TargetEnemy(LastTarget);

	// have the idle state machine look at the new target
	FiringUnit.IdleStateMachine.CheckForStanceUpdate();

	// have the pathing pawn draw a path to the target
	History = `XCOMHISTORY;
	Target = History.GetGameStateForObjectID(Action.AvailableTargets[LastTarget].PrimaryTarget.ObjectID);
	PathingPawn.UpdateMeleeTarget(Target);

	TargetUnit = XGUnit(Target.GetVisualizer());

	LookAtCamera = new class'X2Camera_LookAtActorTimed';
	LookAtCamera.LookAtDuration = 0.0f;
	LookAtCamera.ActorToFollow = TargetUnit != none ? TargetUnit.GetPawn() : Target.GetVisualizer();
	`CAMERASTACK.AddCamera(LookAtCamera);
}

function int GetTargetIndex()
{
	return LastTarget;
}

function bool GetPreAbilityPath(out array<TTile> PathTiles)
{
	PathingPawn.GetTargetMeleePath(PathTiles);
	return PathTiles.Length > 1;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	local StateObjectReference Shooter;

	if( TargetUnit != None )
	{
		Shooter.ObjectID = TargetUnit.ObjectID;
		Focus = TargetUnit.GetShootAtLocation(eHit_Success, Shooter);
		return true;
	}
	
	return false;
}

defaultproperties
{
	ProvidesPath=true
}
