class X2Ability_Vulnerabilities extends X2Ability
	config(GameCore);

var config int MELEE_DAMAGE_MODIFIER;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(AddVulnerabilityMeleeAbility());

	return Templates;
}

//******** Melee Vulnerability Ability **********
static function X2AbilityTemplate AddVulnerabilityMeleeAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTargetStyle TargetStyle;
	local X2AbilityTrigger Trigger;
	local X2Effect_MeleeDamageAdjust DamageModifier;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'VulnerabilityMelee');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sectoid_meleevulnerability";

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	// This ability will only be targeting the unit it is on
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	// Triggers at the start of the tactical
	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	DamageModifier = new class'X2Effect_MeleeDamageAdjust';
	DamageModifier.BuildPersistentEffect(1, true, true, true);
	DamageModifier.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, , , Template.AbilitySourceName);
	DamageModifier.DamageMod = default.MELEE_DAMAGE_MODIFIER;
	Template.AddTargetEffect(DamageModifier);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  TODO: Should there be visualization?

	return Template;
}