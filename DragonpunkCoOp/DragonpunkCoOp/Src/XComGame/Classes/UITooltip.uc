//---------------------------------------------------------------------------------------
 //  FILE:    UITooltip.uc
 //  AUTHOR:  Brit Steiner --  2014
 //  PURPOSE: Base class for all other tooltips, with bare-bones functionality for the 
 //			  Movie to be able to interact with any tooltip. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITooltip extends UIPanel
	dependson(UIUtilities)
	native(UI);

//Unique identifier ----------------------------------------------------------------------
var int     ID;  

//Location: -----------------------------------------------------------------------------
var bool    bRelativeLocation; //true if relative to the targeted path UI element; false for absolute placement

//Time: ----------------------------------------------------------------------------------
var float   tDisplayTime;
var float   tDelay;
var float   tAnimateIn;
var float   tAnimateOut;
//Activation Tracking: 
var float   deltaTime; 

//Targeting: ------------------------------------------------------------------------------
var string targetPath; //What we look for in the mouse callback path and use for relative location
var bool bFollowMouse; 
var bool bUsePartialPath; // Allow the path to define a higher level and accept longer matches 
var string currentPath; 

var UITooltipGroup TooltipGroup;

//Callbacks: ------------------------------------------------------------------------------
var UITooltipMgr TooltipMgr; 
//Triggered on mouse in, comes with ref to this tooltip so that it's contents may be updated before displaying 
delegate del_OnMouseIn( UIToolTip refToThisTooltip ); 
delegate del_OnMouseOut( UIToolTip refToThisTooltip ); 

delegate OnSizeRealized();
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);
	TooltipMgr = Movie.Pres.m_kTooltipMgr;
	UpdateData();
	Hide();
	if(!Movie.IsMouseActive())
	{
		//A delay is not necessary in mouseless-mode when a hover is being simulated
		tDelay = 0;
	}
	return self;
}

simulated function UIPanel Init(optional name InitName, optional name InitLibID)
{
	return InitPanel(InitName, InitLibID);
}

simulated function UITooltip InitTooltip(optional name InitName, optional name InitLibID)
{
	return UITooltip(Init(InitName, InitLibID));
}

simulated function SetTooltipGroup(UITooltipGroup Group)
{
	TooltipGroup = Group;
}

//Intended to be overwritten in child classes
simulated function ShowTooltip()
{
	Show();
	ClearTimer(nameof(Hide));
}

//Intended to be overwritten in child classes
simulated function HideTooltip(optional bool bAnimateIfPossible = false)
{
	if(bAnimateIfPossible && bIsVisible)
	{
		MC.FunctionNum("AnimateOut", tAnimateOut);
		SetTimer(tAnimateOut, false, nameof(Hide));
	}
	else
		Hide();
}

//Intended to be overwritten in child classes
public function bool MatchesPath(string NewPath, optional bool bForcePartialPath, optional bool bTooltipIsSourcePath)
{
	if( bUsePartialPath || bForcePartialPath )
	{
		if( (bTooltipIsSourcePath && InStr(TargetPath, NewPath,, true) > INDEX_NONE) || 
			(!bTooltipIsSourcePath && InStr(NewPath, TargetPath,, true) > INDEX_NONE ) )
		{
			CurrentPath = NewPath;
			return true;
		}
	}
	else if( NewPath == TargetPath ) 
	{
		CurrentPath = NewPath; 
		return true;
	}
	return false;
}

//Intended to be overwritten in child classes
public function bool MatchesID(int MatchingID)
{
	return ID == MatchingID;
}

//Intended to be overwritten in child classes
public function UpdateData();

//Gets called once the tooltips delay timer completes
simulated event Activate()
{
	ShowTooltip();
}

simulated event Removed()
{
	super.Removed();
	if (TooltipGroup != none)
	{
		//This sets TooltipGroup to none.
		TooltipGroup.Remove(self);
	}
}

simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;
	if (cmd == "RealizeSize")
	{
		sizeData = SplitString(arg, ",");
		Width = float(sizeData[0]);
		Height = float(sizeData[1]);
		if (OnSizeRealized != none)
		{
			OnSizeRealized();
		}
	}
}
//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	ID          = -1;

	X           = -9999.0;
	Y           = -9999.0;
	anchor      = 1; // class'UIUtilities'.const.ANCHOR_TOP_LEFT; 

	tDisplayTime = -1.0;
	tDelay      = 0.75;
	tAnimateIn  = 0.2;
	tAnimateOut = 0.2;
	deltaTime = 0.0;

	targetPath = "<TARGET PATH NOT SET>";
	currentPath = "<CURRENT PATH NOT SET>";
	
	bFollowMouse = true;
	bUsePartialPath = false;
	bRelativeLocation = false;

	bIsNavigable = false;
	bIsVisible = false;
	bAlwaysTick = true
}