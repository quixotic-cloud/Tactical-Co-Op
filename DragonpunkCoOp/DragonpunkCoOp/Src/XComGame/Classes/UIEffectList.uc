//---------------------------------------------------------------------------------------
//  FILE:    UIEffectList.uc
//  AUTHOR:  Brit Steiner --  7/1/2014
//  PURPOSE: This is an autoformatting list of abilities. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIEffectList extends UIPanel
	dependson(UIQueryInterfaceUnit);

var array<UIEffectListItem> Items; 
var public float MaskHeight; 
var public float MaxHeight; 
delegate OnSizeRealized();

simulated function UIPanel InitEffectList(optional name InitName, 
										  optional name InitLibID = '', 
										  optional int InitX = 0, 
										  optional int InitY = 0, 
										  optional int InitWidth, 
										  optional int InitHeight, 
										  optional int InitMaskHeight,
										  optional int InitMaxHeight = 0,
										  optional delegate<OnSizeRealized> SizeRealizedDelegate)
{
	InitPanel(InitName, InitLibID);
	
	SetPosition(InitX, InitY);

	//We don't want to scale the movie clip, but we do want to save the values for column formatting. 
	width = InitWidth; 
	height = InitHeight; 
	MaskHeight = InitMaskHeight;
	MaxHeight = InitMaxHeight; 

	if(SizeRealizedDelegate != none)
		OnSizeRealized = SizeRealizedDelegate;

	return self; 
}

simulated function RefreshData(array<UISummary_UnitEffect> Data)
{
	RefreshDisplay(Data);
}

simulated function RefreshDisplay(array<UISummary_UnitEffect> Data)
{
	local UIEffectListItem Item; 
	local int i; 

	//Test

	for( i = 0; i < Data.Length; i++ )
	{
		
		// Build new items if we need to. 
		if( i > Items.Length-1 )
		{
			Item = Spawn(class'UIEffectListItem', self).InitEffectListItem(self);
			Item.ID = i; 
			Items.AddItem(Item);
		}
		
		// Grab our target Item
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

}

simulated public function Show()
{
	super.Show();
	//ResetScroll();
	AnimateScroll(height, MaskHeight);
}

simulated function Hide()
{
	super.Hide();
	ClearScroll();
}

simulated function OnItemChanged( UIEffectListItem ItemChanged )
{
	local int i;//, iStartIndex;
	local float currentYPosition;
	local UIEffectListItem Item; 

	//iStartIndex = Items.Find(ItemChanged); 
	currentYPosition = 0; //Items[iStartIndex].Y; 

	ClearScroll();

	for( i = 0; i < Items.Length; i++ )
	{
		Item = Items[i]; 

		if( !Item.bIsVisible )
			break;

		Item.SetY(currentYPosition);
		currentYPosition += Item.Height; 
	}

	if( height != currentYPosition )
	{
		height = currentYPosition; 
		StretchToFit();

		if( OnSizeRealized != none )
			OnSizeRealized();

		AnimateScroll(height, MaskHeight);
	}
}

//If a max size is defined, this list will attempt to stretch or shrink. 
simulated function StretchToFit()
{
	if( MaxHeight == 0 ) return; 

	if( height < MaxHeight )
	{
		MaskHeight = height; 
	}
	else
	{
		MaskHeight = MaxHeight;
	}
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	MaskHeight = 100; 
	MaxHeight = 0; 
}