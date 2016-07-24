class X2Effect_PersistentTraversalChange extends X2Effect_Persistent;

var array<TraversalChange>  aTraversalChanges;

simulated function AddTraversalChange(ETraversalType Traversal, bool Allowed)
{
	local TraversalChange Change;

	Change.Traversal = Traversal;
	Change.bAllowed = Allowed;
	aTraversalChanges.AddItem(Change);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		UnitState.ApplyTraversalChanges(self);
	}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit kOldTargetUnitState, kNewTargetUnitState;	

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	kOldTargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( kOldTargetUnitState != None )
	{
		kNewTargetUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', kOldTargetUnitState.ObjectID));
		kNewTargetUnitState.UnapplyTraversalChanges(self);
		NewGameState.AddStateObject(kNewTargetUnitState);
	}
}