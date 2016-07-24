//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Objective.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Objective extends XComGameState_BaseObject
	dependson(X2StrategyGameRulesetDataStructures) config(GameData);

var() protected name                   m_TemplateName;
var() protected X2ObjectiveTemplate    m_Template;

var StateObjectReference			   MainObjective; // Only applicable if this objective is a step or subobjective
var array<StateObjectReference>		   SubObjectives; // Only applicable if this objective is a main objective

var EObjectiveState					   ObjState;

// The list of availability windows active for this objective.
var array<NarrativeAvailabilityWindow> ActiveAvilabilityWindows;

// The list of all Narrative Moment path names that have already been played for this objective. (Used for bOnlyPlayOnce & narrative dependencies)
var array<string>			AlreadyPlayedNarratives;

// The time to next enable the nag window on this objective.
var() TDateTime NagTime;

var transient array<NarrativeTrigger> PendingNarrativeTriggers;

var bool bIsRevealed;

var config name TutorialStartMissionObjective;
var config name StartMissionObjective;
var config array<name> AlwaysStartObjectives;
var config name BeginnerVOObjective;
var config name BeginnerVONonTutorialObjective;

delegate bool NarrativeRequirementsMet();

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2ObjectiveTemplate GetMyTemplate()
{
	if(m_Template == none)
	{
		m_Template = X2ObjectiveTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
function OnCreation(X2ObjectiveTemplate Template)
{
	m_Template = Template;
	m_TemplateName = Template.DataName;
}

//---------------------------------------------------------------------------------------
static function SetUpObjectives(XComGameState StartState)
{
	local XComGameState_Objective ObjectiveState;
	local array<XComGameState_Objective> AllObjectives;
	local array<X2StrategyElementTemplate> ObjectiveDefs;
	local X2ObjectiveTemplate ObjectiveTemplate;
	local XComGameState_ObjectivesList ObjListState;
	local int idx, i, j;
	local XComGameState_CampaignSettings CampaignState;
	local XComGameStateHistory History;

	ObjectiveDefs = GetMyTemplateManager().GetAllTemplatesOfClass(class'X2ObjectiveTemplate');

	// First create and all objectives
	for(idx = 0; idx < ObjectiveDefs.Length; idx++)
	{
		ObjectiveState = X2ObjectiveTemplate(ObjectiveDefs[idx]).CreateInstanceFromTemplate(StartState);
		StartState.AddStateObject(ObjectiveState);
		AllObjectives.AddItem(ObjectiveState);
	}

	// Next fill out their main/subobjective data
	for(idx = 0; idx < AllObjectives.Length; idx++)
	{
		ObjectiveTemplate = AllObjectives[idx].GetMyTemplate();

		if(ObjectiveTemplate.bMainObjective)
		{
			for(i = 0; i < ObjectiveTemplate.Steps.Length; i++)
			{
				for(j = 0; j < AllObjectives.Length; j++)
				{
					if(AllObjectives[j].GetMyTemplateName() == ObjectiveTemplate.Steps[i])
					{
						AllObjectives[idx].SubObjectives.AddItem(AllObjectives[j].GetReference());
						AllObjectives[j].MainObjective = AllObjectives[idx].GetReference();
					}
				}
			}
		}
	}

	// Create the Objective List Object
	ObjListState = XComGameState_ObjectivesList(StartState.CreateStateObject(class'XComGameState_ObjectivesList'));
	StartState.AddStateObject(ObjListState);

	History = `XCOMHISTORY;
	CampaignState = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	if( CampaignState.bTutorialEnabled )
	{
		StartObjectiveByName(StartState, default.TutorialStartMissionObjective);
		StartObjectiveByName(StartState, default.BeginnerVOObjective);
	}
	else
	{
		StartObjectiveByName(StartState, default.StartMissionObjective);

		// Mark tutorial objectives as complete
		foreach StartState.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
		{
			if (ObjectiveState.GetMyTemplate().bTutorialOnly)
			{
				ObjectiveState.ObjState = eObjectiveState_Completed;
			}
			
			if(CampaignState.bSuppressFirstTimeNarrative)
			{
				if (ObjectiveState.GetMyTemplateName() == default.BeginnerVOObjective ||
					ObjectiveState.GetMyTemplateName() == default.BeginnerVONonTutorialObjective)
				{
					ObjectiveState.ObjState = eObjectiveState_Completed;
				}
			}
		}

		if (!CampaignState.bSuppressFirstTimeNarrative)
		{
			StartObjectiveByName(StartState, default.BeginnerVOObjective);
			StartObjectiveByName(StartState, default.BeginnerVONonTutorialObjective);
		}
	}

	for(idx = 0; idx < default.AlwaysStartObjectives.Length; idx++)
	{
		StartObjectiveByName(StartState, default.AlwaysStartObjectives[idx]);
	}
}

//#############################################################################################
//----------------   START/COMPLETE OBJECTIVES   ----------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function StartObjectiveByName(XComGameState NewGameState, Name ObjectiveName)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	foreach NewGameState.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.GetMyTemplateName() == ObjectiveName)
		{
			ObjectiveState.StartObjective(NewGameState);
			return;
		}
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.GetMyTemplateName() == ObjectiveName)
		{
			ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', ObjectiveState.ObjectID));
			NewGameState.AddStateObject(ObjectiveState);
			ObjectiveState.StartObjective(NewGameState);
			return;
		}
	}
}

//---------------------------------------------------------------------------------------
function StartObjective(XComGameState NewGameState, optional bool bForceStart=false)
{
	local XComGameState_Objective ObjectiveState;
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	// Only unstarted objectives can be started
	if(GetStateOfObjective() != eObjectiveState_NotStarted && !bForceStart)
	{
		return;
	}

	// do not start this objective if the prereqs have not yet been met
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	if( !XComHQ.MeetsAllStrategyRequirements(GetMyTemplate().AssignmentRequirements) && !bForceStart)
	{
		return;
	}

	if( GetMyTemplate().ObjectivePrereqsMetFn != None )
	{
		if( !m_Template.ObjectivePrereqsMetFn(NewGameState, self) && !bForceStart)
		{
			return;
		}
	}


	// Start this objective
	ObjState = eObjectiveState_InProgress;

	// call the special handler when this objective is assigned
	if( GetMyTemplate().AssignObjectiveFn != None )
	{
		m_Template.AssignObjectiveFn(NewGameState, self);
	}

	// enable narrative moments for assignment of this objective
	EnableNarrativeTriggerWindow(NAW_OnAssignment, XComHQ);

	EventManager = `XEVENTMGR;
	ThisObj = self;

	if( m_Template.CompletionEvent != '' )
	{
		EventManager.RegisterForEvent(ThisObj, m_Template.CompletionEvent, OnNarrativeEventTrigger, ELD_OnStateSubmitted, , , true);
	}

	if( m_Template.RevealEvent == '' )
	{
		RevealObjective(NewGameState);
	}
	else
	{
		EventManager.RegisterForEvent(ThisObj, m_Template.RevealEvent, OnNarrativeEventTrigger, ELD_OnStateSubmitted, , , true);
	}

	// Start the first subobjective, if any
	if( SubObjectives.Length > 0 )
	{
		ObjectiveState = XComGameState_Objective(NewGameState.GetGameStateForObjectID(SubObjectives[0].ObjectID));

		if(ObjectiveState == none)
		{
			ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', SubObjectives[0].ObjectID));
			NewGameState.AddStateObject(ObjectiveState);
		}

		ObjectiveState.StartObjective(NewGameState, bForceStart);

		if(bForceStart && !ObjectiveState.bIsRevealed)
		{
			ObjectiveState.RevealObjective(NewGameState);
		}
	}
}

function RevealObjective(XComGameState NewGameState)
{
	local bool bIsMainObjective;
	local ObjectiveDisplayInfo ObjDisplayInfo;
	local XComGameStateHistory History;
	local XComGameState_ObjectivesList ObjListState;
	local XComGameState_HeadquartersXCom XComHQ;

	// Only started objectives can be revealed
	if(GetStateOfObjective() != eObjectiveState_InProgress)
	{
		return;
	}

	if( !GetMyTemplate().bNeverShowObjective )
	{
		History = `XCOMHISTORY;

		foreach NewGameState.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
		{
			break;
		}

		if( ObjListState == None )
		{
			foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
			{
				break;
			}

			if(ObjListState != none)
			{
				ObjListState = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList', ObjListState.ObjectID));
				NewGameState.AddStateObject(ObjListState);
			}
			else
			{
				ObjListState = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList'));
				NewGameState.AddStateObject(ObjListState);
			}
		}

		bIsMainObjective = IsMainObjective();
		ObjDisplayInfo.ShowHeader = bIsMainObjective;
		ObjDisplayInfo.ShowCheckBox = !bIsMainObjective;
		ObjDisplayInfo.DisplayLabel = GetObjectiveString(NewGameState);
		ObjDisplayInfo.GroupID = ObjectID;

		// Never show Main objectives in tactical (all tactical objectives have checkbox)
		ObjDisplayInfo.HideInTactical = (bIsMainObjective || !m_Template.TacticalCompletion);

		ObjDisplayInfo.GPObjective = true;
		ObjDisplayInfo.ObjectiveTemplateName = GetMyTemplateName();
		ObjListState.SetObjectiveDisplay(ObjDisplayInfo);

		if(bIsMainObjective && m_Template.SubObjectiveText != "")
		{
			ObjDisplayInfo.ShowHeader = false;
			ObjDisplayInfo.ShowCheckBox = true;
			ObjDisplayInfo.DisplayLabel = m_Template.SubObjectiveText;
			ObjDisplayInfo.GroupID = ObjectID;
			ObjDisplayInfo.HideInTactical = !m_Template.TacticalCompletion;
			ObjDisplayInfo.GPObjective = true;
			ObjDisplayInfo.ObjectiveTemplateName = GetMyTemplateName();
			ObjListState.SetObjectiveDisplay(ObjDisplayInfo);
		}

		class'X2StrategyGameRulesetDataStructures'.static.UpdateObjectivesUI(NewGameState);
	}

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	EnableNarrativeTriggerWindow(NAW_OnReveal, XComHQ);

	SetNagTimer();

	bIsRevealed = true;
}


function SetNagTimer()
{
	if (`STRATEGYRULES != None)
	{
		class'X2StrategyGameRulesetDataStructures'.static.CopyDateTime(`STRATEGYRULES.GameTime, NagTime);
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(NagTime, GetMyTemplate().NagDelayHours);
	}
}

function bool CheckNagTimer()
{
	return (GetStateOfObjective() == eObjectiveState_InProgress &&
			GetMyTemplate().NagDelayHours > 0 &&
			ActiveAvilabilityWindows.Find(NAW_OnReveal) != INDEX_NONE &&
			ActiveAvilabilityWindows.Find(NAW_OnNag) == INDEX_NONE &&
			class'X2StrategyGameRulesetDataStructures'.static.LessThan(NagTime, `STRATEGYRULES.GameTime));
}

function BeginNagging(XComGameState_HeadquartersXCom XComHQ)
{
	EnableNarrativeTriggerWindow(NAW_OnNag, XComHQ);
}

function StopNagging()
{
	DisableNarrativeTriggerWindow(NAW_OnNag);
	SetNagTimer();
}

//---------------------------------------------------------------------------------------
function CheckObjectiveCompletion(XComGameState NewGameState)
{
	local bool ObjectiveComplete;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if( XComHQ.MeetsAllStrategyRequirements(GetMyTemplate().CompletionRequirements) )
	{
		if( m_Template.ObjectiveRequirementsMetFn != None )
		{
			ObjectiveComplete = m_Template.ObjectiveRequirementsMetFn(NewGameState, self);
		}
		else
		{
			ObjectiveComplete = AllSubObjectivesComplete(NewGameState);
		}

		if( ObjectiveComplete )
		{
			CompleteObjective(NewGameState);
		}
	}
}

static function CompleteObjectiveByName(XComGameState NewGameState, Name ObjectiveName)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	foreach NewGameState.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.GetMyTemplateName() == ObjectiveName)
		{
			ObjectiveState.CompleteObjective(NewGameState);
			return;
		}
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.GetMyTemplateName() == ObjectiveName)
		{
			ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', ObjectiveState.ObjectID));
			NewGameState.AddStateObject(ObjectiveState);
			ObjectiveState.CompleteObjective(NewGameState);
			return;
		}
	}
}

