class X2TargetingMethod_Cone extends X2TargetingMethod;

var protected XCom3DCursor Cursor;
var protected XComPrecomputedPath GrenadePath;
var protected vector NewTargetLocation, FiringLocation;
var protected bool bRestrictToSquadsightRange;
var protected StateObjectReference AssociatedPlayerStateRef;
var protected float ConeLength, ConeWidth;
var protected XComWorldData WorldData;

var protected X2Actor_ConeTarget ConeActor;
var protected bool bGoodTarget;
var protected TTile FiringTile;

var protected array<TTile>			ReticuleTargetedTiles;    // These are tiles the targeting system has set to be active tiles
var protected array<TTile>			ReticuleTargetedSecondaryTiles;    // These are neighboring tiles the from the main targeted tiles

function Init(AvailableAction InAction)
{
	local float TargetingRange;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityMultiTarget_Cone ConeMultiTarget;
	local X2AbilityTemplate AbilityTemplate;

	super.Init(InAction);
	WorldData = `XWORLD;

	// get the firing unit
	FiringTile = UnitState.TileLocation;
	FiringLocation = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);
	FiringLocation.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;

	AssociatedPlayerStateRef.ObjectID = UnitState.ControllingPlayer.ObjectID;

	// determine our targeting range
	TargetingRange = Ability.GetAbilityCursorRangeMeters();

	// lock the cursor to that range
	Cursor = `Cursor;
	Cursor.m_fMaxChainedDistance = `METERSTOUNITS(TargetingRange);

	AbilityTemplate = Ability.GetMyTemplate();

	ConeMultiTarget = X2AbilityMultiTarget_Cone(AbilityTemplate.AbilityMultiTargetStyle);
	`assert(ConeMultiTarget != none);
	ConeLength = ConeMultiTarget.GetConeLength(Ability);
	ConeWidth = ConeMultiTarget.GetConeEndDiameter(Ability);

	CursorTarget = X2AbilityTarget_Cursor(AbilityTemplate.AbilityTargetStyle);
	if (CursorTarget != none)
		bRestrictToSquadsightRange = CursorTarget.bRestrictToSquadsightRange;

	if (!AbilityTemplate.SkipRenderOfTargetingTemplate)
	{
		// setup the targeting mesh
		ConeActor = `BATTLE.Spawn(class'X2Actor_ConeTarget');
		if(AbilityIsOffensive)
		{
			ConeActor.MeshLocation = "UI_3D.Targeting.ConeRange";
		}
		ConeActor.InitConeMesh(ConeLength / class'XComWorldData'.const.WORLD_StepSize, ConeWidth / class'XComWorldData'.const.WORLD_StepSize);
		ConeActor.SetLocation(FiringLocation);
	}
}

function Canceled()
{
	super.Canceled();
	// unlock the 3d cursor
	Cursor.m_fMaxChainedDistance = -1;

	// clean up the ui
	ConeActor.Destroy();
	ClearTargetedActors();
}

function Committed()
{
	Canceled();
}

simulated protected function DrawSplashRadius(Vector TargetLoc)
{
	local Vector ShooterToTarget;
	local Rotator ConeRotator;

	if (ConeActor != none)
	{
		ShooterToTarget = TargetLoc - FiringLocation;
		ConeRotator = rotator(ShooterToTarget);
		ConeActor.SetRotation(ConeRotator);
	}
}

function bool FindTile(TTile t, out array<TTile> tileList)
{
	local TTile iter;
	foreach tileList(iter)
	{
		if (iter == t)
		{
			return true;
		}
	}
	return false;
}

function bool IsNeighborTile(TTile t, out array<TTile> neighbors)
{
	local TTile iter;

	foreach neighbors(iter)
	{
		if ((iter.X >= t.X - 1 && iter.X <= t.X + 1) &&
			(iter.Y >= t.Y - 1 && iter.Y <= t.Y + 1) &&
			//(iter.Z >= t.Z - 1 && iter.Z <= t.Z + 1))
			(iter.Z == t.Z))
		{
			return true;
		}
	}

	return false;
}

function bool IsNextToWall(TTile t)
{
	local TTile test;

	test = t;
	if (!(`XWORLD.IsTileFullyOccupied(test) == false && `XWORLD.IsTileOccupied(test) == true))
	{
		return false;
	}

	test = t;
	test.X += 1;
	if (`XWORLD.IsTileFullyOccupied(test) && `XWORLD.IsTileBlockedByUnitFlag(test) == false)
	{
		return true;
	}

	test = t;
	test.X -= 1;
	if (`XWORLD.IsTileFullyOccupied(test) && `XWORLD.IsTileBlockedByUnitFlag(test) == false)
	{
		return true;
	}

	test = t;
	test.Y += 1;
	if (`XWORLD.IsTileFullyOccupied(test) && `XWORLD.IsTileBlockedByUnitFlag(test) == false)
	{
		return true;
	}

	test = t;
	test.Y -= 1;
	if (`XWORLD.IsTileFullyOccupied(test) && `XWORLD.IsTileBlockedByUnitFlag(test) == false)
	{
		return true;
	}

	return false;
}


function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector Direction;
	local TTile TargetTile;
	local array<TTile> Tiles, NeighborTiles;
	local X2AbilityMultiTarget_Cone targetingMethod;
	local INT i;

	NewTargetLocation = Cursor.GetCursorFeetLocation();
	TargetTile = WorldData.GetTileCoordinatesFromPosition(NewTargetLocation);
	NewTargetLocation = WorldData.GetPositionFromTileCoordinates(TargetTile);

	if (TargetTile == FiringTile)
	{
		bGoodTarget = false;
		return;
	}

	bGoodTarget = true;
	Direction = NewTargetLocation - FiringLocation;

	NewTargetLocation = FiringLocation + (Direction / VSize(Direction)) * ConeLength;       //  recalibrate based on direction to cursor; must always be as long as possible

	if (NewTargetLocation != CachedTargetLocation)
	{
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);

		targetingMethod = X2AbilityMultiTarget_Cone(Ability.GetMyTemplate().AbilityMultiTargetStyle);

		if (Ability.GetMyTemplate().bAffectNeighboringTiles)
		{
			ReticuleTargetedTiles.Length = 0;
			ReticuleTargetedSecondaryTiles.Length = 0;
			Tiles.Length = 0;

			targetingMethod.GetCollisionValidTilesForLocation(Ability, NewTargetLocation, Tiles, NeighborTiles);

			//class'WorldInfo'.static.GetWorldInfo().FlushPersistentDebugLines();
			ReticuleTargetedTiles = Tiles;

			for (i = 0; i < NeighborTiles.Length; i++)
			{
				if (IsNeighborTile(NeighborTiles[i], ReticuleTargetedTiles) && IsNextToWall(NeighborTiles[i]) )
				{
					ReticuleTargetedSecondaryTiles.AddItem(NeighborTiles[i]);
					//`SHAPEMGR.DrawTile(NeighborTiles[i], 0, 255, 0, 0.9);
				}
			}
		}

		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawSplashRadius(NewTargetLocation);		
		DrawAOETiles(Tiles);
	}

	Super.Update(DeltaTime);
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	TargetLocations.Length = 0;
	TargetLocations.AddItem(NewTargetLocation);
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	local TTile TestLoc;
	if (TargetLocations.Length == 1 && bGoodTarget)
	{
		if (bRestrictToSquadsightRange)
		{
			TestLoc = `XWORLD.GetTileCoordinatesFromPosition(TargetLocations[0]);
			if (!class'X2TacticalVisibilityHelpers'.static.CanSquadSeeLocation(AssociatedPlayerStateRef.ObjectID, TestLoc))
				return 'AA_NotVisible';
		}
		return 'AA_Success';
	}
	return 'AA_NoTargets';
}

function int GetTargetIndex()
{
	return 0;
}

function bool GetAdditionalTargets(out AvailableTarget AdditionalTargets)
{
	Ability.GatherAdditionalAbilityTargetsForLocation(NewTargetLocation, AdditionalTargets);
	return true;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	Focus = NewTargetLocation;
	return true;
}

function GetReticuleTargets(out array<TTile> ReticuleMainTargets, out array<TTile> ReticuleSecondaryTargets)
{
	ReticuleMainTargets = ReticuleTargetedTiles;
	ReticuleSecondaryTargets = ReticuleTargetedSecondaryTiles;
}