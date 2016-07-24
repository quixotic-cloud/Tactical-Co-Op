//---------------------------------------------------------------------------------------
//  FILE:    X2ItemTemplate.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2ItemTemplate extends X2DataTemplate
	dependson(X2StrategyGameRulesetDataStructures)
	native(Core)
	config(StrategyTuning);

var protected localized string  FriendlyName;                   //  localized string for the player
var protected localized string  FriendlyNamePlural;             //  localized string for the player
var protected localized string  BriefSummary;
var protected localized string  TacticalText;
var protected localized string  AbilityDescName;				//  localized string for how this weapon is referenced in ability descriptions
var protected localized string  UnknownUtilityCategory;
var localized array<string>  BlackMarketTexts;
var protected localized string	LootTooltip;

var(X2ItemTemplate) int             iItemSize;                      //  space item takes up in backpack
var(X2ItemTemplate) int             MaxQuantity;                    //  number of this item that can fit together in the backpack without taking up an additional slot
var(X2ItemTemplate) bool            LeavesExplosiveRemains;         //  if false, if the unit carrying this item as loot is killed by an explosive, the player gets NOTHING
var(X2ItemTemplate) name            ExplosiveRemains;               //  if LeavesExplosiveRemains is true and this is not empty, this will replace the item for loot on an explosive kill. (if empty it will leave the item intact)

var(X2ItemTemplate) bool            HideInInventory;                // Should the item appear in HQ's inventory screen
var(X2ItemTemplate) bool			HideInLootRecovered;			// Should the item appear on the loot recovered screen
var(X2ItemTemplate) bool            StartingItem;                   // Does XCom HQ start with this item
var(X2ItemTemplate) bool			bInfiniteItem;					// Does this item have infinite quantity in the inventory (Starting Items are assumed to work this way)
var(X2ItemTemplate) bool			bAlwaysUnique;					// Item will never stack in HQ inventory b/c each itemstate is unique (PCS)
var(X2ItemTemplate) bool			bPriority;						// Flag as a priority to build
var(X2ItemTemplate) bool			bAlwaysRecovered;				// When this loot is rolled, auto recover it immediately; don't offer it as normal looting options.

var(X2ItemTemplate) int             ReverseEngineeringValue;        // Data received when item is reverse engineered, 0 when can't reverse engineer
var(X2ItemTemplate) int             ReverseEngineeringBatchSize;    // Number required to get the ReverseEngineeringValue
var(X2ItemTemplate) int             TradingPostValue;               // Supplies received when sold at the trading post
var(X2ItemTemplate) int             TradingPostBatchSize;           // Number required to get the TradingPostValue

var(X2ItemTemplate) Delegate<OnAcquiredDelegate> OnAcquiredFn;		// Any game state updates upon acquisition of this item in the HQ
var(X2ItemTemplate) Delegate<OnBuiltDelegate> OnBuiltFn;			// Any gameplay effects upon building the item
var(X2ItemTemplate) Delegate<OnEquippedDelegate> OnEquippedFn;		// Any gameplay effects upon equipping the item
var(X2ItemTemplate) Delegate<OnEquippedDelegate> OnUnequippedFn;    // Any gameplay effects upon unequipping the item
var(X2ItemTemplate) Delegate<IsObjectiveItemDelegate> IsObjectiveItemFn; // Is this item an objective item (goldenpath and quest category items are assumed to be)

var(X2ItemTemplate) config int		PointsToComplete;
var(X2ItemTemplate) bool            CanBeBuilt;                     // Can XCom HQ build this item
var(X2ItemTemplate) bool			bOneTimeBuild;					// This item can only be built once (Story Items, Schematic Projects)
var(X2ItemTemplate) bool			bBlocked;						// This item must be unblocked before it can be built

var(X2ItemTemplate) name			CreatorTemplateName;			// This item is created by this template (normally a schematic or tech)
var(X2ItemTemplate) name			UpgradeItem;					// This item can be upgraded into another item defined by the named template
var(X2ItemTemplate) name			BaseItem;						// The item this one was upgraded from
var(X2ItemTemplate) name			HideIfResearched;				// If this tech is researched, do not display in Build Items
var(X2ItemTemplate) name			HideIfPurchased;				// If the referenced item is purchased, do not display in Build Items

