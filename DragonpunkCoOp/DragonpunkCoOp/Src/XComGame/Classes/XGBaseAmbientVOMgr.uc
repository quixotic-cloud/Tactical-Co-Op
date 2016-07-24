class XGBaseAmbientVOMgr extends Actor 
	config(GameCore);

struct TimedMusingInfo
{
	var float InitialDelay;          // in seconds
	var float TimeBetween;           // in seconds
	var array<XComNarrativeMoment> Narratives;
};

struct NeedsAttentionInfo
{
	var float InitialDelay;          // in seconds
	var float TimeBetween;           // in seconds
	var array<StateObjectReference> NeedsAttention;
};

struct EventMusingInfo
{
	var float TimeBetween;           // in seconds
	var float LastEvent;
	var array<XComNarrativeMoment> Narratives;
};

var private config TimedMusingInfo AmbientMusings;
var private config NeedsAttentionInfo NeedsAttentionCallouts;
var private config EventMusingInfo TyganMusings;
var private config EventMusingInfo ShenMusings;
var private float NextAmbientTime;                        // time in world seconds when next event should happen. this is used to block general ambient VO from playing too close to tygan/shen VO

var private bool AmbientActive;
var private bool NeedsAttentionActive;
var private XComHQPresentationLayer HQPresLayer;
var private X2AmbientNarrativeCriteriaTemplateManager AmbientCriteriaMgr;
var private XComNarrativeMoment ActiveMusing;

function Init()
{
	local XComHeadquartersCamera HQCamera;
	HQCamera = XComHeadquartersCamera(XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).PlayerController.PlayerCamera);

	AmbientCriteriaMgr = class'X2AmbientNarrativeCriteriaTemplateManager'.static.GetAmbientNarrativeCriteriaTemplateManager();

	HQPresLayer = `HQPRES;
	AmbientActive = false;

	//Don't disable 
	HQCamera.EnteringRoomView = EnableAmbientVO;
	HQCamera.EnteringGeoscapeView = DisableAllAmbientVO;
	HQCamera.EnteringFacilityView = DisableMusingAmbientVO;

	BuildAmbientNarrativeList();

	TyganMusings.LastEvent = WorldInfo.TimeSeconds - TyganMusings.TimeBetween;
	ShenMusings.LastEvent = WorldInfo.TimeSeconds - ShenMusings.TimeBetween;
	NextAmbientTime = 0;
}

private function BuildAmbientNarrativeList()
{
	local XComNarrativeMoment Moment;

	foreach HQPresLayer.m_kNarrative.m_arrNarrativeMoments(Moment)
	{
		if (Moment.AmbientCriteriaTypeName != '' && Moment.arrConversations.Length > 0)
		{
			if (Moment.AmbientSpeaker == 'HeadScientist')
			{
				TyganMusings.Narratives.AddItem(Moment);
			}
			else if (Moment.AmbientSpeaker == 'HeadEngineer')
			{
				ShenMusings.Narratives.AddItem(Moment);
			}
			else
			{
				AmbientMusings.Narratives.AddItem(Moment);
			}
		}
	}
}

private function EnableAmbientVO()
{
	if (!NeedsAttentionActive)
	{
		NeedsAttentionActive  = true;
		if (NeedsAttentionCallouts.NeedsAttention.Length > 0)
		{
			SetTimer(NeedsAttentionCallouts.InitialDelay, true, 'OnNeedsAttentionVO');
		}
	}

	if (!AmbientActive)
	{
		AmbientActive = true;
		SetTimerForNextAmbientEvent();
	}
}


// Only use at beginning of tutorial
function TutorialEnableNeedsAttentionVO()
{
	if(!NeedsAttentionActive)
	{
		NeedsAttentionActive = true;
		if(NeedsAttentionCallouts.NeedsAttention.Length > 0)
		{
			SetTimer(NeedsAttentionCallouts.InitialDelay, true, 'OnNeedsAttentionVO');
		}
	}
}

private function DisableAllAmbientVO()
{
	if (NeedsAttentionActive)
	{
		NeedsAttentionActive = false;
		ClearTimer('OnNeedsAttentionVO');
	}
	
	// If there is a musing playing, stop it when entering the Geoscape
	if (ActiveMusing != none)
	{
		HQPresLayer.m_kNarrativeUIMgr.StopNarrative(ActiveMusing);
	}

	DisableMusingAmbientVO();
}

private function DisableMusingAmbientVO()
{
	if (AmbientActive)
	{
		AmbientActive = false;
		ClearTimer('OnAmbientVOCheck');
	}
}

private function SetTimerForNextAmbientEvent(optional bool bUseInitialDelay = false)
{
	local float NextTime;

	// if its the first time or its been longer then the normal time between ambient VOs so restart with the initial delay
	if (NextAmbientTime == 0 || bUseInitialDelay || WorldInfo.TimeSeconds >= NextAmbientTime)
	{
		NextTime = AmbientMusings.InitialDelay;
	}
	else
	{
		NextTime = NextAmbientTime - WorldInfo.TimeSeconds;
	}

	SetTimer(NextTime, false, 'OnAmbientVOCheck');	
}

private function OnAmbientVOCheck()
{
	local XComNarrativeMoment Moment;
	local bool RetriggerAfterShortDelay;

	RetriggerAfterShortDelay = false;

	if (`XPROFILESETTINGS.Data.m_bAmbientVO && 
		!class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress() &&
		!HQPresLayer.m_kNarrativeUIMgr.bPaused)
	{
		if (WorldInfo.TimeSeconds >= NextAmbientTime && !HQPresLayer.m_kNarrativeUIMgr.AnyActiveConversations())
		{
			// if a non-ambient musing VO hasn't been played recently then pick a musing and play it, otherwise trigger a wait for the standard initial delay
			if (WorldInfo.TimeSeconds > HQPresLayer.m_kNarrativeUIMgr.GetLastVOTime() + AmbientMusings.InitialDelay)
			{
				Moment = ChooseNarrativeMoment(AmbientMusings.Narratives);
				if (Moment != none)
				{
					PlayNarrativeMoment(Moment);
				}
			}
			else
			{
				RetriggerAfterShortDelay = true;
			}
		}
	}

	UpdateNextAmbientTime();

	SetTimerForNextAmbientEvent(RetriggerAfterShortDelay);
}


