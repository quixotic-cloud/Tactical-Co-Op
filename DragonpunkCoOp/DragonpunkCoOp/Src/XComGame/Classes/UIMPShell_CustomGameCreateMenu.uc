//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_CustomGameCreateMenu.uc
//  AUTHOR:  Todd Smith  --  6/23/2015
//  PURPOSE: Configure options for a custom game
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_CustomGameCreateMenu extends UIMPShell_Base
	dependson(X2MPData_Shell);

var localized string m_strCreateGameHeaderText;
var localized string m_strMapPlotTypeSpinnerText;
var localized string m_strMapBiomeTypeSpinnerText;
var localized string m_strMaxSquadCostSpinnerText;
var localized string m_strTurnTimerSpinnerText;
var localized string m_strLobbyTypeSpinnerText;
var localized string m_strPasswordButtonText;
var localized string m_strPasswordDialogTitleText;
var localized string m_strLaunchGameButtonText;
var localized string m_strNoBiomeSelection;

var UIList MenuList;
var UIImage MapImage;
var UIX2PanelHeader TitleText;
var UIPanel ScreenBG;
//var UIMechaListItem   GameTypeSpinner;
var UIMechaListItem   MapPlotTypeSpinner;
var UIMechaListItem   MapBiomeTypeSpinner;
var UIMechaListItem   MaxSquadCostSpinner;
var UIMechaListItem   TurnTimerSpinner;
var UIMechaListItem   LobbyTypeSpinner;

var int m_iSpinnerInt_MapPlotType;
var int m_iSpinnerInt_MapBiomeType;
var int m_iSpinnerInt_MaxSquadCost;
var int m_iSpinnerInt_TurnTimer;
var int m_iSpinnerInt_LobbyType;

var UINavigationHelp m_NavHelp;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	ScreenBG = Spawn(class'UIPanel', self).InitPanel('BGBox', class'UIUtilities_Controls'.const.MC_X2Background);
	ScreenBG.SetSize(700, 610);
	ScreenBG.SetPosition(-345, -360);
	ScreenBG.AnchorCenter();

	MenuList = Spawn(class'UIList', self);
	MenuList.InitList('', -325, -300, 650, 600 );
	MenuList.AnchorCenter();
	MenuList.itemPadding = 2;
	
	MapImage = Spawn(class'UIImage', self).InitImage();
	MapImage.SetSize(512, 256);
	MapImage.AnchorCenter();
	MapImage.SetPosition(-256, -75);

	TitleText = Spawn(class'UIX2PanelHeader', self).InitPanelHeader( , m_strCreateGameHeaderText);
	TitleText.SetHeaderWidth(660);
	TitleText.AnchorCenter();
	TitleText.SetPosition(-325, -350);
	//MapImage.LoadImage(m_kMPShellManager.m_arrMapTypeData[0].strMapImage);

	InitLobbyTypeSpinner();
	InitMaxSquadCostSpinner();
	InitTurnTimerSpinner();
	InitMapPlotTypeSpinner();
	InitMapBiomeTypeSpinner();

	XComShellPresentationLayer(InitController.Pres).CAMLookAtNamedLocation(CameraTag, 0.0f);

	m_NavHelp = m_kMPShellManager.NavHelp;
	UpdateNavHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			LaunchGameButtonCallback();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus() 
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	UpdateLobbyTypeSpinner();
}

function UpdateNavHelp()
{
	m_NavHelp.ClearButtonHelp();
	m_NavHelp.AddBackButton(BackButtonCallback);

	m_NavHelp.AddContinueButton(LaunchGameButtonCallback, 'X2LargeButton');
	m_NavHelp.ContinueButton.AnchorBottomRight();
}

function InitMapPlotTypeSpinner()
{
	MapPlotTypeSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();

	m_iSpinnerInt_MapPlotType = 0;
	MapPlotTypeSpinner.UpdateDataSpinner(m_strMapPlotTypeSpinnerText, class'X2MPData_Shell'.default.arrMPMapFriendlyNames[m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].FriendlyNameIndex], OnMapPlotTypeSpinnerChangedCallback);

	m_kMPShellManager.OnlineGame_SetMapPlotInt(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].FriendlyNameIndex);
	OnPlotTypeChanged();
}

