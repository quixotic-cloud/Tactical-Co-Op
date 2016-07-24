//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory
//  AUTHOR:  Sam Batista
//  PURPOSE: Base screen for Armory screens. 
//           It creates and manages the Soldier Pawn, and various UI controls
//			 that get reused on several UIArmory_ screens.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIResearchReport extends UIScreen;

var public localized string m_strCodename;
var public localized string m_strTopSecret;
var public localized string m_strResearchReport;

var name DisplayTag;
var name CameraTag;

var public bool bInstantInterp;

var UILargeButton ContinueButton;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local float InterpTime;

	super.InitScreen(InitController, InitMovie, InitName);
	UpdateNavHelp();

	InterpTime = `HQINTERPTIME;

	if(bInstantInterp)
	{
		InterpTime = 0.0f;
	}

	if( UIMovie_3D(Movie) != none )
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, InterpTime);
}

simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;
	NavHelp.ClearButtonHelp();

	// Show back button when viewing 
	if(Movie.Pres.ScreenStack.IsInStack(class'UIResearchArchives'))
		NavHelp.AddBackButton(CloseScreen);
	else
		NavHelp.AddContinueButton(CloseScreen);

	NavHelp.Show();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	if( UIMovie_3D(Movie) != none )
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, CameraTag, 0);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	UIMovie_3D(Movie).HideDisplay(DisplayTag);
}

simulated function CloseScreen()
{
	super.CloseScreen();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

simulated function InitResearchReport(StateObjectReference TechRef)
{
	local int i;
	local string Unlocks;
	local array<String> arrStrings;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_WorldRegion RegionState;
	local array<StateObjectReference> arrNewTechs;
	local array<StateObjectReference> arrNewInstantTechs;
	local array<StateObjectReference> arrNewProjects;
	local array<X2ItemTemplate> arrNewItems;
	local array<X2FacilityTemplate> arrNewFacilities;
	local array<X2FacilityUpgradeTemplate> arrNewUpgrades;
	local XGParamTag ParamTag;

	class'UIUtilities_Sound'.static.PlayOpenSound();

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	// Unlocks--------------------------------------------------------------------
	TechState.GetMyTemplate().GetUnlocks(arrNewTechs, arrNewProjects, arrNewItems, arrNewFacilities, arrNewUpgrades, arrNewInstantTechs);

	// Items
	arrStrings = class'UIAlert'.static.GetItemUnlockStrings(arrNewItems);
	for( i = 0; i < arrStrings.Length; i++ )
	{
		Unlocks $= arrStrings[i];
		if(i < arrStrings.Length - 1)
			Unlocks $= "\n";
	}
	// Facilities
	arrStrings = class'UIAlert'.static.GetFacilityUnlockStrings(arrNewFacilities);
	if(arrStrings.Length > 0 && Unlocks != "") Unlocks $= "\n";
	for( i = 0; i < arrStrings.Length; i++ )
	{
		Unlocks $= arrStrings[i];
		if(i < arrStrings.Length - 1)
			Unlocks $= "\n";
	}
	// Facility Upgrades
	arrStrings = class'UIAlert'.static.GetUpgradeUnlockStrings(arrNewUpgrades);
	if(arrStrings.Length > 0 && Unlocks != "") Unlocks $= "\n";
	for (i = 0; i < arrStrings.Length; i++)
	{
		Unlocks $= arrStrings[i];
		if(i < arrStrings.Length - 1)
			Unlocks $= "\n";
	}
	// Techs
	arrStrings = class'UIAlert'.static.GetResearchUnlockStrings(arrNewTechs);
	if(arrStrings.Length > 0 && Unlocks != "") Unlocks $= "\n";
	for( i = 0; i < arrStrings.Length; i++ )
	{
		Unlocks $= arrStrings[i];
		if(i < arrStrings.Length - 1)
			Unlocks $= "\n";
	}
	// Proving Ground Projects
	arrStrings = class'UIAlert'.static.GetProjectUnlockStrings(arrNewProjects);
	if(arrStrings.Length > 0 && Unlocks != "") Unlocks $= "\n";
	for (i = 0; i < arrStrings.Length; i++)
	{
		Unlocks $= arrStrings[i];
		if(i < arrStrings.Length - 1)
			Unlocks $= "\n";
	}

	if (TechState.GetMyTemplate().UnlockedDescription != "")
	{
		if (Unlocks != "") Unlocks $= "\n";

		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

		// Datapads
		if (TechState.IntelReward > 0)
		{
			ParamTag.StrValue0 = string(TechState.IntelReward);
		}

		// Facility Leads
		if (TechState.RegionRef.ObjectID != 0)
		{
			RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(TechState.RegionRef.ObjectID));
			ParamTag.StrValue0 = RegionState.GetDisplayName();
		}

		Unlocks $= `XEXPAND.ExpandString(TechState.GetMyTemplate().UnlockedDescription);
	}

	AS_UpdateResearchReport(
		m_strResearchReport, 
		class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS( TechState.GetDisplayName() ),
		m_strCodename @ TechState.GetCodeName(),
		class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`GAME.GetGeoscape().m_kDateTime),
		TechState.GetImage(),
		Unlocks,
		TechState.GetLongDescription(),
		m_strTopSecret);
}

simulated function AS_UpdateResearchReport(string header, string project, string code, string date, string image, string unlocks, string description, string greeble)
{
	MC.BeginFunctionOp("UpdateResearchReport");
	MC.QueueString(header);
	MC.QueueString(project);
	MC.QueueString(code);
	MC.QueueString(date);
	MC.QueueString(image);
	MC.QueueString(unlocks);
	MC.QueueString(description);
	MC.QueueString(greeble);
	MC.EndOp();
}

//==============================================================================

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			CloseScreen();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			CloseScreen();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}


simulated function OnRemoved()
{
	super.OnRemoved();
}

//==============================================================================

defaultproperties
{
	DisplayTag      = "UIBlueprint_Powercore";
	CameraTag       = "UIBlueprint_Powercore";

	Package = "/ package/gfxResearchReport/ResearchReport";
	InputState = eInputState_Evaluate;
	bAnimateOnInit = true;
}
