//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIList_SquadEditor.uc
//  AUTHOR:  Jake Akemann
//  PURPOSE: This extends UIList, handling functionality for UISquadSelect_ListItem
//----------------------------------------------------------------------------

class UIList_SquadEditor extends UIList;

simulated function OnInit()
{
	Super.OnInit();
	InitPosition();
}

//centers the squad list
simulated function InitPosition()
{
	local int AnchorOffSetX;

	AnchorOffSetX = X;
	AnchorBottomCenter();
	SetX(-Width / 2.0 + AnchorOffSetX);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;
	
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A :
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
			HandleControllerSelect();
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			ShiftFocus(FALSE);
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER :
		case class'UIUtilities_Input'.const.FXS_KEY_TAB :
			ShiftFocus(TRUE);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN :
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
			ShiftFocusVertical(TRUE);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP :
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
			ShiftFocusVertical(FALSE);
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT :
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT :
			if (!ShiftFocusHorizontal(FALSE))
			{
				ShiftFocus(false);
			}

			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT :
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT :
			if (!ShiftFocusHorizontal(TRUE))
			{
				ShiftFocus(true);
			}

			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//Finds the next available index (looping if it moves out of bounds)
simulated function INT LoopListItemIndex(INT Index, Bool bDownward)
{
	Index = bDownward ? Index + 1 : Index - 1;
	if(Index < 0)
		Index = ItemCount - 1;
	Index = Index % ItemCount;

	return Index;
}

//cycles through ListItems and returns the first one that is focused
//(note: if the mouse is allowed with the controller, there may be more than one focused at a time)
simulated function UISquadSelect_ListItem GetActiveListItem()
{
	local UISquadSelect_ListItem ListItem;
	local int Index;

	//attempts to return the first item found that is in focus
	for(Index = 0; Index < ItemCount; ++Index)
	{
		ListItem = UISquadSelect_ListItem(GetItem(Index));
		if(ListItem != None && ListItem.bIsFocused)
			return ListItem;
	}

	//attempts to return the first item found that is not disabled (used for finding the initial focus)
	for(Index = 0; Index < ItemCount; ++Index)
	{
		ListItem = UISquadSelect_ListItem(GetItem(Index));
		if(ListItem != None && !ListItem.bDisabled)
			return ListItem;
	}

	//should never hit this point as there will always be non-disabled listItems in-game
	return UISquadSelect_ListItem(GetItem(0));
}

//The list items are normally given focus using only "mouseover" events set in actionscript, this function simulates that if the player is using a controller
simulated function ShiftFocus(Bool bForward)
{
	local UISquadSelect_ListItem ListItem, PrevListItem;
	local int Index;

	PrevListItem = GetActiveListItem();
	Index = GetItemIndex(PrevListItem);

	//Focused ListItem was found
	if(PrevListItem != None)
	{
		//Remove Current Focus
		PrevListItem.OnLoseFocus();

		//Find index of next ListItem in sequence
		do
		{
			Index = LoopListItemIndex(Index, bForward);
			ListItem = UISquadSelect_ListItem(GetItem(Index));
		}
		until ( ListItem != None && !ListItem.bDisabled );

		//Give next ListItem focus
		ListItem.OnReceiveFocus();
		//attempts to give focus the same button that focus on the previous list item
		//if that button is the utility list, !bForward  tells it that it should give focus to the utility item on the right side
		ListItem.HandleButtonFocus(PrevListItem.m_eActiveButton, !bForward);

		SelectedIndex = Index;
	}
}

//while a Listitem is in focus, this function simulates the player hovering their mouse over specific buttons contained within the ListItem
simulated function ShiftFocusVertical(Bool bDownward)
{
	local UISquadSelect_ListItem ListItem;

	ListItem = GetActiveListItem();
	if(ListItem != None)
		ListItem.ShiftButtonFocus(bDownward);
}

//cycles through the utility items while the player is focused on that them
simulated function bool ShiftFocusHorizontal(Bool bIncreasing)
{
	local UISquadSelect_ListItem ListItem;

	ListItem = GetActiveListItem();
	if(ListItem != None)
		return ListItem.ShiftHorizontalFocus(bIncreasing);
	return false;
}

//marks the currently selected list item as dirty (if it exists)
simulated function MarkActiveListItemAsDirty()
{
	/*local UISquadSelect_ListItem ListItem;

	ListItem = GetActiveListItem();
	//if(ListItem != None)
	//	ListItem.bDirty = true;
	*/
}

simulated function MarkAllListItemsAsDirty()
{
	/*local UISquadSelect_ListItem ListItem;
	local int i;

	for(i = 0; i<ItemCount; i++)
	{
		ListItem = UISquadSelect_ListItem(GetItem(i));
		if(ListItem != None)
			ListItem.bDirty = true;
	}*/
}

//simulates a mouse click by determining which button is focused on the listItem
simulated function HandleControllerSelect()
{
	local UISquadSelect_ListItem ListItem;

	ListItem = GetActiveListItem();
	if(ListItem != None)
		ListItem.HandleButtonSelect();
}

defaultproperties
{
}