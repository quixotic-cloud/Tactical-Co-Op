//---------------------------------------------------------------------------------------
//  FILE:    X2VisualizationMgrObserverInterface.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: Implement this interface on objects that should listen for events triggered
//           from the XComGameStateVisualizationMgr. Example: The HUD may listen for
//           the OnVisualizationBlockComplete message to sync / verify that HUD
//           elements reflect the the game state.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
interface X2VisualizationMgrObserverInterface;

/// <summary>
/// Called when an active visualization block is marked complete 
/// </summary>
event OnVisualizationBlockComplete(XComGameState AssociatedGameState);

/// <summary>
/// Called when the visualizer runs out of active and pending blocks, and becomes idle
/// </summary>
event OnVisualizationIdle();

/// <summary>
/// Called when the active unit selection changes
/// </summary>
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);