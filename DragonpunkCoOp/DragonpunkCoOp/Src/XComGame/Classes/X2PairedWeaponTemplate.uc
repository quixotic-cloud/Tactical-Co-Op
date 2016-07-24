//---------------------------------------------------------------------------------------
//  FILE:    X2PairedWeaponTemplate.uc
//  AUTHOR:  Joshua Bouscher
//
//  PURPOSE: Allows a weapon to specify another weapon that it should always be paired
//           with. This is accomplished by hooking into the equipped and unequipped
//           callbacks made when an item is added or removed from a unit's inventory.
//           When this weapon (the "parent") is equipped, it will create a new item
//           using PairedTemplateName and place it in the PairedSlot.
//           When this weapon is unequipped, if the item in the unit's PairedSlot
//           is the "child" weapon, it will be destroyed.
//           The child weapon will have no such functionality. It is assumed the
//           child weapon is hidden from the UI.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2PairedWeaponTemplate extends X2WeaponTemplate;

var EInventorySlot PairedSlot;
var name PairedTemplateName;

function PairEquipped(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local X2ItemTemplate PairedItemTemplate;
	local XComGameState_Item PairedItem, RemoveItem;

	if (PairedTemplateName != '')
	{
		RemoveItem = UnitState.GetItemInSlot(PairedSlot, NewGameState);
		if (RemoveItem != none)
		{
			if (UnitState.RemoveItemFromInventory(ItemState, NewGameState))
			{
				NewGameState.RemoveStateObject(RemoveItem.ObjectID);
			}
			else
			{
				`RedScreen("Unable to remove item" @ RemoveItem.GetMyTemplateName() @ "in PairedSlot" @ PairedSlot @ "so paired item equip will fail -jbouscher / @gameplay");
			}
		}
		PairedItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(PairedTemplateName);
		if (PairedItemTemplate != none)
		{
			PairedItem = PairedItemTemplate.CreateInstanceFromTemplate(NewGameState);
			NewGameState.AddStateObject(PairedItem);
			UnitState.AddItemToInventory(PairedItem, PairedSlot, NewGameState);
			if (UnitState.GetItemInSlot(PairedSlot, NewGameState, true).ObjectID != PairedItem.ObjectID)
			{
				`RedScreen("Created a paired item ID" @ PairedItem.ObjectID @ "but we could not add it to the unit's inventory, destroying it instead -jbouscher / @gameplay");
				NewGameState.PurgeGameStateForObjectID(PairedItem.ObjectID);
			}
		}
	}
}

function PairUnEquipped(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	local XComGameState_Item PairedItem;
	local XGWeapon VisWeapon;

	PairedItem = UnitState.GetItemInSlot(PairedSlot, NewGameState);
	if (PairedItem != none && PairedItem.GetMyTemplateName() == PairedTemplateName)
	{
		if (UnitState.RemoveItemFromInventory(PairedItem, NewGameState))
		{
			VisWeapon = XGWeapon(PairedItem.GetVisualizer());
			if (VisWeapon != none && VisWeapon.UnitPawn != none)
			{
				VisWeapon.UnitPawn.DetachItem(VisWeapon.GetEntity().Mesh);
			}
			NewGameState.RemoveStateObject(PairedItem.ObjectID);
		}
		else
		{
			`assert(false);
		}
	}
}

DefaultProperties
{
	OnEquippedFn = PairEquipped;
	OnUnequippedFn = PairUnEquipped;
}