private function UpdateNeedsAttentionFromStates()
{
	local XComGameState_FacilityXCom FacilityState;
	local StateObjectReference FacilityRef;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach XComHQ.Facilities(FacilityRef)
	{
		if (FacilityRef.ObjectID != 0)
		{
			FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
			if (FacilityState.NeedsAttention())
			{
				TriggerNeedAttentionVO(FacilityRef, false);
			}
			else
			{
				if ((NeedsAttentionCallouts.NeedsAttention.Find('ObjectID', FacilityRef.ObjectID) != INDEX_NONE))
				{
					// newly NOT in need of attention
					ClearNeedAttentionVO(FacilityRef);
				}
			}
		}
	}
}

private function bool PlayAppropriateNeedsAttentionVO()
{
	local XComNarrativeMoment AttentionNarrative;
	local XComGameState_FacilityXCom FacilityState;
	local StateObjectReference FacilityRef;
	local UIScreen TopScreen;
	local UIFacility FacilityScreen;
	
	TopScreen = HQPresLayer.ScreenStack.GetCurrentScreen();
	FacilityScreen = UIFacility(TopScreen);

	if (!HQPresLayer.m_kNarrativeUIMgr.bPaused &&
		!HQPresLayer.m_kNarrativeUIMgr.AnyActiveConversations())
	{
		if (FacilityScreen != none || UIFacilityGrid(TopScreen) != none)
		{
			foreach NeedsAttentionCallouts.NeedsAttention(FacilityRef)
			{
				FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
				AttentionNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityState.GetMyTemplate().NeedsAttentionNarrative));

				if (AttentionNarrative != none)
				{
					// if a non-ambient musing VO hasn't been played recently then and we aren't in the facility associated with this reminder then play the narrative
					if (WorldInfo.TimeSeconds >= HQPresLayer.m_kNarrativeUIMgr.GetLastVOTime() + NeedsAttentionCallouts.InitialDelay && 
					   (FacilityScreen == none || FacilityScreen.FacilityRef.ObjectID != FacilityRef.ObjectID))
					{
						if (AttentionNarrative.LastAmbientPlayTime == 0)
						{
							// first time playing newly added in need of attention callout
							PlayNarrativeMoment(AttentionNarrative);

							NeedsAttentionCallouts.NeedsAttention.RemoveItem(FacilityRef);
							NeedsAttentionCallouts.NeedsAttention.AddItem(FacilityRef);
							return true;
						}
						else if (WorldInfo.TimeSeconds >= (AttentionNarrative.LastAmbientPlayTime + NeedsAttentionCallouts.TimeBetween))
						{
							// repeat playing in need of attention callout NeedsAttentionCallouts.TimeBetween seconds later (give or take depending on other narrative moments playing)
							PlayNarrativeMoment(AttentionNarrative);

							NeedsAttentionCallouts.NeedsAttention.RemoveItem(FacilityRef);
							NeedsAttentionCallouts.NeedsAttention.AddItem(FacilityRef);
							return true;
						}
					}
				}
			}
		}
	}

	return false;
}

