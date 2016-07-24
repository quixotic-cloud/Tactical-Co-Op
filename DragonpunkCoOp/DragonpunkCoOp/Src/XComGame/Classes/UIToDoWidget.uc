//---------------------------------------------------------------------------------------
//  FILE:    UIToDoWidget.uc
//  AUTHOR:  Brit Steiner --  9/29/2014
//  PURPOSE:Soldier category options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIToDoWidget extends UIPanel;

enum UIToDoCategory
{
	eUIToDoCat_Research,
	eUIToDoCat_Engineering,
	eUIToDoCat_Power,
	eUIToDoCat_Resistance,
	eUIToDoCat_Income,
	eUIToDoCat_Staffing,
	eUIToDoCat_ProvingGround,
	eUIToDoCat_SoldierStatus,
	eUIToDoCat_MAX
};

enum EUIToDoMsgUrgency
{
	eUIToDoMsgUrgency_Low,
	eUIToDoMsgUrgency_Medium,
	eUIToDoMsgUrgency_High,
};

struct UIToDoMessage
{
	var string Label;
	var string Description;
	var StateObjectReference HotLinkRef;
	var EUIToDoMsgUrgency Urgency;
	var delegate<MsgCallback> OnItemClicked; 
};

struct UIToDoMessageCategory
{
	var UIIcon Icon; 
	var array<UIToDoMessage> Messages; 
};

//----------------------------------------------------------------------------
// MEMBERS

var localized string DescNoCurrentResearchText;
var localized string DescLowScienceScoreText;
var localized string DescLowIntelDatapadsText;
var localized string DescGatedPriorityResearchText;
var localized string DescLowEngineeringScoreText;
var localized string DescLowPowerText;
var localized string DescReallyLowPowerText;
var localized string DescNoResCommsContactsText;
var localized string DescNoRadioRelaysText;
var localized string DescLowIncomeText;
var localized string DescNoIncomeText;
var localized string DescBeginExcavationText;
var localized string DescEmptyBuildSlotText;
var localized string DescEmptyClearSlotText;
var localized string DescEmptyStaffSlotText;
var localized string DescEmptySciSlotText;
var localized string DescEmptyEngSlotText;
var localized string DescEmptySoldierSlotText;
var localized string DescIdleStaffText;
var localized string DescLockedSciSlotText;
var localized string DescLockedEngSlotText;
var localized string DescLockedSoldierSlotText;
var localized string DescUnusedEleriumCoresText;
var localized string DescNotSquadFillSoldiersText;
var localized string DescLowSoldiersText;
var localized string DescSoldierPromotionText;

var localized string LabelNoCurrentResearchText;
var localized string LabelLowScienceScoreText;
var localized string LabelLowIntelDatapadsText;
var localized string LabelLowEngineeringScoreText;
var localized string LabelLowPowerText;
var localized string LabelReallyLowPowerText;
var localized string LabelNoRadioRelaysText;
var localized string LabelNoResCommsContactsText;
var localized string LabelLowIncomeText;
var localized string LabelNoIncomeText;
var localized string LabelBeginExcavationText;
var localized string LabelEmptyStaffSlotText;
var localized string LabelEmptySciSlotText;
var localized string LabelEmptyEngSlotText;
var localized string LabelEmptySoldierSlotText;
var localized string LabelIdleStaffText;
var localized string LabelLockedSciSlotText;
var localized string LabelLockedEngSlotText;
var localized string LabelLockedSoldierSlotText;
var localized string LabelUnusedEleriumCoresText;
var localized string LabelNotSquadFillSoldiersText;
var localized string LabelLowSoldiersText;
var localized string LabelSoldierPromotionText;

var UIPanel			Container;
var UIList				List;
var UIColorSelector	ColorSelector;
var UIScreenListener		ScreenListener;

var array<UIToDoMessageCategory> Categories;
var int							 CurrentCategory; 
var int							 TotalCategoryWidth; 

delegate MsgCallback(optional StateObjectReference Facility);


