//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElementTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2StrategyElementTemplate extends X2DataTemplate
	native(Core)
	config(StrategyTuning);

function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

DefaultProperties
{
}