//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultAlienAI.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultAlienAI extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> AIComponents;

	// Actions
	AIComponents.AddItem(CreatePlayerLossTemplate());
	AIComponents.AddItem(CreateIncreaseForceLevelTemplate());
	AIComponents.AddItem(CreateBuildFacilityTemplate());
	AIComponents.AddItem(CreateStartLoseTimerTemplate());
	AIComponents.AddItem(CreateRevertToStartPhaseTemplate());
	AIComponents.AddItem(CreateStartGeneratingFacilityDoomTemplate());
	AIComponents.AddItem(CreateStopGeneratingFacilityDoomTemplate());
	AIComponents.AddItem(CreateAddFacilityDoomTemplate());
	AIComponents.AddItem(CreateStartGeneratingFortressDoomTemplate());
	AIComponents.AddItem(CreateStopGeneratingFortressDoomTemplate());
	AIComponents.AddItem(CreateAddFortressDoomTemplate());
	AIComponents.AddItem(CreateStartBuildingFacilitiesTemplate());
	AIComponents.AddItem(CreateStopBuildingFacilitiesTemplate());
	AIComponents.AddItem(CreateStartThrottlingDoomTemplate());
	AIComponents.AddItem(CreateStopThrottlingDoomTemplate());

	// Conditions
	AIComponents.AddItem(CreateDEBUGFalseConditionTemplate());
	AIComponents.AddItem(CreateInStartPhaseTemplate());
	AIComponents.AddItem(CreateNotInStartPhaseTemplate());
	AIComponents.AddItem(CreateInLoseModeTemplate());
	AIComponents.AddItem(CreateNotInLoseModeTemplate());
	AIComponents.AddItem(CreateModeTimerCompleteTemplate());
	AIComponents.AddItem(CreateForceLevelTimerCompleteTemplate());
	AIComponents.AddItem(CreateBuildFacilityTimerCompleteTemplate());
	AIComponents.AddItem(CreateNotAtMaxForceLevelTemplate());
	AIComponents.AddItem(CreateShouldUpdateForceLevelTemplate());
	AIComponents.AddItem(CreateNeedToStartLoseTimerTemplate());
	AIComponents.AddItem(CreateDoomMeterFullTemplate());
	AIComponents.AddItem(CreateShouldRevertToStartPhaseTemplate());
	AIComponents.AddItem(CreateGeneratingFacilityDoomTemplate());
	AIComponents.AddItem(CreateNotGeneratingFacilityDoomTemplate());
	AIComponents.AddItem(CreateFacilityMissionAvailableTemplate());
	AIComponents.AddItem(CreateNoFacilityMissionAvailableTemplate());
	AIComponents.AddItem(CreateBlacksiteObjectiveCompletedTemplate());
	AIComponents.AddItem(CreateFacilityDoomTimerCompleteTemplate());
	AIComponents.AddItem(CreateGeneratingFortressDoomTemplate());
	AIComponents.AddItem(CreateNotGeneratingFortressDoomTemplate());
	AIComponents.AddItem(CreateFortressDoomTimerCompleteTemplate());
	AIComponents.AddItem(CreateBuildingFacilitiesTemplate());
	AIComponents.AddItem(CreateNotBuildingFacilitiesTemplate());
	AIComponents.AddItem(CreateAtMaxFacilitiesTemplate());
	AIComponents.AddItem(CreateNotAtMaxFacilitiesTemplate());
	AIComponents.AddItem(CreateThrottlingDoomTemplate());
	AIComponents.AddItem(CreateNotThrottlingDoomTemplate());
	AIComponents.AddItem(CreateAtThrottlingPercentTemplate());
	AIComponents.AddItem(CreateNotAtThrottlingPercentTemplate());
	AIComponents.AddItem(CreateInFlightModeTemplate());
	AIComponents.AddItem(CreateNotInFlightModeTemplate());

	// Preview Build
	AIComponents.AddItem(CreateEndPreviewPlaythroughTemplate());
	AIComponents.AddItem(CreatePreviewBuildCompleteTemplate());

	return AIComponents;
}

