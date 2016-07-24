//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_Backpack.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Statistics on the currently selected soldier.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_Backpack extends UIPanel;

var int TotalPips;
var int FilledPips;
var string ImagePath;

// Pseudo-Ctor
simulated function UITacticalHUD_Backpack InitBackpack()
{
	InitPanel();
	return self;
}

simulated function Update( XGUnit kActiveUnit )
{
	local string NewImagePath;
	local int CurrentPips, MaxPips;
	local XComGameState_Unit kGameStateUnit;
	local array<XComGameState_Item> BackpackItems; 
	local XComGameState_Item kArmorItem; 

	kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));

	MaxPips = -1;
	CurrentPips = -1;

	// --------------------------------------
	// First, if we don't have a backpack: 
	if( kGameStateUnit.HasBackpack() )
	{
		NewImagePath = class'UIUtilities_Image'.const.BackpackIcon; 

		BackpackItems = kGameStateUnit.GetAllItemsInSlot(eInvSlot_Backpack);
		MaxPips = kGameStateUnit.GetMaxStat(eStat_BackpackSize);
		CurrentPips = BackpackItems.length;
	}
	else
	{
		// --------------------------------------
		kArmorItem = kGameStateUnit.GetItemInSlot(eInvSlot_Armor); 

		if( kArmorItem != None && kArmorItem.AllowsHeavyWeapon() )
		{
			// Soldier doesn't have a backpack because soldier is wearing heavy armor.
			NewImagePath = kArmorItem.GetMyTemplate().strBackpackIcon; 
		}
		else
		{
			// --------------------------------------
			// Soldier may not have a backpack at all, and no special case from above, in which case, show nothing at all.
			NewImagePath = ""; 
		}
	}

	UpdateImage(NewImagePath);
	UpdatePips(CurrentPips, MaxPips);
}

simulated function UpdateImage(string NewImagePath)
{
	if(ImagePath != NewImagePath)
	{
		ImagePath = NewImagePath;
		MC.FunctionString("updateImage", ImagePath);
	}
}

simulated function UpdatePips(int CurrentPips, int MaxPips)
{
	if(TotalPips != MaxPips || FilledPips != CurrentPips)
	{
		TotalPips = MaxPips;
		FilledPips = CurrentPips;
		MC.BeginFunctionOp("updatePips");
		MC.QueueNumber(FilledPips);
		MC.QueueNumber(TotalPips);
		MC.EndOp();
	}
}

defaultproperties
{
	MCName = "backpack";
	bAnimateOnInit = false;
	bProcessesMouseEvents = true; // enabled to process tooltips
}

