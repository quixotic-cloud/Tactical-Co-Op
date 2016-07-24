//---------------------------------------------------------------------------------------
//  FILE:    UIAbilityDescription.uc
//  AUTHOR:  Brit Steiner --  7/15/2014
//  PURPOSE: This is an autoformatting single ability box. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIAbilityDescription extends UIPanel;

var private array<UIAbilityListItem> Items; 
var public float MaskHeight; 

simulated function UIPanel InitAbilityList(optional name InitName, 
										  optional name InitLibID = '', 
										  optional int InitX = 0, 
										  optional int InitY = 0, 
										  optional int InitWidth, 
										  optional int InitHeight, 
										  optional int InitMaskHeight)  
{
	InitPanel(InitName, InitLibID);
	
	SetPosition(InitX, InitY);

	//We don't want to scale the movie clip, but we do want to save the values for column formatting. 
	width = InitWidth; 
	height = InitHeight; 
	MaskHeight = InitMaskHeight;

	return self; 
}

simulated function RefreshData(array<UISummary_Ability> Data)
{
	RefreshDisplay(Data);
}

simulated private function RefreshDisplay(array<UISummary_Ability> Data)
{
	local UIAbilityListItem Item; 
	local int i; 

	//Test

	for( i = 0; i < Data.Length; i++ )
	{
		
		// Build new items if we need to. 
		if( i > Items.Length-1 )
		{
			Item = Spawn(class'UIAbilityListItem', self); //TEMP .InitAbilityListItem(self);
			Item.ID = i; 
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

}

simulated public function Show()
{
	super.Show();
	AnimateScroll(height, MaskHeight);
}

simulated function Hide()
{
	super.Hide();
	ClearScroll();
}

simulated function OnItemSizeChanged( UIAbilityListItem item )
{
	local int i, iStartIndex; 
	local UIAbilityListItem targetItem;
	local float currentYPosition; 

	iStartIndex = Items.Find(item); 
	currentYPosition = Items[iStartIndex].Y; 

	ClearScroll();

	for( i = iStartIndex; i < Items.Length; i++ )
	{

		targetItem = Items[i]; 

		if( !targetItem.bIsVisible )
			break;

		targetItem.SetY(currentYPosition);

		currentYPosition += targetItem.height; 
	}

	if( height != currentYPosition )
	{
		height = currentYPosition; 
		AnimateScroll(height, MaskHeight);
	}
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	MaskHeight = 100; 
}