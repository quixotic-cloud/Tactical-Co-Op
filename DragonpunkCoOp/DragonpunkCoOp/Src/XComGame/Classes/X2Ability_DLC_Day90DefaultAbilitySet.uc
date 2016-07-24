//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_DLC_Day90DefaultAbilitySet.uc
//  AUTHOR:  David Burchanowski --  4/18/2016
//  PURPOSE: Defines additional "default" abilities that are not item assigned
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Ability_DLC_Day90DefaultAbilitySet extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local X2AbilityTemplate AbilityTemplate;

	AbilityTemplate = class'X2Ability_DefaultAbilitySet'.static.AddInteractAbility('Interact_ActivateSpark');
	AbilityTemplate.RemoveTemplateAvailablility(AbilityTemplate.BITFIELD_GAMEAREA_Multiplayer);
	Templates.AddItem(AbilityTemplate);
	
	AbilityTemplate = class'X2Ability_DefaultAbilitySet'.static.AddHackAbility('Hack_ElevatorControl');
	AbilityTemplate.RemoveTemplateAvailablility(AbilityTemplate.BITFIELD_GAMEAREA_Multiplayer);
	Templates.AddItem(AbilityTemplate);

	AbilityTemplate = class'X2Ability_DefaultAbilitySet'.static.AddInteractAbility('Interact_AtmosphereComputer');
	AbilityTemplate.RemoveTemplateAvailablility(AbilityTemplate.BITFIELD_GAMEAREA_Multiplayer);
	Templates.AddItem(AbilityTemplate);
	
	Templates.AddItem( CreateUseElevatorAbility());

	AbilityTemplate = class'X2Ability_SpecialistAbilitySet'.static.ConstructIntrusionProtocol('IntrusionProtocol_Hack_ElevatorControl', 'Hack_ElevatorControl');
	AbilityTemplate.RemoveTemplateAvailablility(AbilityTemplate.BITFIELD_GAMEAREA_Multiplayer);
	Templates.AddItem(AbilityTemplate);

	return Templates;
}

static function X2AbilityTemplate CreateUseElevatorAbility()
{
	local X2AbilityTemplate Template;
	local X2Condition ShooterCondition;

	Template = class'X2Ability_DefaultAbilitySet'.static.AddInteractAbility('Interact_UseElevator');
	Template.RemoveTemplateAvailablility(Template.BITFIELD_GAMEAREA_Multiplayer);

	// No cost, allows it to be used anytime, even at end of turn if available
	Template.AbilityCosts.Length = 0;

	// You can use the elevator even if you are carrying somebody
	foreach Template.AbilityShooterConditions(ShooterCondition)
	{
		if(X2Condition_UnitEffects(ShooterCondition) != none)
		{
			X2Condition_UnitEffects(ShooterCondition).RemoveExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
		}
	}

	return Template;
}

