//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidgetHelper.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Library of helper elements used for combobox controls 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidgetHelper extends Actor;

enum EUINavDirection
{
	eNavDir_None,
	eNavDir_Down,
	eNavDir_Up
};

const INCREASE_VALUE = -1;  // spinner, sliders
const DECREASE_VALUE = -2;  // spinner, sliders



var protected array<UIWidget>    m_arrWidgets; 
var public int                 m_iCurrentWidget;
var public string              s_widgetName;
var public string              MCName;
var public EUINavDirection     m_eDirection; 

// ----------------------------------------------------------------------------------
//                           INPUT PROCESSING
// ----------------------------------------------------------------------------------

// Collection of helper functions to process comboboxes
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	bHandled = true;
	
	//Don't bother processing if we don't have any comboboxes to work with. 
	if( m_arrWidgets.Length < 1 ) return false; 

	// NOTE: Parsing of input type should be handled by the screen that contains this class. - sbatista 4/4/12
	//if ( !((arg & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0 || ( arg & class'UIUtilities_Input'.const.FXS_ACTION_POSTHOLD_REPEAT) != 0))
	//	return false;
	

	//Capture the navigation direction, used by the list. 
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			m_eDirection = eNavDir_Up;
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			m_eDirection = eNavDir_Down;
			break;

		default:
			m_eDirection = eNavDir_None;
			break;
	}
	
	//Send the signal to the appropriate widget processing 
	switch( m_arrWidgets[m_iCurrentWidget].eType )
	{
		case eWidget_Combobox:
			bHandled = OnUnrealCommand_Combobox( cmd, arg );
			break;
		case eWidget_Button:
			bHandled = OnUnrealCommand_Button( cmd, arg );
			break;
		case eWidget_List:
			bHandled = OnUnrealCommand_List( cmd, arg );
			break;
		case eWidget_Spinner:
			bHandled = OnUnrealCommand_Spinner( cmd, arg );
			break;
		case eWidget_Slider:
			bHandled = OnUnrealCommand_Slider( cmd, arg );
			break;
		case eWidget_Checkbox:
			bHandled = OnUnrealCommand_Checkbox( cmd, arg );
			break;
		case eWidget_Invalid:
		default: 
			`log("UIWidgetHelper OnUnrealCommand failure to process widget type." @self @"; cmd ="@cmd @"; arg =" @arg,,'uixcom');
			bHandled = false;
	}

	return bHandled;
}

simulated private function bool OnUnrealCommand_Combobox( int cmd, int arg )
{
	local bool bHandled, bValueChanged;
	local UIWidget_Combobox kCombobox; 

	bHandled = true;
	bValueChanged = false;
	
	kCombobox = UIWidget_Combobox(m_arrWidgets[m_iCurrentWidget]);

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:

			if(kCombobox.m_bComboBoxHasFocus)
			{
				//Set selection within a combobox
				PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
				kCombobox.iCurrentSelection = (kCombobox.arrLabels.length + kCombobox.iCurrentSelection-1) % kCombobox.arrLabels.length;
				SetDropdownSelection( m_iCurrentWidget, kCombobox.iCurrentSelection );
			}
			else
			{
				SelectPrevAvailableWidget();
			}
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:

			if(kCombobox.m_bComboBoxHasFocus)
			{
				//Set selection within a combobox
				PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
				kCombobox.iCurrentSelection = (kCombobox.iCurrentSelection+1) % kCombobox.arrLabels.length;
				SetDropdownSelection( m_iCurrentWidget, kCombobox.iCurrentSelection );
			}
			else
			{
				SelectNextAvailableWidget();
			}
			break;


		// OnAccept
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			
			bValueChanged = (kCombobox.iBoxSelection != kCombobox.iCurrentSelection);
			kCombobox.iBoxSelection = kCombobox.iCurrentSelection;
			
			if(kCombobox.m_bComboBoxHasFocus)
			{
				SetComboboxValue( m_iCurrentWidget,kCombobox.iCurrentSelection);

				if (bValueChanged)
					m_arrWidgets[m_iCurrentWidget].del_OnValueChanged();
			}
			else
			{
				OpenCombobox( m_iCurrentWidget );
			}

			UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			if(kCombobox.m_bComboBoxHasFocus)
			{
				kCombobox.iCurrentSelection = kCombobox.iBoxSelection;
				SetComboboxValue( m_iCurrentWidget,kCombobox.iCurrentSelection);
				CloseCombobox( m_iCurrentWidget );
				UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);
			}
			else
			{
				bHandled = false;
			}
			break;

		default:
			bHandled = false;
			break;
	}
	return bHandled;
}

simulated private function bool OnUnrealCommand_Button( int cmd, int arg )
{
	local bool bHandled;
	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			SelectPrevAvailableWidget();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			SelectNextAvailableWidget();
			break;


		// OnAccept
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:

			if( !m_arrWidgets[m_iCurrentWidget].bIsDisabled &&
				 m_arrWidgets[m_iCurrentWidget].del_OnValueChanged != none)
			{
				m_arrWidgets[m_iCurrentWidget].del_OnValueChanged();
				UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			}
			else
				UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);

			break;

		default:
			bHandled = false;
			break;
	}
	return bHandled; 
}

simulated private function bool OnUnrealCommand_Spinner( int cmd, int arg )
{
	local UIWidget_Spinner spinner; 
	local bool bHandled;
	bHandled = true;

	spinner = UIWidget_Spinner(m_arrWidgets[m_iCurrentWidget]); 

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			if( spinner.bIsHorizontal ) 
				SelectPrevAvailableWidget();
			else
			{
				if( spinner.bCanSpin )
				{
					if(spinner.arrLabels.Length > 0 && spinner.bCanSpin)
					{
						spinner.iCurrentSelection++;
						if(spinner.iCurrentSelection >= spinner.arrLabels.Length)
							spinner.iCurrentSelection = 0;
						SetSpinnerValue(m_iCurrentWidget, spinner.arrLabels[spinner.iCurrentSelection]);
					}

					if(spinner.del_OnIncrease != none)
						spinner.del_OnIncrease();
					if(spinner.del_OnValueChanged != none)
						spinner.del_OnValueChanged();
					PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
				}
				else
					UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);
			}
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			if( spinner.bIsHorizontal ) 
				SelectNextAvailableWidget();
			else
			{
				if( spinner.bCanSpin )
				{
					if(spinner.arrLabels.Length > 0  && spinner.bCanSpin)
					{
						spinner.iCurrentSelection--;
						if(spinner.iCurrentSelection < 0)
							spinner.iCurrentSelection = spinner.arrLabels.Length - 1;
						SetSpinnerValue(m_iCurrentWidget, spinner.arrLabels[spinner.iCurrentSelection]);
					}

					if(spinner.del_OnDecrease != none)
						spinner.del_OnDecrease();
					if(spinner.del_OnValueChanged != none)
						spinner.del_OnValueChanged();
					PlaySound( SoundCue'SoundUI.MenuScrollCue', true );	
				}
				else
					UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);
			}
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_KEY_D:
			if( spinner.bIsHorizontal ) 
			{
				if( spinner.bCanSpin )
				{
					if(spinner.arrLabels.Length > 0)
					{
						spinner.iCurrentSelection++;
						if(spinner.iCurrentSelection >= spinner.arrLabels.Length)
							spinner.iCurrentSelection = 0;
						SetSpinnerValue(m_iCurrentWidget, spinner.arrLabels[spinner.iCurrentSelection]);
					}

					if(spinner.del_OnIncrease != none)
						spinner.del_OnIncrease();
					if(spinner.del_OnValueChanged != none)
						spinner.del_OnValueChanged();
					PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
				}
				else
					UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);
			}
			else
				SelectNextAvailableWidget();				
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_KEY_A:
			if( spinner.bIsHorizontal ) 
			{
				if( spinner.bCanSpin )
				{
					if(spinner.arrLabels.Length > 0)
					{
						spinner.iCurrentSelection--;
						if(spinner.iCurrentSelection < 0)
							spinner.iCurrentSelection = spinner.arrLabels.Length - 1;
						SetSpinnerValue(m_iCurrentWidget, spinner.arrLabels[spinner.iCurrentSelection]);
					}

					if(spinner.del_OnDecrease != none)
						spinner.del_OnDecrease();
					if(spinner.del_OnValueChanged != none)
						spinner.del_OnValueChanged();
					PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
				}
				else
					UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);
			}
			else
				SelectPrevAvailableWidget();			
			break;

		default:
			bHandled = false;
			break;
	}
	return bHandled; 
}

simulated private function bool OnUnrealCommand_Slider( int cmd, int arg )
{
	local UIWidget_Slider kSlider; 
	local bool bHandled;
	bHandled = true;

	kSlider = UIWidget_Slider(m_arrWidgets[m_iCurrentWidget]); 

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			SelectPrevAvailableWidget();
			
			kSlider.del_OnValueChanged();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			SelectNextAvailableWidget();
			
			kSlider.del_OnValueChanged();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_KEY_D:
			kSlider.del_OnIncrease();
			if ( kSlider.iValue != 100 ) PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
			kSlider.iValue += kSlider.iStepSize;			
			if( kSlider.iValue > 100 ) kSlider.iValue = 100;
			RefreshSlider( m_iCurrentWidget );			
			
			kSlider.del_OnValueChanged();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_KEY_A:
			kSlider.del_OnDecrease();
			if ( kSlider.iValue != 0 ) PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
			kSlider.iValue -= kSlider.iStepSize;
			if( kSlider.iValue < 0 ) kSlider.iValue = 0;
			RefreshSlider( m_iCurrentWidget );

			kSlider.del_OnValueChanged();
			break;

		default:
			bHandled = false;
			break;
	}
	
	return bHandled; 
}

simulated private function bool OnUnrealCommand_Checkbox( int cmd, int arg )
{
	local bool bHandled;
	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			SelectPrevAvailableWidget();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			SelectNextAvailableWidget();
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			ToggleCheckbox( m_iCurrentWidget );
			PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
			break;

		default:
			bHandled = false;
			break;
	}
	return bHandled; 
}


simulated private function bool OnUnrealCommand_List( int cmd, int arg )
{
	local bool bHandled;
	local UIWidget_List kList; 

	bHandled = true;
	
	kList = UIWidget_List(m_arrWidgets[m_iCurrentWidget]); 

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			//Set selection within the lsit
			//kList.iCurrentSelection = (kList.arrLabels.length + kList.iCurrentSelection-1) % kList.arrLabels.length;
			SetListSelection( m_iCurrentWidget, --kList.iCurrentSelection );
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			//Set selection within the list
			//kList.iCurrentSelection = (kList.iCurrentSelection+1) % kList.arrLabels.length;
			SetListSelection( m_iCurrentWidget, ++kList.iCurrentSelection );
			break;

		// OnAccept
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			m_arrWidgets[m_iCurrentWidget].del_OnValueChanged();

			UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			break;

		default:
			bHandled = false;
			break;
	}
	return bHandled;
}

protected function SelectNextAvailableWidget()
{
	local int iCurrent;
	iCurrent = m_iCurrentWidget;

	if( SafetyCheckForActiveWidgets() )
	{
		do
		{
			//Change selection to next widget 
			m_iCurrentWidget = (m_iCurrentWidget+1) % m_arrWidgets.length;		

		} until ( m_arrWidgets[m_iCurrentWidget].bIsActive );
	}

	// If a change occurred.
	if ( iCurrent != m_iCurrentWidget )
	{
		RefreshWidget( m_iCurrentWidget );
		RealizeSelected();
	}
}

protected function SelectPrevAvailableWidget()
{
	local int iCurrent;
	iCurrent = m_iCurrentWidget;

	if( SafetyCheckForActiveWidgets() )
	{
		do
		{
			//Change selection to prev widget 
			m_iCurrentWidget = (m_arrWidgets.length + m_iCurrentWidget-1) % m_arrWidgets.length;
		} until ( m_arrWidgets[m_iCurrentWidget].bIsActive );
	}

	// If a change occurred.
	if ( iCurrent != m_iCurrentWidget )
	{
		RefreshWidget( m_iCurrentWidget );
		RealizeSelected();
	}
}

// ----------------------------------------------------------------------------------
//                            MOUSE PROCESSING
// ----------------------------------------------------------------------------------


simulated function ProcessMouseEvent(int iTargetBox, int iTargetOption = -1 )
 {
	m_iCurrentWidget = iTargetBox;

	//`log("Selected:" @ string(iTargetBox) $":" @iTargetOption , ,'uixcom');
				

	switch( m_arrWidgets[m_iCurrentWidget].eType )
	{
		case eWidget_Combobox:
			ProcessMouseEvent_Combobox( iTargetOption );
			break;
		case eWidget_Button:
			ProcessMouseEvent_Button( iTargetBox );
			break;
		case eWidget_List:
			ProcessMouseEvent_List( iTargetOption );
			break;
		case eWidget_Spinner: 
			ProcessMouseEvent_Spinner( iTargetOption );
			break;
		case eWidget_Slider: 
			ProcessMouseEvent_Slider( iTargetOption );
			break;
		case eWidget_Checkbox: 
			ProcessMouseEvent_Checkbox( iTargetBox );
			break;
		case eWidget_Invalid:
		default: 
			`log("UIWidgetHelper ProcessMouseEvent failure to process widget type." @self,,'uixcom');
	}
}

simulated private function ProcessMouseEvent_Combobox( int iTargetOption )
{
	local UIWidget_Combobox kCombobox; 
	local bool bValueChanged;

	bValueChanged = false;

	kCombobox = UIWidget_Combobox(m_arrWidgets[m_iCurrentWidget]);

	if( iTargetOption != -1 ) 
	{
		//Clicked an element in the listbox
		bValueChanged = (iTargetOption != kCombobox.iCurrentSelection);
		kCombobox.iCurrentSelection = iTargetOption;
		SetComboboxValue( m_iCurrentWidget,kCombobox.iCurrentSelection);
		if (bValueChanged && kCombobox.del_OnValueChanged != none)
			kCombobox.del_OnValueChanged();

		kCombobox.m_bComboBoxHasFocus = false;
	}
	else
	{
		//Clicked a top box area, either open or close.
		RealizeSelected();
		kCombobox.m_bComboBoxHasFocus = !kCombobox.m_bComboBoxHasFocus;
	}
	UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

simulated private function ProcessMouseEvent_Button( int iTargetBox )
{
	m_iCurrentWidget = iTargetBox;
	// TODO: what happens when mouse over a button?  
	RealizeSelected();

	if( !m_arrWidgets[m_iCurrentWidget].bIsDisabled && 
	 	 m_arrWidgets[m_iCurrentWidget].del_OnValueChanged != none)
	{
		m_arrWidgets[m_iCurrentWidget].del_OnValueChanged();
		UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
	else
		UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose); 
}

simulated private function ProcessMouseEvent_Checkbox( int iTargetOption )
{
	m_iCurrentWidget = iTargetOption;

	 if(!m_arrWidgets[m_iCurrentWidget].bIsDisabled)
		ToggleCheckbox( iTargetOption );

	RealizeSelected();

	UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}


simulated private function ProcessMouseEvent_List( int iTargetOption )
{
	SetListSelection( m_iCurrentWidget, iTargetOption );

	if( GetWidget(m_iCurrentWidget).del_OnValueChanged != none)
		GetWidget(m_iCurrentWidget).del_OnValueChanged();

	UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

simulated private function ProcessMouseEvent_Spinner( int iTargetBox )
{
	local UIWidget_Spinner spinner;
	spinner = UIWidget_Spinner(m_arrWidgets[m_iCurrentWidget]);
	if(spinner == none)
	{
		`warn("UI ERROR: Processing Mouse Event for Spinner. But 'm_arrWidgets[m_iCurrentWidget]' is not a UIWidget_Spinner.");
		return;
	}

	switch( iTargetBox )
	{
		case DECREASE_VALUE: 

			if(spinner.arrLabels.Length > 0)
			{
				spinner.iCurrentSelection--;
				if(spinner.iCurrentSelection < 0)
					spinner.iCurrentSelection = spinner.arrLabels.Length - 1;
				SetSpinnerValue(m_iCurrentWidget, spinner.arrLabels[spinner.iCurrentSelection]);
			}

			spinner.del_OnDecrease();
			if(spinner.del_OnValueChanged != none)
				spinner.del_OnValueChanged();
			break;

		case INCREASE_VALUE:

			if(spinner.arrLabels.Length > 0)
			{
				spinner.iCurrentSelection++;
				if(spinner.iCurrentSelection >= spinner.arrLabels.Length)
					spinner.iCurrentSelection = 0;
				SetSpinnerValue(m_iCurrentWidget, spinner.arrLabels[spinner.iCurrentSelection]);
			}

			spinner.del_OnIncrease();
			if(spinner.del_OnValueChanged != none)
				spinner.del_OnValueChanged();
			break;

	}
	UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

simulated private function ProcessMouseEvent_Slider( int iValue )
{
	local UIWidget_Slider kSlider; 
	
	kSlider = UIWidget_Slider(m_arrWidgets[m_iCurrentWidget]);

	switch( iValue )
	{
		case DECREASE_VALUE: 
			kSlider.del_OnDecrease();
			kSlider.iValue -= kSlider.iStepSize;
			if( kSlider.iValue < 0 ) kSlider.iValue = 0;
			RefreshSlider( m_iCurrentWidget );
			UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			
			if(kSlider.del_OnValueChanged != none)
				kSlider.del_OnValueChanged();
			break;

		case INCREASE_VALUE:
			kSlider.del_OnIncrease();
			kSlider.iValue += kSlider.iStepSize;
			if( kSlider.iValue > 100 ) kSlider.iValue = 100;
			RefreshSlider( m_iCurrentWidget );
			UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			
			if(kSlider.del_OnValueChanged != none)
				kSlider.del_OnValueChanged();
			break;

		default: 
			//Sending in raw percent 0<=n<=100
			//Cap the values 
			kSlider.iValue = iValue;
			if( kSlider.iValue > 100 ) kSlider.iValue = 100;
			if( kSlider.iValue < 0 ) kSlider.iValue = 0;
			
			if(kSlider.del_OnValueChanged != none)
				kSlider.del_OnValueChanged();
			break;
	}
}



//Checks to see if there is at least one active widget in m_arrWidgets.
//Used to prevent an infinite loop of all inactive widgets in the input sequence where we automatically skip inactive widgets. 
simulated function bool SafetyCheckForActiveWidgets()
{
	local int i;
	for( i=0; i< m_arrWidgets.Length; i++)
	{
		if( m_arrWidgets[i].bIsActive ) return true;
	}

	`log("Beware: Potential infinite loop detected if you send input to UIWidgetHelper("$ self $")."); 
	return false; 
}

// ----------------------------------------------------------------------------------
//                                     GENERAL
// ----------------------------------------------------------------------------------

simulated function RealizeSelected()
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	myValue.Type = AS_Number;
	myValue.n = m_iCurrentWidget;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSelected", myArray);
	
	UIPanel(Owner).PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
}
//Simply de-highlights the visuals; does not actually change the data selection.
simulated function Deselect()
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	myValue.Type = AS_Number;
	myValue.n = -1;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSelected", myArray);
}

simulated function int GetCurrentSelection()
{
	return m_iCurrentWidget; 
}

// Returns the stored value of the widget at specified index. 
simulated function int GetCurrentValue( int index  )
{
	local int iSelection; 
	local UIWidget_Combobox kCombobox; 
	local UIWidget_List kList; 

	switch( m_arrWidgets[index].eType )
	{
		case eWidget_Combobox:
			kComboBox = UIWidget_Combobox(m_arrWidgets[index]);
			iSelection = kComboBox.iCurrentSelection;
			if( index < m_arrWidgets.Length && iSelection <= kComboBox.arrValues.length )
			{
				return( kComboBox.arrValues[ iSelection ] );
			}
			else
			{
				`log("Problem with GetCurrentValue for combobox" @index,,'uixcom');
				return -1;
			}
			break;

		case eWidget_Button:
			return UIWidget_Button(m_arrWidgets[index]).iValue; 
			break;

		case eWidget_Checkbox:
			return int(UIWidget_Checkbox(m_arrWidgets[index]).bChecked); 
			break;

		case eWidget_Slider:
			return UIWidget_Slider(m_arrWidgets[index]).iValue; 
			break;

		case eWidget_Spinner:
			if(UIWidget_Spinner(m_arrWidgets[index]).arrLabels.Length > 0)
				return UIWidget_Spinner(m_arrWidgets[index]).arrValues[UIWidget_Spinner(m_arrWidgets[index]).iCurrentSelection];
			else
				return -1; //Spinner doesn't have a numeric value
			break;

		case eWidget_List:
			kList = UIWidget_List(m_arrWidgets[index]);
			iSelection = kList.iCurrentSelection;
			if( index < m_arrWidgets.Length && iSelection <= kList.arrValues.length )
			{
				return( kList.arrValues[ iSelection ] );
			}
			break;

		case eWidget_Invalid:
		default: 
			`log("UIWidgetHelper GetCurrentValue failure to process widget type." @self,,'uixcom');
			return -1;
	}
}

// Returns the stored value of the widget at specified index. 
simulated function string GetCurrentValueString( int index  )
{
	switch( m_arrWidgets[index].eType )
	{
		case eWidget_Spinner:
			return UIWidget_Spinner(m_arrWidgets[index]).strValue; 
			break;

		case eWidget_Invalid:
		default: 
			`log("UIWidgetHelper GetCurrentStringValue failure to process widget type." @self,,'uixcom');
			return "";
	}
}
// Returns the stored value of the widget at specified index. 
simulated function string GetCurrentLabel( int index  )
{
	local int iSelection; 
	local UIWidget_Combobox kCombobox; 
	local UIWidget_List kList; 

	switch( m_arrWidgets[index].eType )
	{
		case eWidget_Combobox:
			kComboBox = UIWidget_Combobox(m_arrWidgets[index]);
			iSelection = kComboBox.iCurrentSelection;
			if( index < m_arrWidgets.Length && iSelection <= kComboBox.arrLabels.length )
			{
				return( kComboBox.arrLabels[ iSelection ] );
			}
			else
			{
				`log("Problem with GetCurrentLabel for combobox" @index,,'uixcom');
				return "INVALID STRING";
			}
			break;

		case eWidget_Button:
			return UIWidget_Button(m_arrWidgets[index]).strTitle; 
			break;

		case eWidget_List:
			kList = UIWidget_List(m_arrWidgets[index]);
			iSelection = kList.iCurrentSelection;
			if( index < m_arrWidgets.Length && iSelection <= kList.arrLabels.length )
			{
				return( kList.arrLabels[ iSelection ] );
			}
			break;

		case eWidget_Checkbox:
			return UIWidget_Checkbox(m_arrWidgets[index]).strTitle; 
			break;

		case eWidget_Slider:
			return UIWidget_Slider(m_arrWidgets[index]).strTitle; 
			break;

		case eWidget_Spinner:
			return UIWidget_Slider(m_arrWidgets[index]).strTitle; 
			break;

		case eWidget_Invalid:
		default: 
			`log("UIWidgetHelper GetCurrentLabel failure to process widget type." @self,,'uixcom');
			return "INVALID STRING";
	}
}

simulated function Clear()
{
	m_arrWidgets.Length = 0; 
}

//Clears out internal data then refreshes the display for the targeted widget.
simulated function ClearWidget( int index )
{
	local UIWidget kWidget; 

	//Be sure to have a valid location, since this could be called before a widget has been created.
	if( index >= m_arrWidgets.Length) return; 

	kWidget = m_arrWidgets[index];

	switch( kWidget.eType )
	{
		case eWidget_Combobox:
			UIWidget_Combobox(kWidget).arrLabels.length = 0;
			UIWidget_Combobox(kWidget).arrValues.length = 0;
			break;

		case eWidget_Button:
			 UIWidget_Button(kWidget).strTitle = "";
			break;

		case eWidget_Checkbox:
			 UIWidget_Checkbox(kWidget).strTitle = "";
			 UIWidget_Checkbox(kWidget).bChecked = false;
			break;

		case eWidget_List:
			UIWidget_List(kWidget).arrLabels.Length = 0;
			UIWidget_List(kWidget).arrValues.Length = 0;
			break;
			
		case eWidget_Slider:
			UIWidget_Slider(m_arrWidgets[index]).strTitle = ""; 
			UIWidget_Slider(m_arrWidgets[index]).iValue = -1; 
			break;

		case eWidget_Spinner:
			UIWidget_Spinner(m_arrWidgets[index]).strTitle = ""; 
			UIWidget_Spinner(m_arrWidgets[index]).strValue = ""; 
			UIWidget_Spinner(m_arrWidgets[index]).arrLabels.Length = 0;
			UIWidget_Spinner(m_arrWidgets[index]).iCurrentSelection = 0;
			break;

		case eWidget_Invalid:
		default: 
			`log("UIWidgetHelper ClearWidget failure to process widget type." @self,,'uixcom');
	}

	RefreshWidget( index );
}

simulated function int GetNumWidgets()
{
	return m_arrWidgets.length;
}
simulated function UIWidget GetCurrentWidget()
{
	if( m_iCurrentWidget == -1 ) 
		return none;
	else
		return m_arrWidgets[m_iCurrentWidget];
}

simulated function SetSelected( int index )
{
	m_iCurrentWidget = index;
	RealizeSelected();
}

simulated function ClearSelection()
{
	m_iCurrentWidget = -1;
	RealizeSelected();
}

simulated function UIWidget GetWidget( int index )
{
	if( index > (m_arrWidgets.Length - 1) )
		return none;
	else
		return m_arrWidgets[index];
}

//Use this to modify the visibility "layout" of the buttons 
simulated function SetActive( int index, bool bIsActive )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	m_arrWidgets[index].bIsActive = bIsActive; 

	myValue.Type = AS_Boolean;
	myValue.b = bIsActive;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetActive", myArray);
}

//Use this to lock buttons (grey them out), prevent changed callbacks
simulated function DisableButton( int index )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	m_arrWidgets[index].bIsDisabled = true; 

	UIPanel(Owner).Invoke(MCName $"SetDisabledButton", myArray);
}

// Enable button
simulated function EnableButton( int index )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	m_arrWidgets[index].bIsDisabled = false; 

	UIPanel(Owner).Invoke(MCName $"SetEnabledButton", myArray);
}

// Works only if the widget has a read-only style. Only installed on checkboxes so far, 5/10/2013 bsteiner
simulated function SetReadOnly( int index, bool bReadOnly )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
	myValue.b = bReadOnly;
	myArray.AddItem( myValue );

	m_arrWidgets[index].bReadOnly = bReadOnly; 

	UIPanel(Owner).Invoke(MCName $"SetReadOnly", myArray);
}


simulated function RefreshWidget( int index )
{
	switch( m_arrWidgets[index].eType )
	{
		case eWidget_Combobox:
			RefreshComboBox( index );
			break;
		case eWidget_Button:
			RefreshButton( index );
			break;
		case eWidget_List:
			RefreshList( index );
			break;
		case eWidget_Spinner:
			RefreshSpinner( index );
			break;
		case eWidget_Slider:
			RefreshSlider( index );
			break;
		case eWidget_Checkbox:
			RefreshCheckbox( index );
			break;
		case eWidget_Invalid:
		default: 
			`log("UIWidgetHelper RefreshWidget() failure to process widget type." @self @"; index ="@index,,'uixcom');
	}
}

simulated function RefreshAllWidgets()
{
	local int i;
	for( i = 0; i < GetNumWidgets(); i++)
		RefreshWidget( i );
}

simulated function SelectInitialAvailable()
{
	local int i;
	for( i = 0; i < GetNumWidgets(); i++)
	{
		if( GetWidget(i).bIsActive ) 
		{
			SetSelected( i ); 
			return; 
		}
	}

	`log(self $ "::" $ GetFuncName() @ "can not find initial available widget for selection. Defaulting to zero.", true, 'uixcom');
	SetSelected( 0 ); 
}

// ----------------------------------------------------------------------------------
//                                     COMBOBOXES
// ----------------------------------------------------------------------------------

simulated function UIWidget_Combobox NewCombobox()
{
	local UIWidget_Combobox kCombobox;
	kCombobox = new(self) class'UIWidget_Combobox';	
	m_arrWidgets.AddItem(kCombobox);
	return kCombobox; 
}


simulated private function RefreshComboBox( int index )
{
	local UIWidget_Combobox kCombobox;

	kComboBox = UIWidget_Combobox(m_arrWidgets[index]);

	if(kCombobox == none ) return; 
	
	SetComboboxLabel( index, kCombobox.strTitle );
	SetComboboxText( index, kCombobox.arrLabels[kCombobox.iCurrentSelection] );
	SetDropdownOptions( index, kCombobox.arrLabels );
	
	//Refresh default selection
	if( kCombobox.iCurrentSelection < kCombobox.arrValues.Length ) //if it's in range of the values 
	{
		kCombobox.iBoxSelection = kCombobox.iCurrentSelection;
		SetComboboxValue( index, kCombobox.iCurrentSelection );
	}
	else
	{
		SetComboboxValue( index, kCombobox.arrValues.length ); //set to last element available 
	}
}

simulated private function SetComboboxLabel( int index, string strText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = strText;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetComboboxLabel", myArray);
}

simulated private function SetComboboxText( int index, string strText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = strText;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetComboboxText", myArray);
}


simulated function SetDropdownOptions( int index, array<string> arrLabels)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int i; 
	
	myValue.Type = AS_Number;
	myValue.n = index; 
	myArray.AddItem( myValue );

	//Process the labels into a comma/semi-colon delimited 2D array. 
	myValue.Type = AS_String;
	for (i = 0; i < arrLabels.Length; ++i)
	{
		myValue.s $= arrLabels[ i ] $ "," $ i;
		if (i < arrLabels.Length - 1)
			myValue.s $= ";";
	}
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetDropdownOptions", myArray);
}

//Sets the selection in the currently (open) list
simulated protected function SetDropdownSelection( int index, int iSelection )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );
	
	myValue.Type = AS_Number;
	myValue.n = iSelection;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetDropdownSelection", myArray);
}

// Pushes the selection and closes up the box. Used to push the value into this box. 
simulated protected function SetComboboxValue( int index, int iSelectionIndex )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	if( m_iCurrentWidget != -1  && UIWidget_Combobox(m_arrWidgets[m_iCurrentWidget]) != none )
		UIWidget_Combobox(m_arrWidgets[m_iCurrentWidget]).m_bComboBoxHasFocus = false;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );
	
	myValue.Type = AS_Number;
	myValue.n = iSelectionIndex;
	myArray.AddItem( myValue );
	
	`log("SetComboboxValue:" @index @iSelectionIndex ,,'uixcom');
	UIPanel(Owner).Invoke(MCName $"SetComboboxValue", myArray);
}

simulated protected function OpenCombobox( int index )
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	
	UIWidget_Combobox(m_arrWidgets[index]).m_bComboBoxHasFocus = true;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );
	
	UIPanel(Owner).Invoke(MCName $"OpenCombobox", myArray);
}

