/**
 * A wait condition that requires an actor be at a specific location.
 */
class XComWaitCondition_UnitMoving extends SeqAct_XComWaitCondition;

/** The Unit we're waiting for */
var() Actor UnitActor;

/** @return true if the condition has been met */
event bool CheckCondition()
{
	local XComUnitPawn UnitPawn;
	local XGUnit Unit;

	UnitPawn = XComUnitPawn(UnitActor);
	if (UnitPawn != none)
		Unit = XGUnit(UnitPawn.GetGameUnit());
	else
		Unit = XGUnit(UnitActor);

	return Unit != none && Unit.IsMoving();
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if( !bNot )
		return "unit moves";
	else
		return "unit has stopped moving";
}

DefaultProperties
{
	ObjName="Wait for Unit Movement"
	
	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Unit", PropertyName=UnitActor)
}