var(X2ItemTemplate) Name			ResourceTemplateName;			// This item awards the specified Resource when it is acquired
var(X2ItemTemplate) int				ResourceQuantity;				// The amount of that Resource to be acquired

var(X2ItemTemplate) int				Tier;							// The tier this item should be assigned to. Used for sorting lists.

var(X2ItemTemplate) array<name>		RewardDecks;					// This item template should be added to all of these reward decks.

// Requirements and Cost
var config StrategyRequirement		Requirements;
var config array<StrategyRequirement> AlternateRequirements; // Other possible StrategyRequirements for this item
var config StrategyCost				Cost;
var StrategyRequirement				ArmoryDisplayRequirements;
var int                             MPCost;                         // the cost when equiping this item in a multiplayer squad. -tsmith

// Sounds
var(X2ItemTemplate) string			ItemRecoveredAsLootNarrative;
var(X2ItemTemplate) string			ItemRecoveredAsLootNarrativeReqsNotMet;
var(X2ItemTemplate) name			ItemRecoveredAsLootEventToTrigger;

var() name            ItemCat;      //  must match one of the entries in X2ItemTemplateManager's ItemCategories
var() string          strImage;     //  you can find pre-defined images in UIUtilities_Image.GetItemImagePath()
var() string          strInventoryImage;
var() string          strBackpackIcon;     //  you can find pre-defined images in UIUtilities_Image.GetItemImagePath()
var() StaticMesh      LootStaticMesh;     //  the static mesh that represents this item in the world

delegate bool OnAcquiredDelegate(XComGameState NewGameState);
delegate OnBuiltDelegate(XComGameState NewGameState, XComGameState_Item ItemState);
delegate OnEquippedDelegate(XComGameState_Item ItemState, XComGameState_Unit UnitState, XComGameState NewGameState);
delegate bool IsObjectiveItemDelegate();

function bool ValidateTemplate(out string strError)
{
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (!ItemTemplateManager.ItemCategoryIsValid(ItemCat))
	{
		strError = "given item category '" $ ItemCat $ "' is invalid";
		return false;
	}
	
	if (LeavesExplosiveRemains && ExplosiveRemains != '' && ItemTemplateManager.FindItemTemplate(ExplosiveRemains) == none)
	{
		strError = "ExplosiveRemains set to '" $ ExplosiveRemains $ "' which does not exist";
		return false;
	}

	return super.ValidateTemplate(strError);
}

function XComGameState_Item CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Item Item;

	Item = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item'));
	Item.OnCreation(self);

	return Item;
}

function class<XGItem> GetGameplayInstanceClass()
{
	return none;
}

function string GetItemUnknownUtilityCategory()
{
	return UnknownUtilityCategory;
}

function string GetItemBlackMarketText()
{
	if(BlackMarketTexts.Length == 0)
	{
		return "";
	}

	return BlackMarketTexts[`SYNC_RAND(BlackMarketTexts.Length)];
}

function string GetItemLootTooltip()
{
	return `XEXPAND.ExpandString(LootTooltip);
}

function string GetItemTacticalText()
{
	return `XEXPAND.ExpandString(TacticalText);
}

function string GetItemAbilityDescName()
{
	if (AbilityDescName != "")
	{
		return AbilityDescName;
	}
	else
	{
		return "Error! " $ string(DataName) $ " has no AbilityDescName!";
	}
}

function string GetItemFriendlyNamePlural()
{
	if( FriendlyNamePlural != "" )
	{
		return FriendlyNamePlural;
	}
	else
	{
		return "Error! " $ string(DataName) $ " has no FriendlyNamePlural!";
	}
}

function string GetItemFriendlyNameNoStats()
{
	if (FriendlyName != "")
	{
		return FriendlyName;
	}
	else
	{
		return "Error! " $ string( DataName ) $ " has no FriendlyName!";
	}
}

function string GetItemFriendlyName(optional int ItemID = 0, optional bool bShowSquadUpgrade)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local string strTemp;
	local int idx, BoostValue;
	local bool bHasStatBoostBonus;

	if(FriendlyName != "")
	{
		strTemp = FriendlyName;
		History = `XCOMHISTORY;
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemID));

		if(ItemState != none && ItemState.Nickname != "")
			strTemp = ItemState.Nickname;

		if(ItemState != none && ItemState.StatBoosts.Length > 0)
		{
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ != none)
			{
				bHasStatBoostBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;
			}

			strTemp @= "(";

			for(idx = 0; idx < ItemState.StatBoosts.Length; idx++)
			{
				BoostValue = ItemState.StatBoosts[idx].Boost;
				if (bHasStatBoostBonus)
				{
					if (X2EquipmentTemplate(ItemState.GetMyTemplate()).bUseBoostIncrement)
						BoostValue += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement;
					else
						BoostValue += Round(BoostValue * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue);
				}

				if(idx > 0)
				{
					strTemp $= ", ";
				}

				strTemp $= "+" $ string(BoostValue) @ class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[ItemState.StatBoosts[idx].StatType];
			}

			strTemp $= ")";
		}

		return strTemp;
	}
	else
	{
		return "Error! " $ string(DataName) $ " has no FriendlyName!";
	}
}

