///---------------------------------------------------------------------------------------
//  FILE:    SeqAct_UnitHasItem.uc
//  AUTHOR:  David Burchanowski  --  1/21/2014
//  PURPOSE: Action to check if a unit carries a particular item.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_UnitHasItem extends SequenceAction;

var XComGameState_Unit Unit;
var string ItemTemplate;

event Activated()
{
	local bool HasItem;
	local array<XComGameState_Item> AllItems;
	local XComGameState_Item Item;

	if (Unit != none)
	{
		AllItems = Unit.GetAllInventoryItems(Unit.GetParentGameState());

		HasItem = false;
		foreach AllItems(Item)
		{
			if(Item.GetMyTemplateName() == name(ItemTemplate))
			{
				HasItem = true;
				break;
			}
		}

		OutputLinks[0].bHasImpulse = HasItem;
		OutputLinks[1].bHasImpulse = !HasItem;
	}
	else
	{
		OutputLinks[0].bHasImpulse = false;
		OutputLinks[1].bHasImpulse = true;
	}
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Unit Has Item"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	bAutoActivateOutputLinks=false
	
	OutputLinks(0)=(LinkDesc="True")
	OutputLinks(1)=(LinkDesc="False")

	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="Item Template",PropertyName=ItemTemplate,bWriteable=TRUE)
}
