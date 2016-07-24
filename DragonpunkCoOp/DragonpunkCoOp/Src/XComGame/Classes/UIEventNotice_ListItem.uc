//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIListItemString.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Basic list item control.
//
//  NOTE: Mouse events are handled by UIList class
//
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIEventNotice_ListItem extends UIPanel;

var string Text;
var string ImagePath;

simulated function UIEventNotice_ListItem PopulateData(string NewText, string NewPath)
{
	if( Text != NewText || ImagePath != NewPath )
	{
		Text = NewText;	
		ImagePath = NewPath;
		
		MC.BeginFunctionOp("PopulateData");
		MC.QueueString(Text);
		MC.QueueString(ImagePath);
		MC.QueueBoolean(XComPresentationLayer(Movie.Pres) != none );  // bIsInTactical
		MC.EndOp();
	}
	return self;
}

defaultproperties
{
	LibID = "X2EventNoticeListItem";
	bProcessesMouseEvents = false;

	width = 433; // size according to flash movie clip
	height = 26; // size according to flash movie clip
}