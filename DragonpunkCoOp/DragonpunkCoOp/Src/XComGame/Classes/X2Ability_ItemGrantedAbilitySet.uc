//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_ItemGrantedAbilitySet.uc
//  AUTHOR:  Dan Kaplan  --  5/20/2014
//  PURPOSE: Defines abilities made available to XCom soldiers through their equipped inventory items in X-Com 2. 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_ItemGrantedAbilitySet extends X2Ability
	dependson (XComGameStateContext_Ability) config(GameCore);

var config int HACKING_KIT_TECH_BONUS;
var config int NANOFIBER_VEST_HP_BONUS;

var config int PLATED_VEST_HP_BONUS;
var config int PLATED_VEST_MITIGATION_AMOUNT;
var config int PLATED_VEST_MITIGATION_CHANCE;

var config int HAZMAT_VEST_HP_BONUS;

var config int STASIS_VEST_HP_BONUS;
var config int STASIS_VEST_REGEN_AMOUNT;
var config int STASIS_VEST_MAX_REGEN_AMOUNT;

var config int MEDIUM_PLATED_HEALTH_BONUS;

var config int LIGHT_PLATED_HEALTH_BONUS;
var config int LIGHT_PLATED_MOBILITY_BONUS;
var config int LIGHT_PLATED_DODGE_BONUS;

var config int HEAVY_PLATED_HEALTH_BONUS;
var config int HEAVY_PLATED_MITIGATION_AMOUNT;
var config int HEAVY_PLATED_MITIGATION_CHANCE;

var config int MEDIUM_POWERED_HEALTH_BONUS;
var config int MEDIUM_POWERED_MITIGATION_AMOUNT;
var config int MEDIUM_POWERED_MITIGATION_CHANCE;

var config int HEAVY_POWERED_HEALTH_BONUS;
var config int HEAVY_POWERED_MITIGATION_AMOUNT;
var config int HEAVY_POWERED_MITIGATION_CHANCE;

var config int LIGHT_POWERED_HEALTH_BONUS;
var config int LIGHT_POWERED_MOBILITY_BONUS;
var config int LIGHT_POWERED_DODGE_BONUS;

var config int PSIAMP_CV_STATBONUS;
var config int PSIAMP_MG_STATBONUS;
var config int PSIAMP_BM_STATBONUS;

var config int APROUNDS_CRIT, APROUNDS_CRITCHANCE, APROUNDS_PIERCE;
var config int STILETTOROUNDS_CRIT, STILETTOROUNDS_CRITCHANCE, STILETTOROUNDS_PIERCE;

var config int TALON_AIM, TALON_CRIT, TALON_CRITCHANCE;
var config int FALCON_AIM, FALCON_CRIT, FALCON_CRITCHANCE;

var config int AMPBOOSTER_PSIOFFENSE, NEUROWHIP_PSIOFFENSE;
var config int DAMPING_WILL, MINDSHIELD_WILL;
var config int SCORCHCIRCUITS_HEALTH_BONUS;
var config int SCORCHCIRCUITS_APPLY_CHANCE;

var localized string CombatStimBonusName;
var localized string CombatStimBonusDesc;
var localized string CombatStimPenaltyName;
var localized string CombatStimPenaltyDesc;

var config float COMBAT_STIM_MOBILITY_MOD;
var config int COMBAT_STIM_DURATION;
var config int BATTLESCANNER_DURATION;

var config name MIMIC_BEACON_START_ANIM;

var config int WALL_PHASING_DURATION, WALL_PHASING_CHARGES;

var privatewrite name WraithActivationDurationEventName;

/// <summary>
/// Creates the set of abilities granted to units through their equipped items in X-Com 2
/// </summary>
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(AddNanofiberVestBonusAbility());
	Templates.AddItem(PlatedVestBonusAbility());
	Templates.AddItem(HazmatVestBonusAbility());
	Templates.AddItem(StasisVestBonusAbility());
	Templates.AddItem(MediumPlatedArmorStats());
	Templates.AddItem(HeavyPlatedArmorStats());
	Templates.AddItem(LightPlatedArmorStats());
	Templates.AddItem(LightPoweredArmorStats());
	Templates.AddItem(MediumPoweredArmorStats());
	Templates.AddItem(HeavyPoweredArmorStats());
	Templates.AddItem(AddExplosiveDeviceDetonateAbility());
	Templates.AddItem(TracerRounds());
	Templates.AddItem(BattleScanner());
	Templates.AddItem(TalonRounds());
	Templates.AddItem(FalconRounds());
	Templates.AddItem(APRounds());
	Templates.AddItem(StilettoRounds());
	Templates.AddItem(IncendiaryRounds());
	Templates.AddItem(VenomRounds());
	Templates.AddItem(MedikitBonusAbility());
	Templates.AddItem(NanoMedikitBonusAbility());
	Templates.AddItem(AmpBoosterAbility());
	Templates.AddItem(Neurowhip());
	Templates.AddItem(NeuralDampingAbility());
	Templates.AddItem(MindShield());
	Templates.AddItem(SKULLJACKAbility());
	Templates.AddItem(FinalizeSKULLJACK());
	Templates.AddItem(CancelSKULLJACK('CancelSKULLJACK', 'SKULLJACKAbility'));
	Templates.AddItem(CancelSKULLJACK('CancelSKULLMINE', 'SKULLMINEAbility'));
	Templates.AddItem(SKULLMINEAbility());
	Templates.AddItem(FinalizeSKULLMINE());
	Templates.AddItem(CombatStims());
	Templates.AddItem(ScorchCircuits());
	Templates.AddItem(ScorchCircuitsDamage());
	Templates.AddItem(AddPsiAmpCV_BonusStats());
	Templates.AddItem(AddPsiAmpMG_BonusStats());
	Templates.AddItem(AddPsiAmpBM_BonusStats());
	Templates.AddItem(LaserSight_Bsc());
	Templates.AddItem(LaserSight_Adv());
	Templates.AddItem(LaserSight_Sup());
	Templates.AddItem(HighCoverGenerator());
	Templates.AddItem(MimicBeacon());
	Templates.AddItem(WallPhasing());
	Templates.AddItem(WraithActivation());

	return Templates;
}

