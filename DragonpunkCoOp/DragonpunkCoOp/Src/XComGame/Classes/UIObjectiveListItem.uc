//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIObjectiveListItem.uc
//  AUTHOR:  Brit Steiner 11/13/2014
//  PURPOSE: Objective list item used in objective list. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIObjectiveListItem extends UIPanel;

enum EUIObjectiveDisplayType
{
	eUIODT_Title,
	eUIODT_ClickableButton,
	eUIODT_Label,
	eUIODT_Warning,
	eUIODT_Timer,
	eUIODT_Counter,
	eUIODT_Checkbox,
};

var public int ID; 
var public ObjectiveDisplayInfo Data; 
var public EUIObjectiveDisplayType Type; 

var bool            bBGVisible; 
var UIPanel       GroupBG; 
var int             BGAnchorPointY; 
var float           BaseDelay; 
var         bool            bIsDarkEvent;

//List that owns this object. 
var UIObjectiveList List;

var localized string m_strObjectivesListTitle;
var localized string m_strDarkEventsListTitle;
var localized string m_strPriority;
var localized string m_strInProgress;

simulated function UIObjectiveListItem InitObjectiveListItem(UIObjectiveList initList,
															   optional int InitX = 0, 
															   optional int InitY = 0)
{
	InitPanel(); 

	List = initList;

	ProcessMouseEvents(OnMouseEventHotlink); 

	if( List == none )
	{
		`log("UIObjectiveListItem incoming 'List' is none.",,'uixcom');
		return self;
	}
	return self;
}


simulated function OnInit()
{
	super.OnInit();
}

simulated function UIObjectiveListItem SetText(string txt)
{
	//Do nothing.
	return self;
}

simulated function Show()
{
	RefreshDisplay(Data);
	super.Show();
}

simulated function RefreshType(ObjectiveDisplayInfo NewData)
{
	bIsDarkEvent = NewData.bIsDarkEvent;

	//Title is manually set 
	if( NewData.MissionType == "TITLE" 
		||  NewData.MissionType == "DARKEVENTTITLE" )
	{
		Type = eUIODT_Title;
		return; 
	}
	//Group header is manually set 
	if( NewData.ShowHeader )
	{
		Type = eUIODT_ClickableButton;
		return; 
	}

	// Warning style 
	if( NewData.CounterHaveAmount > -1 )
	{
		Type = eUIODT_Counter; 
		return;
	}

	// Warning style 
	if( NewData.ShowWarning )
	{
		Type = eUIODT_Warning; 
		return;
	}

	// Check box 
	if( NewData.ShowCheckBox )
	{
		Type = eUIODT_Checkbox; 
		return;
	}

	if( NewData.Timer > -1 )
	{
		Type = eUIODT_Timer; 
		return;
	}
	// Else show as a basic text area. 
	Type = eUIODT_Label; 
}

simulated function RefreshDisplay(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	RefreshType(NewData); 

	//Set strings if NewData != OldData
	switch( Type )
	{
	case eUIODT_Title:
		SetTitle(NewData, bForce);
		break;
	case eUIODT_ClickableButton: 
		SetLabelButton(NewData, bForce);
		break;
	case eUIODT_Label: 
		SetLabelRow(NewData, bForce);
		break;
	case eUIODT_Warning: 
		SetWarningRow(NewData, bForce);
		break;
	case eUIODT_Timer: 
		SetTimerRow(NewData, bForce);
		break;
	case eUIODT_Counter: 
		SetCounterRow(NewData, bForce);
		break;
	case eUIODT_Checkbox: 
		SetCheckboxRow(NewData, bForce);
		break;

	}

	Data = NewData; 
}

simulated function string GetDisplayLabelString(ObjectiveDisplayInfo NewData)
{
	local XComGameStateHistory History;
	local string strToReturn;
	local X2StrategyElementTemplateManager StratMgr;
	local X2ObjectiveTemplate ObjectiveTemplate;


	History = `XCOMHISTORY;
	strToReturn = NewData.DisplayLabel;

	if(NewData.GPObjective && (XComGameStateContext_TacticalGameRule(History.GetGameStateFromHistory(History.FindStartStateIndex()).GetContext()) != None))
	{
		strToReturn = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 20, 20, 0) @ strToReturn;
	}

	if(NewData.ObjectiveTemplateName != '')
	{
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		ObjectiveTemplate = X2ObjectiveTemplate(StratMgr.FindStrategyElementTemplate(NewData.ObjectiveTemplateName));

		if(ObjectiveTemplate != none && (ObjectiveTemplate.SubObjectiveText == "" || Type == eUIODT_Checkbox) && ObjectiveTemplate.InProgressFn != none && ObjectiveTemplate.InProgressFn())
		{
			strToReturn = strToReturn @ m_strInProgress;
		}
	}

	if( NewData.bIsDarkEvent )
		return class'UIUtilities_Text'.static.GetColoredText(strToReturn, eUIState_Bad);
	else
		return strToReturn;
}

