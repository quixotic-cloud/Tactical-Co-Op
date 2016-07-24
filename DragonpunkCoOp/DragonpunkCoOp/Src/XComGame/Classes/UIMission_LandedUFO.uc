
class UIMission_LandedUFO extends UIMission;

var public localized String m_strLandedUFOMission;
var public localized String m_strLockedHelp;
var public localized String m_strMissionDesc;
var public localized String m_strBuyMission;
var public localized String m_strLandedUFOTitleGreeble;
var public localized string m_strLandedUFOGreeble;

var array<UIPanel> arrOptionsWidgets;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	FindMission('MissionSource_LandedUFO');

	BuildScreen();
}

//Override this in child classes. 
simulated function Name GetLibraryID()
{
	return 'Alert_SupplyRaidBlades';
}

simulated function BuildScreen()
{
	// Add Interception warning and Shadow Chamber info
	super.BuildScreen();

	PlaySFX("Geoscape_UFO_Landed");
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetMission().Get2DLocation(), CAMERA_ZOOM, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetMission().Get2DLocation(), CAMERA_ZOOM);
	}
}

simulated function BuildMissionPanel()
{
	LibraryPanel.MC.BeginFunctionOp("UpdateSupplyRaidButtonBlade");
	LibraryPanel.MC.QueueString(m_strLandedUFOTitleGreeble);
	LibraryPanel.MC.QueueString(GetRaidDesc());
	LibraryPanel.MC.QueueString(m_strLaunchMission);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

	Button1.OnClickedDelegate = OnLaunchClicked;
	Button2.OnClickedDelegate = OnCancelClicked;

	Button3.Hide();
	ConfirmButton.Hide();
}

simulated function BuildOptionsPanel()
{
	LibraryPanel.MC.BeginFunctionOp("UpdateSupplyRaidInfoBlade");
	LibraryPanel.MC.QueueString(GetMissionImage());
	LibraryPanel.MC.QueueString(m_strLandedUFOMission);
	LibraryPanel.MC.QueueString(GetRegion().GetMyTemplate().DisplayName);
	LibraryPanel.MC.QueueString(GetOpName());
	LibraryPanel.MC.QueueString(m_strMissionObjective);
	LibraryPanel.MC.QueueString(GetObjectiveString());
	LibraryPanel.MC.QueueString(m_strLandedUFOGreeble);

	// Launch/Help Panel
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");

	LibraryPanel.MC.EndOp();
}

//-------------- EVENT HANDLING --------------------------------------------------------

simulated function UpdateData()
{
	FindMission('MissionSource_LandedUFO');
	BuildOptionsPanel();
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function String GetRaidDesc()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegionName();

	return `XEXPAND.ExpandString(m_strMissionDesc);
}

//==============================================================================

defaultproperties
{
	InputState = eInputState_Consume;
	Package = "/ package/gfxAlerts/Alerts";
}