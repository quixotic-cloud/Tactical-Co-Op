//---------------------------------------------------------------------------------------
//  FILE:    X2SeqVisualizer.uc
//  AUTHOR:  David Burchanowski  --  1/15/2014
//
//  Purpose: Interface to be implemented by SequenceOps that need to be visualized.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

// Implement this interface on SequenceOps that must build
// visualization tracks
interface X2KismetSeqOpVisualizer 
	dependson (XComGameStateVisualizationMgr);

/// <summary>
/// Builds the visualization for a seqop
/// </summary>
function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks);

/// <summary>
/// Allows a sequence op to add game state objects to the game state so that the visualizer will wait to
/// visualize this operation until all dependent object tracks have completed.
/// Example: You want to look at a unit, but only after it is finished doing what it was doing before.
///          Add a blank state object for the unit here.
/// </summary>
function ModifyKismetGameState(out XComGameState GameState);