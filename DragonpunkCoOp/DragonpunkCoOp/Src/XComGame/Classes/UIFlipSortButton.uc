
class UIFlipSortButton
	extends UIButton
	dependson (UIPersonnel);

var string ID;
var int SortType;
var string Label;
var string Value;
var bool bArrowVisible;
var bool bArrowFlipped;
var UIButton Button;
var IUISortableScreen SortingScreen; 

simulated function InitFlipSortButton(string InitID, int InitSortType, optional string InitLabel, optional string InitValue)
{
	ID = InitID;
	SortType = InitSortType;

	//All these buttons are unique but share the same class in flash
	LibID = name(ID $ "Button");
	super.InitButton(name(ID $ "Button"));

	//After the init 
	SortingScreen = IUISortableScreen(screen);
	if( SortingScreen == none )
	{
		`Redscreen("UI Screen Error", "A flip sort button tried to access a non-sorting parent screen.");
		return;
	}

	SetLabel(InitLabel);
	SetValue(InitValue);

	// set arrow visibility if we're the default selection
	RealizeSortOrder();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int i;
	local array<UIPanel> arrHeaderButtons;

	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		// deselect all other buttons
		screen.GetChildrenOfType(class'UIFlipSortButton', arrHeaderButtons);

		for(i = 0; i < arrHeaderButtons.Length; ++i)
		{
			if(arrHeaderButtons[i] != self)
				UIFlipSortButton(arrHeaderButtons[i]).Deselect();
		}

		// if we were previously selected, flip the sort
		if(IsSelected())
		{
			SortingScreen.SetFlipSort(!SortingScreen.GetFlipSort());
			SetArrow(SortingScreen.GetFlipSort());
		}
		else
			Select();

		SortingScreen.RefreshData();
	}
	else
		super.OnMouseEvent(cmd, args);
}

simulated function Select()
{
	if(!bArrowVisible)
	{
		bArrowVisible = true;
		MC.FunctionBool("setArrowVisible", true);

		// if we were previously NOT selected, reset the sort flip
		SortingScreen.SetFlipSort(false);
		SortingScreen.SetSortType(SortType);

		SetArrow(SortingScreen.GetFlipSort());
		OnReceiveFocus();
	}
	
}

simulated function Deselect()
{
	if(bArrowVisible)
	{
		bArrowVisible = false;
		MC.FunctionBool("setArrowVisible", false);
		OnLoseFocus();
	}
}

simulated function SetLabel(string NewLabel)
{
	if(Label != NewLabel)
	{
		Label = NewLabel;
		MC.FunctionString("setLabel", Label);
	}
}

simulated function SetValue(string NewValue)
{
	if(Value != NewValue)
	{
		Value = NewValue;
		MC.FunctionString("setValue", Value);
	}
}

simulated function SetArrow(bool flipArrow)
{
	if(bArrowFlipped != flipArrow)
	{
		bArrowFlipped = flipArrow;
		MC.FunctionBool("setArrow", bArrowFlipped);
	}
}

simulated function bool IsSelected()
{
	return SortingScreen.GetSortType() == SortType;
}

simulated function RealizeSortOrder()
{
	// set arrow visibility if we're the default selection
	if(IsSelected())
		Select();
	else
		Deselect();
}

defaultproperties
{
	//mouse events are processed by the button's bg in flash
	bProcessesMouseEvents = false;
	bArrowFlipped = true;
	bArrowVisible = true;
}