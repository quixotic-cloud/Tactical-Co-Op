class X2Ability_Berserker extends X2Ability
	config(GameData_SoldierSkills);

var config int RAGE_APPLY_CHANCE_PERCENT;
var config float RAGE_MOBILITY_MULTIPLY_MODIFIER;
var config int MELEE_RESISTANCE_ARMOR;

var localized string RageTriggeredFriendlyName;
var localized string RageTriggeredFriendlyDesc;
var localized string LocRageFlyover;
var localized string BlindRageFlyover;

var name RageTriggeredEffectName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateTriggerRageDamageListenerAbility());
	Templates.AddItem(CreateTriggerRageAbility());
	Templates.AddItem(PurePassive('Rage', "img:///UILibrary_PerkIcons.UIPerk_beserk"));
	Templates.AddItem(CreateMeleeResistanceAbility());
	Templates.AddItem(CreateDevastatingPunchAbility());

	// MP Versions of Abilities
	Templates.AddItem(CreateDevastatingPunchAbilityMP());

	return Templates;
}

static function X2AbilityTemplate CreateTriggerRageDamageListenerAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Effect_RunBehaviorTree RageBehaviorEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TriggerRageDamageListener');
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.bDontDisplayInAbilitySummary = true;

	Template.AdditionalAbilities.AddItem('Rage');
	Template.AdditionalAbilities.AddItem('TriggerRage');

	// This ability fires when the unit takes damage
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitTakeEffectDamage';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AbilityTargetStyle = default.SelfTarget;

	RageBehaviorEffect = new class'X2Effect_RunBehaviorTree';
	RageBehaviorEffect.BehaviorTreeName = 'TryTriggerRage';
	Template.AddTargetEffect(RageBehaviorEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateTriggerRageAbility()
{
	local X2AbilityTemplate Template;
	local X2Effect_PersistentStatChange RageTriggeredPersistentEffect;
	local X2Condition_UnitEffects RageTriggeredCondition;
	local array<name> SkipExclusions;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'TriggerRage');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_beserk";

	Template.bDontDisplayInAbilitySummary = true;
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	// Rage may trigger if the unit is burning
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// Check to make sure rage has been activated
	RageTriggeredCondition = new class'X2Condition_UnitEffects';
	RageTriggeredCondition.AddExcludeEffect(default.RageTriggeredEffectName, 'AA_UnitRageTriggered');
	Template.AbilityShooterConditions.AddItem(RageTriggeredCondition);

	// Create the Rage Triggered Effect
	RageTriggeredPersistentEffect = new class'X2Effect_PersistentStatChange';
	RageTriggeredPersistentEffect.EffectName = default.RageTriggeredEffectName;
	RageTriggeredPersistentEffect.BuildPersistentEffect(1, true, true, true);
	RageTriggeredPersistentEffect.SetDisplayInfo(ePerkBuff_Bonus, default.RageTriggeredFriendlyName, default.RageTriggeredFriendlyDesc, Template.IconImage, true);
	RageTriggeredPersistentEffect.DuplicateResponse = eDupe_Ignore;
	RageTriggeredPersistentEffect.EffectHierarchyValue = class'X2StatusEffects'.default.RAGE_HIERARCHY_VALUE;
	RageTriggeredPersistentEffect.AddPersistentStatChange(eStat_Mobility, default.RAGE_MOBILITY_MULTIPLY_MODIFIER, MODOP_Multiplication);
	RageTriggeredPersistentEffect.ApplyChanceFn = ApplyChance_Rage;
	RageTriggeredPersistentEffect.VisualizationFn = RageTriggeredVisualization;
	Template.AddTargetEffect(RageTriggeredPersistentEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Berserker_Rage";

	return Template;
}

static function name ApplyChance_Rage(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local int RandRoll;

	UnitState = XComGameState_Unit(kNewTargetState);
	if( UnitState.GetCurrentStat(eStat_HP) <= (UnitState.GetMaxStat(eStat_HP) / 2) )
	{
		// If the current health is <= to half her max health, attach the Rage effect
		`log("Success!");
		return 'AA_Success';
	}

	if (default.RAGE_APPLY_CHANCE_PERCENT > 0)
	{
		RandRoll = `SYNC_RAND_STATIC(100);

		`log("ApplyChance_Rage check chance" @ default.RAGE_APPLY_CHANCE_PERCENT @ "rolled" @ RandRoll);
		if (RandRoll <= default.RAGE_APPLY_CHANCE_PERCENT)
		{
			`log("Success!");
			return 'AA_Success';
		}
		`log("Failed.");
	}

	return 'AA_EffectChanceFailed';
}

static function RageTriggeredVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_PlayAnimation PlayAnimation;

	if (EffectApplyResult != 'AA_Success')
		return;

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.LocRageFlyover, '', eColor_Good);

	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
	PlayAnimation.Params.AnimName = 'NO_Rage';
}

//******** Melee Resistance Ability **********
static function X2AbilityTemplate CreateMeleeResistanceAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTargetStyle TargetStyle;
	local X2Effect_MeleeDamageAdjust MeleeArmor;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MeleeResistance');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_absorption_fields";

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	// This ability will only be targeting the unit it is on
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	// Triggers at the start of the tactical
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	MeleeArmor = new class'X2Effect_MeleeDamageAdjust';
	MeleeArmor.BuildPersistentEffect(1, true, true, true);
	MeleeArmor.DamageMod = default.MELEE_RESISTANCE_ARMOR;
	MeleeArmor.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	Template.AddTargetEffect(MeleeArmor);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateDevastatingPunchAbility(optional Name AbilityName = 'DevastatingPunch', int MovementRangeAdjustment=1)
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee MeleeHitCalc;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local X2Effect_ImmediateAbilityActivation BrainDamageAbilityEffect;
	local X2AbilityTarget_MovingMelee MeleeTarget;
	local X2Effect_Knockback KnockbackEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_muton_punch";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	Template.AdditionalAbilities.AddItem(class'X2Ability_Impairing'.default.ImpairingAbilityName);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	MeleeHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = MeleeHitCalc;

	MeleeTarget = new class'X2AbilityTarget_MovingMelee';
	MeleeTarget.MovementRangeAdjustment = MovementRangeAdjustment;
	Template.AbilityTargetStyle = MeleeTarget;
	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_PlayerInput');
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	// May punch if the unit is burning or disoriented
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.AbilityTargetConditions.AddItem(new class'X2Condition_BerserkerDevastatingPunch');	
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	//Impairing effects need to come before the damage. This is needed for proper visualization ordering.
	//Effect on a successful melee attack is triggering the BrainDamage Ability
	BrainDamageAbilityEffect = new class 'X2Effect_ImmediateAbilityActivation';
	BrainDamageAbilityEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	BrainDamageAbilityEffect.EffectName = 'ImmediateBrainDamage';
	// NOTICE: For now StunLancer, Muton, and Berserker all use this ability. This may change.
	BrainDamageAbilityEffect.AbilityName = class'X2Ability_Impairing'.default.ImpairingAbilityName;
	BrainDamageAbilityEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	BrainDamageAbilityEffect.bRemoveWhenTargetDies = true;
	BrainDamageAbilityEffect.VisualizationFn = class'X2Ability_Impairing'.static.ImpairingAbilityEffectTriggeredVisualization;
	Template.AddTargetEffect(BrainDamageAbilityEffect);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.BERSERKER_MELEEATTACK_BASEDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	Template.AddTargetEffect(PhysicalDamageEffect);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.BERSERKER_MELEEATTACK_MISSDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	PhysicalDamageEffect.bApplyOnHit=False;
	PhysicalDamageEffect.bApplyOnMiss=True;
	PhysicalDamageEffect.bIgnoreBaseDamage=True;
	Template.AddTargetEffect(PhysicalDamageEffect);

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.KnockbackDistance = 5; //Knockback 5 meters
	Template.AddTargetEffect(KnockbackEffect);

	Template.CustomFireAnim = 'FF_Melee';
	Template.bSkipMoveStop = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.bOverrideMeleeDeath = true;
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildVisualizationFn = DevastatingPunchAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.CinescriptCameraType = "Berserker_DevastatingPunch";
	
	return Template;
}

function DevastatingPunchAbility_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameState_Unit SourceState, TargetState;
	local XComGameStateContext_Ability  Context;
	local VisualizationTrack				BuildTrack;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;

	TypicalAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
	
	// Check if we should add a fly-over for 'Blind Rage' (iff both source and target are AI).
	History = `XCOMHISTORY;
	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	SourceState = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.SourceObject.ObjectID));
	if( SourceState.ControllingPlayerIsAI() && SourceState.IsUnitAffectedByEffectName(RageTriggeredEffectName))
	{
		TargetState = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
		if( TargetState.GetTeam() == SourceState.GetTeam() )
		{
			BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(SourceState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
			BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(SourceState.ObjectID);
			BuildTrack.TrackActor = History.GetVisualizer(SourceState.ObjectID);

			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
 			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, default.BlindRageFlyover, '', eColor_Good);
			OutVisualizationTracks.AddItem(BuildTrack);
		}
	}
}

