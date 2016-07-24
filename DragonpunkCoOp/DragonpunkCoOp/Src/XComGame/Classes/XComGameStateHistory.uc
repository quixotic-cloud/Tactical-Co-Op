//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateHistory.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: This object stores and maintains a history of state changes that have occurred 
//           while playing X-Com. It represents the data store for game play.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateHistory extends Object native(Core) config(GameData);

var config bool EnableSingletonStateOptimization;

var private{private} int NumSessions;				//Counter for how many history sessions have been entered
var() private{private} array<XComGameState> History;//Lists game state changes in the current session.
var() private{private} int CurrentIndex;            //If greater than -1, this directs the history to treat History(CurrentIndex) as the "latest" game state when queried
var() private{private} int NextObjectID;
var() private{private} int HistoryStartIndex;       //This marker/index adjusts the History's notion of "first game state". Used to limit the scope of game state searches.
var() private{private} int EventChainStartIndex;	//This value will be set into the field of the same name in all game states that are added to the history
var() protectedwrite int Version;					//Used to track version / CL / etc. during development
var() private{private} int CurrRandomSeed;			//The Current Random Seed

var private{private} native Map_Mirror VisualizerMap{ TMap<INT, AActor*> }; //Stores a lookuptable for GetVisualizer to use
var private{private} XComGameState StateObjectCache; //This game state contains references to the latest state object, for each ObjectID that exists in the History. The determination
													 //of 'latest' takes into consideration the value of CurrentIndex. 
var private{private} native Map_Mirror StateObjectCacheTypeMap{ TMap<FName, TArray<UXComGameState_BaseObject*> > }; //This map allows quick per-type retrieval of objects from the StateObjectCache

// A list of all game states that have been created but not yet submitted
var private{private} array<XComGameState> PendingGameStates;

//Delegates - when adding new delegate arrays, ensure that they are cleaned up properly in ResetHistory and on level transitions
var array< Delegate<OnNewGameStateDelegate> > OnNewGameStateReceivers;
var array< Delegate<OnObliteratedGameStateDelegate> > OnObliteratedGameStateReceivers;
var array< Delegate<OnNewGameStateObjectDelegate> > OnNewGameStateObjectReceivers;

delegate OnNewGameStateDelegate(XComGameState NewGameState);
delegate OnObliteratedGameStateDelegate(XComGameState NewGameState);
delegate OnNewGameStateObjectDelegate(XComGameState_BaseObject NewGameStateObject);

cpptext
{
public: 
	void Serialize(FArchive& Ar);

	void WriteToByteArray(TArray<BYTE>& InData);
	void WriteToByteArray(TArray<BYTE>& InData, TArray<UObject*>& AdditionalObjects); //AdditionalObjects specifies additional objects to serialize with the history
	void ReadFromByteArray(TArray<BYTE>& InData, INT PackageFileVersion = GPackageFileVersion, INT PackageFileLicenseeVersion = GPackageFileLicenseeVersion);
	void ReadFromByteArray(TArray<BYTE>& InData, TArray<UObject*>& AdditionalObjects, INT PackageFileVersion = GPackageFileVersion, INT PackageFileLicenseeVersion = GPackageFileLicenseeVersion); //AdditionalObjects specifies additional objects to serialize with the history

	class UXComGameState_BaseObject* NativeGetGameStateForObjectID(INT ObjectID, INT HistoryIndex=-1 ); //Returns a reference to the XComGameStateObject associated with ObjectID
	class UXComGameState* NativeGetGameState(INT HistoryIndex); //Returns a history frame
	class UXComGameState* GetStateObjectCache();
	const TArray<UXComGameState_BaseObject*>* GetStateObjectsOfClass(const FName& ClassName);

	void InsertHistoryFrame(INT InsertIndex, class UXComGameState* InsertGameState); //Used by the x-com network mgr to add history frames directly
	void SetNextObjectID(INT NewNextObjectID); //Specialized method used in serialization, esp. from the network

	//Synchronizes the StateObjectCache with a new state, or the entire History up to HistoryIndex if NULL is provided. If HistoryIndex is -1, then the entire history 
	//is used.
	void UpdateStateObjectCache(const UXComGameState* NewState = NULL, INT HistoryIndex = -1);
	void UpdateStateObjectCacheIncremental(UXComGameState_BaseObject* NewStateObject);

	void AddObjectToTypeMap(UXComGameState_BaseObject* NewStateObject);
	void AddObjectToTypeMap(UXComGameState_BaseObject* NewStateObject, FName ClassName);

	void LoadEngineRandomSeedFromStateHistory();
	void GetLatestRandomSeed();

	// Accessors for the Visualizer Map - used to hold over the map between MP history loading mid-game.
	TMap<INT, AActor*>* GetVisualizerMap();
	void SetVisualizerMap(TMap<INT, AActor*>* NewMap);

	void ActorDestroyedHandler(AActor* ActorBeingDestroyed);

	void DuplicateHistoryDiff( UXComGameStateHistory *OtherHistory );

private:
	bool ShouldValidateContext(const UXComGameStateContext_Ability* Context);
}