//----------------------------------------------------------------------------
// FUNCTIONS


simulated function UIToDoWidget InitToDoWidget(optional name InitName)
{
	local int i; 
	local UIIcon Icon; 

	InitPanel(InitName);
	SetSize(300, 600);
	RealizeLocation();

	// ---------------------------------------------------------

	//Spawn container first, so that the list shows beneath the category list. 
	Container = Spawn(class'UIPanel', self).InitPanel('');

	// ---------------------------------------------------------

	Categories.length = eUIToDoCat_MAX;

	for( i = eUIToDoCat_MAX - 1; i >= 0; i-- )
	{
		Icon = Spawn(class'UIIcon', self).InitIcon(Name("CatImage_" $ i),,,,32);
		Icon.SetBGShape(eHexagon);
		Icon.ProcessMouseEvents( OnCategoryMouseEvent );
		Icon.Hide(); // starts off hidden
		Icon.bDisableSelectionBrackets = true;
		Categories[i].Icon = Icon; 
	}

	// ---------------------------------------------------------

	// Create Container
	Container.SetY(Icon.Height);
	Container.SetSize(600, 500);

	List = Spawn(class'UIList', Container);
	List.BGPaddingBottom = 100;
	List.InitList('', 10, 0, width - 20, height - 10, , true);
	List.BG.SetAlpha(80);
	List.OnItemClicked = OnListItemCallback;
	List.OnItemDoubleClicked = OnListItemCallback;
	List.OnSelectionChanged = ClearDelayTimerFromList;
	List.bStickyHighlight = false;
	List.BG.ProcessMouseEvents(OnBGMouseEvent);
	HideList();

	// ---------------------------------------------------------
	
	UpdateCategories();
	
	// ---------------------------------------------------------

	return self;
}

// to avoid updating the widget if we're cycling through facilities, we wait a frame before checking to make sure we're supposed to be visible
simulated function RequestCategoryUpdate()
{
	Movie.Pres.SubscribeToUIUpdate(ShouldUpdateCategories);
}

simulated function ShouldUpdateCategories()
{
	Movie.Pres.UnsubscribeToUIUpdate(ShouldUpdateCategories);
	if(Movie.Pres.ScreenStack.GetCurrentClass() == class'UIFacilityGrid')
	{
		UpdateCategories();
		Show();
	}
}

simulated function UpdateCategories()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int i, CurrentImageX;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	Categories[eUIToDoCat_Research].Messages = GetResearchMessages(History, XComHQ);
	Categories[eUIToDoCat_Engineering].Messages = GetEngineeringMessages(History, XComHQ);
	Categories[eUIToDoCat_Power].Messages = GetPowerMessages(History, XComHQ);
	Categories[eUIToDoCat_Resistance].Messages = GetResistanceMessages(History, XComHQ);
	Categories[eUIToDoCat_Income].Messages = GetIncomeMessages(History, XComHQ);
	Categories[eUIToDoCat_Staffing].Messages = GetStaffingMessages(History, XComHQ);
	Categories[eUIToDoCat_ProvingGround].Messages = GetProvingGroundMessages(History, XComHQ);
	Categories[eUIToDoCat_SoldierStatus].Messages = GetSoldierStatusMessages(History, XComHQ);
		
	CurrentImageX = 0; 
	for( i = 0; i < eUIToDoCat_MAX; i++ )
	{
		if( Categories[i].Messages.length > 0 )
		{
			//Icons stick together to the bottom left, so no blank spaces between icons. 
			Categories[i].Icon.Show();
			Categories[i].Icon.SetX(CurrentImageX);
			Categories[i].Icon.LoadIcon( class'UIUtilities_Image'.static.GetToDoWidgetImagePath(i) );
			CurrentImageX += Categories[i].Icon.Width + 2;

			if(CurrentCategory == i && List.bIsVisible)
			{
				Categories[i].Icon.SetForegroundColorState( GetUrgencyColor(i) );
				Categories[i].Icon.SetBGColor( class'UIUtilities_Colors'.const.BLACK_HTML_COLOR );
			}
			else
			{
				Categories[i].Icon.SetForegroundColor( class'UIUtilities_Colors'.const.BLACK_HTML_COLOR );
				Categories[i].Icon.SetBGColorState( GetUrgencyColor(i) );
			}
		}
		else
		{
			Categories[i].Icon.Hide();
		}
	}
	TotalCategoryWidth = CurrentImageX;
}

