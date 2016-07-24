//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_Archon extends X2Ability
	config(GameData_SoldierSkills);

// --------------- Variable Declarations --------------------------------------
var config int FRENZY_ACTIVATE_PERCENT_CHANCE;
var config float FRENZY_ARMOR_CHANCE;
var config int FRENZY_ARMOR_MITIGATION;
var config int FRENZY_TURNS_DURATION;
var config int BLAZING_PINIONS_LOCAL_COOLDOWN;
var config int BLAZING_PINIONS_GLOBAL_COOLDOWN;
var config int BLAZING_PINIONS_TARGETING_AREA_RADIUS;
var config int BLAZING_PINIONS_SELECTION_RANGE;
var config int BLAZING_PINIONS_NUM_TARGETS;
var config float BLAZING_PINIONS_IMPACT_RADIUS_METERS;
var config int BLAZING_PINIONS_ENVIRONMENT_DAMAGE_AMOUNT;

var config int BLAZING_PINIONSMP_LOCAL_COOLDOWN;

var name BlazingPinionsStage1EffectName;

var privatewrite name BlazingPinionsStage2AbilityName;
var privatewrite name BlazingPinionsStage2TriggerName;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateFrenzyTriggerAbility());
	Templates.AddItem(CreateFrenzyDamageListenerAbility());
	Templates.AddItem(CreateBlazingPinionsStage1Ability());
	Templates.AddItem(CreateBlazingPinionsStage2Ability());
	Templates.AddItem(PurePassive('FrenzyInfo', "img:///UILibrary_PerkIcons.UIPerk_archon_beserk"));

	// MP Versions of Abilities
	Templates.AddItem(CreateBlazingPinionsStage1MPAbility());
	
	return Templates;
}

static function X2AbilityTemplate CreateFrenzyDamageListenerAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener EventListener;
	local X2Condition_UnitEffects ExcludeEffects;
	local X2Condition_UnitProperty UnitProperty;
	local X2Effect_RunBehaviorTree FrenzyBehaviorEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FrenzyDamageListener');
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeUnrevealedAI = true;
	Template.AbilityShooterConditions.AddItem(UnitProperty);

	Template.bDontDisplayInAbilitySummary = true;

	Template.AdditionalAbilities.AddItem('FrenzyInfo');
	Template.AdditionalAbilities.AddItem('FrenzyTrigger');

	// Frenzy may trigger if the unit is burning
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// This ability fires when the unit takes damage
	EventListener = new class'X2AbilityTrigger_EventListener';
	EventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	EventListener.ListenerData.EventID = 'UnitTakeEffectDamage';
	EventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	EventListener.ListenerData.Filter = eFilter_Unit;
	Template.AbilityTriggers.AddItem(EventListener);

	// The shooter must not have Frenzy activated
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Effect_Frenzy'.default.EffectName, 'AA_UnitIsFrenzied');
	Template.AbilityShooterConditions.AddItem(ExcludeEffects);

	Template.AbilityTargetStyle = default.SelfTarget;

	FrenzyBehaviorEffect = new class'X2Effect_RunBehaviorTree';
	FrenzyBehaviorEffect.BehaviorTreeName = 'TryFrenzyTrigger';
	Template.AddTargetEffect(FrenzyBehaviorEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}

