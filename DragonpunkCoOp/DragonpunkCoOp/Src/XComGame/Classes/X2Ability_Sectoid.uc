class X2Ability_Sectoid extends X2Ability
	config(GameData_SoldierSkills);

var config int PSIDET_ENV_DMG;
var config float PSIDET_RADIUS_METERS;
var config int SECTOID_MINDSPIN_DISORIENTED_DURATION;
var config int SECTOID_MINDSPIN_CONFUSED_DURATION;
var config int SECTOID_MINDSPIN_CONTROL_DURATION;
var config float SECTOID_REANIMATION_ZOMBIE_RISE_DELAY;

var name DelayedPsiExplosionEffectName;
var name PsiExplosionTriggerName;
var name SireZombieLinkName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddMindspinTemplate());
	Templates.AddItem(AddDeathOverride());
	Templates.AddItem(AddDelayedPsiExplosionAbility());
	Templates.AddItem(AddPsiExplosionAbility());
	Templates.AddItem(AddPsiReanimation());
	Templates.AddItem(AddKillSiredZombies());

	Templates.AddItem(AddSireZombieLink());
	Templates.AddItem(CreatePsiZombieInitializationAbility());

	// MP Versions of Abilities
	Templates.AddItem(AddPsiReanimationMP());

	return Templates;
}

static function X2DataTemplate AddMindspinTemplate()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2Condition_UnitProperty      UnitPropertyCondition;
	local X2Condition_Visibility        TargetVisibilityCondition;
	local X2Condition_UnitImmunities	UnitImmunityCondition;
	local X2Effect_PersistentStatChange DisorientedEffect;
	local X2Effect_Panicked             PanickedEffect;
	local X2Effect_MindControl          MindControlEffect;
	local X2Effect_RemoveEffects        MindControlRemoveEffects;
	local X2Condition_UnitEffects		ExcludeEffects;
	local X2AbilityTarget_Single        SingleTarget;
	local X2AbilityTrigger_PlayerInput  InputTrigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Mindspin');
	
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sectoid_mindspin";

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = 3;
	Cooldown.NumGlobalTurns = 1;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	Template.AddShooterEffectExclusions();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);
	
	TargetVisibilityCondition = new class'X2Condition_Visibility';	
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);

	UnitImmunityCondition = new class'X2Condition_UnitImmunities';
	UnitImmunityCondition.AddExcludeDamageType('Mental');
	UnitImmunityCondition.bOnlyOnCharacterTemplate = true;
	Template.AbilityTargetConditions.AddItem(UnitImmunityCondition);

	//  Disorient effect for 1 unblocked psi hit
	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
	DisorientedEffect.iNumTurns = default.SECTOID_MINDSPIN_DISORIENTED_DURATION;
	DisorientedEffect.MinStatContestResult = 1;
	DisorientedEffect.MaxStatContestResult = 1;
	Template.AddTargetEffect(DisorientedEffect);
	//  Disorient effect for 2 unblocked psi hits
	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect();
	DisorientedEffect.iNumTurns = default.SECTOID_MINDSPIN_DISORIENTED_DURATION + 1;
	DisorientedEffect.MinStatContestResult = 2;
	DisorientedEffect.MaxStatContestResult = 2;
	Template.AddTargetEffect(DisorientedEffect);

	PanickedEffect = class'X2StatusEffects'.static.CreatePanickedStatusEffect();
	PanickedEffect.MinStatContestResult = 3;
	PanickedEffect.MaxStatContestResult = 4;
	Template.AddTargetEffect(PanickedEffect);

	MindControlEffect = class'X2StatusEffects'.static.CreateMindControlStatusEffect(default.SECTOID_MINDSPIN_CONTROL_DURATION);
	MindControlEffect.MinStatContestResult = 5;
	MindControlEffect.MaxStatContestResult = 0;
	Template.AddTargetEffect(MindControlEffect);

	MindControlRemoveEffects = class'X2StatusEffects'.static.CreateMindControlRemoveEffects();
	MindControlRemoveEffects.MinStatContestResult = 5;
	MindControlRemoveEffects.MaxStatContestResult = 0;
	MindControlRemoveEffects.DamageTypes.AddItem('Mental');
	Template.AddTargetEffect(MindControlRemoveEffects);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	// Unlike in other cases, in TypicalAbility_BuildVisualization, the MissSpeech is used on the Target!
	Template.TargetMissSpeech = 'SoldierResistsMindControl';

	Template.CustomFireAnim = 'HL_Psi_ProjectileMedium';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Sectoid_Mindspin";

	// This action is considered 'hostile' and can be interrupted!
	Template.Hostility = eHostility_Offensive;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	
	return Template;
}

