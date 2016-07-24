class SeqAct_OverWatch extends SequenceAction;

var XGUnit TargetUnit;

event Activated()
{	
	/*
	local XGAbility kAbility;
	
	kAbility = TargetUnit.FindAbility(eAbility_Overwatch, none);
	if (kAbility != none && kAbility.CheckAvailable())
	{
		kAbility.Execute();
	}
	*/
}

defaultproperties
{
	ObjCategory="Unit"
	ObjName="Unit Action - Overwatch"
	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Target Unit",PropertyName=TargetUnit)
	bCallHandler=false
}
