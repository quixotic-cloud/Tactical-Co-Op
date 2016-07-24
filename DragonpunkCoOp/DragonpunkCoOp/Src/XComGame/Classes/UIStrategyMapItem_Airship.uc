//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMapItem_Airship
//  AUTHOR:  Joe Weinhoffer -- 07/2015
//  PURPOSE: This file represents an Airship on the StrategyMap.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMapItem_Airship extends UIStrategyMapItem 
	dependson(XComAnimNodeBlendDynamic);

// This function feeds values from the XComGameState_Airship into the animation nodes
function UpdateAnimMapItem3DVisuals()
{
	local XComGameStateHistory History;
	local XComGameState_Airship AirshipState;
	local UIStrategyMapItemAnim3D_Airship AirshipMapItem3D;
	local Vector NewVelocity;
	//local Vector NewAcceleration;

	History = `XCOMHISTORY;
	AirshipState = XComGameState_Airship(History.GetGameStateForObjectID(GeoscapeEntityRef.ObjectID));
	AirshipMapItem3D = UIStrategyMapItemAnim3D_Airship(AnimMapItem3D);
	
	// This entity is an Airship, so update the velocity and acceleration of its 3D anim map
	if (AirshipState != None && AirshipMapItem3D != None)
	{
		UpdateAirshipAnimations(AirshipState, AirshipMapItem3D);
	
		NewVelocity = AirshipState.GetAnimNodeVelocity();
		if (NewVelocity != AirshipMapItem3D.GetAnimVelocityInputs())
		{
			AirshipMapItem3D.SetAnimVelocityInputs(NewVelocity);
		}

		//NewAcceleration = AirshipState.GetAnimNodeAcceleration();
		//if (NewAcceleration != AirshipMapItem3D.GetAnimAccelerationInputs())
		//{
		//	AirshipMapItem3D.SetAnimAccelerationInputs(NewAcceleration);
		//}
	}
}

function UpdateAirshipAnimations(XComGameState_Airship AirshipState, UIStrategyMapItemAnim3D_Airship AirshipMapItem3D)
{
	if (AirshipState.LiftingOff && !AirshipMapItem3D.IsTakeoffPlaying())
	{
		if (!AirshipMapItem3D.IsTakeoffRelevant()) // Takeoff sequence is not playing and has not started
		{
			AirshipMapItem3D.PlayTakeoff();
		}
		else // Takeoff sequence is not playing and was the most recent animation to finish
		{
			AirshipState.ProcessFlightBegin();
			AirshipMapItem3D.PlayFlyingIdle();
		}
	}
	else if (AirshipState.Landing && !AirshipMapItem3D.IsLandPlaying())
	{
		if (!AirshipMapItem3D.IsLandRelevant()) // Landing sequence is not playing and has not started
		{
			AirshipMapItem3D.PlayLand();
		}
		else // Landing sequence is not playing and was the most recent animation to finish
		{
			AirshipState.ProcessFlightComplete();
			AirshipMapItem3D.PlayLandedIdle();
		}
	}
}

defaultproperties
{
}