private function UpdateLastPlayedTimeForNeedsAttention()
{
	local XComNarrativeMoment AttentionNarrative;
	local XComGameState_FacilityXCom FacilityState;
	local StateObjectReference FacilityRef;
	
	foreach NeedsAttentionCallouts.NeedsAttention(FacilityRef)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
		AttentionNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityState.GetMyTemplate().NeedsAttentionNarrative));

		if (AttentionNarrative != none)
		{
			AttentionNarrative.LastAmbientPlayTime = WorldInfo.TimeSeconds;
		}
	}
}

private function OnNeedsAttentionVO()
{
	UpdateNeedsAttentionFromStates();

	if (NeedsAttentionCallouts.NeedsAttention.Length == 0)
		return;



	if (!NeedsAttentionActive)
		return;

	if (PlayAppropriateNeedsAttentionVO())
	{
		UpdateLastPlayedTimeForNeedsAttention();
	}
}

private function UpdateNextAmbientTime()
{
	NextAmbientTime = WorldInfo.TimeSeconds + AmbientMusings.TimeBetween;
}

function ClearNeedAttentionVO(StateObjectReference FacilityRef)
{
	NeedsAttentionCallouts.NeedsAttention.RemoveItem(FacilityRef);
}

function TriggerNeedAttentionVO(StateObjectReference FacilityRef, optional bool bImmediate)
{
	local XComNarrativeMoment AttentionNarrative;
	local XComGameState_FacilityXCom FacilityState;

	if (bImmediate)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
		AttentionNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityState.GetMyTemplate().NeedsAttentionNarrative));

		if(AttentionNarrative != none)
		{
			AttentionNarrative.LastAmbientPlayTime = 0;
		}

		NeedsAttentionCallouts.NeedsAttention.RemoveItem(FacilityRef);
		NeedsAttentionCallouts.NeedsAttention.InsertItem(0, FacilityRef);
	}
	else
	{
		if (NeedsAttentionCallouts.NeedsAttention.Find('ObjectID', FacilityRef.ObjectID) == INDEX_NONE)
		{
			NeedsAttentionCallouts.NeedsAttention.AddItem(FacilityRef);
		}
	}
}

function TriggerTyganVOEvent()
{
	local XComNarrativeMoment Moment;

	if (`XPROFILESETTINGS.Data.m_bAmbientVO && !class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress())
	{
		if (WorldInfo.TimeSeconds - TyganMusings.LastEvent > TyganMusings.TimeBetween && !HQPresLayer.m_kNarrativeUIMgr.AnyActiveConversations())
		{
			Moment = ChooseNarrativeMoment(TyganMusings.Narratives);
			if (Moment != none)
			{
				PlayNarrativeMoment(Moment);
				//UpdateNextAmbientTime();

				TyganMusings.LastEvent = WorldInfo.TimeSeconds;
			}
		}
	}
}

function TriggerShenVOEvent()
{
	local XComNarrativeMoment Moment;

	if (`XPROFILESETTINGS.Data.m_bAmbientVO && !class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress())
	{
		if (WorldInfo.TimeSeconds - ShenMusings.LastEvent > ShenMusings.TimeBetween && !HQPresLayer.m_kNarrativeUIMgr.AnyActiveConversations())
		{
			Moment = ChooseNarrativeMoment(ShenMusings.Narratives);
			if (Moment != none)
			{
				PlayNarrativeMoment(Moment);
				//UpdateNextAmbientTime();

				ShenMusings.LastEvent = WorldInfo.TimeSeconds;
			}
		}
	}
}

