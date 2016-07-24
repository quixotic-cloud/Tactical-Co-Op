class X2Ability_MimicBeacon extends X2Ability
	config(GameData_SoldierSkills);

var config int MIMIC_BEACON_TURNS_LENGTH;
var config int GuaranteedToHitMod;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateInitializeAbility());
	Templates.AddItem(GuaranteedToHit());
	
	return Templates;
}

static function X2AbilityTemplate CreateInitializeAbility()
{
	local X2AbilityTemplate Template;
	local X2Effect_MimicBeacon MimicBeaconEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'MimicBeaconInitialize');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	// Build the immunities
	MimicBeaconEffect = new class'X2Effect_MimicBeacon';
	MimicBeaconEffect.BuildPersistentEffect(default.MIMIC_BEACON_TURNS_LENGTH, false, true, false, eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(MimicBeaconEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;

	return Template;
}

static function X2AbilityTemplate GuaranteedToHit()
{
	local X2AbilityTemplate						Template;
	local X2Effect_ToHitModifier                HitEffect;

	// Icon Properties
	`CREATE_X2ABILITY_TEMPLATE(Template, 'GuaranteedToHit');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	HitEffect = new class'X2Effect_ToHitModifier';
	HitEffect.BuildPersistentEffect(1, true, false, false);
	HitEffect.bApplyAsTarget = true;
	HitEffect.AddEffectHitModifier(eHit_Success, default.GuaranteedToHitMod, Template.LocFriendlyName);
	Template.AddTargetEffect(HitEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}