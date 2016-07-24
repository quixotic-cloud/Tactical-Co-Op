class X2Item_DefaultGrenades extends X2Item config(GameData_WeaponData);

// ***** Grenade Variables *****
//*** Config var declarations
var config int GRENADE_SOUND_RANGE;

// Mk1 grenades
var config WeaponDamageValue FRAGGRENADE_BASEDAMAGE;
var config WeaponDamageValue ACIDGRENADEM1_BASEDAMAGE;
var config WeaponDamageValue FIREGRENADEM1_BASEDAMAGE;
var config WeaponDamageValue GASGRENADEM1_BASEDAMAGE;
var config WeaponDamageValue EMPGRENADEM1_BASEDAMAGE;

// Mk2 grenades
var config WeaponDamageValue ALIENGRENADE_BASEDAMAGE;
var config WeaponDamageValue ACIDGRENADEM2_BASEDAMAGE;
var config WeaponDamageValue FIREGRENADEM2_BASEDAMAGE;
var config WeaponDamageValue GASGRENADEM2_BASEDAMAGE;
var config WeaponDamageValue EMPGRENADEM2_BASEDAMAGE;
var config WeaponDamageValue PROXIMITYMINE_BASEDAMAGE;

// non-damaging grenades
var config WeaponDamageValue FLASHBANGGRENADE_BASEDAMAGE;
var config WeaponDamageValue SMOKEGRENADE_BASEDAMAGE;

var config WeaponDamageValue ADVCAPTAINM1_GRENADE_BASEDAMAGE;
var config WeaponDamageValue ADVCAPTAINM2_GRENADE_BASEDAMAGE;
var config WeaponDamageValue ADVCAPTAINM3_GRENADE_BASEDAMAGE;

var config WeaponDamageValue ADVPURIFIERM1_FIREBOMB_BASEDAMAGE;
var config WeaponDamageValue ADVPURIFIERM2_FIREBOMB_BASEDAMAGE;
var config WeaponDamageValue ADVPURIFIERM3_FIREBOMB_BASEDAMAGE;

var config WeaponDamageValue ADVTROOPERM2_GRENADE_BASEDAMAGE;
var config WeaponDamageValue ADVTROOPERM3_GRENADE_BASEDAMAGE;

var config WeaponDamageValue MUTON_GRENADE_BASEDAMAGE;

var config WeaponDamageValue ANDROMEDON_ACIDBLOB_BASEDAMAGE;

var config WeaponDamageValue VIPER_POISONSPIT_BASEDAMAGE;



var config int FIREBOMB_ISOUNDRANGE;
var config int FIREBOMB_IENVIRONMENTDAMAGE;
var config int FIREBOMB_ISUPPLIES;
var config int FIREBOMB_TRADINGPOSTVALUE;
var config int FIREBOMB_IPOINTS;
var config int FIREBOMB_ICLIPSIZE;
var config int FIREGRENADE_RANGE;
var config int FIREGRENADE_RADIUS;
var config int FIREBOMB_RANGE;
var config int FIREBOMB_RADIUS;

var config int FRAGGRENADE_ISOUNDRANGE;
var config int FRAGGRENADE_IENVIRONMENTDAMAGE;
var config int FRAGGRENADE_ISUPPLIES;
var config int FRAGGRENADE_TRADINGPOSTVALUE;
var config int FRAGGRENADE_IPOINTS;
var config int FRAGGRENADE_ICLIPSIZE;
var config int FRAGGRENADE_RANGE;
var config int FRAGGRENADE_RADIUS;

var config int ALIENGRENADE_ISOUNDRANGE;
var config int ALIENGRENADE_IENVIRONMENTDAMAGE;
var config int ALIENGRENADE_ISUPPLIES;
var config int ALIENGRENADE_TRADINGPOSTVALUE;
var config int ALIENGRENADE_IPOINTS;
var config int ALIENGRENADE_ICLIPSIZE;
var config int ALIENGRENADE_RANGE;
var config int ALIENGRENADE_RADIUS;

var config int FLASHBANGGRENADE_ISOUNDRANGE;
var config int FLASHBANGGRENADE_IENVIRONMENTDAMAGE;
var config int FLASHBANGGRENADE_ISUPPLIES;
var config int FLASHBANGGRENADE_TRADINGPOSTVALUE;
var config int FLASHBANGGRENADE_IPOINTS;
var config int FLASHBANGGRENADE_ICLIPSIZE;
var config int FLASHBANGGRENADE_RANGE;
var config int FLASHBANGGRENADE_RADIUS;

var config int SMOKEGRENADE_ISOUNDRANGE;
var config int SMOKEGRENADE_IENVIRONMENTDAMAGE;
var config int SMOKEGRENADE_ISUPPLIES;
var config int SMOKEGRENADE_TRADINGPOSTVALUE;
var config int SMOKEGRENADE_IPOINTS;
var config int SMOKEGRENADE_ICLIPSIZE;
var config int SMOKEGRENADE_RANGE;
var config int SMOKEGRENADE_RADIUS;
var config int SMOKEGRENADEMK2_RANGE;
var config int SMOKEGRENADEMK2_RADIUS;

var config int GASGRENADE_ISOUNDRANGE;
var config int GASGRENADE_IENVIRONMENTDAMAGE;
var config int GASGRENADE_ISUPPLIES;
var config int GASGRENADE_TRADINGPOSTVALUE;
var config int GASGRENADE_IPOINTS;
var config int GASGRENADE_ICLIPSIZE;
var config int GASGRENADE_RANGE;
var config int GASGRENADE_RADIUS;
var config int GASBOMB_RANGE;
var config int GASBOMB_RADIUS;