simulated protected function CloseCombobox( int index )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	UIWidget_Combobox(m_arrWidgets[index]).m_bComboBoxHasFocus = false;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );
	
	UIPanel(Owner).Invoke(MCName $"CloseCombobox", myArray);
}

simulated function CloseAllComboboxes ()
{
	local int i;

	for( i = 0; i < m_arrWidgets.Length; i++ )
	{
		if(m_arrWidgets[i].eType == eWidget_Combobox && m_arrWidgets[i].bIsActive)
		{
			//set the display selection so the actual selection shows
			UIWidget_Combobox(m_arrWidgets[i]).iCurrentSelection = UIWidget_Combobox(m_arrWidgets[i]).iBoxSelection;
			CloseCombobox(i);
			RefreshComboBox(i);
		}
	}
}

// ----------------------------------------------------------------------------------
//                                     BUTTONS
// ----------------------------------------------------------------------------------

simulated function UIWidget_Button NewButton()
{
	local UIWidget_Button kButton;

	kButton = new(self) class'UIWidget_Button';	
	m_arrWidgets.AddItem(kButton);

	return kButton; 
}

simulated private function RefreshButton( int index )
{
	local UIWidget_Button kButton;

	kButton = UIWidget_Button(m_arrWidgets[index]);	
	
	if(kButton == none) return; 

	SetButtonLabel( index, kButton.strTitle );
}

