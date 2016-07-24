//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_PreppingCallReinforcements extends X2Action;

var localized string m_sPreppingCallReinforcementsMessage;
var XComUIBroadcastWorldMessage kBroadcastWorldMessage;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function RequestLookAtCamera()
	{		
		local X2Camera_LookAtActorTimed LookAtCam;
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
	
	RequestLookAtCamera();
	if( `CHEATMGR.bWorldDebugMessagesEnabled )
	{
		kBroadcastWorldMessage = `PRES.GetWorldMessenger().Message(m_sPreppingCallReinforcementsMessage, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, , , Unit.m_eTeamVisibilityFlags, , , , class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');
		if( kBroadcastWorldMessage != none )
		{
			XComUIBroadcastWorldMessage_UnexpandedLocalizedString(kBroadcastWorldMessage).Init_UnexpandedLocalizedString(0, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, Unit.m_eTeamVisibilityFlags);
		}
	}

	CompleteAction();
}

defaultproperties
{
}

