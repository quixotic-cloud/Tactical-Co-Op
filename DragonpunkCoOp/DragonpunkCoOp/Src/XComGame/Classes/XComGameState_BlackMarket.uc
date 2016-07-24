//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_BlackMarket.uc
//  AUTHOR:  Mark Nauta  --  08/21/2014
//  PURPOSE: This object represents the instance data for the Black Markets on the 
//           X-Com 2 strategy game map
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_BlackMarket extends XComGameState_ScanningSite
	config(GameData) dependson(X2StrategyGameRulesetDataStructures) native(Core);

var int									SupplyReserve; // Current number of Supplies the Black Market has
var bool								bNeedsScan; // When the Black Market appears, it needs to be scanned to open
var bool								bIsOpen;
var bool								bLandedUFOMission; // Replace the supply raid mission with landed UFO for this month
var bool								bPurchasedUFOMission; // Has the player purchased the current UFO mission
var bool								bPurchasedSupplyMission; // Has the player purchased the current supply raid mission
var bool								bNeedsAppearedPopup; // Should the POI Appeared popup be displayed for the Market
var bool								bNeedsOpenPopup;  // Should the Black Market window popup be displayed
var bool								bHasSeenNewGoods; // Has the player seen new goods the Black Market is offering
var TDateTime							OpeningTime; // we've got the best deals anywhere
var TDateTime							ClosingTime;  // you don't have to go home, but you can't stay here
var array<Commodity>					ForSaleItems;
var deprecated array<StateObjectReference>			Interests;
var array<name>							InterestTemplates;
var array<BlackMarketItemPrice>			BuyPrices; // Prices for items in your inventory
var StateObjectReference				Mission;
var int									NumTimesAppeared;

// Modifiers
var float								PriceReductionScalar; // Alien Cypher Dark Event does not effect BM so apply inverse scalar here
var int									GoodsCostPercentDiscount; // QuidProQuo Continent Bonus
var int									BuyPricePercentIncrease; // UnderTheTable Continent Bonus


var config array<int>					MinDaysToShow;
var config array<int>					MaxDaysToShow;
var config array<int>					NumInterestItems;
var config array<int>					NumTechRushes;
var config array<int>					TechPointsPerIntelCost;
var config array<int>					BaseItemIntelCost;
var config array<int>					PersonnelItemIntelCost;
var config array<int>					IntelCostVariance;
var config array<int>					ItemIntelCostIncrease;
var config array<int>					PersonnelItemIntelCostIncrease;
var config array<int>					BuyPriceVariancePercent;
var config array<int>					InterestPriceMultiplier;
var config array<float>					WeaponUpgradeCostScalar;
var config array<float>					SupplyGoodScalar;
var config array<StrategyCostScalar>	GoodsCostScalars;

