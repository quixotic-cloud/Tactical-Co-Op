//---------------------------------------------------------------------------------------
//  FILE:    UIMechaListItem.uc
//  AUTHOR:  Brit Steiner --  7/8/2015
//  PURPOSE: A list item can contain a variety of sub controls, and will format 
//			 automatically based on what control is defined. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIMechaListItem extends UIPanel;

var public int    metadataInt;    // int variable for gameplay use
var public string metadataString; // string variable for gameplay use
var public Object metadataObject;

enum EUILineItemType
{
	// THIS MUST BE SYNCHROMIZED WITH FLASH. 
	EUILineItemType_Description, //Basic line item, with only a description label and no widgets. 
	EUILineItemType_ColorChip,
	EUILineItemType_Spinner,
	EUILineItemType_Dropdown,
	EUILineItemType_Slider,
	EUILineItemType_Checkbox,
	EUILineItemType_Button,
	EUILineItemType_Value,
	EUILineItemType_SpinnerAndButton
};

var UIScrollingText Desc;
var UIPanel BG;
var bool bDisabled;
var bool bIsBad;

var UIText Value;
var UIBGBox ColorChip;
var UIListItemSpinner Spinner;
var UIDropdown Dropdown;
var UIButton Button;
var UICheckbox Checkbox;
var UISlider Slider;

var EUILineItemType Type; 

delegate OnClickDelegate();
delegate OnSpinnerChangedCallback(UIListItemSpinner SpinnerControl, int Direction);
delegate OnButtonClickedCallback(UIButton ButtonSource);
delegate OnDropdownSelectionChangedCallback(UIDropdown DropdownControl);
delegate OnSliderChangedCallback(UISlider SliderControl);
delegate OnCheckboxChangedCallback(UICheckbox CheckboxControl);

simulated function UIMechaListItem InitListItem()
{
	local UIList List; 	

	Type = -1; //Initialize.

	InitPanel(); // must do this before adding children or setting data

	List = UIList(GetParent(class'UIList'));
	if(List != none && List.Width > 0)
		Width = List.Width; 

	BG = Spawn(class'UIPanel', self);
	BG.bAnimateOnInit = false;
	BG.bIsNavigable = false;
	BG.InitPanel('mechaBG');
	BG.SetWidth(width);

	Desc = Spawn(class'UIScrollingText', self);
	Desc.bIsNavigable = false;
	Desc.bAnimateOnInit = bAnimateOnInit;
	Desc.InitScrollingText('DescTextControl',,250,5);

	Spinner = Spawn(class'UIListItemSpinner', self);
	Spinner.bIsNavigable = false;
	Spinner.MCName = 'SpinnerMC';
	Spinner.InitSpinner("", "", OnSpinnerChangeDelegate);
	Spinner.Navigator.HorizontalNavigation = true;
	Spinner.SetX(width - 330);
	Spinner.SetValueWidth(250, true);
	Spinner.Hide();

	return self;
}

// NOTE: Type should be set before additional data on child widgets  is set.
simulated function SetWidgetType(EUILineItemType NewType)
{
	if( Type != NewType )
	{
		Type = NewType;
		MC.BeginFunctionOp("SetType");
		MC.QueueNumber(Type);
		MC.QueueBoolean(Screen.bIsIn3D);
		MC.EndOp();
	}

	// Hide all subcomponents, they'll be shown when data is updated if necessary
	if(Desc != None) Desc.Hide();
	if(Value != None) Value.Hide();
	if(ColorChip != None) ColorChip.Hide();
	if(Spinner != None) Spinner.Hide();
	if(Dropdown != None) Dropdown.Hide();
	if(Button != None) Button.Hide();
	if(Checkbox != None) Checkbox.Hide();
	if(Slider != None) Slider.Hide();

	Show();
}

// -----------------------------------------------------------------

simulated function UpdateDataSlider(string _Desc,
									 String _SliderLabel,
									 optional int _SliderPosition,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none,
									 optional delegate<OnSliderChangedCallback> _OnSliderChangedDelegate = none)
{
	SetWidgetType(EUILineItemType_Slider);

	if( Slider == none )
	{
		Slider = Spawn(class'UISlider', self);
		Slider.bIsNavigable = false;
		Slider.bAnimateOnInit = false;
		Slider.InitSlider('SliderMC');
		Slider.Navigator.HorizontalNavigation = true;
		//Slider.SetPosition(width - 420, 0);
		Slider.SetX(width - 418);
	}

	Slider.SetPercent(_SliderPosition);
	Slider.SetText(_SliderLabel);
	Slider.Show();

	Desc.SetWidth(width - 418);

	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	OnSliderChangedCallback = _OnSliderChangedDelegate;
	Slider.onChangedDelegate = _OnSliderChangedDelegate;
}

