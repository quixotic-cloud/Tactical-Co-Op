//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_SpecialistAbilitySet.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    17 Jul 2014
//  PURPOSE: Defines abilities used by the Specialist class.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Ability_SpecialistAbilitySet extends X2Ability
	config(GameData_SoldierSkills);

var name EverVigilantEffectName;

var localized string AidProtocolEffectName;
var localized string AidProtocolEffectDesc;

var config int UNDER_PRESSURE_BONUS;

var config float MIST_RADIUS;        //  meters
var config float MIST_RANGE;         //  meters
var config float GREMLIN_PERK_EFFECT_WINDOW; // seconds
var config float GREMLIN_ARRIVAL_TIMEOUT;   //  seconds

var config int FIELD_MEDIC_BONUS;
var config int GUARDIAN_PROC;
var config int COMBAT_PROTOCOL_CHARGES;
var config int REVIVAL_PROTOCOL_CHARGES;
var config int RESTORATIVE_MIST_CHARGES;
var config int CAPACITOR_DISCHARGE_CHARGES;
var config int HAYWIRE_PROTOCOL_COOLDOWN;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CoolUnderPressure());
	Templates.AddItem(AidProtocol());
	Templates.AddItem(IntrusionProtocol());
	Templates.AddItem(ConstructIntrusionProtocol('IntrusionProtocol_Chest', 'Hack_Chest'));
	Templates.AddItem(ConstructIntrusionProtocol('IntrusionProtocol_Workstation', 'Hack_Workstation'));
	Templates.AddItem(ConstructIntrusionProtocol('IntrusionProtocol_ObjectiveChest', 'Hack_ObjectiveChest'));
	Templates.AddItem(FinalizeIntrusion('FinalizeIntrusion', false));
	Templates.AddItem(FinalizeIntrusion('FinalizeHaywire', true));
	Templates.AddItem(CancelIntrusion());
	Templates.AddItem(CancelHaywire());
	Templates.AddItem(HaywireProtocol());
	Templates.AddItem(EverVigilant());
	Templates.AddItem(EverVigilantTrigger());
	Templates.AddItem(Sentinel());
	Templates.AddItem(PurePassive('CoveringFire', "img:///UILibrary_PerkIcons.UIPerk_coverfire", true));
	Templates.AddItem(RestorativeMist());
	Templates.AddItem(CapacitorDischarge());
	Templates.AddItem(MedicalProtocol());
	Templates.AddItem(GremlinHeal());
	Templates.AddItem(GremlinStabilize());
	Templates.AddItem(CombatProtocol());
	Templates.AddItem(RevivalProtocol());
	Templates.AddItem(ScanningProtocol());
	Templates.AddItem(PurePassive('ThreatAssessment', "img:///UILibrary_PerkIcons.UIPerk_threat_assesment"));
	Templates.AddItem(FieldMedic());
	Templates.AddItem(PurePassive('IntrusionProtocolPassive', "img:///UILibrary_PerkIcons.UIPerk_intrusionprotocol"));

	return Templates;
}

static function X2AbilityTemplate FieldMedic()
{
	local X2AbilityTemplate         Template;

	Template = PurePassive('FieldMedic', "img:///UILibrary_PerkIcons.UIPerk_fieldmedic");
	Template.GetBonusWeaponAmmoFn = FieldMedic_BonusWeaponAmmo;

	return Template;
}

function int FieldMedic_BonusWeaponAmmo(XComGameState_Unit UnitState, XComGameState_Item ItemState)
{
	if (ItemState.GetWeaponCategory() == class'X2Item_DefaultUtilityItems'.default.MedikitCat)
		return default.FIELD_MEDIC_BONUS;

	return 0;
}

//******** Cool Under Pressure Ability **********
static function X2AbilityTemplate CoolUnderPressure()
{
	local X2AbilityTemplate						Template;
	local X2AbilityTargetStyle                  TargetStyle;
	local X2AbilityTrigger						Trigger;
	local X2Effect_ModifyReactionFire           ReactionFire;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CoolUnderPressure');
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_coolpressure";

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;

	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);

	ReactionFire = new class'X2Effect_ModifyReactionFire';
	ReactionFire.bAllowCrit = true;
	ReactionFire.ReactionModifier = default.UNDER_PRESSURE_BONUS;
	ReactionFire.BuildPersistentEffect(1, true, true, true);
	ReactionFire.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,,,Template.AbilitySourceName);
	Template.AddTargetEffect(ReactionFire);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate AidProtocol()
{
	local X2AbilityTemplate                     Template;
	local X2AbilityCost_ActionPoints            ActionPointCost;
	local X2Condition_UnitProperty              TargetProperty;
	local X2Condition_UnitEffects               EffectsCondition;
	local X2AbilityCooldown_AidProtocol         Cooldown;
	local X2Effect_ThreatAssessment             CoveringFireEffect;
	local X2Condition_AbilityProperty           AbilityCondition;
	local X2Condition_UnitProperty              UnitCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'AidProtocol');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_aidprotocol";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Defensive;
	Template.bLimitTargetIcons = true;
	Template.DisplayTargetHitChance = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SQUADDIE_PRIORITY;

	Cooldown = new class'X2AbilityCooldown_AidProtocol';
	Template.AbilityCooldown = Cooldown;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = false;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	TargetProperty = new class'X2Condition_UnitProperty';
	TargetProperty.ExcludeDead = true;
	TargetProperty.ExcludeHostileToSource = true;
	TargetProperty.ExcludeFriendlyToSource = false;
	TargetProperty.RequireSquadmates = true;
	Template.AbilityTargetConditions.AddItem(TargetProperty);

	EffectsCondition = new class'X2Condition_UnitEffects';
	EffectsCondition.AddExcludeEffect('AidProtocol', 'AA_UnitIsImmune');
	EffectsCondition.AddExcludeEffect('MimicBeaconEffect', 'AA_UnitIsImmune');
	Template.AbilityTargetConditions.AddItem(EffectsCondition);

	Template.AddTargetEffect(AidProtocolEffect());

	//  add covering fire effect if the soldier has threat assessment - this regular shot applies to all non-sharpshooters
	CoveringFireEffect = new class'X2Effect_ThreatAssessment';
	CoveringFireEffect.EffectName = 'ThreatAssessment_CF';
	CoveringFireEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	CoveringFireEffect.AbilityToActivate = 'OverwatchShot';
	CoveringFireEffect.ImmediateActionPoint = class'X2CharacterTemplateManager'.default.OverwatchReserveActionPoint;
	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('ThreatAssessment');
	CoveringFireEffect.TargetConditions.AddItem(AbilityCondition);
	UnitCondition = new class'X2Condition_UnitProperty';
	UnitCondition.ExcludeHostileToSource = true;
	UnitCondition.ExcludeFriendlyToSource = false;
	UnitCondition.ExcludeSoldierClasses.AddItem('Sharpshooter');
	CoveringFireEffect.TargetConditions.AddItem(UnitCondition);
	Template.AddTargetEffect(CoveringFireEffect);

	//  add covering fire effect if the soldier has threat assessment - this pistol shot only applies to sharpshooters
	CoveringFireEffect = new class'X2Effect_ThreatAssessment';
	CoveringFireEffect.EffectName = 'PistolThreatAssessment';
	CoveringFireEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnBegin);
	CoveringFireEffect.AbilityToActivate = 'PistolReturnFire';
	CoveringFireEffect.ImmediateActionPoint = class'X2CharacterTemplateManager'.default.PistolOverwatchReserveActionPoint;
	AbilityCondition = new class'X2Condition_AbilityProperty';
	AbilityCondition.OwnerHasSoldierAbilities.AddItem('ThreatAssessment');
	CoveringFireEffect.TargetConditions.AddItem(AbilityCondition);
	UnitCondition = new class'X2Condition_UnitProperty';
	UnitCondition.ExcludeHostileToSource = true;
	UnitCondition.ExcludeFriendlyToSource = false;
	UnitCondition.RequireSoldierClasses.AddItem('Sharpshooter');
	CoveringFireEffect.TargetConditions.AddItem(UnitCondition);
	Template.AddTargetEffect(CoveringFireEffect);

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.bStationaryWeapon = true;
	Template.BuildNewGameStateFn = AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = GremlinSingleTarget_BuildVisualization;
	Template.bSkipPerkActivationActions = true;
	Template.bShowActivation = true;

	Template.CustomSelfFireAnim = 'NO_DefenseProtocol';

	return Template;
}

