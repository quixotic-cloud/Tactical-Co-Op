//---------------------------------------------------------------------------------------
//  FILE:    UITacticalQuickLaunch_UnitAbilities.uc
//  AUTHOR:  Joshua Bouscher
//  PURPOSE: Allow for normal and full debug editing of a unit's abilities.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class UITacticalQuickLaunch_UnitAbilities extends UIScreen;

var private X2SoldierClassTemplate  SoldierClassTemplate;
var private array<SCATProgression>  arrProgression;
var private UITacticalQuickLaunch_UnitSlot OriginatingSlot;
var private array<name>     m_arrTemplateNames;

var private int         m_ypos;
var private UIPanel   m_kContainer;
var private UIText m_kTitle;
var private UIButton m_kSaveButton;
var private UIButton m_kCancelButton;
var private array<UICheckbox>   m_arrAbilityCheckboxes;

simulated function InitAbilities(UITacticalQuickLaunch_UnitSlot Slot)
{
	local UIPanel kBG;

	// Create Container
	m_kContainer = Spawn(class'UIPanel', self);
	m_kContainer.InitPanel();

	// Create BG
	kBG = Spawn(class'UIBGBox', m_kContainer).InitBG('BG', 0, 0, 1240, 620);

	// Center Container using BG
	m_kContainer.CenterWithin(kBG);

	// Create Title text
	m_kTitle = Spawn(class'UIText', m_kContainer);
	m_kTitle.InitText('', Slot.m_FirstName @ Slot.m_NickName @ Slot.m_LastName, true);
	m_kTitle.SetPosition(500, 10).SetWidth(kBG.width);

	m_kSaveButton = Spawn(class'UIButton', m_kContainer).InitButton('', "Save & Close", SaveButton, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	m_kSaveButton.SetPosition(10, 10);
	m_kCancelButton = Spawn(class'UIButton', m_kContainer).InitButton('', "Cancel", CancelButton, eUIButtonStyle_BUTTON_WHEN_MOUSE);
	m_kCancelButton.SetPosition(10, 42);

	OriginatingSlot = Slot;
	SoldierClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(Slot.m_nSoldierClassTemplate);
	arrProgression = Slot.m_arrSoldierProgression;
	BuildSoldierAbilities();
}

simulated function BuildSoldierAbilities()
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local UICheckbox AbilityBox;
	local SCATProgression Progression;
	local string Display;
	local int i, j;
	local array<bool> arrEarned;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplate AbilityTemplate;

	m_arrTemplateNames.Length = 0;
	m_ypos = 90;
	for (i = 0; i < SoldierClassTemplate.GetMaxConfiguredRank(); ++i)
	{
		AbilityTree = SoldierClassTemplate.GetAbilityTree(i);
		for (j = 0; j < AbilityTree.Length; ++j)
		{
			if (AbilityTree[j].AbilityName != '')
			{
				m_arrTemplateNames.AddItem(AbilityTree[j].AbilityName);
				arrEarned.AddItem(false);
				
				foreach arrProgression(Progression)
				{
					if (Progression.iRank == i && Progression.iBranch == j)
					{
						arrEarned[arrEarned.Length - 1] = true;
						break;
					}
				}
			}
		}
	}
	`assert(arrEarned.Length == m_arrTemplateNames.Length);
	//  Now m_arrTemplateNames is filled out, so populate the UI controls
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for (i = 0; i < m_arrTemplateNames.Length; ++i)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(m_arrTemplateNames[i]);
		if (AbilityTemplate == none)
			Display = "MISSING TEMPLATE!" @ "(" $ string(m_arrTemplateNames[i]) $ ")";
		else
			Display = AbilityTemplate.LocFriendlyName @ "(" $ string(m_arrTemplateNames[i]) $ ")";

		AbilityBox = Spawn(class'UICheckbox', m_kContainer).InitCheckbox('', Display, arrEarned[i]);
		AbilityBox.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(10, m_ypos);
		m_arrAbilityCheckboxes.AddItem(AbilityBox);
		m_ypos += 32;
	}
	`assert(m_arrAbilityCheckboxes.Length == m_arrTemplateNames.Length);
}

simulated function SaveButton(UIButton kButton)
{
	local SCATProgression Progress;
	local array<SoldierClassAbilityType> AbilityTree;
	local int i, j, k, iChecked;

	arrProgression.Length = 0;
	iChecked = 0;

	for (i = 0; i < m_arrAbilityCheckboxes.Length; ++i)
	{
		if (m_arrAbilityCheckboxes[i].bChecked)
		{			
			iChecked += 1;
			for (j = 0; j < SoldierClassTemplate.GetMaxConfiguredRank(); ++j)
			{
				AbilityTree = SoldierClassTemplate.GetAbilityTree(j);
				for (k = 0; k < AbilityTree.Length; ++k)
				{
					if (AbilityTree[k].AbilityName == m_arrTemplateNames[i])
					{
						Progress.iRank = j;
						Progress.iBranch = k;
						//  @TODO gameplay / UI - handle elite training on this screen
						arrProgression.AddItem(Progress);						
						break;
					}
				}
			}
		}
	}
	`assert(iChecked == arrProgression.Length);
	OriginatingSlot.m_arrSoldierProgression = arrProgression;
	OriginatingSlot.RefreshDropdowns();     //  if abilities changed a slot's availability, it should update it now

	Movie.Stack.Pop(self);
}

simulated function CancelButton(UIButton kButton)
{
	Movie.Stack.Pop(self);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			SaveButton(none);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CancelButton(none);
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	bConsumeMouseEvents = true;
}