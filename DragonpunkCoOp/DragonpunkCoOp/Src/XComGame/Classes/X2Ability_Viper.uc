class X2Ability_Viper extends X2Ability
	config(GameData_SoldierSkills);

var config float POISON_SPIT_CYLINDER_HEIGHT_METERS;
var config float BIND_RANGE;
var config int BIND_FRAGILE_AMOUNT;
var config float GET_OVER_HERE_MIN_RANGE;
var config float GET_OVER_HERE_MAX_RANGE;
var config array<name> BIND_ABILITY_ALIASES;
var config array<name> GET_OVER_HERE_ABILITY_ALIASES;

var name BindSustainedEffectName;
var name GetOverHereAbilityName;
var name BindAbilityName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreatePoisonSpitAbility());
	Templates.AddItem(CreateBindAbility(true, default.BindAbilityName));
	Templates.AddItem(CreateBindSustainedAbility());
	Templates.AddItem(CreateEndBindAbility());
	Templates.AddItem(CreateGetOverHereAbility());

	return Templates;
}

static function X2AbilityTemplate CreatePoisonSpitAbility()
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTarget_Cursor            CursorTarget;
	local X2AbilityMultiTarget_Cylinder     CylinderMultiTarget;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2AbilityCooldown_LocalAndGlobal  Cooldown;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'PoisonSpit');
	Template.bDontDisplayInAbilitySummary = false;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_poisonspit";

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	
	Template.AddMultiTargetEffect(class'X2StatusEffects'.static.CreatePoisonedStatusEffect());
	Template.AddMultiTargetEffect(new class'X2Effect_ApplyPoisonToWorld');

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.bRestrictToWeaponRange = true;
	Template.AbilityTargetStyle = CursorTarget;

	CylinderMultiTarget = new class'X2AbilityMultiTarget_Cylinder';
	CylinderMultiTarget.bUseWeaponRadius = true;
	CylinderMultiTarget.fTargetHeight = default.POISON_SPIT_CYLINDER_HEIGHT_METERS;
	CylinderMultiTarget.bUseOnlyGroundTiles = true;
	Template.AbilityMultiTargetStyle = CylinderMultiTarget;

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition); 
	Template.AddShooterEffectExclusions();

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);
	
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_AlwaysShow;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_viper_poisonspit";
	Template.bUseAmmoAsChargesForHUD = true;

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.CinescriptCameraType = "Viper_PoisonSpit";

	Template.TargetingMethod = class'X2TargetingMethod_ViperSpit';

	// Cooldown on the ability
	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = 4;
	Cooldown.NumGlobalTurns = 1;
	Template.AbilityCooldown = Cooldown;

	// This action is considered 'hostile' and can be interrupted!
	Template.Hostility = eHostility_Offensive;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	return Template;
}

