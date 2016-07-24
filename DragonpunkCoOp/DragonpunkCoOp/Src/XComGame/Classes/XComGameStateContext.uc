//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext.uc
//  AUTHOR:  Ryan McFall  --  11/20/2013
//  PURPOSE: This is the base class and interface for an XComGameStateContext related to an 
//           XComGameState. The context is responsible for containing the logic and domain
//           specific knowledge to convert game play requests into new game states, and game
//           states into visualization primitives for the visualization mgr.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext extends object abstract native(Core) dependson(XComGameStateVisualizationMgr);

struct VisualizationTrackInsertedInfo
{
	var XComGameStateContext_Ability InsertingAbiltyContext;
	var StateObjectReference TrackActorRef;
	var X2Action LastTrackActionInserted;
};

var privatewrite bool bReadOnly;                //TRUE indicates that this object is a read-only copy
var privatewrite bool bSendGameState;           //TRUE indicates that this game state should be sent to remote clients in MP
var privatewrite bool bNetworkAdded;            //TRUE indicates that this was sent from a remote client (i.e. do not "resend" this back)
var privatewrite bool bVisualizerUpdatesState;	//TRUE indicates that this game state will modify the game state system when it is visualized. This is very special case - ie. ragdolls moving units around
var privatewrite int  CurrentRandSeed;          //Seed is used for replay validation (later) and MP synchronization.
var privatewrite XComGameState AssociatedState; //Reference to the XComGameState we are a part of

//X-Com allows 'interrupts' to occur, which can alter the game state that the context generates. The below variables provide enough information to trace backwards through
//the game state history to find game states that were created from the same original context object.
//
// -1 is a sentinel value in the indices that indicate that a game state that is not interrupted/resuming from an interruption.
//
var privatewrite EInterruptionStatus InterruptionStatus;//Provides information on whether the associated game state was an interrupted state or not
var privatewrite int InterruptionHistoryIndex;          //If this game state is resuming from an interruption, this index points back to the game state that are resuming from
var privatewrite int ResumeHistoryIndex;                //If this game state has been interrupted, this index points forward to the game state that will resume														

//This index provides information allowing the visualization mgr and other systems to identify "chains" of game states For instance, a move game state may be followed by a change in 
//concealment or the automatic activation of an ability. In that situation the states following the move (and resulting from it) would have a 'EventChainStartIndex' pointing to the move game state.
var privatewrite int EventChainStartIndex;		
var privatewrite bool bFirstEventInChain;	//Indicates that this game state is the first in its event chain
var privatewrite bool bLastEventInChain;	//Indicates that this game state is the last in its event chain

//Visualization sequencing controls
var privatewrite bool bVisualizationOrderIndependent; //If TRUE, marks this game state as able to start visualizing with no history index / sequencing restrictions. This is used for player
													  //directed movement and abilities where there are no side effects of the ability or interrupts, and thus the abilities should be visualized
													  //as quickly as the player can enter the commands.

var privatewrite bool bVisualizationFence;		  //Specifies that in order for this game state to be visualized all prior game states must have
												  //completed visualization
var privatewrite float VisualizationFenceTimeout; //This allows a timeout to be specified so that the fence will not block indefinitely if there is a 
												  //failure of some type. Ie. if a fence were accidentally inserted in between an interrupt state and its interrupter.

var privatewrite INT  VisualizationStartIndex;  //By default, game state visualization chains started when the game states immediately prior to them have finished visualization. This index lets
												//a game state manually control this sequencing. When the game state indicated by VisualizationOverrideIndex has been visualized, this game state will
												//be permitted to start its visualization. Using this index, for example, a set of game states could be set to visualize concurrently.

var privatewrite int DesiredVisualizationBlockIndex;    /// The desired history index the context should be visualized in. This will move it from its associated state's visualization
														/// to the DesiredVisualizationBlockIndex. Note: this is best used on states that are self contained - ie. are not interruptible.

var transient private bool bAddedFutureVisualizations; // Flag used during visualization building to determine whether 

var array< Delegate<BuildVisualizationDelegate> > PreBuildVisualizationFn; // Optional visualization functions, whose tracks precede the tracks added in ContextBuildVisualization
var array< Delegate<BuildVisualizationDelegate> > PostBuildVisualizationFn; // Optional visualization functions, whose tracks follow the tracks added in ContextBuildVisualization

delegate BuildVisualizationDelegate(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks);

