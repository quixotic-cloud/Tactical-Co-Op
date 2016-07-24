//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_Chryssalid extends X2Ability
	config(GameData_SoldierSkills);

var config int CHARGE_AND_SLASH_COOLDOWN;
var config int UNBURROW_ACTION_POINTS_ADDED;
var config int BURROWED_ATTACK_RANGE_METERS;
var config int POISON_DURATION;
var config int UNBURROW_PERCENT_CHANCE;

var localized string ParthenogenicPoisonFriendlyName;
var localized string ParthenogenicPoisonFriendlyDesc;

var privatewrite name UnburrowTriggerEventName;
var private name UnburrowTriggerCheckEffectName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateSlashAbility());
	Templates.AddItem(CreateBurrowAbility());
	Templates.AddItem(CreateUnburrowAbility());
	Templates.AddItem(CreateBurrowedAttackAbility());
	Templates.AddItem(CreateUnburrowSawEnemyAbility());
	Templates.AddItem(PurePassive('ChyssalidPoison', "img:///UILibrary_PerkIcons.UIPerk_chryssalid_poisonousclaws"));
	Templates.AddItem(CreateImmunitiesAbility());

	// MP Versions of Abilities
	Templates.AddItem(CreateSlashMPAbility());

	return Templates;
}

static function X2AbilityTemplate CreateSlashAbility(optional Name AbilityName = 'ChryssalidSlash')
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee MeleeHitCalc;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local X2Effect_ParthenogenicPoison ParthenogenicPoisonEffect;
	local X2AbilityTarget_MovingMelee MeleeTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_slash";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	MeleeHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = MeleeHitCalc;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false; // Disable this to allow civilians to be attacked.
	UnitPropertyCondition.ExcludeSquadmates = true;		   // Don't attack other AI units.
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);
	
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	ParthenogenicPoisonEffect = new class'X2Effect_ParthenogenicPoison';
	ParthenogenicPoisonEffect.BuildPersistentEffect(default.POISON_DURATION, true, false, false, eGameRule_PlayerTurnEnd);
	ParthenogenicPoisonEffect.SetDisplayInfo(ePerkBuff_Penalty, default.ParthenogenicPoisonFriendlyName, default.ParthenogenicPoisonFriendlyDesc, Template.IconImage, true);
	ParthenogenicPoisonEffect.DuplicateResponse = eDupe_Ignore;
	ParthenogenicPoisonEffect.SetPoisonDamageDamage();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeDead = false;
	ParthenogenicPoisonEffect.TargetConditions.AddItem(UnitPropertyCondition);
	Template.AddTargetEffect(ParthenogenicPoisonEffect);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.CHRYSSALID_MELEEATTACK_BASEDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	Template.AddTargetEffect(PhysicalDamageEffect);

	MeleeTarget = new class'X2AbilityTarget_MovingMelee';
	MeleeTarget.MovementRangeAdjustment = 0;
	Template.AbilityTargetStyle = MeleeTarget;
	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_PlayerInput');
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');

	Template.CustomFireAnim = 'FF_Melee';
	Template.bSkipMoveStop = true;
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.CinescriptCameraType = "Chryssalid_PoisonousClaws";
	
	return Template;
}

static function X2AbilityTemplate CreateBurrowAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Condition_UnitEffects ExcludeEffects;
	local X2Condition_OnGroundTile GroundFloorCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChryssalidBurrow');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_burrow";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_HideIfOtherAvailable;
	Template.HideIfAvailable.AddItem( 'ChryssalidUnburrow' );

	Template.AdditionalAbilities.AddItem('ChryssalidUnburrow');
	Template.AdditionalAbilities.AddItem('BurrowedAttack');
	Template.AdditionalAbilities.AddItem('UnburrowSawEnemy');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	GroundFloorCondition = new class'X2Condition_OnGroundTile';
	GroundFloorCondition.NotAFloorTileTag = 'DoNotBurrow';
	Template.AbilityShooterConditions.AddItem(GroundFloorCondition);

	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BurrowedName, 'AA_UnitIsBurrowed');
	Template.AbilityShooterConditions.AddItem(ExcludeEffects);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AddTargetEffect(new class'X2Effect_Burrowed');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Burrow_BuildVisualization;
	Template.BuildAppliedVisualizationSyncFn = Burrow_BuildVisualizationSync;
	Template.CinescriptCameraType = "Chryssalid_Burrow";
	
	return Template;
}

simulated function Burrow_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local int EffectIndex;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	//****************************************************************************************
	//Configure the visualization track for the target
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_Burrow'.static.AddToVisualizationTrack(BuildTrack, Context);

	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************
}

