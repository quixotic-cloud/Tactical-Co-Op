//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIBarMemorial_Details
//  AUTHOR:  Brian Whitman
//  PURPOSE: Bar/Memorial Facility Screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIBarMemorial_Details 
		extends UIScreen
		dependson(UIDialogueBox)
		dependson(UIQueryInterfaceItem)
		dependson(UIInputDialogue);

var int PADDING_LEFT;
var int PADDING_RIGHT;
var int PADDING_TOP;
var int PADDING_BOTTOM;
var int CENTER_PADDING;
var int StatsHeight;
var int StatsTop;

var XComLevelActor RefPolaroidActor;
var XComLevelActor PolaroidActor;
var UIDisplay_LevelActor DisplayActor;
var CameraActor CameraActor;
var Vector WorldOffset;

var StateObjectReference UnitReference;
var XComHQPresentationLayer HQPres;
var XComGameStateHistory History;
var XComGameState_Analytics Analytics;

var UIPanel				BGBox; 
var UISoldierHeader Header;
var UIScrollingText StatsTitle;
var public UIPanel StatArea;
var public UIStatList StatListBasic; 
var UIScrollingText EpitaphTitle;
var UIScrollingText EpitaphText;
var public UIButton EpitaphButton;
var UIButton PoolButton;

var X2ImageCaptureManager ImageCaptureMgr;

var name DisplayTag;
var name CameraTag;

var localized string m_strSoldierStats;
var localized string m_strSoldierEpitaph;
var localized string m_strEpitaphButton;

var localized array<string> m_statLabels;
var localized string m_strDays;

var localized string m_strUnknownCause;
var localized string m_strFriendlyFire;
var localized string m_strFalling;
var localized string m_strExploding;
var localized string m_strPoolButtonText;
var localized string m_strPoolConfirmTitle;
var localized string m_strPoolConfirmBody;

