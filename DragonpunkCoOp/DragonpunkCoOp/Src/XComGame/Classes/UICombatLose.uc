//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIConbatLose
//  AUTHOR:  Brit Steiner -- 4/2/12 
//  PURPOSE: Special tactical game lost screen. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UICombatLose extends UIScreen
	dependson(UIDialogueBox);

enum UICombatLoseOption
{
	eUICombatLoseOpt_Restart,
	eUICombatLoseOpt_Reload,
	eUICombatLoseOpt_ExitToMain,
};


var localized string m_sGenericTitle;
var localized string m_sGenericBody;
var localized string m_sObjectiveTitle;
var localized string m_sObjectiveBody;
var localized string m_sHQAssaultTitle;
var localized string m_sHQAssaultBody;
var localized string m_sCommanderKilledTitle;
var localized string m_sCommanderKilledBody;
var localized string m_sSubtitle;

var localized string m_sRestart;
var localized string m_sReload; 
var localized string m_sExitToMain;

var localized string m_kExitGameDialogue_title;
var localized string m_kExitGameDialogue_body; 
var localized string m_sAccept; 
var localized string m_sCancel;

var localized string m_sReloadDisabledTooltip;

var UICombatLoseType m_eType; 
var UIButton Button0;
var UIButton Button1;
var UIButton Button2;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UIPanel ButtonGroup;
	
	super.InitScreen(InitController, InitMovie, InitName);

	ButtonGroup = Spawn(class'UIPanel', self);
	ButtonGroup.bAnimateOnInit = false;
	ButtonGroup.bIsNavigable = true;
	ButtonGroup.InitPanel('ButtonGroup', '');
	ButtonGroup.bCascadeFocus = false;

	Button0 = Spawn(class'UIButton', ButtonGroup);
	Button0.bAnimateOnInit = false;
	Button0.SetResizeToText(false);
	Button0.InitButton('Button0', m_sRestart, RequestRestart);

	Button1 = Spawn(class'UIButton', ButtonGroup);
	Button1.bAnimateOnInit = false; 
	Button1.SetResizeToText(false);
	Button1.InitButton('Button1', m_sReload, RequestLoad);

	Button2 = Spawn(class'UIButton', ButtonGroup);
	Button2.bAnimateOnInit = false; 
	Button2.SetResizeToText(false);
	Button2.InitButton('Button2', m_sExitToMain, RequestExit);

	Navigator.SetSelected(ButtonGroup);
	ButtonGroup.Navigator.SetSelected(Button0);

	//We're hijacking the pause menu override of the input methods here, to allow the Steam controller to switch the input mode in Tactical to use the menu mode. 
	`BATTLE.m_bInPauseMenu = true;
}

//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	super.OnInit();		

	switch( m_eType )
	{
		case eUICombatLose_UnfailableGeneric:
			AS_SetDisplay(m_sGenericTitle, m_sGenericBody, class'UIUtilities_Image'.const.CombatLose, m_sSubtitle, m_sRestart, m_sReload, m_sExitToMain);
			break;

		case eUICombatLose_UnfailableObjective:
			AS_SetDisplay(m_sObjectiveTitle, m_sObjectiveBody, class'UIUtilities_Image'.const.CombatLose, m_sSubtitle, m_sRestart, m_sReload, m_sExitToMain);
			break;

		case eUICombatLose_UnfailableHQAssault: 
			AS_SetDisplay(m_sHQAssaultTitle, m_sHQAssaultBody, class'UIUtilities_Image'.const.CombatLose, m_sSubtitle, m_sRestart, m_sReload, m_sExitToMain);
			break;
		case eUICombatLose_UnfailableCommanderKilled:
			AS_SetDisplay(m_sCommanderKilledTitle, m_sCommanderKilledBody, class'UIUtilities_Image'.const.CombatLose, m_sSubtitle, m_sRestart, m_sReload, m_sExitToMain);
			break;
	}

	Show();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	return super.OnUnrealCommand(cmd, arg);
}

simulated function RequestRestart(UIButton Button)
{
	//Turn the visualization mgr off while the map shuts down / seamless travel starts
	`XCOMVISUALIZATIONMGR.DisableForShutdown();
	PC.RestartLevel();
}
simulated function RequestLoad(UIButton Button)
{
	Movie.Pres.UILoadScreen(); 
}
simulated function RequestExit(UIButton Button)
{
	local TDialogueBoxData      kDialogData;
	
	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle	= m_kExitGameDialogue_title;
	kDialogData.strText     = m_kExitGameDialogue_body; 
	kDialogData.fnCallback  = ExitGameDialogueCallback;

	kDialogData.strAccept = m_sAccept; 
	kDialogData.strCancel = m_sCancel; 

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function ExitGameDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		`BATTLE.m_bInPauseMenu = false;
		Movie.Pres.UIEndGame();
		`XCOMHISTORY.ResetHistory();
		ConsoleCommand("disconnect");
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}

simulated protected function AS_SetDisplay( string title, string body, string image, string subtitle, string button0Label, string button1Label, string button2Label )
{
	Movie.ActionScriptVoid(screen.MCPath$".SetDisplay");
}



	
DefaultProperties
{
	Package   = "/ package/gfxCombatLose/CombatLose";
	MCName      = "theCombatLoseScreen";
	InputState= eInputState_Consume;
}
