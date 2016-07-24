class X2Ability_Muton extends X2Ability
	config(GameData_SoldierSkills);

var config int BAYONET_STUN_CHANCE;
var config int EXECUTE_RANGE;
var config int EXECUTE_DAMAGE_AMOUNT;
var config int COUNTERATTACK_RANGE;
var config int COUNTERATTACK_DODGE_AMOUNT;

var localized string MarkedForExecuteName;
var localized string MarkedForExecuteDescription;
var localized string CounterattackDodgeName;
var localized string CounterattackDodgeDescription;

var name DelayedExecuteEffectName;
var name MarkedForExecuteEffectName;
var name ExecuteTriggerName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateBayonetAbility('Bayonet', false));
	Templates.AddItem(CreateBayonetAbility('CounterattackBayonet', true));
	Templates.AddItem(CreateDelayedExecuteAbility());
	Templates.AddItem(CreateExecuteAbility());
	Templates.AddItem(CreateCounterattackPreparationAbility());
	Templates.AddItem(CreateCounterattackAbility());
	Templates.AddItem(PurePassive('CounterattackDescription', "img:///UILibrary_PerkIcons.UIPerk_muton_counterattack"));

	return Templates;
}

static function X2DataTemplate CreateBayonetAbility(name TemplateName, bool bForCounterattack)
{
	// Because the Bayonet is a real weapon, the damage for it is in the weapon defintion. This just creates the capacity for the skill to exist.
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee MeleeHitCalc;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local X2Effect_SetUnitValue SetUnitValEffect;
	local X2Effect_ImmediateAbilityActivation ImpairingAbilityEffect;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_muton_bayonet";

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Offensive;

	Template.AdditionalAbilities.AddItem(class'X2Ability_Impairing'.default.ImpairingAbilityName);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;

	if (bForCounterattack)
	{
		ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.CounterattackActionPoint);
		Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
		Template.bDontDisplayInAbilitySummary = true;
	}

	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	MeleeHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = MeleeHitCalc;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	//Impairing effects need to come before the damage. This is needed for proper visualization ordering.
	//Effect on a successful melee attack is triggering the Apply Impairing Effect Ability
	ImpairingAbilityEffect = new class 'X2Effect_ImmediateAbilityActivation';
	ImpairingAbilityEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	ImpairingAbilityEffect.EffectName = 'ImmediateStunImpair';
	ImpairingAbilityEffect.AbilityName = class'X2Ability_Impairing'.default.ImpairingAbilityName;
	ImpairingAbilityEffect.bRemoveWhenTargetDies = true;
	ImpairingAbilityEffect.VisualizationFn = class'X2Ability_Impairing'.static.ImpairingAbilityEffectTriggeredVisualization;
	Template.AddTargetEffect(ImpairingAbilityEffect);

	// Damage Effect
	//
	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	Template.AddTargetEffect(PhysicalDamageEffect);

	// The Muton gets to counterattack once
	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = class'X2Ability'.default.CounterattackDodgeEffectName;
	SetUnitValEffect.NewValueToSet = 0;
	SetUnitValEffect.CleanupType = eCleanup_BeginTurn;
	SetUnitValEffect.bApplyOnHit = true;
	SetUnitValEffect.bApplyOnMiss = true;
	Template.AddShooterEffect(SetUnitValEffect);

	// Remove the dodge increase (happens with a counter attack, which is one time per turn)
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Ability'.default.CounterattackDodgeEffectName);
	RemoveEffects.bApplyOnHit = true;
	RemoveEffects.bApplyOnMiss = true;
	Template.AddShooterEffect(RemoveEffects);

	Template.AbilityTargetStyle = default.SimpleSingleMeleeTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	if (!bForCounterattack) //Counterattack is non-interruptible (bad things happen to the visualizer otherwise)
		Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.CinescriptCameraType = "Muton_Punch";
	
	return Template;
}

static function X2DataTemplate CreateDelayedExecuteAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown Cooldown;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2AbilityTarget_Single SingleTarget;
	local X2Effect_DelayedAbilityActivation DelayedExecuteEffect;
	local X2Effect_Persistent MarkedForExecuteEffect;
	local X2Effect_FaceMultiRoundTarget FaceTargetEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DelayedExecute');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_muton_execute"; 

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Offensive;

	// This ability is a free action
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// While this action is free, it can only be used once per turn
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 1;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.IsImpaired = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.RequireWithinRange = true;
	UnitPropertyCondition.WithinRange = default.EXECUTE_RANGE;

	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	//Effect on a successful test is adding the delayed marked effect to the target
	DelayedExecuteEffect = new class 'X2Effect_DelayedAbilityActivation';
	DelayedExecuteEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	DelayedExecuteEffect.EffectName = default.DelayedExecuteEffectName;
	DelayedExecuteEffect.TriggerEventName = default.ExecuteTriggerName;
	DelayedExecuteEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddShooterEffect(DelayedExecuteEffect);

	// Cause the source to face the target until the execution has occured
	FaceTargetEffect = new class 'X2Effect_FaceMultiRoundTarget';
	FaceTargetEffect.BuildPersistentEffect(2, false, true, , eGameRule_PlayerTurnBegin);
	FaceTargetEffect.DuplicateResponse = eDupe_Refresh;
	Template.AddShooterEffect(FaceTargetEffect);

	// Marked for execute effect
	MarkedForExecuteEffect = new class 'X2Effect_Persistent';
	MarkedForExecuteEffect.EffectName = default.MarkedForExecuteEffectName;
	MarkedForExecuteEffect.DuplicateResponse = eDupe_Refresh;
	MarkedForExecuteEffect.BuildPersistentEffect(2, false, true, , eGameRule_PlayerTurnEnd);
	MarkedForExecuteEffect.bRemoveWhenTargetDies = true;
	MarkedForExecuteEffect.SetDisplayInfo(ePerkBuff_Penalty, default.MarkedForExecuteName, default.MarkedForExecuteDescription, Template.IconImage);
	Template.AddTargetEffect(MarkedForExecuteEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = DelayedExecute_BuildVisualization;
	
	return Template;
}

