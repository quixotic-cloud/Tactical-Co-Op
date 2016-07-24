//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIShellDifficulty.uc
//  AUTHOR:  Brit Steiner       -- 01/25/12
//           Tronster           -- 04/13/12
//  PURPOSE: Controls the difficulty menu in the shell SP game. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISecondWave extends UIScreen;

var localized string m_strTitle;
var localized string m_strWarning;
var localized string m_arrGameplayToggleTitle[EGameplayOption.EnumCount]<BoundEnum=EGameplayOption>;
var localized string m_arrGameplayToggleDesc[EGameplayOption.EnumCount]<BoundEnum=EGameplayOption>;
var localized string m_strCanNotChangeInGame; 

var UIWidgetHelper          m_hWidgetHelper; 
var UINavigationHelp        NavHelp;

var bool m_bViewOnly;

//The game play options array does not necessary match the checkboxes 1:1 - this array is the same size as the widget/checkbox array and holds info on 
//what gameplay option each checkbox is controlling
var private array<int> CheckboxIndexToGameplayOptionMap; 

//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	m_hWidgetHelper = Spawn( class'UIWidgetHelper', self );

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddBackButton(OnUCancel);
}
//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	super.OnInit();
	UpdateData();
	RefreshDescInfo();
	Show();
}

//----------------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return true;

	//Pass down to the helper, return if handled. 
	bHandled =  m_hWidgetHelper.OnUnrealCommand( cmd, arg ); 

	if( !bHandled )
	{
		switch(cmd)
		{
			case class'UIUtilities_Input'.const.FXS_BUTTON_X:
				//OnToggleAdvancedOptions();
				break;

			case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
				//OnToggleOption( m_iCurrentOption );
				break;
			
			case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
			case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
				OnUCancel();
				break;
			default:
				bHandled = false;
		}
	}
	else
		RefreshDescInfo();

	if (bHandled)
		return true;

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int iSelection;

	if(InStr(args[args.Length - 1], "option") != -1)
		iSelection = int(Split( args[args.Length - 1], "option", true));
	else
		iSelection = int(Split( args[args.Length - 2], "option", true));

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			//Update the selection based on what the mouse rolled over
			m_hWidgetHelper.SetSelected( iSelection );
			RefreshDescInfo();
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
				m_hWidgetHelper.ProcessMouseEvent( iSelection );
			break;
	}
}


//----------------------------------------------------------------------------

simulated function UpdateData()
{
	local UIWidget_Checkbox kCheckbox;
	local int i, ActiveWidgetIndex;

	// Title
	AS_SetTitle( m_strTitle );

	// Toggle description string
	RefreshDescInfo();

	// Build the toggles
	for( i = 0; i < eGO_MAX; i++ )
	{
		// Later options may not be unlocked yet
		if( !`XPROFILESETTINGS.Data.IsGameplayToggleUnlocked(EGameplayOption(i)) )
			continue;

		if( m_hWidgetHelper.GetNumWidgets() <= ActiveWidgetIndex )
		{			
			kCheckbox = m_hWidgetHelper.NewCheckbox();
			ActiveWidgetIndex = m_hWidgetHelper.GetNumWidgets() - 1;
		}
		else
		{
			kCheckbox = UIWidget_Checkbox(m_hWidgetHelper.GetWidget(ActiveWidgetIndex));
		}

		kCheckbox.strTitle = m_arrGameplayToggleTitle[i];
		
		if(m_bViewOnly)
			kCheckbox.bChecked = Movie.Pres.IsGameplayOptionEnabled(EGameplayOption(i));
		else
			kCheckbox.bChecked = `XPROFILESETTINGS.Data.GetGameplayOption(EGameplayOption(i)); //This query is only valid in the shell! 		

		CheckboxIndexToGameplayOptionMap.AddItem(i);

		m_hWidgetHelper.RefreshWidget( ActiveWidgetIndex );

		// Don't allow modification of this in View Only mode
		if(!m_bViewOnly)
			kCheckbox.del_OnValueChanged = UpdateToggle;
		else
			kCheckbox.bReadOnly = true;

		m_hWidgetHelper.SetActive( ActiveWidgetIndex, true );
		
		++ActiveWidgetIndex;
	}
	m_hWidgetHelper.RefreshAllWidgets();
	m_hWidgetHelper.SetSelected(0);
}

// Lower pause screen
simulated public function OnUCancel()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
}

simulated function UpdateToggle()
{
	local EGameplayOption eOption;
	local bool bTurnedOn;

	eOption = EGameplayOption(CheckboxIndexToGameplayOptionMap[m_hWidgetHelper.GetCurrentSelection()]);
	bTurnedOn = bool(m_hWidgetHelper.GetCurrentValue(m_hWidgetHelper.GetCurrentSelection()) );
	`XPROFILESETTINGS.Data.SetGameplayOption( eOption, bTurnedOn );

	if( eOption == eGO_Marathon && bTurnedOn )
	{
		UIShellDifficulty(Movie.Pres.ScreenStack.GetScreen(class'UIShellDifficulty')).ForceTutorialOff();  // Tutorial is not compatible with Marathon
	}
	
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

simulated function RefreshDescInfo()
{
	local string desc; 
	if( m_bViewOnly )
		desc = class'UIUtilities_Text'.static.GetColoredText( m_strCanNotChangeInGame, eUIState_Warning) $"\n" $ m_arrGameplayToggleDesc[CheckboxIndexToGameplayOptionMap[m_hWidgetHelper.GetCurrentSelection()]]; 
	else 
		desc = m_arrGameplayToggleDesc[CheckboxIndexToGameplayOptionMap[m_hWidgetHelper.GetCurrentSelection()]];

	AS_SetDesc( desc );
}

simulated function AS_SetTitle( string title )
{
	Movie.ActionScriptVoid(MCPath$".SetTitle");
}

simulated function AS_SetDesc( string desc )
{
	Movie.ActionScriptVoid(MCPath$".SetDesc");
}

DefaultProperties
{
	Package   = "/ package/gfxSecondWave/SecondWave";
	MCName      = "theScreen";

	InputState= eInputState_Consume;
}