simulated function bool HandleCustomControls(int cmd, int arg)
{
	if (Spinner != none && Spinner.bIsVisible)
	{
		return Spinner.OnUnrealCommand(cmd, arg);
	}

	if (Dropdown != none && Dropdown.bIsVisible)
	{
		return Dropdown.OnUnrealCommand(cmd, arg);
	}

	if (Button != none && Button.bIsVisible)
	{
		return Button.OnUnrealCommand(cmd, arg);
	}

	if (Checkbox != none && Checkbox.bIsVisible)
	{
		return Checkbox.OnUnrealCommand(cmd, arg);
	}

	if (Slider != none && Slider.bIsVisible)
	{
		return Slider.OnUnrealCommand(cmd, arg);
	}

	return false;
}

simulated function bool HandleClickableControls(int cmd, int arg)
{
	if ( ((Desc != none && Desc.bIsVisible) || (ColorChip != none && ColorChip.bIsVisible) || (Value != none && Value.bIsVisible)) && 
		(cmd == class'UIUtilities_Input'.const.FXS_KEY_ENTER || cmd == class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR || cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A))
	{
		Click();
		return true;
	}

	return false;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if (!bDisabled)
	{
		if (HandleCustomControls(cmd, arg))
			return true;

		if (HandleClickableControls(cmd, arg))
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function UIMechaListItem UpdateDataDescription(string _Desc,
										  optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_Description);
	Desc.SetHTMLText(_Desc);
	Desc.Show();
	Desc.SetWidth(Width - 10);
	OnClickDelegate = _OnClickDelegate;
	return self;
}

simulated function UIMechaListItem UpdateDataValue(string _Desc,
								    String _ValueLabel,
								    optional delegate<OnClickDelegate> _OnClickDelegate = none,
									optional bool bForce = false)
{
	SetWidgetType(EUILineItemType_Value);

	if( Value == none )
	{
		Value = Spawn(class'UIText', self);
		Value.bAnimateOnInit = false;
		Value.bIsNavigable = false;
		Value.InitText('ValueTextControl');
		Value.SetWidth(width - 20);
		//Value.SetPosition(10, 0);
		Value.SetX(10);
	}
		
	Value.SetHTMLText(class'UIUtilities_Text'.static.AlignRight(_ValueLabel), , bForce);
	Value.Show();

	Desc.SetHTMLText(_Desc, bForce);
	Desc.Show();
	
	OnClickDelegate = _OnClickDelegate;
	return self;
}

simulated function UIMechaListItem UpdateDataColorChip(string _Desc,
										String _HTMLColorChip,
										optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_ColorChip);

	if( ColorChip == none )
	{
		ColorChip = Spawn(class'UIBGBox', self);
		ColorChip.bAnimateOnInit = false;
		ColorChip.bIsNavigable = false;
		ColorChip.InitBG('ColorChipMC');
		ColorChip.SetSize(165, 20);
		ColorChip.SetPosition(width - 170, 7);
		//ColorChip.SetX(width - 170);
	}

	// HAX: Don't show a pure black color since that is an indicator that the weapon color is set to -1 (default)
	if(_HTMLColorChip != "0x00000000")
	{
		ColorChip.SetColor(_HTMLColorChip);
		ColorChip.Show();
	}
	else
		ColorChip.Hide();

	Desc.SetWidth(width - 170);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	return self;
}

simulated function UIMechaListItem UpdateDataButton(string _Desc,
								 	 string _ButtonLabel,
								 	 delegate<OnButtonClickedCallback> _OnButtonClicked = none,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_Button);

	if( Button == none )
	{
		Button = Spawn(class'UIButton', self);
		Button.bAnimateOnInit = false;
		Button.bIsNavigable = false;
		Button.InitButton('ButtonMC', "", OnButtonClickDelegate);
		Button.SetX(width - 150);
		Button.SetHeight( 34 );
		Button.MC.SetNum("textY", 2);
	}

	Button.SetText(_ButtonLabel);
	RefreshButtonVisibility();

	Desc.SetWidth(width - 150);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	OnButtonClickedCallback = _OnButtonClicked;
	return self;
}

