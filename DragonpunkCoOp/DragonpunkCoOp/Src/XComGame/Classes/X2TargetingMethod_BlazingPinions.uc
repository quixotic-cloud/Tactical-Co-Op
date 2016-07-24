//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_BlazingPinions extends X2TargetingMethod;

var protected XCom3DCursor Cursor;
var protected bool bRestrictToSquadsightRange;

var private X2Actor_InvalidTarget InvalidTileActor;
var private X2Actor_BlazingPinionsTarget TargetActor;

function Init(AvailableAction InAction)
{
	local float TargetingRange;
	local X2AbilityTarget_Cursor CursorTarget;
	local XGBattle Battle;

	super.Init(InAction);

	Battle = `BATTLE;

	// determine our targeting range
	TargetingRange = Ability.GetAbilityCursorRangeMeters();

	// lock the cursor to that range
	Cursor = `Cursor;
	Cursor.m_fMaxChainedDistance = `METERSTOUNITS(TargetingRange);

	CursorTarget = X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle);
	if( CursorTarget != none )
	{
		bRestrictToSquadsightRange = CursorTarget.bRestrictToSquadsightRange;
	}

	InvalidTileActor = Battle.Spawn(class'X2Actor_InvalidTarget');
	TargetActor = Battle.Spawn(class'X2Actor_BlazingPinionsTarget');
}

function Canceled()
{
	super.Canceled();

	// unlock the 3d cursor
	Cursor.m_fMaxChainedDistance = -1;

	// clean up the ui
	InvalidTileActor.Destroy();
	TargetActor.Destroy();
	ClearTargetedActors();
}

function Committed()
{
	Canceled();
}

simulated protected function Vector GetSplashRadiusCenter()
{
	local Vector Center;
	local XComWorldData World;
	local vector CursorLocation;
	local TTile CursorTile;

	World = `XWORLD;
	CursorLocation = Cursor.Location;
	CursorLocation.Z = World.GetFloorZForPosition(CursorLocation);
	
	CursorTile = World.GetTileCoordinatesFromPosition(CursorLocation);
	CursorLocation = World.GetPositionFromTileCoordinates(CursorTile);

	Center = Cursor.Location;
	Center.Z = World.GetFloorZForPosition(CursorLocation);

	return Center;
}

simulated protected function DrawSplashRadius()
{
	local Vector Center;
	local float Radius;

	Center = GetSplashRadiusCenter();
	Radius = Ability.GetAbilityRadius();

	TargetActor.SetDrawScale(Radius / 48.0f);
	TargetActor.SetLocation(Center);
	TargetActor.SetHidden(false);

	InvalidTileActor.SetHidden(true);
}

simulated protected function DrawInvalidTile()
{
	local Vector Center;

	Center = GetSplashRadiusCenter();

	// Hide the Target Actor
	TargetActor.SetHidden(true);
	
	InvalidTileActor.SetHidden(false);
	InvalidTileActor.SetLocation(Center);
}

function Update(float DeltaTime)
{
	local vector NewTargetLocation;
	local array<vector> TargetLocations;
	local array<TTile> Tiles;
	
	NewTargetLocation = Cursor.GetCursorFeetLocation();

	if( NewTargetLocation != CachedTargetLocation )
	{
		TargetLocations.AddItem(Cursor.GetCursorFeetLocation());
		if( ValidateTargetLocations(TargetLocations) == 'AA_Success')
		{
			// The current tile the cursor is on is a valid tile
			DrawSplashRadius();
			Ability.GetMyTemplate().AbilityMultiTargetStyle.GetValidTilesForLocation(Ability, NewTargetLocation, Tiles);
		}
		else
		{
			DrawInvalidTile();
		}
		DrawAOETiles(Tiles);
		CachedTargetLocation = NewTargetLocation;
	}
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityMultiTarget_BlazingPinions BlazingPinionsMultiTarget;
	local AvailableTarget PossibleTargets;

	AbilityTemplate = Ability.GetMyTemplate();
	BlazingPinionsMultiTarget = X2AbilityMultiTarget_BlazingPinions(AbilityTemplate.AbilityMultiTargetStyle);
	`assert(BlazingPinionsMultiTarget != none);

	GetAdditionalTargets(PossibleTargets);
	TargetLocations.Length = 0;
	BlazingPinionsMultiTarget.CalculateValidLocationsForLocation(Ability, Cursor.GetCursorFeetLocation(), PossibleTargets, TargetLocations);
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	local TTile TestLoc, TestLocSky;
	local XComWorldData World;
	local bool FoundFloorTile;
	local GameRulesCache_VisibilityInfo DirectionInfo;

	if( TargetLocations.Length > 0 )
	{
		World = `XWORLD;

		FoundFloorTile = World.GetFloorTileForPosition(TargetLocations[0], TestLoc, true);
		TestLocSky = TestLoc;
		TestLocSky.Z = World.WORLD_FloorHeightsPerLevel * World.WORLD_TotalLevels;

		if( FoundFloorTile && World.CanSeeTileToTile(TestLoc, TestLocSky, DirectionInfo) )
		{
			// This tile can see the max tile above it in the sky
			return 'AA_Success';
		}
	}

	return 'AA_NoTargets';
}

function int GetTargetIndex()
{
	return 0;
}

function bool GetAdditionalTargets(out AvailableTarget AdditionalTargets)
{
	Ability.GatherAdditionalAbilityTargetsForLocation(Cursor.GetCursorFeetLocation(), AdditionalTargets);
	return true;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	Focus = Cursor.GetCursorFeetLocation();
	return true;
}