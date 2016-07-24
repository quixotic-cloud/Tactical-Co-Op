//-----------------------------------------------------------
//
//-----------------------------------------------------------
class XComTacticalHUD extends XComHUD;

const MAXIMUM_PICK_SLOPE_COEFFICIENT = 0.2;

var array<XComBuildingVolume> m_arrBuildingVolumes;

simulated event PostBeginPlay()
{
	local XComBuildingVolume kVolume;

	super.PostBeginPlay();

	foreach AllActors(class'XComBuildingVolume', kVolume)
	{
		m_arrBuildingVolumes.AddItem(kVolume);
	}
}

simulated private function XCom3DCursor Get3DCursor()
{
	local XComTacticalController kTacticalPC;
	
	if(PlayerOwner == none) return none;
	
	kTacticalPC = XComTacticalController(PlayerOwner);
	if(kTacticalPC != none)
	{
		return kTacticalPC.GetCursor();
	}
	else
	{
		return none;
	}
}

function XComUnitPawn GetPawnInSameTile(Vector HitLocation)
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local StateObjectReference UnitReference;
	local XGUnit UnitVisualizer;
	local TTile Tile;

	WorldData = `XWORLD;
	if(WorldData == none) return none;

	if(WorldData.GetFloorTileForPosition(HitLocation, Tile))
	{
		UnitReference = WorldData.GetUnitOnTile(Tile);
		if (UnitReference.ObjectID > 0)
		{
			History = `XCOMHISTORY;
			UnitVisualizer = XGUnit(History.GetVisualizer(UnitReference.ObjectID));
			return UnitVisualizer != none ? UnitVisualizer.GetPawn() : none;
		}
	}

	return none;
}