/// <summary>
/// Returns the size of the history array
/// </summary>
native function int GetNumGameStates();

/// <summary>
/// Manipulates CurrentIndex. Should only ever be used by the replay system
/// </summary>
native function SetCurrentHistoryIndex(int InCurrentIndex);

/// <summary>
/// External systems can register a delegate method that will be called once a new game state has been added to the history
/// </summary>
native function RegisterOnNewGameStateDelegate( Delegate<OnNewGameStateDelegate> OnNewGameStateReceiver);
function UnRegisterOnNewGameStateDelegate(Delegate<OnNewGameStateDelegate> OnNewGameStateReceiver)
{
	OnNewGameStateReceivers.RemoveItem(OnNewGameStateReceiver);
}

/// <summary>
/// Issued from AddGameStateToHistory, this allows external systems to respond to new game state frames being added
/// </summary>
event OnNewGameStateDelegates(XComGameState NewGameState)
{
	local int DelegateIndex;
	local Delegate<OnNewGameStateDelegate> CallDelegate;

	for( DelegateIndex = 0; DelegateIndex < OnNewGameStateReceivers.Length; ++DelegateIndex )
	{
		CallDelegate = OnNewGameStateReceivers[DelegateIndex];
		CallDelegate(NewGameState);
	}
}

/// <summary>
///  External systems can register a delegate method that will be called when a game state has been obliterated
/// </summary>
function RegisterOnObliteratedGameStateDelegate( Delegate<OnObliteratedGameStateDelegate> OnObliteratedGameStateReceiver)
{
	OnObliteratedGameStateReceivers.AddItem(OnObliteratedGameStateReceiver);
}

function UnRegisterOnObliteratedGameStateDelegate(Delegate<OnObliteratedGameStateDelegate> OnObliteratedGameStateReceiver)
{
	OnObliteratedGameStateReceivers.RemoveItem(OnObliteratedGameStateReceiver);
}


/// <summary>
/// Issued from ObliterateGameStatesFromHistory, this allows external systems to respond to game state destruction
/// </summary>
event OnObliteratedGameStateDelegates(XComGameState ObliteratedGameState)
{
	local int DelegateIndex;
	local Delegate<OnObliteratedGameStateDelegate> CallDelegate;

	for( DelegateIndex = 0; DelegateIndex < OnObliteratedGameStateReceivers.Length; ++DelegateIndex )
	{
		CallDelegate = OnObliteratedGameStateReceivers[DelegateIndex];
		CallDelegate(ObliteratedGameState);
	}
}

/// <summary>
/// External systems can register a delegate method that will be called once a new game state object has been added to the history
/// </summary>
function RegisterOnNewGameStateObjectDelegate( Delegate<OnNewGameStateObjectDelegate> OnNewGameStateObjectReceiver)
{
	OnNewGameStateObjectReceivers.AddItem(OnNewGameStateObjectReceiver);
}

/// <summary>
/// Issued from AddGameStateToHistory, this allows external systems to respond to new game state objects being added
/// </summary>
event OnNewGameStateObjectDelegates(XComGameState_BaseObject NewGameStateObject)
{
	local int DelegateIndex;
	local Delegate<OnNewGameStateObjectDelegate> CallDelegate;

	for( DelegateIndex = 0; DelegateIndex < OnNewGameStateObjectReceivers.Length; ++DelegateIndex )
	{
		CallDelegate = OnNewGameStateObjectReceivers[DelegateIndex];
		CallDelegate(NewGameStateObject);
	}
}

simulated function DrawDebugLabel(Canvas kCanvas)
{
	local string kStr;
	local int iX, iY;
	local int MaxHistoryFrames;
	local XComCheatManager LocalCheatManager;
	
		
	LocalCheatManager = XComCheatManager(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().CheatManager);

	if( LocalCheatManager.bDebugHistory )
	{
		iX=250;
		iY=50;

		MaxHistoryFrames = 40;
		kStr = HistoryDebugString(MaxHistoryFrames);

		kCanvas.SetPos(iX, iY);
		kCanvas.SetDrawColor(0,255,0);
		kCanvas.DrawText(kStr);
	}
}

