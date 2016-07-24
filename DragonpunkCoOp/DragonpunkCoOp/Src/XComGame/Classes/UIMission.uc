
class UIMission extends UIX2SimpleScreen;

var StateObjectReference MissionRef;

var public localized String m_strUFOTitle;
var public localized String m_strInterceptionChance;
var public localized String m_strShadowChamberTitle;
var public localized String m_strEnemiesDetected;
var public localized String m_strMissionDifficulty;
var public localized String m_strMissionObjective;
var public localized String m_strMissionLabel;
var public localized String m_strEasy;
var public localized String m_strModerate;
var public localized String m_strDifficult;
var public localized String m_strVeryDifficult;
var public localized String m_strControl;
var public localized String m_strLocked;
var public localized String m_strAvengerFlightDistance;
var public localized String m_strMiles;
var public localized String m_strLaunchMission;

var public bool				bInstantInterp;

var UIPanel LibraryPanel;
var UIPanel ShadowChamber;
var UIButton Button1, Button2, Button3, ConfirmButton;
var UIPanel ButtonGroup;

var UIPanel LockedPanel;
var UIButton LockedButton;

const LABEL_ALPHA = 0.75f;
const CAMERA_ZOOM = 0.5f;

delegate ActionCallback(eUIAction eAction);
delegate OnClickedDelegate(UIButton Button);

// img:///UILibrary_ProtoImages.Proto_AdventControl
// img:///UILibrary_ProtoImages.Proto_AdventFacility
// img:///UILibrary_ProtoImages.Proto_AlienBase
// img:///UILibrary_ProtoImages.Proto_AlienFacility
// img:///UILibrary_ProtoImages.Proto_BuildOutpost
// img:///UILibrary_ProtoImages.Proto_Council
// img:///UILibrary_ProtoImages.Proto_DoomIcons
// img:///UILibrary_ProtoImages.Proto_GuerrillaOps
// img:///UILibrary_ProtoImages.Proto_MakeContact
// img:///UILibrary_ProtoImages.Proto_ObjectiveComplete
// img:///UILibrary_ProtoImages.Proto_Terror

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	//TODO: bsteiner: remove this when the strategy map handles it's own visibility
	if( Package != class'UIScreen'.default.Package )
		`HQPRES.StrategyMap2D.Hide();
}

simulated function FindMission(name MissionSource)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if( MissionState.Source == MissionSource && MissionState.Available )
		{
			MissionRef = MissionState.GetReference();
		}
	}
}

//overwritable for the children to initialize which mission is shown
simulated function SelectMission(XComGameState_MissionSite missionToSelect)
{
}


simulated function BindLibraryItem()
{
	local Name AlertLibID;

	AlertLibID = GetLibraryID();
	if( AlertLibID != '' )
	{
		LibraryPanel = Spawn(class'UIPanel', self);
		LibraryPanel.bAnimateOnInit = false;
		LibraryPanel.InitPanel('LibraryPanel', AlertLibID);

		ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
		ButtonGroup.InitPanel('ButtonGroup', '');

		Button1 = Spawn(class'UIButton', ButtonGroup);
		Button1.SetResizeToText( false );
		Button1.InitButton('Button0', "");

		Button2 = Spawn(class'UIButton', ButtonGroup);
		Button2.SetResizeToText( false );
		Button2.InitButton('Button1', "");

		Button3 = Spawn(class'UIButton', ButtonGroup);
		Button3.SetResizeToText( false );
		Button3.InitButton('Button2', "");

		ConfirmButton = Spawn(class'UIButton', LibraryPanel);
		ConfirmButton.SetResizeToText( false );
		ConfirmButton.InitButton('ConfirmButton', "", OnLaunchClicked);

		ShadowChamber = Spawn(class'UIPanel', LibraryPanel);
		ShadowChamber.InitPanel('ShadowChamber');		
		ShadowChamber.DisableNavigation();
	}
}

//Override this in child classes. 
simulated function Name GetLibraryID()
{
	return '';
}

simulated function BuildScreen()
{
	BindLibraryItem();
	UpdateShadowChamber();
	BuildMissionPanel();
	BuildOptionsPanel();

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
}

simulated function RefreshNavigation()
{
	if( ConfirmButton.bIsVisible )
	{
		ConfirmButton.EnableNavigation();
	}
	else
	{
		ConfirmButton.DisableNavigation();
	}

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

	if( Button3.bIsVisible )
	{
		Button3.EnableNavigation();
	}
	else
	{
		Button3.DisableNavigation();
	}

	if( LockedPanel != none && LockedPanel.bIsVisible )
	{
		ConfirmButton.DisableNavigation();
		Button1.DisableNavigation();
		Button2.DisableNavigation();
		Button3.DisableNavigation();
	}

	LibraryPanel.bCascadeFocus = false;
	LibraryPanel.SetSelectedNavigation();
	ButtonGroup.bCascadeFocus = false;
	ButtonGroup.SetSelectedNavigation();

	if( Button1.bIsNavigable )
		Button1.SetSelectedNavigation();
	else if( Button2.bIsNavigable )
		Button2.SetSelectedNavigation();
	else if( Button3.bIsNavigable )
		Button3.SetSelectedNavigation();
	else if( LockedPanel != none && LockedPanel.IsVisible() )
		LockedButton.SetSelectedNavigation();
	else if( ConfirmButton.bIsNavigable )
		ConfirmButton.SetSelectedNavigation();

	if( ShadowChamber != none )
		ShadowChamber.DisableNavigation();
}

simulated function BuildOptionsPanel(); //Overwritten in child classes if applicable. 
simulated function BuildMissionPanel(); //Overwritten in child classes if applicable. 

simulated function BuildConfirmPanel(optional TRect rPanel, optional EUIState eColor)
{
	local TRect rPos;

	if( LibraryPanel != none )
	{
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		AddIgnoreButton();
	}
	else
	{
		AddBG(rPanel, eColor);

		// Launch Mission Button
		rPos = VSubRect(rPanel, 0.4f, 0.5f);
		AddButton(rPos, m_strLaunchMission, OnLaunchClicked);

		rPos.fTop += 35;
		rPos.fBottom += 35;
		AddButton(rPos, m_strIgnore, OnCancelClicked);
	}
}

simulated function AddIgnoreButton()
{
	if(CanBackOut())
	{
		`HQPRES.m_kAvengerHUD.NavHelp.AddLeftHelp(m_strIgnore, "", OnCancelClickedNavHelp);
	}
}