var config int ACIDGRENADE_ISOUNDRANGE;
var config int ACIDGRENADE_IENVIRONMENTDAMAGE;
var config int ACIDGRENADE_ISUPPLIES;
var config int ACIDGRENADE_TRADINGPOSTVALUE;
var config int ACIDGRENADE_IPOINTS;
var config int ACIDGRENADE_ICLIPSIZE;
var config int ACIDGRENADE_RANGE;
var config int ACIDGRENADE_RADIUS;
var config int ACIDBOMB_RANGE;
var config int ACIDBOMB_RADIUS;

var config int GRENADELAUNCHER_ISOUNDRANGE;
var config int GRENADELAUNCHER_IENVIRONMENTDAMAGE;
var config int GRENADELAUNCHER_ISUPPLIES;
var config int GRENADELAUNCHER_TRADINGPOSTVALUE;
var config int GRENADELAUNCHER_IPOINTS;
var config int GRENADELAUNCHER_ICLIPSIZE;
var config int GRENADELAUNCHER_RANGEBONUS;
var config int GRENADELAUNCHER_RADIUSBONUS;

var config int ADVGRENADELAUNCHER_ISOUNDRANGE;
var config int ADVGRENADELAUNCHER_IENVIRONMENTDAMAGE;
var config int ADVGRENADELAUNCHER_ISUPPLIES;
var config int ADVGRENADELAUNCHER_TRADINGPOSTVALUE;
var config int ADVGRENADELAUNCHER_IPOINTS;
var config int ADVGRENADELAUNCHER_ICLIPSIZE;
var config int ADVGRENADELAUNCHER_RANGEBONUS;
var config int ADVGRENADELAUNCHER_RADIUSBONUS;

var config int EMPGRENADE_RANGE;
var config int EMPGRENADE_RADIUS;
var config int EMPGRENADE_HACK_DEFENSE_CHANGE;

var config int EMPBOMB_RANGE;
var config int EMPBOMB_RADIUS;
var config int EMPBOMB_HACK_DEFENSE_CHANGE;

var config int PROXIMITYMINE_RANGE;
var config int PROXIMITYMINE_RADIUS;

var localized string SmokeGrenadeEffectDisplayName;
var localized string SmokeGrenadeEffectDisplayDesc;
var config int SMOKEGRENADE_HITMOD;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Grenades;

	Grenades.AddItem(CreateFirebomb());
	Grenades.AddItem(FirebombMK2());
	Grenades.AddItem(CreateFragGrenade());
	Grenades.AddItem(CreateAlienGrenade());
	Grenades.AddItem(CreateFlashbangGrenade());
	Grenades.AddItem(CreateSmokeGrenade());
	Grenades.AddItem(SmokeGrenadeMk2());
	Grenades.AddItem(CreateGasGrenade());
	Grenades.AddItem(CreateGasGrenadeMk2());
	Grenades.AddItem(CreateAcidGrenade());
	Grenades.AddItem(CreateAcidGrenadeMk2());
	Grenades.AddItem(CreatePoisonSpitGlob());
	Grenades.AddItem(CreateAcidBlob());
	Grenades.AddItem(GrenadeLauncher());
	Grenades.AddItem(AdvGrenadeLauncher());
	Grenades.AddItem(CreateAdventCaptainMk1Grenade());
	Grenades.AddItem(CreateAdventCaptainMk2Grenade());
	Grenades.AddItem(CreateAdventCaptainMk3Grenade());
	Grenades.AddItem(CreateAdventTrooperMk2Grenade());
	Grenades.AddItem(CreateAdventTrooperMk3Grenade());
	Grenades.AddItem(CreateMutonGrenade());
	Grenades.AddItem(EMPGrenade());
	Grenades.AddItem(EMPGrenadeMk2());
	Grenades.AddItem(ProximityMine());

	return Grenades;
}

static function X2DataTemplate CreateFirebomb()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'Firebomb');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Firebomb";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_firebomb");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_firebomb");

	Template.iRange = default.FIREGRENADE_RANGE;
	Template.iRadius = default.FIREGRENADE_RADIUS;
	Template.fCoverage = 50;

	Template.BaseDamage = default.FIREGRENADEM1_BASEDAMAGE;
	Template.iSoundRange = default.FIREBOMB_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.FIREBOMB_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.FIREBOMB_TRADINGPOSTVALUE;
	Template.PointsToComplete = default.FIREBOMB_IPOINTS;
	Template.iClipSize = default.FIREBOMB_ICLIPSIZE;
	Template.Tier = 1;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.ThrownGrenadeEffects.AddItem(new class'X2Effect_ApplyFireToWorld');
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 1));
	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;
	
	Template.GameArchetype = "WP_Grenade_Fire.WP_Grenade_Fire";

	Template.iPhysicsImpulse = 10;

	Template.CanBeBuilt = false;
	
	Template.RewardDecks.AddItem('ExperimentalGrenadeRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.FIREGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.FIREGRENADE_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.FIREGRENADEM1_BASEDAMAGE.Shred);

	return Template;
}