static function XComGameState AttachGremlinToTarget_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Item GremlinItemState;
	local XComGameState_Unit GremlinUnitState, TargetUnitState;
	local TTile TargetTile;

	AbilityContext = XComGameStateContext_Ability(Context);
	NewGameState = TypicalAbility_BuildGameState(Context);

	TargetUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnitState == none)
	{
		TargetUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', AbilityContext.InputContext.PrimaryTarget.ObjectID));
		NewGameState.AddStateObject(TargetUnitState);
	}
	GremlinItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	if (GremlinItemState == none)
	{
		GremlinItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', AbilityContext.InputContext.ItemObject.ObjectID));
		NewGameState.AddStateObject(GremlinItemState);
	}
	GremlinUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(GremlinItemState.CosmeticUnitRef.ObjectID));
	if (GremlinUnitState == none)
	{
		GremlinUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', GremlinItemState.CosmeticUnitRef.ObjectID));
		NewGameState.AddStateObject(GremlinUnitState);
	}

	`assert(TargetUnitState != none && GremlinItemState != none && GremlinUnitState != none);

	GremlinItemState.AttachedUnitRef = TargetUnitState.GetReference();

	//Handle height offset for tall units
	TargetTile = TargetUnitState.GetDesiredTileForAttachedCosmeticUnit();

	GremlinUnitState.SetVisibilityLocation(TargetTile);

	return NewGameState;
}

static simulated function GremlinSingleTarget_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate, ThreatTemplate;
	local StateObjectReference          InteractingUnitRef;
	local StateObjectReference          GremlinOwnerUnitRef;
	local XComGameState_Item			GremlinItem;
	local XComGameState_Unit			TargetUnitState;
	local XComGameState_Unit			AttachedUnitState;
	local XComGameState_Unit			GremlinUnitState, ActivatingUnitState;
	local array<PathPoint> Path;
	local TTile                         TargetTile;
	local TTile							StartTile;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;
	local X2Action_WaitForAbilityEffect DelayAction;
	local X2Action_AbilityPerkStart		PerkStartAction;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local int EffectIndex;
	local PathingInputData              PathData;
	local X2Action_SendInterTrackMessage SendMessageAction;
	local X2Action_PlayAnimation		PlayAnimation;

	local X2VisualizerInterface TargetVisualizerInterface;
	local string FlyOverText, FlyOverIcon;
	local X2AbilityTag AbilityTag;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	TargetUnitState = XComGameState_Unit( VisualizeGameState.GetGameStateForObjectID( Context.InputContext.PrimaryTarget.ObjectID ) );

	GremlinItem = XComGameState_Item( History.GetGameStateForObjectID( Context.InputContext.ItemObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 ) );
	GremlinUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.CosmeticUnitRef.ObjectID ) );
	AttachedUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.AttachedUnitRef.ObjectID ) );
	ActivatingUnitState = XComGameState_Unit( History.GetGameStateForObjectID( Context.InputContext.SourceObject.ObjectID) );

	if( GremlinUnitState == none )
	{
		`RedScreen("Attempting GremlinSingleTarget_BuildVisualization with a GremlinUnitState of none");
		return;
	}
	
	//Configure the visualization track for the shooter
	//****************************************************************************************

	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.SourceObject;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID( InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 );
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID( InteractingUnitRef.ObjectID );
	BuildTrack.TrackActor = History.GetVisualizer( InteractingUnitRef.ObjectID );

	class'X2Action_IntrusionProtocolSoldier'.static.AddToVisualizationTrack(BuildTrack, Context);

	OutVisualizationTracks.AddItem( BuildTrack );
	
	//Configure the visualization track for the gremlin
	//****************************************************************************************

	InteractingUnitRef = GremlinUnitState.GetReference( );

	BuildTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(GremlinUnitState.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, , VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = GremlinUnitState.GetVisualizer();

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

	if (AttachedUnitState.TileLocation != TargetUnitState.TileLocation)
	{
		// Given the target location, we want to generate the movement data.  

		//Handle tall units.
		TargetTile = TargetUnitState.GetDesiredTileForAttachedCosmeticUnit();
		StartTile = AttachedUnitState.GetDesiredTileForAttachedCosmeticUnit();

		class'X2PathSolver'.static.BuildPath(GremlinUnitState, StartTile, TargetTile, PathData.MovementTiles);
		class'X2PathSolver'.static.GetPathPointsFromPath( GremlinUnitState, PathData.MovementTiles, Path );
		class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(BuildTrack.TrackActor), Path);

		PathData.MovingUnitRef = GremlinUnitState.GetReference();
		PathData.MovementData = Path;
		Context.InputContext.MovementPaths.AddItem(PathData);
		class'X2VisualizerHelpers'.static.ParsePath( Context, BuildTrack, OutVisualizationTracks );
	}

	PerkStartAction = X2Action_AbilityPerkStart(class'X2Action_AbilityPerkStart'.static.AddToVisualizationTrack(BuildTrack, Context));
	PerkStartAction.NotifyTargetTracks = true;

	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack( BuildTrack, Context ));
	if( AbilityTemplate.CustomSelfFireAnim != '' )
	{
		PlayAnimation.Params.AnimName = AbilityTemplate.CustomSelfFireAnim;
	}
	else
	{
		PlayAnimation.Params.AnimName = 'NO_CombatProtocol';
	}

	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTrack( BuildTrack, Context );

	SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
	SendMessageAction.SendTrackMessageToRef = Context.InputContext.PrimaryTarget;

	OutVisualizationTracks.AddItem( BuildTrack );
	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.PrimaryTarget;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

	DelayAction = X2Action_WaitForAbilityEffect( class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack( BuildTrack, Context ) );
	DelayAction.ChangeTimeoutLength( default.GREMLIN_ARRIVAL_TIMEOUT );       //  give the gremlin plenty of time to show up
	
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityTargetEffects[ EffectIndex ].AddX2ActionsForVisualization( VisualizeGameState, BuildTrack, Context.FindTargetEffectApplyResult( AbilityTemplate.AbilityTargetEffects[ EffectIndex ] ) );
	}
					
	if (AbilityTemplate.bShowActivation)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		if (AbilityTemplate.DataName == 'AidProtocol' && ActivatingUnitState.HasSoldierAbility('ThreatAssessment'))
		{
			ThreatTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('ThreatAssessment');
			FlyOverText = ThreatTemplate.LocFlyOverText;			
			FlyOverIcon = ThreatTemplate.IconImage;
		}
		else
		{		
			FlyOverText = AbilityTemplate.LocFlyOverText;
			FlyOverIcon = AbilityTemplate.IconImage;
		}
		AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
		AbilityTag.ParseObj = History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID);
		FlyOverText = `XEXPAND.ExpandString(FlyOverText);
		AbilityTag.ParseObj = none;

		SoundAndFlyOver.SetSoundAndFlyOverParameters(none, FlyOverText, '', eColor_Good, FlyOverIcon, 1.5f, true);
	}

	TargetVisualizerInterface = X2VisualizerInterface(BuildTrack.TrackActor);
	if (TargetVisualizerInterface != none)
	{
		//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
		TargetVisualizerInterface.BuildAbilityEffectsVisualization(VisualizeGameState, BuildTrack);
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************


	//Configure the visualization track for the owner of the Gremlin
	//****************************************************************************************
	if (AbilityTemplate.ActivationSpeech != '')
	{
		GremlinOwnerUnitRef = GremlinItem.OwnerStateObject;

		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(GremlinOwnerUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(GremlinOwnerUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(GremlinOwnerUnitRef.ObjectID);

		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.ActivationSpeech, eColor_Good);

		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************
}

static function X2Effect_AidProtocol AidProtocolEffect()
{
	local X2Effect_AidProtocol                Effect;

	Effect = new class'X2Effect_AidProtocol';
	Effect.EffectName = 'AidProtocol';
	Effect.DuplicateResponse = eDupe_Ignore;            //  Gremlin effects should always be setup such that a target already under the effect is invalid.
	Effect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Effect.bRemoveWhenTargetDies = true;
	Effect.SetDisplayInfo(ePerkBuff_Bonus, default.AidProtocolEffectName, default.AidProtocolEffectDesc, "img:///UILibrary_PerkIcons.UIPerk_aidprotocol", true);

	return Effect;
}

static function X2AbilityTemplate CombatProtocol()
{
	local X2AbilityTemplate                     Template;
	local X2AbilityCost_ActionPoints            ActionPointCost;
	local X2AbilityCharges                      Charges;
	local X2AbilityCost_Charges                 ChargeCost;
	local X2Effect_ApplyWeaponDamage            RobotDamage;
	local X2Condition_UnitProperty              RobotProperty;
	local X2Condition_Visibility                VisCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CombatProtocol');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_combatprotocol";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Offensive;
	Template.bLimitTargetIcons = true;
	Template.DisplayTargetHitChance = false;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;

	Charges = new class 'X2AbilityCharges';
	Charges.InitialCharges = default.COMBAT_PROTOCOL_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(default.LivingHostileUnitOnlyProperty);
	VisCondition = new class'X2Condition_Visibility';
	VisCondition.bRequireGameplayVisible = true;
	VisCondition.bActAsSquadsight = true;
	Template.AbilityTargetConditions.AddItem(VisCondition);

	Template.AddTargetEffect(new class'X2Effect_ApplyWeaponDamage');
	
	RobotDamage = new class'X2Effect_ApplyWeaponDamage';
	RobotDamage.bIgnoreBaseDamage = true;
	RobotDamage.DamageTag = 'CombatProtocol_Robotic';
	RobotProperty = new class'X2Condition_UnitProperty';
	RobotProperty.ExcludeOrganic = true;
	RobotDamage.TargetConditions.AddItem(RobotProperty);
	Template.AddTargetEffect(RobotDamage);

	Template.bStationaryWeapon = true;
	Template.BuildNewGameStateFn = AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = GremlinSingleTarget_BuildVisualization;
	Template.bSkipPerkActivationActions = true;
	Template.PostActivationEvents.AddItem('ItemRecalled');
	
	Template.CustomSelfFireAnim = 'NO_CombatProtocol';
	Template.CinescriptCameraType = "Specialist_CombatProtocol";

	return Template;
}

static function X2AbilityTemplate MedicalProtocol()
{
	local X2AbilityTemplate             Template;

	Template = PurePassive('MedicalProtocol',  "img:///UILibrary_PerkIcons.UIPerk_medicalprotocol", , 'eAbilitySource_Perk');
	Template.AdditionalAbilities.AddItem('GremlinHeal');
	Template.AdditionalAbilities.AddItem('GremlinStabilize');

	return Template;
}

static function X2AbilityTemplate GremlinHeal()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCost_Charges             ChargeCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Condition_UnitStatCheck         UnitStatCheckCondition;
	local X2Condition_UnitEffects           UnitEffectsCondition;
	local X2Effect_ApplyMedikitHeal         MedikitHeal;
	local array<name>                       SkipExclusions;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'GremlinHeal');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;	
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityCharges = new class'X2AbilityCharges_GremlinHeal';

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	ChargeCost.SharedAbilityCharges.AddItem('GremlinStabilize');
	Template.AbilityCosts.AddItem(ChargeCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	SkipExclusions.AddItem(class'X2StatusEffects'.default.BurningName);
	Template.AddShooterEffectExclusions(SkipExclusions);

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false; //Hack: See following comment.
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.ExcludeFullHealth = true;
	UnitPropertyCondition.ExcludeRobotic = true;
	UnitPropertyCondition.ExcludeTurret = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	//Hack: Do this instead of ExcludeDead, to only exclude properly-dead or bleeding-out units.
	UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
	UnitStatCheckCondition.AddCheckStat(eStat_HP, 0, eCheck_GreaterThan);
	Template.AbilityTargetConditions.AddItem(UnitStatCheckCondition);

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect(class'X2StatusEffects'.default.BleedingOutName, 'AA_UnitIsImpaired');
	Template.AbilityTargetConditions.AddItem(UnitEffectsCondition);


	MedikitHeal = new class'X2Effect_ApplyMedikitHeal';
	MedikitHeal.PerUseHP = class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_PERUSEHP;
	MedikitHeal.IncreasedHealProject = 'BattlefieldMedicine';
	MedikitHeal.IncreasedPerUseHP = class'X2Ability_DefaultAbilitySet'.default.NANOMEDIKIT_PERUSEHP;
	Template.AddTargetEffect(MedikitHeal);

	Template.AddTargetEffect(RemoveAllEffectsByDamageType());

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_medicalprotocol";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	Template.bStationaryWeapon = true;
	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.BuildNewGameStateFn = AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = GremlinSingleTarget_BuildVisualization;

	Template.ActivationSpeech = 'MedicalProtocol';

	Template.OverrideAbilities.AddItem('MedikitHeal');
	Template.OverrideAbilities.AddItem('NanoMedikitHeal');
	Template.bOverrideWeapon = true;
	Template.CustomSelfFireAnim = 'NO_MedicalProtocol';
	return Template;
}

static function X2AbilityTemplate GremlinStabilize()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCost_Charges             ChargeCost;
	local X2Condition_UnitProperty          UnitPropertyCondition;
	local X2Effect_RemoveEffects            RemoveEffects;
	local X2AbilityCharges_GremlinHeal      Charges;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'GremlinStabilize');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Charges = new class'X2AbilityCharges_GremlinHeal';
	Charges.bStabilize = true;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	ChargeCost.SharedAbilityCharges.AddItem('GremlinHeal');
	Template.AbilityCosts.AddItem(ChargeCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = false;
	UnitPropertyCondition.ExcludeAlive = false;
	UnitPropertyCondition.ExcludeHostileToSource = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	UnitPropertyCondition.IsBleedingOut = true;
	Template.AbilityTargetConditions.AddItem(UnitPropertyCondition);

	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.BleedingOutName);
	Template.AddTargetEffect(RemoveEffects);
	Template.AddTargetEffect(class'X2StatusEffects'.static.CreateUnconsciousStatusEffect());

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_gremlinheal";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	Template.bStationaryWeapon = true;
	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.BuildNewGameStateFn = AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = GremlinSingleTarget_BuildVisualization;

	Template.ActivationSpeech = 'MedicalProtocol';

	Template.OverrideAbilities.AddItem( 'MedikitStabilize' );
	Template.bOverrideWeapon = true;
	Template.CustomSelfFireAnim = 'NO_MedicalProtocol';

	return Template;
}

static function X2AbilityTemplate RevivalProtocol()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCost_Charges             ChargeCost;
	local X2AbilityCharges                  Charges;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'RevivalProtocol');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.REVIVAL_PROTOCOL_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);
	
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SingleTargetWithSelf;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTargetConditions.AddItem(new class'X2Condition_RevivalProtocol');

	Template.AddTargetEffect(RemoveAdditionalEffectsForRevivalProtocolAndRestorativeMist());
	Template.AddTargetEffect(RemoveAllEffectsByDamageType());
	Template.AddTargetEffect(new class'X2Effect_RestoreActionPoints');      //  put the unit back to full actions

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_revivalprotocol";
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY;
	Template.Hostility = eHostility_Defensive;
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.AbilitySourceName = 'eAbilitySource_Perk';

	Template.bShowActivation = true;
	Template.bStationaryWeapon = true;
	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.BuildNewGameStateFn = AttachGremlinToTarget_BuildGameState;
	Template.BuildVisualizationFn = GremlinSingleTarget_BuildVisualization;

	Template.CustomSelfFireAnim = 'NO_RevivalProtocol';

	return Template;
}

static function X2AbilityTemplate FinalizeIntrusion(name FinalizeName, bool bHaywire)
{
	local X2AbilityTemplate                 Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2AbilityTarget_Single            SingleTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, FinalizeName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_intrusionprotocol";
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.bStationaryWeapon = true; // we move the gremlin during the action, don't move it before we're ready
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;

	// successfully completing the hack requires and costs an action point
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = bHaywire;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = new class'X2AbilityToHitCalc_Hacking';
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.CinescriptCameraType = "Specialist_IntrusionProtocol";

	Template.BuildNewGameStateFn = class'X2Ability_DefaultAbilitySet'.static.FinalizeHackAbility_BuildGameState;
	Template.BuildVisualizationFn = class'X2Ability_DefaultAbilitySet'.static.FinalizeHackAbility_BuildVisualization;
	Template.PostActivationEvents.AddItem('ItemRecalled');

	Template.OverrideAbilities.AddItem( 'FinalizeHack' );
	Template.bOverrideWeapon = true;

	return Template;
}

static function X2AbilityTemplate CancelIntrusion(Name TemplateName = 'CancelIntrusion')
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTarget_Single            SingleTarget;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_intrusionprotocol";
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.bStationaryWeapon = true; // we move the gremlin during the action, dont move it before we're ready
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.Hostility = eHostility_Neutral;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(new class'X2AbilityTrigger_Placeholder');

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.CinescriptCameraType = "Specialist_IntrusionProtocol";

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = None;
	Template.PostActivationEvents.AddItem('ItemRecalled');

	Template.OverrideAbilities.AddItem( 'CancelHack' );
	Template.bOverrideWeapon = true;

	return Template;
}

static function X2AbilityTemplate IntrusionProtocol()
{
	local X2AbilityTemplate             Template;

	Template = ConstructIntrusionProtocol('IntrusionProtocol');

	// add the intrusion protocol variants as well
	Template.AdditionalAbilities.AddItem('IntrusionProtocol_Chest');
	Template.AdditionalAbilities.AddItem('IntrusionProtocol_Workstation');
	Template.AdditionalAbilities.AddItem('IntrusionProtocol_ObjectiveChest');

	return Template;
}

static function X2AbilityTemplate ConstructIntrusionProtocol(name TemplateName, optional name OverrideTemplateName = 'Hack', optional bool bHaywireProtocol = false)
{
	local X2AbilityTemplate             Template;		
	local X2AbilityCost_ActionPoints        ActionPointCost;	
	local X2AbilityTarget_Single            SingleTarget;
	local X2Condition_HackingTarget         HackingTargetCondition;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_comm_hack";
	Template.bDisplayInUITooltip = false;
	Template.bLimitTargetIcons = true;
	Template.bStationaryWeapon = true;
	if(OverrideTemplateName != 'Hack')
	{
		Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.OBJECTIVE_INTERACT_PRIORITY;
		Template.AbilitySourceName = 'eAbilitySource_Commander';
	}
	else
	{
		Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_SERGEANT_PRIORITY;
		Template.AbilitySourceName = 'eAbilitySource_Perk';
	}
	Template.Hostility = eHostility_Neutral;

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bFreeCost = true;                   //  the FinalizeIntrusion ability will consume the action point
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);

	HackingTargetCondition = new class'X2Condition_HackingTarget';
	HackingTargetCondition.RequiredAbilityName = OverrideTemplateName; // filter based on the "normal" hacking ability we are replacing
	HackingTargetCondition.bIntrusionProtocol = !bHaywireProtocol;
	HackingTargetCondition.bHaywireProtocol = bHaywireProtocol;
	Template.AbilityTargetConditions.AddItem(HackingTargetCondition);
	Template.AddShooterEffectExclusions();
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_ShowIfAvailable;

	SingleTarget = new class'X2AbilityTarget_Single';
	SingleTarget.bAllowInteractiveObjects = true;
	Template.AbilityTargetStyle = SingleTarget;

	Template.FinalizeAbilityName = 'FinalizeIntrusion';
	Template.CancelAbilityName = 'CancelIntrusion';
	Template.AdditionalAbilities.AddItem('FinalizeIntrusion');
	Template.AdditionalAbilities.AddItem('CancelIntrusion');
	Template.AdditionalAbilities.AddItem('IntrusionProtocolPassive');

	Template.CinescriptCameraType = "Specialist_IntrusionProtocol";

	Template.ActivationSpeech = 'AttemptingHack';  // This seems to have the most appropriate lines, mdomowicz 2015_07_09

	Template.BuildNewGameStateFn = IntrusionProtocol_BuildGameState;
	Template.BuildVisualizationFn = IntrusionProtocol_BuildVisualization;

	Template.OverrideAbilities.AddItem( OverrideTemplateName );
	Template.bOverrideWeapon = true;

	return Template;
}

function XComGameState IntrusionProtocol_BuildGameState( XComGameStateContext Context )
{
	local XComWorldData WorldData;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Item GremlinItemState;
	local XComGameState_Unit GremlinUnitState, TargetUnitState;
	local XComGameState_InteractiveObject InteractiveState;
	local array<TTile> PathTiles;
	local TTile DestinationTile;
	local Vector DesiredLocation;

	AbilityContext = XComGameStateContext_Ability(Context);
	NewGameState = class'X2Ability_DefaultAbilitySet'.static.HackAbility_BuildGameState(Context);

	TargetUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnitState == none)
	{
		InteractiveState = XComGameState_InteractiveObject(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	}
	GremlinItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	if (GremlinItemState == none)
	{
		GremlinItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', AbilityContext.InputContext.ItemObject.ObjectID));
		NewGameState.AddStateObject(GremlinItemState);
	}
	GremlinUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(GremlinItemState.CosmeticUnitRef.ObjectID));
	if (GremlinUnitState == none)
	{
		GremlinUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', GremlinItemState.CosmeticUnitRef.ObjectID));
		NewGameState.AddStateObject(GremlinUnitState);
	}

	`assert((TargetUnitState != none || InteractiveState != none) && GremlinItemState != none && GremlinUnitState != none);

	WorldData = `XWORLD;
	if (TargetUnitState != none)
	{
		DesiredLocation = WorldData.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
		DesiredLocation = WorldData.FindClosestValidLocation(DesiredLocation, true, true);
		DestinationTile = WorldData.GetTileCoordinatesFromPosition(DesiredLocation);
		GremlinItemState.AttachedUnitRef = TargetUnitState.GetReference();
	}
	else if (InteractiveState != none)
	{
		DesiredLocation = WorldData.GetPositionFromTileCoordinates(InteractiveState.TileLocation);
		DesiredLocation = WorldData.FindClosestValidLocation(DesiredLocation, true, true);
		DestinationTile = WorldData.GetTileCoordinatesFromPosition(DesiredLocation);
		GremlinItemState.AttachedUnitRef.ObjectID = 0;

		if(InteractiveState.IsDoor() && !class'X2PathSolver'.static.BuildPath(GremlinUnitState, GremlinUnitState.TileLocation, DestinationTile, PathTiles, false))
		{
			// no path to this side of the door, so try to fly to the other side of it
			DesiredLocation -= (DesiredLocation - InteractiveState.GetVisualizer().Location) * 2;
			DestinationTile = WorldData.GetTileCoordinatesFromPosition(DesiredLocation);
		}
	}
	GremlinUnitState.SetVisibilityLocation(DestinationTile);

	return NewGameState;
}

simulated function IntrusionProtocol_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local StateObjectReference          InteractingUnitRef;	
	local XComGameState_Unit              InteractiveUnit;
	local bool                            bInteractiveUnitIsTurret;
	local XComGameState_Ability         Ability;
	local XComGameState_Item			GremlinWeapon;
	local XComGameState_Unit          GremlinUnitState, OldGremlinUnit;
	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;
	local array<TTile> PathTiles;
	local PathingInputData PathData;
	local array<PathPoint> Path;
	local X2Action_SendInterTrackMessage SendMessageAction;
	local X2Action_WaitForAbilityEffect WaitAction;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local bool bLocalUnit;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	InteractingUnitRef = Context.InputContext.SourceObject;
	
	GremlinWeapon = XComGameState_Item(History.GetGameStateForObjectID(Context.InputContext.ItemObject.ObjectID,,VisualizeGameState.HistoryIndex));
	InteractiveUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.PrimaryTarget.ObjectID));
	bInteractiveUnitIsTurret = (InteractiveUnit != none && InteractiveUnit.IsTurret());
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));

	//Configure the visualization track for the Gremlin
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(GremlinWeapon.CosmeticUnitRef.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, , VisualizeGameState.HistoryIndex);
	OldGremlinUnit = XComGameState_Unit(BuildTrack.StateObject_OldState);
	GremlinUnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	BuildTrack.TrackActor = History.GetVisualizer(GremlinUnitState.ObjectID);
	bLocalUnit = (GremlinUnitState.ControllingPlayer.ObjectID == `TACTICALRULES.GetLocalClientPlayerObjectID());

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);
	
	// Path gremlin to target.
	if(GremlinUnitState.TileLocation != OldGremlinUnit.TileLocation)
	{
		// Given the target location, we want to generate the movement data.  
		class'X2PathSolver'.static.BuildPath(GremlinUnitState, OldGremlinUnit.TileLocation, GremlinUnitState.TileLocation, PathTiles);
		class'X2PathSolver'.static.GetPathPointsFromPath(GremlinUnitState, PathTiles, Path);
		class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(BuildTrack.TrackActor), Path);

		PathData.MovingUnitRef = GremlinUnitState.GetReference();
		PathData.MovementData = Path;
		Context.InputContext.MovementPaths.AddItem(PathData);
		class'X2VisualizerHelpers'.static.ParsePath( Context, BuildTrack, OutVisualizationTracks );
	}

	// Skip hacking visualization for the other player
	if( bLocalUnit )
	{
		class'X2Action_IntrusionProtocol'.static.AddToVisualizationTrack(BuildTrack, Context);
	}

	SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
	SendMessageAction.SendTrackMessageToRef = Context.InputContext.SourceObject;

 	OutVisualizationTracks.AddItem(BuildTrack);

	//Configure the visualization track for the shooter
	//****************************************************************************************
	BuildTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(InteractingUnitRef.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, , VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	
	if (bInteractiveUnitIsTurret)
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", 'HackTurret', eColor_Good);
	}
	else if(Ability.GetMyTemplate().ActivationSpeech != '')
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", Ability.GetMyTemplate().ActivationSpeech, eColor_Good);
	}

	class'X2Action_IntrusionProtocolSoldier'.static.AddToVisualizationTrack(BuildTrack, Context);

	WaitAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
	WaitAction.ChangeTimeoutLength(-1);     //  infinite time - we must wait for the hacking UI to resolve

 	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************
}


