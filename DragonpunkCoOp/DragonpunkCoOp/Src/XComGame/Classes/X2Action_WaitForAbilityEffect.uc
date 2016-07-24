//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_WaitForAbilityEffect extends X2Action;

var bool bWaitingForActionMessage;

var privatewrite bool bAbilityEffectReceived;
var private bool bSkip;

function Init(const out VisualizationTrack InTrack)
{
	local X2Action FirstWait;

	super.Init(InTrack);

	if( !bWaitingForActionMessage )
	{
		//There can only be one wait of this type per track. Skip all but the first.
		if(`XCOMVISUALIZATIONMGR.TrackHasActionOfType(InTrack, class'X2Action_WaitForAbilityEffect', FirstWait))
		{
			bSkip = FirstWait != self;
		}
	}
}

function HandleTrackMessage()
{
	bAbilityEffectReceived = true;
}

function ChangeTimeoutLength( float newTimeout )
{
	TimeoutSeconds = newTimeout;
}

function bool IsTimedOut()
{
	return ExecutingTime >= TimeoutSeconds && TimeoutSeconds > 0.0f;
}

function bool CheckInterrupted()
{
	return VisualizationBlockContext.InterruptionStatus == eInterruptionStatus_Interrupt;
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
	bAbilityEffectReceived = true;
}

//------------------------------------------------------------------------------------------------

simulated state Executing
{
Begin:
	while(!bSkip && !bAbilityEffectReceived && !IsTimedOut())
	{
		sleep(0.0f);
	}

	CompleteAction();
}

DefaultProperties
{
	TimeoutSeconds = 15.0;
}
