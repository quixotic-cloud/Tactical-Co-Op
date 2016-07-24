//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComHeadquartersInput.uc
//  AUTHOR:  Tronster Hartley --  04/14/2009
//           Brit Steiner
//  PURPOSE: Hands out input.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComHeadquartersInput extends XComInputBase within XComHeadquartersController;

const MOUSE_EDGE_SCROLL_PIXELS = 5;

var Vector2D m_fFreeMovementMouseScrollRate;

var float MOUSE_GLOBE_SPEED_MULTIPLIER;
var float CONTROLLER_GLOBE_SPEED_MULTIPLIER;

var bool m_bDisableAccept;
var bool m_bDisableCancel;
var bool m_bDisableLeftStick;
var bool m_bDisableRightStick;
var bool m_bDisableDPad;
var bool m_bDisableBumpers;
var bool m_bDisableSelect;
var bool m_bDisableStart;

var bool m_bMouseDraggingGeoscape;
var float m_fKeyPanX;
var float m_fKeyPanY;

simulated function bool PreProcessCheckGameLogic( int cmd, int ActionMask ) 
{
	local XComBaseCamera kCamera;
	local XComCamState_Earth kCameraState;
	local bool bCanStartGeoscapeDrag;
	local bool bCanStartAvengerDrag;
	//local XComHUD kHUD;
	//local StaticMeshActor kHitActor;
	local XComHQPresentationLayer HQPresentationLayer;

	HQPresentationLayer = XComHQPresentationLayer(Outer.Pres);
	if (HQPresentationLayer != none)
	{
		// Geoscape mouse drag panning
		//
		// Process here before flash has a chance to consume our input. This avoid flash-based
		// dead zones that cause panning to be ignored, or worse, to be stuck on. The logic for
		// allowing panning checks for the strategy map UI to be at the top of the flash stack.
		//************************************************************************
		//kHUD = GetXComHUD();
		//if (kHUD != none)
		//{
		//	kHitActor = StaticMeshActor(kHUD.CachedMouseInteractionInterface);
		//}
		kCamera = XComBaseCamera(PlayerCamera);
		if (kCamera != none)
		{
			kCameraState = XComCamState_Earth(kCamera.CameraState);
			if (kCameraState != none)
			{
				bCanStartGeoscapeDrag = (HQPresentationLayer.ScreenStack.GetCurrentScreen().IsA('UIStrategyMap')  
										 && HQPresentationLayer.StrategyMap2D.m_eUIState != eSMS_Flight 
										 && !HittestEventPanel());
			}
			else
			{
				bCanStartAvengerDrag = HQPresentationLayer.Get2DMovie().IsMouseActive();
			}
		}

		if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN &&
			((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0))
		{
			m_bMouseDraggingGeoscape = false;
		}
		else if (cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN &&
			((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0))
		{
			if (bCanStartGeoscapeDrag)
			{
				m_bMouseDraggingGeoscape = true;
				AbortCameraPan();
				return true;
			}
		}

		else if (cmd == class'UIUtilities_Input'.const.FXS_ARROW_UP)
		{
			if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
			{
				if (bCanStartGeoscapeDrag || bCanStartAvengerDrag)
				{
					m_fKeyPanY = 1;
					return true;
				}
			}
			else if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			{
				m_fKeyPanY = 0;
			}
		}
		else if (cmd == class'UIUtilities_Input'.const.FXS_ARROW_LEFT)
		{
			if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
			{
				if (bCanStartGeoscapeDrag || bCanStartAvengerDrag)
				{
					m_fKeyPanX = -1;
					return true;
				}
			}
			else if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			{
				m_fKeyPanX = 0;
			}
		}
		else if (cmd == class'UIUtilities_Input'.const.FXS_ARROW_DOWN)
		{
			if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
			{
				if (bCanStartGeoscapeDrag || bCanStartAvengerDrag)
				{
					m_fKeyPanY = -1;
					return true;
				}
			}
			else if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			{
				m_fKeyPanY = 0;
			}
		}
		else if (cmd == class'UIUtilities_Input'.const.FXS_ARROW_RIGHT)
		{
			if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
			{
				if (bCanStartGeoscapeDrag || bCanStartAvengerDrag)
				{
					m_fKeyPanX = 1;
					return true;
				}
			}
			else if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
			{
				m_fKeyPanX = 0;
			}
		}

		/*
		if(cmd == class'UIUtilities_Input'.const.FXS_ARROW_UP)
		{
		MOUSE_GLOBE_SPEED_MULTIPLIER += 0.00001;
		ClientMessage("New Speed Multiplier:"@MOUSE_GLOBE_SPEED_MULTIPLIER);
		}
		else if(cmd == class'UIUtilities_Input'.const.FXS_ARROW_DOWN)
		{
		MOUSE_GLOBE_SPEED_MULTIPLIER -= 0.00001;
		ClientMessage("New Speed Multiplier:"@MOUSE_GLOBE_SPEED_MULTIPLIER);
		}*/
		//************************************************************************

		// This player is waiting on a camera animation	
		if(HQPresentationLayer.CAMIsBusy())
			return false;

		//Prevent input from disrupting a shuttle from one game area in the UI to another area. 
		if(HQPresentationLayer.m_bIsShuttling) return false;
	}

	return true;
}

simulated function bool HittestEventPanel()
{
	local string CurrentPath, EventsPath; 
	local XComHQPresentationLayer HQPres; 

	HQPres = XComHQPresentationLayer(Outer.Pres);

	CurrentPath = HQPres.Get2DMovie().GetPathUnderMouse();
	EventsPath = string(HQPres.m_kAvengerHUD.EventQueue.MCPath);

	if( InStr(CurrentPath, EventsPath) > -1 || InStr(EventsPath, CurrentPath) > -1 ) 
		return true;
	else
		return false; 
}

// Stops camera from panning 
simulated function AbortCameraPan()
{
	local XComCamState_Earth kCameraState;
	kCameraState = XComCamState_Earth(XComBaseCamera(PlayerCamera).CameraState);
	`EARTH.SetViewLocation(`EARTH.ConvertWorldToEarth(kCameraState.m_kCamera.LastCameraStateOrientation.Focus));
	`EARTH.SetCurrentZoomLevel(`EARTH.GetZoomLevel(kCameraState.m_kCamera.LastCameraStateOrientation.ViewDistance));
	XComHeadquartersCamera(PlayerCamera).NewEarthView(0);
}

