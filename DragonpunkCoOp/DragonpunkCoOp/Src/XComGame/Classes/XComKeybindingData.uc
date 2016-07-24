/**
 * XComKeybindingGData
 *
 * 
 * Copyright 2012 Firaxis
 * @owner sbatista
 */

class XComKeybindingData extends Object
	native(UI);

enum KeybindCategories
{
	eKC_General,
	eKC_Tactical, 
	eKC_Avenger,
//	eKC_Geoscape,
};
enum GeneralBindableCommands
{
	eGBC_Confirm,
	eGBC_Cancel,
	eGBC_NavigateUp,
	eGBC_NavigateDown,
	eGBC_NavigateLeft,
	eGBC_NavigateRight,
	eGBC_QuickSave,
	eGBC_QuickLoad,
	eGBC_PushToTalk,
};
enum TacticalBindableCommands
{
	eTBC_EnterShotHUD_Confirm,
	eTBC_Pause,
	eTBC_Path,
	eTBC_Interact,
	eTBC_EndTurn,
	eTBC_Chat,
	eTBC_Waypoint,
	eTBC_CamCenterOnActiveUnit,
	eTBC_CamMoveUp,
	eTBC_CamMoveDown,
	eTBC_CamMoveLeft,
	eTBC_CamMoveRight,
	eTBC_CamRotateLeft,
	eTBC_CamRotateRight,
	eTBC_CamZoomIn,
	eTBC_CamZoomOut,
	eTBC_CamFreeZoom,
	eTBC_CamToggleZoomLevel,
	eTBC_CursorUp,
	eTBC_CursorDown,
	eTBC_NextUnit,
	eTBC_PrevUnit,
	eTBC_AbilityOverwatch,
	eTBC_AbilityReload,
	eTBC_Ability1,
	eTBC_Ability2,
	eTBC_Ability3,
	eTBC_Ability4,
	eTBC_Ability5,
	eTBC_Ability6,
	eTBC_Ability7,
	eTBC_Ability8,
	eTBC_Ability9,
	eTBC_Ability0,
	eTBC_QuickSave,
	eTBC_QuickLoad,
	eTBC_CommandAbility1,
	eTBC_CommandAbility2,
	eTBC_CommandAbility3,
	eTBC_CommandAbility4,
	eTBC_CommandAbility5,
};
/*enum GeoscapeBindableCommands
{
	eGeoBC_Confirm,
	eGeoBC_Cancel,
};*/
enum AvengerBindableCommands
{
	eABC_Geoscape,
	eABC_Research,
	eABC_Engineering,
	eABC_Barracks,
	eABC_CommandersQuarters,
	eABC_ShadowChamber,
};
enum LocalizedKeyNames
{
	eLKN_Tab,
	eLKN_Home,
	eLKN_CapsLock,
	eLKN_Enter,
	eLKN_Escape,
	eLKN_End,
	eLKN_Delete,
	eLKN_BackSpace,
	eLKN_Insert,
	eLKN_NumLock,
	eLKN_Spacebar,
	eLKN_LeftShift,
	eLKN_RightShift,
	eLKN_LeftControl,
	eLKN_RightControl,
	eLKN_LeftAlt,
	eLKN_RightAlt,
	eLKN_RightMouseButton,
	eLKN_LeftMouseButton,
	eLKN_MiddleMouseButton,
	eLKN_MouseScrollUp,
	eLKN_MouseScrollDown,
	eLKN_ThumbMouseButton,
	eLKN_ThumbMouseButton2,
	// Numbers are universal
	eLKN_Up,
	eLKN_Down,
	eLKN_Left,
	eLKN_Right,
	
	eLKN_ScrollLock,
	eLKN_LeftAccent,
	eLKN_LeftBracket,
	eLKN_RightBracket,
	eLKN_PageUp,
	eLKN_PageDown,
	eLKN_Divide,
	eLKN_Multiply,
	eLKN_Subtract,
	eLKN_Semicolon,
	eLKN_Underscore,
	eLKN_Equals,
	eLKN_Add,
	eLKN_Tilde,
	eLKN_Quote,
	eLKN_Slash,
	eLKN_Backslash,
	eLKN_Comma,
	eLKN_Period,
	eLKN_Decimal,
	eLKN_Pause,
};

// Collection of binding "Commands" to the enums declared above. For fast access of localized text.
var native Map_Mirror m_GeneralBindableCommandsMap  {TMap<FString, INT>};
var native Map_Mirror m_TacticalBindableCommandsMap {TMap<FString, INT>};
//var native Map_Mirror m_GeoscapeBindableCommandsMap {TMap<FString, INT>};
var native Map_Mirror m_AvengerBindableCommandsMap  {TMap<FString, INT>};
var native Map_Mirror m_KeyToLocalizedKeyMap        {TMap<FString, INT>};

var localized string m_arrGeneralBindableLabels  [GeneralBindableCommands]  <BoundEnum=GeneralBindableCommands>;
var localized string m_arrTacticalBindableLabels [TacticalBindableCommands] <BoundEnum=TacticalBindableCommands>;
//var localized string m_arrGeoscapeBindableLabels [GeoscapeBindableCommands] <BoundEnum=GeoscapeBindableCommands>;
var localized string m_arrAvengerBindableLabels  [AvengerBindableCommands] <BoundEnum=AvengerBindableCommands>;
var localized string m_arrLocalizedKeyNames      [LocalizedKeyNames]        <BoundEnum=LocalizedKeyNames>;

var localized string m_strShiftKeyPreprocessor;
var localized string m_strControlKeyPreprocessor;
var localized string m_strAltKeyPreprocessor;
var localized string m_strNumpadKeyPreprocessor;

