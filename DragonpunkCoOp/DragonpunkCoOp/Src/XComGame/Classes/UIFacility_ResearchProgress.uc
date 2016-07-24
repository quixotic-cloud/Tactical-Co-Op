class UIFacility_ResearchProgress extends UIPanel;

simulated function UIFacility_ResearchProgress InitResearchProgress()
{
	InitPanel();

	return self;
}

simulated function Update(string title, string researchName, string days, string progress, int percentComplete)
{
	MC.BeginFunctionOp("update");
	MC.QueueString(title);
	MC.QueueString(researchName);
	MC.QueueString(days);
	MC.QueueString(progress);
	MC.QueueNumber(percentComplete);
	MC.EndOp();
}

defaultproperties
{
	LibID = "FacilityResearchProgress";
	bIsNavigable = false;
}