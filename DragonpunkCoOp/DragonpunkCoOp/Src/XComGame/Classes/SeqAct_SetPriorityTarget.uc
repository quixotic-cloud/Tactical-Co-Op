class SeqAct_SetPriorityTarget extends SequenceAction;

var XComGameState_Unit TargetUnit; // Target unit
var XComGameState_InteractiveObject TargetInteractiveObject;

event Activated()
{
	local XComGameState NewGameState;
	local XComGameState_AIPlayerData kAIData;
	local StateObjectReference TargetReference;
	local SeqVar_InteractiveObject TargetSeqObj;
	local SeqVar_GameUnit kGameUnit;
	local XComGameStateHistory History;
	History = `XCOMHISTORY;

	foreach LinkedVariables(class'SeqVar_GameUnit',kGameUnit,"Target Unit")
	{
		TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(kGameUnit.IntValue));
		break;
	}

	foreach LinkedVariables(class'SeqVar_InteractiveObject',TargetSeqObj,"Target Object")
	{
		TargetInteractiveObject = TargetSeqObj.GetInteractiveObject();
		break;
	}

	if (TargetUnit != None)
	{
		TargetReference = TargetUnit.GetReference();
	}
	else if (TargetInteractiveObject != None)
	{
		TargetReference = TargetInteractiveObject.GetReference();
	}

	if (TargetReference.ObjectID <= 0)
	{
		`RedScreen("SeqAct_SetPriorityTarget activated with no valid target!");
	}
	else
	{
		// Kick off mass alert to location.
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Kismet - SetPriorityTarget");
		kAIData = XComGameState_AIPlayerData(`XCOMHISTORY.GetGameStateForObjectID(XGAIPlayer(`BATTLE.GetAIPlayer()).GetAIDataID()));
		if (kAIData != None)
		{
			kAIData.SetPriorityTarget(TargetReference);
		}
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

defaultproperties
{
	ObjCategory="Gameplay"
	ObjName="Set Priority Target"
	bConvertedForReplaySystem=true

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_GameUnit',LinkDesc="Target Unit")
	VariableLinks(1)=(ExpectedType=class'SeqVar_InteractiveObject', LinkDesc="Target Object")
}