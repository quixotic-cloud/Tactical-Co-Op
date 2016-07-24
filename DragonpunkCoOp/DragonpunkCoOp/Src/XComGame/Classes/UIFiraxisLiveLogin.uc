//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIFiraxisLiveLogin
//  AUTHOR:  Timothy Talley
//
//  PURPOSE: Handles the entire Firaxis Live / My2K Login process.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIFiraxisLiveLogin extends UILoginScreen
	dependson(X2FiraxisLiveClient);


const NUM_DROPDOWN_YEARS = 100;

//--------------------------------------------------------------------------------------- 
// UI Layout Data
//
var UIPanel								m_kAllContainer;
var UIPanel                             m_eulaBG;

var UIButton							m_Generic1Button;
var UIButton							m_Generic2Button;
var UIButton							m_Generic4Button;

var UIButton							m_UsernameButton;
var UIButton							m_PasswordButton;
var UIButton                            m_TextBoxBeingSet;

var UITextContainer                     m_eulaTitle;
var UITextContainer                     m_eulaText;
var UIButton							m_eulaAcceptButton;

var array<UIButton>                     m_eulaButtons;

var UIText                              m_DoBText;
var UIDropdown                          m_DoBDayDropdown;
var UIDropdown                          m_DoBMonthDropdown;
var UIDropdown                          m_DoBYearDropdown;

var localized string                    m_InitNewUserLabel;
var localized string                    m_LoginSuccessLabel;
var localized string                    m_LoginFailLabel;
var localized string                    m_RememberMeLabel;
var localized string                    m_LogoutLabel;

// these labels are set by callbacks in firaxis live but we need default labels in case of errors
var localized string                    m_InitUserNameLabel;
var localized string                    m_InitPasswordLabel;
var localized string                    m_UnlinkAccountLabel;
var localized string                    m_LinkAccountLabel;
var localized string                    m_InitOKLabel;
var localized string                    m_InitCloseLabel;
var localized string                    m_LoginLabel;
var localized string                    m_CheckEMailMessage;
var localized string                    m_LinkAccountMessage;
var localized string                    m_DeclineEULATitle;
var localized string                    m_DeclineEULABody;
var localized string                    m_ReadEULALabel;
var localized string                    m_ConnectionUnavailableTitle;
var localized string                    m_ConnectionUnavailableMessage;
var localized string                    m_UnLinkAccountMessage;


var string								m_UsernameLabel; 
var string								m_PasswordLabel;
var string								m_Generic1Label;
var string								m_Generic2Label;
var string								m_Generic4Label;
var string								m_Agree;
var string								m_Disagree;
var string								m_DoBLabel;
var string								m_ReadLabel;
var array<string>						m_MonthNames;
var array<LegalDocuments>				m_EULAs;

//--------------------------------------------------------------------------------------- 
// Data
//
var bool                                bStoredMouseIsActive;
var bool                                m_bAccountCreationFailure;
var bool                                m_bWaitingForAccountCallback;
var bool                                m_bWaitingForLogonData;
var string                              m_2KTitle;
var string                              m_2kMessage;
var string                              m_PasswordStarredOutLabel;
var string                              m_Username, m_Password;
var bool                                m_PasswordEntered;
var int                                 m_CurrentEULA;
var UINavigationHelp                    NavHelp;
var bool                                bUpdateState;
var array<string>                       AcceptedDocumentIds, DeclinedDocumentIds;
var array<delegate<SubStateLoginStatus> > StatusCallbacks;

//--------------------------------------------------------------------------------------- 
// Cached References
//
var X2FiraxisLiveClient         LiveClient;

//--------------------------------------------------------------------------------------- 
// Delegates
//
delegate SubStateLoginStatus(ELoginStatusType Type, EFiraxisLiveAccountType Account, string Message, bool bSuccess);


