/**
 * A wait condition that requires an actor be at a specific location.
 */
class XComWaitCondition_InteractPoints extends SeqAct_XComWaitCondition deprecated;

/** The Unit we're waiting for */
var() Actor UnitActor;

/** The number of interact points we're looking for */
var() int NumInteractPoints;

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

	return Unit != none;// && (Unit.m_arrInteractPoints.Length == NumInteractPoints);
}

/** @return A string description of the current condition */
event string GetConditionDesc()
{
	if( !bNot )
		return "unit is around "@NumInteractPoints@" interaction points.";
	else
		return "unit is not around "@NumInteractPoints@" interaction points.";
}

DefaultProperties
{
	ObjName="Wait for Interact Points"
	
	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object', LinkDesc="Unit", PropertyName=UnitActor)
}
