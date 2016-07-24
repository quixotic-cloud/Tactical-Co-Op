//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_Text.uc
//  AUTHOR:  bsteiner
//  PURPOSE: Container of static text formatting helpers.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_Text extends Object
	dependson(UIUtilities);

// 2D font sizes
const BODY_FONT_SIZE_2D = 22; // TODO *IMPORTANT* - 26 is the value on the style guide, keeping it at 18 to not break stuff right now
const TITLE_FONT_SIZE_2D = 32; 
// 3D font sizes
const BODY_FONT_SIZE_3D = 26; 
const TITLE_FONT_SIZE_3D = 32;
// Font faces
const BODY_FONT_TYPE = "$NormalFont";
const TITLE_FONT_TYPE = "$TitleFont";

struct UITextStyleObject
{
	var bool bUseCaps; 
	var bool bUseTitleFont; 
	var int FontSize; 
	var EUIState iState; 
	var string HTMLColor; //This will color only if the state is eUIState_Normal 
	var bool bIs3D;
	var string Alignment; 
	//var int Alpha; //NOTE: Alpha can't be set in the text formatting, but may be stored to use elsewhere. 
	var EUIUtilities_TextStyle eType; 

	structdefaultproperties
	{
		//Defaults are 2D body copy 
		bUseCaps = false; 
		bUseTitleFont = false;
		FontSize = BODY_FONT_SIZE_2D; 
		iState = eUIState_Normal; 
		HTMLColor ="";
		bIs3D = false;
		Alignment = "";
		eType = eUITextStyle_Body; 
	}
};

// GENERIC LOCALIZED STRINGS USED BY SEVERAL UI CLASSES
var localized string m_strGenericOK;
var localized string m_strGenericAccept;
var localized string m_strGenericConfirm;
var localized string m_strGenericCancel;
var localized string m_strGenericBack;
var localized string m_strGenericYes;
var localized string m_strGenericNo;
var localized string m_strGenericContinue;
var localized string m_strPriority;

var localized string m_strDay;
var localized string m_strDays;

var localized string m_strHour;
var localized string m_strHours;

var localized string m_strItemRequirements;

var localized string m_strMPPlayerEndTurnDialog_Title;
var localized string m_strMPPlayerEndTurnDialog_Body;

var localized string m_strUpperYWithUmlaut;
var localized string m_strLowerYWithUmlaut;

var localized string KOR_year_suffix;
var localized string KOR_month_suffix;
var localized string KOR_day_suffix;

var localized string JPN_year_suffix;
var localized string JPN_month_suffix;
var localized string JPN_day_suffix;

// Null character is purposefully used here because it's an unsupported symbol in all of our fonts, so will show the null character square intentionally. 
var localized string KNOWN_NULL_CHARACTER_DO_NOT_TRANSLATE;

//------------------------------------------------------------
//------------------------------------------------------------
static function string GetDaysString( int iDays )
{
	if( iDays == 1 )
		return class'UIUtilities_Text'.default.m_strDay;
	else
		return class'UIUtilities_Text'.default.m_strDays;
}

static function string GetHoursString( int iHours )
{
	if( iHours == 1 )
		return class'UIUtilities_Text'.default.m_strHour; 
	else
		return  class'UIUtilities_Text'.default.m_strHours;
}

static function String GetTimeRemainingString(int iHours, optional int iShowDays = 0)
{
	local string TimeValue, TimeLabel; 

	class'UIUtilities_Text'.static.GetTimeValueAndLabel(iHours, TimeValue, TimeLabel, iShowDays); 

	return TimeValue @ TimeLabel; 
}

static function GetTimeValueAndLabel(int iHours, out string TimeValue, out string TimeLabel, optional int iShowDays = 1)
{
	local int iDays;

	if( iHours < (24 * iShowDays) )
	{
		TimeValue = string(iHours);
		TimeLabel = static.GetHoursString(iHours);
	}
	else
	{
		iDays = FCeil(iHours / 24.0f);
		TimeValue = string(iDays);
		TimeLabel = static.GetDaysString(iDays);
	}
}