static function X2DataTemplate FirebombMK2()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'FirebombMK2');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_FirebombMK2";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_firebomb");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_firebomb");

	Template.iRange = default.FIREBOMB_RANGE;
	Template.iRadius = default.FIREBOMB_RADIUS;
	Template.fCoverage = 50;

	Template.BaseDamage = default.FIREGRENADEM2_BASEDAMAGE;
	Template.iSoundRange = default.FIREBOMB_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.FIREBOMB_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.FIREBOMB_TRADINGPOSTVALUE;
	Template.PointsToComplete = default.FIREBOMB_IPOINTS;
	Template.iClipSize = default.FIREBOMB_ICLIPSIZE;
	Template.Tier = 2;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.ThrownGrenadeEffects.AddItem(new class'X2Effect_ApplyFireToWorld');
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 1));
	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;
	
	Template.GameArchetype = "WP_Grenade_Fire.WP_Grenade_Fire_Lv2";

	Template.iPhysicsImpulse = 10;

	Template.CanBeBuilt = false;

	Template.CreatorTemplateName = 'AdvancedGrenades'; // The schematic which creates this item
	Template.BaseItem = 'Firebomb'; // Which item this will be upgraded from

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.FIREBOMB_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.FIREBOMB_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.FIREGRENADEM2_BASEDAMAGE.Shred);

	return Template;
}

static function X2DataTemplate CreateFragGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local X2Effect_Knockback KnockbackEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'FragGrenade');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Frag_Grenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.iRange = default.FRAGGRENADE_RANGE;
	Template.iRadius = default.FRAGGRENADE_RADIUS;

	Template.BaseDamage = default.FRAGGRENADE_BASEDAMAGE;
	Template.iSoundRange = default.FRAGGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.FRAGGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.FRAGGRENADE_TRADINGPOSTVALUE;
	Template.iClipSize = default.FRAGGRENADE_ICLIPSIZE;
	Template.DamageTypeTemplateName = 'Explosion';
	Template.Tier = 0;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	Template.GameArchetype = "WP_Grenade_Frag.WP_Grenade_Frag";

	Template.iPhysicsImpulse = 10;

	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);

	Template.HideIfResearched = 'PlasmaGrenade';

	Template.OnThrowBarkSoundCue = 'ThrowGrenade';

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.bUseTargetLocation = true; //This looks better for the animations used even though the source location should be used for grenades.
	KnockbackEffect.KnockbackDistance = 2;
	Template.ThrownGrenadeEffects.AddItem(KnockbackEffect);
	Template.LaunchedGrenadeEffects.AddItem(KnockbackEffect);

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.FRAGGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.FRAGGRENADE_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.FRAGGRENADE_BASEDAMAGE.Shred);

	return Template;
}

static function X2DataTemplate CreateAlienGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local X2Effect_Knockback KnockbackEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AlienGrenade');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Plasma_Grenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.iRange = default.ALIENGRENADE_RANGE;
	Template.iRadius = default.ALIENGRENADE_RADIUS;

	Template.BaseDamage = default.ALIENGRENADE_BASEDAMAGE;
	Template.iSoundRange = default.ALIENGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ALIENGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.ALIENGRENADE_TRADINGPOSTVALUE;
	Template.PointsToComplete = default.ALIENGRENADE_IPOINTS;
	Template.iClipSize = default.ALIENGRENADE_ICLIPSIZE;
	Template.DamageTypeTemplateName = 'Explosion';
	Template.Tier = 2;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);
	
	Template.GameArchetype = "WP_Grenade_Alien.WP_Grenade_Alien_Soldier";

	Template.iPhysicsImpulse = 10;

	Template.CreatorTemplateName = 'PlasmaGrenade'; // The schematic which creates this item
	Template.BaseItem = 'FragGrenade'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	KnockbackEffect = new class'X2Effect_Knockback';
	KnockbackEffect.bUseTargetLocation = true; //This looks better for the animations used even though the source location should be used for grenades.
	KnockbackEffect.KnockbackDistance = 2;
	Template.ThrownGrenadeEffects.AddItem(KnockbackEffect);
	Template.LaunchedGrenadeEffects.AddItem(KnockbackEffect);

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.ALIENGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.ALIENGRENADE_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.ALIENGRENADE_BASEDAMAGE.Shred);
	
	return Template;
}

static function X2DataTemplate CreateFlashbangGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'FlashbangGrenade');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons..Inv_Flashbang_Grenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_flash");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_flash");
	Template.iRange = default.FLASHBANGGRENADE_RANGE;
	Template.iRadius = default.FLASHBANGGRENADE_RADIUS;
	
	Template.bFriendlyFire = false;
	Template.bFriendlyFireWarning = false;
	Template.Abilities.AddItem('ThrowGrenade');

	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreateDisorientedStatusEffect(, , false));

	//We need to have an ApplyWeaponDamage for visualization, even if the grenade does 0 damage (makes the unit flinch, shows overwatch removal)
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);

	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;
	
	Template.GameArchetype = "WP_Grenade_Flashbang.WP_Grenade_Flashbang";

	Template.CanBeBuilt = true;

	Template.iSoundRange = default.FLASHBANGGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.FLASHBANGGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = 10;
	Template.PointsToComplete = default.FLASHBANGGRENADE_IPOINTS;
	Template.iClipSize = default.FLASHBANGGRENADE_ICLIPSIZE;
	Template.Tier = 0;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 35;
	Template.Cost.ResourceCosts.AddItem(Resources);

	// Soldier Bark
	Template.OnThrowBarkSoundCue = 'ThrowFlashbang';

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.FLASHBANGGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.FLASHBANGGRENADE_RADIUS);

	return Template;
}

