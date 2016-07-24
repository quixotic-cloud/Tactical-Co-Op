//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIRewardsRecap
//  AUTHOR:  Sam Batista
//  PURPOSE: Shows a list of rewards obtained during last mission.
//           Part of the post mission flow.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIRewardsRecap extends UIX2SimpleScreen;

var localized String m_strSuccessSummary;
var localized String m_strFailSummary;
var localized String m_strIncreasedRegionControl;
var localized String m_strDecreasedRegionControl;
var localized String m_strRegionAtMaxControl;
var localized String m_strIncreasedContinentControl;
var localized String m_strDecreasedContinentControl;
var localized String m_strRegionLostOutpost;
var localized String m_strRegionLostContact;
var localized String m_strIncreasedRegionSupplyOutput;
var localized String m_strDecreasedRegionSupplyOutput;
var localized String m_strIncreasedContinentalSupplyOutput;
var localized String m_strDecreasedContinentalSupplyOutput;
var localized String m_strIncreasedSupplyIncome;
var localized String m_strDecreasedSupplyIncome;
var localized String m_strAvatarProgressReducedSingular;
var localized String m_strAvatarProgressReducedPlural;
var localized String m_strAvatarProgressGainedSingular;
var localized String m_strAvatarProgressGainedPlural;
var localized String m_strSecureTransmission;
var localized String m_strGlobalEffects;
var localized String m_strObjectiveRewards;
var localized String m_strAvatarProjectDelayed;

var int CouncilRemarkChance;

var XComGameState_HeadquartersXCom XComHQ;

var name DisplayTag;
var string CameraTag;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	// get existing states
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	
	super.InitScreen( InitController, InitMovie, InitName );
	UpdateNavHelp();
	BuildScreen();

	class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), 0);
	
	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();

	`XCOMGRI.DoRemoteEvent('RewardsRecap');

	if (XComHQ.GetObjectiveStatus('T5_M1_AutopsyTheAvatar') != eObjectiveState_Completed)
	{
		`XCOMGRI.DoRemoteEvent('CIN_ShowCouncil');
		RewardRecapEvents(); // Trigger appropriate Narrative Moment events
	}
	else
	{
		`XCOMGRI.DoRemoteEvent('CIN_ShowResistance');
	}
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();
	NavHelp.AddContinueButton(OnContinue);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), 0);
	UpdateNavHelp();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		// OnAccept
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnContinue();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			`HQPRES.UIPauseMenu( ,true );
			return true;
	}

	return true;
}