static function X2AbilityTemplate CreateBindAbility(bool Interruptible, name AbilityName, name SustainedAbilityName='BindSustained')
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_UnitEffects           UnitEffectsCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2AbilityCooldown                 Cooldown;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Effect_Persistent			    BoundEffect;
	local X2Effect_ViperBindSustained       SustainedEffect;
	local X2Effect_GrantActionPoints        ActionPointsEffect;
	local X2Effect_ApplyWeaponDamage        PhysicalDamageEffect;
	local X2Effect_ApplyDirectionalWorldDamage EnvironmentDamageEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_viper_bind";

	Template.AbilitySourceName = 'eAbilitySource_Standard';

	if (Interruptible)
	{
		Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	}
	else
	{
		Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
		Template.bDontDisplayInAbilitySummary = true;
	}

	Template.Hostility = eHostility_Offensive;

	Template.AdditionalAbilities.AddItem('BindSustained');
	Template.AdditionalAbilities.AddItem('EndBind');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.GOHBindActionPoint);
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = 1;
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_DeadEye';

	// Source cannot be dead
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);
	Template.AddShooterEffectExclusions();

	// The Target must be alive and a humanoid
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeAlien = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.RequireWithinRange = true;
	UnitPropertyCondition.WithinRange = default.BIND_RANGE;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// This Target cannot already be bound
	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');
	UnitEffectsCondition.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	TargetVisibilityCondition = new class'X2Condition_Visibility';	
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	TargetVisibilityCondition.bCannotPeek = true;
	TargetVisibilityCondition.bRequireNotMatchCoverType = true;
	TargetVisibilityCondition.TargetCover = CT_Standing;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	// Add to the target the sustained bind effect
	SustainedEffect = new class'X2Effect_ViperBindSustained';
	SustainedEffect.SustainedAbilityName = SustainedAbilityName;
	SustainedEffect.FragileAmount = default.BIND_FRAGILE_AMOUNT;
	SustainedEffect.EffectName = default.BindSustainedEffectName;
	SustainedEffect.bRemoveWhenTargetDies = true;
	SustainedEffect.EffectRemovedSourceVisualizationFn = BindEndSource_BuildVisualization;
	SustainedEffect.EffectRemovedVisualizationFn = BindEndTarget_BuildVisualization;
	SustainedEffect.BuildPersistentEffect(1, true, true, false, eGameRule_PlayerTurnBegin);
	SustainedEffect.RegisterAdditionalEventsLikeImpair.AddItem('AffectedByStasis');
	SustainedEffect.bBringRemoveVisualizationForward = true;

	// Since this will also be a sustained ability, only put the bound status on the target
	// for one round
	BoundEffect = class'X2StatusEffects'.static.CreateBoundStatusEffect(1, true, true);
	BoundEffect.CustomIdleOverrideAnim = 'NO_BindLoop';
	Template.AddTargetEffect(BoundEffect);
	// This target effect needs to be set as a child on the sustain effect
	SustainedEffect.EffectsToRemoveFromTarget.AddItem(BoundEffect.EffectName);

	// The shooter is also bound
	BoundEffect = class'X2StatusEffects'.static.CreateBoundStatusEffect(1, true, false);
	BoundEffect.CustomIdleOverrideAnim = 'NO_BindLoop';
	Template.AddShooterEffect(BoundEffect);
	// This source effect needs to be set as a child on the sustain effect
	SustainedEffect.EffectsToRemoveFromSource.AddItem(BoundEffect.EffectName);

	// All child effects to the sustained effect have been added, submit
	Template.AddTargetEffect(SustainedEffect);

	// The shooter gets a free point that can be used to end the bind
	ActionPointsEffect = new class'X2Effect_GrantActionPoints';
	ActionPointsEffect.NumActionPoints = 1;
	ActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.EndBindActionPoint;
	Template.AddShooterEffect(ActionPointsEffect);

	// Ability causes damage by crushing
	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.Viper_Bind_BaseDamage;
	PhysicalDamageEffect.DamageTypes.AddItem('ViperCrush');
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	Template.AddTargetEffect(PhysicalDamageEffect);

	EnvironmentDamageEffect = new class 'X2Effect_ApplyDirectionalWorldDamage';
	EnvironmentDamageEffect.DamageTypeTemplateName = 'Melee';
	EnvironmentDamageEffect.EnvironmentalDamageAmount = 30;
	EnvironmentDamageEffect.PlusNumZTiles = 1;
	EnvironmentDamageEffect.bApplyToWorldOnMiss = false;
	EnvironmentDamageEffect.bHitSourceTile = true;
	EnvironmentDamageEffect.bAllowDestructionOfDamageCauseCover=true;
	Template.AddTargetEffect(EnvironmentDamageEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Bind_BuildVisualization;
	Template.BuildAffectedVisualizationSyncFn = BindUnit_BuildAffectedVisualization;
	Template.CinescriptCameraType = "Viper_Bind";

	// This action is considered 'hostile' and can be interrupted!
	if (Interruptible)
	{
		Template.Hostility = eHostility_Offensive;
		Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	}

	return Template;
}

