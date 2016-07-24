//---------------------------------------------------------------------------------------
//  FILE:    X2FacilityTemplate_Infirmary.uc
//  AUTHOR:  Brian Whitman
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2FacilityTemplate_Infirmary extends X2FacilityTemplate;

function PopulateImportantFacilityCrew(XGBaseCrewMgr Mgr, StateObjectReference FacilityRef)
{
	local int Idx, RoomIdx, PatientIdx;
	local int SoldierIndex;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectHealSoldier HealingSoldier;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_Unit PatientUnit;
	local array<XComGameState_Unit> PotentialVisitors;
	local vector RoomOffset;
	local int HoursToHeal;
	local bool bGravelyInjured;
	local string VisitorSlotName;
	local bool bWillHaveVisitor;
	local XComGameState_StaffSlot StaffSlot;
	local StateObjectReference MedicRef;
	local bool bAllStaffSlotsFilled;
	local int VisitorLimit;
	local int VisitorCount;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

	RoomIdx = Facility.GetRoom().MapIndex;
	RoomOffset = Facility.GetRoom().GetLocation();
	
	bAllStaffSlotsFilled = true;
	for(Idx = 0; Idx < Facility.StaffSlots.Length; ++Idx)
	{
		StaffSlot = XComGameState_StaffSlot(History.GetGameStateForObjectID(Facility.StaffSlots[Idx].ObjectID));
		if(StaffSlot.AssignedStaff.ObjectID <= 0)
		{
			bAllStaffSlotsFilled = false;
			break;
		}
		else if( Idx == 0 )
		{
			MedicRef = StaffSlot.AssignedStaff;
		}
	}

	if(MedicRef.ObjectID > 0)
	{
		if(bAllStaffSlotsFilled)
		{
			Mgr.AddCrew(RoomIdx, self, MedicRef, "MedicSlot1", RoomOffset, true); //Doctor observing the soldier transformation
		}
		else
		{
			if(FRand() < 0.5f)
			{
				Mgr.AddCrew(RoomIdx, self, MedicRef, "MedicSlot2", RoomOffset, true); //Doctor observing the soldier transformation
			}
			else
			{
				Mgr.AddCrew(RoomIdx, self, MedicRef, "MedicSlot3", RoomOffset, true); //Doctor observing the soldier transformation
			}
		}
	}

	PotentialVisitors = XComHQ.GetDeployableSoldiers();

	VisitorLimit = 2;
	VisitorCount = 0;
	PatientIdx = 0;
	for(Idx = 0; Idx < XComHQ.Projects.Length && PatientIdx < 6; ++Idx)
	{
		HealingSoldier = XComGameState_HeadquartersProjectHealSoldier(History.GetGameStateForObjectID(XComHQ.Projects[Idx].ObjectID));
		if (HealingSoldier != None)
		{
			PatientUnit = XComGameState_Unit(History.GetGameStateForObjectID(HealingSoldier.ProjectFocus.ObjectID));
			`assert(PatientUnit != none);
			
			if(PatientUnit.CanAppearInBase()) // Check if the healing unit is allowed to visually appear in infirmary patient staff slots
			{
			++PatientIdx;
			HoursToHeal = HealingSoldier.GetProjectedNumHoursRemaining();
			bGravelyInjured = PatientUnit.IsGravelyInjured(HoursToHeal);

				bWillHaveVisitor = (VisitorCount < VisitorLimit) && FRand() < 0.25f; //Chance for a visitor / vigil keepre
			if(bGravelyInjured || !bWillHaveVisitor)
			{
				Mgr.AddCrew(RoomIdx, self, HealingSoldier.ProjectFocus, "PatientSlot"$PatientIdx, RoomOffset, true); //Character lying down, unconscious
			}
			else
			{
				Mgr.AddCrew(RoomIdx, self, HealingSoldier.ProjectFocus, "InjuredSlot"$PatientIdx, RoomOffset, true); //Paired with visitor slots - patient and visitor having a conversation
			}			
						
			if(bWillHaveVisitor)
			{
				++VisitorCount;
				if(bGravelyInjured)
				{
					VisitorSlotName = "VigilSlot"$PatientIdx;
				}
				else
				{
					VisitorSlotName = "VisitorSlot"$PatientIdx;
				}
				
				for(SoldierIndex = 0; SoldierIndex < PotentialVisitors.Length; ++SoldierIndex)
				{
						if(PotentialVisitors[SoldierIndex].CanAppearInBase()) // First check if the potential visitor is eligible to appear
						{
					if(!Mgr.IsAlreadyPlaced(PotentialVisitors[SoldierIndex].GetReference(), RoomIdx))
					{
						if(Mgr.AddCrew(RoomIdx, self, PotentialVisitors[SoldierIndex].GetReference(), VisitorSlotName, RoomOffset, true))
						{
							break;
						}
					}
				}
			}
		}
	}
}
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}