simulated function SetTitle(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	if( Data != NewData || bForce )
	{
		Data = NewData; 
		if( Data.bIsDarkEvent )
			MC.FunctionString("setTitleDarkEvent", class'UIUtilities_Text'.static.GetColoredText(m_strDarkEventsListTitle, eUIState_Bad));
		else
			MC.FunctionString("setTitle", m_strObjectivesListTitle);
	}
}

simulated function SetLabelRow(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	if(Data != NewData || bForce)
	{
		Data = NewData; 

		MC.FunctionString("setLabelRow", GetDisplayLabelString(NewData));
	}
}

simulated function SetLabelButton(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	if(Data != NewData || bForce)
	{
		Data = NewData; 

		MC.FunctionString("setLabelButton", GetDisplayLabelString(NewData));
	}
}

simulated function SetTimerRow(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	local int eUIState; 

	if(Data != NewData || bForce)
	{
		Data = NewData; 
		
		if( Data.ShowCompleted ) 
			eUIState = eUIState_Good; 
		else if( Data.ShowFailed ) 
			eUIState = eUIState_Bad; 
		else 
			eUIState = eUIState_Normal; 

		mc.BeginFunctionOp("setTimerRow");
		mc.QueueNumber(eUIState);
		mc.QueueString(GetDisplayLabelString(NewData));
		mc.QueueNumber(Data.Timer);
		mc.EndOp(); 
	}
}


simulated function SetWarningRow(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	if(Data != NewData || bForce)
	{
		Data = NewData; 

		MC.FunctionString("setWarningRow", GetDisplayLabelString(NewData));
	}
}

simulated function SetCheckboxRow(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	local int eUIState; 

	if(Data != NewData || bForce)
	{
		Data = NewData; 

		if( Data.ShowCompleted ) 
			eUIState = eUIState_Good; 
		else if( Data.ShowFailed ) 
			eUIState = eUIState_Bad; 
		//else if( Data.ShowDisabled )   // TODO: do we want a disabled state? 
		//	eUIState = eUIState_Disabled; 
		else 
			eUIState = eUIState_Normal; 

		mc.BeginFunctionOp("setCheckboxRow");
		mc.QueueNumber(eUIState);
		mc.QueueString(GetDisplayLabelString(NewData));
		mc.EndOp(); 
	}
}

simulated function SetCounterRow(ObjectiveDisplayInfo NewData, optional bool bForce = false)
{
	if(Data != NewData || bForce)
	{
		Data = NewData; 
		
		mc.BeginFunctionOp("setCounterRow");
		mc.QueueString(Data.CounterHaveImage);
		mc.QueueNumber(Data.CounterHaveAmount);
		mc.QueueNumber(Data.CounterHaveMin);
		mc.QueueString(Data.CounterAvailableImage);
		mc.QueueNumber(Data.CounterAvailableAmount);
		mc.QueueString(Data.CounterLostImage);
		mc.QueueNumber(Data.CounterLostAmount);
		mc.EndOp(); 
	}
}

