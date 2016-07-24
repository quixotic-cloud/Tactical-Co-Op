//---------------------------------------------------------------------------------------
//  FILE:    X2GameRulesetEventObserverInterface.uc
//  AUTHOR:  Ryan McFall  --  1/15/2013
//  PURPOSE: Implemented by observer objects that would implement game state effects in 
//           response to specific changes in game state. For example, abilities that 
//           fire in response to the death of a unit.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
interface X2GameRulesetEventObserverInterface;

/// <summary>
/// Called immediately prior to the creation of a new game state via SubmitGameStateContext. New game states can be submitted
/// prior to a game state being created with this context
/// </summary>
/// <param name="NewGameState">The state to examine</param>
event PreBuildGameStateFromContext(XComGameStateContext NewGameStateContext);

/// <summary>
/// This event is issued from within the context method ContextBuildGameState
/// </summary>
/// <param name="NewGameState">The state to examine</param>
event InterruptGameState(XComGameState NewGameState);

/// <summary>
/// Called immediately after the creation of a new game state via SubmitGameStateContext. 
/// Note that at this point, the state has already been committed to the history
/// </summary>
/// <param name="NewGameState">The state to examine</param>
event PostBuildGameState(XComGameState NewGameState);

/// <summary>
/// Allows the observer class to set up any internal state it needs to when it is created
/// </summary>
event Initialize();

/// <summary>
/// Event observers may use this to cache information about the state objects they need to operate on
/// </summary>
event CacheGameStateInformation();