//---------------------------------------------------------------------------------------
//  FILE:    X2AvengerAnimationTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AvengerAnimationTemplate extends X2StrategyElementTemplate;

var() array<name>                   EligibleFacilities; // Which facilities can this animation appear in
var() array<AvengerAnimationSlot>   AnimationSlots; // array of slots for characters which hold data about their requirements
var() float                         Weight; // Weight used to increase or decrease odds of animation being played
var() bool                          CanUseEmptyRoom; // can this animation appear in an empty room?
var() bool                          UsesStaffSlot; // Does this animation involve someone in a staffing slot?
var() bool                          UsesRepairSlot; // Does this animation involve someone repairing a room?
var() bool                          UsesBuildSlot; // Does this animation involve someone building a facility, clearing a room, or building an upgrade?

// some reference to the actual animation would go here
var() string                        AnimationName;



//---------------------------------------------------------------------------------------
// Do you have the staff to fill this animation, if true will remove characters from pool and send out characters for the animation
function bool FillAnimation(out array<XComGameState_Unit> CrewPool, out array<XComGameState_Unit> AnimPool, out array<int> SlotIndices)
{
	local int iAnimSlot, iCrew, iCharacter, Sum, CurrentTotal, RandAmount;
	local array<XComGameState_Unit> EligibleUnits;
	local XComGameState_Unit UnitState;
	local AvengerAnimationSlot AnimationSlot;
	local array<AvengerAnimationCharacter> SlotCharacters;
	local AvengerAnimationCharacter AnimCharacter;

	AnimPool.Length = 0;
	SlotIndices.Length = 0;

	for(iAnimSlot = 0; iAnimSlot < AnimationSlots.Length; iAnimSlot++)
	{
		AnimationSlot = AnimationSlots[iAnimSlot];
		EligibleUnits.Length = 0;
		SlotCharacters.Length = 0;
		SlotCharacters = AnimationSlot.EligibleCharacters;

		while(EligibleUnits.Length == 0 && SlotCharacters.Length != 0)
		{
			// Roll for character type
			Sum = 0;
			CurrentTotal = 0;

			for(iCharacter = 0; iCharacter < SlotCharacters.Length; iCharacter++)
			{
				Sum += AnimationSlot.EligibleCharacters[iCharacter].PercentChance;
			}

			RandAmount = `SYNC_RAND(Sum);

			for(iCharacter = 0; iCharacter < SlotCharacters.Length; iCharacter++)
			{
				CurrentTotal += SlotCharacters[iCharacter].PercentChance;

				if(RandAmount < CurrentTotal)
				{
					AnimCharacter = SlotCharacters[iCharacter];
					SlotCharacters.Remove(iCharacter, 1);
					break;
				}
			}

			// Check if there are eligible units of this character type
			for(iCrew = 0; iCrew < CrewPool.Length; iCrew++)
			{
				UnitState = CrewPool[iCrew];

				if(AnimPool.Find(UnitState) == INDEX_NONE && IsValidCharacter(UnitState, AnimCharacter))
				{
					EligibleUnits.AddItem(UnitState);
				}
			}
		}

		if(EligibleUnits.Length == 0)
		{
			if(AnimationSlot.IsMandatory)
			{
				AnimPool.Length = 0;
				SlotIndices.Length = 0;
				return false;
			}

			// If the slot is not mandatory continue
			continue;
		}
		else
		{
			// Add a random unit from those eligible, and record the slot index
			AnimPool.AddItem(EligibleUnits[`SYNC_RAND(EligibleUnits.Length)]);
			SlotIndices.AddItem(iAnimSlot);
		}
	}

	// Remove used crew members from the crew pool
	for(iCrew = 0; iCrew < AnimPool.Length; iCrew++)
	{
		CrewPool.RemoveItem(AnimPool[iCrew]);
	}

	return true;

}

//---------------------------------------------------------------------------------------
function int GetMinAnimationSlots()
{
	local int idx, Count;

	Count = 0;

	for(idx = 0; idx < AnimationSlots.Length; idx++)
	{
		if(AnimationSlots[idx].IsMandatory)
		{
			Count++;
		}
	}

	return Count;
}

//---------------------------------------------------------------------------------------
function int GetMaxAnimationSlots()
{
	return AnimationSlots.Length;
}

//---------------------------------------------------------------------------------------
private function bool IsValidCharacter(XComGameState_Unit UnitState, AvengerAnimationCharacter AnimCharacter)
{
	if((UnitState.IsASoldier() && AnimCharacter.CharacterType == eStaff_Soldier) ||
		(UnitState.IsAScientist() && (AnimCharacter.CharacterType == eStaff_Scientist || AnimCharacter.CharacterType == eStaff_HeadScientist)) ||
		(UnitState.IsAnEngineer() && (AnimCharacter.CharacterType == eStaff_Engineer || AnimCharacter.CharacterType == eStaff_HeadEngineer)))
	{
		if (UnitState.CanBeStaffed())
		{
			return true;
		}
	}

	return false;
}


//---------------------------------------------------------------------------------------
DefaultProperties
{
}