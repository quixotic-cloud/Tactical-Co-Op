class UIBlackMarket_Buy extends UISimpleCommodityScreen;

var StateObjectReference	BlackMarketRef;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	m_strTitle = ""; //Clear the header out intentionally. 	
	super.InitScreen(InitController, InitMovie, InitName);
	SetBlackMarketLayout();

	MC.BeginFunctionOp("SetGreeble");
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterLeft);
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketLogoString);
	MC.EndOp();
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}

	if( CanAffordItem(iSelectedItem) )
	{
		PlaySFX("StrategyUI_Purchase_Item");
		GetMarket().BuyBlackMarketItem(arrItems[iSelectedItem].RewardRef);
		GetItems();
		PopulateData();
	}
	else
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
	}
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.UpdateResources();
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function XComGameState_BlackMarket GetMarket()
{
	return class'UIUtilities_Strategy'.static.GetBlackMarket();
}

simulated function String GetButtonString(int ItemIndex)
{
	local StateObjectReference RewardRef;
	local XComGameState_Reward RewardState;
	local XComGameState_Unit UnitState;

	RewardRef = arrItems[ItemIndex].RewardRef;

	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));

	if( UnitState != none )
	{
		return class'UIRecruitmentListItem'.default.RecruitConfirmLabel;
	}
	else
	{
		return m_strBuy;
	}
}

simulated function GetItems()
{
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Tech Rushes");
	BlackMarketState = XComGameState_BlackMarket(NewGameState.CreateStateObject(class'XComGameState_BlackMarket', GetMarket().ObjectID));
	NewGameState.AddStateObject(BlackMarketState);
	BlackMarketState.UpdateTechRushItems(NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	arrItems = GetMarket().GetForSaleList();
}

defaultproperties
{
	bConsumeMouseEvents = true;
}