simulated private function SetButtonLabel( int index, string strText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = strText;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetButtonLabel", myArray);
}


// ----------------------------------------------------------------------------------
//                                     CHECKBOX
// ----------------------------------------------------------------------------------

simulated function UIWidget_Checkbox NewCheckbox(optional int textStyle = 0)
{
	local UIWidget_Checkbox kCheckbox;

	kCheckbox = new(self) class'UIWidget_Checkbox';	
	kCheckbox.iTextStyle = textStyle;
	m_arrWidgets.AddItem(kCheckbox);

	return kCheckbox; 
}

simulated function ToggleCheckbox( int index )
{
	SetCheckboxValue(index, !UIWidget_Checkbox(m_arrWidgets[index]).bChecked);
}

simulated function SetCheckboxValue( int index, bool bChecked)
{
	local UIWidget_Checkbox kCheckbox;

	kCheckbox = UIWidget_Checkbox(m_arrWidgets[index]);	
	
	if(kCheckbox == none) return; 
	if(kCheckbox.bReadOnly) return; 

	if(kCheckbox.bChecked != bChecked)
	{
		kCheckbox.bChecked = bChecked;
		RefreshCheckbox( index );

		kCheckbox.del_OnValueChanged();
	}
}

simulated private function RefreshCheckbox( int index )
{
	local UIWidget_Checkbox kCheckbox;

	kCheckbox = UIWidget_Checkbox(m_arrWidgets[index]);	
	
	if(kCheckbox == none) return; 

	AS_SetCheckboxLabel( index, kCheckbox.strTitle );
	AS_SetCheckboxValue( index, kCheckbox.bChecked );
	AS_SetCheckboxStyle( index, kCheckbox.iTextStyle );
	SetReadOnly(index, kCheckbox.bReadOnly );
}

