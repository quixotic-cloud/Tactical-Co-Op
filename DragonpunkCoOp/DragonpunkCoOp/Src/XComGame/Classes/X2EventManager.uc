//---------------------------------------------------------------------------------------
//  FILE:    X2EventManager.uc
//  AUTHOR:  Dan Kaplan
//	DATE:	 5/22/2014
//           
//  This class provides a generic interface for registration for notification of game events 
//	  and hooks for receiving and dispatching those game events.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2EventManager extends Object
	native(Core)
	dependson(XComGameState);

/////////////////////////////////////////////////////////////////////////////////////////
// Event Listeners

struct native EventObjectRef
{
	// the hard ref to the object
	var private{private,mutable} transient Object	Object;

	// If the object is a StateObject, this ID will be used as the lookup to the most 
	// current version of this object in the history whenever this ref is used
	var private{private} StateObjectReference		StateObjectID;

	structcpptext
	{
		FEventObjectRef()
		{
			appMemzero(this, sizeof(FEventObjectRef));
		}
		FEventObjectRef(EEventParm)
		{
			appMemzero(this, sizeof(FEventObjectRef));
		}

		// gets the hard ref to the object represented by this ref
		UObject* GetObject() const;

		// returns a positive non-zero value if the object has an associated state
		INT GetStateObjectId() const;

		// Set this object reference
		void InitializeFromObject( UObject* Obj );

		// comparison against a UObject
		UBOOL operator==( const UObject* Obj ) const;

		// check if this Object Ref always evaluates to NULL
		UBOOL IsAlwaysNULL() const;

		/** Serializer. */
		friend FArchive& operator<<(FArchive& Ar, FEventObjectRef& ObjectRef);
	}
};

struct native EventListener
{
	// The unique ID of the event this listener is interested in receiving notification for.
	var Name							EventID;

	// The object that is registered for this event.
	var EventObjectRef					SourceObject;

	// If non-null, this is the object that will be used to pre-filter the event
	var EventObjectRef					PreFilterObject;

	// When this listener should be notified about the event.
	var EventListenerDeferral			Deferral;

	// The priority given to this event listener (relative to all other listeners for the same event).  
	// Determines the order in which event listeners are processed.
	var int								Priority;

	// If true, this Event Listener needs to persist across Tactical-Strategy transitions.
	var bool							bPersistent;

	// The delegate to be called when this event is activated.
	var const delegate<OnEventDelegate> EventDelegate;

	structcpptext
	{
		FEventListener()
		{
			appMemzero(this, sizeof(FEventListener));
		}
		FEventListener(EEventParm)
		{
			appMemzero(this, sizeof(FEventListener));
		}

		UBOOL operator==(const FEventListener& Other) const
		{
			return ( (EventID == Other.EventID) && (SourceObject == Other.SourceObject.GetObject()) );
		}

		// Process the EventDelgate for this event
		EventListenerReturn ProcessEventDelegate( FEventObjectRef& EventData, FEventObjectRef& EventSource, const UXComGameState* GameState );

		// Helper to perform validation of a specified event source against the PreFilter configured on this EventListener
		UBOOL ValidatesForPreFilter( const UObject* EventSource ) const;

		/** Serializer. */
		friend FArchive& operator<<(FArchive& Ar, FEventListener*& EventListener)
		{
			if( Ar.IsLoading() )
			{
				EventListener = new FEventListener;
			}

			check( EventListener != NULL );
			Ar << EventListener->EventID 
				<< EventListener->SourceObject 
				<< EventListener->PreFilterObject 
				<< EventListener->Deferral 
				<< EventListener->Priority 
				<< EventListener->EventDelegate;

			if( Ar.LicenseeVer() >= FXS_VER_EVENTLISTENER_PERSISTENCE )
			{
				UBOOL Temp = EventListener->bPersistent;
				Ar << Temp;
				EventListener->bPersistent = Temp;
			}

			return Ar;
		}
	}
};

// The master set of all listeners, keyed by event type.
var private native MultiMap_Mirror   AllEventListeners{TMultiMap<FName, FEventListener*>};

/////////////////////////////////////////////////////////////////////////////////////////
// Pending Events

struct native PendingEvent
{
	// The unique ID of the event.
	var Name							EventID;

	// The data that should be passed back to any listeners for this event.
	var EventObjectRef					EventData;

	// The source object that is being affected by this event
	var EventObjectRef					EventSource;

	// The (priority sorted) list of all event listeners who were registered for this event when it was triggered.
	var array<EventListener>			EventListeners;

	// The GameState that -if not NULL- is required for this event to trigger when processing this as a deferred event.
	var XComGameState					EventGameState;

