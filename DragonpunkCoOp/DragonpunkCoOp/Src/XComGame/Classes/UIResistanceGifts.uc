class UIResistanceGifts extends UIX2SimpleScreen;

var array<Commodity>		arrGoods;
var array<Commodity>		arrOps;

var UIList		GoodsList;
var UIList		OpsList;
var UIButton	ContinueButton;

var public localized String m_strTitle;
var public localized String m_strTitleQuote;
var public localized String m_strGoodsTitle;
var public localized String m_strOpsTitle;
var public localized String m_strGiftsHelp;

var int m_iSelectedGift;

//-------------- UI LAYOUT --------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	class'UIUtilities_Sound'.static.PlayOpenSound();

	BuildScreen();
}

simulated function BuildScreen()
{
	local TRect rTitle, rList, rHelp, rContinue;

	AddFullscreenBG(0.9f);

	rTitle = MakeRect(0, 0, 1800, 350);
	BuildTitlePanel(rTitle);

	AddBG(MakeRect(0, 351, 1800, 700), eUIState_Warning);

	rList = MakeRect(300, 450, 500, 500);
	GoodsList = AddList(rList, m_strGoodsTitle, OnListClicked);
	BuildGoodsList();

	rHelp = AnchorRect(MakeRect(0, 0, 1600, 80), eRectAnchor_BottomCenter, 50);
	AddBG(rHelp, eUIState_Good);
	AddTitle(rHelp, m_strGiftsHelp, eUIState_Warning, 30);

	// Carry On
	rContinue = MakeRect(1600, 1050, 50, 25);
	ContinueButton = AddButton(rContinue, m_strContinue, OnContinueClicked);
	ContinueButton.DisableButton( "Please choose a resistance gift before continuing." );
}

simulated function BuildTitlePanel(TRect rPanel)
{
	local TRect rImage, rPos;

	AddBG(rPanel, eUIState_Good);
	
	// Corner images
	rImage = MakeRect(rPanel.fLeft, rPanel.fTop, 300, 150);
	AddImage(rImage, "img:///UILibrary_ProtoImages.Proto_GuerrillaOps", eUIState_Good);

	rImage = MakeRect(rPanel.fRight-300, rPanel.fTop, 300, 150);
	AddImage(rImage, "img:///UILibrary_ProtoImages.Proto_GuerrillaOps", eUIState_Good);

	rPos = VSubRectPixels(rPanel, 0.0f, 60);
	AddTitle(rPos, m_strTitle, eUIState_Warning, 50);

	rPos = VCopyRect(rPos, 10, 30);
	AddText(rPos, m_strTitleQuote);

	rImage = VSubRect(HSubRect(rPanel, 0.35f, 0.65f), 0.35f, 1.0f);
	AddImage(rImage, "img:///UILibrary_ProtoImages.Proto_Council", eUIState_Normal);
}

simulated function BuildGoodsList()
{
	local int i;

	GetGoods();

	for( i = 0; i < arrGoods.Length; i++ )
	{
		AddListItem(GoodsList, GetGoodsString(i));
	}
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnListClicked(UIList kList, int itemIndex)
{
	m_iSelectedGift = itemIndex;
	ContinueButton.EnableButton();
}

simulated function OnOpsListClicked(UIList kList, int itemIndex)
{

}

simulated function OnContinueClicked(UIButton button)
{
	RESHQ().BuyResistanceGood(RESHQ().ResistanceGoods[m_iSelectedGift].RewardRef, true);

	CloseScreen();
	HQPRES().UIAdventOperations(true);
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function GetGoods()
{
	arrGoods = RESHQ().ResistanceGoods;
}

simulated function String GetGoodsString(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrGoods.Length )
	{
		return arrGoods[ItemIndex].Title;
	}
	else
	{
		return "";
	}
}
simulated function String GetOpsString(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrOps.Length )
	{
		return arrOps[ItemIndex].Title;
	}
	else
	{
		return "";
	}
}