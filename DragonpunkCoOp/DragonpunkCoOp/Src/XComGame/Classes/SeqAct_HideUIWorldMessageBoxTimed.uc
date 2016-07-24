//-----------------------------------------------------------
//Show a floating message in the UI messaging system, floating at vLocation
//-----------------------------------------------------------
class SeqAct_HideUIWorldMessageBoxTimed extends SequenceAction;

var() string MessageBoxIdentifier;

event Activated()
{
	local XComTacticalController kTacticalController;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		XComPresentationLayer(kTacticalController.Pres).GetWorldMessenger().RemoveMessage( MessageBoxIdentifier );
		break;
	}
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Floating World Message Box - Hide"
	bCallHandler = false

	VariableLinks.Empty
}