//---------------------------------------------------------------------------------------
function CompleteObjective(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;
	local XComGameState_ObjectivesList ObjListState;
	local ObjectiveDisplayInfo ObjDisplayInfo;
	local int idx;
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState_HeadquartersXCom XComHQ;

	// early out if the objective has already been completed
	if( ObjState == eObjectiveState_Completed )
	{
		return;
	}

	History = `XCOMHISTORY;
		ObjState = eObjectiveState_Completed;

	if( !GetMyTemplate().bNeverShowObjective )
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
		{
			break;
		}

		if( ObjListState == none )
		{
			foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjListState)
			{
				break;
			}

			if(ObjListState != none)
			{
				ObjListState = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList', ObjListState.ObjectID));
				NewGameState.AddStateObject(ObjListState);
			}
			else
			{
				ObjListState = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList'));
				NewGameState.AddStateObject(ObjListState);
			}
		}
	}

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	DisableNarrativeTriggerWindow(NAW_OnAssignment);
	DisableNarrativeTriggerWindow(NAW_OnReveal);
	DisableNarrativeTriggerWindow(NAW_OnNag);
	EnableNarrativeTriggerWindow(NAW_OnCompletion, XComHQ);

	// call the special handler when this objective completes
	if( m_Template.CompleteObjectiveFn != None )
	{
		m_Template.CompleteObjectiveFn(NewGameState, self);
	}

	if( IsMainObjective() )
	{
		// Complete all subobjectives
		for( idx = 0; idx < SubObjectives.Length; idx++ )
		{
			ObjectiveState = XComGameState_Objective(NewGameState.GetGameStateForObjectID(SubObjectives[idx].ObjectID));

			if( ObjectiveState == none )
			{
				ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', SubObjectives[idx].ObjectID));
				NewGameState.AddStateObject(ObjectiveState);
			}

			ObjectiveState.CompleteObjective(NewGameState);

			// all children objectives should be hidden when the main objective is completed
			if( !m_Template.bNeverShowObjective )
			{
				ObjListState.HideObjectiveDisplay("", ObjectiveState.GetObjectiveString(NewGameState));
			}
		}

		if( !m_Template.bNeverShowObjective )
		{
			ObjListState.HideObjectiveDisplay("", GetObjectiveString(NewGameState));

			if(m_Template.SubObjectiveText != "")
			{
				ObjListState.HideObjectiveDisplay("", m_Template.SubObjectiveText);
			}

			class'X2StrategyGameRulesetDataStructures'.static.UpdateObjectivesUI(NewGameState);
		}
	}
	else
	{
		if( !m_Template.bNeverShowObjective &&
			ObjListState.GetObjectiveDisplay("", GetObjectiveString(NewGameSTate), ObjDisplayInfo) )
		{
			ObjDisplayInfo.ShowCompleted = true;
			ObjListState.SetObjectiveDisplay(ObjDisplayInfo);

			class'X2StrategyGameRulesetDataStructures'.static.UpdateObjectivesUI(NewGameState);
		}

		// Check if main objective is complete
		ObjectiveState = XComGameState_Objective(NewGameState.GetGameStateForObjectID(MainObjective.ObjectID));

		// if the parent objective already exists in this game state, that means its completion state has already been checked
		if( ObjectiveState == None )
		{
			ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', MainObjective.ObjectID));
			NewGameState.AddStateObject(ObjectiveState);
			ObjectiveState.CheckObjectiveCompletion(NewGameState);

			// the objective state will only have changed if it is now marked as completed
			if( ObjectiveState.GetStateOfObjective() != eObjectiveState_Completed )
			{
				NewGameState.PurgeGameStateForObjectID(MainObjective.ObjectID);
			}
		}
	}
	
	if( m_Template.NextObjectives.Length > 0 )
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;

		EventManager.RegisterForEvent(ThisObj, 'ObjectiveCompleted', OnObjectiveCompleted, ELD_OnStateSubmitted, , ThisObj, true);
		EventManager.TriggerEvent('ObjectiveCompleted', ThisObj, ThisObj, NewGameState);
	}
}

function EventListenerReturn OnObjectiveCompleted(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local Name NextObjective;
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState NewGameState;

	foreach m_Template.NextObjectives(NextObjective)
	{
		if( NextObjective != '' )
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Start The Next Objective");
			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForNarrative;

			StartObjectiveByName(NewGameState, NextObjective);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.UnRegisterFromEvent(ThisObj, 'ObjectiveCompleted');

	return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------------------
function bool AllSubObjectivesComplete(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < SubObjectives.Length; idx++)
	{
		ObjectiveState = XComGameState_Objective(NewGameState.GetGameStateForObjectID(SubObjectives[idx].ObjectID));

		if(ObjectiveState == none)
		{
			ObjectiveState = XComGameState_Objective(History.GetGameStateForObjectID(SubObjectives[idx].ObjectID));
		}

		if(ObjectiveState.GetStateOfObjective() != eObjectiveState_Completed)
		{
			return false;
		}
	}

	return true;
}

//#############################################################################################
//----------------   HELPER FUNCTIONS   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool IsMainObjective()
{
	return GetMyTemplate().bMainObjective;
}

//---------------------------------------------------------------------------------------
function bool IsSubObjective()
{
	return !GetMyTemplate().bMainObjective;
}

//---------------------------------------------------------------------------------------
function XComGameState_Objective GetMainObjective()
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	History = `XCOMHISTORY;

	if(IsMainObjective())
	{
		return self;
	}
	else
	{
		ObjectiveState = XComGameState_Objective(History.GetGameStateForObjectID(MainObjective.ObjectID));

		if(ObjectiveState != none)
		{
			return ObjectiveState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Objective> GetSubObjectives()
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;
	local array<XComGameState_Objective> SubObjectiveStates;
	local int idx;

	History = `XCOMHISTORY;
	SubObjectiveStates.Length = 0;

	if(IsMainObjective())
	{
		for(idx = 0; idx < SubObjectives.Length; idx++)
		{
			ObjectiveState = XComGameState_Objective(History.GetGameStateForObjectID(SubObjectives[idx].ObjectID));

			if(ObjectiveState != none)
			{
				SubObjectiveStates.AddItem(ObjectiveState);
			}
		}
	}

	return SubObjectiveStates;
}

//---------------------------------------------------------------------------------------
function EObjectiveState GetStateOfObjective()
{
	return ObjState;
}

//---------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------

function bool TriggerNarrativeMoment(const out NarrativeTrigger EventTrigger, out XComGameState_HeadquartersXCom XComHQ)
{
	local string NarrativeMomentPathName;

	if( EventTrigger.NarrativeMoment != None )
	{
		NarrativeMomentPathName = PathName(EventTrigger.NarrativeMoment);

		if (EventTrigger.PlayCount == NPC_OncePerTacticalMission && XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.Find(NarrativeMomentPathName) == INDEX_NONE)
		{
			XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.AddItem(NarrativeMomentPathName);
		}
		else if(AlreadyPlayedNarratives.Find(NarrativeMomentPathName) == INDEX_NONE)
		{
			AlreadyPlayedNarratives.AddItem(NarrativeMomentPathName);
		}
		else if (EventTrigger.PlayCount != NPC_Multiple)
		{
			// already played this "play once" moment
			return false;
		}
	}

	PendingNarrativeTriggers.AddItem(EventTrigger);

	// whenever a nag is played, we should disable the nag window
	if( EventTrigger.AvailabilityWindow == NAW_OnNag )
	{
		StopNagging();
	}

	return true;
}

function ApplyPendingNarrativeTriggers()
{
	local XComPresentationLayerBase PresBase;
	local delegate<X2StrategyGameRulesetDataStructures.NarrativeCompleteDelegate> LocalNarrativeCompleteFn;
	local int Index;

	PresBase = XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres;

	for( Index = 0; Index < PendingNarrativeTriggers.Length; ++Index )
	{
		if( PendingNarrativeTriggers[Index].NarrativeMoment != None )
		{
			PresBase.UINarrative(PendingNarrativeTriggers[Index].NarrativeMoment, , PendingNarrativeTriggers[Index].NarrativeCompleteFn);
		}
		else
		{
			// no narrative moment, just call the completion function
			LocalNarrativeCompleteFn = PendingNarrativeTriggers[Index].NarrativeCompleteFn;
			if( LocalNarrativeCompleteFn != None )
			{
				LocalNarrativeCompleteFn();
			}
		}
	}

	PendingNarrativeTriggers.Remove(0, PendingNarrativeTriggers.Length);
}

//---------------------------------------------------------------------------------------

function EnableNarrativeTriggerWindow(NarrativeAvailabilityWindow AvailabityWindow, out XComGameState_HeadquartersXCom XComHQ)
{
	local X2ObjectiveTemplate TheTemplate;
	local NarrativeTrigger EventTrigger;
	local X2EventManager EventManager;
	local Object ThisObj;

	// early out if this window is already active
	if( ActiveAvilabilityWindows.Find(AvailabityWindow) != INDEX_NONE )
	{
		return;
	}

	TheTemplate = GetMyTemplate();
	EventManager = `XEVENTMGR;
	ThisObj = self;

	foreach TheTemplate.NarrativeTriggers(EventTrigger)
	{
		if( EventTrigger.AvailabilityWindow == AvailabityWindow )
		{
			// narrative moments without a specific triggering event need to be triggered immediately when the window is enabled
			if( EventTrigger.TriggeringEvent == '' )
			{
				TriggerNarrativeMoment(EventTrigger, XComHQ);
			}
			// narrative moments in this window with a specific triggering event can now register for those events
			else
			{
				EventManager.RegisterForEvent(ThisObj, EventTrigger.TriggeringEvent, OnNarrativeEventTrigger, EventTrigger.EventDeferral, , , true);
			}
		}
	}

	ActiveAvilabilityWindows.AddItem(AvailabityWindow);
}

function DisableNarrativeTriggerWindow(NarrativeAvailabilityWindow AvailabityWindow)
{
	local X2ObjectiveTemplate TheTemplate;
	local int NarrativeIndex;
	local array<Name> EventKillList;
	local Name TestEvent;
	local NarrativeAvailabilityWindow TestWindow;

	// early out if this window is not already active
	if( ActiveAvilabilityWindows.Find(AvailabityWindow) == INDEX_NONE )
	{
		return;
	}

	ActiveAvilabilityWindows.RemoveItem(AvailabityWindow);

	TheTemplate = GetMyTemplate();

	for( NarrativeIndex = 0; NarrativeIndex < TheTemplate.NarrativeTriggers.Length; ++NarrativeIndex )
	{
		TestEvent = TheTemplate.NarrativeTriggers[NarrativeIndex].TriggeringEvent;
		if( TestEvent != '' )
		{
			TestWindow = TheTemplate.NarrativeTriggers[NarrativeIndex].AvailabilityWindow;

			// events in the disabled window may need to be cleaned up, if nothing else is listening for them
			if( TestWindow == AvailabityWindow )
			{
				if( EventKillList.Find(TestEvent) == INDEX_NONE )
				{
					EventKillList.AddItem(TestEvent);
				}
			}
		}
	}

	UnRegisterFromEvents(EventKillList);
}

function UnRegisterFromEvents(out array<Name> EventKillList)
{
	local array<Name> EventKeepList;
	local Name TestEvent;
	local X2EventManager EventManager;
	local Object ThisObj;

	GetCurrentEventKeepList(EventKeepList);

	foreach EventKeepList(TestEvent)
	{
		EventKillList.RemoveItem(TestEvent);
	}

	EventManager = `XEVENTMGR;
	ThisObj = self;

	foreach EventKillList(TestEvent)
	{
		EventManager.UnRegisterFromEvent(ThisObj, TestEvent);
	}
}

function GetCurrentEventKeepList(out array<Name> EventKeepList)
{
	local X2ObjectiveTemplate TheTemplate;
	local NarrativeTrigger EventTrigger;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	TheTemplate = GetMyTemplate();

	foreach TheTemplate.NarrativeTriggers(EventTrigger)
	{
		if (IsNarrativeTriggerActive(EventTrigger, XComHQ))
		{
			// the event doesn't already exist in the keep list
			if( EventKeepList.Find(EventTrigger.TriggeringEvent) == INDEX_NONE )
			{
				EventKeepList.AddItem(EventTrigger.TriggeringEvent);
			}
		}
	}

	// todo: may need to manually exempt the events used to trigger the windows, if any are done through the event manager
}

function bool IsNarrativeTriggerActive(const out NarrativeTrigger EventTrigger, XComGameState_HeadquartersXCom XComHQ, optional Name EventID, optional Name TriggeringTemplateName)
{
	local delegate<NarrativeRequirementsMet> ReqMetFn;

	// no triggering event
	if( EventTrigger.TriggeringEvent == '' )
	{
		return false;
	}

	// the triggering event does not match the specified event
	if( EventID != '' && EventTrigger.TriggeringEvent != EventID )
	{
		return false;
	}

	// Specific Template associated with this event trigger does not match the passed in template name
	if( EventTrigger.TriggeringTemplateName != '' && TriggeringTemplateName != '' && EventTrigger.TriggeringTemplateName != TriggeringTemplateName )
	{
		return false;
	}

	// the narrative moment's trigger window is not active
	if( ActiveAvilabilityWindows.Find(EventTrigger.AvailabilityWindow) == INDEX_NONE )
	{
		return false;
	}

	// the narrative moment should only play once and has already been played once
	if (EventTrigger.PlayCount == NPC_Once && AlreadyPlayedNarratives.Find(PathName(EventTrigger.NarrativeMoment)) != INDEX_NONE)
	{
		return false;
	}

	if (EventTrigger.PlayCount == NPC_OncePerTacticalMission && XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.Find(PathName(EventTrigger.NarrativeMoment)) != INDEX_NONE)
	{
		return false;
	}

	if (EventTrigger.NarrativeRequirementsMetFn != none)
	{
		ReqMetFn = EventTrigger.NarrativeRequirementsMetFn;
		if (!ReqMetFn())
		{
			return false;
		}
	}

	return true;
}

static function BuildVisualizationForNarrative(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks)
{
	local VisualizationTrack BuildTrack;
	local X2Action_PlayNarrative NarrativeAction;
	local XComGameState_Objective ObjectiveState;
	local int i;

	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		for (i = 0; i < ObjectiveState.PendingNarrativeTriggers.Length; i++)
		{
			NarrativeAction = X2Action_PlayNarrative(class'X2Action_PlayNarrative'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
			NarrativeAction.Moment = ObjectiveState.PendingNarrativeTriggers[i].NarrativeMoment;
			NarrativeAction.NarrativeCompleteFn = ObjectiveState.PendingNarrativeTriggers[i].NarrativeCompleteFn;
			NarrativeAction.WaitForCompletion = ObjectiveState.PendingNarrativeTriggers[i].bWaitForCompletion;

			BuildTrack.StateObject_OldState = ObjectiveState;
			BuildTrack.StateObject_NewState = ObjectiveState;
			OutVisualizationTracks.AddItem(BuildTrack);
		}
	}

}

function EventListenerReturn OnNarrativeEventTrigger(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local X2ObjectiveTemplate TheTemplate;
	local NarrativeTrigger EventTrigger;
	local XComGameState NewGameState;
	local XComGameState_Objective ObjectiveState;
	local XComGameState_HeadquartersXCom XComHQ;
	local bool AnyNarrativeUpdateMade, AnyPlayMultipleNarrativeMoments;
	local bool AnyObjectiveStateModified;
	local Name TriggeringTemplateName;
	local array<Name> AlreadySelectedDecks;
	local X2CardManager CardManager;
	local string SelectedNarrativeMomentPath;
	local array<Name> EventKillList;
	local XComGameStateHistory History;

	TheTemplate = GetMyTemplate();

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Objective Narrative Moment");
	XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = BuildVisualizationForNarrative;
	ObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', ObjectID));
	NewGameState.AddStateObject(ObjectiveState);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	// if this is the completion event, attempt to complete this objective
	if( TheTemplate.CompletionEvent == EventID )
	{
		AnyObjectiveStateModified = true;
		ObjectiveState.CheckObjectiveCompletion(NewGameState);
	}

	// if this is the reveal event, perform the reveal on this objective
	if( TheTemplate.RevealEvent == EventID )
	{
		AnyObjectiveStateModified = true;
		ObjectiveState.RevealObjective(NewGameState);
	}

	AnyNarrativeUpdateMade = false;
	AnyPlayMultipleNarrativeMoments = false;
	if( EventData != None && EventData.IsA('XComGameState_BaseObject') )
	{
		TriggeringTemplateName = XComGameState_BaseObject(EventData).GetMyTemplateName();
	}

	foreach TheTemplate.NarrativeTriggers(EventTrigger)
	{
		// check if the specified narrative trigger is primed for this event to be fired
		if (IsNarrativeTriggerActive(EventTrigger, XComHQ, EventID, TriggeringTemplateName))
		{
			if( EventTrigger.NarrativeDeck != '' )
			{
				if (XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.Find(string(EventTrigger.NarrativeDeck)) != INDEX_NONE ||
					AlreadySelectedDecks.Find(EventTrigger.NarrativeDeck) != INDEX_NONE)
				{
					continue;
				}

				// choose one active trigger from this deck
				CardManager = class'X2CardManager'.static.GetCardManager();
				CardManager.SelectNextCardFromDeck(EventTrigger.NarrativeDeck, SelectedNarrativeMomentPath);

				// play the chosen event trigger
				GetNarrativeTrigger(SelectedNarrativeMomentPath, EventTrigger);

				if (EventTrigger.PlayCount == NPC_Once || EventTrigger.PlayCount == NPC_OncePerTacticalMission )
				{
					// Add the deck rather than the narrative moment itself
					XComHQ.PlayedTacticalNarrativeMomentsCurrentMapOnly.AddItem(string(EventTrigger.NarrativeDeck));

					CardManager.RemoveCardFromDeck(EventTrigger.NarrativeDeck, SelectedNarrativeMomentPath);
				}
				else
				{
					// these narrative moments can be played multiple times, but mark the deck used so we don't pull every card from the deck
					AlreadySelectedDecks.AddItem(EventTrigger.NarrativeDeck);
				}
			}

			// trigger the narrative moment
			AnyNarrativeUpdateMade = AnyNarrativeUpdateMade || ObjectiveState.TriggerNarrativeMoment(EventTrigger, XComHQ);

			// update whether or not any of the narratives that are playing from this event can be played multiple times
			AnyPlayMultipleNarrativeMoments = 
				AnyPlayMultipleNarrativeMoments || 
				EventTrigger.PlayCount != NPC_Once || 
				EventTrigger.NarrativeDeck != '';
		}
	}

	if( AnyNarrativeUpdateMade && !AnyPlayMultipleNarrativeMoments && EventID != TheTemplate.CompletionEvent )
	{
		// if the are no remaining dependencies on this event, we can unregister from it
		EventKillList.AddItem(EventID);
		ObjectiveState.UnRegisterFromEvents(EventKillList);
	}

	if(!AnyNarrativeUpdateMade && !AnyObjectiveStateModified)//Nothing happened, clean up the game state and don't submit it
	{
		History.CleanupPendingGameState(NewGameState); 
	}
	else
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function GetNarrativeTrigger(string SelectedNarrativeMomentPath, out NarrativeTrigger OutNarrativeTrigger)
{
	local int Index;
	local X2ObjectiveTemplate TheTemplate;

	TheTemplate = GetMyTemplate();
	for( Index = 0; Index < TheTemplate.NarrativeTriggers.Length; ++Index )
	{
		if( PathName(TheTemplate.NarrativeTriggers[Index].NarrativeMoment) == SelectedNarrativeMomentPath )
		{
			OutNarrativeTrigger = TheTemplate.NarrativeTriggers[Index];
		}
	}
}


function string GetImage()
{
	// TODO: use a default if the image is undefined.
	return m_Template.ImagePath;
}

function string GetObjectiveString(optional XComGameState NewGameState)
{
	if(GetMyTemplate().GetDisplayStringFn != none)
	{
		return GetMyTemplate().GetDisplayStringFn(NewGameState, self);
	}
	else
	{
		return GetMyTemplate().Title;
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bIsRevealed = false; 
}