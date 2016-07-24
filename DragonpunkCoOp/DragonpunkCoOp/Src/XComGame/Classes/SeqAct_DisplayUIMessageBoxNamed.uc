//-----------------------------------------------------------
//Show a tactical message in the UI messaging system, allowed to persist until removed.
//-----------------------------------------------------------
class SeqAct_DisplayUIMessageBoxNamed extends SequenceAction;

var string ID;
var string Message;
var bool bCreate;
var bool bDestroy;

event Activated()
{
	local XComTacticalController kTacticalController;
	//`log("+++ SeqAct_DisplayUIMessageBoxNamed");

	if( bCreate )
	{
		foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
		{
			XComPresentationLayer(kTacticalController.Pres).GetMessenger().Message(class'UIUtilities_Input'.static.InsertGamepadIconsMessenger(Message), eIcon_ExclamationMark, ,-1.0, ID);
			//`log("+++ SeqAct_DisplayUIMessageBoxNamed Create " @ ID);

			break;
		}
	}
	if( bDestroy )
	{
		foreach GetWorldInfo().AllControllers(class'XComTacticalController', kTacticalController)
		{
			XComPresentationLayer(kTacticalController.Pres).GetMessenger().RemoveMessage(name(ID));
			//`log("+++ SeqAct_DisplayUIMessageBoxNamed Destroy " @ ID);

			break;
		}
	}
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Spawn Persistant Message Box"
	bCallHandler = false
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_String',LinkDesc="ID",PropertyName=ID)
	VariableLinks(1)=(ExpectedType=class'SeqVar_String',LinkDesc="Display Message",PropertyName=Message)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Bool',LinkDesc="Create?",bWriteable=true,PropertyName=bCreate)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Bool',LinkDesc="Destroy?",bWriteable=true,PropertyName=bDestroy)

}
