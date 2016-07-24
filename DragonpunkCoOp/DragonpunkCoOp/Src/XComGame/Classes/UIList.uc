//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIList.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIPanel to that automatically positions its elements and adds a Scrollbar if necessary.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIList extends UIPanel;

// IMPOTRTANT: list items must be owned by the ItemContainer - ex: Spawn(class'UIPanel', list.ItemContainer);
var UIPanel				ItemContainer;
var UIBGBox  			BG;		          // optional (pass true to 'addBG' parameter of InitList)
var UIMask				Mask;			  // only gets spawned if necessary
var UIScrollbar			Scrollbar;		  // only gets spawned if necessary

var public int				            ItemPadding;
var public bool					        bStickyHighlight;
var public bool					        bSelectFirstAvailable;
var public bool					        bCenterNoScroll;   // centers the list items in the display area if no Scrollbar is necessary
var public bool		        			bAutosizeItems;
var bool					bIsHorizontal;
var bool					bShrinkToFit;
var int				    ItemCount;
var int					SelectedIndex;
var public int					        BGPaddingLeft;        // if BG is not none, this value will get added to width / height when calling GetTotalWidth() / GetTotalHeight()
var public int					        BGPaddingRight;        // if BG is not none, this value will get added to width / height when calling GetTotalWidth() / GetTotalHeight()
var public int					        BGPaddingTop;        // if BG is not none, this value will get added to width / height when calling GetTotalWidth() / GetTotalHeight()
var public int					        BGPaddingBottom;  
var int					ScrollbarPadding; // if Scrollbar is not none, this value will get added to width / height when calling GetTotalWidth() / GetTotalHeight()
var float				TotalItemSize;

var delegate<OnItemSelectedCallback>    OnSelectionChanged;
var delegate<OnItemSelectedCallback>    OnItemClicked;
var delegate<OnItemSelectedCallback>    OnItemDoubleClicked; // this must be triggered from UIControls within this

delegate OnChildMouseEventDelegate(UIPanel Panel, int Cmd);
delegate OnItemSelectedCallback(UIList ContainerList, int ItemIndex);

simulated function UIList InitList( optional name InitName, 
									optional float initX, optional float initY, 
									optional float initWidth, optional float initHeight, 
									optional bool horizontalList, optional bool addBG, optional name bgLibID )
{
	InitPanel(InitName);

	SetPosition(initX, initY);
	SetSize(initWidth, initHeight);
	bIsHorizontal = horizontalList;

	if(addBG)
	{
		// BG must be added before ItemContainer so it draws underneath it
		BG = Spawn(class'UIBGBox', self);
		BG.bAnimateOnInit = bAnimateOnInit;
		BG.bIsNavigable = false;
		if(bgLibID != '') BG.LibID = bgLibID;
		BG.InitBG('BGBox', -(BGPaddingLeft), -(BGPaddingTop), width+BGPaddingLeft+BGPaddingRight, height+BGPaddingTop+BGPaddingBottom);
		BG.ProcessMouseEvents(OnChildMouseEvent);
		BG.bShouldPlayGenericUIAudioEvents = false; 
	}

	CreateItemContainer();
	return self;
}

simulated function CreateItemContainer()
{
	ItemContainer = Spawn(class'UIPanel', self);
	ItemContainer.bAnimateOnInit = bAnimateOnInit;
	ItemContainer.onChildAdded = ItemAdded;
	ItemContainer.onChildRemoved = ItemRemoved;
	ItemContainer.bCascadeFocus = false;
	ItemContainer.bIsNavigable = false;
	ItemContainer.InitPanel('ListItemContainer');

	// HAX: items are contained within ItemContainer, so our Navigator must reference the container's Navigator
	Navigator = ItemContainer.Navigator.InitNavigator(self); // set owner to be self;

	// Remove the container so its not part of the navigation cycle
	Navigator.RemoveControl(ItemContainer);

	Navigator.OnSelectedIndexChanged = NavigatorSelectionChanged;
	Navigator.LoopSelection = true;
}

// Create a UIPanel of the specified type and add it to the ItemContainer.
simulated function UIPanel CreateItem(optional class<UIPanel> ItemClass = class'UIListItemString')
{
	return Spawn(ItemClass, ItemContainer);
}

// This is called automatically when the Item is initialized (during UIPanel.InitPanel)
simulated function ItemAdded(UIPanel Item)
{
	if(ItemCount == 0)
	{
		if( BG != none && bAnimateOnInit )
			BG.AnimateIn();

		if (bSelectFirstAvailable)
			Navigator.SelectFirstAvailable();
	}

	ItemCount++;

	RealizeItems(ItemCount - 1);
	RealizeList();
}

