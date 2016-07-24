class UIResistance extends UIX2SimpleScreen;

var StateObjectReference RegionRef;

var public localized String m_strSupplyIncome;
var public localized String m_strMakeContact;
var public localized String m_strLockedHelp;
var public localized String m_strContactCap;
var public localized String m_strContactCapHelp_BuildComms;
var public localized String m_strContactCapHelp_UpgradeComms;
var public localized String m_strOutpostReward;
var public localized String m_strBuildOutpost;
var public localized String m_strResOps;
var public localized String m_strCurrentResOp;
var public localized String m_strFly;
var public localized String m_strResGoodsHelp;
var public localized String m_strResHQ;
var public localized String m_strResHQHelp;
var public localized String m_strResGoods;
var public localized String m_strUFOTitle;
var public localized String m_strInterceptionChance;

var public bool bInstantInterp;

const CAMERA_ZOOM = 0.75f;

const PANEL_WIDTH = 300.0f;
const PANEL_TOP = 750.0f;
const PANEL_LEFT = 800.0f;

delegate ActionCallback(EUIAction eAction);


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	BuildScreen();

	`GAME.GetGeoscape().Pause();
}

//-------------- UI LAYOUT --------------------------------------------------------
simulated function BuildScreen()
{
	local TRect rCancel;
	local float fY;

	HQPRES().CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		HQPRES().CAMLookAtEarth(GetRegion().Get2DLocation(), CAMERA_ZOOM, 0);
	}
	else
	{
		HQPRES().CAMLookAtEarth(GetRegion().Get2DLocation(), CAMERA_ZOOM);
	}

	
	PlayOpenSound();

	GetStrategyMap().SetUIState(eSMS_Resistance);

	BuildBGPanels(AnchorRect(MakeRect(0, 0, 1000, 600), eRectAnchor_Center), 0.5f);

	// Region Name, Control, and Income
	fY = BuildIncomePanel(PANEL_TOP);

	if( XCOMHQ().Region != RegionRef )
	{
		fY = BuildFlightPanel(fY);
	}
	if( XCOMHQ().IsContactResearched() )
	{
		if( GetRegion().ResistanceLevel == eResLevel_Locked || GetRegion().ResistanceLevel == eResLevel_Unlocked )
		{
			fY = BuildContactPanel(fY);
		}
	}
	if( XCOMHQ().IsOutpostResearched() )
	{
		if( IsBuildingOutpost() )
		{
			fY = BuildOutpostPanel(fY);
		}
	}
	if( XCOMHQ().StartingRegion.ObjectID == RegionRef.ObjectID )
	{
		BuildResistanceHQPanel();
	}
	
	// Cancel
	rCancel = AnchorRect(MakeRect(0, 0, 50, 20), eRectAnchor_BottomLeft, 25);
	AddButton(rCancel, m_strBack, OnExitButtonClicked);

	GetRegion().RefreshMapItem();
}

simulated function BuildBGPanels(TRect rWindow, float fAlpha)
{
	AddFillRect(MakeRect(0, 0, 1920, rWindow.fTop), MakeLinearColor(0, 0, 0, fAlpha));
	AddFillRect(MakeRect(0, rWindow.fTop, rWindow.fLeft, RectHeight(rWindow)), MakeLinearColor(0, 0, 0, fAlpha));
	AddFillRect(MakeRect(rWindow.fRight, rWindow.fTop, 1920 - rWindow.fRight, RectHeight(rWindow)), MakeLinearColor(0, 0, 0, fAlpha));
	AddFillRect(MakeRect(0, rWindow.fBottom, 1920, 1080-rWindow.fBottom), MakeLinearColor(0, 0, 0, fAlpha));
}

simulated function float BuildIncomePanel(float fTop)
{
	local TRect rPanel;
	local TRect rName, rControl, rIncome, rIncomeLabel;

	rPanel = MakeRect(PANEL_LEFT, fTop, PANEL_WIDTH, 60);
	AddBG(rPanel, eUIState_Normal);
	AddBG(rPanel, eUIState_Normal);

	rName = HSubRect(rPanel, 0, 0.5f);
	rControl = VSubRect( HSubRect(rPanel, 0, 0.5f), 0.5f, 1.0f );
	rIncome = PadRect( HSubRect(rPanel, 0.6f, 0.9f), 5 );

	// Region Name
	AddTitle(rName, GetRegionName(), GetRegionColor(GetRegionControl()), 25);

	// Control
	AddControlBar(rControl, GetRegionControl());

	// Region Income
	AddBG(rIncome, eUIState_Good);
	rIncomeLabel = VSubRectPixels(rIncome, 0.0f, 20);
	AddTitle(rIncomeLabel, m_strSupplyIncome, GetRegionSupplyColor(), 15).SetAlpha(0.5f);
	rIncome.fTop += RectHeight(rIncomeLabel);
	AddTitle(rIncome, GetRegionSupplyString(), GetRegionSupplyColor(), 25);

	return fTop + RectHeight(rPanel);
}

simulated function float BuildContactPanel(float fTop)
{
	local TRect rPanel;
	local TRect rTitle, rCost;

	rPanel = MakeRect(PANEL_LEFT, fTop, PANEL_WIDTH, 100);
	AddBG(rPanel, GetContactColor());
	AddBG(rPanel, GetContactColor());

	rTitle = VSubRectPixels(rPanel, 0, 30);
	rCost = VCopyRect(rTitle, 0, 70);

	// "Make Contact" Label
	AddUncenteredTitle(rTitle, m_strMakeContact, GetContactColor(), 25).SetAlpha(0.5f);

	// Communications Capacity
	AddTitle(HSubRect(rTitle, 0.6f, 1.0f), GetContactCapString(), GetContactCapColor(), 15);

	if( IsMakingContact() )
	{
		if( HasContactCapacity() )
		{
			// Cost Panel
			BuildCostPanel(rCost, GetContactCostLabel(), GetCostString(), CanAffordCost());
		}
		else
		{
			AddBG(rCost, eUIState_Bad);
			AddTitle(rCost, GetContactCapHelpString(), eUIState_Bad, 15);
		}
	}
	else
	{
		AddBG(rCost, GetContactColor());
		AddTitle(rCost, m_strLockedHelp, GetContactColor(), 25);
	}

	return fTop + RectHeight(rPanel);
}

simulated function float BuildOutpostPanel(float fTop)
{
	local TRect rPanel;
	local TRect rTitle;

	rPanel = MakeRect(PANEL_LEFT, fTop, PANEL_WIDTH, 100);
	AddBG(rPanel, eUIState_Normal);
	AddBG(rPanel, eUIState_Normal);

	rTitle = VSubRectPixels(rPanel, 0, 30);

	// "Build Outpost" Label
	AddUncenteredTitle(rTitle, m_strBuildOutpost, eUIState_Normal, 25).SetAlpha(0.5f);

	return fTop + RectHeight(rPanel);
}

simulated function float BuildFlightPanel(float fTop)
{
	local TRect rPanel, rButtons;
	local TRect rFly;

	`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.Avenger_New_Course');
	rPanel = MakeRect(PANEL_LEFT, fTop, PANEL_WIDTH, 50);
	AddBG(rPanel, eUIState_Normal);
	AddBG(rPanel, eUIState_Normal);

	rButtons = VSubRect(rPanel, 0.25, 0.75f);
	rFly = HSubRect(rButtons, 0.0f, 1.0f);

	AddButton(rFly, GetFlightString(), OnFlightClicked);

	return fTop + RectHeight(rPanel);
}

