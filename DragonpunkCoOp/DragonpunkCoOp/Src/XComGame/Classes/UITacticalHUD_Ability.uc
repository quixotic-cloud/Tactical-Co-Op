//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_AbilityContainer.uc
//  AUTHOR:  Brit Steiner, Sam Batista
//  PURPOSE: Containers holding current soldiers ability icons.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_Ability extends UIPanel;

var localized string m_strCooldownPrefix; 
var localized string m_strChargePrefix;

var string m_strCooldown;
var string m_strCharge;
var string m_strAntennaText;
var string m_strHotkeyLabel;
var bool IsAvailable;
var bool bIsShiney; 
var int Index; 

var X2AbilityTemplate AbilityTemplate;    //Holds TEMPLATE data for the ability referenced by AvailableActionInfo. Ie. what icon does this ability use?

var UIIcon Icon;

simulated function UIPanel InitAbilityItem(optional name InitName)
{
	InitPanel(InitName);
	
	// Link up with existing IconControl in AbilityItem movieclip
	Icon = Spawn(class'UIIcon', self);
	Icon.InitIcon('IconMC',, false, true, 36); // 'IconMC' matches instance name of control in Flash's 'AbilityItem' Symbol
	Icon.SetPosition(-20, -20); // offset because we scale the icon
	
	return self;
}

simulated function UpdateData(int NewIndex, const out AvailableAction AvailableActionInfo)
{
	local XComGameState_BattleData BattleDataState;
	local bool bCoolingDown;
	local int iTmp;
	local XComGameState_Ability AbilityState;   //Holds INSTANCE data for the ability referenced by AvailableActionInfo. Ie. cooldown for the ability on a specific unit

	Index = NewIndex; 

	//AvailableActionInfo function parameter holds UI-SPECIFIC data such as "is this ability visible to the HUD?" and "is this ability available"?
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);
	AbilityTemplate = AbilityState.GetMyTemplate();

	//Indicate whether the ability is available or not
	SetAvailable(AvailableActionInfo.AvailableCode == 'AA_Success');	

	//Cooldown handling
	bCoolingDown = AbilityState.IsCoolingDown();
	if(bCoolingDown)
		SetCooldown(m_strCooldownPrefix $ string(AbilityState.GetCooldownRemaining()));
	else
		SetCooldown("");

	//Set the icon
	if (AbilityTemplate != None)
	{
		Icon.LoadIcon(AbilityState.GetMyIconImage());
	
		// Set Antenna text, PC only
		if(Movie.IsMouseActive())
			SetAntennaText(Caps(AbilityState.GetMyFriendlyName()));
	}

	iTmp = AbilityState.GetCharges();
	if(iTmp >= 0 && !bCoolingDown)
		SetCharge(m_strChargePrefix $ string(iTmp));
	else
		SetCharge("");

	//Key the color of the ability icon on the source of the ability
	if (AbilityTemplate != None)
	{
		BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
		if(BattleDataState.IsAbilityObjectiveHighlighted(AbilityTemplate.DataName))
		{
			Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.OBJECTIVEICON_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		}
		else if(AbilityTemplate.AbilityIconColor != "")
		{
			Icon.EnableMouseAutomaticColor(AbilityTemplate.AbilityIconColor, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
		}
		else
		{
			switch(AbilityTemplate.AbilitySourceName)
			{
			case 'eAbilitySource_Perk':
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.PERK_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;

			case 'eAbilitySource_Debuff':
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.BAD_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;

			case 'eAbilitySource_Psionic':
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;

			case 'eAbilitySource_Commander': 
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.GOOD_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
				break;
		
			case 'eAbilitySource_Item':
			case 'eAbilitySource_Standard':
			default:
				Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
			}
		}
	}

	// HOTKEY LABEL (pc only)
	if(Movie.IsMouseActive())
	{
		iTmp = eTBC_Ability1 + Index;
		if( iTmp <= eTBC_Ability0 )
			SetHotkeyLabel(PC.Pres.m_kKeybindingData.GetPrimaryOrSecondaryKeyStringForAction(PC.PlayerInput, (eTBC_Ability1 + Index)));
		else
			SetHotkeyLabel("");
	}
	RefreshShine();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local UITacticalHUD_AbilityContainer AbilityContainer;

	super.OnMouseEvent(cmd, args);

	Index = int(GetRightMost(string(MCName)));
	AbilityContainer = UITacticalHUD_AbilityContainer(ParentPanel);

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		AbilityContainer.ShowAOE(Index);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		AbilityContainer.HideAOE(Index);
		break;

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		RefreshShine();
		AbilityContainer.AbilityClicked(Index);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		if( AbilityContainer.AbilityClicked(Index) && AbilityContainer.GetTargetingMethod() != none )
		{
			AbilityContainer.OnAccept();
			AbilityContainer.ResetMouse();
			RefreshShine();
		}
		break;
	}
}

simulated function RefreshShine(optional bool bIgnoreMenuStatus = false)
{
	if( `REPLAY.bInTutorial )
	{
		if( ShouldShowShine(bIgnoreMenuStatus) )
		{
			ShowShine();
		}
		else
		{
			HideShine();
		}
	}
}

function bool ShouldShowShine( bool bIgnoreMenuStatus )
{
	if( AbilityTemplate != None && `TUTORIAL.IsNextAbility(AbilityTemplate.DataName) )
	{
		if( bIgnoreMenuStatus )
			return true; 

		if( !UITacticalHUD(Screen).IsMenuRaised() )
			return true; 

		if(UITacticalHUD(Screen).IsMenuRaised() && !UITacticalHUD_AbilityContainer(Owner).IsSelectedValue(Index) )
			return true;
	}
	 
	return false;
}

simulated function SetCooldown(string cooldown)
{
	if(m_strCooldown != cooldown)
	{
		m_strCooldown = cooldown;
		mc.FunctionString("SetCooldown", m_strCooldown);
	}
}

simulated function SetCharge(string charge)
{
	if(m_strCharge != charge)
	{
		m_strCharge = charge;
		mc.FunctionString("SetCharge", m_strCharge);
	}
}

simulated function SetAntennaText(string text)
{
	if(m_strAntennaText != text)
	{
		m_strAntennaText = text;
		mc.FunctionString("SetAntennaText", m_strAntennaText);
	}
}

simulated function SetHotkeyLabel(string hotkey)
{
	if(m_strHotkeyLabel != hotkey)
	{
		m_strHotkeyLabel = hotkey;
		mc.FunctionString("SetHotkeyLabel", m_strHotkeyLabel);
	}
}

simulated function ShowShine()
{
	if( !bIsShiney )
	{
		bIsShiney = true;
		mc.FunctionVoid("ShowShine");
	}
}

simulated function HideShine()
{
	if( bIsShiney )
	{
		bIsShiney = false;
		mc.FunctionVoid("HideShine");
	}
}

simulated function SetAvailable(bool Available)
{
	if(IsAvailable != Available)
	{
		IsAvailable = Available;
		MC.FunctionBool("SetAvailable", IsAvailable);
	}
}

simulated function Show()
{
	// visibility is controlled by AbilityContainer.as
	//super.Show();
	bIsVisible = true;
}

simulated function Hide()
{
	// visibility is controlled by AbilityContainer.as
	//super.Hide();
	bIsVisible = false;
}

defaultproperties
{
	LibID = "AbilityItem";

	bIsVisible = false; // Start off hidden
	IsAvailable = true;

	// The AbilityItem class in flash implements 'onMouseEvent' to provide custom mouse handling code -sbatista
	bProcessesMouseEvents = false;

	bAnimateOnInit = false;

	bIsShiney = false;
}