	structcpptext
	{
		FPendingEvent()
		{
			appMemzero(this, sizeof(FPendingEvent));
		}
		FPendingEvent(EEventParm)
		{
			appMemzero(this, sizeof(FPendingEvent));
		}

		// Return true if any event listener returned ELR_InterruptEvent or ELR_InterruptEventAndListeners
		UBOOL ProcessPendingEvent( const UXComGameState* GameState );
		void AddEventListener( const FEventListener& EventListener );

		// return true if this event can be processed for the specified GameState.  Will be false only if both are different and non-NULL
		UBOOL CanProcessForGameState( const UXComGameState* GameState ) const;
	}
};

struct native PendingEventWindow
{
	// The set of all pending events which need to be processed within this timing window.
	var array<PendingEvent>				PendingEvents;

	structcpptext
	{
		FPendingEventWindow()
		{
			appMemzero(this, sizeof(FPendingEventWindow));
		}
		FPendingEventWindow(EEventParm)
		{
			appMemzero(this, sizeof(FPendingEventWindow));
		}

		// Add a new Pending event to this event window
		void AddPendingEvent( const FPendingEvent& PendingEvent );

		// Process all events within this event window.  Return TRUE if any of them return an "Event Interrupt"
		UBOOL ProcessPendingEvents( const UXComGameState* GameState );

		// Removes all PendingEvents which correspond to the specified GameState without processing them
		void RemovePendingEventsForGameState( const UXComGameState& GameState );
	}
};

// All timing windows, containing all of the events which still need to be processed.
var private{private} PendingEventWindow PendingEventWindows[EventListenerDeferral.EnumCount];

var private{private} bool bIsLocked;


/////////////////////////////////////////////////////////////////////////////////////////
// The Event Manager

native static function X2EventManager GetEventManager();


/////////////////////////////////////////////////////////////////////////////////////////
// The master Event Delegate prototype

delegate EventListenerReturn OnEventDelegate(Object EventData, Object EventSource, XComGameState GameState, Name EventID);


/////////////////////////////////////////////////////////////////////////////////////////
// Event Listener Registration

native function RegisterForEvent( ref Object SourceObj, Name EventID, delegate<OnEventDelegate> NewDelegate, optional EventListenerDeferral Deferral=ELD_Immediate, optional int Priority=50, optional Object PreFilterObject, optional bool bPersistent );
native function UnRegisterFromEvent(const ref Object SourceObj, Name EventID);
native function UnRegisterFromAllEvents(const ref Object SourceObj);


/////////////////////////////////////////////////////////////////////////////////////////
// Triggered Event Processing

/**
 *  Triggers the specified event, queueing up all listeners for this event to be processed 
 *  during their specified Event Window.  Also, immediately triggers the ELD_Immediate event window.
 *
 *  @param EventID is the handle for the type of event that has been triggered.
 *  @param EventData is the optional object containing the data relevant to this event's triggered state.
 *  @param EventSource is the optional object to be considered the source of this event (used for pre-filtering).
 *
 *  @return TRUE iff any event listener with ELD_Immediate specified for this event executes and causes an event interrupt
 */
native function bool TriggerEvent( Name EventID, optional Object EventData, optional Object EventSource, optional XComGameState EventGameState );

/**
 *  Triggers the ELD_OnStateSubmitted event window.
 *
 *  @return TRUE iff any event listener with ELD_OnStateSubmitted specified for any currently queued event executes and causes an event interrupt
 */
native function bool OnGameStateSubmitted( const ref XComGameState GameState );

/**
 *  Triggers the ELD_PreStateSubmitted event window. Similar to ELD_OnStateSubmitted but fired immediately prior to the game state being added to the history.
 *  Listeners may make last minute additions to the game state at this time ( no new events or interrupts may be added )
 *
 *  @return TRUE iff any event listener with ELD_PreStateSubmitted specified for any currently queued event executes and causes an event interrupt
 */
native function bool PreGameStateSubmitted( const ref XComGameState GameState );


/**
*  Triggers the ELD_OnVisualizationBlockStarted event window.
*
*  @return TRUE iff any event listener with ELD_OnVisualizationBlockStarted specified for any currently queued event executes and causes an event interrupt
*/
native function bool OnVisualizationBlockStarted(const ref XComGameState GameState);

/**
*  Triggers the ELD_OnVisualizationBlockCompleted event window.
*
*  @return TRUE iff any event listener with ELD_OnVisualizationBlockCompleted specified for any currently queued event executes and causes an event interrupt
*/
native function bool OnVisualizationBlockCompleted(const ref XComGameState GameState);

/////////////////////////////////////////////////////////////////////////////////////////
// Accessors

