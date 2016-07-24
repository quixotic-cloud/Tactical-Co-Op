//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelectMissionInfo.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Simple hookup to a text field and formatting MC. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UISquadSelectMissionInfo extends UIPanel;

var localized string m_strObjectives;
var localized string m_strDifficulty;
var localized string m_strRewards;

var localized string m_strTurnTime;
var localized string m_strMapType;

simulated function UISquadSelectMissionInfo InitMissionInfo(optional name InitName)
{
	InitPanel(InitName);
	SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	return self;
}

simulated function UISquadSelectMissionInfo UpdateData(string strMission, string strObjective, string strDifficulty, string strRewards)
{
	mc.BeginFunctionOp("UpdateData");
	mc.QueueString(strMission);
	mc.QueueString(m_strObjectives);
	mc.QueueString(strObjective);
	mc.QueueString(m_strDifficulty);
	mc.QueueString(strDifficulty);
	mc.QueueString(m_strRewards);
	mc.QueueString(strRewards);
	mc.EndOp();
	return self;
}

// we're Hijacking the update data to only show what we want for MP
simulated function UISquadSelectMissionInfo UpdateDataMP(X2MPShellManager MPGameSettings)
{
	mc.BeginFunctionOp("UpdateData");
	mc.QueueString(MPGameSettings.GetMatchString());
	mc.QueueString("");
	mc.QueueString("");
	mc.QueueString(m_strTurnTime);
	mc.QueueString(MPGameSettings.GetTimeString());
	mc.QueueString(m_strMapType);
	mc.QueueString(MPGameSettings.GetMapString());
	mc.EndOp();
	return self;
}


defaultproperties
{
	LibID = "MissionInfo";
	bIsNavigable = false;
	bProcessesMouseEvents = false;
}