static function X2AbilityTemplate EverVigilant()
{
	local X2AbilityTemplate         Template;

	Template = PurePassive('EverVigilant', "img:///UILibrary_PerkIcons.UIPerk_evervigilant");
	Template.AdditionalAbilities.AddItem('EverVigilantTrigger');

	Template.bCrossClassEligible = true;

	return Template;
}

static function X2AbilityTemplate EverVigilantTrigger()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityTrigger_EventListener    Trigger;
	local X2Effect_Persistent               VigilantEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'EverVigilantTrigger');

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;

	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'PlayerTurnEnded';
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.EverVigilantTurnEndListener;
	Template.AbilityTriggers.AddItem(Trigger);

	VigilantEffect = new class'X2Effect_Persistent';
	VigilantEffect.EffectName = default.EverVigilantEffectName;
	VigilantEffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnBegin);
	Template.AddShooterEffect(VigilantEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	
	return Template;
}

static function X2AbilityTemplate RestorativeMist()
{
	local X2AbilityTemplate                 Template;
	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2Condition_UnitProperty          HealTargetCondition;
	local X2Condition_UnitStatCheck         UnitStatCheckCondition;
	local X2Condition_UnitEffects           UnitEffectsCondition;
	local X2Effect_ApplyMedikitHeal         MedikitHeal;
	local X2AbilityCharges                  Charges;
	local X2AbilityCost_Charges             ChargeCost;
	local X2Effect_RestoreActionPoints      RestoreEffect;
	local X2Effect_RemoveEffects            RemoveEffects;
	local X2AbilityMultiTarget_AllAllies	MultiTargetingStyle;
	`CREATE_X2ABILITY_TEMPLATE(Template, 'RestorativeMist');

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.RESTORATIVE_MIST_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();
	Template.bLimitTargetIcons = true;

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	
	//This ability self-targets the specialist, and pulls in everyone on the squad (including the specialist) as multi-targets
	Template.AbilityTargetStyle = default.SelfTarget;
	MultiTargetingStyle = new class'X2AbilityMultiTarget_AllAllies';
	MultiTargetingStyle.bAllowSameTarget = true;
	MultiTargetingStyle.NumTargetsRequired = 1; //At least someone must need healing
	Template.AbilityMultiTargetStyle = MultiTargetingStyle;

	//Targets must need healing
	HealTargetCondition = new class'X2Condition_UnitProperty';
	HealTargetCondition.ExcludeHostileToSource = true;
	HealTargetCondition.ExcludeFriendlyToSource = false;
	HealTargetCondition.ExcludeFullHealth = true;
	HealTargetCondition.RequireSquadmates = true;
	HealTargetCondition.ExcludeDead = false; //See comment below...
	HealTargetCondition.ExcludeRobotic = true;      //  restorative mist can't affect robots
	Template.AbilityMultiTargetConditions.AddItem(HealTargetCondition);

	//Hack: Do this instead of ExcludeDead, to only exclude properly-dead or bleeding-out units.
	UnitStatCheckCondition = new class'X2Condition_UnitStatCheck';
	UnitStatCheckCondition.AddCheckStat(eStat_HP, 0, eCheck_GreaterThan);
	Template.AbilityMultiTargetConditions.AddItem(UnitStatCheckCondition);

	UnitEffectsCondition = new class'X2Condition_UnitEffects';
	UnitEffectsCondition.AddExcludeEffect(class'X2StatusEffects'.default.BleedingOutName, 'AA_UnitIsImpaired');
	Template.AbilityMultiTargetConditions.AddItem(UnitEffectsCondition);

	//Healing effects follow...
	MedikitHeal = new class'X2Effect_ApplyMedikitHeal';
	MedikitHeal.PerUseHP = class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_PERUSEHP;
	Template.AddMultiTargetEffect(MedikitHeal);	

	RestoreEffect = new class'X2Effect_RestoreActionPoints';
	RestoreEffect.TargetConditions.AddItem(new class'X2Condition_RevivalProtocol');
	Template.AddMultiTargetEffect(RestoreEffect);

	RemoveEffects = RemoveAdditionalEffectsForRevivalProtocolAndRestorativeMist();
	RemoveEffects.TargetConditions.AddItem(new class'X2Condition_RevivalProtocol');
	Template.AddMultiTargetEffect(RemoveEffects);
	Template.AddMultiTargetEffect(RemoveAllEffectsByDamageType());
	
	//Typical path to build gamestate, but a (very crazy) special-case visualization
	Template.BuildNewGameStateFn = SendGremlinToOwnerLocation_BuildGameState;
	Template.BuildVisualizationFn = GremlinRestoration_BuildVisualization;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bStationaryWeapon = true;
	Template.bSkipPerkActivationActions = true;
	Template.PostActivationEvents.AddItem('ItemRecalled');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_restorative_mist";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_HideSpecificErrors;
	Template.HideErrors.AddItem('AA_CannotAfford_ActionPoints');
	Template.HideErrors.AddItem('AA_ValueCheckFailed');
	Template.Hostility = eHostility_Defensive;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.TargetingMethod = class'X2TargetingMethod_GremlinAOE';

	Template.ActivationSpeech = 'RestorativeMist';

	return Template;
}

function XComGameState SendGremlinToOwnerLocation_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Item GremlinItemState;
	local XComGameState_Unit GremlinUnitState, OwnerUnitState;

	AbilityContext = XComGameStateContext_Ability(Context);
	NewGameState = TypicalAbility_BuildGameState(Context);

	GremlinItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	if (GremlinItemState == none)
	{
		GremlinItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', AbilityContext.InputContext.ItemObject.ObjectID));
		NewGameState.AddStateObject(GremlinItemState);
	}
	GremlinUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(GremlinItemState.CosmeticUnitRef.ObjectID));
	if (GremlinUnitState == none)
	{
		GremlinUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', GremlinItemState.CosmeticUnitRef.ObjectID));
		NewGameState.AddStateObject(GremlinUnitState);
	}
	OwnerUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	
	`assert(GremlinItemState != none && GremlinUnitState != none && OwnerUnitState != none);

	GremlinItemState.AttachedUnitRef.ObjectID = OwnerUnitState.ObjectID;
	GremlinUnitState.SetVisibilityLocation(OwnerUnitState.TileLocation);

	return NewGameState;
}

