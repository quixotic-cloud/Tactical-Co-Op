//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_PlayNarrative extends X2Action;


var XComNarrativeMoment Moment;
var bool WaitForCompletion;
var private bool WaitingForCompletion;
var bool StopExistingNarrative;
var delegate<NarrativeCompleteDelegate> NarrativeCompleteFn;
var bool bCallbackCalled;
var bool bEndOfMissionNarrative; //Permanently fade the camera to black, hide the UI. Use for end of mission narratives

delegate NarrativeCompleteDelegate();



simulated private function OnFinishedNarrative();

event bool BlocksAbilityActivation()
{
	return false;
}

function Init(const out VisualizationTrack InTrack)
{
	super.Init(InTrack);
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated private function OnFinishedNarrative()
	{
		if (NarrativeCompleteFn != none)
		{
			NarrativeCompleteFn();
			bCallbackCalled = true;
		}

		WaitingForCompletion = false;
	}

Begin:

	// Waiting for Completion must be set if we have a Narrative Completion delegate
	if (NarrativeCompleteFn != none)
	{
		WaitForCompletion = true;
	}

	if (Moment == none)
	{
		OnFinishedNarrative();
	}
	else
	{
		WaitingForCompletion = WaitForCompletion;

		if(bEndOfMissionNarrative)
		{
			`PRES.HUDHide();
			class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ClientSetCameraFade(true, MakeColor(0, 0, 0), vect2d(0, 1), 0.0);
		}

		if(StopExistingNarrative)
		{
			`PRES.m_kNarrativeUIMgr.ClearConversationQueueOfNonTentpoles();
		}
		
		`PRESBASE.UINarrative(Moment, , OnFinishedNarrative);
		
		while (WaitingForCompletion)
		{
			Sleep(0.1);
		}
	}

	CompleteAction();
}

function CompleteAction()
{
	if (NarrativeCompleteFn != none && !bCallbackCalled)
	{
		// Must have timed out before callback was called, so call it now
		NarrativeCompleteFn();
		bCallbackCalled = true;
	}

	super.CompleteAction();
}

function bool IsTimedOut()
{
	if(Moment != none && Moment.eType == eNarrMoment_UIOnly)
	{
		return false;
	}

	return super.IsTimedOut();
}

defaultproperties
{
	TimeoutSeconds = 30.0f
}

