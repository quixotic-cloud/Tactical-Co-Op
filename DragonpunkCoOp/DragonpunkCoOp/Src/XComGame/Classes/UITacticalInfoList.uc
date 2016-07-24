//---------------------------------------------------------------------------------------
//  FILE:    UITacticalInfoList.uc
//  AUTHOR:  Brit Steiner --  7/28/2014
//  PURPOSE: This is an autoformatting list of tactical info blobs. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UITacticalInfoList extends UIPanel
	dependson(UIQueryInterfaceItem);

var array<UITacticalInfoListItem> Items; 
var public float MaskHeight; 
var public float scrollbarPadding; 
var UIMask       Mask;
var UIScrollbar	Scrollbar;
var UIPanel			Container;
var UIScrollingText TitleControl;
var UIPanel                   Line; 

var int PADDING_BOTTOM; 

// this delegate is triggered when text size is calculated after setting text data
delegate OnSizeRealized();

simulated function UIPanel InitTacticalInfoList(optional name InitName, 
										  optional name InitLibID = '', 
										  optional string Title,
										  optional int InitX = 0, 
										  optional int InitY = 0, 
										  optional int InitWidth, 
										  optional int InitHeight)  
{
	InitPanel(InitName, InitLibID);
	
	SetPosition(InitX, InitY);

	//We don't want to scale the movie clip, but we do want to save the values for column formatting. 
	width = InitWidth; 
	height = InitHeight; 

	TitleControl = Spawn(class'UIScrollingText', self);
	TitleControl.InitScrollingText(, "", width); 
	TitleControl.SetSubTitle( Title );

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( TitleControl, none, 2 );

	//Contains all items added to this list, used to reposition when using scrollbar. 
	Container = Spawn(class'UIPanel', self); 
	Container.InitPanel('Container').SetPosition(0, Line.Y+4); 

	return self; 
}

simulated function RefreshData(array<UISummary_TacaticalText> Data)
{
	local int i;
	local UITacticalInfoListItem Item; 

	for( i = 0; i < Data.Length; i++ )
	{
		// Build new items if we need to. 
		if( i > Items.Length-1 )
		{
			Item = Spawn(class'UITacticalInfoListItem', Container).InitTacticalInfoListItem();
			Items.AddItem(Item);
		}
		
		// Grab our target item
		Item = Items[i]; 

		//Update Data 
		Item.Data = Data[i];
		Item.Show();
	}

	// Hide any excess list items if we didn't use them. 
	for( i = Data.Length; i < Items.Length; i++ )
	{
		Items[i].Hide();
	}

	RealizeSize();
}

function RealizeSize()
{
	local int i, VisibleItems; 
	local float CurrentYPosition;
	local UITacticalInfoListItem TargetItem;

	VisibleItems = 0;
	CurrentYPosition = 0;
	for( i = 0; i < Items.Length; i++ )
	{
		TargetItem = Items[i]; 

		if( TargetItem.bIsVisible )
		{
			TargetItem.SetY(currentYPosition);
			CurrentYPosition += TargetItem.Height; 
			VisibleItems++;
		}
	}

	if( VisibleItems > 0 )
	{
		Height = CurrentYPosition + Container.Y + PADDING_BOTTOM;
		Show();
	}
	else // Hide if we have nothing to show, and report empty height 
	{
		Height = 0;
		Hide();
	}

	if( OnSizeRealized != none )
		OnSizeRealized();
}



//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	PADDING_BOTTOM = 10;
	bAnimateOnInit = false;
}