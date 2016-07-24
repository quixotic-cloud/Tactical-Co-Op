//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Skyranger.uc
//  AUTHOR:  Dan Kaplan  --  10/21/2014
//  PURPOSE: This object represents the instance data for the Skyranger.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Skyranger extends XComGameState_Airship 
	native(Core);

var localized string m_strFlyingToPOI;
var localized string m_strFlyingToMission;
var localized string m_strFlyingToTradingPost;
var localized string m_strReturningToHQ;

//#############################################################################################
//----------------   Variables   --------------------------------------------------------------
//#############################################################################################

// If true, this Skyranger has a squad of XCom soldiers on board.
var() bool SquadOnBoard;

//---------------------------------------------------------------------------------------

//#############################################################################################
//----------------   Movement & Rotation    ---------------------------------------------------
//#############################################################################################

function UpdateMovement(float fDeltaT)
{
	if (CurrentlyInFlight && TargetEntity.ObjectID > 0)
	{
		if (LiftingOff)
		{
			LiftingOff = false;
			Flying = true; //jump straight to flying, no lift off state
		}
		
		if (Flying)
		{
			`GAME.GetGeoscape().m_fTimeScale = InFlightTimeScale; // Speed up the time scale
			UpdateMovementFly(fDeltaT);
			UpdateHeight(fDeltaT);
		}

		if (Landing)
		{
			Landing = false;
			ProcessFlightComplete(); //jump straight to done processing, no landing animation
		}
	}
}

function UpdateHeight(float fDeltaT)
{
	local float PercentComplete;
		
	PercentComplete = GetDistance(Get2DLocation(), SourceLocation) / TotalFlightDistance;
	
	//Update height of the skyranger based on distance to the target so we have a smooth flight arc
	if (PercentComplete <= 0.5)
	{
		if ((FlightHeight - Location.Z) <= GetDistanceNeededToDecelerate(Velocity.Z, Acceleration.Z)) //Start decelerating after passing the threshold
		{
			Velocity.Z -= Acceleration.Z * fDeltaT;
		}
		else if (Velocity.Z < MaxSpeedVertical)
		{
			Velocity.Z += Acceleration.Z * fDeltaT;
		}
	}
	else
	{
		if (Location.Z <= GetDistanceNeededToDecelerate(Velocity.Z, Acceleration.Z)) //Start decelerating after passing the threshold
		{
			Velocity.Z += Acceleration.Z * fDeltaT;
		}
		else if (Velocity.Z > (-1.0 * MaxSpeedVertical)) //reverse velocity check since we are descending and want a negative velocity
		{
			Velocity.Z -= Acceleration.Z * fDeltaT;
		}
	}

	Location.Z += Velocity.Z * fDeltaT;
}

//---------------------------------------------------------------------------------------
function OnTakeOff(optional bool bInstantCamInterp = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComHQPresentationLayer PresLayer;

	PresLayer = `HQPRES;

	// Pause all HQ projects
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ.PauseProjectsForFlight();
	
	// Hide map UI elements while flying
	PresLayer.StrategyMap2D.SetUIState(eSMS_Flight);
	
	if(bInstantCamInterp)
	{
		PresLayer.UIFocusOnEntity(self, 0.66f, 0.0f); //focus the camera on the airship
	}
	else
	{
		PresLayer.UIFocusOnEntity(self, 0.66f); //focus the camera on the airship
	}
}

//---------------------------------------------------------------------------------------
function OnLanded()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bIsAvenger;
	local XComHQPresentationLayer PresLayer;

	PresLayer = `HQPRES;
	
	// Let the HQ know that this flight has been completed
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (!XComHQ.bReturningFromMission)
	{
		`GAME.GetGeoscape().m_fTimeScale = `GAME.GetGeoscape().ONE_MINUTE;
	}
	
	// Show map UI elements which were hidden while flying
	PresLayer.StrategyMap2D.SetUIState(eSMS_Default);
	

	bIsAvenger = (ObjectID == XComHQ.ObjectID);
	XComHQ.OnFlightCompleted(TargetEntity, bIsAvenger);
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_Skyranger';
}

function class<UIStrategyMapItemAnim3D> GetMapItemAnim3DClass()
{
	return class'UIStrategyMapItemAnim3D_Airship';
}

function string GetUIWidgetFlashLibraryName()
{
	return string(class'UIPanel'.default.LibID);
}

function string GetUIPinImagePath()
{
	return "";
}

function string GetUIPinLabel()
{
	return "";
}

// The skeletal mesh for this entity's 3D UI
function SkeletalMesh GetSkeletalMesh()
{
	return SkeletalMesh'SkyrangerIcon_ANIM.Meshes.SM_SkyrangerIcon';
}

function AnimSet GetAnimSet()
{
	return AnimSet'SkyrangerIcon_ANIM.Anims.AS_SkyrangerIcon';
}

function AnimTree GetAnimTree()
{
	return AnimTree'AnimatedUI_ANIMTREE.AircraftIcon_ANIMTREE';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 2.0;
	ScaleVector.Y = 2.0;
	ScaleVector.Z = 2.0;

	return ScaleVector;
}

// Rotation adjustment for the 3D UI static mesh
function Rotator GetMeshRotator()
{
	local Rotator MeshRotation;

	MeshRotation.Roll = 0;
	MeshRotation.Pitch = 0;
	MeshRotation.Yaw = 180 * DegToUnrRot; //Rotate by 180 degrees so the ship is facing the correct way when flying

	return MeshRotation;
}

protected function bool CanInteract()
{
	return false;
}

function bool ShouldBeVisible()
{
	return !IsFlightComplete();
}


//---------------------------------------------------------------------------------------
DefaultProperties
{
}