//==============================================================================
//		INITIALIZATION:
//==============================================================================
simulated function InitScreen( XComPlayerController InitController, UIMovie InitMovie, optional name InitName )
{
	LiveClient = `FXSLIVE;
	LiveClient.AddClientStateChangeDelegate(OnClientStateChange);
	LiveClient.AddConnectionFailureDelegate(OnConnectionFailure);
	LiveClient.AddConnectionStatusDelegate(OnConnectionStatusChange);
	LiveClient.AddLogonDataDelegate(OnLogonData);
	LiveClient.AddLoginStatusDelegate(OnLoginStatus);
	LiveClient.AddCreateNewAccountDelegate(OnNewAccountNotify);
	LiveClient.AddDOBDataDelegate(OnDoBNotify);
	LiveClient.AddLegalInfoDelegate(OnLegalNotify);

	super.InitScreen(InitController, InitMovie, InitName);

	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	m_Generic4Label = m_InitNewUserLabel;
	m_UsernameLabel = m_InitUserNameLabel; 
	m_PasswordLabel = m_InitPasswordLabel;
	m_Generic2Label = m_InitOKLabel;
	m_Generic1Label = m_InitCloseLabel;

	m_kAllContainer = Spawn(class'UIPanel', self).InitPanel('loginScreenMC');

	m_Generic4Button = Spawn(class'UIButton', m_kAllContainer).InitButton('NewUserButton', m_Generic4Label, OnGeneric4ButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_Generic4Button.SetPosition(325, 370);
	m_Generic4Button.OnSizeRealized = OnCreateAccountButtonSizeRealized;
	
	m_Generic2Button = Spawn(class'UIButton', m_kAllContainer).InitButton('LoginButton', m_Generic2Label, OnGeneric2ButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	m_Generic2Button.SetPosition(500, 370);
	m_Generic1Button = Spawn(class'UIButton', m_kAllContainer).InitButton('CancelButton', m_Generic1Label, OnGeneric1ButtonPress, eUIButtonStyle_HOTLINK_BUTTON);
	//m_eulaAcceptButton = Spawn(class'UIButton', self);
	m_UsernameButton = Spawn(class'UIButton', m_kAllContainer);
	m_UsernameButton.ResizeToText = false;
	m_UsernameButton.InitButton('loginTextButton', class'UIUtilities_Text'.static.AlignLeft(m_UsernameLabel), OpenTextBoxInput);

	m_PasswordButton = Spawn(class'UIButton', m_kAllContainer);
	m_PasswordButton.ResizeToText = false;
	m_PasswordButton.InitButton('passwordTextButton', class'UIUtilities_Text'.static.AlignLeft(m_PasswordLabel), OpenTextBoxInput);

	/*m_eulaAcceptButton.InitButton( , m_InitOKLabel, AgreeToEULA);
	m_eulaAcceptButton.SetPosition(850, 920);
	m_eulaAcceptButton.Hide();*/
	
	MC.FunctionString("UpdateLoginTitle", m_2KTitle);

	NavHelp = Movie.Pres.GetNavHelp();
	//NavHelp.AddBackButton(CloseScreen);
}

simulated function OnCreateAccountButtonSizeRealized()
{
	m_Generic2Button.SetX(m_Generic4Button.X + m_Generic4Button.Width + 10);
}

function HideAll()
{
	m_Generic4Button.Hide();
	m_Generic2Button.Hide();
	m_Generic1Button.Hide();
	m_UsernameButton.Hide();
	m_PasswordButton.Hide();
	MC.FunctionString("setDetailText", "");
	MC.FunctionString("UpdateLoginTitle", "");
	MC.FunctionString("setUsernameText", "");
}

function ResetScreen()
{	
	MC.FunctionString("setDetailText", m_2KMessage);
	MC.FunctionString("UpdateLoginTitle", m_2KTitle);

	m_Generic1Button.SetText(m_Generic1Label);
	m_Generic2Button.SetText(m_Generic2Label);
	m_Generic4Button.SetText(m_Generic4Label);

	m_Generic1Button.Show();
	m_Generic2Button.Show();
	m_Generic4Button.Show();
}

// Flash side is initialized.
simulated function OnInit()
{
	super.OnInit();

	if( bUpdateState )
	{
		if( !UpdateLoginState() )
		{
			// Auto-login the user
			LiveClient.StartLoginRequest(EFLC_Platform);
		}
	}

	Movie.InsertHighestDepthScreen(self);

	SetPosition(500, 200);
}

function UpdateDisplay()
{
}

function InitDoBDropDowns()
{
	local int i, days, prevSelected;
	
	m_DoBDayDropdown.Clear();
	m_DoBMonthDropdown.Clear();
	m_DoBYearDropdown.Clear();

	prevSelected = m_DoBYearDropdown.SelectedItem;
	for(i = 0; i < NUM_DROPDOWN_YEARS; i++)
	{
		m_DoBYearDropdown.AddItem(string(2015 - i), string(2015 - i));
	}
	m_DoBYearDropdown.SetSelected(prevSelected);
	
	prevSelected = m_DoBMonthDropdown.SelectedItem;
	for(i = 0; i < m_MonthNames.Length; i++)
	{
		m_DoBMonthDropdown.AddItem(m_MonthNames[i], string(i + 1));
	}
	m_DoBMonthDropdown.SetSelected(prevSelected);

	days = class'X2StrategyGameRulesetDataStructures'.static.DaysInMonth(prevSelected, 2015);
	prevSelected = m_DoBDayDropdown.SelectedItem;
	for(i = 1; i <= days; i++)
	{
		m_DoBDayDropdown.AddItem(string(i), string(i));
	}

	if(prevSelected >= days)
		prevSelected = days-1;

	m_DoBDayDropdown.SetSelected(prevSelected);

	m_DoBDayDropdown.Show();
	m_DoBMonthDropdown.Show();
	m_DoBYearDropdown.Show();
	m_DoBText.Show();
}

function bool UpdateLoginState()
{
	local EStatusType StatusType;

	StatusType = LiveClient.GetStatus();
	`log( `location @ `ShowEnum(EStatusType, StatusType, StatusType),,'FiraxisLive');

	switch(StatusType)
	{
	case E2kST_Online:
	case E2kST_OnlineLoggedIn:
		if( LiveClient.IsAccountAnonymous() )
		{
			LiveClient.UpgradeAccount();
		}
		else if( LiveClient.IsAccountFull() )
		{
			GotoState('LoggedIn');
		}
		else if( LiveClient.IsAccountPlatform() )
		{
			LiveClient.StartLinkAccount();
		}
		else
		{
			return false;
		}
		break;

	case E2kST_Unknown:
	case E2kST_Offline:
	case E2kST_OfflineBanned:
	case E2kST_OfflineBlocked:
	case E2kST_OfflineRejectedWhitelist:
	case E2kST_OfflineRejectedCapacity:
	case E2kST_OfflineLegalAccepted:
	case E2kST_OfflineLoggedInCached:
	case E2kST_LoggedInDoormanOffline:
	default:
		return false;
		break;
	}
	return true;
}

