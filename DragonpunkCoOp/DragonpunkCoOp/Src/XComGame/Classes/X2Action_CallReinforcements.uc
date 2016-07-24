//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_CallReinforcements extends X2Action;

var localized string m_sCallReinforcementsMessage;
var XComUIBroadcastWorldMessage kBroadcastWorldMessage;
var X2Camera_LookAtActorTimed LookAtCam;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function RequestLookAtCamera()
	{		
		local XComCamera Cam;

		if( Unit != none )
		{	
			Cam = XComCamera(GetALocalPlayerController().PlayerCamera);
			if(Cam == none) return;

			LookAtCam = new class'X2Camera_LookAtActorTimed';
			LookAtCam.ActorToFollow = Unit;
			LookAtCam.LookAtDuration = 2.0f;
			Cam.CameraStack.AddCamera(LookAtCam);
		}
	}
Begin:
	
	if( !bNewUnitSelected )
	{
		RequestLookAtCamera();
	}
	if( `CHEATMGR.bWorldDebugMessagesEnabled )
	{
		kBroadcastWorldMessage = `PRES.GetWorldMessenger().Message(m_sCallReinforcementsMessage, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, , , Unit.m_eTeamVisibilityFlags, , , , class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');
		if( kBroadcastWorldMessage != none )
		{
			XComUIBroadcastWorldMessage_UnexpandedLocalizedString(kBroadcastWorldMessage).Init_UnexpandedLocalizedString(0, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, Unit.m_eTeamVisibilityFlags);
		}
	}
	StartReinforcementsCountdown(Unit);

	CompleteAction();
}

function StartReinforcementsCountdown( XGUnit kUnit )
{
	// no longer using this action
	`RedScreen("X2Action_CallReinforcements called - we no longer expect to be using this action");
}

event HandleNewUnitSelection()
{
	if( LookAtCam != None )
	{
		`CAMERASTACK.RemoveCamera(LookAtCam);
		LookAtCam = None;
	}
}

defaultproperties
{
}

