//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ConcealmentLost extends X2Action;

var localized string m_sConcealmentLostMessage;
var XComUIBroadcastWorldMessage kBroadcastWorldMessage;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	if( `CHEATMGR.bWorldDebugMessagesEnabled )
	{
		kBroadcastWorldMessage = `PRES.GetWorldMessenger().Message(m_sConcealmentLostMessage, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, , , Unit.m_eTeamVisibilityFlags, , , , class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');
		if( kBroadcastWorldMessage != none )
		{
			XComUIBroadcastWorldMessage_UnexpandedLocalizedString(kBroadcastWorldMessage).Init_UnexpandedLocalizedString(0, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, Unit.m_eTeamVisibilityFlags);
		}
	}

	CompleteAction();
}

defaultproperties
{
	bCauseTimeDilationWhenInterrupting = true
}