static function X2DataTemplate CapacitorDischarge()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2Condition_UnitProperty      UnitPropertyCondition;
	local X2AbilityTarget_Cursor        CursorTarget;
	local X2Effect_ApplyWeaponDamage    DamageEffect;
	local X2Condition_UnitProperty      DamageCondition;
	local X2AbilityMultiTarget_Radius   RadiusMultiTarget;
	local X2AbilityCharges              Charges;
	local X2AbilityCost_Charges         ChargeCost;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'CapacitorDischarge');

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Charges = new class'X2AbilityCharges';
	Charges.InitialCharges = default.CAPACITOR_DISCHARGE_CHARGES;
	Template.AbilityCharges = Charges;

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.AddItem(ChargeCost);

	Template.AbilityToHitCalc = default.DeadEye;

	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	UnitPropertyCondition = new class'X2Condition_UnitProperty';
	UnitPropertyCondition.ExcludeDead = true;
	UnitPropertyCondition.ExcludeFriendlyToSource = false;
	Template.AbilityMultiTargetConditions.AddItem(UnitPropertyCondition);	

	CursorTarget = new class'X2AbilityTarget_Cursor';
	CursorTarget.FixedAbilityRange = 24;            //  meters
	Template.AbilityTargetStyle = CursorTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.fTargetRadius = 5;
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'CapacitorDischarge';
	DamageCondition = new class'X2Condition_UnitProperty';
	DamageCondition.ExcludeRobotic = true;
	DamageCondition.ExcludeFriendlyToSource = false;
	DamageEffect.TargetConditions.AddItem(DamageCondition);
	Template.AddMultiTargetEffect(DamageEffect);

	DamageEffect = new class'X2Effect_ApplyWeaponDamage';
	DamageEffect.bIgnoreBaseDamage = true;
	DamageEffect.DamageTag = 'CapacitorDischarge_Robotic';
	DamageCondition = new class'X2Condition_UnitProperty';
	DamageCondition.ExcludeOrganic = true;
	DamageCondition.ExcludeFriendlyToSource = false;
	DamageEffect.TargetConditions.AddItem(DamageCondition);
	Template.AddMultiTargetEffect(DamageEffect);

	Template.AddMultiTargetEffect(class'X2StatusEffects'.static.CreateDisorientedStatusEffect(true, , false));

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);
	Template.PostActivationEvents.AddItem('ItemRecalled');

	Template.bStationaryWeapon = true;
	Template.BuildNewGameStateFn = SendGremlinToLocation_BuildGameState;
	Template.BuildVisualizationFn = CapacitorDischarge_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_COLONEL_PRIORITY;
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_capacitordischarge";
	Template.Hostility = eHostility_Offensive;
	Template.TargetingMethod = class'X2TargetingMethod_GremlinAOE';
	
	Template.ActivationSpeech = 'CapacitorDischarge';
	Template.CustomSelfFireAnim = 'NO_CapacitorDischargeA';
	Template.DamagePreviewFn = CapacitorDischargeDamagePreview;

	return Template;
}

