//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIGraphicsOptionsDebugScreen.uc
//  AUTHOR:  Ken Derda - 5/13/15
//  PURPOSE: This file corresponds to the server browser list screen in the shell. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UIGraphicsOptionsDebugScreen extends UIScreen;
	/*config(UI)
	native(UI);

//--------------------------------------------------------------------------------------
// MEMBERS

// Must match the FXAA enums in UberPostProcessEffect.uc
enum EFXSFXAAType
{
	FXSAA_Off<DisplayName = Off>,
	FXSAA_FXAA0<DisplayName = FXAA0>,	// NVIDIA 1 pass LQ PS3 and Xbox360 specific optimizations
	FXSAA_FXAA1<DisplayName = FXAA1>,	// NVIDIA 1 pass LQ
	FXSAA_FXAA2<DisplayName = FXAA2>,	// NVIDIA 1 pass LQ
	FXSAA_FXAA3<DisplayName = FXAA3>,	// NVIDIA 1 pass HQ
	FXSAA_FXAA4<DisplayName = FXAA4>,	// NVIDIA 1 pass HQ
	FXSAA_FXAA5<DisplayName = FXAA5>,	// NVIDIA 1 pass HQ
};

var localized string m_strVideoLabel_Mode;
var localized string m_strVideoLabel_Fullscreen;
var localized string m_strVideoLabel_Windowed;
var localized string m_strVideoLabel_BorderlessWindow;

var localized string m_strVideoLabel_Resolution;
var localized string m_strVideoLabel_Gamma;
var localized string m_strVideoLabel_GammaDirections;
var localized string m_strVideoLabel_VSyncToggle;

var localized string m_strGraphicsLabel_Preset;
var localized string m_strGraphicsLabel_Shadow;
var localized string m_strGraphicsLabel_ShadowQuality;
var localized string m_strGraphicsLabel_TextureFiltering;
var localized string m_strGraphicsLabel_TextureDetail;
var localized string m_strGraphicsLabel_AntiAliasing;
var localized string m_strGraphicsLabel_AmbientOcclusion;
var localized string m_strGraphicsLabel_Effects;
var localized string m_strGraphicsLabel_Bloom;
var localized string m_strGraphicsLabel_DepthOfField;
var localized string m_strGraphicsLabel_DirtyLens;
var localized string m_strGraphicsLabel_Decals;
var localized string m_strGraphicsLabel_SubsurfaceScattering;
var localized string m_strGraphicsLabel_ScreenSpaceReflections;
var localized string m_strGraphicsLabel_HighPrecisionGBuffers;

// Graphics settings - re-usable across various graphics options
// =========================================================
var localized string m_strGraphicsSetting_Low;
var localized string m_strGraphicsSetting_Medium;
var localized string m_strGraphicsSetting_High;
var localized string m_strGraphicsSetting_Custom;
var localized string m_strGraphicsSetting_Disabled;

var localized string m_strVideoKeepSettings_Title;
var localized string m_strVideoKeepSettings_Body;
var localized string m_strVideoKeepSettings_Confirm;

var private int m_KeepResolutionCountdown;
var private bool m_bPendingExit;

const GAMMA_HIGH = 2.7;
const GAMMA_LOW = 1.7;

var array<string> m_VideoMode_Labels;

var array<string> m_DefaultGraphicsSettingLabels;

var private bool m_bAnyValueChanged;
var private bool m_bResolutionChanged;
var private bool m_bGammaChanged;

enum EUI_PCOptions_GraphicsSettings
{
	eGraphicsSetting_Disabled,
	eGraphicsSetting_Low,
	eGraphicsSetting_Medium,
	eGraphicsSetting_High,
	eGraphicsSetting_Custom,
};

// NOTE: if this changes, then consts SpinnerEnumCount and CheckboxEnumCount below must change to reflect it
enum EUI_PCOptions_Graphics
{
	// Spinners
	ePCGraphics_Shadow,
	ePCGraphics_ShadowQuality,
	ePCGraphics_TextureFiltering,
	ePCGraphics_TextureDetail,
	ePCGraphics_AntiAliasing,
	ePCGraphics_AmbientOcclusion,
	//ePCGraphics_PostProcessing,

	// CheckBoxes
	ePCGraphics_Effects,
	ePCGraphics_Bloom,
	ePCGraphics_DepthOfField,
	ePCGraphics_DirtyLens,
	ePCGraphics_Decals,
	ePCGraphics_SubsurfaceScattering,
	ePCGraphics_ScreenSpaceReflections,
	ePCGraphics_HighPrecisionGBuffers,
};

// HACK: Can't use ePCGraphics_MAX for TUIGraphicsOptionsInitSettings.SpinnerVals
//		 and TUIGraphicsOptionsInitSettings.CheckBoxVals below.
//		 This must be updated if EUI_PCOptions_Graphics above changes.
const SpinnerEnumCount = 7;
const CheckboxEnumCount = 8;

// Masks are defined in default properties
var array<byte> PerSettingMasks;

//Stores the video settings at the time the screen initializes, for use when exiting without changes. 
struct native TUIGraphicsOptionsInitSettings
{
	// standard settings
	var int iMode;
	var int iResolutionWidth;
	var int iResolutionHeight;
	var bool bVSync;
	var float fGamma;

	// advanced settings
	var int SpinnerVals[SpinnerEnumCount];
	var int CheckBoxVals[CheckboxEnumCount];
};

var TUIGraphicsOptionsInitSettings m_kInitGraphicsSettings;

// Standard settings
var UIListItemSpinner ModeSpinner;
var transient int ModeSpinnerVal;

var UIList ResolutionsList;
var array<string> m_kGameResolutionStrings;
var array<int> m_kGameResolutionWidths;
var array<int> m_kGameResolutionHeights;
var int m_kCurrentSupportedResolutionIndex;

var UICheckbox VSyncCheckBox;
var UISlider GammaSlider;

// Advanced settings
var UIListItemSpinner PresetSpinner;
var transient int PresetSpinnerVal;
var array<UIListItemSpinner> Spinners;
var array<int> SpinnerVals;
var array<UICheckbox> CheckBoxes;

simulated private native function bool GetIsBorderlessWindow();
simulated private native function SetSupportedResolutionsNative(bool bBorderlessWindow);
simulated private native function UpdateViewportNative(INT ScreenWidth, INT ScreenHeight, BOOL Fullscreen, INT BorderlessWindow);
simulated private native function bool GetCurrentVSync();
simulated private native function UpdateVSyncNative(bool bUseVSync);
simulated public native function float GetGammaPercentageNative();
simulated public native function UpdateGammaNative(float UpdateGamma);
simulated private native function SaveGamma();
simulated private native function SaveSystemSettings();

// Determine graphics quality settings from system settings
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentShadowSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentShadowQualitySetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentTextureFilteringSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentTextureDetailSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentAntiAliasingSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentAmbientOcclusionSetting();

simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentEffectsSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentBloomSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentDepthOfFieldSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentDirtyLensSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentDecalsSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentSubsurfaceScatteringSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentScreenSpaceReflectionsSetting();
simulated private native function EUI_PCOptions_GraphicsSettings GetCurrentHighPrecisionGBuffersSetting();

// Set system settings based on graphics quality settings
simulated private native function SetShadowSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetShadowQualitySysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetTextureFilteringSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetTextureDetailSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetAntiAliasingSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetAmbientOcclusionSysSetting(EUI_PCOptions_GraphicsSettings InSetting);

simulated private native function SetEffectsSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetBloomSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetDepthOfFieldSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetDirtyLensSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetDecalsSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetSubsurfaceScatteringSysSettings(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetScreenSpaceReflectionsSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated private native function SetHighPrecisionGBuffersSysSetting(EUI_PCOptions_GraphicsSettings InSetting);


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local UINavigationHelp kNavHelp;

	super.InitScreen(InitController, InitMovie, InitName);

	// Low and High are implicit on all settings
	// Overloading eGraphicsSetting_Custom to mean "if set, use High for medium preset, 
	// else use Low for medium preset" when eGraphicsSetting_Medium is not set
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Custom));	// ePCGraphics_Shadow
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Medium));									// ePCGraphics_ShadowQuality
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Medium));									// ePCGraphics_TextureFiltering
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Medium));									// ePCGraphics_TextureDetail
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Custom));	// ePCGraphics_AntiAliasing
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Custom));	// ePCGraphics_AmbientOcclusion

	// Checkboxes are false on Low and true on High
	// Unlike above we can just use eGraphicsSetting_Medium for medium preset
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_Effects
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_Bloom
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_DepthOfField
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_DirtyLens
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_Decals
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_SubsurfaceScattering
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_ScreenSpaceReflections
	PerSettingMasks.AddItem((1 << eGraphicsSetting_Disabled) | (1 << eGraphicsSetting_Medium));	// ePCGraphics_HighPrecisionGBuffers


	m_bAnyValueChanged = false;
	m_bResolutionChanged = false;
	m_bGammaChanged = false;
	m_bPendingExit = false;

	// Populate the reusable arrays from localized strings
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Disabled);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Low);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Medium);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_High);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Custom);

	m_VideoMode_Labels.AddItem(m_strVideoLabel_Fullscreen);
	m_VideoMode_Labels.AddItem(m_strVideoLabel_BorderlessWindow);
	m_VideoMode_Labels.AddItem(m_strVideolabel_Windowed);

	RefreshData();

	StoreInitGraphicsSettings();

	kNavHelp = Spawn(class'UINavigationHelp', self);
	kNavHelp.InitNavHelp('');
	kNavHelp.SetY(-5);
	kNavHelp.AddBackButton(GoBack);
	kNavHelp.AddRightHelp("SAVE AND EXIT", "", SaveAndExit);
	kNavHelp.AddCenterHelp("RESTORE SETTINGS", "", RestoreInitGraphicsSettings);

	SetTimer(0.1, true, 'WatchForChanges');
}

// This is how the UI updates the safezones when resolution / screen mode canges
function WatchForChanges()
{
	Movie.SetResolutionAndSafeArea();
}

simulated private function RefreshData()
{
	local int currentPos, YPos, YSpacing;
	local Engine Engine;
	local vector2d ViewportSize;
	local UIText TextBox;

	TextBox = Spawn(class'UIText', self).InitText(, "STANDARD SETTINGS");
	TextBox.SetPosition(300, 50);

	// Mode: -----------------------------------------------------
	ModeSpinner = UIListItemSpinner(Spawn(class'UIListItemSpinner', self)
		.InitSpinner(m_strVideoLabel_Mode, , UpdateMode_OnChanged)
		.SetPosition(300, 90)
		.SetSize(800, 35));

	Engine = class'Engine'.static.GetEngine();

	if (Engine.GameViewport.IsFullScreenViewport())
		ModeSpinnerVal = 0;
	else if (GetIsBorderlessWindow())
		ModeSpinnerVal = 1;
	else
		ModeSpinnerVal = 2;

	ModeSpinner.SetValue(m_VideoMode_Labels[ModeSpinnerVal]);

	m_kInitGraphicsSettings.iMode = ModeSpinnerVal;
	Engine.GameViewport.GetViewportSize(ViewportSize);
	m_kInitGraphicsSettings.iResolutionWidth = ViewportSize.X;
	m_kInitGraphicsSettings.iResolutionHeight = ViewportSize.Y;

	// Resolution: -----------------------------------------------
	TextBox = Spawn(class'UIText', self).InitText(, m_strVideoLabel_Resolution);
	TextBox.SetPosition(200, 130);

	ResolutionsList = Spawn(class'UIList', self);
	ResolutionsList.InitList('', 300, 130, 400, 400, false, true);
	ResolutionsList.OnItemClicked = UpdateResolution;

	SetSupportedResolutions();

	// V-Sync toggle: --------------------------------------------
	m_kInitGraphicsSettings.bVSync = GetCurrentVSync();
	VSyncCheckBox = Spawn(class'UICheckbox', self);
	VSyncCheckBox.InitCheckbox('', m_strVideoLabel_VSyncToggle, m_kInitGraphicsSettings.bVSync, UpdateVSync, false).SetPosition(300, 570);

	// Gamma: ----------------------------------------------------
	m_kInitGraphicsSettings.fGamma = GetGammaPercentage();
	GammaSlider = Spawn(class'UISlider', self);
	GammaSlider.InitSlider('', m_strVideoLabel_Gamma, m_kInitGraphicsSettings.fGamma, UpdateGamma).SetPosition(300, 610);







	TextBox = Spawn(class'UIText', self).InitText(, "ADVANCED SETTINGS");
	TextBox.SetPosition(1350, 50);

	// Preset: --------------------------------------------
	PresetSpinner = UIListItemSpinner(Spawn(class'UIListItemSpinner', self)
		.InitSpinner(m_strGraphicsLabel_Preset, , UpdatePreset_OnChanged)
		.SetPosition(1350, 90)
		.SetSize(800, 35));


	// SPINNERS
	currentPos = 0;
	YPos = 130;
	YSpacing = 40;

	// Shadow: --------------------------------------------
	SpinnerVals[currentPos] = GetCurrentShadowSetting();
	Spinners.AddItem(Spawn(class'UIListItemSpinner', self));
	Spinners[currentPos].InitSpinner(m_strGraphicsLabel_Shadow, , UpdateShadow_OnChanged)
		.SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[currentPos]])
		.SetPosition(1350, YPos)
		.SetSize(800, 35);
	currentPos++;
	YPos += YSpacing;

	// Shadow Quality: ------------------------------------
	SpinnerVals[currentPos] = GetCurrentShadowQualitySetting();
	Spinners.AddItem(Spawn(class'UIListItemSpinner', self));
	Spinners[currentPos].InitSpinner(m_strGraphicsLabel_ShadowQuality, , UpdateShadowQuality_OnChanged)
		.SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[currentPos]])
		.SetPosition(1350, YPos)
		.SetSize(800, 35);
	currentPos++;
	YPos += YSpacing;

	// Texture Filtering: ---------------------------------
	SpinnerVals[currentPos] = GetCurrentTextureFilteringSetting();
	Spinners.AddItem(Spawn(class'UIListItemSpinner', self));
	Spinners[currentPos].InitSpinner(m_strGraphicsLabel_TextureFiltering, , UpdateTextureFiltering_OnChanged)
		.SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[currentPos]])
		.SetPosition(1350, YPos)
		.SetSize(800, 35);
	currentPos++;
	YPos += YSpacing;

	// Texture Detail: --------------------------------------------
	SpinnerVals[currentPos] = GetCurrentTextureDetailSetting();
	Spinners.AddItem(Spawn(class'UIListItemSpinner', self));
	Spinners[currentPos].InitSpinner(m_strGraphicsLabel_TextureDetail, , UpdateTextureDetail_OnChanged)
		.SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[currentPos]])
		.SetPosition(1350, YPos)
		.SetSize(800, 35);
	currentPos++;
	YPos += YSpacing;

	// Anti-Aliasing: --------------------------------------------
	SpinnerVals[currentPos] = GetCurrentAntiAliasingSetting();
	Spinners.AddItem(Spawn(class'UIListItemSpinner', self));
	Spinners[currentPos].InitSpinner(m_strGraphicsLabel_AntiAliasing, , UpdateAntiAliasing_OnChanged)
		.SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[currentPos]])
		.SetPosition(1350, YPos)
		.SetSize(800, 35);
	currentPos++;
	YPos += YSpacing;

	// AmbientOcclusion: --------------------------------------------
	SpinnerVals[currentPos] = GetCurrentAmbientOcclusionSetting();
	Spinners.AddItem(Spawn(class'UIListItemSpinner', self));
	Spinners[currentPos].InitSpinner(m_strGraphicsLabel_AmbientOcclusion, , UpdateAmbientOcclusion_OnChanged)
		.SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[currentPos]])
		.SetPosition(1350, YPos)
		.SetSize(800, 35);
	currentPos++;
	YPos += YSpacing;


	// CHECKBOXES
	currentPos = 0;

	// Effects: --------------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_Effects, GetCurrentEffectsSetting() == eGraphicsSetting_High, UpdateEffects_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// Bloom: -------------------------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_Bloom, GetCurrentBloomSetting() == eGraphicsSetting_High, UpdateBloom_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// Depth of Field: ----------------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_DepthOfField, GetCurrentDepthOfFieldSetting() == eGraphicsSetting_High, UpdateDepthOfField_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// Dirty Lens: --------------------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_DirtyLens, GetCurrentDirtyLensSetting() == eGraphicsSetting_High, UpdateDirtyLens_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// Decals: ------------------------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_Decals, GetCurrentDecalsSetting() == eGraphicsSetting_High, UpdateDecals_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// SubsurfaceScattering: ----------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_SubsurfaceScattering, GetCurrentSubsurfaceScatteringSetting() == eGraphicsSetting_High, UpdateSubsurfaceScattering_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// ScreenSpaceReflections: --------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_ScreenSpaceReflections, GetCurrentScreenSpaceReflectionsSetting() == eGraphicsSetting_High, UpdateScreenSpaceReflections_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// HighPrecisionGBuffers: ---------------------------------------
	CheckBoxes[currentPos] = Spawn(class'UICheckbox', self);
	CheckBoxes[currentPos].InitCheckbox('', m_strGraphicsLabel_HighPrecisionGBuffers, GetCurrentHighPrecisionGBuffersSetting() == eGraphicsSetting_High, UpdateHighPrecisionGBuffers_OnChanged, false)
		.SetPosition(1350, YPos);
	currentPos++;
	YPos += YSpacing;

	// Determine if we're using a preset or custom configuration
	SetPresetState();
}

public function UpdateMode_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	ModeSpinnerVal += direction;

	if (ModeSpinnerVal < 0)
		ModeSpinnerVal = 2;
	else if (ModeSpinnerVal > 2)
		ModeSpinnerVal = 0;

	SetSupportedResolutions();

	spinnerControl.SetValue(m_VideoMode_Labels[ModeSpinnerVal]);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	m_bAnyValueChanged = true;
	m_bResolutionChanged = true;
}

simulated private function SetSupportedResolutions()
{
	local int i;

	SetSupportedResolutionsNative(ModeSpinnerVal == 1);

	ResolutionsList.ClearItems();
	for (i = 0; i < m_kGameResolutionStrings.length; ++i)
	{
		UIListItemString(ResolutionsList.CreateItem()).InitListItem(m_kGameResolutionStrings[i]);
	}
	ResolutionsList.SetSelectedIndex(m_kCurrentSupportedResolutionIndex);
}

public function UpdateResolution(UIList ContainerList, int ItemIndex)
{
	m_kCurrentSupportedResolutionIndex = ItemIndex;

	m_bAnyValueChanged = true;
	m_bResolutionChanged = true;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

private function UpdateViewportCheck()
{
	if (m_bResolutionChanged)
	{
		UpdateViewport();

		m_bPendingExit = true;
		m_bResolutionChanged = false;
	}
}

private function UpdateViewport()
{
	local int tmpWidth, tmpHeight;
	local TDialogueBoxData kDialogData;

	tmpWidth = m_kGameResolutionWidths[m_kCurrentSupportedResolutionIndex];
	tmpHeight = m_kGameResolutionHeights[m_kCurrentSupportedResolutionIndex];

	UpdateViewportNative(tmpWidth, tmpHeight, ModeSpinnerVal == 0, ModeSpinnerVal == 1 ? 1 : 0);

	m_KeepResolutionCountdown = 15;
	SetTimer(1, true, 'KeepResolutionCountdown');

	// show dialog
	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_strVideoKeepSettings_Title;
	kDialogData.strText     = Repl(m_strVideoKeepSettings_Body, "%VALUE", m_KeepResolutionCountdown);
	kDialogData.strAccept   = m_strVideoKeepSettings_Confirm;
	kDialogData.strCancel   = class'UIDialogueBox'.default.m_strDefaultCancelLabel;	
	kDialogData.fnCallback  = KeepResolutionCallback;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function KeepResolutionCountdown()
{
	local string NewText; 

	m_KeepResolutionCountdown--;
	if (m_KeepResolutionCountdown <= 0)
	{
		ClearTimer('KeepResolutionCountdown');
		// cancel the dialog
		Movie.Pres.Get2DMovie().DialogBox.ClearDialogs();
		// and revert
		UpdateViewportNative(m_kInitGraphicsSettings.iResolutionWidth, 
							 m_kInitGraphicsSettings.iResolutionHeight, 
							 m_kInitGraphicsSettings.iMode == 0, 
							 m_kInitGraphicsSettings.iMode == 1 ? 1 : 0);

		m_bPendingExit = false;
	}
	else
	{
		NewText = Repl(m_strVideoKeepSettings_Body, "%VALUE", m_KeepResolutionCountdown);
		Movie.Pres.Get2DMovie().DialogBox.UpdateDialogText(NewText);
	}
}

simulated public function KeepResolutionCallback(eUIAction eAction)
{
	//local vector2d ViewportSize;
	//local Engine Engine;

	ClearTimer('KeepResolutionCountdown');

	m_bPendingExit = false;

	if (eAction == eUIAction_Accept)
	{
		// save our current settings - these should be unnecessary since we are immediately exiting upon accepting of changes
		// leaving for UI guys if they decide to change things - KD
		//m_kInitGraphicsSettings.iMode = ModeSpinnerVal;

		//SetSupportedResolutions();

		//m_kInitGraphicsSettings.bVSync = VSyncCheckBox.bChecked;

		//Engine = class'Engine'.static.GetEngine();
		//Engine.GameViewport.GetViewportSize(ViewportSize);
		//m_kInitGraphicsSettings.iResolutionWidth = ViewportSize.X;
		//m_kInitGraphicsSettings.iResolutionHeight = ViewportSize.Y;

		SaveAndExit();
	}
	else
	{
		// revert to old settings
		UpdateViewportNative(m_kInitGraphicsSettings.iResolutionWidth, 
							 m_kInitGraphicsSettings.iResolutionHeight, 
							 m_kInitGraphicsSettings.iMode == 0, 
							 m_kInitGraphicsSettings.iMode == 1 ? 1 : 0);

		ModeSpinnerVal = m_kInitGraphicsSettings.iMode;
		ModeSpinner.SetValue(m_VideoMode_Labels[ModeSpinnerVal]);
		VSyncCheckBox.SetChecked(m_kInitGraphicsSettings.bVSync);

		SetSupportedResolutions();
	}
}

public function UpdateVSync(UICheckbox checkboxControl)
{
	UpdateVSyncNative(checkboxControl.bChecked);

	m_bAnyValueChanged = true;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

public function float GetGammaPercentage()
{
	return (GetGammaPercentageNative() - GAMMA_LOW) / (GAMMA_HIGH - GAMMA_LOW) * 100.0;
}

public function UpdateGamma(UISlider sliderControl)
{
	UpdateGammaNative((sliderControl.percent * 0.01) * (GAMMA_HIGH - GAMMA_LOW) + GAMMA_LOW);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	m_bAnyValueChanged = true;
	m_bGammaChanged = true;
}

simulated private function ApplyPresetState()
{
	local EUI_PCOptions_GraphicsSettings kCurrentPresetState;
	local int i;
	//local bool bTextureFilteringChanged;

	kCurrentPresetState = EUI_PCOptions_GraphicsSettings(PresetSpinnerVal);

	// K DERDA TODO: Commenting out code that is causing a crash in the steam build.
	//				 Needs to be revisited for a proper fix
	//bTextureFilteringChanged = SpinnerVals[ePCGraphics_TextureFiltering] != PresetToSpinnerVal(kCurrentPresetState, ePCGraphics_TextureFiltering);

	for (i = 0; i < SpinnerEnumCount; ++i)
	{
		SpinnerVals[i] = PresetToSpinnerVal(kCurrentPresetState, i);
		Spinners[i].SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[i]]);
	}

	for (i = 0; i < CheckboxEnumCount; ++i)
	{
		CheckBoxes[i].SetChecked(PresetToCheckBoxVal(kCurrentPresetState, i));
	}

	// K DERDA TODO: Commenting out code that is causing a crash in the steam build.
	//				 Needs to be revisited for a proper fix
	// HACK: This particular setting needs to update textures and currently used textures
	//		 (i.e., all the current UI shell's text) will be wiped out.
	//		 For now we immediately save this setting and reboot the shell.
	//if (bTextureFilteringChanged)
	//{
	//	SaveSystemSettings();
	//	ConsoleCommand("disconnect");
	//}
}

simulated private function SetPresetState()
{
	local int i;
	local bool bSame;

	// Check spinners
	bSame = true;
	for (i = 1; i < SpinnerEnumCount; ++i)
	{
		if (!SpinnerValMatchesSetting(SpinnerVals[0], i))
		{
			bSame = false;
			break;
		}
	}

	// Check checkboxes
	if (bSame)
	{
		for (i = 1; i < CheckboxEnumCount; ++i)
		{
			if (!CheckBoxValMatchesSetting(SpinnerVals[0], i))
			{
				bSame = false;
				break;
			}
		}
	}

	if (bSame)
		PresetSpinnerVal = SpinnerVals[0];
	else
		PresetSpinnerVal = eGraphicsSetting_Custom;

	PresetSpinner.SetValue(m_DefaultGraphicsSettingLabels[PresetSpinnerVal]);
}

simulated function int PresetToSpinnerVal(int InSetting, int SpinnerId)
{
	local byte Mask;

	Mask = PerSettingMasks[SpinnerId];

	switch (InSetting)
	{
	case eGraphicsSetting_Medium:
		if ((Mask & (1 << eGraphicsSetting_Medium)) > 0) return InSetting;
		else if ((Mask & (1 << eGraphicsSetting_Custom)) > 0) return eGraphicsSetting_High;
		else return eGraphicsSetting_Low;
	default:
		return InSetting;
	}
}

simulated function bool SpinnerValMatchesSetting(int InSetting, int SpinnerId)
{
	local byte Mask;
	local int SpinnerSetting;

	Mask = PerSettingMasks[SpinnerId];
	SpinnerSetting = SpinnerVals[SpinnerId];

	switch (InSetting)
	{
	case eGraphicsSetting_Medium:
		if ((Mask & (1 << eGraphicsSetting_Medium)) > 0) return SpinnerSetting == InSetting;
		else if ((Mask & (1 << eGraphicsSetting_Custom)) > 0) return SpinnerSetting == eGraphicsSetting_High;
		else return SpinnerSetting == eGraphicsSetting_Low;
	default:
		return SpinnerSetting == InSetting;
	}
}

simulated function bool PresetToCheckBoxVal(int InSetting, int CheckBoxId)
{
	local byte Mask;

	Mask = PerSettingMasks[SpinnerEnumCount + CheckBoxId];

	switch (InSetting)
	{
	case eGraphicsSetting_Low:
		return false;
	case eGraphicsSetting_Medium:
		return (Mask & (1 << eGraphicsSetting_Medium)) > 0;
	case eGraphicsSetting_High:
		return true;
	}
}

simulated function bool CheckBoxValMatchesSetting(int InSetting, int CheckBoxId)
{
	local byte Mask;
	local bool CheckBoxSetting;

	Mask = PerSettingMasks[SpinnerEnumCount + CheckBoxId];
	CheckBoxSetting = CheckBoxes[CheckBoxId].bChecked;

	switch (InSetting)
	{
	case eGraphicsSetting_Low:
		return !CheckBoxSetting;
	case eGraphicsSetting_Medium:
		return (Mask & (1 << eGraphicsSetting_Medium)) > 0 == CheckBoxSetting;
	case eGraphicsSetting_High:
		return CheckBoxSetting;
	}
}

private function UpdateGraphicsWidgetCommon()
{
	SetPresetState();

	m_bAnyValueChanged = true;
}

public function SetGraphicsSettingsFromUIElements()
{
	SetShadowSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_Shadow]));
	SetShadowQualitySysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_ShadowQuality]));
	SetTextureFilteringSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_TextureFiltering]));
	SetTextureDetailSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_TextureDetail]));
	SetAntiAliasingSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_AntiAliasing]));
	SetAmbientOcclusionSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_AmbientOcclusion]));

	SetEffectsSysSetting(CheckBoxes[ePCGraphics_Effects - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
	SetBloomSysSetting(CheckBoxes[ePCGraphics_Bloom - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
	SetDepthOfFieldSysSetting(CheckBoxes[ePCGraphics_DepthOfField - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
	SetDirtyLensSysSetting(CheckBoxes[ePCGraphics_DirtyLens - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
	SetDecalsSysSetting(CheckBoxes[ePCGraphics_Decals - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
	SetSubsurfaceScatteringSysSettings(CheckBoxes[ePCGraphics_SubsurfaceScattering - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
	SetScreenSpaceReflectionsSysSetting(CheckBoxes[ePCGraphics_ScreenSpaceReflections - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
	SetHighPrecisionGBuffersSysSetting(CheckBoxes[ePCGraphics_HighPrecisionGBuffers - SpinnerEnumCount].bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);
}

public function UpdatePreset_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	PresetSpinnerVal += direction;

	if (PresetSpinnerVal < eGraphicsSetting_Low)
		PresetSpinnerVal = eGraphicsSetting_High;
	else if (PresetSpinnerVal > eGraphicsSetting_High)
		PresetSpinnerVal = eGraphicsSetting_Low;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	spinnerControl.SetValue(m_DefaultGraphicsSettingLabels[PresetSpinnerVal]);

	// Set all graphics options based on the preset
	ApplyPresetState();
	SetGraphicsSettingsFromUIElements();
	m_bAnyValueChanged = true;
}




//// SPINNERS

public function UpdateSpinnerVal(UIListItemSpinner spinnerControl, int direction, int SpinnerId)
{
	local int SpinnerVal;
	local bool bFound;
	local byte Mask;

	SpinnerVal = SpinnerVals[SpinnerId];
	bFound = false;
	while (!bFound)
	{
		SpinnerVal += direction;

		if (SpinnerVal < eGraphicsSetting_Disabled)
			SpinnerVal = eGraphicsSetting_High;
		else if (SpinnerVal > eGraphicsSetting_High)
			SpinnerVal = eGraphicsSetting_Disabled;

		Mask = PerSettingMasks[SpinnerId];
		bFound = (Mask & (1 << SpinnerVal)) > 0 || SpinnerVal == eGraphicsSetting_Low || SpinnerVal == eGraphicsSetting_High;
	}

	SpinnerVals[SpinnerId] = SpinnerVal;
	spinnerControl.SetValue(m_DefaultGraphicsSettingLabels[SpinnerVal]);
}

//-------------------------------------------------------
public function UpdateShadow_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	UpdateSpinnerVal(spinnerControl, direction, ePCGraphics_Shadow);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetShadowSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_Shadow]));

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateShadowQuality_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	UpdateSpinnerVal(spinnerControl, direction, ePCGraphics_ShadowQuality);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetShadowQualitySysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_ShadowQuality]));

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateTextureFiltering_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	UpdateSpinnerVal(spinnerControl, direction, ePCGraphics_TextureFiltering);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetTextureFilteringSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_TextureFiltering]));

	UpdateGraphicsWidgetCommon();

	// K DERDA TODO: Commenting out code that is causing a crash in the steam build.
	//				 Needs to be revisited for a proper fix
	// HACK: This particular setting needs to update textures and currently used textures
	//		 (i.e., all the current UI shell's text) will be wiped out.
	//		 For now we immediately save this setting and reboot the shell.
	//SaveSystemSettings();
	//ConsoleCommand("disconnect");
}

//-------------------------------------------------------
public function UpdateTextureDetail_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	UpdateSpinnerVal(spinnerControl, direction, ePCGraphics_TextureDetail);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetTextureDetailSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_TextureDetail]));

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateAntiAliasing_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	UpdateSpinnerVal(spinnerControl, direction, ePCGraphics_AntiAliasing);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetAntiAliasingSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_AntiAliasing]));

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateAmbientOcclusion_OnChanged(UIListItemSpinner spinnerControl, int direction)
{
	UpdateSpinnerVal(spinnerControl, direction, ePCGraphics_AmbientOcclusion);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetAmbientOcclusionSysSetting(EUI_PCOptions_GraphicsSettings(SpinnerVals[ePCGraphics_AmbientOcclusion]));

	UpdateGraphicsWidgetCommon();
}



//// CHECKBOXES

//-------------------------------------------------------
public function UpdateEffects_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetEffectsSysSetting(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateBloom_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetBloomSysSetting(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateDepthOfField_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetDepthOfFieldSysSetting(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateDirtyLens_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetDirtyLensSysSetting(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateDecals_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetDecalsSysSetting(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateSubsurfaceScattering_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetSubsurfaceScatteringSysSettings(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateScreenSpaceReflections_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetScreenSpaceReflectionsSysSetting(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}

//-------------------------------------------------------
public function UpdateHighPrecisionGBuffers_OnChanged(UICheckbox checkboxControl)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetHighPrecisionGBuffersSysSetting(checkboxControl.bChecked ? eGraphicsSetting_High : eGraphicsSetting_Low);

	UpdateGraphicsWidgetCommon();
}


simulated public function SaveAndExit()
{
	if (m_bAnyValueChanged)
	{
		UpdateViewportCheck();

		if (!m_bPendingExit)
		{
			SaveSystemSettings();

			if (m_bGammaChanged)
			{
				SaveGamma();
				m_bGammaChanged = false;
			}

			m_bAnyValueChanged = false;
		}
	}

	if (!m_bPendingExit)
		OnCancel();
}


simulated function StoreInitGraphicsSettings()
{
	local int i;

	m_kInitGraphicsSettings.iMode = ModeSpinnerVal;

	for (i = 0; i < SpinnerEnumCount; ++i)
	{
		m_kInitGraphicsSettings.SpinnerVals[i] = SpinnerVals[i];
	}

	for (i = 0; i < CheckboxEnumCount; ++i)
	{
		m_kInitGraphicsSettings.CheckBoxVals[i] = int(CheckBoxes[i].bChecked);
	}
}
simulated function RestoreInitGraphicsSettings()
{
	local int i;
	// Update the UI
	ModeSpinnerVal = m_kInitGraphicsSettings.iMode;
	ModeSpinner.SetValue(m_VideoMode_Labels[ModeSpinnerVal]);
	SetSupportedResolutions();

	VSyncCheckBox.SetChecked(m_kInitGraphicsSettings.bVSync);
	GammaSlider.SetPercent(m_kInitGraphicsSettings.fGamma);
	
	for (i = 0; i < SpinnerEnumCount; ++i)
	{
		SpinnerVals[i] = m_kInitGraphicsSettings.SpinnerVals[i];
		Spinners[i].SetValue(m_DefaultGraphicsSettingLabels[SpinnerVals[i]]);
	}

	for (i = 0; i < CheckboxEnumCount; ++i)
	{
		CheckBoxes[i].SetChecked(bool(m_kInitGraphicsSettings.CheckBoxVals[i]));
	}

	SetPresetState();

	// Update the actual system settings
	UpdateViewportNative(m_kInitGraphicsSettings.iResolutionWidth, m_kInitGraphicsSettings.iResolutionHeight, ModeSpinnerVal == 0, ModeSpinnerVal == 1 ? 1 : 0);
	UpdateVSyncNative(m_kInitGraphicsSettings.bVSync);
	UpdateGammaNative((m_kInitGraphicsSettings.fGamma * 0.01) * (GAMMA_HIGH - GAMMA_LOW) + GAMMA_LOW);
	SetGraphicsSettingsFromUIElements();
}

simulated function GoBack()
{
	if (m_bAnyValueChanged)
		RestoreInitGraphicsSettings();

	OnCancel();
}

simulated function OnCancel()
{
	Movie.Stack.Pop(self);
}

simulated function Remove()
{
	super.Remove();
	ClearTimer('WatchForChanges');
	Movie.SetResolutionAndSafeArea();
}

//==============================================================================
//		DEFAULTS:
//==============================================================================
DefaultProperties
{
}*/
