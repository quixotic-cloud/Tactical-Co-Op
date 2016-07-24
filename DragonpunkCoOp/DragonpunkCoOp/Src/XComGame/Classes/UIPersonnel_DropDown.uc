
class UIPersonnel_DropDown extends UIPanel
	dependson(UIPersonnel);

//----------------------------------------------------------------------------
// MEMBERS

// UI
var int m_iMaskWidth;
var int m_iMaskHeight;

var UIList m_kList;

// Gameplay
var XComGameState GameState; // setting this allows us to display data that has not yet been submitted to the history 
var XComGameState_HeadquartersXCom HQState;
var array<StaffUnitInfo> m_staff;
var StateObjectReference SlotRef;

// Delegates
var bool m_bRemoveWhenUnitSelected;
var public delegate<OnPersonnelSelected> onSelectedDelegate;
var public delegate<OnDropDownSizeRealized> OnDropDownSizeRealizedDelegate;

delegate OnPersonnelSelected(StaffUnitInfo selectedUnitInfo);
delegate OnButtonClickedDelegate(UIButton ButtonControl);
delegate OnDropDownSizeRealized(float CtlWidth, float CtlHeight);

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function InitDropDown(optional delegate<OnDropDownSizeRealized> OnDropDownSizeRealizedDel)
{	
	// Init UI
	super.InitPanel();

	m_kList = Spawn(class'UIList', self);
	m_kList.bIsNavigable = true;
	m_kList.InitList('listAnchor', , 5, m_iMaskWidth, m_iMaskHeight);
	m_kList.bStickyHighlight = false;
	m_kList.OnItemClicked = OnStaffSelected;
	
	OnDropDownSizeRealizedDelegate = OnDropDownSizeRealizedDel;
	
	HQState = class'UIUtilities_Strategy'.static.GetXComHQ();

	RefreshData();
}

simulated function ClearDelayTimer()
{
	ClearTimer('CloseMenu');
}

simulated function TryToStartDelayTimer()
{	
	local string TargetPath; 
	local int iFoundIndex; 

	TargetPath = Movie.GetPathUnderMouse();
	iFoundIndex = InStr(TargetPath, MCName);

	if( iFoundIndex == -1 ) //We're moused completely off this movie clip, which includes all children.
	{
		SetTimer(1.0, false, 'CloseMenu');
	}
}

simulated function CloseMenu()
{
	Hide();
}

simulated function Show()
{
	RefreshData();
	super.Show();
}

simulated function RefreshData()
{
	UpdateData();
	UpdateList();
}

