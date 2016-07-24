//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect_ListItem
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: Displays information pertaining to a single soldier in the Squad Select screen
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISquadSelect_ListItem extends UIPanel;

var int SlotIndex;
var bool bDisabled;

// Disable functionality for certain buttons
var bool bDisabledLoadout;
var bool bDisabledEdit;
var bool bDisabledDismiss;
var array<EInventorySlot> CannotEditSlots;

var UIPanel DynamicContainer;
var UIImage PsiMarkup;
var UIPanel AbilityIcons;
var UIList UtilitySlots;

var localized string m_strSelectUnit;
var localized string m_strBackpack;
var localized string m_strBackpackDescription;
var localized string m_strEmptyHeavyWeapon;
var localized string m_strEmptyHeavyWeaponDescription;
var localized string m_strPromote;
var localized string m_strEdit;
var localized string m_strDismiss;
var localized string m_strNeedsMediumArmor;
var localized string m_strNoUtilitySlots;
var localized string m_strIncreaseSquadSize;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	DynamicContainer = Spawn(class'UIPanel', self).InitPanel('dynamicContainerMC');
	
	PsiMarkup = Spawn(class'UIImage', DynamicContainer).InitImage(, class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.SetScale(0.7).SetPosition(220, 258).Hide(); // starts off hidden until needed
	
	return self;
}
 
