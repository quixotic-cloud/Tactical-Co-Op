class X2StrategyElement_DefaultSoldierPersonalities extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
		
	Templates.AddItem(Personality_ByTheBook());
	Templates.AddItem(Personality_LaidBack());
	Templates.AddItem(Personality_Normal());
	Templates.AddItem(Personality_Twitchy());
	Templates.AddItem(Personality_HappyGoLucky());
	Templates.AddItem(Personality_HardLuck());
	Templates.AddItem(Personality_Intense());

	return Templates;
}

static function X2SoldierPersonalityTemplate Personality_ByTheBook()
{
	local X2SoldierPersonalityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierPersonalityTemplate', Template, 'Personality_ByTheBook');

	Template.IdleAnimName = 'Idle_ByTheBook_TG02';
	Template.PostMissionWalkUpAnimName = 'WalkUp_ByTheBook_TG02';
	Template.PostMissionWalkBackAnimName = 'WalkBack_ByTheBook_TG02';
	Template.PostMissionGravelyInjuredWalkUpAnimName = 'WalkUp_InjuredKneelB_TG03';
	Template.IdleGravelyInjuredAnimName = 'Idle_InjuredKneelB_TG03';
	Template.PostMissionInjuredWalkUpAnimName = 'WalkUp_InjuredA';
	Template.IdleInjuredAnimName = 'Idle_InjuredA';
	
	return Template;
}

static function X2SoldierPersonalityTemplate Personality_LaidBack()
{
	local X2SoldierPersonalityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierPersonalityTemplate', Template, 'Personality_LaidBack');

	Template.IdleAnimName = 'Idle_LaidBackC_TG03';
	Template.PostMissionWalkUpAnimName = 'WalkUp_LaidBackC_TG03';
	Template.PostMissionWalkBackAnimName = 'WalkBack_LaidBackC_TG03';
	Template.PostMissionGravelyInjuredWalkUpAnimName = 'WalkUp_InjuredKneelB_TG03';
	Template.IdleGravelyInjuredAnimName = 'Idle_InjuredKneelB_TG03';
	Template.PostMissionInjuredWalkUpAnimName = 'WalkUp_InjuredA';
	Template.IdleInjuredAnimName = 'Idle_InjuredA';

	return Template;
}

static function X2SoldierPersonalityTemplate Personality_Normal()
{
	local X2SoldierPersonalityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierPersonalityTemplate', Template, 'Personality_Normal');

	Template.IdleAnimName = 'Idle_Normal_TG01';
	Template.PostMissionWalkUpAnimName = 'WalkUp_Normal_TG01';
	Template.PostMissionWalkBackAnimName = 'WalkBack_Normal_TG01';
	Template.PostMissionGravelyInjuredWalkUpAnimName = 'WalkUp_InjuredKneelB_TG03';
	Template.IdleGravelyInjuredAnimName = 'Idle_InjuredKneelB_TG03';
	Template.PostMissionInjuredWalkUpAnimName = 'WalkUp_InjuredA';
	Template.IdleInjuredAnimName = 'Idle_InjuredA';

	return Template;
}

static function X2SoldierPersonalityTemplate Personality_Twitchy()
{
	local X2SoldierPersonalityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierPersonalityTemplate', Template, 'Personality_Twitchy');

	Template.IdleAnimName = 'Idle_Twitchy_TG01';
	Template.PostMissionWalkUpAnimName = 'WalkUp_Normal_TG01';
	Template.PostMissionWalkBackAnimName = 'WalkBack_Normal_TG01';
	Template.PostMissionGravelyInjuredWalkUpAnimName = 'WalkUp_InjuredKneelB_TG03';
	Template.IdleGravelyInjuredAnimName = 'Idle_InjuredKneelB_TG03';
	Template.PostMissionInjuredWalkUpAnimName = 'WalkUp_InjuredA';
	Template.IdleInjuredAnimName = 'Idle_InjuredA';

	return Template;
}

static function X2SoldierPersonalityTemplate Personality_HappyGoLucky()
{
	local X2SoldierPersonalityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierPersonalityTemplate', Template, 'Personality_HappyGoLucky');

	Template.IdleAnimName = 'Idle_HappyGoLuckyB_TG01';
	Template.PostMissionWalkUpAnimName = 'WalkUp_HappyGoLuckyB_TG01';
	Template.PostMissionWalkBackAnimName = 'WalkBack_HappyGoLuckyB_TG01';
	Template.PostMissionGravelyInjuredWalkUpAnimName = 'WalkUp_InjuredKneelB_TG03';
	Template.IdleGravelyInjuredAnimName = 'Idle_InjuredKneelB_TG03';
	Template.PostMissionInjuredWalkUpAnimName = 'WalkUp_InjuredA';
	Template.IdleInjuredAnimName = 'Idle_InjuredA';

	return Template;
}

static function X2SoldierPersonalityTemplate Personality_HardLuck()
{
	local X2SoldierPersonalityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierPersonalityTemplate', Template, 'Personality_HardLuck');

	Template.IdleAnimName = 'Idle_HardLuckB_TG01';
	Template.PostMissionWalkUpAnimName = 'WalkUp_HardLuckB_TG01';
	Template.PostMissionWalkBackAnimName = 'WalkBack_HardLuckB_TG01';
	Template.PostMissionGravelyInjuredWalkUpAnimName = 'WalkUp_InjuredKneelB_TG03';
	Template.IdleGravelyInjuredAnimName = 'Idle_InjuredKneelB_TG03';
	Template.PostMissionInjuredWalkUpAnimName = 'WalkUp_InjuredA';
	Template.IdleInjuredAnimName = 'Idle_InjuredA';

	return Template;
}

static function X2SoldierPersonalityTemplate Personality_Intense()
{
	local X2SoldierPersonalityTemplate Template;

	`CREATE_X2TEMPLATE(class'X2SoldierPersonalityTemplate', Template, 'Personality_Intense');

	Template.IdleAnimName = 'Idle_Intense_TG02';
	Template.PostMissionWalkUpAnimName = 'WalkUp_Intense_TG02';
	Template.PostMissionWalkBackAnimName = 'WalkBack_Intense_TG02';
	Template.PostMissionGravelyInjuredWalkUpAnimName = 'WalkUp_InjuredKneelB_TG03';
	Template.IdleGravelyInjuredAnimName = 'Idle_InjuredKneelB_TG03';
	Template.PostMissionInjuredWalkUpAnimName = 'WalkUp_InjuredA';
	Template.IdleInjuredAnimName = 'Idle_InjuredA';

	return Template;
}