static function X2AbilityTemplate CreateFrenzyTriggerAbility()
{
	local X2AbilityTemplate Template;
	local X2Condition_UnitEffects ExcludeEffects;
	local X2Condition_UnitProperty UnitProperty;
	local X2Effect_Frenzy FrenzyEffect;
	local array<name> SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'FrenzyTrigger');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_beserk"; // TODO: This needs to be changed
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Defensive;

	Template.bDontDisplayInAbilitySummary = true;

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeUnrevealedAI = true;
	Template.AbilityShooterConditions.AddItem(UnitProperty);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	// Frenzy may trigger if the unit is burning
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	// The shooter must not have Frenzy activated
	ExcludeEffects = new class'X2Condition_UnitEffects';
	ExcludeEffects.AddExcludeEffect(class'X2Effect_Frenzy'.default.EffectName, 'AA_UnitIsFrenzied');
	Template.AbilityShooterConditions.AddItem(ExcludeEffects);

	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	FrenzyEffect = new class'X2Effect_Frenzy';
	FrenzyEffect.BuildPersistentEffect(default.FRENZY_TURNS_DURATION, false, true, , eGameRule_PlayerTurnEnd);
	FrenzyEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true);
	FrenzyEffect.AddPersistentStatChange(eStat_ArmorChance, default.FRENZY_ARMOR_CHANCE);
	FrenzyEffect.AddPersistentStatChange(eStat_ArmorMitigation, default.FRENZY_ARMOR_MITIGATION);
	FrenzyEffect.DuplicateResponse = eDupe_Ignore;
	FrenzyEffect.EffectHierarchyValue = class'X2StatusEffects'.default.FRENZY_HIERARCHY_VALUE;
	FrenzyEffect.ApplyChance = default.FRENZY_ACTIVATE_PERCENT_CHANCE;
	Template.AddTargetEffect(FrenzyEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.bSkipFireAction = true;
	Template.BuildVisualizationFn = Frenzy_BuildVisualization;
	Template.CinescriptCameraType = "Archon_Frenzy";

	return Template;
}

simulated function Frenzy_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local int EffectIndex;
	local X2Action_PlayAnimation PlayAnimation;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());

	if( Context.IsResultContextHit() )
	{
		InteractingUnitRef = Context.InputContext.SourceObject;

		AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

		//****************************************************************************************
		//Configure the visualization track for the target
		//****************************************************************************************
		InteractingUnitRef = Context.InputContext.PrimaryTarget;
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, Context));
		PlayAnimation.Params.AnimName = 'NO_Berserk';
		PlayAnimation.bFinishAnimationWait = false;

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult(AbilityTemplate.AbilityTargetEffects[EffectIndex]));
		}

		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good);

		OutVisualizationTracks.AddItem(BuildTrack);
		//****************************************************************************************
	}
}

static function X2DataTemplate CreateBlazingPinionsStage1Ability()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2AbilityMultiTarget_BlazingPinions BlazingPinionsMultiTarget;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2Condition_UnitProperty UnitProperty;
	local X2Effect_DelayedAbilityActivation BlazingPinionsStage1DelayEffect;
	local X2Effect_Persistent BlazingPinionsStage1Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BlazingPinionsStage1');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.bShowActivation = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.TwoTurnAttackAbility = default.BlazingPinionsStage2AbilityName;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.BLAZING_PINIONS_LOCAL_COOLDOWN;
	Cooldown.NumGlobalTurns = default.BLAZING_PINIONS_GLOBAL_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeDead = true;
	UnitProperty.HasClearanceToMaxZ = true;
	Template.AbilityShooterConditions.AddItem(UnitProperty);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
 
	Template.TargetingMethod = class'X2TargetingMethod_BlazingPinions';

	// The target locations are enemies
	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeFriendlyToSource = true;
	UnitProperty.ExcludeCivilian = true;
	UnitProperty.ExcludeDead = true;
	UnitProperty.HasClearanceToMaxZ = true;
	UnitProperty.FailOnNonUnits = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitProperty);

	BlazingPinionsMultiTarget = new class'X2AbilityMultiTarget_BlazingPinions';
	BlazingPinionsMultiTarget.fTargetRadius = default.BLAZING_PINIONS_TARGETING_AREA_RADIUS;
	BlazingPinionsMultiTarget.NumTargetsRequired = default.BLAZING_PINIONS_NUM_TARGETS;
	Template.AbilityMultiTargetStyle = BlazingPinionsMultiTarget;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = default.BLAZING_PINIONS_SELECTION_RANGE;
	Template.AbilityTargetStyle = CursorTarget;

	//Delayed Effect to cause the second Blazing Pinions stage to occur
	BlazingPinionsStage1DelayEffect = new class 'X2Effect_DelayedAbilityActivation';
	BlazingPinionsStage1DelayEffect.BuildPersistentEffect(1, false, false, , eGameRule_PlayerTurnBegin);
	BlazingPinionsStage1DelayEffect.EffectName = 'BlazingPinionsStage1Delay';
	BlazingPinionsStage1DelayEffect.TriggerEventName = default.BlazingPinionsStage2TriggerName;
	BlazingPinionsStage1DelayEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddShooterEffect(BlazingPinionsStage1DelayEffect);

	// An effect to attach Perk FX to
	BlazingPinionsStage1Effect = new class'X2Effect_Persistent';
	BlazingPinionsStage1Effect.BuildPersistentEffect(1, true, false, true);
	BlazingPinionsStage1Effect.EffectName = default.BlazingPinionsStage1EffectName;
	Template.AddShooterEffect(BlazingPinionsStage1Effect);

	//  The target FX goes in target array as there will be no single target hit and no side effects of this touching a unit
	Template.AddShooterEffect(new class'X2Effect_ApplyBlazingPinionsTargetToWorld');

	Template.ModifyNewContextFn = BlazingPinionsStage1_ModifyActivatedAbilityContext;
	Template.BuildNewGameStateFn = BlazingPinionsStage1_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = BlazingPinionsStage1_BuildVisualization;
	Template.BuildAppliedVisualizationSyncFn = BlazingPinionsStage1_BuildVisualizationSync;
	Template.CinescriptCameraType = "Archon_BlazingPinions_Stage1";
	
	return Template;
}

