//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_ActivateNarrative.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Latent version of SeqAct_ActivateNarrative
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_ActivateNarrativeImmediate extends SequenceAction 
	dependson(XGNarrative);

var() XComNarrativeMoment NarrativeMoment;

event Activated()
{
	local XComPresentationLayerBase Presentation;

	if(NarrativeMoment != none)
	{
		Presentation = `PRESBASE;
		Presentation.UINarrative(NarrativeMoment);
	}
}

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
	ObjName="Narrative Moment - Latent Activate"
	bCallHandler=false
	
	bConvertedForReplaySystem=true

	VariableLinks.Empty

	OutputLinks(1)=(LinkDesc="Completed")
}
