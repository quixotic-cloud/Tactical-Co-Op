//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITurnOverlay.uc
//  AUTHOR:  Brit Steiner - 7/12/2010
//  PURPOSE: This file corresponds to the changing turns overlay in flash. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITurnOverlay extends UIScreen;

enum ETurnOverlay
{
	eTurnOverlay_Local,
	eTurnOverlay_Remote,
	eTurnOverlay_Alien
};

var float m_fAnimateTime;
var float m_fAnimateRate;
var bool m_bXComTurn;
var bool m_bAlienTurn;
var bool m_bOtherTurn;
var bool m_bReflexAction;
var bool m_bSpecialTurn;

var localized string       m_sXComTurn;
var localized string       m_sAlienTurn;
var localized string       m_sOtherTurn;
var localized string       m_sExaltTurn;
var localized string       m_sReflexAction;
var localized string       m_sSpecialTurn;

var string XComTurnSoundResourcePath;
var string AlienTurnSoundResourcePath;
var string SpecialTurnSoundResourcePath;
var string ReflexStartAndLoopSoundResourcePath;
var string ReflexEndResourcePath;

var AkEvent XComTurnSound;
var AkEvent AlienTurnSound;
var AkEvent SpecialTurnSound;
//----------------------------------------------------------------------------
// MEMBERS

simulated function OnInit()
{
	super.OnInit();

	//When starting a match, this UI element was showing a spurious "reflex action" label for one frame (though nothing called for a reflex action in any way). 
	//Force it to be hidden until something actually wants to trigger it.
	Hide();
	
	if( WorldInfo.NetMode == NM_Standalone && `BATTLE.m_kDesc != None && `BATTLE.m_kDesc.m_iMissionType == eMission_ExaltRaid )		
		SetDisplayText( m_sAlienTurn, m_sXComTurn, m_sExaltTurn, m_sReflexAction, m_sSpecialTurn );
	else
		SetDisplayText( m_sAlienTurn, m_sXComTurn, m_sOtherTurn, m_sReflexAction, m_sSpecialTurn );

	if(`PRES.m_bUIShowMyTurnOnOverlayInit)
	{
		PulseXComTurn();		
	}
	else if(`PRES.m_bUIShowOtherTurnOnOverlayInit)
	{
		PulseOtherTurn();		
	}
	else if(`PRES.m_bUIShowReflexActionOnOverlayInit)
	{
		ShowReflexAction(); 
	}
	else if( `PRES.m_bUIShowSpecialTurnOnOverlayInit )
	{
		ShowSpecialTurn();
	}

	if(!WorldInfo.IsConsoleBuild())
	{
		Invoke("HideBlackBars");
	}
	else
	{
		if( Movie.m_v2FullscreenDimension == Movie.m_v2ViewportDimension )
		{
			Invoke("HideBlackBars");
		}
		else
		{
			AS_ShowBlackBars(); 
		}
	}

	XComTurnSound = AkEvent(DynamicLoadObject(XComTurnSoundResourcePath, class'AkEvent'));
	AlienTurnSound = AkEvent(DynamicLoadObject(AlienTurnSoundResourcePath, class'AkEvent'));
	SpecialTurnSound = AkEvent(DynamicLoadObject(SpecialTurnSoundResourcePath, class'AkEvent'));
}



//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================

simulated function SetDisplayText(string alienText, string xcomText, string p2Text, string reflexText, optional string specialOverlayText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;

	myValue.s = alienText;
	myArray.AddItem( myValue );

	myValue.s = xcomText;
	myArray.AddItem( myValue );

	myValue.s = p2Text;
	myArray.AddItem( myValue );

	myValue.s = reflexText;
	myArray.AddItem(myValue);

	myValue.s = specialOverlayText;
	myArray.AddItem(myValue);

	Invoke("SetText", myArray);
}

//--------------------------------------
simulated function ShowAlienTurn() 
{
	m_bAlienTurn = true;

	`XENGINE.SetAlienFXColor(eAlienFX_Red);
	
	// Still playing last animation?
	if ( m_fAnimateTime != 0 )
		ClearTimer( 'AnimateOut' );
	
	m_fAnimateTime = 0;

	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		SetTimer( m_fAnimateRate, true, 'AnimateIn' );

		Invoke("ShowAlienTurn");

		WorldInfo.PlayAkEvent(AlienTurnSound);
	}
}

simulated function PulseAlienTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();
		Invoke("ShowAlienTurn");
		m_bAlienTurn = true;
	}
}

simulated function HideAlienTurn() 
{	
	m_bAlienTurn = false;

	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		`XENGINE.SetAlienFXColor(eAlienFX_Orange);

		// Still playing last animation?
		if ( m_fAnimateTime != 0 )
			ClearTimer( 'AnimateIn' );

		m_fAnimateTime = 0;

		SetTimer( m_fAnimateRate, true, 'AnimateOut' );

		Invoke("HideAlienTurn");
	}
}