// This is called automatically when the Item is removed (during UIPanel.RemoveChild)
simulated function ItemRemoved(UIPanel Item)
{
	ItemCount--;
	RealizeItems(GetItemIndex(Item));
	RealizeList();
}


// NOTE: You must init the item panel before calling this function
simulated function MoveItemToTop(UIPanel Item)
{
	local int StartingIndex, ItemIndex;

	StartingIndex = GetItemIndex(Item);

	if(StartingIndex != INDEX_NONE)
	{
		if(SelectedIndex > INDEX_NONE && SelectedIndex < ItemCount)
			GetSelectedItem().OnLoseFocus();

		ItemIndex = StartingIndex;
		while(ItemIndex > 0)
		{
			ItemContainer.SwapChildren(ItemIndex, ItemIndex - 1);
			ItemIndex--;
		}

		RealizeItems();

		if(SelectedIndex > INDEX_NONE && SelectedIndex < ItemCount)
			GetSelectedItem().OnReceiveFocus();
	}

	//if we move the currently selected item to the top, change the selection to the item that got moved into that location
	if(StartingIndex == SelectedIndex && OnSelectionChanged != none)
		OnSelectionChanged(self, SelectedIndex);
}

// NOTE: You must init the item panel before calling this function
simulated function MoveItemToBottom(UIPanel Item)
{
	local int StartingIndex, ItemIndex;

	StartingIndex = GetItemIndex(Item);

	if(StartingIndex != INDEX_NONE)
	{
		if(SelectedIndex > INDEX_NONE && SelectedIndex < ItemCount)
			GetSelectedItem().OnLoseFocus();

		ItemIndex = StartingIndex;
		while(ItemIndex < ItemCount - 1)
		{
			ItemContainer.SwapChildren(ItemIndex, ItemIndex + 1);
			ItemIndex++;
		}

		RealizeItems(StartingIndex);

		if(SelectedIndex > INDEX_NONE && SelectedIndex < ItemCount)
			GetSelectedItem().OnReceiveFocus();
	}

	//if we move the currently selected item to the bottom, change the selection to the item that got moved into that location
	if(StartingIndex == SelectedIndex && OnSelectionChanged != none)
		OnSelectionChanged(self, SelectedIndex);
}

simulated function ClearItems()
{
	local bool LoopNavigator, LoopOnReceiveFocus;
	if( ItemCount > 0 )
	{
		ItemCount = 0;
		TotalItemSize = 0;
		SelectedIndex = -1;

		if(Scrollbar != none)
		{
			Scrollbar.Remove();
			Scrollbar = none;
		}

		// It's much cheaper to destroy and recreate the container than removing each individual item.
		ItemContainer.Remove();

		//Create Item Container sets a new Navigator, save the previous LoopSelection and reuse it
		LoopNavigator = Navigator.LoopSelection;
		LoopOnReceiveFocus = Navigator.LoopOnReceiveFocus;
		CreateItemContainer();
		Navigator.LoopSelection = LoopNavigator;
		Navigator.LoopOnReceiveFocus = LoopOnReceiveFocus;
		
		RealizeList();
	}
}

// Get item based on Index
simulated function UIPanel GetItem(int Index)
{
	if (Index >= 0 && Index < ItemContainer.ChildPanels.Length)
		return ItemContainer.ChildPanels[Index];
	return none;
}

// Traverses the ownership chain to determine if the passed in control is contained within this List
simulated function bool HasItem(UIPanel Item)
{
	return GetItemIndex(Item) != INDEX_NONE;
}

// Traverse the ownership chain looking an item contained in this list, returns the Index of said item, or -1 if not found.
simulated function int GetItemIndex(UIPanel Control)
{
	local int Index;
	Index = ItemContainer.ChildPanels.Find(Control);
	if(Index == INDEX_NONE && Control != none && Control.ParentPanel != none && Control.ParentPanel != Screen)
		Index = GetItemIndex(Control.ParentPanel);
	return Index;
}

simulated function int GetItemCount()
{
	return ItemContainer.ChildPanels.Length;
}

// Returns the first item that has bIsFocused set to true
simulated function UIPanel GetFocusedItem()
{
	local int i;
	for(i = 0; i < ItemCount; ++ i)
	{
		if(ItemContainer.ChildPanels[i].bIsFocused)
			return GetItem(i);
	}
	return none;
}

simulated function UIPanel GetSelectedItem()
{
	return ItemContainer.ChildPanels[SelectedIndex];
}

