//---------------------------------------------------------------------------------------
//  FILE:    X2VisualizedInterface.uc
//  AUTHOR:  David Burchanowski  --  4/2/2015
//  PURPOSE: Implemented by visualized game state objects, this provides a common mechanism for the system
//           to interact with them. For example, syncing/creating their visualizers
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
interface X2VisualizedInterface native(Core);

// When called, the visualized object must create it's visualizer if needed, 
function Actor FindOrCreateVisualizer(optional XComGameState Gamestate = none);

// Ensure that the visualizer visual state is an accurate reflection of the state of this object.
function SyncVisualizer(optional XComGameState GameState = none);

function AppendAdditionalSyncActions( out VisualizationTrack BuildTrack );
