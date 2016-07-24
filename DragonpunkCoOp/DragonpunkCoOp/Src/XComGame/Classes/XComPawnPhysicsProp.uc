//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComPawnPhysicsProp.cpp
//  AUTHOR:  Elliot Pace
//  PURPOSE: Used as prop attachments for pawns.
//           This is an implementation similar to:
//           https://udn.epicgames.com/lists/showpost.php?list=unprog3&id=57556&lessthan=&show=20
//           I had no success with using just a SkeletalMeshComponent for the pawns, because the
//           actor has to use PHYS_RigidBody.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComPawnPhysicsProp extends XComSkeletalMeshActor;

var private XComAnimNodeBlendByMovementType BlendByMovement;
var private AnimNodeSequence                FinishAnimNodeSequence; //Stores the sequence we are waiting on in FinishAnim
var private Vector                          LastHeadBoneLocation;
var private Vector                          CurrentHeadBoneLocation;

function bool ShouldSaveForCheckpoint()
{
	return false;
}

event Tick(float DeltaTime)
{
	//If we aren't technically using rigid body physics, but instead are "faking it" - still apply our rigid body forces
	if(Physics != PHYS_RigidBody)
	{
		ScriptAddRBGravAndDamping();
	}
}

auto state Dormant
{	
begin:
}

defaultproperties
{
	TickGroup=TG_PostAsyncWork	
	bStatic=false
	bNoDelete=false
}