class UIServerBrowser_HeaderButton 
	extends UIButton
	dependson (UIMPShell_ServerBrowser);

var string ID;
var EServerBrowserSortType SortType;
var UIButton  m_kButton;

simulated function InitHeaderButton(string initID, EServerBrowserSortType initSortType, string initLabel)
{
	ID = initID;
	SortType = initSortType;
	
	//All these buttons are unique but share the same class in flash
	LibID = name(ID $ "Button");
	super.InitButton(name(ID $ "Button"));
	
	SetLabel( initLabel );

	// set arrow visibility if we're the default selection
	if(IsSelected())
		Select();
	else
		Deselect();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i;
	local array<UIPanel> arrHeaderButtons;

	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		// deselect all other buttons
		screen.GetChildrenOfType(class'UIServerBrowser_HeaderButton', arrHeaderButtons);

		for(i = 0; i < arrHeaderButtons.Length; ++i)
		{
			if(arrHeaderButtons[i] != self)
				UIServerBrowser_HeaderButton(arrHeaderButtons[i]).Deselect();
		}

		// if we were previously selected, flip the sort
		if(IsSelected())
		{
			UIMPShell_ServerBrowser(screen).m_bFlipSort = !UIMPShell_ServerBrowser(screen).m_bFlipSort;
			SetArrow( UIMPShell_ServerBrowser(screen).m_bFlipSort );
		}
		else
			Select();

		UIMPShell_ServerBrowser(screen).UpdateData();
	}
	else
		super.OnMouseEvent(cmd, args);
}

simulated function Select()
{
	OnReceiveFocus();

	// if we were previously NOT selected, reset the sort flip
	UIMPShell_ServerBrowser(screen).m_bFlipSort = class'UIMPShell_ServerBrowser'.default.m_bFlipSort;
	UIMPShell_ServerBrowser(screen).m_eSortType = SortType;

	mc.FunctionBool("setArrowVisible", true);
	SetArrow( UIMPShell_ServerBrowser(screen).m_bFlipSort );
}

simulated function Deselect()
{
	OnLoseFocus();
	mc.FunctionBool("setArrowVisible", false);
}

simulated function SetLabel(string theLabel)
{
	mc.FunctionString("setLabel", theLabel);
}

simulated function SetArrow(bool flipArrow)
{
	mc.FunctionBool("setArrow", flipArrow);
}

simulated function bool IsSelected()
{
	return UIMPShell_ServerBrowser(screen).m_eSortType == SortType;
}

defaultproperties
{
	//mouse events are processed by the button's bg in flash
	bProcessesMouseEvents = false;
}