function bool CapacitorDischargeDamagePreview(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield)
{
	//  return only the damage preview for the organic damage effect
	AbilityState.GetMyTemplate().AbilityMultiTargetEffects[0].GetDamagePreview(TargetRef, AbilityState, MinDamagePreview, MaxDamagePreview, AllowsShield);		
	return true;
}

simulated function CapacitorDischarge_BuildVisualization( XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks )
{
	local XComGameStateHistory			History;
	local XComWorldData					WorldData;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate;

	local XComGameState_Item			GremlinItem;
	local XComGameState_Unit			AttachedUnitState;
	local XComGameState_Unit			GremlinUnitState;

	local StateObjectReference          InteractingUnitRef;
	local StateObjectReference          GremlinOwnerUnitRef;

	local VisualizationTrack			EmptyTrack;
	local VisualizationTrack			BuildTrack;
	local X2Action_WaitForAbilityEffect DelayAction;
	local X2Action_AbilityPerkStart		PerkStartAction;

	local Vector						TargetPosition;
	local TTile							TargetTile;
	local PathingInputData              PathData;
	local array<PathPoint> Path;

	local XComGameState_Ability         Ability;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_PlayAnimation		PlayAnimation;


	local int i, j, EffectIndex;
	local X2VisualizerInterface TargetVisualizerInterface;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	Context = XComGameStateContext_Ability( VisualizeGameState.GetContext( ) );
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( Context.InputContext.AbilityTemplateName );

	GremlinItem = XComGameState_Item( History.GetGameStateForObjectID( Context.InputContext.ItemObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 ) );
	GremlinUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.CosmeticUnitRef.ObjectID ) );
	AttachedUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.AttachedUnitRef.ObjectID ) );

	InteractingUnitRef = GremlinItem.CosmeticUnitRef;

	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID( InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 );
	BuildTrack.StateObject_NewState = BuildTrack.StateObject_OldState;
	BuildTrack.TrackActor = History.GetVisualizer( InteractingUnitRef.ObjectID );

	//If there are effects added to the shooter, add the visualizer actions for them
	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[ EffectIndex ].AddX2ActionsForVisualization( VisualizeGameState, BuildTrack, Context.FindShooterEffectApplyResult( AbilityTemplate.AbilityShooterEffects[ EffectIndex ] ) );
	}

	if (Context.InputContext.TargetLocations.Length > 0)
	{
		TargetPosition = Context.InputContext.TargetLocations[0];
		TargetTile = `XWORLD.GetTileCoordinatesFromPosition( TargetPosition );

		if (WorldData.IsTileFullyOccupied( TargetTile ))
		{
			TargetTile.Z++;
		}

		if (!WorldData.IsTileFullyOccupied( TargetTile ))
		{
			class'X2PathSolver'.static.BuildPath( GremlinUnitState, AttachedUnitState.TileLocation, TargetTile, PathData.MovementTiles );
			class'X2PathSolver'.static.GetPathPointsFromPath( GremlinUnitState, PathData.MovementTiles, Path );
			class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(BuildTrack.TrackActor), Path);
			PathData.MovementData = Path;
			PathData.MovingUnitRef = GremlinUnitState.GetReference();
			Context.InputContext.MovementPaths.AddItem(PathData);
			class'X2VisualizerHelpers'.static.ParsePath( Context, BuildTrack, OutVisualizationTracks );
		}
		else
		{
			`redscreen("Gremlin was unable to find a location to move to for ability "@Context.InputContext.AbilityTemplateName);
		}
	}
	else
	{
		`redscreen("Gremlin was not provided a location to move to for ability "@Context.InputContext.AbilityTemplateName);
	}

	PerkStartAction = X2Action_AbilityPerkStart(class'X2Action_AbilityPerkStart'.static.AddToVisualizationTrack(BuildTrack, Context));
	PerkStartAction.NotifyTargetTracks = true;

	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack( BuildTrack, Context ));
	PlayAnimation.Params.AnimName = AbilityTemplate.CustomSelfFireAnim;

	

	// build in a delay before we hit the end (which stops activation effects)
	DelayAction = X2Action_WaitForAbilityEffect( class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack( BuildTrack, Context ) );
	DelayAction.ChangeTimeoutLength( default.GREMLIN_PERK_EFFECT_WINDOW );

	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTrack( BuildTrack, Context );

	OutVisualizationTracks.AddItem( BuildTrack );

	//****************************************************************************************
	//Configure the visualization track for the targets
	//****************************************************************************************
	for (i = 0; i < Context.InputContext.MultiTargets.Length; ++i)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[i];
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack( BuildTrack, Context );

		for( j = 0; j < Context.ResultContext.MultiTargetEffectResults[i].Effects.Length; ++j )
		{
			Context.ResultContext.MultiTargetEffectResults[i].Effects[j].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.ResultContext.MultiTargetEffectResults[i].ApplyResults[j]);
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


	//Configure the visualization track for the owner of the Gremlin
	//****************************************************************************************
	Ability = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID));
	if (Ability.GetMyTemplate().ActivationSpeech != '')
	{
		GremlinOwnerUnitRef = GremlinItem.OwnerStateObject;

		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(GremlinOwnerUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(GremlinOwnerUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(GremlinOwnerUnitRef.ObjectID);

		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", Ability.GetMyTemplate().ActivationSpeech, eColor_Good);

		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************
}

static function X2AbilityTemplate ScanningProtocol()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCost_ActionPoints    ActionPointCost;
	local X2AbilityMultiTarget_Radius   RadiusMultiTarget;
	local X2Effect_PersistentSquadViewer    ViewerEffect;
	local X2Effect_ScanningProtocol     ScanningEffect;
	local X2AbilityCost_Charges         ChargeCost;
	local X2Condition_UnitProperty      CivilianProperty;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'ScanningProtocol');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sensorsweep";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;

	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_LIEUTENANT_PRIORITY;

	Template.AbilityCharges = new class'X2AbilityCharges_ScanningProtocol';

	ChargeCost = new class'X2AbilityCost_Charges';
	ChargeCost.NumCharges = 1;
	Template.AbilityCosts.Additem(ChargeCost);

	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	Template.AbilityCosts.AddItem(ActionPointCost);

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
	Template.AddShooterEffectExclusions();

	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	Template.AbilityTargetStyle = default.SelfTarget;

	RadiusMultiTarget = new class'X2AbilityMultiTarget_Radius';
	RadiusMultiTarget.bUseWeaponRadius = true;
	RadiusMultiTarget.bIgnoreBlockingCover = true; // skip the cover checks, the squad viewer will handle this once selected
	Template.AbilityMultiTargetStyle = RadiusMultiTarget;

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

	Template.TargetingMethod = class'X2TargetingMethod_TopDown';

	ViewerEffect = new class'X2Effect_PersistentSquadViewer';
	ViewerEffect.bUseSourceLocation = true;
	ViewerEffect.BuildPersistentEffect(1, false, false, false, eGameRule_PlayerTurnEnd);
	Template.AddShooterEffect(ViewerEffect);

	Template.bStationaryWeapon = true;
	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.bSkipPerkActivationActions = true;

	Template.ActivationSpeech = 'ScanningProtocol';
	Template.PostActivationEvents.AddItem('ItemRecalled');
	Template.BuildNewGameStateFn = SendGremlinToOwnerLocation_BuildGameState;
	Template.BuildVisualizationFn = GremlinScanningProtocol_BuildVisualization;
	Template.CinescriptCameraType = "Specialist_ScanningProtocol";
	return Template;
}

function XComGameState SendGremlinToLocation_BuildGameState( XComGameStateContext Context )
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Item GremlinItemState;
	local XComGameState_Unit GremlinUnitState;
	local vector TargetPos;

	AbilityContext = XComGameStateContext_Ability(Context);
	NewGameState = TypicalAbility_BuildGameState(Context);

	GremlinItemState = XComGameState_Item(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));
	if (GremlinItemState == none)
	{
		GremlinItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', AbilityContext.InputContext.ItemObject.ObjectID));
		NewGameState.AddStateObject(GremlinItemState);
	}
	GremlinUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(GremlinItemState.CosmeticUnitRef.ObjectID));
	if (GremlinUnitState == none)
	{
		GremlinUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', GremlinItemState.CosmeticUnitRef.ObjectID));
		NewGameState.AddStateObject(GremlinUnitState);
	}

	`assert(GremlinItemState != none && GremlinUnitState != none);

	GremlinItemState.AttachedUnitRef.ObjectID = 0;
	TargetPos = AbilityContext.InputContext.TargetLocations[0];
	GremlinUnitState.SetVisibilityLocationFromVector(TargetPos);

	return NewGameState;
}

