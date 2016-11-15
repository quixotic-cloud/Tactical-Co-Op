
class UIArmory_PromotionItem extends UIPanel;

var int Rank;
var name ClassName;
var name AbilityName1;
var name AbilityName2;

var UIButton InfoButton1;
var UIButton InfoButton2;
var UIIcon AbilityIcon1;
var UIIcon AbilityIcon2;
var UIIcon ClassIcon;

var int SelectedAbility;
var bool bIsDisabled;
var bool bEligibleForPromotion;

var localized string m_strNewRank;

simulated function UIArmory_PromotionItem InitPromotionItem(int InitRank)
{
	Rank = InitRank;

	InitPanel();

	Navigator.HorizontalNavigation = true;

	AbilityIcon1 = Spawn(class'UIIcon', self).InitIcon('abilityIcon1MC');
	AbilityIcon1.ProcessMouseEvents(OnChildMouseEvent);
	AbilityIcon1.bDisableSelectionBrackets = true;
	AbilityIcon1.bAnimateOnInit = false;
	AbilityIcon1.Hide(); // starts hidden
	AbilityIcon1.DisableNavigation();

	AbilityIcon2 = Spawn(class'UIIcon', self).InitIcon('abilityIcon2MC');
	AbilityIcon2.ProcessMouseEvents(OnChildMouseEvent);
	AbilityIcon2.bDisableSelectionBrackets = true;
	AbilityIcon2.bAnimateOnInit = false;
	AbilityIcon2.Hide(); // starts hidden
	AbilityIcon2.DisableNavigation();

	InfoButton1 = Spawn(class'UIButton', self);
	InfoButton1.bIsNavigable = false;
	InfoButton1.InitButton('infoButtonLeft');
	InfoButton1.ProcessMouseEvents(OnChildMouseEvent);
	InfoButton1.bAnimateOnInit = false;
	InfoButton1.Hide(); // starts hidden
	InfoButton1.DisableNavigation();
	InfoButton2 = Spawn(class'UIButton', self);
	InfoButton2.bIsNavigable = false;
	InfoButton2.InitButton('infoButtonRight');
	InfoButton2.ProcessMouseEvents(OnChildMouseEvent);
	InfoButton2.bAnimateOnInit = false;
	InfoButton2.Hide(); // starts hidden
	InfoButton2.DisableNavigation();

	ClassIcon = Spawn(class'UIIcon', self);
	ClassIcon.bIsNavigable = false;
	ClassIcon.InitIcon('classIconMC');
	ClassIcon.ProcessMouseEvents(OnChildMouseEvent);
	ClassIcon.bAnimateOnInit = false;
	ClassIcon.bDisableSelectionBrackets = true;
	ClassIcon.Hide(); // starts hidden
	ClassIcon.DisableNavigation();

	SelectedAbility = -1;

	MC.FunctionString("setPromoteRank", m_strNewRank);

	return self;
}

simulated function SetDisabled(bool bDisabled)
{
	bIsDisabled = bDisabled;

	AbilityIcon1.SetDisabled(bIsDisabled);
	AbilityIcon2.SetDisabled(bIsDisabled);

	MC.FunctionBool("setDisabled", bIsDisabled);

	RealizeInfoButtons();
}

simulated function SetPromote(bool bIsPromote, optional bool highlightAbility1, optional bool highlightAbility2)
{
	bEligibleForPromotion = bIsPromote;
	
	MC.BeginFunctionOp("setPromote");
	MC.QueueBoolean(bIsPromote);
	MC.QueueBoolean(highlightAbility1);
	MC.QueueBoolean(highlightAbility2);
	MC.EndOp();
}

simulated function SetClassData(string Icon, string Label)
{
	ClassIcon.Show();
	AbilityIcon1.Hide();
	InfoButton1.Hide();

	MC.BeginFunctionOp("setClassData");
	MC.QueueString(Icon);
	MC.QueueString(Label);
	MC.EndOp();
}

simulated function SetRankData(string Icon, string Label)
{
	MC.BeginFunctionOp("setRankData");
	MC.QueueString(Icon);
	MC.QueueString(Label);
	MC.EndOp();
}

