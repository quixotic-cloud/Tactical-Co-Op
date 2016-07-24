//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_WaitForWorldDamage extends X2Action;

var private X2EventManager EventManager;
var private bool bTriggered;
var bool bIgnoreIfPriorWaitFound; //If this is set, the X2Action_WaitForWorldDamage will check its track for prior waits, and will immediately complete if any are found.

function Init(const out VisualizationTrack InTrack)
{
	local Object ThisObj;
	local int i;

	super.Init(InTrack);

	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.RegisterForEvent(ThisObj, 'HandleDestructionVisuals', OnHandleDestructionVisuals, ELD_Immediate);

	if (bIgnoreIfPriorWaitFound)
	{
		for (i = 0; i < InTrack.TrackActions.Length; i++)
		{
			if (InTrack.TrackActions[i] == self)
				break;

			if (InTrack.TrackActions[i].IsA('X2Action_WaitForAbilityEffect') || InTrack.TrackActions[i].IsA('X2Action_WaitForWorldDamage'))
			{
				bTriggered = true;
				break;
			}
		}
	}
}

function EventListenerReturn OnHandleDestructionVisuals(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{	
	bTriggered = true;
	return ELR_NoInterrupt;
}

event bool BlocksAbilityActivation()
{
	return false;
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

function bool CheckInterrupted()
{
	return VisualizationBlockContext.InterruptionStatus == eInterruptionStatus_Interrupt;
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
	bIgnoreIfPriorWaitFound=false
}