simulated private function AS_SetCheckboxLabel( int index, string strText ) {
	UIPanel(Owner).Movie.ActionScriptVoid(GetASFuncPath("SetCheckboxLabel"));
}

simulated private function AS_SetCheckboxValue( int index, bool bChecked ) {
	UIPanel(Owner).Movie.ActionScriptVoid(GetASFuncPath("SetCheckboxValue"));
}

// style 0 == label to the left of the checkbox (default)
// style 1 == label to the right of the checkbox
simulated private function AS_SetCheckboxStyle( int index, int style ) {
	UIPanel(Owner).Movie.ActionScriptVoid(GetASFuncPath("SetCheckboxStyle"));
}


// ----------------------------------------------------------------------------------
//                                     LIST
// ----------------------------------------------------------------------------------

simulated function UIWidget_List NewList()
{
	local UIWidget_List kList;

	kList = new(self) class'UIWidget_List';	
	m_arrWidgets.AddItem(kList);

	return kList; 
}

simulated function SetListOptions( int index, array<string> arrLabels)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local int i; 

	myValue.Type = AS_Number;
	myValue.n = index; 
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = "";
	if( arrLabels.Length > 0 )
	{
		//Process the labels into a comma/semi-colon delimited 2D array. 
		for (i = 0; i < arrLabels.Length; ++i)
		{
			myValue.s @= arrLabels[ i ] $ "," $ i;
			if (i < arrLabels.Length - 1)
				myValue.s @= ";";
		}
	}
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetListOptions", myArray);
}

