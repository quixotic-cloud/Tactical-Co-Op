//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_MouseControls.uc
//  AUTHORS: Brit Steiner, Tronster
//           
//  PURPOSE: Container for mouse controls within the tactical hud.  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_MouseControls extends UIPanel;

struct TButtonItems
{
	var string Label;	
	var string key;
	var EUIState UIState;	
};

//----------------------------------------------------------------------------
// MEMBERS
var localized string m_strPrevSoldier;
var localized string m_strNextSoldier;
var localized string m_strEndTurn;
var localized string m_strNoKeyBoundString;
var localized string m_strCancelShot;
var localized string m_strShotInfo;

var int m_optPrevSoldier;
var int m_optNextSoldier;
var int m_optEndTurn;
var int m_optRotateCameraLeft;
var int m_optRotateCameraRight;
var int m_optCallSkyranger;

var int m_optCancelShot;
var int m_optShotInfo;

var int m_iCurrentSelection;

var Color         m_clrBad;

var array<TButtonItems> ButtonItems;
var array<AvailableAction> CommandAbilities;

var UIPanel AttentionPulse; 

//----------------------------------------------------------------------------
// METHODS
//

simulated function UITacticalHUD_MouseControls InitMouseControls()
{
	InitPanel();
	
	ButtonItems.Length = 10;

	//Ask to be dynamically bound:
	UITacticalHUD(screen).InitializeMouseControls();

	return self;
}

simulated function OnInit()
{
	super.OnInit();
	UpdateControls();
} 

simulated function SetCommandAbilities(array<AvailableAction> NewCommandAbilities)
{
	CommandAbilities = NewCommandAbilities;
}

simulated function UpdateControls()
{
	local string key, label;
	local PlayerInput kInput;
	local XComKeybindingData kKeyData;
	local int i;
	local TacticalBindableCommands command;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	kInput = PC.PlayerInput;
	kKeyData = Movie.Pres.m_kKeybindingData;

	AS_SetHoverHelp("");

	if(UITacticalHUD(screen).m_isMenuRaised)
	{
		SetNumActiveControls(1);

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(kInput, eGBC_Cancel, eKC_General);
		SetButtonItem( m_optCancelShot,     m_strCancelShot,       key != "" ? key : m_strNoKeyBoundString,    ButtonItems[0].UIState );
	}
	else
	{
		SetNumActiveControls(5 + CommandAbilities.Length );

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(kInput, eTBC_EndTurn);
		SetButtonItem( m_optEndTurn,        m_strEndTurn,       key != "" ? key : m_strNoKeyBoundString,    ButtonItems[m_optEndTurn].UIState );

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(kInput, eTBC_PrevUnit);
		SetButtonItem( m_optPrevSoldier,    m_strPrevSoldier,   key != "" ? key : m_strNoKeyBoundString,    ButtonItems[m_optPrevSoldier].UIState );

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(kInput, eTBC_NextUnit);
		SetButtonItem( m_optNextSoldier,    m_strNextSoldier,   key != "" ? key : m_strNoKeyBoundString,    ButtonItems[m_optNextSoldier].UIState );

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(kInput, eTBC_CamRotateLeft);
		label = kKeyData.GetTacticalBindableActionLabel(eTBC_CamRotateLeft);
		SetButtonItem( m_optRotateCameraLeft,    label,   key != "" ? key : m_strNoKeyBoundString,    ButtonItems[m_optRotateCameraLeft].UIState );

		key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(kInput, eTBC_CamRotateRight);
		label = kKeyData.GetTacticalBindableActionLabel(eTBC_CamRotateRight);
		SetButtonItem( m_optRotateCameraRight,    label,   key != "" ? key : m_strNoKeyBoundString,    ButtonItems[m_optRotateCameraRight].UIState );

		for(i = 0; i < CommandAbilities.Length; i++)
		{
			command = TacticalBindableCommands(eTBC_CommandAbility1 + i);
			AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(CommandAbilities[i].AbilityObjectRef.ObjectID));
			key = kKeyData.GetPrimaryOrSecondaryKeyStringForAction(kInput, command);
			label = Caps(AbilityState.GetMyFriendlyName());
			SetButtonItem( m_optCallSkyranger + i,    label,   key != "" ? key : m_strNoKeyBoundString,    ButtonItems[m_optCallSkyranger + i].UIState, BattleData.IsAbilityObjectiveHighlighted(AbilityState.GetMyTemplateName()));
		}
	}
}

simulated function SetButtonItem( int index, string label, string key, EUIState uistate, optional bool bIsSpecial = false )
{
	// Remap any key names that blow past the maximum space with the wide Asian font
	if ( GetLanguage() == "KOR" || GetLanguage() == "JPN" )
	{
		key = Repl( key, "BACKSPACE", "BKSPACE", false );
	}

	ButtonItems[index].Label     = label;
	ButtonItems[index].key       = key;
	ButtonItems[index].UIState   = uistate;

	AS_SetIconButton(index, label, key, GetIconLabelForIndex(index), ButtonItems[index].UIState != eUIState_Disabled, bIsSpecial);
}


