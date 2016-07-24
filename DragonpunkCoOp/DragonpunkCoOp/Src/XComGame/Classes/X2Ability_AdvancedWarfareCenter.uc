class X2Ability_AdvancedWarfareCenter extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(LightningReflexes());

	return Templates;
}

static function X2AbilityTemplate LightningReflexes()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_Persistent                   ReflexesEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LightningReflexes');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_lightningreflexes";

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	ReflexesEffect = new class'X2Effect_Persistent';
	ReflexesEffect.BuildPersistentEffect(1, true, false, false, eGameRule_PlayerTurnBegin);
	ReflexesEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	ReflexesEffect.EffectTickedFn = ReflexesEffectTicked;
	ReflexesEffect.DuplicateResponse = eDupe_Ignore;
	Template.AddTargetEffect(ReflexesEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	Template.bCrossClassEligible = true;

	return Template;
}

function bool ReflexesEffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit SourceUnit, NewSourceUnit;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (SourceUnit != none)
	{
		if (!SourceUnit.bLightningReflexes)
		{
			NewSourceUnit = XComGameState_Unit(NewGameState.CreateStateObject(SourceUnit.Class, SourceUnit.ObjectID));
			NewSourceUnit.bLightningReflexes = true;
			NewGameState.AddStateObject(NewSourceUnit);
		}
	}

	return false;           //  do not end the effect
}