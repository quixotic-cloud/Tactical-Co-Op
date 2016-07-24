class UIX2SimpleScreen extends UISimpleScreen;

var localized String m_strContactPlusSupplies;
var localized String m_strOutpostPlusSupplies;
var localized String m_strControlPlusSupplies;
var localized String m_strNoContact;

var public localized String m_strResistanceStatus;
var public localized String m_strResLocked;
var public localized String m_strResUnlocked;
var public localized String m_strResContact;
var public localized String m_strResOutpost;

var public localized String m_strIntel;
var public localized String m_strSupplies;
var public localized String m_strTime;
var public localized String m_strCost;
var public localized String m_strRequired;
var public localized String m_strDays;
var public localized String m_strReward;

var public localized String m_strSuppliesPrefix;

// GAME HELPER FUNCS---------------------------------------------------------------
simulated function String FormatSupplies(int iAmount, optional bool bIncome)
{
	local String strSupplies;

	strSupplies = m_strSuppliesPrefix $ iAmount;

	if( bIncome && iAmount > 0 )
	{
		strSupplies = "+" $ strSupplies;
	}

	return strSupplies;
}
simulated function AddControlBar(TRect rPanel, int iRegionControl, optional name InitName)
{
	local int iSegments, i;
	local float fSegmentPct;
	local LinearColor clrPanel;
	local TRect rSegment;

	iSegments = 5;
	fSegmentPct = 1.0f / iSegments;

	clrPanel = GetControlBarColor(iRegionControl);

	for( i = 0; i < iSegments; i++ )
	{
		rSegment = PadRect(HSubRect(rPanel, i*fSegmentPct, (i + 1)*fSegmentPct), 5);
		clrPanel.A = i < iRegionControl ? 1.0f : 0.2f;

		AddFillRect(rSegment, clrPanel, name(String(InitName)$"Control"$i));
	}
}

simulated function LinearColor GetControlBarColor(int iControl)
{
	switch( iControl )
	{
	case 1: return MakeLinearColor(0, 1, 1, 1);	// CYAN
	case 2: return MakeLinearColor(1, 1, 0, 1); // YELLOW
	case 3: return MakeLinearColor(1, 0.5, 0, 1); // ORANGE
	case 4:
	default:
		return MakeLinearColor(1, 0, 0, 1);; // RED
	}
}

simulated function UpdateControlBar(int iRegionControl, optional name InitName)
{
	local int iSegments, i;
	local LinearColor clrPanel;

	iSegments = 5;
	clrPanel = GetControlBarColor(iRegionControl);
	
	for( i = 0; i < iSegments; i++ )
	{
		clrPanel.A = i < iRegionControl ? 1.0f : 0.2f;
		UpdateFillRect(name(String(InitName)$"Control"$i), clrPanel);
	}
}

simulated function BuildRegion(StateObjectReference RegionRef, TRect rPanel)
{
	local XComGameState_WorldRegion Region;
	local TRect rPos;

	Region = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));

	AddBG(rPanel, GetRegionColor(1));

	// Region Name
	rPos = VSubRect(rPanel, 0.0f, 0.33f);
	AddTitle(rPos, Region.GetMyTemplate().DisplayName, GetRegionColor(1), 40);
	// Control Threshold
	// Resistance Status
}

simulated function EUIState GetRegionColor(int iControl)
{
	switch( iControl )
	{
	case 1:
		return eUIState_Normal;	// CYAN
	case 2:
		return eUIState_Warning; // YELLOW
	case 3:
		return eUIState_Warning2; // ORANGE
	case 4:
	default:
		return eUIState_Bad; // RED
	}
}

simulated function String GetResistanceStatusString(XComGameState_WorldRegion Region)
{
	local XGParamTag ParamTag;
	local String strSupplies;

	if( Region.ResistanceLevel == eResLevel_Locked )
	{
		return m_strResLocked;
	}
	else if (Region.ResistanceLevel == eResLevel_Unlocked)
	{
		return m_strResUnlocked;
	}
	else
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.IntValue0 = Region.GetSupplyDropReward();

		if(Region.ResistanceLevel == eResLevel_Contact)
		{
			strSupplies = `XEXPAND.ExpandString(m_strContactPlusSupplies);
		}
		else
		{
			strSupplies = `XEXPAND.ExpandString(m_strOutpostPlusSupplies);
		}
		
	}

	return strSupplies;
}

simulated function EUIState GetResistanceStatusColor(XComGameState_WorldRegion Region)
{
	if (Region.ResistanceLevel == eResLevel_Locked)
	{
		return eUIState_Disabled;
	}
	else if (Region.ResistanceLevel == eResLevel_Unlocked)
	{
		return eUIState_Normal;
	}
	else
	{
		return eUIState_Good;
	}
}