simulated function Burrow_BuildVisualizationSync( name EffectName, XComGameState VisualizeGameState, out VisualizationTrack BuildTrack )
{
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate AbilityTemplate;
	local int EffectIndex;

	Context = XComGameStateContext_Ability( VisualizeGameState.GetContext( ) );

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( Context.InputContext.AbilityTemplateName );

	class'X2Action_Burrow'.static.AddToVisualizationTrack( BuildTrack, Context );

	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[ EffectIndex ].AddX2ActionsForVisualization( VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult( AbilityTemplate.AbilityTargetEffects[ EffectIndex ] ) );
	}
}

static function X2AbilityTemplate CreateUnburrowAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2Condition_UnitEffects RequiredEffects;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_GrantActionPoints AddActionPointsEffect;
	local X2AbilityTrigger_EventListener Trigger;
	local X2AbilityCooldown Cooldown;
	local AdditionalCooldownInfo CooldownInfo;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChryssalidUnburrow');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_burrow";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.AllowedTypes.Length = 0;        //  clear default allowances
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.UnburrowActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 0;

	CooldownInfo.AbilityName = 'ChryssalidBurrow';
	CooldownInfo.NumTurns = 2;
	Cooldown.AditionalAbilityCooldowns.AddItem(CooldownInfo);

	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// This ability fires can when the unit takes damage
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'UnitTakeEffectDamage';
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.BurrowedChryssalidTakeDamageListener;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(Trigger);

	// This ability fires can when the unit passes a check after seeing an enemy
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = default.UnburrowTriggerEventName;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self_VisualizeInGameState;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(Trigger);

	RequiredEffects = new class'X2Condition_UnitEffects';
	RequiredEffects.AddRequireEffect(class'X2AbilityTemplateManager'.default.BurrowedName, 'AA_UnitIsNotBurrowed');

	Template.AbilityShooterConditions.AddItem(RequiredEffects);
	Template.AbilityShooterConditions.AddItem(new class'X2Condition_ValidUnburrowTile');
	
	// Unburrow may trigger if the unit is burning or disoriented
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.BurrowedName);
	RemoveEffects.EffectNamesToRemove.AddItem(default.UnburrowTriggerCheckEffectName);
	Template.AddTargetEffect(RemoveEffects);

	AddActionPointsEffect = new class'X2Effect_GrantActionPoints';
	AddActionPointsEffect.NumActionPoints = default.UNBURROW_ACTION_POINTS_ADDED;
	AddActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.StandardActionPoint;
	Template.AddTargetEffect(AddActionPointsEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Unburrow_BuildVisualization;
	Template.CinescriptCameraType = "Chryssalid_Unburrow";
	
	return Template;
}

simulated function Unburrow_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local int EffectIndex;
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local array<StateObjectReference> EnemyUnitsThatSeeThisUnit;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	//****************************************************************************************
	//Configure the visualization track for the target
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
					
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
	}

	UnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	if(UnitState != None && UnitState.IsDead())
	{
		// If the unit is dead then do the death action
		class'X2Action_Death'.static.AddToVisualizationTrack(BuildTrack, Context);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************


	//****************************************************************************************
	//Configure a visualization track for any enemy unit that would witness the unburrow.
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	class'X2TacticalVisibilityHelpers'.static.GetEnemyViewersOfTarget(InteractingUnitRef.ObjectID, EnemyUnitsThatSeeThisUnit);

	if ( EnemyUnitsThatSeeThisUnit.Length > 0 )
	{
		BuildTrack.TrackActor = History.GetVisualizer(EnemyUnitsThatSeeThisUnit[0].ObjectID);
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(EnemyUnitsThatSeeThisUnit[0].ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;

		// Note: despite the cue name, 'TrippedBurrow', this cue is to be played when witnessing a chryssalid unburrow.
		// This is by instruction from Griffin F, and is consistent with the recorded lines.  mdomowicz 2015_07_08
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'TrippedBurrow', eColor_Good);
		
		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************

}

static function X2AbilityTemplate CreateBurrowedAttackAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local X2Condition_UnitEffects RequiredEffects;
	local X2Effect_ChryssalidBurrowedAttack BehaviorTreeEffect;
	local X2AbilityMultiTarget_Radius RadiusMultiTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BurrowedAttack');

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_overwatch";
	Template.bDisplayInUITooltip = false;
	Template.bDisplayInUITacticalText = false;
	Template.DisplayTargetHitChance = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	// The Target a living enemy
	Template.AbilityMultiTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);

	// The shooter must be burrowed
	RequiredEffects = new class'X2Condition_UnitEffects';
	RequiredEffects.AddRequireEffect(class'X2AbilityTemplateManager'.default.BurrowedName, 'AA_UnitIsNotBurrowed');

	Template.AbilityShooterConditions.AddItem(RequiredEffects);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.bIgnoreBlockingCover = true;
	RadiusMultiTarget.fTargetRadius = default.BURROWED_ATTACK_RANGE_METERS;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.CheckForVisibleMovementInRadius_Self;
	Trigger.ListenerData.EventID = 'UnitMoveFinished';
	Template.AbilityTriggers.AddItem(Trigger);

	BehaviorTreeEffect = new class'X2Effect_ChryssalidBurrowedAttack';
	BehaviorTreeEffect.EffectName = 'ChryssalidBurrowedAttackAI';
	BehaviorTreeEffect.DuplicateResponse = eDupe_Refresh;
	BehaviorTreeEffect.BuildPersistentEffect(1, , , , eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(BehaviorTreeEffect);

	Template.AddMultiTargetEffect(new class'X2Effect_BreakUnitConcealment');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;	
}

