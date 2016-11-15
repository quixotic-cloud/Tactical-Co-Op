//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadLoadoutList_AcceptingInvite.uc
//  AUTHOR:  Timothy Talley  --  12/01/2015
//  PURPOSE: Squad loadout list for selection prior to entering the lobby after accepting an invite.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadLoadoutList_AcceptingInvite extends UIMPShell_SquadLoadoutList;

var UIButton EditSquadButton;
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);	
}

simulated function OnInit()
{
	super.OnInit();

	m_kMPShellManager.OnMPShellScreenInitialized();
	m_kMPShellManager.UpdateConnectivityData();
	`log(self $ "::" $ GetFuncName() @ `ShowVar(m_kMPShellManager.m_bPassedNetworkConnectivityCheck, PassedNetworkConnectivityCheck) @ `ShowVar(m_kMPShellManager.m_bPassedOnlineConnectivityCheck, PassedOnlineConnectivityCheck),, 'XCom_Online');
	if(!m_kMPShellManager.m_bPassedNetworkConnectivityCheck)
	{
		ConnectionLost(QuitReason_LostLinkConnection, m_kMPShellManager.GetOnlineNoNetworkConnectionDialogBoxData());
		
	}
	else if(!m_kMPShellManager.m_bPassedOnlineConnectivityCheck)
	{
		ConnectionLost(QuitReason_LostConnection, m_kMPShellManager.GetOnlineConnectionFailedDialogData());
	}
}

function EditSquadButtonCallback()
{
	if(!EditSquadButton.IsDisabled)
		CreateSquadEditor(m_kSquadLoadout);
}

simulated function UpdateNavHelp()
{
	super.UpdateNavHelp();
	//<workshop> GAMEPAD_NAV_HELP - JTA 2015/11/15
	if(!Movie.IsMouseActive())
		return;
	//</workshop>

	if(EditSquadButton == none)
	{
		EditSquadButton = IntegratedNavHelp.AddCenterButton(m_strEditSquad,, EditSquadButtonCallback, m_kSquadLoadout == none);
		EditSquadButton.OnClickedDelegate = EditSquadClickedButtonCallback;
		Navigator.AddControl(EditSquadButton);
	}

	 UpdateNavHelpState();
}

simulated function UpdateNavHelpState()
{
	super.UpdateNavHelpState();
	//<workshop> GAMEPAD_NAV_HELP - JTA 2015/11/15
	if( `ISCONTROLLERACTIVE )
		return;
	//</workshop>
	EditSquadButton.SetDisabled(m_kSquadLoadout == none);
}

function EditSquadClickedButtonCallback(UIButton Button)
{
	EditSquadButtonCallback();
}
function ConnectionLost(EQuitReason Reason, TDialogueBoxData DialogBoxData)
{
	BackButtonCallback();
	m_kMPShellManager.m_kShellPres.UIRaiseDialog(DialogBoxData);
}

function BackButtonCallback()
{
	local OnlineSubsystem OnlineSub;

	OnlineSub = Class'Engine'.static.GetOnlineSubsystem();
	OnlineSub.GameInterface.AddDestroyOnlineGameCompleteDelegate(OnDestroyOnlineGameComplete);
	OnlineSub.GameInterface.DestroyOnlineGame('Game');
}

function NextButton()
{
	local XComOnlineEventMgr EventMgr;
	if(m_kSquadLoadout == none)
		return;

	if(CanJoinGame())
	{
		`XPROFILESETTINGS.X2MPWriteTempLobbyLoadout(m_kSquadLoadout);
		m_kMPShellManager.SaveProfileSettings();

		EventMgr = `ONLINEEVENTMGR;
		EventMgr.TriggerAcceptedInvite();
	}
}

function OnDestroyOnlineGameComplete(name SessionName, bool bWasSuccessful)
{
	local XComShellPresentationLayer Pres;
	local OnlineSubsystem OnlineSub;
	local XComOnlineEventMgr EventMgr;

	`log(`location @ `ShowVar(SessionName) @ `ShowVar(bWasSuccessful), true, 'XCom_Online');

	OnlineSub = Class'Engine'.static.GetOnlineSubsystem();
	OnlineSub.GameInterface.ClearDestroyOnlineGameCompleteDelegate(OnDestroyOnlineGameComplete);

	EventMgr = `ONLINEEVENTMGR;
	EventMgr.CancelInvite();
	EventMgr.RefreshLoginStatus();

	Pres = XComShellPresentationLayer(Movie.Pres);
	Pres.OSSCheckNetworkConnectivity(false);
	Pres.OSSCheckOnlineConnectivity(false);
	Pres.OSSCheckOnlinePlayPermissions(false);

	CloseScreen();
}

defaultproperties
{
	UISquadEditorClass=class'UIMPShell_SquadEditor_AcceptInvite'

	TEMP_strSreenNameText="Invite Squad Loadout List"
}