simulated function UIList SetSelectedIndex(int Index, optional bool bForce)
{
	if(Index != SelectedIndex || bForce)
	{
		if(SelectedIndex > INDEX_NONE && SelectedIndex < ItemCount)
			GetSelectedItem().OnLoseFocus();

		SelectedIndex = Index;
		Navigator.SetSelected(GetItem(Index));

		if(SelectedIndex > INDEX_NONE && SelectedIndex < ItemCount)
			GetSelectedItem().OnReceiveFocus();

		if(OnSelectionChanged != none)
			OnSelectionChanged(self, SelectedIndex);
	}

	// lists with a valid selected index are considered "focused" for navigation purposes
	bIsFocused = SelectedIndex > -1 && SelectedIndex < ItemCount;
	return self;
}

simulated function UIList SetSelectedItem(UIPanel Item, optional bool bForce)
{
	local int Index;
	if( HasItem(Item) )
	{
		Index = GetItemIndex(Item);
		SetSelectedIndex(Index, bForce);
	}
	return self;
}

simulated function NavigatorSelectionChanged(int NavigationIndex)
{
	local int ListIndex;

	//Translate the navigator index to the list's item index. 
	ListIndex = GetItemIndex(Navigator.GetControl(NavigationIndex));
	SetSelectedIndex(ListIndex);

	if(Scrollbar != none)
	{
		// TODO: ensure we don't scroll unless the selected item is not in the visible area
		Scrollbar.SetThumbAtPercent(float(ListIndex) / float(ItemCount - 1));
	}
}

simulated function UIList ClearSelection()
{
	SetSelectedIndex(-1);
	return self;
}

// If you have the child Control's name, usually from a path, this will return a reference to the child object.
simulated function UIPanel GetItemNamed( name childName )
{
	local UIPanel Control; 

	foreach ItemContainer.ChildPanels(Control)
	{
		if( Control.Name == childName )
			return Control;
	}
	
	return none;
}

// These functions return the size of the list accounting for Scrollbar when it exists
simulated function float GetTotalWidth()
{
	if(!bIsHorizontal && Scrollbar != none)
	{
		if( bShrinkToFit && TotalItemSize < width )
			return TotalItemSize + ScrollbarPadding;
		else
			return width + ScrollbarPadding;
	}
	if( bShrinkToFit && TotalItemSize < width && bIsHorizontal )
		return TotalItemSize;
	else
		return width;
}
simulated function float GetTotalHeight()
{
	if(bIsHorizontal && Scrollbar != none)
	{
		if( bShrinkToFit && TotalItemSize < height )
			return TotalItemSize + ScrollbarPadding;
		else
			return height + ScrollbarPadding;
	}
	if( bShrinkToFit && TotalItemSize < height && !bIsHorizontal )
		return TotalItemSize; 
	else
		return height;
}

// UIList makes no distinction between its size and the masks size, they're both one in the same
simulated function SetWidth(float newWidth)
{
	local int i;

	if(width != newWidth)
	{
		width = newWidth;

		if(bAutosizeItems && !bIsHorizontal && ItemCount > 0)
		{
			for(i = 0; i < ItemCount; ++i)
				GetItem(i).SetWidth(newWidth);
		}

		RealizeMaskAndScrollbar();

		if(Mask != none && Scrollbar != none)
		{
			Mask.SetWidth(width);
			Scrollbar.SnapToControl(Mask,,!bIsHorizontal);
		}
	}

	if(bIsHorizontal)
		RealizeList();
}

simulated function SetHeight(float newHeight)
{
	local int i;

	if(height != newHeight)
	{
		height = newHeight;

		if(bIsHorizontal && ItemCount > 0)
		{
			for(i = 0; i < ItemCount; ++i)
				GetItem(i).SetHeight(newHeight);
		}

		RealizeMaskAndScrollbar();

		if(Mask != none && Scrollbar != none)
		{
			Mask.SetHeight(height);
			Scrollbar.SnapToControl(Mask,,!bIsHorizontal);
		}
	}

	if(!bIsHorizontal)
		RealizeList();
}

simulated function SetMaskSize(float newWidth, float newHeight)
{
	SetWidth(newWidth);
	SetHeight(newHeight);
}
simulated function UIPanel SetSize(float newWidth, float newHeight)
{
	SetWidth(newWidth);
	SetHeight(newHeight);
	return self;
}

simulated function int ShrinkToFit()
{
	bShrinkToFit = true; 

	if( BG != none )
		RealizeBGSize();

	if( bIsHorizontal )
		return GetTotalWidth();
	else
		return GetTotalHeight();

}

