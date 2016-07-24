//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIScanButton.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: UIScanButton to interface with scan button. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIScanButton extends UIPanel;

// Needs to match values in StrategyScanButton.as
enum EUIScanButtonState
{
	eUIScanButtonState_Default,
	eUIScanButtonState_Expanded
};
enum EUIScanButtonType
{
	eUIScanButtonType_Default,
	eUIScanButtonType_ResHQ,
	eUIScanButtonType_BlackMarket,
	eUIScanButtonType_Supplies,
	eUIScanButtonType_Contact,
	eUIScanButtonType_Tower,
	eUIScanButtonType_Alien
};

var EUIScanButtonType Type;
var EUIScanButtonState ButtonState;

var string Title;
var string Subtitle;
var string DaysValue;
var string DaysLabel;
var string IconPath;
var bool bShouldAnimate; 
var int PercentFilled; 
var bool bShowScanIcon;
var bool bPulseFaction;
var bool bPulseScannner;

var bool bDirty; // Used to gate the realize call for only if data has changed. 
var bool bExpandOnRealize; // Triggers the expansion call upon realize, after data has been set. 

var public delegate<OnClickDefault> onClickDefaultDelegate;
var public delegate<OnClickFaction> onClickFactionDelegate;

delegate OnClickDefault();
delegate OnClickFaction();

simulated function UIScanButton InitScanButton(optional name InitName)
{
	super.InitPanel(InitName);

	return self;
}

simulated function OnInit()
{
	super.OnInit();
	
	ShowScanIcon(bShowScanIcon, true);

	if( bDirty ) Realize();
}

public function Expand()
{
	SetButtonState(eUIScanButtonState_Expanded);
}
public function DefaultState()
{
	SetButtonState(eUIScanButtonState_Default);
}

simulated function UIScanButton SetButtonState(EUIScanButtonState NewButtonState)
{
	// The update chain is hammered by the geoscape entity updates, and often before the object has finished initializing. 
	// So, by adding this init bail out check, it fixes the bug of lost calls across the wire because the MC wasn't 
	// initialized in some cases. - bsteiner 7/16/2015
	if( !bIsInited ) return self; 

	if( ButtonState != NewButtonState )
	{
		ButtonState = NewButtonState;
		MC.FunctionNum("setButtonState", ButtonState);
		if( ButtonState == eUIScanButtonState_Expanded )
			bExpandOnRealize = true; 

		bDirty = true;
	}

	return self;
}
simulated function UIScanButton SetButtonType(EUIScanButtonType NewType)
{
	// Adding an init check here, because this function gets hammered. See comment in SetButtonTypeAndState().
	if( !bIsInited ) return self;

	if( Type != NewType )
	{
		Type = NewType;
		MC.FunctionNum("setButtonType", Type);
		bDirty = true;
	}

	return self;
}

simulated function UIScanButton SetText(string NewTitle, string NewSubtitle, string NewDaysValue, string NewDaysLabel, optional bool bForce = false)
{
	if (NewTitle != "")
		Show();
	else
		Hide();

	if(	   Title != NewTitle
	    || Subtitle != NewSubtitle 
		|| DaysValue != NewDaysValue
		|| DaysLabel != NewDaysLabel
		|| bForce )
	{
		Title = NewTitle;
		Subtitle = NewSubtitle;
		DaysValue = NewDaysValue;
		DaysLabel = NewDaysLabel;

		mc.BeginFunctionOp("setHTMLText");
		MC.QueueString(Title);
		MC.QueueString(Subtitle);
		MC.QueueString(DaysValue);
		MC.QueueString(DaysLabel);
		MC.EndOp();

		bDirty = true;
	}
	return self;
}

simulated function UIScanButton SetButtonIcon(string NewIconPath, optional bool bForce = false)
{
	if( IconPath != NewIconPath || bForce )
	{
		IconPath = NewIconPath;
		MC.FunctionString("setButtonIcon", IconPath);
	}

	return self;
}

simulated function UIScanButton SetScanMeter(int NewPercentFilled)
{
	if( PercentFilled != NewPercentFilled )
	{
		PercentFilled = NewPercentFilled;
		MC.FunctionNum("setScanMeter", PercentFilled); //must receive an int, as this is translated to a frame in flash. 
		bDirty = true;
	}

	return self;
}