static function X2AbilityTemplate CreateUnburrowSawEnemyAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Condition_UnitEffects RequiredEffects;
	local X2Effect_Persistent UnburrowCheck;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'UnburrowSawEnemy');

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.none";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.CheckForVisibleMovementInSightRadius_Self;
	Trigger.ListenerData.EventID = 'UnitMoveFinished';
	Template.AbilityTriggers.AddItem(Trigger);

	// Only triggers from player controlled units moving in range
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.IsPlayerControlled = false;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);

	RequiredEffects = new class'X2Condition_UnitEffects';
	RequiredEffects.AddRequireEffect(class'X2AbilityTemplateManager'.default.BurrowedName, 'AA_UnitIsNotBurrowed');
	Template.AbilityShooterConditions.AddItem(RequiredEffects);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Only triggers from player controlled units moving in range
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.IsPlayerControlled = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	UnburrowCheck = new class'X2Effect_Persistent';
	UnburrowCheck.DuplicateResponse = eDupe_Refresh;
	UnburrowCheck.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	UnburrowCheck.iInitialShedChance = default.UNBURROW_PERCENT_CHANCE;
	UnburrowCheck.ChanceEventTriggerName = default.UnburrowTriggerEventName;
	UnburrowCheck.EffectName = default.UnburrowTriggerCheckEffectName;
	Template.AddShooterEffect(UnburrowCheck);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}

static function X2AbilityTemplate CreateImmunitiesAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_UnitPostBeginPlay Trigger;
	local X2Effect_DamageImmunity DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChryssalidImmunities');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_immunities";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// Build the immunities
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.BuildPersistentEffect(1, true, true, true);
	DamageImmunity.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	DamageImmunity.ImmuneTypes.AddItem('Poison');
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);

	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

// #######################################################################################
// -------------------- MP Abilities -----------------------------------------------------
// #######################################################################################

static function X2AbilityTemplate CreateSlashMPAbility(optional Name AbilityName = 'ChryssalidSlashMP')
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee MeleeHitCalc;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local X2Effect_ParthenogenicPoison ParthenogenicPoisonEffect;
	local X2AbilityTarget_MovingMelee MeleeTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_slash";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.MP_PerkOverride = 'ChryssalidSlash';

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	MeleeHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = MeleeHitCalc;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false; // Disable this to allow civilians to be attacked.
	UnitPropertyCondition.ExcludeSquadmates = true;		   // Don't attack other AI units.
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	ParthenogenicPoisonEffect = new class'X2Effect_ParthenogenicPoison';
	ParthenogenicPoisonEffect.UnitToSpawnName = 'ChryssalidCocoonMP';
	ParthenogenicPoisonEffect.AltUnitToSpawnName = 'ChryssalidCocoonHumanMP';
	ParthenogenicPoisonEffect.BuildPersistentEffect(default.POISON_DURATION, true, false, false, eGameRule_PlayerTurnEnd);
	ParthenogenicPoisonEffect.SetDisplayInfo(ePerkBuff_Penalty, default.ParthenogenicPoisonFriendlyName, default.ParthenogenicPoisonFriendlyDesc, Template.IconImage, true);
	ParthenogenicPoisonEffect.DuplicateResponse = eDupe_Ignore;
	ParthenogenicPoisonEffect.SetPoisonDamageDamage();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeDead = false;
	ParthenogenicPoisonEffect.TargetConditions.AddItem(UnitPropertyCondition);
	Template.AddTargetEffect(ParthenogenicPoisonEffect);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.CHRYSSALIDMP_MELEEATTACK_BASEDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	Template.AddTargetEffect(PhysicalDamageEffect);

	MeleeTarget = new class'X2AbilityTarget_MovingMelee';
	MeleeTarget.MovementRangeAdjustment = 0;
	Template.AbilityTargetStyle = MeleeTarget;
	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_PlayerInput');
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');

	Template.CustomFireAnim = 'FF_Melee';
	Template.bSkipMoveStop = true;
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.CinescriptCameraType = "Chryssalid_PoisonousClaws";

	return Template;
}

DefaultProperties
{
	UnburrowTriggerEventName="UnburrowCheckTrigger"
	UnburrowTriggerCheckEffectName="UnburrowTriggerCheckEffect"
}