static function X2Effect SmokeGrenadeEffect()
{
	local X2Effect_SmokeGrenade Effect;

	Effect = new class'X2Effect_SmokeGrenade';
	//Must be at least as long as the duration of the smoke effect on the tiles. Will get "cut short" when the tile stops smoking or the unit moves. -btopp 2015-08-05
	Effect.BuildPersistentEffect(class'X2Effect_ApplySmokeGrenadeToWorld'.default.Duration + 1, false, false, false, eGameRule_PlayerTurnBegin);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, default.SmokeGrenadeEffectDisplayName, default.SmokeGrenadeEffectDisplayDesc, "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke");
	Effect.HitMod = default.SMOKEGRENADE_HITMOD;
	Effect.DuplicateResponse = eDupe_Refresh;
	return Effect;
}

static function X2DataTemplate CreateSmokeGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplySmokeGrenadeToWorld WeaponEffect;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'SmokeGrenade');

	Template.WeaponCat = 'utility';
	Template.ItemCat = 'utility';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Smoke_Grenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke");
	Template.iRange = default.SMOKEGRENADE_RANGE;
	Template.iRadius = default.SMOKEGRENADE_RADIUS;

	Template.iSoundRange = default.SMOKEGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SMOKEGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = 7;
	Template.PointsToComplete = default.SMOKEGRENADE_IPOINTS;
	Template.iClipSize = default.SMOKEGRENADE_ICLIPSIZE;
	Template.Tier = 0;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.bFriendlyFireWarning = false;

	WeaponEffect = new class'X2Effect_ApplySmokeGrenadeToWorld';	
	Template.ThrownGrenadeEffects.AddItem(WeaponEffect);
	Template.ThrownGrenadeEffects.AddItem(SmokeGrenadeEffect());
	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;

	Template.GameArchetype = "WP_Grenade_Smoke.WP_Grenade_Smoke";

	Template.CanBeBuilt = true;

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 25;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Template.HideIfResearched = 'AdvancedGrenades';

	// Soldier Bark
	Template.OnThrowBarkSoundCue = 'SmokeGrenade';

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.SMOKEGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.SMOKEGRENADE_RADIUS);

	return Template;
}

static function X2DataTemplate SmokeGrenadeMk2()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplySmokeGrenadeToWorld WeaponEffect;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'SmokeGrenadeMk2');
	
	Template.WeaponCat = 'utility';
	Template.ItemCat = 'utility';
	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Smoke_GrenadeMK2";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_smoke");
	Template.iRange = default.SMOKEGRENADEMK2_RANGE;
	Template.iRadius = default.SMOKEGRENADEMK2_RADIUS;

	Template.iSoundRange = default.SMOKEGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.SMOKEGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = 10;
	Template.PointsToComplete = default.SMOKEGRENADE_IPOINTS;
	Template.iClipSize = default.SMOKEGRENADE_ICLIPSIZE;
	Template.Tier = 1;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.bFriendlyFireWarning = false;

	WeaponEffect = new class'X2Effect_ApplySmokeGrenadeToWorld';	
	Template.ThrownGrenadeEffects.AddItem(WeaponEffect);
	Template.ThrownGrenadeEffects.AddItem(SmokeGrenadeEffect());
	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;

	Template.GameArchetype = "WP_Grenade_Smoke.WP_Grenade_Smoke_Lv2";

	Template.CanBeBuilt = true;

	Template.CreatorTemplateName = 'AdvancedGrenades'; // The schematic which creates this item
	Template.BaseItem = 'SmokeGrenade'; // Which item this will be upgraded from
	
	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Template.Requirements.RequiredTechs.AddItem('AdvancedGrenades');

	// Soldier Bark
	Template.OnThrowBarkSoundCue = 'SmokeGrenade';

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.SMOKEGRENADEMK2_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.SMOKEGRENADEMK2_RADIUS);

	return Template;
}

static function X2DataTemplate CreateGasGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local X2Effect_ApplyPoisonToWorld WeaponEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'GasGrenade');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Gas_Grenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_gas");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_gas");
	Template.iRange = default.GASGRENADE_RANGE;
	Template.iRadius = default.GASGRENADE_RADIUS;

	Template.BaseDamage = default.GASGRENADEM1_BASEDAMAGE;
	Template.iSoundRange = default.GASGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.GASGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.GASGRENADE_TRADINGPOSTVALUE;
	Template.PointsToComplete = default.GASGRENADE_IPOINTS;
	Template.iClipSize = default.GASGRENADE_ICLIPSIZE;
	Template.Tier = 1;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	WeaponEffect = new class'X2Effect_ApplyPoisonToWorld';	
	Template.ThrownGrenadeEffects.AddItem(WeaponEffect);
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreatePoisonedStatusEffect());
	// immediate damage
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);

	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;
	
	Template.GameArchetype = "WP_Grenade_Gas.WP_Grenade_Gas";

	Template.CanBeBuilt = false;
	
	Template.RewardDecks.AddItem('ExperimentalGrenadeRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.GASGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.GASGRENADE_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.GASGRENADEM1_BASEDAMAGE.Shred);

	return Template;
}

