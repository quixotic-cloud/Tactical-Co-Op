//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ShowTutorialPopup extends X2Action;

var private const localized string TutorialBoxTitle;

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	function RemoveBladeTutorialBox()
	{
		local XComGameStateContext_TutorialBox Context;
		local XComPresentationLayer Pres;

		Context = XComGameStateContext_TutorialBox(StateChangeContext);
		Pres = `PRES;
		Pres.GetWorldMessenger().RemoveMessage(Context.MessageID);
	}

	function GetTutorialBoxText(out string Title, out string Body)
	{
		local XComTacticalMissionManager MissionManager;
		local X2MissionNarrativeTemplateManager TemplateManager;
		local XComGameStateContext_TutorialBox Context;
		local X2MissionNarrativeTemplate NarrativeTemplate;

		MissionManager = `TACTICALMISSIONMGR;

		// grab the mission narrative template and the tutorial box context that spawned this action 
		TemplateManager = class'X2MissionNarrativeTemplateManager'.static.GetMissionNarrativeTemplateManager();
		NarrativeTemplate = TemplateManager.FindMissionNarrativeTemplate(MissionManager.ActiveMission.sType, MissionManager.MissionQuestItemTemplate);
		Context = XComGameStateContext_TutorialBox(StateChangeContext);

		if (Context.ExplicitText != "")
		{
			Title = Context.ExplicitTitle;
			Body = Context.ExplicitText;
		}
		else if(NarrativeTemplate == None || Context == none)
		{
			Body = "Cannot show tutorial box, narrative template not found or not a tutorial context!\n MissionType:" $ MissionManager.ActiveMission.sType;
		}
		else
		{
			// if no title was specified, just use the default
			Title = Context.TitleObjectiveTextIndex >= 0 ? NarrativeTemplate.GetObjectiveText(Context.TitleObjectiveTextIndex) : TutorialBoxTitle;
			Body = NarrativeTemplate.GetObjectiveText(Context.ObjectiveTextIndex);
		}
	}

	function ShowTutorialBox()
	{
		local XComGameStateContext_TutorialBox Context;
		local string TitleText;
		local string BodyText;
		local XComPresentationLayer Pres;

		Pres = `PRES;

		Context = XComGameStateContext_TutorialBox(StateChangeContext);

		switch(Context.BoxType)
		{
		case TutorialBoxType_Modal:
			GetTutorialBoxText(TitleText, BodyText);			
			Pres.UITutorialBox(TitleText, BodyText, Context.ImagePath);
			break;

		case TutorialBoxType_Blade:
			GetTutorialBoxText(TitleText, BodyText);
			Pres.GetWorldMessenger().BladeMessage(BodyText, Context.MessageID, Context.ObjectToAnchorTo, Context.AnchorLocation, Context.HideBladeInShotHud);
			break;

		default:
			`Redscreen("X2Action_ShowTutorialPopup: Unknown box type.");
		}
	}

	function bool IsTutorialBoxVisible()
	{
		local XComPresentationLayer Pres;

		Pres = `PRES;
		return Pres.IsTutorialBoxShown();
	}

Begin:
	if(XComGameStateContext_TutorialBox(StateChangeContext).Remove)
	{
		RemoveBladeTutorialBox();
	}
	else
	{
		ShowTutorialBox();

		while(IsTutorialBoxVisible())
		{
			Sleep(0.1);
		}
	}

	CompleteAction();
}

defaultproperties
{
	TimeoutSeconds=-1
}