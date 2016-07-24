//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_Trait.uc
//  AUTHOR:  Brit Steiner --  9/4/2014
//  PURPOSE: EditTrait menu in the character pool system. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize_Trait extends UICustomize;

//----------------------------------------------------------------------------
// MEMBERS

// UI
var array<string> Data; 
var public string Title;
var public string Subtitle;
var public int StartingIndex;

var delegate<OnItemSelectedCallback> OnSelectionChanged;
var delegate<OnItemSelectedCallback> OnItemClicked;
var delegate<OnItemSelectedCallback> OnConfirmButtonClicked;

delegate OnItemSelectedCallback(UIList _list, int itemIndex);

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
}

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
	local int i;
	local UIMechaListItem ListItem;
	local int currentSel;
	currentSel = _startingIndex != -1 ? _startingIndex : List.SelectedIndex;

	super.UpdateData();

	Data = _Data;
	List.OnSelectionChanged = _onSelectionChanged;
	List.OnItemClicked = OnClickLocal;
	List.OnItemDoubleClicked = OnDoubleClickLocal;
	//List.ItemPadding = 0; // List item height already accounts for padding
	OnItemClicked = _onItemClicked;
	IsSoldierEligible = _checkSoldierEligibility;
	StartingIndex = _startingIndex;
	OnConfirmButtonClicked = _onConfirmButtonClicked;
	
	if(List.itemCount > Data.length)
		List.ClearItems();

	//while(List.itemCount < Data.length)
	//	Spawn(class'UIListItemString', List.itemContainer).InitListItem();
	
	for( i = 0; i < Data.Length; i++ )
	{
		ListItem = GetListItem(i);
		ListItem.SetWidth(List.Width);
		if( ListItem != none )
		{
			if( _ConfirmButtonLabel != "" )
			{
				ListItem.UpdateDataButton(Data[i], _ConfirmButtonLabel, ConfirmButtonClicked);
				//ListItemString.SetConfirmButtonStyle(eUIConfirmButtonStyle_Default, _ConfirmButtonLabel, , , ConfirmButtonClicked);
			}
			else
			{
				ListItem.UpdateDataDescription(Data[i]);

			}
		}
	}

	if (currentSel > -1 && currentSel < List.ItemCount)
	{
		List.Navigator.SetSelected(List.GetItem(currentSel));
	}
	else
	{
		List.Navigator.SetSelected(List.GetItem(0));
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
			OnClickLocal(List, List.SelectedIndex);
			break;		

		default:
			break;			
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function ConfirmButtonClicked(UIButton Button)
{
	if(List.SelectedIndex != -1 && OnConfirmButtonClicked != none)
		OnConfirmButtonClicked(List, List.SelectedIndex);
}

simulated function OnCancel()
{
	if(StartingIndex != -1 && OnItemClicked != none)
		OnItemClicked(List, StartingIndex);
	super.OnCancel();
}

simulated function OnClickLocal(UIList _list, int itemIndex)
{
	OnItemClicked(_list, itemIndex);
	CloseScreen();
}

simulated function OnDoubleClickLocal(UIList _list, int itemIndex)
{
	OnItemClicked(_list, itemIndex);
	CloseScreen();
}

//==============================================================================

defaultproperties
{
}