simulated function ShowList( int eCat )
{
	local int i; 
	local UIListItemString Item; 
	
	List.ClearItems();
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath( string(MCPath) );

	for( i = 0; i < Categories[eCat].Messages.length; i++ )
	{
		Item = Spawn(class'UIListItemString', List.itemContainer);
		Item.InitListItem( Categories[eCat].Messages[i].Label );
		Item.SetTooltipText(Categories[eCat].Messages[i].Description,,,,false,class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT);

		switch( Categories[eCat].Messages[i].Urgency )
		{
		case eUIToDoMsgUrgency_Low: 
			//Do nothing
			break;
		case eUIToDoMsgUrgency_Medium: 
			Item.SetWarning(true);
			break;
		case eUIToDoMsgUrgency_High: 
			Item.SetBad(true);
			break;
		}

		
		/*Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox( Categories[eCat].Messages[i].Description, 
			0, 
			0, 
			string(ListItem.MCPath), 
			,,
			class'UIUtilities'.const.ANCHOR_BOTTOM_LEFT,
			true );*/
	}

	List.SetY(-List.ShrinkToFit() - 42);
	List.Show();
}
simulated function HideList()
{
	List.Hide();	
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath( string(MCPath) );
}

simulated function RefreshLocation()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	AnchorBottomLeft();

	//Stick to the left side of the shortcuts menu
	if(!XComHQ.IsContactResearched())
	{
		SetPosition(80, -60); //Lined up centered with the back button
	}
	else
	{
		SetPosition(150, -60);
	}
}

//------------------------------------------------------
// We care when you mouse IN to a category, and change the category.
simulated function OnCategoryMouseEvent(UIPanel Control, int cmd)
{
	local int iNewCat; 

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		ClearDelayTimer();
		iNewCat = int(GetRightMost(Control.MCName));
		if( iNewCat != CurrentCategory || !List.bIsVisible )
		{
			CurrentCategory = iNewCat;
			ShowList(CurrentCategory);
		}
		RefreshCategoryIcons();
		//`log("Selected CurrentCategory: " $ CurrentCategory);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE: //Snap this shut when you've clicked elsewhere. 
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		TryToStartDelayTimer();
		break;
	}
}
// We care if you've moused out only from the overall movieclip in general. 
simulated function OnBGMouseEvent(UIPanel Control, int cmd)
{
	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN: 
		ClearDelayTimer(); 
		break; 

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE: //Snap this shut when you've clicked elsewhere. 
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		TryToStartDelayTimer();
		break;
	}

}

simulated function ClearDelayTimerFromList(UIList ContainerList, int ItemIndex)
{
	ClearDelayTimer();
}
simulated function ClearDelayTimer()
{
	ClearTimer('CloseAfterDelay');
}

simulated function TryToStartDelayTimer()
{	
	local string TargetPath; 
	local int iFoundIndex; 

	TargetPath = Movie.GetPathUnderMouse();
	iFoundIndex = InStr(TargetPath, MCName);

	if( iFoundIndex == -1 ) //We're moused completely off this movie clip, which includes all children.
	{
		SetTimer(1.0, false, 'CloseAfterDelay');
	}
}
simulated function CloseAfterDelay()
{
	HideList();
	CurrentCategory = -1; 
	RefreshCategoryIcons();
}