//----------------------------------------------------------------------------------------------------
// NATIVE FUNCTIONS
// Only call once when class is created.
simulated native function InitializeBindableCommandsMap();

// Need to pass in XComTacticalInput to obtain the key for a 'TacticalBindableCommands' enum
// Need to pass in XComHeadquartersInput to obtain the key for a 'GeneralBindableCommands' enum
simulated native function KeyBind GetBoundKeyForAction(out PlayerInput kPlayerInput, int actionEnum, 
													   optional bool SecondaryBind = false, 
													   optional KeybindCategories category = eKC_Tactical);

simulated native function int    GetEnumValueForGeneralBindingsFromCommand(string command);
simulated native function int    GetEnumValueForTacticalBindingsFromCommand(string command);
//simulated native function int    GetEnumValueForGeoscapeBindingsFromCommand(string command);
simulated native function int    GetEnumValueForAvengerBindingsFromCommand(string command);

simulated native function string GetGeneralBindableActionLabel(GeneralBindableCommands action);
simulated native function string GetTacticalBindableActionLabel(TacticalBindableCommands action);
//simulated native function string GetGeoscapeBindableActionLabel(GeoscapeBindableCommands action);
simulated native function string GetAvengerBindableActionLabel(AvengerBindableCommands action);

simulated native function string GetCommandStringForGeneralAction(GeneralBindableCommands action);
simulated native function string GetCommandStringForTacticalAction(TacticalBindableCommands action);
//simulated native function string GetCommandStringForGeoscapeAction(GeoscapeBindableCommands action);
simulated native function string GetCommandStringForAvengerAction(AvengerBindableCommands action);

simulated native function bool   IsBindableKey(out KeyBind kKeyBinding);
simulated native function string GetLocalizedStringName(string keyName);

//----------------------------------------------------------------------------------------------------
// HELPER FUNCTIONS
simulated function string GetKeyStringForAction(out PlayerInput kPlayerInput, int actionEnum, 
												optional bool SecondaryBind = false,
												optional KeybindCategories category = eKC_Tactical)
{
	local KeyBind kKey;
	kKey = GetBoundKeyForAction(kPlayerInput, actionEnum, secondaryBind, category);
	return GetKeyString(kKey);
}

simulated function string GetPrimaryOrSecondaryKeyStringForAction(out PlayerInput kPlayerInput, 
																  int actionEnum, 
																  optional KeybindCategories category = eKC_Tactical)
{
	local KeyBind kKey;

	// Get primary key
	kKey = GetBoundKeyForAction(kPlayerInput, actionEnum, false, category);
	// If there's nothing bound on primary slot, try secondary slot
	if(kKey.Name == '')
		kKey = GetBoundKeyForAction(kPlayerInput, actionEnum, true, category);
	// Return results
	return GetKeyString(kKey);
}

simulated function string GetKeyString(out KeyBind kKey)
{
	local string strDisplayName; 
	local string result;
	
	if(kKey.Name == '')
		return "";

	switch(kKey.Name)
	{
	case 'ZERO':    strDisplayName = "0";	break;
	case 'ONE':     strDisplayName = "1";	break;
	case 'TWO':     strDisplayName = "2";	break;
	case 'THREE':   strDisplayName = "3";	break;
	case 'FOUR':    strDisplayName = "4";	break;
	case 'FIVE':    strDisplayName = "5";	break;
	case 'SIX':     strDisplayName = "6";	break;
	case 'SEVEN':   strDisplayName = "7";	break;
	case 'EIGHT':   strDisplayName = "8";	break;
	case 'NINE':    strDisplayName = "9";	break;

	case 'NumPadZero':  strDisplayName = m_strNumpadKeyPreprocessor $ "0"; break;
	case 'NumPadOne':   strDisplayName = m_strNumpadKeyPreprocessor $ "1"; break;
	case 'NumPadTwo':   strDisplayName = m_strNumpadKeyPreprocessor $ "2"; break;
	case 'NumPadThree': strDisplayName = m_strNumpadKeyPreprocessor $ "3"; break;
	case 'NumPadFour':  strDisplayName = m_strNumpadKeyPreprocessor $ "4"; break;
	case 'NumPadFive':  strDisplayName = m_strNumpadKeyPreprocessor $ "5"; break;
	case 'NumPadSix':   strDisplayName = m_strNumpadKeyPreprocessor $ "6"; break;
	case 'NumPadSeven': strDisplayName = m_strNumpadKeyPreprocessor $ "7"; break;
	case 'NumPadEight': strDisplayName = m_strNumpadKeyPreprocessor $ "8"; break;
	case 'NumPadNine':  strDisplayName = m_strNumpadKeyPreprocessor $ "9"; break;

	default: strDisplayName = GetLocalizedStringName(string(kKey.Name)); break;
	};

	result = "";

	if(kKey.Control && (kKey.Name != 'LeftControl' && kKey.Name != 'RightControl'))
		result $= m_strControlKeyPreprocessor;
	if(kKey.Alt && (kKey.Name != 'LeftAlt' && kKey.Name != 'RightAlt'))
		result $= (result != "") ? " + " $ m_strAltKeyPreprocessor : m_strAltKeyPreprocessor;
	if(kKey.Shift && (kKey.Name != 'LeftShift' && kKey.Name != 'RightShift'))
		result $= (result != "") ? " + " $ m_strShiftKeyPreprocessor : m_strShiftKeyPreprocessor;
	
	result $= (result != "") ? " + " $ strDisplayName : strDisplayName;
	return result;
}