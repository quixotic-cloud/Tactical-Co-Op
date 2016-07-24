
class UISimpleListItem extends UIPanel;

var UIBGBox m_BG;
var string	m_strItemCost;
var string	m_strItemReq;
var string	m_strItemTitle;
var bool	m_bCanAfford;
var bool	m_bMeetsReqs;
var bool	m_bIsPurchased;

var public localized String m_strCostLabel;
var public localized String m_strReqLabel;
var public localized String m_strPurchasedLabel;

simulated function InitListItem(String strText, int iWidth, int iHeight, String strCost, String reqCost, bool bMeetsReqs, bool bCanAfford, bool bIsPurchased)
{
	local UIText kText, kCost;

	m_strItemCost = strCost;
	m_strItemReq = reqCost;
	m_strItemTitle = strText;
	m_bCanAfford = bCanAfford;
	m_bMeetsReqs = bMeetsReqs;
	m_bIsPurchased = bIsPurchased;

	InitPanel(); // must do this before adding children or setting data

	m_BG = Spawn(class'UIBGBox', self);
	m_BG.InitBG('', 0, 0, iWidth, iHeight);

	if (IsPurchased())
		m_BG.SetBGColorState(eUIState_Normal);
	else
	{
		if (MeetsReqs())
		{
			if (CanAfford())
				m_BG.SetBGColorState(eUIState_Normal);
			else
				m_BG.SetBGColorState(eUIState_Disabled);
		}
		else
			m_BG.SetBGColorState(eUIState_Disabled);
	}

	m_BG.bHighlightOnMouseEvent = true;
	m_BG.ProcessMouseEvents(OnMouseEventDelegate); // BG processes all our Mouse Events

	kText = Spawn(class'UIText', self);
	kText.InitText('', GetTextString());
	kText.SetPosition(10, 5);

	if (IsPurchased())
	{
		kCost = Spawn(class'UIText', self);
		kCost.InitText('', GetPurchasedString());
		kCost.SetPosition(20, 25);
	}
	else
	{
		// If requirements are met and a cost exists, display the cost string
		if (MeetsReqs() && HasCost())
		{
			kCost = Spawn(class'UIText', self);
			kCost.InitText('', GetCostString());
			kCost.SetPosition(20, 25);
		}
		else // Otherwise show the requirements
		{
			kCost = Spawn(class'UIText', self);
			kCost.InitText('', GetReqString());
			kCost.SetPosition(20, 25);
		}
	}
}

simulated function bool IsPurchased()
{
	return m_bIsPurchased;
}

simulated function bool HasCost()
{
	return m_strItemCost != "";
}

simulated function bool CanAfford()
{
	return !HasCost() || m_bCanAfford;
}

simulated function bool HasReqs()
{
	return m_strItemReq != "";
}

simulated function bool MeetsReqs()
{
	return !HasReqs() || m_bMeetsReqs;
}

simulated function String GetTextString()
{
	local String strText;

	strText = m_strItemTitle;

	if (!MeetsReqs())
	{
		strText = class'UIUtilities_Text'.static.GetColoredText(strText, eUIState_Disabled);
	}
	else if(!CanAfford())
	{
		strText = class'UIUtilities_Text'.static.GetColoredText(strText, eUIState_Bad);
	}

	return strText;
}

simulated function String GetPurchasedString()
{
	return class'UIUtilities_Text'.static.GetColoredText(m_strPurchasedLabel, eUIState_Good);
}

simulated function String GetCostString()
{
	local String strCost;

	if (!HasCost())
	{
		return "";
	}

	strCost = m_strCostLabel @ m_strItemCost;

	if( !CanAfford() )
	{
		strCost = class'UIUtilities_Text'.static.GetColoredText(strCost, eUIState_Bad);
	}

	return strCost;
}

simulated function String GetReqString()
{
	local String strReq;

	if (!HasReqs())
	{
		return "";
	}
		
	strReq = m_strReqLabel @ m_strItemReq;

	if (!MeetsReqs())
	{
		strReq = class'UIUtilities_Text'.static.GetColoredText(strReq, eUIState_Disabled);
	}

	return strReq;
}

// all mouse events get processed by bg
simulated function UIPanel ProcessMouseEvents(optional delegate<onMouseEventDelegate> mouseEventDelegate)
{
	onMouseEventDelegate = mouseEventDelegate;
	return self;
}

simulated function OnReceiveFocus()
{
	m_BG.SetHighlighed(true);
	super.OnReceiveFocus();
}

simulated function OnLoseFocus()
{
	m_BG.SetHighlighed(false);
	super.OnLoseFocus();
}


defaultproperties
{
	width = 375;
	height = 50;
	bProcessesMouseEvents = true;
}