simulated function UpdateData(optional int Index = -1, optional bool bDisableEdit, optional bool bDisableDismiss, optional bool bDisableLoadout, optional array<EInventorySlot> CannotEditSlotsList)
{
	local bool bCanPromote;
	local string ClassStr, NameStr;
	local int i, NumUtilitySlots, UtilityItemIndex, NumUnitUtilityItems;
	local float UtilityItemWidth, UtilityItemHeight;
	local UISquadSelect_UtilityItem UtilityItem;
	local array<XComGameState_Item> EquippedItems;
	local XComGameState_Unit Unit;
	local XComGameState_Item PrimaryWeapon, HeavyWeapon;
	local X2WeaponTemplate PrimaryWeaponTemplate, HeavyWeaponTemplate;
	local X2AbilityTemplate HeavyWeaponAbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;

	if(bDisabled)
		return;

	SlotIndex = Index != -1 ? Index : SlotIndex;

	bDisabledEdit = bDisableEdit;
	bDisabledDismiss = bDisableDismiss;
	bDisabledLoadout = bDisableLoadout;
	CannotEditSlots = CannotEditSlotsList;

	if( UtilitySlots == none )
	{
		UtilitySlots = Spawn(class'UIList', DynamicContainer).InitList(, 0, 138, 282, 70, true);
		UtilitySlots.bStickyHighlight = false;
		UtilitySlots.ItemPadding = 5;
	}

	if( AbilityIcons == none )
	{
		AbilityIcons = Spawn(class'UIPanel', DynamicContainer).InitPanel().SetPosition(4, 92);
		AbilityIcons.Hide(); // starts off hidden until needed
	}

	// -------------------------------------------------------------------------------------------------------------

	// empty slot
	if(GetUnitRef().ObjectID <= 0)
	{
		AS_SetEmpty(m_strSelectUnit);
		AS_SetUnitHealth(-1, -1);

		AbilityIcons.Remove();
		AbilityIcons = none;

		DynamicContainer.Hide();
	}
	else
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID));
		bCanPromote = (Unit.ShowPromoteIcon());

		UtilitySlots.Show();
		DynamicContainer.Show();
		//Backpack controlled separately by the heavy weapon info. 

		NumUtilitySlots = 2;
		if(Unit.HasGrenadePocket()) NumUtilitySlots++;
		if(Unit.HasAmmoPocket()) NumUtilitySlots++;
		
		UtilityItemWidth = (UtilitySlots.GetTotalWidth() - (UtilitySlots.ItemPadding * (NumUtilitySlots - 1))) / NumUtilitySlots;
		UtilityItemHeight = UtilitySlots.Height;

		if(UtilitySlots.ItemCount != NumUtilitySlots)
			UtilitySlots.ClearItems();

		for(i = 0; i < NumUtilitySlots; ++i)
		{
			if(i >= UtilitySlots.ItemCount)
			{
				UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.CreateItem(class'UISquadSelect_UtilityItem').InitPanel());
				UtilityItem.SetSize(UtilityItemWidth, UtilityItemHeight);
				UtilityItem.CannotEditSlots = CannotEditSlotsList;
				UtilitySlots.OnItemSizeChanged(UtilityItem);
			}
		}

		NumUnitUtilityItems = Unit.GetCurrentStat(eStat_UtilityItems); // Check how many utility items this unit can use
		
		UtilityItemIndex = 0;
		UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
		if (NumUnitUtilityItems > 0)
		{
			EquippedItems = class'UIUtilities_Strategy'.static.GetEquippedItemsInSlot(Unit, eInvSlot_Utility);
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_Utility, 0, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_Utility, 0, NumUtilitySlots);
		}
		else
			UtilityItem.SetLocked(m_strNoUtilitySlots); // If the unit has no utility slots allowed, lock the slot

		if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress)
		{
			// spawn the attention icon externally so it draws on top of the button and image 
			Spawn(class'UIPanel', UtilityItem).InitPanel('attentionIconMC', class'UIUtilities_Controls'.const.MC_AttentionIcon)
			.SetPosition(2, 4)
			.SetSize(70, 70); //the animated rings count as part of the size. 
		} else if(GetChildByName('attentionIconMC', false) != none) {
			GetChildByName('attentionIconMC').Remove();
		}

		UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
		if (Unit.HasExtraUtilitySlot())
		{
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 1 ? EquippedItems[1] : none, eInvSlot_Utility, 1, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 1 ? EquippedItems[1] : none, eInvSlot_Utility, 1, NumUtilitySlots);
		}
		else
			UtilityItem.SetLocked(NumUnitUtilityItems > 0 ? m_strNeedsMediumArmor : m_strNoUtilitySlots);

		if(Unit.HasGrenadePocket())
		{
			UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
			EquippedItems = class'UIUtilities_Strategy'.static.GetEquippedItemsInSlot(Unit, eInvSlot_GrenadePocket); 
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_GrenadePocket, 0, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_GrenadePocket, 0, NumUtilitySlots);
		}

		if(Unit.HasAmmoPocket())
		{
			UtilityItem = UISquadSelect_UtilityItem(UtilitySlots.GetItem(UtilityItemIndex++));
			EquippedItems = class'UIUtilities_Strategy'.static.GetEquippedItemsInSlot(Unit, eInvSlot_AmmoPocket);
			if (bDisableLoadout)
				UtilityItem.SetDisabled(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_AmmoPocket, 0, NumUtilitySlots);
			else
				UtilityItem.SetAvailable(EquippedItems.Length > 0 ? EquippedItems[0] : none, eInvSlot_AmmoPocket, 0, NumUtilitySlots);
		}
		
		// Don't show class label for rookies since their rank is shown which would result in a duplicate string
		if(Unit.GetRank() > 0)
			ClassStr = class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetSoldierClassTemplate().DisplayName), eUIState_Faded, 17);
		else
			ClassStr = "";

		PrimaryWeapon = Unit.GetItemInSlot(eInvSlot_PrimaryWeapon);
		if(PrimaryWeapon != none)
		{
			PrimaryWeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
		}

		NameStr = Unit.GetName(eNameType_Last);
		if (NameStr == "") // If the unit has no last name, display their first name instead
		{
			NameStr = Unit.GetName(eNameType_First);
		}

		// TUTORIAL: Disable buttons if tutorial is enabled
		if(bDisableEdit)
			MC.FunctionVoid("disableEdit");
		if(bDisableDismiss)
			MC.FunctionVoid("disableDismiss");

		AS_SetFilled( class'UIUtilities_Text'.static.GetColoredText(Caps(class'X2ExperienceConfig'.static.GetRankName(Unit.GetRank(), Unit.GetSoldierClassTemplateName())), eUIState_Normal, 18),
					  class'UIUtilities_Text'.static.GetColoredText(Caps(NameStr), eUIState_Normal, 22),
					  class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetName(eNameType_Nick)), eUIState_Header, 28),
					  Unit.GetSoldierClassTemplate().IconImage, class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName()),
					  class'UIUtilities_Text'.static.GetColoredText(m_strEdit, bDisableEdit ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(m_strDismiss, bDisableDismiss ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(PrimaryWeaponTemplate.GetItemFriendlyName(PrimaryWeapon.ObjectID), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(class'UIArmory_loadout'.default.m_strInventoryLabels[eInvSlot_PrimaryWeapon], bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponName(), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  class'UIUtilities_Text'.static.GetColoredText(GetHeavyWeaponDesc(), bDisableLoadout ? eUIState_Disabled : eUIState_Normal),
					  (bCanPromote ? m_strPromote : ""), Unit.IsPsiOperative() || (Unit.HasPsiGift() && Unit.GetRank() < 2), ClassStr);
		
		AS_SetUnitHealth(class'UIUtilities_Strategy'.static.GetUnitCurrentHealth(Unit), class'UIUtilities_Strategy'.static.GetUnitMaxHealth(Unit));
		
		PsiMarkup.SetVisible(Unit.HasPsiGift());

		HeavyWeapon = Unit.GetItemInSlot(eInvSlot_HeavyWeapon);
		if(HeavyWeapon != none)
		{
			HeavyWeaponTemplate = X2WeaponTemplate(HeavyWeapon.GetMyTemplate());

			// Only show one icon for heavy weapon abilities
			if(HeavyWeaponTemplate.Abilities.Length > 0)
			{
				AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
				HeavyWeaponAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(HeavyWeaponTemplate.Abilities[0]);
				if(HeavyWeaponAbilityTemplate != none)
					Spawn(class'UIIcon', AbilityIcons).InitIcon(, HeavyWeaponAbilityTemplate.IconImage, false);
			}

			AbilityIcons.Show();
			AS_HasHeavyWeapon(true);
		}
		else
		{
			AbilityIcons.Hide();
			AS_HasHeavyWeapon(false);
		}
	}
}

simulated function DisableSlot()
{
	bDisabled = true;
	AS_SetDisabled(m_strIncreaseSquadSize);
	DynamicContainer.Hide();
}

simulated function AnimateIn(optional float AnimationIndex = -1.0)
{
	MC.FunctionNum("animateIn", AnimationIndex);
}

function StateObjectReference GetUnitRef()
{
	local StateObjectReference NullRef; 
	if( SlotIndex >= UISquadSelect(Screen).XComHQ.Squad.length )
		return NullRef;
	else
		return UISquadSelect(Screen).XComHQ.Squad[SlotIndex];
}

simulated function string GetHeavyWeaponName()
{
	if(GetEquippedHeavyWeapon() != none)
		return GetEquippedHeavyWeapon().GetMyTemplate().GetItemFriendlyName();
	else
		return HasHeavyWeapon() ? m_strEmptyHeavyWeapon : "";
}

simulated function string GetHeavyWeaponDesc()
{
	if(GetEquippedHeavyWeapon() != none)
		return class'UIArmory_loadout'.default.m_strInventoryLabels[eInvSlot_HeavyWeapon];
	else
		return "";
}

simulated function XComGameState_Item GetEquippedHeavyWeapon()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID)).GetItemInSlot(eInvSlot_HeavyWeapon);
}