/// <summary>
/// Returns the index of the specified delegate by name in the PostBuildVisualizationFn array if it exists, returns -1 if it does not exist.
/// </summary>
native function int HasPostBuildVisualization(Delegate<BuildVisualizationDelegate> del);

//XComGameStateContext interface
//***************************************************
/// <summary>
/// Should return true if ContextBuildGameState can return a game state, false if not. Used internally and externally to determine whether a given context is
/// valid or not.
/// </summary>
function bool Validate(optional EInterruptionStatus InInterruptionStatus);

/// <summary>
/// Override in concrete classes to convert the InputContext into an XComGameState ( or XComGameStates). The method is responsible
/// for adding these game states to the history
/// </summary>
/// <param name="Depth">ContextBuildGameState can be called recursively ( for interrupts ). Depth is used to track the recursion depth</param>
function XComGameState ContextBuildGameState();

/// <summary>
/// Override in concrete classes to properly handle interruptions. The method should instantiate a new 'interrupted' context and return a game state that reflects 
/// being interrupted. 'Self' for this method is the context that is getting interrupted. 
///
/// Example:
/// A move action game state would set the location of the moving unit to be the interruption tile location.
///
/// NOTE: when the interruption completes, the system will try to resume the interrupted context. Building interruption game states should ensure that the
///       interruption state will not block / prevent resuming (ie. abilities should not apply their cost in an interrupted game state)
/// </summary>
function XComGameState ContextBuildInterruptedGameState(int InterruptStep, EInterruptionStatus InInterruptionStatus);

/// <summary>
/// Override in concrete classes to convert the ResultContext and AssociatedState into a set of visualization tracks
/// </summary>
protected function ContextBuildVisualization(out array<VisualizationTrack> VisualizationTracks, out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray);

/// <summary>
/// Hook to build visualization for this entire frame
/// </summary>
function ContextBuildVisualizationFrame(out array<VisualizationTrack> VisualizationTracks)
{
	local Delegate<BuildVisualizationDelegate> VisFunction;
	local XComGameStateContext ResumeContext;
	local XComGameState ResumeState;
	local array<VisualizationTrackInsertedInfo> CollectedVisTrackInsertedInfoArray;
	local int i, TrackIndex, ActionIndex, FoundObjectIndex;
	local X2AbilityTemplate AbilityTemplate;

	// only run Pre vis functions on contexts that arent resume contexts, since we run the pre vis functions on the interrupted context
	if (InterruptionHistoryIndex < 0)
	{
		// Run pre vis functions on this context and all its resume contexts
		ResumeContext = self;
		while (ResumeContext != none)
		{
			foreach ResumeContext.PreBuildVisualizationFn(VisFunction)
			{
				if (VisFunction != None)
				{
					VisFunction(ResumeContext.AssociatedState, VisualizationTracks);
				}
			}
			ResumeState = ResumeContext.GetResumeState();
			ResumeContext = ResumeState == none ? none : ResumeState.GetContext();
		}
	}

	//Depending on their internal operation, some contexts may want to call AddVisualizationFromFutureGameStates at a specific time during their own ContextBuildVisualization.
	//This flag tracks whether they did that or not
	bAddedFutureVisualizations = false;

	ContextBuildVisualization(VisualizationTracks, CollectedVisTrackInsertedInfoArray);

	//AddVisualizationFromFutureGameStates was not called, do it here
	if(!bAddedFutureVisualizations)
	{
		AddVisualizationFromFutureGameStates(AssociatedState, VisualizationTracks, CollectedVisTrackInsertedInfoArray);
	}

	// If there is any info in CollectedVisTrackInsertedInfoArray, then allow the ability contexts to run their VisualizationTrackInsertedFn
	for( i = 0; i < CollectedVisTrackInsertedInfoArray.Length; ++i )
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(CollectedVisTrackInsertedInfoArray[i].InsertingAbiltyContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate != none && AbilityTemplate.VisualizationTrackInsertedFn != none)
		{
			FoundObjectIndex = -1;
			for(TrackIndex = 0; TrackIndex < VisualizationTracks.Length; ++TrackIndex)
			{
				if (VisualizationTracks[TrackIndex].StateObject_NewState.GetReference() == CollectedVisTrackInsertedInfoArray[i].TrackActorRef)
				{
					// Look to see if the current NewTracks actor is already in the VisualizationTracks
					FoundObjectIndex = TrackIndex;
					break;
				}
			}

			if( FoundObjectIndex > 0 )
			{
				for(ActionIndex = 0; ActionIndex < VisualizationTracks[FoundObjectIndex].TrackActions.Length; ++ActionIndex)
				{
					if( VisualizationTracks[FoundObjectIndex].TrackActions[ActionIndex] == CollectedVisTrackInsertedInfoArray[i].LastTrackActionInserted )
					{
						AbilityTemplate.VisualizationTrackInsertedFn(VisualizationTracks, CollectedVisTrackInsertedInfoArray[i].InsertingAbiltyContext, FoundObjectIndex, ActionIndex);
						break;
					}
				}
			}
		}
	}

	// only run post vis functions on contexts that arent resume contexts, since we run the pre vis functions on the interrupted context
 	if (InterruptionHistoryIndex < 0)
 	{
		// Run post vis functions on this context and all its resume contexts
		ResumeContext = self;
		while (ResumeContext != none)
 		{
			foreach ResumeContext.PostBuildVisualizationFn(VisFunction)
			{
				if (VisFunction != None)
				{
					VisFunction(ResumeContext.AssociatedState, VisualizationTracks);
				}
			}
			ResumeState = ResumeContext.GetResumeState();
			ResumeContext = ResumeState == none ? none : ResumeState.GetContext();
 		}
 	}
}

