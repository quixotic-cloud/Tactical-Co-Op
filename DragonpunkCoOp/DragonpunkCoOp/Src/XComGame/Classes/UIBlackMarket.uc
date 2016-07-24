
class UIBlackMarket extends UIScreen;

const NUM_WELCOMES = 7;

var public localized String m_strTitle;
var public localized String m_strBuy;
var public localized String m_strSell;
var public localized String m_strImage;
var public localized String m_strSupplyLineRaid;
var public localized String m_strLandedUFOMission;
var public localized String m_strWelcome[NUM_WELCOMES];
var public localized String m_strInterests[3];
var public localized String m_strSupplyPool;
var public localized String m_strInterestTitle;
var public localized String m_strEmptyThisMonth;
var public localized string m_strEmptyInventory;

var UIPanel LibraryPanel;
var UIButton Button1, Button2, Button3;
var UIImage ImageTarget;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;

	super.InitScreen(InitController, InitMovie, InitName);
	BuildScreen();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On Black Market Open");
	`XEVENTMGR.TriggerEvent('OnBlackMarketOpen', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function BuildScreen()
{
	local UIPanel ButtonGroup;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Enter");

	LibraryPanel = Spawn(class'UIPanel', self);
	LibraryPanel.bAnimateOnInit = false;
	LibraryPanel.InitPanel('', 'BlackMarketMenu');
		
	ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
	ButtonGroup.InitPanel('ButtonGroup', '');

	Button1 = Spawn(class'UIButton', ButtonGroup);
	Button1.SetResizeToText(false);
	Button1.InitButton('Button0', m_strBuy);

	Button2 = Spawn(class'UIButton', ButtonGroup);
	Button2.SetResizeToText(false);
	Button2.InitButton('Button1', m_strSell);
	
	RefreshButtons();
	
	Button3 = Spawn(class'UIButton', ButtonGroup);
	Button3.SetResizeToText(false);
	Button3.InitButton('Button2', "");

	ImageTarget = Spawn(class'UIImage', LibraryPanel).InitImage('MarketMenuImage');
	ImageTarget.LoadImage(m_strImage);

	//-----------------------------------------------

	LibraryPanel.MC.FunctionString("SetMenuQuote", m_strWelcome[Rand(NUM_WELCOMES)]);

	LibraryPanel.MC.BeginFunctionOp("SetMenuInterest");
	LibraryPanel.MC.QueueString(m_strInterestTitle);
	LibraryPanel.MC.QueueString(GetInterestsString());
	LibraryPanel.MC.EndOp();

	Button1.OnClickedDelegate = OnBuyClicked;
	Button2.OnClickedDelegate = OnSellClicked;
	Button3.Hide();

	LibraryPanel.MC.BeginFunctionOp("SetGreeble");
	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterLeft);
	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
	LibraryPanel.MC.QueueString(class'UIAlert'.default.m_strBlackMarketLogoString);
	LibraryPanel.MC.EndOp();

	LibraryPanel.MC.FunctionVoid("AnimateIn");

	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.ClearButtonHelp();
	XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);
	RefreshButtons();
}

simulated function RefreshButtons()
{
	if( HasItemsForSale() )
	{
		Button1.SetText(m_strBuy);
		Button1.SetDisabled(false, "");
	}
	else
	{
		Button1.SetDisabled(true, m_strEmptyThisMonth);
	}

	if( PlayerHasItemsToSell() )
	{
		Button2.SetDisabled(false);
		Button2.SetText(m_strSell);
	}
	else
	{
		Button2.SetDisabled(true);
		Button2.SetText(m_strEmptyInventory);
	}
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnBuyClicked(UIButton button)
{
	`HQPRES.UIBlackMarketBuy();
}
simulated function OnSellClicked(UIButton button)
{
	`HQPRES.UIBlackMarketSell();
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function String GetInterestsString()
{
	local array<XComGameState_Item> Interests;
	local XGParamTag ParamTag;
	local array<name> InterestNames;
	local int idx;

	Interests = class'UIUtilities_Strategy'.static.GetBlackMarket().GetInterests();

	for(idx = 0; idx < Interests.Length; idx++)
	{
		if(InterestNames.Find(Interests[idx].GetMyTemplateName()) != INDEX_NONE)
		{
			Interests.Remove(idx, 1);
			idx--;
		}
		else
		{
			InterestNames.AddItem(Interests[idx].GetMyTemplateName());
		}
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	if( Interests.Length > 2 )
	{
		ParamTag.StrValue0 = Interests[0].GetMyTemplate().GetItemFriendlyName();
		ParamTag.StrValue1 = Interests[1].GetMyTemplate().GetItemFriendlyName();
		ParamTag.StrValue2 = Interests[2].GetMyTemplate().GetItemFriendlyName();

		return `XEXPAND.ExpandString(m_strInterests[2]);
	}
	else if( Interests.Length > 1 )
	{
		ParamTag.StrValue0 = Interests[0].GetMyTemplate().GetItemFriendlyName();
		ParamTag.StrValue1 = Interests[1].GetMyTemplate().GetItemFriendlyName();

		return `XEXPAND.ExpandString(m_strInterests[1]);
	}
	else if( Interests.Length > 0 )
	{
		ParamTag.StrValue0 = Interests[0].GetMyTemplate().GetItemFriendlyName();

		return `XEXPAND.ExpandString(m_strInterests[0]);
	}

	return "";
}

simulated function String GetSupplyPoolString()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = class'UIUtilities_Strategy'.static.GetBlackMarket().SupplyReserve;

	return `XEXPAND.ExpandString(m_strSupplyPool);
}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Black_Market_Ambience_Loop_Stop");
	super.CloseScreen();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		CloseScreen();
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		`HQPRES.UIPauseMenu(, true);
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function bool HasItemsForSale()
{
	return (class'UIUtilities_Strategy'.static.GetBlackMarket().GetForSaleList().Length > 0);
}


simulated function bool PlayerHasItemsToSell()
{
	local BlackMarketItemPrice Item;
	local XComGameState_Item InventoryItem;
	local array<BlackMarketItemPrice> Items;
	local XComGameStateHistory History;
	local XComGameState_BlackMarket BlackMarketState;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
	Items = BlackMarketState.BuyPrices;

	foreach Items(Item)
	{
		// Don't display if none in your inventory to sell
		InventoryItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Item.ItemRef.ObjectID));
		if( InventoryItem.Quantity > 0 )
		{
			return true;
		}
	}
	return false;
}


//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	Package = "/ package/gfxBlackMarket/BlackMarket";
	bConsumeMouseEvents = true;
}