//---------------------------------------------------------------------------------------
//  FILE:    X2VisualizerInterface.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: Implemented by visualizer class objects, this provides mechanisms for them
//           to react to events within the system and provide class specific behaviors 
//           with respect to effects, time dilation, etc.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
interface X2VisualizerInterface native(Core);

/// <summary>
/// Called on a visualizer when it is added to an active or pending visualizer track
/// </summary>
event OnAddedToVisualizerTrack();

/// <summary>
/// Called on a visualizer when a visualizer block it is a part of is added to the list of 'finished' visualizer blocks
/// </summary>
event OnRemovedFromVisualizerTrack();

/// <summary>
/// Called on a visualizer when a visualizer block it is a part of is added to the list of 'active' visualizer blocks
/// </summary>
event OnVisualizationBlockStarted(const out VisualizationBlock StartedBlock);

/// <summary>
/// Modulates the delta time of this visualizer - putting it into slow mo or speeding it up.
/// </summary>
event SetTimeDilation(float TimeDilation, optional bool bComingFromDeath=false);

/// <summary>
/// Returns a vector representing a location to shoot at on this visualizer. HitResult allows the implementor to 
/// treat different projectile impact results differently.
/// </summary>
event vector GetShootAtLocation(EAbilityHitResult HitResult, StateObjectReference Shooter);

/// <summary>
/// Returns the location that we should focus while targeting a unit. Since we don't yet know what the hit result
/// will be, this will be more general than GetShootAtLocation()
/// </summary>
event vector GetTargetingFocusLocation();

/// <summary>
/// Returns the location that we should anchor the unit flag to
/// </summary>
event vector GetUnitFlagLocation();

/// <summary>
/// Returns a UI path for the HUD targetable icon of this object.
/// </summary>
function string GetMyHUDIcon();

/// <summary>
/// Returns a UI color for the HUD targetable icon of this object.
/// </summary>
function EUIState GetMyHUDIconColor();

/// <summary>
/// Returns reference to the game state object this visualizer is visualizing. For example,
/// if this is a unit, would return an XComGameState_Unit reference.
/// </summary>
event StateObjectReference GetVisualizedStateReference();

/// <summary>
/// Triggers the verification process for this observer
/// </summary>
event VerifyTrackSyncronization();

/// <summary>
/// Each visualizer class is responsible for creating the appropriate visualizer actions for itself when ability affects are applied to it. The main
/// class of ability affects are damage types, which result in death/destruction or some reaction to a hit. The visualizer for a unit would play a 
/// get hit anim, while the visualizer for a destructible actor might transition to the actor to a new 'damaged' state.
/// </summary>
function BuildAbilityEffectsVisualization(XComGameState VisualizeGameState, out VisualizationTrack InTrack);

function int GetNumVisualizerTracks();