function bool HasHeavyWeapon()
{
	if(GetUnitRef().ObjectID > 0)
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(GetUnitRef().ObjectID)).HasHeavyWeapon();
	return false;
}

//------------------------------------------------------

simulated function OnClickedPromote()
{
	UISquadSelect(Screen).m_iSelectedSlot = SlotIndex;
	if( GetUnitRef().ObjectID > 0 )
	{
		UISquadSelect(Screen).bDirty = true;
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoPromote));
	}
}

simulated function GoPromote()
{
	`HQPRES.UIArmory_Promotion(GetUnitRef());
}

simulated function OnClickedPrimaryWeapon()
{
	if (bDisabledLoadout)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	UISquadSelect(Screen).m_iSelectedSlot = SlotIndex;
	if(GetUnitRef().ObjectID > 0)
	{
		UISquadSelect(Screen).bDirty = true;
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoToPrimaryWeapon));
	}
}

simulated function GoToPrimaryWeapon()
{
	`HQPRES.UIArmory_Loadout(GetUnitRef(), CannotEditSlots);
	
	if (CannotEditSlots.Find(eInvSlot_PrimaryWeapon) == INDEX_NONE)
	{
		UIArmory_Loadout(Movie.Stack.GetScreen(class'UIArmory_Loadout')).SelectWeapon(eInvSlot_PrimaryWeapon);
	}
}

simulated function OnClickedHeavyWeapon()
{
	if (bDisabledLoadout)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	UISquadSelect(Screen).m_iSelectedSlot = SlotIndex;
	if(GetUnitRef().ObjectID > 0)
	{
		UISquadSelect(Screen).bDirty = true;
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoToHeavyWeapon));
	}
}

