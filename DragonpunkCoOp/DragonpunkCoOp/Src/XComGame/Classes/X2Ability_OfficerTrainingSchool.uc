//---------------------------------------------------------------------------------------
//  FILE:    X2Ability_OfficerTrainingSchool.uc
//  AUTHOR:  Joshua Bouscher - 3/19/2015
//  PURPOSE: Officer Training School abilities which are not class specific live here.
//           Class specific abilities live in their respective class ability files.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Ability_OfficerTrainingSchool extends X2Ability config(GameData_SoldierSkills);

var config int LIGHTNING_STRIKE_MOVE_BONUS;
var config int LIGHTNING_STRIKE_NUM_TURNS;

var config int VENGEANCE_DURATION;
var config int VENGEANCE_MIN_RANK;

var localized string AimBonus, CritBonus, WillBonus, MobilityBonus;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(LightningStrike());
	Templates.AddItem(Vengeance());

	return Templates;
}

static function X2AbilityTemplate LightningStrike()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PersistentStatChange     StatEffect;
	local X2Condition_UnitProperty          ConcealedCondition;
	local X2AbilityTrigger_EventListener    Trigger;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'LightningStrike');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_tacticalsense";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	
	Trigger = new class'X2AbilityTrigger_EventListener';
	Trigger.ListenerData.Deferral = ELD_OnStateSubmitted;
	Trigger.ListenerData.EventID = 'StartOfMatchConcealment';
	Trigger.ListenerData.Filter = eFilter_Player;
	Trigger.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Template.AbilityTriggers.AddItem(Trigger);

	ConcealedCondition = new class'X2Condition_UnitProperty';
	ConcealedCondition.ExcludeFriendlyToSource = false;
	ConcealedCondition.IsConcealed = true;

	StatEffect = new class'X2Effect_PersistentStatChange';
	StatEffect.BuildPersistentEffect(default.LIGHTNING_STRIKE_NUM_TURNS, false, true, false, eGameRule_PlayerTurnBegin);
	StatEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	StatEffect.AddPersistentStatChange(eStat_Mobility, default.LIGHTNING_STRIKE_MOVE_BONUS);
	StatEffect.bRemoveWhenTargetConcealmentBroken = true;
	StatEffect.TargetConditions.AddItem(ConcealedCondition);
	Template.AddTargetEffect(StatEffect);

	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	//  NOTE: No visualization on purpose!

	return Template;
}

static function X2AbilityTemplate Vengeance()
{
	local X2AbilityTemplate                 Template;
	local X2Effect_Vengeance                VengeanceEffect;
	local X2Condition_UnitProperty          ShooterProperty, MultiTargetProperty;
	local X2AbilityTrigger_EventListener    Listener;

	`CREATE_X2ABILITY_TEMPLATE(Template, 'Vengeance');

	Template.AbilitySourceName = 'eAbilitySource_Perk';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.IconImage = "img:///UILibrary_PerkIcons.UIPerk_tacticalsense";

	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityMultiTargetStyle = new class'X2AbilityMultiTarget_AllAllies';

	VengeanceEffect = new class'X2Effect_Vengeance';
	VengeanceEffect.BuildPersistentEffect(default.VENGEANCE_DURATION, false, false, false, eGameRule_PlayerTurnEnd);
	VengeanceEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage);
	Template.AddMultiTargetEffect(VengeanceEffect);

	Listener = new class'X2AbilityTrigger_EventListener';
	Listener.ListenerData.Filter = eFilter_Unit;
	Listener.ListenerData.Deferral = ELD_OnStateSubmitted;
	Listener.ListenerData.EventFn = class'XComGameState_Ability'.static.AbilityTriggerEventListener_Self;
	Listener.ListenerData.EventID = 'UnitDied';
	Template.AbilityTriggers.AddItem(Listener);

	ShooterProperty = new class'X2Condition_UnitProperty';
	ShooterProperty.ExcludeAlive = false;
	ShooterProperty.ExcludeDead = false;
	ShooterProperty.MinRank = default.VENGEANCE_MIN_RANK;
	Template.AbilityShooterConditions.AddItem(ShooterProperty);

	MultiTargetProperty = new class'X2Condition_UnitProperty';
	MultiTargetProperty.ExcludeAlive = false;
	MultiTargetProperty.ExcludeDead = true;
	MultiTargetProperty.ExcludeHostileToSource = true;
	MultiTargetProperty.ExcludeFriendlyToSource = false;
	MultiTargetProperty.RequireSquadmates = true;	
	MultiTargetProperty.ExcludePanicked = true;
	Template.AbilityMultiTargetConditions.AddItem(MultiTargetProperty);

	Template.bSkipFireAction = true;
	Template.bShowActivation = true;
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = Vengeance_BuildVisualization;

	return Template;
}

function Vengeance_BuildVisualization(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack TargetTrack, EmptyTrack;
	local XComGameState_Effect EffectState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2Action_PlaySoundAndFlyOver FlyOverAction;
	local int i;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
	{
		if (EffectState.GetX2Effect().EffectName != class'X2Effect_Vengeance'.default.EffectName)
			continue;

		TargetTrack = EmptyTrack;
		UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		TargetTrack.StateObject_NewState = UnitState;
		TargetTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex - 1);
		TargetTrack.TrackActor = UnitState.GetVisualizer();

		for (i = 0; i < EffectState.StatChanges.Length; ++i)
		{
			FlyOverAction = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(TargetTrack, VisualizeGameState.GetContext()));
			FlyOverAction.SetSoundAndFlyOverParameters(none, GetStringForVengeanceStat(EffectState.StatChanges[i]), '', eColor_Good, , i == 0 ? 2.0f : 0.0f);
		}

		if (TargetTrack.TrackActions.Length > 0)
			OutVisualizationTracks.AddItem(TargetTrack);
	}
}

function string GetStringForVengeanceStat(const StatChange VengeanceStat)
{
	local string StatString;

	switch (VengeanceStat.StatType)
	{
	case eStat_Offense:
		StatString = default.AimBonus;
		break;
	case eStat_CritChance:
		StatString = default.CritBonus;
		break;
	case eStat_Will:
		StatString = default.WillBonus;
		break;
	case eStat_Mobility:
		StatString = default.MobilityBonus;
		break;
	default:
		StatString = "UNKNOWN";
		`RedScreenOnce("Unhandled Vengeance stat" @ VengeanceStat.StatType @ "-jbouscher @gameplay");
		break;
	}
	StatString = repl(StatString, "<amount/>", int(VengeanceStat.StatAmount));
	return StatString;
}