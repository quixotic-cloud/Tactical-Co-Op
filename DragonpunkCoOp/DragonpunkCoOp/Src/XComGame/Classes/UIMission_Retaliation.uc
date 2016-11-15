
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

	Navigator.Clear();
	Button1.OnLoseFocus();
	Button2.OnLoseFocus();
	Button3.OnLoseFocus();
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
	
	// For this particular screen Button1, and Button2 are specifically getting used.
	Button1.SetResizeToText(true);
	Button2.SetResizeToText(true);
	Button1.SetStyle(eUIButtonStyle_HOTLINK_BUTTON);
	Button1.SetGamepadIcon(class 'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	Button2.SetStyle(eUIButtonStyle_HOTLINK_BUTTON);
	Button2.SetGamepadIcon(class 'UIUtilities_Input'.static.GetBackButtonIcon());
}
simulated function OnButtonSizeRealized()
{
	super.OnButtonSizeRealized();

	Button1.SetX(-Button1.Width / 2.0);
	Button2.SetX(-Button2.Width / 2.0);

	Button1.SetY(10.0);
	Button2.SetY(40.0);
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

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	switch(cmd)
	{
	case class 'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class 'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class 'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		if(Button1 != none && Button1.OnClickedDelegate != none)
		{
			Button1.OnClickedDelegate(Button1);
			return true;
		}
	}
	return super.OnUnrealCommand(cmd, arg);
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