static function X2DataTemplate CreateGasGrenadeMk2()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyPoisonToWorld WeaponEffect;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'GasGrenadeMk2');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Gas_GrenadeMK2";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_gas");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_gas");
	Template.iRange = default.GASBOMB_RANGE;
	Template.iRadius = default.GASBOMB_RADIUS;

	Template.BaseDamage = default.GASGRENADEM2_BASEDAMAGE;
	Template.iSoundRange = default.GASGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.GASGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.GASGRENADE_TRADINGPOSTVALUE;
	Template.PointsToComplete = default.GASGRENADE_IPOINTS;
	Template.iClipSize = default.GASGRENADE_ICLIPSIZE;
	Template.Tier = 2;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	WeaponEffect = new class'X2Effect_ApplyPoisonToWorld';
	Template.ThrownGrenadeEffects.AddItem(WeaponEffect);
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreatePoisonedStatusEffect());
	// immediate damage
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);

	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;

	Template.GameArchetype = "WP_Grenade_Gas.WP_Grenade_Gas_Lv2";

	Template.CanBeBuilt = false;
	
	Template.CreatorTemplateName = 'AdvancedGrenades'; // The schematic which creates this item
	Template.BaseItem = 'GasGrenade'; // Which item this will be upgraded from

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.GASBOMB_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.GASBOMB_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.GASGRENADEM2_BASEDAMAGE.Shred);

	return Template;
}

static function X2DataTemplate CreateAcidGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyAcidToWorld WeaponEffect;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AcidGrenade');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Acid_Bomb";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_acidbomb");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_acidbomb");
	Template.iRange = default.ACIDGRENADE_RANGE;
	Template.iRadius = default.ACIDGRENADE_RADIUS;
	Template.fCoverage = 2/3 * 100;

	Template.BaseDamage = default.ACIDGRENADEM1_BASEDAMAGE;
	Template.iSoundRange = default.ACIDGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ACIDGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.ACIDGRENADE_TRADINGPOSTVALUE;
	Template.PointsToComplete = default.ACIDGRENADE_IPOINTS;
	Template.iClipSize = default.ACIDGRENADE_ICLIPSIZE;
	Template.Tier = 1;
	
	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	WeaponEffect = new class'X2Effect_ApplyAcidToWorld';	
	Template.ThrownGrenadeEffects.AddItem(WeaponEffect);
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreateAcidBurningStatusEffect(2,1));
	// immediate damage
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);

	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;
	
	Template.GameArchetype = "WP_Grenade_Acid.WP_Grenade_Acid";

	Template.CanBeBuilt = false;
	
	Template.RewardDecks.AddItem('ExperimentalGrenadeRewards');

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.ACIDGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.ACIDGRENADE_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.ACIDGRENADEM1_BASEDAMAGE.Shred);

	return Template;
}

static function X2DataTemplate CreateAcidGrenadeMk2()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyAcidToWorld WeaponEffect;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AcidGrenadeMk2');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Acid_BombMK2";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_acidbomb");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_acidbomb");
	Template.iRange = default.ACIDBOMB_RANGE;
	Template.iRadius = default.ACIDBOMB_RADIUS;
	Template.fCoverage = 2 / 3 * 100;

	Template.BaseDamage = default.ACIDGRENADEM2_BASEDAMAGE;
	Template.iSoundRange = default.ACIDGRENADE_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ACIDGRENADE_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.ACIDGRENADE_TRADINGPOSTVALUE;
	Template.PointsToComplete = default.ACIDGRENADE_IPOINTS;
	Template.iClipSize = default.ACIDGRENADE_ICLIPSIZE;
	Template.Tier = 2;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');

	WeaponEffect = new class'X2Effect_ApplyAcidToWorld';
	Template.ThrownGrenadeEffects.AddItem(WeaponEffect);
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreateAcidBurningStatusEffect(2,1));
	// immediate damage
	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);

	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;

	Template.GameArchetype = "WP_Grenade_Acid.WP_Grenade_Acid";

	Template.CanBeBuilt = false;

	Template.CreatorTemplateName = 'AdvancedGrenades'; // The schematic which creates this item
	Template.BaseItem = 'AcidGrenade'; // Which item this will be upgraded from

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.ACIDBOMB_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.ACIDBOMB_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.ACIDGRENADEM2_BASEDAMAGE.Shred);

	return Template;
}

static function X2GrenadeLauncherTemplate GrenadeLauncher()
{
	local X2GrenadeLauncherTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GrenadeLauncherTemplate', Template, 'GrenadeLauncher_CV');

	Template.strImage = "img:///UILibrary_Common.ConvSecondaryWeapons.ConvGrenade";
	Template.EquipSound = "Secondary_Weapon_Equip_Conventional";

	Template.iSoundRange = default.GRENADELAUNCHER_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.GRENADELAUNCHER_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = default.GRENADELAUNCHER_TRADINGPOSTVALUE;
	Template.iClipSize = default.GRENADELAUNCHER_ICLIPSIZE;
	Template.Tier = 0;

	Template.IncreaseGrenadeRadius = default.GRENADELAUNCHER_RADIUSBONUS;
	Template.IncreaseGrenadeRange = default.GRENADELAUNCHER_RANGEBONUS;

	Template.GameArchetype = "WP_GrenadeLauncher_CV.WP_GrenadeLauncher_CV";
	
	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.GrenadeRangeBonusLabel, , default.GRENADELAUNCHER_RANGEBONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.GrenadeRadiusBonusLabel, , default.GRENADELAUNCHER_RADIUSBONUS);

	return Template;
}

