class X2TacticalGameRuleset_AttackObserver extends Object implements(X2GameRulesetEventObserverInterface);

var private array<StateObjectReference> InterruptAbilityList;
var private array<StateObjectReference> PostBuildAbilityList;
var private XComGameState_Unit AttackingUnitState;

//A core assumption of this method is that new ability state objects cannot be created by abilities running. If this assumption does not
//hold true, the lists below will be incomplete
event CacheGameStateInformation()
{
	local XComGameState_Ability AbilityStateObject;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTrigger_Event EventTrigger;
	local int Index;

	InterruptAbilityList.Length = 0;
	PostBuildAbilityList.Length = 0;
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Ability', AbilityStateObject)
	{
		AbilityTemplate = AbilityStateObject.GetMyTemplate();
		if (AbilityTemplate != None)
		{
			for( Index = 0; Index < AbilityTemplate.AbilityTriggers.Length; ++Index )
			{
				EventTrigger = X2AbilityTrigger_Event(AbilityTemplate.AbilityTriggers[Index]);
				if( EventTrigger != none )
				{
					if( EventTrigger.EventObserverClass == Class )
					{
						if( EventTrigger.MethodName == nameof(InterruptGameState) )
						{
							InterruptAbilityList.AddItem(AbilityStateObject.GetReference());
						}

						if( EventTrigger.MethodName == nameof(PostBuildGameState) )
						{
							PostBuildAbilityList.AddItem(AbilityStateObject.GetReference());
						}
					}
				}
			}
		}
	}
}

event Initialize()
{
}

event PreBuildGameStateFromContext(XComGameStateContext NewGameStateContext)
{

}

event InterruptGameState(XComGameState NewGameState)
{	
	local StateObjectReference CheckAbilityRef;
	local XComGameState_Ability CheckAbility;
	local XComGameStateContext AbilityContext;

	if (InterruptAbilityList.Length == 0)
		return;

	AttackingUnitState = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(NewGameState);

	if (AttackingUnitState != none)
	{
		foreach InterruptAbilityList(CheckAbilityRef)
		{		
			CheckAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(CheckAbilityRef.ObjectID));		
			if( CheckAbility.CanActivateAbilityForObserverEvent( AttackingUnitState ) == 'AA_Success' )
			{
				//This only feeds in a primary target right now. If we need to start supporting locational targets or multi-target interrupts, extend this
				AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(CheckAbility, AttackingUnitState.ObjectID);
				if( AbilityContext.Validate() )
				{
					`XCOMGAME.GameRuleset.SubmitGameStateContext(AbilityContext);
				}
			}
		}		
	}
}

event PostBuildGameState(XComGameState NewGameState)
{	
	local StateObjectReference CheckAbilityRef;
	local XComGameState_Ability CheckAbility;
	local XComGameStateContext AbilityContext;

	if (PostBuildAbilityList.Length == 0)
		return;

	AttackingUnitState = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(NewGameState);
	
	if (AttackingUnitState != none)
	{	
		foreach PostBuildAbilityList(CheckAbilityRef)
		{		
			CheckAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(CheckAbilityRef.ObjectID));
			if( CheckAbility.CanActivateAbilityForObserverEvent( AttackingUnitState ) == 'AA_Success' )
			{
				//This only feeds in a primary target right now. If we need to start supporting locational targets or multi-target interrupts, extend this
				AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(CheckAbility, AttackingUnitState.ObjectID);
				if( AbilityContext.Validate() )
				{
					`XCOMGAME.GameRuleset.SubmitGameStateContext(AbilityContext);
				}
			}
		}		
	}
}