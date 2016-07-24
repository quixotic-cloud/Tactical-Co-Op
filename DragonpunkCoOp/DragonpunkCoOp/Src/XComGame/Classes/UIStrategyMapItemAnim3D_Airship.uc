//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItemAnim3D
//  AUTHOR:  Joe Weinhoffer -- 07/2015
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItemAnim3D_Airship extends UIStrategyMapItemAnim3D;

var AnimNodeSequenceBlendByAim AimAcceleration[NUM_TILES];
var AnimNodeSequenceBlendByAim AimVelocity[NUM_TILES];
var AnimNodeSequenceBlendByAim AimTurningAngle[NUM_TILES];
var XComAnimNodeBlendDynamic BlendDynamicNode[NUM_TILES];

var AnimNodeSequence TakeoffSequence;
var AnimNodeSequence LandingSequence;

var CustomAnimParams AnimParams;

function SetUpAnimMapItem(SkeletalMesh UIMesh, AnimTree UIAnimTree, AnimSet UIAnimSet)
{
	super.SetUpAnimMapItem(UIMesh, UIAnimTree, UIAnimSet);

	// After all of the map item skeleton meshes are set up, play the landed idle on each of them
	PlayLandedIdle();
}

function PlayLand()
{
	local int i;

	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'Land';
	
	for (i = 0; i < NUM_TILES; ++i)
	{
		if (BlendDynamicNode[i] != None)
		{
			LandingSequence = BlendDynamicNode[i].PlayDynamicAnim(AnimParams);
		}
	}
}

function bool IsLandPlaying()
{
	return LandingSequence != none && LandingSequence.bPlaying;
}

function bool IsLandRelevant()
{
	return LandingSequence != none && LandingSequence.bRelevant;
}

function PlayTakeoff()
{
	local int i;

	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'Takeoff';
	
	for (i = 0; i < NUM_TILES; ++i)
	{
		if (BlendDynamicNode[i] != None)
		{
			TakeoffSequence = BlendDynamicNode[i].PlayDynamicAnim(AnimParams);
		}
	}
}

function bool IsTakeoffPlaying()
{
	return TakeoffSequence != none && TakeoffSequence.bPlaying;
}

function bool IsTakeoffRelevant()
{
	return TakeoffSequence != none && TakeoffSequence.bRelevant;
}

function PlayFlyingIdle()
{
	local int i;
	
	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'FlyingIdle';
	AnimParams.Looping = true;

	for (i = 0; i < NUM_TILES; ++i)
	{
		if (BlendDynamicNode[i] != None)
		{
			BlendDynamicNode[i].PlayDynamicAnim(AnimParams);
		}
	}
}

function PlayLandedIdle()
{
	local int i;

	AnimParams = default.AnimParams;
	AnimParams.AnimName = 'LandedIdle';
	AnimParams.Looping = true;
	
	for (i = 0; i < NUM_TILES; ++i)
	{
		if (BlendDynamicNode[i] != None)
		{
			BlendDynamicNode[i].PlayDynamicAnim(AnimParams);
		}
	}
}

function SetUpAnimNodes(int MeshIndex)
{
	local SkeletalMeshComponent SkelComp;
	
	SkelComp = SkeletalMeshs[MeshIndex];

	AimAcceleration[MeshIndex] = AnimNodeSequenceBlendByAim(SkelComp.Animations.FindAnimNode('AimAcceleration'));
	AimVelocity[MeshIndex] = AnimNodeSequenceBlendByAim(SkelComp.Animations.FindAnimNode('AimTranslate'));
	AimTurningAngle[MeshIndex] = AnimNodeSequenceBlendByAim(SkelComp.Animations.FindAnimNode('AimTorque'));
	BlendDynamicNode[MeshIndex] = XComAnimNodeBlendDynamic(SkelComp.Animations.FindAnimNode('BlendDynamic'));

	if (AimAcceleration[MeshIndex] != None)
	{
		AimAcceleration[MeshIndex].Aim.X = 0.0f;
		AimAcceleration[MeshIndex].Aim.Y = 0.0f;
	}

	if (AimVelocity[MeshIndex] != None)
	{
		AimVelocity[MeshIndex].Aim.X = 0.0f;
		AimVelocity[MeshIndex].Aim.Y = 0.0f;
	}

	if (AimTurningAngle[MeshIndex] != None)
	{
		AimTurningAngle[MeshIndex].Aim.X = 0.0f;
		AimTurningAngle[MeshIndex].Aim.Y = 0.0f;
	}
}

function SetAnimVelocityInputs(Vector NewVelocity)
{
	local int i;
	
	AnimVelocity = NewVelocity;
	
	for (i = 0; i < NUM_TILES; ++i)
	{
		AimVelocity[i].Aim.X = NewVelocity.X;
		AimVelocity[i].Aim.Y = NewVelocity.Y;
	}
}

function SetAnimAccelerationInputs(Vector NewAcceleration)
{
	local int i;

	AnimAcceleration = NewAcceleration;
	
	for (i = 0; i < NUM_TILES; ++i)
	{
		AimAcceleration[i].Aim.X = NewAcceleration.X;
		AimAcceleration[i].Aim.Y = NewAcceleration.Y;
	}
}


//--------------------------------------------------------------------------------------- 
DefaultProperties
{
}