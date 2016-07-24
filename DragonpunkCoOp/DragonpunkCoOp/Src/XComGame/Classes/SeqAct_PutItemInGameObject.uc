//  FILE:    SeqAct_PutItemInGameObject.uc
//  AUTHOR:  David Burchanowski  --  9/16/2014
//  PURPOSE: Action to get the quest item for the mission script this action instance belongs to
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_PutItemInGameObject extends SequenceAction;

var private XComGameState_InteractiveObject InteractiveObject;
var() private string ItemTemplate;

event Activated()
{
	local X2ItemTemplate Item;
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;

	if(InteractiveObject == none)
	{
		`PARCELMGR.ParcelGenerationAssert(false, "SeqAct_PutItemInGameObject: InteractiveObject is none! Bailing out... ");
		return;
	}

	Item = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(name(ItemTemplate));

	if(Item == none)
	{
		`PARCELMGR.ParcelGenerationAssert(false, "SeqAct_PutItemInGameObject: Item template " $ ItemTemplate $ " not found. Bailing out...");
		return;
	}

	// create a new game state
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_PutItemInGameObject");
	
	// update the interactive object state
	InteractiveObject = XComGameState_InteractiveObject(NewGameState.CreateStateObject(class'XComGameState_InteractiveObject', InteractiveObject.ObjectID));

	// create a new instance of the item template and add it to the object
	ItemState = Item.CreateInstanceFromTemplate(NewGameState);

	// add the modified state objects to the game state
	NewGameState.AddStateObject(InteractiveObject);
	NewGameState.AddStateObject(ItemState);

	// add the loot
	InteractiveObject.AddLoot(ItemState.GetReference(), NewGameState);

	// and submit
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

defaultproperties
{
	ObjName="Put Item In Game Object"
	ObjCategory="Procedural Missions"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_InteractiveObject', LinkDesc="Interactive Object", PropertyName=InteractiveObject, bWriteable=true)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String', LinkDesc="Item Template", PropertyName=ItemTemplate)
}