//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    SeqAct_ShowTutorialBox.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Shows a tutorial popup
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class SeqAct_ShowTutorialBox extends SequenceAction;

// Id of the message (for blade messages)
var() private string MessageID;

// Index into the objective text array that we will pull the localized title text from
var() private int TitleObjectiveTextIndex;

// Index into the objective text array that we will pull the localized message text from
var() private int ObjectiveTextIndex;

// Path to the image to show in a modal box
var() private string ImagePath;

// optional, allows blade messages to be anchored to a unit in the world
var private XComGameState_Unit AnchorUnit;

// optional, allows blade messages to be anchored to an interactive object in the world
var private XComGameState_Unit AnchorInteractiveObject;

// optional, allows blade messages to be anchored to an interactive object in the world
var private string AnchorActorTag;

// If true, hides this blade when in the shot hud. Only valid for the hud blade
var() private bool HideBladeInShotHud;

event Activated()
{
	local StateObjectReference AnchorReference;

	if(InputLinks[2].bHasImpulse)
	{
		class'XComGameStateContext_TutorialBox'.static.RemoveBladeTutorialBoxFromHistory(MessageID);
	}
	else
	{
		if(InputLinks[0].bHasImpulse)
		{
			class'XComGameStateContext_TutorialBox'.static.AddModalTutorialBoxToHistory(TitleObjectiveTextIndex, ObjectiveTextIndex, ImagePath);
		}
		else if(InputLinks[1].bHasImpulse)
		{
			// determine if we should anchor the message
			if(AnchorUnit != none)
			{
				AnchorReference = AnchorUnit.GetReference();
			}
			else if(AnchorInteractiveObject != none)
			{
				AnchorReference = AnchorInteractiveObject.GetReference();
			}

			class'XComGameStateContext_TutorialBox'.static.AddBladeTutorialBoxToHistory(MessageID, 
																						ObjectiveTextIndex, 
																						AnchorReference, 
																						AnchorActorTag,
																						HideBladeInShotHud);
		}
	}
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 2;
}

defaultproperties
{
	ObjName="Show Tutorial Box"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	TitleObjectiveTextIndex=-1
	HideBladeInShotHud=false

	InputLinks(0)=(LinkDesc="Modal")
	InputLinks(1)=(LinkDesc="Blade")
	InputLinks(2)=(LinkDesc="Remove")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Int', LinkDesc="Objective Text Index", PropertyName=ObjectiveTextIndex)
	VariableLinks(1)=(ExpectedType=class'SeqVar_GameUnit', LinkDesc="Anchor Unit", PropertyName=AnchorUnit)
	VariableLinks(2)=(ExpectedType=class'SeqVar_InteractiveObject', LinkDesc="Anchor Object", PropertyName=AnchorInteractiveObject)
	VariableLinks(3)=(ExpectedType=class'SeqVar_String', LinkDesc="Anchor Actor Tag", PropertyName=AnchorActorTag)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Int', LinkDesc="Title Objective Text Index", PropertyName=TitleObjectiveTextIndex)
}