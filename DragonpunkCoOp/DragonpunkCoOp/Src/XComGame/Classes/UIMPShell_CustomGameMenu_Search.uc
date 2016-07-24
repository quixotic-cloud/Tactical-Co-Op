//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_CustomGameMenu_Search.uc
//  AUTHOR:  Todd Smith  --  8/14/2015
//  PURPOSE: Configure options for a custom game search
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UIMPShell_CustomGameMenu_Search extends UIMPShell_Base
	dependson(X2MPData_Shell)
	dependson(X2MPData_Common);

const MENU_CONTAINER_POSX = 30;
const MENU_CONTAINER_POSY = 110;
const SEARCH_GAME_HEADER_OFFSET_X = 0;
const SEARCH_GAME_HEADER_OFFSET_Y = 10;
const SPINNER_WIDTH = 200;
const SPINNER_OFFSET_X = 150;
const SPINNER_OFFSET_Y = 20;
const SEARCH_GAME_BUTTON_OFFSET_X = 0;
const SEARCH_GAME_BUTTON_OFFSET_Y = 20;

var localized string m_strSearchGameHeaderText;
var localized string m_strMapPlotTypeSpinnerText;
var localized string m_strMapBiomeTypeSpinnerText;
var localized string m_strMaxSquadCostSpinnerText;
var localized string m_strTurnTimerSpinnerText;
var localized string m_strLobbyTypeSpinnerText;
var localized string m_strSearchGameButtonText;
var localized string m_strNoBiomeSelection;

var UIPanel ScreenBG;
var UIList MenuList;
var UIImage MapImage;
var UIText TitleText;
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

var array<TX2UIMapTypeData> m_arrMapTypeData;
var array<TX2UIMaxSquadCostData> m_arrMaxSquadCostData;
var array<TX2UITurnTimerData> m_arrTurnTimerData;
var array<TX2UILobbyTypeData> m_arrLobbyTypeData;

var UINavigationHelp m_NavHelp;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	ScreenBG = Spawn(class'UIPanel', self).InitPanel('BGBox', class'UIUtilities_Controls'.const.MC_X2Background);
	ScreenBG.SetSize(700, 610);
	ScreenBG.SetPosition(-345, -360);
	ScreenBG.AnchorCenter();

	MenuList = Spawn(class'UIList', self);
	MenuList.InitList('', -325, -300, 650, 600, , true);
	MenuList.AnchorCenter();
	MenuList.itemPadding = 2;
	MenuList.Navigator.LoopSelection = true;
	
	MapImage = Spawn(class'UIImage', self).InitImage();
	MapImage.bIsNavigable = false;
	MapImage.SetSize(512, 256);
	MapImage.AnchorCenter();
	MapImage.SetPosition(-256, -75);

	TitleText = Spawn(class'UIText', self).InitText( , m_strSearchGameHeaderText, true);
	TitleText.AnchorCenter();
	TitleText.SetPosition(-325, -350);
	//MapImage.LoadImage(m_kMPShellManager.m_arrMapTypeData[0].strMapImage);

	InitLobbyTypeSpinner();
	InitMaxSquadCostSpinner();
	InitTurnTimerSpinner();
	InitMapPlotTypeSpinner();
	InitMapBiomeTypeSpinner();
	//GameTypeSpinner = MenuList.CreateItem(class'UIMechaListItem');
	m_NavHelp = m_kMPShellManager.NavHelp;
	UpdateNavHelp();

	OnPlotTypeChanged();
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

	m_NavHelp.AddContinueButton(SearchGameButtonCallback, 'X2LargeButton');
	m_NavHelp.ContinueButton.AnchorBottomRight();
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
			SearchGameButtonCallback();
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

function InitMapPlotTypeSpinner()
{
	MapPlotTypeSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();

	m_iSpinnerInt_MapPlotType = m_kMPShellManager.m_arrMapTypeData.Length;
	MapPlotTypeSpinner.UpdateDataSpinner(m_strMapPlotTypeSpinnerText, class'X2MPData_Shell'.default.m_strMPCustomMatchAnyString, OnMapPlotTypeSpinnerChangedCallback);

	m_kMPShellManager.OnlineGame_SetMapPlotInt(class'X2MPData_Common'.const.ANY_VALUE);
}