simulated function RefreshCategoryIcons()
{
	local int i; 

	for( i = 0; i < eUIToDoCat_MAX; i++ )
	{
		if(CurrentCategory == i && List.bIsVisible)
		{
			Categories[i].Icon.SetForegroundColorState( GetUrgencyColor(i) );
			Categories[i].Icon.SetBGColor( class'UIUtilities_Colors'.const.BLACK_HTML_COLOR );
		}
		else
		{
			Categories[i].Icon.SetForegroundColor( class'UIUtilities_Colors'.const.BLACK_HTML_COLOR );
			Categories[i].Icon.SetBGColorState( GetUrgencyColor(i) );
		}
	}
}
simulated function OnListItemCallback(UIList ContainerList, int ItemIndex)
{
	local UIToDoMessage Msg; 
	local delegate<MsgCallback> MsgCallback; 
	
	Msg = Categories[CurrentCategory].Messages[ItemIndex]; 
	MsgCallback = Msg.OnItemClicked;

	if( MsgCallback != none )
	{
		//`HQPRES.ClearToFacilityMainMenu();
		MsgCallback(Msg.HotLinkRef);
	}

	Movie.Pres.m_kTooltipMgr.HideAllTooltips();
	CloseAfterDelay();
}

//------------------------------------------------------

//----------------------------------------------------------------------------
// GATHER MESSAGE FUNCTIONS

function array<UIToDoMessage> GetResearchMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_FacilityXCom FacilityState;
	local array<UIToDoMessage> Messages;
	local UIToDoMessage Msg;

	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	FacilityState = XComHQ.GetFacilityByName('PowerCore');

	if (!XComHQ.HasResearchProject() && !XComHQ.HasShadowProject() && 
		(XComHQ.HasTechsAvailableForResearchWithRequirementsMet() || XComHQ.HasTechsAvailableForResearchWithRequirementsMet(true)))
	{
		Msg.Label = LabelNoCurrentResearchText;
		Msg.Description = DescNoCurrentResearchText;
		Msg.HotLinkRef = FacilityState.GetReference();
		Msg.Urgency = eUIToDoMsgUrgency_High;
		Msg.OnItemClicked = ChooseResearchHotlink;
		Messages.AddItem(Msg);
	}
	
	// if any high priority tech is above current science score
	if (ResHQ.NumMonths > 0)
	{
		if (XComHQ.HasGatedPriorityResearch())
		{
			Msg.Label = LabelLowScienceScoreText;
			Msg.Description = DescGatedPriorityResearchText;
			Msg.Urgency = eUIToDoMsgUrgency_Medium;
			Msg.OnItemClicked = LowScientistsPopup;
			Messages.AddItem(Msg);
		}
		else if (XComHQ.GetPercentSlowTechs() > 50) // if 50% of non-autopsy, non-repeatable techs are projected to take a long time
		{
			Msg.Label = LabelLowScienceScoreText;
			Msg.Description = DescLowScienceScoreText;
			Msg.Urgency = eUIToDoMsgUrgency_Medium;
			Msg.OnItemClicked = LowScientistsPopup;
			Messages.AddItem(Msg);
		}
	}
	
	return Messages;
}

function array<UIToDoMessage> GetEngineeringMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local array<UIToDoMessage> Messages;
	local UIToDoMessage Msg;
	
	// If any weapon or armor is above current engineering score
	if (XComHQ.HasGatedEngineeringItem())
	{
		Msg.Label = LabelLowEngineeringScoreText;
		Msg.Description = DescLowEngineeringScoreText;
		Msg.Urgency = eUIToDoMsgUrgency_Medium;
		Msg.OnItemClicked = LowEngineersPopup;
		Messages.AddItem(Msg);
	}

	return Messages;
}

function array<UIToDoMessage> GetPowerMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_FacilityXCom PowerRelayState;
	local array<UIToDoMessage> Messages;
	local UIToDoMessage Msg;

	PowerRelayState = XComHQ.GetFacilityByNameWithAvailableStaffSlots('PowerRelay');
	
	if (XComHQ.PowerState == ePowerState_Red)
	{
		Msg.Label = LabelReallyLowPowerText;
		Msg.Description = DescReallyLowPowerText;
		Msg.Urgency = eUIToDoMsgUrgency_High;
		Msg.OnItemClicked = BuildStaffUpgradeFacilityHotlink;
		if (PowerRelayState != none)
			Msg.HotLinkRef = PowerRelayState.GetReference();
		Messages.AddItem(Msg);
	}

	return Messages;
}

