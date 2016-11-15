//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_Voice.uc
//  AUTHOR:  Jake Akemann --  2/3/2016
//  PURPOSE: Extends the Customize_Trait class to incorporate voice-specific navhelp and controls
//---------------------------------------------------------------------------------------

class UICustomize_Voice extends UICustomize_Trait;

var protectedwrite String m_strPreviewLabel;

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function UpdateTrait( string _Title, 
							  string _Subtitle, 
							  array<string> _Data, 
							  delegate<OnItemSelectedCallback> _onSelectionChanged,
							  delegate<OnItemSelectedCallback> _onItemClicked,
							  optional delegate<IsSoldierEligible> _checkSoldierEligibility,
							  optional int _startingIndex = -1, 
							  optional string _ConfirmButtonLabel,
							  optional delegate<OnItemSelectedCallback> _onConfirmButtonClicked )
{
	m_strPreviewLabel = _ConfirmButtonLabel;

	//removes the confirmation buttons (will show those via NavHelp)
	Super.UpdateTrait(_Title,_Subtitle,_Data,_onSelectionChanged,_onItemClicked,_checkSoldierEligibility,_startingIndex);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch(cmd)
	{		
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			PreviewVoice();
			return true;
		default:
			break;			
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function UpdateNavHelp()
{
	Super.UpdateNavHelp();

	NavHelp.AddLeftHelp(m_strPreviewLabel, class'UIUtilities_Input'.const.ICON_X_SQUARE);
}

simulated function PreviewVoice()
{
	//ConfirmButtonClicked(None);
	CustomizeManager.OnCategoryValueChange( eUICustomizeCat_Voice, 0, List.SelectedIndex ); 
}

//==============================================================================

defaultproperties
{
}