static function X2GrenadeLauncherTemplate AdvGrenadeLauncher()
{
	local X2GrenadeLauncherTemplate Template;

	`CREATE_X2TEMPLATE(class'X2GrenadeLauncherTemplate', Template, 'GrenadeLauncher_MG');

	Template.strImage = "img:///UILibrary_Common.MagSecondaryWeapons.MagLauncher";
	Template.EquipSound = "Secondary_Weapon_Equip_Magnetic";

	Template.iSoundRange = default.ADVGRENADELAUNCHER_ISOUNDRANGE;
	Template.iEnvironmentDamage = default.ADVGRENADELAUNCHER_IENVIRONMENTDAMAGE;
	Template.TradingPostValue = 18;
	Template.iClipSize = default.ADVGRENADELAUNCHER_ICLIPSIZE;
	Template.Tier = 1;

	Template.IncreaseGrenadeRadius = default.ADVGRENADELAUNCHER_RADIUSBONUS;
	Template.IncreaseGrenadeRange = default.ADVGRENADELAUNCHER_RANGEBONUS;

	Template.GameArchetype = "WP_GrenadeLauncher_MG.WP_GrenadeLauncher_MG";

	Template.CreatorTemplateName = 'GrenadeLauncher_MG_Schematic'; // The schematic which creates this item
	Template.BaseItem = 'GrenadeLauncher_CV'; // Which item this will be upgraded from

	Template.CanBeBuilt = false;
	Template.bInfiniteItem = true;

	Template.SetUIStatMarkup(class'XLocalizedData'.default.GrenadeRangeBonusLabel, , default.ADVGRENADELAUNCHER_RANGEBONUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.GrenadeRadiusBonusLabel, , default.ADVGRENADELAUNCHER_RADIUSBONUS);

	return Template;
}

// **********************************************************************************************************
// // ***                                         Enemy Weapons                                           ***
// **********************************************************************************************************

static function X2DataTemplate CreateAdventCaptainMk1Grenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AdventCaptainMk1Grenade');

	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_FragGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";

	Template.BaseDamage = default.ADVCAPTAINM1_GRENADE_BASEDAMAGE;
	Template.iEnvironmentDamage = default.FRAGGRENADE_IENVIRONMENTDAMAGE;
	Template.iRange = 10;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.iSoundRange = default.GRENADE_SOUND_RANGE;
	Template.DamageTypeTemplateName = 'Explosion';

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	Template.GameArchetype = "WP_Grenade_Frag.WP_Grenade_Frag";

	Template.iPhysicsImpulse = 10;

	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);

	return Template;
}

static function X2DataTemplate CreateAdventCaptainMk2Grenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AdventCaptainMk2Grenade');

	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_FragGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";

	Template.BaseDamage = default.ADVCAPTAINM2_GRENADE_BASEDAMAGE;
	Template.iEnvironmentDamage = default.FRAGGRENADE_IENVIRONMENTDAMAGE;
	Template.iRange = 10;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.iSoundRange = default.GRENADE_SOUND_RANGE;
	Template.DamageTypeTemplateName = 'Explosion';

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	Template.GameArchetype = "WP_Grenade_Frag.WP_Grenade_Frag";

	Template.iPhysicsImpulse = 10;

	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);

	return Template;
}

static function X2DataTemplate CreateAdventCaptainMk3Grenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AdventCaptainMk3Grenade');

	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_FragGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";

	Template.BaseDamage = default.ADVCAPTAINM3_GRENADE_BASEDAMAGE;
	Template.iEnvironmentDamage = default.ALIENGRENADE_IENVIRONMENTDAMAGE;
	Template.iRange = 10;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.iSoundRange = default.GRENADE_SOUND_RANGE;
	Template.DamageTypeTemplateName = 'Explosion';

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	Template.GameArchetype = "WP_Grenade_Frag.WP_Grenade_Frag";

	Template.iPhysicsImpulse = 10;

	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);

	return Template;
}

static function X2DataTemplate CreateAdventTrooperMk2Grenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AdventTrooperMk2Grenade');

	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_FragGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";

	Template.BaseDamage = default.ADVTROOPERM2_GRENADE_BASEDAMAGE;
	Template.iEnvironmentDamage = default.FRAGGRENADE_IENVIRONMENTDAMAGE;
	Template.iRange = 10;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.iSoundRange = default.GRENADE_SOUND_RANGE;
	Template.DamageTypeTemplateName = 'Explosion';

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	Template.GameArchetype = "WP_Grenade_Frag.WP_Grenade_Frag";

	Template.iPhysicsImpulse = 10;

	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);

	return Template;
}

static function X2DataTemplate CreateAdventTrooperMk3Grenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'AdventTrooperMk3Grenade');

	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_FragGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";

	Template.BaseDamage = default.ADVTROOPERM3_GRENADE_BASEDAMAGE;
	Template.iEnvironmentDamage = default.ALIENGRENADE_IENVIRONMENTDAMAGE;
	Template.iRange = 10;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.iSoundRange = default.GRENADE_SOUND_RANGE;
	Template.DamageTypeTemplateName = 'Explosion';

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');
	
	Template.GameArchetype = "WP_Grenade_Frag.WP_Grenade_Frag";

	Template.iPhysicsImpulse = 10;

	Template.StartingItem = false;
	Template.CanBeBuilt = false;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);

	return Template;
}

static function X2DataTemplate CreateMutonGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'MutonGrenade');

	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_AlienGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.BaseDamage = default.MUTON_GRENADE_BASEDAMAGE;
	Template.iEnvironmentDamage = default.ALIENGRENADE_IENVIRONMENTDAMAGE;
	Template.iRange = 12;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.iSoundRange = default.GRENADE_SOUND_RANGE;
	Template.DamageTypeTemplateName = 'Explosion';
	
	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	Template.LaunchedGrenadeEffects.AddItem(WeaponDamageEffect);
	
	Template.GameArchetype = "WP_Grenade_Alien.WP_Grenade_Alien";

	Template.iPhysicsImpulse = 10;

	Template.CanBeBuilt = false;
	Template.TradingPostValue = 50;

	return Template;
}

static function X2DataTemplate CreatePoisonSpitGlob()
{
	local X2WeaponTemplate Template;

	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'PoisonSpitGlob');

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'grenade';
	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_SmokeGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	//Template.GameArchetype = "WP_Grenade_Frag.WP_Grenade_Frag";
	Template.GameArchetype = "WP_Viper_PoisonSpit.WP_Viper_PoisonSpit";
	Template.CanBeBuilt = false;	

	Template.iRange = 12;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;

	Template.iSoundRange = 6;
	Template.bSoundOriginatesFromOwnerLocation = true;

	Template.BaseDamage.DamageType = 'Poison';
	Template.BaseDamage = default.VIPER_POISONSPIT_BASEDAMAGE;

	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_None;
	Template.Abilities.AddItem('PoisonSpit');

	// This controls how much arc this projectile may have and how many times it may bounce
	Template.WeaponPrecomputedPathData.InitialPathTime = 0.5;
	Template.WeaponPrecomputedPathData.MaxPathTime = 1.0;
	Template.WeaponPrecomputedPathData.MaxNumberOfBounces = 0;

	return Template;
}

static function X2DataTemplate CreateAcidBlob()
{
	local X2WeaponTemplate Template;

	Template = new class'X2WeaponTemplate';
	
	`CREATE_X2TEMPLATE(class'X2WeaponTemplate', Template, 'AcidBlob');

	Template.ItemCat = 'weapon';
	Template.WeaponCat = 'grenade';
	Template.strImage = "img:///UILibrary_StrategyImages.InventoryIcons.Inv_SmokeGrenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.GameArchetype = "WP_Andromedon_AcidAttack.WP_Andromedon_AcidAttack";
	Template.CanBeBuilt = false;

	Template.iRange = 14;
	Template.iRadius = 4;
	Template.iClipSize = 1;
	Template.InfiniteAmmo = true;

	Template.iSoundRange = default.GRENADE_SOUND_RANGE;
	Template.bSoundOriginatesFromOwnerLocation = false;

	Template.BaseDamage.DamageType = 'Acid';
	Template.BaseDamage = default.ANDROMEDON_ACIDBLOB_BASEDAMAGE;
	
	Template.InventorySlot = eInvSlot_Utility;
	Template.StowedLocation = eSlot_None;
	Template.Abilities.AddItem('AcidBlob');

	return Template;
}