/// <summary>
/// In some cases a single logical action in the game will span several game states and in those cases it may be desired for the visualization to happen in a single visualization block. 
/// Example: viper grab + bind or a missed shot destroying a vehicle
///
/// This method loops over the GameStates in the 'future' to see if any have requested to be put into this visualization block.
///
/// </summary>
protected function AddVisualizationFromFutureGameStates(XComGameState VisualizeGameState, out array<VisualizationTrack> VisualizationTracks,
														out array<VisualizationTrackInsertedInfo> VisTrackInsertedInfoArray)
{
	local XComGameStateHistory History;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability AbilityContext;
	local int ChainHistoryIndex, NewTracksIndex, FoundObjectIndex, TrackActionsIndex, InsertedIndex;
	local array<VisualizationTrack> NewTracks;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationTrackInsertedInfo NewVisTrackInfo, EmptyVisTrackInfo;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	// Start the loop at ourself to ensure we don't gather any previous visualizations
	Context = self;

	if(IsStartState())
	{
		return;
	}

	//Mark the transient flag to indicate we have run
	bAddedFutureVisualizations = true;

	// Gather until we reach the end of the chain. This is limited to event chains since we know that they are built within a single frame / iteration of the visualization mgr.
	for(ChainHistoryIndex = Context.AssociatedState.HistoryIndex + 1; !Context.bLastEventInChain; ++ChainHistoryIndex)
	{
		if(ChainHistoryIndex >= History.GetNumGameStates())
		{
			break;
		}

		Context = History.GetGameStateFromHistory(ChainHistoryIndex).GetContext();

		if(VisualizationMgr.ShouldSkipVisualization(Context.AssociatedState.HistoryIndex))
		{
			// This Context is set to be skiped (probably already visualized)
			continue;
		}

		// Bring the visualization forward if this Context wants to be visualized in the same state as the current VisualizeGameState
		if (Context.DesiredVisualizationBlockIndex == VisualizeGameState.HistoryIndex ||
			(InterruptionStatus == eInterruptionStatus_Interrupt && Context.DesiredVisualizationBlockIndex > 0 && Context.DesiredVisualizationBlockIndex <= VisualizeGameState.HistoryIndex))
		{
			// Get the visualization tracks for this context and append them to this context's visualization
			NewTracks.Length = 0;
			Context.ContextBuildVisualization(NewTracks, VisTrackInsertedInfoArray);

			for(NewTracksIndex = 0; NewTracksIndex < NewTracks.Length; ++NewTracksIndex)
			{
				FoundObjectIndex = 0;
				while((NewTracks[NewTracksIndex].StateObject_NewState.ObjectID != VisualizationTracks[FoundObjectIndex].StateObject_NewState.ObjectID) && (FoundObjectIndex < VisualizationTracks.Length))
				{
					// Look to see if the current NewTracks actor is already in the VisualizationTracks
					++FoundObjectIndex;
				}

				if(FoundObjectIndex < VisualizationTracks.Length)
				{
					// Append the new tracks to this track that has the same actor
					for(TrackActionsIndex = 0; TrackActionsIndex < NewTracks[NewTracksIndex].TrackActions.Length; ++TrackActionsIndex)
					{
						InsertedIndex = VisualizationTracks[FoundObjectIndex].TrackActions.AddItem(NewTracks[NewTracksIndex].TrackActions[TrackActionsIndex]);
					}
		
					//Check if these tracks are from an ability that want to modify the exisiting tracks.
					AbilityContext = XComGameStateContext_Ability(Context);
					if (AbilityContext != none)
					{
						AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
						if (AbilityTemplate != none && AbilityTemplate.VisualizationTrackInsertedFn != none)
						{
							NewVisTrackInfo = EmptyVisTrackInfo;

							NewVisTrackInfo.InsertingAbiltyContext = AbilityContext;
							NewVisTrackInfo.TrackActorRef = VisualizationTracks[FoundObjectIndex].StateObject_NewState.GetReference();
							NewVisTrackInfo.LastTrackActionInserted = VisualizationTracks[FoundObjectIndex].TrackActions[InsertedIndex];

							VisTrackInsertedInfoArray.AddItem(NewVisTrackInfo);
						}
					}
				}
				else
				{
					// The current new track is not in this block, so just add it
					VisualizationTracks.AddItem(NewTracks[NewTracksIndex]);
				}
			}

			//Notify the visualization mgr that the this visualization has occurred
			VisualizationMgr.SkipVisualization(Context.AssociatedState.HistoryIndex);
		}
	}
}