simulated function OnItemSizeChanged(UIPanel Item)
{
	local int Index;
	
	Index = GetItemIndex(Item);
	
	if(Index != INDEX_NONE)
		RealizeItems(GetItemIndex(Item));
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local UIPanel CurrentSelection; 
	local bool bConsumed; 

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bConsumed = false; 

	if ((cmd == class'UIUtilities_Input'.const.FXS_KEY_ENTER ||
		 cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A ||
		 cmd == class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR) && 
		SelectedIndex != -1 )
	{
		CurrentSelection = GetSelectedItem();
		if( CurrentSelection != none )
		{
			bConsumed = CurrentSelection.OnUnrealCommand(cmd, arg);
		}

		if( !bConsumed && OnItemDoubleClicked != none )
		{
			OnItemDoubleClicked(self, SelectedIndex);
			return true;
		}

		if( !bConsumed && OnItemClicked != none )
		{
			OnItemClicked(self, SelectedIndex);
			return true;
		}
	}

	if( !bConsumed && super.OnUnrealCommand(cmd, arg) )
	{
		return true;
	}

	return bConsumed || Navigator.OnUnrealCommand(cmd, arg);
}

simulated function OnChildMouseEvent(UIPanel Control, int cmd)
{
	// Ensure we're not processing any delayed mouse events if the user has requested to ignore mouse input.
	if(HasHitTestDisabled()) return;

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		if( HasItem(Control) )
		{
			SetSelectedIndex(GetItemIndex(Control));
			if(OnItemClicked != none)
				OnItemClicked(self, SelectedIndex);
		}
		break;

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		if( `XENGINE.m_SteamControllerManager.IsSteamControllerActive() )
		{
			if( HasItem(Control) )
			{
				SetSelectedIndex(GetItemIndex(Control));
				if( OnItemClicked != none )
					OnItemClicked(self, SelectedIndex);
			}
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		if( HasItem(Control) )
		{
			SetSelectedIndex(GetItemIndex(Control));
			if(OnItemDoubleClicked != none)
				OnItemDoubleClicked(self, SelectedIndex);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		if( HasItem(Control) )
		{
			SetSelectedIndex(GetItemIndex(Control));
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		if( HasItem(Control) && !bStickyHighlight )
		{
			SetSelectedIndex(INDEX_NONE);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
		if( Scrollbar != none )
			Scrollbar.OnMouseScrollEvent(1);
		break;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
		if( Scrollbar != none )
			Scrollbar.OnMouseScrollEvent(-1);
		break;
	}

	if(OnChildMouseEventDelegate != none)
		OnChildMouseEventDelegate(Control, Cmd);
}

simulated function RealizeBGSize()
{
	local float NewBGWidth, NewBGHeight;

	RealizeItems();

	NewBGWidth = GetTotalWidth() + BGPaddingLeft + BGPaddingRight;
	NewBGHeight = GetTotalHeight() + BGPaddingTop + BGPaddingBottom;

	// Don't animate shrinking the BG, it looks weird
	if( NewBGWidth > BG.Width && NewBGHeight <= BG.Height ||
		NewBGHeight > BG.Height && NewBGWidth <= BG.Width )
		BG.AnimateSize(GetTotalWidth() + BGPaddingLeft + BGPaddingRight, GetTotalHeight() + BGPaddingTop + BGPaddingBottom);
	else
		BG.SetSize(GetTotalWidth() + BGPaddingLeft + BGPaddingRight, GetTotalHeight() + BGPaddingTop + BGPaddingBottom);
}

simulated function RealizeLocation()
{
	if( anchor != class'UIUtilities'.const.ANCHOR_NONE )
		mc.FunctionNum("setAnchor", float(anchor));

	if( origin != class'UIUtilities'.const.ANCHOR_NONE )
	{
		// TODO: need custom origin logic since width / height don't get propagated to flash
	}

	// set Offset / Position (both functions take x and y parameters)
	if( origin != class'UIUtilities'.const.ANCHOR_NONE || anchor != class'UIUtilities'.const.ANCHOR_NONE )
		mc.BeginFunctionOp("setOffset");    // set Offset if anchor is set
	else
		mc.BeginFunctionOp("setPosition");  // otherwise set Position

	mc.QueueNumber(x);                  // add x parameter
	mc.QueueNumber(y);                  // add y parameter
	mc.EndOp();
}

simulated function RealizeList()
{
	RealizeMaskAndScrollbar();

	if(bCenterNoScroll && Scrollbar != none)
	{
		if(bIsHorizontal)
			ItemContainer.SetX(0);
		else
			ItemContainer.SetY(0);
	}
	else if(bCenterNoScroll && Scrollbar == none)
	{
		if(bIsHorizontal)
			ItemContainer.SetX((width / 2) - (TotalItemSize / 2));
		else
			ItemContainer.SetY((height / 2) - (TotalItemSize / 2));
	}

	if(BG != none)
	{
		if( bAnimateOnInit )
		{
			BG.RemoveTweens();
			BG.AnimateIn();
		}
		RealizeBGSize();
	}
}

simulated function RealizeItems(optional int StartingIndex)
{
	local int i;
	local float NextItemPosition;
	local UIPanel Item;

	if(StartingIndex > 0)
	{
		Item = GetItem(StartingIndex - 1);

		if( bIsHorizontal )
			NextItemPosition = Item.X + Item.Width + ItemPadding;
		else
			NextItemPosition = Item.Y + Item.Height + ItemPadding;
	}

	for(i = StartingIndex; i < ItemCount; ++i)
	{
		Item = GetItem(i);

		if( bIsHorizontal )
		{
			Item.SetX(NextItemPosition);
			NextItemPosition += Item.Width + (i < ItemCount - 1) ? ItemPadding : 0;
		}
		else
		{
			Item.SetY(NextItemPosition);
			NextItemPosition += Item.Height + (i < ItemCount - 1) ? ItemPadding : 0;
		}
	}

	TotalItemSize = NextItemPosition;
}

simulated function RealizeMaskAndScrollbar()
{
	local float RelevantSize;
	local bool bAnimateScrollbarIn; 

	RelevantSize = bIsHorizontal ? width : height;

	if(RelevantSize != 0 && TotalItemSize > RelevantSize)
	{
		if(Mask == none)
		{
			Mask = Spawn(class'UIMask', self).InitMask('ListMask');
		}
		Mask.SetMask(ItemContainer);
		Mask.SetSize(Width, Height);

		if(Scrollbar == none)
		{
			Scrollbar = Spawn(class'UIScrollbar', self).InitScrollbar('ListScrollbar');
			bAnimateScrollbarIn = true; 
		}
		Scrollbar.SnapToControl(Mask,,!bIsHorizontal);
		Scrollbar.NotifyValueChange(bIsHorizontal ? ItemContainer.SetX : ItemContainer.SetY, 0, relevantSize - TotalItemSize); 

		if( bAnimateScrollbarIn && bAnimateOnInit)
			Scrollbar.AnimateIn();
	}
	else if(Mask != none)
	{
		Mask.Remove();
		Mask = none;

		Scrollbar.Remove();
		Scrollbar = none;

		ItemContainer.SetPosition(0, 0);
	}
}

// This is overwritten by the List because we only focus the *selected* child, and not *all* children like the Panel does.  
simulated function OnReceiveFocus()
{
	local UIPanel SelectedChild;

	super.OnReceiveFocus();

	if( !bIsFocused )
	{
		bIsFocused = true;
		MC.FunctionVoid("onReceiveFocus");
	}

	SelectedChild = Navigator.GetSelected();

	if( SelectedChild != none )
		SelectedChild.OnReceiveFocus();
}

// This allows a StageList object that is placed on the stage in flash to report back its size
simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;
	if(cmd == "RealizeSize")
	{
		sizeData = SplitString(arg, ",");
		SetSize(float(sizeData[0]), float(sizeData[1]));
	}
}

simulated function Remove()
{
	ItemContainer.onChildAdded = none;
	ItemContainer.onChildRemoved = none;
	super.Remove();
}

simulated function DebugControl()
{
	Spawn(class'UIPanel', self).InitPanel(, class'UIUtilities_Controls'.const.MC_GenericPixel).SetSize(width, height).SetAlpha(20);
}

defaultproperties
{
	LibID = "EmptyControl"; // the list itself is just an empty container

	SelectedIndex = -1;

	ItemPadding = 0;
	TotalItemSize = 0;
	ScrollbarPadding = 25;
	BGPaddingLeft = 10;
	BGPaddingRight = 10;
	BGPaddingTop = 10;
	BGPaddingBottom = 10;

	bCascadeFocus = false;
	bIsHorizontal = false;
	bIsNavigable = true;
	bAutosizeItems = true;
	bAnimateOnInit = true;
	bStickyHighlight = true;
	bSelectFirstAvailable = true;

	bShouldPlayGenericUIAudioEvents = false
}