simulated function GremlinScanningProtocol_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate;
	local StateObjectReference          InteractingUnitRef;
	local XComGameState_Item			GremlinItem;
	local XComGameState_Unit			GremlinUnitState, ShooterState;
	local XComGameState_Ability         AbilityState;
	local array<PathPoint> Path;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;
	local X2Action_WaitForAbilityEffect DelayAction;

	local int EffectIndex, MultiTargetIndex;
	local PathingInputData              PathData;
	local X2Action_SendInterTrackMessage SendMessageAction;
	local X2Action_RevealArea			RevealAreaAction;
	local TTile TargetTile;
	local vector TargetPos;

	local X2Action_PlayAnimation PlayAnimation;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Context.InputContext.AbilityRef.ObjectID, , VisualizeGameState.HistoryIndex));
	AbilityTemplate = AbilityState.GetMyTemplate();

	GremlinItem = XComGameState_Item(History.GetGameStateForObjectID(Context.InputContext.ItemObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1));
	GremlinUnitState = XComGameState_Unit(History.GetGameStateForObjectID(GremlinItem.CosmeticUnitRef.ObjectID, , VisualizeGameState.HistoryIndex - 1));

	//Configure the visualization track for the shooter
	//****************************************************************************************

	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.SourceObject;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
	BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);
	ShooterState = XComGameState_Unit(BuildTrack.StateObject_NewState);

	class'X2Action_IntrusionProtocolSoldier'.static.AddToVisualizationTrack(BuildTrack, Context);

	/*for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));
	}*/

	OutVisualizationTracks.AddItem(BuildTrack);

	//Configure the visualization track for the gremlin
	//****************************************************************************************
	InteractingUnitRef = GremlinUnitState.GetReference();

	BuildTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(GremlinUnitState.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, , VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = GremlinUnitState.GetVisualizer();

	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);

	// Given the target location, we want to generate the movement data.  
	TargetTile = ShooterState.TileLocation;
	TargetPos = `XWORLD.GetPositionFromTileCoordinates(TargetTile);

	class'X2PathSolver'.static.BuildPath(GremlinUnitState, GremlinUnitState.TileLocation, TargetTile, PathData.MovementTiles);
	class'X2PathSolver'.static.GetPathPointsFromPath(GremlinUnitState, PathData.MovementTiles, Path);
	class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(BuildTrack.TrackActor), Path);
	PathData.MovingUnitRef = GremlinUnitState.GetReference();
	PathData.MovementData = Path;
	Context.InputContext.MovementPaths.AddItem(PathData);
	class'X2VisualizerHelpers'.static.ParsePath(Context, BuildTrack, OutVisualizationTracks);
	class'X2Action_AbilityPerkStart'.static.AddToVisualizationTrack(BuildTrack, Context);

	RevealAreaAction = X2Action_RevealArea(class'X2Action_RevealArea'.static.AddToVisualizationTrack(BuildTrack, Context));
	RevealAreaAction.TargetLocation = TargetPos;
	RevealAreaAction.ScanningRadius = GremlinItem.GetItemRadius(AbilityState) * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;
	
	PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, Context));
	PlayAnimation.Params.AnimName = 'NO_ScanningProtocol';
	
	DelayAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
	DelayAction.ChangeTimeoutLength(default.GREMLIN_PERK_EFFECT_WINDOW);

	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTrack(BuildTrack, Context);

	for (MultiTargetIndex = 0; MultiTargetIndex < Context.InputContext.MultiTargets.Length; ++MultiTargetIndex)
	{
		SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
		SendMessageAction.SendTrackMessageToRef = Context.InputContext.MultiTargets[MultiTargetIndex];
	}

	OutVisualizationTracks.AddItem(BuildTrack);
	//****************************************************************************************

	//Configure the visualization track for the target
	//****************************************************************************************
	for (MultiTargetIndex = 0; MultiTargetIndex < Context.InputContext.MultiTargets.Length; ++MultiTargetIndex)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[MultiTargetIndex];
		BuildTrack = EmptyTrack;
		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		DelayAction = X2Action_WaitForAbilityEffect(class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context));
		DelayAction.ChangeTimeoutLength(default.GREMLIN_ARRIVAL_TIMEOUT);       //  give the gremlin plenty of time to show up

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityMultiTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityMultiTargetEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindMultiTargetEffectApplyResult(AbilityTemplate.AbilityMultiTargetEffects[EffectIndex], MultiTargetIndex));
		}

		OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************
}

simulated function GremlinRestoration_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability  Context;
	local X2AbilityTemplate             AbilityTemplate;
	local StateObjectReference          InteractingUnitRef;
	local XComGameState_Item			GremlinItem;
	local XComGameState_Unit			GremlinUnitState, MultiTargetUnit;
	local array<PathPoint>              Path;
	local name                          ResultName;
	local bool                          TargetGotAnyEffects;

	local VisualizationTrack        EmptyTrack;
	local VisualizationTrack        BuildTrack;
	local X2Action_WaitForAbilityEffect DelayAction;
	local X2Action_Delay ShortDelayAction;

	local int EffectIndex, MultiTargetIndex, ActionIndex;
	local PathingInputData              PathData;
	local X2Action_SendInterTrackMessage SendMessageAction;
	local TTile TargetTile, PrevTile;

	local X2Action_PlayAnimation PlayAnimation;
	local EffectResults MultiTargetResult;

	local X2Action_PlaySoundAndFlyOver SoundAndFlyover;
	local X2Action_UpdateUI UIUpdate;

	History = `XCOMHISTORY;

	Context = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(Context.InputContext.AbilityTemplateName);

	GremlinItem = XComGameState_Item( History.GetGameStateForObjectID( Context.InputContext.ItemObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 ) );
	GremlinUnitState = XComGameState_Unit( History.GetGameStateForObjectID( GremlinItem.CosmeticUnitRef.ObjectID, , VisualizeGameState.HistoryIndex - 1 ) );
	
	//Configure the visualization track for the shooter
	//****************************************************************************************

	//****************************************************************************************
	InteractingUnitRef = Context.InputContext.SourceObject;
	BuildTrack = EmptyTrack;
	BuildTrack.StateObject_OldState = History.GetGameStateForObjectID( InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1 );
	BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID( InteractingUnitRef.ObjectID );
	BuildTrack.TrackActor = History.GetVisualizer( InteractingUnitRef.ObjectID );

	class'X2Action_IntrusionProtocolSoldier'.static.AddToVisualizationTrack(BuildTrack, Context);

	for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityShooterEffects.Length; ++EffectIndex)
	{
		AbilityTemplate.AbilityShooterEffects[EffectIndex].AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, Context.FindShooterEffectApplyResult(AbilityTemplate.AbilityShooterEffects[EffectIndex]));
	}

	if (AbilityTemplate.ActivationSpeech != '')
	{
		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyover'.static.AddToVisualizationTrack(BuildTrack, Context));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, "", AbilityTemplate.ActivationSpeech, eColor_Good);
	}

	OutVisualizationTracks.AddItem( BuildTrack );
	
	//Configure the visualization track for the gremlin
	//****************************************************************************************

	InteractingUnitRef = GremlinUnitState.GetReference( );

	BuildTrack = EmptyTrack;
	History.GetCurrentAndPreviousGameStatesForObjectID(GremlinUnitState.ObjectID, BuildTrack.StateObject_OldState, BuildTrack.StateObject_NewState, , VisualizeGameState.HistoryIndex);
	BuildTrack.TrackActor = GremlinUnitState.GetVisualizer();

	//Wait to start until the soldier tells us to
	class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack(BuildTrack, Context);
	class'X2Action_AbilityPerkStart'.static.AddToVisualizationTrack( BuildTrack, Context );

	//Handle each multi-target
	PrevTile = GremlinUnitState.TileLocation;
	for (MultiTargetIndex = 0; MultiTargetIndex < Context.InputContext.MultiTargets.Length; ++MultiTargetIndex)
	{
		MultiTargetUnit = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(Context.InputContext.MultiTargets[MultiTargetIndex].ObjectID));
		MultiTargetResult = Context.ResultContext.MultiTargetEffectResults[MultiTargetIndex];

		//Gremlin doesn't have to heal itself - ignore
		if (MultiTargetUnit.ObjectID == GremlinUnitState.ObjectID)
			continue;

		//Don't visit targets which got no effect
		TargetGotAnyEffects = false;
		foreach MultiTargetResult.ApplyResults(ResultName)
		{
			if (ResultName == 'AA_Success')
				TargetGotAnyEffects = true;
		}
		if (!TargetGotAnyEffects)
			continue;

		//  build path to multi target
		TargetTile = MultiTargetUnit.TileLocation;
		class'X2PathSolver'.static.BuildPath( GremlinUnitState, PrevTile, TargetTile, PathData.MovementTiles );
		class'X2PathSolver'.static.GetPathPointsFromPath( GremlinUnitState, PathData.MovementTiles, Path );
		class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(BuildTrack.TrackActor), Path);
		PrevTile = TargetTile;
		PathData.MovingUnitRef = GremlinUnitState.GetReference();
		PathData.MovementData = Path;
		Context.InputContext.MovementPaths.Length = 0;
		Context.InputContext.MovementPaths.AddItem(PathData);
		class'X2VisualizerHelpers'.static.ParsePath( Context, BuildTrack, OutVisualizationTracks );

		// The MoveEnd action typically forces the unit to end up at its gamestate position; avoid this
		for( ActionIndex = 0; ActionIndex < BuildTrack.TrackActions.Length; ++ActionIndex )
		{
			if( BuildTrack.TrackActions[ActionIndex].IsA('X2Action_MoveEnd') )
			{
				X2Action_MoveEnd(BuildTrack.TrackActions[ActionIndex]).IgnoreDestinationMismatch = true;
			}
		}

		// Play our animation(s) instead
		if (MultiTargetResult.ApplyResults[2] == 'AA_Success') //Successfully removed disoriented/panicked
		{
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, Context));
			PlayAnimation.Params.AnimName = 'NO_RevivalProtocol';
			PlayAnimation.Params.PlayRate = PlayAnimation.GetNonCriticalAnimationSpeed();
			PlayAnimation.bFinishAnimationWait = true;
		}
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, Context));
		PlayAnimation.Params.AnimName = 'NO_MedicalProtocol';
		PlayAnimation.Params.PlayRate = PlayAnimation.GetNonCriticalAnimationSpeed();
		PlayAnimation.bFinishAnimationWait = true;

		//  tell multi target to go ahead
		SendMessageAction = X2Action_SendInterTrackMessage(class'X2Action_SendInterTrackMessage'.static.AddToVisualizationTrack(BuildTrack, Context));
		SendMessageAction.SendTrackMessageToRef = Context.InputContext.MultiTargets[MultiTargetIndex];
		
		//Pause a little so the animations don't cram together
		ShortDelayAction = X2Action_Delay(class'X2Action_Delay'.static.AddToVisualizationTrack(BuildTrack, Context));
		ShortDelayAction.Duration = 0.5;
	}

	class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTrack( BuildTrack, Context );

	//Move to ending position after each of the targets
	class'X2PathSolver'.static.BuildPath(GremlinUnitState, PrevTile, GremlinUnitState.TileLocation, PathData.MovementTiles);
	class'X2PathSolver'.static.GetPathPointsFromPath(GremlinUnitState, PathData.MovementTiles, Path);
	class'XComPath'.static.PerformStringPulling(XGUnitNativeBase(BuildTrack.TrackActor), Path);
	PathData.MovingUnitRef = GremlinUnitState.GetReference();
	PathData.MovementData = Path;
	Context.InputContext.MovementPaths.Length = 0;
	Context.InputContext.MovementPaths.AddItem(PathData);
	class'X2VisualizerHelpers'.static.ParsePath(Context, BuildTrack, OutVisualizationTracks);


	OutVisualizationTracks.AddItem( BuildTrack );
	//****************************************************************************************

	//Configure the visualization track for the targets
	//****************************************************************************************
	for (MultiTargetIndex = 0; MultiTargetIndex < Context.InputContext.MultiTargets.Length; ++MultiTargetIndex)
	{
		InteractingUnitRef = Context.InputContext.MultiTargets[MultiTargetIndex];

		//Gremlin doesn't have to heal itself.
		if (InteractingUnitRef.ObjectID == GremlinUnitState.ObjectID)
			continue;

		//Same as above - skip units that got no effect
		MultiTargetResult = Context.ResultContext.MultiTargetEffectResults[MultiTargetIndex];
		TargetGotAnyEffects = false;
		foreach MultiTargetResult.ApplyResults(ResultName)
		{
			if (ResultName == 'AA_Success')
				TargetGotAnyEffects = true;
		}
		if (!TargetGotAnyEffects)
			continue;

		BuildTrack = EmptyTrack;

		BuildTrack.StateObject_OldState = History.GetGameStateForObjectID(InteractingUnitRef.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		BuildTrack.StateObject_NewState = VisualizeGameState.GetGameStateForObjectID(InteractingUnitRef.ObjectID);
		BuildTrack.TrackActor = History.GetVisualizer(InteractingUnitRef.ObjectID);

		if (BuildTrack.StateObject_NewState == OutVisualizationTracks[OutVisualizationTracks.length-1].StateObject_NewState)
		{
			BuildTrack = OutVisualizationTracks[OutVisualizationTracks.length-1];
		}

		DelayAction = X2Action_WaitForAbilityEffect( class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTrack( BuildTrack, Context ) );
		DelayAction.ChangeTimeoutLength( default.GREMLIN_ARRIVAL_TIMEOUT * MultiTargetIndex );       //  give the gremlin plenty of time to show up
	
		UIUpdate = X2Action_UpdateUI(class'X2Action_UpdateUI'.static.AddToVisualizationTrack(BuildTrack, Context));
		UIUpdate.SpecificID = InteractingUnitRef.ObjectID;
		UIUpdate.UpdateType = EUIUT_UnitFlag_Health;

		for (EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityMultiTargetEffects.Length; ++EffectIndex)
		{
			AbilityTemplate.AbilityMultiTargetEffects[ EffectIndex ].AddX2ActionsForVisualization( VisualizeGameState, BuildTrack, Context.FindMultiTargetEffectApplyResult( AbilityTemplate.AbilityMultiTargetEffects[ EffectIndex ], MultiTargetIndex ) );
		}
							
		if (BuildTrack.StateObject_NewState != OutVisualizationTracks[OutVisualizationTracks.length-1].StateObject_NewState)
			OutVisualizationTracks.AddItem(BuildTrack);
	}
	//****************************************************************************************
}