static function X2AbilityTemplate AddDeathOverride()
{
	local X2AbilityTemplate Template;
	local X2Effect_OverrideDeathAction DeathActionEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SectoidDeathOverride');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter"; // TODO: This needs to be changed

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	DeathActionEffect = new class'X2Effect_OverrideDeathAction';
	DeathActionEffect.DeathActionClass = class'X2Action_SectoidDeath';
	Template.AddTargetEffect(DeathActionEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate AddDelayedPsiExplosionAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitValue UnitValue;
	local X2Effect_SetUnitValue SetUnitValEffect;
	local X2Effect_DelayedAbilityActivation DelayedPsiExplosionEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'DelayedPsiExplosion');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter"; // TODO: This needs to be changed

	Template.AdditionalAbilities.AddItem('PsiExplosion');

	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	// This ability is only valid if there has not been another death explosion on the unit
	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue('DelayedDeathPsiExplosion', 1, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(UnitValue);

	// This ability fires when the sectoid dies
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitDied';
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the sectoid unit so the blast center is its dead body
	Template.AbilityTargetStyle = default.SelfTarget;

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	//Delayed Effect to cause the Psi Explosion to happen next turn
	DelayedPsiExplosionEffect = new class 'X2Effect_DelayedAbilityActivation';
	DelayedPsiExplosionEffect.BuildPersistentEffect(2, false, false, , eGameRule_PlayerTurnBegin);
	DelayedPsiExplosionEffect.EffectName = default.DelayedPsiExplosionEffectName;
	DelayedPsiExplosionEffect.TriggerEventName = default.PsiExplosionTriggerName;
	DelayedPsiExplosionEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddShooterEffect(DelayedPsiExplosionEffect);

	// Once this ability is fired, set the DeathPsiExplosion Unit Value so it will not happen again
	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = 'DelayedDeathPsiExplosion';
	SetUnitValEffect.NewValueToSet = 1;
	SetUnitValEffect.CleanupType = eCleanup_BeginTactical;
	Template.AddShooterEffect(SetUnitValEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = DelayedPsiExplosion_BuildVisualization;
	Template.CinescriptCameraType = "Sectoid_PsiExplosion";

	return Template;
}

static function X2AbilityTemplate AddPsiExplosionAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2AbilityMultiTarget_Radius MultiTarget;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local X2Effect_ApplyWeaponDamage PsiDamageEffect;
	local X2Effect_ApplyWeaponDamage EnvironmentalDamageEffect;
	local X2Condition_UnitValue UnitValue;
	local X2Effect_SetUnitValue SetUnitValEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiExplosion');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter"; // TODO: This needs to be changed

	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	// This ability is only valid if there has not been another death explosion on the unit
	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue('DeathPsiExplosion', 1, eCheck_LessThan);
	Template.AbilityShooterConditions.AddItem(UnitValue);

	// This ability fires when the event DelayedPsiExplosionRemoved fires on this unit
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = default.PsiExplosionTriggerName;
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_SelfIgnoreCache;
	Template.AbilityTriggers.AddItem(EventListener);

	// Targets the sectoid unit so the blast center is its dead body
	Template.AbilityTargetStyle = default.SelfTarget;

	// Add dead eye to guarantee the explosion occurs
	Template.AbilityToHitCalc = default.DeadEye;

	// Target everything in this blast radius
	MultiTarget = new class'X2AbilityMultiTarget_Radius';
	MultiTarget.fTargetRadius = default.PSIDET_RADIUS_METERS;
	MultiTarget.bIgnoreBlockingCover = true;
	Template.AbilityMultiTargetStyle = MultiTarget;

	// Once this ability is fired, set the DeathPsiExplosion Unit Value so it will not happen again
	SetUnitValEffect = new class'X2Effect_SetUnitValue';
	SetUnitValEffect.UnitName = 'DeathPsiExplosion';
	SetUnitValEffect.NewValueToSet = 1;
	SetUnitValEffect.CleanupType = eCleanup_BeginTactical;
	Template.AddTargetEffect(SetUnitValEffect);

	// Target must be a living unit
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = false;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	// Everything in the blast radius receives physical damage
	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.SECTOID_PSI_DEATHDETONATION_BASEDAMAGE;
	Template.AddMultiTargetEffect(PhysicalDamageEffect);

	// Everything in the blast radius receives psi damage
	PsiDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PsiDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.SECTOID_PSI_DEATHDETONATION_BASEDAMAGE;
	PsiDamageEffect.EffectDamageValue.DamageType = 'Psi';
	PsiDamageEffect.bIgnoreArmor = true;
	Template.AddMultiTargetEffect(PsiDamageEffect);

	// Causes environmental damage too
	EnvironmentalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	EnvironmentalDamageEffect.EnvironmentalDamageAmount = default.PSIDET_ENV_DMG;
	EnvironmentalDamageEffect.EffectDamageValue.Damage = 0;
	EnvironmentalDamageEffect.EffectDamageValue.Spread = 0;
	EnvironmentalDamageEffect.EffectDamageValue.Crit = 0;
	EnvironmentalDamageEffect.EffectDamageValue.Pierce = 0;
	Template.AddTargetEffect(EnvironmentalDamageEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = PsiExplosion_BuildVisualization;
	Template.CinescriptCameraType = "Sectoid_PsiExplosion";

	return Template;
}

static function X2AbilityTemplate AddPsiReanimation()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown Cooldown;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_Visibility TargetVisibilityCondition;
	local X2Effect_SpawnPsiZombie SpawnZombieEffect;
	local X2Condition_UnitValue UnitValue;
	local X2Condition_UnitEffects ExcludeEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiReanimation');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sectoid_psireanimate";

	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;

	// Cost of the ability
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Cooldown on the ability
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 4;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);// Prevent ability from being available when dead
	Template.AddShooterEffectExclusions();

	// This ability is only valid if the target has not yet been turned into a zombie
	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue(class'X2Effect_SpawnPsiZombie'.default.TurnedZombieName, 1, eCheck_LessThan);
	Template.AbilityTargetConditions.AddItem(UnitValue);

	// the target's tile must be clear of obstruction. Functionally this is the same as the
	// unburrow condition, but it can't renamed now that we've launched the game
	Template.AbilityTargetConditions.AddItem(new class'X2Condition_ValidUnburrowTile');

	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_UnitIsImmune');
	ExcludeEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName, 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);

	// The unit must be organic, dead, and not an alien
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeOrganic = false;
	UnitPropertyCondition.ExcludeAlien = true;
	UnitPropertyCondition.ExcludeCivilian = false;
	UnitPropertyCondition.ExcludeCosmetic = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// Must be able to see the dead unit to reanimate it
	TargetVisibilityCondition = new class'X2Condition_Visibility';	
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	// Add dead eye to guarantee the reanimation occurs
	Template.AbilityToHitCalc = default.DeadEye;

	// The target will now be turned into a zombie
	SpawnZombieEffect = new class'X2Effect_SpawnPsiZombie';
	SpawnZombieEffect.BuildPersistentEffect(1, true);
	Template.AddTargetEffect(SpawnZombieEffect);

	Template.bSkipPerkActivationActions = true;
	Template.bSkipPerkActivationActionsSync = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = PsiReanimation_BuildVisualization;
	Template.CinescriptCameraType = "Sectoid_PsiReanimation";

	return Template;
}

