
class UIFacilitySummary extends UIScreen;

enum EFacilitySortType
{
	eFacilitySortType_Name,
	eFacilitySortType_Staff,
	eFacilitySortType_Power,
	eFacilitySortType_ConstructionDate,
	eFacilitySortType_Status,
};

// these are set in UIFacilitySummary_HeaderButton
var bool m_bFlipSort;
var EFacilitySortType m_eSortType;

var UIPanel       m_kHeader;
var UIPanel       m_kContainer; // contains all controls bellow
var UIList  m_kList;
var UIBGBox  m_kListBG;
var UIX2PanelHeader  m_kTitle;

var array<XComGameState_FacilityXCom> m_arrFacilities;

var localized string m_strTitle;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	m_kContainer = Spawn(class'UIPanel', self).InitPanel();
	m_kContainer.SetPosition(300, 85);
	
	// add BG
	m_kListBG = Spawn(class'UIBGBox', m_kContainer);
	m_kListBG.InitPanel('', class'UIUtilities_Controls'.const.MC_X2Background).SetSize(1310, 940);

	m_kTitle = Spawn(class'UIX2PanelHeader', self).InitPanelHeader('', m_strTitle);
	m_kTitle.SetPosition(20, 20);

	m_kList = Spawn(class'UIList', m_kContainer).InitList('', 15, 60, 1265, 810);
	m_kList.OnItemClicked = OnFacilitySelectedCallback;

	// allows list to scroll when mouse is touching the BG
	m_kListBG.ProcessMouseEvents(m_kList.OnChildMouseEvent);

	m_eSortType = eFacilitySortType_Name;

	m_kHeader = Spawn(class'UIPanel', self).InitPanel('', 'FacilitySummaryHeader');

	Spawn(class'UIFacilitySummary_HeaderButton', m_kHeader).InitHeaderButton("name", eFacilitySortType_Name);
	Spawn(class'UIFacilitySummary_HeaderButton', m_kHeader).InitHeaderButton("staff", eFacilitySortType_Staff);
	Spawn(class'UIFacilitySummary_HeaderButton', m_kHeader).InitHeaderButton("power", eFacilitySortType_Power);
	Spawn(class'UIFacilitySummary_HeaderButton', m_kHeader).InitHeaderButton("construction", eFacilitySortType_ConstructionDate);
	Spawn(class'UIFacilitySummary_HeaderButton', m_kHeader).InitHeaderButton("status", eFacilitySortType_Status);

	UpdateNavHelp();
	UpdateData();
}

simulated function UpdateData()
{
	local int i;
	local XComGameState_FacilityXCom Facility;
	local UIFacilitySummary_ListItem FacilityItem;

	if(m_arrFacilities.Length == 0)
	{
		foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_FacilityXCom', Facility)
		{
			//if( Facility.StaffSlots.length > 0 || Facility.UpkeepCost > 0) //Include all facilities that have staffing slots or an upkeep cost
			m_arrFacilities.AddItem(Facility);
		}
	}

	SortFacilities();

	// Clear old data
	m_kList.ClearItems();

	for(i = 0; i < m_arrFacilities.Length; ++i)
	{
		FacilityItem = UIFacilitySummary_ListItem(m_kList.CreateItem(class'UIFacilitySummary_ListItem')).InitListItem();
		FacilityItem.UpdateData(m_arrFacilities[i].GetReference());
	}
}

simulated function UpdateNavHelp()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);
}

simulated function OnReceiveFocus()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	super.OnReceiveFocus();
	UpdateData();
	Show();

	// Move the camera back to the Commander's Quarters
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('CommandersQuarters');
	`HQPRES.CAMLookAtRoom(FacilityState.GetRoom(), `HQINTERPTIME);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	Hide();
}

simulated function OnFacilitySelectedCallback(UIList list, int itemIndex)
{
	class'UIUtilities_Strategy'.static.SelectFacility(UIFacilitySummary_ListItem(list.GetItem(itemIndex)).FacilityRef);
}

simulated function OnCancel()
{
	// TODO: Make sure items are decrypted before continuing
	Movie.Stack.Pop(self);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		// OnAccept
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			`HQPRES.UIPauseMenu( ,true );
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

function SortFacilities()
{
	switch(m_eSortType)
	{
	case eFacilitySortType_Name: m_arrFacilities.Sort(SortByName); break;
	case eFacilitySortType_Staff: m_arrFacilities.Sort(SortByStaff); break;
	case eFacilitySortType_Power: m_arrFacilities.Sort(SortByPower); break;
	case eFacilitySortType_ConstructionDate: m_arrFacilities.Sort(SortByConstructionDate); break;
	case eFacilitySortType_Status: m_arrFacilities.Sort(SortByStatus); break;
	}
}

simulated function int SortByName(XComGameState_FacilityXCom A, XComGameState_FacilityXCom B)
{
	local string NameA, NameB;

	NameA = A.GetMyTemplate().DisplayName;
	NameB = B.GetMyTemplate().DisplayName;

	if(NameA < NameB) return m_bFlipSort ? -1 : 1;
	else if(NameA > NameB) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByStaff(XComGameState_FacilityXCom A, XComGameState_FacilityXCom B)
{
	local int StaffA, StaffB;

	StaffA = A.GetNumFilledStaffSlots();
	StaffB = B.GetNumFilledStaffSlots();

	if(StaffA < StaffB) return m_bFlipSort ? -1 : 1;
	else if(StaffA > StaffB) return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortByPower(XComGameState_FacilityXCom A, XComGameState_FacilityXCom B)
{
	local int PowerA, PowerB;

	PowerA = A.GetPowerOutput();
	PowerB = B.GetPowerOutput();

	if(PowerA < PowerB) return m_bFlipSort ? -1 : 1;
	else if(PowerA > PowerB) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByConstructionDate(XComGameState_FacilityXCom A, XComGameState_FacilityXCom B)
{
	if(class'X2StrategyGameRulesetDataStructures'.static.LessThan(A.ConstructionDateTime, B.ConstructionDateTime)) return m_bFlipSort ? -1 : 1;
	else if(class'X2StrategyGameRulesetDataStructures'.static.LessThan(B.ConstructionDateTime, A.ConstructionDateTime)) return m_bFlipSort ? 1 : -1;
	else return 0;
}

simulated function int SortByStatus(XComGameState_FacilityXCom A, XComGameState_FacilityXCom B)
{
	local string StatusA, StatusB, QueueA, QueueB;

	StatusA = A.GetStatusMessage();
	StatusB = B.GetStatusMessage();
	QueueA = A.GetQueueMessage();
	QueueB = B.GetQueueMessage();

	if( StatusA == StatusB )
	{
		if(QueueA < QueueB) return m_bFlipSort ? -1 : 1;
		else if(QueueA > QueueB) return m_bFlipSort ? 1 : -1;
		else return 0;
	}
	if(StatusA < StatusB) 
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if(StatusA > StatusB) 
	{
		return m_bFlipSort ? 1 : -1;
	}
	else 
		return 0;
}

defaultproperties
{
	Package   = "/ package/gfxFacilitySummary/FacilitySummary";
	InputState = eInputState_Consume;
}