simulated function BuildRewardPanel(float fX, float fY, EUIState eLabelColor, String strLabel, String strReward)
{
	local TRect rReward, rPos;

	rReward = MakeRect(fX, fY, 400, 120);

	// "Reward" Label
	rPos = MakeRect(fX, fY, RectWidth(rReward), 30);
	AddUncenteredTitle(rPos, strLabel, eLabelColor, 25);

	// Reward Value
	rPos = MakeRect(fX, rPos.fBottom, RectWidth(rReward), RectHeight(rReward) - RectHeight(rPos));
	AddFillRect(rPos, MakeLinearColor(0, 0.5, 0, 0.5));
	AddTitle(rPos, strReward, eUIState_Cash, 25, 'Reward');
}

simulated function BuildCostPanel(TRect rCost, String strLabel, String strCost, bool bCanAfford)
{
	local UIText CostLabel;
	local TRect rPos;

	// BG
	AddBG(rCost, bCanAfford ? eUIState_Normal : eUIState_Bad, 'CostBG');

	// "Cost" Label
	CostLabel = Spawn(class'UIText', self).InitText('CostLabel', class'UIUtilities_Text'.static.GetColoredText(strLabel, bCanAfford ? eUIState_Normal : eUIState_Bad, 15), true);
	CostLabel.SetPosition(rCost.fLeft, rCost.fTop).SetSize(RectWidth(rCost), 20);
	CostLabel.SetAlpha(0.5f);

	// Fill
	AddFillRect(rCost, bCanAfford ? MakeLinearColor(0.0f, 0.5, 0.5f, 0.25f) : MakeLinearColor(0.5f, 0.0, 0, 0.25f), 'CostFill');

	// Cost Value
	rPos = PadRect(MakeRect(rCost.fLeft, rCost.fTop+20, RectWidth(rCost), RectHeight(rCost)), 5);
	AddTitle(rPos, strCost, eUIState_Normal, 30, 'Cost');
}

simulated function BuildReqPanel(TRect rReq, String strLabel, String strReq, bool bMeetsReq)
{
	local UIText RequiredLabel;
	local TRect rPos;

	// BG
	AddBG(rReq, bMeetsReq ? eUIState_Normal : eUIState_Bad, 'ReqBG');

	// "Required" Label
	RequiredLabel = Spawn(class'UIText', self).InitText('ReqLabel', class'UIUtilities_Text'.static.GetColoredText(strLabel, bMeetsReq ? eUIState_Normal : eUIState_Bad, 20), true);
	RequiredLabel.SetPosition(rReq.fLeft, rReq.fTop).SetSize(RectWidth(rReq), 25);
	RequiredLabel.SetAlpha(0.5f);

	// Fill
	AddFillRect(rReq, bMeetsReq ? MakeLinearColor(0.0f, 0.5, 0.5f, 0.25f) : MakeLinearColor(0.5f, 0.0, 0, 0.25f), 'ReqFill');

	// Required Value
	rPos = PadRect(MakeRect(rReq.fLeft, rReq.fTop, RectWidth(rReq), RectHeight(rReq)), 5);
	AddTitle(rPos, strReq, bMeetsReq ? eUIState_Normal : eUIState_Bad, 25, 'Req');
}

simulated function BuildDurationPanel(TRect rTime, String strLabel, String strTime, EUIState eColor)
{
	local UIText TimeLabel;
	local TRect rPos;

	// BG
	AddBG(rTime, eUIState_Warning, 'TimeBG');

	// "ETA" Label
	TimeLabel = Spawn(class'UIText', self).InitText('TimeLabel', class'UIUtilities_Text'.static.GetColoredText(strLabel, eUIState_Warning, 20), true);
	TimeLabel.SetPosition(rTime.fLeft, rTime.fTop).SetSize(RectWidth(rTime), 25).SetAlpha(0.5f);

	// Fill
	//AddFillRect(rCost, bCanAfford ? MakeLinearColor(0.0f, 0.5, 0.5f, 0.25f) : MakeLinearColor(0.5f, 0.0, 0, 0.25f), 'CostFill');

	// Time Value
	rPos = PadRect(MakeRect(rTime.fLeft, rTime.fTop, RectWidth(rTime), RectHeight(rTime)), 5);
	AddTitle(rPos, strTime, eColor, 25, 'Time');
}

simulated function UpdateRewardPanel(String strReward)
{
	UpdateTitle('Reward', strReward, eUIState_Cash, 25);
}

simulated function UpdateDarkEventPanel(String strDarkEvent, String strSummary)
{
	UpdateTitle('AlienOperation', strDarkEvent, eUIState_Bad, 25);
	UpdateTitle('AlienOperationText', strSummary, eUIState_Bad, 20);
}

