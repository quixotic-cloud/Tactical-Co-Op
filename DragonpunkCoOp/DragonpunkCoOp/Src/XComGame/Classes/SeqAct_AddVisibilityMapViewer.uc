class SeqAct_AddVisibilityMapViewer extends SequenceAction
	implements(X2KismetSeqOpVisualizer);

/** Location to View */
var private Vector ViewerLocation;

/** Radius of viewer */
var() private float ViewerRadiusInTiles;

/** Additional z offset to apply to the viewer's location, in tiles */
var() private float ViewerVerticalOffset;

/** If false, this viewer will provide no visibility of gamestate objects */
var() private bool RevealUnits; 

function ModifyKismetGameState(out XComGameState GameState)
{
	local XComGameStateHistory History;
	local XComGameState_SquadViewer SquadViewer;
	local XComGameState_Player PlayerState;
	local XComWorldData WorldData;
	local Vector EffectiveViewerLocation;
	local TTile TileLocation;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;
	EffectiveViewerLocation = ViewerLocation;
	ViewerLocation.Z += ViewerVerticalOffset;
	TileLocation = WorldData.GetTileCoordinatesFromPosition(EffectiveViewerLocation);

	if(InputLinks[0].bHasImpulse) // add a viewer
	{
		SquadViewer = XComGameState_SquadViewer(GameState.CreateStateObject(class'XComGameState_SquadViewer'));
		SquadViewer.ViewerTile = TileLocation;
		SquadViewer.ViewerRadius = ViewerRadiusInTiles;
		SquadViewer.RevealUnits = RevealUnits;

		// autoset the viewer to always be for the local (human) team. If this ever needs to be used
		// for aliens or multiplayer, make the modification here
		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if(PlayerState.IsLocalPlayer())
			{
				SquadViewer.AssociatedPlayer = PlayerState.GetReference();
				break;
			}
		}

		GameState.AddStateObject(SquadViewer);
	}
	else // remove a viewer
	{
		foreach History.IterateByClassType(class'XComGameState_SquadViewer', SquadViewer)
		{
			if(SquadViewer.ViewerTile == TileLocation)
			{
				GameState.RemoveStateObject(SquadViewer.ObjectID);
				break;
			}
		}
	}
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComWorldData WorldData;
	local XComGameState_SquadViewer SquadViewer;
	local Actor Visualizer;

	foreach GameState.IterateByClassType(class'XComGameState_SquadViewer', SquadViewer)
	{
		if(SquadViewer.bRemoved)
		{
			WorldData = `XWORLD;
			Visualizer = SquadViewer.GetVisualizer();
			WorldData.UnregisterActor(Visualizer);
			`XCOMHISTORY.SetVisualizer(SquadViewer.ObjectID, none); //Let the history know that we are destroying this visualizer
			Visualizer.Destroy();			
		}
		else
		{
			SquadViewer.FindOrCreateVisualizer();
		}
	}
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 3;
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Squad Viewer"
	bCallHandler=false	

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	RevealUnits=true

	InputLinks(0)=(LinkDesc="Add")
	InputLinks(1)=(LinkDesc="Remove")

	VariableLinks(0)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Location",PropertyName=ViewerLocation)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Float',LinkDesc="Radius (Tiles)",PropertyName=ViewerRadiusInTiles)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Float',LinkDesc="Vertical Offset (Tiles)",PropertyName=ViewerVerticalOffset)

	ViewerRadiusInTiles=6 // Doubled, per Jake
}