simulated function BlazingPinionsStage1_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateHistory History;
	local vector EndLocation;
	local TTile EndTileLocation;
	local XComWorldData World;
	local PathingInputData InputData;
	local PathingResultData ResultData;

	History = `XCOMHISTORY;
	World = `XWORLD;

	AbilityContext = XComGameStateContext_Ability(Context);
	`assert(AbilityContext.InputContext.TargetLocations.Length > 0);
	
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	// solve the path to get him to the fire location
	EndLocation = AbilityContext.InputContext.TargetLocations[0];
	EndTileLocation = World.GetTileCoordinatesFromPosition(EndLocation);
	EndTileLocation.Z = World.NumZ - 2; // Subtract Magic Number X to make the height visually appealing

	class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, EndTileLocation, InputData.MovementTiles, false);
	
	// get the path points
	class'X2PathSolver'.static.GetPathPointsFromPath(UnitState, InputData.MovementTiles, InputData.MovementData);

	// make the flight path nice and smooth
	class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(UnitState.GetVisualizer()), InputData.MovementData);

	//Now add the path to the input context
	InputData.MovingUnitRef = UnitState.GetReference();
	AbilityContext.InputContext.MovementPaths.AddItem(InputData);

	// Update the result context's PathTileData, without this the AI doesn't know it has been seen and will use the invisible teleport move action
	class'X2TacticalVisibilityHelpers'.static.FillPathTileData(AbilityContext.InputContext.SourceObject.ObjectID, InputData.MovementTiles, ResultData.PathTileData);
	AbilityContext.ResultContext.PathResults.AddItem(ResultData);
}

simulated function XComGameState BlazingPinionsStage1_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local vector NewLocation;
	local TTile NewTileLocation;
	local XComWorldData World;
	local X2EventManager EventManager;
	local int LastPathElement;

	World = `XWORLD;
	EventManager = `XEVENTMGR;

	//Build the new game state frame
	NewGameState = TypicalAbility_BuildGameState(Context);

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());	
	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	
	LastPathElement = AbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1;

	// Move the unit vertically, set the unit's new location
	// The last position in MovementData will be the end location
	`assert(LastPathElement > 0);
	NewLocation = AbilityContext.InputContext.MovementPaths[0].MovementData[LastPathElement].Position;
	NewTileLocation = World.GetTileCoordinatesFromPosition(NewLocation);
	UnitState.SetVisibilityLocation(NewTileLocation);

	NewGameState.AddStateObject(UnitState);

	AbilityContext.ResultContext.bPathCausesDestruction = MoveAbility_StepCausesDestruction(UnitState, AbilityContext.InputContext, 0, LastPathElement);
	MoveAbility_AddTileStateObjects(NewGameState, UnitState, AbilityContext.InputContext, 0, LastPathElement);

	EventManager.TriggerEvent('ObjectMoved', UnitState, UnitState, NewGameState);
	EventManager.TriggerEvent('UnitMoveFinished', UnitState, UnitState, NewGameState);

	//Return the game state we have created
	return NewGameState;
}