function array<UIToDoMessage> GetResistanceMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_FacilityXCom ResistanceCommsState, PowerCoreState;
	local array<UIToDoMessage> Messages;
	local UIToDoMessage Msg;
	local int ContactCost;

	ResistanceCommsState = XComHQ.GetFacilityByNameWithAvailableStaffSlots('ResistanceComms');
	PowerCoreState = XComHQ.GetFacilityByName('PowerCore');

	if (XComHQ.GetRemainingContactCapacity() == 0 && XComHQ.HasRegionsAvailableForContact())
	{
		Msg.Label = LabelNoResCommsContactsText;
		Msg.Description = DescNoResCommsContactsText;
		Msg.Urgency = eUIToDoMsgUrgency_High;
		Msg.OnItemClicked = BuildStaffUpgradeFacilityHotlink;
		if (ResistanceCommsState != none)
			Msg.HotLinkRef = ResistanceCommsState.GetReference();
		Messages.AddItem(Msg);
	}

	if (!XComHQ.IsOutpostResearched())
	{
		ContactCost = class'XComGameState_WorldRegion'.default.ContactIntelCost[`DIFFICULTYSETTING];
		if (class'UIUtilities_Strategy'.static.GetMinimumContactCost() >= (ContactCost * 2))
		{
			Msg.Label = LabelNoRadioRelaysText;
			Msg.Description = DescNoRadioRelaysText;
			Msg.HotLinkRef = PowerCoreState.GetReference();
			Msg.Urgency = eUIToDoMsgUrgency_Medium;
			Msg.OnItemClicked = ChooseResearchHotlink;
			Messages.AddItem(Msg);
		}
	}
	
	// If the player does not have enough Intel to make contact
	if (XComHQ.GetIntel() < class'UIUtilities_Strategy'.static.GetMinimumContactCost() && XComHQ.IsContactResearched())
	{
		Msg.Label = LabelLowIntelDatapadsText;
		Msg.Description = DescLowIntelDatapadsText;
		Msg.Urgency = eUIToDoMsgUrgency_High;
		Msg.OnItemClicked = LowIntelPopup;
		Messages.AddItem(Msg);
	}

	return Messages;
}

function array<UIToDoMessage> GetIncomeMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_FacilityXCom BridgeState;
	local array<UIToDoMessage> Messages;
	local UIToDoMessage Msg;
	local int iCurrentIncome;

	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	BridgeState = XComHQ.GetFacilityByName('CIC');

	if (XComHQ.IsContactResearched())
	{
		iCurrentIncome = ResHQ.GetSuppliesReward();

		if (iCurrentIncome <= 0)
		{
			Msg.Label = LabelNoIncomeText;
			Msg.Description = DescNoIncomeText;
			Msg.Urgency = eUIToDoMsgUrgency_High;
			Msg.OnItemClicked = SelectFacilityHotlink;
			if (BridgeState != none)
				Msg.HotLinkRef = BridgeState.GetReference();
			Messages.AddItem(Msg);
		}
		else if (iCurrentIncome < 100)
		{
			Msg.Label = LabelLowIncomeText;
			Msg.Description = DescLowIncomeText;
			Msg.Urgency = eUIToDoMsgUrgency_Medium;
			Msg.OnItemClicked = SelectFacilityHotlink;
			if (BridgeState != none)
				Msg.HotLinkRef = BridgeState.GetReference();
			Messages.AddItem(Msg);
		}
	}

	return Messages;
}

function array<UIToDoMessage> GetStaffingMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	local X2FacilityTemplate FacilityTemplate;
	local array<StaffUnitInfo> UnstaffedEngineers;
	local array<UIToDoMessage> Messages;
	local StaffUnitInfo UnitInfo;
	local UIToDoMessage Msg;

	if (XComHQ.GetNumberOfUnstaffedEngineers() > 0)
	{
		UnstaffedEngineers = XComHQ.GetUnstaffedEngineers();

		foreach UnstaffedEngineers(UnitInfo)
		{
			// Only display the to do warning if we have a real engineer available, not a ghost
			if (!UnitInfo.bGhostUnit)
			{
				Msg.Label = LabelEmptyEngSlotText;
				Msg.Description = LabelEmptyEngSlotText;
				Msg.Urgency = eUIToDoMsgUrgency_High;
				Msg.OnItemClicked = EngineerInfoPopup;
				Msg.HotLinkRef = UnitInfo.UnitRef;
				Messages.AddItem(Msg);

				break;
			}
		}		
	}

	foreach History.IterateByClassType(class'XComGameState_HeadquartersRoom', RoomState)
	{
		if (RoomState.HasFacility())		
		{
			FacilityState = RoomState.GetFacility();

			if (FacilityState.DisplayStaffingInfo()) // First check if staff slot info should be shown for this facility
			{
				if (FacilityState.HasEmptyScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0)
				{
					StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptySciStaffSlotIndex());
					if (StaffSlotState.ShouldDisplayToDoWarning())
					{
						FacilityTemplate = FacilityState.GetMyTemplate();

						Msg.Label = LabelEmptySciSlotText @ FacilityTemplate.DisplayName;
						Msg.Description = DescEmptySciSlotText @ StaffSlotState.GetBonusDisplayString();
						Msg.Urgency = eUIToDoMsgUrgency_High;
						Msg.OnItemClicked = StaffSlotHotlink;
						Msg.HotLinkRef = FacilityState.GetReference();
						Messages.AddItem(Msg);
					}
				}

				if (FacilityState.HasEmptySoldierSlot())
				{
					StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptySoldierStaffSlotIndex());
					if (StaffSlotState.ShouldDisplayToDoWarning())
					{
						FacilityTemplate = FacilityState.GetMyTemplate();

						Msg.Label = LabelEmptySoldierSlotText @ FacilityTemplate.DisplayName;
						Msg.Description = DescEmptySoldierSlotText @ StaffSlotState.GetBonusDisplayString();
						Msg.Urgency = eUIToDoMsgUrgency_High;
						Msg.OnItemClicked = StaffSlotHotlink;
						Msg.HotLinkRef = FacilityState.GetReference();
						Messages.AddItem(Msg);
					}
				}

				if (FacilityState.HasIdleStaff())
				{
					StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetIdleStaffSlotIndex());
					FacilityTemplate = FacilityState.GetMyTemplate();

					Msg.Label = LabelIdleStaffText @ FacilityTemplate.DisplayName;
					Msg.Description = DescIdleStaffText;
					Msg.Urgency = eUIToDoMsgUrgency_Medium;
					Msg.OnItemClicked = StaffSlotHotlink;
					Msg.HotLinkRef = FacilityState.GetReference();
					Messages.AddItem(Msg);
				}
			}
		}
	}

	return Messages;
}

function array<UIToDoMessage> GetProvingGroundMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_FacilityXCom ProvingGroundState;
	local array<UIToDoMessage> Messages;
	local UIToDoMessage Msg;

	ProvingGroundState = XComHQ.GetFacilityByName('ProvingGround');

	if (ProvingGroundState != none && XComHQ.HasItemByName('EleriumCore') && ProvingGroundState.BuildQueue.Length == 0)
	{
		Msg.Label = LabelUnusedEleriumCoresText;
		Msg.Description = DescUnusedEleriumCoresText;
		Msg.Urgency = eUIToDoMsgUrgency_Low;
		Msg.OnItemClicked = SelectFacilityHotlink;
		Msg.HotLinkRef = ProvingGroundState.GetReference();
		Messages.AddItem(Msg);
	}

	return Messages;
}

function array<UIToDoMessage> GetSoldierStatusMessages(XComGameStateHistory History, XComGameState_HeadquartersXCom XComHQ)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Unit UnitState;
	local array<UIToDoMessage> Messages;
	local UIToDoMessage Msg;
	local int idx;

	FacilityState = XComHQ.GetFacilityByName('Hangar');

	if (XComHQ.GetNumberOfDeployableSoldiers() == 0)
	{
		Msg.Label = LabelNotSquadFillSoldiersText;
		Msg.Description = DescNotSquadFillSoldiersText;
		Msg.Urgency = eUIToDoMsgUrgency_High;
		Msg.HotLinkRef = FacilityState.GetReference();
		Msg.OnItemClicked = RecruitSoldierHotlink;
		Messages.AddItem(Msg);
	}
	else if (XComHQ.GetNumberOfDeployableSoldiers() < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
	{
		Msg.Label = LabelLowSoldiersText;
		Msg.Description = DescLowSoldiersText;
		Msg.Urgency = eUIToDoMsgUrgency_Medium;
		Msg.HotLinkRef = FacilityState.GetReference();
		Msg.OnItemClicked = RecruitSoldierHotlink;
		Messages.AddItem(Msg);
	}
	
	for (idx = 0; idx < XComHQ.Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(XComHQ.Crew[idx].ObjectID));

		if (UnitState != none && UnitState.IsASoldier() && (UnitState.CanRankUpSoldier() || UnitState.HasAvailablePerksToAssign()))
		{
			Msg.Label = LabelSoldierPromotionText @ UnitState.GetName(eNameType_RankFull);
			Msg.Description = UnitState.GetName(eNameType_RankFull) @ DescSoldierPromotionText;
			Msg.Urgency = eUIToDoMsgUrgency_Low;
			Msg.HotLinkRef = UnitState.GetReference();
			Msg.OnItemClicked = PromoteSoldierHotlink;
			Messages.AddItem(Msg);
		}
	}

	return Messages;
}

//----------------------------------------------------------------------------
// HOTLINK FUNCTIONS

function ChooseResearchHotlink(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local bool bInstantInterp;

	bInstantInterp = NeedsInstantInterp();
	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityRef);

	// get to choose research screen
	`HQPRES.UIChooseResearch(bInstantInterp);
}

function BuildStaffUpgradeFacilityHotlink(optional StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local UIFacility CurrentFacilityScreen;
	local int emptyStaffSlotIndex;

	History = `XCOMHISTORY;
	
	// If XComHQ does not have a lab/workshop, go to the build facilities screen
	if (FacilityRef.ObjectID == 0)
	{
		`HQPRES.ClearUIToHUD();
		`HQPRES.UIBuildFacilities();
	}
	else // A lab/workshop exists
	{
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityRef);

		if (FacilityState.GetNumEmptyStaffSlots() > 0) // First check if there are any open staff slots
		{
			// get to choose scientist screen (from staff slot)
			CurrentFacilityScreen = UIFacility(Movie.Stack.GetCurrentScreen());
			emptyStaffSlotIndex = FacilityState.GetEmptyStaffSlotIndex();
			if (CurrentFacilityScreen != none && emptyStaffSlotIndex > -1)
			{
				CurrentFacilityScreen.ClickStaffSlot(emptyStaffSlotIndex);
			}
		}
		else if (FacilityState.GetNumLockedStaffSlots() > 0) // Then check if there are any locked staff slots
		{
			// get to choose upgrade screen
			`HQPRES.UIFacilityUpgrade(FacilityState.GetReference());
		}
	}
}