cpptext
{
public:
	virtual void PostLoad();
}
//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SetUpBlackMarket(XComGameState StartState)
{
	local XComGameState_BlackMarket BlackMarketState;
	local int HoursToAdd;

	BlackMarketState = XComGameState_BlackMarket(StartState.CreateStateObject(class'XComGameState_BlackMarket'));
	StartState.AddStateObject(BlackMarketState);

	// Set the time when the Black Market will open
	HoursToAdd = (default.MinDaysToShow[`DIFFICULTYSETTING] * 24) + `SYNC_RAND_STATIC((default.MaxDaysToShow[`DIFFICULTYSETTING] * 24) - (default.MinDaysToShow[`DIFFICULTYSETTING] * 24) + 1);
	BlackMarketState.OpeningTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(BlackMarketState.OpeningTime, HoursToAdd);
}

//#############################################################################################
//----------------   OPENING/CLOSING   --------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool ShowBlackMarket(XComGameState NewGameState, optional bool bForceShow = false)
{
	if (bForceShow || (!bIsOpen && !bNeedsScan && class'X2StrategyGameRulesetDataStructures'.static.LessThan(OpeningTime, GetCurrentTime())))
	{
		bNeedsScan = true;
		bNeedsAppearedPopup = true;
		SetScanHoursRemaining(default.MinScanDays[`DIFFICULTYSETTING], default.MaxScanDays[`DIFFICULTYSETTING]);

		SetContinent();
		//SetSupplyReserve();

		ResetBlackMarketGoods(NewGameState);

		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function OpenBlackMarket(XComGameState NewGameState)
{
	//local int HoursToAdd;

	bNeedsScan = false;
	bIsOpen = true;
	bNeedsOpenPopup = true;
	/*if (Mission.ObjectID != 0)
	{
	ShowMission(NewGameState);
	}*/

	// Add some time back onto the Black Market to account for when we were scanning
	//HoursToAdd = (default.MinScanDays * 24) + `SYNC_RAND((default.MaxScanDays * 24) - (default.MinScanDays * 24) + 1);
	//class'X2StrategyGameRulesetDataStructures'.static.AddHours(ClosingTime, HoursToAdd);
}

//---------------------------------------------------------------------------------------
//function CloseBlackMarket(XComGameState NewGameState)
//{
//	bNeedsScan = false;
//	bIsOpen = false;
//	NumTimesAppeared++;
//	CleanUpForSaleItems(NewGameState);
//	BuyPrices.Length = 0;
//}

//---------------------------------------------------------------------------------------
function ResetBlackMarketGoods(XComGameState NewGameState)
{
	NumTimesAppeared++;
	CleanUpForSaleItems(NewGameState);
	BuyPrices.Length = 0;
	SetInterests();
	//SetClosingTime();
	SetUpForSaleItems(NewGameState);
	UpdateBuyPrices();

	bHasSeenNewGoods = false;
}

//---------------------------------------------------------------------------------------
function SetContinent()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_WorldRegion> AllRegions, ValidRegions;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		AllRegions.AddItem(RegionState);

		if(RegionState.HaveMadeContact())
		{
			ValidRegions.AddItem(RegionState);
		}
	}

	if(ValidRegions.Length > 0)
	{
		RegionState = ValidRegions[`SYNC_RAND(ValidRegions.Length)];
	}
	else
	{
		RegionState = AllRegions[`SYNC_RAND(AllRegions.Length)];
	}

	Continent = RegionState.GetContinent().GetReference();
	SetLocation(RegionState.GetContinent());
}

//---------------------------------------------------------------------------------------
function SetLocation(XComGameState_Continent ContinentState)
{
	Location = ContinentState.GetRandomLocationInContinent(, self);
}

//---------------------------------------------------------------------------------------
//function SetSupplyReserve()
//{
//	SupplyReserve = class'X2StrategyElement_DefaultRewards'.static.GetSuppliesReward();
//}

//---------------------------------------------------------------------------------------
//function SetClosingTime()
//{
//	local int HoursToAdd;
//
//	HoursToAdd = default.MinOperatingHours + `SYNC_RAND(default.MaxOperatingHours - default.MinOperatingHours + 1);
//	ClosingTime = GetCurrentTime();
//	class'X2StrategyGameRulesetDataStructures'.static.AddHours(ClosingTime, HoursToAdd);
//}

//---------------------------------------------------------------------------------------
function SetUpForSaleItems(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local Commodity ForSaleItem, EmptyForSaleItem;
	local array<XComGameState_Item> ItemList;
	local array<XComGameState_Tech> TechList;
	local array<name> PersonnelRewardNames;
	local int idx;
	local XComPhotographer_Strategy Photo;	

	Photo = `GAME.StrategyPhotographer;
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Item'));
	ItemList = RollForBlackMarketLoot(NewGameState);

	// Loot Table Rewards
	for(idx = 0; idx < ItemList.Length; idx++)
	{
		ForSaleItem = EmptyForSaleItem;
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(RewardState);
		RewardState.SetReward(ItemList[idx].GetReference());
		ForSaleItem.RewardRef = RewardState.GetReference();

		ForSaleItem.Title = RewardState.GetRewardString();

		if(X2WeaponUpgradeTemplate(ItemList[idx].GetMyTemplate()) != none)
		{
			ForSaleItem.Cost = GetForSaleItemCost(default.WeaponUpgradeCostScalar[`DIFFICULTYSETTING] * PriceReductionScalar);
		}
		else
		{
			ForSaleItem.Cost = GetForSaleItemCost(PriceReductionScalar);
		}
		
		ForSaleItem.Desc = RewardState.GetBlackMarketString();
		ForSaleItem.Image = RewardState.GetRewardImage();
		ForSaleItem.CostScalars = GoodsCostScalars;
		ForSaleItem.DiscountPercent = GoodsCostPercentDiscount;

		ForSaleItems.AddItem(ForSaleItem);
	}

	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_TechRush'));
	TechList = RollForTechRushItems();

	// Tech Rush Rewards
	for(idx = 0; idx < TechList.Length; idx++)
	{
		ForSaleItem = EmptyForSaleItem;
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(RewardState);
		RewardState.SetReward(TechList[idx].GetReference());
		ForSaleItem.RewardRef = RewardState.GetReference();

		ForSaleItem.Title = RewardState.GetRewardString();
		ForSaleItem.Cost = GetTechRushCost(TechList[idx], NewGameState, PriceReductionScalar);
		ForSaleItem.Desc = RewardState.GetBlackMarketString();
		ForSaleItem.Image = RewardState.GetRewardImage();
		ForSaleItem.CostScalars = GoodsCostScalars;
		ForSaleItem.DiscountPercent = GoodsCostPercentDiscount;

		ForSaleItems.AddItem(ForSaleItem);
	}

	// Supply Reward
	ForSaleItem = EmptyForSaleItem;
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Supplies'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(RewardState);
	RewardState.GenerateReward(NewGameState, default.SupplyGoodScalar[`DIFFICULTYSETTING]);
	ForSaleItem.RewardRef = RewardState.GetReference();

	ForSaleItem.Title = RewardState.GetRewardString();
	ForSaleItem.Cost = GetForSaleItemCost(PriceReductionScalar);
	ForSaleItem.Desc = RewardState.GetBlackMarketString();
	ForSaleItem.Image = RewardState.GetRewardImage();
	ForSaleItem.CostScalars = GoodsCostScalars;
	ForSaleItem.DiscountPercent = GoodsCostPercentDiscount;

	ForSaleItems.AddItem(ForSaleItem);

	// Personnel Reward
	PersonnelRewardNames.AddItem('Reward_Scientist');
	PersonnelRewardNames.AddItem('Reward_Engineer');
	PersonnelRewardNames.AddItem('Reward_Soldier');

	ForSaleItem = EmptyForSaleItem;
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(PersonnelRewardNames[`SYNC_RAND(PersonnelRewardNames.Length)]));
	
	// Only give the personnel reward if it is available for the player
	if (RewardTemplate.IsRewardAvailableFn == none || RewardTemplate.IsRewardAvailableFn())
	{
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);

		NewGameState.AddStateObject(RewardState);
		RewardState.GenerateReward(NewGameState, , Region);
		ForSaleItem.RewardRef = RewardState.GetReference();

		ForSaleItem.Title = RewardState.GetRewardString();
		ForSaleItem.Cost = GetPersonnelForSaleItemCost(PriceReductionScalar);
		ForSaleItem.Desc = RewardState.GetBlackMarketString();
		ForSaleItem.Image = RewardState.GetRewardImage();
		ForSaleItem.CostScalars = GoodsCostScalars;
		ForSaleItem.DiscountPercent = GoodsCostPercentDiscount;

		if (ForSaleItem.Image == "")
		{
			if (!Photo.HasPendingHeadshot(RewardState.RewardObjectReference, OnUnitHeadCaptureFinished))
			{
				Photo.AddHeadshotRequest(RewardState.RewardObjectReference, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Head_Armory', 512, 512, OnUnitHeadCaptureFinished);
			}
		}

		ForSaleItems.AddItem(ForSaleItem);
	}
}