simulated function Bind_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate				AbilityTemplate;
	local StateObjectReference          InteractingUnitRef;
	local X2Action_PlaySoundAndFlyOver  FlyOver;

	local VisualizationTrack			EmptyTrack;
	local VisualizationTrack			BuildTrack;

	local int                           EffectIndex;
	local int							SearchHistoryIndex;

	local XComGameStateContext			TestContext;
	local XComGameStateContext_TacticalGameRule TestGameRuleContext;
	local XComGameStateContext_Ability  GetOverHereAbilityContext;
	local bool                          bGetOverHereWasHit;
	local bool                          bDisplayAnimations;
	local X2VisualizerInterface         TargetVisualizerInterface;
	local bool                          bIsContextHit;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	if( Context.InterruptionStatus == eInterruptionStatus_Interrupt )
	{
		// Only visualize InterruptionStatus eInterruptionStatus_None or eInterruptionStatus_Resume,
		// if eInterruptionStatus_Interrupt then the Viper was killed (or removed)
		return;
	}

	bIsContextHit = Context.IsResultContextHit();   // If this missed, there is no need to display animations

	bDisplayAnimations = Context.IsResultContextHit();

	// If this missed, there is no need to display animations
	if( bDisplayAnimations &&
		Context.InterruptionStatus == eInterruptionStatus_None )
	{
		// Look backwards for a turn begin, Bind, or GetOverHere
		for( SearchHistoryIndex = VisualizeGameState.HistoryIndex - 1; SearchHistoryIndex >= 0; --SearchHistoryIndex )
		{
			TestContext = History.GetGameStateFromHistory(SearchHistoryIndex).GetContext();
			TestGameRuleContext = XComGameStateContext_TacticalGameRule(TestContext);
			if( (TestGameRuleContext != none) && ( TestGameRuleContext.GameRuleType == eGameRule_PlayerTurnBegin ) )
			{
				// Found a begin turn, so no need to keep lookig for GetOverHere
				break;
			}

			GetOverHereAbilityContext = XComGameStateContext_Ability(TestContext);
			bGetOverHereWasHit = GetOverHereAbilityContext != none && class'XComGameStateContext_Ability'.static.IsHitResultHit(GetOverHereAbilityContext.ResultContext.HitResult);

			if( bGetOverHereWasHit &&
				default.BIND_ABILITY_ALIASES.Find(GetOverHereAbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE &&
				GetOverHereAbilityContext.InputContext.SourceObject.ObjectID == Context.InputContext.SourceObject.ObjectID )
			{
				// A Bind with the same source was found, so this can't be a Bind due to GetOverHere
				break;
			}
			else if( bGetOverHereWasHit &&
					 default.GET_OVER_HERE_ABILITY_ALIASES.Find(GetOverHereAbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE &&
					 GetOverHereAbilityContext.InputContext.SourceObject.ObjectID == Context.InputContext.SourceObject.ObjectID )
			{
				// An associated GetOverHere Ability was found, so we won't need to show the animations
				bDisplayAnimations = false;
				break;
			}
		}
	}

	//Configure the visualization track for the shooter
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.SourceObject;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	if( bDisplayAnimations && bIsContextHit )
	{
		BindSourceAnimationVisualization(BuildTrack, Context);
	}
	
	if( !bIsContextHit && (AbilityTemplate.LocMissMessage != "") )
	{
		FlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
		FlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocMissMessage, '', eColor_Bad);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	if( bIsContextHit )
	{
		InteractingUnitRef = Context.InputContext.PrimaryTarget;
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		if( bDisplayAnimations )
		{
			BindTargetAnimationVisualization(BuildTrack, Context);
		}

		for(EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
		}

		TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************

	//****************************************************************************************
	//Configure the visualization tracks for the environment
	//****************************************************************************************

	if( bIsContextHit && bDisplayAnimations )
	{
		BindEnvironmentDamageVisualization(Context, Context, AbilityTemplate, OutVisualizationTracks);
	}
}

static simulated function BindSourceAnimationVisualization(out VisualizationTrack BuildTrack, XComGameStateContext Context, bool bSyncAction = false)
{
	local X2Action_PersistentEffect		PersistentEffectAction;

	class'X2Action_ViperBind'.static.AddToVisualizationTrack(BuildTrack, Context);

	PersistentEffectAction = X2Action_PersistentEffect(class'X2Action_PersistentEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
	PersistentEffectAction.IdleAnimName = 'NO_BindLoop';
}

static simulated function BindTargetAnimationVisualization(out VisualizationTrack BuildTrack, XComGameStateContext Context)
{
	local X2Action_PersistentEffect		PersistentEffectAction;
	local X2Action_WaitForAbilityEffect WaitAction;

	WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
	WaitAction.bWaitingForActionMessage = true;

	PersistentEffectAction = X2Action_PersistentEffect(class'X2Action_PersistentEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
	PersistentEffectAction.IdleAnimName = 'NO_BindLoop';
}

static simulated function BindEnvironmentDamageVisualization(XComGameStateContext Context, XComGameStateContext_Ability BindContext, X2AbilityTemplate AbilityTemplate, 
													  out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local int EffectIndex;
	local XComGameState VisualizeGameState;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;

	VisualizeGameState = BindContext.AssociatedState;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.TrackActor = none;
		BuildTrack.StateObject_NewState = EnvironmentDamageEvent;
		BuildTrack.StateObject_OldState = EnvironmentDamageEvent;

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

		for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex )
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}
}

static function X2AbilityTemplate CreateBindSustainedAbility(name AbilityName='BindSustained')
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityTrigger_SustainedEffect  InputTrigger;
	local X2Condition_UnitEffectsWithAbilitySource UnitEffectsCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Effect_GrantActionPoints        ActionPointsEffect;
	local X2Effect_ApplyWeaponDamage        PhysicalDamageEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, AbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_viper_bind";

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Offensive;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	// This ability is only valid if this unit is currently binding the target
	UnitEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	UnitEffectsCondition.AddRequireEffect(default.BindSustainedEffectName, 'AA_UnitIsBound');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	// May only target a single unit
	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	InputTrigger = new class'X2AbilityTrigger_SustainedEffect';
	Template.AbilityTriggers.AddItem(InputTrigger);

	// While sustained this ability causes damage by crushing
	PhysicalDamageEffect = new class'X2Effect_ApplyWeaponDamage';
	PhysicalDamageEffect.EffectDamageValue = class'X2Item_DefaultWeapons'.default.Viper_Bind_BaseDamage;
	PhysicalDamageEffect.DamageTypes.AddItem('ViperCrush');
	PhysicalDamageEffect.EffectDamageValue.DamageType = 'Melee';
	Template.AddTargetEffect(PhysicalDamageEffect);

	// The shooter gets a free point that can be used to end the bind
	ActionPointsEffect = new class'X2Effect_GrantActionPoints';
	ActionPointsEffect.NumActionPoints = 1;
	ActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.EndBindActionPoint;
	Template.AddShooterEffect(ActionPointsEffect);

	Template.bSkipFireAction = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = BindSustained_BuildVisualization;

	return Template;
}

simulated function BindSustained_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;
	local bool                          bTargetIsDead;
	local int                           i;
	local X2Action_SendInterTrackMessage SendMessageAction;
	

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//Configure the visualization track for the target
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	bTargetIsDead = XComGameState_Unit(BuildTrack.StateObject_NewState).IsDead() ||
					XComGameState_Unit(BuildTrack.StateObject_NewState).bBleedingOut;

	if( bTargetIsDead )
	{
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);
	}

	for( i = 0; i < Context.ResultContext.TargetEffectResults.Effects.Length; ++i )
	{
		Context.ResultContext.TargetEffectResults.Effects[i].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.ResultContext.TargetEffectResults.ApplyResults[i]);
	}

	if( bTargetIsDead )
	{
		class'X2Action_Death'.static.AddToVisualizationTrack(BuildTrack, Context);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************

	//Configure the visualization track for the shooter
	//****************************************************************************************
	if( bTargetIsDead )
	{
		BuildTrack = EmptyTrack;
		InteractingUnitRef = Context.InputContext.SourceObject;
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);

		// Send an intertrack message letting the target know it can now die
		SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
		SendMessageAction.SendTrackMessageToRef = Context.InputContext.PrimaryTarget;

		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************
}

