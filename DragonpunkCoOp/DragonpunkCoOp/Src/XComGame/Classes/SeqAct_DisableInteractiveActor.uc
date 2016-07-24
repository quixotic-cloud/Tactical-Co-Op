/**
 * Disable Interactive Level Actors via kismet
 */
class SeqAct_DisableInteractiveActor extends SequenceAction
	deprecated;

event Activated ()
{
	local SeqVar_Object TargetSeqObj;
	local Object TargetObject;
	local XComInteractiveLevelActor interactiveActor;

	//Disable each XComInteractiveLevelActor that is connected
	foreach LinkedVariables(class'SeqVar_Object',TargetSeqObj,"XComInteractiveLevelActor")
	{
		TargetObject = TargetSeqObj.GetObjectValue();
		
		interactiveActor = XComInteractiveLevelActor(TargetObject);
		interactiveActor.OnDisableInteractiveActor();
	}
}

defaultproperties
{
	ObjName="Interactive Actor - Disable"
	ObjCategory="Level"
	bCallHandler = false

	InputLinks(0)=(LinkDesc="Disable")
	
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="XComInteractiveLevelActor")
}
