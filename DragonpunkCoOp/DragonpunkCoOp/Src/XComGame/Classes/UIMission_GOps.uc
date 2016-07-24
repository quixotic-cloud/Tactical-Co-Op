class UIMission_GOps extends UIMission;

var array<XComGameState_MissionSite> arrMissions;

var UIButton CurrentButton; 

var public localized string m_strGOpsSites;
var public localized string m_strGOpsSite;
var public localized string m_strGOPUnlockHelp;
var public localized string m_strDarkEventLabel;
var public localized string m_strGOpsTitle;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState NewGameState;

	super.InitScreen(InitController, InitMovie, InitName);

	FindMission('MissionSource_GuerillaOp');

	BuildScreen();
	UpdateStickyButton(Button1);

	if (GetNumMissions() > 1)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: On Multi Mission GOps");
		`XEVENTMGR.TriggerEvent('OnMultiMissionGOps', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated function BindLibraryItem()
{
	super.BindLibraryItem();
	Button1.OnMouseEventDelegate = OnButtonMouseEvent;
	Button1.MC.FunctionVoid("mouseIn"); //Creating a sticky highlight in this screen. 
	CurrentButton = Button1; 
	Button2.OnMouseEventDelegate = OnButtonMouseEvent;
	Button3.OnMouseEventDelegate = OnButtonMouseEvent;
}

simulated function FindMission(name MissionSource)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if( MissionState.Source == 'MissionSource_GuerillaOp' && MissionState.Available )
		{
			arrMissions.AddItem(MissionState);
		}
	}

	MissionRef = arrMissions[0].GetReference();
}

simulated function SelectMission(XComGameState_MissionSite missionToSelect)
{
	local int missionNum;
	missionNum = arrMissions.Find(missionToSelect);

	if(missionNum >= 0)
	{
		MissionRef = arrMissions[missionNum].GetReference();
		UpdateData();
	}
}

//Override this in child classes. 
simulated function Name GetLibraryID()
{
	return 'Alert_GuerrillaOpsBlades';
}

simulated function BuildScreen()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("GeoscapeFanfares_GuerillaOps");
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

	BuildConfirmPanel();
}

simulated function BuildMissionPanel()
{
	local XComGameState_WorldRegion Region;
	local string strDarkEventLabel, strDarkEventValue, strDarkEventTime;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with a mission! Couldn't find LibraryPanel for current UIMission: " $ Name);
		return;
	}

	Region = GetRegion();

	if(GetMission().HasDarkEvent())
	{
		strDarkEventLabel = m_strDarkEventLabel;
		strDarkEventValue = GetMission().GetDarkEvent().GetDisplayName();
		strDarkEventTime = GetMission().GetDarkEvent().GetPreMissionText();
	}
	else
	{
		strDarkEventLabel = "";
		strDarkEventValue = "";
		strDarkEventTime = "";
	}

	// Send over to flash ---------------------------------------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateGuerrillaOpsInfoBlade");
	LibraryPanel.MC.QueueString(Region.GetMyTemplate().DisplayName);
	LibraryPanel.MC.QueueString(m_strGOpsTitle);
	LibraryPanel.MC.QueueString(GetMissionImage());
	LibraryPanel.MC.QueueString(m_strMissionLabel);
	LibraryPanel.MC.QueueString(GetOpName());
	LibraryPanel.MC.QueueString(m_strMissionObjective);
	LibraryPanel.MC.QueueString(GetObjectiveString());
	LibraryPanel.MC.QueueString(m_strMissionDifficulty);
	LibraryPanel.MC.QueueString(GetDifficultyString());
	LibraryPanel.MC.QueueString(m_strReward);
	LibraryPanel.MC.QueueString(GetRewardString());
	LibraryPanel.MC.QueueString(strDarkEventLabel);
	LibraryPanel.MC.QueueString(strDarkEventValue);
	LibraryPanel.MC.QueueString(strDarkEventTime);
	LibraryPanel.MC.QueueString(GetRewardIcon());
	LibraryPanel.MC.EndOp();
}


simulated function BuildOptionsPanel()
{
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with a mission! Couldn't find LibraryPanel for current UIMission: " $ Name);
		return;
	}


	if( GetNumMissions() > 0 )
	{
		// Mission 1
		Button1.SetText(GetGOpsMissionLocString(0));
		Button1.OnClickedDelegate = OnMissionOneClicked;
		Button1.OnDoubleClickedDelegate = OnMissionOneClicked;
		Button1.Show();
	}
	else
		Button1.Hide();

	if( GetNumMissions() > 1 )
	{
		// Mission 2
		Button2.SetText(GetGOpsMissionLocString(1));
		Button2.OnClickedDelegate = OnMissionTwoClicked;
		Button2.OnDoubleClickedDelegate = OnMissionTwoClicked;
		Button2.Show();
	}
	else
		Button2.Hide();

	if( GetNumMissions() > 2 )
	{
		// Mission 3
		Button3.SetText(GetGOpsMissionLocString(2));
		Button3.OnClickedDelegate = OnMissionThreeClicked;
		Button3.OnDoubleClickedDelegate = OnMissionThreeClicked;
		Button3.Show();
	}
	else
		Button3.Hide();
	
	// Send over to flash ---------------------------------------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateGuerrillaOpsButtonBlade");
	LibraryPanel.MC.QueueString((GetNumMissions() > 1) ? m_strGOpsSites : m_strGOpsSite);
	LibraryPanel.MC.QueueString(GetUnlockHelpString());
	LibraryPanel.MC.QueueString(GetGOpsMissionLocString(0));
	LibraryPanel.MC.QueueString(GetGOpsMissionLocString(1));
	LibraryPanel.MC.QueueString(GetGOpsMissionLocString(2));
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.default.m_strGenericConfirm);
	LibraryPanel.MC.QueueString(CanBackOut() ? m_strIgnore : "");
	LibraryPanel.MC.EndOp();

	// ----------------------------------------------------------------------

	BuildConfirmPanel();
}

simulated function AddIgnoreButton()
{
	//Button is controlled by flash and shows by default. Hide if need to. 
	local UIButton IgnoreButton; 

	IgnoreButton = Spawn(class'UIButton', LibraryPanel);
	if(CanBackOut())
	{
		IgnoreButton.SetResizeToText( false );
		IgnoreButton.InitButton('IgnoreButton', "", OnCancelClicked);
	}
	else
	{
		IgnoreButton.InitButton('IgnoreButton').Hide();
	}
}

simulated function UpdateData()
{
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_AlienOperation");
	XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetMission().Get2DLocation(), CAMERA_ZOOM);

	BuildMissionPanel();
	RefreshNavigation();

	super.UpdateData();
}

//-------------- EVENT HANDLING --------------------------------------------------------

simulated function OnMissionOneClicked(UIButton button)
{
	local StateObjectReference NewRef; 

	NewRef = arrMissions[0].GetReference();
	if( MissionRef != NewRef )
	{
		MissionRef = NewRef;
		UpdateData();
		UpdateStickyButton(button);
	}
}

simulated function OnMissionTwoClicked(UIButton button)
{
	local StateObjectReference NewRef; 

	NewRef = arrMissions[1].GetReference();
	if( MissionRef != NewRef )
	{
		MissionRef = NewRef;
		UpdateData();
		UpdateStickyButton(button);
	}
}

simulated function OnMissionThreeClicked(UIButton button)
{
	local StateObjectReference NewRef; 

	NewRef = arrMissions[2].GetReference();
	if( MissionRef != NewRef )
	{
		MissionRef = NewRef;
		UpdateData();
		UpdateStickyButton(button);
	}
}

simulated function UpdateStickyButton(UIButton TargetButton)
{
	CurrentButton = TargetButton; 
	if( Button1 != CurrentButton )
	{
		Button1.SetGood(false);
		Button1.MC.FunctionVoid("mouseOut");
	}

	if( Button2 != CurrentButton )
	{
		Button2.SetGood(false);
		Button2.MC.FunctionVoid("mouseOut");
	}

	if( Button3 != CurrentButton )
	{
		Button3.SetGood(false);
		Button3.MC.FunctionVoid("mouseOut");
	}

	CurrentButton.SetGood(true);
	CurrentButton.MC.FunctionVoid("mouseIn");
}

simulated function OnButtonMouseEvent(UIPanel Panel, int cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
		if( UIButton(Panel) == CurrentButton )
			UIButton(Panel).MC.FunctionVoid("mouseIn"); //Force sticky highlight back on
		break;
	}
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function int GetNumMissions()
{
	return arrMissions.Length;
}

simulated function String GetGOpsMissionLocString(int iMission)
{
	if( iMission >= arrMissions.Length ) return "";

	return arrMissions[iMission].GetWorldRegion().GetMyTemplate().DisplayName;
}

simulated function String GetUnlockHelpString()
{
	local XGParamTag ParamTag;

	if (GetRegion().ResistanceLevel == eResLevel_Locked)
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		ParamTag.StrValue0 = GetRegionName();

		return `XEXPAND.ExpandString(m_strGOPUnlockHelp);
	}
	else
	{
		return "";
	}	
}

simulated function bool CanBackOut()
{
	return (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape'));
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxAlerts/Alerts";
	InputState = eInputState_Consume;
}