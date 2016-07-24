/**
 * A latent kismet action that blocks a sequence until certain 
 * conditions are met or the action is aborted
 */
class SeqAct_XComWaitCondition extends SequenceAction
	abstract
	editinlinenew
	native(Level);

// The functionality of this sequence action is entirely
// in the native UpdateOp function.
cpptext
{
	virtual UBOOL UpdateOp(FLOAT DeltaTime);

#if WITH_EDITOR
	virtual FString GetDisplayTitle() const;
#endif
};

/**
 * Check for this condition to not be true. 
 * Subclasses do NOT need to impliment this. 
 * It is handled in UpdateOp.
 */
var() bool bNot;

/** @return true if the condition has been met */
event bool CheckCondition();

/** @return A string description of the current condition */
event string GetConditionDesc();

defaultproperties
{
	ObjName="Wait Condition"
	ObjCategory="Wait Conditions"

	bCallHandler=false
	bLatentExecution=true
	bAutoActivateOutputLinks=false

	bNot=false

	InputLinks.Empty
	InputLinks(0)=(LinkDesc="Wait")
	InputLinks(1)=(LinkDesc="Abort")

	OutputLinks.Empty
	OutputLinks(0)=(LinkDesc="Finished")
	OutputLinks(1)=(LinkDesc="Aborted")

	VariableLinks.Empty
}