static function X2AbilityTemplate CreateEndBindAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitEffectsWithAbilitySource UnitEffectsCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2AbilityTarget_Single            SingleTarget;
	local X2Effect_RemoveEffects            RemoveEffects;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'EndBind');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_viper_bind";

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;
	Template.Hostility = eHostility_Offensive;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.AllowedTypes.Length = 0;        //  clear default allowances
	ActionPointCost.AllowedTypes.AddItem(class'X2CharacterTemplateManager'.default.EndBindActionPoint);
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	// This ability is only valid if this unit is currently binding the target
	UnitEffectsCondition = new class'X2Condition_UnitEffectsWithAbilitySource';
	UnitEffectsCondition.AddRequireEffect(default.BindSustainedEffectName, 'AA_UnitIsBound');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	// Remove the bind/bound effects from the Target
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.BindSustainedEffectName);
	Template.AddTargetEffect(RemoveEffects);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = BindEnd_BuildVisualization;

	return Template;
}

simulated function BindEndSource_BuildVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{
	local XComGameStateHistory			History;
	local XComGameState_Effect          BindSustainedEffectState;
	local XComGameState_Unit            OldUnitState, BindTarget;
	local X2Action_ViperBindEnd         BindEnd;
	local XComGameStateContext			Context;

	History = `XCOMHISTORY;

	if (BuildTrack.TrackActor != None)
	{
		Context = VisualizeGameState.GetContext( );

		OldUnitState = XComGameState_Unit(BuildTrack.StateObject_OldState);
		BindSustainedEffectState = OldUnitState.GetUnitApplyingEffectState(class'X2Ability_Viper'.default.BindSustainedEffectName);
		`assert(BindSustainedEffectState != none);
		BindTarget = XComGameState_Unit(History.GetGameStateForObjectID(BindSustainedEffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		`assert(BindTarget != none);

		if( BindTarget.IsDead() ||
			BindTarget.IsBleedingOut() ||
			BindTarget.IsUnconscious() )
		{
			// The target is dead, wait for it to die and inform the source
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);
		}
		else
		{

			BindEnd = X2Action_ViperBindEnd(class'X2Action_ViperBindEnd'.static.AddToVisualizationTrack(BuildTrack, Context));
			BindEnd.PartnerUnitRef = BindSustainedEffectState.ApplyEffectParameters.TargetStateObjectRef;
		}
	}
}

simulated function BindEndTarget_BuildVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult)
{	
	local XComGameState_Effect          BindSustainedEffectState;
	local XComGameState_Unit            OldUnitState;
	local X2Action_ViperBindEnd         BindEnd;
	local XComGameStateContext			Context;
	local X2Action_WaitForAbilityEffect WaitAction;

	if(BuildTrack.TrackActor != None)
	{
		Context = VisualizeGameState.GetContext();

		if( XComGameState_Unit(BuildTrack.StateObject_NewState).IsDead() ||
		   XComGameState_Unit(BuildTrack.StateObject_NewState).IsBleedingOut() ||
		   XComGameState_Unit(BuildTrack.StateObject_NewState).IsUnconscious() )
		{
			OldUnitState = XComGameState_Unit(BuildTrack.StateObject_OldState);
			BindSustainedEffectState = OldUnitState.GetUnitAffectedByEffectState(class'X2Ability_Viper'.default.BindSustainedEffectName);
			`assert(BindSustainedEffectState != none);

			BindEnd = X2Action_ViperBindEnd(class'X2Action_ViperBindEnd'.static.AddToVisualizationTrack(BuildTrack, Context));
			BindEnd.PartnerUnitRef = BindSustainedEffectState.ApplyEffectParameters.SourceStateObjectRef;
		}
		else
		{
			WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
			WaitAction.bWaitingForActionMessage = true;
		}
	}
}

