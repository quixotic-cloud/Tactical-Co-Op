//---------------------------------------------------------------------------------------
//  FILE:    X2QuestItemTemplate.uc
//  AUTHOR:  David Burchanowski
//
//			Base template for mission objective items.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2QuestItemTemplate extends X2ItemTemplate;

// In order to be considered for a mission, a quest item must match at least one entry in each of these
// arrays. If any array is empty (Length == 0), then it is considered a wildcard and matches all
var(X2QuestItemTemplate) array<string> MissionType;	// Recover, Rescue VIP, etc
var(X2QuestItemTemplate) array<name> MissionSource;	// BlackMarket, ResistenceOP, etc
var(X2QuestItemTemplate) array<name> RewardType;	// Intel, Clue, etc

// This flag exists to allow for a different UI flow for lootable items that are electronic in nature.
// Design wants these to automatically be acquired when interacting with the containing object
// (such as a workstation), and to show the acquisition as part of the hack UI instead of
// using the normal loot UI.
var(X2QuestItemTemplate) bool IsElectronicReward;

// This flag denotes that this item is related to a dark event which this mission is trying to cancel
var(X2QuestItemTemplate) bool bDarkEventRelated;

defaultproperties
{
	HideInInventory=true
	HideInLootRecovered=true
}

