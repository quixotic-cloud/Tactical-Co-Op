
class UISkyrangerArrives extends UIScreen;

var public localized String m_strBody;
var public localized String m_strConfirmMission;
var public localized String m_strReturnToBase;
var public localized String m_strSkyrangerArrivesTitle;
var public localized String m_strSkyrangerArrivesSubtitle;

var UIPanel LibraryPanel;
var UIPanel ShadowChamber;
var UIPanel ButtonGroup; 
var UIButton Button1, Button2;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	//TODO: bsteiner: remove this when the strategy map handles it's own visibility
	if( Package != class'UIScreen'.default.Package )
		`HQPRES.StrategyMap2D.Hide();
	
	BindLibraryItem();
	BuildScreen();
}

simulated function BindLibraryItem()
{

	LibraryPanel = Spawn(class'UIPanel', self);
	LibraryPanel.bAnimateOnInit = false;
	LibraryPanel.InitPanel('', 'Alert_SkyrangerLanding');

	ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
	ButtonGroup.InitPanel('ButtonGroup', '');

	Button1 = Spawn(class'UIButton', ButtonGroup);
	Button1.SetResizeToText(false);
	Button1.InitButton('Button0', "", OnLaunchClicked);

	Button2 = Spawn(class'UIButton', ButtonGroup);
	Button2.SetResizeToText(false);
	Button2.InitButton('Button1', "", OnCancelClicked);

	ShadowChamber = Spawn(class'UIPanel', LibraryPanel);
	ShadowChamber.InitPanel('ShadowChamber');
}
simulated function RefreshNavigation()
{
	if( Button1.bIsVisible )
	{
		Button1.EnableNavigation();
	}
	else
	{
		Button1.DisableNavigation();
	}

	if( Button2.bIsVisible )
	{
		Button2.EnableNavigation();
	}
	else
	{
		Button2.DisableNavigation();
	}

	LibraryPanel.bCascadeFocus = false;
	LibraryPanel.SetSelectedNavigation();
	ButtonGroup.bCascadeFocus = false;
	ButtonGroup.SetSelectedNavigation();

	if( Button1.bIsNavigable )
		Button1.SetSelectedNavigation();
	else if( Button2.bIsNavigable )
		Button2.SetSelectedNavigation();

	if( ShadowChamber != none )
		ShadowChamber.DisableNavigation();
}

simulated function BuildScreen()
{
	local XComGameState NewGameState;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStop");

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skyranger Arrives Event");
	`XEVENTMGR.TriggerEvent('OnSkyrangerArrives', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	BuildSkyrangerPanel();
	BuildOptionsPanel();

	if (!class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape') || GetMission().GetMissionSource().DataName == 'MissionSource_Broadcast')
	{
		Button2.Hide();
	}

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
}

simulated function BuildSkyrangerPanel()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateSkyrangerInfoBlade");
	LibraryPanel.MC.QueueString(m_strSkyrangerArrivesTitle);
	LibraryPanel.MC.QueueString(m_strSkyrangerArrivesSubtitle);
	LibraryPanel.MC.EndOp();
}

simulated function BuildOptionsPanel()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateSkyrangerButtonBlade");
	LibraryPanel.MC.QueueString(GetOpName());
	LibraryPanel.MC.QueueString(m_strBody);
	LibraryPanel.MC.QueueString(m_strConfirmMission);
	LibraryPanel.MC.QueueString(m_strReturnToBase);
	LibraryPanel.MC.EndOp();
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnLaunchClicked(UIButton button)
{
	GetMission().ConfirmMission();
	// don't close the screen to prevent facility grid to show up unintentionally prior to launching into a mission
	if(`GAME.SimCombatNextMission)
		CloseScreen();
}
simulated function OnCancelClicked(UIButton button)
{
	if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape') && GetMission().GetMissionSource().DataName != 'MissionSource_Broadcast')
	{
		`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.Avenger_Skyranger_Recalled');
		GetMission().CancelMission();
		CloseScreen();
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	local UIButton CurrentButton;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	bHandled = true;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:

		CurrentButton = UIButton(ButtonGroup.Navigator.GetSelected());
		if( CurrentButton.bIsVisible && !CurrentButton.IsDisabled )
		{
			CurrentButton.Click();
			return true;
		}
		//If you don't have a current button, fall down and hit the Navigation system. 
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnCancelClicked(none);
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function String GetOpName()
{
	local GeneratedMissionData MissionData;
	local XComGameState_HeadquartersXCom HQ; 

	HQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	MissionData = HQ.GetGeneratedMissionData(HQ.MissionRef.ObjectID);

	return MissionData.BattleOpName;
}
simulated function XComGameState_MissionSite GetMission()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom HQ;

	HQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	History = `XCOMHISTORY;
	return XComGameState_MissionSite(History.GetGameStateForObjectID(HQ.MissionRef.ObjectID));
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	Package = "/ package/gfxAlerts/Alerts";
	
	bAutoSelectFirstNavigable = false; 
}