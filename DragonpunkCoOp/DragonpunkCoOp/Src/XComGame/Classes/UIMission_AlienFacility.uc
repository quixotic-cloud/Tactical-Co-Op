
class UIMission_AlienFacility extends UIMission;

var public localized String m_strFlavorText;
var public localized String m_strLockedHelp;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;
	
	super.InitScreen(InitController, InitMovie, InitName);

	if (CanTakeMission())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Central Setup Phase Geoscape Dialogue");
		`XEVENTMGR.TriggerEvent('OnViewUnlockedAlienFacility', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	BuildScreen();
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

simulated function Name GetLibraryID()
{
	return 'Alert_GoldenPath';
}

// Override, because we use a DefaultPanel in teh structure. 
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
		ConfirmButton.SetResizeToText(false);
		ConfirmButton.InitButton('ConfirmButton', "", OnLaunchClicked);

		ButtonGroup = Spawn(class'UIPanel', DefaultPanel);
		ButtonGroup.InitPanel('ButtonGroup', '');

		Button1 = Spawn(class'UIButton', ButtonGroup);

		Button1.InitButton('Button0', "",, eUIButtonStyle_NONE);
		Button1.OnSizeRealized = OnButtonSizeRealized;

		Button2 = Spawn(class'UIButton', ButtonGroup);
		Button2.InitButton('Button1', "");
		Button2.InitButton('Button1', "",, eUIButtonStyle_NONE);
		Button2.OnSizeRealized = OnButtonSizeRealized;

		Button3 = Spawn(class'UIButton', ButtonGroup);
		Button3.InitButton('Button2', "");
		Button3.InitButton('Button2', "",, eUIButtonStyle_NONE);
		Button3.OnSizeRealized = OnButtonSizeRealized;

		ShadowChamber = Spawn(class'UIPanel', LibraryPanel);
		ShadowChamber.InitPanel('ShadowChamber');
	}
}
simulated function OnButtonSizeRealized()
{
	super.OnButtonSizeRealized();

	Button1.SetX(-Button1.Width / 2.0);
	Button2.SetX(-Button2.Width / 2.0);
	LockedButton.SetX(185 - LockedButton.Width / 2.0);

	Button1.SetY(10.0);
	Button2.SetY(40.0);
	LockedButton.SetY(125.0);
}

simulated function BuildScreen()
{
	PlaySFX("GeoscapeFanfares_AlienFacility");
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
	
	Navigator.Clear();
	Button1.OnLoseFocus();
	Button2.OnLoseFocus();
	Button3.OnLoseFocus();
	Button1.SetResizeToText(true);
	Button2.SetResizeToText(true);
	Button1.SetStyle(eUIButtonStyle_HOTLINK_BUTTON);
	Button1.SetGamepadIcon(class 'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	Button2.SetStyle(eUIButtonStyle_HOTLINK_BUTTON);
	Button2.SetGamepadIcon(class 'UIUtilities_Input'.static.GetBackButtonIcon());
}

simulated function BuildMissionPanel()
{
	// Send over to flash ---------------------------------------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateGoldenPathInfoBlade");
	LibraryPanel.MC.QueueString(GetMission().GetMissionSource().MissionPinLabel);
	LibraryPanel.MC.QueueString(GetMissionTitle());
	LibraryPanel.MC.QueueString(GetMissionImage());
	LibraryPanel.MC.QueueString(GetOpName());
	LibraryPanel.MC.QueueString(m_strMissionObjective);
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
		LibraryPanel.MC.QueueString(m_strLocked);
		LibraryPanel.MC.QueueString(m_strLockedHelp);
		LibraryPanel.MC.QueueString(m_strOK); //OnCancelClicked
	}
	LibraryPanel.MC.EndOp();

	// ---------------------

	if( !CanTakeMission() )
	{
		// Hook up to the flash assets for locked info.
		LockedPanel = Spawn(class'UIPanel', LibraryPanel);
		LockedPanel.InitPanel('lockedMC', '');

		LockedButton = Spawn(class'UIButton', LockedPanel);
		LockedButton.SetResizeToText(false);
		LockedButton.InitButton('ConfirmButton', "");
		LockedButton.SetResizeToText(true);
		LockedButton.SetStyle(eUIButtonStyle_HOTLINK_BUTTON);
		LockedButton.SetGamepadIcon(class 'UIUtilities_Input'.static.GetAdvanceButtonIcon());
		LockedButton.OnSizeRealized = OnButtonSizeRealized;
		LockedButton.SetText(m_strOK);
		LockedButton.OnClickedDelegate = OnCancelClicked;
		LockedButton.Show();
		LockedButton.DisableNavigation();
	}
	else
	{
		Button1.OnClickedDelegate = OnLaunchClicked;
		Button2.OnClickedDelegate = OnCancelClicked;
	}
	
	Button1.SetBad(true);
	Button2.SetBad(true);

	Button3.Hide();
	ConfirmButton.Hide();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	switch (cmd)
	{
	case class 'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class 'UIUtilities_Input'.const.FXS_KEY_ENTER:
		if (CanTakeMission() && Button1 != none)
		{
			Button1.Click();
			return true;
		}
		else
		{
			CloseScreen();
			return true;
		}
	}

	return super.OnUnrealCommand(cmd, arg);
}

//-------------- EVENT HANDLING --------------------------------------------------------

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function String GetMissionDescString()
{
	return m_strFlavorText;
}
simulated function bool CanTakeMission()
{
	return GetRegion().HaveMadeContact() || !GetMission().bNotAtThreshold;
}
simulated function EUIState GetLabelColor()
{
	return eUIState_Bad;
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	Package = "/ package/gfxAlerts/Alerts";
}