function GotoRequestUnlink()
{
	GotoState('LoggedIn');
}

function GotoUnlinkedAccount()
{
	GotoState('LinkingAccount');
}

function GotoConnectionStatus()
{
	PushState('ConnectionStatus');
}

function GotoConnectionFailure()
{
	GotoState('ConnectionFailure');
}

//==============================================================================
//		STATES:
//==============================================================================
auto state Startup
{
	function ResetScreen()
	{
		`log(`location,,'FiraxisLive');

		HideAll();
	}

	function OnClientStateChange(string StateName)
	{
		`log(`location @ " -- Startup --" @ `ShowVar(StateName),,'FiraxisLive');
		global.OnClientStateChange(StateName);
		UpdateLoginState();
	}

	function OnConnectionFailure(string Reason)
	{
		global.OnConnectionFailure(Reason);
		GotoConnectionFailure();
	}

	function OnConnectionStatusChange(string Title, string Message, string OkLabel)
	{
		global.OnConnectionStatusChange(Title, Message, OkLabel);
		GotoConnectionStatus();
	}

	function OnLogonData(string Title, string Message, string EMailLabel, string PasswordLabel, string OkLabel, string CancelLabel, string CreateLabel, bool Error)
	{
		global.OnLogonData(Title, Message, EMailLabel, PasswordLabel, OkLabel, CancelLabel, CreateLabel, Error);
		GotoUnlinkedAccount();
	}

	function OnLoginStatus(ELoginStatusType Type, EFiraxisLiveAccountType Account, string Message, bool bSuccess)
	{
		global.OnLoginStatus(Type, Account, Message, bSuccess);
		UpdateLoginState();
	}

	/*
	function OnNewAccountNotify(string Title, string Message, string EmailLabel, string OkLabel, string CancelLabel, bool Error)
	{
		global.OnNewAccountNotify(Title, Message, EmailLabel, OkLabel, CancelLabel, Error);
		UpdateLoginState();
	}

	function OnDoBNotify(string Title, string Message, string DoBLabel, string OkLabel, string CancelLabel, array<string> MonthNames, bool Error)
	{
		global.OnDoBNotify(Title, Message, DoBLabel, OkLabel, CancelLabel, MonthNames, Error);
		UpdateLoginState();
	}

	function OnLegalNotify(string Title, string Message, string AgreeLabel, string AgreeAllLabel, string DisagreeLabel, string DisagreeAllLabel, string ReadLabel, array<LegalDocuments> EULAs)
	{
		global.OnLegalNotify(Title, Message, AgreeLabel, AgreeAllLabel, DisagreeLabel, DisagreeAllLabel, ReadLabel, EULAs);
		UpdateLoginState();
	}

	function AgreeToEULA()
	{
		global.AgreeToEULA();
		UpdateLoginState();
	}
	*/


Begin:
	ResetScreen();
}

state LoggedIn
{
	function ShowPopup()
	{
		local TDialogueBoxData kData;

		kData.eType = eDialog_Warning;
		kData.strText = m_UnLinkAccountMessage;
		kData.fnCallback = ConfirmUnlinkAccount;
		
		Movie.Pres.UIRaiseDialog(kData);
	}

	function ConfirmUnlinkAccount(eUIAction Action)
	{
		if(Action == eUIAction_Accept)
		{
			LiveClient.UnlinkAccount();
		}
	
		CloseScreen();
	}

	function OnGeneric1ButtonPress(UIButton button)
	{
		`log(`location,,'FiraxisLive');
		CloseScreen();
	}

	function OnGeneric2ButtonPress(UIButton button)
	{
		`log(`location,,'FiraxisLive');
		LiveClient.UnlinkAccount();
		CloseScreen();
	}

	function OnGeneric4ButtonPress(UIButton button)
	{
		`log(`location @ "-- Not Implemented --",,'FiraxisLive');
	}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
	ShowPopup();
};

state EnterDOBData
{
	function BeginState(name PreviousStateName)
	{
		MC.FunctionVoid("UpdateFirstTimeLayout");
		if(m_DoBYearDropdown == none)
		{
			m_DoBYearDropdown = Spawn(class'UIDropdown', self);
			m_DoBMonthDropdown = Spawn(class'UIDropdown', self);
			m_DoBDayDropdown = Spawn(class'UIDropdown', self);
			m_DoBText = Spawn(class'UIText', self);

			m_DoBYearDropdown.InitDropdown( , , OnDropdownChanged);
			m_DoBYearDropdown.SetPosition(50, 320);
			m_DoBMonthDropdown.InitDropdown( , , OnDropdownChanged);
			m_DoBMonthDropdown.SetPosition(50, 270);
			m_DoBDayDropdown.InitDropdown( , , OnDropdownChanged);
			m_DoBDayDropdown.SetPosition(50, 220);
	
			m_DoBText.InitText(, m_DoBLabel);
			m_DoBText.SetPosition(30, 200);
		}

		InitDoBDropDowns();
	}

	function ResetScreen()
	{
		`log(`location,,'FiraxisLive');
		global.ResetScreen();

		m_Generic4Button.Hide();
	}

	function OnGeneric2ButtonPress(UIButton button)
	{
		local int Month, Day, Year;

		Month = int(m_DoBMonthDropdown.GetSelectedItemData());
		Day = int(m_DoBDayDropdown.GetSelectedItemData());
		Year = int(m_DoBYearDropdown.GetSelectedItemData());

		`log(`location @ `ShowVar(Month) @ `ShowVar(Day) @ `ShowVar(Year),,'FiraxisLive');
		LiveClient.SetDOBData(true, Month, Day, Year);
	}

	function OnGeneric1ButtonPress(UIButton button)
	{
		LiveClient.SetDOBData(false, 0, 0, 0);
		UpdateLoginState();
	}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
};

state CreateUserEmail
{
	function BeginState(name PreviousStateName)
	{
		MC.FunctionVoid("UpdateEULALayout");
	}

	function ResetScreen()
	{
		`log(`location,,'FiraxisLive');

		global.ResetScreen();

		m_Generic4Button.Hide();

		m_UsernameButton.Show();
		m_PasswordButton.Hide();
	}

	function OnGeneric2ButtonPress(UIButton button)
	{
		LiveClient.CreateNewAccount(true,  m_Username);
	}

	function OnGeneric1ButtonPress(UIButton button)
	{
		LiveClient.CreateNewAccount(false, "");
		UpdateLoginState();
	}

	function AutoOpenTextBox();

	function OnConnectionStatusChange(string Title, string Message, string OkLabel)
	{
		`log(`location,,'FiraxisLive');
		global.OnConnectionStatusChange(Title, Message, OkLabel);

		GotoState('ShowEmailNotify');
	}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
	ResetScreen();
};

state ShowEmailNotify
{
	function ResetScreen()
	{
		`log(`location,,'FiraxisLive');
		global.ResetScreen();

		m_Generic1Button.Hide();
		m_Generic2Button.Show();
		m_Generic4Button.Hide();
	}

	function OnGeneric2ButtonPress(UIButton button)
	{
		UpdateLoginState();
	}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
	MC.FunctionVoid("UpdateEULALayout");
	ResetScreen();
};

