class X2Effect_MimicBeacon extends X2Effect_Persistent config(GameCore);

var private config array<name> ABILITIES_ALLOWED_TO_HIT;
var private config name REMOVE_EFFECT_ANIM_NAME;

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.Length = 0;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit MimicUnit;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	MimicUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( MimicUnit != None )
	{
		MimicUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', MimicUnit.ObjectID));

		// Remove the dead unit from play
		`XEVENTMGR.TriggerEvent('UnitRemovedFromPlay', MimicUnit, MimicUnit, NewGameState);

		NewGameState.AddStateObject(MimicUnit);
	}
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_MimicBeaconEnd MimicEndAction;
	local XComGameState_Unit UnitState;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);

	if (EffectApplyResult != 'AA_Success' || BuildTrack.TrackActor == none)
	{
		return;
	}

	MimicEndAction = X2Action_MimicBeaconEnd(class'X2Action_MimicBeaconEnd'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));

	UnitState = XComGameState_Unit(BuildTrack.StateObject_OldState);
	if( (UnitState != none) && UnitState.IsAlive() )
	{
		MimicEndAction.AnimationName = default.REMOVE_EFFECT_ANIM_NAME;
	}
}

simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationTrack BuildTrack )
{
	local X2Action_PlayAnimation AnimationAction;

	super.AddX2ActionsForVisualization_Sync(VisualizeGameState, BuildTrack);

	AnimationAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	AnimationAction.Params.AnimName = class'X2Ability_ItemGrantedAbilitySet'.default.MIMIC_BEACON_START_ANIM;
	AnimationAction.Params.BlendTime = 0.0f;
}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	return DamageType == 'poison' ||
		   DamageType == 'fire' ||
		   DamageType == 'acid' ||
		   DamageType == class'X2Item_DefaultDamageTypes'.default.KnockbackDamageType ||
		   DamageType == 'psi' ||
		   DamageType == class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType ||
		   DamageType == 'stun';
}

function bool CanAbilityHitUnit(name AbilityName)
{
	return ABILITIES_ALLOWED_TO_HIT.Find(AbilityName) != INDEX_NONE;
}

function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) {return false; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) {return false; }

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	EffectName = "MimicBeaconEffect"
}