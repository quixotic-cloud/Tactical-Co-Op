
class UIMission_Retaliation extends UIMission;

var public localized String m_strRetaliationMission;
var public localized String m_strRetaliationDesc;
var public localized string m_strRetaliationWarning; 

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	FindMission('MissionSource_Retaliation');

	BuildScreen();
}

simulated function Name GetLibraryID()
{
	return 'Alert_RetaliationBlades';
}

simulated function BuildScreen()
{
	// Add Interception warning and Shadow Chamber info 
	super.BuildScreen();

	PlaySFX("GeoscapeFanfares_Retaliation");
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
	// Send over to flash ---------------------------------------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateRetaliationInfoBlade");
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS( GetRegion().GetMyTemplate().DisplayName ));
	LibraryPanel.MC.QueueString(m_strRetaliationMission);
	LibraryPanel.MC.QueueString(m_strRetaliationWarning);
	LibraryPanel.MC.QueueString(GetMissionImage());
	LibraryPanel.MC.QueueString(GetOpName());
	LibraryPanel.MC.QueueString(m_strMissionObjective);
	LibraryPanel.MC.QueueString(GetObjectiveString());
	LibraryPanel.MC.EndOp();
}

simulated function BuildOptionsPanel()
{
	// Send over to flash ---------------------------------------------------

	LibraryPanel.MC.BeginFunctionOp("UpdateRetaliationButtonBlade");
	LibraryPanel.MC.QueueString(m_strRetaliationWarning);
	LibraryPanel.MC.QueueString(GetMissionDescString());
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.default.m_strGenericConfirm);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.default.m_strGenericCancel);
	LibraryPanel.MC.QueueString("" /*LockedTitle*/);
	LibraryPanel.MC.QueueString("" /*LockedDesc*/);
	LibraryPanel.MC.QueueString("" /*LockedOKButton*/);
	LibraryPanel.MC.EndOp();

	Button1.SetText(class'UIUtilities_Text'.default.m_strGenericConfirm);
	Button1.SetBad(true);
	Button1.OnClickedDelegate = OnLaunchClicked;

	Button2.SetText(class'UIUtilities_Text'.default.m_strGenericCancel);
	Button2.SetBad(true);
	Button2.OnClickedDelegate = OnCancelClicked;

	Button3.Hide();
	ConfirmButton.Hide();
}

//-------------- EVENT HANDLING --------------------------------------------------------

//-------------- GAME DATA HOOKUP --------------------------------------------------------

simulated function String GetMissionDescString()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegionName();

	return `XEXPAND.ExpandString(m_strRetaliationDesc);
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxAlerts/Alerts";
	InputState = eInputState_Consume;
}