simulated function UpdateData()
{
	local int i;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit; 
	local XComGameState_StaffSlot SlotState;
	local StaffUnitInfo UnitInfo;

	// Destroy old data
	m_staff.Length = 0;
		
	History = `XCOMHISTORY;
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));
		
	// If staff slot is filled and can be relocated, add an Empty Ref unit to represent the slot
	if (SlotState.IsSlotFilled())
	{
		m_staff.AddItem(UnitInfo);
	}
	
	// Add any existing ghost units to the list, but only if the staff slot doesn't provide them
	if (!SlotState.GetMyTemplate().CreatesGhosts)
		AddGhostUnits(SlotState);

	for(i = 0; i < HQState.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(HQState.Crew[i].ObjectID));

		UnitInfo.UnitRef = Unit.GetReference();
		UnitInfo.bGhostUnit = false;
		UnitInfo.GhostLocation.ObjectID = 0;

		if (SlotState.ValidUnitForSlot(UnitInfo))
		{
			m_staff.AddItem(UnitInfo);
		}
	}
}

simulated function AddGhostUnits(XComGameState_StaffSlot SlotState)
{
	local int i, iSlot, NumUnassignedGhostStaff;
	local array<XComGameState_StaffSlot> AdjacentGhostStaffSlots;
	local array<XComGameState_StaffSlot> GhostFilledStaffSlots;
	local XComGameState_StaffSlot GhostFilledSlot;
	local XComGameState_Unit Unit;
	local StaffUnitInfo UnitInfo;

	// If there are any ghost staff units created by adjacent slots, add them to the staff list
	AdjacentGhostStaffSlots = SlotState.GetAdjacentGhostCreatingStaffSlots();
	for (i = 0; i < AdjacentGhostStaffSlots.Length; i++)
	{
		NumUnassignedGhostStaff = AdjacentGhostStaffSlots[i].AvailableGhostStaff;
		Unit = AdjacentGhostStaffSlots[i].GetAssignedStaff();

		// Failsafe check to ensure that ghosts are only displayed for matching unit and staff slot references
		if (Unit.StaffingSlot.ObjectID == AdjacentGhostStaffSlots[i].ObjectID)
		{
			// Create ghosts duplicating the unit who is staffed in the ghost-creating slot
			UnitInfo.UnitRef = Unit.GetReference();
			UnitInfo.bGhostUnit = true;
			UnitInfo.GhostLocation.ObjectID = 0;

			// First add an item for each of the unassigned GREMLINs, if they are valid for the slot
			if (SlotState.ValidUnitForSlot(UnitInfo))
			{
				for (iSlot = 0; iSlot < NumUnassignedGhostStaff; iSlot++)
				{
					m_staff.AddItem(UnitInfo);
				}
			}

			// Then add an item for all of the GREMLINs which were created by the ghost creating slot, and are already assigned to slots adjacent to it
			GhostFilledStaffSlots = AdjacentGhostStaffSlots[i].GetAdjacentGhostFilledStaffSlots();
			for (iSlot = 0; iSlot < GhostFilledStaffSlots.Length; iSlot++)
			{
				GhostFilledSlot = GhostFilledStaffSlots[iSlot];
				UnitInfo.GhostLocation = GhostFilledStaffSlots[iSlot].GetReference();

				// Check if the ghost is allowed to be moved to the new slot, now that it has its correct current location
				if (SlotState.ValidUnitForSlot(UnitInfo))
				{
					// If the ghost-filled slot is in the same room or facility as the slot we want to fill, don't show that ghost in the list
					if ((GhostFilledSlot.Room.ObjectID != 0 && GhostFilledSlot.GetRoom().ObjectID != SlotState.GetRoom().ObjectID) ||
						(GhostFilledSlot.Facility.ObjectID != 0 && GhostFilledSlot.GetFacility().ObjectID != SlotState.GetFacility().ObjectID))
					{
						// Otherwise, add it to the dropdown as available to relocate
						m_staff.AddItem(UnitInfo);
					}
				}
			}
		}
	}
}

simulated function UpdateList()
{
	m_kList.ClearItems();
	PopulateListInstantly();
	m_kList.Navigator.SelectFirstAvailable();
}

simulated function UpdateItemWidths()
{
	local int Idx;
	local float MaxWidth, MaxHeight;

	for ( Idx = 0; Idx < m_kList.itemCount; ++Idx )
	{
		if ( !UIPersonnel_DropDownListItem(m_kList.GetItem(Idx)).bSizeRealized )
		{
			return;
		}

		MaxWidth = Max(MaxWidth, m_kList.GetItem(Idx).Width);
		MaxHeight += m_kList.GetItem(Idx).Height;
	}

	Width = MaxWidth;
	Height = MaxHeight;

	for ( Idx = 0; Idx < m_kList.itemCount; ++Idx )
	{
		m_kList.GetItem(Idx).SetWidth(Width);
	}

	if (OnDropDownSizeRealizedDelegate != none)
	{
		OnDropDownSizeRealizedDelegate(Width, Height);
	}

	m_kList.SetWidth(MaxWidth);
}

// calling this function will add items instantly
simulated function PopulateListInstantly()
{
	local UIPersonnel_DropDownListItem kItem;

	while( m_kList.itemCount < m_staff.Length )
	{
		kItem = Spawn(class'UIPersonnel_DropDownListItem', m_kList.itemContainer);
		kItem.OnDimensionsRealized = UpdateItemWidths;
		kItem.InitListItem(self, m_staff[m_kList.itemCount], SlotRef);
	}
}

// calling this function will add items sequentially, the next item loads when the previous one is initialized
simulated function PopulateListSequentially( UIPanel Control )
{
	local UIPersonnel_DropDownListItem kItem;

	if(m_kList.itemCount < m_staff.Length)
	{
		kItem = Spawn(class'UIPersonnel_DropDownListItem', m_kList.itemContainer);
		kItem.OnDimensionsRealized = UpdateItemWidths;
		kItem.InitListItem(self, m_staff[m_kList.itemCount], SlotRef);
		kItem.AddOnInitDelegate(PopulateListSequentially);
	}
}

//------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnAccept();
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			return true;
	}

	if (m_kList.Navigator.OnUnrealCommand(cmd, arg))
		return true;

	return super.OnUnrealCommand(cmd, arg);
}

//------------------------------------------------------

simulated function OnStaffSelected( UIList kList, int index )
{
	if( onSelectedDelegate != none )
	{
		onSelectedDelegate(m_staff[index]);
		Hide();
	}
}

//------------------------------------------------------

simulated function OnAccept()
{
	OnStaffSelected(m_kList, m_kList.selectedIndex  < 0 ? 0 : m_kList.selectedIndex);
}

simulated function OnCancel()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Stop_AvengerAmbience");
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Play_AvengerNoRoom");
	Hide();
}

//==============================================================================

defaultproperties
{
	LibID = "EmptyControl"; // the dropdown itself is just an empty container

	bIsNavigable = false;
	m_iMaskWidth = 420;
	m_iMaskHeight = 794;
}