simulated function PsiReanimation_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local StateObjectReference InteractingUnitRef;
	local X2Action_PlayAnimation AnimationAction;

	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack, ZombieTrack, DeadUnitTrack;
	local XComGameState_Unit SpawnedUnit, DeadUnit, SectoidUnit;
	local UnitValue SpawnedUnitValue;
	local X2Effect_SpawnPsiZombie SpawnPsiZombieEffect;
	local X2Action_TimedWait ReanimateTimedWaitAction;
	local X2Action_SendInterTrackMessage SendMessageAction;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	SectoidUnit = XComGameState_Unit(BuildTrack.StateObject_NewState);

	if( SectoidUnit != none )
	{
		// Configure the visualization track for the psi zombie
		//******************************************************************************************
		DeadUnitTrack.StateObject_OldState = History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		DeadUnitTrack.StateObject_NewState = DeadUnitTrack.StateObject_OldState;
		DeadUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
		`assert(DeadUnit != none);
		DeadUnitTrack.TrackActor = History.GetVisualizer(DeadUnit.ObjectID);

		// Get the ObjectID for the ZombieUnit created from the DeadUnit
		DeadUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

		ZombieTrack = EmptyTrack;
		ZombieTrack.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
		ZombieTrack.StateObject_NewState = ZombieTrack.StateObject_OldState;
		SpawnedUnit = XComGameState_Unit(ZombieTrack.StateObject_NewState);
		`assert(SpawnedUnit != none);
		ZombieTrack.TrackActor = History.GetVisualizer(SpawnedUnit.ObjectID);

		// Only one target effect and it is X2Effect_SpawnPsiZombie
		SpawnPsiZombieEffect = X2Effect_SpawnPsiZombie(Context.ResultContext.TargetEffectResults.Effects[0]);

		if( SpawnPsiZombieEffect == none )
		{
			`RedScreenOnce("PsiReanimation_BuildVisualization: Missing X2Effect_SpawnPsiZombie -dslonneger @gameplay");
			return;
		}

		// Build the tracks
		class'X2Action_ExitCover'.static.AddToVisualizationTrack(BuildTrack, Context);
		class'X2Action_AbilityPerkStart'.static.AddToVisualizationTrack(BuildTrack, Context);

		// Let the dead unit know that it may start its rise timer
		SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
		SendMessageAction.SendTrackMessageToRef = DeadUnit.GetReference();

		AnimationAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, Context));
		AnimationAction.Params.AnimName = 'HL_Psi_ReAnimate';

		class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTrack(BuildTrack, Context);
		class'X2Action_EnterCover'.static.AddToVisualizationTrack(BuildTrack, Context);

		// Dead unit should wait for the Sectoid to play its Reanimation animation
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(DeadUnitTrack, Context);

		// Preferable to have an anim notify from content but can't do that currently, animation gave the time to wait before the zombie rises
		ReanimateTimedWaitAction = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTrack(DeadUnitTrack, Context));
		ReanimateTimedWaitAction.DelayTimeSec = default.SECTOID_REANIMATION_ZOMBIE_RISE_DELAY;

		// Let the spawned Zombie unit know that it may now rise
		SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(DeadUnitTrack, Context));
		SendMessageAction.SendTrackMessageToRef = SpawnedUnit.GetReference();

		SpawnPsiZombieEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, ZombieTrack, DeadUnit, DeadUnitTrack);
	
		OutVisualizationTracks.AddItem(BuildTrack);
		OutVisualizationTracks.AddItem(DeadUnitTrack);
		OutVisualizationTracks.AddItem(ZombieTrack);
	}
}

simulated function DelayedPsiExplosion_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
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
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Bad);
	OutVisualizationTracks.AddItem(BuildTrack);
}

simulated function PsiExplosion_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference InteractingUnitRef;
	local XComGameState_Ability Ability;
	local X2VisualizerInterface TargetVisualizerInterface;

	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;

	local X2Action_PlayAnimation PlayAnimation;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int i, j;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, Context));
	PlayAnimation.Params.AnimName = 'HL_Psi_ExplosionStop';
	PlayAnimation.bFinishAnimationWait = false;

	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, Ability.GetMyTemplate().LocFlyOverText, '', eColor_Bad);

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for (i = 0; i < Context.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[i];
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		for( j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}

		TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
		}

		if (BuildTrack.TrackActions.Length > 0)
		{
			OutVisualizationTracks.AddItem(BuildTrack);
		}
	}
	//****************************************************************************************
}

// Place holder ability to grab the Sire-Zombie link effect
static function X2AbilityTemplate AddSireZombieLink()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_Placeholder PlaceholderTrigger;
	local X2Effect_Persistent SireZombieLinkEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.SireZombieLinkName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sectoid_psireanimate";

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';

	PlaceholderTrigger = new class'X2AbilityTrigger_Placeholder';
	Template.AbilityTriggers.AddItem(PlaceholderTrigger);

	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';

	// Create an effect that will be attached to the spawned zombie
	SireZombieLinkEffect = new class'X2Effect_Persistent';
	SireZombieLinkEffect.BuildPersistentEffect(1, true, false, true);
	SireZombieLinkEffect.EffectName = default.SireZombieLinkName;
	Template.AddTargetEffect(SireZombieLinkEffect);

	Template.BuildNewGameStateFn = Empty_BuildGameState;
	Template.BuildVisualizationFn = none;

	//We re-run the X2Action_CreateDoppelganger on load, to restore the appearance and tether of the zombie.
	Template.BuildAffectedVisualizationSyncFn = SireZombieLink_BuildVisualizationSyncDelegate;

	return Template;
}

simulated function SireZombieLink_BuildVisualizationSyncDelegate(name EffectName, XComGameState VisualizeGameState, out VisualizationTrack BuildTrack)
{
	local XComGameStateContext_Ability AbilityContext;

	local XComGameState_Unit ZombieUnitState;
	local XComGameState_Unit DeadUnitState;

	local XComGameState_Ability ZombieAbility;

	local X2Action_CreateDoppelganger DoppelgangerAction;

	//Only run on the SireZombieLink effect
	if (EffectName != default.SireZombieLinkName)
		return;
	
	//Find the context and unit states associated with the Psi Reanimation ability used
	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == None)
		return;

	ZombieUnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	DeadUnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (ZombieUnitState == None || DeadUnitState == None)
		return;

	ZombieAbility = XComGameState_Ability(VisualizeGameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (ZombieAbility == none)
		return;

	//Perform X2Action_CreateDoppelganger on the zombie, as we did when it was spawned, to grab the original unit's appearance and tether effect.
	DoppelgangerAction = X2Action_CreateDoppelganger(class'X2Action_CreateDoppelganger'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	DoppelgangerAction.OriginalUnitState = DeadUnitState;
	DoppelgangerAction.ShouldCopyAppearance = 
		ZombieUnitState.GetMyTemplateName() == 'PsiZombie' ||
		ZombieUnitState.GetMyTemplateName() == 'PsiZombieHuman' ||
		ZombieUnitState.GetMyTemplateName() == 'PsiZombieHumanF';
	DoppelgangerAction.ReanimatorAbilityState = ZombieAbility;
	DoppelgangerAction.bIgnorePose = true;
}

simulated function XComGameState Empty_BuildGameState( XComGameStateContext Context )
{
	//	This is an explicit placeholder so that ValidateTemplates doesn't think something is wrong with the ability template.
	`RedScreen("This function should never be called.");
	return none;
}

static function X2AbilityTemplate AddKillSiredZombies()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener DeathEventListener;
	local X2AbilityTrigger_EventListener ImpairedEventListener;
	local X2Condition_UnitEffectsWithAbilitySource TargetEffectCondition;
	local X2Effect_KillUnit KillUnitEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'KillSiredZombies');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	// This ability fires when the sectoid dies
	DeathEventListener = new class'X2AbilityTrigger_EventListener';
	DeathEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DeathEventListener.ListenerData.EventID = 'UnitDied';
	DeathEventListener.ListenerData.Filter = eFilter_Unit;
	DeathEventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_SelfWithAdditionalTargets;
	Template.AbilityTriggers.AddItem(DeathEventListener);

	// Also activate when the sectoid becomes impaired (mainly to prevent them getting mind-controlled and having to propagate that along...)
	ImpairedEventListener = new class'X2AbilityTrigger_EventListener';
	ImpairedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	ImpairedEventListener.ListenerData.EventID = 'ImpairingEffect';
	ImpairedEventListener.ListenerData.Filter = eFilter_Unit;
	ImpairedEventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_SelfWithAdditionalTargets;
	Template.AbilityTriggers.AddItem(ImpairedEventListener);

	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllUnits';

	TargetEffectCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	TargetEffectCondition.AddRequireEffect(default.SireZombieLinkName, 'AA_UnitIsImmune');
	Template.AbilityMultiTargetConditions.AddItem(TargetEffectCondition);

	KillUnitEffect = new class'X2Effect_KillUnit';
	KillUnitEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	KillUnitEffect.DeathActionClass = class'X2Action_ZombieSireDeath';
	KillUnitEffect.VisualizationFn = BuildVisualization_SireDeathEffect;
	Template.AddMultiTargetEffect(KillUnitEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Zombie_SireDeath";

	return Template;
}

