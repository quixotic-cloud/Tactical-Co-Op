class X2Effect_FaceMultiRoundTarget extends X2Effect_Persistent;

var name TriggerEventName;      // Used to identify the event that this effect will trigger

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit AimingUnitState;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	AimingUnitState = XComGameState_Unit(kNewTargetState);

	// Record the Target Unit as the multi turn target
	AimingUnitState.m_MultiTurnTargetRef = ApplyEffectParameters.AbilityInputContext.PrimaryTarget;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit AimingUnitState;
	local StateObjectReference EmptyStateObjectReference;
	
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	AimingUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( AimingUnitState != none )
	{
		AimingUnitState = XComGameState_Unit(NewGameState.CreateStateObject(AimingUnitState.Class, AimingUnitState.ObjectID));

		// Remove the multi turn target
		AimingUnitState.m_MultiTurnTargetRef = EmptyStateObjectReference;
		NewGameState.AddStateObject(AimingUnitState);
	}
}

defaultproperties
{
	EffectName="FaceMultiRoundTargetEffect"
}