function InitMapBiomeTypeSpinner()
{
	MapBiomeTypeSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();
	m_iSpinnerInt_MapBiomeType = 0;

	MapBiomeTypeSpinner.UpdateDataSpinner(m_strMapBiomeTypeSpinnerText, m_strNoBiomeSelection, OnMapBiomeTypeSpinnerChangedCallback);
	MapBiomeTypeSpinner.SetDisabled(true);

	m_kMPShellManager.OnlineGame_SetMapBiomeInt(class'X2MPData_Common'.const.ANY_VALUE);
}

function InitMaxSquadCostSpinner()
{
	MaxSquadCostSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();
	m_iSpinnerInt_MaxSquadCost = m_kMPShellManager.m_arrMaxSquadCostData.Length;

	MaxSquadCostSpinner.UpdateDataSpinner(m_strMaxSquadCostSpinnerText, class'X2MPData_Shell'.default.m_strMPCustomMatchAnyString, OnMaxSquadCostSpinnerChangedCallback);
	m_kMPShellManager.OnlineGame_SetMaxSquadCost(class'X2MPData_Common'.const.ANY_VALUE);
}

function InitTurnTimerSpinner()
{
	TurnTimerSpinner = UIMechaListItem(MenuList.CreateItem(class'UIMechaListItem')).InitListItem();
	m_iSpinnerInt_TurnTimer = m_kMPShellManager.m_arrTurnTimerData.Length;

	TurnTimerSpinner.UpdateDataSpinner(m_strTurnTimerSpinnerText, class'X2MPData_Shell'.default.m_strMPCustomMatchAnyString, OnTurnTimerSpinnerChangedCallback);
	
	m_kMPShellManager.OnlineGame_SetTurnTimeSeconds(class'X2MPData_Common'.const.ANY_VALUE);
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

	if(m_iSpinnerInt_MapPlotType > m_kMPShellManager.m_arrMapTypeData.Length)
		m_iSpinnerInt_MapPlotType = 0;
	else if(m_iSpinnerInt_MapPlotType < 0)
		m_iSpinnerInt_MapPlotType = m_kMPShellManager.m_arrMapTypeData.Length;
	
	if(m_iSpinnerInt_MapPlotType == m_kMPShellManager.m_arrMapTypeData.Length)
	{
		spinnerControl.SetValue(class'X2MPData_Shell'.default.m_strMPCustomMatchAnyString);
		m_kMPShellManager.OnlineGame_SetMapPlotInt(class'X2MPData_Common'.const.ANY_VALUE);
		return;
	}

	m_kMPShellManager.OnlineGame_SetMapPlotInt(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].FriendlyNameIndex);
	spinnerControl.SetValue(class'X2MPData_Shell'.default.arrMPMapFriendlyNames[m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].FriendlyNameIndex]);

	OnMapBiomeTypeSpinnerChangedCallback(MapBiomeTypeSpinner.Spinner, 0);
}

function OnMapBiomeTypeSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	if(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length == 0)
	{
		spinnerControl.SetValue(m_strNoBiomeSelection);
		MapBiomeTypeSpinner.SetDisabled(true);
		m_kMPShellManager.OnlineGame_SetMapBiomeInt(class'X2MPData_Common'.const.ANY_VALUE);
	}
	else
	{
		MapBiomeTypeSpinner.SetDisabled(false);
		m_iSpinnerInt_MapBiomeType += direction;

		if(m_iSpinnerInt_MapBiomeType > m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length)
			m_iSpinnerInt_MapBiomeType = 0;
		else if(m_iSpinnerInt_MapBiomeType < 0)
			m_iSpinnerInt_MapBiomeType = m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length;
		
		if(m_iSpinnerInt_MapBiomeType == m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].arrValidBiomes.Length)
		{
			spinnerControl.SetValue(class'X2MPData_Shell'.default.m_strMPCustomMatchAnyString);
			m_kMPShellManager.OnlineGame_SetMapBiomeInt(class'X2MPData_Common'.const.ANY_VALUE);
			return;
		}

		spinnerControl.SetValue(class'X2MPData_Shell'.default.arrMPBiomeFriendlyNames[m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].ValidBiomeFriendlyNames[m_iSpinnerInt_MapBiomeType]]);
		m_kMPShellManager.OnlineGame_SetMapBiomeInt(m_kMPShellManager.m_arrMapTypeData[m_iSpinnerInt_MapPlotType].ValidBiomeFriendlyNames[m_iSpinnerInt_MapBiomeType]);
	}

	OnPlotTypeChanged();
}

function OnMaxSquadCostSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	m_iSpinnerInt_MaxSquadCost += direction;
	if(m_iSpinnerInt_MaxSquadCost > m_kMPShellManager.m_arrMaxSquadCostData.Length)
		m_iSpinnerInt_MaxSquadCost = 0;
	else if(m_iSpinnerInt_MaxSquadCost < 0)
		m_iSpinnerInt_MaxSquadCost = m_kMPShellManager.m_arrMaxSquadCostData.Length;
	
	if(m_iSpinnerInt_MaxSquadCost == m_kMPShellManager.m_arrMaxSquadCostData.Length)
	{
		spinnerControl.SetValue(class'X2MPData_Shell'.default.m_strMPCustomMatchAnyString);
		m_kMPShellManager.OnlineGame_SetMaxSquadCost(class'X2MPData_Common'.const.ANY_VALUE);
		return;
	}

	spinnerControl.SetValue(m_kMPShellManager.m_arrMaxSquadCostData[m_iSpinnerInt_MaxSquadCost].strText);
	m_kMPShellManager.OnlineGame_SetMaxSquadCost(m_kMPShellManager.m_arrMaxSquadCostData[m_iSpinnerInt_MaxSquadCost].iCost);
}

function OnTurnTimerSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	m_iSpinnerInt_TurnTimer += direction;
	if(m_iSpinnerInt_TurnTimer > m_kMPShellManager.m_arrTurnTimerData.Length)
		m_iSpinnerInt_TurnTimer = 0;
	else if(m_iSpinnerInt_TurnTimer < 0)
		m_iSpinnerInt_TurnTimer = m_kMPShellManager.m_arrTurnTimerData.Length;
	
	if(m_iSpinnerInt_TurnTimer == m_kMPShellManager.m_arrTurnTimerData.Length)
	{
		spinnerControl.SetValue(class'X2MPData_Shell'.default.m_strMPCustomMatchAnyString);
		m_kMPShellManager.OnlineGame_SetTurnTimeSeconds(class'X2MPData_Common'.const.ANY_VALUE);
		return;
	}

	spinnerControl.SetValue(m_kMPShellManager.m_arrTurnTimerData[m_iSpinnerInt_TurnTimer].strText);
	m_kMPShellManager.OnlineGame_SetTurnTimeSeconds(m_kMPShellManager.m_arrTurnTimerData[m_iSpinnerInt_TurnTimer].iTurnTime);
}

simulated function OnLobbyTypeSpinnerChangedCallback(UIListItemSpinner spinnerControl, int direction)
{
	`log(self $ "::" $ GetFuncName() @ "You CHANGED direction of spinner: " $spinnerControl.Name @" in direction: "$ string(direction),, 'uixcom_mp');
	m_iSpinnerInt_LobbyType += direction;
	if( m_iSpinnerInt_LobbyType >= 0 && m_iSpinnerInt_LobbyType < m_kMPShellManager.m_arrLobbyTypeData.Length && m_kMPShellManager.m_arrLobbyTypeData[m_iSpinnerInt_LobbyType].iLobbyType == eMPNetworkType_Private)
	{
		m_iSpinnerInt_LobbyType += direction; // Skip searching for the Private lobby
	}

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

function BackButtonCallback()
{
	CloseScreen();
}

function SearchGameButtonCallback()
{
	`log(self $ "::" $ GetFuncName(),, 'uixcom_mp');
	m_kMPShellManager.AddSearchGamesCompleteDelegate(OnSearchGamesCompleteCallback);
	m_kMPShellManager.OnlineGame_SearchGame();
}

function OnSearchGamesCompleteCallback(const out TServerBrowserData kServerData, bool bSuccess)
{
	`log(self $ "::" $ GetFuncName() @ `ShowVar(bSuccess),, 'uixcom_mp');
	m_kMPShellManager.ClearSearchGamesCompleteDelegate(OnSearchGamesCompleteCallback);
	if(bSuccess)
	{
		UIMPShell_ServerBrowser(`SCREENSTACK.Push(Spawn(class'UIMPShell_ServerBrowser', Movie.Pres))).InitServerBrowser(kServerData);
	}
}

defaultproperties
{
	DisplayTag="UIDisplay_MPShell"
	CameraTag="UIDisplay_MPShell"
}