simulated function BindEnd_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;
	

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	InteractingUnitRef = Context.InputContext.SourceObject;
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);

	BindEndSource_BuildVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	BindEndTarget_BuildVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************
}

static function X2AbilityTemplate CreateGetOverHereAbility()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_UnitEffects           UnitEffectsCondition;
	local X2AbilityTrigger_PlayerInput      InputTrigger;
	local X2AbilityCooldown_LocalAndGlobal  Cooldown;
	local X2Condition_Visibility            TargetVisibilityCondition;
	local X2Condition_UnblockedNeighborTile UnblockedNeighborTileCondition;
	local X2AbilityTarget_Single            SingleTarget;
	local X2AbilityToHitCalc_StandardAim    StandardAim;
	local X2Effect_GetOverHere              GetOverHereEffect;
	local X2Effect_ImmediateAbilityActivation BindAbilityEffect;
	local X2Effect_GrantActionPoints        ActionPointsEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.GetOverHereAbilityName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_viper_getoverhere";

	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Offensive;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	//ActionPointCost.iNumPoints = 2;  //BMU changing to be only one action point
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	//ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = 1;
	Cooldown.NumGlobalTurns = 1;
	Template.AbilityCooldown = Cooldown;

	// Source cannot be dead
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	Template.AbilityShooterConditions.AddItem(UnitPropertyCondition);
	Template.AddShooterEffectExclusions();

	// There must be a free tile around the source unit
	UnblockedNeighborTileCondition = new class'X2Condition_UnblockedNeighborTile';
	template.AbilityShooterConditions.AddItem(UnblockedNeighborTileCondition);

	// The Target must be alive and a humanoid
	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeAlien = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = true;
	UnitPropertyCondition.RequireWithinMinRange = true;
	UnitPropertyCondition.WithinMinRange = default.GET_OVER_HERE_MIN_RANGE;
	UnitPropertyCondition.RequireWithinRange = true;
	UnitPropertyCondition.WithinRange = default.GET_OVER_HERE_MAX_RANGE;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	// This Target cannot already be bound
	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');
	UnitEffectsCondition.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);

	// Target must be visible and not in high cover
	TargetVisibilityCondition = new class'X2Condition_Visibility';
	TargetVisibilityCondition.bRequireGameplayVisible = true;
	Template.AbilityTargetConditions.AddItem(TargetVisibilityCondition);

	SingleTarget = new class'X2AbilityTarget_Single';
	Template.AbilityTargetStyle = SingleTarget;

	InputTrigger = new class'X2AbilityTrigger_PlayerInput';
	Template.AbilityTriggers.AddItem(InputTrigger);

	// This will attack using the standard aim
	StandardAim = new class'X2AbilityToHitCalc_StandardAim';
	Template.AbilityToHitCalc = StandardAim;

	// Apply the effect that pulls the unit to the Viper
	GetOverHereEffect = new class'X2Effect_GetOverHere';
	Template.AddTargetEffect(GetOverHereEffect);

	// Successful GetOverHere leads to a bind
	BindAbilityEffect = new class 'X2Effect_ImmediateAbilityActivation';
	BindAbilityEffect.BuildPersistentEffect(1, false, true, , eGameRule_PlayerTurnBegin);
	BindAbilityEffect.EffectName = 'ImmediateBind';
	BindAbilityEffect.AbilityName = default.BindAbilityName;
	BindAbilityEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddTargetEffect(BindAbilityEffect);

	// The shooter gets a free point that can be used bind
	ActionPointsEffect = new class'X2Effect_GrantActionPoints';
	ActionPointsEffect.NumActionPoints = 1;
	ActionPointsEffect.PointType = class'X2CharacterTemplateManager'.default.GOHBindActionPoint;
	Template.AddShooterEffect(ActionPointsEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = GetOverhere_BuildVisualization;
	Template.CinescriptCameraType = "Viper_StranglePull";

	// This action is considered 'hostile' and can be interrupted!
	Template.Hostility = eHostility_Offensive;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	return Template;
}

