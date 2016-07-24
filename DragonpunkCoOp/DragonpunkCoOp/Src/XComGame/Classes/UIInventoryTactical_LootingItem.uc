//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventoryTactical_LootingItem.uc
//  AUTHOR:  Jason Montgomery
//  PURPOSE: 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIInventoryTactical_LootingItem extends UIPanel;

var int GameStateObjectID;
var string LootButtonPath; 

simulated function UIInventoryTactical_LootingItem InitLootItem(optional bool isRightAligned)
{
	InitPanel();
	
	return self;
}

simulated function SetText(string theTitle, optional string theTooltip) 
{
	mc.BeginFunctionOp("setText");
	mc.QueueString(theTitle);
	mc.QueueString(""); // Old params no longer used. 
	mc.QueueString(""); // Old params no longer used.
	mc.EndOp();

	CreateTooltip(theTooltip);
}

simulated function SetDoubleRow(bool isDouble) 
{
	mc.FunctionBool("setDoubleRow", isDouble);
}

simulated function SetDisabled(bool isDisabled) 
{
	mc.FunctionBool("setDisabled", isDisabled);
}

simulated function SetRowHeader(bool isHeader) 
{
	mc.FunctionBool("setRowHeader", isHeader);
}

simulated function AlignRight()
{
	mc.FunctionVoid("alignRight");
}

simulated function CreateTooltip( string TooltipText )
{
	local UITextTooltip Tooltip; 

	// Clean up any previous version of this tooltip. 
	Movie.Pres.m_kTooltipMgr.RemoveTooltipByTarget(string(MCPath));

	Tooltip = Spawn(class'UITextTooltip', Movie.Pres.m_kTooltipMgr); 
	Tooltip.InitTextTooltip(,);
	Tooltip.bFollowMouse = true;
	Tooltip.bRelativeLocation = false;
	Tooltip.tDelay = 0.0; //Instant

	Tooltip.sBody = `XEXPAND.ExpandString(TooltipText);

	Tooltip.targetPath = string(MCPath) $ LootButtonPath;

	Tooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( Tooltip );
}

defaultproperties
{
	LibID = "LootItem";
	height = 46;
	LootButtonPath = ".lootButton"; 
}