private function XComNarrativeMoment ChooseNarrativeMoment(out array<XComNarrativeMoment> Narratives)
{
	local XComNarrativeMoment Moment;
	local array<XComNarrativeMoment> BestMoments;
	local X2AmbientNarrativeCriteriaTemplate Criteria, BlockingCriteria;
	local float CurrentBestPriority;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local int NarrativeInfoIdx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ == none)
		return none;

	foreach Narratives(Moment)
	{
		if (Moment.AmbientMaxPlayCount > 0)
		{
			NarrativeInfoIdx = XComHQ.PlayedAmbientNarrativeMoments.Find('QualifiedName', PathName(Moment));
			if (NarrativeInfoIdx != -1 && XComHQ.PlayedAmbientNarrativeMoments[NarrativeInfoIdx].PlayCount >= Moment.AmbientMaxPlayCount)
				continue;
		}

		Criteria = AmbientCriteriaMgr.FindAmbientCriteriaTemplate(Moment.AmbientCriteriaTypeName);
		BlockingCriteria = AmbientCriteriaMgr.FindAmbientCriteriaTemplate(Moment.AmbientBlockingTypeName);
		
		if (Criteria != none && Criteria.IsAmbientPlayCriteriaMet(Moment))
		{
			if (BlockingCriteria == none || !BlockingCriteria.IsAmbientPlayCriteriaMet(Moment))
			{
				if (Moment.AmbientPriority == CurrentBestPriority)
				{
					BestMoments.AddItem(Moment);
				}
				else if (Moment.AmbientPriority > CurrentBestPriority)
				{
					BestMoments.Length = 0;
					CurrentBestPriority = Moment.AmbientPriority;
					BestMoments.AddItem(Moment);
				}
			}
		}
	}

	if (BestMoments.Length == 0)
		return none;

	return BestMoments[Rand(BestMoments.Length)];
}

private function UpdatePlayedAmbientNarrativeList(out XComGameState_HeadquartersXCom XComHQ, XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;
	local AmbientNarrativeInfo NarrativeInfo;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = XComHQ.PlayedAmbientNarrativeMoments.Find('QualifiedName', QualifiedName);
	if (NarrativeInfoIdx != -1)
	{
		NarrativeInfo = XComHQ.PlayedAmbientNarrativeMoments[NarrativeInfoIdx];
		`assert(NarrativeInfo.QualifiedName == QualifiedName);
		NarrativeInfo.PlayCount++;
		XComHQ.PlayedAmbientNarrativeMoments[NarrativeInfoIdx] = NarrativeInfo;
	}
	else
	{
		NarrativeInfo.QualifiedName = QualifiedName;
		NarrativeInfo.PlayCount = 1;
		XComHQ.PlayedAmbientNarrativeMoments.AddItem(NarrativeInfo);
	}
}

private function PlayNarrativeMoment(XComNarrativeMoment Moment)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	History = `XCOMHISTORY;
		
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Update Played VO");
	NewGameState = History.CreateNewGameState(true, ChangeContainer);
	
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	
	`assert(XComHQ != none);

	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	HQPresLayer.UINarrative(Moment);
	ActiveMusing = Moment;

	Moment.LastAmbientPlayTime = WorldInfo.TimeSeconds;

	UpdatePlayedAmbientNarrativeList(XComHQ, Moment);

	`GAMERULES.SubmitGameState(NewGameState);
}

defaultproperties
{
	AmbientActive = false
	NeedsAttentionActive = false
}