/**
 *  Determines if there are any listeners currently registered to receive notification about the specified event.  
 *  This version of AnyListenersForEvent considers pre-filtering to determine if any of the event listeners who 
 *  are registered for the event could possibly pass the pre-filter requirements for the specified EventSource.
 *
 *  @param EventID is the handle for the type of event that is being queried.
 *  @param EventSource is the object to use to conduct the pre-filter check
 *
 *  @return TRUE iff any event listener is currently registered for this event and will pass the pre-filter 
 *	  check against the EventSource
 */
native function bool AnyListenersForEvent( Name EventID, optional const Object EventSource );

/**
 *  Determines if there are any listeners currently registered to receive notification about the specified event; 
 *  if so, this function passes back the list of pre-filter objects being used by those listeners 
 *
 *  @param EventID is the handle for the type of event that is being queried.
 *  @out param PreFilterObjects is the list of Objects used as prefilters for all listeners for this event
 *
 *  @return TRUE iff any event listener is currently registered for this event and specified a PreFilterObject
 */
native function bool GetPreFiltersForEvent( Name EventID, out array<Object> PreFilterObjects );

// Clear all pending events and listeners
native final function Clear();

// Reset this EventManager to defaults, clearing all pending events and listeners
native final function ResetToDefaults(bool ResetPersistentEvents);

// Clears out the associated object for all delegates
native function ResetDelegates();

// Merges the contents of supplied Event Manager into this Manager
native function MergeEventManager( X2EventManager InEventManager );

/**
*	This method examines the current state of the event manager and makes sure that all the delegates and objects within
*	are valid. If invalid event listeners are found, the method returns false and deletes the bad listeners. This will mainly
*	happen when loading saved games that were produced from a different version of the game.
*
*/
native function bool ValidateEventManager(string AdditionalInfo);

/// <summary>
/// IterateEventByName provides a foreach iterator by interfacing with the AllEventListeners multimap.
/// </summary>
/// <param name="LookupName">[out] 'Key' of the multimap, the lookup name for the current listener.</param>
/// <param name="Listener">[out] 'Value' of the multimap, the actual listener information.</param>
/// <param name="SearchName">[optional] If empty '', then will search for all key/values, otherwise LookupName will always equal SearchName.</param>
native final iterator function IterateEventByName( out name LookupName, out EventListener Listener, optional name SearchName='' );


/////////////////////////////////////////////////////////////////////////////////////////
// Debugging output
native function string AllEventListenersToString( optional name EventID='', optional string DelegateObjectClassType="", optional int SourceObjectFilter=-1, optional int PreFilterObject=-1 ); // -1 means any.
native function string EventListenerToString( const out EventListener InEventListener, optional bool bShortDesc=false );
native function string PendingEventToString( const out PendingEvent InPendingEvent, optional name EventID='', optional string DelegateObjectClassType="", optional int SourceObjectFilter=-1, optional int PreFilterObject=-1 ); // -1 means any.
native function string PendingEventWindowToString( const out PendingEventWindow InPendingEventWindow );
native function string EventManagerDebugString( optional name EventID='', optional string DelegateObjectClassType="", optional int SourceObjectFilter=-1, optional int PreFilterObject=-1 ); // -1 means any.


/////////////////////////////////////////////////////////////////////////////////////////
// cpptext

cpptext
{
public: 
	void Serialize(FArchive& Ar);

	// When a GameState is removed rather than submitted, the event manager needs to clean up all 
	// pending events that are waiting on that GameState's submission
	void RemovePendingEventsForGameState( const UXComGameState& GameState );

	// When a gamestate is completely obliterated, the event manager needs to clean up all event listeners 
	// that existed solely within the obliterated game state
	void OnGameStateObliterated(const UXComGameState& GameState);
	
	// When a gamestate object is purged from a pending game state, the event manager needs to clean up all event listeners 
	// that existed solely within that game state
	void OnPurgedGameStateObject(INT PurgedStateObjectID);

	void LockEventManager();

	void UnLockEventManager();

	// When a game state is submitted to the history, clean up any state objects in that game state that were marked as bRemoved
	void CleanupRemovedGameStateObjectListeners(const UXComGameState& GameState);

private:
	// helper function to find the specific listener corresponding to the source object and eventID pair
	FEventListener* FindExistingEventListener( const UObject& SourceObject, const FName& EventID );

	// helper function to trigger a single (specified) event window
	UBOOL TriggerEventWindow( EventListenerDeferral Deferral, const UXComGameState* GameState );

	// Helper function to remove all event listeners with the specified ObjectID
	void RemoveAllListenersWithID(INT ObjectID);
};

/////////////////////////////////////////////////////////////////////////////////////////
// defprops

defaultproperties
{

}