simulated function BlazingPinionsStage1_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationTrack EmptyTrack, BuildTrack;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local int i;
	local X2Action_MoveTurn MoveTurnAction;
	local X2Action_PlayAnimation PlayAnimation;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	//****************************************************************************************
	//Configure the visualization track for the source
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good);

	// Turn to face the target action. The target location is the center of the ability's radius, stored in the 0 index of the TargetLocations
	MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	MoveTurnAction.m_vFacePoint = AbilityContext.InputContext.TargetLocations[0];

	// Fly up actions
	class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, BuildTrack, OutVisualizationTracks);

	// Play the animation to get him to his looping idle
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	PlayAnimation.Params.AnimName = 'HL_FlyBlazingPinionsFire';
	
	for( i = 0; i < AbilityContext.ResultContext.ShooterEffectResults.Effects.Length; ++i )
	{
		AbilityContext.ResultContext.ShooterEffectResults.Effects[i].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 
																								  AbilityContext.ResultContext.ShooterEffectResults.ApplyResults[i]);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
}

simulated function BlazingPinionsStage1_BuildVisualizationSync( name EffectName, XComGameState VisualizeGameState, out VisualizationTrack BuildTrack )
{
	local X2Action_MoveTurn MoveTurnAction;
	local XComGameStateContext_Ability  AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local X2Action_PlayAnimation PlayAnimation;
	local X2Action_MoveTeleport MoveTeleport;
	local PathingInputData PathingData;
	local PathingResultData ResultData;
	local vector PathEndPos;
	local int i, LastPathIndex;

	if (!`XENGINE.IsMultiplayerGame() && EffectName == 'BlazingPinionsStage1Delay')
	{
		AbilityContext = XComGameStateContext_Ability( VisualizeGameState.GetContext( ) );
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

		// Turn to face the target action. The target location is the center of the ability's radius, stored in the 0 index of the TargetLocations
		MoveTurnAction = X2Action_MoveTurn( class'X2Action_MoveTurn'.static.AddToVisualizationTrack( BuildTrack, AbilityContext ) );
		MoveTurnAction.m_vFacePoint = AbilityContext.InputContext.TargetLocations[ 0 ];

		// Fly up actions
		PathingData = AbilityContext.InputContext.MovementPaths[0];
		ResultData = AbilityContext.ResultContext.PathResults[0];
		LastPathIndex = PathingData.MovementData.Length - 1;
		PathEndPos = PathingData.MovementData[ LastPathIndex ].Position;
		MoveTeleport = X2Action_MoveTeleport( class'X2Action_MoveTeleport'.static.AddToVisualizationTrack( BuildTrack, ABilityContext ) );
		MoveTeleport.ParsePathSetParameters( LastPathIndex, PathEndPos, 0, PathingData, ResultData );
		MoveTeleport.SnapToGround = false;

		// Play the animation to get him to his looping idle
		PlayAnimation = X2Action_PlayAnimation( class'X2Action_PlayAnimation'.static.AddToVisualizationTrack( BuildTrack, AbilityContext ) );
		PlayAnimation.Params.AnimName = 'HL_FlyBlazingPinionsFire';

		// The references to the shooter effect instances in the input context don't restore to be the references to the ability
		// template that they should.  Which is okay, we'll just use the effects directly.
		for (i = 0; i < AbilityTemplate.AbilityShooterEffects.Length; ++i)
		{
			AbilityTemplate.AbilityShooterEffects[ i ].AddX2ActionsForVisualization( VisualizeGameState, BuildTrack,
				AbilityContext.ResultContext.ShooterEffectResults.ApplyResults[ i ] );
		}
	}
}

static function X2DataTemplate CreateBlazingPinionsStage2Ability()
{
	local X2AbilityTemplate Template;
	local X2AbilityTrigger_EventListener DelayedEventListener;
	local X2Effect_RemoveEffects RemoveEffects;
	local X2Effect_ApplyWeaponDamage DamageEffect;
	local X2AbilityMultiTarget_Radius RadMultiTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, default.BlazingPinionsStage2AbilityName);
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	Template.bDontDisplayInAbilitySummary = true;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;

	// This ability fires when the event DelayedExecuteRemoved fires on this unit
	DelayedEventListener = new class'X2AbilityTrigger_EventListener';
	DelayedEventListener.ListenerData.Deferral = ELD_OnStateSubmitted;
	DelayedEventListener.ListenerData.EventID = default.BlazingPinionsStage2TriggerName;
	DelayedEventListener.ListenerData.Filter = eFilter_Unit;
	DelayedEventListener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_BlazingPinions;
	Template.AbilityTriggers.AddItem(DelayedEventListener);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(default.BlazingPinionsStage1EffectName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2Effect_ApplyBlazingPinionsTargetToWorld'.default.EffectName);
	Template.AddShooterEffect(RemoveEffects);

	RadMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadMultiTarget.fTargetRadius = default.BLAZING_PINIONS_IMPACT_RADIUS_METERS;

	Template.AbilityMultiTargetStyle = RadMultiTarget;

	// The MultiTarget Units are dealt this damage
	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bApplyWorldEffectsForEachTargetLocation = true;
	Template.AddMultiTargetEffect(DamageEffect);

	Template.ModifyNewContextFn = BlazingPinionsStage2_ModifyActivatedAbilityContext;
	Template.BuildNewGameStateFn = BlazingPinionsStage2_BuildGameState;
	Template.BuildVisualizationFn = BlazingPinionsStage2_BuildVisualization;
	Template.CinescriptCameraType = "Archon_BlazingPinions_Stage2";

	return Template;
}

simulated function BlazingPinionsStage2_ModifyActivatedAbilityContext(XComGameStateContext Context)
{
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameStateHistory History;
	local TTile SelectedTile, LandingTile;
	local XComWorldData World;
	local vector TargetLocation, LandingLocation;
	local array<vector> FloorPoints;
	local int i;
	local X2AbilityMultiTargetStyle RadiusMultiTarget;
	local XComGameState_Ability AbilityState;
	local AvailableTarget MultiTargets;
	local PathingInputData InputData;

	History = `XCOMHISTORY;
	World = `XWORLD;

	AbilityContext = XComGameStateContext_Ability(Context);
	
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	// Find a valid landing location
	TargetLocation = World.GetPositionFromTileCoordinates(UnitState.TileLocation);

	LandingLocation = TargetLocation;
	LandingLocation.Z = World.GetFloorZForPosition(TargetLocation, true);
	LandingTile = World.GetTileCoordinatesFromPosition(LandingLocation);
	LandingTile = class'Helpers'.static.GetClosestValidTile(LandingTile);

	if( !World.CanUnitsEnterTile(LandingTile) )
	{
		// The selected tile is no longer valid. A new landing position
		// must be found. TODO: Decide what to do when FoundFloorPositions is false.
		World.GetFloorTilePositions(TargetLocation, World.WORLD_StepSize * default.BLAZING_PINIONS_TARGETING_AREA_RADIUS, World.WORLD_StepSize, FloorPoints, true);

		i = 0;
		while( i < FloorPoints.Length )
		{
			LandingLocation = FloorPoints[i];
			LandingTile = World.GetTileCoordinatesFromPosition(LandingLocation);
			if( World.CanUnitsEnterTile(SelectedTile) )
			{
				// Found a valid landing location
				i = FloorPoints.Length;
			}

			++i;
		}
	}

	//Attempting to build a path to our current location causes a problem, so avoid that
	if(UnitState.TileLocation != LandingTile) 
	{
		// Build the MovementData for the path
		// solve the path to get him to the end location
		class'X2PathSolver'.static.BuildPath(UnitState, UnitState.TileLocation, LandingTile, InputData.MovementTiles, false);

		// get the path points
		class'X2PathSolver'.static.GetPathPointsFromPath(UnitState, InputData.MovementTiles, InputData.MovementData);

		// string pull the path to smooth it out
		class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(UnitState.GetVisualizer()), InputData.MovementData);

		//Now add the path to the input context
		InputData.MovingUnitRef = UnitState.GetReference();
		AbilityContext.InputContext.MovementPaths.AddItem(InputData);
	}

	// Build the MultiTarget array based upon the impact points
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID, eReturnType_Reference));
	RadiusMultiTarget = AbilityState.GetMyTemplate().AbilityMultiTargetStyle;// new class'X2AbilityMultiTarget_Radius';

	AbilityContext.ResultContext.ProjectileHitLocations.Length = 0;
	for( i = 0; i < AbilityContext.InputContext.TargetLocations.Length; ++i )
	{
		RadiusMultiTarget.GetMultiTargetsForLocation(AbilityState, AbilityContext.InputContext.TargetLocations[i], MultiTargets);

		// Add the TargetLocations as ProjectileHitLocations
		AbilityContext.ResultContext.ProjectileHitLocations.AddItem(AbilityContext.InputContext.TargetLocations[i]);
	}

	AbilityContext.InputContext.MultiTargets = MultiTargets.AdditionalTargets;
}

simulated function XComGameState BlazingPinionsStage2_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;	
	local XComGameStateContext_Ability AbilityContext;
	local TTile LandingTile;
	local XComWorldData World;
	local X2EventManager EventManager;
	local vector LandingLocation;
	local int LastPathElement;

	World = `XWORLD;
	EventManager = `XEVENTMGR;

	//Build the new game state frame
	NewGameState = TypicalAbility_BuildGameState(Context);

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());	
	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	
	if(AbilityContext.InputContext.MovementPaths.Length > 0)
	{
		LastPathElement = AbilityContext.InputContext.MovementPaths[0].MovementData.Length - 1;

		// Move the unit vertically, set the unit's new location
		// The last position in MovementData will be the end location
		`assert(LastPathElement > 0);
		LandingLocation = AbilityContext.InputContext.MovementPaths[0].MovementData[LastPathElement /*- 1*/].Position;
		LandingTile = World.GetTileCoordinatesFromPosition(LandingLocation);
		UnitState.SetVisibilityLocation(LandingTile);

		AbilityContext.ResultContext.bPathCausesDestruction = MoveAbility_StepCausesDestruction(UnitState, AbilityContext.InputContext, 0, AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1);
		MoveAbility_AddTileStateObjects(NewGameState, UnitState, AbilityContext.InputContext, 0, AbilityContext.InputContext.MovementPaths[0].MovementTiles.Length - 1);
		EventManager.TriggerEvent('ObjectMoved', UnitState, UnitState, NewGameState);
		EventManager.TriggerEvent('UnitMoveFinished', UnitState, UnitState, NewGameState);
	}

	NewGameState.AddStateObject(UnitState);

	//Return the game state we have created
	return NewGameState;
}

