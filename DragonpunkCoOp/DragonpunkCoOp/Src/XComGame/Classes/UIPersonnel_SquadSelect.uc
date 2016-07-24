//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPersonnel_SquadSelect
//  AUTHOR:  Sam Batista
//  PURPOSE: Provides custom behavior for personnel selection screen when
//           selecting soldiers to take on a mission.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIPersonnel_SquadSelect extends UIPersonnel;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}

simulated function UpdateList()
{
	local int i;
	local XComGameState_Unit Unit;
	local GeneratedMissionData MissionData;
	local UIPersonnel_ListItem UnitItem;
	local bool bAllowWoundedSoldiers; // true if wounded soldiers are allowed to be deployed on this mission
	
	super.UpdateList();
	
	MissionData = HQState.GetGeneratedMissionData(HQState.MissionRef.ObjectID);
	bAllowWoundedSoldiers = MissionData.Mission.AllowDeployWoundedUnits;

	// loop through every soldier to make sure they're not already in the squad
	for(i = 0; i < m_kList.itemCount; ++i)
	{
		UnitItem = UIPersonnel_ListItem(m_kList.GetItem(i));
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitItem.UnitRef.ObjectID));

		if(HQState.IsUnitInSquad(UnitItem.UnitRef) || (Unit.IsInjured() && !bAllowWoundedSoldiers && !Unit.IgnoresInjuries()) || Unit.IsTraining() || Unit.IsPsiTraining())
			UnitItem.SetDisabled(true);
	}
}

// Override sort function
simulated function SortPersonnel()
{
	SortCurrentData(SortSoldiers);
}

// show available units first
simulated function int SortSoldiers(StateObjectReference A, StateObjectReference B)
{
	if( !HQState.IsUnitInSquad(A) && HQState.IsUnitInSquad(B) )
		return 1;
	else if( HQState.IsUnitInSquad(A) && !HQState.IsUnitInSquad(B) )
		return -1;
	return 0;
}

defaultproperties
{
	m_eListType = eUIPersonnel_Soldiers;
	m_bRemoveWhenUnitSelected = true;
}