function InitMapBiomeTypeSpinner()
{
	MapBiomeTypeSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();
	m_iSpinnerInt_MapBiomeType = 0;

	if(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length == 0)
	{
		m_kMPShellManager.OnlineGame_SetMapBiomeInt(class'X2MPData_Common'.const.ANY_VALUE);
		MapBiomeTypeSpinner.UpdateDataSpinner(m_strMapBiomeTypeSpinnerText, m_strNoBiomeSelection, OnMapBiomeTypeSpinnerChangedCallback);
		MapBiomeTypeSpinner.SetDisabled(true);
	}
	else
	{
		MapBiomeTypeSpinner.UpdateDataSpinner(m_strMapBiomeTypeSpinnerText, class'X2MPData_Shell'.default.arrMPBiomeFriendlyNames[m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].ValidBiomeFriendlyNames[m_iSpinnerInt_MapBiomeType]], OnMapBiomeTypeSpinnerChangedCallback);
		
		m_kMPShellManager.OnlineGame_SetMapBiomeInt(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].ValidBiomeFriendlyNames[m_iSpinnerInt_MapBiomeType]);

		MapBiomeTypeSpinner.SetDisabled(false);
	}

	OnPlotTypeChanged();
}

function InitMaxSquadCostSpinner()
{
	MaxSquadCostSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();
	m_iSpinnerInt_MaxSquadCost = 0;

	MaxSquadCostSpinner.UpdateDataSpinner(m_strMaxSquadCostSpinnerText, m_kMPShellManager.m_arrMaxSquadCostData[m_iSpinnerInt_MaxSquadCost].strText, OnMaxSquadCostSpinnerChangedCallback);
	m_kMPShellManager.OnlineGame_SetMaxSquadCost(m_kMPShellManager.m_arrMaxSquadCostData[m_iSpinnerInt_MaxSquadCost].iCost);
}

function InitTurnTimerSpinner()
{
	TurnTimerSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();
	m_iSpinnerInt_TurnTimer = 0;

	TurnTimerSpinner.UpdateDataSpinner(m_strTurnTimerSpinnerText, m_kMPShellManager.m_arrTurnTimerData[m_iSpinnerInt_TurnTimer].strText, OnTurnTimerSpinnerChangedCallback);
	
	m_kMPShellManager.OnlineGame_SetTurnTimeSeconds(m_kMPShellManager.m_arrTurnTimerData[m_iSpinnerInt_TurnTimer].iTurnTime);
}

function InitLobbyTypeSpinner()
{
	LobbyTypeSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();
	m_iSpinnerInt_LobbyType = 0;
	UpdateLobbyTypeSpinner();
}

function UpdateLobbyTypeSpinner()
{
	local int i;

	if(m_kMPShellManager.m_OnlineSub.PlayerInterface.IsLocalLogin(m_kMPShellManager.m_OnlineEventMgr.LocalUserIndex) ||
		(m_kMPShellManager.m_bPassedNetworkConnectivityCheck && !m_kMPShellManager.m_bPassedOnlineConnectivityCheck))
	{
		// only LAN games allowed -tsmith
		m_kMPShellManager.OnlineGame_SetNetworkType(eMPNetworkType_LAN);
		for(i = 0; i < m_kMPShellManager.m_arrLobbyTypeData.Length; i++)
		{
			if(m_kMPShellManager.m_arrLobbyTypeData[i].iLobbyType == eMPNetworkType_LAN)
			{
				LobbyTypeSpinner.UpdateDataSpinner(m_strLobbyTypeSpinnerText, m_kMPShellManager.m_arrLobbyTypeData[i].strText);
				break;		
			}
		}
		LobbyTypeSpinner.SetDisabled(true);
	}
	else
	{
		LobbyTypeSpinner.UpdateDataSpinner(m_strLobbyTypeSpinnerText, m_kMPShellManager.m_arrLobbyTypeData[m_iSpinnerInt_LobbyType].strText, OnLobbyTypeSpinnerChangedCallback);
		m_kMPShellManager.OnlineGame_SetNetworkType(m_kMPShellManager.m_arrLobbyTypeData[m_iSpinnerInt_LobbyType].iLobbyType);
	}
}

function OnMapPlotTypeSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	m_iSpinnerInt_MapPlotType += direction;

	if(m_iSpinnerInt_MapPlotType >= m_kMPShellManager.m_arrMapTypeData.Length)
		m_iSpinnerInt_MapPlotType = 0;
	else if(m_iSpinnerInt_MapPlotType < 0)
		m_iSpinnerInt_MapPlotType = m_kMPShellManager.m_arrMapTypeData.Length - 1;

	spinnerControl.SetValue(class'X2MPData_Shell'.default.arrMPMapFriendlyNames[m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].FriendlyNameIndex]);
	m_kMPShellManager.OnlineGame_SetMapPlotInt(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].FriendlyNameIndex);

	OnMapBiomeTypeSpinnerChangedCallback(MapBiomeTypeSpinner.Spinner, 0);
}

function OnMapBiomeTypeSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	if(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length == 0)
	{
		m_kMPShellManager.OnlineGame_SetMapBiomeInt(class'X2MPData_Common'.const.ANY_VALUE);
		spinnerControl.SetValue(m_strNoBiomeSelection);
		MapBiomeTypeSpinner.SetDisabled(true);
	}
	else
	{
		m_iSpinnerInt_MapBiomeType += direction;
		if(m_iSpinnerInt_MapBiomeType >= m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length)
			m_iSpinnerInt_MapBiomeType = 0;
		else if(m_iSpinnerInt_MapBiomeType < 0)
			m_iSpinnerInt_MapBiomeType = m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length - 1;
		spinnerControl.SetValue(class'X2MPData_Shell'.default.arrMPBiomeFriendlyNames[m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].ValidBiomeFriendlyNames[m_iSpinnerInt_MapBiomeType]]);
		m_kMPShellManager.OnlineGame_SetMapBiomeInt(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].ValidBiomeFriendlyNames[m_iSpinnerInt_MapBiomeType]);

		MapBiomeTypeSpinner.SetDisabled(false);
	}

	OnPlotTypeChanged();
}

function OnMaxSquadCostSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	m_iSpinnerInt_MaxSquadCost += direction;
	if(m_iSpinnerInt_MaxSquadCost >= m_kMPShellManager.m_arrMaxSquadCostData.Length)
		m_iSpinnerInt_MaxSquadCost = 0;
	else if(m_iSpinnerInt_MaxSquadCost < 0)
		m_iSpinnerInt_MaxSquadCost = m_kMPShellManager.m_arrMaxSquadCostData.Length - 1;
	spinnerControl.SetValue(m_kMPShellManager.m_arrMaxSquadCostData[m_iSpinnerInt_MaxSquadCost].strText);
	m_kMPShellManager.OnlineGame_SetMaxSquadCost(m_kMPShellManager.m_arrMaxSquadCostData[m_iSpinnerInt_MaxSquadCost].iCost);
}

function OnTurnTimerSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	m_iSpinnerInt_TurnTimer += direction;
	if(m_iSpinnerInt_TurnTimer >= m_kMPShellManager.m_arrTurnTimerData.Length)
		m_iSpinnerInt_TurnTimer = 0;
	else if(m_iSpinnerInt_TurnTimer < 0)
		m_iSpinnerInt_TurnTimer = m_kMPShellManager.m_arrTurnTimerData.Length - 1;
	spinnerControl.SetValue(m_kMPShellManager.m_arrTurnTimerData[m_iSpinnerInt_TurnTimer].strText);
	m_kMPShellManager.OnlineGame_SetTurnTimeSeconds(m_kMPShellManager.m_arrTurnTimerData[m_iSpinnerInt_TurnTimer].iTurnTime);
}

simulated function OnLobbyTypeSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	m_iSpinnerInt_LobbyType += direction;

	if(m_iSpinnerInt_LobbyType >= m_kMPShellManager.m_arrLobbyTypeData.Length)
	{
		m_iSpinnerInt_LobbyType = 0;
	}
	else if(m_iSpinnerInt_LobbyType < 0)
	{
		m_iSpinnerInt_LobbyType = m_kMPShellManager.m_arrLobbyTypeData.Length - 1;
	}
	
	spinnerControl.SetValue(m_kMPShellManager.m_arrLobbyTypeData[m_iSpinnerInt_LobbyType].strText);
	m_kMPShellManager.OnlineGame_SetNetworkType(m_kMPShellManager.m_arrLobbyTypeData[m_iSpinnerInt_LobbyType].iLobbyType);
}

function OnPlotTypeChanged()
{
	MapImage.LoadImage(`MAPS.SelectMPMapImage(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].strPlotType, m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes[m_iSpinnerInt_MapBiomeType]));
}

function PasswordButtonCallback(UIButton kButton)
{
	local TInputDialogData kData;

	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	
	kData.iMaxChars = 16;
	kData.strTitle = m_strPasswordDialogTitleText;
	kData.strInputBoxText = "";
	kData.fnCallbackAccepted = PasswordDialog_OnAccept;
	kData.fnCallbackCancelled = PasswordDialog_OnCancel;
	Movie.Pres.UIInputDialog(kData);
}

function PasswordDialog_OnAccept(string strUserInput)
{
	`log(self $ "::" $ GetFuncName() @ "UserInput=" $ strUserInput,, 'uixcom_mp');
}

function PasswordDialog_OnCancel(string strUserInput)
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
}

function LaunchGameButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	`SCREENSTACK.Push(Spawn(class'UIMPShell_SquadLoadoutList_CustomGameCreate', Movie.Pres));
}

function BackButtonCallback()
{
	CloseScreen();
}