static function X2DataTemplate EMPGrenade()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_Stunned StunnedEffect;
	local X2Condition_UnitProperty UnitCondition;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'EMPGrenade');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Emp_Grenade";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_emp");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_emp");
	Template.iRange = default.EMPGRENADE_RANGE;
	Template.iRadius = default.EMPGRENADE_RADIUS;
	Template.iClipSize = 1;
	Template.BaseDamage = default.EMPGRENADEM1_BASEDAMAGE;
	Template.iSoundRange = 10;
	Template.iEnvironmentDamage = 0;
	Template.TradingPostValue = 10;
	Template.Tier = 1;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');

	Template.GameArchetype = "WP_Grenade_EMP.WP_Grenade_EMP";

	Template.iPhysicsImpulse = 10;

	Template.CanBeBuilt = true;

	UnitCondition = new class'X2Condition_UnitProperty';
	UnitCondition.ExcludeOrganic = true;
	UnitCondition.IncludeWeakAgainstTechLikeRobot = true;
	UnitCondition.ExcludeFriendlyToSource = false;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	WeaponDamageEffect.TargetConditions.AddItem(UnitCondition);
	WeaponDamageEffect.bShowImmunityAnyFailure = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_EnergyShield'.default.EffectName);
	Template.ThrownGrenadeEffects.AddItem(RemoveEffects);

	StunnedEffect = class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 33, false);
	StunnedEffect.SetDisplayInfo(ePerkBuff_Penalty, class'X2StatusEffects'.default.RoboticStunnedFriendlyName, class'X2StatusEffects'.default.RoboticStunnedFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_stun");
	StunnedEffect.TargetConditions.AddItem(UnitCondition);
	Template.ThrownGrenadeEffects.AddItem(StunnedEffect);

	UnitCondition = new class'X2Condition_UnitProperty';
	UnitCondition.ExcludeOrganic = true;
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreateHackDefenseChangeStatusEffect(default.EMPGRENADE_HACK_DEFENSE_CHANGE, UnitCondition));

	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;
	
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Template.Requirements.RequiredTechs.AddItem('Bluescreen');

	Template.HideIfResearched = 'AdvancedGrenades';
	
	Template.bHideDamageStat = true;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RoboticDamageLabel, , default.EMPGRENADEM1_BASEDAMAGE.Damage);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.EMPGRENADE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.EMPGRENADE_RADIUS);

	return Template;
}

