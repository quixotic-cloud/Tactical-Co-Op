//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_WaitForDestructibleActorActionTrigger extends X2Action;

var private X2EventManager EventManager;
var private bool bTriggered;
var private class<XComDestructibleActor_Action> WaitForActionClass;
var private int WaitForDestructibleActorObjectID;

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

function SetTriggerParameters(class<XComDestructibleActor_Action> WaitForClass, int InWaitForDestructibleActorObjectID)
{
	local Object ThisObj;

	WaitForActionClass = WaitForClass;
	WaitForDestructibleActorObjectID = InWaitForDestructibleActorObjectID;

	//Register for the event here, to cover the situation where the event we are waiting on is triggered in the same frame
	//as init
	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'DestructibleActorActionTrigger', OnHandleActionTrigger, ELD_Immediate);
}

function EventListenerReturn OnHandleActionTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{		
	local XComDestructibleActor Destructible;
	local XComDestructibleActor_Action TriggeredAction;

	TriggeredAction = XComDestructibleActor_Action(EventData);
	Destructible = XComDestructibleActor(EventSource);
	if (TriggeredAction != none && TriggeredAction.Class == WaitForActionClass &&
		Destructible != none && Destructible.ObjectID == WaitForDestructibleActorObjectID)
	{
		bTriggered = true;
	}	
	
	return ELR_NoInterrupt;
}

event bool BlocksAbilityActivation()
{
	return false;
}

function bool CheckInterrupted()
{	
	return true;
}

function bool IsWaitingOnActionTrigger()
{
	return true;
}

function TriggerWaitCondition()
{
	bTriggered = true;
}

/// <summary>
/// X2Actions call this at the conclusion of their behavior to signal to the visualization mgr that they are done
/// </summary>
function CompleteAction()
{
	local Object ThisObj;

	super.CompleteAction();

	ThisObj = self;
	EventManager.UnRegisterFromAllEvents(ThisObj);
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{	
Begin:
	while(!bTriggered)
	{
		sleep(0.0);
	}

	CompleteAction();
}

defaultproperties
{
}

