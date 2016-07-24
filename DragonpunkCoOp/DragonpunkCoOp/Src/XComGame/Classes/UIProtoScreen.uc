class UIProtoScreen extends UIScreen;

enum ERectAnchor
{
	eRectAnchor_TopLeft,
	eRectAnchor_TopCenter,
	eRectAnchor_TopRight,
	eRectAnchor_CenterLeft,
	eRectAnchor_Center,
	eRectAnchor_CenterRight,
	eRectAnchor_BottomLeft,
	eRectAnchor_BottomCenter,
	eRectAnchor_BottomRight,
};


delegate OnClickedDelegate(UIButton Button);

//-------------- HELPER FUNCS --------------------------------------------------------
simulated function UIBGBox AddBG(TRect rPos, EUIState eUIStateColor, optional name InitName, optional UIPanel Parent)
{
	local UIBGBox BGBox;

	BGBox = Spawn(class'UIBGBox', (Parent != none ? Parent : self)).InitBG(InitName, rPos.fLeft, rPos.fTop, RectWidth(rPos), RectHeight(rPos));
	BGBox.SetBGColorState(eUIStateColor);

	return BGBox;
}

simulated function UIPanel AddFillRect(TRect rPos, LinearColor clrPanel, optional name InitName, optional UIPanel Parent)
{
	local UIPanel Panel;

	Panel = Spawn(class'UIPanel', (Parent != none ? Parent : self)).InitPanel(InitName, class'UIUtilities_Controls'.const.MC_GenericPixel);
	Panel.SetPosition(rPos.fLeft, rPos.fTop).SetSize(RectWidth(rPos), RectHeight(rPos));
	Panel.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(clrPanel));
	Panel.SetAlpha(clrPanel.A);

	return Panel;
}

simulated function UIX2PanelHeader AddHeader(TRect rPos, String strTitle, LinearColor clrHeader, optional String strLabel, optional name InitName, optional UIPanel Parent)
{
	local UIX2PanelHeader Header;
	Header = Spawn(class'UIX2PanelHeader', Parent);
	Header.InitPanelHeader(InitName);
	Header.SetText(strTitle, strLabel);
	Header.SetHeaderWidth(RectWidth(rPos));
	Header.SetPosition(rPos.fLeft, rPos.fTop);
	Header.SetColor(class'UIUtilities_Colors'.static.LinearColorToFlashHex(clrHeader));
	Header.SetAlpha(clrHeader.A);

	return Header;
}

simulated function UIImage AddImage(TRect rPos, String ImagePath, optional name InitName, optional UIPanel Parent)
{
	local UIImage Image;

	Image = Spawn(class'UIImage', (Parent != none ? Parent : self)).InitImage(InitName, ImagePath);
	Image.SetPosition(rPos.fLeft, rPos.fTop).SetSize(RectWidth(rPos), RectHeight(rPos));

	return Image;
}

simulated function UIText AddText(TRect rPos, String strText, optional name InitName, optional UIPanel Parent)
{
	local UIText TextWidget;

	TextWidget = Spawn(class'UIText', (Parent != none ? Parent : self)).InitText(InitName, class'UIUtilities_Text'.static.GetColoredText(strText, eUIState_Normal, 25));
	TextWidget.SetPosition(rPos.fLeft, rPos.fTop).SetSize(RectWidth(rPos), RectHeight(rPos));
	TextWidget.SetHtmlText(class'UIUtilities_Text'.static.AlignCenter(TextWidget.Text));

	return TextWidget;
}

simulated function UIText AddTitle(TRect rPos, String strText, EUIState ColorState, int FontSize, optional name InitName, optional UIPanel Parent)
{
	local UIText TextWidget;

	TextWidget = Spawn(class'UIText', (Parent != none ? Parent : self)).InitText(InitName, class'UIUtilities_Text'.static.GetColoredText(strText, ColorState, FontSize), true);
	TextWidget.SetPosition(rPos.fLeft, rPos.fTop).SetSize(RectWidth(rPos), RectHeight(rPos));
	TextWidget.SetHtmlText(class'UIUtilities_Text'.static.AlignCenter(TextWidget.Text));

	return TextWidget;
}

