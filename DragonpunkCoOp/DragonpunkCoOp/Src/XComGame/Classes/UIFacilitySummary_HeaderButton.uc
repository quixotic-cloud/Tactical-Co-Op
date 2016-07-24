
class UIFacilitySummary_HeaderButton 
	extends UIButton
	dependson (UIFacilitySummary);

var string ID;
var EFacilitySortType SortType;
var UIButton  m_kButton;

var localized string m_strButtonLabels[EFacilitySortType.EnumCount]<BoundEnum=EFacilitySortType>;

simulated function InitHeaderButton(string initID, EFacilitySortType initSortType)
{
	ID = initID;
	SortType = initSortType;
	
	//All these buttons are unique but share the same class in flash
	LibID = name(ID $ "Button");
	super.InitButton(name(ID $ "Button"));
	
	//mc.ChildSetString("_parent." $ ID $ "Label.theText", "htmlText", m_strButtonLabels[int(sortType)]);
	SetLabel( m_strButtonLabels[int(sortType)] );

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
		screen.GetChildrenOfType(class'UIFacilitySummary_HeaderButton', arrHeaderButtons);

		for(i = 0; i < arrHeaderButtons.Length; ++i)
		{
			if(arrHeaderButtons[i] != self)
				UIFacilitySummary_HeaderButton(arrHeaderButtons[i]).Deselect();
		}

		// if we were previously selected, flip the sort
		if(IsSelected())
		{
			UIFacilitySummary(screen).m_bFlipSort = !UIFacilitySummary(screen).m_bFlipSort;
			//mc.ChildFunctionString("_parent." $ ID $ "Arrow", "gotoAndStop", UIFacilitySummary(screen).m_bFlipSort ? "up" : "down");
			SetArrow( UIFacilitySummary(screen).m_bFlipSort );
		}
		else
			Select();

		UIFacilitySummary(screen).UpdateData();
	}
	else
		super.OnMouseEvent(cmd, args);
}

simulated function Select()
{
	OnReceiveFocus();

	// if we were previously NOT selected, reset the sort flip
	UIFacilitySummary(screen).m_bFlipSort = class'UIFacilitySummary'.default.m_bFlipSort;
	UIFacilitySummary(screen).m_eSortType = SortType;

	//mc.ChildSetBool("_parent." $ ID $ "Arrow", "_visible", true);
	//mc.ChildFunctionString("_parent." $ ID $ "Arrow", "gotoAndStop", UIFacilitySummary(screen).m_bFlipSort ? "up" : "down");
	mc.FunctionBool("setArrowVisible", true);
	SetArrow( UIFacilitySummary(screen).m_bFlipSort );
}

simulated function Deselect()
{
	OnLoseFocus();
	//mc.ChildSetBool("_parent." $ ID $ "Arrow", "_visible", false);
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
	return UIFacilitySummary(screen).m_eSortType == SortType;
}

defaultproperties
{
	//mouse events are processed by the button's bg in flash
	bProcessesMouseEvents = false;
}