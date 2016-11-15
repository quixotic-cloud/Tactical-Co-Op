//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIMissionSummary.uc
//  AUTHOR:  Brit Steiner, Tronster
//  PURPOSE: Display summary of a squad's tactical mission.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIMissionSummary extends UIScreen;

const MISSION_SUCCESS = 0;
const MISSION_FAILURE = 1;

struct TSimCombatSummaryData
{
	var bool bMissionSuccess;
	
	var string MissionName;
	var string MissionType;
	var string MissionDuration;
	var string MissionLocation;
};

var TSimCombatSummaryData SimCombatData;
var UINavigationHelp NavHelp;
var XComGameState_BattleData BattleData;

var localized string m_strMissionComplete;
var localized string m_strMissionFailed;
var localized string m_strMissionAbandoned;

var localized string m_strComplete;
var localized string m_strFailed;

var localized string m_strContinue;
var localized string m_strMissionTypeLabel;
var localized string m_strObjectiveLabel;
var localized string m_strCiviliansRescuedLabel;
var localized string m_strTurnsTakenLabel;
var localized string m_strTurnsRemainingLabel;
var localized string m_strLootRecoveredLabel;
var localized string m_strEnemiesKilledLabel;
var localized string m_strSoldiersWoundedLabel;
var localized string m_strSoldiersKilledLabel;
var localized string m_strRatingLabel;
var localized string m_strFlawlessRating;
var localized string m_strExcellentRating;
var localized string m_strGoodRating;
var localized string m_strFairRating;
var localized string m_strPoorRating;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddContinueButton(CloseScreen);
}

simulated function OnInit()
{
	local int MissionStatus;
	local string MissionResult, MPOPName;
	local X2MissionTemplate MissionTemplate;
	local GeneratedMissionData GeneratedMission;
	local int iKilled, iTotal;

	super.OnInit();

	GeneratedMission = class'UIUtilities_Strategy'.static.GetXComHQ().GetGeneratedMissionData(BattleData.m_iMissionID);
	MissionTemplate = class'X2MissionTemplateManager'.static.GetMissionTemplateManager().FindMissionTemplate(GeneratedMission.Mission.MissionName);

	if( BattleData.bLocalPlayerWon && !BattleData.bMissionAborted )
	{
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(m_strMissionComplete, eUIState_Good);
		MissionStatus = MISSION_SUCCESS;
	}
	else if( BattleData.bMissionAborted )
	{
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(m_strMissionAbandoned, eUIState_Bad);
		MissionStatus = MISSION_FAILURE;
	}
	else if( !BattleData.bLocalPlayerWon )
	{
		MissionResult = class'UIUtilities_Text'.static.GetColoredText(m_strMissionFailed, eUIState_Bad);
		MissionStatus = MISSION_FAILURE;
	}

	iKilled = GetNumEnemiesKilled(iTotal);

	if(BattleData.IsMultiplayer())
	{
		//OP name was using the hosts language, we need to translate here
		if(BattleData.bRanked )
		{
			MPOPName = class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_Ranked];
		}
		else if(BattleData.bAutomatch)
		{
			MPOPName = class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_QuickMatch];
		}
		else
		{
			MPOPName = class'XComMultiplayerUI'.default.m_aMainMenuOptionStrings[eMPMainMenu_CustomMatch];
		}

		SetMissionInfo(
			MissionStatus,
			MissionResult,
			MPOPName,
			GetMaxPointsLabel(),
			GetMaxPointsValue(),
			GetTurnTimeLabel(),
			GetTurnTimeValue(),
			"",
			"",
			"",
			"",
			m_strEnemiesKilledLabel,
			GetEnemiesKilled(),
			m_strSoldiersWoundedLabel,
			GetSoldiersInjured(),
			m_strSoldiersKilledLabel,
			GetSoldiersKilled(),
			m_strRatingLabel,
			GetMissionRating(),
			iKilled,
			iTotal);
	}
	else
	{
		SetMissionInfo(
			MissionStatus,
			MissionResult,
			BattleData.m_strOpName,
			m_strMissionTypeLabel,
			MissionTemplate.PostMissionType,
			GetObjectiveLabel(),
			GetObjectiveValue(),
			GetTurnsLabel(),
			GetTurnsValue(),
			"",
			"",
			m_strEnemiesKilledLabel,
			GetEnemiesKilled(),
			m_strSoldiersWoundedLabel,
			GetSoldiersInjured(),
			m_strSoldiersKilledLabel,
			GetSoldiersKilled(),
			m_strRatingLabel,
			GetMissionRating(),
			iKilled,
			iTotal);
	}
}