private function OnUnitHeadCaptureFinished(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local string TextureName;
	local Texture2D UnitPicture;
	local X2ImageCaptureManager CapMan;
	CapMan = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	
	if (ReqInfo.Height == 512 && ReqInfo.Width == 512)
	{
		TextureName = "UnitPicture"$ReqInfo.UnitRef.ObjectID;
	}
	else
	{
		TextureName = "UnitPictureSmall"$ReqInfo.UnitRef.ObjectID;
	}

	UnitPicture = RenderTarget.ConstructTexture2DScript(CapMan, TextureName, false, false, false);	
	CapMan.StoreImage(ReqInfo.UnitRef, UnitPicture, name(TextureName));
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Tech> RollForTechRushItems()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Tech> ChosenTechs;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> AvailableTechRefs;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Grab all available techs
	AvailableTechRefs = XComHQ.GetAvailableTechsForResearch();

	// Include current Tech being researched
	TechState = XComHQ.GetCurrentResearchTech();
	
	if(TechState != none)
	{
		AvailableTechRefs.AddItem(TechState.GetReference());
	}

	// Filter Techs (no instant, repeatable, priority)
	for(idx = 0; idx < AvailableTechRefs.Length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(AvailableTechRefs[idx].ObjectID));

		if(TechState != none && TechState.CanBeRushed())
		{
			ChosenTechs.AddItem(TechState);
		}
	}
	
	// Limit chosen techs to a max number
	while (ChosenTechs.Length > default.NumTechRushes[`DIFFICULTYSETTING])
	{
		ChosenTechs.Remove(`SYNC_RAND_STATIC(ChosenTechs.Length), 1);
	}

	return ChosenTechs;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Item> RollForBlackMarketLoot(XComGameState NewGameState)
{
	local X2ItemTemplateManager ItemMgr;
	local array<XComGameState_Item> ItemList;
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;
	local X2LootTableManager LootManager;
	local LootResults Loot;
	local int LootIndex, idx, i;
	local bool bFound;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	LootManager = class'X2LootTableManager'.static.GetLootTableManager();
	LootIndex = LootManager.FindGlobalLootCarrier('BlackMarket');

	if(LootIndex >= 0)
	{
		LootManager.RollForGlobalLootCarrier(LootIndex, Loot);
	}

	for(idx = 0; idx < Loot.LootToBeCreated.Length; idx++)
	{
		bFound = false;
		
		if(InterestTemplates.Find(Loot.LootToBeCreated[idx]) == INDEX_NONE)
		{
			for(i = 0; i < ItemList.Length; i++)
			{
				if(Loot.LootToBeCreated[idx] == ItemList[i].GetMyTemplateName())
				{
					bFound = true;
					ItemList[i].Quantity++;
					break;
				}
			}

			if(!bFound)
			{
				ItemTemplate = ItemMgr.FindItemTemplate(Loot.LootToBeCreated[idx]);

				if(ItemTemplate != none)
				{
					ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
					NewGameState.AddStateObject(ItemState);
					ItemList.AddItem(ItemState);
				}
			}
		}
	}

	return ItemList;
}

