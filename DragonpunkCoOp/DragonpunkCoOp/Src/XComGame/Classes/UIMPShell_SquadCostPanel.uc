//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMPShell_SquadCostPanel.uc
//  AUTHOR:  Todd Smith  --  6/30/2015
//  PURPOSE: This file is used for the following stuff..blah
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMPShell_SquadCostPanel extends UIPanel;

var localized string m_strSquadText;
var localized string m_strOpponentSquadText;

var string m_strPlayerName;
var string m_strLoadoutName;

var int m_iSquadCost;
var int m_iMaxSquadCost;
var int m_iNumUnits;

var bool m_bMicAvailable;
var bool m_bMicActive;

var XComGameState m_kMyLoadout;

var localized string m_strPlayerPointsLabel;

var UIText                      StatusText;

var localized string m_strMPLoadout_RemotePlayerInfo_NotReady;
var localized string m_strMPLoadout_RemotePlayerInfo_Ready;


function InitSquadCostPanel(int iMaxSquadCost, XComGameState playerLoadout, string strPlayerName, optional name InitName, optional name InitLibID)
{
	local XComGameState_Unit kUnit;
	local int cost;

	super.InitPanel(InitName, InitLibID);

	m_iMaxSquadCost = iMaxSquadCost;
	m_strPlayerName = strPlayerName;
	cost = 0;
	if(playerLoadout != none)
	{
		m_strLoadoutName = XComGameStateContext_SquadSelect(playerLoadout.GetContext()).strLoadoutName;
		foreach playerLoadout.IterateByClassType(class'XComGameState_Unit', kUnit)
		{
			cost += kUnit.GetUnitPointValue();
		}
		m_iSquadCost = cost;
	}

	
	UpdateSquadCostText();

	AnchorTopCenter();
}

simulated function SetMicAvailable(bool bAvailable)
{
	if(m_bMicAvailable != bAvailable)
	{
		m_bMicAvailable = bAvailable;
		UpdateSquadCostText();
	}
}

simulated function SetMicActive(bool bActive)
{
	if(m_bMicActive != bActive)
	{
		m_bMicActive = bActive;
		UpdateSquadCostText();
	}
}

simulated function OnInit()
{
	super.OnInit();

	MC.FunctionVoid("setPlayerColor");
}

function SetPlayerName(string strPlayerName)
{
	m_strPlayerName = strPlayerName;
	UpdateSquadCostText();
}

function SetPlayerLoadout(XComGameState playerLoadout)
{
	local XComGameState_Unit kUnit;
	local int cost;

	cost = 0;
	if(playerLoadout != none)
	{
		m_strLoadoutName = XComGameStateContext_SquadSelect(playerLoadout.GetContext()).strLoadoutName;
		
		foreach playerLoadout.IterateByClassType(class'XComGameState_Unit', kUnit)
		{
			cost += kUnit.GetUnitPointValue();
		}
		m_iSquadCost = cost;
	}

	UpdateSquadCostText();
}

function SetMaxSquadCost(int iMaxSquadCost)
{
	m_iMaxSquadCost = iMaxSquadCost;
	UpdateSquadCostText();
}

function UpdateSquadCostText()
{
	local int meterPercent;
	local int maximumCost;
	local string maxCostString;
	local string playername;
	local OnlineSubsystem OnlineSub;
    OnlineSub = class'GameEngine'.static.GetOnlineSubsystem(); 

	if(m_iMaxSquadCost == class'X2MPData_Common'.const.INFINITE_VALUE)
	{
		maximumCost = m_iSquadCost;
		maxCostString = class'X2MPData_Shell'.default.m_strMPCustomMatchInfinitePointsString;
	}
	else
	{
		maximumCost = m_iMaxSquadCost;
		maxCostString =string(m_iMaxSquadCost);
	}

	if(maximumCost > 0)
		meterPercent = (float(m_iSquadCost)/maximumCost) * 100.0f;
	else
		meterPercent = 100;

	playername = m_strPlayerName;

	if(m_strPlayerName != "" && OnlineSub.VoiceInterface != none)
	{
		if(m_bMicAvailable)
		{
			if(m_bMicActive)
			{
				playername @= class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_MicActive, , , -8);
			}
			else
			{
				playername @= class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_MicOn, , , -8);
			}
		}
	}

	SetPointMeters(playername, string(m_iSquadCost), maxCostString, m_strSquadText, meterPercent);
}

function setPointMeters(string strPlayerGamertag, string strPlayerTotal, string strPlayerMax, string strPlayerpointTotal, int numPlayerMeter)
{
	MC.BeginFunctionOp("setPointMeters");
	MC.QueueString(strPlayerGamertag);
	MC.QueueString(strPlayerTotal);
	MC.QueueString(strPlayerMax);
	MC.QueueString(strPlayerpointTotal);
	MC.QueueNumber(numPlayerMeter);
	MC.QueueString(m_strLoadoutName);
	MC.EndOp();

	//MC.FunctionVoid("setPointMeters");
}

defaultproperties
{
	LibID     = "MP_PointMeters";

	m_bMicAvailable = false;
	m_bMicActive = false;
}