simulated function UIScanButton AnimateIcon(bool bNewShouldAnimate)
{
	if( bShouldAnimate != bNewShouldAnimate )
	{
		bShouldAnimate = bNewShouldAnimate;
		MC.FunctionBool("animateScan", bShouldAnimate);
		bDirty = true;
	}

	return self;
}

simulated function UIScanButton ShowScanIcon(bool bShouldShow, optional bool bForce = false)
{
	if( bShowScanIcon != bShouldShow || bForce )
	{
		bShowScanIcon = bShouldShow;
		MC.FunctionBool("showScanIcon", bShowScanIcon);
		bDirty = true;
	}

	return self;
}

simulated function UIScanButton PulseFaction(bool bNewPulseFaction)
{
	if( !bIsInited ) return self;
	if( bPulseFaction != bNewPulseFaction )
	{
		bPulseFaction = bNewPulseFaction;
		MC.FunctionBool("showFactionButtonPulse", bPulseFaction);
		bDirty = true;
	}

	return self;
}

simulated function UIScanButton PulseScanner(bool bNewPulseScannner)
{
	if( bPulseScannner != bNewPulseScannner )
	{
		bPulseScannner = bNewPulseScannner;
		MC.FunctionBool("showScannerButtonPulse", bPulseScannner);
		bDirty = true;
	}

	return self;
}

simulated function UIScanButton Realize()
{
	if( !bIsInited ) return self;
	
	//animate expansion in should be called before realize
	if( bExpandOnRealize )
	{
		MC.FunctionBool("setAnimateExpansionIn", true);
		bExpandOnRealize = false;
	}

	if( bDirty )
	{
		MC.FunctionVoid("realize");
		bDirty = false;
	}
	
	return self;
}

simulated function UIScanButton SetDefaultDelegate(delegate<OnClickDefault> onClickDefaultDel)
{
	onClickDefaultDelegate = onClickDefaultDel;

	return self;
}

simulated function UIScanButton SetFactionDelegate(delegate<OnClickFaction> onClickFactionDel)
{
	onClickFactionDelegate = onClickFactionDel;

	return self;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string target; 

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		target = args[args.length - 1];
		switch( target )
		{
		case "bgButton":
			ClickButtonDefault();
			break;
		case "scanFactionButton":
			ClickButtonFaction();
			break;
		case "scanScannerButton":
			ClickButtonScan();
			break;
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		UIStrategyMapItem(Owner).OnMouseIn(); 
		break;

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		UIStrategyMapItem(Owner).OnMouseOut(); 
		break;
	}
}

function SetFactionTooltip(string tooltipHTML)
{
	local int TooltipID; 
	TooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(tooltipHTML, 15, 0, MCPath$".scanFactionButton", , false, , true, , , , , , 0.0 /*no delay*/);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(TooltipID, true);
}

function SetScannerTooltip(string tooltipHTML)
{
	local int TooltipID;
	TooltipID = Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(tooltipHTML, 15, 0, MCPath$".scanScannerButton", , false, , true, , , , , , 0.0 /*no delay*/);
	Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(TooltipID, true);
}

simulated function ClickButtonDefault()
{
	if (onClickDefaultDelegate != none)
		onClickDefaultDelegate();
}

simulated function ClickButtonScan()
{
	`HQPRES.StrategyMap2D.ToggleScan();
}

simulated function ClickButtonFaction()
{
	if (onClickFactionDelegate != none)
		onClickFactionDelegate();
}


defaultproperties
{
	LibID = "StrategyScanButton";
	bIsNavigable = true;
	Type = EUIScanButtonType_MAX; 
	ButtonState = EUIScanButtonState_MAX;

	Title="UNINITIALIZED";
	Subtitle="UNINITIALIZED";
	DaysValue="UNINITIALIZED";
	DaysLabel="UNINITIALIZED";
	IconPath="UNINITIALIZED PATH";
	bShouldAnimate=false;
	PercentFilled=-1;
	bShowScanIcon=true;
	bDirty = false;
}

