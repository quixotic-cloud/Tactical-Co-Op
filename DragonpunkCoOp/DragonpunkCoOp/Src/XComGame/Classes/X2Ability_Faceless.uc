//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_Faceless extends X2Ability
	config(GameData_SoldierSkills);

var config int REGENERATION_HEAL_VALUE;
var config int STABBING_CLAWS_RANGE;
var config int SCYTHING_CLAWS_LENGTH_TILES;
var config int SCYTHING_CLAWS_END_DIAMETER_TILES;
var config int AREA_MELEE_ENVIRONMENT_DAMAGE;
var config float CIVILIAN_MORPH_RANGE_METERS;
var config int CHANGE_FORM_PERCENT_CHANCE;

var config int REGENERATION_HEALMP_VALUE;

var privatewrite name ChangeFormTriggerEventName;
var private name ChangeFormCheckEffectName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateFacelessInitAbility());
	Templates.AddItem(PurePassive('Regeneration', "img:///UILibrary_PerkIcons.UIPerk_rapidregeneration"));
	Templates.AddItem(CreateScythingClawsAbility());
	Templates.AddItem(CreateChangeFormAbility());
	Templates.AddItem(CreateChangeFormSawEnemyAbility());

	// MP Versions of Abilities
	Templates.AddItem(CreateFacelessInitMPAbility());
	Templates.AddItem(PurePassive('FacelessRegenerationMP', "img:///UILibrary_PerkIcons.UIPerk_rapidregeneration"));
	Templates.AddItem(CreateScythingClawsMPAbility());

	return Templates;
}

static function X2AbilityTemplate CreateFacelessInitAbility()
{
	local X2AbilityTemplate Template;
	local X2Effect_Regeneration RegenerationEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FacelessInit');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter"; // TODO: This needs to be changed
	Template.bCausesCheckFirstSightingOfEnemyGroup = true;  // Check when this unit first spawns

	Template.bDontDisplayInAbilitySummary = true;

	Template.AdditionalAbilities.AddItem('Regeneration');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the regeneration effect
	RegenerationEffect = new class'X2Effect_Regeneration';
	RegenerationEffect.BuildPersistentEffect(1,  true, true, false, eGameRule_PlayerTurnBegin);
//	RegenerationEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	RegenerationEffect.HealAmount = default.REGENERATION_HEAL_VALUE;
	Template.AddTargetEffect(RegenerationEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateScythingClawsAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee MeleeHitCalc;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityMultiTarget_Cone ConeMultiTarget;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ScythingClaws');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_chargeandslash";

	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	MeleeHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = MeleeHitCalc;

	Template.TargetingMethod = class'X2TargetingMethod_Cone';

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = false;
	CursorTarget.FixedAbilityRange = default.SCYTHING_CLAWS_LENGTH_TILES * class'XComWorldData'.const.WORLD_StepSize;
	Template.AbilityTargetStyle = CursorTarget;

	ConeMultiTarget = new class'X2AbilityMultiTarget_Cone';
	ConeMultiTarget.ConeEndDiameter = default.SCYTHING_CLAWS_END_DIAMETER_TILES * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.ConeLength = default.SCYTHING_CLAWS_LENGTH_TILES * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.fTargetRadius = Sqrt( Square(ConeMultiTarget.ConeEndDiameter / 2) + Square(ConeMultiTarget.ConeLength) ) * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	ConeMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
	Template.AbilityMultiTargetStyle = ConeMultiTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	// May attack if the unit is burning or disoriented
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Primary Target
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeCosmetic = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.FACELESS_MELEEAOE_BASEDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	PhysicalDamageEffect.EnvironmentalDamageAmount = default.AREA_MELEE_ENVIRONMENT_DAMAGE;
	Template.AddTargetEffect(PhysicalDamageEffect);

	// Multi Targets
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.RequireWithinRange = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);	

	Template.AddMultiTargetEffect(PhysicalDamageEffect);

	Template.CustomFireAnim = 'NO_ScythingClawsSlash';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Faceless_ScythingClaws";
	
	return Template;
}

