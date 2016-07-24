class SeqAct_ToggleBuildingReveal extends SequenceAction;

event Activated()
{
	local SeqVar_Object ObjVar;
	local XComBuildingVolume kVolume;

	foreach LinkedVariables(class'SeqVar_Object', ObjVar, "Volumes")
	{
		kVolume = XComBuildingVolume(ObjVar.GetObjectValue());
		if( kVolume != none )
		{
			kVolume.m_bAllowBuildingReveal = InputLinks[0].bHasImpulse;
		}
	}
}

defaultproperties
{
	ObjName="Toggle Building Reveal"
	ObjCategory="Tutorial"
	bCallHandler=false

	InputLinks(0)=(LinkDesc="Enable")
	InputLinks(1)=(LinkDesc="Disable")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Object',LinkDesc="Volumes")
}