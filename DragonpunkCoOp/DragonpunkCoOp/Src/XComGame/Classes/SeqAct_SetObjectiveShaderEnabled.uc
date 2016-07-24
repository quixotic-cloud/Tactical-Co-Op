//-----------------------------------------------------------
//Enables or disables an Interactive Object's Objective shader
//-----------------------------------------------------------
class SeqAct_SetObjectiveShaderEnabled extends SequenceAction;

var XComGameState_InteractiveObject InteractiveObject;

event Activated()
{
	local XComGameState NewGameState;
	local XComGameState_InteractiveObject NewInteractiveObject;
	local bool bEnable;

	bEnable = InputLinks[0].bHasImpulse;

	if( InteractiveObject == None || InteractiveObject.GetRequiresObjectiveGlint() == bEnable )
	{
		return;
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_SetObjectiveShaderEnabled: " @ InteractiveObject.GetVisualizer() @ " (" @ InteractiveObject.ObjectID @ ")");

	NewInteractiveObject = XComGameState_InteractiveObject(NewGameState.CreateStateObject(class'XComGameState_InteractiveObject', InteractiveObject.ObjectID));
	NewInteractiveObject.SetRequiresObjectiveGlint(bEnable);

	`XEVENTMGR.TriggerEvent( 'ObjectiveGlintStatusChanged', NewInteractiveObject, NewInteractiveObject, NewGameState );
	
	NewGameState.AddStateObject(NewInteractiveObject);
	`TACTICALRULES.SubmitGameState(NewGameState);
}

defaultproperties
{
	ObjCategory="InteractiveObject"
	ObjName="Set Objective Shader Enabled"
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")
	
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks(0)=(ExpectedType=class'SeqVar_InteractiveObject',LinkDesc="InteractiveObject",PropertyName=InteractiveObject)
}