simulated function ProcessGeoscapeRotation()
{
	local XComBaseCamera kCamera;
	local XComCamState_Earth kCameraState;
	local Vector2D v2ViewDelta;
	local XComEarth Geoscape;

	kCamera = XComBaseCamera(PlayerCamera);
	if(kCamera == none) return;

	kCameraState = XComCamState_Earth(kCamera.CameraState);
	if(kCameraState == none) return;

	Geoscape = `EARTH;

	if(m_bMouseDraggingGeoscape && (aMouseX != 0.0f || aMouseY != 0.0f))
	{
		v2ViewDelta.X = aMouseX * (-MOUSE_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom);
		v2ViewDelta.Y = aMouseY * (MOUSE_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom * 3.0f);
	}
	else if (m_fKeyPanX != 0 || m_fKeyPanY != 0)
	{
		v2ViewDelta.X = m_fKeyPanX * (CONTROLLER_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom);
		v2ViewDelta.Y = m_fKeyPanY * (-CONTROLLER_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom);
	}
	else if (m_fSteamControllerGeoscapeScrollX != 0 || m_fSteamControllerGeoscapeScrollY != 0)
	{
		v2ViewDelta.X = m_fSteamControllerGeoscapeScrollX * (CONTROLLER_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom);
		v2ViewDelta.Y = m_fSteamControllerGeoscapeScrollY * (-CONTROLLER_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom);

		m_fSteamControllerGeoscapeScrollX = 0;
		m_fSteamControllerGeoscapeScrollY = 0;
	}
	else
	{
		v2ViewDelta.X = aTurn * (CONTROLLER_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom);
		v2ViewDelta.Y = aLookUp * (-CONTROLLER_GLOBE_SPEED_MULTIPLIER * Geoscape.fCurrentZoom);
	}
	Geoscape.MoveViewLocation(v2ViewDelta);
}

simulated function bool PostProcessCheckGameLogic( float DeltaTime )
{
	ProcessGeoscapeRotation();

	if (m_fSteamControllerGeoscapeZoomOffset != 0)
	{
		`EARTH.ApplyImmediateZoomOffset(m_fSteamControllerGeoscapeZoomOffset);
		m_fSteamControllerGeoscapeZoomOffset = 0;
	}
	return true;
}