// ******************* Psi Amp Bonus ********************************
static function X2AbilityTemplate AddPsiAmpCV_BonusStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiAmpCV_BonusStats');
	Template.IconImage = "img:///gfxXComIcons.psi_telekineticfield";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Bonus to hacking stat Effect
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_PsiOffense, default.PSIAMP_CV_STATBONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}

static function X2AbilityTemplate AddPsiAmpMG_BonusStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiAmpMG_BonusStats');
	Template.IconImage = "img:///gfxXComIcons.psi_telekineticfield";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Bonus to hacking stat Effect
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_PsiOffense, default.PSIAMP_MG_STATBONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}
static function X2AbilityTemplate AddPsiAmpBM_BonusStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PsiAmpBM_BonusStats');
	Template.IconImage = "img:///gfxXComIcons.psi_telekineticfield";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Bonus to hacking stat Effect
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_PsiOffense, default.PSIAMP_BM_STATBONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}
// ******************* Psi Amp Bonus ********************************

static function X2AbilityTemplate AddNanofiberVestBonusAbility()
{
	local X2AbilityTemplate                 Template;	
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'NanofiberVestBonus');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	
	// Bonus to health stat Effect
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.NANOFIBER_VEST_HP_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}

static function X2AbilityTemplate PlatedVestBonusAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PlatedVestBonus');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Bonus to health stat Effect, also has armor
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.PLATED_VEST_HP_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.PLATED_VEST_MITIGATION_CHANCE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.PLATED_VEST_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate HazmatVestBonusAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;
	local X2Effect_DamageImmunity           DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HazmatVestBonus');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Bonus to health stat Effect, also gives protection from fire and poison
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.HAZMAT_VEST_HP_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);
	
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.ImmuneTypes.AddItem('Fire');
	DamageImmunity.ImmuneTypes.AddItem('Poison');
	DamageImmunity.ImmuneTypes.AddItem('Acid');
	DamageImmunity.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.ParthenogenicPoisonType);
	DamageImmunity.BuildPersistentEffect(1, true, false, false);
	DamageImmunity.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate MedikitBonusAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_DamageImmunity           DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MedikitBonus');
	Template.IconImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Medkit";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Protection from poison
	//
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.ImmuneTypes.AddItem('Poison');
	DamageImmunity.BuildPersistentEffect(1, true, false, false);
	DamageImmunity.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate NanoMedikitBonusAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_DamageImmunity           DamageImmunity;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'NanoMedikitBonus');
	Template.IconImage = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_MedkitMK2";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Protection from poison
	//
	DamageImmunity = new class'X2Effect_DamageImmunity';
	DamageImmunity.ImmuneTypes.AddItem('Poison');
	DamageImmunity.BuildPersistentEffect(1, true, false, false);
	DamageImmunity.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddTargetEffect(DamageImmunity);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate StasisVestBonusAbility()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;
	local X2Effect_Regeneration				RegenerationEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'StasisVestBonus');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_nanofibervest";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Bonus to health stat Effect
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.STASIS_VEST_HP_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	// Build the regeneration effect
	RegenerationEffect = new class'X2Effect_Regeneration';
	RegenerationEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	RegenerationEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, false, , Template.AbilitySourceName);
	RegenerationEffect.HealAmount = default.STASIS_VEST_REGEN_AMOUNT;
	RegenerationEffect.MaxHealAmount = default.STASIS_VEST_MAX_REGEN_AMOUNT;
	RegenerationEffect.HealthRegeneratedName = 'StasisVestHealthRegenerated';
	Template.AddTargetEffect(RegenerationEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate AddExplosiveDeviceDetonateAbility()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ExplosiveDeviceDetonate');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_storagemodule";

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.Hostility = eHostility_Offensive;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Template.TargetingMethod = class'X2TargetingMethod_ExplosiveDeviceDetonate';

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}

static function X2AbilityTemplate MediumPlatedArmorStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MediumPlatedArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	// giving health here; medium plated doesn't have mitigation
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.MEDIUM_PLATED_HEALTH_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}

static function X2AbilityTemplate HeavyPlatedArmorStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HeavyPlatedArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.HEAVY_PLATED_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.HEAVY_PLATED_MITIGATION_CHANCE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.HEAVY_PLATED_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}

static function X2AbilityTemplate MediumPoweredArmorStats()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MediumPoweredArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.MEDIUM_POWERED_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.MEDIUM_POWERED_MITIGATION_CHANCE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.MEDIUM_POWERED_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate HeavyPoweredArmorStats()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HeavyPoweredArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.HEAVY_POWERED_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorChance, default.HEAVY_POWERED_MITIGATION_CHANCE);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.HEAVY_POWERED_MITIGATION_AMOUNT);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate LightPlatedArmorStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LightPlatedArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	// light armor has dodge and mobility as well as health
	//
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	// PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, default.MediumPlatedHealthBonusName, default.MediumPlatedHealthBonusDesc, Template.IconImage);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.LIGHT_PLATED_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.LIGHT_PLATED_MOBILITY_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Dodge, default.LIGHT_PLATED_DODGE_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}