static function X2AbilityTemplate HaywireProtocol()
{
	local X2AbilityTemplate             Template;
	local X2AbilityCooldown             Cooldown;

	Template = ConstructIntrusionProtocol('HaywireProtocol', , true);

	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_haywireprotocol";

	Cooldown = new class'X2AbilityCooldown';
	Cooldown.iNumTurns = default.HAYWIRE_PROTOCOL_COOLDOWN;
	Template.AbilityCooldown = Cooldown;

	Template.CancelAbilityName = 'CancelHaywire';
	Template.AdditionalAbilities.AddItem('CancelHaywire');
	Template.FinalizeAbilityName = 'FinalizeHaywire';
	Template.AdditionalAbilities.AddItem('FinalizeHaywire');

	Template.AbilityTargetStyle = default.SimpleSingleTarget;

	Template.ActivationSpeech = 'HaywireProtocol';

	return Template;
}

static function X2AbilityTemplate CancelHaywire()
{
	local X2AbilityTemplate             Template;

	Template = CancelIntrusion('CancelHaywire');

	Template.BuildNewGameStateFn = CancelHaywire_BuildGameState;

	return Template;
}

function XComGameState CancelHaywire_BuildGameState(XComGameStateContext Context)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(Context);
	NewGameState = TypicalAbility_BuildGameState(Context);

	// locate the Ability gamestate for HaywireProtocol associated with this unit, and remove the turn timer
	foreach History.IterateByClassType(class'XComGameState_Ability', AbilityState)
	{
		if( AbilityState.OwnerStateObject.ObjectID == AbilityContext.InputContext.SourceObject.ObjectID &&
		   AbilityState.GetMyTemplateName() == 'HaywireProtocol' )
		{
			AbilityState = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability', AbilityState.ObjectID));
			NewGameState.AddStateObject(AbilityState);
			AbilityState.iCooldown = 0;
			break;
		}
	}

	return NewGameState;
}

