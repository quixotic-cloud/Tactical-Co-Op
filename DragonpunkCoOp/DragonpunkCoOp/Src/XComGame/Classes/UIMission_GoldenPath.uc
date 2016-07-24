
class UIMission_GoldenPath extends UIMission config(GameData);

var localized String m_strLockedHelp;
var localized String m_strGPMissionSubtitle;
var localized String m_strAvatarTitle;
var localized String m_strAvatarSubtitle;
var localized String m_strProgressLabel;
var localized String m_strAvatarDesc;
var localized String m_strAvatarLocked;
var localized String m_strAvatarLockedHelp;

var name GPMissionSource;

var bool bMissionLaunched;

var config string AvatarImagePath;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;

	super.InitScreen(InitController, InitMovie, InitName);
		
	FindMission(GPMissionSource);

	if (GetMission().GetMissionSource().DataName == 'MissionSource_Final')
	{
		if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T5_M3_CompleteFinalMission') == eObjectiveState_InProgress)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Event Trigger: View Final Mission");
			`XEVENTMGR.TriggerEvent('OnViewFinalMission', , , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('S0_RevealAvatarProject'))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Event Trigger: View Avatar Project");
			`XEVENTMGR.TriggerEvent('OnViewAvatarProject', , , NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}

	BuildScreen();
}

simulated function Name GetLibraryID()
{
	return 'Alert_GoldenPath';
}

// Override, because we use a DefaultPanel in the structure. 
simulated function BindLibraryItem()
{
	local Name AlertLibID;
	local UIPanel DefaultPanel;

	AlertLibID = GetLibraryID();
	if( AlertLibID != '' )
	{
		LibraryPanel = Spawn(class'UIPanel', self);
		LibraryPanel.bAnimateOnInit = false;
		LibraryPanel.InitPanel('', AlertLibID);
		LibraryPanel.SetSelectedNavigation();

		DefaultPanel = Spawn(class'UIPanel', LibraryPanel);
		DefaultPanel.bAnimateOnInit = false;
		DefaultPanel.bCascadeFocus = false;
		DefaultPanel.InitPanel('DefaultPanel');
		DefaultPanel.SetSelectedNavigation();

		ConfirmButton = Spawn(class'UIButton', DefaultPanel);
		ConfirmButton.SetResizeToText( false );
		ConfirmButton.InitButton('ConfirmButton', "", OnLaunchClicked);

		ButtonGroup = Spawn(class'UIPanel', DefaultPanel);
		ButtonGroup.InitPanel('ButtonGroup', '');
		ButtonGroup.SetSelectedNavigation();

		Button1 = Spawn(class'UIButton', ButtonGroup);
		Button1.SetResizeToText( false );
		Button1.InitButton('Button0', "");

		Button2 = Spawn(class'UIButton', ButtonGroup);
		Button2.SetResizeToText( false );
		Button2.InitButton('Button1', "");

		Button3 = Spawn(class'UIButton', ButtonGroup);
		Button3.SetResizeToText( false );
		Button3.InitButton('Button2', "");

		ShadowChamber = Spawn(class'UIPanel', LibraryPanel);
		ShadowChamber.InitPanel('ShadowChamber');		
	}
}

simulated function BuildScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("GeoscapeFanfares_GoldenPath");
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetMission().Get2DLocation(), CAMERA_ZOOM, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetMission().Get2DLocation(), CAMERA_ZOOM);
	}

	// Add Interception warning and Shadow Chamber info 
	super.BuildScreen();
}

simulated function BuildMissionPanel()
{
	// Send over to flash ---------------------------------------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateGoldenPathInfoBlade");
	LibraryPanel.MC.QueueString(GetMissionTitle());
	LibraryPanel.MC.QueueString(GetMissionSubtitle());
	LibraryPanel.MC.QueueString(GetMissionImage());
	LibraryPanel.MC.QueueString(GetOpName());
	LibraryPanel.MC.QueueString(GetObjectiveHeader());
	LibraryPanel.MC.QueueString(GetObjectiveString());
	LibraryPanel.MC.QueueString(GetMissionDescString());
	if( GetMission().GetRewardAmountString() != "" )
	{
		LibraryPanel.MC.QueueString(m_strReward $":");
		LibraryPanel.MC.QueueString(GetMission().GetRewardAmountString());
	}
	LibraryPanel.MC.EndOp();
}

