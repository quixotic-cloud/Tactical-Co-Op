//-----------------------------------------------------------
//
//-----------------------------------------------------------
class Helpers extends Object
	dependson(XComGameStateVisualizationMgr)
	abstract
	native;

struct native CamCageResult
{
	var int                 iCamZoneID;
	var int                 iCamZoneBlocked;
};


native static final function float S_EvalInterpCurveFloat( const out InterpCurveFloat Curve, float AlphaValue );
native static final function vector S_EvalInterpCurveVector( const out InterpCurveVector Curve, float AlphaValue );

native static final function rotator RotateLocalByWorld( rotator Local, rotator ByWorld );

native static final function bool isVisibilityBlocked(vector vFrom, vector vTo, Actor SourceActor, out vector vHitLoc, optional bool bVolumesOnly = false);

native static final function OverridePPSettings(out PostProcessSettings BasePPSettings, out PostProcessSettings NewPPSettings, float Alpha);

native static final function WorldInfo GetWorldInfo();

static final function OutputMsg( string msg, optional name logCategory)
{
    local Console PlayerConsole;
    local LocalPlayer LP;

	LP = LocalPlayer( GetWorldInfo().GetALocalPlayerController().Player );
	if( ( LP != none )  && ( LP.ViewportClient.ViewportConsole != none ) )
	{
		PlayerConsole = LP.ViewportClient.ViewportConsole;
		PlayerConsole.OutputText(msg);
	}
	
	//Output to log just encase..
	`log(msg, true, logCategory);
}

static simulated native function SetGameRenderingEnabled(bool Enabled, int iFrameDelay);

static native final function int NextAbilityID();

/**
 * GetUVCoords - Used to get the UV intersection of a ray with a static mesh.
 * MeshComp - The mesh component you want to test intersection with
 * vWorldStartPos - The origin point of the line check in world space
 * vWorldDirection - The direction of the line check in world space
 * Return value - FVector2D - return the UVs of the intersection point. Returns (-1,-1) if we failed intersection.
 */
static native function vector2d GetUVCoords(StaticMeshComponent MeshComp, vector vWorldStartPos, vector vWorldDirection);

native static final function bool AreVectorsDifferent(const out Vector v1, const out Vector v2, float fTolerance);

/**
 * Returns the concatenated hashes of all the important packages we care the network to verify between client and server.
 */
native static final function string NetGetVerifyPackageHashes();

static native function bool NetAreModsInstalled();
static native function bool NetAreInstalledDLCsRankedFriendly();
static native function bool NetGameDataHashesAreValid();
static native function bool NetAllRankedGameDataValid();
static native function int  NetGetInstalledMPFriendlyDLCHash();
static native function int  NetGetInstalledModsHash();
static native function string NetGetMPINIHash();
static native function array<string>     GetInstalledModNames();
static native function array<string>     GetInstalledDLCNames();
static native function bool IsDevConsoleEnabled();

static native function SetOnAllActorsInLevel(LevelStreaming StreamedLevel, bool bHidden, bool bCollision);

static native function SetOnAllActorsInLevelWithTag(LevelStreaming StreamedLevel, name TagToMatch, bool bHidden, bool bCollision);

static native function CollectDynamicShadowLights(LevelStreaming StreamedLevel);

static native function ToggleDynamicShadowLights(LevelStreaming StreamedLevel, bool bTurnOn);

native static final function float CalculateStatContestBinomialDistribution(float AttackerRolls, float AttackerRollSuccessChance, float DefenderRolls, float DefenderRollSuccessChance);

static native function StaticMesh ConstructRegionActor(Texture2D RegionTexture);

static native function Vector GetRegionCenterLocation(StaticMeshComponent MeshComp, bool bUseTransform);

static native function bool IsInRegion(StaticMeshComponent MeshComp, Vector Loc, bool bUseTransform);

static native function Vector GetRegionBorderIntersectionPoint(StaticMeshComponent MeshComp, Vector InnerPoint, Vector OuterPoint);

static native function GenerateCumulativeTriangleAreaArray(StaticMeshComponent MeshComp, out array<float> CumulativeTriangleArea);

static native function Vector GetRandomPointInRegionMesh(StaticMeshComponent MeshComp, int Tri, bool bUseTransform);

// Check if unit is in range (Cylindrical range - Z-diff checked within MaxZTileDist, then 2D distance check.)
static native function bool IsTileInRange(const out TTile TileA, const out TTile TileB, float MaxTileDistSq, float MaxZTileDiff=3.0f);

// Test if the Target Unit is within the required min/max ranges and angle of the source unit. If MinRange is 0, no minimum range is
// required. If MaxRange is 0, no maximum range is required. If MaxAngle is 360 or greater, then no angle check is required.
static native function bool IsUnitInRange(const ref XComGameState_Unit SourceUnit, const ref XComGameState_Unit TargetUnit,
										  float MinRange = 0.0f, float MaxRange = 0.0f, float MaxAngle = 360.0f);

static native function bool IsUnitInRangeFromLocations(const ref XComGameState_Unit SourceUnit, const ref XComGameState_Unit TargetUnit,
										  const out TTile SourceTile, const out TTile TargetTile, 
										  float MinRange = 0.0f, float MaxRange = 0.0f, float MaxAngle = 360.0f);

static function bool GetLootInternal(Lootable LootableObject, StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	local XComGameState_Item Item;
	local XComGameState_Unit Looter;
	local X2EquipmentTemplate EquipmentTemplate;
	local EInventorySlot DestinationSlot;

	Looter = XComGameState_Unit(ModifyGameState.CreateStateObject(class'XComGameState_Unit', LooterRef.ObjectID));
	ModifyGameState.AddStateObject(Looter);

	Item = XComGameState_Item(ModifyGameState.CreateStateObject(class'XComGameState_Item', ItemRef.ObjectID));
	ModifyGameState.AddStateObject(Item);

	if( Looter != none && Item != none )
	{
		DestinationSlot = eInvSlot_Backpack;
		EquipmentTemplate = X2EquipmentTemplate(Item.GetMyTemplate());
		if( EquipmentTemplate != none && EquipmentTemplate.InventorySlot == eInvSlot_Mission )
			DestinationSlot = eInvSlot_Mission;

		if( Looter.CanAddItemToInventory(Item.GetMyTemplate(), DestinationSlot, ModifyGameState) )
		{
			if( Looter.AddItemToInventory(Item, DestinationSlot, ModifyGameState) )
			{
				LootableObject.RemoveLoot(ItemRef, ModifyGameState);
				return true;
			}
		}
	}
	return false;
}


/**
* LeaveLoot
* Remove item from Looter's backpack and place in Lootable object.
*/
static function bool LeaveLootInternal(Lootable LootableObject, StateObjectReference ItemRef, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	local XComGameState_Item Item;
	local XComGameState_Unit Looter;

	Looter = XComGameState_Unit(ModifyGameState.CreateStateObject(class'XComGameState_Unit', LooterRef.ObjectID));
	ModifyGameState.AddStateObject(Looter);

	Item = XComGameState_Item(ModifyGameState.CreateStateObject(class'XComGameState_Item', ItemRef.ObjectID));
	ModifyGameState.AddStateObject(Item);

	if( Looter != none && Item != none )
	{
		if( Looter.RemoveItemFromInventory(Item, ModifyGameState) )
		{
			LootableObject.AddLoot(ItemRef, ModifyGameState);
			return true;
		}
	}
	return false;
}

static function VisualizeLootFountainInternal(Lootable LootableObject, XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local VisualizationTrack BuildTrack;
	local int ThisObjectID;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability AbilityContext;
	local XGUnit ShootingUnit, TargetUnit;
	local VisualizationTrack ShootersBuildTrack, TargetBuildTrack;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_SendInterTrackMessage InterTrackMessage;
	local XComGameState_Item WeaponUsed;
	local bool bOutOfAmmoVOWillPlay;

	Context = VisualizeGameState.GetContext();
	ThisObjectID = XComGameState_BaseObject(LootableObject).ObjectID;

	// loot fountain
	History = `XCOMHISTORY;
	History.GetCurrentAndPreviousGameStatesForObjectID(ThisObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);

	if( BuildTrack.StateObject_OldState == None || Lootable(BuildTrack.StateObject_OldState).HasLoot() )
	{
		BuildTrack.TrackActor = History.GetVisualizer(ThisObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);
		class'X2Action_LootFountain'.static.AddToVisualizationTrack(BuildTrack, Context);

		OutVisualizationTracks.AddItem(BuildTrack);
	}


	// Make the shooter speak a line of VO, e.g. "Looks like something over here."
	AbilityContext = XComGameStateContext_Ability(Context);
	if (AbilityContext != None)
	{
		// Detect if an out-of-ammo VO cue will play. The detection logic here matches the same in X2Action_EnterCover
		bOutOfAmmoVOWillPlay = false;
		if( AbilityContext.InputContext.AbilityTemplateName == 'StandardShot')
		{
			WeaponUsed = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
			if( WeaponUsed != None )
			{
				bOutOfAmmoVOWillPlay = ( WeaponUsed.Ammo <= 1 );
			}
		}


		ShootingUnit = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID).GetVisualizer());
		if (ShootingUnit != none)
		{
			// prepare the track
			History.GetCurrentAndPreviousGameStatesForObjectID(ShootingUnit.ObjectID, ShootersBuildTrack.StateObject_OldState, ShootersBuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
			ShootersBuildTrack.TrackActor = ShootingUnit;

			// play the loot VO line, only if we know it won't be stomped by an out-of-ammo line
			if (!bOutOfAmmoVOWillPlay)
			{
				SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(ShootersBuildTrack, Context));
				SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'LootSpotted', eColor_Good);
			}

			OutVisualizationTracks.AddItem(ShootersBuildTrack);
		}


		TargetUnit = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID).GetVisualizer());
		if( TargetUnit != none )
		{
			// add target visualization sentinel
			History.GetCurrentAndPreviousGameStatesForObjectID(TargetUnit.ObjectID, TargetBuildTrack.StateObject_OldState, TargetBuildTrack.StateObject_NewState, eReturnType_Reference, VisualizeGameState.HistoryIndex);
			TargetBuildTrack.TrackActor = TargetUnit;

			// trigger the Loot Drop vis
			InterTrackMessage = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(TargetBuildTrack, Context));
			InterTrackMessage.SendTrackMessageToRef.ObjectID = ThisObjectID;

			OutVisualizationTracks.AddItem(TargetBuildTrack);
		}
	}
}

