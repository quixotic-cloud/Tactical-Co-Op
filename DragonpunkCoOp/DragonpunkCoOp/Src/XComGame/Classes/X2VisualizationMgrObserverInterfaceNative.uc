//---------------------------------------------------------------------------------------
//  FILE:    X2VisualizationMgrObserverInterfaceNative.uc
//  AUTHOR:  Ryan McFall  --  1/24/2013
//  PURPOSE: Native variant of X2VisualizationMgrObserverInterface
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
interface X2VisualizationMgrObserverInterfaceNative native(Core);

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