//---------------------------------------------------------------------------------------
//  FILE:    SeqEvent_UnitAcquiredItem.uc
//  AUTHOR:  David Burchanowski  --  1/21/2014
//  PURPOSE: Event for handling when an item is added to a unit's inventory.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
 
class SeqEvent_UnitAcquiredItem extends SeqEvent_X2GameState;

var private XComGameState_Unit Unit;
var private string ItemTemplate;

function FireEvent(XComGameState_Unit InUnit, XComGameState_Item InItem)
{
	if(InUnit == none || InItem == none)
	{
		`assert(false);
		return;
	}

	Unit = InUnit;
	ItemTemplate = string(InItem.GetMyTemplateName());
	CheckActivate(InUnit.GetVisualizer(), none);
}

defaultproperties
{
	ObjName="Unit Acquired Item"

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Unit",PropertyName=Unit,bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="Item Template",PropertyName=ItemTemplate,bWriteable=TRUE)
}
