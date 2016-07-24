//-----------------------------------------------------------
// Used by the visualizer system to control a Camera
//-----------------------------------------------------------
class X2Camera_FollowMovingUnit extends X2Camera_LookAt
	dependson(X2Camera)
	config(Camera);

var const config bool UseFollowUnitCamera; // should we use this kind of camera instead of a normal frame ability camera?
var private const config int TilesToLookAhead; // tiles ahead of the unit along his path that we should be looking towards
var private const config int TilesToPlaceCameraAheadOfUnit; // how far ahead of the unit should the movement camera be placed

var private const config float LookAheadVsLookTowardDestinationRatio; // 0.0 == full look ahead, 1.0 == full look toward destination.
var private const config bool SkipIfPathAlreadyInSafeZone; // if true, will only do the camera if the path starts or ends outside the safe zone

// ability that this camera should be framing
var XComGameStateContext_Ability MoveAbility;

// Unit pawn that is moving
var XGUnit Unit;

// Unit pawn that is moving
var private XComUnitPawn UnitPawn;

// angle from the moving unit at which the camera's lookat point is placed
var private Rotator CurrentLookAheadRotation;

// if this is the first update, force the look ahead rotation to be absolute
var private bool FirstUpdate;

// since we need path information before the unit begins moving, we need to setup our own path
var private XComPath PathToFollow;

var private Vector LookAtPoint;

// true if the camera is done with the move
var privatewrite bool HasArrived;

// if the unit's path was already on the screen, then don't move the camera. Just wait for the unit to finish moving
var privatewrite bool IsStationary;

var private bool bHiddenAtStart;

var private array<TTile> PathFocalTiles;

var bool bLockFloorZ;       //  don't move up/down based on unit changing floors