state ReadEULA
{
	function BeginState(name PreviousStateName)
	{
		local int i;

		m_eulaButtons.Remove(0, m_eulaButtons.Length);
		for( i = 0; i < m_EULAs.Length; ++i )
		{
			m_eulaButtons.AddItem(Spawn(class'UIButton', self));
			m_eulaButtons[i].ResizeToText = false;
			m_eulaButtons[i].InitButton('', class'UIUtilities_Text'.static.AlignLeft(m_ReadLabel$":"@m_EULAs[i].Title), ReadEulas);
			m_eulaButtons[i].SetPosition(320, 240 + (30 * i));
			m_eulaButtons[i].SetWidth( 510 );
			
		}

		//flash set eula layout
		MC.FunctionVoid("UpdateEULALayout");
		
		m_eulaBG = Spawn(class'UIPanel', self).InitPanel('BGBox', class'UIUtilities_Controls'.const.MC_X2Background);
		m_eulaBG.SetSize(870, 750);
		m_eulaBG.SetPosition(-10, -40);
		m_eulaBG.Hide();

		m_eulaText = Spawn(class'UITextContainer', self);
		m_eulaText.InitTextContainer('eulaContainer', "", 0, 0, 850, 700, false);
		m_eulaText.Hide();
		m_eulaTitle = Spawn(class'UITextContainer', m_eulaText);
		m_eulaTitle.InitTextContainer('eulaTitle', "", 0, -30, 850, 30, false);

	}

	function AgreeToEULA()
	{
		local int i;

		NavHelp.ClearButtonHelp();
		m_eulaText.Hide();
		m_eulaBG.Hide();
		
		for(i = 0; i < m_eulaButtons.Length; i++)
		{
			m_eulaButtons[i].Show();
		}

		MC.FunctionVoid("ShowMy2kPanel");
	}

	function AcceptAllEULAs()
	{
		local int i;
		DeclinedDocumentIds.Length = 0;
		for( i = 0; i < m_EULAs.Length; ++i )
		{
			if(AcceptedDocumentIds.Find(m_EULAs[i].UID) == -1)
			{
				AcceptedDocumentIds.AddItem(m_EULAs[i].UID);
			}
			m_eulaButtons[i].Remove();
		}
		LiveClient.RespondLegal(AcceptedDocumentIds, DeclinedDocumentIds);
		LiveClient.UserEULAs(true);
		m_eulaButtons.Remove(0, m_eulaButtons.Length);
		CloseScreen();
		m_2KTitle = "";
	}

	function DisagreeAllEULAs(eUIAction eAction)
	{
		local int i;
		if(eAction == eUIAction_Accept)
		{
			AcceptedDocumentIds.Length = 0;
			for( i = 0; i < m_EULAs.Length; ++i )
			{
				if(DeclinedDocumentIds.Find(m_EULAs[i].UID) == -1)
				{
					DeclinedDocumentIds.AddItem(m_EULAs[i].UID);
				}
				m_eulaButtons[i].Remove();
			}

			LiveClient.RespondLegal(AcceptedDocumentIds, DeclinedDocumentIds);
			LiveClient.CancelLoginRequest(); // Make sure that the login request that opened this window is canceled, otherwise further requests will be denied.
			LiveClient.UserEULAs(false);
			m_eulaButtons.Remove(0, m_eulaButtons.Length);
			CloseScreen();
		}
	}
	

	function OnGeneric2ButtonPress(UIButton button)
	{
		AcceptAllEULAs();
	}

	function OnGeneric1ButtonPress(UIButton button)
	{
		DisagreeAllEULAs(eUIAction_Accept);
	}

	function DeclinePopup()
	{
		local TDialogueBoxData  kDialogData;

		kDialogData.fnCallback = DisagreeAllEULAs;
		kDialogData.strTitle = m_DeclineEULATitle;
		kDialogData.strText = m_DeclineEULABody;
		kDialogData.strAccept = m_Generic1Label;
		kDialogData.strCancel = m_Generic2Label;

		Movie.Pres.UIRaiseDialog(kDialogData);
	}

	function ResetScreen()
	{
		global.ResetScreen();

		m_Generic4Button.Hide();
		m_PasswordButton.Hide();
		m_UsernameButton.Hide();
	}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
	ResetScreen();
};

