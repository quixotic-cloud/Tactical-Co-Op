//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIEventQueue.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Individual event list item that connects to a flash library asset. 
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIEventQueue_ListItem extends UIPanel;

var string Title;
var string DaysLabel;
var string DaysValue;
var string ImagePath;

delegate OnUpButtonClicked(int ItemIndex);
delegate OnDownButtonClicked(int ItemIndex);
delegate OnCancelButtonClicked(int ItemIndex);

simulated function UIEventQueue_ListItem InitListItem()
{
	InitPanel(); // must do this before adding children or setting data
	return self; 
}

simulated function OnInit()
{
	super.OnInit();
}

simulated function OnMouseEvent(int Cmd, array<string> Args) 
{ 
    local string ClickedButton;

    if(Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP) 
    { 
        ClickedButton = Args[Args.Length - 2]; // -2 to account for bg within ButtonControls 

        switch(ClickedButton) 
        { 
        case "moveup":  
			if(OnUpButtonClicked != none)
			{
        		OnUpButtonClicked(ParentPanel.GetChildIndex(self)); 
			}
			break; 

        case "movedown":    
        	if(OnDownButtonClicked != none)
        	{
				OnDownButtonClicked(ParentPanel.GetChildIndex(self));
        	}
        	break; 

        case "cancel":      
        	if(OnCancelButtonClicked != none)
        	{
				OnCancelButtonClicked(ParentPanel.GetChildIndex(self));
        	}
			break;
        } 
    } 
}

simulated function UpdateData(HQEvent Event)
{
	local string TimeValue, TimeLabel, Desc; 

	Desc = Event.Data; 

	// Let the utility auto format: 
	class'UIUtilities_Text'.static.GetTimeValueAndLabel(Event.Hours, TimeValue, TimeLabel, 0);
	
	if (Event.Hours < 0)
	{
		Desc = class'UIUtilities_Text'.static.GetColoredText(Desc, eUIState_Warning);
		TimeLabel = " ";
		TimeValue = "--"; 
	}

	SetTitle(Desc);
	SetDaysLabel(TimeLabel);
	SetDaysValue(TimeValue);
	SetIconImage(Event.ImagePath);
}

simulated function AS_SetButtonsEnabled(bool EnableUpButton, bool EnableDownButton, bool EnableCancelButton)
{
	MC.BeginFunctionOp("SetButtonsEnabled");
	MC.QueueBoolean(EnableUpButton);
	MC.QueueBoolean(EnableDownButton);
	MC.QueueBoolean(EnableCancelButton);
	MC.EndOp();
}

simulated function SetTitle(string NewValue)
{
	if(Title != NewValue)
	{
		Title = NewValue;
		MC.FunctionString("setTitle", Title);
	}
}

simulated function SetDaysLabel(string NewValue)
{
	if(DaysLabel != NewValue)
	{
		DaysLabel = NewValue;
		MC.FunctionString("setDaysLabel", DaysLabel);
	}
}

simulated function SetDaysValue(string NewValue)
{
	if(DaysValue != NewValue)
	{
		DaysValue = NewValue;
		MC.FunctionString("setDaysValue", DaysValue);
	}
}

simulated function SetIconImage(string NewValue)
{
	if(ImagePath != NewValue)
	{
		ImagePath = NewValue;
		MC.FunctionString("setIconImage", ImagePath);
	}
}

defaultproperties
{
	LibID = "X2EventListItem";

	width = 354;
	height = 60;
	bIsNavigable = true;
}