simulated function UIButton AddButton(TRect rPos, String strText, delegate<OnClickedDelegate> OnClicked, optional name InitName, optional UIPanel Parent)
{
	local UIButton Button;

	Button = Spawn(class'UIButton', (Parent != none ? Parent : self)).InitButton(InitName, class'UIUtilities_Text'.static.GetColoredText(strText, eUIState_Normal, 25), OnClicked, eUIButtonStyle_HOTLINK_BUTTON);
	rPos = HSubRect(rPos, 0.25f, 0.75f);
	Button.SetPosition(rPos.fLeft, rPos.fTop);

	return Button;
}

simulated function AddLineBreak(out String BodyString)
{
	BodyString $= "\n";
}

simulated function AddLine(out String BodyString, String AddString)
{
	BodyString $= AddString;
	BodyString $= "\n";
}

simulated function TRect MakeRect(float fLeft, float fTop, float fWidth, float fHeight)
{
	local TRect Rect;

	Rect.fLeft = fLeft;
	Rect.fTop = fTop;
	Rect.fRight = fLeft + fWidth;
	Rect.fBottom = fTop + fHeight;

	return Rect;
}

simulated function TRect PadRect(TRect InRect, float fPadding)
{
	local TRect Rect;

	Rect.fLeft = InRect.fLeft + fPadding;
	Rect.fTop = InRect.fTop + fPadding;
	Rect.fRight = InRect.fRight - fPadding;
	Rect.fBottom = InRect.fBottom - fPadding;

	return Rect;
}

simulated function TRect HSubRect(TRect InRect, float fPercentLeft, float fPercentRight)
{
	local TRect Rect;

	Rect.fTop = InRect.fTop;
	Rect.fBottom = InRect.fBottom;

	Rect.fLeft = InRect.fLeft + RectWidth(InRect) * fPercentLeft;
	Rect.fRight = InRect.fLeft + RectWidth(InRect) * fPercentRight;

	return Rect;
}

simulated function TRect VSubRect(TRect InRect, float fPercentTop, float fPercentBottom)
{
	local TRect Rect;

	Rect.fLeft = InRect.fLeft;
	Rect.fRight = InRect.fRight;

	Rect.fTop = InRect.fTop + RectHeight(InRect) * fPercentTop;
	Rect.fBottom = InRect.fTop + RectHeight(InRect) * fPercentBottom;

	return Rect;
}

simulated function TRect AnchorRect(TRect InRect, ERectAnchor eAnchor, optional int Padding)
{
	local TRect Rect;

	Rect = InRect;

	switch(eAnchor)
	{
	case eRectAnchor_CenterLeft:
	case eRectAnchor_TopLeft:
	case eRectAnchor_BottomLeft:
		Rect.fLeft = 0 + Padding;
		break;
	case eRectAnchor_Center:
	case eRectAnchor_TopCenter:
	case eRectAnchor_BottomCenter:
		Rect.fLeft = 1920 / 2 - RectWidth(InRect) / 2;
		break;
	case eRectAnchor_CenterRight:
	case eRectAnchor_TopRight:
	case eRectAnchor_BottomRight:
		Rect.fLeft = 1920 - (RectWidth(InRect) + Padding);
		break;
	}

	Rect.fRight = Rect.fLeft + RectWidth(InRect);

	switch(eAnchor)
	{
	case eRectAnchor_TopLeft:
	case eRectAnchor_TopCenter:
	case eRectAnchor_TopRight:
		Rect.fTop = 0 + Padding;
		break;
	case eRectAnchor_CenterLeft:
	case eRectAnchor_Center:
	case eRectAnchor_CenterRight:
		Rect.fTop = 1080 / 2 - RectHeight(InRect) / 2;
		break;
	case eRectAnchor_BottomLeft:
	case eRectAnchor_BottomCenter:
	case eRectAnchor_BottomRight:
		Rect.fTop = 1080 - (RectHeight(InRect) + Padding);
		break;
	}

	Rect.fBottom = Rect.fTop + RectHeight(InRect);

	return Rect;
}

simulated function float RectWidth(TRect Rect, optional float fPercent = 1.0f)
{
	return (Rect.fRight - Rect.fLeft) * fPercent;
}

simulated function float RectHeight(TRect Rect, optional float fPercent = 1.0f)
{
	return (Rect.fBottom - Rect.fTop) * fPercent;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	bHandled = true;

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		//TODO: Selection + Confirmation 
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		CloseScreen();
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled;
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
}
