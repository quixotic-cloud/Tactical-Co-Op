/**
 * Disable Dynamic Trigger Volumes via kismet
 */
class SeqAct_DisableDynamicTriggerVol extends SequenceAction;

event Activated ()
{
	local SeqVar_Object TargetSeqObj;
	local Object TargetObject;
	local DynamicTriggerVolume TriggerVol;

	//Disable each XComInteractiveLevelActor that is connected
	foreach LinkedVariables(class'SeqVar_Object',TargetSeqObj,"DynamicTriggerVolume")
	{
		TargetObject = TargetSeqObj.GetObjectValue();
		
		TriggerVol = DynamicTriggerVolume(TargetObject);
		TriggerVol.bActorDisabled = true;
	}
}

defaultproperties
{
	ObjName="Dynamic Trigger Volume - Disable"
	ObjCategory="Level"
	bCallHandler = false

	InputLinks(0)=(LinkDesc="Disable")
	
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="DynamicTriggerVolume")
}