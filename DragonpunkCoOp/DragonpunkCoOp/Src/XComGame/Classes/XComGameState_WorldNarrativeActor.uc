//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_WorldNarrativeActor.uc
//  AUTHOR:  David Burchanowski  --  6/2/2015
//  PURPOSE: Provides the gameplay state object for LD placed X2WorldNarrativeActors
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameState_WorldNarrativeActor extends XComGameState_BaseObject
	implements(X2GameRulesetVisibilityInterface, X2VisualizedInterface)
	native(Core);

// unique identifier for the actor in the map that we represent
var ActorIdentifier ActorId;

// cached tile location of the visualizer so we don't need to keep calculating it from the position
var privatewrite TTile TileLocation;

// a reference to the unit that saw this WorldNarrativeActor.  For use with a "SoldierVO" type XComNarrativeMoment
var StateObjectReference UnitThatSawMeRef;


function SetInitialState(X2WorldNarrativeActor InVisualizer)
{
	local XComWorldData WorldData;

	WorldData = `XWORLD;

	ActorId = InVisualizer.GetActorId();
	TileLocation = WorldData.GetTileCoordinatesFromPosition( InVisualizer.Location );
	bRequiresVisibilityUpdate = true;
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local Actor Visualizer;

	Visualizer = GetVisualizer( );
	if (Visualizer == none)
	{
		// find our actor in the map and link to it
		if (class'Actor'.static.FindActorByIdentifier( ActorId, Visualizer ))
		{
			`XCOMHISTORY.SetVisualizer( ObjectID, Visualizer );
		}
	}

	return Visualizer;
}

// Return the range pct at which this should be considered seen
function float GetSightRangePct()
{
	local X2WorldNarrativeActor WorldNarrativeVis;

	WorldNarrativeVis = X2WorldNarrativeActor(FindOrCreateVisualizer());

	return WorldNarrativeVis.SightRangeToPct();
}

function SyncVisualizer(optional XComGameState GameState = none)
{
}

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack )
{
}

event float GetVisibilityRadius();
event UpdateGameplayVisibility(out GameRulesCache_VisibilityInfo InOutVisibilityInfo);
event SetVisibilityLocation(const out TTile VisibilityLocation);
event EForceVisibilitySetting ForceModelVisible();
event bool ShouldTreatLowCoverAsHighCover();

event bool TargetIsEnemy(int TargetObjectID, int HistoryIndex = -1)
{
	return false;
}

event bool TargetIsAlly(int TargetObjectID, int HistoryIndex = -1)
{
	return false;
}

event int GetAssociatedPlayerID()
{
	return -1;
}

native function NativeGetVisibilityLocation(out array<TTile> VisibilityTiles) const;
native function NativeGetKeystoneVisibilityLocation(out TTile VisibilityTile) const;

function GetVisibilityLocation(out array<TTile> VisibilityTiles)
{
	NativeGetVisibilityLocation(VisibilityTiles);
}

function GetKeystoneVisibilityLocation(out TTile VisibilityTile)
{
	NativeGetKeystoneVisibilityLocation(VisibilityTile);
}

event GetVisibilityExtents(out Box VisibilityExtents)
{
	local Vector HalfTileExtents;
	
	HalfTileExtents.X = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Y = class'XComWorldData'.const.WORLD_HalfStepSize;
	HalfTileExtents.Z = class'XComWorldData'.const.WORLD_HalfStepSize;

	VisibilityExtents.Min = `XWORLD.GetPositionFromTileCoordinates(TileLocation ) - HalfTileExtents;
	VisibilityExtents.Max = `XWORLD.GetPositionFromTileCoordinates(TileLocation) + HalfTileExtents;
	VisibilityExtents.IsValid = 1;
}

cpptext
{
	// True if this object can be included in another viewer's visibility updates (ie. this object can be seen by other objects)
	virtual UBOOL CanEverBeSeen() const
	{
		return TRUE;
	}
};