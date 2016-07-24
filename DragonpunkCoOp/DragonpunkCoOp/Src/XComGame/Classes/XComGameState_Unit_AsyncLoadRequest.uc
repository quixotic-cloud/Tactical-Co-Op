
class XComGameState_Unit_AsyncLoadRequest extends AsynchronousLoadRequest;


var string ArchetypeName;

var Actor PawnOwner;
var vector UseLocation;
var rotator UseRotation;
var bool bForceMenuState;

var bool bIsComplete;

var XComUnitPawn UnitPawnArchetype;

var delegate<OnUnitPawnCreated> PawnCreatedCallback;

var delegate<OnAsyncLoadComplete_UnitCallbackDelegate> OnAsyncLoadComplete_UnitCallback;

delegate OnAsyncLoadComplete_UnitCallbackDelegate(XComGameState_Unit_AsyncLoadRequest asyncRequest);
delegate OnUnitPawnCreated(XComGameState_Unit Unit);

function OnObjectLoaded(Object LoadedObject)
{
    UnitPawnArchetype = XComUnitPawn( LoadedObject);

    OnAsyncLoadComplete_UnitCallback(self);
}

defaultProperties
{
    bForceMenuState = false;
    bIsComplete = false;
}