simulated function UIMechaListItem UpdateDataSpinner(string _Desc,
									 String _SpinnerLabel,
									 delegate<OnSpinnerChangedCallback> _OnSpinnerChange = none,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_Spinner);

	if( Spinner == none )
	{
		Spinner = Spawn(class'UIListItemSpinner', self);
		Spinner.bAnimateOnInit = false;
		Spinner.bIsNavigable = false;
		Spinner.MCName = 'SpinnerMC';
		Spinner.InitSpinner("", _SpinnerLabel, OnSpinnerChangeDelegate);
		Spinner.Navigator.HorizontalNavigation = true;
		Spinner.SetX(width - 330);
		Spinner.SetValueWidth(250, true);
	}

	Spinner.SetValue(_SpinnerLabel);
	Spinner.Show();

	Desc.SetWidth(width - 330);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	OnSpinnerChangedCallback = _OnSpinnerChange;
	return self;
}

simulated function UIMechaListItem UpdateDataSpinnerAndButton(string _Desc,
									 string _SpinnerLabel,
									 string _ButtonLabel,
									 delegate<OnSpinnerChangedCallback> _OnSpinnerChange,
									 delegate<OnButtonClickedCallback> _OnButtonClicked,
									 optional delegate<OnClickDelegate> _OnClickDelegate = none)
{

	SetWidgetType(EUILineItemType_SpinnerAndButton);

	if( Button == none )
	{
		Button = Spawn(class'UIButton', self);
		Button.bAnimateOnInit = false;
		Button.bIsNavigable = false;
		Button.LibID = 'X2ClearButton';
		Button.InitButton('ClearButtonMC', _ButtonLabel, OnButtonClickDelegate);
		Button.SetPosition(width - 205, 2);
	}

	if( Spinner == none )
	{
		Spinner = Spawn(class'UIListItemSpinner', self);
		Spinner.bAnimateOnInit = false;
		Spinner.bIsNavigable = false;
		Spinner.MCName = 'SpinnerMC';
		Spinner.InitSpinner("", _SpinnerLabel, OnSpinnerChangeDelegate);
		Spinner.Navigator.HorizontalNavigation = true;
		Spinner.SetX(width - 180);
		Spinner.SetValueWidth(100, true);
	}

	Spinner.SetValue(_SpinnerLabel);
	Spinner.Show();

	Button.SetText(_ButtonLabel);
	RefreshButtonVisibility();

	Desc.SetWidth(width - 205);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	OnButtonClickedCallback = _OnButtonClicked;
	OnSpinnerChangedCallback = _OnSpinnerChange;
	return self;
}


simulated function UIMechaListItem UpdateDataDropdown(string _Desc, 
									   array<String> Data, 
									   int SelectedIndex,
									   delegate<OnDropdownSelectionChangedCallback> _OnSelectionChange,
									   optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	local int i;

	SetWidgetType(EUILineItemType_Dropdown);
	if(Dropdown != none)
	{
		Dropdown.Remove();
		Dropdown = none;
	}
	
	if( Dropdown == none )
	{
		Dropdown = Spawn(class'UIDropdown', self);
		Dropdown.bIsNavigable = false;
		Dropdown.InitDropdown('DropdownMC');
		Dropdown.SetPosition(width - 308, 24);
	}
	
	Dropdown.Clear();

	for(i = 0; i < Data.Length; ++i)
	{
		Dropdown.AddItem(Data[i]);
	}

	Dropdown.SetLabel("");
	Dropdown.SetSelected(SelectedIndex);
	Dropdown.Show();
	
	Desc.SetWidth(width - 308);
	Desc.SetHTMLText(_Desc);
	Desc.Show();

	OnClickDelegate = _OnClickDelegate;
	Dropdown.OnItemSelectedDelegate = _OnSelectionChange;
	return self;
}