// #######################################################################################
// -------------------- MP Abilities -----------------------------------------------------
// #######################################################################################

static function X2AbilityTemplate CreateDevastatingPunchAbilityMP(optional Name AbilityName = 'DevastatingPunchMP')
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee MeleeHitCalc;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local X2Effect_ImmediateAbilityActivation BrainDamageAbilityEffect;
	local X2AbilityTarget_MovingMelee MeleeTarget;
	//local X2Effect_Knockback KnockbackEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_muton_punch";
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.MP_PerkOverride = 'DevastatingPunch';

	Template.AdditionalAbilities.AddItem(class'X2Ability_Impairing'.default.ImpairingAbilityName);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	MeleeHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = MeleeHitCalc;

	MeleeTarget = new class'X2AbilityTarget_MovingMelee';
	Template.AbilityTargetStyle = MeleeTarget;
	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_PlayerInput');
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_EndOfMove');

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	// May punch if the unit is burning or disoriented
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	Template.AbilityTargetConditions.AddItem(new class'X2Condition_BerserkerDevastatingPunch');
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.BERSERKERMP_MELEEATTACK_BASEDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	Template.AddTargetEffect(PhysicalDamageEffect);

	//Impairing effects need to come before the damage. This is needed for proper visualization ordering.
	//Effect on a successful melee attack is triggering the BrainDamage Ability
	BrainDamageAbilityEffect = new class 'X2Effect_ImmediateAbilityActivation';
	BrainDamageAbilityEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	BrainDamageAbilityEffect.EffectName = 'ImmediateBrainDamage';
	// NOTICE: For now StunLancer, Muton, and Berserker all use this ability. This may change.
	BrainDamageAbilityEffect.AbilityName = class'X2Ability_Impairing'.default.ImpairingAbilityName;
	BrainDamageAbilityEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	BrainDamageAbilityEffect.bRemoveWhenTargetDies = true;
	BrainDamageAbilityEffect.VisualizationFn = class'X2Ability_Impairing'.static.ImpairingAbilityEffectTriggeredVisualization;
	Template.AddTargetEffect(BrainDamageAbilityEffect);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.BERSERKER_MELEEATTACK_MISSDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	PhysicalDamageEffect.bApplyOnHit = False;
	PhysicalDamageEffect.bApplyOnMiss = True;
	PhysicalDamageEffect.bIgnoreBaseDamage = True;
	Template.AddTargetEffect(PhysicalDamageEffect);

	//KnockbackEffect = new class'X2Effect_Knockback';
	//KnockbackEffect.KnockbackDistance = 5; //Knockback 5 meters
	//Template.AddTargetEffect(KnockbackEffect);

	Template.CustomFireAnim = 'FF_Melee';
	Template.bSkipMoveStop = true;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.bOverrideMeleeDeath = true;
	Template.BuildNewGameStateFn = TypicalMoveEndAbility_BuildGameState;
	Template.BuildVisualizationFn = DevastatingPunchAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalMoveEndAbility_BuildInterruptGameState;
	Template.CinescriptCameraType = "Berserker_DevastatingPunch";

	return Template;
}

defaultproperties
{
	RageTriggeredEffectName="RageTriggered" //String change requires updating DefaultAI.ini
}