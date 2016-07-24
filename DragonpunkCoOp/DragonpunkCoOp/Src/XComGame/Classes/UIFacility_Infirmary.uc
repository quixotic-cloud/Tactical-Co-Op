
class UIFacility_Infirmary extends UIFacility;


var public localized string m_strOption_Heal;
var public localized string m_strNoActiveHealing;
var public localized string m_strCurrentPatients;
var public localized string m_strNoDoctor;

var UIList PatientList;

//----------------------------------------------------------------------------
// MEMBERS

simulated function RealizeStaffSlots()
{
	local XComGameState_FacilityXCom Facility;
	local UIFacility_InfirmarySlot PatientSlot;
	local int i, listX, listWidth, listItemPadding, NumPatients;

	//Update regular staff slots in super version.-------------------------
	super.RealizeStaffSlots();

	//Create list if it hasn't been created already------------------------
	if( PatientList == none )
	{
		listItemPadding = 0;
		listWidth = GetFacility().StaffSlots.Length * (class'UIFacility_InfirmarySlot'.default.width + listItemPadding);
		listX = Clamp((Movie.UI_RES_X / 2) - (listWidth / 2), 100, Movie.UI_RES_X / 2);

		PatientList = Spawn(class'UIList', self);
		PatientList.InitList('', listX, -250, Movie.UI_RES_X - 200, 310, true).AnchorBottomLeft();
		PatientList.itemPadding = listItemPadding;
		//PatientList.bCenterNoScroll = true;
	}

	//Update the patient group slots --------------------------------------
	Facility = GetFacility();

	// Show or create slots for the currently requested facility
	for( i = 0; i < Facility.StaffSlots.Length; i++ )
	{
		//Only include patient types in the list. 
		if( !Facility.GetStaffSlot(i).IsSoldierSlot() ) continue;
		
		//Track number of patients so that we don't get thrown off by the non-patient staff slots in the staffing array. 
		NumPatients++;

		if( NumPatients <= PatientList.ItemCount )
		{
			PatientSlot = UIFacility_InfirmarySlot(PatientList.GetItem(i));
		}
		else
		{
			PatientSlot = UIFacility_InfirmarySlot(PatientList.CreateItem(class'UIFacility_InfirmarySlot'));
			PatientSlot.InitStaffSlot(none, FacilityRef, i, onStaffUpdatedDelegate);
		}

		PatientSlot.UpdateData();
	}
}


simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	m_kTitle.Hide();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	m_kTitle.Show();
	RealizeFacility();
}

//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = false;
}
