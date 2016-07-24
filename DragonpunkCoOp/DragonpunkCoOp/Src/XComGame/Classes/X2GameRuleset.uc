//---------------------------------------------------------------------------------------
//  FILE:    X2GameRuleset.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: The rule set is the interface between the game state and the systems that want
//			 to change it. These systems include: player UI, AI, cheat manager, kismet,
//			 and multi-player. The rule set is responsible for enforcing game rules like
//			 interrupts and processing game state based events.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2GameRuleset extends Actor
	dependson(XGTacticalGameCore, XComGameState, XComGameState_BaseObject)
	native(Core);

cpptext
{
	/* Latent Function Declarations */
	DECLARE_FUNCTION(execPollLatentWaitingForPlayerSync);
}

struct native AvailableTarget
{
	var StateObjectReference PrimaryTarget;             //  unit the user should be targeting via UI.
	var array<StateObjectReference> AdditionalTargets;  //  units that will be affected by the ability but are not directly targeted.
														//  all targets live here for free aim abilities.
	structcpptext
	{
		FAvailableTarget() 
		{
			appMemzero(this, sizeof(FAvailableTarget));
		}

		FAvailableTarget(EEventParm)
		{
			appMemzero(this, sizeof(FAvailableTarget));
		}
	}
};

struct native AvailableAction
{
	var StateObjectReference AbilityObjectRef;
	var array<AvailableTarget> AvailableTargets;
	var int AvailableTargetCurrIndex;				//  points to which of the target we are targeting at right now.
	var bool bFreeAim;                          //  if this is true, targets will change based on cursor location.
	var name AvailableCode;     //  if this is anything except 'AA_Success', the ability can't be used.
	var EAbilityIconBehavior eAbilityIconBehaviorHUD;   //  store off whether this ability should be shown in the HUD.
	var bool bInputTriggered;                   //  true if this ability is 'active' IE - it is triggered by player input.
	var int ShotHUDPriority;                    // this number is used to sort the icon position in the Ability Container in Tactical HUD.

	structcpptext
	{
		FAvailableAction() 
		{
			appMemzero(this, sizeof(FAvailableAction));
		}

		FAvailableAction(EEventParm)
		{
			appMemzero(this, sizeof(FAvailableAction));
		}
	}
};

struct native GameRulesCache_Unit
{
	var StateObjectReference UnitObjectRef;
	var array<AvailableAction> AvailableActions;
	var bool bAnyActionsAvailable;
	var int LastUpdateHistoryIndex; // keep track of the last history index this cache was updated so we can update the cache only as needed

	structcpptext
	{
		FGameRulesCache_Unit() 
		{
			appMemzero(this, sizeof(FGameRulesCache_Unit));
		}

		FGameRulesCache_Unit(EEventParm)
		{
			appMemzero(this, sizeof(FGameRulesCache_Unit));
		}
	}
};



//******** Event Observers
var protected array<class> EventObserverClasses; //Add to this array in default properties of the concrete ruleset class to add observers
var protected array<X2GameRulesetEventObserverInterface> EventObservers; //The list of instantiated event observer. One per entry in EventObserverClasses

//******** Cached systems variables
var XComGameStateHistory CachedHistory; //Cache to the singleton XComGameStateHistory, manages game state
var XComGameStateVisualizationMgr VisualizationMgr; //`XCOMVISUALIZATIONMGR - processes history frames to show the player game state changes
var XComGameStateNetworkManager NetworkMgr; //Cached reference to the network manager to support MP
var X2GameRulesetVisibilityManager VisibilityMgr; //Cached reference to the visibility manager, manages visibility relationships between game state objects

//******** Local rules processing variables
var private int ContextBuildDepth; //Keep track of how far we've recursed into building game states
var protected bool bWaitingForNewStates; //This flag is set to true when the rules engine is waiting for a decision on what action will be taken next
var protectedwrite bool bProcessingLoad; //This flag is used to determine whether the game rules are processing a load, and thus should not admit changes to the game state
var protected int CurrentSyncPoint; // Current location where the ruleset is waiting for a network sync; this is automatically updated per LatentWaitingForPlayerSync call.

/// <summary>
/// Returns a state object reference to the battle data
/// </summary>
simulated function StateObjectReference GetCachedBattleDataRef();

/// <summary>
/// Entry point for the rules engine if the map URL indicates this IS NOT a loaded save game
/// </summary>
simulated function StartNewGame();

/// <summary>
/// Entry point for the rules engine if the map URL indicates this IS a loaded save game
/// </summary>
simulated function LoadGame();