simulated function BuildVisualization_SireDeathEffect(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local X2Action_CameraLookAt LookAtAction;

	UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	if (UnitState != None)
	{
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		LookAtAction.LookAtDuration = 2.0f;
		LookAtAction.UseTether = false;
		LookAtAction.LookAtObject = UnitState;
		LookAtAction.BlockUntilActorOnScreen = true;
	}
}

static function X2AbilityTemplate CreatePsiZombieInitializationAbility()
{
	local X2AbilityTemplate Template;
	local X2Effect_DamageImmunity DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ZombieInitialization');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_mentalfortress"; 

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, true, true);
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.DisorientDamageType);
	DamageImmunity.ImmuneTypes.AddItem('stun');
	DamageImmunity.ImmuneTypes.AddItem('Unconscious');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

// #######################################################################################
// -------------------- MP Abilities -----------------------------------------------------
// #######################################################################################

static function X2AbilityTemplate AddPsiReanimationMP()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown Cooldown;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_Visibility TargetVisibilityCondition;
	local X2Effect_SpawnPsiZombie SpawnZombieEffect;
	local X2Condition_UnitValue UnitValue;
	local X2Condition_UnitEffects ExcludeEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiReanimationMP');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sectoid_psireanimate";
	Template.MP_PerkOverride = 'PsiReanimation';

	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;

	// Cost of the ability
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Cooldown on the ability
	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 4;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityTargetStyle = new class'X2AbilityTarget_Single';
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);// Prevent ability from being available when dead
	Template.AddShooterEffectExclusions();

	// This ability is only valid if the target has not yet been turned into a zombie
	UnitValue = new class'X2Condition_UnitValue';
	UnitValue.AddCheckValue(class'X2Effect_SpawnPsiZombie'.default.TurnedZombieName, 1, eCheck_LessThan);
	Template.AbilityTargetConditions.AddItem(UnitValue);

	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_UnitIsImmune');
	ExcludeEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName, 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(ExcludeEffects);

	// The unit must be organic, dead, and not an alien
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeOrganic = false;
	UnitPropertyCondition.ExcludeAlien = true;
	UnitPropertyCondition.ExcludeCivilian = false;
	UnitPropertyCondition.ExcludeCosmetic = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// Must be able to see the dead unit to reanimate it
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	// Add dead eye to guarantee the reanimation occurs
	Template.AbilityToHitCalc = default.DeadEye;

	// The target will now be turned into a zombie
	SpawnZombieEffect = new class'X2Effect_SpawnPsiZombie';
	SpawnZombieEffect.UnitToSpawnName = 'PsiZombieMP';
	SpawnZombieEffect.AltUnitToSpawnName = 'PsiZombieHumanMP';
	SpawnZombieEffect.BuildPersistentEffect(1, true);
	Template.AddTargetEffect(SpawnZombieEffect);

	Template.bSkipPerkActivationActions = true;
	Template.bSkipPerkActivationActionsSync = false;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = PsiReanimation_BuildVisualization;
	Template.CinescriptCameraType = "Sectoid_PsiReanimation";

	return Template;
}

defaultproperties
{
	DelayedPsiExplosionEffectName="DelayedPsiExplosionEffect"
	PsiExplosionTriggerName="DelayedPsiExplosionRemoved"
	SireZombieLinkName="SireZombieLink"
}