//---------------------------------------------------------------------------------------
//  FILE:    XComGameState.uc
//  AUTHOR:  Ryan McFall  --  10/9/2013
//  PURPOSE: This object stores the board/actor state. It may be a 'full state' in which
//           every state object has an object in GameStates, or a 'delta state' where
//           the only objects in GameStates are objects that have been changed as of this
//           XComGameState.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState extends Object native(Core);

enum EInterruptionStatus
{
	eInterruptionStatus_None,
	eInterruptionStatus_Interrupt,
	eInterruptionStatus_Resume,	
};

enum EventListenerDeferral
{
	ELD_Immediate,						// The Listener will be notified in-line (no deferral)
	ELD_OnStateSubmitted,				// The Listener will be notified after the associated game state is processed
	ELD_OnVisualizationBlockCompleted,	// The Listener will be notified after the associated visualization block is completed
	ELD_PreStateSubmitted,				// The Listener will be notified immediately prior to the associated game state being added to the history
	ELD_OnVisualizationBlockStarted,	// The Listener will be notified when the associated visualization block begins execution
};

enum EventListenerReturn
{
	ELR_NoInterrupt,				// any subsequent event listeners WILL be processed; if ELD_Immediate, the event WILL NOT be interrupted
	ELR_InterruptEvent,				// any subsequent event listeners WILL be processed; if ELD_Immediate, the event WILL be interrupted
	ELR_InterruptListeners,			// any subsequent event listeners WILL NOT be processed; if ELD_Immediate, the event WILL NOT be interrupted
	ELR_InterruptEventAndListeners,	// any subsequent event listeners WILL NOT be processed; if ELD_Immediate, the event WILL be interrupted
};

enum EGameStateReturnType
{
	eReturnType_Copy,
	eReturnType_Reference,
};


//Use this structure when referencing a state object (XComGameState_<SomeObjectType>). The purpose of this structure instead of just using INTs is to allow for 
//debugger integration
struct native StateObjectReference
{
	var int ObjectID;

structcpptext
{
	FStateObjectReference()
	{
		appMemzero(this, sizeof(FStateObjectReference));
	}
	FStateObjectReference(EEventParm)
	{
		appMemzero(this, sizeof(FStateObjectReference));
	}
	explicit FStateObjectReference(INT InObjectID) : ObjectID(InObjectID)
	{	
	}

	FORCEINLINE UBOOL operator==(const FStateObjectReference &Other) const
	{
		return  ObjectID == Other.ObjectID;
	}

	FString ToString() const;

	FORCEINLINE UBOOL IsValidRef() const { return (ObjectID > 0); }

	/** Serializer. */
	friend FArchive& operator<<(FArchive& Ar, FStateObjectReference& ObjectRef)
	{
		Ar << ObjectRef.ObjectID;
		return Ar;
	}

	friend inline DWORD GetTypeHash(const FStateObjectReference &Reference)
	{
		return Reference.ObjectID;
	}
}
};

cpptext
{
	void Serialize(FArchive& Ar);
	void WriteToByteArray(TArray<BYTE>& InData);    //Serialization support
	void ReadFromByteArray(TArray<BYTE>& InData);   //Serialization support
	INT  ResetObjectIDMap();                        //Helper method for fixing up the ObjectID table after serialization	
	class UXComGameState_BaseObject* InternalGetGameState(INT Index, bool bForceRef); //Provides a wrapper to access GameStates - contains logic for returning a reference or read-only copy.
	class UXComGameState_BaseObject* NativeGetGameStateForObjectID(INT ObjectID); //Returns a reference to the XComGameStateObject associated with ObjectID

	template <class type_t>
	FORCEINLINE type_t* CreateState( INT ObjectID = -1 )
	{
		return CastChecked<type_t>( CreateStateObject( type_t::StaticClass( ), ObjectID ) );
	}
}

var() private array<XComGameState_BaseObject> PendingGameStates;        //Following a call to CreateStateObject, the new XComGameState_BaseObject is added to this list for validation on 
																		//subsequent AddStateObject calls.

var() private array<XComGameState_BaseObject> GameStates;               //State objects for all game pieces/actors. For a delta, may contain very few objects with disparate ObjectIDs
var() private XComGameStateContext StateChangeContext;                  //Context that generated this game state and results meta data + interface for visualization
var() privatewrite int  HistoryIndex;                                   //The index in the History array that refers to this game state. -1 indicates this state is not part of the history.
var() privatewrite bool bIsDelta;                                       //Indicates whether this game state is a delta from the previous game state, or a complete state
var() privatewrite bool bReadOnly;                                      //Similar to the flag of the same name in XComGameState_BaseObject, if true it indicates that this object is a read-only copy
var() privatewrite int  TickAddedToHistory;                             //Tracks which engine tick this game state was added to the history in. Provides time/precedence for game states that can be useful when debugging.
var() privatewrite init string TimeStamp;								//Records the value of appSystemTimeString at the time this game state was added to the history

//This map facilitates O(1) cost when accessing GameStates by ObjectID.
var private native Map_Mirror ObjectIDToGameStatesIndex      {TMap<INT, INT>};


