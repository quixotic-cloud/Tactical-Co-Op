//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_BaseObject.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: Root class for all game state object classes
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_BaseObject extends Object native(Core);

const PRE_LINKED_LIST_OBJECT_HISTORY = -2; // sentinel value to allow us to detect and support saves that were made before PreviousHistoryFrameIndex was added

var() privatewrite int ObjectID;    //Unique handle by which this object is accessed by systems external to the XComGameState system
var() private int PreviousHistoryFrameIndex; // Linked list to the history frame of the direct ancestor of this object in the history.  -1 if no previous state

var() privatewrite bool bReadOnly;  //This flag is set when game state objects are accessed and indicates whether this object is a copy (read only) or a reference (can modify an XComGameState)
var() privatewrite bool bRemoved;   //Set true by calls to XComGameState::RemoveStateObject() - 
var() bool bInPlay;	// Set to true following a BeginTacticalPlay() call and set to false after a EndTacticalPlay() call

var() privatewrite int OwningObjectId; // Parent object state component of this base object
var() privatewrite array<int> ComponentObjectIds; // Child object state components of this base object

var() privatewrite X2GameRulesetVisibilityInterface VisibilityInterface;	// cached interface to speed up ai, especially, by eliminating the need for InterfaceCasts
var() bool bRequiresVisibilityUpdate;// this flag must be updated by state object modifying code to indicate that the state change represented by this object could affect this 
									 // object's visibility relationships

var() const bool bSingletonStateType;// this type of gamestate should be treated as a singleton in the history.  When creating delta gamestates, state creations will return the existing state object for modification.

/// <summary>
/// Returns the name of the template associated with this object, if any.
/// </summary>
function Name GetMyTemplateName()
{
	return '';
}

/// <summary>
/// Called immediately prior to loading, this method is called on each state object so that its resources can be ready when the map completes loading. Request resources
/// should 
/// </summary>
event RequestResources(out array<string> ArchetypesToLoad);

/// <summary>
/// Returns the XComGameState object that this object belongs to, if any.
/// </summary>
native final function XComGameState GetParentGameState() const;

/// <summary>
/// Returns the root of the state object hierarchy that this object belongs to.
/// </summary>
native final function XComGameState_BaseObject GetRootObject() const;

/// <summary>
/// Sets the specified state object to be a component object of this object.
/// </summary>
native final function AddComponentObject(XComGameState_BaseObject ComponentObject); 

/// <summary>
/// Removes the specified state object from this objects component list
/// </summary>
native final function RemoveComponentObject(XComGameState_BaseObject ComponentObject); 

/// <summary>
/// Finds the component of the specified class. If FullHierarchy is true, will search all related components and parents
/// that are connected to this object.
/// </summary>
native final function XComGameState_BaseObject FindComponentObject(class<XComGameState_BaseObject> ComponentClass, optional bool FullHierarchy = true) const; 

/// <summary>
/// Returns all component game states that are part of this object. If FullHierarchy is true, will search all related components and parents
/// that are connected to this object.
/// </summary>
native final function GetAllComponentObjects(out array<XComGameState_BaseObject> Components, optional bool FullHierarchy = true) const;

/// <summary>
/// Returns a StateObjectReference struct copy that should be used when creating a reference to game state objects.
/// </summary>
native final function StateObjectReference GetReference() const;

/// <summary>
/// Returns a reference to the actor that represents this game state object. Uses XComGameStateHistory.GetVisualizer internally.
/// </summary>
native final function Actor GetVisualizer() const;

/// <summary>
/// Returns a string representation of this object.
/// </summary>
native function string ToString(optional bool bAllFields);

/// <summary>
/// Returns a string representation of StateObjectReference.
/// </summary>
static native final function string StateObjectReference_ToString(const out StateObjectReference kSOR) const;

/// <summary>
/// This method is designed to be overridden and to support session-specific state variables. For instance: Units track which player is controlling them
/// during a tactical battle. This information should be cleared / reset when starting a new tactical battle so Unit state objects override this method 
/// to perform that action
/// </summary>
function OnBeginTacticalPlay();
final event BeginTacticalPlay()
{
	if( !bInPlay && `TACTICALRULES != none && `TACTICALRULES.TacticalGameIsInPlay() )
	{
		if (!`ONLINEEVENTMGR.bInitiateValidationAfterLoad)
		{
			//Validation does not require tactical play event listeners.
			OnBeginTacticalPlay();
		}
		bInPlay = true;
	}
}

/// <summary>
/// This method is designed to be overridden and to support session-specific state variables performing any neccessary cleanup at the end of a tactical game
/// </summary>
function OnEndTacticalPlay();
final event EndTacticalPlay()
{
	if( bInPlay && !`TACTICALRULES.TacticalGameIsInPlay() )
	{
		OnEndTacticalPlay();
		bInPlay = false;
	}
}

event OnStateSubmitted();

final function bool IsInPlay()
{
	return bInPlay;
}

native function bool CanEarnXp() const;

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

/// <summary>
///	This method is designed to be overridden by types that set the bSingletonStateType to true.
/// There is an optimization to the saveing process that keeps a snapshot of the history every time the game saves.
/// This method is to update the snapshot instance of the singleton gamestate with the values from current version of the history.
/// </summary>
native function SingletonCopyForHistoryDiffDuplicate( XComGameState_BaseObject NewState );

cpptext
{
	UBOOL IsRelevantToGetAll();
	IX2GameRulesetVisibilityInterface *GetVisibilityInterface() const;
	
	virtual void PostLoad();

	void SyncObjectId(const UXComGameState_BaseObject* Other);

private:
	const UXComGameState_BaseObject* FindComponentObjectRecursiveInternal(UClass* ComponentClass, INT HistoryIndex) const;
	void GetAllComponentObjectsInternal(TArray<UXComGameState_BaseObject*>& Components, INT HistoryIndex, UBOOL Recursive) const;
}

DefaultProperties
{
	OwningObjectId=-1
	PreviousHistoryFrameIndex=PRE_LINKED_LIST_OBJECT_HISTORY
	bSingletonStateType=false
}
