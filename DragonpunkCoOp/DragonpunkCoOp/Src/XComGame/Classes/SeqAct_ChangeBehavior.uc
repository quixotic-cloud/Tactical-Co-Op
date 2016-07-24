/**
 * Sequence action to change an AI behavior
 */
class SeqAct_ChangeBehavior extends SequenceAction;

/* The enemy unit on which to change behavior */
var Object EnemyUnit;

/* The new behavior for the enemy */
var() class<XGAIBehavior> NewBehavior;

event Activated()
{
	
}

defaultproperties
{
	ObjName="Change AI Behavior"
	ObjCategory="Tutorial"
	bCallHandler = false

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Enemy Unit", PropertyName=EnemyUnit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object', LinkDesc="New Behavior", PropertyName=NewBehavior)
}