/// <summary>
/// Instantiates a new state object of the specified type and adds it to the PendingGameStates list in this object for validation / book-keeping.
/// </summary>
/// <param name="StateClass">The class of state object to create. If ObjectID is specified, then this argument is overridden by the type of the object represented by ObjectID</param>
/// <param name="ObjectID">An optional parameter specifying that the state object being created is an update to a state object that already exists.</param>
native final function XComGameState_BaseObject CreateStateObject(class StateClass, optional int ObjectID = -1, optional int HACK_HistoryIndex = -1);

/// <summary>
/// The passed in state object is added to GameStates.
/// </summary>
/// <param name="StateObject">The state object to add to this game state. MUST have been created by a corresponding CreateStateObject</param>
native final function XComGameState_BaseObject AddStateObject(XComGameState_BaseObject StateObject);

/// <summary>
/// Purges the game state object with the specified ObjectID from the GameStates array and associated caching structures.
/// NOTE: This may only be done for state objects that are not yet part of the history!
/// </summary>
/// <param name="ObjectID">Unique indentifier associated with the object state to be purged</param>
/// <param name="FullHierarchy">If true, also deletes all associated component objects</param>
native final function PurgeGameStateForObjectID(int ObjectID, optional bool FullHierarchy = true);

/// <summary>
/// This method is intended to be the typical path for 'removing' a state object from the history. A new state is created, and the 'bRemoved' flag is set on the state object
/// indicating that it should no longer appear in lists of 'current' state objects. The state object will still show up if history frames are examined prior to its removal.
/// </summary>
/// <param name="ObjectID">Unique indentifier associated with the object state to be marked as removed</param>
native final function RemoveStateObject(int ObjectID);

/// <summary>
/// IterateByClassType provides a foreach iterator that provides an interface for looping through the game state objects of a given class. If this XComGameState is a start
/// state or not in the history, then GameStateObject is a reference. Otherwise it is a copy (read only).
/// </summary>
/// <param name="ObjectID">Unique indentifier associated with the object state requested</param>
native final iterator function IterateByClassType( class<object> SearchClass, out object GameStateObject, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference );

/// <summary>
/// Returns a copy or reference of the state related to the specified object ID. If no state exists the function will return none. If this XComGameState is a start
/// state or not in the history, then GameStateObject is a reference. Otherwise it is a copy (read only).
/// </summary>
/// <param name="ObjectID">Unique indentifier associated with the object state requested</param>
native final function XComGameState_BaseObject GetGameStateForObjectID(int ObjectID, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference);

/// <summary>
/// Returns a copy or reference of the state for the given component class on the specified objectid. For example, if a 
/// game object has both a destructible and an interactive object state in it's hierarchy, this function will return the specified
/// type of component regardless of which of the two object ids is passed in.
/// </summary>
/// <param name="ObjectID">Unique indentifier associated with the object state requested</param>
/// <param name="ComponentClass">Unreal class of the component state you are looking for.</param>
native final function XComGameState_BaseObject GetGameStateComponentForObjectID(int ObjectID, class<object> ComponentClass, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference);

/// <summary>
/// Returns a copy or reference of the XComGameState that comes immediately before this one in the history.
/// </summary>
/// <param name="ObjectID">Unique indentifier associated with the object state requested</param>
native final function XComGameState GetPreviousGameState(optional EGameStateReturnType DesiredReturnType=eReturnType_Reference, optional bool bDelta);

/// <summary>
/// GetNumGameStateObjects returns the size of GameStates
/// </summary>
native final function int GetNumGameStateObjects();

/// <summary>
/// Used in combination with GetNumGameStateObjects, GetGameStateForObjectIndex provides an alternate interface to get GameState objects
/// by their index in the GameStates array. Reference / Copy rules operate like GetGameStateForObjectID.
/// </summary>
/// <param name="GameStateArrayIndex">Index into GameStates from which to retrieve the GameState object</param>
native final function XComGameState_BaseObject GetGameStateForObjectIndex(int GameStateArrayIndex, optional EGameStateReturnType DesiredReturnType=eReturnType_Reference);

/// <summary>
/// This function will update the passed-in TargetGameState with this object's object states.
/// </summary>
/// <param name="TargetGameState">The game state that should be modified by this state</param>
/// <param name="bObjectsOnly">If true, only the BaseObjects will be applied to the base state, ignoring context information.</param>
native final function CopyGameState(XComGameState TargetGameState, optional bool bObjectsOnly=false);

/// <summary>
/// If we are a delta game state, this function will update the passed-in BaseGameState with this object's locally changed object states. Will do 
/// nothing with a non-delta state.
/// </summary>
/// <param name="BaseGameState">The game state that should be modified by this state</param>
/// <param name="bObjectsOnly">If true, only the BaseObjects will be applied to the base state, ignoring context information.</param>
native final function ApplyDelta(XComGameState BaseGameState, optional bool bObjectsOnly=false);

/// <summary>
/// Returns a reference to the game state meta data object associated with this XComGameState
/// </summary>
native final function XComGameStateContext GetContext();

native function bool Validate();

/// <summary>
/// Returns a string representation of this object.
/// </summary>
native function string ToString() const;

/// ********* Helper Methods for serializing X-Com game state from script *********
static native final function WriteToByteArray(XComGameState WriteState, out array<byte> WriteToArray);
static native final function ReadFromByteArray(XComGameState OutReadState, out array<byte> ReadFromArray);

DefaultProperties
{	
	HistoryIndex=-1
	bIsDelta=false
}
