//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIWidgetHelper_Table.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Library of helper elements used for simple table of widgets navigation. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIWidgetHelper_Table extends UIWidgetHelper;

var private int m_iCurrentRow;
var private int m_iCurrentCol;

var private int m_iNumRows;
var private int m_iNumCols;

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
	
	if( !bHandled )
		bHandled = super.OnUnrealCommand( cmd, arg ); 

	return bHandled;
}

simulated private function bool OnUnrealCommand_Combobox( int cmd, int arg )
{
	local bool bHandled;//, bNav;
	local UIWidget_Combobox kCombobox; 
	//local int iOpenIndex; 

	bHandled = true;
	
	kCombobox = UIWidget_Combobox(m_arrWidgets[m_iCurrentWidget]);
	//iOpenIndex = m_iCurrentWidget; 

	switch( cmd )
	{

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_KEY_D:
			if(kCombobox.m_bComboBoxHasFocus)
			{
				/*kCombobox.iCurrentSelection = kCombobox.iBoxSelection;
				SetComboboxValue( iOpenIndex,kCombobox.iCurrentSelection);
				CloseCombobox( iOpenIndex );
				UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);*/
			}
			else
			{
				SelectNextAvailableWidget_Right();
			}
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_KEY_A:
			if(kCombobox.m_bComboBoxHasFocus)
			{
				/*kCombobox.iCurrentSelection = kCombobox.iBoxSelection;
				SetComboboxValue( iOpenIndex, kCombobox.iCurrentSelection);
				CloseCombobox( iOpenIndex );
				UIPanel(Owner).Movie.Pres.PlayUISound(eSUISound_MenuClose);*/
			}
			else
			{
				SelectNextAvailableWidget_Left();
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
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_KEY_D:
			SelectNextAvailableWidget_Right();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_KEY_A:
			SelectNextAvailableWidget_Left();
			break;

		default:
			bHandled = false;
			break;
	}
	return bHandled; 
}

simulated private function bool OnUnrealCommand_Spinner( int cmd, int arg )
{
	//If you put a spinner in a table, you need to figure out how to handle it. Not intended to be used.
	return false; 
}

simulated private function bool OnUnrealCommand_Slider( int cmd, int arg )
{
	//If you put a slider in a table, you need to figure out how to handle it. Not intended to be used.
	return false; 
}

simulated private function bool OnUnrealCommand_Checkbox( int cmd, int arg )
{
	local bool bHandled;
	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_KEY_D:
			SelectNextAvailableWidget_Right();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_KEY_A:
			SelectNextAvailableWidget_Left();
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
	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_KEY_D:
			SelectNextAvailableWidget_Right();
			break;

		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_KEY_A:
			SelectNextAvailableWidget_Left();
			break;

		default:
			bHandled = false;
			break;
	}
	return bHandled; 
}

private function bool SelectNextAvailableWidget_Right()
{
	local int iCurrent;
	iCurrent = m_iCurrentWidget;

	if( SafetyCheckForActiveWidgets() )
	{
		do
		{
			iCurrent += m_iNumRows; 
			//horizontal wrapping
			if( iCurrent > m_arrWidgets.Length-1 ) 
			{
				iCurrent = (iCurrent) % m_arrWidgets.length;
			}

		} until (  m_arrWidgets[iCurrent].bIsActive );
	}

	// If a change occurred.
	if ( iCurrent != m_iCurrentWidget )
	{
		m_iCurrentWidget = iCurrent;
		RefreshWidget( m_iCurrentWidget );
		RealizeSelected();
		return true;
	}
	else
	{
		return false;
	}
}

private function bool SelectNextAvailableWidget_Left()
{
	local int iCurrent, iTemp;
	iCurrent = m_iCurrentWidget;

	if( SafetyCheckForActiveWidgets() )
	{
		do
		{
			iCurrent -= m_iNumRows; 	
			//horizontal wrapping
			if( iCurrent < 0 ) 
			{
				iTemp = m_arrWidgets.length + iCurrent; //where iCurrent is negative to start with 
				iCurrent = iTemp;
			}
		} until ( m_arrWidgets[iCurrent].bIsActive );
	}

	// If a change occurred.
	if ( iCurrent != m_iCurrentWidget )
	{
		m_iCurrentWidget = iCurrent;
		RefreshWidget( m_iCurrentWidget );
		RealizeSelected();
		return true; 
	}
	else
	{
		return false;
	}
}


protected function SelectNextAvailableWidget()
{
	local int iCurrent, itemp, iWrap;
	iCurrent = m_iCurrentWidget;

	if( SafetyCheckForActiveWidgets() )
	{
		do
		{
			//Change selection to prev widget 
			iCurrent = iCurrent + 1;
			iWrap = iCurrent % m_iNumRows;
			if( iCurrent > m_arrWidgets.Length-1  ) // catch going out of the last column
			{
				//This temp var is used because UnrealScript is crazy. 
				iTemp =  iCurrent - m_iNumRows;
				iCurrent = iTemp;
			}
			else if ( iWrap == 0  ) //Wrap columns 
			{
				//This temp var is used because UnrealScript is crazy. 
				iTemp = iCurrent - m_iNumRows;
				iCurrent = iTemp;
			}
		} until ( m_arrWidgets[iCurrent].bIsActive );
	}

	// If a change occurred.
	if ( iCurrent != m_iCurrentWidget )
	{
		m_iCurrentWidget = iCurrent;
		RefreshWidget( m_iCurrentWidget );
		RealizeSelected();
	}
}

protected function SelectPrevAvailableWidget()
{
	local int iCurrent, iTemp, iWrap;
	iCurrent = m_iCurrentWidget;

	if( SafetyCheckForActiveWidgets() )
	{
		do
		{
			//Change selection to prev widget 
			iCurrent = iCurrent - 1;
			iWrap = iCurrent % m_iNumRows;
			if( iCurrent < 0 ) // catch zero in first column 
			{
				//This temp var is used because UnrealScript is crazy. 
				iTemp = m_iNumRows + iCurrent;
				iCurrent = iTemp;
			}
			else if ( iWrap == m_iNumRows - 1 ) //Wrap columns 
			{
				//This temp var is used because UnrealScript is crazy. 
				iTemp = m_iNumRows + iCurrent;
				iCurrent = iTemp;
			}
		} until ( m_arrWidgets[iCurrent].bIsActive );
	}

	// If a change occurred.
	if ( iCurrent != m_iCurrentWidget )
	{
		m_iCurrentWidget = iCurrent;
		RefreshWidget( m_iCurrentWidget );
		RealizeSelected();
	}
}


public function SetTable( int rows, int cols )
{
	m_iNumRows = rows;
	m_iNumCols = cols; 
} 

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_iCurrentRow = -1;
	m_iCurrentCol = -1;

	m_iNumRows = -1;
	m_iNumCols = -1;
}