simulated function InitMemorial(StateObjectReference UnitRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int DeadIdx;
	local UIPanel Line; 
	local Texture2D SoldierPicture;
	local MaterialInstanceConstant ScreenMaterial;

	UnitReference = UnitRef;
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	HQPres = XComHQPresentationLayer(PC.Pres);
	ImageCaptureMgr = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager());
	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));

	Header = Spawn(class'UISoldierHeader', self);
	Header.bSoldierStatsHidden = true;
	Header.InitSoldierHeader(UnitReference);
	Header.HideSoldierStats();
	
	StatsTop = Header.Height + PADDING_TOP;
	Height = StatsTop + StatsHeight;

	BGBox = Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2Background).SetSize(Width, Height).SetPosition(25, StatsTop);

	StatsTitle = Spawn(class'UIScrollingText', self);
	StatsTitle.InitScrollingText('StatsTitle', m_strSoldierStats, Width - PADDING_LEFT - PADDING_RIGHT, PADDING_LEFT, PADDING_TOP); 
	StatsTitle.SetPosition(23 + PADDING_LEFT, StatsTop + 10);
	
	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( StatsTitle );

	//-----------------------

	StatArea = Spawn(class'UIPanel', self); 
	StatArea.InitPanel('StatArea').SetPosition(23, Line.Y + PADDING_TOP).SetWidth(Width);
	StatListBasic = Spawn(class'UIStatList', StatArea);
	StatListBasic.InitStatList('StatList', , 0, 0, Width, StatArea.Height);

	PopulateStatsData();
	StatArea.SetHeight(StatListBasic.Height);

	EpitaphTitle = Spawn(class'UIScrollingText', self);
	EpitaphTitle.InitScrollingText('EpitaphTitle', m_strSoldierEpitaph, Width - PADDING_LEFT - PADDING_RIGHT, PADDING_LEFT, PADDING_TOP); 
	EpitaphTitle.SetPosition(23 + PADDING_LEFT, StatArea.Y + StatArea.Height + PADDING_TOP);

	Line = class'UIUtilities_Controls'.static.CreateDividerLineBeneathControl( EpitaphTitle );
	
	MC.FunctionString("setEpitaph", "");
	MC.FunctionNum("setEpitaphY", Line.Y + PADDING_TOP);

	PopulateEpitaphText();
	
	EpitaphButton = Spawn(class'UIButton', self).InitButton('EpitaphButton', m_strEpitaphButton, OnSetEpitaph);
	EpitaphButton.SetPosition((Width - EpitaphButton.Width) / 2, ((BGBox.Y + BGBox.Height) - EpitaphButton.Height) - PADDING_BOTTOM - 10);
	PoolButton = Spawn(class'UIButton', self).InitButton('PoolButton', m_strPoolButtonText, OnPoolButton);
	PoolButton.SetPosition(23 + PADDING_LEFT, EpitaphButton.Y);

	DeadIdx = XComHQ.DeadCrew.Find('ObjectID', UnitReference.ObjectID);
	`assert(DeadIdx != -1);

	// first 36 get their own picture frame, all others get a shared frame
	if (DeadIdx < 36)
	{
		PolaroidActor = GetLevelActor(name("PolaroidActor"$(DeadIdx+1)));
	}
	else
	{
		PolaroidActor = GetLevelActor('PolaroidActor37');
		SoldierPicture = X2ImageCaptureManager(`XENGINE.GetImageCaptureManager()).GetStoredImage(UnitReference, name("UnitPicture"$UnitReference.ObjectID));
		ScreenMaterial = new(self) class'MaterialInstanceConstant';
		ScreenMaterial.SetParent(PolaroidActor.StaticMeshComponent.GetMaterial(0));
		PolaroidActor.StaticMeshComponent.SetMaterial(0, ScreenMaterial);				
		ScreenMaterial.SetTextureParameterValue('PolaroidTexture', SoldierPicture);
		PolaroidActor.StaticMeshComponent.SetHidden(false);
	}

	RefPolaroidActor = GetLevelActor('PolaroidActor37');
	CameraActor = GetCameraActor();
	DisplayActor = UIDisplay_LevelActor(GetLevelActor(DisplayTag));

	WorldOffset = PolaroidActor.Location - RefPolaroidActor.Location;

	CameraActor.SetLocation(CameraActor.Location + WorldOffset);
	DisplayActor.SetLocation(DisplayActor.Location + WorldOffset);

	UpdateNavHelp();

	`HQPRES.CAMLookAtNamedLocation(string(CameraTag), `HQINTERPTIME);
	if(bIsIn3D) UIMovie_3D(Movie).ShowDisplay(DisplayTag, DisplayActor);
}

simulated function OnSetEpitaph(UIButton Button)
{
	local TInputDialogData kData;

	kData.strTitle = m_strSoldierEpitaph;
	kData.strInputBoxText = GetEpitaphText();
	kData.fnCallbackAccepted = OnNewEpitaphSet;
	kData.DialogType = eDialogType_MultiLine;
	kData.iMaxChars = 256;

	HQPres.UIInputDialog(kData);
}

simulated function OnNewEpitaphSet(string newText)
{
	SetEpitaphText(newText);
	PopulateEpitaphText();
}