/// <summary>
/// Used to set internal state variables for interruption. Called from InterruptionPostProcess
/// </summary>
function SetInterruptionIndex(bool bSetResumeHistoryIndex, int HistoryIndex)
{
	`assert(InterruptionStatus != eInterruptionStatus_None);

	if( bSetResumeHistoryIndex )
	{
		if( InterruptionStatus != eInterruptionStatus_Resume ) //Resume states never have a ResumeHistoryIndex set
		{
			ResumeHistoryIndex = HistoryIndex;  //Index in the history that holds the state that is resuming from where we were interrupted
		}
	}
	else			
	{
		InterruptionHistoryIndex = HistoryIndex; //Index in the history that holds the state that was interrupted, which we are resuming		
	}
}

/// <summary>
/// Sets whether this is an interrupted or a resume state context
/// </summary>
function SetInterruptionStatus(EInterruptionStatus Status)
{
	InterruptionStatus = Status;
}

function SetSendGameState(bool bSend)
{
	bSendGameState = bSend;
}

/// <summary>
/// Permits gameplay to mark this context as being order independent with its visualization
/// </summary>
native final function SetVisualizationOrderIndependent(bool bSetVisualizationOrderIndependent);

/// <summary>
/// Allows this game state to be visualized concurrently with the specified history index
/// </summary>
native final function SetVisualizationStartIndex(int SetVisualizationStartIndex);

/// <summary>
/// Marks this game state object as a visualization fence. These game states do not start their visualization until all prior game 
/// states have been visualized, and inhibit all subsequent game states from being visualized until they have started their visualization
///
/// <param name="Timeout">Sets a maximum time for the fence to wait. A setting of 0 waits indefinitely</param>
/// </summary>
native final function SetVisualizationFence(bool bSetVisualizationFence, float Timeout = 20.0f);

/// <summary>
/// Sets the currently used random number seed on the Context from the Engine.
/// </summary>
native function SetContextRandSeedFromEngine();

/// <summary>
/// Sets the Engine's random number seed to the one specified from this context.
/// </summary>
native function SetEngineRandSeedFromContext();


/// <summary>
/// Override to return TRUE for the context object to show that the associated state is a start state
/// </summary>
event bool IsStartState()
{
	return false;
}

event int GetStartStateOffset()
{
	return 0;
}

/// <summary>
/// Returns the first game state in the event chain that this game state context is a part of.
/// </summary>
native function XComGameState GetFirstStateInEventChain();

/// <summary>
/// Returns the next game state in the event chain that this game state context is a part of.
/// </summary>
native function XComGameState GetNextStateInEventChain();

/// <summary>
/// Returns the last game state in the event chain that this game state context is a part of.
/// </summary>
native function XComGameState GetLastStateInEventChain();

/// <summary>
/// Seaches backwards in the history and returns the first state with an interruption status of eInterruptionStatus_Interrupt
/// </summary>
native function XComGameState GetInterruptedState();

/// <summary>
/// If this context is part of an interruption sequence, returns the game state that initiated the interruption.
/// For example, if a unit moves, and is then overwatched, and then killed, this function will return
/// the initial move game state for all three of the above contexts.
/// If this context is not interrupted, returns the associated game state.
/// </summary>
native function XComGameState GetFirstStateInInterruptChain();

/// <summary>
/// If this context is part of an interruption sequence, returns the game state that finished the interrupted sequence.
/// For example, if a unit moves, and is then overwatched, and then killed, this function will return
/// the move state for all three of the above contexts.
/// If this context is not interrupted, returns the associated game state.
/// </summary>
native function XComGameState GetLastStateInInterruptChain();

/// <summary>
/// If this context has a resume index, returns the gamestate for it, or null if it doesn't have one
/// </summary>
native function XComGameState GetResumeState();

function VisualizerReplaySyncSetState(XComGameState InAssociatedState)
{	
	AssociatedState = InAssociatedState;
}

/// <summary>
/// Returns a short description of this context object
/// </summary>
event string SummaryString();

/// <summary>
/// Returns a string representation of this object.
/// </summary>
native function string ToString() const;

/// <summary>
/// Returns a long description of information about the context. 
/// </summary>
function string VerboseDebugString()
{
	return ToStringT3D();
}

// Debug-only function used in X2DebugHistory screen.
function bool HasAssociatedObjectID(int ID)
{
	return (AssociatedState.GetGameStateForObjectID(ID) != none);
}
//***************************************************

/// <summary>
/// Builds a new meta data object that can be associated with a game state. XComGameStateContext objects provide context for the object state changes 
/// contained in an XComGameState. See the description in XComGameStateContext for more detail.
/// </summary>
static function XComGameStateContext CreateXComGameStateContext()
{
	local XComGameStateContext NewContext;

	NewContext = new default.Class;
	NewContext.bReadOnly = false;

	return NewContext;
}

/// <summary>
/// This static method encapsulates the logic that must take place following an interruption - letting the interrupted and resumed states know about 
/// each other. Must be called after both states have been added to the history.
/// </summary>
static function InterruptionPostProcess(XComGameState InterruptedState, XComGameState ResumedState)
{	
	local int NextHistoryIndex;

	//None of this logic needs to be done for interrupt states that don't resume
	if( ResumedState != none )
	{
		//Make sure the states being input to this method are what we expect
		`assert(InterruptedState != none);
		`assert(InterruptedState.HistoryIndex > -1);
		`assert(InterruptedState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt);				
		`assert(ResumedState != none);
		`assert(ResumedState.HistoryIndex == -1);		
		`assert(ResumedState.GetContext().InterruptionStatus != eInterruptionStatus_None);		

		//At the point this method should be called, the resume state has not yet been added to the history but it should be the next state added.
		NextHistoryIndex = `XCOMHISTORY.GetNumGameStates();
		InterruptedState.GetContext().SetInterruptionIndex(true, NextHistoryIndex);
		ResumedState.GetContext().SetInterruptionIndex(false, InterruptedState.HistoryIndex);		
	}
}

function OnSubmittedToReplay(XComGameState SubmittedGameState);

/// <summary>
/// This sets what history index the context should be visualized in. This will move it from its associated state's visualization
/// to the given history index. If the given HistoryIndex is part of a context that doesn't get visualized then this context will
/// still visualize during its associated states history index.
/// </summary>
function SetDesiredVisualizationBlockIndex(int HistoryIndex)
{
	DesiredVisualizationBlockIndex = HistoryIndex;
}

/// <summary>
/// Setting this flag indicates that a this game state's visualization will have game state side effects. This should be extraordinarily rare. Rag dolls, for example, may 
/// alter the location of a unit.
/// </summary>
function SetVisualizerUpdatesState(bool bSetting)
{
	bVisualizerUpdatesState = bSetting;
}

defaultproperties
{
	InterruptionHistoryIndex = -1
	ResumeHistoryIndex = -1
	EventChainStartIndex = -1
	bVisualizationOrderIndependent = false;	
	VisualizationStartIndex = -1
	VisualizationFenceTimeout = 20.0 // Timeout of 20 seconds by default
	DesiredVisualizationBlockIndex=-1
	bAddedFutureVisualizations = false
}