static function X2AbilityTemplate LightPoweredArmorStats()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;
	//local X2Effect_LowProfile               LowProfileEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LightPoweredArmorStats');
	// Template.IconImage  -- no icon needed for armor stats

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.LIGHT_POWERED_HEALTH_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Mobility, default.LIGHT_POWERED_MOBILITY_BONUS);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Dodge, default.LIGHT_POWERED_DODGE_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	// disabled - ttp# 6818
	//LowProfileEffect = new class'X2Effect_LowProfile';
	//LowProfileEffect.BuildPersistentEffect(1, true, false, false);
	//Template.AddTargetEffect(LowProfileEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;	
}

static function X2AbilityTemplate TracerRounds()
{
	local X2AbilityTemplate             Template;
	local X2Effect_TracerRounds         Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TracerRounds');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_TracerRounds';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	Template.AddShooterEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate TalonRounds()
{
	local X2AbilityTemplate             Template;
	local X2Effect_TalonRounds          Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'TalonRounds');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_TalonRounds';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	Effect.AimMod = default.TALON_AIM;
	Effect.CritChance = default.TALON_CRITCHANCE;
	Effect.CritDamage = default.TALON_CRIT;
	Template.AddShooterEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate FalconRounds()
{
	local X2AbilityTemplate             Template;
	local X2Effect_TalonRounds          Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FalconRounds');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_TalonRounds';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	Effect.AimMod = default.FALCON_AIM;
	Effect.CritChance = default.FALCON_CRITCHANCE;
	Effect.CritDamage = default.FALCON_CRIT;
	Template.AddShooterEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate IncendiaryRounds()
{
	local X2AbilityTemplate             Template;
	local X2Effect_IncendiaryRounds     Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'IncendiaryRounds');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_IncendiaryRounds';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	Template.AddShooterEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate VenomRounds()
{
	local X2AbilityTemplate             Template;
	local X2Effect_IncendiaryRounds     Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'VenomRounds');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_IncendiaryRounds';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	Template.AddShooterEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate APRounds()
{
	local X2AbilityTemplate             Template;
	local X2Effect_APRounds             Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'APRounds');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.bDisplayInUITacticalText = false;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_APRounds';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	Effect.CritDamage = default.APROUNDS_CRIT;
	Effect.CritChance = default.APROUNDS_CRITCHANCE;
	Effect.Pierce = default.APROUNDS_PIERCE;
	Template.AddShooterEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate StilettoRounds()
{
	local X2AbilityTemplate             Template;
	local X2Effect_APRounds             Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'StilettoRounds');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.bDisplayInUITacticalText = false;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	Effect = new class'X2Effect_APRounds';
	Effect.BuildPersistentEffect(1, true, false, false);
	Effect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	Effect.CritDamage = default.STILETTOROUNDS_CRIT;
	Effect.CritChance = default.STILETTOROUNDS_CRITCHANCE;
	Effect.Pierce = default.STILETTOROUNDS_PIERCE;
	Template.AddShooterEffect(Effect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate BattleScanner()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityCost_Ammo            AmmoCost;
	local X2AbilityTarget_Cursor        CursorTarget;
	local X2AbilityMultiTarget_Radius   RadiusMultiTarget;
	local X2Effect_PersistentSquadViewer    ViewerEffect;
	local X2Effect_ScanningProtocol     ScanningEffect;
	local X2Condition_UnitProperty      CivilianProperty;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BattleScanner');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_battlescanner";
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.bHideWeaponDuringFire = true;

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	RadiusMultiTarget.bIgnoreBlockingCover = true; // we don't need this, the squad viewer will do the appropriate things once thrown
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_Grenade';

	ScanningEffect = new class'X2Effect_ScanningProtocol';
	ScanningEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	ScanningEffect.TargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	Template.AddMultiTargetEffect(ScanningEffect);

	ScanningEffect = new class'X2Effect_ScanningProtocol';
	ScanningEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	CivilianProperty = new class'X2Condition_UnitProperty';
	CivilianProperty.ExcludeNonCivilian = true;
	CivilianProperty.ExcludeHostileToSource = false;
	CivilianProperty.ExcludeFriendlyToSource = false;
	ScanningEffect.TargetConditions.AddItem(CivilianProperty);
	Template.AddMultiTargetEffect(ScanningEffect);

	ViewerEffect = new class'X2Effect_PersistentSquadViewer';
	ViewerEffect.BuildPersistentEffect(default.BATTLESCANNER_DURATION, false, false, false, eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(ViewerEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
		
	return Template;
}

static function X2AbilityTemplate AmpBoosterAbility()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_PersistentStatChange         PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AmpBoosterAbility');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_PsiOffense, default.AMPBOOSTER_PSIOFFENSE);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate Neurowhip()
{
	local X2AbilityTemplate						Template;
	local X2Effect_PersistentStatChange         PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Neurowhip');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_PsiOffense, default.NEUROWHIP_PSIOFFENSE);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate NeuralDampingAbility()
{
	local X2AbilityTemplate						Template;
	local X2Effect_PersistentStatChange         PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'NeuralDampingAbility');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Will, default.DAMPING_WILL);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate MindShield()
{
	local X2AbilityTemplate						Template;
	local X2Effect_PersistentStatChange         PersistentStatChangeEffect;
	local X2Effect_DamageImmunity               ImmunityEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MindShield');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.EffectName = 'MindShieldStats';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_Will, default.MINDSHIELD_WILL);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	ImmunityEffect = new class'X2Effect_DamageImmunity';
	ImmunityEffect.EffectName = 'MindShieldImmunity';
	ImmunityEffect.ImmuneTypes.AddItem('Mental');
	ImmunityEffect.ImmuneTypes.AddItem(class'X2Item_DefaultDamageTypes'.default.DisorientDamageType);
	ImmunityEffect.ImmuneTypes.AddItem('stun');
	ImmunityEffect.ImmuneTypes.AddItem('Unconscious');
	ImmunityEffect.BuildPersistentEffect(1, true, false, false);
	ImmunityEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false, , Template.AbilitySourceName);
	Template.AddTargetEffect(ImmunityEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate SKULLMINEAbility()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityTarget_MovingMelee        MovingMeleeTarget;
	local X2Condition_StasisLanceTarget StasisLanceCondition;
	local X2Effect_ApplyWeaponDamage        MissDamageEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SKULLMINEAbility');
	Template.FinalizeAbilityName = 'FinalizeSKULLMINE';
	Template.CancelAbilityName = 'CancelSKULLMINE';
	Template.AdditionalAbilities.AddItem('FinalizeSKULLMINE');
	Template.AdditionalAbilities.AddItem('CancelSKULLMINE');

	Template.AbilityCharges = new class'X2AbilityCharges_StasisLance';

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STASIS_LANCE_PRIORITY;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;                   //  the FinalizeSKULLJACK ability will consume the action point
	Template.AbilityCosts.AddItem(ActionPointCost);
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Charges');

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StasisLance';

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	StasisLanceCondition = new class'X2Condition_StasisLanceTarget';
	StasisLanceCondition.HackAbilityName = Template.FinalizeAbilityName;
	Template.AbilityTargetConditions.AddItem(StasisLanceCondition);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);
	Template.AddShooterEffectExclusions();

	MovingMeleeTarget = new class'X2AbilityTarget_MovingMelee';
	Template.AbilityTargetStyle = MovingMeleeTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	//  Miss Damage Effect
	MissDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	MissDamageEffect.bApplyOnHit = False;
	MissDamageEffect.bApplyOnMiss = True;
	MissDamageEffect.bIgnoreBaseDamage = true;
	MissDamageEffect.EffectDamageValue.Pierce = 2;	// 2 points of damage on a miss
	MissDamageEffect.EffectDamageValue.Damage = 2;	// 2 points of damage on a miss
	Template.AddTargetEffect(MissDamageEffect);

	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_mindblast";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.bShowActivation = true;
	Template.SourceHitSpeech = 'StunnedAlien';
	Template.SourceMissSpeech = 'AlienNotStunned';
	Template.MeleePuckMeshPath = "UI_3D.CursorSet.S_MovePuck_SkullJack";

	Template.Requirements.RequiredTechs.AddItem('Skullmining');

	Template.CinescriptCameraType = "Soldier_Skulljack_Stage1";

	Template.BuildNewGameStateFn = SKULLJACK_BuildGameState;
	Template.BuildInterruptGameStateFn = SKULLJACK_BuildInterruptGameState;
	Template.BuildVisualizationFn = SKULLJACK_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate FinalizeSKULLMINE()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Effect_ApplyWeaponDamage        HitDamageEffect;
	local X2AbilityCost_ActionPoints        ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FinalizeSKULLMINE');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HACK_PRIORITY;
	Template.bDisplayInUITooltip = false;

	// successfully completing the hack requires and costs an action point
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_Hacking';
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  This will be activated automatically by the hacking UI.

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	//  Hit Damage Effect
	HitDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	HitDamageEffect.bApplyOnHit = true;
	HitDamageEffect.bApplyOnMiss = false;
	HitDamageEffect.bIgnoreBaseDamage = true;
	HitDamageEffect.EffectDamageValue.Pierce = 20;	// 20 points of damage on a hit
	HitDamageEffect.EffectDamageValue.Damage = 20;	// 20 points of damage on a hit
	Template.AddTargetEffect(HitDamageEffect);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType = "Soldier_Skulljack_Stage2";

	Template.BuildNewGameStateFn = class'X2Ability_DefaultAbilitySet'.static.FinalizeHackAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.FinalizeHackAbility_BuildVisualization;

	return Template;
}


static function X2AbilityTemplate SKULLJACKAbility()
{
	local X2AbilityTemplate         Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityTarget_MovingMelee       MovingMeleeTarget;
	local X2Condition_StasisLanceTarget StasisLanceCondition;
	local X2Effect_ApplyWeaponDamage        MissDamageEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'SKULLJACKAbility');
	Template.FinalizeAbilityName = 'FinalizeSKULLJACK';
	Template.CancelAbilityName = 'CancelSKULLJACK';
	Template.AdditionalAbilities.AddItem('FinalizeSKULLJACK');
	Template.AdditionalAbilities.AddItem('CancelSKULLJACK');

	Template.AbilityCharges = new class'X2AbilityCharges_StasisLance';

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STASIS_LANCE_PRIORITY;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;                   //  the FinalizeSKULLJACK ability will consume the action point
	Template.AbilityCosts.AddItem(ActionPointCost);
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_Charges');

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_StasisLance';

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	StasisLanceCondition = new class'X2Condition_StasisLanceTarget';
	StasisLanceCondition.HackAbilityName = Template.FinalizeAbilityName;
	Template.AbilityTargetConditions.AddItem(StasisLanceCondition);
	Template.AbilityTargetConditions.AddItem(default.MeleeVisibilityCondition);
	Template.AddShooterEffectExclusions();

	MovingMeleeTarget = new class'X2AbilityTarget_MovingMelee';
	Template.AbilityTargetStyle = MovingMeleeTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.TargetingMethod = class'X2TargetingMethod_MeleePath';

	//  Miss Damage Effect
	MissDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	MissDamageEffect.bApplyOnHit = False;
	MissDamageEffect.bApplyOnMiss = True;
	MissDamageEffect.bIgnoreBaseDamage = true;
	MissDamageEffect.EffectDamageValue.Pierce = 2;	// 2 points of damage on a miss
	MissDamageEffect.EffectDamageValue.Damage = 2;	// 2 points of damage on a miss
	Template.AddTargetEffect(MissDamageEffect);

	Template.MeleePuckMeshPath = "UI_3D.CursorSet.S_MovePuck_SkullJack";

	Template.Hostility = eHostility_Offensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_skulljack";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.bShowActivation = true;
	Template.SourceHitSpeech = 'StunnedAlien';
	Template.SourceMissSpeech = 'AlienNotStunned';

	Template.CinescriptCameraType = "Soldier_Skulljack_Stage1";
	Template.BuildNewGameStateFn = SKULLJACK_BuildGameState;
	Template.BuildInterruptGameStateFn = SKULLJACK_BuildInterruptGameState;
	Template.BuildVisualizationFn = SKULLJACK_BuildVisualization;

	return Template;
}


simulated static function XComGameState SKULLJACK_BuildInterruptGameState(XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus)
{
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit TargetUnit;

	NewGameState = class'X2Ability_DefaultAbilitySet'.static.MoveAbility_BuildInterruptGameState(Context, InterruptStep, InterruptionStatus);

	AbilityContext = XComGameStateContext_Ability(Context);
	`assert(AbilityContext != None);
	`assert(AbilityContext.InputContext.PrimaryTarget.ObjectID != 0);

	// Hack: Prevent the target from scampering inbetween the SKULLJACK and FinalizeSKULLJACK abilities.
	// Needs to happen before the unit is seen - AI builds their list of scampering units immediately.
	if (AbilityContext.IsResultContextHit())
	{
		TargetUnit = XComGameState_Unit(NewGameState.CreateStateObject(TargetUnit.Class, AbilityContext.InputContext.PrimaryTarget.ObjectID));
		TargetUnit.bTriggerRevealAI = false;
		NewGameState.AddStateObject(TargetUnit);
	}

	return NewGameState;
}

static function XComGameState SKULLJACK_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityCost_ActionPoints ActionPointCostOnMiss;
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit SourceUnit;

	History = `XCOMHISTORY;
	NewGameState = History.CreateNewGameState(true, Context);

	// finalize the movement portion of the ability
	class'X2Ability_DefaultAbilitySet'.static.MoveAbility_FillOutGameState(NewGameState, false); //Do not apply costs at this time.

	// on a miss, this needs to actually cost an action point, so remove the "free" from the cost
	AbilityContext = XComGameStateContext_Ability(Context);
	if( AbilityContext.ResultContext.HitResult == eHit_Miss )
	{
		ActionPointCostOnMiss = new class'X2AbilityCost_ActionPoints';
		ActionPointCostOnMiss.iNumPoints = 1;

		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));
		SourceUnit = XComGameState_Unit(NewGameState.CreateStateObject(SourceUnit.Class, AbilityContext.InputContext.SourceObject.ObjectID));
		NewGameState.AddStateObject(SourceUnit);

		ActionPointCostOnMiss.ApplyCost(AbilityContext, AbilityState, SourceUnit, None, NewGameState);
	}

	// build the "fire" animation for the skulljack
	class'X2Ability_DefaultAbilitySet'.static.HackAbility_FillOutGameState(NewGameState); //Costs applied here.

	return NewGameState;
}

static function X2AbilityTemplate FinalizeSKULLJACK()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Effect_ApplyWeaponDamage        HitDamageEffect;
	local X2AbilityCost_ActionPoints        ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FinalizeSKULLJACK');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HACK_PRIORITY;
	Template.bDisplayInUITooltip = false;

	// successfully completing the hack requires and costs an action point
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_Hacking';
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  This will be activated automatically by the hacking UI.

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	//  Hit Damage Effect
	HitDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	HitDamageEffect.bApplyOnHit = true;
	HitDamageEffect.bApplyOnMiss = false;
	HitDamageEffect.bIgnoreBaseDamage = true;
	HitDamageEffect.EffectDamageValue.Pierce = 20;	// 20 points of damage on a hit
	HitDamageEffect.EffectDamageValue.Damage = 20;	// 20 points of damage on a hit
	Template.AddTargetEffect(HitDamageEffect);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType = "Soldier_Skulljack_Stage2";

	Template.BuildNewGameStateFn = class'X2Ability_DefaultAbilitySet'.static.FinalizeHackAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.FinalizeHackAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate CancelSKULLJACK(Name TemplateName, Name AssociatedTemplateName)
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityCost_Charges				ChargesCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.HACK_PRIORITY;
	Template.bDisplayInUITooltip = false;

	// we need to refund the costs of initiating the hack
	ChargesCost = new class'X2AbilityCost_Charges';
	ChargesCost.NumCharges = -1;
	ChargesCost.SharedAbilityCharges.AddItem(AssociatedTemplateName);
	Template.AbilityCosts.AddItem(ChargesCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  This will be activated automatically by the hacking UI.

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.Hostility = eHostility_Neutral;

	Template.CinescriptCameraType = "Soldier_Skulljack_Stage2";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = None;

	return Template;
		}
simulated function SKULLJACK_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef, TargetUnitRef;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_PlaySyncedMeleeAnimation SynceMeleeAction;
	local X2Action_SendInterTrackMessage MissTriggerAction;
	local X2Action_ApplyWeaponDamageToUnit WeaponDamageAction;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate     AbilityTemplate;
	local X2VisualizerInterface TargetVisualizerInterface;
	local int i;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;
	TargetUnitRef = Context.InputContext.PrimaryTarget;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	AbilityTemplate = AbilityState.GetMyTemplate();

	// first build any movement visualization
	if(Context.InputContext.MovementPaths.Length > 0)
	{
		class'X2Ability_DefaultAbilitySet'.static.MoveAbility_BuildVisualization(VisualizeGameState, OutVisualizationTracks);
	}

	//Configure the visualization track for the shooter
	//****************************************************************************************
	if(OutVisualizationTracks.Length > 0)
	{
		// if we had a movement track added, use that
		BuildTrack = OutVisualizationTracks[0];
		OutVisualizationTracks.Remove(0, 1); // we'll readd it after modifying it, since unrealscript can't pass structs by reference
	}
	else
	{
		BuildTrack = EmptyTrack;
	}

	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	if( Context.IsResultContextHit() )
	{
		if( AbilityTemplate.SourceHitSpeech != '' )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceHitSpeech, eColor_Bad);
		}

		class'X2Action_SKULLJACK'.static.AddToVisualizationTrack(BuildTrack, Context);
	}
	else
	{
		if( AbilityTemplate.SourceMissSpeech != '' )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.SourceMissSpeech, eColor_Bad);
		}

		SynceMeleeAction = X2Action_PlaySyncedMeleeAnimation(class'X2Action_PlaySyncedMeleeAnimation'.static.AddToVisualizationTrack(BuildTrack, Context));
		SynceMeleeAction.SourceAnim = 'FF_SkulljackerMissA';
		SynceMeleeAction.TargetAnim = 'FF_SkulljackedMissA';

		//The synced-melee doesn't actually send a message to let the damage flyover/etc happen
		MissTriggerAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
		MissTriggerAction.SendTrackMessageToRef = TargetUnitRef;
	}

	OutVisualizationTracks.AddItem(BuildTrack);


	//Configure the visualization track for the target
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(TargetUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(TargetUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(TargetUnitRef.ObjectID);

	//  This is sort of a super hack, that allows DLC/mods to visualize extra stuff in here.
	//  Visualize effects from index 1 as index 0 should be the base game damage effect.
	for (i = 1; i < AbilityTemplate.AbilityTargetEffects.Length; ++i)
	{
		AbilityTemplate.AbilityTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[i]));
	}

	if( Context.IsResultContextMiss() )
	{
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

		if( AbilityTemplate.LocMissMessage != "" || AbilityTemplate.TargetMissSpeech != '' )
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocMissMessage, AbilityTemplate.TargetMissSpeech, eColor_Bad);
		}

		//Show the miss damage here, including a "MISSED" flyover (LocMissMessage should never just contain "Miss" or something similar)
		WeaponDamageAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, Context));
		WeaponDamageAction.OriginatingEffect = AbilityTemplate.AbilityTargetEffects[0];
		WeaponDamageAction.bPlayDamageAnim = false; //The synced melee action will play the animation for us

		//Visualize the target's death normally if they were killed by the miss damage
		TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
		if (TargetVisualizerInterface != none)
		{
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
		}
	}
	else if( Context.IsResultContextHit() && (AbilityTemplate.LocHitMessage != "" || AbilityTemplate.TargetHitSpeech != '') )
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocHitMessage, AbilityTemplate.TargetHitSpeech, eColor_Good);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
}

static function X2AbilityTemplate CombatStims()
{
	local X2AbilityTemplate             Template;
	local X2Effect_CombatStims          StimEffect;
	local X2Effect_PersistentStatChange StatEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CombatStims');

	Template.AbilityCosts.AddItem(default.FreeActionCost);
	Template.AbilityCosts.AddItem(new class'X2AbilityCost_ConsumeItem');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.Hostility = eHostility_Defensive;
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_combatstims";
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.COMBAT_STIMS_PRIORITY;
	Template.ActivationSpeech = 'CombatStim';
	Template.bShowActivation = true;
	Template.CustomSelfFireAnim = 'FF_FireMedkitSelf';

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	StimEffect = new class'X2Effect_CombatStims';
	StimEffect.BuildPersistentEffect(default.COMBAT_STIM_DURATION, false, true, false, eGameRule_PlayerTurnEnd);
	StimEffect.SetDisplayInfo(ePerkBuff_Bonus, default.CombatStimBonusName, default.CombatStimBonusDesc, Template.IconImage);
	Template.AddTargetEffect(StimEffect);

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.EffectName = 'StimStats';
	StatEffect.DuplicateResponse = eDupe_Refresh;
	StatEffect.BuildPersistentEffect(default.COMBAT_STIM_DURATION, false, true, false, eGameRule_PlayerTurnEnd);
	StatEffect.SetDisplayInfo(ePerkBuff_Bonus, default.CombatStimBonusName, default.CombatStimBonusDesc, Template.IconImage, false);
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.COMBAT_STIM_MOBILITY_MOD, MODOP_Multiplication);
	Template.AddTargetEffect(StatEffect);

	return Template;
}

static function X2AbilityTemplate ScorchCircuits()
{
	local X2AbilityTemplate						Template;
	local X2Effect_PersistentStatChange         PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ScorchCircuits');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_HP, default.SCORCHCIRCUITS_HEALTH_BONUS);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	Template.AdditionalAbilities.AddItem('ScorchCircuitsDamage');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate ScorchCircuitsDamage()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ApplyWeaponDamage            DamageEffect;
	local X2AbilityTrigger_EventListener        EventTrigger;
	local X2Condition_AbilitySourceWeapon       WeaponCondition;
	local X2Effect_Burning                      BurningEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ScorchCircuitsDamage');

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Defensive;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SimpleSingleTarget;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetConditions.AddItem(default.LivingHostileTargetProperty);

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.EffectDamageValue.Damage = 3;
	DamageEffect.EffectDamageValue.Spread = 1;
	DamageEffect.DamageTypes.AddItem('Electrical');
	Template.AddTargetEffect(DamageEffect);

	BurningEffect = class'X2StatusEffects'.static.CreateBurningStatusEffect(2, 0);
	BurningEffect.ApplyChance = default.SCORCHCIRCUITS_APPLY_CHANCE;
	WeaponCondition = new class'X2Condition_AbilitySourceWeapon';
	WeaponCondition.MatchWeaponTemplate = 'Hellweave';
	BurningEffect.TargetConditions.AddItem(WeaponCondition);
	Template.AddTargetEffect(BurningEffect);

	EventTrigger = new class'X2AbilityTrigger_EventListener';
	EventTrigger.ListenerData.EventID = 'AbilityActivated';
	EventTrigger.ListenerData.Filter = eFilter_None;
	EventTrigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventTrigger.ListenerData.EventFn = class'XComGameState_Ability'.static.ScorchCircuits_AbilityActivated;
	Template.AbilityTriggers.AddItem(EventTrigger);

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.VisualizationTrackInsertedFn = ScorchCircuits_VisualizationTrackInsert;

	return Template;
}

static function X2AbilityTemplate LaserSight(int CritBonus, name TemplateName)
{
	local X2AbilityTemplate						Template;
	local X2Effect_LaserSight                   LaserSightEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_hunter";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	LaserSightEffect = new class'X2Effect_LaserSight';
	LaserSightEffect.BuildPersistentEffect(1, true, false, false);
	LaserSightEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, false);
	LaserSightEffect.CritBonus = CritBonus;
	LaserSightEffect.FriendlyName = Template.LocFriendlyName;
	Template.AddTargetEffect(LaserSightEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate LaserSight_Bsc()
{
	return LaserSight(class'X2Item_DefaultUpgrades'.default.CRIT_UPGRADE_BSC, 'LaserSight_Bsc');
}

static function X2AbilityTemplate LaserSight_Adv()
{
	return LaserSight(class'X2Item_DefaultUpgrades'.default.CRIT_UPGRADE_ADV, 'LaserSight_Adv');
}

static function X2AbilityTemplate LaserSight_Sup()
{
	return LaserSight(class'X2Item_DefaultUpgrades'.default.CRIT_UPGRADE_SUP, 'LaserSight_Sup');
}

static function X2AbilityTemplate HighCoverGenerator()
{
	local X2AbilityTemplate             Template;
	local X2Effect_GenerateCover        CoverEffect;
	local X2AbilityCost_ActionPoints    ActionPointCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'HighCoverGenerator');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_shieldwall";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.ARMOR_ACTIVE_PRIORITY;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	CoverEffect = new class'X2Effect_GenerateCover';
	CoverEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	CoverEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	Template.AddShooterEffect(CoverEffect);

	Template.bShowActivation = true;
	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate MimicBeacon()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityCost_Ammo            AmmoCost;
	local X2AbilityTarget_Cursor        CursorTarget;
	local X2AbilityMultiTarget_Radius   RadiusMultiTarget;
	local X2Effect_SpawnMimicBeacon     SpawnMimicBeacon;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MimicBeaconThrow');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_mimicbeacon";
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	Template.bHideWeaponDuringFire = true;

	AmmoCost = new class'X2AbilityCost_Ammo';
	AmmoCost.iAmmo = 1;
	Template.AbilityCosts.AddItem(AmmoCost);

	Template.bUseAmmoAsChargesForHUD = true;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.STANDARD_GRENADE_PRIORITY;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	RadiusMultiTarget.bIgnoreBlockingCover = true; // we don't need this, the squad viewer will do the appropriate things once thrown
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	Template.TargetingMethod = class'X2TargetingMethod_MimicBeacon';
	Template.SkipRenderOfTargetingTemplate = true;

	Template.bUseThrownGrenadeEffects = true;

	SpawnMimicBeacon = new class'X2Effect_SpawnMimicBeacon';
	SpawnMimicBeacon.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(SpawnMimicBeacon);
	Template.AddShooterEffect(new class'X2Effect_BreakUnitConcealment');

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = MimicBeacon_BuildVisualization;
		
	return Template;
}

simulated function MimicBeacon_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability Context;
	local StateObjectReference InteractingUnitRef;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack SourceTrack, MimicBeaconTrack;
	local XComGameState_Unit MimicSourceUnit, SpawnedUnit;
	local UnitValue SpawnedUnitValue;
	local X2Effect_SpawnMimicBeacon SpawnMimicBeaconEffect;
	local X2Action_MimicBeaconThrow FireAction;
	local X2Action_PlayAnimation AnimationAction;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;

	//Configure the visualization track for the shooter
	//****************************************************************************************
	SourceTrack = EmptyTrack;
	SourceTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	SourceTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	SourceTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_ExitCover'.static.AddToVisualizationTrack(SourceTrack, Context);
	FireAction = X2Action_MimicBeaconThrow(class'X2Action_MimicBeaconThrow'.static.AddToVisualizationTrack(SourceTrack, Context));
	class'X2Action_EnterCover'.static.AddToVisualizationTrack(SourceTrack, Context);

	// Configure the visualization track for the mimic beacon
	//******************************************************************************************
	MimicSourceUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID));
	`assert(MimicSourceUnit != none);
	MimicSourceUnit.GetUnitValue(class'X2Effect_SpawnUnit'.default.SpawnedUnitValueName, SpawnedUnitValue);

	MimicBeaconTrack = EmptyTrack;
	MimicBeaconTrack.StateObject_OldState = History.GetGameStateForObjectID(SpawnedUnitValue.fValue, eReturnType_Reference, VisualizeGameState.HistoryIndex);
	MimicBeaconTrack.StateObject_NewState = MimicBeaconTrack.StateObject_OldState;
	SpawnedUnit = XComGameState_Unit(MimicBeaconTrack.StateObject_NewState);
	`assert(SpawnedUnit != none);
	MimicBeaconTrack.TrackActor = History.GetVisualizer(SpawnedUnit.ObjectID);

	// Set the Throwing Unit's FireAction to reference the spawned unit
	FireAction.MimicBeaconUnitReference = SpawnedUnit.GetReference();
	// Set the Throwing Unit's FireAction to reference the spawned unit
	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(MimicBeaconTrack, Context);

	// Only one target effect and it is X2Effect_SpawnMimicBeacon
	SpawnMimicBeaconEffect = X2Effect_SpawnMimicBeacon(Context.ResultContext.ShooterEffectResults.Effects[0]);
	
	if( SpawnMimicBeaconEffect == none )
	{
		`RedScreenOnce("MimicBeacon_BuildVisualization: Missing X2Effect_SpawnMimicBeacon -dslonneger @gameplay");
		return;
	}

	SpawnMimicBeaconEffect.AddSpawnVisualizationsToTracks(Context, SpawnedUnit, MimicBeaconTrack, MimicSourceUnit, SourceTrack);

	class'X2Action_SyncVisualizer'.static.AddToVisualizationTrack(MimicBeaconTrack, Context);

	AnimationAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(MimicBeaconTrack, Context));
	AnimationAction.Params.AnimName = default.MIMIC_BEACON_START_ANIM;
	AnimationAction.Params.BlendTime = 0.0f;

	OutVisualizationTracks.AddItem(SourceTrack);
	OutVisualizationTracks.AddItem(MimicBeaconTrack);
}

