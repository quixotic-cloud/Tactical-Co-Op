//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement.uc
//  AUTHOR:  Mark Nauta
//    
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement extends X2DataSet;

static event array<X2DataTemplate> CreateStrategyElementTemplatesEvent()
{
	return CreateStrategyElementTemplates();
}

static function array<X2DataTemplate> CreateStrategyElementTemplates();