simulated function BuildOptionsPanel()
{
	LibraryPanel.MC.BeginFunctionOp("UpdateGoldenPathIntel");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.EndOp();

	// ---------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateGoldenPathButtonBlade");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strLaunchMission);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.default.m_strGenericCancel);

	if( !CanTakeMission() )
	{
		if(IsFinalMission())
		{
			LibraryPanel.MC.QueueString(m_strAvatarLocked);
			LibraryPanel.MC.QueueString(m_strAvatarLockedHelp);
		}
		else
		{
			LibraryPanel.MC.QueueString(m_strLocked);
			LibraryPanel.MC.QueueString(m_strLockedHelp);
		}
		
		LibraryPanel.MC.QueueString(m_strOK); //OnCancelClicked
	}
	LibraryPanel.MC.EndOp();

	// ---------------------

	Button1.SetBad(true);
	Button2.SetBad(true);

	if( !CanTakeMission() )
	{
		// Hook up to the flash assets for locked info.
		LockedPanel = Spawn(class'UIPanel', LibraryPanel);
		LockedPanel.InitPanel('lockedMC', '');

		LockedButton = Spawn(class'UIButton', LockedPanel);
		LockedButton.SetResizeToText(false);
		LockedButton.InitButton('ConfirmButton', "");
		LockedButton.SetText(m_strOK);
		LockedButton.OnClickedDelegate = OnCancelClicked;
		LockedButton.Show();

		Button1.SetDisabled(true);
		Button2.SetDisabled(true);
	}


	if( CanTakeMission() )
	{
		Button1.OnClickedDelegate = OnLaunchClicked;
		Button2.OnClickedDelegate = OnCancelClicked;
	}
	Button3.Hide();
	ConfirmButton.Hide();
}

//-------------- EVENT HANDLING --------------------------------------------------------

simulated public function OnLaunchClicked(UIButton button)
{
	bMissionLaunched = true;

	super.OnLaunchClicked(button);
}

simulated function CloseScreen()
{	
	super.CloseScreen();
	
	if (GetMission().GetMissionSource().DataName == 'MissionSource_Final' && class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T5_M3_CompleteFinalMission') == eObjectiveState_InProgress && !bMissionLaunched)
	{
		// If this is the final mission, exit the Geoscape whenever the mission was not launched and the UI is closed
		HQPRES().ClearUIToHUD();
	}
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function String GetMissionTitle()
{
	if(IsFinalMission() && !CanTakeMission())
	{
		return m_strAvatarTitle;
	}

	return super.GetMissionTitle();
}
simulated function String GetMissionSubtitle()
{
	if(IsFinalMission() && !CanTakeMission())
	{
		return m_strAvatarSubtitle;
	}
	
	return m_strGPMissionSubtitle;
}
simulated function String GetMissionImage()
{
	if(IsFinalMission() && !CanTakeMission())
	{
		return AvatarImagePath;
	}

	return super.GetMissionImage();
}
simulated function String GetOpName()
{
	if(IsFinalMission() && !CanTakeMission())
	{
		return m_strProgressLabel;
	}

	return super.GetOpName();
}
simulated function String GetObjectiveHeader()
{
	if(IsFinalMission() && !CanTakeMission())
	{
		return "";
	}

	return m_strMissionObjective;
}
simulated function String GetObjectiveString()
{
	if(IsFinalMission() && !CanTakeMission())
	{
		return "";
	}

	return super.GetObjectiveString();
}
simulated function String GetMissionDescString()
{
	if(IsFinalMission() && !CanTakeMission())
	{
		return m_strAvatarDesc;
	}

	return GetMission().GetMissionSource().MissionFlavorText;
}
simulated function bool CanTakeMission()
{
	return !GetMission().bNotAtThreshold;
}
simulated function EUIState GetLabelColor()
{
	return eUIState_Warning2;
}
simulated function bool IsFinalMission()
{
	return GetMission().Source == 'MissionSource_Final';
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxAlerts/Alerts";
	InputState = eInputState_Consume;
}