static function X2AbilityTemplate WallPhasing()
{
	local X2AbilityTemplate                     Template;
	local X2Effect_PersistentTraversalChange	WallPhasing;
	local X2AbilityCharges                      Charges;
	local X2AbilityCost_Charges                 ChargeCost;
	local X2Effect_TriggerEvent					ActivationWindowEvent;
	local X2Condition_UnitEffects               EffectsCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'WallPhasing');

	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_item_wraith";
	Template.AbilityConfirmSound = "TacticalUI_Activate_Ability_Wraith_Armor";

	Template.AdditionalAbilities.AddItem( 'WraithActivation' );

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem( default.LivingShooterProperty );
	Template.AbilityTriggers.AddItem( default.PlayerInputTrigger );
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityCosts.AddItem(default.FreeActionCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.WALL_PHASING_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');
	Template.AbilityShooterConditions.AddItem(EffectsCondition);

	ActivationWindowEvent = new class'X2Effect_TriggerEvent';
	ActivationWindowEvent.TriggerEventName = default.WraithActivationDurationEventName;
	Template.AddTargetEffect( ActivationWindowEvent );

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;
	Template.bSkipPerkActivationActions = true; // we'll trigger related perks as part of the movement action

	WallPhasing = new class'X2Effect_PersistentTraversalChange';
	WallPhasing.BuildPersistentEffect( default.WALL_PHASING_DURATION, false, true, false, eGameRule_PlayerTurnBegin );
	WallPhasing.SetDisplayInfo( ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText( ), Template.IconImage, true );
	WallPhasing.AddTraversalChange( eTraversal_Phasing, true );
	WallPhasing.EffectName = 'PhasingEffect';
	WallPhasing.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect( WallPhasing );

	return Template;
}