simulated function BuildResistanceHQPanel()
{
	local TRect rPanel;
	local TRect rTitle, rGoods, rHelp;
	local UIButton ResGoodsButton;

	rPanel = AnchorRect(MakeRect(0, 0, 350, 110), eRectAnchor_TopCenter, 125);
	AddBG(rPanel, eUIState_Normal);
	AddBG(rPanel, eUIState_Normal);

	rTitle = VSubRectPixels(rPanel, 0, 30);

	// "Resistance HQ" Label
	AddTitle(rTitle, m_strResHQ, eUIState_Warning, 25);

	if( !HasResistanceGoods() )
	{
		rHelp = VCopyRect(rTitle, 10, 80);
		AddBG(rHelp, eUIState_Normal);
		AddTitle(rHelp, GetResistanceHQHelpString(), eUIState_Normal, 16);
	}
	else
	{
		rGoods = VCopyRect(rTitle, 25, 55);

		ResGoodsButton = AddButton(rGoods, m_strResGoods, OnResGoodsClicked);

		if( !CanBuyResGoods() )
		{
			ResGoodsButton.DisableButton(m_strResGoodsHelp);
		}
	}
} 

simulated function bool CanBuyResGoods()
{
	return XCOMHQ().Region == RegionRef;
}

simulated function UpdateData()
{
	//ClearOptionsPanel();
	//UpdateControlBar(GetRegionControl());
	//BuildOptionsPanel();
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnResGoodsClicked(UIButton button)
{
	HQPRES().UIResistanceGoods();
}
simulated function OnHavenOpsClicked(UIButton button)
{
	HQPRES().UIResistanceOps(GetRegion().GetReference());
}

simulated function OnFlightClicked(UIButton button)
{
	CloseScreen();
	
	GetRegion().ConfirmSelection();
}
simulated function OnExitButtonClicked(UIButton button)
{
	CloseScreen();
}

simulated function CloseScreen()
{
	GetStrategyMap().SetUIState(eSMS_Default);
	`GAME.GetGeoscape().Resume();
	super.CloseScreen();
	GetRegion().RefreshMapItem();
}

simulated function OnRemoved()
{
	HQPRES().CAMRestoreSavedLocation();

	super.OnRemoved();

	PlaySFX("Play_MenuClose");
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function XComGameState_WorldRegion GetRegion()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));
}
simulated function bool IsMakingContact()
{
	return GetRegion().ResistanceLevel == eResLevel_Unlocked;
}

simulated function bool IsBuildingOutpost()
{
	return GetRegion().ResistanceLevel == eResLevel_Contact;
}
simulated function String GetFlightString()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegionName();

	return `XEXPAND.ExpandString(m_strFly);
}

simulated function EUIState GetContactColor()
{
	if( GetRegion().ResistanceLevel > eResLevel_Locked )
	{
		return eUIState_Normal;
	}
	else
	{
		return eUIState_Disabled;
	}
}

simulated function String GetContactCostLabel()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = GetRegion().ContactCostScalars[0].Scalar;

	return `XEXPAND.ExpandString(class'UIAlert'.default.m_strContactCostHelp);
}
simulated function bool HasResistanceGoods()
{
	return RESHQ().ResistanceGoods.Length > 0;
}

simulated function String GetRegionName()
{
	return GetRegion().GetMyTemplate().DisplayName;
}
simulated function int GetRegionControl()
{
	return 0;
}

simulated function String GetRegionSupplyString()
{
	return FormatSupplies(GetRegion().GetSupplyDropReward(), true);
}

simulated function EUIState GetRegionSupplyColor()
{
	switch(GetRegion().ResistanceLevel )
	{
	case eResLevel_Unlocked:
		return eUIState_Normal;
	case eResLevel_Contact:
	case eResLevel_Outpost:
		return eUIState_Good;
	case eResLevel_Locked:
	default:
		return eUIState_Disabled;
	}
}

simulated function String GetCostString()
{
	if( IsMakingContact() )
	{
		return class'UIUtilities_Strategy'.static.GetStrategyCostString(GetRegion().CalcContactCost(), GetRegion().ContactCostScalars);
	}
	else if( IsBuildingOutpost() )
	{
		return class'UIUtilities_Strategy'.static.GetStrategyCostString(GetRegion().CalcOutpostCost(), GetRegion().OutpostCostScalars);
	}

	return "";
}

simulated function bool CanAffordCost()
{
	if( IsMakingContact() )
	{
		return XCOMHQ().CanAffordAllStrategyCosts(GetRegion().CalcContactCost(), GetRegion().ContactCostScalars);
	}
	else if( IsBuildingOutpost() )
	{
		return XCOMHQ().CanAffordAllStrategyCosts(GetRegion().CalcOutpostCost(), GetRegion().OutpostCostScalars);
	}

	return false;
}

simulated function bool HasContactCapacity()
{
	return XCOMHQ().GetRemainingContactCapacity() > 0;
}

simulated function String GetContactCapString()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = XCOMHQ().GetCurrentResContacts();
	ParamTag.IntValue1 = XCOMHQ().GetPossibleResContacts();

	return `XEXPAND.ExpandString(m_strContactCap);
}