state LinkingAccount_NewUser
{
	function BeginState(name PreviousStateName)
	{
		MC.FunctionVoid("UpdateLoginLayout");
	}

	function EndState(name NextStateName)
	{
		m_Generic4Button.Show();
		m_PasswordButton.Show();
	}

	function InitButtons()
	{
		m_Generic4Button.Hide();
		m_PasswordButton.Hide();
	}

	function ResetScreen()
	{	
		MC.FunctionString("UpdateLoginTitle", m_2KTitle);
		MC.FunctionString("setDetailText", m_2KMessage);

		m_Generic1Button.SetText(m_Generic1Label);
		m_Generic2Button.SetText(m_Generic2Label);

		m_Generic1Button.Show();
		m_Generic2Button.Show();
	}

	// Cancel
	function OnGeneric1ButtonPress(UIButton button)
	{
		LiveClient.CreateNewAccount(false, "");
		CloseScreen();
	}

	// Okay
	function OnGeneric2ButtonPress(UIButton button)
	{
		if( len(m_Username) > 0 )
		{
			LiveClient.CreateNewAccount(true, m_Username);
		}
		else
		{
			// TODO: @UI: Make this user friendly ... -ttalley
		}
	}

	function OnLogonData(string Title, string Message, string EMailLabel, string PasswordLabel, string OkLabel, string CancelLabel, string CreateLabel, bool Error)
	{
		`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EMailLabel) @ `ShowVar(PasswordLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(CreateLabel) @ `ShowVar(Error),,'FiraxisLive');

		global.OnLogonData(Title, Message,  EMailLabel, PasswordLabel, OkLabel, CancelLabel, CreateLabel, Error);

		if( m_bWaitingForLogonData )
		{
			m_bWaitingForLogonData = false;
		}
	}

	function OnNewAccountNotify(string Title, string Message, string EmailLabel, string OkLabel, string CancelLabel, bool Error)
	{
		`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EMailLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(Error),,'FiraxisLive');
		global.OnNewAccountNotify(Title, Message, EmailLabel, OkLabel, CancelLabel, Error);

		if( !Error )
		{
			// TODO: Success!!
		}
	}


Begin:
	InitButtons();
	ResetScreen();
	LiveClient.LinkAccount(true, m_Username);
}