static function X2AbilityTemplate WraithActivation()
{
	local X2AbilityTemplate		Template;
	local X2Effect_Persistent	ActivationDuration;
	local X2AbilityTrigger_EventListener EventListener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'WraithActivation');

	Template.Hostility = eHostility_Neutral;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.AbilitySourceName = 'eAbilitySource_Item';

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityShooterConditions.AddItem( default.LivingShooterProperty );
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityCosts.AddItem( default.FreeActionCost );

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.FrameAbilityCameraType = eCameraFraming_Never;

	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.EventID = default.WraithActivationDurationEventName;
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.Filter = eFilter_Unit;
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.WallPhasingActivation;
	Template.AbilityTriggers.AddItem( EventListener );

	ActivationDuration = new class'X2Effect_Persistent';
	ActivationDuration.BuildPersistentEffect( default.WALL_PHASING_DURATION, false, true, false, eGameRule_PlayerTurnBegin );
	ActivationDuration.EffectName = 'ActivationDuration';
	ActivationDuration.DuplicateResponse = eDupe_Refresh;
	Template.AddTargetEffect( ActivationDuration );

	return Template;
}

static function ScorchCircuits_VisualizationTrackInsert(out array<VisualizationTrack> VisualizationTracks, XComGameStateContext_Ability Context, int OuterIndex, int InnerIndex)
{
	local int TrackIndex;
	local X2Action_ApplyWeaponDamageToUnit DamageAction;
	local X2Action_EnterCover EnterCoverAction;

	if (XGUnit(`XCOMHISTORY.GetVisualizer(Context.InputContext.PrimaryTarget.ObjectID)) == VisualizationTracks[OuterIndex].TrackActor)
	{
		//Look for the EnteringCover action for the target and prevent the delay from happening because the ApplyWeaponDamage action should happen immediately.
		for (TrackIndex = InnerIndex - 1; TrackIndex >= 0; --TrackIndex)
		{
			EnterCoverAction = X2Action_EnterCover(VisualizationTracks[OuterIndex].TrackActions[TrackIndex]);
			if (EnterCoverAction != none)
			{
				EnterCoverAction.bInstantEnterCover = true;
				break;
			}
		}
	}
	else
	{
		//Look for the ApplyWeaponDamage action for the source and prevent waiting on the hit animation to end since the counterattack needs to happen immediately.
		for (TrackIndex = InnerIndex - 1; TrackIndex >= 0; --TrackIndex)
		{
			DamageAction = X2Action_ApplyWeaponDamageToUnit(VisualizationTracks[OuterIndex].TrackActions[TrackIndex]);
			if (DamageAction != none)
			{
				DamageAction.bSkipWaitForAnim = true;
				break;
			}
		}
	}
}

DefaultProperties
{
	WraithActivationDurationEventName="WraithActivationEvent"
}