simulated function GoToHeavyWeapon()
{
	`HQPRES.UIArmory_Loadout(GetUnitRef(), CannotEditSlots);

	if (CannotEditSlots.Find(eInvSlot_HeavyWeapon) == INDEX_NONE)
	{
		UIArmory_Loadout(Movie.Stack.GetScreen(class'UIArmory_Loadout')).SelectWeapon(eInvSlot_HeavyWeapon);
	}
}

simulated function OnClickedDismissButton()
{
	local UISquadSelect SquadScreen;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(!XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ') || bDisabledDismiss)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	SquadScreen = UISquadSelect(screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	SquadScreen.ChangeSlot();
	UpdateData(); // passing no params clears the slot
}

simulated function OnClickedEditUnitButton()
{
	local UISquadSelect SquadScreen;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	if(!XComHQ.IsObjectiveCompleted('T0_M3_WelcomeToHQ') || bDisabledEdit)
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
		return;
	}

	SquadScreen = UISquadSelect(screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	
	if( XComHQ.Squad[SquadScreen.m_iSelectedSlot].ObjectID > 0 )
	{
		SquadScreen.bDirty = true;
		SquadScreen.SnapCamera();
		`HQPRES.UIArmory_MainMenu(XComHQ.Squad[SquadScreen.m_iSelectedSlot], 'PreM_CustomizeUI', 'PreM_SwitchToSoldier', 'PreM_GoToLineup', 'PreM_CustomizeUI_Off', 'PreM_SwitchToLineup');
		`XCOMGRI.DoRemoteEvent('PreM_GoToSoldier');
	}
}

simulated function OnClickedSelectUnitButton()
{
	local UISquadSelect SquadScreen;
	SquadScreen = UISquadSelect(Screen);
	SquadScreen.m_iSelectedSlot = SlotIndex;
	SquadScreen.bDirty = true;
	SquadScreen.SnapCamera();
	`HQPRES.UIPersonnel_SquadSelect(SquadScreen.ChangeSlot, SquadScreen.UpdateState, SquadScreen.XComHQ);
}

simulated function OnMouseEvent(int Cmd, array<string> Args)
{
	local string CallbackTarget;

	Super.OnMouseEvent(Cmd, Args);

	if(bDisabled) return;

	if(Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		CallbackTarget = Args[Args.Length - 2]; // -2 to account for bg within ButtonControls

		switch(CallbackTarget)
		{
		case "promoteButtonMC":         OnClickedPromote(); break;
		case "primaryWeaponButtonMC":   OnClickedPrimaryWeapon(); break;
		case "heavyWeaponButtonMC":     OnClickedHeavyWeapon(); break;
		case "dismissButtonMC":         OnClickedDismissButton(); break;
		case "selectUnitButtonMC":      OnClickedSelectUnitButton(); break;
		case "editButtonMC":            OnClickedEditUnitButton(); break;
		}
	}
}

//------------------------------------------------------

simulated function AS_SetFilled( string firstName, string lastName, string nickName,
								 string classIcon, string rankIcon, string editLabel, string dismissLabel, 
								 string primaryWeaponLabel, string primaryWeaponDescription,
								 string heavyWeaponLabel, string heavyWeaponDescription,
								 string promoteLabel, bool isPsiPromote, string className )
{
	mc.BeginFunctionOp("setFilledSlot");
	mc.QueueString(firstName);
	mc.QueueString(lastName);
	mc.QueueString(nickName);
	mc.QueueString(classIcon);
	mc.QueueString(rankIcon);
	mc.QueueString(editLabel);
	mc.QueueString(dismissLabel);
	mc.QueueString(primaryWeaponLabel);
	mc.QueueString(primaryWeaponDescription);
	mc.QueueString(heavyWeaponLabel);
	mc.QueueString(heavyWeaponDescription);
	mc.QueueString(promoteLabel);
	mc.QueueBoolean(isPsiPromote);
	mc.QueueString(className);
	mc.EndOp();
}

simulated function AS_HasHeavyWeapon( bool bHasHeavyWeapon )
{
	mc.FunctionBool("setHeavyWeapon", bHasHeavyWeapon);
}

simulated function AS_SetEmpty( string label )
{
	mc.FunctionString("setEmptySlot", label);
}

simulated function AS_SetBlank( string label )
{
	mc.FunctionString("setBlankSlot", label);
}

simulated function AS_SetDisabled( string label )
{
	mc.FunctionString("setDisabledSlot", label);
}

simulated function AS_SetUnitHealth(int CurrentHP, int MaxHP)
{
	mc.BeginFunctionOp("setUnitHealth");
	mc.QueueNumber(CurrentHP);
	mc.QueueNumber(MaxHP);
	mc.EndOp();
}

// Don't propagate focus changes to children
simulated function OnReceiveFocus()
{
	local UISquadSelect SquadScreen;
	SquadScreen = UISquadSelect(Screen);
	if(SquadScreen != none)
	{
		SquadScreen.m_iSelectedSlot = SlotIndex;
		SquadScreen.m_kSlotList.SetSelectedItem(self);
	}
	Invoke("onReceiveFocus");
}

simulated function OnLoseFocus()
{
	local UISquadSelect SquadScreen;
	SquadScreen = UISquadSelect(Screen);
	if(SquadScreen != none)
	{
		SquadScreen.m_iSelectedSlot = SlotIndex;
		SquadScreen.m_kSlotList.SetSelectedItem(none);
	}
	Invoke("onLoseFocus");
}

defaultproperties
{
	LibID = "SquadSelectListItem";
	width = 282;
	bIsNavigable = true;
	bCascadeFocus = false;
}

//------------------------------------------------------