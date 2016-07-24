//---------------------------------------------------------------------------------------
//  FILE:    X2FacilityTemplate_Memorial.uc
//  AUTHOR:  Brian Whitman
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2FacilityTemplate_Memorial extends X2FacilityTemplate;

var protectedwrite int MemorialCapacity;

private function int SortSoldiers(XComGameState_Unit SoldierA, XComGameState_Unit SoldierB)
{
	if(SoldierA.GetNumMissions() < SoldierB.GetNumMissions())
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

/*
function PopulateFillerFacilityCrew(XGBaseCrewMgr Mgr, StateObjectReference FacilityRef, int LowPopulationRoomMax)
{	
	local int i, DrinkerCnt, GrieverCnt, SoldierCnt, SoldierIdx, RoomIdx, GrieverMax;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local XComGameState_FacilityXCom Facility;
	local Vector RoomOffset;
	local array<XComGameState_Unit> Soliders;

	super.PopulateFillerFacilityCrew(Mgr, FacilityRef, LowPopulationRoomMax);

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	RoomOffset = Facility.GetRoom().GetLocation();
	RoomIdx = Facility.GetRoom().MapIndex;

	SoldierCnt = Rand(MaxFillerCrew - MinFillerCrew) + BaseMinFillerCrew;

	for(i = 0; i < XComHQ.Crew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));
		if (Unit.IsAlive())
		{
			if (!Unit.IsInjured() && Unit.IsASoldier())
			{
				if (!Mgr.IsAlreadyPlaced(Unit.GetReference()))
				{
					Soliders.AddItem(Unit);
				}
			}
		}
		else
		{
			++GrieverMax;
		}
	}

	for(i = 0; i < XComHQ.DeadCrew.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.DeadCrew[i].ObjectID));
		if (!Unit.IsAlive())
		{
			++GrieverMax;
		}
	}
	

	SoldierCnt = Min(SoldierCnt, Soliders.Length);
	DrinkerCnt = Min(SoldierCnt, 4);
	GrieverCnt = Min(GrieverMax, Min(SoldierCnt - DrinkerCnt, 6));
	SoldierIdx = 0;

	Soliders.Sort(SortSoldiers);
		
	`log("");	
	`log("----- Memorial -----");
	`log("");
	`log("Soliders.Length:"@Soliders.Length);
	`log("SoldierCnt:"@SoldierCnt);
	`log("GrieverCnt:"@GrieverCnt);
	`log("DrinkerCnt:"@DrinkerCnt);
	`log("");

	for(i = 0; i < GrieverCnt; i++)
	{
		Unit = Soliders[SoldierIdx++];
		Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Griever", RoomOffset, false);
	}

	for(i = 0; i < DrinkerCnt; i++)
	{
		Unit = Soliders[SoldierIdx++];
		Mgr.AddCrew(RoomIdx, self, Unit.GetReference(), "Drinker", RoomOffset, false);
	}
}
*/

//---------------------------------------------------------------------------------------
DefaultProperties
{
}