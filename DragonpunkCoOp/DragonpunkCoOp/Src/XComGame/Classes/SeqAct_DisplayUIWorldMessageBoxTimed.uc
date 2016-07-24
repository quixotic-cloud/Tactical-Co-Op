//-----------------------------------------------------------
//Show a floating message in the UI messaging system, floating at vLocation
//-----------------------------------------------------------
class SeqAct_DisplayUIWorldMessageBoxTimed extends SequenceAction;

var string Message;
var XGUnit kUnit;
var vector vLocation;
var() string MessageBoxIdentifier;
var() float DisplayTime;
var() bool Steady;

event Activated()
{
	local XComTacticalController kTacticalController;
	local string LocalizedMessage;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		LocalizedMessage = ParseLocalizedPropertyPath(Message);
		if (LocalizedMessage != "")
		{
			Message = LocalizedMessage;
		}
		
		// Location priority: kUnit primarily, then vLocation 		
		if( kUnit == none )
		{
			XComPresentationLayer(kTacticalController.Pres).GetWorldMessenger().Message(class'UIUtilities_Input'.static.InsertGamepadIcons(Message), vLocation,,,INT(Steady),MessageBoxIdentifier,,,,DisplayTime);
		}
		else
		{ 
			XComPresentationLayer(kTacticalController.Pres).GetWorldMessenger().Message(class'UIUtilities_Input'.static.InsertGamepadIcons(Message), kUnit.GetLocation(), kUnit.GetVisualizedStateReference() ,,INT(Steady),MessageBoxIdentifier,,,,DisplayTime);
		}
		break;
	}
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Floating World Message Box - Spawn"
	bCallHandler = false
	DisplayTime = 5.0
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Display Message",PropertyName=Message)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Unit...",bWriteable=true,PropertyName=kUnit)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Vector',LinkDesc="... or VLocation",bWriteable=true,PropertyName=vLocation)

}
