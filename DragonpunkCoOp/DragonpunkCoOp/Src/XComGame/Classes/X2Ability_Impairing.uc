//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_Impairing extends X2Ability;

var privatewrite name ImpairingAbilityName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateApplyImpairingEffectAbility());
	
	return Templates;
}

static function X2DataTemplate CreateApplyImpairingEffectAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityToHitCalc_StatCheck_UnitVsUnit    StatContest;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Effect_Persistent               DisorientedEffect;
	local X2Effect_Stunned				    StunnedEffect;
	local X2Effect_Persistent               UnconsciousEffect;
	local X2Condition_UnitProperty          UnitPropertyCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.ImpairingAbilityName);

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	Template.bDontDisplayInAbilitySummary = true;
	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.OnlyIncludeTargetsInsideWeaponRange = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');      //  ability is activated by another ability that hits

	// Target Conditions
	//
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeImpaired = true;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeHostileToSource = false;
	UnitPropertyCondition.FailOnNonUnits = true;

	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);
	Template.AbilityTargetConditions.AddItem(default.GameplayVisibilityCondition);

	// Shooter Conditions
	//
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Template.AddShooterEffectExclusions();

	// This will be a stat contest
	StatContest = new class'X2AbilityToHitCalc_StatCheck_UnitVsUnit';
	StatContest.AttackerStat = eStat_Strength;
	Template.AbilityToHitCalc = StatContest;

	// On hit effects
	//  Stunned effect for 1 or 2 unblocked hit
	DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect(, , false);
	DisorientedEffect.MinStatContestResult = 1;
	DisorientedEffect.MaxStatContestResult = 2;
	DisorientedEffect.bRemoveWhenSourceDies = false;
	Template.AddTargetEffect(DisorientedEffect);

	//  Stunned effect for 3 or 4 unblocked hit
	StunnedEffect = class'X2StatusEffects'.static.CreateStunnedStatusEffect(2, 100, false);
	StunnedEffect.MinStatContestResult = 3;
	StunnedEffect.MaxStatContestResult = 4;
	StunnedEffect.bRemoveWhenSourceDies = false;
	Template.AddTargetEffect(StunnedEffect);

	//  Unconscious effect for 5 unblocked hits
	UnconsciousEffect = class'X2StatusEffects'.static.CreateUnconsciousStatusEffect();
	UnconsciousEffect.MinStatContestResult = 5;
	UnconsciousEffect.MaxStatContestResult = 0;
	UnconsciousEffect.bRemoveWhenSourceDies = false;
	Template.AddTargetEffect(UnconsciousEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function ImpairingAbilityEffectTriggeredVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateContext Context;
	local XComGameStateContext_Ability TestAbilityContext;
	local int i, j;
	local XComGameStateHistory History;
	local bool bAbilityWasSuccess;
	local X2AbilityTemplate AbilityTemplate;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameStateVisualizationMgr VisualizationMgr;

	if( (EffectApplyResult != 'AA_Success') || (XComGameState_Unit(BuildTrack.StateObject_NewState) == none) )
	{
		return;
	}

	Context = VisualizeGameState.GetContext();
	AbilityContext = XComGameStateContext_Ability(Context);

	if( AbilityContext.EventChainStartIndex != 0 )
	{
		History = `XCOMHISTORY;
		VisualizationMgr = `XCOMVISUALIZATIONMGR;

		// This GameState is part of a chain, which means there may be a stun to the target
		for( i = AbilityContext.EventChainStartIndex; !Context.bLastEventInChain; ++i )
		{
			Context = History.GetGameStateFromHistory(i).GetContext();

			TestAbilityContext = XComGameStateContext_Ability(Context);
			bAbilityWasSuccess = (TestAbilityContext != none) && class'XComGameStateContext_Ability'.static.IsHitResultHit(TestAbilityContext.ResultContext.HitResult);

			// Continue if
			// The TestAbilityContext exists and was successful
			// AND
			// The TestAbility is the Impairing Ability
			// AND
			// The TestAbility and Original Ability have the same source
			// AND
			// The TestAbility's primary target and BuildTrack's unit are the same
			// AND
			// The primary targets are the same OR the Impairing Ability's target is in the Original Ability's MultiTargets
			if( bAbilityWasSuccess &&
				TestAbilityContext.InputContext.AbilityTemplateName == default.ImpairingAbilityName &&
				TestAbilityContext.InputContext.SourceObject.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID &&
				TestAbilityContext.InputContext.PrimaryTarget.ObjectID == BuildTrack.StateObject_NewState.ObjectID &&
				(TestAbilityContext.InputContext.PrimaryTarget.ObjectID == AbilityContext.InputContext.PrimaryTarget.ObjectID ||
				 AbilityContext.InputContext.MultiTargets.Find('ObjectID', TestAbilityContext.InputContext.PrimaryTarget.ObjectID) != INDEX_NONE) )
			{
				// The Melee Impairing Ability has been found with the same source and target
				// Move that ability's visualization forward to this track
				AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(TestAbilityContext.InputContext.AbilityTemplateName);

				for( j = 0; j < AbilityTemplate.AbilityTargetEffects.Length; ++j )
				{
					AbilityTemplate.AbilityTargetEffects[j].AddX2ActionsForVisualization(Context.AssociatedState, BuildTrack, TestAbilityContext.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[j]));
				}

				TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
				if (TargetVisualizerInterface != none)
				{
					TargetVisualizerInterface.BuildAbilityEffectsVisualization(Context.AssociatedState, BuildTrack);
				}

				//Notify the visualization mgr that the Impairing Ability visualization has occured
				VisualizationMgr.SkipVisualization(TestAbilityContext.AssociatedState.HistoryIndex);
			}
		}
	}
}

defaultproperties
{
	ImpairingAbilityName="ImpairingAbility"
}