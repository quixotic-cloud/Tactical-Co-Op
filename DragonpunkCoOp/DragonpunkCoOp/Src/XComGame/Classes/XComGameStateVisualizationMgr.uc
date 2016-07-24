//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateVisualizationMgr.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: This object is responsible for taking an XComGameState delta and visually
//           representing the state change ( unit moving, shooting, etc. )
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateVisualizationMgr extends Actor native(Core) dependson(XComGameState);

//Visualization Tracks correspond to XComGameState_<ObjectType> objects. They encapsulate the sequence of actions necessary for a 
//state object visualizer (TrackActor) to show how the game state changed. Examples: 
//    1. A unit moves from one point to another - represented by a sequence of XGActions that perform direct movement, climbing, kicking doors down, etc.
//    2. A unit shoots at an entity in the world - represented by an exit cover action, a shoot action, and a return to cover action
//    3. A vehicle explodes after being shot - represented by a destructible actor state change action
//    4. A unit activates one of their togglable abilities, such as the MEC rocket boot ability - represented by an RMA_Animation action;
struct native VisualizationTrack
{		
	//Set when the track is being configured
	var XComGameState_BaseObject StateObject_OldState;  //A copy of the state object at the beginning of the action being visualized
	var XComGameState_BaseObject StateObject_NewState;  //A copy of the state object at the end of the action being visualized
	var Actor TrackActor;                               //The visualizer object associated with StateObject 
	var init array<X2Action> TrackActions;	            //A sequence of XGActions that will be used to show the action taking place.
	var bool bWantsTimeDilation;						//Flag for whether this visualization track should be time dilated or not when the track becomes interrupted
	var Name AbilityName;

	//Set when the track runs
	var bool FiredCompletedEvent;                       //To know if we've already sent the OnRemovedFromVisualizerTrack event
	var bool bInterrupted;                              //Tracks whether this visualization track should have "resume from interrupt" called on it	
	var int BlockHistoryIndex;							//The history index that this block was originally created for. 
														//Following creation actions can be shuffled around to different visualization blocks, but this value will always point to the original
};

//Visualization Blocks correspond to XComGameState objects. For all XComGameState_<Object> that change within the state and have visualizers
//a track will be created to represent their state change. All tracks in a visualization block are run simultaneously.
struct native VisualizationBlock
{
	var int HistoryIndex;                                           //The frame in the history that was used to create this VisualizationBlock
	var bool bStarted;                                              //TRUE if this visualization block has started executing track actions	
	var bool bInterruptBlock;										//TRUE if this visualization block is interrupted will lead to a resume block
	var bool bResumeBlock;                                          //TRUE if this visualization block is resuming from an interruption	
	var bool bAllowOutOfOrderStarts;                                //TRUE if this visualization block should not block subsequent blocks from running	
	var init array<VisualizationTrack> Tracks;                      //A list of tracks that associate visualizer actors with actions that will control them
	var native Map_Mirror ObjectIDToTrackIndexMap {TMap<INT, INT>}; //Lookup table that allows for quick searches of the Tracks based on ObjectID

	var float StartTime;                                            //Debug support - tracks when this visualization block started
	var float EndTime;                                              //Debug support - tracks when this visualization block ended

	structcpptext
	{
	FVisualizationBlock() : 
	HistoryIndex(-1),
	bStarted(FALSE),
	bResumeBlock(FALSE)
	{
		Tracks.Empty();
		ObjectIDToTrackIndexMap.Empty();
	}

	FVisualizationBlock(EEventParm)
	{
		appMemzero(this, sizeof(FVisualizationBlock));
	}
	}
};

//used for building visualizations
struct native VisualizationTrackModInfo
{
	var XComGameStateContext_Ability Context;
	var int BlockIndex;
	var int TrackIndex;
};

enum EVisualizerCustomCommand
{
	eCommandNone,
	eCommandReplaySkip,
	eCommandLoadGame,
};

var private array<VisualizationBlock> ActiveVisualizationBlocks;        //Queue of visualization blocks that contain running tracks
var private array<VisualizationBlock> PendingVisualizationBlocks;       //Queue of visualization blocks that have been submitted for visualization, but have not yet started
var private array<VisualizationBlock> InterruptedVisualizationBlocks;   //Visualization blocks that have been interrupted and are waiting for a resume are placed here
var private array<VisualizationBlock> FinishedVisualizationBlocks;      //When blocks are marked complete and removed from the active list, they are placed here
var private int BlocksAddedHistoryIndex;                                //This index keeps track of which frames from History have been added to the system already
var private int StartStateHistoryIndex;									//Caches off the start state index for the current session being visualized
var public	int LastStateHistoryVisualized;								//Caches off the latest visualization block we've visualized
var private native Set_Mirror CompletedBlocks{TSet<INT>};				//Tracks which visualization blocks have been completed
var private array<int> SkipVisualizationList;							//History indices in this list will have their visualization block pushed empty instead of normally processing
var private bool bEnabled;                                              //Determines whether this manager can process new state frames. Defaults to false, set to true by the bootstrapping process when entering a game.
var private bool bWaitingOnVisualizationFence;							//TRUE if the last call to TryAddPendingBlocks hit a visualization fence
var private float TimeWaitingOnVisualizationFence;						//Tracks the time spent waiting for a visualization fence