simulated function bool PauseKey( int ActionMask )
{
	return false;
}

function bool EscapeKey( int ActionMask )
{
	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
		return Start_Button( ActionMask );
	else 
		return false;
}

function bool Start_Button( int ActionMask )
{
	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) == 0) return false; 		

	// DO NOT allow the pause menu during the dropship loading sequence. That would make one hell of a save game... -bsteiner
	if( !XComHQPresentationLayer(Outer.Pres).IsInState('State_DropshipBriefing') && XComHQPresentationLayer(Outer.Pres).m_bCanPause ) //jmk
	{
		XComHQPresentationLayer(Outer.Pres).UIPauseMenu( );
	}

	return true;
}

function bool Key_F5(int ActionMask)
{
	if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		`AUTOSAVEMGR.DoQuicksave(QuicksaveComplete);
		return true;
	}
	return false;
}

function bool Key_F10( int ActionMask )
{
	if ((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		`AUTOSAVEMGR.DoQuicksave(QuicksaveComplete);
		return true;
	} 
	return false;
}

private function QuicksaveComplete(bool bWasSuccessful)
{
	if( !bWasSuccessful )
		XComHQPresentationLayer(Outer.Pres).PlayUISound(eSUISound_MenuClose);
}

function bool IsMouseInHUDArea()
{	
	local Vector2D v2MousePosition;

	// Grab the current mouse location.
	v2MousePosition = LocalPlayer(Outer.Player).ViewportClient.GetMousePosition();

	return (v2MousePosition.Y < 60 ); //Pixel height of the facility menu in Flash. 
}

