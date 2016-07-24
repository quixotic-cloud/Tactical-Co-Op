//-----------------------------------------------------------
//Show a tactical message in the UI messaging system, allowed to persist until removed.
//-----------------------------------------------------------
class SeqAct_DisplayMissionObjective extends SequenceAction
	dependson(UIObjectiveList, XComTacticalMissionManager);

var int TextPoolIndex;
var int LineIndex;
var int TimerValue;
var int GroupID;

event Activated()
{
	local XComGameStateHistory History;
	local XComTacticalMissionManager MissionManager;
	local XComGameState NewGameState;
	local XComGameState_ObjectivesList ObjectiveList;
	local ObjectiveDisplayInfo DisplayInfo;
	local string DisplayLabel;
	local string MissionType;

	History = `XCOMHISTORY;
	MissionManager = `TACTICALMISSIONMGR;

	NewGameState = History.GetStartState();
	if (NewGameState == None)
	{		
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Display Mission Objective");
	}

	foreach History.IterateByClassType(class'XComGameState_ObjectivesList', ObjectiveList)
	{
		break;
	}

	ObjectiveList = XComGameState_ObjectivesList(NewGameState.CreateStateObject(class'XComGameState_ObjectivesList', 
												 ObjectiveList != none ? ObjectiveList.ObjectID : -1));

	MissionType = MissionManager.ActiveMission.sType;
	DisplayLabel = GetDisplayLabel(MissionType, MissionManager.MissionQuestItemTemplate);

	if(InputLinks[2].bHasImpulse)
	{
		ObjectiveList.HideObjectiveDisplay(MissionType, DisplayLabel);
	}
	else
	{
		if(!ObjectiveList.GetObjectiveDisplay(MissionType, DisplayLabel, DisplayInfo))
		{
			// there is no current line for this mission text yet, so add a new one
			DisplayInfo.MissionType = MissionType;
			DisplayInfo.DisplayLabel = DisplayLabel;
		}

		// update the status
		DisplayInfo.ShowCheckBox = InputLinks[0].bHasImpulse || InputLinks[1].bHasImpulse || InputLinks[3].bHasImpulse;
		DisplayInfo.ShowCompleted = InputLinks[1].bHasImpulse;
		DisplayInfo.ShowFailed = InputLinks[3].bHasImpulse;
		DisplayInfo.ShowWarning = InputLinks[4].bHasImpulse;
		DisplayInfo.ShowHeader = InputLinks[6].bHasImpulse;
		DisplayInfo.Timer = InputLinks[5].bHasImpulse ? TimerValue : -1;
		DisplayInfo.GroupID = GroupID; 

		// and add/update it in the state object
		ObjectiveList.SetObjectiveDisplay(DisplayInfo);

		if(DisplayInfo.ShowCompleted)
		{
			`XEVENTMGR.TriggerEvent( 'MissionObjectiveMarkedCompleted', ObjectiveList, self, NewGameState );
		}
		if(DisplayInfo.ShowFailed)
		{
			`XEVENTMGR.TriggerEvent( 'MissionObjectiveMarkedFailed', ObjectiveList, self, NewGameState );
		}
	}

	NewGameState.AddStateObject(ObjectiveList);

	if (NewGameState != History.GetStartState())
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated private function string GetDisplayLabel(string MissionType, name QuestItemTemplate)
{
	local X2MissionNarrativeTemplateManager TemplateManager;
	local X2MissionNarrativeTemplate NarrativeTemplate;

	TemplateManager = class'X2MissionNarrativeTemplateManager'.static.GetMissionNarrativeTemplateManager();
	NarrativeTemplate = TemplateManager.FindMissionNarrativeTemplate(MissionType, QuestItemTemplate);
	return NarrativeTemplate.GetObjectiveText(LineIndex); 
}

static event int GetObjClassVersion()
{
	return super.GetObjClassVersion() + 1;
}

defaultproperties
{
	ObjCategory="UI/Input"
	ObjName="Display Mission Objective"
	bCallHandler = false

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks(0)=(LinkDesc="Show Incomplete")
	InputLinks(1)=(LinkDesc="Show Complete")
	InputLinks(2)=(LinkDesc="Remove")
	InputLinks(3)=(LinkDesc="Show Failed")
	InputLinks(4)=(LinkDesc="Show Warning")
	InputLinks(5)=(LinkDesc="Show Timer")
	InputLinks(6)=(LinkDesc="Set Header")
	
	bAutoActivateOutputLinks=true
	OutputLinks(0)=(LinkDesc="Out")

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Int',LinkDesc="Text Pool Index",PropertyName=TextPoolIndex)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Int',LinkDesc="Line Index",PropertyName=LineIndex)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int',LinkDesc="TimerValue",PropertyName=TimerValue)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Int',LinkDesc="GroupID",PropertyName=GroupID)
}