//---------------------------------------------------------------------------------------
function SetInterests()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	local array<StateObjectReference> AllItems;
	local name InterestName;
	local int idx, i;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AllItems = XComHQ.GetTradingPostItems();
	InterestTemplates.Length = 0;

	for(idx = 0; idx < default.NumInterestItems[`DIFFICULTYSETTING]; idx++)
	{
		if(AllItems.Length > 0)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(AllItems[`SYNC_RAND(AllItems.Length)].ObjectID));

			if(ItemState != none)
			{
				InterestName = ItemState.GetMyTemplateName();
				InterestTemplates.AddItem(InterestName);

				for(i = 0; i < AllItems.Length; i++)
				{
					ItemState = XComGameState_Item(History.GetGameStateForObjectID(AllItems[i].ObjectID));

					if(ItemState != none && ItemState.GetMyTemplateName() == InterestName)
					{
						AllItems.Remove(i, 1);
						i--;
					}
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function UpdateForSaleItemDiscount()
{
	local int idx;

	for (idx = 0; idx < ForSaleItems.Length; idx++)
	{
		ForSaleItems[idx].DiscountPercent = GoodsCostPercentDiscount;
	}
}

//---------------------------------------------------------------------------------------
function bool UpdateBuyPrices()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StateObjectReference> AllItems;
	local bool bUpdated;
	local int idx;
	local BlackMarketItemPrice BuyPrice;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AllItems = XComHQ.GetTradingPostItems();
	bUpdated = false;

	// Remove prices for items not available to be sold
	for(idx = 0; idx < BuyPrices.Length; idx++)
	{
		if(AllItems.Find('ObjectID', BuyPrices[idx].ItemRef.ObjectID) == INDEX_NONE)
		{
			BuyPrices.Remove(idx, 1);
			idx--;
			bUpdated = true;
		}
	}

	// Add items that aren't in the price list
	for(idx = 0; idx < AllItems.Length; idx++)
	{
		if(BuyPrices.Find('ItemRef', AllItems[idx]) == INDEX_NONE)
		{
			BuyPrice = GetItemPrice(AllItems[idx]);
			BuyPrices.AddItem(BuyPrice);
			bUpdated = true;
		}
	}

	return bUpdated;
}

//---------------------------------------------------------------------------------------
function private BlackMarketItemPrice GetItemPrice(StateObjectReference ItemRef)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local BlackMarketItemPrice BuyPrice;
	local int PriceDelta;

	History = `XCOMHISTORY;
	ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemRef.ObjectID));
	BuyPrice.ItemRef = ItemRef;
	BuyPrice.Price = ItemState.GetMyTemplate().TradingPostValue;
	PriceDelta = float(BuyPrice.Price) * (float(`SYNC_RAND(default.BuyPriceVariancePercent[`DIFFICULTYSETTING])) / 100.0);

	if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		PriceDelta = -PriceDelta;
	}

	BuyPrice.Price += PriceDelta;

	if(BuyPrice.Price <= 0)
	{
		BuyPrice.Price = 1;
	}

	if(InterestTemplates.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
	{
		BuyPrice.Price *= default.InterestPriceMultiplier[`DIFFICULTYSETTING];
	}

	return BuyPrice;
}

