
class UIRecruitmentListItem extends UIListItemString;

var localized string RecruitConfirmLabel; 

simulated function InitRecruitItem(XComGameState_Unit Recruit)
{
	local string ColoredName;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	InitPanel(); // must do this before adding children or setting data

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResistanceHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	if(XComHQ.GetSupplies() < ResistanceHQ.GetRecruitSupplyCost())
		SetDisabled(true);

	ColoredName = class'UIUtilities_Text'.static.GetColoredText(Recruit.GetName(eNameType_Full), bDisabled ? eUIState_Disabled : eUIState_Normal);
	AS_PopulateData(Recruit.GetCountryTemplate().FlagImage, ColoredName);

	SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, RecruitConfirmLabel, 5, 4);

	// HAX: Undo the height override set by UIListItemString
	MC.ChildSetNum("theButton", "_height", 40);
}		

simulated function OnClickedConfirmButton(UIButton Button)
{
	local UIRecruitSoldiers RecruitScreen;
	RecruitScreen = UIRecruitSoldiers(Screen);
	RecruitScreen.OnRecruitSelected(RecruitScreen.List, RecruitScreen.List.GetItemIndex(self));
}

simulated function AS_PopulateData( string flagIcon, string recruitName )
{
	MC.BeginFunctionOp("populateData");
	MC.QueueString(flagIcon);
	MC.QueueString(recruitName);
	MC.EndOp();
}

defaultproperties
{
	width = 540;
	height = 40;
	LibID = "NewRecruitItem";
}