//-----------------------------------------------------------
//Show a tactical message in the UI messaging system.
//-----------------------------------------------------------
class SeqAct_DisplayUIMessageBoxTimed extends SequenceAction;

var string Message;
var float DisplayTime;

event Activated()
{
	local XComTacticalController kTacticalController;

	foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
	{
		if(DisplayTime < 1.0)
		{
			DisplayTime = 1.0;
			`log("Warning: You've used a UI Message Box in Kismet but failed to define the Display Time properly! (instance = " $self $")");
		}

		XComPresentationLayer(kTacticalController.Pres).GetMessenger().Message(class'UIUtilities_Input'.static.InsertGamepadIconsMessenger(Message), , ,DisplayTime);
		break;
	}
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Spawn Timed Message Box"
	bCallHandler = false
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="Display Message",PropertyName=Message)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Float',LinkDesc="Display Time",bWriteable=true,PropertyName=DisplayTime)

}
