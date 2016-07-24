//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2Actor_TurretBase.uc    
//  AUTHOR:  Alex Cheng  --  5/09/2015
//  PURPOSE: Mesh to display the base of the turret.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Actor_TurretBase extends Actor
	native;

var protected SkeletalMeshComponent MeshComp;

function InitTurretBaseMesh(vector vLocation, rotator vRotator, SkeletalMeshComponent BaseComponent)
{
	AttachComponent(BaseComponent);
	MeshComp = BaseComponent;

	UpdateLocationAndRotation(vLocation, vRotator);
}

function UpdateLocationAndRotation(vector vLocation, rotator vRotator)
{
	SetLocation(vLocation);
	SetRotation(vRotator);
}

DefaultProperties
{
}