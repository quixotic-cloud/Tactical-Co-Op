class X2Condition_HackingTarget extends X2Condition;

var bool bIntrusionProtocol;
var bool bHaywireProtocol;
var name RequiredAbilityName;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	return 'AA_Success';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameState_InteractiveObject TargetObject;
	local XComInteractiveLevelActor TargetVisualizer;
	local GameRulesCache_VisibilityInfo VisInfo;
	local bool bGoodTarget;
	local array<StateObjectReference> VisibleUnits;
	local array<XComInteractPoint> InteractionPoints;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);
	TargetObject = XComGameState_InteractiveObject(kTarget);
	
	if (TargetUnit != none && bHaywireProtocol)
	{
		//  Only Haywire can target units, they must be alive, unhacked, enemy robotic units
		bGoodTarget = TargetUnit.IsAlive() && !TargetUnit.bHasBeenHacked && TargetUnit.IsEnemyUnit(SourceUnit) && TargetUnit.IsRobotic();
		if (!bGoodTarget)
		{
			return 'AA_TargetHasNoLoot';
		}

		class'X2TacticalVisibilityHelpers'.static.GetAllVisibleEnemyUnitsForUnit(SourceUnit.ObjectID, VisibleUnits);
		//  allow squad sight for the gremlin.  (Squadsight fn only adds visible units that the source unit cannot see).
		class'X2TacticalVisibilityHelpers'.static.GetAllSquadsightEnemiesForUnit(SourceUnit.ObjectID, VisibleUnits);
		if (VisibleUnits.Find('ObjectID', TargetUnit.ObjectID) == INDEX_NONE)
			return 'AA_NotVisible';
		
		return 'AA_Success';
	}
	else if (TargetObject != none && !bHaywireProtocol)     //  Haywire is ONLY allowed to target units
	{
		TargetVisualizer = XComInteractiveLevelActor(TargetObject.GetVisualizer());

		if( bIntrusionProtocol )
		{
			if (!`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(SourceUnit.ObjectID, TargetObject.ObjectID, VisInfo)
				|| !VisInfo.bVisibleGameplay)
			{
				return 'AA_NotInRange';
			}
		}
		else
		{
			// check to see if we have an interaction point for the selected target
			InteractionPoints = class'X2Condition_UnitInteractions'.static.GetUnitInteractionPoints(SourceUnit, eInteractionType_Hack);
			if( InteractionPoints.Find('InteractiveActor', TargetVisualizer) == INDEX_NONE )
			{
				return 'AA_NoTargets';
			}
		}

		if( TargetVisualizer != none && TargetVisualizer.HackAbilityTemplateName != RequiredAbilityName && RequiredAbilityName != '' )
			return 'AA_AbilityUnavailable';

		if (TargetObject.Health == 0) // < 0 is a sentinel for indestructible
			return 'AA_NoTargets';

		if (TargetObject.CanInteractHack(SourceUnit))
			return 'AA_Success';
	}

	return 'AA_TargetHasNoLoot';
}