function RewardRecapEvents()
{
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState NewGameState;
	local name MissionSourceName;
	local bool bMissionSuccess, bSubmitGameState;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Mission Reward Recap Event Hook");

	MissionSourceName = GetMission().GetMissionSource().DataName;
	bMissionSuccess = WasMissionSuccessful();
	bSubmitGameState = true;

	// If the Councilman has been introduced, play his post-mission comment narratives
	if ((XComHQ.bTutorial && XComHQ.IsObjectiveCompleted('T0_M10_IntroToBlacksite')) ||
		XComHQ.IsObjectiveCompleted('T2_M1_L1_RevealBlacksiteObjective'))
	{
		if (bMissionSuccess && MissionSourceName == 'MissionSource_Blacksite')
		{
			`XEVENTMGR.TriggerEvent('AfterActionCouncil_Blacksite', , , NewGameState);
		}
		else if(bMissionSuccess && MissionSourceName == 'MissionSource_PsiGate')
		{
			`XEVENTMGR.TriggerEvent('AfterActionCouncil_PsiGate', , , NewGameState);
		}
		else if(bMissionSuccess && MissionSourceName == 'MissionSource_Forge')
		{
			`XEVENTMGR.TriggerEvent('AfterActionCouncil_Forge', , , NewGameState);
		}
		else if (MissionSourceName == 'MissionSource_AlienNetwork')
		{
			if (bMissionSuccess)
			{
				`XEVENTMGR.TriggerEvent('AfterActionCouncil_FacilitySuccess', , , NewGameState);
			}
			else
			{
				`XEVENTMGR.TriggerEvent('AfterActionCouncil_FacilityFailed', , , NewGameState);
			}
		}
		else
		{
			if(BattleData.bToughMission)
			{
				`XEVENTMGR.TriggerEvent('AfterActionCouncil_ToughMission', , , NewGameState);
			}
			else if(BattleData.bGreatMission && class'X2StrategyGameRulesetDataStructures'.static.Roll(CouncilRemarkChance))
			{
				`XEVENTMGR.TriggerEvent('AfterActionCouncil_GreatMission', , , NewGameState);
			}
			else
			{
				PlaySFX("HelloCommander");
				bSubmitGameState = false;
			}
		}
	}

	if(bSubmitGameState)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

}

//-------------- UI LAYOUT --------------------------------------------------------
simulated function BuildScreen()
{
	local int i;
	local array<string> EffectsData;
	local string MissionName, MissionLocation, MissionSummary, GlobalEffects;

	// Mission Info
	MissionName = class'UIUtilities_Text'.static.GetColoredText(GetOpNameString(), WasMissionSuccessful() ? eUIState_Good : eUIState_Bad);
	MissionLocation = GetOpLocationString();
	MissionSummary = GetOpSummaryString();
	
	AS_UpdateCouncilAfterActionInfo(MissionName, MissionLocation, m_strSecureTransmission, MissionSummary);

	// Reward Panel
	AS_UpdateCouncilAfterActionRewards(m_strReward, Repl(GetRewardString(), "\n", ", "));

	// Global Effect
	EffectsData = GetGlobalEffectsStrings();
	for(i = 0; i < EffectsData.Length; ++i)
	{
		GlobalEffects $= EffectsData[i];
		if(i < EffectsData.Length - 1)
			GlobalEffects $= ", ";
	}

	if(EffectsData.Length > 0)
		AS_UpdateCouncilAfterActionGlobalAffects(m_strGlobalEffects, GlobalEffects);

	AS_UpdateCouncilAfterActionObjectives(m_strObjectiveRewards, "");
}

simulated function AS_UpdateCouncilAfterActionInfo(string strMission, string strLocation, string strGreeble, string strFlavor)
{
	MC.BeginFunctionOp("UpdateCouncilAfterActionInfo");
	MC.QueueString(strMission);
	MC.QueueString(strLocation);
	MC.QueueString(strGreeble);
	MC.QueueString(strFlavor);
	MC.EndOp();
}

simulated function AS_UpdateCouncilAfterActionRewards(string strRewardLabel, string strRewardValue)
{
	MC.BeginFunctionOp("UpdateCouncilAfterActionRewards");
	MC.QueueString(strRewardLabel);
	MC.QueueString(strRewardValue);
	MC.EndOp();
}

simulated function AS_UpdateCouncilAfterActionGlobalAffects(string strGlobalLabel, string strGlobalValue)
{
	MC.BeginFunctionOp("UpdateCouncilAfterActionGlobalAffects");
	MC.QueueString(strGlobalLabel);
	MC.QueueString(strGlobalValue);
	MC.EndOp();
}

simulated function AS_UpdateCouncilAfterActionObjectives(string strObjectiveLabel, string strObjectiveValue)
{
	MC.BeginFunctionOp("UpdateCouncilAfterActionObjectives");
	MC.QueueString(strObjectiveLabel);
	MC.QueueString(strObjectiveValue);
	MC.EndOp();
}

simulated function AS_UpdateCouncilAfterActionAvatarProgress(string strAvatarLabel, int numPips)
{
	MC.BeginFunctionOp("UpdateCouncilAfterActionAvatarProgress");
	MC.QueueString(strAvatarLabel);
	MC.QueueNumber(numPips);
	MC.EndOp();
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnContinue()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear Reward Recap Data");
	ResistanceHQ = RESHQ();
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
	NewGameState.AddStateObject(ResistanceHQ);
	ResistanceHQ.ClearRewardsRecapData();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	CloseScreen();

	`HQPRES.ExitPostMissionSequence();
}

//-------------- GAME DATA HOOKUP ------------------------------------------------------
simulated function XComGameState_MissionSite GetMission()
{
	return XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID));
}
simulated function String GetOpNameString()
{
	local GeneratedMissionData MissionData;

	MissionData = XComHQ.GetGeneratedMissionData(GetMission().GetReference().ObjectID);

	return MissionData.BattleOpName;
}

