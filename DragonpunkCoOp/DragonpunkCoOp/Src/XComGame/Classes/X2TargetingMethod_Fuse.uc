class X2TargetingMethod_Fuse extends X2TargetingMethod_TopDown;

var protected XComGameState_Ability FuseAbility;

function DirectSetTarget(int TargetIndex)
{
	local StateObjectReference FuseRef;
	local XComGameState_Unit TargetUnit;
	local int TargetID;
	local array<TTile> Tiles;

	super.DirectSetTarget(TargetIndex);

	FuseAbility = none;
	TargetID = GetTargetedObjectID();
	if (TargetID != 0)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetID));
		if (TargetUnit != none)
		{
			if (class'X2Condition_FuseTarget'.static.GetAvailableFuse(TargetUnit, FuseRef))
			{
				FuseAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(FuseRef.ObjectID));
				if (FuseAbility != none && FuseAbility.GetMyTemplate().AbilityMultiTargetStyle != none)
				{
					FuseAbility.GetMyTemplate().AbilityMultiTargetStyle.GetValidTilesForLocation(FuseAbility, GetTargetedActor().Location, Tiles);	
					DrawAOETiles(Tiles);
				}
			}
		}
	}
}

function Update(float DeltaTime)
{
	local XComGameState_Ability ActualAbility;
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local TTile SnapTile;

	NewTargetLocation = GetTargetedActor().Location;
	SnapTile = `XWORLD.GetTileCoordinatesFromPosition( NewTargetLocation );
	`XWORLD.GetFloorPositionForTile( SnapTile, NewTargetLocation );

	if(NewTargetLocation != CachedTargetLocation)
	{		
		ActualAbility = Ability;
		Ability = FuseAbility;
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );

		Ability = ActualAbility;
		CachedTargetLocation = NewTargetLocation;
	}
}

function Canceled()
{
	ClearTargetedActors();
	super.Canceled();
}