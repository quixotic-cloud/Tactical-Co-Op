//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_CommLink extends X2Action;

var localized string m_sCommLinkMessage;
var XComUIBroadcastWorldMessage kBroadcastWorldMessage;

event bool BlocksAbilityActivation()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
Begin:
	
	kBroadcastWorldMessage = `PRES.GetWorldMessenger().Message(m_sCommLinkMessage, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, , , Unit.m_eTeamVisibilityFlags, , , , class'XComUIBroadcastWorldMessage_UnexpandedLocalizedString');
	if(kBroadcastWorldMessage != none)
	{
		XComUIBroadcastWorldMessage_UnexpandedLocalizedString(kBroadcastWorldMessage).Init_UnexpandedLocalizedString(0, Unit.GetLocation(), Unit.GetVisualizedStateReference(), eColor_Bad, Unit.m_eTeamVisibilityFlags);
	}

	CompleteAction();
}

defaultproperties
{
}