simulated function SetAbilityData(string Icon1, string Name1, string Icon2, string Name2)
{
	AbilityIcon1.Show();
	AbilityIcon2.Show();

	MC.BeginFunctionOp("setAbilityData");
	MC.QueueString(Icon1);
	MC.QueueString(Name1);
	MC.QueueString(Icon2);
	MC.QueueString(Name2);
	MC.EndOp();
}

simulated function SetEquippedAbilities(optional bool bEquippedAbility1, optional bool bEquippedAbility2)
{
	MC.BeginFunctionOp("setEquippedAbilities");
	MC.QueueBoolean(bEquippedAbility1);
	MC.QueueBoolean(bEquippedAbility2);
	MC.EndOp();
}

simulated function RealizeVisuals()
{
	MC.FunctionVoid("realizeFocus");

	if(`ISCONTROLLERACTIVE)
		RealizeInfoButtons();
}

simulated function OnAbilityInfoClicked(UIButton Button)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	if(Button == InfoButton1)
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName1);
	else if(Button == InfoButton2)
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName2);

	if(AbilityTemplate != none)
		`HQPRES.UIAbilityPopup(AbilityTemplate);
	AbilityIcon1.OnLoseFocus();
	AbilityIcon2.OnLoseFocus();
	RealizeHighlight();
}

simulated function SelectAbility(int idx)
{
	local UIArmory_Promotion PromotionScreen;
	PromotionScreen = UIArmory_Promotion(Screen);

	if(bEligibleForPromotion)
	{
		PromotionScreen.ConfirmAbilitySelection(Rank, idx);
		AbilityIcon1.OnLoseFocus();
		AbilityIcon2.OnLoseFocus();
		RealizePromoteState();
		RealizeHighlight();
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
}

simulated function OnChildMouseEvent(UIPanel ChildControl, int cmd)
{
	local bool bHandled;
	bHandled = true;

	switch(ChildControl)  
	{
	case AbilityIcon1:
		if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		{
			SelectAbility(0);
		}
		else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN)
		{
			OnReceiveFocus();
			AbilityIcon1.OnReceiveFocus();
			RealizePromoteState();
			RealizeHighlight();
		}
		else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT)
		{
			AbilityIcon1.OnLoseFocus();
			RealizePromoteState();
			RealizeHighlight();
		}
		break;
	case AbilityIcon2:
		if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		{
			SelectAbility(1);
		}
		else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER)
		{
			OnReceiveFocus();
			AbilityIcon2.OnReceiveFocus();
			RealizePromoteState();
			RealizeHighlight();
		}
		else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT)
		{
			AbilityIcon2.OnLoseFocus();
			RealizePromoteState();
			RealizeHighlight();
		}
		break;
	case InfoButton1:
	case InfoButton2:
		if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		{
			OnAbilityInfoClicked(UIButton(ChildControl));
		}
		else if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER)
		{
			OnReceiveFocus();
		}
		break;
	case ClassIcon:
		if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN || cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER)
		{
			OnReceiveFocus();
		}
		break;
	default:
		bHandled = false;
		break;
	}

	if( bHandled )
		RealizeVisuals();
}

simulated function RealizePromoteState()
{
	if(bEligibleForPromotion && Movie.Pres.ScreenStack.GetCurrentScreen() == Screen)
		SetPromote(true, AbilityIcon1.bIsFocused, AbilityIcon2.bIsFocused);
}

