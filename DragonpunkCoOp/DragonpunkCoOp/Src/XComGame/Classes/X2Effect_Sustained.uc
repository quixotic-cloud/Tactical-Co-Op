//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Sustained extends X2Effect_Persistent;

var name SustainedAbilityName;
var array<name> EffectsToRemoveFromSource;
var array<name> EffectsToRemoveFromTarget;
var array<name> RegisterAdditionalEventsLikeImpair;

// If the sustained effect's source unit takes more damage in a full turn than this 
// amount, then the sustain is broken
var int FragileAmount;

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_Persistent PersistentEffect;
	local XComGameState_Unit SustainedEffectSourceUnit, SustainedEffectTargetUnit;
	local XComGameStateHistory History;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	History = `XCOMHISTORY;
	// Remove the associated source effects
	if (EffectsToRemoveFromSource.Length > 0)
	{
		SustainedEffectSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		foreach SustainedEffectSourceUnit.AffectedByEffects(EffectRef)
		{
			// Loop over all effects affecting the source of the sustained effect
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == ApplyEffectParameters.SourceStateObjectRef.ObjectID)
			{
				// The current EffectState's target and source are the same unit as the source of the sustained effect
				PersistentEffect = EffectState.GetX2Effect();
				if (PersistentEffect != none && EffectsToRemoveFromSource.Find(PersistentEffect.EffectName) != INDEX_NONE)
				{
					// The PersistentEffect affecting the source unit is a child of this sustained effect, so remove it
					EffectState.RemoveEffect(NewGameState, NewGameState, bCleansed);
				}
			}
		}
	}

	// Remove the associated target effects
	if (EffectsToRemoveFromTarget.Length > 0)
	{
		SustainedEffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		foreach SustainedEffectTargetUnit.AffectedByEffects(EffectRef)
		{
			// Loop over all effects affecting the target of the sustained effect
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == ApplyEffectParameters.SourceStateObjectRef.ObjectID)
			{
				// The current EffectState's source is the same unit as the source of the sustained effect
				PersistentEffect = EffectState.GetX2Effect();
				if (PersistentEffect != none && EffectsToRemoveFromTarget.Find(PersistentEffect.EffectName) != INDEX_NONE)
				{
					// The PersistentEffect affecting the target unit is a child of this sustained effect, so remove it
					EffectState.RemoveEffect(NewGameState, NewGameState, bCleansed);
				}
			}
		}
	}
}

//Occurs once per turn during the Unit Effects phase
simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit SustainedEffectSourceUnit, SustainedEffectTargetUnit;
	local StateObjectReference SustainedAbilityRef;
	local XComGameState_Ability SustainedAbility;
	local XComGameStateContext SustainedAbilityContext;
	local bool bContinueTicking;
	local XComGameStateHistory History;
	local X2EventManager EventManager;

	bContinueTicking = super.OnEffectTicked(ApplyEffectParameters, kNewEffectState, NewGameState, FirstApplication);

	if((SustainedAbilityName != '') && FullTurnComplete(kNewEffectState))
	{
		History = `XCOMHISTORY;
	
		SustainedEffectSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		SustainedEffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

		// Get the associated sustain ability and attempt to build a context for it
		//SustainedAbility = XComGameState_Ability(History.GetGameStateForObjectID(m_SustainedAbilityReference.ObjectID));
		SustainedAbilityRef = SustainedEffectSourceUnit.FindAbility(SustainedAbilityName);
		`assert(SustainedAbilityRef.ObjectID != 0);
		SustainedAbility = XComGameState_Ability(History.GetGameStateForObjectID(SustainedAbilityRef.ObjectID));
		SustainedAbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(SustainedAbility, SustainedEffectTargetUnit.ObjectID);

		// If the sustained ability context was sucessfully created, fire the sustained ability.
		// Otherwise remove this sustained effect because it has been broken
		if (SustainedAbilityContext.Validate())
		{
			// Because a new XComGameState is already queued, create an event that the sustained effect is
			// listening for to submit this context.
			EventManager = `XEVENTMGR;
			EventManager.TriggerEvent('FireSustainedAbility', SustainedEffectTargetUnit, SustainedEffectSourceUnit);
		}
		else
		{
			bContinueTicking = false;
		}
	}

	return bContinueTicking;
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit SourceUnitState;
	local XComGameStateHistory History;
	local Object EffectObj;
	local int i;

	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	// Register for the required events
	EventMgr.RegisterForEvent(EffectObj, 'UnitTakeEffectDamage', EffectGameState.OnSourceUnitTookEffectDamage, ELD_OnStateSubmitted,, SourceUnitState);
	EventMgr.RegisterForEvent(EffectObj, 'ImpairingEffect', EffectGameState.OnSourceBecameImpaired, ELD_OnStateSubmitted,, SourceUnitState);
	EventMgr.RegisterForEvent(EffectObj, 'FireSustainedAbility', EffectGameState.OnFireSustainedAbility, ELD_OnStateSubmitted,, SourceUnitState);

	for( i = 0; i < RegisterAdditionalEventsLikeImpair.Length; ++i )
	{
		EventMgr.RegisterForEvent(EffectObj, RegisterAdditionalEventsLikeImpair[i], EffectGameState.OnSourceBecameImpaired, ELD_OnStateSubmitted,, SourceUnitState);
	}
}

defaultproperties
{
	bUseSourcePlayerState=true
	FragileAmount=0
	bBringRemoveVisualizationForward=false
	SustainedAbilityName=""
	bCanBeRedirected=false
}