var private array<X2VisualizationMgrObserverInterfaceNative> NativeObservers; //List of observer objects that are listening for events triggered by visualization
var private array<X2VisualizationMgrObserverInterface>       Observers; //List of observer objects that are listening for events triggered by visualization

var bool SingleBlockMode; //If this flag is true, ActiveVisualizationBlocks will only be allowed to have one element. This will force visualization of the game states to 
						  //run one at a time.

var X2VisualizerHelpers VisualizerHelpers;

cpptext
{
	/// <summary>
	/// This method is used to check whether a given visualization block has a collision with the list of running or pending blocks. A collision is
	/// defined as a situation where the test block contains a visualizer track for a visualizer that is already running a track in one of the active 
	/// blocks. The system currently forbids two tracks for a visualizer to run at the same time.
	/// </summary>
	UBOOL HasCollisionWithBlocks(const FVisualizationBlock& TestCollideBlock, UXComGameState& TestCollideGameState, UXComGameStateHistory& History);

	/// <summary>
	/// Adds the specified value to CompletedBlocks and encapsulates any related logic
	/// </summary>
	void AddEntryToCompletedBlocks(int BlockCompletedHistoryIndex);

	// Begin execution of a new visualization block, adding it to the ActiveVisualizationBlocks list
	void StartVisualizationBlock(FVisualizationBlock& NewBlock);
}

/// <summary>
/// Handles initialization for this actor
/// </summary>
event PostBeginPlay()
{
	VisualizerHelpers = new class'X2VisualizerHelpers';
	SubscribeToOnCleanupWorld();
}

function Cleanup()
{
	VisualizerHelpers = none; //Clear out the visualizer helpers
}

event Destroyed()
{
	Cleanup();
}

simulated event OnCleanupWorld()
{
	Cleanup();
}

native function OnAnimNotify(AnimNotify Notify, XGUnitNativeBase Unit);

/// <summary>
/// Called following the load of a saved game. Fills out the completed blocks set and performs other load specific startup logic.
/// </summary>
native function OnJumpForwardInHistory();

