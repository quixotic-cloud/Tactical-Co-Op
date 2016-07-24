class X2AmbientNarrativeCriteria_RoomSpecific extends X2AmbientNarrativeCriteriaTemplate
	native(Core);

var() name RoomTemplateName;

simulated function bool IsAmbientPlayCriteriaMet(XComNarrativeMoment MomentContext)
{
	local XComGameState_FacilityXCom FacilityState;
	local UIFacility FacilityScreen;

	if (!super.IsAmbientPlayCriteriaMet(MomentContext))
		return false;

	FacilityScreen = UIFacility(`SCREENSTACK.GetFirstInstanceOf(class'UIFacility'));
	if(FacilityScreen == none)
		return false;

	if (FacilityScreen.FacilityRef.ObjectID <= 0)
		return false;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityScreen.FacilityRef.ObjectID));
	if (FacilityState.GetMyTemplateName() != RoomTemplateName)
		return false;
	
	return true;
}

defaultproperties
{
}