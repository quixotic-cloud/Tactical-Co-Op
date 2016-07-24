//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIX2ResourceHeader.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIX2ResourceHeader extends UIPanel;

var bool bIsEmpty; 

delegate OnSizeRealized();

simulated function UIX2ResourceHeader InitResourceHeader( optional name InitName )
{
	InitPanel(InitName);
	return self;
}

simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;
	if( cmd == "RealizeSize" )
	{
		sizeData = SplitString(arg, ",");
		Width = float(sizeData[0]);
		Height = float(sizeData[1]);

		if( OnSizeRealized != none )
			OnSizeRealized();
	}
}

simulated function AddResource(string label, string data)
{
	MC.BeginFunctionOp("addResource");
	MC.QueueString(label);
	MC.QueueString(data);
	MC.EndOp();
	bIsEmpty = false;
}

simulated function ClearResources() 
{
	MC.FunctionVoid("clearResources");
	Hide();
	bIsEmpty = true;
}

defaultproperties
{
	LibID = "X2ResourceHeader";
	bIsEmpty = true; 
	bIsNavigable = false;
}