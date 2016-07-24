//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIViewObjectives.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Screen to view all current and previous in the strategy game. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIViewObjectives extends UISimpleCommodityScreen;

var array<StateObjectReference> m_arrObjectives;
var StateObjectReference CurrentProjectRef;

var public localized String m_strMainObjectivesSectionHeader;
var public localized String m_strSubObjectivesSectionHeader;
var public localized String m_strInProgress;
var public localized String m_strCompleted;

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}

	//Do nothing else, since this is just a view screen.
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------

// Needed for blank inventory label to show up blank
simulated function BuildScreen()
{
	super.BuildScreen();

	SetCategory("");
}

simulated function GetItems()
{
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	arrItems = ConvertObjectivesToCommodities();
}

simulated function array<Commodity> ConvertObjectivesToCommodities()
{
	local XComGameState_Objective ObjectiveState;
	local int iObjective;
	local array<Commodity> arrCommodoties;
	local Commodity ObjectiveComm;
	local StrategyCost EmptyCost;

	m_arrObjectives.Remove(0, m_arrObjectives.Length);
	m_arrObjectives = GetObjectives();
	m_arrObjectives.Sort(SortObjectivesCompletion);

	for (iObjective = 0; iObjective < m_arrObjectives.Length; iObjective++)
	{
		ObjectiveState = XComGameState_Objective(History.GetGameStateForObjectID(m_arrObjectives[iObjective].ObjectID));

		if( ObjectiveState.GetStateOfObjective() == eObjectiveState_Completed )
			ObjectiveComm.Title = class'UIUtilities_Text'.static.GetColoredText(ObjectiveState.GetObjectiveString(), eUIState_Good);
		else
			ObjectiveComm.Title = ObjectiveState.GetObjectiveString();

		ObjectiveComm.Image = ObjectiveState.GetImage();
		ObjectiveComm.Desc = GetDescription(ObjectiveState);
		ObjectiveComm.OrderHours = 0;
		ObjectiveComm.Cost = EmptyCost; // ObjectiveState.GetMyTemplate().Cost;

		arrCommodoties.AddItem(ObjectiveComm);
	}

	return arrCommodoties;
}

function string GetDescription(XComGameState_Objective ObjectiveState)
{
	local array<XComGameState_Objective> SubObjectives;
	local string Desc, LongDesc;
	local int i; 

	Desc = "";

	if( ObjectiveState.GetStateOfObjective() == eObjectiveState_InProgress )
		Desc $= m_strInProgress $"\n";

	if( ObjectiveState.GetStateOfObjective() == eObjectiveState_Completed)
		Desc $= class'UIUtilities_Text'.static.GetColoredText(m_strCompleted, eUIState_Good) $"\n";

	Desc $= "\n";

	Desc $= class'UIUtilities_Text'.static.GetColoredText(m_strMainObjectivesSectionHeader, eUIState_Header) $"\n";
	Desc $= ObjectiveState.GetObjectiveString() $"\n";

	LongDesc = class'UIUtilities_Text'.static.GetColoredText(ObjectiveState.GetMyTemplate().LocLongDescription, eUIState_Faded);
	if( LongDesc != "" )
		Desc $= LongDesc$"\n";

	SubObjectives = ObjectiveState.GetSubObjectives();
	if( SubObjectives.Length > 0)
	{
		Desc $= "\n";
		Desc $= class'UIUtilities_Text'.static.GetColoredText(m_strSubObjectivesSectionHeader, eUIState_Header)  $"\n";

		for( i = 0; i < SubObjectives.Length; i++ )
		{
			// Do not display objectives which have not been started yet
			if (SubObjectives[i].GetStateOfObjective() == eObjectiveState_NotStarted || !SubObjectives[i].bIsRevealed)
				continue;

			Desc $= SubObjectives[i].GetObjectiveString() $"\n";

			LongDesc = class'UIUtilities_Text'.static.GetColoredText(SubObjectives[i].GetMyTemplate().LocLongDescription, eUIState_Faded);
			if( LongDesc != "" )
				Desc $= LongDesc$"\n";
			Desc $= "\n";
		}
	}
	else if (ObjectiveState.GetMyTemplate().SubObjectiveText != "")
	{
		Desc $= "\n";
		Desc $= class'UIUtilities_Text'.static.GetColoredText(m_strSubObjectivesSectionHeader, eUIState_Header)  $"\n";
		
		LongDesc = ObjectiveState.GetMyTemplate().SubObjectiveText;
		if (LongDesc != "")
			Desc $= LongDesc$"\n";
		Desc $= "\n";
	}

	return Desc; 
}

//-----------------------------------------------------------------------------

simulated function array<StateObjectReference> GetObjectives()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetCompletedAndActiveStrategyObjectives();
}

function int SortObjectivesCompletion(StateObjectReference ObjRefA, StateObjectReference ObjRefB)
{
	local XComGameState_Objective ObjStateA, ObjStateB;

	ObjStateA = XComGameState_Objective(History.GetGameStateForObjectID(ObjRefA.ObjectID));
	ObjStateB = XComGameState_Objective(History.GetGameStateForObjectID(ObjRefB.ObjectID));

	if( ObjStateA.GetStateOfObjective() == eObjectiveState_Completed && ObjStateB.GetStateOfObjective() != eObjectiveState_Completed )
	{
		return -1;
	}
	else if( ObjStateA.GetStateOfObjective() != eObjectiveState_Completed && ObjStateB.GetStateOfObjective() == eObjectiveState_Completed )
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

function bool OnObjectiveTableOption(int iOption)
{
/*	local XComGameState_Objective ObjectiveState;

	ObjectiveState = XComGameState_Objective(History.GetGameStateForObjectID(m_arrObjectives[iOption].ObjectID));
		
	if (!XComHQ.HasPausedProject(m_arrObjectives[iOption]) && !XComHQ.MeetsRequirmentsAndCanAffordCost(ObjectiveState.GetMyTemplate().Requirements, ObjectiveState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars))
	{
		//SOUND().PlaySFX(SNDLIB().SFX_UI_No);
		return false;
	}
	*/
	return true;
}

//----------------------------------------------------------------
simulated function OnCancelButton(UIButton kButton) { OnCancel(); }
simulated function OnCancel()
{
	CloseScreen();
}

//==============================================================================

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);
}

defaultproperties
{
	InputState = eInputState_Consume;

	DisplayTag      = "UIBlueprint_QuartersCommander";
	CameraTag       = "UIBlueprint_QuartersCommander";

	bHideOnLoseFocus = true;
	m_eStyle = eUIConfirmButtonStyle_None;
	bUseSimpleCard = true;
}
