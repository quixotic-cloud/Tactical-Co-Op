//---------------------------------------------------------------------------------------
 //  FILE:    UIStrategyMap_MissionIconTooltip.uc
 //  AUTHOR:  Brit Steiner --  11/5/2015
 //  PURPOSE: Tooltip for the mission icons in strategy map HUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UIStrategyMap_MissionIconTooltip extends UITooltip;

var string Title;
var string Body;

simulated function UIPanel InitMissionIconTooltip(optional string InitTitle, optional string InitBody)
{
	InitTooltip();
	Title = InitTitle;
	Body = InitBody;
	return self;
}

simulated function ShowTooltip()
{
	MC.FunctionString("setTargetPath", targetPath);

	MC.BeginFunctionOp("SetText");
	MC.QueueString(Title);
	MC.QueueString(Body);
	MC.EndOp();

	super.ShowTooltip();
}

simulated function SetText(string NewTitle, string NewBody)
{
	Title = NewTitle;
	Body = NewBody;
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	LibID = "ScanHUDTooltip";
}