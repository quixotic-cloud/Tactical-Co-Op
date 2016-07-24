//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_GetInteractiveObject.uc
//  AUTHOR:  David Burchanowski  --  4/14/2016
//  PURPOSE: Allows the LDs to get a reference to hand placed interactive objects
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_GetInteractiveObject extends SequenceAction;

var XComGameState_InteractiveObject ObjectState;
var string ObjectTag;

function Activated()
{
	local XComInteractiveLevelActor InteractiveActor;
	local name TagName;

	TagName = name(ObjectTag);
	foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'XComInteractiveLevelActor', InteractiveActor)
	{
		if(InteractiveActor.Tag == TagName)
		{
			ObjectState = XComGameState_InteractiveObject(`XCOMHISTORY.GetGameStateForObjectID(InteractiveActor.ObjectID));
			`assert(ObjectState != none);
			return;
		}
	}

	`Redscreen("SeqAct_GetInteractiveObject: no object found with tag: " $ ObjectTag $ ". Talk to an LD.");
	ObjectState = none; // return none if we don't find a match 
}

defaultproperties
{
	ObjCategory="Level"
	ObjName="Get Interactive Object"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	
	bAutoActivateOutputLinks=true
	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Object Tag",PropertyName=ObjectTag)
	VariableLinks(1)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="Object",PropertyName=ObjectState,bWriteable=true)
}