simulated function OnPoolButton(UIButton Button)
{
	local TDialogueBoxData kDialogData;
	local CharacterPoolManager PoolMgr;
	local XComGameState_Unit UnitState, PoolUnitState;

	PoolMgr = `CHARACTERPOOLMGR;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitReference.ObjectID));
	//  create soldier using the pool function so we have a clean slate to work with
	PoolUnitState = PoolMgr.CreateSoldier(UnitState.GetMyTemplateName());
	//  copy appearance, name, country of origin, et cetera
	PoolUnitState.SetTAppearance(UnitState.kAppearance);
	PoolUnitState.SetCharacterName(UnitState.GetFirstName(), UnitState.GetLastName(), UnitState.GetNickName(true));
	PoolUnitState.SetCountry(UnitState.GetCountry());
	PoolUnitState.SetBackground(UnitState.GetBackground());
	PoolUnitState.SetSoldierClassTemplate(UnitState.GetSoldierClassTemplateName());
	PoolUnitState.PoolTimestamp = class'X2StrategyGameRulesetDataStructures'.static.GetSystemDateTimeString();
	//  save to the pool
	PoolMgr.CharacterPool.AddItem(PoolUnitState);
	PoolMgr.SaveCharacterPool();
	//  let the user know it worked
	kDialogData.eType = eDialog_Normal;
	kDialogData.strTitle = default.m_strPoolConfirmTitle;
	kDialogData.strText = default.m_strPoolConfirmBody;
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;
	Movie.Pres.UIRaiseDialog(kDialogData);
}

simulated function XComLevelActor GetLevelActor(name TagName)
{
	local XComLevelActor TheActor;

	foreach WorldInfo.AllActors(class'XComLevelActor', TheActor)
	{
		if (TheActor != none && TheActor.Tag == TagName)
			break;
	}

	return TheActor;
}

simulated function CameraActor GetCameraActor()
{
	local CameraActor TheActor;

	foreach WorldInfo.AllActors(class'CameraActor', TheActor)
	{
		if (TheActor != none && TheActor.Tag == CameraTag)
			break;
	}

	return TheActor;
}

simulated function SetEpitaphText(string newText)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitChange;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Change Soldier Epitaph");
	UnitChange = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitReference.ObjectID));
	UnitChange.m_strEpitaph = newText;
	NewGameState.AddStateObject(UnitChange );
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function string GetEpitaphText()
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID)).m_strEpitaph;
}

simulated function PopulateStatsData()
{
	local array<UISummary_ItemStat> UnitStats;
	local UISummary_ItemStat AStat;
	local float Hours;
	local int Days;
	local XComGameState_Unit Unit;

	AStat.Label = m_statLabels[ 2 ];
	Hours = Analytics.GetUnitFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_SERVICE_HOURS, UnitReference );
	Days = int(Hours / 24.0f);
	AStat.Value = string(Days) $ " " $ m_strDays;
	UnitStats.AddItem( AStat );

	AStat.Label = m_statLabels[ 3 ];
	Unit = XComGameState_Unit( History.GetGameStateForObjectID( UnitReference.ObjectID ) );
	AStat.Value = Unit.m_strCauseOfDeath;
	UnitStats.AddItem( AStat );

	AStat.Label = m_statLabels[ 4 ];
	Hours = Analytics.GetUnitFloatValue( class'XComGameState_Analytics'.const.ANALYTICS_UNITS_HEALED_HOURS, UnitReference );
	Days = int( Hours / 24.0f );
	AStat.Value = string( Days ) $ " " $ m_strDays;
	UnitStats.AddItem( AStat );

	AStat.Label = m_statLabels[ 5 ];
	AStat.Value = Analytics.GetUnitValueAsString( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ATTACKS, UnitReference );
	UnitStats.AddItem( AStat );

	AStat.Label = m_statLabels[ 6 ];
	AStat.Value = Analytics.GetUnitValueAsString( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE, UnitReference );
	UnitStats.AddItem( AStat );

	AStat.Label = m_statLabels[ 7 ];
	AStat.Value = Analytics.GetUnitValueAsString( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ABILITIES_RECIEVED, UnitReference );
	UnitStats.AddItem( AStat );

	StatListBasic.RefreshData( UnitStats );
}

static simulated function string FormatCauseOfDeath( XComGameState_Unit DeadUnit, XComGameState_Unit Killer, XComGameStateContext Context )
{
	local string CauseOfDeath;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Item WeaponState;
	local X2ItemTemplate ItemTemplate;
	local X2Effect_Persistent PersistentEffect;
	local X2EffectTemplateRef EffectRef;

	if (Killer != none)
	{
		if (Killer.IsASoldier( ))
		{
			CauseOfDeath = Killer.GetName( eNameType_FullNick );
		}
		else
		{
			CauseOfDeath = Killer.GetMyTemplate( ).strCharacterName;
		}

		if (Killer.GetTeam( ) == DeadUnit.GetTeam( ))
		{
			CauseOfDeath = default.m_strFriendlyFire $ " - " $ CauseOfDeath;
		}

		AbilityContext = XComGameStateContext_Ability( Context );
		if (AbilityContext != none)
		{
			if ((AbilityContext.InputContext.AbilityTemplateName == 'StandardShot') ||
				(AbilityContext.InputContext.AbilityTemplateName == 'OverwatchShot') ||
				(AbilityContext.InputContext.AbilityTemplateName == 'ThrowGrenade') ||
				(AbilityContext.InputContext.AbilityTemplateName == 'LaunchGrenade'))
			{
				WeaponState = XComGameState_Item( `XCOMHISTORY.GetGameStateForObjectID( AbilityContext.InputContext.ItemObject.ObjectID ) );
				ItemTemplate = WeaponState.GetMyTemplate( );

				CauseOfDeath = CauseOfDeath $ " - " $ ItemTemplate.GetItemFriendlyNameNoStats();
			}
			else
			{
				AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( AbilityContext.InputContext.AbilityTemplateName );
				CauseOfDeath = CauseOfDeath $ " - " $ AbilityTemplate.LocFriendlyName;
			}
		}

		return CauseOfDeath;
	}

	if (XComGameStateContext_Falling( Context ) != none)
	{
		return default.m_strFalling;
	}

	if (DeadUnit.DamageResults.Length > 0)
	{
		EffectRef = DeadUnit.DamageResults[0].SourceEffect.EffectRef;
		if (EffectRef.SourceTemplateName != '')
		{
			PersistentEffect = X2Effect_Persistent( class'X2Effect'.static.GetX2Effect( EffectRef ) );
			if (PersistentEffect != none)
			{
				return PersistentEffect.FriendlyName;
			}
		}
	}

	if (XComGameStateContext_AreaDamage( Context ) != none)
	{
		return default.m_strExploding;
	}

	return default.m_strUnknownCause;
}