static function X2AbilityTemplate CreateExecuteAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_UnitEffectsWithAbilitySource UnitEffectsCondition;
	local X2AbilityMultiTarget_Radius MultiTarget;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Execute');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_muton_execute"; 

	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = default.ExecuteTriggerName;
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_AdditionalTargetRequiredIgnoreCache;
	Template.AbilityTriggers.AddItem(EventListener);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.RequireWithinRange = true;
	UnitPropertyCondition.WithinRange = default.EXECUTE_RANGE;

	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);
	Template.AbilityMultiTargetConditions.AddItem(default.GameplayVisibilityCondition);

	// Remove the force facing effect
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class 'X2Effect_FaceMultiRoundTarget'.default.EffectName);
	Template.AddShooterEffect(RemoveEffects);

	// The target must be the same as the one that was marked by the delayed execute effect
	UnitEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	UnitEffectsCondition.AddRequireEffect(default.MarkedForExecuteEffectName, 'AA_UnitIsMarked');
	Template.AbilityMultiTargetConditions.AddItem(UnitEffectsCondition);

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;
	// Target everything in this blast radius
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = default.EXECUTE_RANGE * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	Template.AbilityMultiTargetStyle = MultiTarget;

	// Once this ability is fired, remove the target's mark
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.MarkedForExecuteEffectName);
	Template.AddMultiTargetEffect(RemoveEffects);

	Template.AddMultiTargetEffect(new class'X2Effect_Executed');

	Template.CustomFireAnim = 'FF_Fire';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Muton_Execute";

	return Template;
}

simulated function DelayedExecute_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference InteractingUnitRef;
	local XComGameState_Ability Ability;

	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
					
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Good);
	OutVisualizationTracks.AddItem(BuildTrack);
	
	//****************************************************************************************
}


static function X2AbilityTemplate CreateCounterattackPreparationAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local X2Effect_ToHitModifier DodgeEffect;
	local X2Effect_SetUnitValue SetUnitValEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CounterattackPreparation');

	Template.bDontDisplayInAbilitySummary = true;
	Template.AdditionalAbilities.AddItem('Counterattack');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'PlayerTurnEnded';
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_UnitPostBeginPlay');

	// During the Enemy player's turn, the Muton gets a dodge increase
	DodgeEffect = new class'X2Effect_ToHitModifier';
	DodgeEffect.EffectName = class'X2Ability'.default.CounterattackDodgeEffectName;
	DodgeEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	//DodgeEffect.SetDisplayInfo(ePerkBuff_Bonus, default.CounterattackDodgeName, default.CounterattackDodgeDescription, Template.IconImage);
	DodgeEffect.AddEffectHitModifier(eHit_Graze, default.COUNTERATTACK_DODGE_AMOUNT, default.CounterattackDodgeName, class'X2AbilityToHitCalc_StandardMelee',
									 true, false, true, true, , false);
	DodgeEffect.bApplyAsTarget = true;
	Template.AddShooterEffect(DodgeEffect);

	// The Muton gets to counterattack once
	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = class'X2Ability'.default.CounterattackDodgeEffectName;
	SetUnitValEffect.NewValueToSet = class'X2Ability'.default.CounterattackDodgeUnitValue;
	SetUnitValEffect.CleanupType = eCleanup_BeginTurn;
	Template.AddTargetEffect(SetUnitValEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}

static function X2AbilityTemplate CreateCounterattackAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'Counterattack');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_muton_counterattack";

	Template.bDontDisplayInAbilitySummary = true;
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'AbilityActivated';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.MeleeCounterattackListener;
	Template.AbilityTriggers.AddItem(EventListener);

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.CinescriptCameraType = "Muton_Counterattack";

	return Template;
}

defaultproperties
{
	DelayedExecuteEffectName="DelayedExecuteEffect"
	MarkedForExecuteEffectName="MarkedForExecuteEffect"
	ExecuteTriggerName="DelayedExecuteRemoved"	
}