function string GetItemBriefSummary(optional int ItemID = 0)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local X2AbilityTag AbilityTag;
	local string strTemp;
	local int idx, BoostValue;
	local bool bHasStatBoostBonus;

	if(BriefSummary != "")
	{
		strTemp = "";
		History = `XCOMHISTORY;
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemID));

		if(ItemState != none && ItemState.StatBoosts.Length > 0)
		{
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ != none)
			{
				bHasStatBoostBonus = XComHQ.SoldierUnlockTemplates.Find('IntegratedWarfareUnlock') != INDEX_NONE;
			}

			strTemp @= "(";

			for(idx = 0; idx < ItemState.StatBoosts.Length; idx++)
			{
				BoostValue = ItemState.StatBoosts[idx].Boost;
				if (bHasStatBoostBonus)
				{
					if (X2EquipmentTemplate(ItemState.GetMyTemplate()).bUseBoostIncrement)
						BoostValue += class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostIncrement;
					else
						BoostValue += Round(BoostValue * class'X2SoldierIntegratedWarfareUnlockTemplate'.default.StatBoostValue);
				}

				if(idx > 0)
				{
					strTemp $= ", ";
				}

				strTemp $= "+" $ string(BoostValue) @ class'X2TacticalGameRulesetDataStructures'.default.m_aCharStatLabels[ItemState.StatBoosts[idx].StatType];
			}

			strTemp $= ")\n";
		}
		
		AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
		AbilityTag.ParseObj = self;
		strTemp = class'UIUtilities_Text'.static.GetColoredText(strTemp, eUIState_Good) $ `XEXPAND.ExpandString(BriefSummary);
		AbilityTag.ParseObj = none;

		return strTemp;
	}
	else
	{
		return "Error! " $ string(DataName) $ " has no BriefSummary!";
	}
}

function string GetLocalizedCategory()
{
	switch(ItemCat)
	{
	case 'grenade':     return class'XGLocalizedData'.default.UtilityCatGrenade;
	case 'tech':        return class'XGLocalizedData'.default.UtilityCatTech;
	case 'ammo':        return class'XGLocalizedData'.default.UtilityCatAmmo;
	case 'defense':     return class'XGLocalizedData'.default.UtilityCatDefense;
	case 'heal':        return class'XGLocalizedData'.default.UtilityCatHeal;
	case 'psidefense':	return class'XGLocalizedData'.default.UtilityCatPsiDefense;
	case 'skulljack':	return class'XGLocalizedData'.default.UtilityCatSkulljack;
	default:            return class'XGLocalizedData'.default.UtilityCatUnknown;
	}
}
function array<int> GetItemStats()
{
	local array<int> Stats; 
	local int i; 

	//TODO: @jbouscher: fill in the stats for items. 

	//DEBUGGING: to visualize in the UI. Please nuke this. 
	for( i = 0; i < eStat_MAX; i++ )
	{
		Stats.AddItem(99);
	}
	return Stats; 
}


DefaultProperties
{
	iItemSize=1;
	TradingPostBatchSize=1;
	ReverseEngineeringBatchSize=1;
	MaxQuantity=1;
	LootStaticMesh = StaticMesh'BeerCase.Meshes.BeerCase_A'
}