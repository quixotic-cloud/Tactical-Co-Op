//---------------------------------------------------------------------------------------
//  FILE:    X2ObjectTag.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2ObjectTag extends XGLocalizeTag native(Core);

var Object ParseObj;

native function bool Expand(string InString, out string OutString);

DefaultProperties
{
	Tag="Obj";
}