//---------------------------------------------------------------------------------------
 //  FILE:    UITooltip.uc
 //  AUTHOR:  Sam Batista --  2015
 //  PURPOSE: Singleton class that handles basic text tooltips.
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITextTooltip extends UITooltip;

enum EUITT_Behavior
{
	eUITT_Behavior_Hover,
	eUITT_Behavior_Sticky,
};

enum EUITT_Color
{
	eUITT_Style_Cyan,
	eUITT_Style_Red,
	eUITT_Style_Yellow,
};

struct TTextTooltipData
{
	var int ID;  
	var bool bRelativeLocation;
	var float tDisplayTime;
	var float tDelay;
	var float tAnimateIn;
	var float tAnimateOut;
	var float deltaTime; 
	var string targetPath;
	var bool bFollowMouse; 
	var bool bUsePartialPath;
	var float maxW;
	var float maxH;
	var int anchor;
	var float x;
	var float y;
	var string sTitle;
	var string sBody; 
	var int eTTBehavior; 
	var int eTTColor;
	var delegate<del_OnMouseIn> del_OnMouseIn;
	var delegate<del_OnMouseOut> del_OnMouseOut;
};

//Size:----------------------------------------------------------------------------------
var float   maxW;
var float   maxH; 
	
//Contents: ------------------------------------------------------------------------------
var string  sTitle;
var string  sBody; 

//Style: ----------------------------------------------------------------------------------
var int eTTBehavior; 
var int eTTColor; 

var int DataIndex;
var int PreviousDataIndex;
var array<TTextTooltipData> TextTooltipData;

simulated function UITextTooltip InitTextTooltip(optional name InitName, optional name InitLibID)
{
	return UITextTooltip(Init(InitName, InitLibID));
}

simulated function ShowTooltip()
{
	if(TextTooltipData.Length == 0 || (DataIndex != INDEX_NONE && DataIndex != PreviousDataIndex))
	{
		PreviousDataIndex = DataIndex;
		UpdateData();
	}
	super.ShowTooltip();
}

public function UpdateData()
{
	local bool bUseCachedData;
	local TTextTooltipData TooltipData;

	bUseCachedData = TextTooltipData.Length > 0 && DataIndex > INDEX_NONE;
	if(bUseCachedData)
		TooltipData = TextTooltipData[DataIndex];


	MC.BeginFunctionOp("UpdateData");
	MC.QueueNumber(bUseCachedData ? TooltipData.Id : ID);
	MC.QueueString(bUseCachedData ? TooltipData.sTitle : sTitle);
	MC.QueueString(bUseCachedData ? TooltipData.sBody : sBody);
	MC.QueueNumber(bUseCachedData ? TooltipData.eTTColor : eTTColor);
	MC.QueueNumber(bUseCachedData ? TooltipData.X : X);
	MC.QueueNumber(bUseCachedData ? TooltipData.Y : Y);
	MC.QueueNumber(bUseCachedData ? TooltipData.maxW : maxW);
	MC.QueueNumber(bUseCachedData ? TooltipData.maxH : maxH);
	MC.QueueNumber(bUseCachedData ? TooltipData.Anchor : Anchor);
	MC.QueueString(bUseCachedData ? TooltipData.targetPath : TargetPath);
	MC.QueueBoolean(bUseCachedData ? TooltipData.bRelativeLocation : bRelativeLocation);
	MC.QueueNumber(bUseCachedData ? TooltipData.tAnimateIn : tAnimateIn);
	MC.QueueBoolean(bUseCachedData ? TooltipData.bFollowMouse : bFollowMouse);
	MC.EndOp();
}

private function SetDataIndex(int NewIndex)
{
	DataIndex = NewIndex;
	if(DataIndex != INDEX_NONE)
	{
		tDelay = TextTooltipData[DataIndex].tDelay;
		del_OnMouseIn = TextTooltipData[DataIndex].del_OnMouseIn;
		del_OnMouseOut = TextTooltipData[DataIndex].del_OnMouseOut;
	}
}

function SetText(optional string NewText)
{
	local bool bUseCachedData;

	bUseCachedData = TextTooltipData.Length > 0 && DataIndex > INDEX_NONE;
	if(bUseCachedData)
		TextTooltipData[DataIndex].sBody = NewText;
	else
		sBody = NewText;

	PreviousDataIndex = INDEX_NONE; // Reset previous data index to force a data update
}