simulated public function SetListSelection( int index, int iSelection)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local UIWidget_List kList; 

	kList = UIWidget_List( GetWidget(index) );

	//Save the value: 
	kList.iCurrentSelection = iSelection; 

	if( !kList.m_bHasFocus ) // this is deactivated , so reactivate correctly 
	{
		kList.m_bHasFocus = true;

		if( m_eDirection == eNavDir_Up )
			kList.iCurrentSelection = kList.arrLabels.Length-1; 
		else if( m_eDirection == eNavDir_Down )
			kList.iCurrentSelection = 0; 
	}
	
	//Process wrapping and directional entrance to the list, if necessary. 
	// Check for endcaps 
	if( kList.iCurrentSelection < 0 )
	{
		if( m_eDirection == eNavDir_Up )
		{
			if( kList.m_bWrap )
			{
				kList.iCurrentSelection = kList.arrLabels.Length-1; 
			}
			else
			{

				kList.m_bHasFocus = false;
				SelectPrevAvailableWidget();
			}
		}
		else if( m_eDirection == eNavDir_Down && kList.arrLabels.Length > 0 )
		{
			kList.iCurrentSelection = 0;
		}

	}
	else if( kList.iCurrentSelection >= kList.arrLabels.Length )
	{
		if( m_eDirection == eNavDir_Down )
		{
			if( kList.m_bWrap )
			{
				kList.iCurrentSelection = 0; 
			}
			else
			{
				kList.m_bHasFocus = false;
				SelectNextAvailableWidget();
			}
		}
	}

	if(kList.iCurrentSelection == -1 || kList.arrLabels.Length > 0 )
	{
		//Update the display 
		myValue.Type = AS_Number;
		myValue.n = index;
		myArray.AddItem( myValue );	

		myValue.Type = AS_Number;
		myValue.n = kList.iCurrentSelection; 
		myArray.AddItem( myValue );

		//`log("SetListSelection: " @ kList.iCurrentSelection @", " @ iSelection);
		UIPanel(Owner).Invoke(MCName $"SetListSelection", myArray);
	}

	if(kList.del_OnSelectionChanged != none)
		kList.del_OnSelectionChanged(kList.iCurrentSelection);
}