// This ability is built as a single player mechanic and that it will be placed onto
// a civilian unit. If this spec changes, this ability needs to be revisited.
static function X2AbilityTemplate CreateChangeFormAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local X2AbilityMultiTarget_Radius RadiusMultiTarget;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Condition_UnitValue NotAlreadyChangedFormCondition;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChangeForm');

	Template.AdditionalAbilities.AddItem('ChangeFormSawEnemy');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.none";

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = false;
	RadiusMultiTarget.fTargetRadius = default.CIVILIAN_MORPH_RANGE_METERS;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	// Only triggers from player controlled units moving in range
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.IsPlayerControlled = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	// May change form if the unit is burning or disoriented
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	//If two of the following triggers occur simultaneously, the ability may try to trigger twice before the civilian unit is removed.
	//This conditional will catch and prevent this from happening.
	NotAlreadyChangedFormCondition = new class'X2Condition_UnitValue';
	NotAlreadyChangedFormCondition.AddCheckValue(class'X2Effect_SpawnFaceless'.default.SpawnedUnitValueName, 0);
	Template.AbilityShooterConditions.AddItem(NotAlreadyChangedFormCondition);

	// This ability fires when an enemy unit moves within range
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.CheckForVisibleMovementInRadius_Self;
	Trigger.ListenerData.EventID = 'UnitMoveFinished';
	Template.AbilityTriggers.AddItem(Trigger);
	
	// This ability fires can when the unit takes damage
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'UnitTakeEffectDamage';
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(Trigger);

	// This ability fires can when the unit passes a check after seeing an enemy
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = default.ChangeFormTriggerEventName;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Trigger.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(Trigger);

	// This ability fires when any unit dies - check if any active AI remain. If not, transform.
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'UnitDied';
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.FacelessOnDeathListener;
	Template.AbilityTriggers.AddItem(Trigger);

	Template.AddTargetEffect(new class'X2Effect_SpawnFaceless');

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.ChangeFormCheckEffectName);
	Template.AddTargetEffect(RemoveEffects);

	Template.AddMultiTargetEffect(new class'X2Effect_BreakUnitConcealment');

	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Always;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = ChangeForm_BuildVisualization;
	Template.CinescriptCameraType = "Faceless_ChangeForm";

	return Template;
}