/// <summary>
/// Creates an action sequence for delta between HistoryFrame(FrameIndex) and HistoryFrame(FrameIndex - 1). By default, builds a visualization for the last frame.
/// </summary>
/// <param name="FrameIndex">The index of the history frame for which we want to build a visualization</param>
simulated event BuildVisualization(optional int FrameIndex = -1, optional bool bReplaySkip = false)
{
	local XComGameStateHistory History;
	local XComGameState VisualizeFrame;
	local array<VisualizationTrack> VisualizationTracks;
	local XComGameStateContext_TacticalGameRule ReplaySkipContext;
	local int NumGameStates, x;
	local VisualizationTrack Track;

	History = `XCOMHISTORY;
	NumGameStates = History.GetNumGameStates();

	if( NumGameStates > 0 )
	{		
		if( NumGameStates == 1 || FrameIndex == 0 )
		{			
			VisualizeFrame = History.GetGameStateFromHistory(0, eReturnType_Reference);
		}
		else
		{
			FrameIndex = FrameIndex == -1 ? (NumGameStates - 1) : FrameIndex;
			//If this is a replay skip, then get a full game state
			VisualizeFrame = History.GetGameStateFromHistory(FrameIndex, bReplaySkip ? eReturnType_Copy : eReturnType_Reference, !bReplaySkip); 
		}

		if(VisualizeFrame != none)
		{
			//Update our cached start state index
			if(VisualizeFrame.GetContext().IsStartState())
			{
				StartStateHistoryIndex = FrameIndex;
			}		

			//If we are doing a replay skip, build a fake context and use that
			if( bReplaySkip )
			{
				ReplaySkipContext = XComGameStateContext_TacticalGameRule(class'XComGameStateContext_TacticalGameRule'.static.CreateXComGameStateContext());			
				ReplaySkipContext.GameRuleType = eGameRule_ReplaySync;
				ReplaySkipContext.VisualizerReplaySyncSetState(VisualizeFrame);
				ReplaySkipContext.ContextBuildVisualizationFrame(VisualizationTracks);
			}
			else
			{
				if (SkipVisualizationList.Find(FrameIndex) < 0)
				{
					VisualizeFrame.GetContext().ContextBuildVisualizationFrame(VisualizationTracks);
				}
				else
				{
					SkipVisualizationList.RemoveItem(FrameIndex);
				}
			}

		
			for (x = 0; x < VisualizationTracks.Length; ++x)
			{
				Track = VisualizationTracks[x];

				if ((Track.TrackActor == none) && (X2VisualizedInterface(Track.StateObject_NewState) != none))
				{
					VisualizationTracks[x].TrackActor = X2VisualizedInterface(Track.StateObject_NewState).FindOrCreateVisualizer();
				}
			}		
		
			AddVisualizationBlock(VisualizeFrame, VisualizationTracks);
		}
	}
}

simulated function EnableBuildVisualization()
{
	bEnabled = true;
}

//Use to halt processing, for example - while a map is shutting down
simulated function DisableForShutdown()
{
	bEnabled = false;
	SetTickIsDisabled(true);
}


simulated function SetCurrentHistoryFrame(int SetIndex)
{
	BlocksAddedHistoryIndex = SetIndex;
}

simulated function EvaluateVisualizationState()
{
	local int NumHistoryFrames;
	local int LastHistoryFrameIndex;
	local int Index;
	
	NumHistoryFrames = `XCOMHISTORY.GetNumGameStates();
	LastHistoryFrameIndex = NumHistoryFrames - 1;
	if(LastHistoryFrameIndex > BlocksAddedHistoryIndex)
	{
		for(Index = BlocksAddedHistoryIndex + 1; Index < NumHistoryFrames; ++Index)
		{
			BuildVisualization(Index);			
		}		
		BlocksAddedHistoryIndex = LastHistoryFrameIndex;

		// Before handling control over the visualizer, reset all the collision that may have been changed by the state submission
		`XWORLD.RestoreFrameDestructionCollision( );
	}	
}

/// <summary>
/// Using a list of visualization tracks, adds a new visualiation block to either the active or pending lists.
/// </summary>
simulated native function AddVisualizationBlock(XComGameState AssociatedState, const out array<VisualizationTrack> VisualizationTracks);

/// <summary>
/// Removes the block at the specified index from the active blocks list, adds it to the finished list, and sends out 
/// block completion messages
/// </summary>
simulated native function MarkVisualizationBlockFinished(int ActiveBlockIndex);

/// <summary>
/// Sends out a track complete message
/// </summary>
simulated native function MarkVisualizationTrackComplete(out VisualizationTrack Track);

/// <summary>
/// Visualization blocks representing game state changes which have been 'interrupted' have special handling. From the perspective of the game state
/// system an interruption is just a series of game state changes like any other and is simple to process - but to the visualizer it is trickier to 
/// represent. In the interest of simplicity for the ability code, the methods that convert an ability into visualization tracks are not required to 
/// be aware of interrupts and should output a fixed set of visualization tracks dictated by the ability logic.
///
/// MarkVisualizationBlockInterrupted and the X2Action override method 'HandleInterruption' provide the mechanisms by which the visualization mgr is 
/// able to deal with interrupts:
///
/// 1. The interrupted visualization block is added normally using AddVisualizationBlock
/// 2. The interrupted visualization block's tracks run like normal.
/// 3. Within ProcessActiveVisualizationBlocks, while the interrupted block is running, the visualization mgr calls 'CheckInterrupted' on each track within the block. 
///      a. If TRUE is returned, the current track within the block has a 'WaitingOnInterruption' pushed onto its state stack. This halts execution of the action.
/// 4. Each track / action determines the timing of its interrupt independently. Once all the tracks within a block have been marked interrupted, 
///    MarkVisualizationBlockInterrupted is called. The interrupted block is moved into the InterruptedVisualizationBlocks list.
/// 5. Visualization blocks that caused the interruption play out ( ie. overwatch / reaction shots ).
/// 6. Eventually, the 'resume' block that contains the track actions in the 'WaitingOnInterruption' will be added to the active list of blocks. When this happens
///    CopyTracksFromInterruptionBlockToResumeBlock is called for it. This method transfers the track actions in the interrupted block over to the corresponding 'resume' block. The  
///    tracks in the resume block pop 'WaitingOnInterruption' from their state stacks, call 'ResumeFromInterrupt', and then resume execution - finishing the 
///    visualizer sequence that was interrupted.
///
/// </summary>
simulated native function MarkVisualizationBlockInterrupted(int ActiveBlockIndex);

/// <summary>
/// Copies tracks from an interruption block ( in the finished list ) to the resume block ( in ActiveVisualizationBlocks ).
/// </summary>
simulated native function CopyTracksFromInterruptionBlockToResumeBlock(int ResumeBlockIndex);

/// <summary>
/// Track actions communicate with each other via this method. When called, a message is sent to all tracks whose track actors that match the specified 
/// state object reference. A HistoryIndex can be specified to narrow the receiver down to a specific visualization block ( in situations where there is more than one active block )
/// </summary>
simulated native function SendInterTrackMessage(const out StateObjectReference Receiver, optional int HistoryIndex = -1);

/// <summary>
/// Iterates through the list of pending visualization blocks, and adds them to the active list / removes them from the pending list if there is no collision
/// between the pending block and any active blocks
/// </summary>
simulated native function bool TryAddPendingBlocks();

/// <summary>
/// For a given active block, returns the interruption status on the context
/// </summary>
simulated native function EInterruptionStatus GetContextInterruptionStatus(int ActiveBlockIndex);

/// <summary>
/// Returns a reference to the currently running action for a VisualizationTrack. Returns none if the track contains no actions(ie. is complete)
/// </summary>
simulated native function X2Action GetCurrentTrackAction(const out VisualizationTrack Track);

/// <summary>
/// Returns a reference to the currently running action, given an actor / visualizer. This searches both the active and interrupted lists, and
/// will use bFromInterrupted to choose which one if there are running track actions from both.
/// </summary>
simulated native function X2Action GetCurrentTrackActionForVisualizer(const Actor Visualizer, bool bFromInterrupted = false);
simulated native function X2Action GetCurrentTrackActionForState(const out StateObjectReference Receiver, optional int HistoryIndex = -1);

/// <summary>
/// Returns a reference to the currently running action, given an action class type. This searches only active lists and return actions without actors
/// Use GetCurrentTrackActionForVisualizer for actions with Actors. This is only for actions with no actors ie World Effect Actions
/// X2ActionIgnore is for skipping over actionType, and continue to scrub down the track 
/// </summary>
simulated native function array<X2Action> GetCurrentWorldEffectTrackAction(class X2ActionType, class X2ActionIgnore, INT historyIndex, const StateObjectReference Receiver);

/// <summary>
/// Make sure the unit and the VisualizationMgr are in sync about how many tracks they have
/// </summary>
native function VerifyUnitTrackSyncronization (XGUnitNativeBase Unit);

/// <summary>
/// Responsible for setting time dilation for the actively running blocks
/// </summary>
native function UpdateTrackActorTimeDilation(int ActiveBlockIndex, bool bInterruptBlocks);

/// <summary>
/// Returns true if the specified actor belongs to any active visualization blocks. If IncludePending
/// is set to true, will also check pending (not yet active) blocks.
/// </summary>
native function bool IsActorBeingVisualized(Actor Visualizer, optional bool IncludePending = true);

/// <summary>
/// Returns true if CheckTrack already has a track action of the specified type. If the method returns true, OutAction will represent the action that it found. In situations
/// where there is more than one instance of the specified action, OutAction will contain the first.
/// </summary>
native function bool TrackHasActionOfType(const out VisualizationTrack CheckTrack, class<X2Action> CheckForClass, optional out X2Action OutAction);

/// <summary>
/// Instructs the visualization mgr to insert and empty frame for the specified game state index
/// </summary>
simulated function SkipVisualization(int HistoryIndex)
{
	SkipVisualizationList.AddItem(HistoryIndex);
}

/// <summary>
/// Ask the visualization mgr to if this history index is in the skip visualization list
/// </summary>
simulated function bool ShouldSkipVisualization(int HistoryIndex)
{
	return SkipVisualizationList.Find(HistoryIndex) != INDEX_NONE;
}

/// <summary>
/// This is a special use method that will add a given active visualization block to the completed set, which will allow pending visualization blocks to start
/// running simultaneously with it. Use for special sequencing requirements such as multiple simultaneous overwatch shots
/// </summary>
native function ManualPermitNextVisualizationBlockToRun(int HistoryIndex);

/// <summary>
/// Adds the specified observer object to the list of observers to notify when visualization events occur
/// </summary>
simulated function RegisterObserver(object NewObserver)
{
	if( X2VisualizationMgrObserverInterfaceNative(NewObserver) != none )
	{
		if(NativeObservers.Find(NewObserver) == INDEX_NONE)
		{
			NativeObservers.AddItem( X2VisualizationMgrObserverInterfaceNative(NewObserver) );
		}
	}
	else if( X2VisualizationMgrObserverInterface(NewObserver) != none )
	{
		if(Observers.Find(NewObserver) == INDEX_NONE)
		{
			Observers.AddItem( X2VisualizationMgrObserverInterface(NewObserver) );
		}
	}
	else
	{
		`log("XComGameStateVisualizationMgr.RegisterObserver called with invalid observer:"@ NewObserver);
		ScriptTrace();
	}
}

