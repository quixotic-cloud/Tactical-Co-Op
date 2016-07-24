//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ActivateNarrative.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Implements a Kismet sequence action that can activate a specified NarrativeMoment
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_ActivateNarrative extends SequenceAction 
	implements(X2KismetSeqOpVisualizer)
	dependson(XGNarrative, XComTacticalMissionManager)
	native(Level);

var() int NarrativeIndex;
var() bool StopExistingNarrative;

private function XComNarrativeMoment LoadNarrativeMoment()
{
	local XComTacticalMissionManager MissionManager;
	local X2MissionNarrativeTemplateManager TemplateManager;
	local X2MissionNarrativeTemplate NarrativeTemplate;
	local string NarrativeMomentPath;
	local XComNarrativeMoment NarrativeMoment;

	MissionManager = `TACTICALMISSIONMGR;
	TemplateManager = class'X2MissionNarrativeTemplateManager'.static.GetMissionNarrativeTemplateManager();
	NarrativeTemplate = TemplateManager.FindMissionNarrativeTemplate(MissionManager.ActiveMission.sType, MissionManager.MissionQuestItemTemplate);

	if(NarrativeIndex < NarrativeTemplate.NarrativeMoments.Length)
	{
		NarrativeMomentPath = NarrativeTemplate.NarrativeMoments[NarrativeIndex];
		NarrativeMoment = XComNarrativeMoment(DynamicLoadObject(NarrativeMomentPath, class'XComNarrativeMoment'));
	}

	if(NarrativeMoment == none)
	{
		`log("SeqAct_ActivateNarrative: Narrative moment not found: " $ NarrativeMomentPath);
	}

	return NarrativeMoment;
}

event Activated()
{
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local X2Action_PlayNarrative Narrative;
	local VisualizationTrack BuildTrack;
	local XComGameState_KismetVariable KismetStateObject;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_KismetVariable', KismetStateObject)
	{
		break;
	}

	BuildTrack.StateObject_OldState = KismetStateObject;
	BuildTrack.StateObject_NewState = KismetStateObject;

	Narrative = X2Action_PlayNarrative( class'X2Action_PlayNarrative'.static.AddToVisualizationTrack( BuildTrack, GameState.GetContext() ) );

	Narrative.Moment = LoadNarrativeMoment();
	Narrative.WaitForCompletion = OutputLinks[1].Links.Length > 0;
	Narrative.StopExistingNarrative = StopExistingNarrative;

	VisualizationTracks.AddItem(BuildTrack);
}

function ModifyKismetGameState(out XComGameState GameState);

/**
 * Return the version number for this class.  Child classes should increment this method by calling Super then adding
 * a individual class version to the result.  When a class is first created, the number should be 0; each time one of the
 * link arrays is modified (VariableLinks, OutputLinks, InputLinks, etc.), the number that is added to the result of
 * Super.GetObjClassVersion() should be incremented by 1.
 *
 * @return	the version number for this specific class.
 */
static event int GetObjClassVersion()
{
	return Super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjCategory="Sound"
	ObjName="Narrative Moment - Activate"
	bCallHandler=false
	
	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int',LinkDesc="Narrative Index",PropertyName=NarrativeIndex)

	OutputLinks(1)=(LinkDesc="Completed")
}