/**
* AcquireAllLoot
* Award all loot held by this lootable to the player.
*/
static function AcquireAllLoot(Lootable TheLootable, StateObjectReference LooterRef, XComGameState ModifyGameState)
{
	local int LootIndex;
	local array<StateObjectReference> LootRefs;
	local bool AnyLootGotten;

	AnyLootGotten = false;
	LootRefs = TheLootable.GetAvailableLoot();

	for( LootIndex = 0; LootIndex < LootRefs.Length; ++LootIndex )
	{
		AnyLootGotten = TheLootable.GetLoot(LootRefs[LootIndex], LooterRef, ModifyGameState) || AnyLootGotten;
	}
}

static function int GetNumCiviliansKilled(optional out int iTotal, optional bool bPostMission = false)
{
	local int iKilled, i;
	local array<XComGameState_Unit> arrUnits;
	local XGBattle_SP Battle;
	local XComGameState_BattleData BattleData;

	Battle = XGBattle_SP(`BATTLE);
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if( Battle != None )
	{
		Battle.GetCivilianPlayer().GetOriginalUnits(arrUnits);

		for(i = 0; i < arrUnits.Length; i++)
		{
			if(arrUnits[i].GetMyTemplate().bIsAlien)
			{
				arrUnits.Remove(i, 1);
				i--;
			}
		}

		iTotal = arrUnits.Length;

		for( i = 0; i < iTotal; i++ )
		{
			if(arrUnits[i].IsDead())
			{
				iKilled++;
			}
			else if(bPostMission && !arrUnits[i].bRemovedFromPlay)
			{
				if(!BattleData.bLocalPlayerWon)
				{
					iKilled++;
				}
			}
		}
	}
	return iKilled;
}

static function int GetRemainingXComActionPoints(bool CheckSkipped, optional out array<StateObjectReference> UnitsWithActionPoints)
{
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local int TotalPoints, Points;
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState, , , )
	{
		if( UnitState.GetTeam() == eTeam_XCom 
		   && UnitState.IsAbleToAct() 
		   && !UnitState.bRemovedFromPlay
		   && !UnitState.GetMyTemplate().bIsCosmetic )
		{
			if( CheckSkipped )
			{
				Points = UnitState.SkippedActionPoints.Length;
			}
			else
			{
				Points = UnitState.ActionPoints.Length;
			}

			if( Points > 0 )
			{
				TotalPoints += Points;
				`LogAI("Adding Action Points from unit"@UnitState.ObjectID@":"@Points);
				UnitsWithActionPoints.AddItem(UnitState.GetReference());
			}
		}
	}
	return TotalPoints;
}