// #######################################################################################
// -------------------- ACTIONS ----------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreatePlayerLossTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_PlayerLoss');
	Template.PerformActionFn = PlayerLossAction;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_InLoseMode');
	Template.Conditions.AddItem('AlienAICondition_ModeTimerComplete');
	
	return Template;
}
static function PlayerLossAction()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	`GAME.GetGeoscape().Pause();
	`HQPRES.StrategyMap2D.SetUIState(eSMS_Flight);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: YOU LOSE");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.bAlienFullGameVictory = true;

	`XEVENTMGR.TriggerEvent('XComLoss', , , NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateIncreaseForceLevelTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_IncreaseForceLevel');
	Template.PerformActionFn = IncreaseForceLevelAction;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_ShouldUpdateForceLevel');
	
	return Template;
}
static function IncreaseForceLevelAction()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: IncreaseForceLevel");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.IncreaseForceLevel();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateBuildFacilityTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_BuildFacility');
	Template.PerformActionFn = BuildFacilityAction;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_BuildFacilityTimerComplete');
	Template.Conditions.AddItem('AlienAICondition_NotInFlightMode');

	return Template;
}
static function BuildFacilityAction()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Facilities;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: BuildFacility");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);
	AlienHQ.BuildAlienFacility(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Facilities = AlienHQ.GetValidFacilityDoomMissions();

	if(Facilities.Length > 1)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: BuildFacility Update Doom Timer");
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		NewGameState.AddStateObject(AlienHQ);
		AlienHQ.UpdateFacilityDoomHours(true);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}
static function X2DataTemplate CreateStartLoseTimerTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StartLoseTimer');
	Template.PerformActionFn = StartLoseTimerAction;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_NeedToStartLoseTimer');
	
	return Template;
}
static function StartLoseTimerAction()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int LoseModeDuration;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StartLoseTimer");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.AIMode = "Lose";
	AlienHQ.AIModeIntervalStartTime = `STRATEGYRULES.GameTime;
	AlienHQ.AIModeIntervalEndTime = AlienHQ.AIModeIntervalStartTime;

	if(AlienHQ.LoseTimerTimeRemaining == 0)
	{
		LoseModeDuration = AlienHQ.GetLoseModeDuration();
		if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
		{
			LoseModeDuration += `SYNC_RAND_STATIC(AlienHQ.GetLoseModeVariance());
		}
		else
		{
			LoseModeDuration -= `SYNC_RAND_STATIC(AlienHQ.GetLoseModeVariance());
		}
	}
	else
	{
		LoseModeDuration = (AlienHQ.LoseTimerTimeRemaining/3600.0f);
		LoseModeDuration = Clamp(LoseModeDuration, AlienHQ.GetMinLoseModeDuration(), (AlienHQ.GetLoseModeDuration() + AlienHQ.GetLoseModeVariance()));
	}
	
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(AlienHQ.AIModeIntervalEndTime, LoseModeDuration);

	AlienHQ.PauseDoomTimers();
	AlienHQ.PauseFacilityTimer();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_DoomIncrease");
	`GAME.GetGeoscape().Pause();
	`HQPRES.UIDoomTimer();
}
static function X2DataTemplate CreateRevertToStartPhaseTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_RevertToStartPhase');
	Template.PerformActionFn = RevertToStartPhase;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_ShouldRevertToStartPhase');

	return Template;
}
static function RevertToStartPhase()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: RevertToStartPhase");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.LoseTimerTimeRemaining = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInSeconds(AlienHQ.AIModeIntervalEndTime, `STRATEGYRULES.GameTime);
	AlienHQ.AIMode = "StartPhase";
	AlienHQ.ResumeDoomTimers(true);
	AlienHQ.ResumeFacilityTimer(true);
	AlienHQ.PostResumeDoomTimers();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateStartGeneratingFacilityDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StartGeneratingFacilityDoom');
	Template.PerformActionFn = StartGeneratingFacilityDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_NotGeneratingFacilityDoom');
	Template.Conditions.AddItem('AlienAICondition_InStartPhase');
	Template.Conditions.AddItem('AlienAICondition_FacilityMissionAvailable');

	return Template;
}
static function StartGeneratingFacilityDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StartGeneratingFacilityDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StartGeneratingFacilityDoom();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateStopGeneratingFacilityDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StopGeneratingFacilityDoom');
	Template.PerformActionFn = StopGeneratingFacilityDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_GeneratingFacilityDoom');
	Template.Conditions.AddItem('AlienAICondition_NoFacilityMissionAvailable');

	return Template;
}
static function StopGeneratingFacilityDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StopGeneratingFacilityDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StopGeneratingFacilityDoom();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateAddFacilityDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_AddFacilityDoom');
	Template.PerformActionFn = AddFacilityDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_GeneratingFacilityDoom');
	Template.Conditions.AddItem('AlienAICondition_FacilityDoomTimerComplete');
	Template.Conditions.AddItem('AlienAICondition_NotInFlightMode');

	return Template;
}
static function AddFacilityDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: AddFacilityDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.OnFacilityDoomTimerComplete(NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	//if (DoomAddedSite != none)
	//	`HQPRES.StartDoomGeneratedCameraPan(DoomAddedSite);
}
static function X2DataTemplate CreateStartGeneratingFortressDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StartGeneratingFortressDoom');
	Template.PerformActionFn = StartGeneratingFortressDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_NotGeneratingFortressDoom');
	Template.Conditions.AddItem('AlienAICondition_InStartPhase');

	return Template;
}
static function StartGeneratingFortressDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StartGeneratingFortressDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StartGeneratingFortressDoom();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateStopGeneratingFortressDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StopGeneratingFortressDoom');
	Template.PerformActionFn = StopGeneratingFortressDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_DEBUGFalseCondition');

	return Template;
}
static function StopGeneratingFortressDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StopGeneratingFortressDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StopGeneratingFortressDoom();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateAddFortressDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_AddFortressDoom');
	Template.PerformActionFn = AddFortressDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_GeneratingFortressDoom');
	Template.Conditions.AddItem('AlienAICondition_FortressDoomTimerComplete');
	Template.Conditions.AddItem('AlienAICondition_NotInFlightMode');

	return Template;
}
static function AddFortressDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local bool bFortressRevealPopup;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: AddFortressDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	if (!AlienHQ.bHasSeenFortress)
	{
		bFortressRevealPopup = true;
		AlienHQ.bHasSeenFortress = true;
		AlienHQ.StartGeneratingFortressDoom(true);
	}
	else
	{
		AlienHQ.OnFortressDoomTimerComplete(NewGameState);
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	if (bFortressRevealPopup)
	{
		`HQPRES.UIFortressReveal();
	}
}
static function X2DataTemplate CreateStartBuildingFacilitiesTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StartBuildingFacilities');
	Template.PerformActionFn = StartBuildingFacilities;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_NotBuildingFacilities');
	Template.Conditions.AddItem('AlienAICondition_NotAtMaxFacilities');
	Template.Conditions.AddItem('AlienAICondition_NotInLoseMode');

	return Template;
}
static function StartBuildingFacilities()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StartBuildingFacilities");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StartBuildingFacilities();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateStopBuildingFacilitiesTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StopBuildingFacilities');
	Template.PerformActionFn = StopBuildingFacilities;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_BuildingFacilities');
	Template.Conditions.AddItem('AlienAICondition_AtMaxFacilities');

	return Template;
}
static function StopBuildingFacilities()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StopBuildingFacilities");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StopBuildingFacilities();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateStartThrottlingDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StartThrottlingDoom');
	Template.PerformActionFn = StartThrottlingDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_NotThrottlingDoom');
	Template.Conditions.AddItem('AlienAICondition_AtThrottlingPercent');

	return Template;
}
static function StartThrottlingDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StartThrottlingDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StartThrottlingDoom();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
static function X2DataTemplate CreateStopThrottlingDoomTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_StopThrottlingDoom');
	Template.PerformActionFn = StopThrottlingDoom;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_ThrottlingDoom');
	Template.Conditions.AddItem('AlienAICondition_NotAtThrottlingPercent');

	return Template;
}
static function StopThrottlingDoom()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("AIAction: StopThrottlingDoom");
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.CreateStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	NewGameState.AddStateObject(AlienHQ);

	AlienHQ.StopThrottlingDoom();

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}
// #######################################################################################
// -------------------- CONDITIONS -------------------------------------------------------
// #######################################################################################
static function X2DataTemplate CreateDEBUGFalseConditionTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_DEBUGFalseCondition');
	Template.IsConditionMetFn = DEBUGFalseCondition;
	
	return Template;
}
static function bool DEBUGFalseCondition()
{
	return false;
}
static function X2DataTemplate CreateInStartPhaseTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_InStartPhase');
	Template.IsConditionMetFn = InStartPhase;
	
	return Template;
}
static function bool InStartPhase()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(AlienHQ.AIMode == "StartPhase")
	{
		return true;
	}

	return false;
}
static function X2DataTemplate CreateNotInStartPhaseTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotInStartPhase');
	Template.IsConditionMetFn = NotInStartPhase;
	
	return Template;
}
static function bool NotInStartPhase()
{
	return (!InStartPhase());
}
static function X2DataTemplate CreateInLoseModeTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_InLoseMode');
	Template.IsConditionMetFn = InLoseMode;
	
	return Template;
}
static function bool InLoseMode()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	if(AlienHQ.AIMode == "Lose")
	{
		return true;
	}

	return false;
}
static function X2DataTemplate CreateNotInLoseModeTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotInLoseMode');
	Template.IsConditionMetFn = NotInLoseMode;
	
	return Template;
}
static function bool NotInLoseMode()
{
	return (!InLoseMode());
}
static function X2DataTemplate CreateModeTimerCompleteTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_ModeTimerComplete');
	Template.IsConditionMetFn = ModeTimerComplete;
	
	return Template;
}
static function bool ModeTimerComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (class'X2StrategyGameRulesetDataStructures'.static.LessThan(AlienHQ.AIModeIntervalEndTime, `STRATEGYRULES.GameTime));
}
static function X2DataTemplate CreateForceLevelTimerCompleteTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_ForceLevelTimerComplete');
	Template.IsConditionMetFn = ForceLevelTimerComplete;
	
	return Template;
}
static function bool ForceLevelTimerComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (class'X2StrategyGameRulesetDataStructures'.static.LessThan(AlienHQ.ForceLevelIntervalEndTime, `STRATEGYRULES.GameTime));
}
static function X2DataTemplate CreateBuildFacilityTimerCompleteTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_BuildFacilityTimerComplete');
	Template.IsConditionMetFn = BuildFacilityTimerComplete;

	return Template;
}
static function bool BuildFacilityTimerComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (class'X2StrategyGameRulesetDataStructures'.static.LessThan(AlienHQ.FacilityBuildEndTime, `STRATEGYRULES.GameTime));
}
static function X2DataTemplate CreateNotAtMaxForceLevelTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotAtMaxForceLevel');
	Template.IsConditionMetFn = NotAtMaxForceLevel;
	
	return Template;
}
static function bool NotAtMaxForceLevel()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (AlienHQ.ForceLevel < AlienHQ.AlienHeadquarters_MaxForceLevel);
}
static function X2DataTemplate CreateShouldUpdateForceLevelTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_ShouldUpdateForceLevel');
	Template.IsConditionMetFn = ShouldUpdateForceLevel;
	
	return Template;
}
static function bool ShouldUpdateForceLevel()
{
	return (NotAtMaxForceLevel() && ForceLevelTimerComplete());
}
static function X2DataTemplate CreateNeedToStartLoseTimerTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NeedToStartLoseTimer');
	Template.IsConditionMetFn = NeedToStartLoseTimer;

	return Template;
}
static function bool NeedToStartLoseTimer()
{
	return (NotInLoseMode() && DoomMeterFull());
}
static function X2DataTemplate CreateDoomMeterFullTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_DoomMeterFull');
	Template.IsConditionMetFn = DoomMeterFull;

	return Template;
}
static function bool DoomMeterFull()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	return (AlienHQ.GetCurrentDoom() >= AlienHQ.GetMaxDoom());
}
static function X2DataTemplate CreateShouldRevertToStartPhaseTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_ShouldRevertToStartPhase');
	Template.IsConditionMetFn = ShouldRevertToStartPhase;

	return Template;
}
static function bool ShouldRevertToStartPhase()
{
	return (NotInStartPhase() && !DoomMeterFull());
}
static function X2DataTemplate CreateGeneratingFacilityDoomTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_GeneratingFacilityDoom');
	Template.IsConditionMetFn = GeneratingFacilityDoom;

	return Template;
}
static function bool GeneratingFacilityDoom()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	return AlienHQ.bGeneratingFacilityDoom;
}
static function X2DataTemplate CreateNotGeneratingFacilityDoomTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotGeneratingFacilityDoom');
	Template.IsConditionMetFn = NotGeneratingFacilityDoom;

	return Template;
}
static function bool NotGeneratingFacilityDoom()
{
	return !GeneratingFacilityDoom();
}
static function X2DataTemplate CreateFacilityMissionAvailableTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_FacilityMissionAvailable');
	Template.IsConditionMetFn = FacilityMissionAvailable;

	return Template;
}
static function bool FacilityMissionAvailable()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Missions;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Missions = AlienHQ.GetValidFacilityDoomMissions();

	return (Missions.Length > 0);
}
static function X2DataTemplate CreateNoFacilityMissionAvailableTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NoFacilityMissionAvailable');
	Template.IsConditionMetFn = NoFacilityMissionAvailable;

	return Template;
}
static function bool NoFacilityMissionAvailable()
{
	return !FacilityMissionAvailable();
}
static function X2DataTemplate CreateBlacksiteObjectiveCompletedTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_BlacksiteObjectiveCompleted');
	Template.IsConditionMetFn = BlacksiteObjectiveCompleted;

	return Template;
}
static function bool BlacksiteObjectiveCompleted()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return XComHQ.IsObjectiveCompleted('T2_M1_InvestigateBlacksite');
}
static function X2DataTemplate CreateFacilityDoomTimerCompleteTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_FacilityDoomTimerComplete');
	Template.IsConditionMetFn = FacilityDoomTimerComplete;

	return Template;
}
static function bool FacilityDoomTimerComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (class'X2StrategyGameRulesetDataStructures'.static.LessThan(AlienHQ.FacilityDoomIntervalEndTime, `STRATEGYRULES.GameTime));
}
static function X2DataTemplate CreateGeneratingFortressDoomTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_GeneratingFortressDoom');
	Template.IsConditionMetFn = GeneratingFortressDoom;

	return Template;
}
static function bool GeneratingFortressDoom()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	return AlienHQ.bGeneratingFortressDoom;
}
static function X2DataTemplate CreateNotGeneratingFortressDoomTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotGeneratingFortressDoom');
	Template.IsConditionMetFn = NotGeneratingFortressDoom;

	return Template;
}
static function bool NotGeneratingFortressDoom()
{
	return !GeneratingFortressDoom();
}
static function X2DataTemplate CreateFortressDoomTimerCompleteTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_FortressDoomTimerComplete');
	Template.IsConditionMetFn = FortressDoomTimerComplete;

	return Template;
}
static function bool FortressDoomTimerComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (class'X2StrategyGameRulesetDataStructures'.static.LessThan(AlienHQ.FortressDoomIntervalEndTime, `STRATEGYRULES.GameTime));
}
static function X2DataTemplate CreateBuildingFacilitiesTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_BuildingFacilities');
	Template.IsConditionMetFn = BuildingFacilities;

	return Template;
}
static function bool BuildingFacilities()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	return AlienHQ.bBuildingFacility;
}
static function X2DataTemplate CreateNotBuildingFacilitiesTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotBuildingFacilities');
	Template.IsConditionMetFn = NotBuildingFacilities;

	return Template;
}
static function bool NotBuildingFacilities()
{
	return !BuildingFacilities();
}
static function X2DataTemplate CreateAtMaxFacilitiesTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_AtMaxFacilities');
	Template.IsConditionMetFn = AtMaxFacilities;

	return Template;
}
static function bool AtMaxFacilities()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<XComGameState_MissionSite> Facilities;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	Facilities = AlienHQ.GetValidFacilityDoomMissions();

	return (Facilities.Length >= AlienHQ.GetMaxFacilities());
}
static function X2DataTemplate CreateNotAtMaxFacilitiesTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotAtMaxFacilities');
	Template.IsConditionMetFn = NotAtMaxFacilities;

	return Template;
}
static function bool NotAtMaxFacilities()
{
	return !AtMaxFacilities();
}
static function X2DataTemplate CreateThrottlingDoomTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_ThrottlingDoom');
	Template.IsConditionMetFn = ThrottlingDoom;

	return Template;
}
static function bool ThrottlingDoom()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return (AlienHQ.bThrottlingDoom);
}
static function X2DataTemplate CreateNotThrottlingDoomTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotThrottlingDoom');
	Template.IsConditionMetFn = NotThrottlingDoom;

	return Template;
}
static function bool NotThrottlingDoom()
{
	return !ThrottlingDoom();
}
static function X2DataTemplate CreateAtThrottlingPercentTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_AtThrottlingPercent');
	Template.IsConditionMetFn = AtThrottlingPercent;

	return Template;
}
static function bool AtThrottlingPercent()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	return ((float(AlienHQ.GetCurrentDoom(true)) / float(AlienHQ.GetMaxDoom())) >= AlienHQ.GetDoomThrottleMinPercent());
}
static function X2DataTemplate CreateNotAtThrottlingPercentTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotAtThrottlingPercent');
	Template.IsConditionMetFn = NotAtThrottlingPercent;

	return Template;
}
static function bool NotAtThrottlingPercent()
{
	return !AtThrottlingPercent();
}
static function X2DataTemplate CreateInFlightModeTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_InFlightMode');
	Template.IsConditionMetFn = InFlightMode;

	return Template;
}
static function bool InFlightMode()
{
	return `HQPRES.StrategyMap2D.m_eUIState == eSMS_Flight;
}
static function X2DataTemplate CreateNotInFlightModeTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_NotInFlightMode');
	Template.IsConditionMetFn = NotInFlightMode;

	return Template;
}
static function bool NotInFlightMode()
{
	return !InFlightMode();
}

// #######################################################################################
// -------------------- PREVIEW BUILD ----------------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateEndPreviewPlaythroughTemplate()
{
	local X2AlienStrategyActionTemplate Template;

	Template = new class'X2AlienStrategyActionTemplate';
	Template.SetTemplateName('AlienAI_EndPreviewPlaythrough');
	Template.PerformActionFn = EndPreviewPlaythroughAction;

	// Conditions
	Template.Conditions.AddItem('AlienAICondition_PreviewBuildComplete');

	return Template;
}
static function EndPreviewPlaythroughAction()
{
	`GAME.GetGeoscape().Pause();
	`HQPRES.PreviewBuildComplete();
}

static function X2DataTemplate CreatePreviewBuildCompleteTemplate()
{
	local X2AlienStrategyConditionTemplate Template;

	Template = new class'X2AlienStrategyConditionTemplate';
	Template.SetTemplateName('AlienAICondition_PreviewBuildComplete');
	Template.IsConditionMetFn = PreviewBuildComplete;

	return Template;
}
static function bool PreviewBuildComplete()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	local TDateTime CurrentTime;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CurrentTime = class'XComGameState_GeoscapeEntity'.static.GetCurrentTime();

	return (AlienHQ.bPreviewBuild && 
			(CurrentTime.m_iMonth >= 6 || XComHQ.IsObjectiveCompleted('T2_M3_CompleteForgeMission') || XComHQ.IsObjectiveCompleted('T4_M1_CompleteStargateMission')));
}