simulated function SetAlienScreenGlow( float fAmount ) 
{
	local MaterialInstanceConstant kMIC;
	kMIC = MaterialInstanceConstant'XComEngineMaterials.PPM_Vignette';
	kMIC.SetScalarParameterValue('Vignette_Intensity', fAmount);
}


simulated function AnimateIn(optional float Delay = -1.0)
{
	m_fAnimateTime += m_fAnimateRate;

	SetAlienScreenGlow( m_fAnimateTime * 2 );

	if ( m_fAnimateTime > 1 )
	{
		ClearTimer( 'AnimateIn' );
		m_fAnimateTime = 0;
	}
}


simulated function AnimateOut(optional float Delay = -1.0)
{
	m_fAnimateTime += m_fAnimateRate;

	SetAlienScreenGlow( 2 - (m_fAnimateTime * 2) );

	if ( m_fAnimateTime > 1 )
	{		
		ClearTimer( 'AnimateOut' );
		m_fAnimateTime = 0;
	}
}
simulated public function AS_ShowBlackBars()
{ 
	Show();
	Movie.ActionScriptVoid(MCPath$".ShowBlackBars"); 
}

//--------------------------------------
simulated function ShowXComTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("ShowXComTurn");

		//XComm turn will need to be cleared specifically, as no game logic will call in 
		//to clear it like the other overlays have. 
		SetTimer( 1.5, false, 'HideXComTurn' );

		m_bXComTurn = true;

		WorldInfo.PlayAkEvent(XComTurnSound);
	}
}
simulated function PulseXComTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("PulseXComTurn");
		m_bXComTurn = true;

		//XComm turn will need to be cleared specifically, as no game logic will call in 
		//to clear it like the other overlays have. 
		SetTimer( 1.5, false, 'HideXComTurn' );
	}
}
simulated function HideXComTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Invoke("HideXComTurn");
		m_bXComTurn = false;
	}
}
//--------------------------------------
simulated function ShowOtherTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("ShowP2Turn");
		m_bOtherTurn = true;
	}
}
simulated function PulseOtherTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("PulseP2Turn");
		m_bOtherTurn = true;
	}
}
simulated function HideOtherTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Invoke("HideP2Turn");
		m_bOtherTurn = false;
	}
}
//--------------------------------------
simulated function ShowReflexAction() 
{
	Show();

	Invoke("ShowReflexAction");
	m_bReflexAction = true;
}

simulated function HideReflexAction() 
{
	XComPresentationLayer(Owner).HUDShow();
	ClearTimer('HideReflexAction');
	Invoke("HideReflexAction");
	m_bReflexAction = false;
}
//--------------------------------------
simulated function ShowSpecialTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Show();

		Invoke("ShowSpecialTurn");
		m_bSpecialTurn = true;

		WorldInfo.PlayAkEvent(SpecialTurnSound);
	}
}
simulated function HideSpecialTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Invoke("HideSpecialTurn");
		m_bSpecialTurn = false;
	}
}
//--------------------------------------

simulated function bool IsShowingAlienTurn()
{
	return m_bAlienTurn;
}
simulated function bool IsShowingXComTurn()
{
	return m_bXComTurn;
}
simulated function bool IsShowingOtherTurn()
{
	return m_bOtherTurn;
}
simulated function bool IsShowingReflexAction()
{
	return m_bReflexAction;
}
simulated function bool IsShowingSpecialTurn()
{
	return m_bSpecialTurn;
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	MCName = "theTurnOverlay";
	Package = "/ package/gfxTurnOverlay/TurnOverlay";
	
	m_fAnimateRate = 0.01f;

	m_bXComTurn  = false;
	m_bAlienTurn = false;
	m_bOtherTurn = false;
	m_bReflexAction = false; 
	m_bSpecialTurn = false;

	bHideOnLoseFocus = false;

	XComTurnSoundResourcePath = "SoundTacticalUI.TacticalUI_XCOMTurn"
	AlienTurnSoundResourcePath = "SoundTacticalUI.TacticalUI_AlienTurn"
	SpecialTurnSoundResourcePath = "DLC_60_SoundTacticalUI.TacticalUI_AlienRulerTurn";
	//ReflexStartAndLoopSoundResourcePath;
	//ReflexEndResourcePath;
}