simulated function string HistoryDebugString(int HistoryPrintLimit=0)
{
	local int HistoryIndex;
	local int NumHistoryPrinted;
	local XComGameState AssociatedGameStateFrame;	
	local string ContextString;	
	local string kStr;

	kStr =      "\n=========================================================================================\n";
	kStr = kStr$"History\n";
	kStr = kStr$"=========================================================================================\n";	
	
	kStr = kStr$"\n";

	HistoryPrintLimit = HistoryPrintLimit == 0 ? MaxInt : HistoryPrintLimit;
	NumHistoryPrinted = 0;
	for( HistoryIndex = GetCurrentHistoryIndex(); HistoryIndex > -1 && NumHistoryPrinted < HistoryPrintLimit; --HistoryIndex )
	{
		AssociatedGameStateFrame = GetGameStateFromHistory(HistoryIndex, eReturnType_Reference);
		ContextString = AssociatedGameStateFrame.GetContext().SummaryString();

		kStr = kStr$"History Frame"@HistoryIndex@" : "@ContextString@"\n";

		++NumHistoryPrinted;
	}

	return kStr;
}

/// <summary>
/// Returns the index into History that is considered the 'current' history frame. For normal play, this will the last index in the History array.
/// </summary>
native final function int GetCurrentHistoryIndex();

/// <summary>
/// Called during GWorld::CleanupWorld - removes any references to world actors that the History may have accumulated ( such as visualizers, delegates )
/// </summary>
native final function Cleanup();

/// <summary>
/// Clears all history frames, wipes the visualizer map, and sets the NextObjectID to 0
/// </summary>
/// <param name="EventManager">If NONE, will use the engine's singleton instead</param>
native final function ResetHistory(optional X2EventManager EventManager, optional bool RemovePersistentListeners = true);

/// <summary>
/// Calls destroy on all visualizer actors. Meant to be called in combination with ResetHistory so that the visualizers go away with the history
/// </summary>
native final function DestroyVisualizers();

/// <summary>
/// Archives the current state of the history, zeros all references from History, appends two full game states containing the current and previous states 
/// for all state objects
/// </summary>
native final function ArchiveHistory(string ArchiveDescriptor);

/// <summary>
/// Instantiates a new XComGameState. By default the returned game state is empty.
/// </summary>
/// <param name="bCreateDelta">IF TRUE, will return an empty state IF FALSE, Instructs the function to return a complete copy of the most recent game state.</param>
/// <param name="NewContext">This will become the context for the new XComGameState</param>
native final function XComGameState CreateNewGameState(bool bCreateDelta, XComGameStateContext NewContext);

/// <summary>
/// Removes the specified game state from the PendingGameStates list without adding it to the history.
/// </summary>
/// <param name="GameState">Game state to clean up</param>
native final function CleanupPendingGameState(XComGameState GameState);

/// <summary>
/// Adds the specified game state to the History as the top most history element.
/// </summary>
/// <param name="NewGameState">Game state to add to the history</param>
native final function AddGameStateToHistory(XComGameState NewGameState);

/// <summary>
/// Removes all information related to the last Count states from the history.
/// </summary>
/// <param name="Count">Number of states to pop from the history.</param>
native final function ObliterateGameStatesFromHistory(optional int Count = 1);

/// <summary>
/// GetFrame returns the game state at the specified HistoryFrame. Depending on the DesiredReturnType parameter the returned game state could be a copy or a reference. If the
/// returned game state is a reference, the game state is intended to be read only.
/// </summary>
/// <param name="HistoryIndex">Specify a history index if CurrentState should represent a full state at some arbitrary point in History. Default value specifies the last frame</param>
/// <param name="DesiredReturnType">Specifies whether the returned XComGameState is a reference or a copy. If this is set to eReturnType_Reference - bDelta is ignored 
///             ( ie. cannot return a full game state reference to a delta game state and vice versa )</param>
/// <param name="bDelta">IF TRUE, the returned game state will be a delta between HistoryIndex's frame and the previous frame IF FALSE, the returned game state will be 
///             a full game state. Ignored if DesiredReturnType=eReturnType_Reference</param>
native final function XComGameState GetGameStateFromHistory(optional int HistoryIndex=-1, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference, optional bool bDelta=true);

