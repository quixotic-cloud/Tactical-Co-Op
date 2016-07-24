class UIResistanceGoods extends UISimpleCommodityScreen;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;
	
	super.InitScreen(InitController, InitMovie, InitName);
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On ResHQ Goods Open");
	`XEVENTMGR.TriggerEvent('OnResHQGoodsOpen', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
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
		PlaySFX("BuildItem");
		RESHQ().BuyResistanceGood(arrItems[iSelectedItem].RewardRef);
		GetItems();
		PopulateData();

		// Queue new staff popups to give an alert if a Sci or Eng was received
		`HQPRES.DisplayNewStaffPopupIfNeeded();
	}
	else
	{
		class'UIUtilities_Sound'.static.PlayNegativeSound();
	}
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------


simulated function GetItems()
{
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	arrItems = RESHQ().ResistanceGoods;
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

defaultproperties
{
	m_eStyle = eUIConfirmButtonStyle_Default; //word button
	bIsIn3D = false;
	bConsumeMouseEvents = true;
}