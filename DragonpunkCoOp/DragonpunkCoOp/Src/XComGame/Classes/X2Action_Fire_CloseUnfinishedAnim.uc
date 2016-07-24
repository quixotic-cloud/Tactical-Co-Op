//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Fire_CloseUnfinishedAnim extends X2Action_Fire;

var bool bNotifyTargets;
var private bool bAnimTargetNotifyReceived;

event OnAnimNotify(AnimNotify ReceiveNotify)
{
	local XComAnimNotify_NotifyTarget NotifyTarget;

	super.OnAnimNotify(ReceiveNotify);

	NotifyTarget = XComAnimNotify_NotifyTarget(ReceiveNotify);
	if(NotifyTarget != none)
	{
		bAnimTargetNotifyReceived = true;
	}
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

//------------------------------------------------------------------------------------------------

simulated state Executing
{
Begin:
	while(!bAnimTargetNotifyReceived && !IsTimedOut())
	{
		sleep(0.0f);
	}

	//Failure case handling! We failed to notify our targets that damage was done. Notify them now.
	SetTargetUnitDiscState();

	//reset to false, only during firing would the projectile be able to overwrite aim
	UnitPawn.ProjectileOverwriteAim = false;

	if( bNotifyTargets )
	{
		NotifyTargetsAbilityApplied();
	}

	CompleteAction();
}

DefaultProperties
{
	TimeoutSeconds = 10.0;
}