/// <summary>
/// Provided a given game state, returns the gamestate immediately before that game state in the history.
/// </summary>
/// <param name="GameState">The game state immediately after the state you want to get.</param>
/// <param name="DesiredReturnType">Specifies whether the returned XComGameState is a reference or a copy. If this is set to eReturnType_Reference - bDelta is ignored 
///             ( ie. cannot return a full game state reference to a delta game state and vice versa )</param>
/// <param name="bDelta">IF TRUE, the returned game state will be a delta between HistoryIndex's frame and the previous frame IF FALSE, the returned game state will be 
///             a full game state. Ignored if DesiredReturnType=eReturnType_Reference</param>
native final function XComGameState GetPreviousGameStateFromHistory(XComGameState GameState, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference, optional bool bDelta=true);

/// <summary>
/// If a 'start state' is the top element on the history, this method will return a reference to it. Start states 
/// are built over a potentially long period of time including map loading. While the state object could be stored 
/// anywhere technically, it is natural for it to simply be stored in the history and accessible as a reference for 
/// the period of time where it is still being edited.
///
/// The returned start state could be a strategy, or tactical start state. If the topmost state is not a start 
/// state, the returned reference will be null.
/// </summary>
native final function XComGameState GetStartState();

/// <summary>
/// Searches backwards from the latest frame in the History array, and returns the index of the first start state encountered.
/// </summary>
native final function int FindStartStateIndex();

/// <summary>
/// Similar to the method of the same name in XComGameState, this method retrieves a copy of the state object for the requested ObjectID. By default this method
/// returns the most recent state object, but older state objects can be retrieved by using the optional HistoryIndex parameter.
/// </summary>
/// <param name="ObjectID">Specifies which state object to retrieve</param>
/// <param name="HistoryIndex">If set, the method will return the latest game state object as of the passed in HistoryIndex</param>
native final function XComGameState_BaseObject GetGameStateForObjectID(int ObjectID, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference, optional int HistoryIndex=-1);

/// Returns a copy or reference of the state for the given component class on the specified objectid. For example, if a 
/// game object has both a destructible and an interactive object state in it's hierarchy, this function will return the specified
/// type of component regardless of which of the two object ids is passed in.
/// </summary>
/// <param name="ObjectID">Unique indentifier associated with the object state requested</param>
/// <param name="ComponentClass">Unreal class of the component state you are looking for.</param>
/// <param name="HistoryIndex">If set, the method will return the latest game state object as of the passed in HistoryIndex</param>
native final function XComGameState_BaseObject GetGameStateComponentForObjectID(int ObjectID, class<object> ComponentClass, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference, optional int HistoryIndex=-1);

/// <summary>
/// Returns the most recent state object of the type specified. Intended to be used primarily for singleton style state objects such as the X-Com headquarters, battle data, or game time
/// </summary>
/// <param name="StateObjectClass">The class of the object to find</param>
/// <param name="AllowNULL">If true, no error/warning will be spewed if no singleton was found</param>
native final function XComGameState_BaseObject GetSingleGameStateObjectForClass(class StateObjectClass, optional bool AllowNULL);

/// <summary>
/// This method will return, as out parameters, copies of the current and previous state objects for the given ObjectID.
/// </summary>
/// <param name="ObjectID">Specifies which state object to retrieve</param>
/// <param name="PreviousState">Filled out with the previous state of this object, none if the object does not have a previous state</param>
/// <param name="CurrentState">Filled out with the current state of this object, none if the object does not have a current state/param>
/// <param name="HistoryIndex">If set, the method will return the latest game state object as of the passed in HistoryIndex</param>
native final function GetCurrentAndPreviousGameStatesForObjectID(int ObjectID, 
																 out XComGameState_BaseObject OutPreviousState, 
																 out XComGameState_BaseObject OutCurrentState, 
																 optional EGameStateReturnType DesiredReturnType=eReturnType_Reference, 
																 optional int HistoryIndex=-1);

native final function XComGameState_BaseObject GetPreviousGameStateForObject( XComGameState_BaseObject CurrentState,
												optional EGameStateReturnType DesiredReturnType = eReturnType_Reference);

/// <summary>
/// This method will return the original, or head, version of a given object. In other words, the very first version
/// of it that has ever existed. This function does not cross the archive boundary, so if this object was created before
/// the current session, it will return the version of the object as it existed when the archive was last created..
/// </summary>
native final function XComGameState_BaseObject GetOriginalGameStateRevision(int ObjectID, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference);