/// <summary>
/// This method builds a local list of state object references for objects that are relatively static, and that we 
/// may need to access frequently. Using the cached ObjectID from a game state object reference is much faster than
/// searching for it each time we need to use it.
/// </summary>
simulated function BuildLocalStateObjectCache()
{		
	local int Index;
	local X2GameRulesetEventObserverInterface EventObserver;

	CachedHistory = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	NetworkMgr = `XCOMNETMANAGER;

	for(Index = 0; Index < EventObserverClasses.Length; ++Index)
	{
		EventObserver = new(self)EventObserverClasses[Index];
		EventObserver.Initialize();
		EventObservers.AddItem(EventObserver);
	}
}

/// <summary>
/// The SubmitGameStateXXX methods are the interface by which the UI, AI, and MP subsystems push new game states
/// into the history. SubmitGameStateContext is used by AI and UI to indicate what action they intend to perform
/// when they are allowed input. 
///
/// In some cases the resulting history frames will match exactly what the incoming context is requesting. However
/// actions can be interrupted which may result in a sequence of unintended state changes ( such as a unit being
/// killed while moving ). The rules engine is responsible for converting the state change context into a
/// series of new history states/frames.
/// Return true of successful, false otherwise
/// </summary>
simulated function bool SubmitGameStateContext(XComGameStateContext Context, bool bAISpawningCode = false)
{
	local int Index, InterruptStep, LastInterruptedStep;
	local XComGameState SubmittedGameState;
	local bool bCanAdd, bStateInterrupted;

	//Used for interruption processing
	local XComGameState InterruptedGameState;
	local XComGameState LastInterruptedGameState;
	local XComGameStateContext InterruptedContext;

	local bool bWasWaitingForNewStates;

	bCanAdd = AddNewStatesAllowed();
	if(bCanAdd)
	{
		if(ContextBuildDepth == 0)
		{			
			bWasWaitingForNewStates = bWaitingForNewStates;
			bWaitingForNewStates = false;
			CachedHistory.BeginEventChain();
		}

		if(Context.bNetworkAdded)
		{
			// Use the exiting random seed from the given context
			Context.SetEngineRandSeedFromContext();
		}
		else
		{
			// Any further replay will need the original context's starting rand seed, so store the engine's seed into this context.
			Context.SetContextRandSeedFromEngine();

			//Send off any contexts that are generated via "user-input"
			if(NetworkMgr != none && NetworkMgr.HasConnections())
			{
				if(Context.bSendGameState)
				{
					Context.SetSendGameState(false);
					NetworkMgr.QueueContextForSending(Context, CachedHistory.GetCurrentHistoryIndex());
				}
				else
				{
					`log(`location @ "Did not Queue Context for Sending!! " @ Context.SummaryString() @ `ShowVar(GetStateName(), State) @ `ShowVar(bWasWaitingForNewStates) @ `ShowVar(bWaitingForNewStates) @ `ShowVar(ContextBuildDepth));
					ScriptTrace();
				}
			}
		}

		//Anything that should only be run ONCE per external call to SubmitGameStateContext should go in here.
		if(ContextBuildDepth == 0)
		{
			for(Index = 0; Index < EventObservers.Length; ++Index)
			{
				EventObservers[Index].CacheGameStateInformation();
			}
		}

		//@TODO - rmcfall - find a home for these ( other turn phases? )
		/*
		1. Turn starts 	a. Ex Rapid Regen
		2. Turn ends 	a. Ex EXALT’s Regen Pheromones
		3. Mission start 	a. Ex (maybe): MEC Heavy’s Body Shield, if mission starts with enemies visible
		4. End of mission 	a. XP bonuses from abilities (like medals)
		*/
		ContextBuildDepth++;

		//Process any preemptive events
		/*
		* Ex:
		* 1. A unit state variable needs to change when an ability context has been submitted ala. ReflexObserver
		*/
		for(Index = 0; Index < EventObservers.Length && Context != none; ++Index)
		{
			EventObservers[Index].PreBuildGameStateFromContext(Context);
		}

		// TODO: consider adding pre state change hook here
		//EventManager.TriggerPreStateChangeDeferredEvents();

		//Process any interrupt events
		/*
		*  Ex:
		*  1. Unit enters tile / uses ability that causes another ability to fire (Overwatch) (Close Combat Specialist)
		*  3. Unit sighted (AI Alert)
		*/
		bStateInterrupted = false;
		InterruptStep = 0;
		LastInterruptedGameState = None;
		do
		{
			InterruptedGameState = Context.ContextBuildInterruptedGameState(InterruptStep, eInterruptionStatus_Interrupt);
			if(InterruptedGameState != none)
			{
				if(LastInterruptedGameState != None)
				{
					//Set internal state of the contexts for the interrupted and resumed game states, linking them.
					class'XComGameStateContext'.static.InterruptionPostProcess(LastInterruptedGameState, InterruptedGameState);
				}

				InterruptedContext = InterruptedGameState.GetContext();

				//tentatively add the interrupted state to the history. We'll remove it again if
				//no interruption observers add new game states in response
				SubmitGameStateInternal(InterruptedGameState, true, bWasWaitingForNewStates);

				//if no observers submitted a game state context, then roll back the tentative interruption
				//state. It is unneeded
				if(InterruptedContext.AssociatedState != none &&
				   InterruptedContext.AssociatedState.HistoryIndex == CachedHistory.GetCurrentHistoryIndex())
				{
					CachedHistory.ObliterateGameStatesFromHistory(1);

					// since we just obliterated the resume context, make sure to clear out the index in the last interrupted state.
					// This was set in InterruptionPostProcess
					if(LastInterruptedGameState != none)
					{
						LastInterruptedGameState.GetContext().SetInterruptionIndex(true, -1);
					}
				}
				else
				{
					bStateInterrupted = true;

					LastInterruptedGameState = InterruptedGameState;
					LastInterruptedStep = InterruptStep;
					Context = InterruptedContext;
				}
			}

			++InterruptStep;

		} until(InterruptedGameState == none);

		// if there was no interruption, submit using a normally built game state
		if(!bStateInterrupted)
		{
			//Get the game state output from the passed-in context
			SubmittedGameState = Context.ContextBuildGameState();
		}
		else
		{
			SubmittedGameState = Context.ContextBuildInterruptedGameState(LastInterruptedStep, eInterruptionStatus_Resume);

			//Set internal state of the contexts for the interrupted and resumed game states, linking them.
			class'XComGameStateContext'.static.InterruptionPostProcess(LastInterruptedGameState, SubmittedGameState);
		}

		//If SubmittedGameState was uninterrupted, or resumed - add it to the history here
		//SubmittedGameState can be none if conditions in the interrupt loop above cause it to fail, or if the context
		//itself determines that there should not be one ( ie. a roll failed for an ability and there were no side-effects )
		if(SubmittedGameState != none)
		{
			SubmitGameStateInternal(SubmittedGameState, false, bWasWaitingForNewStates);
		}

		ContextBuildDepth--;

		if (ContextBuildDepth == 0)
		{
			CachedHistory.EndEventChain();
		}
	}
	else if (`REPLAY.bInTutorial)
	{
		return `TUTORIAL.HandleSubmittedGameStateContext(Context);	
	}

	assert(ContextBuildDepth >= 0);

	return true;
}

simulated event SubmitGameStateContextNative(XComGameStateContext StateChangeContext, bool bAISpawningCode=false)
{
	SubmitGameStateContext( StateChangeContext, bAISpawningCode );
}

simulated event SubmitChallengeGameStateContextNative(XComGameStateContext StateChangeContext)
{
	StateChangeContext.SetEngineRandSeedFromContext();
	SubmitGameStateContextNative(StateChangeContext);
}

/// <summary>
/// Internal helper method that helps encapsulate the logic that has to happen each time a game state is submitted
/// </summary>
simulated function SubmitGameStateInternal(XComGameState NewGameState, bool bInterrupt = false, bool bSendGameState = false)
{
	local int Index;
	local X2EventManager EventManager;

	EventManager = `XEVENTMGR;

	++ContextBuildDepth;

	// cause any queued up events waiting for the PreStateChange deferral to execute
	EventManager.PreGameStateSubmitted(NewGameState);

	// commit the state change
	CachedHistory.AddGameStateToHistory(NewGameState);

	if(bInterrupt)
	{
		// let state change listeners respond to the post state change event
		for(Index = 0; Index < EventObservers.Length; ++Index)
		{
			EventObservers[Index].InterruptGameState(NewGameState);
		}
	}
	else
	{
		// let state change listeners respond to the post state change event
		for(Index = 0; Index < EventObservers.Length; ++Index)
		{
			EventObservers[Index].PostBuildGameState(NewGameState);
		}
	}

	//Process any result events	
	/*
	* Ex:
	* 1. Unit takes damage/gets healed 	a. Ex: Psi reflect, Damage Control
	* 2. Unit changes status 	a. ex: unit is concealed and enemy successfully spots, but unit has ability to mitigate the effects of being spotted
	* 3. Unit dies a. Ex: Secondary Heart
	* 4. Unit scores a kill 	a. Ex: the Ranger ability that resets Melee Charge’s cooldown
	* 5. Civilian interacted with 	a. Ex: an ability that gives bonus Supplies every time a civilian is rescued
	* 6. Hackable object hacked 	a. Ex: reinforcement timers extended because of a hack
	* 7. Unit “bursts” 	a. Burst is the replacement stat for crit
	* 8. Get loot from box or body
	*/

	// cause any queued up events waiting for the PostStateChange deferral to execute
	EventManager.OnGameStateSubmitted(NewGameState);

	--ContextBuildDepth;
}

/// <summary>
/// The SubmitGameStateXXX methods are the interface by which the UI, AI, and MP subsystems push new game states
/// into the history. SubmitGameStates is used by MP and DEBUG to directly add new game states to the history
///
/// The rules engine is responsible for validating and vetting the incoming game states. Additionally, some turn 
/// phases / rules engine state may prohibit the addition of new states this way while they are running. In this 
/// situation the calling system is responsible for handling this condition and trying again when it is permitted.
/// </summary>
simulated function bool SubmitGameStates(array<XComGameState> NewStates)
{
	local XComGameState NewState;
	local bool bCanAdd;
	local bool bValid;
	local bool bWasWaitingForNewStates;

	bCanAdd = AddNewStatesAllowed();
	if(bCanAdd)
	{
		if(ContextBuildDepth == 0)
		{
			bWasWaitingForNewStates = bWaitingForNewStates;
			bWaitingForNewStates = false;
			CachedHistory.BeginEventChain();
		}
		
		bValid = ValidateIncomingGameStates();
		if(bValid)
		{
			foreach NewStates(NewState)
			{
				// commit the state change
				SubmitGameStateInternal(NewState, false, bWasWaitingForNewStates);
			}
			`assert(ContextBuildDepth >= 0);
		}
		else
		{
			`log("Detected cheating or errant behavior!", , 'XCom_GameStates');
		}
	}
	else
	{
		//Tell the history we don't actually want these game states
		foreach NewStates(NewState)
		{
			CachedHistory.CleanupPendingGameState(NewState);
		}
	}

	if(bCanAdd && ContextBuildDepth == 0)
	{
		CachedHistory.EndEventChain();
	}

	return bCanAdd;
}


simulated event bool SubmitGameState( XComGameState NewState)
{
	local array<XComGameState> SubmitArray;

	SubmitArray.AddItem(NewState);
	return SubmitGameStates(SubmitArray);
}

function Object GetEventObserver(int ObserverIndex)
{
	return EventObservers[ObserverIndex];
}

/// <summary>
/// This event is called from native code when new states are generated natively. States are received by a remote machine
/// come via this event.
/// </summary>
simulated event bool SubmitGameStatesNative(array<XComGameState> NewStates)
{
	return SubmitGameStates(NewStates);
}

/// <summary>
/// Overridden by subclasses - used in submit game state context to gate the addition of new states
/// </summary>
simulated function bool AddNewStatesAllowed()
{
	if (CachedHistory == None) //We can't add new states if there's nothing to add to.
	{
		//At present, nothing triggers this aside from some destructibles looking for initial state in the obstaclecourse. -btopp 2015-07-22
		`log("X2GameRuleset : AddNewStatesAllowed() queried before CachedHistory is available!", , 'XCom_GameStates');
		return false;
	}

	return !bProcessingLoad;
}

/// <summary>
/// This event is called after a system adds a gamestate to the history, perhaps circumventing the ruleset itself.
/// </summary>
simulated event OnSubmitGameState();

/// <summary>
/// Reponsible for verifying that a set of newly incoming game states obey the rules.
/// </summary>
simulated function bool ValidateIncomingGameStates()
{
	return true;
}

/// <summary>
/// Returns true if the visualizer is busy
/// </summary>
simulated function bool WaitingForVisualizer();

/// <summary>
/// Returns true if all players remote and local are at the same point in their game rules engine state system
/// </summary>
native final latent function LatentWaitingForPlayerSync();

/// <summary>
/// Returns cached information about the unit such as what actions are available
/// </summary>
simulated function bool GetGameRulesCache_Unit(StateObjectReference UnitStateRef, out GameRulesCache_Unit OutCacheData);

simulated function DrawDebugLabel(Canvas kCanvas);

simulated native function RegisterEventObserver(X2GameRulesetEventObserverInterface EventObserver);

simulated native function UnregisterEventObserver(X2GameRulesetEventObserverInterface EventObserver);

simulated event string GetStateDebugString();