simulated function PopulateEpitaphText()
{
	local string UnitEpitaph;
	UnitEpitaph = GetEpitaphText();
	if (UnitEpitaph != "")
	{
		MC.FunctionString("setEpitaph", UnitEpitaph);
	}
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	if(bIsIn3D) UIMovie_3D(Movie).ShowDisplay(DisplayTag);
	`HQPRES.CAMLookAtNamedLocation(string(CameraTag), `HQINTERPTIME);

	UpdateNavHelp();
}

simulated function OnRemoved()
{
	super.OnRemoved();

	CameraActor.SetLocation(CameraActor.Location - WorldOffset);
	DisplayActor.SetLocation(DisplayActor.Location - WorldOffset);

	if (PolaroidActor == RefPolaroidActor)
	{
		PolaroidActor.StaticMeshComponent.SetHidden(true);
	}

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

//==============================================================================

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			bHandled = true;
			OnClose();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function UpdateNavHelp()
{
	HQPres.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	HQPres.m_kAvengerHUD.NavHelp.AddBackButton(OnClose);
}

simulated function OnClose()
{
	if(bIsIn3D) UIMovie_3D(Movie).HideDisplay(DisplayTag);

	Movie.Stack.PopFirstInstanceOfClass(class'UIBarMemorial_Details');
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

defaultproperties
{
	Width = 915;
	StatsTop = 375;
	StatsHeight = 190;

	PADDING_LEFT	= 14;
	PADDING_RIGHT	= 14;
	PADDING_TOP		= 10;
	PADDING_BOTTOM	= 10;

	Package         = "/ package/gfxMemorialDetail/MemorialDetail";
	MCName          = "theScreen";
	InputState      = eInputState_Evaluate;
	LibID           = "BarMemorialDetailScreenMC";
	DisplayTag      = "UIDisplay_BarMemorialDetail";
	CameraTag    	= "UICamera_BarMemorialDetail";
}