/// <summary>
/// IterateByClassType provides a foreach iterator that provides an interface for looping through the game state objects of a given class. 
/// If a specific history frame is needed, use GetGameStateFromHistory and iterate on the returned XComGameState directly.
/// </summary>
/// <param name="SearchClass">Type of object to iterate</param>
/// <param name="GameStateObject">Returns a game state of the type specified</param>
/// <param name="DesiredReturnType">Allows a user to specify that a copy be returned, or a reference</param>
/// <param name="bUnlimitedSearch">If set to TRUE, tells the system to search backwards past the last start state for objects of the specified type</param>
native final iterator function IterateByClassType(class<object> SearchClass, out object GameStateObject, optional EGameStateReturnType DesiredReturnType = eReturnType_Reference, optional bool bUnlimitedSearch, int HistoryIndex = -1);

/// <summary>
/// IterateContextsByClassType provides a foreach iterator that loops through the history and allows searching for specific game state contexts
/// </summary>
/// <param name="SearchClass">XComGameState_Context derived class to search for.</param>
/// <param name="ContextObject">Output of the iterator</param>
/// <param name="IterateIntoThePast">If true, search from the current history frame backwards toward the start state. If false, iterate forward from the start state. Defaults to true.</param>
native final iterator function IterateContextsByClassType( class<object> SearchClass, out object ContextObject, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference, optional bool IterateIntoThePast = true );

/// <summary>
/// Returns an ObjectID that will be unique within this session of X-Com
/// </summary>
native final function int GetNextObjectID();

/// <summary>
/// Retrieves the XComGameStateHistory from the global engine object. Provides logic for editor vs. game operation.
/// </summary>
static native final function XComGameStateHistory GetGameStateHistory();

/// <summary>
/// Retrieves the XComGameStateHistory from the global engine object. This is used for validating Challenge Mode game saves.
/// </summary>
static native final function XComGameStateHistory GetValidationGameStateHistory();

/// <summary>
/// Returns the visualizer actor for the specified object ID.
/// </summary>
/// <param name="ObjectID">Specifies which state object to retrieve</param>
native final function Actor GetVisualizer(int ObjectID);

/// <summary>
/// Sets the visualizer actor for the specified object ID.
/// </summary>
/// <param name="ObjectID">Specifies which state object to retrieve</param>
/// <param name="Visualizer">Actor that will become the visualizer for the specified object state</param>
native final function SetVisualizer(int ObjectID, Actor Visualizer);

/// <summary>
/// Populates the History with the byte data stored in the ChallengeModeManager.
/// </summary>
/// <param name="ChallengeIndex">The Index in the Challenges array of the ChallengeModeManager from which to read the byte data.</param>
native final function bool ReadHistoryFromChallengeModeManager(int ChallengeIndex);

/// <summary>
/// Stores the history in a file at the location specified. Returns true if the file specified was found and
/// read successfully
/// </summary>
/// <param name="RelativePath">Specifies a relative path from the game's root directory, appGameDir()</param>
/// <param name="Filename">Name of the file that will hold the history data</param>
native final function bool ReadHistoryFromFile(string RelativePath, string Filename);

/// <summary>
/// Stores the history in a file at the location specified
/// </summary>
/// <param name="RelativePath">Specifies a relative path from the game's root directory, appGameDir()</param>
/// <param name="Filename">Name of the file that will hold the history data</param>
native final function WriteHistoryToFile(string RelativePath, string Filename);

/// <summary>
/// Returns a string representation of this object.
/// </summary>
native function string ToString() const;

// Methods for adding/removing locks on the history; while locked, GameStates should not be Created, Destroyed, Added, or Obliterated
native function AddHistoryLock();
native function RemoveHistoryLock();

/// <summary>
/// Event chains allow game states to be grouped together based on rule set logic. This method signals to the history that an event chain has started
/// </summary>
native function BeginEventChain();

/// <summary>
/// Event chains allow game states to be grouped together based on rule set logic. This method signals to the history that an event chain has ended
/// </summary>
native function EndEventChain();

// Access the start index of the current event chain
native function int GetEventChainStartIndex();

// Helper function to check & warn if any game states have been created but not yet submitted
native function CheckNoPendingGameStates(optional XComGameState NewGameState);

/// <summary>
/// Resubmits input contexts of a replay history to enusre it regenerates the same game states for verification.
/// </summary>
native function bool ValidateHistory();

DefaultProperties
{	
	CurrentIndex=-1
	NextObjectID=1 //0 and less is reserved to indicate a NULL or unset ObjectID
	HistoryStartIndex=0
}
