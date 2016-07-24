class XComGameState_SquadViewer extends XComGameState_BaseObject
	native(Core)
	implements(X2GameRulesetVisibilityInterface, X2VisualizedInterface);

var TTile ViewerTile;
var float ViewerRadius;
var StateObjectReference AssociatedPlayer;
var bool RevealUnits;

event float GetVisibilityRadius()
{
	return ViewerRadius;
}

event UpdateGameplayVisibility(out GameRulesCache_VisibilityInfo InOutVisibilityInfo)
{
	InOutVisibilityInfo.bVisibleGameplay = InOutVisibilityInfo.bVisibleBasic;
}

event bool TargetIsEnemy(int TargetObjectID, int HistoryIndex = -1)
{
	local XComGameState_Unit TargetState;

	TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetObjectID, , HistoryIndex));
	if( TargetState != none )
	{
		return TargetState.ControllingPlayer != AssociatedPlayer;
	}

	return false;
}

event bool TargetIsAlly(int TargetObjectID, int HistoryIndex = -1)
{
	local XComGameState_Unit TargetState;

	TargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetObjectID, , HistoryIndex));
	if( TargetState != none )
	{
		return TargetState.ControllingPlayer == AssociatedPlayer;
	}

	return false;
}

event bool ShouldTreatLowCoverAsHighCover( )
{
	return false;
}

event int GetAssociatedPlayerID()
{
	return AssociatedPlayer.ObjectID;
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
	HalfTileExtents.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;

	VisibilityExtents.Min = `XWORLD.GetPositionFromTileCoordinates( ViewerTile ) - HalfTileExtents;
	VisibilityExtents.Max = `XWORLD.GetPositionFromTileCoordinates( ViewerTile ) + HalfTileExtents;
	VisibilityExtents.IsValid = 1;
}

event SetVisibilityLocation(const out TTile VisibilityLocation)
{
	ViewerTile = VisibilityLocation;
}

event EForceVisibilitySetting ForceModelVisible()
{
	return eForceNone;
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local DynamicPointInSpace Visualizer;
	local Vector Position;

	Visualizer = DynamicPointInSpace(`XCOMHISTORY.GetVisualizer(ObjectID));
	if(Visualizer == none)
	{
		WorldData = `XWORLD;
		Position = WorldData.GetPositionFromTileCoordinates(ViewerTile);
		Visualizer = DynamicPointInSpace(WorldData.CreateFOWViewer(Position, ViewerRadius * class'XComWorldData'.const.WORLD_StepSize));

		//We don't make this actor a visualizer since that is not its role. This actor is responsible for communicating with the world data FOW system
		Visualizer.SetObjectID(ObjectID); //Associate this actor with this game state object

		History = `XCOMHISTORY;
		History.SetVisualizer(ObjectID, Visualizer);
	}

	return Visualizer;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
}

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack )
{
}

function DestroyVisualizer()
{
	local DynamicPointInSpace Visualizer;

	Visualizer = DynamicPointInSpace(`XCOMHISTORY.GetVisualizer(ObjectID));
	if (Visualizer != none)
	{
		`XWORLD.DestroyFOWViewer(Visualizer);
	}
}

cpptext
{
	// True if this object requires visibility updates as a Source object (ie. this object can see other objects)
	virtual UBOOL CanEverSee() const
	{
		return RevealUnits;
	}

	// True if this object can be included in another viewer's visibility updates (ie. this object can be seen by other objects)
	virtual UBOOL CanEverBeSeen() const
	{
		return FALSE;
	}
};

defaultproperties
{
	RevealUnits=true
}