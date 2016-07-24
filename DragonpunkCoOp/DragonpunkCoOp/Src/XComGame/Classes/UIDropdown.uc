//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDropdown.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIDropdown that controls a UI dropdown widget.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIDropdown extends UIPanel;

var string		 Label;
var string		 Description;
var array<string> Items;
var array<string> Data;
var int			 SelectedItem;
var bool			 AllItemsLoaded;
var bool			 IsOpen;
var bool			 OpenOnHover;

var delegate<OnItemsLoadedCallback> OnItemsLoadedDelegate;
var delegate<OnSelectionChangedCallback> OnItemSelectedDelegate;

delegate OnItemsLoadedCallback(UIDropdown DropdownControl);
delegate OnSelectionChangedCallback(UIDropdown DropdownControl);

simulated function UIDropdown InitDropdown(optional name InitName, optional string startingLabel, optional delegate<OnSelectionChangedCallback> itemSelectedDelegate)
{
	InitPanel(InitName);
	SetLabel(startingLabel);

	if(itemSelectedDelegate != none) 
		onItemSelectedDelegate = itemSelectedDelegate;
	return self;
}

simulated function UIDropdown SetLabel(string newLabel)
{
	if(label != newLabel)
	{
		label = newLabel;
		mc.FunctionString("setButtonLabel", label);
	}
	return self;
}

simulated function UIDropdown SetDescription(string newDescription)
{
	if(description != newDescription)
	{
		description = newDescription;
		mc.FunctionString("setButtonText", description);
	}
	return self;
}

// example of function with custom params
public function UIDropdown AddItem(string itemText, optional string itemData)
{
	mc.BeginFunctionOp("AddListItem");
	mc.QueueNumber(float(items.Length));
	mc.QueueString(itemText);
	mc.EndOp();
	
	Items.AddItem(itemText);                 // store item text in case we need to access it later
	Data.AddItem(itemData);

	if(SelectedItem < 0 || SelectedItem >= Items.Length)
	{
		SelectedItem = 0;
	}

	return self;
}

simulated function UIDropdown SetSelected(int itemIndex)
{
	if(selectedItem != itemIndex)
	{
		selectedItem = itemIndex;
		
		// setting selection before all items are loaded doesn't do anything
		if(allItemsLoaded)
		{
			mc.FunctionNum("setSelected", itemIndex);
		}
	}
	return self;
}

simulated function string GetSelectedItemText()
{
	return Items[SelectedItem];
}

simulated function string GetSelectedItemData()
{
	return Data[SelectedItem];
}

simulated function string GetItemText(int itemIndex)
{
	return Items[itemIndex];
}

simulated function UIDropdown Open()
{
	if(!isOpen)
	{
		// close all other dropdowns
		class'UIUtilities_Controls'.static.CloseAllDropdowns(screen);

		isOpen = true;
		//mc.FunctionBool("playListboxAnim", isOpen);
	}
	return self;
}

simulated function UIDropdown Close()
{
	if(isOpen)
	{
		isOpen = false;
		//mc.FunctionBool("playListboxAnim", isOpen);
	}
	return self;
}

simulated function UIDropdown Clear()
{
	Close();
	SelectedItem = -1;
	if(Items.Length > 0)
	{
		Items.Length = 0;
		Data.Length = 0;
		allItemsLoaded = false;
		mc.FunctionVoid("clearList");
	}
	return self;
}

simulated function UIDropdown HideButton()
{
	mc.FunctionVoid("hideButton");
	return self;
}

simulated function UIDropdown ShowButton()
{
	mc.FunctionVoid("showButton");
	return self;
}

simulated function OnCommand(string cmd, string arg)
{
	if(cmd == "allItemsLoaded")
	{
		allItemsLoaded = true;

		// refresh selection if it was set before items were loaded
		if(selectedItem != class'UIDropdown'.default.selectedItem)
			mc.FunctionNum("setSelected", selectedItem);
		else
			mc.FunctionNum("setSelected", 0);

		if(onItemsLoadedDelegate != none)
			onItemsLoadedDelegate(self);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local int selIdx;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			if(isOpen)
				Close();
			else
				Open();
			return true;
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
			if(isOpen)
			{
				selIdx = selectedItem - 1;
				if ( selIdx < 0 )
					selIdx = Items.Length - 1;

				SetSelected(selIdx);
				if(onItemSelectedDelegate != none)
					onItemSelectedDelegate(self);
				return true;
			}
			break;
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
			if(isOpen)
			{
				selIdx = (selectedItem + 1) % Items.Length;
				SetSelected(selIdx);
				if(onItemSelectedDelegate != none)
					onItemSelectedDelegate(self);
				return true;
			}
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int selectedIndex;

	// send a clicked callback
	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		if(args[args.Length - 1] == "theButton")
		{
			if(isOpen)
				Close();
			else
				Open();
		}
		else
		{
			selectedIndex = int(args[args.Length - 1]);
			if(selectedIndex != -1)
			{
				Close();
				SetSelected(selectedIndex);
				if(onItemSelectedDelegate != none)
					onItemSelectedDelegate(self);
			}
		}
	}
	super.OnMouseEvent(cmd, args);
}

defaultproperties
{
	label = "undefined"; // this forces the SetLabel call to go through with the empty string
	selectedItem = -1;
	LibID = "DropdownControl";
	bProcessesMouseEvents = true;
}
