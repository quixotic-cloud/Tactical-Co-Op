/**
 * Sequence action to change an AI behavior
 */
class SeqAct_SetDirectedBehavior extends SequenceAction;

/* The enemy unit onto which to apply the DTE */
var Object EnemyUnit;

/* The DTE */
var XComDirectedTacticalExperience DTE;

event Activated()
{
}

defaultproperties
{
	ObjName="Set Enemy Directed Tactical Environment"
	ObjCategory="Tutorial"
	bCallHandler = false

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Enemy Unit", PropertyName=EnemyUnit)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Object', LinkDesc="Directed Tactical Environment", PropertyName=DTE)
}
