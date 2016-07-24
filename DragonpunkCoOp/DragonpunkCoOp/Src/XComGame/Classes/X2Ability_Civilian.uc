//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_Civilian.uc
//  AUTHOR:  Alex Cheng  --  5/13/2015
//  PURPOSE: Provides ability definitions for Civilian
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_Civilian extends X2Ability config(GameData_SoldierSkills);

var config int EasyToHitMod;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateInitialStateAbility());
	Templates.AddItem(CreateCivilianPanicAbility());
	Templates.AddItem(CivilianEasyToHit());
	Templates.AddItem(CreateCivilianRescuedStateAbility());
	return Templates;
}

// Add initial ability on PostBeginPlay to initialize Civilian with panic effects on terror missions.
static function X2AbilityTemplate CreateInitialStateAbility()
{
	local X2AbilityTemplate					Template;
	local X2AbilityTrigger_UnitPostBeginPlay Trigger;
	local X2Effect_Panicked		            CivilianPanickedEffect;
	local X2Effect_UnblockPathing			CivilianUnblockPathingEffect;
	local X2Condition_BattleState			TerrorCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CivilianInitialState');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	TerrorCondition = new class'X2Condition_BattleState';
	TerrorCondition.bCiviliansTargetedByAliens = true;
	Template.AbilityShooterConditions.AddItem(TerrorCondition);

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	// Set initial effect - panicked effect.
	CivilianPanickedEffect = class'X2StatusEffects'.static.CreateCivilianPanickedStatusEffect();
	Template.AddTargetEffect(CivilianPanickedEffect);
	// Set initial effect - disable blocking.
	CivilianUnblockPathingEffect = class'X2StatusEffects'.static.CreateCivilianUnblockedStatusEffect();
	Template.AddShooterEffect(CivilianUnblockPathingEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	return Template;
}

// For non-terror missions, Panic is kicked off on all civilians by squad concealment being broken.
static function X2DataTemplate CreateCivilianPanicAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Condition_UnitProperty          Condition;
	local X2AbilityTrigger_EventListener EventListener;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_BattleState			TerrorCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CivilianPanicked');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bFreeCost = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.CinescriptCameraType = "Panic";

	Template.AbilityToHitCalc = default.DeadEye;

	TerrorCondition = new class'X2Condition_BattleState';
	TerrorCondition.bCiviliansNotTargetedByAliens = true;
	Template.AbilityShooterConditions.AddItem(TerrorCondition);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilitySourceName = 'eAbilitySource_Standard';

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'SquadConcealmentBroken';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Filter = eFilter_None;
	Template.AbilityTriggers.AddItem(EventListener);

	Template.AddShooterEffectExclusions();

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.AddShooterEffect(class'X2StatusEffects'.static.CreateCivilianPanickedStatusEffect());

	Condition = new class'X2Condition_UnitProperty';
	Condition.ExcludeRobotic = true;
	Condition.ExcludeImpaired = true;
	Condition.ExcludePanicked = true;
	Template.AbilityShooterConditions.AddItem(Condition);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;

	return Template;
}

static function X2AbilityTemplate CivilianEasyToHit()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ToHitModifier                HitEffect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'CivilianEasyToHit');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	HitEffect = new class'X2Effect_ToHitModifier';
	HitEffect.BuildPersistentEffect(1, true, false, false);
	HitEffect.bApplyAsTarget = true;
	HitEffect.AddEffectHitModifier(eHit_Success, default.EasyToHitMod, Template.LocFriendlyName);
	Template.AddTargetEffect(HitEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}


// Add shadowstep ability to civilians upon getting rescued, preventing them from being overwatch-shot.
static function X2AbilityTemplate CreateCivilianRescuedStateAbility()
{
	local X2AbilityTemplate						Template;
	local X2Effect_Persistent                   Effect;
	local X2AbilityTrigger_EventListener	Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CivilianRescuedState');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shadowstep";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'CivilianRescued';
	Trigger.ListenerData.Filter = eFilter_Unit;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	Effect = new class'X2Effect_Persistent';
	Effect.EffectName = 'Shadowstep';
	Effect.DuplicateResponse = eDupe_Ignore;
	Effect.BuildPersistentEffect(1, true, false);
	Template.AddTargetEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}
DefaultProperties
{
}