simulated function UpdateCostPanel(String strCost, bool bCanAfford)
{
	local UIText txtLabel;

	txtLabel = UIText(GetChildByName('CostLabel'));
	txtLabel.SetText(class'UIUtilities_Text'.static.GetColoredText(txtLabel.Text, bCanAfford ? eUIState_Normal : eUIState_Bad, 15));
	UpdateBG('CostBG', bCanAfford ? eUIState_Normal : eUIState_Bad);
	UpdateFillRect('CostFill', bCanAfford ? MakeLinearColor(0.0f, 0.5, 0.5f, 0.25f) : MakeLinearColor(0.5f, 0.0, 0, 0.25f));
	UpdateTitle('Cost', strCost, eUIState_Normal, 30);
}

simulated function UpdateReqPanel(String strReq, bool bMeetsReq)
{
	local UIText txtLabel;

	txtLabel = UIText(GetChildByName('ReqLabel'));
	txtLabel.SetText(class'UIUtilities_Text'.static.GetColoredText(txtLabel.Text, bMeetsReq ? eUIState_Normal : eUIState_Bad, 20));
	UpdateBG('ReqBG', bMeetsReq ? eUIState_Normal : eUIState_Bad);
	UpdateFillRect('ReqFill', bMeetsReq ? MakeLinearColor(0.0f, 0.5, 0.5f, 0.25f) : MakeLinearColor(0.5f, 0.0, 0, 0.25f));
	UpdateTitle('Req', strReq, eUIState_Normal, 25);
}

simulated function UpdateDurationPanel(String strTime, EUIState eColor)
{
	local UIText txtLabel;

	txtLabel = UIText(GetChildByName('TimeLabel'));
	txtLabel.SetText(class'UIUtilities_Text'.static.GetColoredText(txtLabel.Text, eUIState_Warning, 20));
	txtLabel.SetAlpha(0.5f);
	//UpdateBG('ReqBG', bMeetsReq ? eUIState_Normal : eUIState_Bad);
	//UpdateFillRect('CostFill', bCanAfford ? MakeLinearColor(0.0f, 0.5, 0.5f, 0.25f) : MakeLinearColor(0.5f, 0.0, 0, 0.25f));
	UpdateTitle('Time', strTime, eColor, 25);
}

simulated function RemoveCostPanel()
{
	GetChildByName('CostLabel').Remove();
	GetChildByName('CostLabel').Destroy();
	GetChildByName('CostBG').Remove();
	GetChildByName('CostBG').Destroy();
	GetChildByName('CostFill').Remove();
	GetChildByName('CostFill').Destroy();
	GetChildByName('Cost').Remove();
	GetChildByName('Cost').Destroy();
}

simulated function HideCostPanel()
{
	GetChildByName('CostLabel').Hide();
	GetChildByName('CostBG').Hide();
	GetChildByName('CostFill').Hide();
	GetChildByName('Cost').Hide();
}

simulated function ShowCostPanel()
{
	GetChildByName('CostLabel').Show();
	GetChildByName('CostBG').Show();
	GetChildByName('CostFill').Show();
	GetChildByName('Cost').Show();
}

simulated function HideReqPanel()
{
	GetChildByName('ReqLabel').Hide();
	GetChildByName('ReqBG').Hide();
	GetChildByName('Req').Hide();
	GetChildByName('ReqFill').Hide();
}
simulated function ShowReqPanel()
{
	GetChildByName('ReqLabel').Show();
	GetChildByName('ReqBG').Show();
	GetChildByName('Req').Show();
	GetChildByName('ReqFill').Show();
}
simulated function HideDurationPanel()
{
	GetChildByName('TimeLabel').Hide();
	GetChildByName('TimeBG').Hide();
	GetChildByName('Time').Hide();
	//GetChildByName('ReqFill').Hide();
}
simulated function ShowDurationPanel()
{
	GetChildByName('TimeLabel').Show();
	GetChildByName('TimeBG').Show();
	GetChildByName('Time').Show();
	//GetChildByName('ReqFill').Hide();
}

simulated function XComGameState_HeadquartersXCom XCOMHQ()
{
	return class'UIUtilities_Strategy'.static.GetXComHQ();
}

simulated function XComGameState_HeadquartersResistance RESHQ()
{
	return class'UIUtilities_Strategy'.static.GetResistanceHQ();
}

simulated function XComGameState_HeadquartersAlien ALIENHQ()
{
	return class'UIUtilities_Strategy'.static.GetAlienHQ();
}

simulated function XComGameState_BlackMarket BLACKMARKET()
{
	return class'UIUtilities_Strategy'.static.GetBlackMarket();
}

simulated function PlaySFX(String Sound)
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent(Sound);
}

simulated function XComHQPresentationLayer HQPRES()
{
	return XComHQPresentationLayer(Movie.Pres);
}
