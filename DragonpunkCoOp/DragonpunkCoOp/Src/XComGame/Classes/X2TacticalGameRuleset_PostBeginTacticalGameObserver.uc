//---------------------------------------------------------------------------------------
//  FILE:    X2TacticalGameRuleset_PostBeginTacticalGameObserver.uc
//  AUTHOR:  Dan Kaplan  --  5/12/2014
//  PURPOSE: Provides an event hook for the start of a tactical game.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2TacticalGameRuleset_PostBeginTacticalGameObserver extends Object implements(X2GameRulesetEventObserverInterface);

var private array<StateObjectReference> PostBuildAbilityList;
var private int LastCheckedHistoryIndex;

//A core assumption of this method is that new ability state objects cannot be created by abilities running. If this assumption does not
//hold true, the lists below will be incomplete
event CacheGameStateInformation()
{
	local XComGameState_Ability AbilityStateObject;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTrigger_Event EventTrigger;
	local int Index;

	PostBuildAbilityList.Length = 0;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Ability', AbilityStateObject)
	{
		AbilityTemplate = AbilityStateObject.GetMyTemplate();
		for( Index = 0; Index < AbilityTemplate.AbilityTriggers.Length; ++Index )
		{
			EventTrigger = X2AbilityTrigger_Event(AbilityTemplate.AbilityTriggers[Index]);
			if( EventTrigger != none )
			{
				if( EventTrigger.EventObserverClass == Class )
				{
					if( EventTrigger.MethodName == nameof(PostBuildGameState) )
					{
						PostBuildAbilityList.AddItem(AbilityStateObject.GetReference());
					}
				}
			}
		}
	}
}

event Initialize()
{
	LastCheckedHistoryIndex = `XCOMHISTORY.GetCurrentHistoryIndex() - 1;
}

event PreBuildGameStateFromContext(const out XComGameStateContext NewGameStateContext)
{

}

event InterruptGameState(const out XComGameState NewGameState)
{	
}

event PostBuildGameState(const out XComGameState NewGameState)
{	
	local StateObjectReference	CheckAbilityRef;
	local XComGameState_Unit	CheckUnit;
	local XComGameState_Ability CheckAbility;
	local XComGameStateContext	AbilityContext;
	local XComGameStateHistory	History;
	local bool					FirstFrameOfTacticalGame;

	History = `XCOMHISTORY;

	FirstFrameOfTacticalGame = ( History.FindStartStateIndex() > LastCheckedHistoryIndex );

	LastCheckedHistoryIndex = History.GetCurrentHistoryIndex();

	foreach History.IterateByClassType(class'XComGameState_Unit', CheckUnit)
	{
		// if this is the first entry for this unit, it was freshly spawned
		if( FirstFrameOfTacticalGame || History.GetGameStateForObjectID( CheckUnit.ObjectID, eReturnType_Reference, LastCheckedHistoryIndex ) == None )
		{
			foreach PostBuildAbilityList(CheckAbilityRef)
			{		
				CheckAbility = XComGameState_Ability(History.GetGameStateForObjectID(CheckAbilityRef.ObjectID));
				if( CheckAbility.OwnerStateObject.ObjectID == CheckUnit.ObjectID &&
					CheckAbility.CanActivateAbilityForObserverEvent( CheckUnit ) == 'AA_Success' )
				{
					//This only feeds in a primary target right now. If we need to start supporting locational targets or multi-target interrupts, extend this
					AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(CheckAbility, CheckAbility.OwnerStateObject.ObjectID);
					if( AbilityContext.Validate() )
					{
						`XCOMGAME.GameRuleset.SubmitGameStateContext(AbilityContext);
					}
				}
			}		
		}
	}
}