simulated function RealizeHighlight()
{
	MC.BeginFunctionOp("setHighlight");
	MC.QueueBoolean(AbilityIcon1.bIsFocused);
	MC.QueueBoolean(AbilityIcon2.bIsFocused);
	MC.EndOp();
}
simulated function RealizeInfoButtons()
{
	if(`ISCONTROLLERACTIVE)
	{
		// Directly force visibility update because PromotionListItem.as manipulates visibility of these components without controller logic
		InfoButton1.MC.SetBool("_visible", bIsFocused && !bIsDisabled && !bEligibleForPromotion && !ClassIcon.bIsVisible && AbilityIcon1.bIsFocused);
		InfoButton2.MC.SetBool("_visible", bIsFocused && !bIsDisabled && !bEligibleForPromotion && AbilityIcon2.bIsFocused);
	}
	else
	{
		InfoButton1.SetVisible(bIsFocused && !bIsDisabled && !ClassIcon.bIsVisible);
		InfoButton2.SetVisible(bIsFocused && !bIsDisabled);
	}
}
simulated function SetSelectedAbility(int AbilityIndex)
{
	if (AbilityIndex == 0 && AbilityIcon1.bIsVisible)
	{
		AbilityIcon1.OnReceiveFocus();
		RealizePromoteState();
		RealizeHighlight();
		SelectedAbility = 0;
	}
	else if (AbilityIndex == 1 && AbilityIcon2.bIsVisible)
	{
		AbilityIcon2.OnReceiveFocus();
		RealizePromoteState();
		RealizeHighlight();
		SelectedAbility = 1;
	}
	else
	{
		AbilityIcon1.OnLoseFocus();
		AbilityIcon2.OnLoseFocus();
		RealizePromoteState();
		RealizeHighlight();
		SelectedAbility = -1;
	}

	if(`ISCONTROLLERACTIVE)
		RealizeInfoButtons();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	// Hax: The first promotion item isn't on the list, so if any other list item gets selected, we must ensure that one loses its focus
	if(self != UIArmory_Promotion(Screen).ClassRowItem)
		UIArmory_Promotion(Screen).ClassRowItem.OnLoseFocus();

	if(UIArmory_Promotion(Screen).List.GetItemIndex(self) != INDEX_NONE)
		UIArmory_Promotion(Screen).List.SetSelectedItem(self);
	else
	{
		UIArmory_Promotion(Screen).List.SetSelectedIndex(-1);
		SetSelectedAbility(ClassIcon.bIsVisible ? 1 : UIArmory_Promotion(Screen).SelectedAbilityIndex);
	}
}

simulated function OnLoseFocus()
{
	// Leave highlighted when confirming ability selection
	if(Movie.Pres.ScreenStack.GetCurrentScreen() == Screen)
	{
		super.OnLoseFocus();
		RealizeInfoButtons();
	}
	AbilityIcon1.OnLoseFocus();
	AbilityIcon2.OnLoseFocus();
	RealizePromoteState();
	RealizeHighlight();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
	{
		return false;
	}
	
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		if (AbilityIcon1.bIsVisible)
		{
			OnChildMouseEvent(AbilityIcon1, class'UIUtilities_Input'.const.FXS_L_MOUSE_IN);
			OnChildMouseEvent(AbilityIcon2, class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT);
			SelectedAbility = 0;
		}

		return true;

	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		if (AbilityIcon2.bIsVisible)
		{
			OnChildMouseEvent(AbilityIcon1, class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT);
			OnChildMouseEvent(AbilityIcon2, class'UIUtilities_Input'.const.FXS_L_MOUSE_IN);
			SelectedAbility = 1;
		}

		return true;
		
	case class'UIUtilities_Input'.const.FXS_DPAD_UP:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		if (self != UIArmory_Promotion(Screen).ClassRowItem)
		{
			UIArmory_Promotion(Screen).SelectedAbilityIndex = SelectedAbility;
			OnChildMouseEvent(AbilityIcon1, class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT);
			OnChildMouseEvent(AbilityIcon2, class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT);
			SelectedAbility = -1;
		}

		break;

	case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
	case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		if (UIArmory_Promotion(Screen).List.SelectedIndex < UIArmory_Promotion(Screen).List.GetItemCount() - 1)
		{
			UIArmory_Promotion(Screen).SelectedAbilityIndex = SelectedAbility;
			OnChildMouseEvent(AbilityIcon1, class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT);
			OnChildMouseEvent(AbilityIcon2, class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT);
			SelectedAbility = -1;
		}

		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		if (!bEligibleForPromotion)
		{
			return false;
		}

		UIArmory_Promotion(Screen).SelectedAbilityIndex = SelectedAbility;
		if (SelectedAbility == 0)
		{
			OnChildMouseEvent(AbilityIcon1, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
		}
		else if (SelectedAbility == 1)
		{
			OnChildMouseEvent(AbilityIcon2, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
		}

		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_L3:
		if (!bIsDisabled)
		{
			UIArmory_Promotion(Screen).SelectedAbilityIndex = SelectedAbility;
			if (SelectedAbility == 0)
			{
				OnChildMouseEvent(InfoButton1, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
			}
			else if (SelectedAbility == 1)
			{
				OnChildMouseEvent(InfoButton2, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
			}
		}

		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	LibID = "PromotionListItem";
	width = 724;
	height = 76;
	bCascadeFocus = false;
}