simulated function SetButtonState(int index, EUIState uistate)
{
	SetButtonItem(index, ButtonItems[index].Label, ButtonItems[index].key, uistate);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string sButtonId;
	local int requestID; 

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			//if( `CAMERAMGR.IsCameraBusyWithKismetLookAts() )
			//	return true;
			sButtonId = args[args.Length - 2];
			sButtonId -= "btn";
			m_iCurrentSelection = int(sButtonId);
			OnAccept();
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			sButtonId = args[args.Length - 2];
			sButtonId -= "btn";
			m_iCurrentSelection = int(sButtonId);
			AS_SetHoverHelp( ButtonItems[m_iCurrentSelection].Label $": [" $ButtonItems[m_iCurrentSelection].key $"]" );
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			sButtonId = args[args.Length - 2];
			sButtonId -= "btn";
			requestID = int(sButtonId);
			if( m_iCurrentSelection == requestID )
				AS_SetHoverHelp("");
			break;
	}
}

simulated function bool OnAccept()
{
	local bool bIsFirstTutorial;
	local PlayerInput kInput;
	
	kInput = PC.PlayerInput;

	if (ButtonItems[m_iCurrentSelection].UIState != eUIState_Normal)
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
		return true;
	}

	// Don't allow end turn during the first phase of the tutorial.
	bIsFirstTutorial = ( `BATTLE != none && `BATTLE.m_kDesc.m_bIsTutorial && `BATTLE.m_kDesc.m_bDisableSoldierChatter );

	if( UITacticalHUD(screen).m_isMenuRaised )
	{
		switch( m_iCurrentSelection )
		{
		case  m_optCancelShot:
			UITacticalHUD(screen).CancelTargetingAction();
			break;
		}
	}
	else
	{
		switch( m_iCurrentSelection )
		{
		case  m_optPrevSoldier:
			if( bIsFirstTutorial || !XComTacticalInput(kInput).PrevUnit() )
			{
				PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			}
			break;

		case m_optNextSoldier:
			if( bIsFirstTutorial || !XComTacticalInput(kInput).NextUnit() )
			{
				PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true , true );
			}
			break;

		case m_optEndTurn:
			if( bIsFirstTutorial || !XComTacticalController(PC).PerformEndTurn(ePlayerEndTurnType_PlayerInput) )
			{
				PlaySound(SoundCue'SoundUI.PositiveUISelctionCue', true, true);
			}
			break;
		case m_optRotateCameraLeft:
			XComTacticalInput(kInput).Key_E(class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
			break;
		case m_optRotateCameraRight:
			XComTacticalInput(kInput).Key_Q(class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
			break;
		default:			
			ActivateCommandAbility(m_iCurrentSelection - 5);
			break;
		}
	}
	
	return true; 
}

simulated function ActivateCommandAbility(int AbilityIndex)
{
	local int AbilityHudIndex;

	AbilityHudIndex = UITacticalHUD(Screen).m_kAbilityHUD.GetAbilityIndex(CommandAbilities[AbilityIndex]);
	if(AbilityHudIndex > -1)
	{
		`Pres.GetTacticalHUD().m_kAbilityHUD.SelectAbility( AbilityHudIndex );
	}
}

simulated function string GetIconLabelForIndex(int index)
{
	if(UITacticalHUD(screen).m_isMenuRaised)
	{
		switch(index)
		{
		case m_optCancelShot:	return "cancelShot";
		case m_optShotInfo:		return "shotInfo";
		}
	}
	else
	{
		switch(index)
		{
		case m_optEndTurn:			return "endTurn";
		case m_optPrevSoldier:		return "prevSoldier";
		case m_optNextSoldier:		return "nextSoldier";
		case m_optRotateCameraLeft:	return "rotCamLeft";
		case m_optRotateCameraRight:return "rotCamRight";
		case m_optCallSkyranger:    return "placeEvac";
		}
	}
}

//==============================================================================
// 		FLASH FUNCTIONS:
//==============================================================================
simulated function SetNumActiveControls( int numActive ) {
	Movie.ActionScriptVoid(MCPath$".SetNumActive");
}

simulated function AS_SetIconButton( int index, string label, string hotKey, string iconLabel, bool enabled, bool bIsSpecial) {
	Movie.ActionScriptVoid(MCPath$".SetIconButton");
}

simulated function AS_SetHoverHelp( string label ) {
	Movie.ActionScriptVoid(MCPath$".SetHoverHelp");
}


//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	MCName="mouseControls";

	m_clrBad=(R=200,G=0,B=0,A=175)
	
	// Non-shot hud
	m_optEndTurn 		   = 0;
	m_optPrevSoldier 	   = 1;
	m_optNextSoldier 	   = 2;
	m_optRotateCameraLeft  = 3;
	m_optRotateCameraRight = 4;
	m_optCallSkyranger     = 5;
	// During shot
	m_optCancelShot		   = 0;
	m_optShotInfo		   = 1;

	bAnimateOnInit = false;
}