static function X2AbilityTemplate Sentinel()
{
	local X2AbilityTemplate             Template;
	local X2Effect_Guardian             PersistentEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Sentinel');

	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_sentinel";
	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bIsPassive = true;

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);

	PersistentEffect = new class'X2Effect_Guardian';
	PersistentEffect.BuildPersistentEffect(1, true, false);
	PersistentEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage, true,, Template.AbilitySourceName);
	PersistentEffect.ProcChance = default.GUARDIAN_PROC;
	Template.AddTargetEffect(PersistentEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	// Note: no visualization on purpose!

	Template.bCrossClassEligible = true;

	return Template;
}

static function X2Effect_RemoveEffectsByDamageType RemoveAllEffectsByDamageType()
{
	local X2Effect_RemoveEffectsByDamageType RemoveEffectTypes;
	local name HealType;

	RemoveEffectTypes = new class'X2Effect_RemoveEffectsByDamageType';
	foreach class'X2Ability_DefaultAbilitySet'.default.MedikitHealEffectTypes(HealType)
	{
		RemoveEffectTypes.DamageTypesToRemove.AddItem(HealType);
	}
	return RemoveEffectTypes;
}

static function X2Effect_RemoveEffects RemoveAdditionalEffectsForRevivalProtocolAndRestorativeMist()
{
	local X2Effect_RemoveEffects RemoveEffects;
	RemoveEffects = new class'X2Effect_RemoveEffects';
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.DisorientedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2AbilityTemplateManager'.default.PanickedName);
	RemoveEffects.EffectNamesToRemove.AddItem(class'X2StatusEffects'.default.UnconsciousName);
	return RemoveEffects;
}

DefaultProperties
{
	EverVigilantEffectName = "EverVigilantTriggered";
}