function SetUsePartialPath(int TooltipID, optional bool bNewUsePartialPath)
{
	local int i;
	if(TextTooltipData.Length > 0)
	{
		for(i = TextTooltipData.length - 1; i > -1; --i)
		{ 
			if( TextTooltipData[i].ID == TooltipID )
			{
				TextTooltipData[i].bUsePartialPath = bNewUsePartialPath;
				break;
			}
		}
	}
	else
		bUsePartialPath = bNewUsePartialPath;
}

function SetMouseDelegates(int TooltipID, optional delegate<del_OnMouseIn> MouseInDel, optional delegate<del_OnMouseOut> MouseOutDel)
{
	local int i;
	if(TextTooltipData.Length > 0)
	{
		for(i = TextTooltipData.length - 1; i > -1; --i)
		{ 
			if( TextTooltipData[i].ID == TooltipID )
			{
				TextTooltipData[i].del_OnMouseIn = MouseInDel;
				TextTooltipData[i].del_OnMouseOut = MouseOutDel;
				break;
			}
		}
	}
	else
	{
		del_OnMouseIn = MouseInDel;
		del_OnMouseOut = MouseOutDel;
	}
}

//Intended to be overwritten in child classes
public function bool MatchesPath(string NewPath, optional bool bForcePartialPath, optional bool bTooltipIsSourcePath)
{
	local int i;
	local TTextTooltipData TooltipData;

	if( TextTooltipData.Length == 0 )
		return super.MatchesPath(NewPath, bForcePartialPath, bTooltipIsSourcePath);

	DataIndex = INDEX_NONE;

	for(i = 0; i < TextTooltipData.Length; ++i)
	{
		TooltipData = TextTooltipData[i];
		if( TooltipData.bUsePartialPath || bForcePartialPath )
		{
			if( (bTooltipIsSourcePath && InStr(TooltipData.TargetPath, NewPath,, true) > INDEX_NONE) || 
				(!bTooltipIsSourcePath && InStr(NewPath, TooltipData.TargetPath,, true) > INDEX_NONE ) )
			{
				CurrentPath = NewPath;
				SetDataIndex(i);
				break;
			}
		}
		else if( TooltipData.TargetPath == NewPath )
		{
			CurrentPath = NewPath;
			SetDataIndex(i);
			break;
		}
	}

	return DataIndex != INDEX_NONE;
}

//Intended to be overwritten in child classes
public function bool MatchesID(int NewID)
{
	local int i;

	if( TextTooltipData.Length == 0 )
		return super.MatchesID(NewID);

	DataIndex = INDEX_NONE;

	for(i = 0; i < TextTooltipData.Length; ++i)
	{
		if( TextTooltipData[i].ID == NewID )
		{
			CurrentPath = TextTooltipData[i].TargetPath;
			SetDataIndex(i);
			break;
		}
	}

	return DataIndex != INDEX_NONE;
}

public function RemoveTooltipByID(int TargetID)
{
	local int i;
	for(i = TextTooltipData.length - 1; i > -1; --i)
	{ 
		if( TextTooltipData[i].ID == TargetID )
		{
			TextTooltipData.Remove(i, 1);
			if( DataIndex == i )
			{
				DataIndex = INDEX_NONE;
				PreviousDataIndex = INDEX_NONE; // Reset previous data index to force a data update

				if( bIsVisible )
				{
					Hide();
				}
			}
		}
	}
}

public function RemoveTooltipByPath(string NewPath)
{
	local int i;
	for(i = TextTooltipData.length - 1; i > -1; --i)
	{ 
		if( TextTooltipData[i].TargetPath == NewPath )
		{
			TextTooltipData.Remove(i, 1);
			if( DataIndex == i )
			{
				DataIndex = INDEX_NONE;
				PreviousDataIndex = INDEX_NONE; // Reset previous data index to force a data update

				if( bIsVisible )
				{
					Hide();
				}
			}
		}
	}
}

public function RemoveTooltipByPartialPath(string NewPath)
{
	local int i;
	for(i = TextTooltipData.length - 1; i > -1; --i)
	{ 
		if( InStr(TextTooltipData[i].TargetPath, NewPath, , true) > INDEX_NONE )
		{
			TextTooltipData.Remove(i, 1);
			if( DataIndex == i )
			{
				DataIndex = INDEX_NONE;
				PreviousDataIndex = INDEX_NONE; // Reset previous data index to force a data update

				if( bIsVisible )
				{
					Hide();
				}
			}
		}
	}
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	LibID       = "TooltipBoxMC";

	eTTBehavior = eUITT_Behavior_Hover
	eTTColor    = eUITT_Style_Cyan; 

	maxW        = 300.0;
	maxH        = 300.0;
	
	sTitle      = "";
	sBody       = "";

	DataIndex = -1;
	PreviousDataIndex = -1;
	bAlwaysTick = true
}