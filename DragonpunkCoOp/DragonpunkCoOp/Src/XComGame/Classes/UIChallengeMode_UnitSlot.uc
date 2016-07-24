









// DEPRECATED bsteiner 3/24/2016 















//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIChallengeMode_UnitSlot
//  AUTHOR:  Sam Batista --  03/20/15
//  PURPOSE: Mainly displays the unit loadout for the Challenge Mode's auto-generated Squad
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChallengeMode_UnitSlot extends UIPanel;

//
// *Soldier Template:
//  - Section: Weapons
//     - Primary Icon
//     - Secondary Icon
//  - Section: Armor
//  - Section: Items
//  - Section: Abilities
//  - Section: Name Details
//     - Class Icon
//     - Rank
//     - Long Last name
//     - Nickname
//

//--------------------------------------------------------------------------------------- 
// UI Elements
//
var UIBGBox                             m_WeaponsBox;
var UIBGBox                             m_ArmorBox;
var UIBGBox                             m_ItemsBox;
var UIBGBox                             m_AbilitiesBox;
var UIBGBox                             m_NamesBox;

var UIText								m_WeaponsText;
var UIText								m_ArmorText;
var UIText								m_ItemsText;
var UIText								m_AbilitiesText;
var UIText								m_NamesText;

var UIPanel								m_WeaponIcons;
var UIPanel								m_ItemIcons;
var UIPanel								m_AbilityIcons;
var UIPanel								m_NameIcons;
var UIPanel								DynamicContainer;


// GAME Vars
var name m_nCharacterTemplate;
var name m_nSoldierClassTemplate;
var int  m_iSoldierRank;
var name m_nPrimaryWeaponTemplate;
var name m_nSecondaryWeaponTemplate;
var name m_nHeavyWeaponTemplate;
var name m_nArmorTemplate;
var name m_nUtilityItem1Template;
var name m_nUtilityItem2Template;
var int  m_iCharacterPoolSelection;
var array<SCATProgression> m_arrSoldierProgression;

var string m_FirstName;
var string m_LastName;
var string m_NickName;


//==============================================================================
//		INITIALIZATION:
//==============================================================================
simulated function UIChallengeMode_UnitSlot InitSlot(int SlotWidth, int SlotHeight)
{
	local int BoxYSpacing, BoxHeight, NumBoxes;
	BoxYSpacing = 10;

	InitPanel();

	SetSize(SlotWidth, SlotHeight);

	NumBoxes = 5;
	BoxHeight = ((SlotHeight - (BoxYSpacing * (NumBoxes - 1))) / NumBoxes);

	m_WeaponsBox = Spawn(class'UIBGBox', self).InitBG('', 0, 0, SlotWidth, BoxHeight).SetBGColor("cyan");
	m_ArmorBox = Spawn(class'UIBGBox', self).InitBG('', 0, m_WeaponsBox.Y + m_WeaponsBox.Height + BoxYSpacing, SlotWidth, BoxHeight).SetBGColor("red");
	m_ItemsBox = Spawn(class'UIBGBox', self).InitBG('', 0, m_ArmorBox.Y + m_ArmorBox.Height + BoxYSpacing, SlotWidth, BoxHeight).SetBGColor("yellow");
	m_AbilitiesBox = Spawn(class'UIBGBox', self).InitBG('', 0, m_ItemsBox.Y + m_ItemsBox.Height + BoxYSpacing, SlotWidth, BoxHeight).SetBGColor("green");
	m_NamesBox = Spawn(class'UIBGBox', self).InitBG('', 0, m_AbilitiesBox.Y + m_AbilitiesBox.Height + BoxYSpacing, SlotWidth, BoxHeight).SetBGColor("gray");

	m_WeaponsText = Spawn(class'UIText', self);
	m_WeaponsText.InitText('', "");
	m_WeaponsText.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	

	m_ArmorText = Spawn(class'UIText', self);
	m_ArmorText.InitText('', "");
	m_ArmorText.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	

	m_ItemsText = Spawn(class'UIText', self);
	m_ItemsText.InitText('', "");
	m_ItemsText.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	

	m_AbilitiesText = Spawn(class'UIText', self);
	m_AbilitiesText.InitText('', "");
	m_AbilitiesText.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	

	m_NamesText = Spawn(class'UIText', self);
	m_NamesText.InitText('', "");
	m_NamesText.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);

	return self;
}

