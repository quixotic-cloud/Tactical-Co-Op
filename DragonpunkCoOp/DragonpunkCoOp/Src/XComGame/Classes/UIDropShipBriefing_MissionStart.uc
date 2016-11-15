//---------------------------------------------------------------
//  FILE:    UIDropShipBriefing_MissionStart.uc
//  AUTHOR:  Brian Whitman --  04/02/2015
//  PURPOSE: Drives the drop ship briefing UI 
//           
//---------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------

class UIDropShipBriefing_MissionStart extends UIDropShipBriefingBase;

var public localized string m_strOpLabel;
var public localized string m_strLocationLabel;
var public localized string m_strBriefingLabel;
var public localized string m_strObjectiveLabel;
var public localized string m_strLaunch;
var public localized string m_strLoadingText;
var public localized string m_strSplashTitle;
var public localized string m_strSplashLabel;
//<workshop> UI_CONSOLE_LOAD_SCREEN_FIXES kmartinez 2015-10-20
// INS:
var public localized string m_strConsoleLaunch;
//</workshop>

var int TipCycle;
var UIButton LaunchButton;
var UIImage TestImage;
var string m_strCurrentTip;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	LaunchButton = Spawn(class'UIButton', self).InitButton('launchButtonMC');
	LaunchButton.bIsVisible = false;
	LaunchButton.DisableNavigation();

	m_strCurrentTip = GetTip(eTip_Tactical);
	UpdateBriefingScreen();

	MC.SetNum("_xscale", 172);
	MC.SetNum("_yscale", 172);
	SetX(44);

	Show();
	SetTimer(1.0, true, 'OnCheckLoading');
}

function UpdateBriefingScreen()
{
	local int numObjectives;
	local X2MissionTemplate MissionTemplate;
	local XComGameState_BattleData BattleData;	
	local GeneratedMissionData GeneratedMission;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	GeneratedMission = class'UIUtilities_Strategy'.static.GetXComHQ().GetGeneratedMissionData(BattleData.m_iMissionID);
	MissionTemplate = class'X2MissionTemplateManager'.static.GetMissionTemplateManager().FindMissionTemplate(GeneratedMission.Mission.MissionName);
	numObjectives = MissionTemplate.GetNumObjectives();

	MC.BeginFunctionOp("updatePreBriefing");
	MC.QueueString(m_strOpLabel);
	MC.QueueString(BattleData.m_strOpName);
	MC.QueueString(m_strLocationLabel);
	MC.QueueString(BattleData.m_strLocation);
	MC.QueueString(m_strBriefingLabel);
	MC.QueueString(MissionTemplate.Briefing);
	MC.QueueString(m_strObjectiveLabel);
	MC.QueueString(numObjectives > 0 ? MissionTemplate.GetObjectiveText(0, GeneratedMission.MissionQuestItemTemplate) : "");
	MC.QueueString(numObjectives > 1 ? MissionTemplate.GetObjectiveText(1, GeneratedMission.MissionQuestItemTemplate) : "");
	MC.QueueString(numObjectives > 2 ? MissionTemplate.GetObjectiveText(2, GeneratedMission.MissionQuestItemTemplate) : "");
	MC.QueueString(m_strCurrentTip);
	MC.QueueString(m_strLoadingText);
	MC.QueueString(m_strSplashTitle);
	MC.QueueString(m_strSplashLabel);
	MC.EndOp();
}

function SetMapImage(string ImagePath)
{
	if (MC != none)
		MC.FunctionString("updateMissionImage", "img:///"$ImagePath);
}

simulated function OnCheckLoading()
{
	local string FinalLaunchStr;
	local string CurrentLanguage;
	local int VerticalTextOffset;
	if (PC.bSeamlessTravelDestinationLoaded)
	{
		LaunchButton.bIsVisible = true;

		if( `ISCONTROLLERACTIVE )
		{
			CurrentLanguage = GetLanguage();

			if(CurrentLanguage == "KOR")
				VerticalTextOffset = -19;

			else if(CurrentLanguage == "CHT")
				VerticalTextOffset = -17;

			else if(CurrentLanguage == "CHN")
				VerticalTextOffset = -20;
		
			else
				VerticalTextOffset = -14;
			FinalLaunchStr = Repl(m_strConsoleLaunch, "%A", class 'UIUtilities_Input'.static.HTML(class 'UIUtilities_Input'.static.GetAdvanceButtonIcon(),24,VerticalTextOffset));
			MC.FunctionString("updateLaunch", FinalLaunchStr);	
		}
		else
		{
			MC.FunctionString("updateLaunch", m_strLaunch);
		}
		
		SetTimer(0.0f);
	}
	else
	{
		TipCycle = (TipCycle + 1) % 10;
		if (TipCycle == 0)
		{
			m_strCurrentTip = GetTip(eTip_Tactical);
			MC.FunctionString("updateTip", m_strCurrentTip);
		}
	}
}

DefaultProperties
{
	Package = "/ package/gfxDropshipBriefing/DropshipBriefing";
	LibID = "DropshipBriefing";
}