simulated private function RefreshList( int index )
{
	local UIWidget_List kList; 
	
	kList = UIWidget_List(GetWidget( index ));

	SetListOptions( index, kList.arrLabels );
	SetListSelection( index, kList.iCurrentSelection );
}

// Used for direct update of the text on a list item within a list. 
simulated function SetListItemText( int iWidgetIndex, int iItemIndex, string displayString )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = iWidgetIndex; 
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = iItemIndex; 
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = displayString; 
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetListItemText", myArray);
}


// ----------------------------------------------------------------------------------
//                                     SPINNER
// ----------------------------------------------------------------------------------

simulated function UIWidget_Spinner NewSpinner()
{
	local UIWidget_Spinner kSpinner;

	kSpinner = new(self) class'UIWidget_Spinner';	
	m_arrWidgets.AddItem(kSpinner);

	return kSpinner; 
}

simulated protected function RefreshSpinner( int index )
{
	local UIWidget_Spinner kSpinner;

	kSpinner = UIWidget_Spinner(m_arrWidgets[index]);	
	
	if(kSpinner == none) return; 

	if( kSpinner.bIsActive )
	{
		if( kSpinner.bIsHorizontal ) //There isn't an autolabel for a vertical spinner 
			SetSpinnerLabel( index, kSpinner.strTitle );

		if(kSpinner.arrLabels.Length > 0)
			SetSpinnerValue( index, kSpinner.arrLabels[kSpinner.iCurrentSelection]  );
		else
			SetSpinnerValue( index, kSpinner.strValue );
	}
	SetSpinnerArrows( index, kSpinner.bCanSpin );
}