simulated function string GetMaxPointsValue()
{
	if(BattleData.iMaxSquadCost < 0)
	{
		return class'UIUtilities_Text'.static.GetColoredText(class'X2MPData_Shell'.default.m_strMPCustomMatchInfinitePointsString, eUIState_Bad);
	}
	else
	{
		return class'UIUtilities_Text'.static.GetColoredText(string(BattleData.iMaxSquadCost), eUIState_Good);
	}
}

simulated function string GetMaxPointsLabel()
{
	return class'UIMPShell_SquadLoadoutList'.default.m_strPointTotalLabel;
}

simulated function string GetTurnTimeLabel()
{
	return class'UISquadSelectMissionInfo'.default.m_strTurnTime;
}

simulated function string GetTurnTimeValue()
{
	if(BattleData.iTurnTimeSeconds > 0)
		return class'UIUtilities_Text'.static.GetColoredText(BattleData.iTurnTimeSeconds@class'X2MPShellManager'.default.m_strTimeLimitPostfix, eUIState_Good);
	else
		return class'UIUtilities_Text'.static.GetColoredText(class'X2MPData_Shell'.default.m_strMPCustomMatchInfiniteTurnTimeString, eUIState_Bad);
}

simulated function string GetMapTypeLabel()
{
	return class'UIMPShell_ServerBrowser'.default.m_strMapTypeText;
}

simulated function string GetMapTypeValue()
{
	return BattleData.strMapType;
}


simulated function string GetObjectiveLabel()
{
	local GeneratedMissionData GeneratedMission;
	
	GeneratedMission = class'UIUtilities_Strategy'.static.GetXComHQ().GetGeneratedMissionData(BattleData.m_iMissionID);
	if(GeneratedMission.Mission.MissionFamily == "Terror")
	{
		return m_strCiviliansRescuedLabel;
	}

	return m_strObjectiveLabel;
}

simulated function string GetObjectiveValue()
{
	local GeneratedMissionData GeneratedMission;

	GeneratedMission = class'UIUtilities_Strategy'.static.GetXComHQ().GetGeneratedMissionData(BattleData.m_iMissionID);
	if(GeneratedMission.Mission.MissionFamily == "Terror")
	{
		return GetCiviliansSaved();
	}

	if(BattleData.OneStrategyObjectiveCompleted())
		return class'UIUtilities_Text'.static.GetColoredText(m_strComplete, eUIState_Good);
	else
		return class'UIUtilities_Text'.static.GetColoredText(m_strFailed, eUIState_Bad);
}

simulated function string GetTurnsLabel()
{
	return m_strTurnsTakenLabel;
}

simulated function string GetTurnsValue()
{
	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local eUIState ColorState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
	{
		if(PlayerState.GetTeam() == eTeam_XCom)
		{
			break;
		}
	}

	if(PlayerState != none)
	{
		if(PlayerState.PlayerTurnCount < 9)
		{
			ColorState = eUIState_Good;
		}
		else if(PlayerState.PlayerTurnCount < 15)
		{
			ColorState = eUIState_Normal;
		}
		else if(PlayerState.PlayerTurnCount < 20)
		{
			ColorState = eUIState_Warning;
		}
		else
		{
			ColorState = eUIState_Bad;
		}

		return class'UIUtilities_Text'.static.GetColoredText(string(PlayerState.PlayerTurnCount), ColorState);
	}

	return "";
}

simulated function string GetMissionRating()
{
	local int iKilled, iTotal, iInjured, iPercentageKilled;

	if(!BattleData.bLocalPlayerWon)
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strPoorRating, eUIState_Bad);
	}

	iKilled = GetNumSoldiersKilled(iTotal);
	iPercentageKilled = (iKilled * 100) / iTotal;
	iInjured = GetNumSoldiersInjured(iTotal);
	
	if(iKilled == 0 && iInjured == 0)
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strFlawlessRating, eUIState_Good);
	}
	else if(iKilled == 0)
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strExcellentRating, eUIState_Good);
	}
	else if(iPercentageKilled <= 34)
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strGoodRating, eUIState_Normal);
	}
	else if(iPercentageKilled <= 50)
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strFairRating, eUIState_Warning);
	}
	else
	{
		return class'UIUtilities_Text'.static.GetColoredText(m_strPoorRating, eUIState_Bad);
	}
}

