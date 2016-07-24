class X2StrategyElement_AcademyUnlocks extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
		
	Templates.AddItem(LightningStrikeUnlock());
	Templates.AddItem(WetWorkUnlock());
	Templates.AddItem(SquadSizeIUnlock());
	Templates.AddItem(SquadSizeIIUnlock());
	Templates.AddItem(IntegratedWarfareUnlock());
	Templates.AddItem(VengeanceUnlock());
	Templates.AddItem(VultureUnlock());
	Templates.AddItem(StayWithMeUnlock());
	Templates.AddItem(FNGUnlock());
	Templates.AddItem(HuntersInstinctUnlock());
	Templates.AddItem(HitWhereItHurtsUnlock());
	Templates.AddItem(CoolUnderPressureUnlock());
	Templates.AddItem(BiggestBoomsUnlock());

	return Templates;
}

static function X2SoldierAbilityUnlockTemplate HuntersInstinctUnlock()
{
	local X2SoldierAbilityUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'HuntersInstinctUnlock');

	Template.AllowedClasses.AddItem('Ranger');
	Template.AbilityName = 'HuntersInstinct';
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_Ranger";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 5;
	Template.Requirements.RequiredSoldierClass = 'Ranger';
	Template.Requirements.RequiredSoldierRankClassCombo = true;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);
	
	return Template;
}

static function X2SoldierAbilityUnlockTemplate HitWhereItHurtsUnlock()
{
	local X2SoldierAbilityUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'HitWhereItHurtsUnlock');

	Template.AllowedClasses.AddItem('Sharpshooter');
	Template.AbilityName = 'HitWhereItHurts';
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_Sharpshooter";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 5;
	Template.Requirements.RequiredSoldierClass = 'Sharpshooter';
	Template.Requirements.RequiredSoldierRankClassCombo = true;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierAbilityUnlockTemplate CoolUnderPressureUnlock()
{
	local X2SoldierAbilityUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'CoolUnderPressureUnlock');

	Template.AllowedClasses.AddItem('Specialist');
	Template.AbilityName = 'CoolUnderPressure';
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_Specialist";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 5;
	Template.Requirements.RequiredSoldierClass = 'Specialist';
	Template.Requirements.RequiredSoldierRankClassCombo = true;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierAbilityUnlockTemplate BiggestBoomsUnlock()
{
	local X2SoldierAbilityUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'BiggestBoomsUnlock');

	Template.AllowedClasses.AddItem('Grenadier');
	Template.AbilityName = 'BiggestBooms';
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_Grenadier";
	
	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 5;
	Template.Requirements.RequiredSoldierClass = 'Grenadier';
	Template.Requirements.RequiredSoldierRankClassCombo = true;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierAbilityUnlockTemplate LightningStrikeUnlock()
{
	local X2SoldierAbilityUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'LightningStrikeUnlock');

	Template.bAllClasses = true;
	Template.AbilityName = 'LightningStrike';
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_LightningStrike";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 3;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 100;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate WetWorkUnlock()
{
	local X2SoldierUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierUnlockTemplate', Template, 'WetWorkUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_WetWork";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 3;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 125;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate SquadSizeIUnlock()
{
	local X2SoldierUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierUnlockTemplate', Template, 'SquadSizeIUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_SquadSize1";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 3;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate SquadSizeIIUnlock()
{
	local X2SoldierUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierUnlockTemplate', Template, 'SquadSizeIIUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_SquadSize2";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 5;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierIntegratedWarfareUnlockTemplate IntegratedWarfareUnlock()
{
	local X2SoldierIntegratedWarfareUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierIntegratedWarfareUnlockTemplate', Template, 'IntegratedWarfareUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_IntegratedWarfare";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 4;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 150;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate VengeanceUnlock()
{
	local X2SoldierAbilityUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierAbilityUnlockTemplate', Template, 'VengeanceUnlock');

	Template.bAllClasses = true;
	Template.AbilityName = 'Vengeance';
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_Vengeance";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 4;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 100;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate VultureUnlock()
{
	local X2SoldierUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierUnlockTemplate', Template, 'VultureUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_Vulture";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 0;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate StayWithMeUnlock()
{
	local X2SoldierUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierUnlockTemplate', Template, 'StayWithMeUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_StayWithMe";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 6;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 150;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}

static function X2SoldierUnlockTemplate FNGUnlock()
{
	local X2SoldierUnlockTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2SoldierUnlockTemplate', Template, 'FNGUnlock');

	Template.bAllClasses = true;
	Template.strImage = "img:///UILibrary_StrategyImages.GTS.GTS_FNG";

	// Requirements
	Template.Requirements.RequiredHighestSoldierRank = 7;
	Template.Requirements.bVisibleIfSoldierRankGatesNotMet = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 175;
	Template.Cost.ResourceCosts.AddItem(Resources);

	return Template;
}