static function X2DataTemplate EMPGrenadeMk2()
{
	local X2GrenadeTemplate Template;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_Stunned StunnedEffect;
	local X2Condition_UnitProperty UnitCondition;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'EMPGrenadeMk2');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Emp_GrenadeMK2";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_emp");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_emp");
	Template.iRange = default.EMPBOMB_RANGE;
	Template.iRadius = default.EMPBOMB_RADIUS;
	Template.iClipSize = 1;
	Template.BaseDamage = default.EMPGRENADEM2_BASEDAMAGE;
	Template.iSoundRange = 10;
	Template.iEnvironmentDamage = 0;
	Template.TradingPostValue = 10;
	Template.Tier = 2;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem('GrenadeFuse');

	Template.GameArchetype = "WP_Grenade_EMP.WP_Grenade_EMP_Lv2";

	Template.iPhysicsImpulse = 10;

	Template.CanBeBuilt = true;

	UnitCondition = new class'X2Condition_UnitProperty';
	UnitCondition.ExcludeOrganic = true;
	UnitCondition.IncludeWeakAgainstTechLikeRobot = true;
	UnitCondition.ExcludeFriendlyToSource = false;

	WeaponDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	WeaponDamageEffect.bExplosiveDamage = true;
	WeaponDamageEffect.TargetConditions.AddItem(UnitCondition);
	WeaponDamageEffect.bShowImmunityAnyFailure = true;
	Template.ThrownGrenadeEffects.AddItem(WeaponDamageEffect);
	
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_EnergyShield'.default.EffectName);
	Template.ThrownGrenadeEffects.AddItem(RemoveEffects);

	StunnedEffect = class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 50, false);
	StunnedEffect.SetDisplayInfo(ePerkBuff_Penalty, class'X2StatusEffects'.default.RoboticStunnedFriendlyName, class'X2StatusEffects'.default.RoboticStunnedFriendlyDesc, "img:///UILibrary_PerkIcons.UIPerk_stun");
	StunnedEffect.TargetConditions.AddItem(UnitCondition);
	Template.ThrownGrenadeEffects.AddItem(StunnedEffect);

	UnitCondition = new class'X2Condition_UnitProperty';
	UnitCondition.ExcludeOrganic = true;
	Template.ThrownGrenadeEffects.AddItem(class'X2StatusEffects'.static.CreateHackDefenseChangeStatusEffect(default.EMPBOMB_HACK_DEFENSE_CHANGE, UnitCondition));

	Template.LaunchedGrenadeEffects = Template.ThrownGrenadeEffects;

	Template.CreatorTemplateName = 'AdvancedGrenades'; // The schematic which creates this item
	Template.BaseItem = 'EMPGrenade'; // Which item this will be upgraded from

	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 50;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Template.Requirements.RequiredTechs.AddItem('Bluescreen');
	Template.Requirements.RequiredTechs.AddItem('AdvancedGrenades');

	Template.bHideDamageStat = true;
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RoboticDamageLabel, , default.EMPGRENADEM2_BASEDAMAGE.Damage);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.EMPBOMB_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.EMPBOMB_RADIUS);

	return Template;
}

static function X2GrenadeTemplate ProximityMine()
{
	local X2GrenadeTemplate Template;
	local ArtifactCost Resources;

	`CREATE_X2TEMPLATE(class'X2GrenadeTemplate', Template, 'ProximityMine');

	Template.strImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Proximity_Mine";
	Template.EquipSound = "StrategyUI_Grenade_Equip";
	Template.AddAbilityIconOverride('ThrowGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_proximitymine");
	Template.AddAbilityIconOverride('LaunchGrenade', "img:///UILibrary_PerkIcons.UIPerk_grenade_proximitymine");
	Template.iRange = default.PROXIMITYMINE_RANGE;
	Template.iRadius = default.PROXIMITYMINE_RADIUS;
	Template.iClipSize = 1;
	Template.BaseDamage = default.PROXIMITYMINE_BASEDAMAGE;
	Template.iSoundRange = 10;
	Template.iEnvironmentDamage = 20;
	Template.DamageTypeTemplateName = 'Explosion';
	Template.Tier = 2;

	Template.Abilities.AddItem('ThrowGrenade');
	Template.Abilities.AddItem(class'X2Ability_Grenades'.default.ProximityMineDetonationAbilityName);
	Template.Abilities.AddItem('GrenadeFuse');

	Template.bOverrideConcealmentRule = true;               //  override the normal behavior for the throw or launch grenade ability
	Template.OverrideConcealmentRule = eConceal_Always;     //  always stay concealed when throwing or launching a proximity mine
	
	Template.GameArchetype = "WP_Proximity_Mine.WP_Proximity_Mine";

	Template.iPhysicsImpulse = 10;

	Template.CanBeBuilt = true;	
	Template.TradingPostValue = 25;
	
	// Requirements
	Template.Requirements.RequiredTechs.AddItem('AutopsyAndromedon');

	// Cost
	Resources.ItemTemplateName = 'Supplies';
	Resources.Quantity = 100;
	Template.Cost.ResourceCosts.AddItem(Resources);

	Template.SetUIStatMarkup(class'XLocalizedData'.default.RangeLabel, , default.PROXIMITYMINE_RANGE);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.RadiusLabel, , default.PROXIMITYMINE_RADIUS);
	Template.SetUIStatMarkup(class'XLocalizedData'.default.ShredLabel, , default.PROXIMITYMINE_BASEDAMAGE.Shred);
	
	return Template;
}


defaultproperties
{
	bShouldCreateDifficultyVariants = true
}