// ----------------------------------------------------------------------

simulated function OnSizeRealized(float newWidth, float newHeight)
{
	if( Width != newWidth || Height != NewHeight )
	{
		Width = newWidth; 
		Height = newHeight;
		List.OnItemChanged(self);
	}
}

simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;
	if(cmd == "RealizeSize")
	{
		sizeData = SplitString(arg, ",");
		OnSizeRealized(float(sizeData[0]), float(sizeData[1]));
	}	
}
simulated function OnClick(UIPanel Control, int Cmd)
{
	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
		List.OnClickGroup(Data.GroupID);
}

simulated function ShowBG()
{
	bBGVisible = true; 
	MC.FunctionVoid("showBG");
}

simulated function HideBG()
{
	bBGVisible = false;
	MC.FunctionVoid("hideBG");
}

simulated function AnimateIn(optional float Delay = -1.0)
{
	if( Delay == -1.0 )
		Delay = ParentPanel.GetChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; 

	AddTweenBetween("_x", -Width - List.X, X, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay);
}

simulated function ToggleVisibility( int IndexWithinGroup )
{
	
	switch(Type)
	{
	case eUIODT_Title:
	case eUIODT_ClickableButton:
	case eUIODT_Warning:  
	case eUIODT_Timer:  
	case eUIODT_Counter: 
		//Always stay visible, but mark the change
		bBGVisible = !bBGVisible; 
		break; 

	case eUIODT_Label: 
	case eUIODT_Checkbox: 
		if( bBGVisible )
		{
			HideBG();
			Hide(); // AnimateOut() ? 
		}
		else
		{
			//ShowBG(); // Unnecessary? 
			bBGVisible = true; 
			Show();
			AnimateIn( BaseDelay * IndexWIthinGroup );
		}
		break; 
	}

}

simulated function RefreshGroupBG(  float BGWidth, float BGHeight )
{
	if( !bBGVisible ) 
	{
		if( GroupBG != none )
			GroupBG.Hide();
	}
	else
	{
		if( GroupBG == none )
		{
			GroupBG = Spawn(class'UIPanel', self).InitPanel('BGBoxGroup', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple);
		}
		GroupBG.SetSize(BGWidth - 14, BGHeight-BGAnchorPointY - 8); //Pixel adjustments to line up with header. 
		GroupBG.SetPosition(-List.X - GroupBG.Width, BGAnchorPointY); 
		GroupBG.AnimateX(-List.X, 0.5); 

		// Do we want this?
		//GroupBG.SetSize(BGWidth, 1); //Start out small
		//GroupBG.AnimateSize(BGWidth + List.X, BGHeight-BGAnchorPointY, 0.5); 
		GroupBG.Show();
	}

}


simulated function SetY(float NewY)
{
	if(Y == 0 ) // First time we're placing it 
	{ 
		super.SetY(NewY);
	}
	else
	{
		//Let's slide to our new spot. 
		AnimateY(NewY, 0.2); 
	}
	return;
}

simulated function OnMouseEventHotlink(UIPanel Panel, int Cmd)
{
	local XComHQPresentationLayer Pres;

	//No mouse processing in the tactical game 
	if( XComHQPresentationLayer(Movie.Pres) == none ) return; 

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		
		Pres = XComHQPresentationLayer(Movie.Pres);
		if( Pres != none && (Pres.StrategyMap2D == none || Pres.StrategyMap2D.m_eUIState != eSMS_Flight))
		{
			if( bIsDarkEvent )
				Pres.HotlinkToViewDarkEvents(true);
			else
				Pres.HotlinkToViewObjectives();

		}
		break;
	}
}


defaultproperties
{
	LibID = "X2ObjectiveListItem";
	Height = 32; 
	bBGVisible = true;
	BGAnchorPointY = 30; 

	BaseDelay = 0.1;
}