function string GetCiviliansSaved()
{
	local eUIState ColorState;
	local int iKilled, iTotal, iPercentageKilled;

	iKilled = GetNumCiviliansKilled(iTotal);
	iPercentageKilled = (iKilled*100)/iTotal;

	if( iPercentageKilled <= 25 )
		ColorState = eUIState_Good;
	else if( iPercentageKilled <= 50 )
		ColorState = eUIState_Normal;
	else if( iPercentageKilled < 90 )
		ColorState = eUIState_Warning;
	else
		ColorState = eUIState_Bad;

	return class'UIUtilities_Text'.static.GetColoredText(string(iTotal-iKilled)$"/"$string(iTotal), ColorState);
}

function int GetNumCiviliansKilled(out int iTotal)
{
	return class'Helpers'.static.GetNumCiviliansKilled(iTotal, true);
}

function string GetEnemiesKilled()
{
	local eUIState ColorState;
	local int iKilled, iTotal, iPercentageKilled;

	iKilled = GetNumEnemiesKilled(iTotal);
	iPercentageKilled = (iKilled*100)/iTotal;

	if( iPercentageKilled == 100 )
		ColorState = eUIState_Good;
	else if( iPercentageKilled >= 50 )
		ColorState = eUIState_Warning;
	else
		ColorState = eUIState_Bad;

	return class'UIUtilities_Text'.static.GetColoredText(string(iKilled)$"/"$string(iTotal), ColorState);
}

static function int GetNumEnemiesKilled(out int iOutTotal)
{
	local int iKilled, iTotal, i;
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_BattleData StaticBattleData;

	StaticBattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(StaticBattleData.IsMultiplayer())
	{
		BATTLE().GetEnemyPlayer(XComTacticalController(Battle().GetALocalPlayerController()).m_XGPlayer).GetOriginalUnits(arrUnits);
	}
	else
	{
		BATTLE().GetAIPlayer().GetOriginalUnits(arrUnits);
	}
	
	iTotal = arrUnits.Length;

	for(i = 0; i < iTotal; i++)
	{
		if(arrUnits[i].IsDead())
		{
			iKilled++;
		}
	}

	// add in any aliens from the transfer state
	if(StaticBattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		iTotal += StaticBattleData.DirectTransferInfo.AliensSeen;
		iKilled += StaticBattleData.DirectTransferInfo.AliensKilled;
	}

	// since it's possible (and currently the case) that you pass a value used in this function into
	// the function as the out value, do computations on a local to prevent memory aliasing
	iOutTotal = iTotal;
	return iKilled;
}

function string GetSoldiersKilled()
{
	local eUIState ColorState;
	local int iKilled, iTotal, iPercentageKilled;

	iKilled = GetNumSoldiersKilled(iTotal);
	iPercentageKilled = ((iKilled)*100)/iTotal;

	if( iPercentageKilled == 0 && BattleData.bLocalPlayerWon )
		ColorState = eUIState_Good;
	else if( iPercentageKilled < 50 )
		ColorState = eUIState_Normal;
	else if( iPercentageKilled < 100 )
		ColorState = eUIState_Warning;
	else
		ColorState = eUIState_Bad;

	return class'UIUtilities_Text'.static.GetColoredText(string(iKilled), ColorState);
}

function int GetNumSoldiersKilled(out int iTotal)
{
	local int iKilled, i;
	local array<XComGameState_Unit> arrUnits;

	if(BattleData.IsMultiplayer())
	{
		XComTacticalController(GetALocalPlayerController()).m_XGPlayer.GetOriginalUnits(arrUnits, true);
	}
	else
	{
		BATTLE().GetHumanPlayer().GetOriginalUnits(arrUnits, true);
	}

	iTotal = arrUnits.Length;
	for(i = 0; i < iTotal; i++)
	{
		if(arrUnits[i].IsDead() || arrUnits[i].IsBleedingOut()) //Bleeding-out units get cleaned up by SquadTacticalToStrategyTransfer, but that happens later
		{
			iKilled++;
		}
	}

	return iKilled;
}