/// <summary>
/// Removes the specified observer object from the list of observers to notify when visualization events occur
/// </summary>
simulated function RemoveObserver(object RemoveObserver)
{
	if( X2VisualizationMgrObserverInterfaceNative(RemoveObserver) != none )
	{
		NativeObservers.RemoveItem( X2VisualizationMgrObserverInterfaceNative(RemoveObserver) );
	}
	else if( X2VisualizationMgrObserverInterface(RemoveObserver) != none )
	{
		Observers.RemoveItem( X2VisualizationMgrObserverInterface(RemoveObserver) );
	}
	else
	{
		`log("XComGameStateVisualizationMgr.RemoveObserver called with invalid observer:"@ RemoveObserver);		
		ScriptTrace();
	}
}

private event OnVisualizationBlockStarted(XComGameState AssociatedGameState)
{
	`XEVENTMGR.OnVisualizationBlockStarted(AssociatedGameState);
}

private event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local int Index;

	// Notify observers that this block is done processing.
	// Iterate backwards in case an observer removes itself from the list in response
	// to the event
	for(Index = Observers.Length - 1; Index >= 0; --Index)
	{
		Observers[Index].OnVisualizationBlockComplete(AssociatedGameState);
	}

	for(Index = NativeObservers.Length - 1; Index >= 0; --Index)
	{
		NativeObservers[Index].OnVisualizationBlockComplete(AssociatedGameState);
	}

	/*
	`log("Marking Visualization Block Complete - History Frame"@AssociatedGameState.HistoryIndex);
	`log("*********************************************************************************");
	`log(AssociatedGameState.GetContext().SummaryString());
	`log("*********************************************************************************");
	*/

	`XEVENTMGR.OnVisualizationBlockCompleted(AssociatedGameState);
}

function NotifyActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	local int Index;

	HandleNewUnitSelection();

	// Notify observers that the active unit has changed
	// Iterate backwards in case an observer removes itself from the list in response
	// to the event
	for(Index = Observers.Length - 1; Index >= 0; --Index)
	{
		Observers[Index].OnActiveUnitChanged(NewActiveUnit);
	}

	for(Index = NativeObservers.Length - 1; Index >= 0; --Index)
	{
		NativeObservers[Index].OnActiveUnitChanged(NewActiveUnit);
	}
}

simulated function DrawDebugLabel(Canvas kCanvas)
{
	local int BlockIndex;
	local int TrackIndex;
	local int TrackActionIndex;
	local X2Action TrackAction;
	local XComGameState AssociatedGameStateFrame;	
	local ETeam UnitActionTeam;
	local string ContextString;
	local string kStr;
	local int iX, iY;
	local XComCheatManager LocalCheatManager;
	local bool bIsVisualizationStartIndexValid;
	local int WaitForHistoryIndex;
	
	LocalCheatManager = XComCheatManager(GetALocalPlayerController().CheatManager);

	if( LocalCheatManager.bDebugVisualizers )
	{
		iX=250;
		iY=50;

		UnitActionTeam = `TACTICALRULES.GetUnitActionTeam();

		kStr =      "=========================================================================================\n";
		kStr = kStr$"Visualizer Mgr State:"@GetStateName()@ (`TACTICALRULES.UnitActionPlayerIsAI() ? "(AI Activity - "@UnitActionTeam@")" : "") @ "\n";
		kStr = kStr$`ShowVar(BlocksAddedHistoryIndex) @ `ShowVar(StartStateHistoryIndex) @ `ShowVar(LastStateHistoryVisualized) @ "\n";
		kStr = kStr$"=========================================================================================\n";	

		if( ActiveVisualizationBlocks.Length > 0 )
		{
			kStr = kStr$"\n";
			kStr = kStr$"\n";

			kStr = kStr$"Active Blocks\n";
			kStr = kStr$"=========================================================================================\n";

			for( BlockIndex = ActiveVisualizationBlocks.Length - 1; BlockIndex > -1; --BlockIndex )
			{
				AssociatedGameStateFrame = `XCOMHISTORY.GetGameStateFromHistory(ActiveVisualizationBlocks[BlockIndex].HistoryIndex, eReturnType_Reference);
				ContextString = AssociatedGameStateFrame.GetContext().SummaryString()@AssociatedGameStateFrame.HistoryIndex;

				kStr = kStr$"___________Block"@BlockIndex@"___________ ("@ContextString@")\n";
				for( TrackIndex = 0; TrackIndex < ActiveVisualizationBlocks[BlockIndex].Tracks.Length; ++TrackIndex )
				{
					kStr = kStr$"Track Actor: "@ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActor@"Actions:";
					for( TrackActionIndex = 0; TrackActionIndex < ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions.Length; ++TrackActionIndex )
					{
						TrackAction = ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions[TrackActionIndex];
						kStr = kStr@"["@TrackAction@"("@TrackAction.GetStateName()@"{"@TrackAction.ExecutingTime@"} ) ] ";					
					}
					kStr = kStr$"\n\n";
				}
				kStr = kStr$"\n";
			}
		}

		if( InterruptedVisualizationBlocks.Length > 0 )
		{
			kStr = kStr$"\n";
			kStr = kStr$"\n";

			kStr = kStr$"Interrupted Blocks (Waiting for Resume)\n";
			kStr = kStr$"=========================================================================================\n";

			for( BlockIndex = InterruptedVisualizationBlocks.Length - 1; BlockIndex > -1; --BlockIndex )
			{
				AssociatedGameStateFrame = `XCOMHISTORY.GetGameStateFromHistory(InterruptedVisualizationBlocks[BlockIndex].HistoryIndex, eReturnType_Reference);
				ContextString = AssociatedGameStateFrame.GetContext().SummaryString()@AssociatedGameStateFrame.HistoryIndex;

				kStr = kStr$"___________Block"@BlockIndex@"(Interrupted)___________ ("@ContextString@")\n";
				for( TrackIndex = 0; TrackIndex < InterruptedVisualizationBlocks[BlockIndex].Tracks.Length; ++TrackIndex )
				{
					kStr = kStr$"Track Actor: "@InterruptedVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActor@"Actions:";
					for( TrackActionIndex = 0; TrackActionIndex < InterruptedVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions.Length; ++TrackActionIndex )
					{
						TrackAction = InterruptedVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions[TrackActionIndex];
						kStr = kStr@"["@TrackAction@"("@TrackAction.GetStateName()@") ] ";					
					}
					kStr = kStr$"\n\n";
				}
				kStr = kStr$"\n";
			}
		}

		if( PendingVisualizationBlocks.Length > 0 )
		{
			kStr = kStr$"\n";
			kStr = kStr$"\n";

			kStr = kStr$"Pending Blocks\n";
			kStr = kStr$"=========================================================================================\n";

			for (BlockIndex = 0; BlockIndex < PendingVisualizationBlocks.Length; ++BlockIndex)
			{
				AssociatedGameStateFrame = `XCOMHISTORY.GetGameStateFromHistory(PendingVisualizationBlocks[BlockIndex].HistoryIndex, eReturnType_Reference);

				bIsVisualizationStartIndexValid = AssociatedGameStateFrame.GetContext( ).VisualizationStartIndex > 0 &&
													AssociatedGameStateFrame.GetContext( ).VisualizationStartIndex > StartStateHistoryIndex;
				WaitForHistoryIndex = bIsVisualizationStartIndexValid ? AssociatedGameStateFrame.GetContext( ).VisualizationStartIndex : -1;

				ContextString = AssociatedGameStateFrame.GetContext().SummaryString()@AssociatedGameStateFrame.HistoryIndex@WaitForHistoryIndex;

				if (AssociatedGameStateFrame.GetContext( ).bVisualizationFence)
				{
					kStr = kStr$"___________Fence---------------------------------------------------------------------------------------------------------------------------------\n";
				}

				kStr = kStr$"___________Block"@BlockIndex@"(Pending)___________ ("@ContextString@")\n";
				for( TrackIndex = 0; TrackIndex < PendingVisualizationBlocks[BlockIndex].Tracks.Length; ++TrackIndex )
				{
					kStr = kStr$"Track Actor: "@PendingVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActor@"Actions:";
					for( TrackActionIndex = 0; TrackActionIndex < PendingVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions.Length; ++TrackActionIndex )
					{
						TrackAction = PendingVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions[TrackActionIndex];
						kStr = kStr@"["@TrackAction@"("@TrackAction.GetStateName()@") ] ";					
					}
					kStr = kStr$"\n\n";
				}
				kStr = kStr$"\n";
			}
		}

		kCanvas.SetPos(iX-1, iY);
		kCanvas.SetDrawColor(0, 0, 0);
		kCanvas.DrawText(kStr);
		kCanvas.SetPos(iX, iY+1);
		kCanvas.SetDrawColor(0, 192, 255);
		kCanvas.DrawText(kStr);
	}
}

/// <summary>
/// Returns true if the visualizer is currently in the process of showing the last game state change
/// </summary>
static simulated function bool VisualizerBusy()
{
	return `XCOMVISUALIZATIONMGR.IsInState('ExecutingVisualization');
}

/// <summary>
/// Returns true if the visualizer is currently in the process of showing the last game state change
/// </summary>
simulated native function bool VisualizerBlockingAbilityActivation(optional bool bDebugWhy);

/// <summary>
/// Attempt to release control of any cameras used by current or pending visualization blocks
/// </summary>
simulated native function HandleNewUnitSelection();

//This state is active if there are NO visualization blocks in the ActiveVisualizationBlocks or PendingVisualizationBlocks
auto state Idle
{
	simulated function NotifyIdle()
	{
		local int Index;

		// Notify observers that this block is done processing.
		// Iterate backwards in case an observer removes itself from the list in response
		// to the event
		for(Index = Observers.Length - 1; Index >= 0; --Index)
		{
			Observers[Index].OnVisualizationIdle();
		}

		for(Index = NativeObservers.Length - 1; Index >= 0; --Index)
		{
			NativeObservers[Index].OnVisualizationIdle();
		}
	}

	simulated event BeginState(name PreviousStateName)
	{
		`log(self@"entered state: "@ GetStateName(), ,'XCom_Visualization');

		NotifyIdle();
	}

	simulated event Tick( float fDeltaT )
	{
		// Failsafe if we are somehow in the idle state and there are blocks that should have been visualized.
		if( (ActiveVisualizationBlocks.Length + InterruptedVisualizationBlocks.Length + PendingVisualizationBlocks.Length) > 0 )
		{
			GotoState('ExecutingVisualization');
		}
		//If we are not performing a replay, see if there are new history frames to visualize
		else if (bEnabled && !InReplay() && !`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
		{
			EvaluateVisualizationState();
		}
	}
Begin:
}

function BeginNextTrackAction(VisualizationTrack Track, X2Action CompletedAction)
{
	local X2Action CurrentTrackAction;	

	CurrentTrackAction = GetCurrentTrackAction(Track);
	if( CurrentTrackAction != None )
	{
		if( CurrentTrackAction.IsInState('WaitingToStart') )
		{
			CurrentTrackAction.Init(Track);
			CurrentTrackAction.GotoState('Executing');
		}
	}
}

simulated function bool InReplay()
{
	return XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI) != None && XComTacticalGRI(class'WorldInfo'.static.GetWorldInfo().GRI).ReplayMgr.bInReplay;
}

//This state is active if there are visualization blocks in the ActiveVisualizationBlocks or PendingVisualizationBlocks
state ExecutingVisualization
{
	simulated event BeginState(name PreviousStateName)
	{
		`log(self@"entered state: "@ GetStateName(), , 'XCom_Visualization');
	}

	/// <summary>
	/// Iterate the list of active blocks and determine whether they are finished or need to start any track actions.
	/// </summary>
	function ProcessActiveVisualizationBlocks( float fDeltaT )
	{
		local int BlockIndex;
		local int TrackIndex;		
		local VisualizationBlock StartActiveBlock;
		local VisualizationTrack ProcessTrack;
		local X2Action CurrentTrackAction;
		local X2VisualizerInterface TrackActorInterface;
		local bool bBlockFinished;	
		local bool bBlockInterrupted;
		local bool bResumeFromInterrupt;
		local X2ReactionFireSequencer ReactionFireSequencer;
		local int TrackActionIndex;
		local bool bAnyNonWaitActionsExecuting;
		local X2Action FirstWaitAction;

		for( BlockIndex = ActiveVisualizationBlocks.Length - 1; BlockIndex > -1; --BlockIndex )
		{
			bResumeFromInterrupt = false;

			if( !ActiveVisualizationBlocks[BlockIndex].bStarted )
			{
				//Only use for OnVisualizationBlockStarted ( cannot pass dynamic array element as out param )
				StartActiveBlock = ActiveVisualizationBlocks[BlockIndex];
				ActiveVisualizationBlocks[BlockIndex].StartTime = WorldInfo.TimeSeconds;

				if( ActiveVisualizationBlocks[BlockIndex].bResumeBlock )
				{
					CopyTracksFromInterruptionBlockToResumeBlock(BlockIndex);
					bResumeFromInterrupt = true;
				}

				//Kick off all the tracks
				for( TrackIndex = 0; TrackIndex < ActiveVisualizationBlocks[BlockIndex].Tracks.Length; ++TrackIndex )
				{
					ProcessTrack = ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex];
					CurrentTrackAction = GetCurrentTrackAction(ProcessTrack);

					if (CurrentTrackAction != None)
					{
						if(ProcessTrack.bInterrupted || bResumeFromInterrupt)
						{
							ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].bInterrupted = false;

							//All track actions must receive the ResumeFromInterrupt so that VisualizationBlockContext can be correct / updated
							for(TrackActionIndex = 0; TrackActionIndex < ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions.Length; ++TrackActionIndex)
							{
								ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions[TrackActionIndex].ResumeFromInterrupt(ActiveVisualizationBlocks[BlockIndex].HistoryIndex);
							}
						}

						if( CurrentTrackAction.IsInState('WaitingToStart') )
						{
							CurrentTrackAction.Init(ProcessTrack);
							CurrentTrackAction.GotoState('Executing');
						}
					}
						
					TrackActorInterface = X2VisualizerInterface(ProcessTrack.TrackActor);
					if( TrackActorInterface != none )
					{
						TrackActorInterface.OnVisualizationBlockStarted(StartActiveBlock);
					}					
				}

				ActiveVisualizationBlocks[BlockIndex].bStarted = true;
			}
			else
			{
				//For each track, start the track if it has not been started yet. If no tracks are executing, the block is 
				//detected as finished and removed from the list of active blocks
				bBlockFinished = true;
				bBlockInterrupted = GetContextInterruptionStatus(BlockIndex) == eInterruptionStatus_Interrupt;
				
				bAnyNonWaitActionsExecuting = false;
				FirstWaitAction = None;

				for( TrackIndex = 0; TrackIndex < ActiveVisualizationBlocks[BlockIndex].Tracks.Length; ++TrackIndex )
				{
					ProcessTrack = ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex];
					
					CurrentTrackAction = GetCurrentTrackAction(ProcessTrack);
					if( CurrentTrackAction != none && CurrentTrackAction.bCompleted == false )
					{
						if( CurrentTrackAction.IsInState('Executing') )
						{
							CurrentTrackAction.UpdateExecutingTime(fDeltaT);

							if( !CurrentTrackAction.IsWaitingOnActionTrigger() )
							{
								bAnyNonWaitActionsExecuting = true;
							}
							else if( FirstWaitAction == None )
							{
								FirstWaitAction = CurrentTrackAction;
							}
						}

						if( CurrentTrackAction.IsInState('WaitingToStart') )
						{
							CurrentTrackAction.Init(ProcessTrack);
							CurrentTrackAction.GotoState('Executing');
						}
						else if( GetContextInterruptionStatus(BlockIndex) == eInterruptionStatus_Interrupt &&
								 CurrentTrackAction.IsInState('Executing') )
						{
							if( CurrentTrackAction.CheckInterrupted() )
							{
								ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].bInterrupted = true;
								CurrentTrackAction.BeginInterruption();
							}
						}

						bBlockInterrupted = bBlockInterrupted && ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex].bInterrupted;
						bBlockFinished = false;
					}
					else
					{
						// All TrackActions are completed
						MarkVisualizationTrackComplete(ProcessTrack);
						ActiveVisualizationBlocks[BlockIndex].Tracks[TrackIndex] = ProcessTrack; // Since MarkVisualizationTrackComplete can change the Track
					}
				}

				// if the only executing action(s) is a Wait, release the wait. This prevents long timeouts when there is no pending inter-track message
				if( !bAnyNonWaitActionsExecuting && FirstWaitAction != None )
				{
					FirstWaitAction.TriggerWaitCondition();
				}

				UpdateTrackActorTimeDilation(BlockIndex, false);

				//Failsafe - interrupted blocks should not reach this state but we give X2Actions plenty of rope to hang themselves with. The correct behavior for interrupt blocks
				//			 is to mark themselves as interrupted before the block is finished. So, alter these values to force the block down the correct path.
				if(ActiveVisualizationBlocks[BlockIndex].bInterruptBlock && bBlockFinished)
				{
					bBlockFinished = false;
					bBlockInterrupted = true;
				}

				if( bBlockFinished )
				{
					MarkVisualizationBlockFinished(BlockIndex);
				}
				else if ( bBlockInterrupted )
				{
					MarkVisualizationBlockInterrupted(BlockIndex);
				}
			}
		}

		//Process time dilation for interrupted actors, but only if we're not doing reaction-fire sequencing
		if (XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI) != none)
		{
			ReactionFireSequencer = class'XComTacticalGRI'.static.GetReactionFireSequencer();
			if (ReactionFireSequencer == None || !ReactionFireSequencer.InReactionFireSequence())
			{
				for (BlockIndex = 0; BlockIndex < InterruptedVisualizationBlocks.Length; ++BlockIndex)
				{
					UpdateTrackActorTimeDilation(BlockIndex, true);
				}
			}
		}
	}

	// scans the list of active blocks and marks any that are empty as "finished"
	simulated function FinishEmptyActiveBlocks()
	{
		local int BlockIndex;

		for( BlockIndex = ActiveVisualizationBlocks.Length - 1; BlockIndex > -1; --BlockIndex )
		{
			if(ActiveVisualizationBlocks[BlockIndex].Tracks.Length == 0 && !ActiveVisualizationBlocks[BlockIndex].bResumeBlock)
			{
				MarkVisualizationBlockFinished(BlockIndex);
			}
		}
	}

	simulated event Tick( float fDeltaT )
	{
		local int Index;
		local VisualizationBlock Temp;

		//If we are not performing a replay, see if there are new history frames to visualize
		if (bEnabled && !InReplay() && !`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
		{
			EvaluateVisualizationState();
		}

		//Process our active blocks, activating visualizer tracks and removing blocks that have completed
		if( ActiveVisualizationBlocks.Length > 0 )
		{
			ProcessActiveVisualizationBlocks(fDeltaT);
		}

		// Now keep trying to add new blocks while removing empty blocks until no new active blocks can be added.
		// Many things will add gamestates without any visualization, and if we do not do this loop, we will be
		// able to retire at most one of them per frame. This causes large delays when a chain of dependent
		// gamestates without visualizations come through, so just blow through them here all at once.
		while(TryAddPendingBlocks())
		{
			FinishEmptyActiveBlocks();
		}

		// RAM - PATCH HAX, the reaction fire sequencer can sometimes cause stranded interrupt blocks which in turn cause hangs in various systems
		// that look to see if the visualizer is busy or not ( which it will be if it still has an interrupt block ). QA was able to get this to happen
		// when putting entire squads in overwatch while triggering enemy pods during the alien turn, resulting in dozens of  chained overwatch shots interrupting
		// reveals, scampers, myriad other actions. This is a low risk bandaid that will keep VisualizerBusy watchers happy...
		if(InterruptedVisualizationBlocks.Length > 0 &&
		   (PendingVisualizationBlocks.Length == 0 && ActiveVisualizationBlocks.Length == 0))
		{
			//Transfer the stranded interrupt blocks to the active list, where they will be cleaned up properly.
			for(Index = 0; Index < InterruptedVisualizationBlocks.Length; ++Index)
			{
				Temp = InterruptedVisualizationBlocks[Index];
				Temp.bInterruptBlock = false;
				ActiveVisualizationBlocks.AddItem(Temp);
			}

			//Clear the interrupted blocks
			InterruptedVisualizationBlocks.Length = 0; 
		}

		if (bWaitingOnVisualizationFence)
		{
			TimeWaitingOnVisualizationFence += fDeltaT;
		}

		if( ActiveVisualizationBlocks.Length == 0 && 
			InterruptedVisualizationBlocks.Length == 0 &&
			PendingVisualizationBlocks.Length == 0 )
		{
			GotoState('Idle');
		}
	}
}

public function GetTrackActions(int BlockIndex, out array<VisualizationTrack> OutVisualizationTracks)
{
	if (BlockIndex < PendingVisualizationBlocks.Length)
	{
		OutVisualizationTracks = PendingVisualizationBlocks[BlockIndex].Tracks;
	}
}

//Find pending visualization blocks that have the TrackActor performing the specified ability.
public function GetVisModInfoForTrackActor(const Name AbilityName, const Actor TrackActor, out array<VisualizationTrackModInfo> InfoArray)
{
	local int Index;
	local int TrackIndex;
	local XComGameState GameState;
	local XComGameStateContext_Ability AbilityContext;
	local VisualizationTrackModInfo NewInfo;

	for (Index = 0; Index < PendingVisualizationBlocks.Length; ++Index)
	{
		for (TrackIndex = 0; TrackIndex < PendingVisualizationBlocks[Index].Tracks.Length; ++TrackIndex)
		{
			if (PendingVisualizationBlocks[Index].Tracks[TrackIndex].AbilityName == AbilityName &&
				PendingVisualizationBlocks[Index].Tracks[TrackIndex].TrackActor == TrackActor)
			{
				GameState = `XCOMHISTORY.GetGameStateFromHistory(PendingVisualizationBlocks[Index].HistoryIndex);
				if (GameState != none)
				{
					AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
					if (AbilityContext != none)
					{
						NewInfo.Context = AbilityContext;
						NewInfo.BlockIndex = Index;
						NewInfo.TrackIndex = TrackIndex;
						InfoArray.AddItem(NewInfo);
						break;
					}
				}
			}
		}
	}
}

public function RemovePendingTrackAction(int BlockIndex, int TrackIndex, int ActionIndex)
{
	`assert(BlockIndex < PendingVisualizationBlocks.Length);
	`assert(TrackIndex < PendingVisualizationBlocks[BlockIndex].Tracks.Length);
	`assert(ActionIndex < PendingVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions.Length);
	PendingVisualizationBlocks[BlockIndex].Tracks[TrackIndex].TrackActions.Remove(ActionIndex, 1);
}

public function bool VisualizationBlockExistForHistoryIndex(int HistoryIndex)
{
	local int Index;

	for( Index = 0; Index < ActiveVisualizationBlocks.Length; ++Index)
	{
		if(ActiveVisualizationBlocks[Index].HistoryIndex == HistoryIndex)
			return true;
	}
	for( Index = 0; Index < PendingVisualizationBlocks.Length; ++Index)
	{
		if(PendingVisualizationBlocks[Index].HistoryIndex == HistoryIndex)
			return true;
	}
	for( Index = 0; Index < InterruptedVisualizationBlocks.Length; ++Index)
	{
		if(InterruptedVisualizationBlocks[Index].HistoryIndex == HistoryIndex)
			return true;
	}

	return false;
}


DefaultProperties
{	
	bEnabled = false;
	LastStateHistoryVisualized = -1;
}