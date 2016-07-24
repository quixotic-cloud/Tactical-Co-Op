//---------------------------------------------------------------------------------------
//  FILE:    XComInteractiveLockInfo.uc
//  AUTHOR:  David Burchanowski
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

/// This class creates a system of "keys" and "doors". The user much interact with and/or hack one or more
/// key objects before the specified door actors will be unlocked and available.
/// To use this, drop an instance of this actor into a level and fill out the fields as needed. The system 
// will then do the needed data hookups on map load at runtime and everything should just work.

class XComInteractiveLockInfo extends Actor
	placeable
	native;

enum EInteractiveLockType
{
	eInteractiveLockType_RequireOne, // just one key will unlock all doors
	eInteractiveLockType_RequireAll, // all keys must be activated to unlock the doors
};

var() array<XComInteractiveLevelActor> arrKeys;
var() array<XComInteractiveLevelActor> arrDoors;
var() const EInteractiveLockType eLockType;
var() int iLockStrengthModifier;

event PostBeginPlay()
{
	local int Index;
	local bool FoundBrokenActorLink;

	// remove broken links from the door and key arrays and warn about the broken data
	for(Index = arrKeys.Length - 1; Index >= 0; Index--)
	{
		if(arrKeys[Index] == none)
		{
			arrKeys.Remove(Index, 1);
			FoundBrokenActorLink = true;
		}
	}

	for(Index = arrDoors.Length - 1; Index >= 0; Index--)
	{
		if(arrDoors[Index] == none)
		{
			arrDoors.Remove(Index, 1);
			FoundBrokenActorLink = true;
		}
	}

	if(FoundBrokenActorLink)
	{
		`Redscreen("Found a none entry in arrKeys or arrDoors in " $ PathName(self) $ ".\nThis is a task for the LDs to fix. David B. added the redscreen.");
	}
}

/// Returns true if this system is currently locked. I.e., the doors belonging to this system should not open.
event bool IsSystemLocked()
{
	local XComInteractiveLevelActor Key;
	local XComGameState_InteractiveObject ObjectState;

	switch(eLockType)
	{
	case eInteractiveLockType_RequireOne:
		foreach arrKeys(Key)
		{
			ObjectState = Key.GetInteractiveState();
			if(ObjectState.HasBeenHacked())
			{
				return false;
			}
		}
		return true; // no unlocked keys were found

	case eInteractiveLockType_RequireAll:
		foreach arrKeys(Key)
		{
			ObjectState = Key.GetInteractiveState();
			if(!ObjectState.HasBeenHacked())
			{
				return true;
			}
		}
		return false; // no locked keys were found
	};

	`assert(false); // invalid enum value for lock type!
	return false;
}

/// should be called when the lock/unlock status of doors has changed. Rebuilds pathing.
function UpdateDoorPathing()
{
	local XComInteractiveLevelActor InteractiveActor;

	foreach arrDoors(InteractiveActor)
	{
		class'XComWorldData'.static.GetWorldData().RefreshActorTileData(InteractiveActor);
	}
}

defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'LayerIcons.Editor.interactivelockinfo'
		HiddenGame=True
	End Object
	Components.Add(Sprite);

	DrawScale3D=(X=0.25,Y=0.25,Z=0.25)
	DrawScale=0.25
	iLockStrengthModifier=0

	eLockType=eInteractiveLockType_RequireOne

	bEdShouldSnap=true
	bCollideActors=false
	bCollideWorld=false
}