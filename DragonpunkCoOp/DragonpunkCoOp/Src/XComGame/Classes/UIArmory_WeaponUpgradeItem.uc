//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_WeaponUpgradeItem
//  AUTHOR:  Sam Batista
//  PURPOSE: UI that represents an upgrade item, largely based off of UIArmory_LoadoutItem
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIArmory_WeaponUpgradeItem extends UIPanel;

var string title;
var string subTitle;
var string disabledText;
var array<string> Images;
var string PrototypeIcon;
var string SlotType;
var int    Count;

var bool bIsLocked;
var bool bIsInfinite;
var bool bIsDisabled;

var X2WeaponUpgradeTemplate UpgradeTemplate;
var XComGameState_Item Weapon;
var int SlotIndex;

simulated function UIArmory_WeaponUpgradeItem InitUpgradeItem(XComGameState_Item InitWeapon, optional X2WeaponUpgradeTemplate InitUpgrade, optional int SlotNum = -1, optional string InitDisabledReason)
{
	Weapon = InitWeapon;
	UpgradeTemplate = InitUpgrade;
	SlotIndex = SlotNum;

	InitPanel();

	UpdateImage();
	UpdateCategoryIcons();

	if(UpgradeTemplate != none)
	{
		SetTitle(UpgradeTemplate.GetItemFriendlyName());
		SetSubTitle(Weapon.GetUpgradeEffectForUI(UpgradeTemplate));
	}
	else
	{
		SetTitle(class'UIArmory_WeaponUpgrade'.default.m_strEmptySlot);
		if(InitDisabledReason != "")
			SetSubTitle(class'UIArmory_WeaponUpgrade'.default.m_strUpgradeAvailable);
	}

	if(InitDisabledReason != "")
		SetDisabled(true, InitDisabledReason);

	return self;
}



simulated function UIArmory_WeaponUpgradeItem SetTitle(string txt)
{
	if(title != txt)
	{
		title = txt;
		MC.FunctionString("setTitle", title);
	}
	return self;
}

simulated function UIArmory_WeaponUpgradeItem SetSubTitle(string txt)
{
	if(subTitle != txt)
	{
		subTitle = txt;
		MC.FunctionString("setSlotType", subTitle);
	}
	return self;
}

simulated function UIArmory_WeaponUpgradeItem UpdateImage()
{
	if(UpgradeTemplate == none)
	{
		MC.FunctionVoid("setImages");
		return self;
	}

	MC.BeginFunctionOp("setImages");
	MC.QueueBoolean(false); // remnant of UIArmory_LoadoutItem, corresponds to "needsMask" param
	MC.QueueString(UpgradeTemplate.GetAttachmentInventoryImage(Weapon));
	MC.EndOp();
	return self;
}

simulated function UIArmory_WeaponUpgradeItem SetCount(int newCount) // -1 for infinite
{
	local XGParamTag kTag;
	
	if(Count != newCount)
	{
		Count = newCount;
		if(Count < 0)
		{
			MC.FunctionBool("setInfinite", true);
		}
		else
		{
			kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			kTag.IntValue0 = Count;
			
			MC.FunctionString("setCount", `XEXPAND.ExpandString(class'UIArmory_LoadoutItem'.default.m_strCount));
			MC.FunctionBool("setInfinite", false);
		}
	}
	return self;
}

simulated function UIArmory_WeaponUpgradeItem SetSlotType(string NewSlotType)
{
	if(NewSlotType != SlotType)
	{
		SlotType = NewSlotType;
		MC.FunctionString("setSlotType", SlotType);
	}
	return self;
}

simulated function UIArmory_WeaponUpgradeItem SetLocked(bool Locked)
{
	if(bIsLocked != Locked)
	{
		bIsLocked = Locked;
		MC.FunctionBool("setLocked", bIsLocked);

		if(!bIsLocked)
			OnLoseFocus();
	}
	return self;
}

simulated function UIArmory_WeaponUpgradeItem SetDisabled(bool bDisabled, optional string Reason)
{
	if(bIsDisabled != bDisabled)
	{
		bIsDisabled = bDisabled;
		MC.BeginFunctionOp("setDisabled");
		MC.QueueBoolean(bDisabled);
		MC.QueueString(Reason);
		MC.EndOp();
	}
	return self;
}

simulated function UIArmory_WeaponUpgradeItem SetInfinite(bool infinite)
{
	if(bIsInfinite != infinite)
	{
		bIsInfinite = infinite;
		MC.FunctionBool("setInfinite", bIsInfinite);
	}
	return self;
}

simulated function UIArmory_WeaponUpgradeItem SetPrototypeIcon(optional string icon) // pass empty string to hide PrototypeIcon
{
	if(PrototypeIcon != icon)
	{
		PrototypeIcon = icon;
		MC.FunctionString("setPrototype", icon);
	}
	return self;
}

simulated function UpdateCategoryIcons()
{
	local int Index;
	local array<string> Icons; 

	if( UpgradeTemplate == none )
	{
		ClearIcons();
		return;
	}

	Icons = UpgradeTemplate.GetAttachmentInventoryCategoryImages(Weapon);

	if( Icons.Length == 0 )
	{
		ClearIcons();
	}
	else
	{
		for( Index = 0; Index < Icons.Length; Index++ )
		{
			AddIcon(Index, Icons[Index]);
		}
	}
}

simulated function AddIcon(int index, string path)
{
	MC.BeginFunctionOp("addIcon");
	MC.QueueNumber(index);
	MC.QueueString(path);
	MC.EndOp();
}

simulated function ClearIcons()
{
	MC.FunctionVoid("clearIcons");
}

simulated function OnReceiveFocus()
{
	if( !bIsLocked && !bIsFocused )
	{
		bIsFocused = true;
		MC.FunctionVoid("onReceiveFocus");
	}
}

simulated function OnLoseFocus()
{
	if( bIsFocused )
	{
		bIsFocused = false;
		MC.FunctionVoid("onLoseFocus");
	}
}

defaultproperties
{
	Width = 342;
	Height = 145;
	bAnimateOnInit = false;
	bProcessesMouseEvents = true;
	LibID = "LoadoutListItem";
}