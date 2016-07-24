class X2Effect_Burrowed extends X2Effect_Persistent
	config(GameCore);

var config float BURROWED_PERCENT_DAMAGE_REDUCTION;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	//Effects that change visibility must actively indicate it
	kNewTargetState.bRequiresVisibilityUpdate = true;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit Unit;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	//Effects that change visibility must actively indicate it
	Unit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	Unit.bRequiresVisibilityUpdate = true;
	NewGameState.AddStateObject(Unit);
}

function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState)
{
	ActionPoints.Length = 0;
	ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.UnburrowActionPoint);
}

function ModifyGameplayVisibilityForTarget(out GameRulesCache_VisibilityInfo InOutVisibilityInfo, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit)
{
	if( SourceUnit.IsEnemyUnit(TargetUnit) )
	{
		InOutVisibilityInfo.bVisibleGameplay = false;
		InOutVisibilityInfo.GameplayVisibleTags.AddItem('burrowed');
	}
}

function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, 
										const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect)
{
	local int ModifiedDamage;

	// Currently causes all damage to be halved. If there are specific abilities/weapons that can target a burrowed
	// Chryssalid this will need to be updated
	ModifiedDamage = CurrentDamage * default.BURROWED_PERCENT_DAMAGE_REDUCTION;

	return ModifiedDamage;
}

function EGameplayBlocking ModifyGameplayPathBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit)
{
	// This unit blocks the target unit if they are on the same team (not an enemy) or the target unit is a civilian
	if( !UnitState.IsEnemyUnit(TargetUnit) || TargetUnit.IsCivilian() )
	{
		return eGameplayBlocking_Blocks;
	}
	else
	{
		return eGameplayBlocking_DoesNotBlock;
	}
}

function EGameplayBlocking ModifyGameplayDestinationBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit) 
{
	return ModifyGameplayPathBlockingForTarget(UnitState, TargetUnit);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	if( EffectApplyResult == 'AA_Success' )
	{
		super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);
		class'X2Action_UnBurrow'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
	}
}

defaultproperties
{
	EffectRank=1 // This rank is set for blocking
	EffectName="Burrowed"
	CustomIdleOverrideAnim="NO_BurrowLoop"
	bBringRemoveVisualizationForward=true
}