simulated function BlazingPinionsStage2_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  AbilityContext;
	local StateObjectReference InteractingUnitRef;
	local X2AbilityTemplate AbilityTemplate;
	local VisualizationTrack EmptyTrack;
	local VisualizationTrack BuildTrack;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_PersistentEffect	PersistentEffectAction;
	local int i, j;
	local X2VisualizerInterface TargetVisualizerInterface;

	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_WorldEffectTileData WorldDataUpdate;
	local XComGameState_InteractiveObject InteractiveObject;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = AbilityContext.InputContext.SourceObject;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);

	//****************************************************************************************
	//Configure the visualization track for the source
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good);

	// Remove the override idle animation
	PersistentEffectAction = X2Action_PersistentEffect(class'X2Action_PersistentEffect'.static.AddToVisualizationTrack(BuildTrack, AbilityContext));
	PersistentEffectAction.IdleAnimName = '';

	// Play the firing action
	class'X2Action_BlazingPinionsStage2'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);

	for( i = 0; i < AbilityContext.ResultContext.ShooterEffectResults.Effects.Length; ++i )
	{
		AbilityContext.ResultContext.ShooterEffectResults.Effects[i].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 
																								  AbilityContext.ResultContext.ShooterEffectResults.ApplyResults[i]);
	}

	if(AbilityContext.InputContext.MovementPaths.Length > 0)
	{
		class'X2VisualizerHelpers'.static.ParsePath(AbilityContext, BuildTrack, OutVisualizationTracks);
	}
	

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for (i = 0; i < AbilityContext.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = AbilityContext.InputContext.MultiTargets[i];
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);
		for( j = 0; j < AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			AbilityContext.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, AbilityContext.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
		}

		TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
		if( TargetVisualizerInterface != none )
		{
			//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
			TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
		}

		if (BuildTrack.TrackActions.Length > 0)
		{
			OutVisualizationTracks.AddItem(BuildTrack);
		}
	}

	//****************************************************************************************
	//Configure the visualization tracks for the environment
	//****************************************************************************************
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.TrackActor = none;
		BuildTrack.StateObject_NewState = EnvironmentDamageEvent;
		BuildTrack.StateObject_OldState = EnvironmentDamageEvent;

		//Wait until signaled by the shooter that the projectiles are hitting
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);

		for( i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; ++i )
		{
			AbilityTemplate.AbilityMultiTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');	
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_WorldEffectTileData', WorldDataUpdate)
	{
		BuildTrack = EmptyTrack;
		BuildTrack.TrackActor = none;
		BuildTrack.StateObject_NewState = WorldDataUpdate;
		BuildTrack.StateObject_OldState = WorldDataUpdate;

		//Wait until signaled by the shooter that the projectiles are hitting
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);

		for( i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; ++i )
		{
			AbilityTemplate.AbilityMultiTargetEffects[i].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');	
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************

	//Process any interactions with interactive objects
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
	{
		// Add any doors that need to listen for notification
		if( InteractiveObject.IsDoor() && InteractiveObject.HasDestroyAnim() && InteractiveObject.InteractionCount % 2 != 0 ) //Is this a closed door?
		{
			BuildTrack = EmptyTrack;
			//Don't necessarily have a previous state, so just use the one we know about
			BuildTrack.StateObject_OldState = InteractiveObject;
			BuildTrack.StateObject_NewState = InteractiveObject;
			BuildTrack.TrackActor = History.GetVisualizer(InteractiveObject.ObjectID);
			class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);
			class'X2Action_BreakInteractActor'.static.AddToVisualizationTrack(BuildTrack, AbilityContext);

			OutVisualizationTracks.AddItem(BuildTrack);
		}
	}
}

