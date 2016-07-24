//---------------------------------------------------------------------------------------
//  FILE:    UIFacility_StaffSlot.uc
//  AUTHOR:  Sam Batista
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIFacility_InfirmarySlot extends UIFacility_StaffSlot
	dependson(UIPersonnel);

//These correspond to Flash settings. 
enum EUIInfirmarySlotFrames
{
	eUIInfirmaryFrame_None,
	eUIInfirmaryFrame_IntensiveCare,
	eUIInfirmaryFrame_Triage,
};

var localized string TriageLabel;
var localized string IntensiveCareLabel;

//-----------------------------------------------------------------------------

simulated function UpdateData()
{
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot StaffSlot;
	local string Status, TimeLabel;
	local int TimeValue;
	
	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	if(!StaffSlot.IsSlotFilled())
	{
		SetOpenSlot(m_strOpenSlot);
		ClearFrame();
	}
	else
	{
		Unit = StaffSlot.GetAssignedStaff();
		Unit.GetStatusStringsSeparate(Status, TimeLabel, TimeValue);

		SetSlotNameRank(Unit.GetName(eNameType_First), 
						Unit.GetName(eNameType_Last), 
						Unit.GetName(eNameType_Nick),
						class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), Unit.GetSoldierClassTemplateName()),
						Unit.GetSoldierClassTemplate().IconImage);
						
		SetDaysRemaining(Status, TimeLabel, class'UIUtilities_Text'.static.GetColoredText(string(TimeValue), Unit.GetStatusUIState()));
		ClearFrame();
	}
}

simulated function OnClickStaffSlot( UIPanel kControl, int cmd )
{
	local XComGameState_StaffSlot StaffSlot;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		if (StaffSlot.IsLocked())
		{
			ShowUpgradeFacility();
		}
		else if (StaffSlot.IsSlotEmpty())
		{
			StaffContainer.ShowDropDown(self);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
		if (!StaffSlot.IsLocked())
		{
			StaffContainer.HideDropDown(self);
		}
		break;
	}
}

simulated function SetSlotNameRank(string FirstName, string LastName, string NickName, string RankImage, string ClassImage)
{
	MC.BeginFunctionOp("SetSlotNameRank");
	MC.QueueString(FirstName);
	MC.QueueString(LastName);
	MC.QueueString(NickName);
	MC.QueueString(RankImage);
	MC.QueueString(ClassImage);
	MC.EndOp();
}

simulated function SetOpenSlot(string Status)
{
	MC.BeginFunctionOp("SetOpenSlot");
	MC.QueueString(Status);
	MC.EndOp();
}

simulated function SetDaysRemaining(string Status, string TimeLabel, string TimeValue)
{
	MC.BeginFunctionOp("SetDaysRemaining");
	MC.QueueString(Status);
	MC.QueueString(TimeLabel);
	MC.QueueString(TimeValue);
	MC.EndOp();
}

//May be used to custom label the frame 
simulated function SetFrame(EUIInfirmarySlotFrames FrameType, string FrameLabel)
{
	MC.BeginFunctionOp("SetFrame");
	MC.QueueNumber(FrameType);
	MC.QueueString(FrameLabel);
	MC.EndOp();
}

simulated function ClearFrame()
{
	SetFrame( eUIInfirmaryFrame_None, "");
}

simulated function SetIntensiveCare()
{
	SetFrame(eUIInfirmaryFrame_IntensiveCare, IntensiveCareLabel);
}

simulated function SetTriage()
{
	SetFrame(eUIInfirmaryFrame_Triage, TriageLabel);
}

//==============================================================================

defaultproperties
{
	LibID = "InfirmarySlot";

	width = 218;
	height = 136;
}
