/**
 * Enable Interactive Level Actors via kismet
 */
class SeqAct_EnableInteractiveActor extends SequenceAction;

event Activated()
{
	local X2TacticalGameRuleset Rules;
	local SeqVar_InteractiveObject TargetSeqObj;
	local XComGameState NewGameState;
	local XComGameState_InteractiveObject ObjectState;

	Rules = `TACTICALRULES;

	//Enable/disable each XComGameState_InteractiveObject that is connected
	foreach LinkedVariables(class'SeqVar_InteractiveObject', TargetSeqObj, "XComGame_InteractiveObject")
	{
		ObjectState = TargetSeqObj.GetInteractiveObject();
		if( ObjectState != None )
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_EnableInteractiveActor: " @ ObjectState.GetVisualizer() @ " (" @ ObjectState.ObjectID @ ")");

			ObjectState = XComGameState_InteractiveObject(NewGameState.CreateStateObject(class'XComGameState_InteractiveObject', ObjectState.ObjectID));
			ObjectState.IsEnabled = InputLinks[0].bHasImpulse;
			
			NewGameState.AddStateObject(ObjectState);
			Rules.SubmitGameState(NewGameState);
		}
	}
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 2;
}

defaultproperties
{
	ObjName="Set Interactive Object Enabled"
	ObjCategory="Level"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")
	
	VariableLinks(0)=(ExpectedType=class'SeqVar_InteractiveObject', LinkDesc="XComGame_InteractiveObject")
}
