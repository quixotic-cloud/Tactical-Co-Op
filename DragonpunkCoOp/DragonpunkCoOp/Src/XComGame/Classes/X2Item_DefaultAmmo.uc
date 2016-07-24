class X2Item_DefaultAmmo extends X2Item config(GameCore);

var config int INCENDIARY_AMMO_DMGMOD;
var config int INCENDIARY_AMMO_BURNDMG;
var config int INCENDIARY_DAMAGE_CLIPSIZE;

var config int BLUESCREEN_CLIPSIZE;
var config int BLUESCREEN_DMGMOD;
var config int BLUESCREEN_ORGANIC_DMGMOD;
var config int BLUESCREEN_HACK_DEFENSE_CHANGE;

var config int TRACER_DMGMOD;

var config int VENOM_DMGMOD;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Items;

	Items.AddItem(CreateAPRounds());
	Items.AddItem(CreateTracerRounds());
	Items.AddItem(CreateIncendiaryAmmo());
	Items.AddItem(CreateTalonRounds());
	Items.AddItem(CreateVenomRounds());
	Items.AddItem(BluescreenRounds());
	
	return Items;
}

static function X2AmmoTemplate CreateAPRounds()
{
	local X2AmmoTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2AmmoTemplate', Template, 'APRounds');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Ap_Rounds";
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.PointsToComplete = 0;
	Template.Abilities.AddItem('APRounds');
	Template.Tier = 1;
	Template.EquipSound = "StrategyUI_Ammo_Equip";

	Template.RewardDecks.AddItem('ExperimentalAmmoRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.PierceLabel, eStat_ArmorPiercing, class'X2Ability_ItemGrantedAbilitySet'.default.APROUNDS_PIERCE);

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 65;
	Template.Cost.ResourceCosts.AddItem(Resources);
		
	//FX Reference
	Template.GameArchetype = "Ammo_AP.PJ_AP";
	
	return Template;
}

static function X2AmmoTemplate CreateTracerRounds()
{
	local X2AmmoTemplate Template;
	local ArtifactCost Resources;
	local WeaponDamageValue DamageValue;

	`CREATE_X2TEMPLATE(class'X2AmmoTemplate', Template, 'TracerRounds');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Tracer_Rounds";
	Template.Abilities.AddItem('TracerRounds');
	DamageValue.Damage = default.TRACER_DMGMOD;
	Template.AddAmmoDamageModifier(none, DamageValue);
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.PointsToComplete = 0;
	Template.Tier = 1;
	Template.EquipSound = "StrategyUI_Ammo_Equip";

	Template.RewardDecks.AddItem('ExperimentalAmmoRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.AimLabel, eStat_Offense, class'X2Effect_TracerRounds'.default.AimMod);

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 25;
	Template.Cost.ResourceCosts.AddItem(Resources);
		
	//FX Reference
	Template.GameArchetype = "Ammo_Tracer.PJ_Tracer";
	
	return Template;
}

static function X2DataTemplate CreateIncendiaryAmmo()
{
	local X2AmmoTemplate Template;
	local ArtifactCost Resources;
	local WeaponDamageValue DamageValue;

	`CREATE_X2TEMPLATE(class'X2AmmoTemplate', Template, 'IncendiaryRounds');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Incendiary_Rounds";
	Template.ModClipSize = default.INCENDIARY_DAMAGE_CLIPSIZE;
	DamageValue.Damage = default.INCENDIARY_AMMO_DMGMOD;
	DamageValue.DamageType = 'Fire';
	Template.AddAmmoDamageModifier(none, DamageValue);
	Template.TargetEffects.AddItem(class'X2StatusEffects'.static.CreateBurningStatusEffect(default.INCENDIARY_AMMO_BURNDMG, 0));
	Template.Abilities.AddItem('IncendiaryRounds');
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.PointsToComplete = 0;
	Template.Tier = 1;
	Template.EquipSound = "StrategyUI_Ammo_Equip";

	Template.RewardDecks.AddItem('ExperimentalAmmoRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.DamageBonusLabel, , default.INCENDIARY_AMMO_DMGMOD);

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);
		
	//FX Reference
	Template.GameArchetype = "Ammo_Incendiary.PJ_Incendiary";
	
	return Template;
}

static function X2DataTemplate CreateTalonRounds()
{
	local X2AmmoTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2AmmoTemplate', Template, 'TalonRounds');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Talon_Rounds";
	Template.Abilities.AddItem('TalonRounds');
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.PointsToComplete = 0;
	Template.Tier = 1;
	Template.EquipSound = "StrategyUI_Ammo_Equip";

	Template.RewardDecks.AddItem('ExperimentalAmmoRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.CriticalChanceBonusLabel, eStat_CritChance, class'X2Ability_ItemGrantedAbilitySet'.default.TALON_CRITCHANCE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.CriticalDamageLabel, , class'X2Ability_ItemGrantedAbilitySet'.default.TALON_CRIT);

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);
		
	//FX Reference
	Template.GameArchetype = "Ammo_Talon.PJ_Talon";
	
	return Template;
}

static function X2DataTemplate CreateVenomRounds()
{
	local X2AmmoTemplate Template;
	local ArtifactCost Resources;
	local WeaponDamageValue DamageValue;

	`CREATE_X2TEMPLATE(class'X2AmmoTemplate', Template, 'VenomRounds');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Venom_Rounds";
	Template.ModClipSize = default.INCENDIARY_DAMAGE_CLIPSIZE;
	DamageValue.Damage = default.VENOM_DMGMOD;
	DamageValue.DamageType = 'Poison';
	Template.AddAmmoDamageModifier(none, DamageValue);
	Template.TargetEffects.AddItem(class'X2StatusEffects'.static.CreatePoisonedStatusEffect());
	Template.Abilities.AddItem('VenomRounds');
	Template.CanBeBuilt = false;
	Template.TradingPostValue = 30;
	Template.PointsToComplete = 0;
	Template.Tier = 1;
	Template.EquipSound = "StrategyUI_Ammo_Equip";

	Template.RewardDecks.AddItem('ExperimentalAmmoRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.DamageBonusLabel, , default.VENOM_DMGMOD);

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);

	//FX Reference
	Template.GameArchetype = "Ammo_Venom.PJ_Venom";

	return Template;
}

static function X2DataTemplate BluescreenRounds()
{
	local X2AmmoTemplate Template;
	local X2Condition_UnitProperty Condition_UnitProperty;
	local ArtifactCost Resources;
	local WeaponDamageValue DamageValue;
	local X2Effect_RemoveEffects RemoveEffects;

	`CREATE_X2TEMPLATE(class'X2AmmoTemplate', Template, 'BluescreenRounds');
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Bluescreen_Rounds";
	Template.ModClipSize = default.BLUESCREEN_CLIPSIZE;
	Condition_UnitProperty = new class'X2Condition_UnitProperty';
	Condition_UnitProperty.ExcludeRobotic = true;
	DamageValue.DamageType = 'Electrical';
	DamageValue.Damage = default.BLUESCREEN_ORGANIC_DMGMOD;
	Template.AddAmmoDamageModifier(Condition_UnitProperty, DamageValue);
	Condition_UnitProperty = new class'X2Condition_UnitProperty';
	Condition_UnitProperty.ExcludeOrganic = true;
	Condition_UnitProperty.IncludeWeakAgainstTechLikeRobot = true;
	Condition_UnitProperty.TreatMindControlledSquadmateAsHostile = true;
	DamageValue.Damage = default.BLUESCREEN_DMGMOD;
	Template.AddAmmoDamageModifier(Condition_UnitProperty, DamageValue);
	Template.CanBeBuilt = true;
	Template.TradingPostValue = 20;
	Template.PointsToComplete = 0;
	Template.Tier = 1;
	Template.EquipSound = "StrategyUI_Ammo_Equip";
	Template.bBypassShields = true;

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_EnergyShield'.default.EffectName);
	Template.TargetEffects.AddItem(RemoveEffects);

	Condition_UnitProperty = new class'X2Condition_UnitProperty';
	Condition_UnitProperty.ExcludeOrganic = true;
	Condition_UnitProperty.TreatMindControlledSquadmateAsHostile = true;
	Template.TargetEffects.AddItem(class'X2StatusEffects'.static.CreateHackDefenseChangeStatusEffect(default.BLUESCREEN_HACK_DEFENSE_CHANGE, Condition_UnitProperty));

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RoboticDamageBonusLabel, , default.BLUESCREEN_DMGMOD);

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Bluescreen');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 75;
	Template.Cost.ResourceCosts.AddItem(Resources);
		
	//FX Reference
	Template.GameArchetype = "Ammo_Bluescreen.PJ_Bluescreen";
	
	return Template;
}