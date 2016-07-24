class SeqAct_HasInteractionPoints extends SequenceCondition deprecated;

var Actor   TargetActor;

event Activated()
{
	/*
	local XGUnit kUnit;

	kUnit = GetXGUnit(TargetActor);
	
	if (kUnit != none)
	{
		if (kUnit.m_arrInteractPoints.Length == 0)
		{
			OutputLinks[0].bHasImpulse = true;
		}
		else
		{
			OutputLinks[1].bHasImpulse = true;
		}
	}	
	*/
}

simulated function XGUnit GetXGUnit( Object UnitActor )
{
	local XComUnitPawn pawn;

	pawn = XComUnitPawn(UnitActor);
	if (pawn != none)
	{
		return XGUnit(pawn.GetGameUnit());
	}
	else
	{
		return XGUnit(UnitActor);
	}
}

defaultproperties
{
	ObjCategory="Xcom Squad"
	ObjName="Has Interaction Points"

	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Actor",PropertyName=TargetActor)

	OutputLinks(0)=(LinkDesc="True")
	OutputLinks(1)=(LinkDesc="False")
}