// #######################################################################################
// -------------------- MP Abilities -----------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateBlazingPinionsStage1MPAbility()
{
	local X2AbilityTemplate Template;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local X2AbilityCooldown_LocalAndGlobal Cooldown;
	local X2AbilityMultiTarget_BlazingPinions BlazingPinionsMultiTarget;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2Condition_UnitProperty UnitProperty;
	local X2Effect_DelayedAbilityActivation BlazingPinionsStage1DelayEffect;
	local X2Effect_Persistent BlazingPinionsStage1Effect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'BlazingPinionsStage1MP');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_archon_blazingpinions"; // TODO: Change this icon
	Template.Hostility = eHostility_Offensive;
	Template.AbilitySourceName = 'eAbilitySource_Standard';
	Template.bShowActivation = true;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.TwoTurnAttackAbility = default.BlazingPinionsStage2AbilityName;
	Template.MP_PerkOverride = 'BlazingPinionsStage1';

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Cooldown = new class'X2AbilityCooldown_LocalAndGlobal';
	Cooldown.iNumTurns = default.BLAZING_PINIONSMP_LOCAL_COOLDOWN;
	Cooldown.NumGlobalTurns = default.BLAZING_PINIONS_GLOBAL_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeDead = true;
	UnitProperty.HasClearanceToMaxZ = true;
	Template.AbilityShooterConditions.AddItem(UnitProperty);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.TargetingMethod = class'X2TargetingMethod_BlazingPinions';

	// The target locations are enemies
	UnitProperty = new class'X2Condition_UnitProperty';
	UnitProperty.ExcludeFriendlyToSource = true;
	UnitProperty.ExcludeCivilian = true;
	UnitProperty.ExcludeDead = true;
	UnitProperty.HasClearanceToMaxZ = true;
	UnitProperty.FailOnNonUnits = true;
	Template.AbilityMultiTargetConditions.AddItem(UnitProperty);

	BlazingPinionsMultiTarget = new class'X2AbilityMultiTarget_BlazingPinions';
	BlazingPinionsMultiTarget.fTargetRadius = default.BLAZING_PINIONS_TARGETING_AREA_RADIUS;
	BlazingPinionsMultiTarget.NumTargetsRequired = default.BLAZING_PINIONS_NUM_TARGETS;
	Template.AbilityMultiTargetStyle = BlazingPinionsMultiTarget;

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = default.BLAZING_PINIONS_SELECTION_RANGE;
	Template.AbilityTargetStyle = CursorTarget;

	//Delayed Effect to cause the second Blazing Pinions stage to occur
	BlazingPinionsStage1DelayEffect = new class 'X2Effect_DelayedAbilityActivation';
	BlazingPinionsStage1DelayEffect.BuildPersistentEffect(1, false, false, , eGameRule_PlayerTurnBegin);
	BlazingPinionsStage1DelayEffect.EffectName = 'BlazingPinionsStage1Delay';
	BlazingPinionsStage1DelayEffect.TriggerEventName = default.BlazingPinionsStage2TriggerName;
	BlazingPinionsStage1DelayEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true, , Template.AbilitySourceName);
	Template.AddShooterEffect(BlazingPinionsStage1DelayEffect);

	// An effect to attach Perk FX to
	BlazingPinionsStage1Effect = new class'X2Effect_Persistent';
	BlazingPinionsStage1Effect.BuildPersistentEffect(1, true, false, true);
	BlazingPinionsStage1Effect.EffectName = default.BlazingPinionsStage1EffectName;
	Template.AddShooterEffect(BlazingPinionsStage1Effect);

	//  The target FX goes in target array as there will be no single target hit and no side effects of this touching a unit
	Template.AddShooterEffect(new class'X2Effect_ApplyBlazingPinionsTargetToWorld');

	Template.ModifyNewContextFn = BlazingPinionsStage1_ModifyActivatedAbilityContext;
	Template.BuildNewGameStateFn = BlazingPinionsStage1_BuildGameState;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.BuildVisualizationFn = BlazingPinionsStage1_BuildVisualization;
	Template.BuildAppliedVisualizationSyncFn = BlazingPinionsStage1_BuildVisualizationSync;
	Template.CinescriptCameraType = "Archon_BlazingPinions_Stage1";

	return Template;
}

defaultproperties
{
	BlazingPinionsStage2AbilityName="BlazingPinionsStage2"
	BlazingPinionsStage2TriggerName="BlazingPinionsStage2Trigger"
	BlazingPinionsStage1EffectName="BlazingPinionsStage1Effect"
}