simulated function EUIState GetContactCapColor()
{
	local int iCapDiff;

	iCapDiff = XCOMHQ().GetRemainingContactCapacity();

	if( iCapDiff > 1 )
	{
		return eUIState_Normal;
	}
	else if( iCapDiff == 1 )
	{
		return eUIState_Warning;
	}
	else
	{
		return eUIState_Bad;
	}
}

simulated function bool ShouldShowContactCapHelp()
{
	return XCOMHQ().GetRemainingContactCapacity() < 1;
}

simulated function String GetContactCapHelpString()
{
	local XGParamTag ParamTag;

	if( XCOMHQ().HasFacilityByName('ResistanceComms') )
	{
		return m_strContactCapHelp_UpgradeComms;
	}
	else
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.StrValue0 = XCOMHQ().GetFacilityByName('ResistanceComms').GetMyTemplate().DisplayName;

		return `XEXPAND.ExpandString(m_strContactCapHelp_BuildComms);
	}
}

simulated function String GetResistanceHQHelpString()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegionSupplyString();

	return `XEXPAND.ExpandString(m_strResHQHelp);
}

/*
simulated function String GetNearestOutpostString()
{
	local XGParamTag ParamTag;
	local XComGameState_WorldRegion NearestOutpost;

	NearestOutpost = GetRegion().GetNearestOupostRegion();

	if( NearestOutpost != none )
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.StrValue0 = NearestOutpost.GetMyTemplate().DisplayName;

		return `XEXPAND.ExpandString(m_strNearestOutpost);
	}
	else
	{
		return m_strNoOutpost;
	}
}*/

//==============================================================================

simulated function UIStrategyMap GetStrategyMap()
{
	return UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));
}

defaultproperties
{
	InputState = eInputState_Consume;
}