static simulated function GetOverhere_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate, BindAbilityTemplate;
	local StateObjectReference          InteractingUnitRef;
	local X2Action_ViperGetOverHere		GetOverHereAction;
	local X2Action_PlaySoundAndFlyOver	SoundAndFlyover;
	local X2VisualizerInterface			Visualizer;
	local XComGameState_Unit            TargetUnit;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;

	local int							EffectIndex;

	//Support for finding and visualizing a bind attack that is part of the grab attack
	local int							SearchHistoryIndex;
	local XComGameState					ApplyBindState;
	local XComGameStateContext_Ability	BindAbilityContext;
	local bool							bGrabWasHit;
	local bool							bBindWasHit;
	local bool                          bDoBindVisuals;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	bGrabWasHit = class'XComGameStateContext_Ability'.static.IsHitResultHit(Context.ResultContext.HitResult);
	
	//If we hit the target, then there should be a game state where we apply our free bind attack to the target. Collect visualization track actions
	//for this bind attack so we can sequence them into the grab + pull visualization
	bBindWasHit = false;
	bDoBindVisuals = false;
	if( bGrabWasHit )
	{	
		//Search forward in the history for the bind that we are going to apply to the target
		for( SearchHistoryIndex = VisualizeGameState.HistoryIndex + 1; SearchHistoryIndex < History.GetNumGameStates(); ++SearchHistoryIndex )
		{
			ApplyBindState = History.GetGameStateFromHistory(SearchHistoryIndex);
			BindAbilityContext = XComGameStateContext_Ability(ApplyBindState.GetContext());
			bBindWasHit = BindAbilityContext != none &&
						  class'XComGameStateContext_Ability'.static.IsHitResultHit(BindAbilityContext.ResultContext.HitResult) &&
						  default.BIND_ABILITY_ALIASES.Find(BindAbilityContext.InputContext.AbilityTemplateName) != INDEX_NONE &&
						  BindAbilityContext.InputContext.SourceObject.ObjectID == Context.InputContext.SourceObject.ObjectID;
				
			if( bBindWasHit )
			{
				bDoBindVisuals = BindAbilityContext.InterruptionStatus == eInterruptionStatus_None;
				BindAbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(BindAbilityContext.InputContext.AbilityTemplateName);
				break;
			}
		}
	}

	//Configure the visualization track for the shooter
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.SourceObject;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	class'X2Action_ExitCover'.static.AddToVisualizationTrack(BuildTrack, Context);
	GetOverHereAction = X2Action_ViperGetOverHere(class'X2Action_ViperGetOverHere'.static.AddToVisualizationTrack(BuildTrack, Context));
	GetOverHereAction.SetFireParameters(Context.IsResultContextHit());

	//Add any actions that we get from our free bind attack if we hit and the Bind was not interrupted
	if( bDoBindVisuals )
	{
		BindSourceAnimationVisualization(BuildTrack, BindAbilityContext);
	}

	Visualizer = X2VisualizerInterface(BuildTrack.TrackActor);
	if(Visualizer != none)
	{
		Visualizer.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);				
	}

	//Don't perform an enter cover if we hit with bind, we need to stay in the bind position
	if(!bBindWasHit)
	{
		class'X2Action_EnterCover'.static.AddToVisualizationTrack(BuildTrack, Context);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	TargetUnit = XComGameState_Unit(BuildTrack.StateObject_OldState);
	if( (TargetUnit != none) && (TargetUnit.IsUnitApplyingEffectName('Suppression')))
	{
		class'X2Action_StopSuppression'.static.AddToVisualizationTrack(BuildTrack, Context);
	}

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
	}

	if (Context.IsResultContextMiss() && AbilityTemplate.LocMissMessage != "")
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocMissMessage, '', eColor_Bad);
	}

	//Add any actions that we get from our free bind attack if we hit and the Bind was not interrupted
	if( bDoBindVisuals )
	{
		BindTargetAnimationVisualization(BuildTrack, BindAbilityContext);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************

	//Configure the visualization tracks for the environment
	//****************************************************************************************
	if( bDoBindVisuals )
	{
		BindEnvironmentDamageVisualization(Context, BindAbilityContext, BindAbilityTemplate, OutVisualizationTracks);
	}
	//****************************************************************************************
}

static simulated function BindUnit_BuildAffectedVisualization(name EffectName, XComGameState VisualizeGameState, out VisualizationTrack BuildTrack )
{
	local XComGameState_Unit NewGameState;
	local XComGameState_Effect BindEffectState;

	if( EffectName == class'X2AbilityTemplateManager'.default.BoundName )
	{
		NewGameState = XComGameState_Unit(BuildTrack.StateObject_NewState);
		BindEffectState = NewGameState.GetUnitAffectedByEffectState(EffectName);

		if( BindEffectState.ApplyEffectParameters.SourceStateObjectRef == NewGameState.GetReference() )
		{
			BindSourceAnimationVisualization(BuildTrack, VisualizeGameState.GetContext(), true);
		}
		else
		{
			BindTargetAnimationVisualization(BuildTrack, VisualizeGameState.GetContext());
		}
	}
}

DefaultProperties
{
	BindSustainedEffectName="BindSustainedEffect"	
	GetOverHereAbilityName="GetOverHere"
	BindAbilityName="Bind"
}