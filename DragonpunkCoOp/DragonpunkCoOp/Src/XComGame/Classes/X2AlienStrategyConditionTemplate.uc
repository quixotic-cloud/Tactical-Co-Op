//---------------------------------------------------------------------------------------
//  FILE:    X2AlienStrategyConditionTemplate.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AlienStrategyConditionTemplate extends X2StrategyElementTemplate;

var () Delegate<IsMetDelegate> IsConditionMetFn;

delegate bool IsMetDelegate();

//---------------------------------------------------------------------------------------
DefaultProperties
{
}