/**
 * Set the toughness of an Interactive Level Object via kismet
 */
class SeqAct_SetInteractiveObjectToughness extends SequenceAction;

// The health value to be set on the Interactive Object when using the "Set Health" input link, or 
// The health value to modify on the Interactive Object when using the "Modify Health" input link
var() int HealthValue;

// The health value to be set on the Interactive Object when using the "Set Toughness" input link 
// equals the health value of this Toughness template.
var() XComDestructibleActor_Toughness Toughness;

event Activated()
{
	// This is currently not needed, and as there are no test cases for it, I'll wait to convert it until such time as it
	// is necessary, which may be never - dburchanowski
	/*
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
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SeqAct_SetInteractiveObjectToughness: (" @ ObjectState.ObjectID @ ")");

			ObjectState = XComGameState_InteractiveObject(NewGameState.CreateStateObject(class'XComGameState_InteractiveObject', ObjectState.ObjectID));

			if( InputLinks[0].bHasImpulse )
			{
				if( Toughness != None )
				{
					ObjectState.Health = Toughness.Health;
				}
				else
				{
					`Redscreen("An Interactive Object was configured to 'Set Toughness' using the 'Set Interactive Object Toughness' kismet action but no Toughness template was specified.");
				}
			}
			else if( InputLinks[1].bHasImpulse )
			{
				ObjectState.Health = HealthValue;
			}
			else if( InputLinks[2].bHasImpulse )
			{
				ObjectState.Health += HealthValue;

				if( ObjectState.Health <= 0 && ObjectState.Health - HealthValue > 0 )
				{
					`Redscreen("An Interactive Object was modified by script to have a non-positive health.");
				}
			}
			
			NewGameState.AddStateObject(ObjectState);
			Rules.SubmitGameState(NewGameState);
		}
	}
	*/
}

defaultproperties
{
	ObjName="Set Interactive Object Toughness (disabled)"
	ObjCategory="Level"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Set Toughness")
	InputLinks(1)=(LinkDesc="Set Health")
	InputLinks(2)=(LinkDesc="Modify Health")
	
	VariableLinks(0)=(ExpectedType=class'SeqVar_InteractiveObject', LinkDesc="XComGame_InteractiveObject")
}