state LinkingAccount
{
	function BeginState(name PreviousStateName)
	{
		MC.FunctionVoid("UpdateLoginLayout");
	}

	function EndState(name NextStateName)
	{
		m_bWaitingForLogonData = false;
		m_Generic4Button.SetDisabled(false);
		m_Generic2Button.SetDisabled(false);
	}

	// Cancel
	function OnGeneric1ButtonPress(UIButton button)
	{
		LiveClient.CancelLinkAccount();
		CloseScreen();
	}

	// Okay
	function OnGeneric2ButtonPress(UIButton button)
	{
		m_2kTitle="";
		m_2kMessage = "";
		MC.FunctionString("setDetailText", m_2KMessage);
		
		m_Generic4Button.SetDisabled(false);
		m_Generic2Button.SetDisabled(false);
		m_bWaitingForLogonData = true;
		LiveClient.LinkAccount(false, m_Username, m_Password);
	}

	// Create
	function OnGeneric4ButtonPress(UIButton button)
	{
		//LiveClient.StartNewAccount();
		if( !m_PasswordEntered )
		{
			m_Generic4Button.SetDisabled(false);
			m_Generic2Button.SetDisabled(false);
			GotoState('LinkingAccount_NewUser');
		}
	}

	function ResetScreen()
	{
		`log(`location,,'FiraxisLive');
		global.ResetScreen();

		m_Generic1Button.Show();
		m_Generic2Button.Show();
		m_Generic4Button.Show();
		m_PasswordButton.Show();
		m_UsernameButton.Show();
		m_Generic4Button.SetDisabled(m_PasswordEntered);
		m_PasswordButton.SetText(class'UIUtilities_Text'.static.AlignLeft(m_PasswordStarredOutLabel != ""? m_PasswordLabel@m_PasswordStarredOutLabel : m_PasswordLabel));
		m_UsernameButton.SetText(class'UIUtilities_Text'.static.AlignLeft(m_Username != ""? m_UsernameLabel@m_Username : m_UsernameLabel));
	}

	function OnLogonData(string Title, string Message, string EMailLabel, string PasswordLabel, string OkLabel, string CancelLabel, string CreateLabel, bool Error)
	{
		`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EMailLabel) @ `ShowVar(PasswordLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(CreateLabel) @ `ShowVar(Error),,'FiraxisLive');

		global.OnLogonData(Title, Message,  EMailLabel, PasswordLabel, OkLabel, CancelLabel, CreateLabel, Error);

		if( m_bWaitingForLogonData )
		{
			m_bWaitingForLogonData = false;
			m_Generic2Button.EnableButton();
		}
	}

	function OnNewAccountNotify(string Title, string Message, string EmailLabel, string OkLabel, string CancelLabel, bool Error)
	{
		`log(`location @ "-Global-" @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EMailLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(Error),,'FiraxisLive');
		global.OnNewAccountNotify(Title, Message, EmailLabel, OkLabel, CancelLabel, Error);

		// What do I need to cancel here?

	}

	//function OnConnectionStatusChange(string Title, string Message, string OkLabel)
	//{
	//	`log(`location @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(OkLabel),,'FiraxisLive');

	//	global.OnConnectionStatusChange(Title, Message, OkLabel);

	//	UpdateLoginState();
	//}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
	ResetScreen();
};

state ConnectionStatus
{
	event EndState(name NextStateName)
	{
		LiveClient.RespondConnectionStatus();
	}

	function ResetScreen()
	{
		`log(`location,,'FiraxisLive');
		global.ResetScreen();

		m_Generic2Button.Show();

		m_Generic1Button.Hide();
		m_Generic4Button.Hide();
		m_PasswordButton.Hide();
		m_UsernameButton.Hide();
	}

	function OnGeneric2ButtonPress(UIButton button)
	{
		CloseScreen();
	}

	simulated function CloseScreen()
	{
		LiveClient.RespondConnectionStatus();
		global.CloseScreen();
	}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
	MC.FunctionVoid("UpdateEULALayout");
	ResetScreen();
};

state ConnectionFailure
{
	function InitButtons()
	{
		m_Generic1Label = m_InitCloseLabel;
		m_2KTitle = "";
	}

	function ResetScreen()
	{
		`log(`location,,'FiraxisLive');
		global.ResetScreen();

		m_Generic1Button.Show();

		m_Generic2Button.Hide();
		m_Generic4Button.Hide();
		m_PasswordButton.Hide();
		m_UsernameButton.Hide();
	}

	function OnGeneric1ButtonPress(UIButton button)
	{
		CloseScreen();
	}

Begin:
	`log(`location @ "Begin State.",,'FiraxisLive');
	MC.FunctionVoid("UpdateEULALayout");
	InitButtons();
	ResetScreen();
}

//==============================================================================
//		FIRAXIS LIVE EVENT HANDLERS:
//==============================================================================

function OnClientStateChange(string StateName)
{
	`log(`location @ "-Global-" @ `ShowVar(StateName),,'FiraxisLive');
	ResetScreen();
}

function OnConnectionFailure(string Reason)
{
	`log(`location @ "-Global-" @ `ShowVar(Reason),,'FiraxisLive');
	m_2kMessage = Reason;

	ResetScreen();
}

function OnConnectionStatusChange(string Title, string Message, string OkLabel)
{
	`log(`location @ "-Global-" @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(OkLabel),,'FiraxisLive');
	m_2KTitle = Title;
	m_2kMessage = Message;
	m_Generic2Label = OkLabel;

	//ResetScreen();
	GotoConnectionStatus();
}

function OnLogonData(string Title, string Message, string EMailLabel, string PasswordLabel, string OkLabel, string CancelLabel, string CreateLabel, bool Error)
{	
	`log(`location @ "-Global-" @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EMailLabel) @ `ShowVar(PasswordLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(CreateLabel) @ `ShowVar(Error),,'FiraxisLive');
	m_2KTitle = Title;
	m_2kMessage = Message;
	m_UsernameLabel = EmailLabel;
	m_PasswordLabel = PasswordLabel;
	m_Generic2Label = OkLabel;
	m_Generic1Label = CancelLabel;
	m_Generic4Label = CreateLabel;

	ResetScreen();
}

function OnLoginStatus(ELoginStatusType Type, EFiraxisLiveAccountType Account, string Message, bool bSuccess)
{
	`log(`location @ "-Global-" @ `ShowEnum(ELoginStatusType, Type, Type) @ `ShowEnum(EFiraxisLiveAccountType, Account, Account) @ `ShowVar(Message) @ `ShowVar(bSuccess),,'FiraxisLive');
	//switch(Type)
	//{
	//case E2kLT_SilentLogin:
	//case E2kLT_Login:
	//case E2kLT_PlatformLogin:
	//case E2kLT_UnLinkAccount:
	//	if( bSuccess )
	//	{
	//		LiveClient.StartLinkAccount();
	//	}
	//	break;
	//case E2kLT_LinkAccount:
	//	if( bSuccess )
	//	{
	//		GotoState('LoggedIn');
	//	}
	//	break;
	//// This should no longer be a thing.
	//case E2kLT_CreateAccount:
	//case E2kLT_Logout:
	//	break;
	//default:
	//	break;
	//}
}

function OnNewAccountNotify(string Title, string Message, string EmailLabel, string OkLabel, string CancelLabel, bool Error)
{
	`log(`location @ "-Global-" @ `ShowVar(Title) @ `ShowVar(Message) @ `ShowVar(EMailLabel) @ `ShowVar(OkLabel) @ `ShowVar(CancelLabel) @ `ShowVar(Error),,'FiraxisLive');
	m_2KTitle = Title;
	m_2kMessage = Message;
	mc.FunctionString("setUsernameText", EmailLabel);
	m_Generic2Label = OkLabel;
	m_Generic1Label = CancelLabel;

	ResetScreen();

	if( !Error )
	{
		GotoState('CreateUserEmail');
	}
}

function OnDoBNotify(string Title, string Message, string DoBLabel, string OkLabel, string CancelLabel, array<string> MonthNames, bool Error)
{
	m_2KTitle = Title;
	m_2kMessage = Message;
	m_Generic2Label = OkLabel;
	m_Generic1Label = CancelLabel;
	m_DoBLabel = DoBLabel;
	m_MonthNames = MonthNames;

	ResetScreen();

	if( !Error )
	{
		GotoState('EnterDOBData');
	}
}

function OnLegalNotify(string Title, string Message, string AgreeLabel, string AgreeAllLabel, string DisagreeLabel, string DisagreeAllLabel, string ReadLabel, array<LegalDocuments> EULAs)
{
	m_2KTitle = Title;
	m_Generic2Label = AgreeAllLabel;
	m_Generic1Label = DisagreeAllLabel;
	m_Agree = AgreeLabel;
	m_Disagree = DisagreeLabel;
	m_ReadLabel = ReadLabel;

	m_2kMessage = Message;
	m_EULAs = EULAs;

	ResetScreen();
	GotoState('ReadEULA');
}

function AgreeToEULA()
{
	`log(`location @ "-Global- Unimplemented!",,'FiraxisLive');
}


//==============================================================================
//		UI EVENT HANDLERS:
//==============================================================================
simulated function CloseScreen()
{
	LiveClient.ClearClientStateChangeDelegate(OnClientStateChange);
	LiveClient.ClearConnectionFailureDelegate(OnConnectionFailure);
	LiveClient.ClearConnectionStatusDelegate(OnConnectionStatusChange);
	LiveClient.ClearLogonDataDelegate(OnLogonData);
	LiveClient.ClearLoginStatusDelegate(OnLoginStatus);
	LiveClient.ClearCreateNewAccountDelegate(OnNewAccountNotify);
	LiveClient.ClearDOBDataDelegate(OnDoBNotify);
	LiveClient.ClearLegalInfoDelegate(OnLegalNotify);
	NavHelp.ClearButtonHelp();
	Super.CloseScreen();
}

function OnDropdownChanged(UIDropdown dropdown)
{
	local int days, i, year, currentSelectedDay;
	if(dropdown != m_DoBDayDropdown)
	{
		year = int(m_DoBYearDropdown.GetSelectedItemText());
		currentSelectedDay = m_DoBDayDropdown.SelectedItem;
		m_DoBDayDropdown.Clear();

		days = class'X2StrategyGameRulesetDataStructures'.static.DaysInMonth(m_DoBMonthDropdown.SelectedItem + 1, year);
		for(i = 1; i <= days; i++)
		{
			m_DoBDayDropdown.AddItem(string(i), string(i));
		}

		if(currentSelectedDay > days)
			currentSelectedDay = days -1;

		m_DoBDayDropdown.SetSelected(currentSelectedDay);
	}
}

function ReadEulas(UIButton button)
{
	local int i;

	m_eulaText.Show();
	m_eulaBG.Show();
	MC.FunctionVoid("HideMy2kPanel");

	for(i = 0; i < m_eulaButtons.Length; i++)
	{
		m_eulaButtons[i].Hide();
		if(button == m_eulaButtons[i])
		{
			m_CurrentEULA = i;
			m_eulaText.SetHTMLText(m_EULAs[i].DocumentText);
			m_eulaText.scrollbar.SetThumbAtPercent(0.0f);
			m_eulaTitle.SetText(m_EULAs[i].Title);
		}
	}

	NavHelp.AddCenterHelp(m_InitOKLabel, , AgreeToEULA);
}

function OnGeneric1ButtonPress(UIButton button)
{
	CloseScreen();
}

function OnGeneric2ButtonPress(UIButton button)
{
	`log(`location @ " -- NOT IMPLEMENTED!!",,'FiraxisLive');
}

function OnGeneric4ButtonPress(UIButton button)
{
	`log(`location @ " -- NOT IMPLEMENTED!!",,'FiraxisLive');
}

function OpenTextBoxInput(UIButton button)
{
	local TInputDialogData kData;

	m_TextBoxBeingSet = button;
	kData.fnCallbackAccepted = OnTextBoxInputClosed;

	switch(button) 
	{
	case m_UsernameButton:
		kData.iMaxChars = 256;
		kData.strTitle = m_UsernameLabel;
		kData.strInputBoxText = m_UsernameButton.text != m_UsernameLabel ? m_Username : "";
		Movie.Pres.UIInputDialog(kData);
		break;
	case m_PasswordButton:
		kData.iMaxChars = 256;
		kData.strTitle = m_PasswordLabel;
		kData.strInputBoxText = "";
		kData.bIsPassword = true;
		Movie.Pres.UIInputDialog(kData);
		break;
	}
}

function AutoOpenTextBox()
{
	OpenTextBoxInput(m_PasswordButton);
}

function OnTextBoxInputClosed(string text)
{
	local int i;
	if ((m_TextBoxBeingSet == m_UsernameButton) && (text != m_UsernameLabel))
	{
		m_UsernameButton.SetText(class'UIUtilities_Text'.static.AlignLeft(text));
		m_Username = text;
	}

	if ((m_TextBoxBeingSet == m_PasswordButton) && (text != m_PasswordLabel))
	{
		m_PasswordStarredOutLabel = "*";
		for(i = 1; i < Len(text); i++)
		{
			m_PasswordStarredOutLabel $= "*";
		}

		m_PasswordButton.SetText(m_PasswordStarredOutLabel);
		m_Password = text;
		m_PasswordEntered = true;
	}

	ResetScreen();
}


// Used in navigation stack
simulated function OnRemoved()
{
	super.OnRemoved();

	if( !bStoredMouseIsActive )
		Movie.DeactivateMouse();

	if( OnClosedDelegate != none )
		OnClosedDelegate(true);

}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:	
			OnGeneric1ButtonPress(m_Generic1Button);
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

function ScrollPercentChanged(float newPercent)
{
	MC.FunctionNum("setScrollPercent", newPercent);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
event ActivateEvent()
{
	PC.Pres.UIRedScreen();	
}

defaultproperties
{
	Package = "/ package/gfxMy2kScreen/My2kScreen";
	MCName      = "theScreen";
	LibID       = "My2k_Login";

	bAlwaysTick = true;
	InputState = eInputState_Consume;
	m_bAccountCreationFailure = false;
	m_PasswordEntered = false;
	bUpdateState = true;
}