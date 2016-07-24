class UIResistanceOps extends UISimpleCommodityScreen;

var StateObjectReference RegionRef;

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
		GetItems();
		PopulateData();
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
	arrItems.Length = 0;
}

simulated function XComGameState_Haven GetHaven()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID)).GetHaven();
}

defaultproperties
{
	m_eStyle = eUIConfirmButtonStyle_BuyCash;
}