protected function bool IsPositionInPathableTile(Vector kPosition, bool CheckUpAndDownRampTiles)
{
	local XComWorldData kWorldData;
	local bool bPositionOnFloorAndValid;
	local TTile PositionTile;
	local TTile OffsetTile;

	kWorldData = `XWORLD;
	if(kWorldData == none) return false;

	kPosition.Z += 1; // to avoid problems when the point is coplanaer with the bottom of the tile
	bPositionOnFloorAndValid = kWorldData.IsPositionOnFloorAndValidDestination(kPosition);

	if (CheckUpAndDownRampTiles && bPositionOnFloorAndValid == false)
	{
		PositionTile = kWorldData.GetTileCoordinatesFromPosition(kPosition);
		OffsetTile = PositionTile;
		OffsetTile.Z += 1;

		if (kWorldData.IsRampTile(OffsetTile))
		{
			return true;
		}

		OffsetTile.Z = PositionTile.Z - 1;

		if (kWorldData.IsRampTile(OffsetTile))
		{
			return true;
		}
	}

	return kWorldData.IsPositionOnFloorAndValidDestination(kPosition);
}

protected function IMouseInteractionInterface GetMousePickActor()
{
	local XComLevelVolume   kLevelVolume;
	local XCom3DCursor      k3DCursor;

	local bool              bSkipActor;
	local bool             			 bDebugTrace;

	local IMouseInteractionInterface kInterface;
	local Actor						 kHitActor;
	local XComUnitPawn				 kHitPawn;
	local UIDisplay_LevelActor       kHitDisplayActor;
	local XComLevelActor             kHitLevelActor;
	local XComFracLevelActor         kHitFracActor;
	local Vector					 vHitLocation;
	local Vector					 vHitNormal; 
	local bool						 bHitActorIsPathable;
	local int						 iHitFloor;

	local IMouseInteractionInterface kBestInterface;
	local bool                       bBestActorIsPathable;
	local int                        iBestFloor;
	local bool                       PathHasWaypoints;

	bDebugTrace = false;
	if(PlayerOwner.CheatManager != none 
		&& XComTacticalCheatManager(PlayerOwner.CheatManager) != none 
		&& XComTacticalCheatManager(PlayerOwner.CheatManager).bDebugMouseTrace)
	{
		bDebugTrace = true;
	}

	kLevelVolume = `LEVEL != none ? `LEVEL.LevelVolume : none;
	if(kLevelVolume == none) return none;

	k3DCursor = Get3DCursor();
	if(k3DCursor == none) return none;

	kBestInterface = none;
	iBestFloor = -1;

	PathHasWaypoints = XComTacticalController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).m_kPathingPawn.Waypoints.Length > 0;

	// Perform a trace actor iterator. An iterator is used so that we get the top most mouse interaction
	// interface. This covers cases when other traceable objects (such as static meshes) are above mouse
	// interaction interfaces.
	ForEach TraceActors(class'Actor', 
						kHitActor, 
						vHitLocation, 
						vHitNormal, 
						CachedMouseWorldOrigin + CachedMouseWorldDirection * 165536.f, 
						CachedMouseWorldOrigin, 
						vect(0,0,0))
	{
		kInterface = IMouseInteractionInterface(kHitActor);
		if(bDebugTrace) DrawDebugSphere(vHitLocation, 15, 12, 0, 0, 255, false); 

		if (kInterface == none) continue; // not a mouseable actor, skip
		kHitPawn = XComUnitPawn(kInterface);
		kHitDisplayActor = UIDisplay_LevelActor(kHitActor);
		
		// check to see if there is a pawn in the tile we are picking, if so we'd rather highlight them
		if(kHitPawn == none)
		{
			kHitPawn = GetPawnInSameTile(vHitLocation);
			if(kHitPawn != none) 
			{
				kInterface = kHitPawn;
			}
		}

		if(kHitPawn != none)
		{
			vHitLocation = kHitPawn.GetFeetLocation();
		}

		//Allow us to click through a 3D UI display if it's hidden (hidden = (movie == none)). 
		if(kHitDisplayActor != none && kHitDisplayActor.m_kMovie == none) 
			continue; 

		// ignore collision with geo marked as "do not collide with 3D cursor"
		if(XComInteractiveLevelActor(kHitActor) == none // still want to be able to click doors, etc
			&& kHitDisplayActor == none) 
		{
			kHitLevelActor = XComLevelActor(kHitActor);
			if(kHitLevelActor != none && kHitLevelActor.bIgnoreFor3DCursorCollision)
				continue;

			kHitFracActor = XComFracLevelActor(kHitActor);
			if(kHitFracActor != none && kHitFracActor.bIgnoreFor3DCursorCollision)
				continue;

			// ignore hits that are on surfaces too steep to ever be walked on (safety catch for walls that
			// may not be marked as do not collide with cursor and aren't UI)
			if((vect(0, 0, 1) dot vHitNormal) < MAXIMUM_PICK_SLOPE_COEFFICIENT) // if wall surface is very close to vertical or upside down
			{
				continue;
			}
		}

		// ignore hits that lie outside the level boundry
		if(!kLevelVolume.ContainsPoint(vHitLocation)) 
			continue;

		iHitFloor = k3DCursor.WorldZToFloor(vHitLocation);
		bHitActorIsPathable = IsPositionInPathableTile(vHitLocation, kHitLevelActor != none && kHitLevelActor.bIsStair);

		if(kBestInterface != none)
		{
			// see if we should skip this actor and keep the previous hit, or if this hit is better
			bSkipActor = true;

			// this check gives us the first actor that is at or below the requested floor, unless there are no hits below
			// our requested floor, in which case we take the lowest floor above.
			if(iBestFloor > k3DCursor.m_iRequestedFloor && iHitFloor < iBestFloor)
			{
				bSkipActor = false;
			}

			if(bSkipActor && iHitFloor == iBestFloor)
			{
				// within a given floor, priority is pawn/interactive actor->pathable floor->non-pathable floor
				if(bHitActorIsPathable 
					&& !bBestActorIsPathable 
					&& XComPawn(kBestInterface) == none 
					&& (PathHasWaypoints || XComInteractiveLevelActor(kBestInterface) == none)) // if we've placed a waypoint, we can't interact anyway, so skip interactives from blocking pathing picks
				{
					bSkipActor = false;
				}
				else if(kHitPawn != none && XComPawn(kBestInterface) == none && (PathHasWaypoints || XComInteractiveLevelActor(kBestInterface) == none))
				{
					bSkipActor = false;
				}
				else if (kHitLevelActor != none && kHitLevelActor.bIsStair)
				{
					bSkipActor = false;
				}
			}

			// UI is highest priority!
			if (!bSkipActor && kBestInterface.IsA('UIDisplay_LevelActor'))
			{
				bSkipActor = true;
			}

			if(bSkipActor)
			{
				continue;
			}
		}

		CachedHitLocation = vHitLocation;
		kBestInterface = kInterface;
		bBestActorIsPathable = bHitActorIsPathable;
		iBestFloor = iHitFloor;

		if(bDebugTrace) DrawDebugSphere(vHitLocation, 16, 12, 255, 0, 0, false); 
	}

	return kBestInterface; 
}