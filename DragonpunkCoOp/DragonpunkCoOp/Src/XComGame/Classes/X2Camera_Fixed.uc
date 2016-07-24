//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_Fixed.uc
//  AUTHOR:  Ryan McFall  --  10/03/2014
//  PURPOSE: A simple camera that cuts instantly and sits in one place.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_Fixed extends X2Camera;

var private TPOV CameraView;
var private bool bActivated;

function SetCameraView(const out TPOV InCameraView)
{
	if( !bActivated )
	{
		CameraView = InCameraView;
	}
	else
	{
		`redscreen("X2Camera_Fixed.SetCameraView must be called prior to the fixed camera being activated!");
	}
}

function Activated(TPOV CurrentPOV, X2Camera PreviousActiveCamera, X2Camera_LookAt LastActiveLookAtCamera)
{
	bActivated = true;
}

function TPOV GetCameraLocationAndOrientation()
{
	return CameraView;
}