// Validate tile to fit in the map and avoid NoSpawn locations.
static function TTile GetClosestValidTile(TTile Tile)
{
	local XComWorldData World;
	local vector ValidLocation;
	World = `XWORLD;
	ValidLocation = World.GetPositionFromTileCoordinates(Tile);
	ValidLocation = World.FindClosestValidLocation(ValidLocation, false, false, true);
	return World.GetTileCoordinatesFromPosition(ValidLocation);
}

static function bool GetFurthestReachableTileOnPathToDestination(out TTile BestTile_out, TTile DestinationTile, XComGameState_Unit UnitState, bool bAllowDash=true)
{
	local bool bHasPath;
	local XComWorldData World;
	local vector EndPos;
	local XGUnit UnitVisualizer;
	local array<TTile> PathTiles;

	UnitVisualizer = XGUnit(UnitState.GetVisualizer());
	// First check the reachable tile cache to see if any tiles are reachable.
	PathTiles.Length = 0;
	if( UnitVisualizer.m_kReachableTilesCache.BuildPathToTile(DestinationTile, PathTiles) )
	{
		if( PathTiles.Length > 0 )
		{
			bHasPath = true;
		}
	}

	if( !bHasPath )
	{
		World = `XWORLD;
		EndPos = World.GetPositionFromTileCoordinates(DestinationTile);
		if( World.IsPositionOnFloorAndValidDestination(EndPos, UnitState) )
		{
			if( class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, DestinationTile, PathTiles, false) )
			{
				// Found a valid path. 
				bHasPath = true;
			}
		}
	}

	if( bHasPath )
	{
		if( GetFurthestReachableTileOnPath(BestTile_out, PathTiles, UnitState, bAllowDash) )
		{
			return true;
		}
	}
	// No valid paths found to target area (or no alert data found).
	return false;
}

