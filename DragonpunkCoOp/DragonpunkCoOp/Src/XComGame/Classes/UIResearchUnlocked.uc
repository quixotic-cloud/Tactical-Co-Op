//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIResearchUnlocked
//  AUTHOR:  Sam Batista
//  PURPOSE: Shows a list of techs now available for research.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIResearchUnlocked extends UIScreen;

// Text
var localized string m_strTitle;
var localized string m_strMissingTechName;
var localized string m_strMissingTechDescription;

var name DisplayTag;
var name CameraTag;

var UIPawnMgr PawnMgr;
var XComUnitPawn TyganPawn;

var int CurrentTechIndex;
var int NumUnlockedTechs;

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen( InitController, InitMovie, InitName );
	
	PawnMgr = Spawn( class'UIPawnMgr', Owner );

	class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, `HQINTERPTIME, true);
	UpdateNavHelp();

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so that they don't overlap with the soldiers

	`XCOMGRI.DoRemoteEvent('ResearchUnlocked');
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();
	NavHelp.AddContinueButton(NextResearch);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.Show();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.Hide();
}

simulated function PopulateData(array<StateObjectReference> UnlockedTechs)
{
	local int i;
	local XComGameStateHistory History;
	local XGParamTag LocTag;
	local XComGameState_Tech TechState;
	local string TechName, TechDescription;

	History = `XCOMHISTORY;
	CurrentTechIndex = 0;
	NumUnlockedTechs = UnlockedTechs.Length;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	
	for(i = 0; i < UnlockedTechs.Length; ++i)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(UnlockedTechs[i].ObjectID));

		LocTag.StrValue0 = string(TechState.GetMyTemplate().DataName);

		if(TechState.GetDisplayName() != "")
			TechName = TechState.GetDisplayName();
		else
			TechName = `XEXPAND.ExpandString(m_strMissingTechName);

		if(TechState.GetSummary() != "")
			TechDescription = TechState.GetSummary();
		else
			TechDescription = `XEXPAND.ExpandString(m_strMissingTechDescription);
		
		AddResearch(m_strTitle, TechName, TechState.GetImage(), TechDescription, TechState.GetMyTemplate().bShadowProject);
	}

	// Causes research panels to reposition themselves and animate in.
	MC.FunctionVoid("realize");

	if (UnlockedTechs.Length > 0)
	{
		SpawnTygan();
	}
}

simulated function OnRemoved()
{
	CleanUpTygan();
	super.OnRemoved();
}

simulated function SpawnTygan()
{
	local Vector ZeroPosition;
	local Rotator ZeroRotation;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	TyganPawn = PawnMgr.RequestCinematicPawn(self, XComHQ.GetTyganReference().ObjectID, ZeroPosition, ZeroRotation, 'TyganPawn');

	SetTimer(0.05, false, 'StartTyganMatinee');
}

simulated function StartTyganMatinee()
{
	`XCOMGRI.DoRemoteEvent('StartTyganMatinee');
}

simulated function CleanUpTygan()
{
	local XComGameState_HeadquartersXCom XComHQ;

	if (TyganPawn == none)
		return;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	PawnMgr.ReleaseCinematicPawn(self, XComHQ.GetTyganReference().ObjectID);
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
			NextResearch();
			return true;
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
			`HQPRES.UIPauseMenu( ,true );
			return true;
	}

	return true;
}

simulated function OnCommand(string cmd, string arg)
{
	if(cmd == "NoMoreResearch")
	{
		CloseScreen();
	}
}

simulated function CloseScreen()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	Super.CloseScreen();

	`XCOMGRI.DoRemoteEvent('CIN_UnhideArmoryStaff'); //Show the armory staff now that we are done

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(!XComGameState_MissionSite(History.GetGameStateForObjectID(XComHQ.MissionRef.ObjectID)).GetMissionSource().bSkipRewardsRecap && 
	   XComHQ.IsObjectiveCompleted('T0_M8_ReturnToAvengerPt2'))
	{
		`HQPRES.UIRewardsRecap();
	}
	else
	{
		`HQPRES.ExitPostMissionSequence();
	}
}

simulated function AddResearch(string Header, string Title, string Image, string Description, bool ShadowProject)
{
	MC.BeginFunctionOp("addResearch");
	MC.QueueString(Header);
	MC.QueueString(Title);
	MC.QueueString(Image);
	MC.QueueString(Description);
	MC.QueueBoolean(ShadowProject);
	MC.EndOp();
}

simulated function NextResearch()
{
	MC.FunctionVoid("nextResearch");

	// This is a safety net that ensures the game will continue regardless of animation time
	CurrentTechIndex++;
	if(CurrentTechIndex > NumUnlockedTechs)
	{
		CloseScreen();
	}	
}

//------------------------------------------------------
defaultproperties
{
	Package = "/ package/gfxResearchUnlocked/ResearchUnlocked";
	DisplayTag="UIBlueprint_ResearchUnlocked"
	CameraTag="UIBlueprint_ResearchUnlocked"
}
