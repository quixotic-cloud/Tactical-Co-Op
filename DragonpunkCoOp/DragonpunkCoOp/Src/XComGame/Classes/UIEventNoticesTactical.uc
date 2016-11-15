//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIEventNoticesTactical.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Triggers notices in the tactical game. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2010-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
class UIEventNoticesTactical extends Object config(GameData);

var localized string RankUpMessage;
var config string RankUpIcon;

simulated function Init()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.RegisterForEvent(ThisObj, 'RankUpMessage', RankUpMessageListener, ELD_OnStateSubmitted);
}

simulated function Uninit()
{
	local Object ThisObj;

	ThisObj = self;
	`XEVENTMGR.UnRegisterFromAllEvents(ThisObj);	
}

function EventListenerReturn RankUpMessageListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	local XComGameState_Unit UnitState;
	local string Display;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState != None)
	{
		Display = Repl(RankUpMessage, "%NAME", UnitState.GetName(eNameType_RankLast));
		`PRES.Notify(Display, default.RankUpIcon);
		`COMBATLOG(Display);

		UnitState.RankUpTacticalVisualization();
	}

	return ELR_NoInterrupt;
}