simulated function InitIconPanels()
{
	if (DynamicContainer != none)
	{
		DynamicContainer.Remove();
	}
	DynamicContainer = Spawn(class'UIPanel', self).InitPanel('dynamicContainerMC');
	m_WeaponIcons = Spawn(class'UIPanel', DynamicContainer).InitPanel().SetPosition(4, m_WeaponsBox.Y + 10);
	m_ItemIcons = Spawn(class'UIPanel', DynamicContainer).InitPanel().SetPosition(4, m_ItemsBox.Y + 10);
	m_AbilityIcons = Spawn(class'UIPanel', DynamicContainer).InitPanel().SetPosition(4, m_AbilitiesBox.Y + 10);
	m_NameIcons = Spawn(class'UIPanel', DynamicContainer).InitPanel().SetPosition(4, m_NamesBox.Y + 10);
}

simulated function SetTextFields(XComGameState_Unit Unit)
{
	local array<XComGameState_Item> Items;
	local array<SoldierClassAbilityType> EarnedSoldierAbilities;
	local XComGameState_Item Item;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate;
	local UIIcon Icon;
	//local string s;
	local int i, NextX;

	InitIconPanels();

	m_WeaponsText.SetPosition(self.X + 25, self.Y + m_WeaponsBox.Y + 10);
	m_ArmorText.SetPosition(self.X + 25, self.Y + m_ArmorBox.Y + 10);
	m_ItemsText.SetPosition(self.X + 25, self.Y + m_ItemsBox.Y + 10);
	m_AbilitiesText.SetPosition(self.X + 25, self.Y + m_AbilitiesBox.Y + 10);
	m_NamesText.SetPosition(self.X + 25, self.Y + m_NamesBox.Y + 10);

	//m_WeaponsText.SetText(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate().GetItemFriendlyName() $ "\n" $ Unit.GetItemInSlot(eInvSlot_SecondaryWeapon).GetMyTemplate().GetItemFriendlyName());

	Spawn(class'UIIcon', m_WeaponIcons).InitIcon(, Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate().strImage, false, false).SetPosition(0, -40);
	Spawn(class'UIIcon', m_WeaponIcons).InitIcon(, Unit.GetItemInSlot(eInvSlot_SecondaryWeapon).GetMyTemplate().strImage, false, false).SetPosition(40, 0);

	m_ArmorText.SetText(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).GetMyTemplate().GetItemFriendlyName() $ "\n" $ Unit.GetItemInSlot(eInvSlot_Armor).GetMyTemplate().GetItemFriendlyName());

	Items = Unit.GetAllItemsInSlot(eInvSlot_Utility);
	NextX = 0;
	foreach Items(Item)
	{
		//s $= Item.GetMyTemplate().GetItemFriendlyName() $ "\n";
		Icon = Spawn(class'UIIcon', m_ItemIcons).InitIcon(, Item.GetMyTemplate().strImage, false, false);
		Icon.SetX(NextX);
		Icon.SetSize(80, 60);
		NextX += 60;
	}

	//m_ItemsText.SetText(s);

	//s = "";

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	EarnedSoldierAbilities = Unit.GetEarnedSoldierAbilities();
	NextX = 0;
	for (i = 0; i < EarnedSoldierAbilities.Length; ++i)
	{
		//s $= EarnedSoldierAbilities[i].AbilityName $ "\n";
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(EarnedSoldierAbilities[i].AbilityName);
		if (AbilityTemplate != none)
		{
			Spawn(class'UIIcon', m_AbilityIcons).InitIcon(, AbilityTemplate.IconImage, false).SetX(NextX);
			NextX += 40;
		}
	}

	Spawn(class'UIIcon', m_NameIcons).InitIcon(, Unit.GetSoldierClassTemplate().IconImage, false, false);

	//m_AbilitiesText.SetText(s);
	m_NamesText.SetText("        " $ Unit.GetName(eNameType_Rank) $ "\n" $
						"        " $ Unit.GetName(eNameType_Last) $ "\n" $
						"        " $ Unit.GetName(eNameType_Nick) $ "\n" $
						Unit.GetSoldierClassTemplate().DisplayName);
}

simulated function CreateRandomSoldier(int TechLevel)
{

}