//------------------------------------------------------------
//------------------------------------------------------------
static function string GetColorFromState( int iState )
{
	switch( iState )
	{
	case eUIState_Normal:   return "cyan";
	case eUIState_Bad:      return "red";
	case eUIState_Warning:  return "yellow";
	case eUIState_Good:     return "green";
	case eUIState_Disabled: return "grey";
	default:
		`warn("UI ERROR: Unsupported UI state '"$iState$"'");
	}
	return "cyan";
}

// keep implementation in sync with Colors.as (Flash)
static function string GetColoredText(string txt, optional int iState = -1, optional int fontSize = -1, optional string align)
{
	local string retTxt, prefixTxt;

	if(Len(txt) == 0) return txt;

	if(align != "")
		prefixTxt $=  "<p align='"$align$"'>";

	if(fontSize > 0)
		prefixTxt $= "<font size='" $ fontSize $ "' color='#";
	else
		prefixTxt $= "<font color='#";

	switch(iState)
	{
	case eUIState_Disabled:		prefixTxt $= class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;	break;
	case eUIState_Good:			prefixTxt $= class'UIUtilities_Colors'.const.GOOD_HTML_COLOR;		break;
	case eUIState_Bad:			prefixTxt $= class'UIUtilities_Colors'.const.BAD_HTML_COLOR;		break;
	case eUIState_Warning:		prefixTxt $= class'UIUtilities_Colors'.const.WARNING_HTML_COLOR;	break;
	case eUIState_Warning2:		prefixTxt $= class'UIUtilities_Colors'.const.WARNING2_HTML_COLOR;	break;
	case eUIState_Highlight:    prefixTxt $= class'UIUtilities_Colors'.const.HILITE_HTML_COLOR;		break;
	case eUIState_Cash:         prefixTxt $= class'UIUtilities_Colors'.const.CASH_HTML_COLOR;		break;
	case eUIState_Header:       prefixTxt $= class'UIUtilities_Colors'.const.HEADER_HTML_COLOR;     break;
	case eUIState_Psyonic:      prefixTxt $= class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;    break;
	case eUIState_Normal:       prefixTxt $= class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR;     break;
	case eUIState_Faded:        prefixTxt $= class'UIUtilities_Colors'.const.FADED_HTML_COLOR;      break;
	default:                    prefixTxt $= class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;      break;
	}

	prefixTxt $= "'>";
	retTxt = prefixTxt $txt$"</font>";

	if(align != "")
		retTxt $= "</p>";

	return retTxt;
}

static function string GetSizedText(string txt, int fontSize)
{
	if(Len(txt) == 0) return txt;
	return "<font size='" $ fontSize $ "'>" $ txt $ "</font>";
}

// Note on verticalOffset: a positive value will move image up, negative value will move it down
static function string InjectImage(string imgID, optional int width, optional int height, optional int verticalOffset)
{
	local string retTxt;
	retTxt = "<img src='" $ imgID $ "'";
	if(width > 0)
		retTxt $= " width='" $ width $ "'";
	if(height > 0)
		retTxt $= " height='" $ height $ "'";
	if(verticalOffset != 0)
		retTxt $= " vspace='" $ verticalOffset $ "'";
	retTxt $= ">";
	return retTxt;
}

static function string AlignCenter( string str )
{
	return "<p align='CENTER'>" $ str $ "</p>";
}

static function string AlignRight( string str )
{
	return "<p align='RIGHT'>" $ str $ "</p>";
}

static function string AlignLeft( string str )
{
	return "<p align='LEFT'>" $ str $ "</p>";
}

/// PS3 TRC R034 - using underscore as consistent replacement character for not supported characters
simulated static function SantizeUserName( out string userName )
{
	userName = Repl( userName, "<", class'UIUtilities_Text'.default.KNOWN_NULL_CHARACTER_DO_NOT_TRANSLATE );
	userName = Repl( userName, ">", class'UIUtilities_Text'.default.KNOWN_NULL_CHARACTER_DO_NOT_TRANSLATE );
	// TODO: Add other non-supported characters.
}

simulated static function StripUnsupportedCharactersFromUserInput( out string userString )
{
	userString = Repl( userString, "<", class'UIUtilities_Text'.default.KNOWN_NULL_CHARACTER_DO_NOT_TRANSLATE );
	userString = Repl( userString, ">", class'UIUtilities_Text'.default.KNOWN_NULL_CHARACTER_DO_NOT_TRANSLATE );
	userString = Repl( userString, "¤", class'UIUtilities_Text'.default.KNOWN_NULL_CHARACTER_DO_NOT_TRANSLATE ); //MS Points symbol 
	// TODO: Add other non-supported characters.
}

simulated static function TrimWhitespaceFromUserInput(out string text)
{
	//This is ridiculous but UnrealScript doesn't have a Trim function (!?!?)
	while ((Len(text) > 0) && (InStr(text, " ") == 0))
		text = right(text, Len(text) - 1);
	while ((Len(text) > 0) && (InStr(text, " ", true) == Len(text) - 1))
		text = left(text, Len(text) - 1);
}

simulated static function string CapsCheckForGermanScharfesS( string str )
{
	If( GetLanguage() == "DEU")
		str = Repl( str, "ß", "SS" );

	//`log( "****************************************");
	//`log( "UIUtilities_Text.CapsCheckForGermanScharfesS:");
	//`log( "*** GetLanguage = '" $GetLanguage() $"', str = '" $str $"'");
	//`log( "*** Caps( str ) = '" $Caps( str ) $"'");
				
	// Unreal fail: it doesn't know how to properly convert this character. Adding it here to cover the general rename case. We should really rename this function. 
	// Extra bonus fun: In Russian, this fix is causing [Cyrillic capital backwards R, "Ya"] to display as [Latin capital "Y"]. Let's not do that... 
	If( GetLanguage() != "RUS")
	{
		str = Repl( str, class'UIUtilities_Text'.default.m_strLowerYWithUmlaut, class'UIUtilities_Text'.default.m_strUpperYWithUmlaut );
		//`log( "***  Y replacement SUCCESSFULLY triggered. Caps( str ) = '" $Caps( str ) $"'");
		//`log( "***  class'UIUtilities_Text'.default.m_strLowerYWithUmlaut = '" $class'UIUtilities_Text'.default.m_strLowerYWithUmlaut $"'.");
		//`log( "***  class'UIUtilities_Text'.default.m_strUpperYWithUmlaut = '" $class'UIUtilities_Text'.default.m_strUpperYWithUmlaut $"'.");
	}

	str = Caps( str );
	return str;
}

simulated static function string AddFontInfo(   string txt, 
												bool is3DScreen, 
												optional bool isTitleFont, 
												optional bool forceBodyFontSize, 
												optional int specifyFontSize = 0 )
{
	local string fontFace;
	local int fontSize, fontSize2D, fontSize3D;

	if(txt == "")
		return txt;

	fontFace = isTitleFont ? TITLE_FONT_TYPE : BODY_FONT_TYPE;

	if ( specifyFontSize == 0 )
	{
		fontSize2D = isTitleFont ? (forceBodyFontSize ? BODY_FONT_SIZE_2D : TITLE_FONT_SIZE_2D) : BODY_FONT_SIZE_2D;
		fontSize3D = isTitleFont ? (forceBodyFontSize ? BODY_FONT_SIZE_3D : TITLE_FONT_SIZE_3D) : BODY_FONT_SIZE_3D;

		fontSize = is3DScreen ? fontSize3D : fontSize2D;
	}
	else 
	{
		fontSize = specifyFontSize;

	}
	return "<font size='" $ fontSize $ "' face='" $ fontFace $ "'>" $ txt $ "</font>";
}

simulated static function string ConvertZeroStatsToDashes( string Stat )
{
	//Easy swap. 
	if( Stat == "0" )
		return "--";
	
	//Let's see if it's already been font-i-fied, and swap it out. 
	if( InStr(Stat, ">0<") > -1 )
		stat = Repl(Stat, ">0<", ">--<");
	
	return Stat; 
}

// AUTOMATIC STYLING ---------------------------------------------------

// Fills out structure properties for the common text styling types, and then applies that style to the requested text. 
simulated static function string StyleText( string targetString, 
	EUIUtilities_TextStyle eStyle, 
	optional EUIState iState = eUIState_Normal, 
	optional bool bIs3D = false )
{
	local UITextStyleObject Style; 

	Style = GetStyle(eStyle, bIs3D);
	if( iState != eUIState_Normal )
		Style.iState = iState; 

	return ApplyStyle(targetString, Style );
}

// Request a style struct filled out with the desired parameters corresponding to the style enum. 
// Used by the defaults, but also may be used to generate a style instance, modify that instance locally, then send 
// the modified instance and intended string to StyleCustomText(). 
simulated static function UITextStyleObject GetStyle( EUIUtilities_TextStyle eStyle, optional bool bIs3D = false )
{
	local UITextStyleObject Style; 

	Style.bIs3D = bIs3D;
	Style.eType = eStyle; 

	switch( eStyle )
	{
		case eUITextStyle_Title:
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D)? TITLE_FONT_SIZE_3D : TITLE_FONT_SIZE_2D;
			break;

		case eUITextStyle_Body:
			Style.FontSize = (Style.bIs3D)? BODY_FONT_SIZE_3D : BODY_FONT_SIZE_2D; 
			break;

		case eUITextStyle_Tooltip_Title:
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = 20; 
			break;

		case eUITextStyle_Tooltip_H1: // Faded yellow all caps title small size 
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.iState = eUIState_Header;
			Style.FontSize = 20; 
			break;

		case eUITextStyle_Tooltip_H2: // Bright blue all caps title small size 
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = 20; 
			break;

		case eUITextStyle_Tooltip_Body: 
			Style.FontSize = 18;
			break;

		case eUITextStyle_Tooltip_StatLabel:
			Style.bUseCaps = true; 
			Style.iState = eUIState_Header;
			Style.FontSize = (Style.bIs3D) ? 24 : 20;
			break;

		case eUITextStyle_Tooltip_StatLabelRight:
			Style.bUseCaps = true; 
			Style.iState = eUIState_Header;
			Style.FontSize = (Style.bIs3D) ? 24 : 20; 
			Style.Alignment = "RIGHT";
			break;

		case eUITextStyle_Tooltip_StatValue:
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D) ? 22 : 18;
			Style.Alignment = "RIGHT";
			break;

		case eUITextStyle_Tooltip_AbilityValue:
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D) ? 22 : 18; 	
			break;

		case eUITextStyle_Tooltip_AbilityRight: // blue all caps body title size 
			Style.bUseCaps = true; 
			Style.FontSize = (Style.bIs3D) ? 24 : 20; 
			Style.Alignment = "RIGHT";
			break;

		case eUITextStyle_Tooltip_HackStatValueLeft:
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D) ? 22 : 18; 
			break;
			
		case eUITextStyle_Tooltip_HackHeaderLeft: // Faded blue all caps title small size 
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D) ? 24 : 20; 
			Style.iState = eUIState_Faded;
			break;

		case eUITextStyle_Tooltip_HackHeaderRight: // Faded blue all caps title small size 
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D) ? 24 : 20; 
			Style.iState = eUIState_Faded;
			Style.Alignment = "RIGHT";
			break;

		case eUITextStyle_Tooltip_HackBodyLeft: 
			Style.FontSize = (Style.bIs3D) ? 22 : 18;
			Style.iState = eUIState_Header;
			break;

		case eUITextStyle_Tooltip_HackBodyRight: 
			Style.FontSize = (Style.bIs3D) ? 22 : 18;
			Style.iState = eUIState_Header;
			Style.Alignment = "RIGHT"; 
			break;

		case eUITextStyle_Tooltip_HackH3Left:// Bright blue all caps title small size, faded 
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D) ? 22 : 18;
			Style.iState = eUIState_Faded;
			break;

		case eUITextStyle_Tooltip_HackH3Right:
			Style.bUseCaps = true; 
			Style.bUseTitleFont = true;
			Style.FontSize = (Style.bIs3D) ? 22 : 18; 
			Style.iState = eUIState_Faded;
			Style.Alignment = "RIGHT"; 
			break;
	}
	return  Style;
}
simulated static function string StyleTextCustom( string targetString, UITextStyleObject CustomStyleObject)
{
	return ApplyStyle(targetString, CustomStyleObject);
}

simulated static function string ApplyStyle( string targetString, UITextStyleObject Style )
{	
	local string formattedString; 

	formattedString = targetString; 

	if( Style.eType == eUITextStyle_Tooltip_StatValue )
		formattedString = class'UIUtilities_Text'.static.ConvertZeroStatsToDashes(formattedString);

	if( Style.bUseCaps ) 
		formattedString = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(formattedString); 
	
	formattedString = class'UIUtilities_Text'.static.AddFontInfo( formattedString, Style.bIs3D, Style.bUseTitleFont, , Style.FontSize );	
	formattedString = class'UIUtilities_Text'.static.GetColoredText( formattedString, Style.iState, , Style.Alignment );
	
	return formattedString; 
}