function bool LMouse( int ActionMask )
{
	local XComHUD kHUD;

	// This player is waiting on a camera animation
	if(XComHQPresentationLayer(Outer.Pres) != none && XComHQPresentationLayer(Outer.Pres).CAMIsBusy())
		return false;

	if(TestMouseConsumedByFlash())
		return false;

	`log("**UIINPUT: BEGIN LMOUSE****************", , 'uixcom');
	kHUD = GetXComHUD();
	if(kHUD == none) return false;

	if((ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		m_bMouseDraggingGeoscape = false;
		if(kHUD.CachedMouseInteractionInterface != none)
		{
			kHUD.CachedMouseInteractionInterface.OnMouseEvent(class'UIUtilities_Input'.const.FXS_L_MOUSE_UP, class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
		}
	}
	return false;
}

state HQ_FreeMovement
{
	event BeginState( name PrevStateName )
	{
		super.BeginState(PrevStateName);

		// reset the mouse scroll
		m_fFreeMovementMouseScrollRate.x = 0.0;
		m_fFreeMovementMouseScrollRate.y = 0.0;

		`log("Entering Input State 'HQ_FreeMovement' ",,'uixcom');
	}

	event EndState( name NextStateName )
	{
		super.EndState(NextStateName);
		`log("Leaving Input State 'HQ_FreeMovement' ",,'uixcom'); 
	}

	function bool Stick_Right(float _x, float _y, int ActionMask)
	{
		local XComHQPresentationLayer pres;
		local Vector vLoc; 
		local float fStepSize; 
		local float fCurrentViewDist;
		local float fMinSpeed;

		fMinSpeed = 128.0f;

		XComHeadquartersCamera(PlayerCamera).StartRoomView('FreeMovement', 2.0f);

		pres = XComHQPresentationLayer(Outer.Pres);

		//Step is a percentage of the view distance. 
		pres.GetCamera().GetViewDistance( fCurrentViewDist );
		fStepSize = (fCurrentViewDist / (class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance() - class'XComCamState_HQ_BaseView'.default.m_fPCDefaultMinViewDistance)) * 500;

		vLoc.x = _x * fMinSpeed + _x * fStepSize;
		vLoc.y = 0.0;
		vLoc.z = _y * fMinSpeed + _y * fStepSize;
		
		pres.GetCamera().LookRelative( vLoc, pres.GetCamera().CurrentZoom );

		return true;
	}

	simulated function CheckMouseScroll(XComHQPresentationLayer kPres, float fDeltaTime)
	{
		local Vector2D kMousePos, v2TopLeft, v2BottomRight;
		local Vector vLoc; 
		local float fMaxRate;
		local float fRate;

		local float fDefaultViewDistance;
		local float fCurrentViewDistance;

		// If mouse isn't yet fully initialized bail out - sbatista 6/17/2013
		if(!kPres.GetMouseCoords(kMousePos)) return;

		fDefaultViewDistance = class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance() - class'XComCamState_HQ_BaseView'.default.m_fPCDefaultMinViewDistance;
		kPres.GetCamera().GetViewDistance( fCurrentViewDistance );

		fMaxRate = 1000.0; // units per second
		fRate = max(50.0, fMaxRate * (fCurrentViewDistance / fDefaultViewDistance)) * fDeltaTime;
		
		kPres.Get2DMovie().GetScaledMouseRect( v2Topleft, v2BottomRight ); 

		// determine if any scrolling is being requested
		if( kMousePos.Y <= v2TopLeft.Y + MOUSE_EDGE_SCROLL_PIXELS )             //Up
			m_fFreeMovementMouseScrollRate.y += fRate;
		else if( kMousePos.Y >= v2BottomRight.Y - MOUSE_EDGE_SCROLL_PIXELS )    //Down
			m_fFreeMovementMouseScrollRate.y -= fRate;
		else
			m_fFreeMovementMouseScrollRate.y = 0.0;

		if( kMousePos.X <= v2TopLeft.X + MOUSE_EDGE_SCROLL_PIXELS )             //Left
			m_fFreeMovementMouseScrollRate.x += fRate;
		else if( kMousePos.X >= v2BottomRight.X - MOUSE_EDGE_SCROLL_PIXELS )   //Right
			m_fFreeMovementMouseScrollRate.x -= fRate;
		else
			m_fFreeMovementMouseScrollRate.x = 0.0;

		clamp(m_fFreeMovementMouseScrollRate.x, 0.0, fMaxRate);
		clamp(m_fFreeMovementMouseScrollRate.y, 0.0, fMaxRate);

		// if the mouse is requesting a scroll, do it
		if( m_fFreeMovementMouseScrollRate.x != 0.0 || m_fFreeMovementMouseScrollRate.y != 0.0 )
		{
			XComHeadquartersCamera(PlayerCamera).StartRoomView('FreeMovement', 2.0f);
			vLoc.x = m_fFreeMovementMouseScrollRate.x;
			vLoc.z = m_fFreeMovementMouseScrollRate.y;
			kPres.GetCamera().LookRelative( vLoc, kPres.GetCamera().CurrentZoom );
		}
	}

	simulated function CheckKeyPan(XComHQPresentationLayer kPres, float fDeltaTime)
	{
		local Vector vLoc; 
		local float fMaxRate;
		local float fRate;

		local float fDefaultViewDistance;
		local float fCurrentViewDistance;

		fDefaultViewDistance = class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance() - class'XComCamState_HQ_BaseView'.default.m_fPCDefaultMinViewDistance;
		kPres.GetCamera().GetViewDistance( fCurrentViewDistance );

		fMaxRate = 10000.0; // units per second
		fRate = max(2500.0, fMaxRate * (fCurrentViewDistance / fDefaultViewDistance)) * fDeltaTime;

		vLoc.x -= (m_fKeyPanX * fRate);
		vLoc.z += (m_fKeyPanY * fRate);

		clamp(vLoc.x, 0.0, fMaxRate);
		clamp(vLoc.z, 0.0, fMaxRate);

		if( vLoc.x != 0.0 || vLoc.z != 0.0 )
		{
			XComHeadquartersCamera(PlayerCamera).StartRoomView('FreeMovement', 2.0f);
			kPres.GetCamera().LookRelative( vLoc, kPres.GetCamera().CurrentZoom );
		}
	}

	simulated function bool PostProcessCheckGameLogic( float DeltaTime )
	{
		local XComHQPresentationLayer kPres;

		kPres = XComHQPresentationLayer( Outer.Pres );
		if( kPres.Get2DMovie().IsMouseActive() )
		{
			CheckMouseScroll( kPres, DeltaTime );
			CheckKeyPan( kPres, DeltaTime );
		}

		return super.PostProcessCheckGameLogic( DeltaTime );
	}

	simulated function ZoomCamera(int iTicks)
	{
		local XComHeadquartersCamera kCamera;
		local float fDefaultViewDistance;
		local float fCurrentViewDistance;
		local float fNewViewDistance;
		local int iTicksForFullZoom; // number of pixels we need to move the mouse to go from no zoom to full zoom

		iTicksForFullZoom = 4;
		
		kCamera = XComHeadquartersCamera(PlayerCamera);
		kCamera.StartRoomView('FreeMovement', 2.0f);

		fDefaultViewDistance = class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance();
		kCamera.GetViewDistance( fCurrentViewDistance );
		fNewViewDistance = fCurrentViewDistance + (((fDefaultViewDistance - class'XComCamState_HQ_BaseView'.default.m_fPCDefaultMinViewDistance) / iTicksForFullZoom) * iTicks);
			
		fNewViewDistance = fclamp( fNewViewDistance, -1000.0, fDefaultViewDistance );
		kCamera.SetViewDistance( fNewViewDistance );
	}

	function bool MouseScrollUp( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			ZoomCamera(-1);
		}
		return true; 
	}

	function bool MouseScrollDown( int ActionMask )
	{
		if (( ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_PRESS) != 0)
		{
			ZoomCamera(1);
		}
		return true; 
	}

	function bool Trigger_Left(float fTrigger, int ActionMask)
	{
		local XComHQPresentationLayer pres;
		local float yPercent; 
		local float fDiff; 		
		local float fCurrentViewDist;

		XComHeadquartersCamera(PlayerCamera).StartRoomView('FreeMovement', 2.0f);

		//Find percentage of movement requested, relative to step size. 
		yPercent = fTrigger; 
		if( yPercent > 1 ) yPercent = 1; 
		if( yPercent < 0 ) yPercent = 0; 

		pres = XComHQPresentationLayer(Outer.Pres);
		pres.GetCamera().GetViewDistance( fCurrentViewDist );
		fDiff = class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance() - (yPercent * class'XComCamState_HQ_BaseView'.static.GetPlatformViewDistance());

		`log("Trigger zoom: fTrigger:" @fTrigger @ "     yPercent: " @yPercent @"      fCurrentViewDist: " @ fCurrentViewDist @"      fDiff: " @ fDiff ,,'uixcom'); 

		pres.GetCamera().SetViewDistance( fDiff );

		return true;
	}
}

defaultproperties
{
	MOUSE_GLOBE_SPEED_MULTIPLIER = 0.0006f
	CONTROLLER_GLOBE_SPEED_MULTIPLIER = 0.006f
}