simulated function BuildMissionRegion(TRect rPanel)
{
	local XComGameState_WorldRegion Region;
	local TRect rRegion, rPos;/*, rLabel, rControl;*/

	rRegion = MakeRect(rPanel.fLeft, rPanel.fTop, 400, 220);

	Region = GetRegion();

	// Region Name
	rPos = VSubRectPixels(rRegion, 0.0f, 55);
	AddTitle(rPos, Region.GetMyTemplate().DisplayName, GetLabelColor(), 50, 'Region');
}

//-------------- EVENT HANDLING --------------------------------------------------------

simulated public function OnLaunchClicked(UIButton button)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	HQPRES().CAMLookAtEarth( XComHQ.Get2DLocation() );

	CloseScreen();

	if(GetMission().Region == XComHQ.Region || GetMission().Region.ObjectID == 0)
	{
		GetMission().ConfirmSelection();
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Store cross continent mission reference");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		NewGameState.AddStateObject(XComHQ);
		XComHQ.CrossContinentMission = MissionRef;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		GetMission().GetWorldRegion().AttemptSelection();
	}
}
simulated function OnCancelClickedNavHelp()
{
	if(CanBackOut())
	{
		OnCancelClicked(none);
	}
}
simulated public function OnCancelClicked(UIButton button)
{
	if(CanBackOut())
	{
		if(GetMission().GetMissionSource().DataName != 'MissionSource_Final' || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T5_M3_CompleteFinalMission') != eObjectiveState_InProgress)
		{
			//Restore the saved camera location
			XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation();
		}

		CloseScreen();
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	if( LibraryPanel != none )
	{
		BuildConfirmPanel();
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	if( LibraryPanel != none )
	{
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	}
}



// Called when screen is removed from Stack
simulated function OnRemoved()
{
	super.OnRemoved();

	//Restore the saved camera location
	if(GetMission().GetMissionSource().DataName != 'MissionSource_Final' || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T5_M3_CompleteFinalMission') != eObjectiveState_InProgress)
	{
		HQPRES().CAMRestoreSavedLocation();
	}

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	class'UIUtilities_Sound'.static.PlayCloseSound();
}

simulated function UpdateData()
{
	// Region Panel
	if( LibraryPanel == none )
	{
		UpdateTitle('Region', GetRegion().GetMyTemplate().DisplayName, GetLabelColor(), 50);
	}
	
	UpdateShadowChamber();
}

simulated function UpdateShadowChamber()
{
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;
	local XComOnlineEventMgr EventManager;
	local array<X2DownloadableContentInfo> DLCInfos;
	local bool bSpawnUpdateFromDLC;
	local int i;

	// Shadow Chamber
	if( ShouldDrawShadowInfo() )
	{
		// Check for update to spawning from DLC
		EventManager = `ONLINEEVENTMGR;
		DLCInfos = EventManager.GetDLCInfos(false);
		bSpawnUpdateFromDLC = false;
		for(i = 0; i < DLCInfos.Length; ++i)
		{
			if(DLCInfos[i].UpdateShadowChamberMissionInfo(MissionRef))
			{
				bSpawnUpdateFromDLC = true;
			}
		}

		// If we have a spawning update, clear out the missions selected spawn data so that it regenerates
		if(bSpawnUpdateFromDLC)
		{
			MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));

			if(MissionState.SelectedMissionData.SelectedMissionScheduleName != '')
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Cached Mission Data");
				MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
				NewGameState.AddStateObject(MissionState);
				MissionState.SelectedMissionData.SelectedMissionScheduleName = '';
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
			}
		}

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Cached Mission Data");
		MissionState = XComGameState_MissionSite(NewGameState.CreateStateObject(class'XComGameState_MissionSite', MissionRef.ObjectID));
		NewGameState.AddStateObject(MissionState);
		if( MissionState.GetShadowChamberStrings() && CanTakeMission() )
		{
			`XEVENTMGR.TriggerEvent('OnShadowChamberMissionUI', , , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			NewGameState.PurgeGameStateForObjectID(MissionState.ObjectID);
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}

		ShadowChamber.MC.BeginFunctionOp("UpdateShadowChamber");
		ShadowChamber.MC.QueueString(m_strShadowChamberTitle);
		ShadowChamber.MC.QueueString(m_strEnemiesDetected);
		ShadowChamber.MC.QueueString(GetCrewString());
		ShadowChamber.MC.QueueString(GetCrewCount());
		ShadowChamber.MC.EndOp();
	}
	else
	{
		ShadowChamber.Hide();
	}
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function bool CanTakeMission()
{
	return true;
}
simulated function XComGameState_MissionSite GetMission()
{
	return XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionRef.ObjectID));
}
simulated function XComGameState_WorldRegion GetRegion()
{
	return GetMission().GetWorldRegion();
}
simulated function String GetRegionName()
{
	return GetMission().GetWorldRegion().GetMyTemplate().DisplayName;
}
simulated function String GetMissionTitle()
{
	return GetMission().GetMissionSource().MissionPinLabel;
}
simulated function String GetMissionImage()
{
	return GetMission().GetMissionSource().MissionImage;
}
simulated function String GetOpName()
{
	local GeneratedMissionData MissionData;

	MissionData = XCOMHQ().GetGeneratedMissionData(MissionRef.ObjectID);

	return MissionData.BattleOpName;
}
simulated function String GetObjectiveString()
{
	return GetMission().GetMissionObjectiveText();
}

simulated function String GetRewardString()
{
	return GetMission().GetRewardAmountString();
}

simulated function String GetRewardIcon()
{
	return GetMission().GetRewardIcon();
}

simulated function String GetRegionString()
{
	return GetMission().GetWorldRegion().GetMyTemplate().DisplayName;
}

simulated function String GetDifficultyString()
{
	return Caps(GetMission().GetMissionDifficultyLabel());
}

simulated function String GetCrewCount()
{
	return GetMission().m_strShadowCount;
}

simulated function String GetCrewString()
{
	return GetMission().m_strShadowCrew;
}

simulated function bool ShouldDrawShadowInfo()
{
	return XCOMHQ().GetFacilityByName('ShadowChamber') != none;
}

simulated function EUIState GetLabelColor()
{
	return eUIState_Normal;
}

simulated function bool CanBackOut()
{
	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local UIButton CurrentButton;
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:

		CurrentButton = UIButton(ButtonGroup.Navigator.GetSelected());
		if( CurrentButton.bIsVisible && !CurrentButton.IsDisabled )
		{
			CurrentButton.Click();
			
			if( CanBackOut() )
			{
				CloseScreen();
			}
			return true;
		}
		//If you don't have a current button, fall down and hit the Navigation system. 
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		if(CanBackOut())
		{
			CloseScreen();
		}
		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	bAutoSelectFirstNavigable = false;
}