simulated function String GetOpLocationString()
{
	return GetMission().GetWorldRegion().GetMyTemplate().DisplayName;
}

simulated function bool WasMissionSuccessful()
{
	local XComGameState_BattleData BattleData;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	return BattleData.bLocalPlayerWon;
}

simulated function bool WasObjectiveSuccessful()
{
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	MissionState = GetMission();

	if(MissionState.Source == 'MissionSource_Retaliation' || (MissionState.Source == 'MissionSource_GuerillaOp' && MissionState.DarkEvent.ObjectID == 0))
	{
		return BattleData.bLocalPlayerWon;
	}

	return BattleData.OneStrategyObjectiveCompleted();
}

simulated function String GetOpSummaryString()
{
	local XComGameState_MissionSite MissionState;
	local X2QuestItemTemplate QuestItem;
	local XGParamTag ParamTag;

	MissionState = GetMission();
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = MissionState.GetWorldRegion().GetMyTemplate().DisplayName;
	QuestItem = X2QuestItemTemplate(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(MissionState.GeneratedMission.MissionQuestItemTemplate));

	if(QuestItem != none)
	{
		ParamTag.StrValue1 = QuestItem.GetItemFriendlyName();
	}
	
	if(WasObjectiveSuccessful())
	{
		if(MissionState.bUsePartialSuccessText && MissionState.PartialSuccessText != "")
		{
			return `XEXPAND.ExpandString(MissionState.PartialSuccessText);
		}

		if(MissionState.SuccessText != "")
		{
			return `XEXPAND.ExpandString(MissionState.SuccessText);
		}

		return `XEXPAND.ExpandString(m_strSuccessSummary);
	}
	else
	{
		if(MissionState.FailureText != "")
		{
			return `XEXPAND.ExpandString(MissionState.FailureText);
		}

		return `XEXPAND.ExpandString(m_strFailSummary);
	}	
}

simulated function String GetRewardString()
{
	return RESHQ().RecapRewardsString;
}

simulated function array<String> GetGlobalEffectsStrings()
{
	local array<String> arrEffects;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int idx;

	ResistanceHQ = RESHQ();

	for(idx = 0; idx < ResistanceHQ.RecapGlobalEffectsGood.Length; idx++)
	{
		arrEffects.AddItem(ColorString(ResistanceHQ.RecapGlobalEffectsGood[idx], eUIState_Good));
	}

	for(idx = 0; idx < ResistanceHQ.RecapGlobalEffectsBad.Length; idx++)
	{
		arrEffects.AddItem(ColorString(ResistanceHQ.RecapGlobalEffectsBad[idx], eUIState_Bad));
	}

	return arrEffects;
}

simulated function Remove()
{
	super.Remove();
	`XCOMGRI.DoRemoteEvent('CIN_HideCouncil');
	`XCOMGRI.DoRemoteEvent('CIN_HideResistance');
}

//------------------------------------------------------

defaultproperties
{
	Package = "/ package/gfxCouncilScreen/CouncilScreen";
	LibID = "CouncilScreenAfterAction";
	DisplayTag="UIDisplay_Council"
	CameraTag="UIDisplayCam_ResistanceScreen"

	CouncilRemarkChance=100
}