function Added()
{
	local array<PathPoint> MovementData;

	super.Added();

	`assert(Unit != none);
	
	UnitPawn = Unit.GetPawn();
	`assert(UnitPawn != none);
	bHiddenAtStart = UnitPawn.bHidden;

	PathToFollow = new class'XComPath';
	MovementData = Unit.CurrentMoveData.MovementData;
	PathToFollow.SetPathPointsDirect(MovementData); //follow cameras follow the first member of a group

	BuildPathFocalTiles();

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

function Removed()
{
	super.Removed();

	`XCOMVISUALIZATIONMGR.RemoveObserver(self);
}

function BuildPathFocalTiles()
{
	local TTile Tile;
	local int PathResultIndex;
	local int PathTileIndex;

	for (PathResultIndex = 0; PathResultIndex < MoveAbility.ResultContext.PathResults.Length; PathResultIndex++)
	{
		for (PathTileIndex = 0; PathTileIndex < MoveAbility.ResultContext.PathResults[PathResultIndex].PathTileData.Length; PathTileIndex++)
		{
			Tile = MoveAbility.ResultContext.PathResults[PathResultIndex].PathTileData[PathTileIndex].EventTile;
			PathFocalTiles.AddItem(Tile);
		}
	}
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	local TPOV StartingPOV;
	local PathPoint PointOnPath;
	local bool PathIsOutsideTether;

	super.Activated(CurrentPOV, PreviousActiveCamera, LastActiveLookAtCamera);

	if(SkipIfPathAlreadyInSafeZone)
	{
		// check if the path lies completely within the tether safe zone. If it does, just pop immediately.
		// There's no need to have the camera move around if everything is already on screen

		PathIsOutsideTether = false;
		StartingPOV = GetCameraLocationAndOrientation();

		foreach MoveAbility.InputContext.MovementPaths[0].MovementData(PointOnPath) //follow cameras follow the first member of a group
		{
			if(!IsPointWithinTether(StartingPOV, PointOnPath.Position))
			{
				PathIsOutsideTether = true;
				break;
			}
		}

		if(!PathIsOutsideTether)
		{
			IsStationary = true; // stay put
			HasArrived = true; // we have arrived
			LookAtPoint = LastActiveLookAtCamera.GetCameraLookat();
		}
	}
}

function UpdateCamera(float DeltaTime)
{
	local Vector LookAheadPoint;
	local Vector LookTowardDestinationPoint;
	local Vector BlendedPoint;
	local Rotator NewLookAheadRotation;
	local float LookAheadDistance;
	local TPOV CurrentCameraLocation;
	local XCom3DCursor Cursor;
	local Vector Delta;
	local Vector TetherPoint;
	local TTile FocalTile, PawnFloorTile;
	local Vector PawnFeet;

	super.UpdateCamera(DeltaTime);

	if(IsStationary)
	{
		// the user can still spin the camera around (which could make part of the path lie outside the screen), 
		// so make sure the unit stays inside the tether even if we aren't officially tracking him
		TetherPoint = Unit.GetLocation();
		
		Cursor = `CURSOR;
		TetherPoint.Z = Cursor.GetFloorMinZ(Cursor.WorldZToFloor(TetherPoint));

		LookAtPoint = GetTetheredLookatPoint(TetherPoint, GetCameraLocationAndOrientation());
		return;
	}

	// the camera can look both in the direction the unit is moving (look ahead point) as we as towards the 
	// move destination. We then blend the desired amount of both to get the final camera look at point. This gives design a
	// little more control over the feel of the camera without needing an engineer to help iterate the options
	// look at a location a little ahead of the unit along it's path
	LookAheadPoint = PathToFollow.FindPointOnPath(UnitPawn.m_fDistanceMovedAlongPath + TilesToLookAhead * class'XComWorldData'.const.WORLD_StepSize);
	LookTowardDestinationPoint = Unit.GetLocation() + Normal(PathToFollow.GetEndPoint() - Unit.GetLocation()) * class'XComWorldData'.const.WORLD_StepSize;

	BlendedPoint = VLerp(LookAheadPoint, LookTowardDestinationPoint, LookAheadVsLookTowardDestinationRatio);

	// slowly interpolate to the desired lookahead angle. This smooths out small bumps and janks
	// in the unit's path
	Delta = BlendedPoint - Unit.GetLocation();
	NewLookAheadRotation = Rotator(Delta);

	if(FirstUpdate)
	{
		 // set directly on the first update or we will blend from the default facing
		FirstUpdate = false;
		CurrentLookAheadRotation = NewLookAheadRotation;
	}
	else
	{
		CurrentLookAheadRotation = RLerp(CurrentLookAheadRotation, NewLookAheadRotation, DeltaTime, true);
	}

	// determine the distance in front of the unit we should place the camera
	LookAheadDistance = TilesToPlaceCameraAheadOfUnit * class'XComWorldData'.const.WORLD_StepSize;

	// need to take zoom scaling into account
	LookAheadDistance = LookAheadDistance * (GetCameraDistanceFromLookAtPoint() / default.DistanceFromCursor);

	// as we approach the destination, pull the camera in so that it stops right on the destination
	LookAheadDistance = fMin(LookAheadDistance, VSize2D(Unit.GetLocation() - PathToFollow.GetEndPoint()));

	//If the unit is hidden at the start of its move, and is still hidden. Have the camera look at the point where the unit will appear out of the fog
	if(bHiddenAtStart && Unit.bHidden)
	{		
		if(PathToFollow.IsValid())
		{
			//Best case, look at the start point of the move ( will be limited to the visible portion of the move )
			LookAtPoint = GetTetheredLookatPoint(PathToFollow.GetStartPoint(), GetCameraLocationAndOrientation());
		}
		else if(PathFocalTiles.Length > 0)
		{
			//Failsafe, look at the destination / last focal point of the move
			FocalTile = PathFocalTiles[PathFocalTiles.Length - 1];
			LookAtPoint = `XWORLD.GetPositionFromTileCoordinates(FocalTile);
		}
		else
		{
			//Something bad has happened so fall back to looking at destination of the move
			LookAtPoint = MoveAbility.InputContext.MovementPaths[0].MovementData[MoveAbility.InputContext.MovementPaths[0].MovementData.Length - 1].Position;
		}
	}
	else
	{
		if (bLockFloorZ)
		{
			PawnFeet = UnitPawn.GetFeetLocation();
			`XWORLD.GetFloorTileForPosition(PawnFeet, PawnFloorTile, true);
			LookAtPoint = PawnFeet + Vector(CurrentLookAheadRotation) * LookAheadDistance;
			LookAtPoint.Z = PawnFloorTile.Z;
		}
		else
		{
			LookAtPoint = UnitPawn.GetFeetLocation() + Vector(CurrentLookAheadRotation) * LookAheadDistance;
			// Snap us to the bottom of the floor the unit is in. Smooths out bumps and jumps in the path.
			// But only do this if the unit isn't actively flying. It feels janky for flying units.
			if(UnitPawn.Physics != PHYS_Flying)
			{
				Cursor = `CURSOR;
				LookAtPoint.Z = Cursor.GetFloorMinZ(Cursor.WorldZToFloor(Unit.GetLocation()));
			}
		}
	}

	CurrentCameraLocation = GetCameraLocationAndOrientation();
	HasArrived = HasArrived || IsPointWithinTether(CurrentCameraLocation, LookAtPoint);
}

protected function RemoveSelfFromCameraStack()
{
	super.RemoveSelfFromCameraStack();
	HasArrived = true; // need to make sure we set this if we remove ourself so we don't block anything waiting for us to arrive
}

protected function Vector GetCameraLookat()
{
	return LookAtPoint;
}

function GetCameraFocusPoints(out array<TFocusPoints> OutFocusPoints)
{
	local XComWorldData WorldData;
	local TFocusPoints FocusPoint;
	local TPOV CurrentCameraLocation;
	local TTile Tile, UnitTile;	
	local int Index;

	WorldData = `XWORLD;

	CurrentCameraLocation = GetCameraLocationAndOrientation();
	FocusPoint.vCameraLocation = CurrentCameraLocation.Location;
	FocusPoint.vFocusPoint = Unit.GetLocation();
	OutFocusPoints.AddItem(FocusPoint);

	WorldData.GetFloorTileForPosition(FocusPoint.vFocusPoint, UnitTile);

	if (WorldData != none)
	{
		for (Index = 0; Index < PathFocalTiles.Length; Index++)
		{
			if (UnitTile == PathFocalTiles[Index])
			{
				PathFocalTiles.Remove(0, Index+1);
				Index = -1;
			}
			else
			{
				Tile = PathFocalTiles[Index];
				FocusPoint.vFocusPoint = WorldData.GetPositionFromTileCoordinates(Tile);
				FocusPoint.vCameraLocation = FocusPoint.vFocusPoint - (Vector(CurrentCameraLocation.Rotation) * 9999);
				OutFocusPoints.AddItem(FocusPoint);
			}
		}
	}
}

function bool DisableFocusPointExpiration()
{
	return false;
}

function bool GetCameraIsPrimaryFocusOn()
{
	return true;
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	// if the active unit changes mid-ability, jump to the new active unit
	// so that the player can control it
	if(NewActiveUnit.ObjectID != MoveAbility.InputContext.SourceObject.ObjectID)
	{
		RemoveSelfFromCameraStack();
	}
}

event OnVisualizationIdle()
{
	// safety: if visualization goes idle and we're still on the stack, remove ourself from the stack.
	// once idle, the move must be finished
	`Redscreen("Follow moving unit cam had to be removed with OnVisualizationIdle(), something terrible has happened.");
	RemoveSelfFromCameraStack();
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	// we want to frame the entire move ability, so make sure we are checking against the last state in
	// any possible interruption chain that is happening.
	if(MoveAbility.GetLastStateInInterruptChain().HistoryIndex == AssociatedGameState.HistoryIndex)
	{
		RemoveSelfFromCameraStack();
	}
}

function string GetDebugDescription()
{
	return super.GetDebugDescription() $ " - " $ MoveAbility.InputContext.AbilityTemplateName;
}

defaultproperties
{
	UpdateWhenInactive=true
	Priority=eCameraPriority_CharacterMovementAndFraming

	FirstUpdate=true
}