//---------------------------------------------------------------------------------------
//  FILE:    UIAbilityList.uc
//  AUTHOR:  Brit Steiner --  7/11/2014
//  PURPOSE: This is an autoformatting list of abilities. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIAbilityList extends UIPanel;

var array<UIAbilityListItem> Items; 
var float MaskHeight; 

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
			Item = Spawn(class'UIAbilityListItem', self).InitAbilityListItem(self);
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
	AnimateScroll(height, MaskHeight);
}

simulated function Hide()
{
	super.Hide();
	ClearScroll();
}

simulated function OnItemChanged( UIAbilityListItem Item )
{
	local int i, iStartIndex; 
	local float currentYPosition; 

	iStartIndex = Items.Find(Item); 
	currentYPosition = Items[iStartIndex].Y; 

	ClearScroll();

	for( i = iStartIndex; i < Items.Length; i++ )
	{
		Item = Items[i]; 

		if( !Item.bIsVisible )
			break;

		Item.SetY(currentYPosition);
		currentYPosition += Item.height; 
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