function SelectRoomHotlink(StateObjectReference RoomRef)
{
	class'UIUtilities_Strategy'.static.SelectRoom(RoomRef);
}

function SelectFacilityHotlink(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityRef);
}

function UpgradeFacilityHotlink(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityRef);

	if (FacilityState.GetNumLockedStaffSlots() > 0) // Then check if there are any locked staff slots
	{
		`HQPRES.UIFacilityUpgrade(FacilityState.GetReference());
	}
}

function RoomSlotHotlink(StateObjectReference RoomRef)
{
	class'UIUtilities_Strategy'.static.SelectRoom(RoomRef);
}

function StaffSlotHotlink(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local UIFacility CurrentFacilityScreen;
	local int emptyStaffSlotIndex;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityRef);

	if (FacilityState.GetNumEmptyStaffSlots() > 0) // First check if there are any open staff slots
	{
		// get to choose scientist screen (from staff slot)
		CurrentFacilityScreen = UIFacility(Movie.Stack.GetCurrentScreen());
		emptyStaffSlotIndex = FacilityState.GetEmptyStaffSlotIndex();
		if (CurrentFacilityScreen != none && emptyStaffSlotIndex > -1)
		{
			CurrentFacilityScreen.ClickStaffSlot(emptyStaffSlotIndex);
		}
	}
}

function RecruitSoldierHotlink(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local UIFacility_Armory ArmoryScreen;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());

	ArmoryScreen = UIFacility_Armory(Movie.Stack.GetCurrentScreen());
	if (ArmoryScreen != none)
	{
		ArmoryScreen.Recruit();
	}
}

function PromoteSoldierHotlink(StateObjectReference UnitRef)
{
	`HQPRES.GoToArmoryPromotion(UnitRef, NeedsInstantInterp());
}