simulated function UIMechaListItem UpdateDataCheckbox(string _Desc,
									  String _CheckboxLabel,
									  bool bIsChecked,
									  delegate<OnCheckboxChangedCallback> _OnCheckboxChangedCallback = none,
									  optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_Checkbox);

	if( Checkbox == none )
	{
		Checkbox = Spawn(class'UICheckbox', self);
		Checkbox.bAnimateOnInit = false;
		Checkbox.bIsNavigable = false;
		Checkbox.LibID = class'UICheckbox'.default.AlternateLibID; 
		Checkbox.InitCheckbox('CheckboxMC');
		Checkbox.SetX(width - 34);
		Desc.SetWidth(Width - 36);
		Checkbox.OnMouseEventDelegate = CheckboxMouseEvent; 
	}
	
	OnClickDelegate = _OnClickDelegate;
	Checkbox.onChangedDelegate = _OnCheckboxChangedCallback;

	Checkbox.SetChecked(bIsChecked, false);
	Checkbox.Show();

	Desc.SetHTMLText(_Desc);
	Desc.Show();
	return self;
}

simulated function CheckboxMouseEvent(UIPanel Panel, int Cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		OnMouseEventDelegate(self, cmd);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		OnMouseEventDelegate(self, cmd);
		break;
	}
}

// -----------------------------------------------------------------
// -----------------------------------------------------------------

simulated function SetDisabled(bool IsDisabled, optional string TooltipReason)
{
	if( BG.bHasTooltip )
		BG.RemoveTooltip();

	if( bDisabled != IsDisabled )
	{
		bDisabled = IsDisabled;
		MC.FunctionBool("SetDisabled", IsDisabled);
	}

	if( Desc!= none )
		Desc.SetDisabled(IsDisabled);

	if(Spinner != none)
		Spinner.SetDisabled(IsDisabled);

	// Set tooltip on BG since that's where our mouse events originate from
	if( bDisabled && TooltipReason != "" )
		BG.SetTooltipText(TooltipReason);
	else if( BG.bHasTooltip )
		BG.RemoveTooltip();

	RefreshButtonVisibility();
}

simulated function SetBad(bool isBad, optional string TooltipText)
{
	if( bIsBad != isBad )
	{
		bIsBad = isBad;
		if( bIsBad )
			mc.FunctionVoid("setBad");
		else
			mc.FunctionVoid("clearBad");
	}

	RefreshButtonVisibility();

	// Set tooltip on BG since that's where our mouse events originate from
	if( isBad && TooltipText != "" )
		BG.SetTooltipText(TooltipText);
	else if( BG.bHasTooltip )
		BG.RemoveTooltip();
}

simulated function AnimateIn(optional float Delay = -1.0)
{
	if( Delay == -1.0)
		Delay = ParentPanel.GetChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; 

	AddTweenBetween("_alpha", 0, alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay);
	AddTweenBetween("_y", Y+10, Y, class'UIUtilities'.const.INTRO_ANIMATION_TIME*2, Delay, "easeoutquad");
}

simulated function OnMouseEvent( int cmd, array<string> args )
{
	super.OnMouseEvent(cmd, args);

	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED )
		Click();
	else if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT )
		OnLoseFocus();

	RefreshButtonVisibility();
}

simulated function Click()
{
	if( OnClickDelegate != none && !bDisabled && bIsVisible )
		OnClickDelegate();
}

simulated function OnSpinnerChangeDelegate( UIListItemSpinner SpinnerPanel, int Direction )
{
	if( OnSpinnerChangedCallback != none && !bDisabled && bIsVisible )
		OnSpinnerChangedCallback(SpinnerPanel, Direction);
	RefreshButtonVisibility();
}

simulated function OnButtonClickDelegate(UIButton ButtonSource)
{
	if( OnButtonClickedCallback != none && !bDisabled && bIsVisible )
		OnButtonClickedCallback(ButtonSource);
	RefreshButtonVisibility();
}

simulated function RefreshButtonVisibility()
{
	if( Button != none)
	{
		// Check to see if the spinner is set to initial default value (0 or -1).
		if ( bDisabled ||(Spinner != none && (InStr( Spinner.value, ">0<" ) > -1  || InStr( Spinner.value, ">-1<" ) > -1)) )
			Button.Hide();
		else if(Type == EUILineItemType_Button)
			Button.Show();
	}
}

// -----------------------------------------------------------------

defaultproperties
{
	width = 313;
	height = 38;
	LibID = "X2MechaListItem";
	bCascadeFocus = false;
}