simulated function ChangeForm_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local StateObjectReference InteractingUnitRef;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack CivilianTrack, FacelessTrack;
	local X2Action_MoveTurn MoveTurnAction;
	local XComGameState_Unit MovedUnitState;
	local XComGameState_Unit CivilianUnit, SpawnedUnit;
	local UnitValue SpawnedUnitValue;
	local X2Effect_SpawnFaceless SpawnFacelessEffect;
	
	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	CivilianTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(InteractingUnitRef.ObjectID,
													   CivilianTrack.StateObject_OldState, CivilianTrack.StateObject_NewState,
													   eReturnType_Reference,
													   VisualizeGameState.HistoryIndex);
	CivilianTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	CivilianUnit = XComGameState_Unit(CivilianTrack.StateObject_NewState);

	if( Context.InputContext.MultiTargets.Length > 0 )
	{
		// Turn to face the moved unit
		MovedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(Context.InputContext.MultiTargets[0].ObjectID));

		MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTrack(CivilianTrack, Context));
		MoveTurnAction.m_vFacePoint = `XWORLD.GetPositionFromTileCoordinates(MovedUnitState.TileLocation);
	}

	// Play the civilian and Faceless change form actions
	CivilianUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

	FacelessTrack = EmptyTrack;
	FacelessTrack.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	FacelessTrack.StateObject_NewState = FacelessTrack.StateObject_OldState;
	SpawnedUnit = XComGameState_Unit(FacelessTrack.StateObject_NewState);
	`assert(SpawnedUnit != none);
	FacelessTrack.TrackActor = History.GetVisualizer(SpawnedUnit.ObjectID);

	// Only one target effect and it is X2Effect_SpawnFaceless
	SpawnFacelessEffect = X2Effect_SpawnFaceless(Context.ResultContext.TargetEffectResults.Effects[0]);

	if( SpawnFacelessEffect == none )
	{
		`RedScreenOnce("ChangeForm_BuildVisualization: Missing X2Effect_SpawnFaceless -dslonneger @gameplay");
		return;
	}

	SpawnFacelessEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, FacelessTrack, CivilianUnit, CivilianTrack);

	OutVisualizationTracks.AddItem(FacelessTrack);
	OutVisualizationTracks.AddItem(CivilianTrack);
}

static function X2AbilityTemplate CreateChangeFormSawEnemyAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener Trigger;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2Effect_Persistent ChangeFormCheck;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ChangeFormSawEnemy');

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

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Only triggers from player controlled units moving in range
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.IsPlayerControlled = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeConcealed = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	ChangeFormCheck = new class'X2Effect_Persistent';
	ChangeFormCheck.DuplicateResponse = eDupe_Refresh;
	ChangeFormCheck.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	ChangeFormCheck.iInitialShedChance = default.CHANGE_FORM_PERCENT_CHANCE;
	ChangeFormCheck.ChanceEventTriggerName = default.ChangeFormTriggerEventName;
	ChangeFormCheck.EffectName = default.ChangeFormCheckEffectName;
	Template.AddShooterEffect(ChangeFormCheck);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}

// #######################################################################################
// -------------------- MP Abilities -----------------------------------------------------
// #######################################################################################

static function X2AbilityTemplate CreateFacelessInitMPAbility()
{
	local X2AbilityTemplate Template;
	local X2Effect_Regeneration RegenerationEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FacelessInitMP');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter"; // TODO: This needs to be changed
	Template.MP_PerkOverride = 'FacelessInit';
	Template.bCausesCheckFirstSightingOfEnemyGroup = true;  // Check when this unit first spawns

	Template.bDontDisplayInAbilitySummary = true;

	Template.AdditionalAbilities.AddItem('FacelessRegenerationMP');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the regeneration effect
	RegenerationEffect = new class'X2Effect_Regeneration';
	RegenerationEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	//	RegenerationEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	RegenerationEffect.HealAmount = default.REGENERATION_HEALMP_VALUE;
	Template.AddTargetEffect(RegenerationEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateScythingClawsMPAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityToHitCalc_StandardMelee MeleeHitCalc;
	local X2Condition_UnitProperty UnitPropertyCondition;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityMultiTarget_Cone ConeMultiTarget;
	local X2Effect_ApplyWeaponDamage PhysicalDamageEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ScythingClawsMP');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_chryssalid_chargeandslash";
	Template.MP_PerkOverride = 'ScythingClaws';

	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	MeleeHitCalc = new class'X2AbilityToHitCalc_StandardMelee';
	Template.AbilityToHitCalc = MeleeHitCalc;

	Template.TargetingMethod = class'X2TargetingMethod_Cone';

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = false;
	CursorTarget.FixedAbilityRange = default.SCYTHING_CLAWS_LENGTH_TILES * class'XComWorldData'.const.WORLD_StepSize;
	Template.AbilityTargetStyle = CursorTarget;

	ConeMultiTarget = new class'X2AbilityMultiTarget_Cone';
	ConeMultiTarget.ConeEndDiameter = default.SCYTHING_CLAWS_END_DIAMETER_TILES * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.ConeLength = default.SCYTHING_CLAWS_LENGTH_TILES * class'XComWorldData'.const.WORLD_StepSize;
	ConeMultiTarget.fTargetRadius = Sqrt(Square(ConeMultiTarget.ConeEndDiameter / 2) + Square(ConeMultiTarget.ConeLength)) * class'XComWorldData'.const.WORLD_UNITS_TO_METERS_MULTIPLIER;
	ConeMultiTarget.bExcludeSelfAsTargetIfWithinRadius = true;
	Template.AbilityMultiTargetStyle = ConeMultiTarget;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	
	// May attack if the unit is burning or disoriented
	SkipExclusions.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// Primary Target
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.ExcludeCosmetic = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.FACELESSMP_MELEEAOE_BASEDAMAGE;
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	PhysicalDamageEffect.EnvironmentalDamageAmount = default.AREA_MELEE_ENVIRONMENT_DAMAGE;
	Template.AddTargetEffect(PhysicalDamageEffect);

	// Multi Targets
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.RequireWithinRange = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);

	Template.AddMultiTargetEffect(PhysicalDamageEffect);

	Template.CustomFireAnim = 'NO_ScythingClawsSlash';
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Faceless_ScythingClaws";

	return Template;
}

DefaultProperties
{
	ChangeFormTriggerEventName="ChangeFormCheckTrigger"
	ChangeFormCheckEffectName="ChangeFormCheckEffect"
}