simulated protected function SetSpinnerLabel( int index, string strText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = strText;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSpinnerLabel", myArray);
}

simulated protected function SetSpinnerValue( int index, string strValue)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = strValue;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSpinnerValue", myArray);
}

simulated private function SetSpinnerArrows( int index, bool bCanSpin)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_Boolean;
	myValue.b = bCanSpin;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSpinnerArrows", myArray);
}

// ----------------------------------------------------------------------------------
//                                     SLIDER
// ----------------------------------------------------------------------------------

simulated function UIWidget_Slider NewSlider()
{
	local UIWidget_Slider kSlider;

	kSlider = new(self) class'UIWidget_Slider';	
	m_arrWidgets.AddItem(kSlider);

	return kSlider; 
}

simulated protected function RefreshSlider( int index )
{
	local UIWidget_Slider kSlider;

	kSlider = UIWidget_Slider(m_arrWidgets[index]);	
	
	if(kSlider == none) return; 

	SetSliderLabel( index, kSlider.strTitle );
	SetSliderValue( index, kSlider.iValue );
	SetSliderMouseWheelStep( index, kSlider.iStepSize );
}

simulated private function SetSliderLabel( int index, string strText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_String;
	myValue.s = strText;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSliderLabel", myArray);
}

simulated private function SetSliderValue( int index, int iValue)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = iValue;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSliderValue", myArray);
}

simulated private function SetSliderMouseWheelStep( int index, int iValue)
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_Number;
	myValue.n = index;
	myArray.AddItem( myValue );

	myValue.Type = AS_Number;
	myValue.n = iValue;
	myArray.AddItem( myValue );

	UIPanel(Owner).Invoke(MCName $"SetSliderMouseWheelStep", myArray);
}

// Helper function to get path that gets passed into ActionscriptVoid calls.
simulated function string GetASFuncPath(string func) {
	return UIPanel(Owner).MCPath $ "." $ MCName $ func;
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	s_widgetName = "option"; 
	MCName = "widgetHelper."; 
	m_eDirection = eNavDir_None;
}

