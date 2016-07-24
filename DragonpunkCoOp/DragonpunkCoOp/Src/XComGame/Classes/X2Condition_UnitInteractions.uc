//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_UnitInteractions.uc
//  AUTHOR:  David Burchanowski
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_UnitInteractions extends X2Condition;

enum UnitInterationType
{
	eInteractionType_Normal, // not hackable, etc. Just plain vanillia interaction
	eInteractionType_Hack,   // only objects that require hacking to unlock
};

var UnitInterationType InteractionType;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitState;
	local array<XComInteractPoint> InteractionPoints;

	UnitState = XComGameState_Unit(kTarget);
	if( UnitState == none )
		return 'AA_NotAUnit';
	
	InteractionPoints = GetUnitInteractionPoints(UnitState, InteractionType);
	return (InteractionPoints.Length > 0) ? 'AA_Success' :  'AA_NoTargets';
}

static function array<XComInteractPoint> GetUnitInteractionPoints(XComGameState_Unit Unit, UnitInterationType Type)
{
	local array<XComInteractPoint> InteractionPoints;
	local XComInteractiveLevelActor InteractiveActor;
	local XComGameState_InteractiveObject InteractiveObject;
	local XComWorldData World;
	local Vector UnitLocation;
	local int Index;

	World = class'XComWorldData'.static.GetWorldData();

	UnitLocation = World.GetPositionFromTileCoordinates(Unit.TileLocation);
	World.GetInteractionPoints(UnitLocation, 8.0f, 90.0f, InteractionPoints);

	// remove any points that we can't interact with
	for(Index = 0; Index < InteractionPoints.Length; Index++)
	{
		InteractiveActor = InteractionPoints[Index].InteractiveActor;
		InteractiveObject = InteractiveActor.GetInteractiveState();
		
		if( InteractiveActor == None 
			|| InteractiveObject == None 
			|| IsInteractionLocationRestrictedByObject(InteractionPoints[Index].Location, InteractiveObject)
			|| !IsObjectAppropriateForInteractionType(InteractiveObject, Unit, Type) )
		{
			InteractionPoints.Remove(Index, 1);
			Index--;
		}
	}

	return InteractionPoints;
}

private static function bool IsObjectAppropriateForInteractionType(XComGameState_InteractiveObject ObjectState,
																   XComGameState_Unit Unit,
																   UnitInterationType Type)
{
	if(Type == eInteractionType_Normal)
	{
		return ObjectState.CanInteractNormally(Unit);
	}
	else if( Type == eInteractionType_Hack )
	{
		return ObjectState.CanInteractHack(Unit);
	}
	else
	{
		`assert(false); // unknown UnitInteractionType
	}
}

private static function bool IsInteractionLocationRestrictedByObject(const out Vector TestLocation, XComGameState_InteractiveObject ObjectState)
{
	return !ObjectState.IsLocationValidForInteraction(TestLocation);
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	return 'AA_Success';
}

DefaultProperties
{
}