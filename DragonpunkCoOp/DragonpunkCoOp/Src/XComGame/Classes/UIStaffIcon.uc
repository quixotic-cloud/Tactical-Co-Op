//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStaffIcon.uc
//  AUTHOR:  Brittany Steiner 4/27/2014
//  PURPOSE: UIPanel to load a dynamic image icon and set background coloring. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIStaffIcon extends UIIcon;

enum EUIStaffIconType
{
	eUIFG_GenericStaff,
	eUIFG_GenericStaffEmpty,
	eUIFG_Science,
	eUIFG_ScienceEmpty,
	eUIFG_Engineer,
	eUIFG_EngineerEmpty,
	eUIFG_Upgrade,
	eUIFG_Soldier,
	eUIFG_SoldierEmpty,
};

var EUIStaffIconType Type;
var UIStaffIcon_Tooltip ItemTooltip;

simulated function UIIcon InitStaffIcon()
{
	super.InitIcon();

	//If we decide to use custom art instead of the generic square, then turn off the SetBGShade call
	// and enable the LoadIconBG call. -bsteiner 
	SetBGShape(eSquare);
	//LoadIconBG(class'UIUtilities_Image'.const.FacilityStatus_Staff_BG);

	SetSize(28, 28);
	return self;
}

simulated function SetType(EUIStaffIconType eType)
{
	local string IconColor, IconImage;
	local float DesiredY; 
	
	//Check to see if we even need to make any updates. 
	if( eType == Type )
		return; 

	Type = eType;
	DesiredY = 0; //Default, unless overwritten in the switch.

	switch( Type )
	{
	case eUIFG_Soldier:
		IconColor = class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff;
		break;

	case eUIFG_SoldierEmpty:
		IconColor = class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff_Empty;
		break;

	case eUIFG_Science:
		IconColor = class'UIUtilities_Colors'.const.SCIENCE_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff;
		break; 

	case eUIFG_ScienceEmpty:
		IconColor = class'UIUtilities_Colors'.const.SCIENCE_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff_Empty;
		break;

	case eUIFG_Engineer:
		IconColor = class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff;
		break;

	case eUIFG_EngineerEmpty:
		IconColor = class'UIUtilities_Colors'.const.ENGINEERING_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff_Empty;
		break;

	case eUIFG_GenericStaff:
		IconColor = class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff;
		break;

	case eUIFG_GenericStaffEmpty:
		IconColor = class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Staff_Empty;
		break;


	case eUIFG_Upgrade:
		IconColor = class'UIUtilities_Colors'.const.CASH_HTML_COLOR;
		IconImage = class'UIUtilities_Image'.const.FacilityStatus_Health; //TODO: @bsteiner make this a final icon.
		break;

	default:
		IconColor = class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR;
		break;
	}

	SetY(DesiredY);
	EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.BLACK_HTML_COLOR, IconColor);
	LoadIcon(IconImage);
}

simulated function BuildStaffTooltip(StaffUnitInfo UnitInfo)
{
	if( ItemTooltip == none )
	{
		ItemToolTip = Spawn(class'UIStaffIcon_Tooltip', Movie.Pres.m_kTooltipMgr);
		ItemToolTip.InitTooltip();
		bHasTooltip = true;
	}

	ItemToolTip.UnitInfo = UnitInfo;
	ItemToolTip.SlotRef.ObjectID = -1;
	ItemToolTip.targetPath = string(MCPath);
	ItemToolTip.tDelay = 0;

	ItemToolTip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(ItemToolTip);

	//RemoveTooltip();
	//SetTooltipText(Staffer.GetName(eNameType_Full) @"(" $Staffer.GetSkillLevel() $")\n" $ class'UIUtilities_Strategy'.static.GetPersonnelStatus(Staffer) );
}

simulated function BuildAssignedStaffTooltip(XComGameState_HeadquartersRoom Room, int SlotIndex)
{
	local StateObjectReference StaffSlotRef;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_Unit Staffer;
	local StaffUnitInfo UnitInfo;
	
	if(ItemToolTip != none)
	{
		Movie.Pres.m_kTooltipMgr.RemoveTooltipByID(ItemToolTip.ID);
		ItemToolTip = none;
	}

	if (!Room.HasFacility())
	{
		StaffSlotState = Room.GetBuildSlot(SlotIndex);
		StaffSlotRef = StaffSlotState.GetReference();
	}
	else
	{
		Facility = Room.GetFacility();
		StaffSlotState = Facility.GetStaffSlot(SlotIndex);
		StaffSlotRef = StaffSlotState.GetReference();
	}

	Staffer = StaffSlotState.GetAssignedStaff();
	if( Staffer != none )
	{
		//SetTooltipText(StaffSlotState.GetNameDisplayString() @"(" $Staffer.GetSkillLevel() $")\n" $ Caps(StaffSlotState.GetBonusDisplayString()));
		
		if( ItemTooltip == none )
		{
			ItemToolTip = Spawn(class'UIStaffIcon_Tooltip', Movie.Pres.m_kTooltipMgr);
			ItemToolTip.InitTooltip();
			bHasTooltip = true;
		}
		
		UnitInfo.UnitRef = Staffer.GetReference();
		UnitInfo.bGhostUnit = StaffSlotState.IsSlotFilledWithGhost();
		UnitInfo.GhostLocation = StaffSlotRef;

		ItemToolTip.UnitInfo = UnitInfo;
		ItemToolTip.SlotRef = StaffSlotRef;
		ItemToolTip.targetPath = string(MCPath);
		ItemToolTip.tDelay = 0;

		ItemToolTip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(ItemToolTip);

	}
	else
	{
		SetTooltipText(StaffSlotState.GetNameDisplayString() $ "\n" $Caps(StaffSlotState.GetBonusDisplayString()));
	}
}

defaultproperties
{
	bIsNavigable = true;
	bProcessesMouseEvents = true;
	bEnableMouseAutoColor = true; 
	bAnimateOnInit = false;

	DefaultForegroundColor = "";
	DefaultBGColor = "";
}