//---------------------------------------------------------------------------------------
function CleanUpForSaleItems(XComGameState NewGameState)
{
	local XComGameState_Reward RewardState;
	local XComGameStateHistory History;
	local int idx;
	local bool bStartState;

	bStartState = (NewGameState.GetContext().IsStartState());
	History = `XCOMHISTORY;

	for(idx = 0; idx < ForSaleItems.Length; idx++)
	{
		if(bStartState)
		{
			RewardState = XComGameState_Reward(NewGameState.GetGameStateForObjectID(ForSaleItems[idx].RewardRef.ObjectID));
		}
		else
		{
			RewardState = XComGameState_Reward(History.GetGameStateForObjectID(ForSaleItems[idx].RewardRef.ObjectID));
		}

		if(RewardState != none)
		{
			RewardState.CleanUpReward(NewGameState);
			NewGameState.RemoveStateObject(RewardState.ObjectID);
		}
	}

	ForSaleItems.Length = 0;
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

// THIS FUNCTION SHOULD RETURN TRUE IN ALL THE SAME CASES AS Update
function bool ShouldUpdate( )
{
	local UIStrategyMap StrategyMap;

	StrategyMap = `HQPRES.StrategyMap2D;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass( class'UIAlert' ))
	{
		// Check if making contact is complete
		if (bNeedsScan && IsScanComplete( ))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// IF ADDING NEW CASES WHERE bModified = true, UPDATE FUNCTION ShouldUpdate ABOVE
function bool Update(XComGameState NewGameState)
{
	local UIStrategyMap StrategyMap;
	local bool bModified;

	StrategyMap = `HQPRES.StrategyMap2D;
	bModified = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{		
		// If the Avenger is not at the location and time runs out, close the market
		/*if ((bNeedsScan || bIsOpen) && XComHQ.GetCurrentScanningSite().GetReference().ObjectID != ObjectID && class'X2StrategyGameRulesetDataStructures'.static.LessThan(ClosingTime, GetCurrentTime()))
		{
			CloseBlackMarket(NewGameState);
			bModified = true;
		}*/

		// Check if making contact is complete
		if (bNeedsScan && IsScanComplete())
		{
			OpenBlackMarket(NewGameState);

			// Reset the scan timer so it can be used again the next time the Black Market appears
			//ResetScan();

			bModified = true;
		}
	}

	return bModified;
}

//#############################################################################################
//----------------   MISSIONS   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function StrategyCost GetForSaleItemCost(optional float CostScalar = 1.0f)
{
	local StrategyCost Cost;
	local ArtifactCost ResourceCost;
	local int IntelAmount, IntelVariance;

	IntelAmount = default.BaseItemIntelCost[`DIFFICULTYSETTING] + ((NumTimesAppeared - 1) * default.ItemIntelCostIncrease[`DIFFICULTYSETTING]);
	IntelVariance = Round((float(`SYNC_RAND(default.IntelCostVariance[`DIFFICULTYSETTING])) / 100.0)* float(IntelAmount));

	if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		IntelVariance = -IntelVariance;
	}

	IntelAmount += IntelVariance;
	IntelAmount = Round(float(IntelAmount) * CostScalar);

	// Make it a multiple of 5
	IntelAmount = Round(float(IntelAmount) / 5.0) * 5;

	ResourceCost.ItemTemplateName = 'Intel';
	ResourceCost.Quantity = IntelAmount;
	Cost.ResourceCosts.AddItem(ResourceCost);

	return Cost;
}

//---------------------------------------------------------------------------------------
function StrategyCost GetPersonnelForSaleItemCost(optional float CostScalar = 1.0f)
{
	local StrategyCost Cost;
	local ArtifactCost ResourceCost;
	local int IntelAmount, IntelVariance;

	IntelAmount = default.PersonnelItemIntelCost[`DIFFICULTYSETTING] + ((NumTimesAppeared - 1) * default.PersonnelItemIntelCostIncrease[`DIFFICULTYSETTING]);
	IntelVariance = Round((float(`SYNC_RAND(default.IntelCostVariance[`DIFFICULTYSETTING])) / 100.0)* float(IntelAmount));

	if(class'X2StrategyGameRulesetDataStructures'.static.Roll(50))
	{
		IntelVariance = -IntelVariance;
	}

	IntelAmount += IntelVariance;
	IntelAmount = Round(float(IntelAmount) * CostScalar);

	// Make it a multiple of 5
	IntelAmount = Round(float(IntelAmount) / 5.0) * 5;

	ResourceCost.ItemTemplateName = 'Intel';
	ResourceCost.Quantity = IntelAmount;
	Cost.ResourceCosts.AddItem(ResourceCost);

	return Cost;
}

function UpdateTechRushItems(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local array<Commodity> UpdatedTechRushes;
	local Commodity TechRushCommodity;
	local int idx;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < ForSaleItems.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(ForSaleItems[idx].RewardRef.ObjectID));

		if(RewardState != none && RewardState.GetMyTemplateName() == 'Reward_TechRush')
		{
			TechRushCommodity = ForSaleItems[idx];
			ForSaleItems.Remove(idx, 1);
			idx--;

			if(!XComHQ.TechIsResearched(RewardState.RewardObjectReference))
			{
				TechState = XComGameState_Tech(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
				if (TechState.CanBeRushed()) // Verify the tech can still be rushed before re-adding
				{
					TechRushCommodity.Cost = GetTechRushCost(TechState, NewGameState, PriceReductionScalar);
					UpdatedTechRushes.AddItem(TechRushCommodity);
				}
			}
		}
	}

	for(idx = 0; idx < UpdatedTechRushes.Length; idx++)
	{
		ForSaleItems.AddItem(UpdatedTechRushes[idx]);
	}
}

//---------------------------------------------------------------------------------------
function StrategyCost GetTechRushCost(XComGameState_Tech TechState, XComGameState NewGameState, optional float CostScalar = 1.0f)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchState;
	local int PointsToComplete, IntelCost;
	local StrategyCost StratCost;
	local ArtifactCost ResourceCost;
	
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectResearch', ResearchState)
	{
		if(ResearchState.ProjectFocus == TechState.GetReference())
		{
			ResearchState = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch', ResearchState.ObjectID));
			NewGameState.AddStateObject(ResearchState);
			ResearchState.UpdateProjectPointsRemaining(ResearchState.GetCurrentWorkPerHour());
			PointsToComplete = ResearchState.ProjectPointsRemaining;
			NewGameState.PurgeGameStateForObjectID(ResearchState.ObjectID);
			break;
		}
	}

	if(PointsToComplete == 0)
	{
		PointsToComplete = TechState.GetMyTemplate().PointsToComplete;
	}

	IntelCost = Round((float(PointsToComplete) / float(default.TechPointsPerIntelCost[`DIFFICULTYSETTING])));
	IntelCost = Round(float(IntelCost) * CostScalar);
	
	// Make it a multiple of 5
	IntelCost = Round(float(IntelCost) / 5.0) * 5;
	IntelCost = Clamp(IntelCost, 5, IntelCost);
	ResourceCost.ItemTemplateName = 'Intel';
	ResourceCost.Quantity = IntelCost;
	StratCost.ResourceCosts.AddItem(ResourceCost);

	return StratCost;
}

//---------------------------------------------------------------------------------------
function ShowMission(XComGameState NewGameState)
{
	local XComGameState_MissionSite MissionState;
		
	// Set the mission to be visible and start expiring
	MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', Mission.ObjectID));
	NewGameState.AddStateObject(MissionState);
	MissionState.Available = true;
	MissionState.Expiring = true;
	MissionState.TimerStartDateTime = `STRATEGYRULES.GameTime;
	MissionState.SetProjectedExpirationDateTime(MissionState.TimerStartDateTime);
}

//#############################################################################################
//----------------  TRADING POST   ------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function array<XComGameState_Item> GetInterests()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Item> InterestItems;
	local array<StateObjectReference> AllItems;
	local XComGameState_Item ItemState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	AllItems = XComHQ.GetTradingPostItems();

	for(idx = 0; idx < AllItems.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(AllItems[idx].ObjectID));

		if(ItemState != none && InterestTemplates.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
		{
			InterestItems.AddItem(ItemState);
		}
	}

	return InterestItems;
}

//---------------------------------------------------------------------------------------
function array<Commodity> GetForSaleList()
{
	return ForSaleItems;
}

//---------------------------------------------------------------------------------------
function BuyBlackMarketItem(StateObjectReference RewardRef)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Reward RewardState;
	local XComGameState_Unit UnitState;
	local int ItemIndex;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ItemIndex = ForSaleItems.Find('RewardRef', RewardRef);

	if(ItemIndex != INDEX_NONE)
	{
		RewardState = XComGameState_Reward( History.GetGameStateForObjectID( RewardRef.ObjectID ) );

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Buy Black Market Item");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.BuyCommodity(NewGameState, ForSaleItems[ItemIndex]);
		BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', self.ObjectID));
		NewGameState.AddStateObject(BlackMarketState);
		BlackMarketState.ForSaleItems.Remove(ItemIndex, 1);

		`XEVENTMGR.TriggerEvent( 'BlackMarketPurchase', RewardState, self, NewGameState );

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		// Check if we need a popup for a new scientist or engineer
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

		if (UnitState != none && (UnitState.IsAScientist() || UnitState.IsAnEngineer()))
		{
			`HQPRES.UINewStaffAvailable(RewardState.RewardObjectReference);
		}
	}
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function string GetDisplayName()
{
	return m_strDisplayLabel;
}

function bool HasTooltipBounds()
{
	return ShouldBeVisible();
}

function bool CanBeScanned()
{
	return bNeedsScan;
}

protected function bool CanInteract()
{
	return ShouldBeVisible();
}

function bool ShouldBeVisible()
{
	return bNeedsScan || bIsOpen;
}

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_BlackMarket';
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return StaticMesh'UI_3D.Overwold_Final.BlackMarkets';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 1;
	ScaleVector.Y = 1;
	ScaleVector.Z = 1;

	return ScaleVector;
}

function OnXComEnterSite()
{
	local XComGameState NewGameState;

	super.OnXComEnterSite();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Avenger Landed POI");
	`XEVENTMGR.TriggerEvent('AvengerLandedScanPOI', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

protected function bool DisplaySelectionPrompt()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// if click here and XComHQ is not in the region, fly to it
	if (XComHQ.CurrentLocation != GetReference())
	{
		return false;
	}

	return true;
}

function DisplayBlackMarket()
{
	if (bIsOpen)
	{
		SetNewGoodsSeen();
		`HQPRES.UIBlackMarket();
	}
}

function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;
	local bool bSuccess;

	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Update Black Market" );

		BlackMarketState = XComGameState_BlackMarket( NewGameState.CreateStateObject( class'XComGameState_BlackMarket', ObjectID ) );
		NewGameState.AddStateObject( BlackMarketState );

		bSuccess = BlackMarketState.Update(NewGameState);
		`assert( bSuccess );

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
	}
	
	if (bNeedsAppearedPopup)
	{
		BlackMarketAppearedPopup();
	}
	else if (bNeedsOpenPopup)
	{
		BlackMarketPopup();
	}
}

//---------------------------------------------------------------------------------------
function DestinationReached()
{
	super.DestinationReached();

	if (bIsOpen)
	{
		SetNewGoodsSeen();
		`HQPRES.UIBlackMarket();
	}
}

//---------------------------------------------------------------------------------------
function SetNewGoodsSeen()
{
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;

	if (!bHasSeenNewGoods)
	{
		// Flag the black market goods as having been seen
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("New black market goods seen");
		BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', ObjectID));
		NewGameState.AddStateObject(BlackMarketState);
		BlackMarketState.bHasSeenNewGoods = true;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
simulated public function BlackMarketAppearedPopup()
{
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Black Market Appeared Popup");
	BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', self.ObjectID));
	NewGameState.AddStateObject(BlackMarketState);
	BlackMarketState.bNeedsAppearedPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIBlackMarketAppearedAlert();

	`GAME.GetGeoscape().Pause();
}

//---------------------------------------------------------------------------------------
simulated public function BlackMarketPopup()
{
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Black Market Open Popup");
	BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', self.ObjectID));
	NewGameState.AddStateObject(BlackMarketState);
	BlackMarketState.bNeedsOpenPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	`HQPRES.UIBlackMarketAlert();

	`GAME.GetGeoscape().Pause();
}

simulated function string GetUIButtonIcon()
{
	return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_BlackMarket";
}

simulated function string GetUIButtonTooltipTitle()
{
	return Caps(GetDisplayName());
}

simulated function string GetUIButtonTooltipBody()
{
	local string TooltipStr, ScanTimeValue, ScanTimeLabel;
	local int DaysRemaining;

	if (!bIsOpen)
	{
		DaysRemaining = GetNumScanDaysRemaining();
		if (DaysRemaining > 0)
		{
			ScanTimeValue = string(DaysRemaining);
			ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
			TooltipStr = ScanTimeValue @ ScanTimeLabel @ m_strRemainingLabel;
		}
	}

	return TooltipStr;
}

//---------------------------------------------------------------------------------------

protected function bool CurrentlyInteracting()
{
	// Notify only if we haven't opened the Black Market yet
	// and the avenger is landed here, then yes, we're interacting.
	return !bIsOpen && GetReference() == class'UIUtilities_Strategy'.static.GetXComHQ().CurrentLocation;
}

//---------------------------------------------------------------------------------------

DefaultProperties
{
	PriceReductionScalar=1.0f
}
