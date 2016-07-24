class X2AmbientNarrativeCriteria_GoldenPath extends X2AmbientNarrativeCriteriaTemplate
	native(Core);

var() name ObjectiveTemplateName;

simulated function bool IsAmbientPlayCriteriaMet(XComNarrativeMoment MomentContext)
{
	local XComGameState_Objective ObjectiveState;

	if (!super.IsAmbientPlayCriteriaMet(MomentContext))
		return false;

	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if (ObjectiveState.GetMyTemplateName() == ObjectiveTemplateName && ObjectiveState.ObjState == eObjectiveState_Completed)
		{
			return true;
		}
	}

	return false;
}

defaultproperties
{
}