function LowEngineersPopup(StateObjectReference EmptyRef)
{
	`HQPRES.UILowEngineers();
}

function LowScientistsPopup(StateObjectReference EmptyRef)
{
	`HQPRES.UILowScientists();
}

function LowIntelPopup(StateObjectReference EmptyRef)
{
	`HQPRES.UILowIntel();
}

function EngineerInfoPopup(StateObjectReference UnitRef)
{
	`HQPRES.UIStaffInfo(UnitRef);
}

function bool NeedsInstantInterp()
{
	if(`HQPRES.ScreenStack.IsInStack(class'UIStrategyMap'))
	{
		return true;
	}

	return false;
}

simulated function int GetUrgencyLevel(int iCat)
{
	if( Categories[iCat].Messages.Find( 'Urgency', eUIToDoMsgUrgency_High ) > -1 )
		return eUIToDoMsgUrgency_High; 

	if( Categories[iCat].Messages.Find( 'Urgency', eUIToDoMsgUrgency_Medium ) > -1 )
		return eUIToDoMsgUrgency_Medium; 

	return eUIToDoMsgUrgency_Low; 

}


simulated function EUIState GetUrgencyColor(int iCat)
{
	if( Categories[iCat].Messages.Find( 'Urgency', eUIToDoMsgUrgency_High ) > -1 )
		return eUIState_Bad; 

	if( Categories[iCat].Messages.Find( 'Urgency', eUIToDoMsgUrgency_Medium ) > -1 )
		return eUIState_Warning; 

	return eUIState_Normal; 

}

simulated public function Show()
{
	local XComHeadquartersCheatManager CheatMgr;
	local UIStrategyMap StrategyMap;

	// If in Strategy check if todo widget hidden by cheat
	if(XComHQPresentationLayer(Movie.Pres) != none)
	{
		CheatMgr = XComHeadquartersCheatManager(GetALocalPlayerController().CheatManager);

		if(CheatMgr != none && CheatMgr.bHideTodoWidget)
		{
			return;
		}
	}

	// Hide if in the tutorial or flight mode
	StrategyMap = `HQPRES.StrategyMap2D;
	if (class'XComGameState_HeadquartersXCom'.static.AnyTutorialObjectivesInProgress() || (StrategyMap != none && StrategyMap.m_eUIState == eSMS_Flight))
	{
		return;
	}

	super.Show();
}

event Destroyed()
{
	Movie.Pres.UnsubscribeToUIUpdate(ShouldUpdateCategories);
	super.Destroyed();
}

//==============================================================================

defaultproperties
{
	MCName          = "ToDoWidget";	
	bIsNavigable		= false; 
}
