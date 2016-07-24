//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Ability_DebugAbilities
//  AUTHOR:  Dan Kaplan -- 2/5/15
//  PURPOSE: Debug abilities for use with the X2UseAbility cheat command. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2Ability_DebugAbilities extends X2Ability;


static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateApplyBurningAbility());

	return Templates;
}

static function X2AbilityTemplate CreateApplyBurningAbility()
{
	local X2AbilityTemplate Template;	

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ApplyBurning');

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.bUseAmmoAsChargesForHUD = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateBurningStatusEffect(1, 0));

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	// This action is considered 'offensive'
	Template.Hostility = eHostility_Offensive;
 
	return Template;
}

