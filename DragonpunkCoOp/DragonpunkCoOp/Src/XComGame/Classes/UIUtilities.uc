//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities.uc
//  AUTHOR:  sbatista
//  PURPOSE: Container of static helper functions that serve as lookup tables for UI 
//           icon labels, as well as text formatting helpers.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities extends Object
	native(UI);

const FLASH_DOCUMENT_WIDTH = 1920.0;
const FLASH_DOCUMENT_HEIGHT = 1080.0;

//Anchors correspond to flash side Environment.as 
const ANCHOR_NONE           = 0;
const ANCHOR_TOP_LEFT       = 1;
const ANCHOR_TOP_CENTER		= 2;
const ANCHOR_TOP_RIGHT		= 3;
const ANCHOR_MIDDLE_LEFT	= 4;
const ANCHOR_MIDDLE_CENTER	= 5;
const ANCHOR_MIDDLE_RIGHT	= 6;
const ANCHOR_BOTTOM_LEFT	= 7;
const ANCHOR_BOTTOM_CENTER	= 8;
const ANCHOR_BOTTOM_RIGHT	= 9;

//Time for an individual transition element multiplied by its child panel index
const INTRO_ANIMATION_DELAY_PER_INDEX = 0.05; 
const INTRO_ANIMATION_TIME = 0.2; 

// Useful function to cut down copy & paste code - sbatista 1/9/12/
static function ClampIndexToArrayRange(int arrLength, out int index)
{
	if(index < 0)
		index = arrLength - 1;
	else if(index > arrLength - 1)
		index = 0;
}

//==============================================================================
//		OLD BATCHING API *DEPRECATED*
//==============================================================================
static simulated function QueueString(string value, out Array<ASValue> arrData)
{
	local ASValue v;
	v.Type = AS_String;
	v.s = value;
	arrData.AddItem(v);
}
static simulated function QueueBoolean(bool value, out Array<ASValue> arrData)
{
	local ASValue v;
	v.Type = AS_Boolean;
	v.b = value;
	arrData.AddItem(v);
}
static simulated function QueueNumber(float value, out Array<ASValue> arrData)
{
	local ASValue v;
	v.Type = AS_Number;
	v.n = value;
	arrData.AddItem(v);
}
static simulated function QueueNull(out Array<ASValue> arrData)
{
	local ASValue v;
	v.Type = AS_Null;
	arrData.AddItem(v);
}

//----------------------------------------------------------------------------
// Call a function that takes no params ()
//----------------------------------------------------------------------------
static simulated function QueueFunctionVoid(name target, string func, out Array<ASValue> arrData)
{
	QueueString(string(target), arrData);
	QueueString(func, arrData);
	QueueNull(arrData);
}

//----------------------------------------------------------------------------
// Call a function that takes a String param (String)
//----------------------------------------------------------------------------
static simulated function QueueFunctionString(name target, string func, string param, out Array<ASValue> arrData)
{
	QueueString(string(target), arrData);
	QueueString(func, arrData);
	QueueString(param, arrData);
	QueueNull(arrData);
}

//----------------------------------------------------------------------------
// Call a function that takes a Number param (Number)
//----------------------------------------------------------------------------
static simulated function QueueFunctionNum(name target, string func, float param, out Array<ASValue> arrData)
{
	QueueString(string(target), arrData);
	QueueString(func, arrData);
	QueueNumber(param, arrData);
	QueueNull(arrData);
}

//----------------------------------------------------------------------------
// Call a function that takes a Boolean params (Boolean)
//----------------------------------------------------------------------------
static simulated function QueueFunctionBool(name target, string func, bool param, out Array<ASValue> arrData)
{
	QueueString(string(target), arrData);
	QueueString(func, arrData);
	QueueBoolean(param, arrData);
	QueueNull(arrData);
}

//----------------------------------------------------------------------------
// Call a function that takes two Number params (Number, Number)
//----------------------------------------------------------------------------
static simulated function QueueFunctionNumPair(name target, string func, float param0, float param1, out Array<ASValue> arrData)
{
	QueueString(string(target), arrData);
	QueueString(func, arrData);
	QueueNumber(param0, arrData);
	QueueNumber(param1, arrData);
	QueueNull(arrData);
}

// ==========================================================================
// ==========================================================================

// Gets a list of socket attachments that start with UI_
// Used in UIArmory_WeaponUpgrade
// IMPORTANT: UI_ is stripped out of the socket name before adding it to the return array
static native function GetSocketNames(SkeletalMesh Mesh, out array<name> SocketNames);

//----------------------------------------------------------------------------
// Returns true if the given world point is currently on screen and within any specified padding
// Whether onscreen or not, v2ScreenCoords will contain the world point transformed into normalized screen coordinates.
//----------------------------------------------------------------------------
static native function bool IsOnScreen(Vector Location, out Vector2D ScreenCoords, optional float Padding = 0.075f, optional float YPlaneOffset = 0.0f );

//Takes a string that the user has entered representing a filename (_not_ a pathname)
//Returns the string with invalid characters replaced and whitespace trimmed.
static native function string SanitizeFilenameFromUserInput(string Filename);

static native function string FormatFloat(float Value, int decimalPlaces);
static native function string FormatPercentage(float Value, int decimalPlaces);

static function DisplayUI3D(name DisplayTag, name CameraTag, float InterpTime, optional bool bSkipBaseViewTransition )
{
	local XComPresentationLayerBase Pres;
	Pres = XComPlayerController(class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController()).Pres;
	Pres.CAMLookAtNamedLocation(string(CameraTag), InterpTime, bSkipBaseViewTransition);
	Pres.Get3DMovie().ShowDisplay(DisplayTag);
}