function string GetSoldiersInjured()
{
	local eUIState ColorState;
	local int iInjured, iTotal, iPercentageInjured;

	iInjured = GetNumSoldiersInjured(iTotal);
	iPercentageInjured = ((iInjured)*100)/iTotal;

	if( iPercentageInjured == 0 && BattleData.bLocalPlayerWon )
		ColorState = eUIState_Good;
	else if( iPercentageInjured < 50 )
		ColorState = eUIState_Normal;
	else if( iPercentageInjured < 100 )
		ColorState = eUIState_Warning;
	else
		ColorState = eUIState_Bad;

	return class'UIUtilities_Text'.static.GetColoredText(string(iInjured), ColorState);
}

function int GetNumSoldiersInjured(out int iTotal)
{
	local int iInjured, i;
	local array<XComGameState_Unit> arrUnits;

	if(BattleData.IsMultiplayer())
	{
		XComTacticalController(GetALocalPlayerController()).m_XGPlayer.GetOriginalUnits(arrUnits, true);
	}
	else
	{
		BATTLE().GetHumanPlayer().GetOriginalUnits(arrUnits, true);
	}

	iTotal = arrUnits.Length;
	for(i = 0; i < iTotal; i++)
	{
		if(arrUnits[i].WasInjuredOnMission())
		{
			iInjured++;
		}
	}

	return iInjured;
}

static function XGBattle_SP BATTLE()
{
	return XGBattle_SP(`BATTLE);
}

simulated function SetMissionInfo(
	int numStatus, 
	string strStatus,
	string strName,
	string typeLabel,
	string typeValue,
	string statusLabel,
	string statusValue,
	string timerLabel,
	string timerValue,
	string strLootLabel,
	string strLootValue,
	string strEnemyLabel,
	string strEnemyValue,
	string strWoundedLabel,
	string strWoundedValue, 
	string strKilledLabel,
	string strKilledValue,
	string strRatingLabel,
	string strRatingValue,
	int numKilled,
	int numTotal)
{
	// 0 == MISSION SUCCESS
	`XENGINE.SetAlienFXColor(numStatus == MISSION_SUCCESS ? eAlienFX_Cyan : eAlienFX_Red);

	MC.BeginFunctionOp("SetMissionInfo");
	MC.QueueNumber(numStatus);
	MC.QueueString(strStatus);
	MC.QueueString(strName);
	MC.QueueString(typeLabel);
	MC.QueueString(typeValue);
	MC.QueueString(statusLabel);
	MC.QueueString(statusValue);
	MC.QueueString(timerLabel);
	MC.QueueString(timerValue);
	MC.QueueString(strLootLabel);
	MC.QueueString(strLootValue);
	MC.QueueString(strEnemyLabel);
	MC.QueueString(strEnemyValue);
	MC.QueueString(strWoundedLabel);
	MC.QueueString(strWoundedValue);
	MC.QueueString(strKilledLabel);
	MC.QueueString(strKilledValue);
	MC.QueueString(strRatingLabel);
	MC.QueueString(strRatingValue);
	MC.QueueNumber(numKilled);
	MC.QueueNumber(numTotal);
	MC.EndOp();
}

function AddStringParam(string Param, out array<ASValue> Data)
{
	local ASValue Value;
	Value.Type = AS_String;
	Value.s = Param;
	Data.AddItem( Value );
}

function AddNumParam(float Param, out array<ASValue> Data)
{
	local ASValue Value;
	Value.Type = AS_Number;
	Value.n = Param;
	Data.AddItem( Value );
}

//==============================================================================
//		INPUT HANDLING:
//==============================================================================
simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(ucmd, arg))
		return false;

	switch(ucmd)
	{
		// Consume 'B' button here so there is no UI functionality in Mission Summary
		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
			// Consume
			return true;

		// Consume the 'A' button so that it doesn't cascade down the input chain
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			CloseScreen();
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			XComPresentationLayer(Movie.Pres).UIPauseMenu( true );
			return true;
	}

	return super.OnUnrealCommand(ucmd, arg);
}

//==============================================================================
//		CLEANUP:
//==============================================================================
simulated function CloseScreen()
{
	super.CloseScreen();

	// Clear Modal before pop state does it's Pop is kicked off.
	`XENGINE.SetAlienFXColor(eAlienFX_Cyan);

	if(!Movie.Pres.IsA('XComHQPresentationLayer'))
		`TACTICALRULES.bWaitingForMissionSummary = false;
	else
	{
		`HQPRES.UIAfterAction(true);
	}
}

DefaultProperties
{
	Package = "/ package/gfxMissionSummary/MissionSummary";
	MCName = "theMissionSummary";

	InputState = eInputState_Consume;
	
	bConsumeMouseEvents = true;
}