static function bool GetFurthestReachableTileOnPath(out TTile FurthestReachable, array<TTile> Path, XComGameState_Unit UnitState, bool bAllowDash=true)
{
	local XGUnit UnitVisualizer;
	local int TileIndex;
	local TTile PathTile, FloorTile;
	local XComWorldData World;
	local float MaxRange;

	World = `XWORLD;
	UnitVisualizer = XGUnit(UnitState.GetVisualizer());
	if( !bAllowDash )
	{
		MaxRange = UnitState.GetCurrentStat(eStat_Mobility);
	}
	if( UnitVisualizer != None )
	{
		for( TileIndex = Path.Length - 1; TileIndex > 0; --TileIndex )
		{
			PathTile = Path[TileIndex];
			if( UnitVisualizer.m_kReachableTilesCache.IsTileReachable(PathTile) && (bAllowDash || UnitVisualizer.m_kReachableTilesCache.GetPathCostToTile(PathTile) <= MaxRange) )
			{
				FurthestReachable = PathTile;
				return true;
			}
			else
			{
				// Try floor tile.  Fixes failures with pathing from different elevations returning mid-air points that aren't in the tile cache.
				FloorTile = PathTile;
				FloorTile.Z = World.GetFloorTileZ(PathTile);
				if( FloorTile.Z != PathTile.Z && 
				   (UnitVisualizer.m_kReachableTilesCache.IsTileReachable(FloorTile) 
				    && (bAllowDash || UnitVisualizer.m_kReachableTilesCache.GetPathCostToTile(PathTile) <= MaxRange) ))
				{
					FurthestReachable = FloorTile;
					return true;
				}
			}
		}
	}
	return false;
}

static native function int FindTileInList(TTile Tile, const out array<TTile> List);
static native function RemoveTileSubset(out array<TTile> ResultList, const out array<TTile> Superset, const out array<TTile> Subset);
static native function bool VectorContainsNaNOrInfinite(Vector V);

cpptext
{
	static class AXComGameInfo* GetXComGameInfo();
	static class AX2GameRuleset* GetX2GameRuleset();
	static class AX2TacticalGameRuleset* GetX2GameTacticalRuleset();
	static class UXComGameStateHistory* GetHistory();
	static class AXComPlotCoverParcel* GetClosestPCPToLocation( const FVector& InLocation );
	static UBOOL TargetInRange(
		const FVector& SourceLocation,
		const FVector& TargetLocation,
		const FVector* SourceFacing=NULL,
		FLOAT MaxRange=0.f,
		FLOAT MaxAngle=360.f);
	static UBOOL IsTileInRangeNative(const FTTile& TileA, const FTTile& TileB, FLOAT MaxTileDistSq, FLOAT MaxTileZDist=3.0f);

	// Test if the Target Unit is within the required min/max ranges and angle of the source unit. If MinRange is 0, no minimum range is
	// required. If MaxRange is 0, no maximum range is required. If MaxAngle is 360 or greater, then no angle check is required.
	static UBOOL IsUnitInRangeNative(const class UXComGameState_Unit& SourceUnit, const class UXComGameState_Unit& TargetUnit,
									 FLOAT MinRange = 0.0f, FLOAT MaxRange = 0.0f, FLOAT MaxAngle = 360.0f);
	static UBOOL IsUnitInRangeFromLocationsNative(const class UXComGameState_Unit& SourceUnit, const class UXComGameState_Unit& TargetUnit,
									 const FTTile& SourceTile, const FTTile& TargetTile,
									 FLOAT MinRange = 0.0f, FLOAT MaxRange = 0.0f, FLOAT MaxAngle = 360.0f);
};

defaultproperties
{
}
